/// <summary>
/// Writes an Execution app note as a standard note (record link) on the released production order.
/// A repeat of a Note Id is answered with Result = Duplicate and writes no second note.
/// </summary>
codeunit 50103 "ALP Order Note Svc"
{
    var
        TextRequiredErr: Label 'Note text is required.';
        NoteTextTok: Label '%1\— %2 (PREKIT Execution)', Comment = '%1 = note text, %2 = author';

    procedure Process(var OrderNote: Record "ALP Order Note")
    var
        Existing: Record "ALP Order Note";
        ProductionOrder: Record "Production Order";
        RecordLink: Record "Record Link";
        RecordLinkMgt: Codeunit "Record Link Management";
    begin
        if OrderNote."Note Text" = '' then
            Error(TextRequiredErr);

        Existing.SetRange("Note Id", OrderNote."Note Id");
        Existing.SetFilter(Result, '<>%1', Existing.Result::Duplicate);
        if not Existing.IsEmpty() then begin
            OrderNote.Result := OrderNote.Result::Duplicate;
            exit;
        end;

        ProductionOrder.Get(ProductionOrder.Status::Released, OrderNote."Prod. Order No.");

        RecordLink.Init();
        RecordLink."Record ID" := ProductionOrder.RecordId();
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := CopyStr(OrderNote."Note Text", 1, MaxStrLen(RecordLink.Description));
        RecordLink.Created := CurrentDateTime();
        RecordLink."User ID" := CopyStr(UserId(), 1, MaxStrLen(RecordLink."User ID"));
        RecordLink.Company := CopyStr(CompanyName(), 1, MaxStrLen(RecordLink.Company));
        RecordLink.Insert(true);
        RecordLinkMgt.WriteNote(RecordLink, StrSubstNo(NoteTextTok, OrderNote."Note Text", OrderNote.Author));
        RecordLink.Modify(true);

        OrderNote."Record Link Id" := RecordLink."Link ID";
        OrderNote.Result := OrderNote.Result::Recorded;
    end;
}
