page 50032 "ALP Production Orders API"
{
    PageType = API;
    Caption = 'Production Orders API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'productionOrder';
    EntitySetName = 'productionOrders';
    SourceTable = "Production Order";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Editable = true;

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
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Source Type';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Source No.';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(endingDate; Rec."Ending Date")
                {
                    Caption = 'Ending Date';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                    Editable = false;
                }
            }
        }
    }

    var
        EnvironmentInfo: Codeunit "Environment Information";

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not EnvironmentInfo.IsSandbox() then
            Error('Production order creation via API is only allowed in Sandbox environments.');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if not EnvironmentInfo.IsSandbox() then
            Error('Production order modification via API is only allowed in Sandbox environments.');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if not EnvironmentInfo.IsSandbox() then
            Error('Production order deletion via API is only allowed in Sandbox environments.');
        exit(true);
    end;
}
