codeunit 50151 "ALP Step Resolver Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Helper: Codeunit "ALP Test Helper";
        StepResolver: Codeunit "ALP Step Resolver";

    [Test]
    procedure StepId_RoundTrips()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Prod. Order Routing Line";
        Resolved: Record "Prod. Order Routing Line";
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.GetRoutingLine(ProductionOrder, '20', RoutingLine);

        StepResolver.GetReleasedRoutingLine(StepResolver.FormatStepId(RoutingLine), Resolved);

        Assert.AreEqual(RoutingLine.SystemId, Resolved.SystemId, 'Step id must resolve to the same routing line');
    end;

    [Test]
    procedure StepId_MalformedIsRefused()
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        asserterror StepResolver.GetReleasedRoutingLine('101001-10', RoutingLine);
        Assert.ExpectedError('is not in the form');
        asserterror StepResolver.GetReleasedRoutingLine('101001:x:10', RoutingLine);
        Assert.ExpectedError('is not in the form');
    end;

    [Test]
    procedure StepId_UnknownIsRefused()
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        asserterror StepResolver.GetReleasedRoutingLine('NOSUCHORDER:10000:10', RoutingLine);
        Assert.ExpectedError('is not a routing line of a released production order');
    end;

    [Test]
    procedure SequenceNo_FollowsOperationOrder()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.GetRoutingLine(ProductionOrder, '10', RoutingLine);
        Assert.AreEqual(1, StepResolver.SequenceNo(RoutingLine), 'First operation');
        Helper.GetRoutingLine(ProductionOrder, '20', RoutingLine);
        Assert.AreEqual(2, StepResolver.SequenceNo(RoutingLine), 'Second operation');
    end;

    [Test]
    procedure PlannedMinutes_SetupPlusRunTimesQuantity()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Prod. Order Routing Line";
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        Expected: Decimal;
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        Helper.GetRoutingLine(ProductionOrder, '10', RoutingLine);

        Expected := Round((RoutingLine."Setup Time" * ShopCalendarMgt.TimeFactor(RoutingLine."Setup Time Unit of Meas. Code") +
            RoutingLine."Run Time" * RoutingLine."Input Quantity" * ShopCalendarMgt.TimeFactor(RoutingLine."Run Time Unit of Meas. Code")) / 60000, 0.01);
        Assert.AreNotEqual(0, Expected, 'Test setup must have planned time');
        Assert.AreEqual(Expected, StepResolver.PlannedMinutes(RoutingLine), 'Planned minutes');
    end;
}
