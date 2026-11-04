/// <summary>Creates the minimal manufacturing setup the tests need: a released order with a two-step routing.</summary>
codeunit 50150 "ALP Test Helper"
{
    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryHumanResource: Codeunit "Library - Human Resource";

    procedure CreateReleasedOrderTwoSteps(var ProductionOrder: Record "Production Order"; var WorkCenter: Record "Work Center"; Quantity: Decimal)
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", 15);
        RoutingLine.Validate("Run Time", 2);
        RoutingLine.Modify(true);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    procedure GetRoutingLine(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; var RoutingLine: Record "Prod. Order Routing Line")
    begin
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.SetRange("Operation No.", OperationNo);
        RoutingLine.FindFirst();
    end;

    procedure StepId(ProductionOrder: Record "Production Order"; OperationNo: Code[10]): Text[100]
    var
        RoutingLine: Record "Prod. Order Routing Line";
        StepResolver: Codeunit "ALP Step Resolver";
    begin
        GetRoutingLine(ProductionOrder, OperationNo, RoutingLine);
        exit(StepResolver.FormatStepId(RoutingLine));
    end;

    procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        exit(Employee."No.");
    end;

    procedure SetPostOutput(PostOutput: Boolean)
    var
        Setup: Record "ALP Shopfloor Setup";
    begin
        Setup.GetOrInit();
        Setup."Post Output" := PostOutput;
        Setup.Modify();
    end;

    procedure NewStepFinish(var StepFinish: Record "ALP Step Finish"; StepIdValue: Text[100]; OutputQty: Decimal)
    begin
        Clear(StepFinish);
        StepFinish."Event Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(StepFinish."Event Id"));
        StepFinish."Step Id" := StepIdValue;
        StepFinish."Started At" := CreateDateTime(WorkDate(), 080000T);
        StepFinish."Finished At" := CreateDateTime(WorkDate(), 090000T);
        StepFinish."Run Minutes" := 50;
        StepFinish."Setup Minutes" := 10;
        StepFinish."Output Quantity" := OutputQty;
    end;

    /// <summary>Runs a command the way the API page does: process, then insert.</summary>
    procedure FinishStep(var StepFinish: Record "ALP Step Finish")
    var
        StepFinishSvc: Codeunit "ALP Step Finish Svc";
    begin
        StepFinishSvc.Process(StepFinish);
        StepFinish.Insert(true);
    end;
}
