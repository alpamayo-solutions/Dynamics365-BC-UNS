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
bridge post-event --order RPO-00001 --operation 10 --parts 100 --rejected 5

# With more options
bridge post-event \
  --order RPO-00001 \
  --operation 10 \
  --work-center WC-001 \
  --parts 100 \
  --rejected 5 \
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
  "nParts": 100,
  "nRejected": 5,
  "runtimeSec": 3600,
  "downtimeSec": 300,
  "availability": 0.92,
  "productivity": 0.85,
  "actualCycleTimeSec": 36.0
}
```

### Setup Test Data

```bash
# Create test items
bridge setup items
bridge setup items --prefix PROD --count 5

# Create test work centers
bridge setup work-centers
bridge setup work-centers --prefix MACH --count 5

# Create a production order (requires existing item)
bridge setup prod-order --item TEST-001 --quantity 100

# Run all setup commands
bridge setup all
```

## Verification

1. **Auth check**: `bridge auth` should print "Authenticated successfully"
2. **List orders**: `bridge get-orders` should list released production orders (or show none)
3. **Setup data**: `bridge setup all` should create test items and work centers
4. **Post event**: `bridge post-event --order <order-no>` should return success

## API Endpoints Used

| Action | Method | Endpoint |
|--------|--------|----------|
| List companies | GET | `/api/v2.0/companies` |
| List prod orders | GET | `/api/v2.0/companies({id})/productionOrders` |
| Get routing lines | GET | `/api/v2.0/companies({id})/prodOrderRoutingLines` |
| Create item | POST | `/api/v2.0/companies({id})/items` |
| Create work center | POST | `/api/v2.0/companies({id})/workCenters` |
| Create prod order | POST | `/api/v2.0/companies({id})/productionOrders` |
| Post execution event | POST | `/api/alpamayo/shopfloor/v1.0/companies({id})/executionEvents` |

## Development

```bash
# Run from source
python -m bridge --help

# Run with uv
uv run bridge --help
```
