page 50044 "ALP Integration Inbox API"
{
    PageType = API;
    Caption = 'Integration Inbox API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'integrationInbox';
    EntitySetName = 'integrationInbox';
    SourceTable = "ALP Integration Inbox";
    DelayedInsert = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(messageId; Rec."Message Id")
                {
                    Caption = 'Message ID';
                }
                field(sourceEventId; Rec."Source Event Id")
                {
                    Caption = 'Source Event Id';
                }
                field(messageType; Rec."Message Type")
                {
                    Caption = 'Message Type';
                }
                field(orderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(receivedAt; Rec."Received At")
                {
                    Caption = 'Received At';
                }
                field(processedAt; Rec."Processed At")
                {
                    Caption = 'Processed At';
                }
                field(error; Rec.Error)
                {
                    Caption = 'Error';
                }
                field(warning; Rec.Warning)
                {
                    Caption = 'Warning';
                }
            }
        }
    }
}
