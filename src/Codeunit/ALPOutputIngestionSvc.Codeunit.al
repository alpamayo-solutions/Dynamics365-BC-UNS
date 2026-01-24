codeunit 50011 "ALP Output Ingestion Svc"
{
    var
        ProdOrderNotFoundErr: Label 'Production Order %1 not found or not in Released status', Comment = '%1 = Order No.';
        ScrapExceedsOutputErr: Label 'Scrap Quantity (%1) cannot exceed Output Quantity (%2)', Comment = '%1 = Scrap Qty, %2 = Output Qty';
        NegativeQuantityErr: Label '%1 (%2) cannot be negative', Comment = '%1 = Field Name, %2 = Value';

    procedure ProcessOutputEvent(var OutputInbox: Record "ALP Output Inbox"; MessageId: Guid): Boolean
    var
        ExistingInbox: Record "ALP Output Inbox";
        ProdOrder: Record "Production Order";
        ErrorText: Text;
    begin
        // Step 1: Idempotency check
        if ExistingInbox.Get(MessageId) then
            if ExistingInbox.Status = ExistingInbox.Status::Processed then
                exit(true);
        // If previously failed, we'll retry

        // Step 2: Create/update inbox entry
        if not ExistingInbox.Get(MessageId) then begin
            OutputInbox."Message Id" := MessageId;
            OutputInbox."Received At" := CurrentDateTime();
            OutputInbox.Status := OutputInbox.Status::Received;
            OutputInbox.Insert(true);
        end else begin
            OutputInbox := ExistingInbox;
            OutputInbox.Status := OutputInbox.Status::Received;
            OutputInbox.Error := '';
            OutputInbox.Modify(true);
        end;

        // Step 3: Validate Production Order exists and is Released
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", OutputInbox."Order No.");
        if not ProdOrder.FindFirst() then begin
            ErrorText := StrSubstNo(ProdOrderNotFoundErr, OutputInbox."Order No.");
            MarkInboxFailed(OutputInbox, ErrorText);
            exit(false);
        end;

        // Step 3b: Validate business rules
        if OutputInbox."Output Quantity" < 0 then begin
            ErrorText := StrSubstNo(NegativeQuantityErr, 'Output Quantity', OutputInbox."Output Quantity");
            MarkInboxFailed(OutputInbox, ErrorText);
            exit(false);
        end;

        if OutputInbox."Scrap Quantity" < 0 then begin
            ErrorText := StrSubstNo(NegativeQuantityErr, 'Scrap Quantity', OutputInbox."Scrap Quantity");
            MarkInboxFailed(OutputInbox, ErrorText);
            exit(false);
        end;

        if OutputInbox."Scrap Quantity" > OutputInbox."Output Quantity" then begin
            ErrorText := StrSubstNo(ScrapExceedsOutputErr, OutputInbox."Scrap Quantity", OutputInbox."Output Quantity");
            MarkInboxFailed(OutputInbox, ErrorText);
            exit(false);
        end;

        // Step 4: Out-of-order guard (check by Order+Operation, compare source timestamps)
        ExistingInbox.Reset();
        ExistingInbox.SetRange("Order No.", OutputInbox."Order No.");
        ExistingInbox.SetRange("Operation No.", OutputInbox."Operation No.");
        ExistingInbox.SetRange(Status, ExistingInbox.Status::Processed);
        if ExistingInbox.FindLast() then
            if ExistingInbox."Source Timestamp" >= OutputInbox."Source Timestamp" then begin
                // Older message arrived later - skip update but mark as processed
                MarkInboxProcessed(OutputInbox);
                exit(true);
            end;

        // Step 5: Data is stored in inbox - no auto-posting to Output Journal
        // This is intentional: output data is stored as facts for manual review

        // Step 6: Update summary fields on Production Order
        ProdOrder."ALP Last Output Update At" := CurrentDateTime();
        ProdOrder."ALP Output Source" := OutputInbox.Source;
        ProdOrder.Modify(true);

        // Step 7: Mark inbox as processed
        MarkInboxProcessed(OutputInbox);
        exit(true);
    end;

    local procedure MarkInboxProcessed(var Inbox: Record "ALP Output Inbox")
    begin
        Inbox.Status := Inbox.Status::Processed;
        Inbox."Processed At" := CurrentDateTime();
        Inbox.Modify(true);
    end;

    local procedure MarkInboxFailed(var Inbox: Record "ALP Output Inbox"; ErrorText: Text)
    begin
        Inbox.Status := Inbox.Status::Failed;
        Inbox."Processed At" := CurrentDateTime();
        Inbox.Error := CopyStr(ErrorText, 1, MaxStrLen(Inbox.Error));
        Inbox.Modify(true);
    end;
}
