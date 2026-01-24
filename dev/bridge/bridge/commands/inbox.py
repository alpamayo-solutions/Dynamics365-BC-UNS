"""Inbox commands for viewing integration and output inbox entries."""

import json

import click
from rich.console import Console
from rich.table import Table

from ..client import BCClient, BCApiError
from ..config import get_config_with_token

console = Console()


@click.command("get-inbox")
@click.option("--type", "-t", "inbox_type", type=click.Choice(["execution", "output", "all"]), default="all", help="Type of inbox to view")
@click.option("--status", "-s", type=click.Choice(["Received", "Processed", "Failed"]), help="Filter by status")
@click.option("--top", "-n", default=50, help="Maximum number of results")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_inbox(inbox_type: str, status: str | None, top: int, json_out: bool):
    """GET inbox entries from the ERP API."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Fetching {inbox_type} inbox entries...[/dim]")

            results = []

            if inbox_type in ("execution", "all"):
                try:
                    exec_entries = client.get_integration_inbox(status=status, top=top)
                    for e in exec_entries:
                        results.append({
                            "type": "execution",
                            "messageId": str(e.message_id),
                            "orderNo": e.order_no,
                            "operationNo": e.operation_no,
                            "status": e.status,
                            "receivedAt": e.received_at.isoformat() if e.received_at else None,
                            "error": e.error,
                            "warning": e.warning,
                        })
                except BCApiError:
                    # Integration inbox API may not exist yet
                    pass

            if inbox_type in ("output", "all"):
                try:
                    output_entries = client.get_output_inbox(status=status, top=top)
                    for e in output_entries:
                        results.append({
                            "type": "output",
                            "messageId": str(e.message_id),
                            "orderNo": e.order_no,
                            "operationNo": e.operation_no,
                            "outputQty": e.output_quantity,
                            "scrapQty": e.scrap_quantity,
                            "status": e.status,
                            "receivedAt": e.received_at.isoformat() if e.received_at else None,
                            "error": e.error,
                        })
                except BCApiError:
                    # Output inbox API may not exist yet
                    pass

            if json_out:
                console.print_json(json.dumps(results))
            elif not results:
                console.print("[yellow]No inbox entries found.[/yellow]")
            else:
                table = Table(title="Inbox Entries")
                table.add_column("Type", style="dim")
                table.add_column("Order No", style="cyan")
                table.add_column("Op No")
                table.add_column("Status")
                table.add_column("Output", justify="right")
                table.add_column("Scrap", justify="right")
                table.add_column("Received At")
                table.add_column("Error", style="red", max_width=25)
                table.add_column("Warning", style="yellow", max_width=25)

                for entry in results:
                    status_style = ""
                    if entry.get("status") == "Processed":
                        status_style = "green"
                    elif entry.get("status") == "Failed":
                        status_style = "red"
                    elif entry.get("status") == "Received":
                        status_style = "yellow"

                    table.add_row(
                        entry.get("type", "-"),
                        entry.get("orderNo") or "-",
                        entry.get("operationNo") or "-",
                        f"[{status_style}]{entry.get('status') or '-'}[/{status_style}]",
                        f"{entry.get('outputQty', 0):.0f}" if entry.get("type") == "output" else "-",
                        f"{entry.get('scrapQty', 0):.0f}" if entry.get("type") == "output" else "-",
                        entry.get("receivedAt", "-") or "-",
                        (entry.get("error") or "-")[:25],
                        (entry.get("warning") or "-")[:25],
                    )

                console.print(table)
                console.print(f"\n[dim]Found {len(results)} entry/entries[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)
