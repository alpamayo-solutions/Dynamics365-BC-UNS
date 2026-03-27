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

    /// <summary>
    /// Backward-compatible overload that defaults to End event behavior.
    /// </summary>
    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid): Boolean
    begin
        exit(ProcessExecutionEvent(Exec, MessageId, '', '', ''));
    end;

    /// <summary>
    /// Main entry point for execution event processing with v3 event type routing.
    /// EventType: 'Start' creates execution record with StartedAt + work log entry, skips KPIs.
    /// EventType: '' or 'End' uses existing KPI-based behavior + closes work log entry.
    /// </summary>
    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid; EventType: Text[10]; OperatorId: Code[20]; ShiftCode: Code[10]): Boolean
    var
        Inbox: Record "ALP Integration Inbox";
        ProdOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ErrorText: Text;
    begin
        if Inbox.Get(MessageId) then
            if Inbox.Status = Inbox.Status::Processed then
                exit(true);
        // If previously failed, we'll retry
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

        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", Exec."Order No.");
        if not ProdOrder.FindFirst() then begin
            ErrorText := StrSubstNo(ProdOrderNotFoundErr, Exec."Order No.");
            MarkInboxFailed(Inbox, ErrorText);
            exit(false);
        end;

        // Resolve Operation No. from Work Center if not provided
        if not ResolveOperationNo(Exec, Inbox) then
            exit(false);

        // Route based on event type
        if UpperCase(EventType) = 'START' then begin
            IngestStartEvent(Exec, ProdOrder, MessageId, OperatorId, ShiftCode);
            MarkInboxProcessed(Inbox);
            exit(true);
        end;

        // End event (default): validate KPIs and process
        if not ValidateEndEventKPIs(Exec, Inbox) then
            exit(false);

        IngestEndEvent(Exec, ProdOrder, OperatorId, ShiftCode);
        MarkInboxProcessed(Inbox);
        exit(true);
    end;

    local procedure ResolveOperationNo(var Exec: Record "ALP Operation Execution"; var Inbox: Record "ALP Integration Inbox"): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ErrorText: Text;
    begin
        if Exec."Operation No." = '' then begin
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
                ErrorText := StrSubstNo(MultipleOperationsForWCErr, Exec."Order No.", Exec."Work Center No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;

            ProdOrderRoutingLine.FindFirst();
            Exec."Operation No." := ProdOrderRoutingLine."Operation No.";
        end else begin
            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", Exec."Order No.");
            ProdOrderRoutingLine.SetRange("Operation No.", Exec."Operation No.");
            if not ProdOrderRoutingLine.FindFirst() then begin
                ErrorText := StrSubstNo(RoutingLineNotFoundErr, Exec."Order No.", Exec."Operation No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;

            if (Exec."Work Center No." <> '') and
               (ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center") and
               (ProdOrderRoutingLine."No." <> Exec."Work Center No.") then begin
                ErrorText := StrSubstNo(WorkCenterMismatchLbl, Exec."Work Center No.", ProdOrderRoutingLine."No.");
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure ValidateEndEventKPIs(var Exec: Record "ALP Operation Execution"; var Inbox: Record "ALP Integration Inbox"): Boolean
    var
        ErrorText: Text;
    begin
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

        exit(true);
    end;

    local procedure IngestStartEvent(var Exec: Record "ALP Operation Execution"; var ProdOrder: Record "Production Order"; MessageId: Guid; OperatorId: Code[20]; ShiftCode: Code[10])
    var
        ExistingExec: Record "ALP Operation Execution";
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
        IsNew: Boolean;
    begin
        // Create or update OpExec record with StartedAt and OperatorId
        IsNew := not ExistingExec.Get(Exec."Order No.", Exec."Operation No.");

        Exec."Started At" := Exec."Source Timestamp";
        Exec."Operator Id" := OperatorId;
        Exec."Last Update At" := CurrentDateTime();

        if IsNew then
            Exec.Insert(true)
        else begin
            ExistingExec."Started At" := Exec."Source Timestamp";
            ExistingExec."Operator Id" := OperatorId;
            ExistingExec."Last Update At" := CurrentDateTime();
            ExistingExec.Modify(true);
        end;

        ProdOrder."ALP Last Exec Update At" := CurrentDateTime();
        ProdOrder."ALP Execution Source" := Exec.Source;
        ProdOrder.Modify(true);

        // Create work log entry — no KPI aggregation for Start events
        WorkLogSvc.CreateWorkLogEntry(
            Format(MessageId),
            Exec."Order No.",
            Exec."Operation No.",
            Exec."Work Center No.",
            OperatorId,
            ProdOrder."Source No.",
            ShiftCode,
            WorkLogEventType::Execution,
            '',
            Exec."Source Timestamp",
            Exec.Source);
    end;

    local procedure IngestEndEvent(var Exec: Record "ALP Operation Execution"; var ProdOrder: Record "Production Order"; OperatorId: Code[20]; ShiftCode: Code[10])
    var
        ExistingExec: Record "ALP Operation Execution";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ExecCalcSvc: Codeunit "ALP Execution Calc Svc";
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
        IsNew: Boolean;
    begin
        IsNew := not ExistingExec.Get(Exec."Order No.", Exec."Operation No.");
        if not IsNew then
            if ExistingExec."Source Timestamp" >= Exec."Source Timestamp" then
                // Older message arrived later - skip update
                exit;

        // Preserve OperatorId if provided
        if OperatorId <> '' then
            Exec."Operator Id" := OperatorId;

        Exec."Last Update At" := CurrentDateTime();
        if IsNew then
            Exec.Insert(true)
        else begin
            ExistingExec.TransferFields(Exec, false);
            ExistingExec."Last Update At" := CurrentDateTime();
            ExistingExec.Modify(true);
        end;

        ProdOrder."ALP Last Exec Update At" := CurrentDateTime();
        ProdOrder."ALP Execution Source" := Exec.Source;
        ProdOrder.Modify(true);

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

        ExecCalcSvc.UpdateProductionOrderAggregates(ProdOrder);

        // Close open work log entry for this operation
        WorkLogSvc.CloseWorkLogEntry(Exec."Order No.", Exec."Operation No.", WorkLogEventType::Execution, Exec."Source Timestamp");
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
