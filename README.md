# ShopfloorExecutionBridge

A Dynamics 365 Business Central AL extension that provides a read-only bridge for aggregated shopfloor execution KPIs.

## Overview

This extension ingests aggregated shopfloor execution metrics via REST API, stores them safely with idempotency guarantees, and displays them in read-only pages within Business Central.

```
┌─────────────────┐     REST API      ┌──────────────────────────────────────┐
│  MES / SCADA    │ ──────────────►   │  Business Central                    │
│  Shopfloor Sys  │   POST /events    │  ┌─────────────────────────────────┐ │
└─────────────────┘                   │  │ ALP Integration Inbox           │ │
                                      │  │ (idempotency + audit trail)     │ │
                                      │  └───────────────┬─────────────────┘ │
                                      │                  │                   │
                                      │                  ▼                   │
                                      │  ┌─────────────────────────────────┐ │
                                      │  │ ALP Operation Execution         │ │
                                      │  │ (KPI storage w/ OOO protection) │ │
                                      │  └───────────────┬─────────────────┘ │
                                      │                  │                   │
                                      │                  ▼                   │
                                      │  ┌─────────────────────────────────┐ │
                                      │  │ Production Order / Routing Line │ │
                                      │  │ (summary fields, read-only)     │ │
                                      │  └─────────────────────────────────┘ │
                                      └──────────────────────────────────────┘
```

## Features

- REST API endpoint for KPI ingestion
- Idempotent API with message-level deduplication
- Out-of-order protection via source timestamps
- Integration inbox for audit trail and troubleshooting
- Read-only pages for KPI viewing
- Granularity at Production Order Operation level

## Scope and Non-Goals

### In Scope
- Receiving aggregated KPIs from external systems
- Storing execution metrics safely
- Displaying metrics in BC UI (read-only)
- Idempotency and out-of-order handling

### Out of Scope (Non-Goals)
- Posting journal entries or transactions
- Cost calculations or variance analysis
- MES business logic or scheduling
- Real-time data streaming
- Bi-directional sync

## Object ID Allocation

| ID | Type | Name |
|----|------|------|
| 50000 | Enum | ALP Integration Status |
| 50001 | Table | ALP Integration Inbox |
| 50002 | Table | ALP Operation Execution |
| 50003 | TableExt | ALP Production Order Ext |
| 50004 | TableExt | ALP Prod Order Rtng Line Ext |
| 50010 | Codeunit | ALP Execution Ingestion Svc |
| 50020 | Page | ALP Integration Inbox List |
| 50021 | PageExt | ALP Production Order Ext |
| 50022 | PageExt | ALP Prod Order Rtng Lines Ext |
| 50030 | API Page | ALP Execution Events API |
| 50040 | PermissionSet | ALP Shopfloor API |
| 50041 | PermissionSet | ALP Shopfloor Reader |

## Technical Details

| Property | Value |
|----------|-------|
| Platform | 26.0 (BC 2025 Wave 1) |
| Runtime | 14.0 |
| Target | Cloud (SaaS) |

## API Reference

### Endpoint

```
POST /api/alpamayo/shopfloor/v1.0/companies({companyId})/executionEvents
```

### Authentication

OAuth 2.0 Bearer token with `https://api.businesscentral.dynamics.com` resource.

### Request Body

```json
{
  "messageId": "11111111-1111-1111-1111-111111111111",
  "orderNo": "101001",
  "operationNo": "10",
  "workCenter": "MACH0001",
  "nParts": 100,
  "nRejected": 5,
  "runtimeSec": 3600,
  "downtimeSec": 300,
  "availability": 0.92,
  "productivity": 0.85,
  "actualCycleTimeSec": 36.5,
  "sourceTimestamp": "2024-01-24T10:30:00Z",
  "source": "MES-SCADA"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| messageId | GUID | Yes | Unique message ID for idempotency |
| orderNo | Code[20] | Yes | Production Order number |
| operationNo | Code[10] | Yes | Operation number in routing |
| workCenter | Code[20] | No | Work Center code |
| nParts | Integer | No | Total parts produced |
| nRejected | Integer | No | Rejected parts (must be <= nParts) |
| runtimeSec | Decimal | No | Runtime in seconds |
| downtimeSec | Decimal | No | Downtime in seconds |
| availability | Decimal | No | Availability ratio (0-1) |
| productivity | Decimal | No | Productivity ratio (0-1) |
| actualCycleTimeSec | Decimal | No | Actual cycle time in seconds |
| sourceTimestamp | DateTime | Yes | Timestamp from source system |
| source | Code[20] | No | Source system identifier |

### Response

- **200 OK**: Message processed successfully (or already processed)
- **400 Bad Request**: Validation failed (check error message)

## Test Harness

### Prerequisites

```bash
# Get OAuth token using Azure CLI
az login
ACCESS_TOKEN=$(az account get-access-token --resource https://api.businesscentral.dynamics.com --query accessToken -o tsv)

# Set environment variables
BC_TENANT="your-tenant-id"
BC_ENV="Sandbox"
BC_COMPANY="your-company-id"
```

### 1. Normal Insert

```bash
curl -X POST "https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/alpamayo/shopfloor/v1.0/companies(${BC_COMPANY})/executionEvents" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "messageId": "11111111-1111-1111-1111-111111111111",
    "orderNo": "101001",
    "operationNo": "10",
    "workCenter": "MACH0001",
    "nParts": 100,
    "nRejected": 5,
    "runtimeSec": 3600,
    "downtimeSec": 300,
    "availability": 0.92,
    "productivity": 0.85,
    "actualCycleTimeSec": 36.5,
    "sourceTimestamp": "2024-01-24T10:30:00Z",
    "source": "MES-SCADA"
  }'
