page 50034 "ALP Prod Order Components API"
{
    PageType = API;
    Caption = 'Production Order Components API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'prodOrderComponent';
    EntitySetName = 'prodOrderComponents';
    SourceTable = "Prod. Order Component";
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
                field(prodOrderLineNo; Rec."Prod. Order Line No.")
                {
                    Caption = 'Prod. Order Line No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(quantityPer; Rec."Quantity per")
                {
                    Caption = 'Quantity Per';
                }
                field(expectedQuantity; Rec."Expected Quantity")
                {
                    Caption = 'Expected Quantity';
                }
                field(remainingQuantity; Rec."Remaining Quantity")
                {
                    Caption = 'Remaining Quantity';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(flushingMethod; Rec."Flushing Method")
                {
                    Caption = 'Flushing Method';
                }
                field(routingLinkCode; Rec."Routing Link Code")
                {
                    Caption = 'Routing Link Code';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
            }
        }
    }
}
