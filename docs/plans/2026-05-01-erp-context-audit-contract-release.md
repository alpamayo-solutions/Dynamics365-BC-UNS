# ERP Context Audit Contract Release Implementation Plan

**Goal:** Release a BC extension version that owns ERP execution audit intervals cleanly, accepts source event IDs used by the UNS/UI, and keeps current-state KPI protection separate from historical work-log audit semantics.

**Architecture:** `/executionEvents` remains the ingestion/current-state API backed by `ALP Operation Execution`, but it also becomes the canonical creator/closer of `ALP Work Log Entry` intervals. Current-state tables keep out-of-order protection; work-log audit intervals are processed idempotently from source event IDs regardless of whether the event timestamp is older than the current-state row. Corrections continue to invalidate and replace/cancel work-log intervals instead of editing or deleting history.

**Tech Stack:** Dynamics 365 Business Central AL, BC API pages, AL test codeunits in `Dynamics365-BC-UNS-Tests`, GitHub Actions BCContainerHelper build/test/release flow.

---

## File Structure

- Modify `src/Table/ALPIntegrationInbox.Table.al`: add source-event ID tracking and a lookup key so ingestion can be idempotent by UNS/UI event ID without changing the existing GUID primary key.
- Modify `src/API/ALPIntegrationInboxAPI.Page.al`: expose the source-event ID and warning fields for deterministic verification.
- Modify `src/API/ALPExecutionEventsAPI.Page.al`: add `sourceEventId`, optionally keep `messageId` for backward compatibility, and pass the source-event ID into ingestion.
- Modify `src/Codeunit/ALPExecutionIngestionSvc.Codeunit.al`: derive a stable audit event ID, decouple work-log processing from current-state timestamp guards, and avoid regressing current-state fields on post-hoc events.
- Modify `src/Codeunit/ALPWorkLogSvc.Codeunit.al`: add source-ID based idempotent create/close helpers and close the open interval whose start time belongs to the end timestamp instead of blindly closing the latest open interval.
- Modify `src/Table/ALPWorkLogEntry.Table.al`: tighten keys for source IDs and correction IDs; keep audit statuses unchanged.
- Modify `src/Table/ALPExecutionCorrection.Table.al`: enforce correction ID lookup/idempotency semantics through service tests, with table keys left compatible.
- Modify `src/Codeunit/ALPExecutionCorrectionSvc.Codeunit.al`: keep current correction behavior, add tests for target resolution against work logs produced by `/executionEvents`, and make correction duplicate handling explicit.
- Modify `README.md`: document that `/executionEvents` is ingestion/current-state plus canonical work-log creation, while `/workLogEntries` is the audit/read model and not the normal bridge write path.
- Modify `app.json`: bump to `1.3.0.0` when cutting the release, or let the release workflow set this from tag `v1.3.0`.
- Modify test repo `~/projects/d365_uns_app_test/ALPWorkLogTests.Codeunit.al`: add work-log contract tests.
- Modify test repo `~/projects/d365_uns_app_test/ALPExecutionIngestionTests.Codeunit.al`: add current-state/out-of-order tests.
- Modify test repo `~/projects/d365_uns_app_test/app.json`: update dependency version to the release candidate version before running CI release validation if the build workflow does not override it.

## Task 1: Source Event ID Contract

**Files:**

- Modify: `src/Table/ALPIntegrationInbox.Table.al`
- Modify: `src/API/ALPIntegrationInboxAPI.Page.al`
- Modify: `src/API/ALPExecutionEventsAPI.Page.al`
- Test: `~/projects/d365_uns_app_test/ALPWorkLogTests.Codeunit.al`

- [ ] **Step 1: Write a failing AL test for source event IDs on work-log intervals**

Add this test to `ALPWorkLogTests.Codeunit.al`:

```al
[Test]
procedure ExecutionEvents_UseSourceEventIdsForWorkLogStartAndEnd()
var
    ProductionOrder: Record "Production Order";
    ALPWorkLogEntry: Record "ALP Work Log Entry";
    ExecStart: Record "ALP Operation Execution";
    ExecEnd: Record "ALP Operation Execution";
    ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
    StartMessageId: Guid;
    EndMessageId: Guid;
    OperationNo: Code[10];
    StartTime: DateTime;
    EndTime: DateTime;
begin
    Initialize();
    CreateReleasedProductionOrderWithRouting(ProductionOrder, OperationNo);

    StartMessageId := CreateGuid();
    EndMessageId := CreateGuid();
    StartTime := CurrentDateTime - 3600000;
    EndTime := CurrentDateTime - 1800000;

    ExecStart := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 0, 0, 0, 0, StartTime);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(ExecStart, StartMessageId, 'Start', 'OP-001', 'F', 'uns-start-001');

    ExecEnd := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 10, 0, 0.9, 0.8, EndTime);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(ExecEnd, EndMessageId, 'End', 'OP-001', 'F', 'uns-stop-001');

    ALPWorkLogEntry.SetRange("Order No.", ProductionOrder."No.");
    ALPWorkLogEntry.SetRange("Operation No.", OperationNo);
    Assert.RecordCount(ALPWorkLogEntry, 1);
    ALPWorkLogEntry.FindFirst();
    Assert.AreEqual('uns-start-001', ALPWorkLogEntry."Message Id", 'Start source event id should be stored as work-log Message Id');
    Assert.AreEqual('uns-stop-001', ALPWorkLogEntry."End Message Id", 'End source event id should be stored as work-log End Message Id');
end;
```

- [ ] **Step 2: Run the test and verify it fails**

Run in the GitHub Actions workflow or local BCContainerHelper flow:

```powershell
Run-TestsInBcContainer -containerName bcbuild -credential $credential -testCodeunit 50094 -XUnitResultFileName "C:\src\TestResults.xml"
```

Expected: compile or test failure because `ProcessExecutionEvent(..., SourceEventId)` does not exist yet.

- [ ] **Step 3: Add `Source Event Id` to the inbox**

Add fields and keys:

```al
field(10; "Source Event Id"; Text[50])
{
    Caption = 'Source Event Id';
    DataClassification = SystemMetadata;
}
```

```al
key(SourceEventId; "Source Event Id")
{
}
key(SourceEventStatus; "Source Event Id", Status)
{
}
```

- [ ] **Step 4: Expose `sourceEventId` in the inbox API**

Add to `ALPIntegrationInboxAPI.Page.al`:

```al
field(sourceEventId; Rec."Source Event Id")
{
    Caption = 'Source Event Id';
}
field(warning; Rec.Warning)
{
    Caption = 'Warning';
}
```

- [ ] **Step 5: Extend `/executionEvents` API variables**

Add to `ALPExecutionEventsAPI.Page.al`:

```al
field(sourceEventId; SourceEventIdText)
{
    Caption = 'Source Event Id';
}
```

Add variable:

```al
SourceEventIdText: Text[50];
```

Pass the value into ingestion:

```al
if not IngestionSvc.ProcessExecutionEvent(Rec, MessageGuid, EventTypeText, OperatorIdCode, ShiftCodeValue, SourceEventIdText) then
    Error(ProcessingFailedErr);
```

- [ ] **Step 6: Add the overload without breaking existing callers**

In `ALPExecutionIngestionSvc.Codeunit.al`, keep the existing overloads and forward them:

```al
procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid; EventType: Text[20]; OperatorId: Code[20]; ShiftCode: Code[10]): Boolean
begin
    exit(ProcessExecutionEvent(Exec, MessageId, EventType, OperatorId, ShiftCode, ''));
end;
```

Add the new overload:

```al
procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid; EventType: Text[20]; OperatorId: Code[20]; ShiftCode: Code[10]; SourceEventId: Text[50]): Boolean
```

Inside it, derive:

```al
SourceEventId := CopyStr(DelChr(SourceEventId, '<>', ' '), 1, MaxStrLen(SourceEventId));
if SourceEventId = '' then
    SourceEventId := CopyStr(Format(MessageId), 1, MaxStrLen(SourceEventId));
```

- [ ] **Step 7: Use source event ID for work-log start/end**

Change start/disruption-start calls from `Format(MessageId)` to `SourceEventId`, and end/disruption-end calls from `Format(MessageId)` to `SourceEventId`.

- [ ] **Step 8: Run the focused tests**

Run:

```powershell
Run-TestsInBcContainer -containerName bcbuild -credential $credential -testCodeunit 50094 -XUnitResultFileName "C:\src\TestResults.xml"
```

