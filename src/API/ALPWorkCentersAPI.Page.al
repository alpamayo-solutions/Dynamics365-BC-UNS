page 50031 "ALP Work Centers API"
{
    PageType = API;
    Caption = 'Work Centers API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'workCenter';
    EntitySetName = 'workCenters';
    SourceTable = "Work Center";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(workCenterGroupCode; Rec."Work Center Group Code")
                {
                    Caption = 'Work Center Group Code';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(capacity; Rec.Capacity)
                {
                    Caption = 'Capacity';
                }
                field(efficiency; Rec.Efficiency)
                {
                    Caption = 'Efficiency';
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                }
                field(indirectCostPercent; Rec."Indirect Cost %")
                {
                    Caption = 'Indirect Cost %';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
            }
        }
    }

    // SANDBOX-ONLY: Master data APIs restricted to sandbox environments.
    // Work centers are owned by ERP admins.
    // API creation/modification is for dev/test data setup only.
    var
        EnvironmentInfo: Codeunit "Environment Information";
        SandboxOnlyCreateErr: Label 'Work center creation is only allowed in Sandbox environments.', Comment = 'Error when trying to create work center in non-sandbox environment';
        SandboxOnlyModifyErr: Label 'Work center modification is only allowed in Sandbox environments.', Comment = 'Error when trying to modify work center in non-sandbox environment';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not EnvironmentInfo.IsSandbox() then
            Error(SandboxOnlyCreateErr);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if not EnvironmentInfo.IsSandbox() then
            Error(SandboxOnlyModifyErr);
        exit(true);
    end;
}
