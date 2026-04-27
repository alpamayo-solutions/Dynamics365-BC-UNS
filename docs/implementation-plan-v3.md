# Implementation Plan — BC Extension (Execution Tracking v3)

**Reference:** `/Users/alpamayo/projects/prekit/merz-benteli/erp-uns-bridge-v2/docs/concept-execution-tracking-v3.md`
**Date:** March 2026

**Main repo:** `/Users/alpamayo/projects/d365_uns_app`
**Test repo:** `/Users/alpamayo/projects/d365_uns_app_test`
**ID range:** 50000-50099

---

## 2.1 New Enum: ALP Work Log Event Type (Enum 50002)

**File:** `ALPWorkLogEventType.Enum.al`

```
enum 50002 "ALP Work Log Event Type"
{
    Extensible = false;
    value(0; Execution) { Caption = 'Execution'; }
    value(1; Disruption) { Caption = 'Disruption'; }
}
```

## 2.2 New Enum: ALP Work Log Status (Enum 50003)

**File:** `ALPWorkLogStatus.Enum.al`

```
enum 50003 "ALP Work Log Status"
{
    Extensible = false;
    value(0; Open) { Caption = 'Open'; }
    value(1; Closed) { Caption = 'Closed'; }
}
```

## 2.3 New Table: ALP Work Log Entry (Table 50006)

**File:** `ALPWorkLogEntry.Table.al`

```
table 50006 "ALP Work Log Entry"
{
    Caption = 'ALP Work Log Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Message Id"; Guid)
        {
            Caption = 'Message Id';
        }
        field(3; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(5; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
        }
        field(6; "Operator Id"; Code[20])
        {
            Caption = 'Operator Id';
        }
        field(7; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(8; "Shift Code"; Code[10])
        {
            Caption = 'Shift Code';
        }
        field(9; "Event Type"; Enum "ALP Work Log Event Type")
        {
            Caption = 'Event Type';
        }
        field(10; "Disruption Code"; Code[20])
        {
            Caption = 'Disruption Code';
        }
        field(11; "Start Time"; DateTime)
        {
            Caption = 'Start Time';
        }
        field(12; "End Time"; DateTime)
        {
            Caption = 'End Time';
        }
        field(13; "Duration Sec"; Decimal)
        {
            Caption = 'Duration (sec)';
        }
        field(14; "Source"; Code[20])
        {
            Caption = 'Source';
        }
        field(15; "Status"; Enum "ALP Work Log Status")
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(OrderOp; "Order No.", "Operation No.") { }
        key(Operator; "Operator Id") { }
        key(WorkCenter; "Work Center No.") { }
        key(Shift; "Shift Code") { }
        key(MessageId; "Message Id") { }
    }
}
```

## 2.4 Extend ALP Operation Execution (Table 50002)

**File:** `ALPOperationExecution.Table.al` (existing, add fields)

Add two new fields at the end of the `fields` block:

```
field(33; "Started At"; DateTime)
{
    Caption = 'Started At';
}
field(34; "Operator Id"; Code[20])
{
    Caption = 'Operator Id';
}
```

## 2.5 Extend ALP Execution Events API (Page 50030)

**File:** `ALPExecutionEventsAPI.Page.al` (existing)

**Current fields:** `messageId`, `orderNo`, `operationNo`, `workCenter`, `qtyProduced`, `qtyRejected`, `runtimeSec`, `downtimeSec`, `availability`, `productivity`, `sourceTimestamp`, `source`, `actualCycleTimeSec`, `operatorEfficiency`, `qualityRate`.

Add three new fields to the `layout` section (these are API-only, not bound to a table field -- they are read in the trigger):

```
field(eventType; eventType)
{
    Caption = 'eventType';
    // Text[10], transient (not stored)
}
field(operatorId; operatorId)
{
    Caption = 'operatorId';
    // Code[20], maps to Operation Execution "Operator Id"
}
field(shiftCode; shiftCode)
{
    Caption = 'shiftCode';
    // Code[10], passed through to work log
}
```

