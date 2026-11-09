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
    Editable = false;
    ODataKeyFields = SystemId;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(stepId; StepId)
                {
                    Caption = 'Step Id';
                }
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
                field(routingNo; Rec."Routing No.")
                {
                    Caption = 'Routing No.';
                }
                field(sequenceNo; SequenceNo)
                {
                    Caption = 'Sequence No.';
                }
                field(previousOperationNo; Rec."Previous Operation No.")
                {
                    Caption = 'Previous Operation No.';
                }
                field(nextOperationNo; Rec."Next Operation No.")
                {
                    Caption = 'Next Operation No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(workCenterNo; Rec."Work Center No.")
                {
                    Caption = 'Work Center No.';
                }
                field(workCenterGroupCode; Rec."Work Center Group Code")
                {
                    Caption = 'Work Center Group Code';
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
                field(plannedMinutes; PlannedMinutes)
                {
                    Caption = 'Planned Minutes';
                }
                field(routingStatus; Rec."Routing Status")
                {
                    Caption = 'Routing Status';
                }
                field(startingDateTime; Rec."Starting Date-Time")
                {
                    Caption = 'Starting Date-Time';
                }
                field(endingDateTime; Rec."Ending Date-Time")
                {
                    Caption = 'Ending Date-Time';
                }
                field(executionFinished; Rec."ALP Exec. Finished")
                {
                    Caption = 'Execution Finished';
                }
                field(executionFinishedAt; Rec."ALP Exec. Finished At")
                {
                    Caption = 'Execution Finished At';
                }
                field(outputQuantity; Rec."ALP Output Qty.")
                {
                    Caption = 'Output Quantity';
                }
                field(scrapQuantity; Rec."ALP Scrap Qty.")
                {
                    Caption = 'Scrap Quantity';
                }
                field(plannedStart; Rec."ALP Planned Start")
                {
                    Caption = 'Planned Start';
                }
                field(plannedEnd; Rec."ALP Planned End")
                {
                    Caption = 'Planned End';
                }
                field(queuePosition; Rec."ALP Queue Position")
                {
                    Caption = 'Queue Position';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }

    var
        StepId: Text[100];
        SequenceNo: Integer;
        PlannedMinutes: Decimal;

    trigger OnAfterGetRecord()
    var
        StepResolver: Codeunit "ALP Step Resolver";
    begin
        StepId := StepResolver.FormatStepId(Rec);
        SequenceNo := StepResolver.SequenceNo(Rec);
        PlannedMinutes := StepResolver.PlannedMinutes(Rec);
    end;
}
