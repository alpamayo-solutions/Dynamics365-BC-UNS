codeunit 50010 "ALP Execution Ingestion Svc"
{
    var
        ProdOrderNotFoundErr: Label 'Production Order %1 not found or not in Released status', Comment = '%1 = Order No.';
        RoutingLineNotFoundErr: Label 'Routing line not found for Order %1, Operation %2', Comment = '%1 = Order No., %2 = Operation No.';
        WorkCenterMismatchLbl: Label 'WorkCenter mismatch: payload has %1, routing line has %2', Comment = '%1 = Payload WC, %2 = Routing WC';
        RejectedExceedsPartsErr: Label 'nRejected (%1) cannot exceed nParts (%2)', Comment = '%1 = nRejected, %2 = nParts';
        AvailabilityOutOfRangeErr: Label 'Availability (%1) must be between 0 and 1', Comment = '%1 = Availability value';
        ProductivityOutOfRangeErr: Label 'Productivity (%1) must be between 0 and 1', Comment = '%1 = Productivity value';

    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid): Boolean
    var
        Inbox: Record "ALP Integration Inbox";
        ExistingExec: Record "ALP Operation Execution";
        ProdOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ExecCalcSvc: Codeunit "ALP Execution Calc Svc";
        ErrorText: Text;
        WarningText: Text;
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
        if Exec."nRejected" > Exec."nParts" then begin
            ErrorText := StrSubstNo(RejectedExceedsPartsErr, Exec."nRejected", Exec."nParts");
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

        // Step 3c: Validate Routing Line exists for (OrderNo, OperationNo)
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", Exec."Order No.");
        ProdOrderRoutingLine.SetRange("Operation No.", Exec."Operation No.");
        if not ProdOrderRoutingLine.FindFirst() then begin
            ErrorText := StrSubstNo(RoutingLineNotFoundErr, Exec."Order No.", Exec."Operation No.");
            MarkInboxFailed(Inbox, ErrorText);
            exit(false);
        end;

        // Step 3d: Check WorkCenter mismatch (warning only, don't fail)
        if (Exec."Work Center No." <> '') and
           (ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center") and
           (ProdOrderRoutingLine."No." <> Exec."Work Center No.") then
            WarningText := StrSubstNo(WorkCenterMismatchLbl, Exec."Work Center No.", ProdOrderRoutingLine."No.");

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
            ProdOrderRoutingLine."ALP nParts" := Exec."nParts";
            ProdOrderRoutingLine."ALP nRejected" := Exec."nRejected";
            ProdOrderRoutingLine."ALP Source Timestamp" := Exec."Source Timestamp";
            ProdOrderRoutingLine.Modify(true);
        end;

        // Step 6c: Update Production Order aggregates (weighted averages)
        ExecCalcSvc.UpdateProductionOrderAggregates(ProdOrder);

        // Step 7: Mark inbox as processed (include warning if any)
        if WarningText <> '' then begin
            Inbox.Warning := CopyStr(WarningText, 1, MaxStrLen(Inbox.Warning));
            Inbox.Modify(true);
        end;
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
