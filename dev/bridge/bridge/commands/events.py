"""Event commands for posting execution events."""

import json
from pathlib import Path

import click
from rich.console import Console
from rich.panel import Panel

from ..client import BCClient, BCApiError
from ..config import get_config_with_token
from ..models import ExecutionEvent, OutputEvent

console = Console()


@click.command("post-event")
@click.option("--order", "-o", "order_no", help="Production order number")
@click.option("--operation", "-op", "operation_no", default="10", help="Operation number")
@click.option("--work-center", "-w", help="Work center code")
@click.option("--qty-produced", "-p", type=int, default=0, help="Quantity produced")
@click.option("--qty-rejected", "-r", type=int, default=0, help="Quantity rejected")
@click.option("--runtime", type=float, default=0, help="Runtime in seconds")
@click.option("--downtime", type=float, default=0, help="Downtime in seconds")
@click.option("--availability", type=float, default=0.95, help="Availability (0-1)")
@click.option("--productivity", type=float, default=0.90, help="Productivity (0-1)")
@click.option("--cycle-time", type=float, default=0, help="Actual cycle time in seconds")
@click.option("--file", "-f", "file_path", type=click.Path(exists=True), help="Load event from JSON file")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def post_event(
    order_no: str | None,
    operation_no: str,
    work_center: str | None,
    qty_produced: int,
    qty_rejected: int,
    runtime: float,
    downtime: float,
    availability: float,
    productivity: float,
    cycle_time: float,
    file_path: str | None,
    json_out: bool,
):
    """POST an execution event to the ERP API."""
    try:
        config = get_config_with_token()

        # Load from file or build from options
        if file_path:
            with open(file_path) as f:
                data = json.load(f)
            event = ExecutionEvent.model_validate(data)
        else:
            if not order_no:
                order_no = click.prompt("Production order number")

            event = ExecutionEvent(
                order_no=order_no,
                operation_no=operation_no,
                work_center=work_center,
                qty_produced=qty_produced,
                qty_rejected=qty_rejected,
                runtime_sec=runtime,
                downtime_sec=downtime,
                availability=availability,
                productivity=productivity,
                actual_cycle_time_sec=cycle_time,
            )

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Posting event for order {event.order_no}...[/dim]")

            result = client.post_execution_event(event)

            if json_out:
                console.print_json(json.dumps(result))
            else:
                console.print("[green]Event posted successfully[/green]")
                console.print(Panel(
                    f"Order: {event.order_no}\n"
                    f"Operation: {event.operation_no}\n"
                    f"Message ID: {event.message_id}\n"
                    f"Qty. Produced: {event.qty_produced} (rejected: {event.qty_rejected})",
                    title="Execution Event",
                ))

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        if e.details:
            console.print_json(json.dumps(e.details))
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("post-output")
@click.option("--order", "-o", "order_no", help="Production order number")
@click.option("--operation", "-op", "operation_no", default="10", help="Operation number")
@click.option("--qty-produced", type=float, default=0, help="Quantity produced")
@click.option("--qty-rejected", type=float, default=0, help="Quantity rejected")
@click.option("--posting-date", help="Posting date (YYYY-MM-DD)")
@click.option("--file", "-f", "file_path", type=click.Path(exists=True), help="Load output event from JSON file")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def post_output(
    order_no: str | None,
    operation_no: str,
    qty_produced: float,
    qty_rejected: float,
    posting_date: str | None,
    file_path: str | None,
    json_out: bool,
):
    """POST an output event (produced/rejected quantities) to the ERP API."""
    from datetime import date as date_type

    try:
        config = get_config_with_token()

        # Load from file or build from options
        if file_path:
            with open(file_path) as f:
                data = json.load(f)
            event = OutputEvent.model_validate(data)
        else:
            if not order_no:
                order_no = click.prompt("Production order number")

            parsed_date = None
            if posting_date:
                parsed_date = date_type.fromisoformat(posting_date)

            event = OutputEvent(
                order_no=order_no,
                operation_no=operation_no,
                qty_produced=qty_produced,
                qty_rejected=qty_rejected,
                posting_date=parsed_date,
            )

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Posting output for order {event.order_no}...[/dim]")

            result = client.post_output_event(event)

            if json_out:
                console.print_json(json.dumps(result))
            else:
                console.print("[green]Output event posted successfully[/green]")
                console.print(Panel(
                    f"Order: {event.order_no}\n"
                    f"Operation: {event.operation_no}\n"
                    f"Message ID: {event.message_id}\n"
                    f"Qty. Produced: {event.qty_produced} (rejected: {event.qty_rejected})",
                    title="Output Event",
                ))

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        if e.details:
            console.print_json(json.dumps(e.details))
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)
