# Execution app contract (UNS Bridge Connector 2.0)

UNS Bridge Connector 2.0 is the Business Central side of the PREKIT Execution app.
The Execution app's BC adapter (alpamayo-chocolate-2, `erp-bridge`, `ERP_KIND=businesscentral`)
reads the order book from these API pages and writes the operator's execution facts back.

Base URL (SaaS):

```
https://api.businesscentral.dynamics.com/v2.0/{tenant}/{environment}/api/alpamayo/shopfloor/v1.0/companies({companyId})/
```

On-prem/container: `http(s)://{host}:{odataPort}/{instance}/api/alpamayo/shopfloor/v1.0/companies({companyId})/`.

All DateTime values are UTC (ISO 8601, `Z`). Business Central has no site time zone to read.

## Errors

| HTTP | Meaning | Adapter reaction |
|---|---|---|
| 201 / 200 / 204 | Accepted (including an idempotent repeat) | Done |
| 400 | Business Central refused the data (validation, posting error). Body: `{"error":{"code","message"}}` | Permanent refusal: log and skip |
| 401 | Token expired | Re-authenticate, retry |
| 404 | Entity not found | Permanent refusal |
| 409 / 412 | Concurrency conflict | Retry |
| 429 / 5xx | Throttled / unavailable | Retry with backoff |

## Step id

A step is one released production order routing line. Its id is

```
stepId = "{prodOrderNo}:{routingReferenceNo}:{operationNo}"     e.g. "101001:10000:10"
```

`stepId` keeps its value when the order is Finished (same order no.). Every write takes `stepId`.
`stepId` is computed, so it cannot be used in `$filter`: filter on `prodOrderNo`, `routingReferenceNo`
and `operationNo` instead.

## Read: order book

### `productionOrders` (existing, extended)

Filter with `$filter=status eq 'Released'` for open orders and
`$filter=status eq 'Finished' and finishedDate ge 2026-10-21` for recently closed ones.

| Field | Type | Notes |
|---|---|---|
| `id` | GUID | SystemId |
| `status` | enum | `Released`, `Finished`, ... |
| `number` | Code[20] | Order id |
| `description` | Text | Product name on the order |
| `sourceType` | enum | `Item`, `Family`, `Sales Header` |
| `sourceNo` | Code[20] | Item no. when `sourceType` = `Item` |
| `itemNo` | Code[20] | Item of the first order line (product) |
| `customerOrderNo` | Code[20] | Sales order no. when `sourceType` = `Sales Header`, else empty |
| `quantity` | Decimal | |
| `dueDate` | Date | |
| `startingDateTime`, `endingDateTime` | DateTime | Planned |
| `finishedDate` | Date | Set when Finished |
| `held` | Boolean | Order is on hold (no new execution) |
| `systemCreatedAt`, `systemModifiedAt` | DateTime | Delta reads: `systemModifiedAt ge ...` |

### `prodOrderRoutingLines` (existing, extended)

Filter `$filter=status eq 'Released'` (optionally `and prodOrderNo eq '...'`).

| Field | Type | Notes |
|---|---|---|
| `id` | GUID | SystemId |
| `stepId` | Text | See above |
| `status`, `prodOrderNo`, `routingReferenceNo`, `routingNo`, `operationNo` | | Key |
| `sequenceNo` | Integer | 1-based position within the order line's routing, by operation no. |
| `previousOperationNo`, `nextOperationNo` | Code | Parallel routings separate several with `|` |
| `type` | enum | `Work Center` or `Machine Center` |
| `no` | Code[20] | Work or machine center no. (the ERP "place") |
| `workCenterNo`, `workCenterGroupCode` | Code | Alternatives: machine centers of the same work center, or work centers of the same group |
| `description` | Text | Operation name |
| `setupTime`, `runTime`, `waitTime`, `moveTime`, `inputQuantity` | Decimal | Raw BC values |
| `plannedMinutes` | Decimal | Setup + run x input quantity, in minutes |
| `routingStatus` | enum | `Planned`, `In Progress`, `Finished` (BC standard) |
| `startingDateTime`, `endingDateTime` | DateTime | BC planned dates |
| `executionFinished` | Boolean | The Execution app finished this step |
| `executionFinishedAt` | DateTime | |
| `outputQuantity`, `scrapQuantity` | Decimal | Reported by the Execution app |
| `plannedStart`, `plannedEnd` | DateTime | Fine plan written by the Execution app |
| `queuePosition` | Integer | Fine plan order at the station |
| `systemModifiedAt` | DateTime | |

