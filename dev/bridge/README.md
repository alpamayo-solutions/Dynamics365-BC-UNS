# Bridge Emulator CLI

A Python CLI that emulates the shopfloor bridge's interactions with the Business Central ERP API. The bridge subscribes to MQTT events from shopfloor systems and aggregates them before posting to BC. This CLI skips the MQTT/aggregation logic but provides commands to simulate the bridge's API interactions.

## Installation

```bash
# From project root
cd dev/bridge
uv pip install -e .

# Or with pip
pip install -e dev/bridge

# Or run directly with uv
uv run --directory dev/bridge bridge --help
```

## Prerequisites

1. Azure CLI installed and logged in: `az login`
2. `.env` file in project root with:
   ```
   BC_TENANT=your-tenant-id
   BC_ENV=Sandbox
   BC_COMPANY=your-company-id
   ```
3. **ShopfloorExecutionBridge extension deployed to BC** (required for `post-event` and `setup work-centers`)
   - Open project in VS Code
   - Press F5 to deploy to BC Sandbox

## Commands

### Authentication & Discovery

```bash
# Verify authentication works (fetches token from Azure CLI)
bridge auth

# Show current configuration
bridge config

# List available companies (useful for finding BC_COMPANY value)
bridge companies
```

The CLI automatically fetches an OAuth token from Azure CLI when needed. If you get 401 errors, run `az login` to refresh your Azure session.

### Query Production Orders

```bash
# List released production orders
bridge get-orders

# Filter by status
bridge get-orders --status Planned

# Filter by item (client-side)
bridge get-orders --item TEST-001

# Output as JSON
bridge get-orders --json-output

# Get routing lines for an order
bridge get-routing RPO-00001
```

### Post Execution Events

```bash
# Interactive prompts
bridge post-event

# With arguments
bridge post-event --order RPO-00001 --operation 10 --qty-produced 100 --qty-rejected 5

# With more options
bridge post-event \
  --order RPO-00001 \
  --operation 10 \
  --work-center WC-001 \
  --qty-produced 100 \
  --qty-rejected 5 \
  --runtime 3600 \
  --downtime 300 \
  --availability 0.92 \
  --productivity 0.85

# From JSON file
bridge post-event --file event.json
```

Example `event.json`:
```json
{
  "orderNo": "RPO-00001",
  "operationNo": "10",
  "workCenter": "WC-001",
  "qtyProduced": 100,
  "qtyRejected": 5,
  "runtimeSec": 3600,
  "downtimeSec": 300,
  "availability": 0.92,
  "productivity": 0.85,
  "actualCycleTimeSec": 36.0
}
```

### Setup Production Orders

The Cronus sandbox already has items (with BOMs/routings) and work centers. Use `setup prod-order` to create production orders from existing items.

```bash
# Create a released production order (item must have BOM/routing)
bridge setup prod-order --item SP-BOM2000 --quantity 100
bridge setup prod-order --item SP-BOM2000 --quantity 100 --due-date 2026-01-26

# Create demo orders (3 released + 2 planned, uses existing items)
bridge setup demo
bridge setup demo --released 5 --planned 3

# Cleanup - delete production orders (sandbox only!)
bridge setup cleanup
bridge setup cleanup --status Released  # Only delete released orders
```

## Verification

1. **Auth check**: `bridge auth` should print "Authenticated successfully"
2. **List orders**: `bridge get-orders` should list released production orders (or show none)
3. **Setup data**: `bridge setup all` should create test items and work centers
4. **Post event**: `bridge post-event --order <order-no>` should return success

## API Endpoints Used

**Standard BC API** (`/api/v2.0/`):
| Action | Method | Endpoint |
|--------|--------|----------|
| List companies | GET | `/api/v2.0/companies` |
| Create/get items | GET/POST | `/api/v2.0/companies({id})/items` |

**Custom API** (`/api/alpamayo/shopfloor/v1.0/`) - requires extension:
| Action | Method | Endpoint |
|--------|--------|----------|
| List/create production orders | GET/POST | `.../productionOrders` |
| Get routing lines | GET | `.../prodOrderRoutingLines` |
| List/create work centers | GET/POST | `.../workCenters` |
| Post execution event | POST | `.../executionEvents` |

Note: Microsoft's standard API doesn't expose manufacturing entities (production orders, work centers, routing). The extension provides custom API pages for these.

## Development

```bash
# Run from source
python -m bridge --help

# Run with uv
uv run bridge --help
```
