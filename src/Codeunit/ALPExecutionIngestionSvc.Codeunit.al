codeunit 50010 "ALP Execution Ingestion Svc"
{
    var
        ProdOrderNotFoundErr: Label 'Production Order %1 not found or not in Released status', Comment = '%1 = Order No.';
        RoutingLineNotFoundErr: Label 'Routing line not found for Order %1, Operation %2', Comment = '%1 = Order No., %2 = Operation No.';
        WorkCenterMismatchLbl: Label 'WorkCenter mismatch: payload has %1, routing line has %2', Comment = '%1 = Payload WC, %2 = Routing WC';
        RejectedExceedsProducedErr: Label 'Qty. Rejected (%1) cannot exceed Qty. Produced (%2)', Comment = '%1 = Qty. Rejected, %2 = Qty. Produced';
        AvailabilityOutOfRangeErr: Label 'Availability (%1) must be between 0 and 1', Comment = '%1 = Availability value';
        ProductivityOutOfRangeErr: Label 'Productivity (%1) must be between 0 and 1', Comment = '%1 = Productivity value';
        OperationNotFoundForWCErr: Label 'No routing line found for Order %1, Work Center %2', Comment = '%1 = Order No., %2 = Work Center No.';
        MultipleOperationsForWCErr: Label 'Multiple routing lines found for Order %1, Work Center %2. Operation No. must be specified.', Comment = '%1 = Order No., %2 = Work Center No.';
        WorkCenterRequiredErr: Label 'Work Center No. is required when Operation No. is not specified';

    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid): Boolean
    var
        Inbox: Record "ALP Integration Inbox";
        ExistingExec: Record "ALP Operation Execution";
        ProdOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ExecCalcSvc: Codeunit "ALP Execution Calc Svc";
        ErrorText: Text;
        IsNew: Boolean;
    begin
        // Step 1: Idempotency check
        if Inbox.Get(MessageId) then
            if Inbox.Status = Inbox.Status::Processed then
                exit(true);
        // If previously failed, we'll retry

        // Step 2: Create/update inbox entry
        if not Inbox.Get(MessageId) then begin
            Inbox.Init();
            Inbox."Message Id" := MessageId;
            Inbox."Message Type" := 'ExecutionEvent';
            Inbox."Order No." := Exec."Order No.";
            Inbox."Operation No." := Exec."Operation No.";
            Inbox."Received At" := CurrentDateTime();
            Inbox.Status := Inbox.Status::Received;
            Inbox.Insert(true);
        end else begin
            Inbox.Status := Inbox.Status::Received;
            Inbox.Error := '';
            Inbox.Modify(true);
        end;

        // Step 3: Validate Production Order exists and is Released
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", Exec."Order No.");
        if not ProdOrder.FindFirst() then begin
            ErrorText := StrSubstNo(ProdOrderNotFoundErr, Exec."Order No.");
            MarkInboxFailed(Inbox, ErrorText);
            exit(false);
        end;

        // Step 3b: Validate business rules
        if Exec."Qty. Rejected" > Exec."Qty. Produced" then begin
            ErrorText := StrSubstNo(RejectedExceedsProducedErr, Exec."Qty. Rejected", Exec."Qty. Produced");
            MarkInboxFailed(Inbox, ErrorText);
            exit(false);
        end;

        if (Exec.Availability < 0) or (Exec.Availability > 1) then begin
            ErrorText := StrSubstNo(AvailabilityOutOfRangeErr, Exec.Availability);
            MarkInboxFailed(Inbox, ErrorText);
            exit(false);
        end;

        if (Exec.Productivity < 0) or (Exec.Productivity > 1) then begin
            ErrorText := StrSubstNo(ProductivityOutOfRangeErr, Exec.Productivity);
            MarkInboxFailed(Inbox, ErrorText);
            exit(false);
        end;

        // Step 3c: Resolve Operation No. dynamically
        if Exec."Operation No." = '' then begin
            // Operation not provided - resolve from Work Center
            if Exec."Work Center No." = '' then begin
                ErrorText := WorkCenterRequiredErr;
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;

            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", Exec."Order No.");
            ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
            ProdOrderRoutingLine.SetRange("No.", Exec."Work Center No.");

            if ProdOrderRoutingLine.Count() = 0 then begin
                ErrorText := StrSubstNo(OperationNotFoundForWCErr, Exec."Order No.", Exec."Work Center No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;

            if ProdOrderRoutingLine.Count() > 1 then begin
                // Multiple matches - ambiguous
                ErrorText := StrSubstNo(MultipleOperationsForWCErr, Exec."Order No.", Exec."Work Center No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;

            // Exactly one match - use it
            ProdOrderRoutingLine.FindFirst();
            Exec."Operation No." := ProdOrderRoutingLine."Operation No.";
        end else begin
            // Operation provided - validate it exists
            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", Exec."Order No.");
            ProdOrderRoutingLine.SetRange("Operation No.", Exec."Operation No.");
            if not ProdOrderRoutingLine.FindFirst() then begin
                ErrorText := StrSubstNo(RoutingLineNotFoundErr, Exec."Order No.", Exec."Operation No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;

            // Step 3d: Check WorkCenter mismatch (hard failure)
            if (Exec."Work Center No." <> '') and
               (ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center") and
               (ProdOrderRoutingLine."No." <> Exec."Work Center No.") then begin
                ErrorText := StrSubstNo(WorkCenterMismatchLbl, Exec."Work Center No.", ProdOrderRoutingLine."No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;
        end;

        // Step 4: Out-of-order guard
        IsNew := not ExistingExec.Get(Exec."Order No.", Exec."Operation No.");
        if not IsNew then
            if ExistingExec."Source Timestamp" >= Exec."Source Timestamp" then begin
                // Older message arrived later - skip update but mark as processed
                MarkInboxProcessed(Inbox);
                exit(true);
            end;

        // Step 5: Upsert execution record
        Exec."Last Update At" := CurrentDateTime();
        if IsNew then
            Exec.Insert(true)
        else begin
            ExistingExec.TransferFields(Exec, false);
            ExistingExec."Last Update At" := CurrentDateTime();
            ExistingExec.Modify(true);
        end;

        // Step 6: Update summary fields on Production Order
        ProdOrder."ALP Last Exec Update At" := CurrentDateTime();
        ProdOrder."ALP Execution Source" := Exec.Source;
        ProdOrder.Modify(true);

        // Step 6b: Update Routing Line with execution data
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", Exec."Order No.");
        ProdOrderRoutingLine.SetRange("Operation No.", Exec."Operation No.");
        if ProdOrderRoutingLine.FindFirst() then begin
            ProdOrderRoutingLine."ALP Actual Availability" := Exec.Availability;
            ProdOrderRoutingLine."ALP Actual Productivity" := Exec.Productivity;
            ProdOrderRoutingLine."ALP Qty. Produced" := Exec."Qty. Produced";
            ProdOrderRoutingLine."ALP Qty. Rejected" := Exec."Qty. Rejected";
            ProdOrderRoutingLine."ALP Source Timestamp" := Exec."Source Timestamp";
            ProdOrderRoutingLine.Modify(true);
        end;

        // Step 6c: Update Production Order aggregates (weighted averages)
        ExecCalcSvc.UpdateProductionOrderAggregates(ProdOrder);

        // Step 7: Mark inbox as processed
        MarkInboxProcessed(Inbox);
        exit(true);
    end;

    local procedure MarkInboxProcessed(var Inbox: Record "ALP Integration Inbox")
    begin
        Inbox.Status := Inbox.Status::Processed;
        Inbox."Processed At" := CurrentDateTime();
        Inbox.Modify(true);
    end;

    local procedure MarkInboxFailed(var Inbox: Record "ALP Integration Inbox"; ErrorText: Text)
    begin
        Inbox.Status := Inbox.Status::Failed;
        Inbox."Processed At" := CurrentDateTime();
        Inbox.Error := CopyStr(ErrorText, 1, MaxStrLen(Inbox.Error));
        Inbox.Modify(true);
    end;
}
