/// <summary>POST a step finish. See docs/execution-app-contract.md.</summary>
page 50111 "ALP Step Finishes API"
{
    PageType = API;
    Caption = 'Step Finishes API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'stepFinish';
    EntitySetName = 'stepFinishes';
    SourceTable = "ALP Step Finish";
    ODataKeyFields = SystemId;
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
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(eventId; Rec."Event Id")
                {
                    Caption = 'Event Id';
                }
                field(stepId; Rec."Step Id")
                {
                    Caption = 'Step Id';
                }
                field(ranOnType; Rec."Ran On Type")
                {
                    Caption = 'Ran On Type';
                }
                field(ranOnNo; Rec."Ran On No.")
                {
                    Caption = 'Ran On No.';
                }
                field(startedAt; Rec."Started At")
                {
                    Caption = 'Started At';
                }
                field(finishedAt; Rec."Finished At")
                {
                    Caption = 'Finished At';
                }
                field(setupMinutes; Rec."Setup Minutes")
                {
                    Caption = 'Setup Minutes';
                }
                field(runMinutes; Rec."Run Minutes")
                {
                    Caption = 'Run Minutes';
                }
                field(outputQuantity; Rec."Output Quantity")
                {
                    Caption = 'Output Quantity';
                }
                field(scrapQuantity; Rec."Scrap Quantity")
                {
                    Caption = 'Scrap Quantity';
                }
                field(scrapCode; Rec."Scrap Code")
                {
                    Caption = 'Scrap Code';
                }
                field(employeeNo; Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(prodOrderNo; Rec."Prod. Order No.")
                {
                    Caption = 'Prod. Order No.';
                    Editable = false;
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                    Editable = false;
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                    Editable = false;
                }
                field(itemLedgerEntryNo; Rec."Item Ledger Entry No.")
                {
                    Caption = 'Item Ledger Entry No.';
                    Editable = false;
                }
                field(capacityLedgerEntryNo; Rec."Capacity Ledger Entry No.")
                {
                    Caption = 'Capacity Ledger Entry No.';
                    Editable = false;
                }
                field(receivedAt; Rec."Received At")
                {
                    Caption = 'Received At';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        StepFinishSvc: Codeunit "ALP Step Finish Svc";
    begin
        StepFinishSvc.Process(Rec);
        exit(true);
    end;
}
