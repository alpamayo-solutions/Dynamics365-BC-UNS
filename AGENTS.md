# AGENTS.md - ShopfloorExecutionBridge

## Project Context

This is a D365 Business Central AL extension that bridges shopfloor execution systems with Business Central by:
1. Ingesting aggregated KPIs via REST API
2. Storing them with idempotency and out-of-order protection
3. Displaying them read-only in BC pages

## Key Constraints

- **No posting**: This extension never posts transactions
- **No cost calculation**: Cost logic belongs in MES/ERP core
- **No MES logic**: Pure data bridge, no business rules
- **No real-time**: Designed for aggregated/batch data
- **Read-only UI**: Display only, no user edits
- **Upgrade-safe**: Standard AL extension patterns only

## Object ID Allocation

| Range | Purpose |
|-------|---------|
| 50000-50009 | Tables |
| 50010-50019 | Codeunits |
| 50020-50029 | Pages (List/Card) |
| 50030-50039 | API Pages |
| 50040-50099 | Reserved |

## AL Coding Standards

- Use `NoImplicitWith` feature
- Follow Microsoft AL best practices
- Use meaningful object names with "Shopfloor" prefix
- All tables must have proper FlowFields for lookups
- API pages use standard OData conventions

## Testing

Since this is a cloud extension, testing is done via:
1. VS Code F5 deployment to sandbox
2. Postman/curl for API endpoint testing
3. Manual UI verification in BC client