Since BC API pages for custom endpoints use a sourceTable, the cleanest approach is:
- Add `operatorId` (Code[20]) and `shiftCode` (Code[10]) as actual fields on the source table (or use the existing `ALP Operation Execution` table and add shiftCode there too).
- **Alternative (recommended):** Use `trigger OnInsertRecord()` to read the raw JSON payload fields and route accordingly, similar to how the existing endpoint handles the `messageId` field.

**OnInsertRecord trigger changes:**

Before (pseudocode):
```
trigger OnInsertRecord()
    IngestionSvc.IngestEvent(Rec);
```

After:
```
trigger OnInsertRecord()
    if Rec.eventType = 'Start' then
        IngestionSvc.IngestStartEvent(Rec.messageId, Rec.orderNo, Rec.operationNo,
            Rec.workCenter, Rec.operatorId, Rec.shiftCode, Rec.sourceTimestamp, Rec.source)
    else
        // "End" (default) — existing KPI path
        IngestionSvc.IngestEndEvent(Rec);  // existing behavior
        WorkLogSvc.CloseWorkLogEntry(Rec.messageId, EndTime);  // also close work log
```

Default value for `eventType`: `'End'` (backward compatibility -- if omitted, existing behavior).

## 2.6 New API Page: ALP Work Log Entries API (Page 50036)

**File:** `ALPWorkLogEntriesAPI.Page.al`

```
page 50036 "ALP Work Log Entries API"
{
    PageType = API;
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'workLogEntry';
    EntitySetName = 'workLogEntries';
    SourceTable = "ALP Work Log Entry";
    DelayedInsert = true;
    ODataKeyFields = "Entry No.";
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(entryNo; "Entry No.") { }
                field(messageId; "Message Id") { }
                field(orderNo; "Order No.") { }
                field(operationNo; "Operation No.") { }
                field(workCenterNo; "Work Center No.") { }
                field(operatorId; "Operator Id") { }
                field(itemNo; "Item No.") { }
                field(shiftCode; "Shift Code") { }
                field(eventType; "Event Type") { }
                field(disruptionCode; "Disruption Code") { }
                field(startTime; "Start Time") { }
                field(endTime; "End Time") { }
                field(durationSec; "Duration Sec") { }
                field(source; "Source") { }
                field(status; "Status") { }
            }
        }
    }
}
```

## 2.7 New API Pages for Shift Data

### Page 50037: ALP Work Shifts API

**File:** `ALPWorkShiftsAPI.Page.al`

```
page 50037 "ALP Work Shifts API"
{
    PageType = API;
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'workShift';
    EntitySetName = 'workShifts';
    SourceTable = "Work Shift";           // BC standard table 99000750
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(code; "Code") { }
                field(description; Description) { }
            }
        }
    }
}
```

### Page 50038: ALP Shop Calendars API

**File:** `ALPShopCalendarsAPI.Page.al`

```
page 50038 "ALP Shop Calendars API"
{
    PageType = API;
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'shopCalendar';
    EntitySetName = 'shopCalendars';
    SourceTable = "Shop Calendar";        // BC standard table 99000751
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(code; "Code") { }
                field(description; Description) { }
            }
        }
    }
}
```

### Page 50039: ALP Shop Calendar Working Days API

**File:** `ALPShopCalendarWorkingDaysAPI.Page.al`

```
page 50039 "ALP Shop Calendar Working Days API"
{
    PageType = API;
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'shopCalendarWorkingDay';
    EntitySetName = 'shopCalendarWorkingDays';
    SourceTable = "Shop Calendar Working Days"; // BC standard table 99000752
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(shopCalendarCode; "Shop Calendar Code") { }
                field(day; Day) { }
                field(workShiftCode; "Work Shift Code") { }
                field(startingTime; "Starting Time") { }
                field(endingTime; "Ending Time") { }
            }
        }
    }
}
```

