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
        OpenParticipantNotFoundErr: Label 'No unique open participant interval found for Order %1, Operation %2, Work Center %3, Operator %4', Comment = '%1 = Order No., %2 = Operation No., %3 = Work Center No., %4 = Operator Id';
        DisruptionStartTok: Label 'DISRUPTIONSTART', Locked = true;
        DisruptionEndTok: Label 'DISRUPTIONEND', Locked = true;
        OperatorSignoffTok: Label 'OPERATORSIGNOFF', Locked = true;

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
    /// EventType: 'DisruptionStart' creates a disruption work log entry.
    /// EventType: 'DisruptionEnd' closes the open disruption work log entry.
    /// EventType: '' or 'End' uses existing KPI-based behavior + closes the execution work log entry.
    /// </summary>
    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid; EventType: Text[20]; OperatorId: Code[20]; ShiftCode: Code[10]): Boolean
    begin
        exit(ProcessExecutionEvent(Exec, MessageId, EventType, OperatorId, ShiftCode, ''));
    end;

    /// <summary>
    /// Main entry point for execution event processing with source event id routing.
    /// SourceEventId is the UNS/UI event id used for work-log idempotency and correction targeting.
    /// If SourceEventId is empty, MessageId remains the backward-compatible source id.
    /// </summary>
    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid; EventType: Text[20]; OperatorId: Code[20]; ShiftCode: Code[10]; SourceEventId: Text[50]): Boolean
    begin
        exit(ProcessExecutionEvent(Exec, MessageId, EventType, OperatorId, ShiftCode, SourceEventId, 0DT, ''));
    end;

    procedure ProcessExecutionEvent(var Exec: Record "ALP Operation Execution"; MessageId: Guid; EventType: Text[20]; OperatorId: Code[20]; ShiftCode: Code[10]; SourceEventId: Text[50]; TimestampStart: DateTime; SourceStartEventId: Text[50]): Boolean
    var
        Inbox: Record "ALP Integration Inbox";
        ProdOrder: Record "Production Order";
        ErrorText: Text;
        IsNewInbox: Boolean;
    begin
        SourceEventId := NormalizeSourceEventId(SourceEventId, MessageId);
        SourceStartEventId := NormalizeOptionalSourceEventId(SourceStartEventId);

        if FindInboxBySourceEventId(SourceEventId, Inbox) then begin
            if Inbox.Status = Inbox.Status::Processed then
                exit(true);
        end else
            if Inbox.Get(MessageId) then begin
                if Inbox.Status = Inbox.Status::Processed then
                    exit(true);
            end else begin
                IsNewInbox := true;
            end;

        // If previously failed, we'll retry in the same inbox row.
        if IsNewInbox then begin
            Inbox.Init();
            Inbox."Message Id" := MessageId;
            SetInboxReceived(Inbox, Exec, SourceEventId);
            Inbox.Insert(true);
        end else begin
            SetInboxReceived(Inbox, Exec, SourceEventId);
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

        EventType := DelChr(UpperCase(EventType), '=', '_ ');

        // Route based on event type
        if EventType = 'START' then begin
            IngestStartEvent(Exec, ProdOrder, SourceEventId, OperatorId, ShiftCode);
            MarkInboxProcessed(Inbox);
            exit(true);
        end;

        if EventType = OperatorSignoffTok then begin
            if not IngestOperatorSignoffEvent(Exec, SourceEventId, OperatorId, SourceStartEventId) then begin
                ErrorText := StrSubstNo(OpenParticipantNotFoundErr, Exec."Order No.", Exec."Operation No.", Exec."Work Center No.", OperatorId);
                MarkInboxFailed(Inbox, ErrorText);
                exit(false);
            end;
            RefreshAttributions();
            MarkInboxProcessed(Inbox);
            exit(true);
        end;

        if EventType = DisruptionStartTok then begin
            IngestDisruptionStartEvent(Exec, ProdOrder, SourceEventId, OperatorId, ShiftCode);
            MarkInboxProcessed(Inbox);
            exit(true);
        end;

        if EventType = DisruptionEndTok then begin
            IngestDisruptionEndEvent(Exec, SourceEventId);
            MarkInboxProcessed(Inbox);
            exit(true);
        end;

        // End event (default): validate KPIs and process
        if not ValidateEndEventKPIs(Exec, Inbox) then
            exit(false);

        IngestEndEvent(Exec, ProdOrder, SourceEventId, OperatorId, ShiftCode, TimestampStart, SourceStartEventId);
        RefreshAttributions();
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

            if (Exec."Work Center No." = '') and (ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center") then
                Exec."Work Center No." := ProdOrderRoutingLine."No.";
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

    local procedure IngestStartEvent(var Exec: Record "ALP Operation Execution"; var ProdOrder: Record "Production Order"; SourceEventId: Text[50]; OperatorId: Code[20]; ShiftCode: Code[10])
    var
        ExistingExec: Record "ALP Operation Execution";
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
        IsNew: Boolean;
    begin
        IsNew := not ExistingExec.Get(Exec."Order No.", Exec."Operation No.");

        if IsNew then begin
            Exec."Started At" := Exec."Source Timestamp";
            if OperatorId <> '' then
                Exec."Operator Id" := OperatorId;
            Exec."Last Update At" := CurrentDateTime();
            Exec.Insert(true);

            ProdOrder."ALP Last Exec Update At" := CurrentDateTime();
            ProdOrder."ALP Execution Source" := Exec.Source;
            ProdOrder.Modify(true);
        end else
            if ExistingExec."Source Timestamp" < Exec."Source Timestamp" then begin
                ExistingExec."Started At" := Exec."Source Timestamp";
                if OperatorId <> '' then
                    ExistingExec."Operator Id" := OperatorId;
                ExistingExec."Source Timestamp" := Exec."Source Timestamp";
                ExistingExec."Last Update At" := CurrentDateTime();
                ExistingExec.Modify(true);

                ProdOrder."ALP Last Exec Update At" := CurrentDateTime();
                ProdOrder."ALP Execution Source" := Exec.Source;
                ProdOrder.Modify(true);
            end;

        // Create work log entry — no KPI aggregation for Start events
        WorkLogSvc.CreateWorkLogEntry(
            SourceEventId,
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

    local procedure IngestDisruptionStartEvent(var Exec: Record "ALP Operation Execution"; var ProdOrder: Record "Production Order"; SourceEventId: Text[50]; OperatorId: Code[20]; ShiftCode: Code[10])
    var
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
    begin
        WorkLogSvc.CreateWorkLogEntry(
            SourceEventId,
            Exec."Order No.",
            Exec."Operation No.",
            Exec."Work Center No.",
            OperatorId,
            ProdOrder."Source No.",
            ShiftCode,
            WorkLogEventType::Disruption,
            '',
            Exec."Source Timestamp",
            Exec.Source);
    end;

    local procedure IngestEndEvent(var Exec: Record "ALP Operation Execution"; var ProdOrder: Record "Production Order"; SourceEventId: Text[50]; OperatorId: Code[20]; ShiftCode: Code[10]; TimestampStart: DateTime; SourceStartEventId: Text[50])
    var
        ExistingExec: Record "ALP Operation Execution";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ExecCalcSvc: Codeunit "ALP Execution Calc Svc";
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
        ExistingOperatorId: Code[20];
        ExistingWorkCenterNo: Code[20];
        ExistingStartedAt: DateTime;
        IsNew: Boolean;
        StartMessageId: Text[50];
    begin
        if TimestampStart <> 0DT then begin
            if SourceStartEventId <> '' then begin
                if not WorkLogSvc.CloseOneOpenWorkLogEntry(Exec."Order No.", Exec."Operation No.", Exec."Work Center No.", OperatorId, WorkLogEventType::Execution, Exec."Source Timestamp", SourceEventId, SourceStartEventId) then
                    WorkLogSvc.CreateClosedExecutionWorkLogEntry(SourceStartEventId, SourceEventId, Exec."Order No.", Exec."Operation No.", Exec."Work Center No.", OperatorId, ProdOrder."Source No.", ShiftCode, TimestampStart, Exec."Source Timestamp", Exec.Source);
            end else begin
                StartMessageId := CopyStr(SourceEventId + '-start', 1, MaxStrLen(StartMessageId));
                WorkLogSvc.CreateClosedExecutionWorkLogEntry(StartMessageId, SourceEventId, Exec."Order No.", Exec."Operation No.", Exec."Work Center No.", OperatorId, ProdOrder."Source No.", ShiftCode, TimestampStart, Exec."Source Timestamp", Exec.Source);
            end;
        end else
            WorkLogSvc.CloseAllOpenWorkLogEntries(Exec."Order No.", Exec."Operation No.", Exec."Work Center No.", WorkLogEventType::Execution, Exec."Source Timestamp", SourceEventId);

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
            ExistingOperatorId := ExistingExec."Operator Id";
            ExistingWorkCenterNo := ExistingExec."Work Center No.";
            ExistingStartedAt := ExistingExec."Started At";
            ExistingExec.TransferFields(Exec, false);
            if ExistingStartedAt <> 0DT then
                ExistingExec."Started At" := ExistingStartedAt;
            if OperatorId = '' then
                ExistingExec."Operator Id" := ExistingOperatorId;
            if (ExistingExec."Work Center No." = '') and (ExistingWorkCenterNo <> '') then
                ExistingExec."Work Center No." := ExistingWorkCenterNo;
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

    end;

    local procedure IngestOperatorSignoffEvent(var Exec: Record "ALP Operation Execution"; SourceEventId: Text[50]; OperatorId: Code[20]; SourceStartEventId: Text[50]): Boolean
    var
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
    begin
        exit(WorkLogSvc.CloseOneOpenWorkLogEntry(
            Exec."Order No.",
            Exec."Operation No.",
            Exec."Work Center No.",
            OperatorId,
            WorkLogEventType::Execution,
            Exec."Source Timestamp",
            SourceEventId,
            SourceStartEventId));
    end;

    local procedure IngestDisruptionEndEvent(var Exec: Record "ALP Operation Execution"; SourceEventId: Text[50])
    var
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
    begin
        WorkLogSvc.CloseWorkLogEntryWithEndMessageId(
            Exec."Order No.",
            Exec."Operation No.",
            WorkLogEventType::Disruption,
            Exec."Source Timestamp",
            SourceEventId);
    end;

    local procedure RefreshAttributions()
    var
        AttributionSvc: Codeunit "ALP Execution Attribution Svc";
    begin
        AttributionSvc.RefreshAll();
    end;

    local procedure NormalizeSourceEventId(SourceEventId: Text[50]; MessageId: Guid): Text[50]
    begin
        SourceEventId := CopyStr(DelChr(SourceEventId, '<>', ' '), 1, MaxStrLen(SourceEventId));
        if SourceEventId = '' then
            SourceEventId := CopyStr(Format(MessageId), 1, MaxStrLen(SourceEventId));
        exit(SourceEventId);
    end;

    local procedure NormalizeOptionalSourceEventId(SourceEventId: Text[50]): Text[50]
    begin
        exit(CopyStr(DelChr(SourceEventId, '<>', ' '), 1, MaxStrLen(SourceEventId)));
    end;

    local procedure FindInboxBySourceEventId(SourceEventId: Text[50]; var Inbox: Record "ALP Integration Inbox"): Boolean
    begin
        if SourceEventId = '' then
            exit(false);

        Inbox.Reset();
        Inbox.SetRange("Source Event Id", SourceEventId);
        if Inbox.FindFirst() then
            exit(true);

        Inbox.Reset();
        exit(false);
    end;

    local procedure SetInboxReceived(var Inbox: Record "ALP Integration Inbox"; var Exec: Record "ALP Operation Execution"; SourceEventId: Text[50])
    begin
        Inbox."Message Type" := 'ExecutionEvent';
        Inbox."Order No." := Exec."Order No.";
        Inbox."Operation No." := Exec."Operation No.";
        Inbox."Source Event Id" := SourceEventId;
        Inbox."Received At" := CurrentDateTime();
        Inbox.Status := Inbox.Status::Received;
        Inbox.Error := '';
        Inbox.Warning := '';
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
