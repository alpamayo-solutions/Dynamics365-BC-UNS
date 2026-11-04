"""Execution app commands (UNS Bridge Connector 2.0).

Read the step list and write execution facts the way the PREKIT Execution app's BC adapter does.
See docs/execution-app-contract.md for the field contract. Every write carries an idempotency key
(eventId / noteId); a repeat with the same key is a no-op that returns result = "Duplicate".
"""

import json
from collections.abc import Callable
from datetime import datetime, timedelta
from functools import wraps
from uuid import uuid4

import click
from rich.console import Console
from rich.table import Table

from ..client import BCApiError, BCClient
from ..config import get_config_with_token
from ..models import RoutingLine, bc_datetime, utc_now

console = Console()

WORK_PLACE_TYPES = click.Choice(["Work Center", "Machine Center"], case_sensitive=False)
DATETIME = click.DateTime(formats=["%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"])


def bc_command(fn: Callable) -> Callable:
    """Open a client, pass it as the first argument and turn errors into exit code 1."""

    @wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            with BCClient(get_config_with_token()) as client:
                return fn(client, *args, **kwargs)
        except BCApiError as e:
            console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
            raise SystemExit(1)
        except ValueError as e:
            console.print(f"[red]Error:[/red] {e}")
            raise SystemExit(1)

    return wrapper


def _print_result(result: dict, json_out: bool, fields: list[str]) -> None:
    if json_out:
        console.print_json(json.dumps(result))
        return
    table = Table(show_header=False)
    table.add_column("Field", style="dim")
    table.add_column("Value")
    for field in fields:
        if field in result:
            table.add_row(field, str(result[field]))
    console.print(table)


def _ts(value: datetime | None) -> str | None:
    return bc_datetime(value) if value else None


def _fmt(value) -> str:
    if value is None or value == "":
        return "-"
    if isinstance(value, float):
        return f"{value:g}"
    if isinstance(value, datetime):
        if value.year == 1:  # BC's empty DateTime (0DT)
            return "-"
        return value.strftime("%Y-%m-%d %H:%M")
    return str(value)


# -- read -----------------------------------------------------------------


@click.command("steps")
@click.option("--order", "-o", "order_no", help="Production order no.")
@click.option("--status", "-s", default="Released", show_default=True, help="Order status filter")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def steps(client: BCClient, order_no: str | None, status: str, json_out: bool):
    """List steps (prodOrderRoutingLines) with stepId and execution state."""
    rows = client.get_routing_lines_raw(order_no=order_no, status=status)
    if json_out:
        console.print_json(json.dumps(rows))
        return
    lines = sorted(
        (RoutingLine.model_validate(r) for r in rows),
        key=lambda r: (r.prod_order_no, r.routing_reference_no or 0, r.sequence_no or 0),
    )
    if not lines:
        console.print("[yellow]No steps found.[/yellow]")
        return
    table = Table(title=f"Steps ({status})" + (f" for {order_no}" if order_no else ""))
    table.add_column("stepId", style="cyan")
    table.add_column("Seq", justify="right")
    table.add_column("Place")
    table.add_column("Description")
    table.add_column("Routing status")
    table.add_column("Exec. finished")
    table.add_column("Output", justify="right")
    table.add_column("Scrap", justify="right")
    table.add_column("Plan start")
    table.add_column("Queue", justify="right")
    for line in lines:
        table.add_row(
            line.step_id or "-",
            _fmt(line.sequence_no),
            f"{line.type or '-'} {line.no or ''}".strip(),
            line.description or "-",
            line.routing_status or "-",
            "yes" if line.execution_finished else "no",
            _fmt(line.output_quantity),
            _fmt(line.scrap_quantity),
            _fmt(line.planned_start),
            _fmt(line.queue_position),
        )
    console.print(table)


@click.command("machine-centers")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def machine_centers(client: BCClient, json_out: bool):
    """List machine centers."""
    rows = client.get_machine_centers()
    if json_out:
        console.print_json(json.dumps(rows))
        return
    if not rows:
        console.print("[yellow]No machine centers found.[/yellow]")
        return
    table = Table(title="Machine Centers")
    for col in ("Number", "Name", "Work center", "Capacity", "Efficiency", "Blocked"):
        table.add_column(col)
    for mc in rows:
        table.add_row(
            mc.get("number", "-"),
            mc.get("name", "-"),
            mc.get("workCenterNo") or "-",
            _fmt(mc.get("capacity")),
            _fmt(mc.get("efficiency")),
            "yes" if mc.get("blocked") else "no",
        )
    console.print(table)


# -- write ----------------------------------------------------------------


