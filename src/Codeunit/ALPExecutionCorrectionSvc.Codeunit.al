codeunit 50014 "ALP Execution Correction Svc"
{
    var
        UnsupportedActionErr: Label 'Correction action %1 is not supported', Comment = '%1 = action';
        WorkLogNotFoundErr: Label 'No work log entry found for Order %1, Operation %2, Event Type %3', Comment = '%1 = order, %2 = operation, %3 = event type';
        InvalidEventTypeErr: Label 'Unsupported event type %1', Comment = '%1 = event type';

    procedure ProcessCorrection(var Correction: Record "ALP Execution Correction"): Boolean
    var
        ErrorText: Text;
    begin
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
        WorkLogEntry: Record "ALP Work Log Entry";
        DurationMs: BigInteger;
    begin
        if not GetLatestMatchingWorkLog(Correction, WorkLogEntry, ErrorText) then
            exit(false);

        if Correction."Replacement Start Time" <> 0DT then
            WorkLogEntry."Start Time" := Correction."Replacement Start Time";
        if Correction."Replacement End Time" <> 0DT then
            WorkLogEntry."End Time" := Correction."Replacement End Time";
        if Correction."Operator Id" <> '' then
            WorkLogEntry."Operator Id" := Correction."Operator Id";
        if Correction."Shift Code" <> '' then
            WorkLogEntry."Shift Code" := Correction."Shift Code";
        if Correction."Work Center No." <> '' then
            WorkLogEntry."Work Center No." := Correction."Work Center No.";

        if WorkLogEntry."End Time" <> 0DT then begin
            DurationMs := WorkLogEntry."End Time" - WorkLogEntry."Start Time";
            if DurationMs > 0 then
                WorkLogEntry."Duration Sec" := DurationMs div 1000
            else
                WorkLogEntry."Duration Sec" := 0;
            WorkLogEntry.Status := WorkLogEntry.Status::Closed;
        end else
            WorkLogEntry.Status := WorkLogEntry.Status::Open;

        WorkLogEntry.Modify(true);
        exit(true);
    end;

    local procedure ApplyChangeMetadata(var Correction: Record "ALP Execution Correction"; var ErrorText: Text): Boolean
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        if not GetLatestMatchingWorkLog(Correction, WorkLogEntry, ErrorText) then
            exit(false);

        if Correction."Operator Id" <> '' then
            WorkLogEntry."Operator Id" := Correction."Operator Id";
        if Correction."Shift Code" <> '' then
            WorkLogEntry."Shift Code" := Correction."Shift Code";
        if Correction."Work Center No." <> '' then
            WorkLogEntry."Work Center No." := Correction."Work Center No.";

        WorkLogEntry.Modify(true);
        exit(true);
    end;

    local procedure GetLatestMatchingWorkLog(var Correction: Record "ALP Execution Correction"; var WorkLogEntry: Record "ALP Work Log Entry"; var ErrorText: Text): Boolean
    var
        WorkLogEventType: Enum "ALP Work Log Event Type";
    begin
        if not ResolveWorkLogEventType(Correction."Event Type", WorkLogEventType, ErrorText) then
            exit(false);

        WorkLogEntry.SetRange("Order No.", Correction."Order No.");
        WorkLogEntry.SetRange("Operation No.", Correction."Operation No.");
        WorkLogEntry.SetRange("Event Type", WorkLogEventType);
        if not WorkLogEntry.FindLast() then begin
            ErrorText := StrSubstNo(WorkLogNotFoundErr, Correction."Order No.", Correction."Operation No.", Correction."Event Type");
            exit(false);
        end;

        exit(true);
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
