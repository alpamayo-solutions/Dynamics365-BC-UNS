codeunit 50013 "ALP Work Log Svc"
{
    procedure CreateWorkLogEntry(MessageId: Text[50]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; ItemNo: Code[20]; ShiftCode: Code[10]; EventType: Enum "ALP Work Log Event Type"; DisruptionCode: Code[20]; StartTime: DateTime; Source: Text[50])
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
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
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        DurationMs: BigInteger;
    begin
        WorkLogEntry.SetRange("Order No.", OrderNo);
        WorkLogEntry.SetRange("Operation No.", OperationNo);
        WorkLogEntry.SetRange("Event Type", EventType);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Open);
        if not WorkLogEntry.FindLast() then
            exit;

        WorkLogEntry."End Time" := EndTime;

        // Compute duration in seconds
        DurationMs := EndTime - WorkLogEntry."Start Time";
        if DurationMs > 0 then
            WorkLogEntry."Duration Sec" := DurationMs div 1000
        else
            WorkLogEntry."Duration Sec" := 0;

        WorkLogEntry.Status := WorkLogEntry.Status::Closed;
        WorkLogEntry.Modify(true);
    end;
}
