"""Main CLI definition using Click."""

import click
from rich.console import Console

from .commands.events import post_event
from .commands.inbox import get_inbox
from .commands.mappings import (
    create_mapping,
    delete_mapping,
    get_mapping,
    get_mappings,
    update_mapping,
)
from .commands.orders import get_components, get_items, get_order, get_orders, get_routing, get_routings, get_work_centers
from .commands.setup import setup

console = Console()


@click.group()
@click.version_option(package_name="bridge")
def cli():
    """Bridge Emulator CLI for Business Central Shopfloor API.

    Simulates the shopfloor bridge's API interactions with BC.
    """
    pass


@cli.command()
def auth():
    """Get and display OAuth token status."""
    from .config import get_token_from_az_cli

    try:
        console.print("[dim]Fetching token from Azure CLI...[/dim]")
        token = get_token_from_az_cli()
        if token:
            console.print("[green]Authenticated successfully[/green]")
            console.print(f"Token preview: {token[:20]}...{token[-10:]}")
        else:
            console.print("[red]Failed to get token[/red]")
            console.print("Run 'az login' first, then retry.")
            raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@cli.command()
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def companies(json_out: bool):
    """List available companies in the BC environment."""
    import json
    from rich.table import Table

    from .client import BCClient, BCApiError
    from .config import get_config_with_token

    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print("[dim]Fetching companies...[/dim]")

            result = client.get_companies()

            if json_out:
                console.print_json(json.dumps(result))
            elif not result:
                console.print("[yellow]No companies found.[/yellow]")
            else:
                table = Table(title="Available Companies")
                table.add_column("ID", style="dim")
                table.add_column("Name", style="cyan")
                table.add_column("Display Name", style="green")

                for company in result:
                    table.add_row(
                        company.get("id", "-"),
                        company.get("name", "-"),
                        company.get("displayName", "-"),
                    )

                console.print(table)
                console.print()
                console.print("[dim]Set BC_COMPANY in .env to use a company ID[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@cli.command()
def config():
    """Show current configuration."""
    from .config import find_project_root, load_config

    try:
        cfg = load_config()
        console.print("[bold]Configuration[/bold]")
        console.print(f"  Tenant:  {cfg.bc_tenant}")
        console.print(f"  Env:     {cfg.bc_env}")
        console.print(f"  Company: {cfg.bc_company}")
        console.print()
        console.print(f"[dim]Loaded from: {find_project_root() / '.env'}[/dim]")
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


# Register commands
cli.add_command(post_event)
cli.add_command(get_orders)
cli.add_command(get_order)
cli.add_command(get_routing)
cli.add_command(get_components)
cli.add_command(get_routings)
cli.add_command(get_work_centers)
cli.add_command(get_items)
cli.add_command(get_inbox)
cli.add_command(setup)

# Mapping commands
cli.add_command(get_mappings)
cli.add_command(get_mapping)
cli.add_command(create_mapping)
cli.add_command(update_mapping)
cli.add_command(delete_mapping)
