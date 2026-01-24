page 50035 "ALP Output Inbox API"
{
    PageType = API;
    Caption = 'Output Inbox API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'outputInbox';
    EntitySetName = 'outputInbox';
    SourceTable = "ALP Output Inbox";
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
                field(messageId; MessageIdText)
                {
                    Caption = 'Message ID';
                }
                field(orderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(outputQuantity; Rec."Output Quantity")
                {
                    Caption = 'Output Quantity';
                }
                field(scrapQuantity; Rec."Scrap Quantity")
                {
                    Caption = 'Scrap Quantity';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(sourceTimestamp; Rec."Source Timestamp")
                {
                    Caption = 'Source Timestamp';
                }
                field(source; Rec.Source)
                {
                    Caption = 'Source';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(receivedAt; Rec."Received At")
                {
                    Caption = 'Received At';
                    Editable = false;
                }
                field(processedAt; Rec."Processed At")
                {
                    Caption = 'Processed At';
                    Editable = false;
                }
                field(error; Rec.Error)
                {
                    Caption = 'Error';
                    Editable = false;
                }
            }
        }
    }

    var
        IngestionSvc: Codeunit "ALP Output Ingestion Svc";
        MessageIdText: Text[50];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        MessageGuid: Guid;
    begin
        if not Evaluate(MessageGuid, MessageIdText) then
            Error('Invalid messageId format. Expected a valid GUID.');

        if not IngestionSvc.ProcessOutputEvent(Rec, MessageGuid) then
            Error('Failed to process output event. Check Output Inbox for details.');

        exit(false); // We handle the insert in the codeunit
    end;
}
