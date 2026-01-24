"""Order commands for querying production orders, routing, and work centers."""

import json

import click
from rich.console import Console
from rich.table import Table

from ..client import BCClient, BCApiError
from ..config import get_config_with_token

console = Console()


@click.command("get-work-centers")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_work_centers(json_out: bool):
    """GET work centers from the custom API."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print("[dim]Fetching work centers...[/dim]")

            wcs = client.get_work_centers()

            if json_out:
                console.print_json(json.dumps(wcs))
            elif not wcs:
                console.print("[yellow]No work centers found.[/yellow]")
            else:
                table = Table(title="Work Centers")
                table.add_column("Number", style="cyan")
                table.add_column("Name", style="green")
                table.add_column("Group")
                table.add_column("Capacity", justify="right")

                for wc in wcs:
                    table.add_row(
                        wc.get("number", "-"),
                        wc.get("name", "-"),
                        wc.get("workCenterGroupCode", "-"),
                        str(wc.get("capacity", "-")),
                    )

                console.print(table)

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("get-orders")
@click.option("--status", "-s", default="Released", help="Filter by status (default: Released)")
@click.option("--item", "-i", "item_filter", help="Filter by item number")
@click.option("--top", "-n", default=50, help="Maximum number of results")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_orders(status: str, item_filter: str | None, top: int, json_out: bool):
    """GET released production orders from ERP."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Fetching {status.lower()} production orders...[/dim]")

            orders = client.get_production_orders(status=status, top=top)

            # Client-side filter by item if specified
            if item_filter:
                orders = [o for o in orders if o.source_no and item_filter in o.source_no]

            if json_out:
                data = [o.model_dump(mode="json", by_alias=True) for o in orders]
                console.print_json(json.dumps(data))
            elif not orders:
                console.print(f"[yellow]No {status.lower()} production orders found.[/yellow]")
            else:
                table = Table(title=f"{status} Production Orders")
                table.add_column("Number", style="cyan")
                table.add_column("Item", style="green")
                table.add_column("Description")
                table.add_column("Quantity", justify="right")

                for order in orders:
                    table.add_row(
                        order.number,
                        order.source_no or "-",
                        order.description or "-",
                        f"{order.quantity:.0f}" if order.quantity else "-",
                    )

                console.print(table)
                console.print(f"\n[dim]Found {len(orders)} order(s)[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("get-routing")
@click.argument("order_no")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_routing(order_no: str, json_out: bool):
    """GET routing lines for a production order."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Fetching routing for order {order_no}...[/dim]")

            lines = client.get_routing_lines(order_no)

            if json_out:
                data = [r.model_dump(mode="json", by_alias=True) for r in lines]
                console.print_json(json.dumps(data))
            elif not lines:
                console.print(f"[yellow]No routing lines found for order {order_no}.[/yellow]")
            else:
                table = Table(title=f"Routing for {order_no}")
                table.add_column("Op No", style="cyan", justify="right")
                table.add_column("Type")
                table.add_column("No", style="green")
                table.add_column("Description")
                table.add_column("Run Time", justify="right")
                table.add_column("Setup Time", justify="right")

                for line in lines:
                    table.add_row(
                        line.operation_no,
                        line.type or "-",
                        line.no or "-",
                        line.description or "-",
                        f"{line.run_time:.2f}" if line.run_time else "-",
                        f"{line.setup_time:.2f}" if line.setup_time else "-",
                    )

                console.print(table)

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)
