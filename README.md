# ShopfloorExecutionBridge

A Dynamics 365 Business Central AL extension that provides a read-only bridge for aggregated shopfloor execution KPIs.

## Overview

This extension ingests aggregated shopfloor execution metrics via REST API, stores them safely with idempotency guarantees, and displays them in read-only pages within Business Central.

## Features

- REST API endpoint for KPI ingestion
- Idempotent API with out-of-order protection
- Read-only list and card pages for KPI viewing
- Granularity at Production Order Line level

## Object ID Range

This extension uses object IDs **50000-50099**.

## Technical Details

| Property | Value |
|----------|-------|
| Platform | 25.0.0.0 (BC 2024 Wave 2) |
| Runtime | 14.0 |
| Target | Cloud (SaaS) |

## Development

### Prerequisites

- Visual Studio Code
- AL Language extension (`ms-dynamics-smb.al`)
- Business Central sandbox environment

### Getting Started

1. Open the project folder in VS Code
2. Press `Ctrl+Shift+P` and run "AL: Download Symbols"
3. Configure your sandbox in `.vscode/launch.json`
4. Press `F5` to publish and debug

### Building

Press `Ctrl+Shift+B` and select "AL: Package" to build the `.app` file.

## Project Structure

```
d365_uns_app/
├── app.json              # Extension manifest
├── src/                  # AL source files
│   ├── Table/           # Table objects
│   ├── Page/            # Page objects
│   ├── Codeunit/        # Codeunit objects
│   └── API/             # API pages
├── .vscode/             # VS Code configuration
└── README.md            # This file
```

## Constraints

- No posting logic
- No cost calculation
- No MES business logic
- No real-time processing
- Read-only display only
