"""Main CLI definition using Click."""

import click
from rich.console import Console

from .commands.e2e import e2e
from .commands.execution import (
    finish,
    machine_centers,
    move,
    note,
    person_time,
    plan,
    steps,
)
from .commands.orders import (
    get_components,
    get_items,
    get_order,
    get_orders,
    get_routing,
    get_routings,
    get_work_centers,
)
from .commands.setup import setup

console = Console()


@click.group()
@click.version_option(package_name="bridge")
def cli():
    """Dev CLI for the UNS Bridge Connector 2.0 (Business Central Shopfloor API).

    Reads the order book and writes execution facts the way the PREKIT Execution app does.
    SaaS: BC_TENANT/BC_ENV + az login. On-prem/container: BC_API_BASE_URL (+ BC_USERNAME/BC_PASSWORD).
    """


@cli.command()
def auth():
    """Get and display OAuth token status."""
    from .config import get_token_from_az_cli, load_config

    try:
        cfg = load_config()
        if not cfg.is_saas:
            mode = f"basic auth as {cfg.username}" if cfg.username else "no credentials"
            console.print(f"On-prem/container mode ({cfg.api_root}), {mode}; no token needed.")
            return
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

    from .client import BCApiError, BCClient
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
                console.print("[dim]Set BC_COMPANY (id) or BC_COMPANY_NAME (name) in .env[/dim]")

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
        console.print(f"  Target:  {cfg.display_target}")
        console.print(f"  API:     {cfg.api_root}")
        if not cfg.is_saas:
            console.print(f"  User:    {cfg.username or '-'}")
        console.print(f"  Company: {cfg.bc_company or '(by name) ' + str(cfg.bc_company_name)}")
        console.print()
        console.print(f"[dim]Loaded from: {find_project_root() / '.env'}[/dim]")
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


# Register commands
for command in (
    get_orders,
    get_order,
    get_routing,
    get_components,
    get_routings,
    get_work_centers,
    get_items,
    setup,
    steps,
    machine_centers,
    finish,
    person_time,
    note,
    move,
    plan,
    e2e,
):
    cli.add_command(command)
