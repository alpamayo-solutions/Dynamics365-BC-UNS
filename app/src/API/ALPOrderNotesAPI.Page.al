/// <summary>POST / DELETE operator notes on a released production order. See docs/execution-app-contract.md.</summary>
page 50113 "ALP Order Notes API"
{
    PageType = API;
    Caption = 'Order Notes API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'orderNote';
    EntitySetName = 'orderNotes';
    SourceTable = "ALP Order Note";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(noteId; Rec."Note Id")
                {
                    Caption = 'Note Id';
                }
                field(orderNo; Rec."Prod. Order No.")
                {
                    Caption = 'Order No.';
                }
                field(text; Rec."Note Text")
                {
                    Caption = 'Text';
                }
                field(author; Rec.Author)
                {
                    Caption = 'Author';
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        OrderNoteSvc: Codeunit "ALP Order Note Svc";
    begin
        OrderNoteSvc.Process(Rec);
        exit(true);
    end;
}