Expected: `ExecutionEvents_UseSourceEventIdsForWorkLogStartAndEnd` passes and existing work-log tests still pass.

## Task 2: Idempotency by Source Event ID

**Files:**

- Modify: `src/Codeunit/ALPExecutionIngestionSvc.Codeunit.al`
- Modify: `src/Codeunit/ALPWorkLogSvc.Codeunit.al`
- Test: `~/projects/d365_uns_app_test/ALPWorkLogTests.Codeunit.al`

- [ ] **Step 1: Write the duplicate source-event test**

Add:

```al
[Test]
procedure Idempotency_DuplicateSourceStartEvent_CreatesOneInboxAndOneWorkLog()
var
    ProductionOrder: Record "Production Order";
    ALPWorkLogEntry: Record "ALP Work Log Entry";
    ALPIntegrationInbox: Record "ALP Integration Inbox";
    Exec: Record "ALP Operation Execution";
    ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
    MessageId1: Guid;
    MessageId2: Guid;
    OperationNo: Code[10];
begin
    Initialize();
    CreateReleasedProductionOrderWithRouting(ProductionOrder, OperationNo);

    MessageId1 := CreateGuid();
    MessageId2 := CreateGuid();
    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 0, 0, 0, 0, CurrentDateTime);

    Assert.IsTrue(ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId1, 'Start', 'OP-001', 'F', 'uns-start-dupe'), 'First source event should process');
    Assert.IsTrue(ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId2, 'Start', 'OP-001', 'F', 'uns-start-dupe'), 'Duplicate source event should be idempotent');

    ALPWorkLogEntry.SetRange("Message Id", 'uns-start-dupe');
    Assert.RecordCount(ALPWorkLogEntry, 1);

    ALPIntegrationInbox.SetRange("Source Event Id", 'uns-start-dupe');
    Assert.RecordCount(ALPIntegrationInbox, 1);
end;
```

- [ ] **Step 2: Run it and verify it fails**

Expected: two inbox rows or an unsupported overload before implementation.

- [ ] **Step 3: Add inbox lookup by source event ID before GUID lookup**

At the top of the new ingestion overload:

```al
if SourceEventId <> '' then begin
    Inbox.SetRange("Source Event Id", SourceEventId);
    if Inbox.FindFirst() then
        if Inbox.Status = Inbox.Status::Processed then
            exit(true);
    Inbox.Reset();
end;

if Inbox.Get(MessageId) then
    if Inbox.Status = Inbox.Status::Processed then
        exit(true);
```

When inserting a new inbox record, store `Inbox."Source Event Id" := SourceEventId;`.

- [ ] **Step 4: Keep work-log create idempotent**

Retain the existing `WorkLogEntry.SetRange("Message Id", MessageId)` guard. Add a guard for blank source IDs:

```al
if MessageId = '' then
    Error('Work log Message Id is required');
```

- [ ] **Step 5: Run focused tests**

Expected: duplicate source ID returns true and creates exactly one inbox/work-log pair.

## Task 3: Separate Audit Work Logs from Current-State Timestamp Guards

**Files:**

- Modify: `src/Codeunit/ALPExecutionIngestionSvc.Codeunit.al`
- Modify: `src/Codeunit/ALPWorkLogSvc.Codeunit.al`
- Test: `~/projects/d365_uns_app_test/ALPExecutionIngestionTests.Codeunit.al`
- Test: `~/projects/d365_uns_app_test/ALPWorkLogTests.Codeunit.al`

- [ ] **Step 1: Write the post-hoc-after-current failing test**

Add to `ALPWorkLogTests.Codeunit.al`:

