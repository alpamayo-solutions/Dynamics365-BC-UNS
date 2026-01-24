"""Setup commands for creating test data in BC."""

import click
from rich.console import Console

from ..client import BCClient, BCApiError
from ..config import get_config_with_token
from ..models import CreateProductionOrder, Item, WorkCenter

console = Console()


@click.group()
def setup():
    """Setup commands for test data population."""
    pass


@setup.command("items")
@click.option("--prefix", "-p", default="TEST", help="Item number prefix")
@click.option("--count", "-n", default=3, help="Number of items to create")
def setup_items(prefix: str, count: int):
    """Create test items in BC."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            console.print(f"[dim]Creating {count} test items...[/dim]")

            for i in range(1, count + 1):
                number = f"{prefix}-{i:03d}"

                # Check if exists
                existing = client.get_item(number)
                if existing:
                    console.print(f"  [yellow]Item {number} already exists[/yellow]")
                    continue

                item = Item(
                    number=number,
                    display_name=f"Test Item {i}",
                    type="Inventory",
                )

                try:
                    client.create_item(item)
                    console.print(f"  [green]Created item {number}[/green]")
                except BCApiError as e:
                    console.print(f"  [red]Failed to create {number}:[/red] {e.message}")

            console.print("[green]Done[/green]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@setup.command("work-centers")
@click.option("--prefix", "-p", default="WC", help="Work center number prefix")
@click.option("--count", "-n", default=3, help="Number of work centers to create")
def setup_work_centers(prefix: str, count: int):
    """Create test work centers in BC.

    Requires the ShopfloorExecutionBridge extension to be deployed (exposes workCenters API).
    """
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            console.print(f"[dim]Creating {count} test work centers...[/dim]")

            for i in range(1, count + 1):
                number = f"{prefix}-{i:03d}"

                # Check if exists
                existing = client.get_work_center(number)
                if existing:
                    console.print(f"  [yellow]Work center {number} already exists[/yellow]")
                    continue

                wc = WorkCenter(
                    number=number,
                    name=f"Test Work Center {i}",
                )

                try:
                    client.create_work_center(wc)
                    console.print(f"  [green]Created work center {number}[/green]")
                except BCApiError as e:
                    console.print(f"  [red]Failed to create {number}:[/red] {e.message}")

            console.print("[green]Done[/green]")

    except BCApiError as e:
        if e.status_code == 404:
            console.print("[red]API Error:[/red] workCenters endpoint not found.")
            console.print()
            console.print("Make sure the ShopfloorExecutionBridge extension is deployed:")
            console.print("  1. Open VS Code in the project root")
            console.print("  2. Press F5 to deploy to BC Sandbox")
            console.print("  3. Retry this command")
        else:
            console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@setup.command("prod-order")
@click.option("--item", "-i", "item_no", help="Item number for the production order")
@click.option("--quantity", "-q", type=float, default=100, help="Quantity to produce")
@click.option("--description", "-d", help="Order description")
@click.option("--status", "-s", default="Released", help="Order status (Released, Planned, Firm_Planned)")
def setup_prod_order(item_no: str | None, quantity: float, description: str | None, status: str):
    """Create a released production order."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            # If no item specified, list available items
            if not item_no:
                items = client.get_items(top=20)
                if items:
                    console.print("[dim]Available items:[/dim]")
                    for item in items[:10]:
                        console.print(f"  {item.get('number', 'N/A'):15} - {item.get('displayName', 'N/A')}")
                    console.print()
                item_no = click.prompt("Item number")

            if not description:
                description = f"Demo order for {item_no}"

            console.print(f"[dim]Creating {status} production order for {item_no}...[/dim]")

            order = CreateProductionOrder(
                status=status,
                source_no=item_no,
                quantity=quantity,
                description=description,
            )

            result = client.create_production_order(order)
            order_no = result.get("number", "Unknown")

            console.print(f"[green]Created production order: {order_no}[/green]")
            console.print(f"  Item: {item_no}")
            console.print(f"  Quantity: {quantity}")
            console.print(f"  Status: {result.get('status', 'Unknown')}")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@setup.command("demo")
