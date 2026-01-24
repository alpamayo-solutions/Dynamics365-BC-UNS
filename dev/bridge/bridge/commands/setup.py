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
    """Create test work centers in BC."""
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
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@setup.command("prod-order")
@click.option("--item", "-i", "item_no", help="Item number for the production order")
@click.option("--quantity", "-q", type=float, default=100, help="Quantity to produce")
@click.option("--description", "-d", help="Order description")
def setup_prod_order(item_no: str | None, quantity: float, description: str | None):
    """Create a production order with routing."""
    try:
        config = get_config_with_token()

        if not item_no:
            item_no = click.prompt("Item number", default="TEST-001")

        if not description:
            description = f"Test production order for {item_no}"

        with BCClient(config) as client:
            # Check if item exists
            existing_item = client.get_item(item_no)
            if not existing_item:
                console.print(f"[yellow]Item {item_no} not found. Create it first with 'bridge setup items'.[/yellow]")
                raise SystemExit(1)

            console.print(f"[dim]Creating production order for {item_no}...[/dim]")

            order = CreateProductionOrder(
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
            console.print()
            console.print("[dim]Note: Use BC client to add routing and release the order.[/dim]")

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
