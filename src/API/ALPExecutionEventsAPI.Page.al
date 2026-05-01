page 50030 "ALP Execution Events API"
{
    PageType = API;
    Caption = 'Execution Events API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'executionEvent';
    EntitySetName = 'executionEvents';
    SourceTable = "ALP Operation Execution";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = "Order No.", "Operation No.";

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(messageId; MessageIdText)
                {
                    Caption = 'Message ID';
                }
                field(sourceEventId; SourceEventIdText)
                {
                    Caption = 'Source Event Id';
                }
                field(orderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(workCenter; Rec."Work Center No.")
                {
                    Caption = 'Work Center';
                }
                field(qtyProduced; Rec."Qty. Produced")
                {
                    Caption = 'Quantity Produced';
                }
                field(qtyRejected; Rec."Qty. Rejected")
                {
                    Caption = 'Quantity Rejected';
                }
                field(runtimeSec; Rec."Runtime Sec")
                {
                    Caption = 'Runtime (Seconds)';
                }
                field(downtimeSec; Rec."Downtime Sec")
                {
                    Caption = 'Downtime (Seconds)';
                }
                field(availability; Rec.Availability)
                {
                    Caption = 'Availability';
                }
                field(productivity; Rec.Productivity)
                {
                    Caption = 'Productivity';
                }
                field(actualCycleTimeSec; Rec."Actual Cycle Time Sec")
                {
                    Caption = 'Actual Cycle Time (Seconds)';
                }
                field(sourceTimestamp; Rec."Source Timestamp")
                {
                    Caption = 'Source Timestamp';
                }
                field(source; Rec.Source)
                {
                    Caption = 'Source';
                }
                field(eventType; EventTypeText)
                {
                    Caption = 'Event Type';
                }
                field(operatorId; OperatorIdCode)
                {
                    Caption = 'Operator Id';
                }
                field(shiftCode; ShiftCodeValue)
                {
                    Caption = 'Shift Code';
                }
            }
        }
    }

    var
        IngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageIdText: Text[50];
        SourceEventIdText: Text[50];
        EventTypeText: Text[20];
        OperatorIdCode: Code[20];
        ShiftCodeValue: Code[10];
        InvalidMessageIdErr: Label 'Invalid messageId format. Expected a valid GUID, or provide sourceEventId without messageId.', Comment = 'Error when API receives malformed GUID';
        ProcessingFailedErr: Label 'Failed to process execution event. Check Integration Inbox for details.', Comment = 'Error when event processing fails';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        MessageGuid: Guid;
    begin
        if MessageIdText <> '' then begin
            if not Evaluate(MessageGuid, MessageIdText) then
                Error(InvalidMessageIdErr);
        end else
            if SourceEventIdText <> '' then
                MessageGuid := CreateGuid()
            else
                Error(InvalidMessageIdErr);

        if not IngestionSvc.ProcessExecutionEvent(Rec, MessageGuid, EventTypeText, OperatorIdCode, ShiftCodeValue, SourceEventIdText) then
            Error(ProcessingFailedErr);

        exit(false); // We handle the insert in the codeunit
    end;
}