@click.command("finish")
@click.argument("step_id")
@click.option("--output", "output_qty", type=float, required=True, help="Good quantity (>= 0)")
@click.option("--scrap", "scrap_qty", type=float, help="Scrap quantity")
@click.option("--scrap-code", help="Scrap code (must exist in BC)")
@click.option("--run-min", type=float, help="Machine run minutes")
@click.option("--setup-min", type=float, help="Setup minutes")
@click.option("--ran-on-type", type=WORK_PLACE_TYPES, help="Where it ran, when not the planned place")
@click.option("--ran-on-no", help="Work/machine center no. it ran on")
@click.option("--employee", "employee_no", help="Employee no. who finished it")
@click.option("--started-at", type=DATETIME, help="UTC, e.g. 2026-11-04T08:00:00Z")
@click.option("--finished-at", type=DATETIME, help="UTC (default: now)")
@click.option("--event-id", help="Idempotency key (default: new uuid4)")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def finish(
    client: BCClient,
    step_id: str,
    output_qty: float,
    scrap_qty: float | None,
    scrap_code: str | None,
    run_min: float | None,
    setup_min: float | None,
    ran_on_type: str | None,
    ran_on_no: str | None,
    employee_no: str | None,
    started_at: datetime | None,
    finished_at: datetime | None,
    event_id: str | None,
    json_out: bool,
):
    """POST stepFinishes: finish STEP_ID ("{order}:{routingRef}:{opNo}")."""
    if bool(ran_on_type) != bool(ran_on_no):
        raise click.UsageError("--ran-on-type and --ran-on-no go together.")
    payload = {
        "eventId": event_id or str(uuid4()),
        "stepId": step_id,
        "finishedAt": bc_datetime(finished_at or utc_now()),
        "outputQuantity": output_qty,
        "startedAt": _ts(started_at),
        "scrapQuantity": scrap_qty,
        "scrapCode": scrap_code,
        "runMinutes": run_min,
        "setupMinutes": setup_min,
        "ranOnType": ran_on_type,
        "ranOnNo": ran_on_no,
        "employeeNo": employee_no,
    }
    result = client.post_step_finish({k: v for k, v in payload.items() if v is not None})
    _print_result(
        result,
        json_out,
        ["eventId", "stepId", "result", "outputQuantity", "scrapQuantity", "itemLedgerEntryNo", "capacityLedgerEntryNo"],
    )


@click.group("person-time")
def person_time():
    """Person time on a step (personTimes)."""


@person_time.command("add")
@click.option("--employee", "employee_no", help="Employee no. (required unless --cancel)")
@click.option("--step", "step_id", help="stepId the time belongs to")
@click.option("--start", "started_at", type=DATETIME, help="UTC start (default: end - 15 min)")
@click.option("--end", "ended_at", type=DATETIME, help="UTC end (default: now)")
@click.option("--session-id", help="Session id (default: new uuid4)")
@click.option("--session-key", help="Revision key of the session (default: new uuid4)")
@click.option("--slice", "slice_no", type=int, default=1, show_default=True, help="Slice no. within the revision")
@click.option("--work-place-type", type=WORK_PLACE_TYPES, help="Where the person worked")
@click.option("--work-place-no", help="Work/machine center no.")
@click.option("--cancel", is_flag=True, help="Cancel every row of --session-id")
@click.option("--event-id", help="Idempotency key (default: {sessionKey}:{slice})")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def person_time_add(
    client: BCClient,
    employee_no: str | None,
    step_id: str | None,
    started_at: datetime | None,
    ended_at: datetime | None,
    session_id: str | None,
    session_key: str | None,
    slice_no: int,
    work_place_type: str | None,
    work_place_no: str | None,
    cancel: bool,
    event_id: str | None,
    json_out: bool,
):
    """POST personTimes: one time slice.

    A new --session-key for an existing --session-id supersedes that session's earlier rows.
    """
    if cancel:
        if not session_id:
            raise click.UsageError("--cancel needs --session-id.")
        payload = {
            "eventId": event_id or f"{session_id}:cancel:{uuid4()}",
            "sessionId": session_id,
            "sessionKey": session_key or "",
            "cancelled": True,
        }
    else:
        if not employee_no:
            raise click.UsageError("--employee is required unless --cancel.")
        end = ended_at or utc_now()
        start = started_at or (end - timedelta(minutes=15))
        session_key = session_key or str(uuid4())
        payload = {
            "eventId": event_id or f"{session_key}:{slice_no}",
            "sessionId": session_id or str(uuid4()),
            "sessionKey": session_key,
            "employeeNo": employee_no,
            "stepId": step_id,
            "workPlaceType": work_place_type,
            "workPlaceNo": work_place_no,
            "startedAt": bc_datetime(start),
            "endedAt": bc_datetime(end),
        }
    result = client.post_person_time({k: v for k, v in payload.items() if v is not None})
    _print_result(
        result,
        json_out,
        ["eventId", "sessionId", "sessionKey", "employeeNo", "stepId", "minutes", "status", "result"],
    )


