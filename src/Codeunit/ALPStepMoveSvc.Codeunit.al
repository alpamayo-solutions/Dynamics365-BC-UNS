/// <summary>
/// Moves a step (released routing line) to another work or machine center.
/// Only a step that has not started is moved: no capacity posted, not finished. Otherwise the move is refused,
/// because time already booked on the old center would no longer match the routing.
/// The move uses the standard field validation of the routing line, so Business Central recalculates
/// the line exactly as when a planner changes it by hand.
/// </summary>
codeunit 50104 "ALP Step Move Svc"
{
    var
        StepResolver: Codeunit "ALP Step Resolver";
        StepStartedErr: Label 'Step %1 cannot move: it is finished or has posted capacity.', Comment = '%1 = step id';
        BlockedErr: Label '%1 %2 is blocked.', Comment = '%1 = table caption, %2 = no.';

    procedure Process(var StepMove: Record "ALP Step Move")
    var
        Existing: Record "ALP Step Move";
        RoutingLine: Record "Prod. Order Routing Line";
        ToType: Enum "Capacity Type Routing";
    begin
        StepMove."Received At" := CurrentDateTime();
        Existing.SetRange("Event Id", StepMove."Event Id");
        Existing.SetFilter(Result, '<>%1', Existing.Result::Duplicate);
        if not Existing.IsEmpty() then begin
            StepMove.Result := StepMove.Result::Duplicate;
            exit;
        end;

        StepResolver.GetReleasedRoutingLine(StepMove."Step Id", RoutingLine);
        ToType := StepResolver.ParseWorkPlaceType(StepMove."To Type");
        StepMove."From Type" := CopyStr(Format(RoutingLine.Type), 1, MaxStrLen(StepMove."From Type"));
        StepMove."From No." := RoutingLine."No.";
        if (RoutingLine.Type = ToType) and (RoutingLine."No." = StepMove."To No.") then begin
            StepMove.Result := StepMove.Result::Duplicate;
            exit;
        end;
        MoveRoutingLine(RoutingLine, ToType, StepMove."To No.");
        StepMove.Result := StepMove.Result::Recorded;
    end;

    procedure MoveRoutingLine(var RoutingLine: Record "Prod. Order Routing Line"; ToType: Enum "Capacity Type Routing"; ToNo: Code[20])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        if StepResolver.IsDone(RoutingLine) or StepResolver.HasPostedCapacity(RoutingLine) then
            Error(StepStartedErr, StepResolver.FormatStepId(RoutingLine));

        case ToType of
            ToType::"Work Center":
                begin
                    WorkCenter.Get(ToNo);
                    if WorkCenter.Blocked then
                        Error(BlockedErr, WorkCenter.TableCaption(), ToNo);
                end;
            ToType::"Machine Center":
                begin
                    MachineCenter.Get(ToNo);
                    if MachineCenter.Blocked then
                        Error(BlockedErr, MachineCenter.TableCaption(), ToNo);
                end;
        end;

        RoutingLine.Validate(Type, ToType);
        RoutingLine.Validate("No.", ToNo);
        RoutingLine.Modify(true);
    end;
}
