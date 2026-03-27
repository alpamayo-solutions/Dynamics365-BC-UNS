page 50036 "ALP Work Log Entries API"
{
    PageType = API;
    Caption = 'Work Log Entries API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'workLogEntry';
    EntitySetName = 'workLogEntries';
    SourceTable = "ALP Work Log Entry";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(messageId; Rec."Message Id")
                {
                    Caption = 'Message Id';
                }
                field(orderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(workCenterNo; Rec."Work Center No.")
                {
                    Caption = 'Work Center No.';
                }
                field(operatorId; Rec."Operator Id")
                {
                    Caption = 'Operator Id';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(shiftCode; Rec."Shift Code")
                {
                    Caption = 'Shift Code';
                }
                field(eventType; Rec."Event Type")
                {
                    Caption = 'Event Type';
                }
                field(disruptionCode; Rec."Disruption Code")
                {
                    Caption = 'Disruption Code';
                }
                field(startTime; Rec."Start Time")
                {
                    Caption = 'Start Time';
                }
                field(endTime; Rec."End Time")
                {
                    Caption = 'End Time';
                }
                field(durationSec; Rec."Duration Sec")
                {
                    Caption = 'Duration (Seconds)';
                }
                field(source; Rec.Source)
                {
                    Caption = 'Source';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
            }
        }
    }
}
