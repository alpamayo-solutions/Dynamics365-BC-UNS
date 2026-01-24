page 50033 "ALP Prod Order Routing API"
{
    PageType = API;
    Caption = 'Production Order Routing Lines API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'prodOrderRoutingLine';
    EntitySetName = 'prodOrderRoutingLines';
    SourceTable = "Prod. Order Routing Line";
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
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(prodOrderNo; Rec."Prod. Order No.")
                {
                    Caption = 'Prod. Order No.';
                }
                field(routingReferenceNo; Rec."Routing Reference No.")
                {
                    Caption = 'Routing Reference No.';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(setupTime; Rec."Setup Time")
                {
                    Caption = 'Setup Time';
                }
                field(runTime; Rec."Run Time")
                {
                    Caption = 'Run Time';
                }
                field(waitTime; Rec."Wait Time")
                {
                    Caption = 'Wait Time';
                }
                field(moveTime; Rec."Move Time")
                {
                    Caption = 'Move Time';
                }
                field(inputQuantity; Rec."Input Quantity")
                {
                    Caption = 'Input Quantity';
                }
            }
        }
    }
}
