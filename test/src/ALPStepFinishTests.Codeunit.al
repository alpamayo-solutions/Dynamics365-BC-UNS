codeunit 50152 "ALP Step Finish Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Helper: Codeunit "ALP Test Helper";

    [Test]
    procedure Finish_ObserverMode_RecordsOnRoutingLineWithoutPosting()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
        RoutingLine: Record "Prod. Order Routing Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 9);
        StepFinish."Scrap Quantity" := 1;

        Helper.FinishStep(StepFinish);

        Assert.AreEqual(StepFinish.Result::Recorded, StepFinish.Result, 'Result');
        Helper.GetRoutingLine(ProductionOrder, '10', RoutingLine);
        Assert.IsTrue(RoutingLine."ALP Exec. Finished", 'Step must be marked finished');
        Assert.AreEqual(9, RoutingLine."ALP Output Qty.", 'Output');
        Assert.AreEqual(1, RoutingLine."ALP Scrap Qty.", 'Scrap');
        Assert.AreEqual(RoutingLine."Routing Status"::Planned, RoutingLine."Routing Status", 'Observer mode must not change routing status');
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.RecordIsEmpty(CapacityLedgerEntry);
    end;

    [Test]
    procedure Finish_PostMode_PostsOutputAndFinishesOperation()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
        RoutingLine: Record "Prod. Order Routing Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        Helper.SetPostOutput(true);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);

        Helper.FinishStep(StepFinish);

        Assert.AreEqual(StepFinish.Result::Posted, StepFinish.Result, 'Result');
        Helper.GetRoutingLine(ProductionOrder, '10', RoutingLine);
        Assert.AreEqual(RoutingLine."Routing Status"::Finished, RoutingLine."Routing Status", 'Posting with Finished must finish the operation');
        CapacityLedgerEntry.Get(StepFinish."Capacity Ledger Entry No.");
        Assert.AreEqual(10, CapacityLedgerEntry."Output Quantity", 'Posted output');
        Assert.AreEqual(ProductionOrder."No.", CapacityLedgerEntry."Order No.", 'Order on capacity entry');
        Helper.SetPostOutput(false);
    end;

    [Test]
    procedure Finish_PostMode_LastOperationBooksOutputToInventory()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Helper.SetPostOutput(true);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);
        Helper.FinishStep(StepFinish);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '20'), 8);

        Helper.FinishStep(StepFinish);

        ItemLedgerEntry.Get(StepFinish."Item Ledger Entry No.");
        Assert.AreEqual(ItemLedgerEntry."Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Entry type');
        Assert.AreEqual(8, ItemLedgerEntry.Quantity, 'Output on the last operation goes to inventory');
        Helper.SetPostOutput(false);
    end;

    [Test]
    procedure Finish_SameEventTwice_IsDuplicate()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
        Again: Record "ALP Step Finish";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);
        Helper.FinishStep(StepFinish);

        Again := StepFinish;
        Again."Entry No." := 0;
        Again."Output Quantity" := 3;
        Helper.FinishStep(Again);

        Assert.AreEqual(Again.Result::Duplicate, Again.Result, 'A repeated event must be a duplicate');
    end;

    [Test]
    procedure Finish_AlreadyDoneStep_IsDuplicate()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);
        Helper.FinishStep(StepFinish);

        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 4);
        Helper.FinishStep(StepFinish);

        Assert.AreEqual(StepFinish.Result::Duplicate, StepFinish.Result, 'The first finish wins');
        Helper.GetRoutingLine(ProductionOrder, '10', RoutingLine);
        Assert.AreEqual(10, RoutingLine."ALP Output Qty.", 'Output of the first finish stays');
    end;

    [Test]
    procedure Finish_BeforePreviousStep_IsRefused()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '20'), 10);

        asserterror Helper.FinishStep(StepFinish);

        Assert.ExpectedError('cannot finish before operation 10');
    end;

    [Test]
    procedure Finish_HeldOrder_IsRefused()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        ProductionOrder."ALP Held" := true;
        ProductionOrder.Modify();
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);

        asserterror Helper.FinishStep(StepFinish);

        Assert.ExpectedError('is on hold');
    end;

    [Test]
    procedure Finish_NegativeQuantity_IsRefused()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), -1);

        asserterror Helper.FinishStep(StepFinish);

        Assert.ExpectedError('must not be negative');
    end;

    [Test]
    procedure Finish_RanOnMachineCenter_MovesStepFirst()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        StepFinish: Record "ALP Step Finish";
        RoutingLine: Record "Prod. Order Routing Line";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", 1);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);
        StepFinish."Ran On Type" := 'Machine Center';
        StepFinish."Ran On No." := MachineCenter."No.";

        Helper.FinishStep(StepFinish);

        Helper.GetRoutingLine(ProductionOrder, '10', RoutingLine);
        Assert.AreEqual(RoutingLine.Type::"Machine Center", RoutingLine.Type, 'Type');
        Assert.AreEqual(MachineCenter."No.", RoutingLine."No.", 'The step must sit where it ran');
    end;
}