@person_time.command("list")
@click.argument("session_id")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def person_time_list(client: BCClient, session_id: str, json_out: bool):
    """List the person-time rows of a session."""
    rows = client.get_person_times(session_id)
    if json_out:
        console.print_json(json.dumps(rows))
        return
    table = Table(title=f"Person times of session {session_id}")
    for col in ("eventId", "sessionKey", "employeeNo", "stepId", "startedAt", "endedAt", "minutes", "status"):
        table.add_column(col)
    for r in rows:
        table.add_row(*(_fmt(r.get(c)) for c in ("eventId", "sessionKey", "employeeNo", "stepId", "startedAt", "endedAt", "minutes", "status")))
    console.print(table)


@click.group("note")
def note():
    """Notes on released production orders (orderNotes)."""


@note.command("add")
@click.argument("order_no")
@click.argument("text")
@click.option("--author", default="bridge-cli", show_default=True)
@click.option("--note-id", help="Idempotency key (default: new uuid4)")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def note_add(client: BCClient, order_no: str, text: str, author: str, note_id: str | None, json_out: bool):
    """POST orderNotes: add TEXT (<= 2048 chars) to ORDER_NO."""
    if len(text) > 2048:
        raise click.UsageError("Note text is limited to 2048 characters.")
    result = client.post_order_note(
        {"noteId": note_id or str(uuid4()), "orderNo": order_no, "text": text, "author": author}
    )
    _print_result(result, json_out, ["id", "noteId", "orderNo", "author", "result"])


@note.command("list")
@click.argument("order_no")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def note_list(client: BCClient, order_no: str, json_out: bool):
    """List notes the Execution app wrote on ORDER_NO."""
    rows = client.get_order_notes(order_no=order_no)
    if json_out:
        console.print_json(json.dumps(rows))
        return
    table = Table(title=f"Notes on {order_no}")
    for col in ("id", "noteId", "author", "text"):
        table.add_column(col)
    for r in rows:
        table.add_row(*(_fmt(r.get(c)) for c in ("id", "noteId", "author", "text")))
    console.print(table)


@note.command("delete")
@click.argument("note_id")
@bc_command
def note_delete(client: BCClient, note_id: str):
    """DELETE orderNotes: remove a note by its noteId (or its SystemId)."""
    rows = client.get_order_notes(note_id=note_id)
    # A repeated POST stores a "Duplicate" row next to the note itself; delete the note.
    originals = [r for r in rows if r.get("result") != "Duplicate"] or rows
    system_id = originals[0]["id"] if originals else note_id
    client.delete_order_note(system_id)
    console.print(f"[green]Deleted note {note_id}[/green]")


@click.command("move")
@click.argument("step_id")
@click.option("--to-type", type=WORK_PLACE_TYPES, required=True)
@click.option("--to-no", required=True, help="Work/machine center no.")
@click.option("--event-id", help="Idempotency key (default: new uuid4)")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def move(client: BCClient, step_id: str, to_type: str, to_no: str, event_id: str | None, json_out: bool):
    """POST stepMoves: move a not-started step to another place."""
    result = client.post_step_move(
        {"eventId": event_id or str(uuid4()), "stepId": step_id, "toType": to_type, "toNo": to_no}
    )
    _print_result(result, json_out, ["eventId", "stepId", "fromType", "fromNo", "toType", "toNo", "result"])


@click.command("plan")
@click.argument("step_id")
@click.option("--start", "planned_start", type=DATETIME, help="UTC planned start")
@click.option("--end", "planned_end", type=DATETIME, help="UTC planned end")
@click.option("--queue", "queue_position", type=int, help="Queue position at the station")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
@bc_command
def plan(
    client: BCClient,
    step_id: str,
    planned_start: datetime | None,
    planned_end: datetime | None,
    queue_position: int | None,
    json_out: bool,
):
    """PATCH stepPlans: set the execution fine plan (does not reschedule the BC order)."""
    fields = {
        "plannedStart": _ts(planned_start),
        "plannedEnd": _ts(planned_end),
        "queuePosition": queue_position,
    }
    fields = {k: v for k, v in fields.items() if v is not None}
    if not fields:
        raise click.UsageError("Give at least one of --start, --end, --queue.")
    step = client.get_step(step_id)
    result = client.patch_step_plan(str(step.id), fields)
    _print_result(result or fields, json_out, ["id", "stepId", "plannedStart", "plannedEnd", "queuePosition"])