```al
[Test]
procedure PostHocEnd_ClosesHistoricalWorkLogWhenCurrentStateIsNewer()
var
    ProductionOrder: Record "Production Order";
    ALPWorkLogEntry: Record "ALP Work Log Entry";
    ALPOperationExecution: Record "ALP Operation Execution";
    Exec: Record "ALP Operation Execution";
    ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
    OperationNo: Code[10];
    CurrentStart: DateTime;
    CurrentEnd: DateTime;
    HistoricalStart: DateTime;
    HistoricalEnd: DateTime;
begin
    Initialize();
    CreateReleasedProductionOrderWithRouting(ProductionOrder, OperationNo);

    CurrentStart := CurrentDateTime - 3600000;
    CurrentEnd := CurrentDateTime - 1800000;
    HistoricalStart := CurrentDateTime - 7200000;
    HistoricalEnd := CurrentDateTime - 5400000;

    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 0, 0, 0, 0, CurrentStart);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, CreateGuid(), 'Start', 'OP-001', 'F', 'current-start');
    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 10, 0, 0.9, 0.8, CurrentEnd);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, CreateGuid(), 'End', 'OP-001', 'F', 'current-end');

    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 0, 0, 0, 0, HistoricalStart);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, CreateGuid(), 'Start', 'OP-001', 'F', 'historical-start');
    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 5, 0, 0.9, 0.8, HistoricalEnd);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, CreateGuid(), 'End', 'OP-001', 'F', 'historical-end');

    ALPWorkLogEntry.SetRange("Message Id", 'historical-start');
    ALPWorkLogEntry.FindFirst();
    Assert.AreEqual(ALPWorkLogEntry.Status::Closed, ALPWorkLogEntry.Status, 'Historical interval should close even when current-state timestamp is newer');
    Assert.AreEqual('historical-end', ALPWorkLogEntry."End Message Id", 'Historical end source event id should be stored');

    ALPOperationExecution.Get(ProductionOrder."No.", OperationNo);
    Assert.AreEqual(CurrentEnd, ALPOperationExecution."Source Timestamp", 'Current-state execution timestamp must not regress');
end;
```

- [ ] **Step 2: Run it and verify it fails**

Expected: historical work log remains open because `IngestEndEvent` exits before `CloseWorkLogEntryWithEndMessageId`.

- [ ] **Step 3: Move work-log close before the stale current-state exit**

In `IngestEndEvent`, close the audit interval before returning for stale current-state updates:

```al
WorkLogSvc.CloseWorkLogEntryWithEndMessageId(Exec."Order No.", Exec."Operation No.", WorkLogEventType::Execution, Exec."Source Timestamp", SourceEventId);

IsNew := not ExistingExec.Get(Exec."Order No.", Exec."Operation No.");
if not IsNew then
    if ExistingExec."Source Timestamp" >= Exec."Source Timestamp" then
        exit;
```

Update the local procedure signature to accept `SourceEventId: Text[50]`.

- [ ] **Step 4: Prevent start events from regressing current-state fields**

In `IngestStartEvent`, only update `ALP Operation Execution` and Production Order current-state metadata when the record is new or the incoming timestamp is newer:

```al
IsNew := not ExistingExec.Get(Exec."Order No.", Exec."Operation No.");
if IsNew or (ExistingExec."Source Timestamp" < Exec."Source Timestamp") then begin
    Exec."Started At" := Exec."Source Timestamp";
    Exec."Operator Id" := OperatorId;
    Exec."Last Update At" := CurrentDateTime();
    if IsNew then
        Exec.Insert(true)
    else begin
        ExistingExec."Started At" := Exec."Source Timestamp";
        ExistingExec."Operator Id" := OperatorId;
        ExistingExec."Last Update At" := CurrentDateTime();
        ExistingExec.Modify(true);
    end;

    ProdOrder."ALP Last Exec Update At" := CurrentDateTime();
    ProdOrder."ALP Execution Source" := Exec.Source;
    ProdOrder.Modify(true);
end;
```

The work-log creation remains outside this current-state guard.

- [ ] **Step 5: Close the interval nearest to the end timestamp**

In `ALPWorkLogSvc.CloseWorkLogEntryWithEndMessageId`, add a start-time filter before `FindLast()`:

```al
WorkLogEntry.SetFilter("Start Time", '..%1', EndTime);
```

This avoids closing a newer open interval when a historical end event arrives post-hoc.

- [ ] **Step 6: Run focused tests**

Expected: the new post-hoc test passes, and existing out-of-order KPI tests still show current-state protection.

## Task 4: Correction Targeting Against ExecutionEvents-Created Work Logs

**Files:**

- Modify: `src/Codeunit/ALPExecutionCorrectionSvc.Codeunit.al`
- Modify: `src/Codeunit/ALPWorkLogSvc.Codeunit.al`
- Test: `~/projects/d365_uns_app_test/ALPWorkLogTests.Codeunit.al`

