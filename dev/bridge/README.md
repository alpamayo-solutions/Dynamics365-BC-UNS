# Bridge dev CLI

A Python CLI (and a small Streamlit GUI) for the Business Central side of the PREKIT Execution app:
the UNS Bridge Connector 2.0 API. It reads the order book and writes execution facts the way the
Execution app's BC adapter does. The field contract is in
[`docs/execution-app-contract.md`](../../docs/execution-app-contract.md).

## Installation

```bash
uv run --directory dev/bridge bridge --help
# or
uv run --directory dev/bridge python -m bridge --help
```

## Connection

Settings come from the environment or a `.env` file in the repo root.

| Mode | Variables | Auth |
|---|---|---|
| SaaS (default) | `BC_TENANT`, `BC_ENV` | Bearer token from `az account get-access-token` (run `az login` first), or `ACCESS_TOKEN` |
| On-prem / container | `BC_API_BASE_URL`, e.g. `http://bcserver:7048/BC/api` | Basic auth with `BC_USERNAME` / `BC_PASSWORD` when set (NavUserPassword) |

`BC_API_BASE_URL` wins when set. The company is `BC_COMPANY` (GUID). When it is unset,
`BC_COMPANY_NAME` is resolved through `/v2.0/companies` (exact name).

```bash
bridge config      # show the target and company
bridge auth        # SaaS: check the az token; on-prem: show the auth mode
bridge companies   # list companies (to find BC_COMPANY / BC_COMPANY_NAME)
```

The extension (`app/`) must be published to the environment.

## Read

```bash
bridge get-orders [--status Released] [--since 2026-11-01T00:00:00Z] [--with-routing]
bridge get-order 101001
bridge steps --order 101001           # stepId, routing status, execution state, output, fine plan
bridge machine-centers
bridge get-work-centers
bridge get-components 101001
bridge get-routing 101001
bridge get-items / get-routings
```

All read commands take `--json-output`.

## Write (Execution app commands)

Every write carries an idempotency key. `eventId` / `noteId` default to a new uuid4; pass
`--event-id` / `--note-id` to repeat a call (a repeat returns `result = Duplicate`). Times are UTC.

| Command | Endpoint |
|---|---|
| `bridge finish <stepId> --output N [--scrap N] [--scrap-code C] [--run-min M] [--setup-min M] [--ran-on-type "Machine Center" --ran-on-no MC1] [--employee E] [--started-at T] [--finished-at T]` | POST `stepFinishes` |
| `bridge person-time add --employee E [--step S] [--start T] [--end T] [--session-id ID] [--session-key K] [--slice N]` | POST `personTimes` (eventId defaults to `{sessionKey}:{slice}`) |
| `bridge person-time add --session-id ID --cancel` | POST `personTimes` with `cancelled = true` |
| `bridge person-time list <sessionId>` | GET `personTimes` |
| `bridge note add <orderNo> "<text>" [--author A]` / `note list <orderNo>` / `note delete <noteId>` | POST / GET / DELETE `orderNotes` |
| `bridge move <stepId> --to-type "Work Center" --to-no 200` | POST `stepMoves` |
| `bridge plan <stepId> [--start T] [--end T] [--queue N]` | PATCH `stepPlans({id})` |

`stepId` is `{prodOrderNo}:{routingReferenceNo}:{operationNo}`, e.g. `101001:10000:10`
(see `bridge steps`). A new `--session-key` for an existing `--session-id` supersedes the
session's earlier person-time rows.

Whether `finish` posts output depends on **ALP Shopfloor Setup → Post Output** in BC: off, the
step is recorded on the routing line only (`result = Recorded`); on, an output journal line is
posted (`result = Posted`).

## Smoke test against a live BC: `bridge e2e`

```bash
bridge e2e --order 101001 --yes [--employee E1] [--output 1] [--move-to 400]
```

It writes to BC, so it refuses to run without `--yes`. Use a fresh released order with at least
two routing lines. It checks, on the first order line's routing:

1. Order and step read fields exist; `machineCenters` is readable.
2. Finishing step 2 before step 1 is refused with HTTP 400.
3. Finishing step 1 returns `Recorded` or `Posted`, and the step then reads as done.
4. Re-sending the same `eventId` returns `Duplicate`.
5. Person time (only with `--employee`): a second `sessionKey` supersedes the first.
6. A note is added, read back, deleted and gone.
7. The last not-started step moves to another work center (`--move-to`, or the lowest-numbered
   other non-blocked one) and back.
8. A fine plan PATCH on step 2 reads back.

It prints a PASS / FAIL / SKIP table and exits 1 on any FAIL. Checks that need a state the order
no longer has (e.g. step 1 already finished) are SKIP; use a new order for a full run.

## Test data setup

```bash
bridge setup prod-order --item SP-BOM2000 --quantity 100 [--due-date 2026-11-30]
bridge setup demo [--released 3] [--planned 2]
bridge setup items / work-centers / all
bridge setup cleanup [--status Released] [--yes]     # sandbox only
```

## GUI

```bash
cd dev/bridge && uv run streamlit run gui/app.py
```

Read-only: work orders (create one) and the steps of an order with their execution state. Writes
go through the CLI.

## API endpoints used

Custom API `.../api/alpamayo/shopfloor/v1.0/companies({id})/`:

| Endpoint | Methods |
|---|---|
| `productionOrders` | GET, POST, PATCH, DELETE, `Microsoft.NAV.Refresh` |
| `prodOrderRoutingLines`, `prodOrderComponents`, `routings`, `items`, `machineCenters` | GET |
| `workCenters` | GET, POST |
| `stepFinishes`, `personTimes`, `stepMoves` | POST (`personTimes` also GET) |
| `orderNotes` | GET, POST, DELETE |
| `stepPlans` | PATCH |

Standard API `.../api/v2.0/`: `companies`, `companies({id})/items`, `companies({id})/employees`.
