codeunit 50155 "ALP Step Move Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Helper: Codeunit "ALP Test Helper";
        LibraryManufacturing: Codeunit "Library - Manufacturing";

    local procedure Move(var StepMove: Record "ALP Step Move"; StepId: Text[100]; ToType: Text[20]; ToNo: Code[20])
    var
        StepMoveSvc: Codeunit "ALP Step Move Svc";
    begin
        Clear(StepMove);
        StepMove."Event Id" := CopyStr(Format(CreateGuid()), 1, 100);
        StepMove."Step Id" := StepId;
        StepMove."To Type" := ToType;
        StepMove."To No." := ToNo;
        StepMoveSvc.Process(StepMove);
        StepMove.Insert(true);
    end;

    [Test]
    procedure Move_NotStartedStep_ChangesWorkPlace()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OtherWorkCenter: Record "Work Center";
        StepMove: Record "ALP Step Move";
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        LibraryManufacturing.CreateWorkCenterWithCalendar(OtherWorkCenter);

        Move(StepMove, Helper.StepId(ProductionOrder, '20'), 'Work Center', OtherWorkCenter."No.");

        Assert.AreEqual(StepMove.Result::Recorded, StepMove.Result, 'Result');
        Assert.AreEqual(WorkCenter."No.", StepMove."From No.", 'From');
        Helper.GetRoutingLine(ProductionOrder, '20', RoutingLine);
        Assert.AreEqual(OtherWorkCenter."No.", RoutingLine."No.", 'Step moved');
    end;

    [Test]
    procedure Move_FinishedStep_IsRefused()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OtherWorkCenter: Record "Work Center";
        StepFinish: Record "ALP Step Finish";
        StepMove: Record "ALP Step Move";
    begin
        Helper.SetPostOutput(false);
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        LibraryManufacturing.CreateWorkCenterWithCalendar(OtherWorkCenter);
        Helper.NewStepFinish(StepFinish, Helper.StepId(ProductionOrder, '10'), 10);
        Helper.FinishStep(StepFinish);

        asserterror Move(StepMove, Helper.StepId(ProductionOrder, '10'), 'Work Center', OtherWorkCenter."No.");

        Assert.ExpectedError('cannot move');
    end;

    [Test]
    procedure Move_UnknownType_IsRefused()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        StepMove: Record "ALP Step Move";
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        asserterror Move(StepMove, Helper.StepId(ProductionOrder, '20'), 'Workstation', WorkCenter."No.");
        Assert.ExpectedError('is not supported');
    end;
}
