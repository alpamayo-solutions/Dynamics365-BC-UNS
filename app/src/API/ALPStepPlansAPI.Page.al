/// <summary>
/// PATCH the fine plan of a step. Only the extension's plan fields change; the production order is not rescheduled,
/// so the planner's dates in Business Central stay as they are.
/// </summary>
page 50115 "ALP Step Plans API"
{
    PageType = API;
    Caption = 'Step Plans API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'stepPlan';
    EntitySetName = 'stepPlans';
    SourceTable = "Prod. Order Routing Line";
    SourceTableView = where(Status = const(Released));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = true;
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
                field(stepId; StepId)
                {
                    Caption = 'Step Id';
                    Editable = false;
                }
                field(plannedStart; PlannedStart)
                {
                    Caption = 'Planned Start';
                }
                field(plannedEnd; PlannedEnd)
                {
                    Caption = 'Planned End';
                }
                field(queuePosition; QueuePosition)
                {
                    Caption = 'Queue Position';
                }
            }
        }
    }

    var
        StepId: Text[100];
        PlannedStart: DateTime;
        PlannedEnd: DateTime;
        QueuePosition: Integer;

    trigger OnAfterGetRecord()
    var
        StepResolver: Codeunit "ALP Step Resolver";
    begin
        StepId := StepResolver.FormatStepId(Rec);
        PlannedStart := Rec."ALP Planned Start";
        PlannedEnd := Rec."ALP Planned End";
        QueuePosition := Rec."ALP Queue Position";
    end;

    // The plan fields are written with Modify(false) on a fresh copy so no routing-line trigger reschedules the order.
    trigger OnModifyRecord(): Boolean
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        RoutingLine.GetBySystemId(Rec.SystemId);
        RoutingLine."ALP Planned Start" := PlannedStart;
        RoutingLine."ALP Planned End" := PlannedEnd;
        RoutingLine."ALP Queue Position" := QueuePosition;
        RoutingLine.Modify(false);
        Rec := RoutingLine;
        exit(false);
    end;
}