- [ ] **Step 1: Write a correction test using `/executionEvents` source IDs**

Add:

```al
[Test]
procedure Correction_TargetsExecutionEventSourceIds()
var
    ProductionOrder: Record "Production Order";
    ALPWorkLogEntry: Record "ALP Work Log Entry";
    Correction: Record "ALP Execution Correction";
    Exec: Record "ALP Operation Execution";
    ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
    CorrectionSvc: Codeunit "ALP Execution Correction Svc";
    OperationNo: Code[10];
    OriginalEntryNo: Integer;
begin
    Initialize();
    CreateReleasedProductionOrderWithRouting(ProductionOrder, OperationNo);

    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 0, 0, 0, 0, CurrentDateTime - 3600000);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, CreateGuid(), 'Start', 'OP-001', 'F', 'source-start-correction');
    Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 10, 0, 0.9, 0.8, CurrentDateTime - 1800000);
    ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, CreateGuid(), 'End', 'OP-001', 'F', 'source-end-correction');

    ALPWorkLogEntry.SetRange("Message Id", 'source-start-correction');
    ALPWorkLogEntry.FindFirst();
    OriginalEntryNo := ALPWorkLogEntry."Entry No.";

    Correction.Init();
    Correction."Correction Id" := 'correction-source-ids';
    Correction.Action := 'cancel_event';
    Correction."Target Event Ids" := 'source-end-correction';
    Correction."Requested By" := 'alice.admin';
    Correction."Requested At" := CurrentDateTime;
    Correction."Order No." := ProductionOrder."No.";
    Correction."Operation No." := OperationNo;
    Correction."Event Type" := 'Execution';

    Assert.IsTrue(CorrectionSvc.ProcessCorrection(Correction), 'Correction should resolve executionEvents-created source IDs');

    ALPWorkLogEntry.Reset();
    ALPWorkLogEntry.Get(OriginalEntryNo);
    Assert.AreEqual(ALPWorkLogEntry.Status::Cancelled, ALPWorkLogEntry.Status, 'Original should be cancelled');
    Assert.AreEqual('correction-source-ids', ALPWorkLogEntry."Invalidated By Correction Id", 'Correction id should be linked');
end;
```

- [ ] **Step 2: Run it**

Expected after Tasks 1-3: pass. If it fails, fix `ResolveTargetWorkLog` only; do not add correction-specific duplicate work-log paths.

- [ ] **Step 3: Add correction idempotency test**

Add a test that calls `CorrectionSvc.ProcessCorrection(Correction)` twice with the same `Correction Id` and asserts one `ALP Execution Correction` row and one replacement/cancel effect.

- [ ] **Step 4: Preserve existing correction action behavior**

Keep `replace_interval`, `cancel_event`, `change_metadata`, and `insert_missing_event` semantics:

- `cancel_event`: original row status becomes `Cancelled`.
- `replace_interval`: original row status becomes `Superseded`; replacement row has new interval.
- `change_metadata`: original row status becomes `Superseded`; replacement row keeps original interval.
- `insert_missing_event`: no original row; correction-backed row is created with `Message Id = Correction Id`.

## Task 5: Read Model and Documentation Cleanup

**Files:**

- Modify: `README.md`
- Modify: `src/API/ALPIntegrationInboxAPI.Page.al`
- Modify: `src/API/ALPWorkLogEntriesAPI.Page.al`

- [ ] **Step 1: Update the API contract table**

Document these `/executionEvents` fields:

```text
messageId       GUID     Optional for compatibility when sourceEventId is supplied; request/inbox correlation ID.
sourceEventId   Text[50] Recommended; UNS/UI event ID used for idempotency and work-log correction targeting.
eventType       Text[20] Start, End, DisruptionStart, DisruptionEnd. Empty defaults to End for legacy KPI ingestion.
operatorId      Code[20] Optional; copied to work-log interval.
shiftCode       Code[10] Optional; copied to work-log interval.
```

- [ ] **Step 2: State the canonical ownership rule**

Add a section:

```md
For normal bridge ingestion, `/executionEvents` is the only write endpoint. It creates and closes `ALP Work Log Entry` audit intervals as part of processing. `/workLogEntries` is the read model for interval/audit verification and remains writable only for controlled diagnostics or compatibility; the bridge must not post a second normal execution interval there.
```

