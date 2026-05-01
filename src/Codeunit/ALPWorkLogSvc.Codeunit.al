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
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        if EndMessageId <> '' then begin
            WorkLogEntry.SetRange("End Message Id", EndMessageId);
            if not WorkLogEntry.IsEmpty() then
                exit;
            WorkLogEntry.Reset();
        end;

        WorkLogEntry.SetCurrentKey("Order No.", "Operation No.", "Event Type", Status, "Start Time");
        WorkLogEntry.SetRange("Order No.", OrderNo);
        WorkLogEntry.SetRange("Operation No.", OperationNo);
        WorkLogEntry.SetRange("Event Type", EventType);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Open);
        if EndTime <> 0DT then
            WorkLogEntry.SetFilter("Start Time", '..%1', EndTime);
        if not WorkLogEntry.FindLast() then
            exit;

        WorkLogEntry."End Message Id" := EndMessageId;
        ApplyEndTime(WorkLogEntry, EndTime);
        WorkLogEntry.Modify(true);
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
}