## 2.8 Extend ALP Work Centers API (Page 50031)

**File:** `ALPWorkCentersAPI.Page.al` (existing)

Add one field to the `repeater(Group)` block:

```
field(shopCalendarCode; "Shop Calendar Code") { }
```

The `Shop Calendar Code` field already exists on BC's standard `Work Center` table (table 99000754, field `"Shop Calendar Code"`). It just needs to be exposed on the API page.

## 2.9 New Codeunit: ALP Work Log Service (Codeunit 50013)

**File:** `ALPWorkLogService.Codeunit.al`

```
codeunit 50013 "ALP Work Log Service"
{
    procedure CreateWorkLogEntry(
        MessageId: Guid;
        OrderNo: Code[20];
        OperationNo: Code[10];
        WorkCenterNo: Code[20];
        OperatorId: Code[20];
        ItemNo: Code[20];
        ShiftCode: Code[10];
        EventType: Enum "ALP Work Log Event Type";
        DisruptionCode: Code[20];
        StartTime: DateTime;
        Source: Code[20]
    ): Integer
    var
        WorkLog: Record "ALP Work Log Entry";
    begin
        // Idempotency: check if MessageId already exists
        WorkLog.SetRange("Message Id", MessageId);
        if WorkLog.FindFirst() then
            exit(WorkLog."Entry No.");

        WorkLog.Init();
        WorkLog."Message Id" := MessageId;
        WorkLog."Order No." := OrderNo;
        WorkLog."Operation No." := OperationNo;
        WorkLog."Work Center No." := WorkCenterNo;
        WorkLog."Operator Id" := OperatorId;
        WorkLog."Item No." := ItemNo;
        WorkLog."Shift Code" := ShiftCode;
        WorkLog."Event Type" := EventType;
        WorkLog."Disruption Code" := DisruptionCode;
        WorkLog."Start Time" := StartTime;
        WorkLog."Source" := Source;
        WorkLog."Status" := "ALP Work Log Status"::Open;
        WorkLog.Insert(true);

        exit(WorkLog."Entry No.");
    end;

    procedure CloseWorkLogEntry(OrderNo: Code[20]; OperationNo: Code[10]; EndTime: DateTime): Boolean
    var
        WorkLog: Record "ALP Work Log Entry";
        DurationSeconds: Decimal;
    begin
        // Find the latest open entry for this order+operation
        WorkLog.SetRange("Order No.", OrderNo);
        WorkLog.SetRange("Operation No.", OperationNo);
        WorkLog.SetRange("Status", "ALP Work Log Status"::Open);
        WorkLog.SetCurrentKey("Entry No.");
        if not WorkLog.FindLast() then
            exit(false);

        WorkLog."End Time" := EndTime;
        DurationSeconds := (EndTime - WorkLog."Start Time") / 1000;  // DateTime diff is in ms
        WorkLog."Duration Sec" := DurationSeconds;
        WorkLog."Status" := "ALP Work Log Status"::Closed;
        WorkLog.Modify(true);

        exit(true);
    end;
}
```

## 2.10 Update ALP Execution Ingestion Svc (Codeunit 50010)

**File:** `ALPExecutionIngestionSvc.Codeunit.al` (existing)

**Current behavior:** `IngestEvent()` validates, resolves operation, detects out-of-order, aggregates KPIs on `ALP Operation Execution`.

**Changes:**

1. Add new procedure `IngestStartEvent()`:

