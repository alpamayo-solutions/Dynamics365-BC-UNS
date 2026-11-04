codeunit 50154 "ALP Order Note Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Helper: Codeunit "ALP Test Helper";

    local procedure AddNote(var OrderNote: Record "ALP Order Note"; NoteId: Text[100]; OrderNo: Code[20])
    var
        OrderNoteSvc: Codeunit "ALP Order Note Svc";
    begin
        Clear(OrderNote);
        OrderNote."Note Id" := NoteId;
        OrderNote."Prod. Order No." := OrderNo;
        OrderNote."Note Text" := 'Nozzle cleaned after batch';
        OrderNote.Author := 'Operator';
        OrderNoteSvc.Process(OrderNote);
        OrderNote.Insert(true);
    end;

    [Test]
    procedure Note_CreatesRecordLinkAndDeleteRemovesIt()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OrderNote: Record "ALP Order Note";
        RecordLink: Record "Record Link";
        LinkId: Integer;
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        AddNote(OrderNote, CopyStr(Format(CreateGuid()), 1, 100), ProductionOrder."No.");

        LinkId := OrderNote."Record Link Id";
        Assert.IsTrue(RecordLink.Get(LinkId), 'A note must exist on the order');
        Assert.AreEqual(ProductionOrder.RecordId(), RecordLink."Record ID", 'Note is attached to the order');

        OrderNote.Delete(true);
        Assert.IsFalse(RecordLink.Get(LinkId), 'Deleting the row removes the note');
    end;

    [Test]
    procedure Note_SameIdTwice_WritesOneNote()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OrderNote: Record "ALP Order Note";
        NoteId: Text[100];
    begin
        Helper.CreateReleasedOrderTwoSteps(ProductionOrder, WorkCenter, 10);
        NoteId := CopyStr(Format(CreateGuid()), 1, 100);
        AddNote(OrderNote, NoteId, ProductionOrder."No.");
        AddNote(OrderNote, NoteId, ProductionOrder."No.");

        Assert.AreEqual(OrderNote.Result::Duplicate, OrderNote.Result, 'Second write is a duplicate');
        Assert.AreEqual(0, OrderNote."Record Link Id", 'No second note');
    end;
}
