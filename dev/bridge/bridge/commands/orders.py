"""Order commands for querying production orders, routing, components, and work centers."""

import json

import click
from rich.console import Console
from rich.panel import Panel
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
@click.option("--since", help="Filter by systemModifiedAt (ISO format, e.g. '2024-01-01T20:00:00Z' - use quotes)")
@click.option("--top", "-n", default=50, help="Maximum number of results")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_orders(status: str, item_filter: str | None, since: str | None, top: int, json_out: bool):
    """GET released production orders from ERP."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                if since:
                    console.print(f"[dim]Polling for {status.lower()} orders modified since {since}...[/dim]")
                else:
                    console.print(f"[dim]Fetching {status.lower()} production orders...[/dim]")

            if since:
                orders = client.poll_production_orders(since=since, status=status, top=top)
            else:
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
                if since:
                    table.add_column("Modified At")

                for order in orders:
                    row = [
                        order.number,
                        order.source_no or "-",
                        order.description or "-",
                        f"{order.quantity:.0f}" if order.quantity else "-",
                    ]
                    if since:
                        modified = getattr(order, "system_modified_at", None)
                        row.append(modified.isoformat() if modified else "-")
                    table.add_row(*row)

                console.print(table)
                console.print(f"\n[dim]Found {len(orders)} order(s)[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("poll")
@click.option("--since", help="Only return orders modified since this timestamp (ISO format)")
@click.option("--status", "-s", default="Released", help="Filter by status (default: Released)")
@click.option("--top", "-n", default=50, help="Maximum number of results")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def poll(since: str | None, status: str, top: int, json_out: bool):
    """Poll for production orders (simulates ERP→UNS polling).

    Returns all orders by default, or only those modified since --since.
    """
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                if since:
                    console.print(f"[dim]Polling for {status.lower()} orders modified since {since}...[/dim]")
                else:
                    console.print(f"[dim]Polling for all {status.lower()} orders...[/dim]")

            if since:
                orders = client.poll_production_orders(since=since, status=status, top=top)
            else:
                orders = client.get_production_orders(status=status, top=top)

            if json_out:
                data = [o.model_dump(mode="json", by_alias=True) for o in orders]
                console.print_json(json.dumps(data))
            elif not orders:
                console.print(f"[yellow]No {status.lower()} orders found.[/yellow]")
            else:
                title = f"Orders Modified Since {since}" if since else f"{status} Production Orders"
                table = Table(title=title)
                table.add_column("Number", style="cyan")
                table.add_column("Item", style="green")
                table.add_column("Description")
                table.add_column("Quantity", justify="right")
                table.add_column("Modified At")

                for order in orders:
                    modified = getattr(order, "system_modified_at", None)
                    table.add_row(
                        order.number,
                        order.source_no or "-",
                        order.description or "-",
                        f"{order.quantity:.0f}" if order.quantity else "-",
                        modified.isoformat() if modified else "-",
                    )

                console.print(table)
                console.print(f"\n[dim]Found {len(orders)} order(s)[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("get-order")
@click.argument("order_no")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_order(order_no: str, json_out: bool):
    """GET a single production order with full details."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Fetching order {order_no}...[/dim]")

            order = client.get_production_order(order_no)

            if json_out:
                if order:
                    console.print_json(json.dumps(order.model_dump(mode="json", by_alias=True)))
                else:
                    console.print_json("{}")
            elif not order:
                console.print(f"[yellow]Order {order_no} not found.[/yellow]")
            else:
                info = (
                    f"[bold]Number:[/bold] {order.number}\n"
                    f"[bold]Status:[/bold] {order.status or '-'}\n"
                    f"[bold]Item:[/bold] {order.source_no or '-'}\n"
                    f"[bold]Description:[/bold] {order.description or '-'}\n"
                    f"[bold]Quantity:[/bold] {order.quantity:.0f}" if order.quantity else "-"
                )
                if order.due_date:
                    info += f"\n[bold]Due Date:[/bold] {order.due_date}"
                if order.starting_date:
                    info += f"\n[bold]Starting Date:[/bold] {order.starting_date}"
                if order.ending_date:
                    info += f"\n[bold]Ending Date:[/bold] {order.ending_date}"
                if order.location_code:
                    info += f"\n[bold]Location:[/bold] {order.location_code}"
                if order.system_modified_at:
                    info += f"\n[bold]Modified At:[/bold] {order.system_modified_at.isoformat()}"

                console.print(Panel(info, title=f"Production Order {order_no}"))

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("get-components")
@click.argument("order_no")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_components(order_no: str, json_out: bool):
    """GET components (BOM lines) for a production order."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Fetching components for order {order_no}...[/dim]")

            components = client.get_components(order_no)

            if json_out:
                data = [c.model_dump(mode="json", by_alias=True) for c in components]
                console.print_json(json.dumps(data))
            elif not components:
                console.print(f"[yellow]No components found for order {order_no}.[/yellow]")
            else:
                table = Table(title=f"Components for {order_no}")
                table.add_column("Item No", style="cyan")
                table.add_column("Description")
                table.add_column("Qty Per", justify="right")
                table.add_column("Expected", justify="right")
                table.add_column("Remaining", justify="right")
                table.add_column("Location")
                table.add_column("Flushing")

                for comp in components:
                    table.add_row(
                        comp.item_no or "-",
                        comp.description or "-",
                        f"{comp.quantity_per:.2f}" if comp.quantity_per else "-",
                        f"{comp.expected_quantity:.2f}" if comp.expected_quantity else "-",
                        f"{comp.remaining_quantity:.2f}" if comp.remaining_quantity else "-",
                        comp.location_code or "-",
                        comp.flushing_method or "-",
                    )

                console.print(table)
                console.print(f"\n[dim]Found {len(components)} component(s)[/dim]")

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
