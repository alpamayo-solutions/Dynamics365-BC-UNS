codeunit 50153 "ALP Person Time Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Helper: Codeunit "ALP Test Helper";

    local procedure Slice(var PersonTime: Record "ALP Person Time Entry"; SessionId: Text[50]; SessionKey: Text[100]; SliceNo: Integer; EmployeeNo: Code[20]; StepId: Text[100]; FromTime: Time; ToTime: Time)
    var
        PersonTimeSvc: Codeunit "ALP Person Time Svc";
    begin
        Clear(PersonTime);
        PersonTime."Event Id" := CopyStr(SessionKey + ':' + Format(SliceNo), 1, MaxStrLen(PersonTime."Event Id"));
        PersonTime."Session Id" := SessionId;
        PersonTime."Session Key" := SessionKey;
        PersonTime."Employee No." := EmployeeNo;
        PersonTime."Step Id" := StepId;
        PersonTime."Started At" := CreateDateTime(WorkDate(), FromTime);
        PersonTime."Ended At" := CreateDateTime(WorkDate(), ToTime);
        PersonTimeSvc.Process(PersonTime);
        PersonTime.Insert(true);
    end;

    [Test]
    procedure Slice_IsRecordedOnStep()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PersonTime: Record "ALP Person Time Entry";
        SessionId: Text[50];
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        SessionId := CopyStr(Format(CreateGuid()), 1, 50);

        Slice(PersonTime, SessionId, SessionId + ':0-a', 0, Helper.CreateEmployee(), Helper.StepId(ProductionOrder, '10'), 080000T, 093000T);

        Assert.AreEqual(PersonTime.Status::Active, PersonTime.Status, 'Status');
        Assert.AreEqual(ProductionOrder."No.", PersonTime."Prod. Order No.", 'Order');
        Assert.AreEqual(90, PersonTime.Minutes, 'Minutes');
    end;

    [Test]
    procedure NewRevision_SupersedesEarlierSlices()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PersonTime: Record "ALP Person Time Entry";
        EmployeeNo: Code[20];
        SessionId: Text[50];
        StepId: Text[100];
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        EmployeeNo := Helper.CreateEmployee();
        StepId := Helper.StepId(ProductionOrder, '10');
        SessionId := CopyStr(Format(CreateGuid()), 1, 50);
        Slice(PersonTime, SessionId, SessionId + ':0-a', 0, EmployeeNo, StepId, 080000T, 090000T);
        Slice(PersonTime, SessionId, SessionId + ':0-a', 1, EmployeeNo, StepId, 090000T, 100000T);

        Slice(PersonTime, SessionId, SessionId + ':1-b', 0, EmployeeNo, StepId, 080000T, 093000T);

        PersonTime.Reset();
        PersonTime.SetRange("Session Id", SessionId);
        PersonTime.SetRange(Status, PersonTime.Status::Active);
        Assert.RecordCount(PersonTime, 1);
        PersonTime.SetRange(Status, PersonTime.Status::Superseded);
        Assert.RecordCount(PersonTime, 2);
    end;

    [Test]
    procedure Cancel_CancelsWholeSession()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PersonTime: Record "ALP Person Time Entry";
        PersonTimeSvc: Codeunit "ALP Person Time Svc";
        SessionId: Text[50];
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        SessionId := CopyStr(Format(CreateGuid()), 1, 50);
        Slice(PersonTime, SessionId, SessionId + ':0-a', 0, Helper.CreateEmployee(), Helper.StepId(ProductionOrder, '10'), 080000T, 090000T);

        Clear(PersonTime);
        PersonTime."Event Id" := CopyStr(SessionId + ':cancel', 1, 100);
        PersonTime."Session Id" := SessionId;
        PersonTime.Cancelled := true;
        PersonTimeSvc.Process(PersonTime);
        PersonTime.Insert(true);

        PersonTime.Reset();
        PersonTime.SetRange("Session Id", SessionId);
        PersonTime.SetRange(Status, PersonTime.Status::Active);
        Assert.RecordIsEmpty(PersonTime);
    end;

    [Test]
    procedure UnknownEmployee_IsRefused()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PersonTime: Record "ALP Person Time Entry";
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        asserterror Slice(PersonTime, 's1', 's1:0-a', 0, 'NOSUCHEMP', Helper.StepId(ProductionOrder, '10'), 080000T, 090000T);
        Assert.AssertRecordNotFound();
    end;
}
