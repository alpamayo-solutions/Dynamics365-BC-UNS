codeunit 50014 "ALP Execution Correction Svc"
{
    var
        UnsupportedActionErr: Label 'Correction action %1 is not supported', Comment = '%1 = action';
        WorkLogNotFoundForTargetErr: Label 'No work log entry found for target event ids %1', Comment = '%1 = target event ids';
        MultipleWorkLogsForTargetErr: Label 'Multiple work log entries found for target event ids %1', Comment = '%1 = target event ids';
        InvalidEventTypeErr: Label 'Unsupported event type %1', Comment = '%1 = event type';
        CorrectionIdRequiredErr: Label 'Correction Id is required';
        OrderNoRequiredErr: Label 'Order No. is required for correction action %1', Comment = '%1 = action';
        ReplacementStartRequiredErr: Label 'Replacement Start Time is required for correction action %1', Comment = '%1 = action';
        InvalidIntervalErr: Label 'Replacement End Time must be later than Replacement Start Time';
        ProdOrderNotFoundErr: Label 'Production Order %1 not found or not in Released status', Comment = '%1 = order no.';

    procedure ProcessCorrection(var Correction: Record "ALP Execution Correction"): Boolean
    var
        ExistingCorrection: Record "ALP Execution Correction";
        ErrorText: Text;
    begin
        if Correction."Correction Id" = '' then begin
            MarkFailed(Correction, CorrectionIdRequiredErr);
            exit(false);
        end;

        ExistingCorrection.SetRange("Correction Id", Correction."Correction Id");
        if ExistingCorrection.FindFirst() then begin
            Correction := ExistingCorrection;
            exit(Correction.Processed);
        end;

        Correction.Processed := false;
        Correction.Error := '';

        case NormalizeText(Correction.Action) of
            'REPLACEINTERVAL':
                begin
                    if not ApplyReplaceInterval(Correction, ErrorText) then begin
                        MarkFailed(Correction, ErrorText);
                        exit(false);
                    end;
                end;
            'CHANGEMETADATA':
                begin
                    if not ApplyChangeMetadata(Correction, ErrorText) then begin
                        MarkFailed(Correction, ErrorText);
                        exit(false);
                    end;
                end;
            'CANCELEVENT':
                begin
                    if not ApplyCancelEvent(Correction, ErrorText) then begin
                        MarkFailed(Correction, ErrorText);
                        exit(false);
                    end;
                end;
            'INSERTMISSINGEVENT':
                begin
                    if not ApplyInsertMissingEvent(Correction, ErrorText) then begin
                        MarkFailed(Correction, ErrorText);
                        exit(false);
                    end;
                end;
            else begin
                ErrorText := StrSubstNo(UnsupportedActionErr, Correction.Action);
                MarkFailed(Correction, ErrorText);
                exit(false);
            end;
        end;

        Correction.Processed := true;
        Correction.Error := '';
        Correction.Insert(true);
        exit(true);
    end;

    local procedure ApplyReplaceInterval(var Correction: Record "ALP Execution Correction"; var ErrorText: Text): Boolean
    var
        OriginalWorkLogEntry: Record "ALP Work Log Entry";
    begin
        if not ResolveTargetWorkLog(Correction, OriginalWorkLogEntry, ErrorText) then
            exit(false);

        if not CreateReplacementWorkLog(Correction, OriginalWorkLogEntry, true, ErrorText) then
            exit(false);

        InvalidateOriginalWorkLog(OriginalWorkLogEntry, OriginalWorkLogEntry.Status::Superseded, Correction."Correction Id");
        exit(true);
    end;

    local procedure ApplyChangeMetadata(var Correction: Record "ALP Execution Correction"; var ErrorText: Text): Boolean
    var
        OriginalWorkLogEntry: Record "ALP Work Log Entry";
    begin
        if not ResolveTargetWorkLog(Correction, OriginalWorkLogEntry, ErrorText) then
            exit(false);

        if not CreateReplacementWorkLog(Correction, OriginalWorkLogEntry, false, ErrorText) then
            exit(false);

        InvalidateOriginalWorkLog(OriginalWorkLogEntry, OriginalWorkLogEntry.Status::Superseded, Correction."Correction Id");
        exit(true);
    end;

    local procedure ApplyCancelEvent(var Correction: Record "ALP Execution Correction"; var ErrorText: Text): Boolean
    var
        OriginalWorkLogEntry: Record "ALP Work Log Entry";
    begin
        if not ResolveTargetWorkLog(Correction, OriginalWorkLogEntry, ErrorText) then
            exit(false);

        InvalidateOriginalWorkLog(OriginalWorkLogEntry, OriginalWorkLogEntry.Status::Cancelled, Correction."Correction Id");
        exit(true);
    end;

    local procedure ApplyInsertMissingEvent(var Correction: Record "ALP Execution Correction"; var ErrorText: Text): Boolean
    var
        EmptyWorkLogEntry: Record "ALP Work Log Entry";
    begin
        EmptyWorkLogEntry.Init();
        exit(CreateReplacementWorkLog(Correction, EmptyWorkLogEntry, true, ErrorText));
    end;

    local procedure CreateReplacementWorkLog(var Correction: Record "ALP Execution Correction"; var OriginalWorkLogEntry: Record "ALP Work Log Entry"; UseReplacementInterval: Boolean; var ErrorText: Text): Boolean
    var
        WorkLogSvc: Codeunit "ALP Work Log Svc";
        WorkLogEventType: Enum "ALP Work Log Event Type";
        OrderNo: Code[20];
        OperationNo: Code[10];
        WorkCenterNo: Code[20];
        OperatorId: Code[20];
        ItemNo: Code[20];
        ShiftCode: Code[10];
        DisruptionCode: Code[20];
        StartTime: DateTime;
        EndTime: DateTime;
        Source: Text[50];
        ReplacesEntryNo: Integer;
    begin
        OrderNo := PickCode20(Correction."Order No.", OriginalWorkLogEntry."Order No.");
        if OrderNo = '' then begin
            ErrorText := StrSubstNo(OrderNoRequiredErr, Correction.Action);
            exit(false);
        end;

        if Correction."Event Type" <> '' then begin
            if not ResolveWorkLogEventType(Correction."Event Type", WorkLogEventType, ErrorText) then
                exit(false);
        end else
            WorkLogEventType := OriginalWorkLogEntry."Event Type";

        OperationNo := PickCode10(Correction."Operation No.", OriginalWorkLogEntry."Operation No.");
        WorkCenterNo := PickCode20(Correction."Work Center No.", OriginalWorkLogEntry."Work Center No.");
        OperatorId := PickCode20(Correction."Operator Id", OriginalWorkLogEntry."Operator Id");
        ShiftCode := PickCode10(Correction."Shift Code", OriginalWorkLogEntry."Shift Code");
        DisruptionCode := OriginalWorkLogEntry."Disruption Code";
        Source := OriginalWorkLogEntry.Source;
        if Source = '' then
            Source := 'CORRECTION';

        if not ResolveItemNo(OrderNo, OriginalWorkLogEntry."Item No.", ItemNo, ErrorText) then
            exit(false);

        StartTime := OriginalWorkLogEntry."Start Time";
        EndTime := OriginalWorkLogEntry."End Time";
        if UseReplacementInterval then begin
            if Correction."Replacement Start Time" <> 0DT then
                StartTime := Correction."Replacement Start Time";
            if Correction."Replacement End Time" <> 0DT then
                EndTime := Correction."Replacement End Time";
        end;

        if not ValidateInterval(Correction.Action, StartTime, EndTime, ErrorText) then
            exit(false);

        ReplacesEntryNo := OriginalWorkLogEntry."Entry No.";
        WorkLogSvc.CreateCorrectionWorkLogEntry(
            Correction."Correction Id",
            OrderNo,
            OperationNo,
            WorkCenterNo,
            OperatorId,
            ItemNo,
            ShiftCode,
            WorkLogEventType,
            DisruptionCode,
            StartTime,
            EndTime,
            Source,
            Correction."Correction Id",
            ReplacesEntryNo);

        exit(true);
    end;

    local procedure ResolveTargetWorkLog(var Correction: Record "ALP Execution Correction"; var WorkLogEntry: Record "ALP Work Log Entry"; var ErrorText: Text): Boolean
    var
        Candidate: Record "ALP Work Log Entry";
        TargetEventId: Text;
        MatchCount: Integer;
    begin
        foreach TargetEventId in Correction."Target Event Ids".Split(',') do begin
            TargetEventId := DelChr(TargetEventId, '<>', ' ');
            if TargetEventId <> '' then begin
                Candidate.Reset();
                Candidate.SetRange("Message Id", CopyStr(TargetEventId, 1, MaxStrLen(Candidate."Message Id")));
                AddTargetMatches(Candidate, WorkLogEntry, MatchCount);

                Candidate.Reset();
                Candidate.SetRange("End Message Id", CopyStr(TargetEventId, 1, MaxStrLen(Candidate."End Message Id")));
                AddTargetMatches(Candidate, WorkLogEntry, MatchCount);
            end;
        end;

        if MatchCount = 0 then begin
            ErrorText := StrSubstNo(WorkLogNotFoundForTargetErr, Correction."Target Event Ids");
            exit(false);
        end;

        if MatchCount > 1 then begin
            ErrorText := StrSubstNo(MultipleWorkLogsForTargetErr, Correction."Target Event Ids");
            exit(false);
        end;

        exit(true);
    end;

    local procedure AddTargetMatches(var Candidate: Record "ALP Work Log Entry"; var WorkLogEntry: Record "ALP Work Log Entry"; var MatchCount: Integer)
    begin
        if Candidate.FindSet() then
            repeat
                if MatchCount = 0 then begin
                    WorkLogEntry := Candidate;
                    MatchCount := MatchCount + 1;
                end else
                    if Candidate."Entry No." <> WorkLogEntry."Entry No." then
                        MatchCount := MatchCount + 1;
            until Candidate.Next() = 0;
    end;

    local procedure InvalidateOriginalWorkLog(var WorkLogEntry: Record "ALP Work Log Entry"; NewStatus: Enum "ALP Work Log Status"; CorrectionId: Text[50])
    begin
        WorkLogEntry.Status := NewStatus;
        WorkLogEntry."Invalidated By Correction Id" := CorrectionId;
        WorkLogEntry.Modify(true);
    end;

    local procedure ResolveWorkLogEventType(EventTypeText: Text[20]; var WorkLogEventType: Enum "ALP Work Log Event Type"; var ErrorText: Text): Boolean
    begin
        case NormalizeText(EventTypeText) of
            'EXECUTION':
                WorkLogEventType := WorkLogEventType::Execution;
            'DISRUPTION':
                WorkLogEventType := WorkLogEventType::Disruption;
            else begin
                ErrorText := StrSubstNo(InvalidEventTypeErr, EventTypeText);
                exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure ResolveItemNo(OrderNo: Code[20]; FallbackItemNo: Code[20]; var ItemNo: Code[20]; var ErrorText: Text): Boolean
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", OrderNo);
        if not ProdOrder.FindFirst() then begin
            ErrorText := StrSubstNo(ProdOrderNotFoundErr, OrderNo);
            exit(false);
        end;

        ItemNo := ProdOrder."Source No.";
        if ItemNo = '' then
            ItemNo := FallbackItemNo;

        exit(true);
    end;

    local procedure ValidateInterval(Action: Text[30]; StartTime: DateTime; EndTime: DateTime; var ErrorText: Text): Boolean
    begin
        if StartTime = 0DT then begin
            ErrorText := StrSubstNo(ReplacementStartRequiredErr, Action);
            exit(false);
        end;

        if (EndTime <> 0DT) and (EndTime <= StartTime) then begin
            ErrorText := InvalidIntervalErr;
            exit(false);
        end;

        exit(true);
    end;

    local procedure PickCode20(Preferred: Code[20]; Fallback: Code[20]): Code[20]
    begin
        if Preferred <> '' then
            exit(Preferred);
        exit(Fallback);
    end;

    local procedure PickCode10(Preferred: Code[10]; Fallback: Code[10]): Code[10]
    begin
        if Preferred <> '' then
            exit(Preferred);
        exit(Fallback);
    end;

    local procedure NormalizeText(Value: Text): Text
    begin
        exit(DelChr(UpperCase(Value), '=', '_ '));
    end;

    local procedure MarkFailed(var Correction: Record "ALP Execution Correction"; ErrorText: Text)
    begin
        Correction.Processed := false;
        Correction.Error := CopyStr(ErrorText, 1, MaxStrLen(Correction.Error));
        Correction.Insert(true);
    end;
}
