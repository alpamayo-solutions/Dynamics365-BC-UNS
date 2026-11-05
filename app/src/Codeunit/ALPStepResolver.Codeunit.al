/// <summary>
/// A step is one released production order routing line. Its id is "{Prod. Order No.}:{Routing Reference No.}:{Operation No.}".
/// This codeunit is the only place that formats, parses and resolves step ids, so the format has one definition.
/// Resolution is exact: an id that does not match exactly one released routing line is refused, never guessed.
/// </summary>
codeunit 50100 "ALP Step Resolver"
{
    var
        StepIdFormatErr: Label 'Step id "%1" is not in the form "{order no.}:{routing reference no.}:{operation no.}".', Comment = '%1 = step id';
        StepNotFoundErr: Label 'Step %1 is not a routing line of a released production order.', Comment = '%1 = step id';
        AmbiguousStepErr: Label 'Step %1 matches %2 routing lines. Business Central cannot decide which one is meant.', Comment = '%1 = step id, %2 = count';
        UnknownWorkPlaceTypeErr: Label 'Work place type "%1" is not supported. Use "Work Center" or "Machine Center".', Comment = '%1 = type text';
        StepIdTok: Label '%1:%2:%3', Locked = true;

    procedure FormatStepId(RoutingLine: Record "Prod. Order Routing Line"): Text[100]
    begin
        exit(CopyStr(StrSubstNo(StepIdTok, RoutingLine."Prod. Order No.", RoutingLine."Routing Reference No.", RoutingLine."Operation No."), 1, 100));
    end;

    procedure ParseStepId(StepId: Text; var ProdOrderNo: Code[20]; var RoutingReferenceNo: Integer; var OperationNo: Code[10])
    var
        Parts: List of [Text];
    begin
        Parts := StepId.Split(':');
        if Parts.Count() <> 3 then
            Error(StepIdFormatErr, StepId);
        if (Parts.Get(1) = '') or (Parts.Get(3) = '') then
            Error(StepIdFormatErr, StepId);
        if StrLen(Parts.Get(1)) > MaxStrLen(ProdOrderNo) then
            Error(StepIdFormatErr, StepId);
        if StrLen(Parts.Get(3)) > MaxStrLen(OperationNo) then
            Error(StepIdFormatErr, StepId);
        if not Evaluate(RoutingReferenceNo, Parts.Get(2)) then
            Error(StepIdFormatErr, StepId);
        ProdOrderNo := CopyStr(Parts.Get(1), 1, MaxStrLen(ProdOrderNo));
        OperationNo := CopyStr(Parts.Get(3), 1, MaxStrLen(OperationNo));
    end;

    /// <summary>Finds the released routing line of a step. Errors when there is none or more than one.</summary>
    procedure GetReleasedRoutingLine(StepId: Text; var RoutingLine: Record "Prod. Order Routing Line")
    var
        ProdOrderNo: Code[20];
        OperationNo: Code[10];
        RoutingReferenceNo: Integer;
        MatchCount: Integer;
    begin
        ParseStepId(StepId, ProdOrderNo, RoutingReferenceNo, OperationNo);
        RoutingLine.Reset();
        RoutingLine.SetRange(Status, RoutingLine.Status::Released);
        RoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        RoutingLine.SetRange("Routing Reference No.", RoutingReferenceNo);
        RoutingLine.SetRange("Operation No.", OperationNo);
        MatchCount := RoutingLine.Count();
        if MatchCount = 0 then
            Error(StepNotFoundErr, StepId);
        if MatchCount > 1 then
            Error(AmbiguousStepErr, StepId, MatchCount);
        RoutingLine.FindFirst();
    end;

    /// <summary>1-based position of the routing line among the lines of the same order line and routing, by operation no.</summary>
    procedure SequenceNo(RoutingLine: Record "Prod. Order Routing Line"): Integer
    var
        Sibling: Record "Prod. Order Routing Line";
    begin
        Sibling.SetRange(Status, RoutingLine.Status);
        Sibling.SetRange("Prod. Order No.", RoutingLine."Prod. Order No.");
        Sibling.SetRange("Routing Reference No.", RoutingLine."Routing Reference No.");
        Sibling.SetRange("Routing No.", RoutingLine."Routing No.");
        Sibling.SetFilter("Operation No.", '<%1', RoutingLine."Operation No.");
        exit(Sibling.Count() + 1);
    end;

    /// <summary>Planned minutes: setup time plus run time times input quantity, converted from the routing line's capacity units.</summary>
    procedure PlannedMinutes(RoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        Milliseconds: Decimal;
    begin
        Milliseconds :=
            RoutingLine."Setup Time" * ShopCalendarMgt.TimeFactor(RoutingLine."Setup Time Unit of Meas. Code") +
            RoutingLine."Run Time" * RoutingLine."Input Quantity" * ShopCalendarMgt.TimeFactor(RoutingLine."Run Time Unit of Meas. Code");
        exit(Round(Milliseconds / 60000, 0.01));
    end;

    procedure IsDone(RoutingLine: Record "Prod. Order Routing Line"): Boolean
    begin
        exit(RoutingLine."ALP Exec. Finished" or (RoutingLine."Routing Status" = RoutingLine."Routing Status"::Finished));
    end;

    procedure ParseWorkPlaceType(TypeText: Text): Enum "Capacity Type Routing"
    var
        CapacityType: Enum "Capacity Type Routing";
    begin
        case DelChr(UpperCase(TypeText), '=', ' _') of
            'WORKCENTER':
                exit(CapacityType::"Work Center");
            'MACHINECENTER':
                exit(CapacityType::"Machine Center");
        end;
        Error(UnknownWorkPlaceTypeErr, TypeText);
    end;

    /// <summary>True when capacity (time or output) was already posted for the step.</summary>
    procedure HasPostedCapacity(RoutingLine: Record "Prod. Order Routing Line"): Boolean
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", RoutingLine."Prod. Order No.");
        CapacityLedgerEntry.SetRange("Routing No.", RoutingLine."Routing No.");
        CapacityLedgerEntry.SetRange("Routing Reference No.", RoutingLine."Routing Reference No.");
        CapacityLedgerEntry.SetRange("Operation No.", RoutingLine."Operation No.");
        exit(not CapacityLedgerEntry.IsEmpty());
    end;
}