- [ ] **Step 3: Clarify current-state versus audit tables**

Document:

- `ALP Operation Execution` is keyed by order/operation and stores latest current-state/KPI values.
- `ALP Work Log Entry` stores immutable-ish time-bounded audit intervals and correction links.
- Older source timestamps must not update current state, but they must still create/close audit intervals.

- [ ] **Step 4: Update example payloads**

Show a start:

```json
{
  "sourceEventId": "uns-start-001",
  "eventType": "Start",
  "orderNo": "101001",
  "workCenter": "K5",
  "operatorId": "OP-001",
  "shiftCode": "F",
  "sourceTimestamp": "2026-05-01T08:00:00Z",
  "source": "PREKIT"
}
```

Show an end:

```json
{
  "sourceEventId": "uns-stop-001",
  "eventType": "End",
  "orderNo": "101001",
  "workCenter": "K5",
  "qtyProduced": 100,
  "qtyRejected": 0,
  "availability": 0.92,
  "productivity": 0.85,
  "sourceTimestamp": "2026-05-01T09:00:00Z",
  "source": "PREKIT"
}
```

## Task 6: Test App and CI Release Validation

**Files:**

- Modify: `~/projects/d365_uns_app_test/app.json`
- Modify: `~/projects/d365_uns_app/.github/workflows/build.yml` only if the test dependency version is not handled by the workflow.

- [ ] **Step 1: Run formatting/compile through CI**

Push a branch and let `build.yml` compile the main app, compile the test app, publish both, and run all AL tests.

Expected: `Build AL App` succeeds and publishes `TestResults.xml`.

- [ ] **Step 2: If test dependency version blocks compilation, update test app dependency**

Set dependency version:

```json
{
  "id": "dbbe7042-978c-461f-abe3-5ce36a97d621",
  "name": "UNS Bridge Connector",
  "publisher": "alpamayo",
  "version": "1.3.0.0"
}
```

- [ ] **Step 3: Run the full AL test suite**

Run all test codeunits:

```powershell
Run-TestsInBcContainer -containerName bcbuild -credential $credential -XUnitResultFileName "C:\src\TestResults.xml"
```

Expected: all ingestion, work-log, correction, permission, install, and mapping tests pass.

## Task 7: Release and Bridge Compatibility

**Files:**

- Modify: `app.json`
- Modify: `README.md`
- Coordinate with: `~/projects/prekit/merz-benteli/erp-bridge`

- [ ] **Step 1: Bump or tag the release**

Preferred release: tag `v1.3.0`; release workflow updates `app.json` to `1.3.0.0`.

- [ ] **Step 2: Update bridge after BC release is deployed**

Bridge follow-up after sandbox gets the new app:

- Stop direct normal writes to `/workLogEntries`.
- Send `/executionEvents.sourceEventId` with the UNS/UI event ID.
- Keep direct `/executionCorrections` posts for correction commands.
- Keep `/workLogEntries` reads for verification.

- [ ] **Step 3: Run the sandbox e2e harness**

From the Merz+Benteli sandbox after app deployment and bridge update:

```bash
docker exec -i mb-hub-test-erp-bridge-1 python - --execute --asset-id B4 --scenario all < /home/amadmin/prekit/merz-benteli/erp-bridge/scripts/erp_context_e2e.py
```

Expected:

- `start-stop` passes with exactly one BC work-log interval.
- `post-hoc` passes even after newer current-state events.
- `correction-replace`, `idempotency`, and `disruption` pass without bridge-side dual ID handling.

## Acceptance Checklist

- [ ] `/executionEvents` accepts `sourceEventId` and uses it as the work-log start/end event ID.
- [ ] Current-state `ALP Operation Execution` timestamp guards still prevent KPI regression.
- [ ] Historical/post-hoc start/end events still create and close `ALP Work Log Entry` intervals.
- [ ] Normal bridge execution no longer creates duplicate/open work logs.
- [ ] Corrections can target the source start or end event IDs produced through `/executionEvents`.
- [ ] Duplicate source event IDs are idempotent at inbox and work-log levels.
- [ ] README distinguishes current-state ingestion from audit interval read model.
- [ ] Full AL CI passes.
- [ ] Sandbox e2e `--scenario all` passes after bridge compatibility update.
