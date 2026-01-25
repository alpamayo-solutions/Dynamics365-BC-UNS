"""Mapping commands for managing UNS topic to work center mappings."""

import json

import click
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from ..client import BCApiError, BCClient
from ..config import get_config_with_token
from ..models import UNSTopicMapping

console = Console()


@click.command("get-mappings")
@click.option(
    "--status",
    "-s",
    type=click.Choice(["Active", "Inactive"]),
    help="Filter by status",
)
@click.option("--top", "-n", default=100, help="Maximum number of results")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_mappings(status: str | None, top: int, json_out: bool):
    """GET UNS topic mappings from the ERP API."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print("[dim]Fetching UNS topic mappings...[/dim]")

            try:
                mappings = client.get_uns_topic_mappings(status=status, top=top)
            except BCApiError as e:
                if e.status_code == 404:
                    mappings = []
                else:
                    raise

            results = [
                {
                    "unsTopic": m.uns_topic,
                    "workCenterNo": m.work_center_no,
                    "status": m.status,
                    "description": m.description,
                    "sourceSystem": m.source_system,
                    "validFrom": m.valid_from.isoformat() if m.valid_from else None,
                    "validTo": m.valid_to.isoformat() if m.valid_to else None,
                }
                for m in mappings
            ]

            if json_out:
                console.print_json(json.dumps(results))
            elif not results:
                console.print("[yellow]No UNS topic mappings found.[/yellow]")
            else:
                table = Table(title="UNS Topic Mappings")
                table.add_column("UNS Topic", style="cyan", max_width=40)
                table.add_column("Work Center", style="green")
                table.add_column("Status")
                table.add_column("Description", max_width=30)

                for m in results:
                    status_style = "green" if m["status"] == "Active" else "dim"
                    wc_display = m["workCenterNo"] or "[yellow]—[/yellow]"
                    table.add_row(
                        m["unsTopic"],
                        wc_display,
                        f"[{status_style}]{m['status']}[/{status_style}]",
                        (m["description"] or "—")[:30],
                    )

                console.print(table)
                console.print(f"\n[dim]Found {len(results)} mapping(s)[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("get-mapping")
@click.argument("topic")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def get_mapping(topic: str, json_out: bool):
    """GET a single UNS topic mapping by topic."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Fetching mapping for '{topic}'...[/dim]")

            mapping = client.get_uns_topic_mapping(topic)

            if not mapping:
                console.print(f"[yellow]No mapping found for topic '{topic}'[/yellow]")
                raise SystemExit(1)

            result = {
                "unsTopic": mapping.uns_topic,
                "workCenterNo": mapping.work_center_no,
                "status": mapping.status,
                "description": mapping.description,
                "sourceSystem": mapping.source_system,
                "validFrom": mapping.valid_from.isoformat() if mapping.valid_from else None,
                "validTo": mapping.valid_to.isoformat() if mapping.valid_to else None,
                "createdAt": mapping.created_at.isoformat() if mapping.created_at else None,
                "createdBy": mapping.created_by,
            }

            if json_out:
                console.print_json(json.dumps(result))
            else:
                panel_content = (
                    f"[bold]UNS Topic:[/bold] {result['unsTopic']}\n"
                    f"[bold]Work Center:[/bold] {result['workCenterNo'] or '—'}\n"
                    f"[bold]Status:[/bold] {result['status']}\n"
                    f"[bold]Description:[/bold] {result['description'] or '—'}\n"
                    f"[bold]Source System:[/bold] {result['sourceSystem'] or '—'}\n"
                    f"[bold]Valid From:[/bold] {result['validFrom'] or '—'}\n"
                    f"[bold]Valid To:[/bold] {result['validTo'] or '—'}\n"
                    f"[bold]Created At:[/bold] {result['createdAt'] or '—'}\n"
                    f"[bold]Created By:[/bold] {result['createdBy'] or '—'}"
                )
                console.print(Panel(panel_content, title="UNS Topic Mapping"))

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("create-mapping")
@click.option("--topic", "-t", required=True, help="UNS topic path")
@click.option("--description", "-d", help="Description")
@click.option("--source-system", help="Source system identifier")
@click.option("--status", "-s", default="Active", type=click.Choice(["Active", "Inactive"]))
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def create_mapping(
    topic: str,
    description: str | None,
    source_system: str | None,
    status: str,
    json_out: bool,
):
    """Register a new UNS topic. Work center mapping is done in ERP."""
    try:
        config = get_config_with_token()

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Registering topic '{topic}'...[/dim]")

            mapping = UNSTopicMapping(
                uns_topic=topic,
                work_center_no=None,
                description=description,
                source_system=source_system,
                status=status,
            )

            result = client.create_uns_topic_mapping(mapping)

            if json_out:
                console.print_json(json.dumps(result))
            else:
                console.print(f"[green]Registered topic '{topic}'[/green]")
                console.print(f"  Status: {status}")
                console.print(f"  [dim]Map to work center in Business Central[/dim]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("update-mapping")
@click.argument("topic")
@click.option("--description", "-d", help="New description")
@click.option("--status", "-s", type=click.Choice(["Active", "Inactive"]), help="New status")
@click.option("--json-output", "json_out", is_flag=True, help="Output as JSON")
def update_mapping(
    topic: str,
    description: str | None,
    status: str | None,
    json_out: bool,
):
    """Update an existing UNS topic. Work center mapping is done in ERP."""
    try:
        config = get_config_with_token()

        # Build updates dict with only provided values
        updates: dict[str, str] = {}
        if description is not None:
            updates["description"] = description
        if status is not None:
            updates["status"] = status

        if not updates:
            console.print("[yellow]No updates provided. Use --description or --status.[/yellow]")
            raise SystemExit(1)

        with BCClient(config) as client:
            if not json_out:
                console.print(f"[dim]Updating mapping for topic '{topic}'...[/dim]")

            result = client.update_uns_topic_mapping(topic, updates)

            if json_out:
                console.print_json(json.dumps(result))
            else:
                console.print(f"[green]Updated mapping for topic '{topic}'[/green]")
                for key, value in updates.items():
                    console.print(f"  {key}: {value}")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)


@click.command("delete-mapping")
@click.argument("topic")
@click.option("--yes", "-y", is_flag=True, help="Skip confirmation")
def delete_mapping(topic: str, yes: bool):
    """Delete a UNS topic mapping."""
    try:
        config = get_config_with_token()

        if not yes:
            if not click.confirm(f"Delete mapping for topic '{topic}'?"):
                console.print("[dim]Cancelled.[/dim]")
                return

        with BCClient(config) as client:
            console.print(f"[dim]Deleting mapping for topic '{topic}'...[/dim]")

            client.delete_uns_topic_mapping(topic)

            console.print(f"[green]Deleted mapping for topic '{topic}'[/green]")

    except BCApiError as e:
        console.print(f"[red]API Error ({e.status_code}):[/red] {e.message}")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)
