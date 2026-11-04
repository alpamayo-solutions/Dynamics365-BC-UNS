/// <summary>POST person time slices. See docs/execution-app-contract.md.</summary>
page 50112 "ALP Person Times API"
{
    PageType = API;
    Caption = 'Person Times API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'personTime';
    EntitySetName = 'personTimes';
    SourceTable = "ALP Person Time Entry";
    ODataKeyFields = SystemId;
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
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(eventId; Rec."Event Id")
                {
                    Caption = 'Event Id';
                }
                field(sessionId; Rec."Session Id")
                {
                    Caption = 'Session Id';
                }
                field(sessionKey; Rec."Session Key")
                {
                    Caption = 'Session Key';
                }
                field(employeeNo; Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(stepId; Rec."Step Id")
                {
                    Caption = 'Step Id';
                }
                field(workPlaceType; Rec."Work Place Type")
                {
                    Caption = 'Work Place Type';
                }
                field(workPlaceNo; Rec."Work Place No.")
                {
                    Caption = 'Work Place No.';
                }
                field(startedAt; Rec."Started At")
                {
                    Caption = 'Started At';
                }
                field(endedAt; Rec."Ended At")
                {
                    Caption = 'Ended At';
                }
                field(cancelled; Rec.Cancelled)
                {
                    Caption = 'Cancelled';
                }
                field(minutes; Rec.Minutes)
                {
                    Caption = 'Minutes';
                    Editable = false;
                }
                field(prodOrderNo; Rec."Prod. Order No.")
                {
                    Caption = 'Prod. Order No.';
                    Editable = false;
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PersonTimeSvc: Codeunit "ALP Person Time Svc";
    begin
        PersonTimeSvc.Process(Rec);
        exit(true);
    end;
}