```
procedure IngestStartEvent(
    MessageId: Text[50];
    OrderNo: Code[20];
    OperationNo: Code[10];
    WorkCenterNo: Code[20];
    OperatorId: Code[20];
    ShiftCode: Code[10];
    SourceTimestamp: Text[30];
    Source: Code[20]
)
var
    OpExec: Record "ALP Operation Execution";
    WorkLogSvc: Codeunit "ALP Work Log Service";
    StartTime: DateTime;
begin
    // 1. Parse timestamp
    Evaluate(StartTime, SourceTimestamp);

    // 2. Resolve operation (same as existing logic, reuse _ResolveOperation)
    if OperationNo = '' then
        OperationNo := ResolveOperation(OrderNo, WorkCenterNo);

    // 3. Create/update ALP Operation Execution — set Started At
    if not OpExec.Get(OrderNo, OperationNo) then begin
        OpExec.Init();
        OpExec."Order No." := OrderNo;
        OpExec."Operation No." := OperationNo;
        OpExec."Started At" := StartTime;
        OpExec."Operator Id" := OperatorId;
        OpExec.Insert(true);
    end else begin
        if OpExec."Started At" = 0DT then  // Don't overwrite if already started
            OpExec."Started At" := StartTime;
        OpExec."Operator Id" := OperatorId;
        OpExec.Modify(true);
    end;

    // 4. Create work log entry (Execution type)
    WorkLogSvc.CreateWorkLogEntry(
        MessageId,      // GUID from bridge
        OrderNo,
        OperationNo,
        WorkCenterNo,
        OperatorId,
        '',             // ItemNo — not required on start
        ShiftCode,
        "ALP Work Log Event Type"::Execution,
        '',             // No disruption code
        StartTime,
        Source
    );

    // 5. NO KPI aggregation — this is a start event
end;
```

2. Modify existing `IngestEvent()` (the end-event path):

After the existing KPI aggregation, add:

```
// Close the corresponding work log entry
WorkLogSvc.CloseWorkLogEntry(OrderNo, OperationNo, SourceTimestamp);
```

3. Store `OperatorId` and `ShiftCode` through to the work log on end events too (pass them from the API page).

## 2.11 Tests (d365_uns_app_test)

**Repo:** `/Users/alpamayo/projects/d365_uns_app_test`

### New test codeunit: ALPWorkLogTests.Codeunit.al (50094)

| Test procedure | Description |
|---|---|
| `TestStartEventCreatesWorkLogEntry` | POST eventType=Start to executionEvents. Assert ALP Work Log Entry created with Status=Open, correct OrderNo, OperatorId, ShiftCode. |
| `TestEndEventClosesWorkLogEntry` | POST Start then End. Assert work log entry has Status=Closed, EndTime set, DurationSec > 0. |
| `TestStartEventSetsStartedAtOnOpExec` | POST eventType=Start. Assert ALP Operation Execution record has "Started At" set to the sourceTimestamp. |
| `TestIdempotencyOnWorkLog` | POST Start twice with same messageId. Assert only one work log entry exists. |
| `TestDisruptionWorkLogEntry` | POST to workLogEntries with EventType=Disruption, DisruptionCode="WARTEN". Assert entry created correctly. |
| `TestEventTypeDefaultsToEnd` | POST without eventType field. Assert existing KPI behavior (backward compat), no work log start created. |
| `TestOperatorAndShiftFieldsPersisted` | POST Start with operatorId="AJU", shiftCode="F". Assert both fields stored in work log. |

### Extend ALPExecutionIngestionTests.Codeunit.al (50090)

| Test procedure | Description |
|---|---|
| `TestStartEventSkipsKpiAggregation` | POST eventType=Start. Assert ALP Operation Execution has no KPI values aggregated. |
| `TestStartEventOperatorIdStoredOnOpExec` | POST Start with operatorId. Assert Operator Id field set on ALP Operation Execution. |

## 2.12 Permission Set Updates

**File:** `ALPShopfloorExec.PermissionSet.al` (PermissionSet 50001)

Add:
```
tabledata "ALP Work Log Entry" = RIMD;
```

**File:** `ALPShopfloorView.PermissionSet.al` (PermissionSet 50002)

Add:
```
tabledata "ALP Work Log Entry" = R;
```
