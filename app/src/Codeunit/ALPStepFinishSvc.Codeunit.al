/// <summary>
/// Finishes a step reported by the Execution app.
///
/// Rules (each failure raises an error, so the API answers 400 and nothing is written):
/// - the step must be a released routing line (ALP Step Resolver);
/// - the production order must not be on hold;
/// - the step may finish before earlier operations: the shop floor reports what happened, and a shift lead
///   may start a later step first (the Execution app then closes the earlier ones without a finish);
/// - quantities must not be negative.
///
/// A repeat of an Event Id is answered with Result = Duplicate and changes nothing.
/// A step that is already done is answered with Result = Duplicate as well: the first finish wins.
///
/// With ALP Shopfloor Setup "Post Output" on, the finish posts one output journal line the same way
/// the standard Production Journal does (codeunit "Production Journal Mgt"), with Finished = true, so
/// Business Central sets the routing status to Finished and, on the last operation, books the output to inventory.
/// With it off, nothing is posted; the facts are kept on the routing line for people to post themselves.
/// </summary>
codeunit 50101 "ALP Step Finish Svc"
{
    var
        StepResolver: Codeunit "ALP Step Resolver";
        OrderOnHoldErr: Label 'Production order %1 is on hold.', Comment = '%1 = order no.';
        NegativeQtyErr: Label 'Output and scrap quantities must not be negative.';
        FinishedAtRequiredErr: Label 'Finished At is required.';
        ProdOrderLineErr: Label 'Step %1 must belong to exactly one production order line, found %2.', Comment = '%1 = step id, %2 = count';
        MinutesUoMErr: Label 'Capacity unit of measure %1 has no time factor.', Comment = '%1 = unit of measure code';

    procedure Process(var StepFinish: Record "ALP Step Finish")
    var
        Existing: Record "ALP Step Finish";
        RoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        Setup: Record "ALP Shopfloor Setup";
        StepMoveSvc: Codeunit "ALP Step Move Svc";
    begin
        StepFinish."Received At" := CurrentDateTime();

        Existing.SetRange("Event Id", StepFinish."Event Id");
        Existing.SetFilter(Result, '<>%1', Existing.Result::Duplicate);
        if not Existing.IsEmpty() then begin
            StepFinish.Result := StepFinish.Result::Duplicate;
            exit;
        end;

        if StepFinish."Finished At" = 0DT then
            Error(FinishedAtRequiredErr);
        if (StepFinish."Output Quantity" < 0) or (StepFinish."Scrap Quantity" < 0) then
            Error(NegativeQtyErr);

        StepResolver.GetReleasedRoutingLine(StepFinish."Step Id", RoutingLine);
        StepFinish."Prod. Order No." := RoutingLine."Prod. Order No.";
        StepFinish."Routing Reference No." := RoutingLine."Routing Reference No.";
        StepFinish."Operation No." := RoutingLine."Operation No.";

        if StepResolver.IsDone(RoutingLine) then begin
            StepFinish.Result := StepFinish.Result::Duplicate;
            exit;
        end;

        ProductionOrder.Get(ProductionOrder.Status::Released, RoutingLine."Prod. Order No.");
        if ProductionOrder."ALP Held" then
            Error(OrderOnHoldErr, ProductionOrder."No.");

        // The step ran somewhere else than planned: move it first, so time and output land on the right center.
        if (StepFinish."Ran On No." <> '') then
            if (RoutingLine.Type <> StepResolver.ParseWorkPlaceType(StepFinish."Ran On Type")) or (RoutingLine."No." <> StepFinish."Ran On No.") then begin
                StepMoveSvc.MoveRoutingLine(RoutingLine, StepResolver.ParseWorkPlaceType(StepFinish."Ran On Type"), StepFinish."Ran On No.");
                RoutingLine.Get(RoutingLine.Status, RoutingLine."Prod. Order No.", RoutingLine."Routing Reference No.", RoutingLine."Routing No.", RoutingLine."Operation No.");
            end;

        Setup.GetOrInit();
        if Setup."Post Output" then begin
            PostOutput(StepFinish, RoutingLine);
            StepFinish.Result := StepFinish.Result::Posted;
            RoutingLine.Get(RoutingLine.Status, RoutingLine."Prod. Order No.", RoutingLine."Routing Reference No.", RoutingLine."Routing No.", RoutingLine."Operation No.");
        end else
            StepFinish.Result := StepFinish.Result::Recorded;

        RoutingLine."ALP Exec. Finished" := true;
        RoutingLine."ALP Exec. Finished At" := StepFinish."Finished At";
        RoutingLine."ALP Output Qty." := StepFinish."Output Quantity";
        RoutingLine."ALP Scrap Qty." := StepFinish."Scrap Quantity";
        RoutingLine."ALP Finished By" := StepFinish."Employee No.";
        RoutingLine.Modify(false);
    end;

    local procedure PostOutput(var StepFinish: Record "ALP Step Finish"; RoutingLine: Record "Prod. Order Routing Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        LineCount: Integer;
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", RoutingLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", RoutingLine."Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", RoutingLine."Routing No.");
        LineCount := ProdOrderLine.Count();
        if LineCount <> 1 then
            Error(ProdOrderLineErr, StepFinish."Step Id", LineCount);
        ProdOrderLine.FindFirst();

        SourceCodeSetup.Get();

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Posting Date", DT2Date(StepFinish."Finished At"));
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ItemJnlLine.Validate("Location Code", ProdOrderLine."Location Code");
        ItemJnlLine.Validate("Dimension Set ID", ProdOrderLine."Dimension Set ID");
        if ProdOrderLine."Bin Code" <> '' then
            ItemJnlLine.Validate("Bin Code", ProdOrderLine."Bin Code");
        ItemJnlLine.Validate("Routing No.", ProdOrderLine."Routing No.");
        ItemJnlLine.Validate("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ItemJnlLine.Validate("Operation No.", RoutingLine."Operation No.");
        ItemJnlLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ItemJnlLine."Document No." := ProdOrderLine."Prod. Order No.";
        ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
        ItemJnlLine."Flushing Method" := RoutingLine."Flushing Method";

        ItemJnlLine.Validate("Setup Time", MinutesToCapacityUnits(StepFinish."Setup Minutes", ItemJnlLine."Cap. Unit of Measure Code"));
        ItemJnlLine.Validate("Run Time", MinutesToCapacityUnits(StepFinish."Run Minutes", ItemJnlLine."Cap. Unit of Measure Code"));
        if StepFinish."Started At" <> 0DT then
            ItemJnlLine.Validate("Starting Time", DT2Time(StepFinish."Started At"));
        ItemJnlLine.Validate("Ending Time", DT2Time(StepFinish."Finished At"));
        ItemJnlLine.Validate("Output Quantity", StepFinish."Output Quantity");
        ItemJnlLine.Validate("Scrap Quantity", StepFinish."Scrap Quantity");
        if StepFinish."Scrap Code" <> '' then
            ItemJnlLine.Validate("Scrap Code", StepFinish."Scrap Code");
        ItemJnlLine.Validate(Finished, true);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", RoutingLine."Prod. Order No.");
        CapacityLedgerEntry.SetRange("Routing Reference No.", RoutingLine."Routing Reference No.");
        CapacityLedgerEntry.SetRange("Operation No.", RoutingLine."Operation No.");
        if CapacityLedgerEntry.FindLast() then
            StepFinish."Capacity Ledger Entry No." := CapacityLedgerEntry."Entry No.";

        if RoutingLine."Next Operation No." = '' then begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
            ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
            ItemLedgerEntry.SetRange("Order No.", RoutingLine."Prod. Order No.");
            ItemLedgerEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
            if ItemLedgerEntry.FindLast() then
                StepFinish."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        end;
    end;

    local procedure MinutesToCapacityUnits(Minutes: Decimal; CapUnitOfMeasureCode: Code[10]): Decimal
    var
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        TimeFactor: Decimal;
    begin
        if Minutes = 0 then
            exit(0);
        TimeFactor := ShopCalendarMgt.TimeFactor(CapUnitOfMeasureCode);
        if TimeFactor = 0 then
            Error(MinutesUoMErr, CapUnitOfMeasureCode);
        exit(Round(Minutes * 60000 / TimeFactor, 0.00001));
    end;
}
