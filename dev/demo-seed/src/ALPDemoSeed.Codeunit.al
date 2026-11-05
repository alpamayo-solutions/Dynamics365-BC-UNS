/// <summary>
/// Development only. Creates the PREKIT chocolate demo plant in a Business Central container so the
/// Execution app (ERP_KIND=businesscentral) can run against it. Repeatable: a second run changes nothing.
/// Machine center numbers are the plant's machine names in upper case (the Execution app matches them
/// regardless of case); names longer than 20 characters are shortened, see MachineNo.
/// Run: Invoke-NavContainerCodeunit -containerName bcbuild -CompanyName 'CRONUS International Ltd.' -Codeunitid 50200
/// </summary>
codeunit 50200 "ALP Demo Seed"
{
    var
        PatternWorkCenter: Record "Work Center";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        OrderTagTok: Label 'ALPDEMO-%1', Locked = true;
        SeedEventTok: Label 'seed:%1:%2', Locked = true;

    trigger OnRun()
    begin
        Employees();
        Plant();
        Calendars();
        Routings();
        Items();
        Orders();
    end;

    local procedure Employees()
    begin
        // The chocolate rig's people (alpamayo-chocolate-2 seeder/src/seeder/render.py DEMO_EMPLOYEES): the
        // Execution app sends a person's employee_id, which must exist here. operator08 has none.
        Employee('EMP-0001', 'Franz', 'Hodler');
        Employee('EMP-0002', 'Sandra', 'Brunner');
        Employee('EMP-0003', 'Marco', 'Keller');
        Employee('EMP-0004', 'Lukas', 'Gerber');
        Employee('EMP-0005', 'Nina', 'Zbinden');
        Employee('EMP-0006', 'Andrea', 'Meier');
        Employee('EMP-0007', 'Daniel', 'Huber');
        Employee('EMP-0008', 'Laura', 'Steiner');
        Employee('EMP-0009', 'Reto', 'Baumann');
        Employee('EMP-0010', 'Claudia', 'Frei');
        Employee('EMP-0011', 'Thomas', 'Moser');
    end;

    local procedure Employee(No: Code[20]; FirstName: Text[30]; LastName: Text[30])
    var
        Emp: Record Employee;
    begin
        if not Emp.Get(No) then begin
            Emp.Init();
            Emp."No." := No;
            Emp.Insert(true);
        end;
        Emp."First Name" := FirstName;
        Emp."Last Name" := LastName;
        Emp.Modify(true);
    end;

    local procedure Plant()
    var
        WorkCenter: Record "Work Center";
    begin
        if WorkCenter.Get('BEAN-CLEANER') then
            exit; // Plant exists.
        Group('BEAN', 'Bean processing');
        Group('MOULD', 'Moulding and cooling');
        Group('PACK', 'Packaging');
        LibraryManufacturing.CreateWorkCenterWithCalendar(PatternWorkCenter);

        Station('BEAN-CLEANER', 'Bean cleaner', 'BEAN', 'bean-cleaner', 2);
        Station('DRUM-ROASTER', 'Drum roaster', 'BEAN', 'drum-roaster', 4);
        Station('CRACKER-WINNOWER', 'Cracker and winnower', 'BEAN', 'cracker-winnower', 3);
        Station('BALL-MILL', 'Ball mill', 'BEAN', 'ball-mill', 4);
        Station('CONCHE', 'Conche', 'BEAN', 'conche', 6);
        Station('TEMPERING-MACHINE', 'Tempering machine', 'MOULD', 'tempering-machine', 6);
        Station('MOULDING-LINE', 'Moulding line', 'MOULD', 'moulding-line', 6);
        Station('COOLING-TUNNEL', 'Cooling tunnel', 'MOULD', 'cooling-tunnel', 4);
        Station('DEMOULDING-STATION', 'Demoulding station', 'MOULD', 'demoulding-station', 4);
        Station('WEIGHT-CHECKER', 'Checkweigher', 'PACK', 'weight-checker', 3);
        Station('VISUAL-INSPECTOR', 'Visual inspector', 'PACK', 'visual-inspector', 4);
        Station('MANUAL-INSPECTION', 'Manual inspection', 'PACK', 'manual-inspection', 2);
        Station('HAND-DECORATION', 'Hand decoration', 'PACK', 'hand-decoration', 3);
        Station('WRAPPING-MACHINE', 'Wrapping machine', 'PACK', 'wrapping-machine', 6);
        Station('CARTONING-MACHINE', 'Cartoning machine', 'PACK', 'cartoning-machine', 4);
        Station('CASE-PACKER', 'Case packer', 'PACK', 'case-packer', 3);
        Station('PALLETIZER', 'Palletizer', 'PACK', 'palletizer', 2);

        PatternWorkCenter.Delete(true);
    end;

    /// <summary>Every run: the plant's calendars from 6 months back to 12 ahead, enough for backward scheduling of the largest order.</summary>
    local procedure Calendars()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        WorkCenter.SetFilter("Work Center Group Code", 'BEAN|MOULD|PACK');
        if WorkCenter.FindSet() then
            repeat
                LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CM-6M>', WorkDate()), CalcDate('<CM+12M>', WorkDate()));
                MachineCenter.SetRange("Work Center No.", WorkCenter."No.");
                if MachineCenter.FindSet() then
                    repeat
                        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-CM-6M>', WorkDate()), CalcDate('<CM+12M>', WorkDate()));
                    until MachineCenter.Next() = 0;
            until WorkCenter.Next() = 0;
    end;

    local procedure Group(Code: Code[10]; Name: Text[50])
    var
        WorkCenterGroup: Record "Work Center Group";
    begin
        if WorkCenterGroup.Get(Code) then
            exit;
        WorkCenterGroup.Init();
        WorkCenterGroup.Code := Code;
        WorkCenterGroup.Name := Name;
        WorkCenterGroup.Insert(true);
    end;

    local procedure Station(No: Code[20]; Name: Text[100]; GroupCode: Code[10]; MachinePrefix: Text; Count: Integer)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        i: Integer;
    begin
        WorkCenter.TransferFields(PatternWorkCenter);
        WorkCenter."No." := No;
        WorkCenter.Name := Name;
        WorkCenter."Search Name" := UpperCase(Name);
        WorkCenter."Work Center Group Code" := GroupCode;
        WorkCenter.Insert(true);
        for i := 1 to Count do begin
            Clear(MachineCenter);
            MachineCenter.Init();
            MachineCenter."No." := MachineNo(MachinePrefix, i);
            MachineCenter.Insert(true);
            MachineCenter.Name := CopyStr(StrSubstNo('%1 %2', Name, i), 1, MaxStrLen(MachineCenter.Name));
            MachineCenter.Validate("Work Center No.", No);
            MachineCenter.Validate(Capacity, 1);
            MachineCenter.Validate(Efficiency, 100);
            MachineCenter.Modify(true);
        end;
    end;

    /// <summary>The machine's PREKIT name in upper case; `demoulding-station-01` (21 characters) becomes DEMOULDING-STN-01.</summary>
    procedure MachineNo(MachinePrefix: Text; i: Integer): Code[20]
    begin
        if MachinePrefix = 'demoulding-station' then
            MachinePrefix := 'demoulding-stn';
        exit(CopyStr(UpperCase(StrSubstNo('%1-%2', MachinePrefix, Format(i, 0, '<Integer,2><Filler Character,0>'))), 1, 20));
    end;

    local procedure Routings()
    begin
        Routing('BEAN-TO-BAR', 'Bean to bar', true);
        Routing('MASS-TO-BAR', 'Mass to bar', false);
    end;

    local procedure Routing(No: Code[20]; Description: Text[100]; FromBean: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        OpNo: Integer;
    begin
        if RoutingHeader.Get(No) then
            exit;
        RoutingHeader.Init();
        RoutingHeader."No." := No;
        RoutingHeader.Insert(true);
        RoutingHeader.Validate(Description, Description);
        RoutingHeader.Validate(Type, RoutingHeader.Type::Serial);
        RoutingHeader.Modify(true);
        if FromBean then begin
            Op(RoutingHeader, OpNo, 'Cleaning', 'bean-cleaner', 20, 0.01);
            Op(RoutingHeader, OpNo, 'Roasting', 'drum-roaster', 30, 0.05);
            Op(RoutingHeader, OpNo, 'Winnowing', 'cracker-winnower', 15, 0.02);
        end;
        Op(RoutingHeader, OpNo, 'Ball Milling', 'ball-mill', 20, 0.06);
        Op(RoutingHeader, OpNo, 'Conching', 'conche', 30, 0.2);
        Op(RoutingHeader, OpNo, 'Tempering', 'tempering-machine', 15, 0.03);
        Op(RoutingHeader, OpNo, 'Moulding', 'moulding-line', 20, 0.02);
        Op(RoutingHeader, OpNo, 'Cooling', 'cooling-tunnel', 5, 0.04);
        Op(RoutingHeader, OpNo, 'Demoulding', 'demoulding-station', 5, 0.01);
        Op(RoutingHeader, OpNo, 'Inspection', 'weight-checker', 5, 0.005);
        Op(RoutingHeader, OpNo, 'Visual Inspection', 'visual-inspector', 5, 0.005);
        Op(RoutingHeader, OpNo, 'Manual Inspection', 'manual-inspection', 0, 0.01);
        Op(RoutingHeader, OpNo, 'Hand Decoration', 'hand-decoration', 0, 0.05);
        Op(RoutingHeader, OpNo, 'Wrapping', 'wrapping-machine', 10, 0.01);
        Op(RoutingHeader, OpNo, 'Cartoning', 'cartoning-machine', 10, 0.01);
        Op(RoutingHeader, OpNo, 'Case Packing', 'case-packer', 10, 0.005);
        Op(RoutingHeader, OpNo, 'Palletizing', 'palletizer', 5, 0.002);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure Op(RoutingHeader: Record "Routing Header"; var OpNo: Integer; Description: Text[100]; MachinePrefix: Text; SetupMinutes: Decimal; RunMinutes: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        // Operation No. is a Code field and BC orders it as text: '0010'..'0170', so '100' never runs before '20'.
        OpNo += 10;
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', Format(OpNo, 0, '<Integer,4><Filler Character,0>'), RoutingLine.Type::"Machine Center", MachineNo(MachinePrefix, 1));
        RoutingLine.Validate(Description, Description);
        RoutingLine.Validate("Setup Time", SetupMinutes);
        RoutingLine.Validate("Run Time", RunMinutes);
        RoutingLine.Modify(true);
    end;

    local procedure Items()
    begin
        Item('BAR-DARK-70', 'Dark 70%', 'BEAN-TO-BAR');
        Item('BAR-MILK', 'Milk', 'MASS-TO-BAR');
        Item('BAR-WHITE', 'White', 'MASS-TO-BAR');
        Item('BAR-SINGLE-ORIGIN-85', 'Single Origin Ghana 85%', 'BEAN-TO-BAR');
    end;

    local procedure Item(No: Code[20]; Description: Text[100]; RoutingNo: Code[20])
    var
        NewItem: Record Item;
    begin
        if NewItem.Get(No) then
            exit;
        LibraryInventory.CreateItem(NewItem);
        NewItem.Rename(No);
        NewItem.Validate(Description, Description);
        NewItem.Validate("Replenishment System", NewItem."Replenishment System"::"Prod. Order");
        NewItem.Validate("Routing No.", RoutingNo);
        NewItem.Modify(true);
    end;

    local procedure Orders()
    begin
        // Tag, item, quantity, due date offset (days), description override, held, finished steps.
        Order(1, 'BAR-DARK-70', 2400, 2, '', false, 0);
        Order(2, 'BAR-MILK', 1200, 3, '', false, 3);
        Order(3, 'BAR-WHITE', 1, 1, '', false, 0);
        Order(4, 'BAR-SINGLE-ORIGIN-85', 50000, 10, '', false, 0);
        Order(5, 'BAR-MILK', 800, -2, 'Milchschokolade für Grüezi-Box ✓ 🍫', false, 0);
        Order(6, 'BAR-DARK-70', 600, 4, 'Dark 70% – Sonderauftrag Weihnachtsmarkt Zürich, Bern, Basel, Luzern, St. Gallen & Lugano 2026/27', false, 0);
        Order(7, 'BAR-WHITE', 300, 5, '', true, 0);
        Order(8, 'BAR-DARK-70', 1000, 0, '', false, 6);
    end;

    local procedure Order(Tag: Integer; ItemNo: Code[20]; Quantity: Decimal; DueDays: Integer; Description: Text[100]; Held: Boolean; FinishedSteps: Integer)
    var
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Prod. Order Routing Line";
        StepFinish: Record "ALP Step Finish";
        StepResolver: Codeunit "ALP Step Resolver";
        StepFinishSvc: Codeunit "ALP Step Finish Svc";
        Done: Integer;
    begin
        Done := 0;
        ProductionOrder.SetRange("Search Description", StrSubstNo(OrderTagTok, Tag));
        if not ProductionOrder.IsEmpty() then
            exit;
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Due Date", WorkDate() + DueDays);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        if Description <> '' then
            ProductionOrder.Description := Description;
        ProductionOrder."Search Description" := StrSubstNo(OrderTagTok, Tag);
        ProductionOrder."ALP Held" := Held;
        ProductionOrder.Modify(false);

        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if RoutingLine.FindSet() then
            repeat
                if Done < FinishedSteps then begin
                    Done += 1;
                    Clear(StepFinish);
                    StepFinish."Event Id" := CopyStr(StrSubstNo(SeedEventTok, ProductionOrder."No.", RoutingLine."Operation No."), 1, MaxStrLen(StepFinish."Event Id"));
                    StepFinish."Step Id" := StepResolver.FormatStepId(RoutingLine);
                    StepFinish."Started At" := CurrentDateTime() - (FinishedSteps - Done + 1) * 3600000;
                    StepFinish."Finished At" := StepFinish."Started At" + 3000000;
                    StepFinish."Output Quantity" := Quantity;
                    StepFinish."Employee No." := 'EMP-0003';
                    StepFinishSvc.Process(StepFinish);
                    StepFinish.Insert(true);
                end;
            until RoutingLine.Next() = 0;
    end;
}
