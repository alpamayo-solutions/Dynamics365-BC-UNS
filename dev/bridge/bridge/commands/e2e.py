"""Scripted smoke run of the Execution app surface against a live Business Central.

It WRITES to BC (finishes a step, posts person time, adds/deletes a note, moves a step, sets a
fine plan), so it refuses to run without --yes. Use a fresh released order with at least two
routing lines whose steps are not started yet; checks that need a state the order no longer has
are reported as SKIP, not FAIL.
"""

import json
from dataclasses import dataclass
from datetime import timedelta
from uuid import uuid4

import click
from rich.console import Console
from rich.table import Table

from ..client import BCApiError, BCClient
from ..config import get_config_with_token
from ..models import RoutingLine, bc_datetime, utc_now

console = Console()

ORDER_FIELDS = [
    "id", "status", "number", "description", "sourceType", "sourceNo", "itemNo", "customerOrderNo",
    "quantity", "dueDate", "startingDateTime", "endingDateTime", "finishedDate", "held",
    "systemCreatedAt", "systemModifiedAt",
]
STEP_FIELDS = [
    "id", "stepId", "status", "prodOrderNo", "routingReferenceNo", "routingNo", "operationNo",
    "sequenceNo", "previousOperationNo", "nextOperationNo", "type", "no", "workCenterNo",
    "workCenterGroupCode", "description", "setupTime", "runTime", "waitTime", "moveTime",
    "inputQuantity", "plannedMinutes", "routingStatus", "startingDateTime", "endingDateTime",
    "executionFinished", "executionFinishedAt", "outputQuantity", "scrapQuantity", "plannedStart",
    "plannedEnd", "queuePosition", "systemModifiedAt",
]
MACHINE_CENTER_FIELDS = ["id", "number", "name", "workCenterNo", "blocked", "capacity", "efficiency"]


@dataclass
class Check:
    name: str
    status: str  # PASS / FAIL / SKIP
    detail: str = ""


class Run:
    def __init__(self) -> None:
        self.checks: list[Check] = []

    def add(self, name: str, ok: bool, detail: str = "") -> bool:
        self.checks.append(Check(name, "PASS" if ok else "FAIL", detail))
        return ok

    def skip(self, name: str, detail: str) -> None:
        self.checks.append(Check(name, "SKIP", detail))

    def call(self, name: str, fn, expect=None):
        """Run fn(); record FAIL on BCApiError. expect(result) -> (ok, detail)."""
        try:
            result = fn()
        except BCApiError as e:
            self.add(name, False, f"HTTP {e.status_code}: {e.message}")
            return None
        if expect:
            ok, detail = expect(result)
            self.add(name, ok, detail)
        else:
            self.add(name, True)
        return result

    @property
    def failed(self) -> bool:
        return any(c.status == "FAIL" for c in self.checks)


def _missing(row: dict, fields: list[str]) -> list[str]:
    return [f for f in fields if f not in row]


def _fields_check(row: dict, fields: list[str]) -> tuple[bool, str]:
    missing = _missing(row, fields)
    return (not missing, f"missing: {', '.join(missing)}" if missing else f"{len(fields)} fields")


def _same_instant(a: str | None, b: str) -> bool:
    return bool(a) and a.replace(".000", "").rstrip("Z") == b.rstrip("Z")


@click.command("e2e")
@click.option("--order", "order_no", required=True, help="Released production order with >= 2 routing lines")
@click.option("--yes", is_flag=True, help="Confirm: this run writes to Business Central")
@click.option("--employee", "employee_no", help="Employee no. for the person-time check (skipped without it)")
@click.option("--output", "output_qty", type=float, default=1, show_default=True, help="Output quantity for step 1")
@click.option("--move-to", "move_to", help="Work center no. for the move check (default: first other non-blocked one by number)")
@click.option("--json-output", "json_out", is_flag=True, help="Print the result table as JSON")
def e2e(order_no: str, yes: bool, employee_no: str | None, output_qty: float, move_to: str | None, json_out: bool):
    """Smoke-test the Execution app API on ORDER against a live BC (writes data; needs --yes)."""
    if not yes:
        raise click.UsageError(
            "bridge e2e writes to Business Central (finish, person time, note, move, plan). "
            "Re-run with --yes on a test order."
        )
    run = Run()
    try:
        with BCClient(get_config_with_token()) as client:
            _run(client, run, order_no, employee_no, output_qty, move_to)
    except BCApiError as e:
        run.add("connection", False, f"HTTP {e.status_code}: {e.message}")
    except ValueError as e:
        run.add("configuration", False, str(e))

    if json_out:
        console.print_json(json.dumps([c.__dict__ for c in run.checks]))
    else:
        table = Table(title=f"bridge e2e - order {order_no}")
        table.add_column("Check")
        table.add_column("Result")
        table.add_column("Detail")
        colors = {"PASS": "green", "FAIL": "red", "SKIP": "yellow"}
        for c in run.checks:
            table.add_row(c.name, f"[{colors[c.status]}]{c.status}[/]", c.detail)
        console.print(table)
    raise SystemExit(1 if run.failed else 0)