```

### 2. Idempotency Test (Duplicate messageId)

Run the same command again. Should return 200 OK without creating duplicate records.

### 3. Out-of-Order Test (Older Timestamp)

```bash
curl -X POST "https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/alpamayo/shopfloor/v1.0/companies(${BC_COMPANY})/executionEvents" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "messageId": "22222222-2222-2222-2222-222222222222",
    "orderNo": "101001",
    "operationNo": "10",
    "workCenter": "MACH0001",
    "nParts": 90,
    "sourceTimestamp": "2024-01-24T09:00:00Z",
    "source": "MES-SCADA"
  }'
```

Should return 200 OK but NOT update the execution record (older timestamp skipped).

### 4. Invalid Availability (> 1)

```bash
curl -X POST "https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/alpamayo/shopfloor/v1.0/companies(${BC_COMPANY})/executionEvents" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "messageId": "33333333-3333-3333-3333-333333333333",
    "orderNo": "101001",
    "operationNo": "10",
    "availability": 1.5,
    "sourceTimestamp": "2024-01-24T11:00:00Z"
  }'
```

Should return 400 Bad Request.

### 5. Rejected > Parts

```bash
curl -X POST "https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/alpamayo/shopfloor/v1.0/companies(${BC_COMPANY})/executionEvents" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "messageId": "44444444-4444-4444-4444-444444444444",
    "orderNo": "101001",
    "operationNo": "10",
    "nParts": 10,
    "nRejected": 20,
    "sourceTimestamp": "2024-01-24T11:00:00Z"
  }'
```

Should return 400 Bad Request.

### 6. Non-Existent Production Order

```bash
curl -X POST "https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/alpamayo/shopfloor/v1.0/companies(${BC_COMPANY})/executionEvents" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "messageId": "55555555-5555-5555-5555-555555555555",
    "orderNo": "NONEXISTENT",
    "operationNo": "10",
    "sourceTimestamp": "2024-01-24T11:00:00Z"
  }'
```

Should return 400 Bad Request.

## Development

### Prerequisites

- Visual Studio Code
- AL Language extension (`ms-dynamics-smb.al`)
- Business Central sandbox environment

### Getting Started

1. Open the project folder in VS Code
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows) and run "AL: Download Symbols"
3. Configure your sandbox in `.vscode/launch.json`
4. Press `F5` to publish and debug

### Building

Press `Cmd+Shift+B` (Mac) or `Ctrl+Shift+B` (Windows) and select "AL: Package" to build the `.app` file.

### Debugging

1. Set breakpoints in `ALPExecutionIngestionSvc.Codeunit.al`
2. Press `F5` to deploy to sandbox
3. Send test API requests via curl or Postman
4. Breakpoints will trigger in VS Code

## Project Structure

```
d365_uns_app/
├── app.json                    # Extension manifest
├── src/
│   ├── Table/
│   │   ├── ALPIntegrationStatus.Enum.al
│   │   ├── ALPIntegrationInbox.Table.al
│   │   ├── ALPOperationExecution.Table.al
│   │   ├── ALPProductionOrderExt.TableExt.al
│   │   ├── ALPProdOrderRtngLineExt.TableExt.al
│   │   ├── ALPShopfloorAPI.PermissionSet.al
│   │   └── ALPShopfloorReader.PermissionSet.al
│   ├── Codeunit/
│   │   └── ALPExecutionIngestionSvc.Codeunit.al
│   ├── Page/
│   │   ├── ALPIntegrationInboxList.Page.al
│   │   ├── ALPProductionOrderPageExt.PageExt.al
│   │   └── ALPProdOrderRtngLinesPageExt.PageExt.al
│   └── API/
│       └── ALPExecutionEventsAPI.Page.al
├── .vscode/                    # VS Code configuration
├── LICENSE                     # MIT License
└── README.md                   # This file
```

## Permission Sets

| Permission Set | Purpose | Grants |
|----------------|---------|--------|
| ALP Shopfloor API | Integration users | Full CRUD on tables, Execute on API |
| ALP Shopfloor Reader | Planners/viewers | Read-only on tables |

## License

MIT License - see [LICENSE](LICENSE) file.