A step is done when `executionFinished` is true or `routingStatus` is `Finished`.

Places are named by number only. Work centers and machine centers should not share numbers; the adapter
cannot tell them apart in the PREKIT element mapping.

### `machineCenters` (new, read-only)

`id, number, name, workCenterNo, blocked, capacity, efficiency`.

### `workCenters`, `items`, `prodOrderComponents`, `routings`, `workShifts`, `shopCalendars`, `shopCalendarWorkingDays`

Unchanged from 1.x (`items`: `number, description, itemCategoryCode, baseUnitOfMeasure, ...`). Employees come from the standard API (`/api/v2.0/companies({id})/employees`, `number` = the Employee No. that PREKIT identities carry as `employee_id`).

## Write

Every write is a POST of one command row. Each carries an idempotency key; a repeat with the same key
returns 201 with `result = "Duplicate"` and changes nothing.

### `stepFinishes`

Finish a step, also before earlier operations are done: the shop floor reports what happened (a shift lead
may start a later step first, and the app closes the earlier ones without a finish). When **ALP Shopfloor Setup → Post Output** is on, posts an output journal line
(output, scrap, setup and run time, `Finished` = yes) so the routing line's status becomes Finished.
With Post Output off, the step is recorded on the routing line only.

| Field | Type | Req. | Notes |
|---|---|---|---|
| `eventId` | Text[100] | yes | Idempotency key (Execution app event id) |
| `stepId` | Text[100] | yes | |
| `ranOnType` | Text | no | `Work Center` / `Machine Center`; with `ranOnNo`, moves the step first when it ran elsewhere |
| `ranOnNo` | Code[20] | no | |
| `startedAt` | DateTime | no | First machine/person start |
| `finishedAt` | DateTime | yes | |
| `setupMinutes` | Decimal | no | |
| `runMinutes` | Decimal | no | Machine run time |
| `outputQuantity` | Decimal | yes | Good quantity, >= 0 |
| `scrapQuantity` | Decimal | no | |
| `scrapCode` | Code[10] | no | Must exist in Scrap codes |
| `employeeNo` | Code[20] | no | Who finished it |
| `result` | Text | read | `Recorded`, `Posted`, `Duplicate` |
| `itemLedgerEntryNo` / `capacityLedgerEntryNo` | Integer | read | When posted |

### `personTimes`

Person time on a step (the ERPNext Timesheet analogue). One row per time slice. Rows with the same
`sessionId` and a different `sessionKey` supersede the earlier rows of that session. A row with
`cancelled = true` cancels every row of the session.

| Field | Type | Req. | Notes |
|---|---|---|---|
| `eventId` | Text[100] | yes | `{sessionKey}:{sliceNo}` |
| `sessionId` | Text[50] | yes | |
| `sessionKey` | Text[100] | yes | Revision key of the session |
| `employeeNo` | Code[20] | yes when not cancelled | Must exist |
| `stepId` | Text[100] | no | |
| `workPlaceType`, `workPlaceNo` | | no | Where the person worked |
| `startedAt`, `endedAt` | DateTime | yes when not cancelled | |
| `cancelled` | Boolean | no | |
| `status` | Text | read | `Active`, `Superseded`, `Cancelled` |

A cancel needs only `eventId`, `sessionId` and `cancelled = true`. GET `personTimes?$filter=sessionId eq '...'`
returns the rows of a session (with `eventId`, `sessionKey`, `status`).

### `orderNotes`

A note on a released production order. It appears in the Notes FactBox of the order.

POST `noteId, orderNo, text (<= 2048), author`. To remove it, GET `orderNotes?$filter=noteId eq '...'`
and DELETE `orderNotes({id})` for every row returned (`id` is the row's SystemId). A repeat POST with the
same `noteId` adds a row with `result = "Duplicate"` and no second note.

### `stepMoves`

Move a not-yet-started step to another work or machine center.

POST `eventId, stepId, toType, toNo`. Refused (400) when the step has output or is finished.
The move validates the routing line's new center the standard way, so Business Central recalculates the
order's dates exactly as when a planner changes the center by hand (its Due Date can move with them). The
operation keeps its description.

### `stepPlans`

Fine plan. PATCH `stepPlans({id})` (routing line SystemId) with `plannedStart, plannedEnd, queuePosition`.
These are execution-side plan fields; they do not reschedule the BC production order.

## Hold

`held` is set in Business Central on the Released Production Order (actions **Hold** / **Release Hold**).
