page 50040 "ALP Execution Corrections API"
{
    PageType = API;
    Caption = 'Execution Corrections API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'executionCorrection';
    EntitySetName = 'executionCorrections';
    SourceTable = "ALP Execution Correction";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(entryNo; Rec."Entry No.") { Caption = 'Entry No.'; Editable = false; }
                field(correctionId; Rec."Correction Id") { Caption = 'Correction Id'; }
                field(action; Rec.Action) { Caption = 'Action'; }
                field(targetEventIds; Rec."Target Event Ids") { Caption = 'Target Event Ids'; }
                field(requestedBy; Rec."Requested By") { Caption = 'Requested By'; }
                field(requestedAt; Rec."Requested At") { Caption = 'Requested At'; }
                field(reasonCode; Rec."Reason Code") { Caption = 'Reason Code'; }
                field(reasonText; Rec."Reason Text") { Caption = 'Reason Text'; }
                field(workCenterNo; Rec."Work Center No.") { Caption = 'Work Center No.'; }
                field(orderNo; Rec."Order No.") { Caption = 'Order No.'; }
                field(operationNo; Rec."Operation No.") { Caption = 'Operation No.'; }
                field(operatorId; Rec."Operator Id") { Caption = 'Operator Id'; }
                field(shiftCode; Rec."Shift Code") { Caption = 'Shift Code'; }
                field(eventType; Rec."Event Type") { Caption = 'Event Type'; }
                field(replacementStartTime; Rec."Replacement Start Time") { Caption = 'Replacement Start Time'; }
                field(replacementEndTime; Rec."Replacement End Time") { Caption = 'Replacement End Time'; }
                field(processed; Rec.Processed) { Caption = 'Processed'; Editable = false; }
                field(error; Rec.Error) { Caption = 'Error'; Editable = false; }
            }
        }
    }

    var
        CorrectionSvc: Codeunit "ALP Execution Correction Svc";
        CorrectionFailedErr: Label 'Failed to process execution correction: %1', Comment = '%1 = correction processing error';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not CorrectionSvc.ProcessCorrection(Rec) then
            Error(CorrectionFailedErr, Rec.Error);

        exit(false);
    end;
}