def _run(client: BCClient, run: Run, order_no: str, employee_no: str | None, output_qty: float, move_to: str | None) -> None:
    # -- read: order, steps, machine centers ------------------------------
    order = client.get_production_order_raw(order_no)
    if not run.add("order exists and is Released", bool(order) and order.get("status") == "Released",
                   f"status={order.get('status') if order else 'not found'}"):
        return
    run.add("order fields", *_fields_check(order, ORDER_FIELDS))
    if order.get("held"):
        run.add("order not on hold", False, "order is held; release the hold first")
        return

    rows = client.get_routing_lines_raw(order_no=order_no, status="Released")
    if not run.add("order has >= 2 steps", len(rows) >= 2, f"{len(rows)} routing line(s)"):
        return
    run.add("step fields", *_fields_check(rows[0], STEP_FIELDS))

    mcs = run.call("machineCenters readable", client.get_machine_centers,
                   lambda r: (True, f"{len(r)} machine center(s)"))
    if mcs:
        run.add("machine center fields", *_fields_check(mcs[0], MACHINE_CENTER_FIELDS))

    lines = [RoutingLine.model_validate(r) for r in rows]
    ref = min(line.routing_reference_no or 0 for line in lines)
    seq = sorted((line for line in lines if (line.routing_reference_no or 0) == ref),
                 key=lambda line: line.sequence_no or 0)
    if len(seq) < 2:
        run.add("first order line has >= 2 steps", False, f"routing reference {ref} has {len(seq)} step(s)")
        return
    step1, step2 = seq[0], seq[1]
    now = utc_now()

    # -- out-of-order finish: step 2 before step 1 -> 400 ---------------
    if step1.done or step2.done:
        run.skip("finish step 2 before step 1 refused", "needs a fresh order (step 1 or 2 already done)")
    else:
        try:
            r = client.post_step_finish({"eventId": str(uuid4()), "stepId": step2.step_id,
                                         "finishedAt": bc_datetime(now), "outputQuantity": output_qty})
            run.add("finish step 2 before step 1 refused", False, f"accepted with result={r.get('result')}")
        except BCApiError as e:
            run.add("finish step 2 before step 1 refused", e.status_code == 400, f"HTTP {e.status_code}: {e.message}")

    # -- finish step 1, then repeat the same eventId -> Duplicate -----------
    if step1.done:
        run.skip("finish step 1", f"{step1.step_id} already done; use a fresh order")
        run.skip("repeat eventId is Duplicate", "step 1 not finished by this run")
    else:
        finish_payload = {
            "eventId": str(uuid4()),
            "stepId": step1.step_id,
            "startedAt": bc_datetime(now - timedelta(minutes=30)),
            "finishedAt": bc_datetime(now),
            "outputQuantity": output_qty,
            "runMinutes": 25,
            "setupMinutes": 5,
        }
        first = run.call("finish step 1", lambda: client.post_step_finish(finish_payload),
                         lambda r: (r.get("result") in ("Recorded", "Posted"), f"result={r.get('result')}"))
        if first is not None:
            after = client.get_step(step1.step_id)
            run.add("step 1 reads as done", after.done,
                    f"executionFinished={after.execution_finished}, routingStatus={after.routing_status}, "
                    f"outputQuantity={after.output_quantity}")
            run.call("repeat eventId is Duplicate", lambda: client.post_step_finish(finish_payload),
                     lambda r: (r.get("result") == "Duplicate", f"result={r.get('result')}"))

    # -- person time: second revision supersedes the first -----------------
    if not employee_no:
        run.skip("person time supersede", "no --employee given")
    else:
        session_id = f"e2e-{uuid4()}"
        keys = [str(uuid4()), str(uuid4())]
        for i, key in enumerate(keys, start=1):
            run.call(f"person time revision {i}", lambda key=key, i=i: client.post_person_time({
                "eventId": f"{key}:1", "sessionId": session_id, "sessionKey": key,
                "employeeNo": employee_no, "stepId": step1.step_id,
                "startedAt": bc_datetime(now - timedelta(minutes=30)),
                "endedAt": bc_datetime(now - timedelta(minutes=10 * i)),
            }), lambda r: (r.get("status") == "Active", f"status={r.get('status')}, result={r.get('result')}"))
        rows_pt = client.get_person_times(session_id)
        by_key = {r.get("sessionKey"): r.get("status") for r in rows_pt}
        run.add("person time supersede", by_key.get(keys[0]) == "Superseded" and by_key.get(keys[1]) == "Active",
                f"{len(rows_pt)} row(s): {by_key}")

    # -- note: add, read back, delete, gone --------------------------------
    note_id = f"e2e-{uuid4()}"
    created = run.call("note add", lambda: client.post_order_note(
        {"noteId": note_id, "orderNo": order_no, "text": "bridge e2e smoke note", "author": "bridge-e2e"}),
        lambda r: (bool(r.get("id")), f"id={r.get('id')}"))
    if created:
        run.add("note readable", len(client.get_order_notes(note_id=note_id)) == 1)
        run.call("note delete", lambda: client.delete_order_note(created["id"]))
        run.add("note gone", not client.get_order_notes(note_id=note_id))

    # -- move a not-started step to another work center, and back -------
    movable = [line for line in seq[1:] if not line.done and not line.output_quantity]
    if not movable:
        run.skip("move step", "no not-started step left")
    else:
        target_step = movable[-1]
        current_wc = target_step.work_center_no or target_step.no
        if move_to:
            target_wc = move_to
        else:
            # Deterministic pick for a smoke test: lowest-numbered other non-blocked work center.
            others = sorted(wc["number"] for wc in client.get_work_centers()
                            if wc.get("number") != current_wc and not wc.get("blocked"))
            target_wc = others[0] if others else None
        if not target_wc:
            run.skip("move step", "no other non-blocked work center")
        else:
            moved = run.call(f"move {target_step.step_id} to {target_wc}", lambda: client.post_step_move(
                {"eventId": str(uuid4()), "stepId": target_step.step_id, "toType": "Work Center", "toNo": target_wc}),
                lambda r: (r.get("result") == "Recorded",
                           f"result={r.get('result')}, from={r.get('fromType')} {r.get('fromNo')}"))
            if moved is not None:
                after = client.get_step(target_step.step_id)
                run.add("moved step reads new place", after.type == "Work Center" and after.no == target_wc,
                        f"{after.type} {after.no}")
                run.call("move step back", lambda: client.post_step_move(
                    {"eventId": str(uuid4()), "stepId": target_step.step_id,
                     "toType": target_step.type, "toNo": target_step.no}),
                    lambda r: (r.get("result") == "Recorded", f"back to {target_step.type} {target_step.no}"))

    # -- fine plan --------------------------------------------------------------
    plan_start = bc_datetime(now + timedelta(hours=1))
    plan_end = bc_datetime(now + timedelta(hours=2))
    patched = run.call("plan PATCH", lambda: client.patch_step_plan(
        str(step2.id), {"plannedStart": plan_start, "plannedEnd": plan_end, "queuePosition": 1}))
    if patched is not None:
        after = client.get_routing_lines_raw(step_id=step2.step_id, status="Released")[0]
        run.add("plan reads back", _same_instant(after.get("plannedStart"), plan_start)
                and _same_instant(after.get("plannedEnd"), plan_end) and after.get("queuePosition") == 1,
                f"plannedStart={after.get('plannedStart')}, queuePosition={after.get('queuePosition')}")