@click.option("--released", "-r", default=3, help="Number of released orders")
@click.option("--planned", "-p", default=2, help="Number of planned orders")
def setup_demo(released: int, planned: int):
    """Create demo production orders using existing items.

    Creates both released and planned production orders.
    """
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            console.print("[dim]Fetching available items...[/dim]")
            items = client.get_items(top=50)

            if not items:
                console.print("[red]No items found. Cannot create production orders.[/red]")
                raise SystemExit(1)

            total = released + planned
            console.print(f"[dim]Found {len(items)} items. Creating {total} production orders...[/dim]")
            console.print()

            # Create released orders
            if released > 0:
                console.print("[bold]Released orders:[/bold]")
                for i in range(min(released, len(items))):
                    item = items[i % len(items)]
                    item_no = item.get("number")

                    order = CreateProductionOrder(
                        status="Released",
                        source_no=item_no,
                        quantity=100 + (i * 50),
                        description=f"Demo (Released): {item.get('displayName', item_no)}",
                    )

                    try:
                        result = client.create_production_order(order)
                        order_no = result.get("number", "Unknown")
                        console.print(f"  [green]{order_no}[/green] - {item_no} x {order.quantity}")
                    except BCApiError as e:
                        console.print(f"  [red]Failed for {item_no}:[/red] {e.message}")

            # Create planned orders
            if planned > 0:
                console.print()
                console.print("[bold]Planned orders:[/bold]")
                for i in range(min(planned, len(items))):
                    item = items[(released + i) % len(items)]
                    item_no = item.get("number")

                    order = CreateProductionOrder(
                        status="Planned",
                        source_no=item_no,
                        quantity=200 + (i * 100),
                        description=f"Demo (Planned): {item.get('displayName', item_no)}",
                    )

                    try:
                        result = client.create_production_order(order)
                        order_no = result.get("number", "Unknown")
                        console.print(f"  [cyan]{order_no}[/cyan] - {item_no} x {order.quantity}")
                    except BCApiError as e:
                        console.print(f"  [red]Failed for {item_no}:[/red] {e.message}")

            console.print()
            console.print("[green]Demo setup complete![/green]")
            console.print()
            console.print("[dim]Run 'bridge get-orders' for released orders[/dim]")
            console.print("[dim]Run 'bridge get-orders --status Planned' for planned orders[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@setup.command("all")
@click.option("--item-prefix", default="TEST", help="Item number prefix")
@click.option("--wc-prefix", default="WC", help="Work center prefix")
@click.pass_context
def setup_all(ctx, item_prefix: str, wc_prefix: str):
    """Run all setup commands (items, work-centers)."""
    console.print("[bold]Running all setup commands...[/bold]")
    console.print()

    console.print("[bold]1. Creating items[/bold]")
    ctx.invoke(setup_items, prefix=item_prefix, count=3)
    console.print()

    console.print("[bold]2. Creating work centers[/bold]")
    ctx.invoke(setup_work_centers, prefix=wc_prefix, count=3)
    console.print()

    console.print("[green]All setup complete![/green]")


@setup.command("cleanup")
@click.option("--status", "-s", help="Only delete orders with this status (Released, Planned, etc.)")
@click.option("--yes", "-y", is_flag=True, help="Skip confirmation prompt")
def setup_cleanup(status: str | None, yes: bool):
    """Delete all production orders (sandbox only).

    This command deletes production orders from the BC sandbox environment.
    Use with caution - this operation cannot be undone.
    """
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            # Fetch orders to delete
            console.print("[dim]Fetching production orders...[/dim]")

            orders_to_delete = []
            for order_status in ["Released", "Planned", "Firm_Planned", "Simulated"]:
                if status and order_status != status:
                    continue
                try:
                    orders = client.get_production_orders(status=order_status, top=100)
                    orders_to_delete.extend(orders)
                except BCApiError:
                    pass  # Status may not have any orders

            if not orders_to_delete:
                console.print("[yellow]No production orders found to delete.[/yellow]")
                return

            # Show what will be deleted
            console.print(f"\n[bold]Found {len(orders_to_delete)} production order(s) to delete:[/bold]")
            for order in orders_to_delete[:10]:
                console.print(f"  {order.number} - {order.status} - {order.source_no or 'N/A'}")
            if len(orders_to_delete) > 10:
                console.print(f"  ... and {len(orders_to_delete) - 10} more")

            # Confirm deletion
            if not yes:
                console.print()
                if not click.confirm("[bold red]Delete these production orders?[/bold red]", default=False):
                    console.print("[yellow]Cancelled.[/yellow]")
                    return

            # Delete orders
            console.print()
            console.print("[dim]Deleting production orders (sandbox only)...[/dim]")

            deleted = 0
            failed = 0
            for order in orders_to_delete:
                try:
                    client.delete_production_order(str(order.id))
                    console.print(f"  [green]Deleted {order.number}[/green]")
                    deleted += 1
                except BCApiError as e:
                    console.print(f"  [red]Failed to delete {order.number}:[/red] {e.message}")
                    failed += 1

            console.print()
            if failed == 0:
                console.print(f"[green]Successfully deleted {deleted} production order(s).[/green]")
            else:
                console.print(f"[yellow]Deleted {deleted}, failed {failed} production order(s).[/yellow]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)
