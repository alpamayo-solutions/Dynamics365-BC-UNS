codeunit 50013 "ALP Work Log Svc"
{
    var
        WorkLogMessageIdRequiredErr: Label 'Work log Message Id is required';

    procedure CreateWorkLogEntry(MessageId: Text[50]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; ItemNo: Code[20]; ShiftCode: Code[10]; EventType: Enum "ALP Work Log Event Type"; DisruptionCode: Code[20]; StartTime: DateTime; Source: Text[50])
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        if MessageId = '' then
            Error(WorkLogMessageIdRequiredErr);

        // Idempotency: skip if a work log entry with this MessageId already exists
        WorkLogEntry.SetRange("Message Id", MessageId);
        if not WorkLogEntry.IsEmpty() then
            exit;

        WorkLogEntry.Init();
        WorkLogEntry."Message Id" := MessageId;
        WorkLogEntry."Order No." := OrderNo;
        WorkLogEntry."Operation No." := OperationNo;
        WorkLogEntry."Work Center No." := WorkCenterNo;
        WorkLogEntry."Operator Id" := OperatorId;
        WorkLogEntry."Item No." := ItemNo;
        WorkLogEntry."Shift Code" := ShiftCode;
        WorkLogEntry."Event Type" := EventType;
        WorkLogEntry."Disruption Code" := DisruptionCode;
        WorkLogEntry."Start Time" := StartTime;
        WorkLogEntry.Source := Source;
        WorkLogEntry.Status := WorkLogEntry.Status::Open;
        WorkLogEntry.Insert(true);
    end;

    procedure CloseWorkLogEntry(OrderNo: Code[20]; OperationNo: Code[10]; EventType: Enum "ALP Work Log Event Type"; EndTime: DateTime)
    begin
        CloseWorkLogEntryWithEndMessageId(OrderNo, OperationNo, EventType, EndTime, '');
    end;

    procedure CloseWorkLogEntryWithEndMessageId(OrderNo: Code[20]; OperationNo: Code[10]; EventType: Enum "ALP Work Log Event Type"; EndTime: DateTime; EndMessageId: Text[50])
    begin
        CloseOneOpenWorkLogEntry(OrderNo, OperationNo, '', '', EventType, EndTime, EndMessageId, '');
    end;

    procedure CloseOneOpenWorkLogEntry(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; EventType: Enum "ALP Work Log Event Type"; EndTime: DateTime; EndMessageId: Text[50]; SourceStartEventId: Text[50]): Boolean
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        CandidateCount: Integer;
    begin
        if SourceStartEventId <> '' then begin
            WorkLogEntry.SetRange("Message Id", SourceStartEventId);
            if not WorkLogEntry.FindFirst() then
                exit(false);

            if (WorkLogEntry.Status = WorkLogEntry.Status::Closed) and (WorkLogEntry."End Message Id" = EndMessageId) then
                exit(true);

            if WorkLogEntry.Status <> WorkLogEntry.Status::Open then
                exit(false);

            if not WorkLogEntryMatches(WorkLogEntry, OrderNo, OperationNo, WorkCenterNo, OperatorId, EventType) then
                exit(false);

            WorkLogEntry."End Message Id" := EndMessageId;
            ApplyEndTime(WorkLogEntry, EndTime);
            WorkLogEntry.Modify(true);
            exit(true);
        end;

        WorkLogEntry.SetCurrentKey("Order No.", "Operation No.", "Work Center No.", "Operator Id", "Event Type", Status, "Start Time");
        WorkLogEntry.SetRange("Order No.", OrderNo);
        WorkLogEntry.SetRange("Operation No.", OperationNo);
        if WorkCenterNo <> '' then
            WorkLogEntry.SetRange("Work Center No.", WorkCenterNo);
        if OperatorId <> '' then
            WorkLogEntry.SetRange("Operator Id", OperatorId);
        WorkLogEntry.SetRange("Event Type", EventType);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Open);
        if EndTime <> 0DT then
            WorkLogEntry.SetFilter("Start Time", '..%1', EndTime);

        CandidateCount := WorkLogEntry.Count();
        if CandidateCount = 0 then begin
            if EndMessageId = '' then
                exit(false);

            WorkLogEntry.Reset();
            WorkLogEntry.SetRange("End Message Id", EndMessageId);
            if WorkLogEntry.FindFirst() then
                exit(true);

            exit(false);
        end;

        if CandidateCount > 1 then
            exit(false);

        WorkLogEntry.FindLast();
        WorkLogEntry."End Message Id" := EndMessageId;
        ApplyEndTime(WorkLogEntry, EndTime);
        WorkLogEntry.Modify(true);
        exit(true);
    end;

    procedure CloseAllOpenWorkLogEntries(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; EventType: Enum "ALP Work Log Event Type"; EndTime: DateTime; EndMessageId: Text[50]): Integer
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        ClosedCount: Integer;
    begin
        WorkLogEntry.SetCurrentKey("Order No.", "Operation No.", "Work Center No.", "Event Type", Status);
        WorkLogEntry.SetRange("Order No.", OrderNo);
        WorkLogEntry.SetRange("Operation No.", OperationNo);
        if WorkCenterNo <> '' then
            WorkLogEntry.SetRange("Work Center No.", WorkCenterNo);
        WorkLogEntry.SetRange("Event Type", EventType);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Open);
        if EndTime <> 0DT then
            WorkLogEntry.SetFilter("Start Time", '..%1', EndTime);
        if not WorkLogEntry.FindSet(true) then
            exit(0);

        repeat
            WorkLogEntry."End Message Id" := EndMessageId;
            ApplyEndTime(WorkLogEntry, EndTime);
            WorkLogEntry.Modify(true);
            ClosedCount += 1;
        until WorkLogEntry.Next() = 0;

        exit(ClosedCount);
    end;

    procedure CreateClosedExecutionWorkLogEntry(MessageId: Text[50]; EndMessageId: Text[50]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; ItemNo: Code[20]; ShiftCode: Code[10]; StartTime: DateTime; EndTime: DateTime; Source: Text[50])
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        WorkLogEventType: Enum "ALP Work Log Event Type";
    begin
        if MessageId = '' then
            Error(WorkLogMessageIdRequiredErr);

        WorkLogEntry.SetRange("Message Id", MessageId);
        if WorkLogEntry.FindFirst() then begin
            if (WorkLogEntry.Status = WorkLogEntry.Status::Closed) and (WorkLogEntry."End Message Id" = EndMessageId) then
                exit;
            Error(WorkLogMessageIdRequiredErr);
        end;

        WorkLogEntry.Init();
        WorkLogEntry."Message Id" := MessageId;
        WorkLogEntry."Order No." := OrderNo;
        WorkLogEntry."Operation No." := OperationNo;
        WorkLogEntry."Work Center No." := WorkCenterNo;
        WorkLogEntry."Operator Id" := OperatorId;
        WorkLogEntry."Item No." := ItemNo;
        WorkLogEntry."Shift Code" := ShiftCode;
        WorkLogEntry."Event Type" := WorkLogEventType::Execution;
        WorkLogEntry."Start Time" := StartTime;
        WorkLogEntry.Source := Source;
        WorkLogEntry."End Message Id" := EndMessageId;
        ApplyEndTime(WorkLogEntry, EndTime);
        WorkLogEntry.Insert(true);
    end;

    procedure CreateCorrectionWorkLogEntry(MessageId: Text[50]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; ItemNo: Code[20]; ShiftCode: Code[10]; EventType: Enum "ALP Work Log Event Type"; DisruptionCode: Code[20]; StartTime: DateTime; EndTime: DateTime; Source: Text[50]; CorrectionId: Text[50]; ReplacesEntryNo: Integer): Integer
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        if MessageId = '' then
            Error(WorkLogMessageIdRequiredErr);

        WorkLogEntry.SetRange("Message Id", MessageId);
        if WorkLogEntry.FindFirst() then
            exit(WorkLogEntry."Entry No.");

        WorkLogEntry.Init();
        WorkLogEntry."Message Id" := MessageId;
        WorkLogEntry."Order No." := OrderNo;
        WorkLogEntry."Operation No." := OperationNo;
        WorkLogEntry."Work Center No." := WorkCenterNo;
        WorkLogEntry."Operator Id" := OperatorId;
        WorkLogEntry."Item No." := ItemNo;
        WorkLogEntry."Shift Code" := ShiftCode;
        WorkLogEntry."Event Type" := EventType;
        WorkLogEntry."Disruption Code" := DisruptionCode;
        WorkLogEntry."Start Time" := StartTime;
        WorkLogEntry.Source := Source;
        WorkLogEntry."Correction Id" := CorrectionId;
        WorkLogEntry."Replaces Entry No." := ReplacesEntryNo;
        ApplyEndTime(WorkLogEntry, EndTime);
        WorkLogEntry.Insert(true);
        exit(WorkLogEntry."Entry No.");
    end;

    local procedure ApplyEndTime(var WorkLogEntry: Record "ALP Work Log Entry"; EndTime: DateTime)
    var
        DurationMs: BigInteger;
    begin
        WorkLogEntry."End Time" := EndTime;
        if EndTime = 0DT then begin
            WorkLogEntry."Duration Sec" := 0;
            WorkLogEntry.Status := WorkLogEntry.Status::Open;
            exit;
        end;

        DurationMs := EndTime - WorkLogEntry."Start Time";
        if DurationMs > 0 then
            WorkLogEntry."Duration Sec" := DurationMs div 1000
        else
            WorkLogEntry."Duration Sec" := 0;

        WorkLogEntry.Status := WorkLogEntry.Status::Closed;
    end;

    local procedure WorkLogEntryMatches(var WorkLogEntry: Record "ALP Work Log Entry"; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; EventType: Enum "ALP Work Log Event Type"): Boolean
    begin
        if WorkLogEntry."Order No." <> OrderNo then
            exit(false);
        if WorkLogEntry."Operation No." <> OperationNo then
            exit(false);
        if (WorkCenterNo <> '') and (WorkLogEntry."Work Center No." <> WorkCenterNo) then
            exit(false);
        if (OperatorId <> '') and (WorkLogEntry."Operator Id" <> OperatorId) then
            exit(false);
        if WorkLogEntry."Event Type" <> EventType then
            exit(false);

        exit(true);
    end;
}
