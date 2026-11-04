/// <summary>POST a step move (reroute). See docs/execution-app-contract.md.</summary>
page 50114 "ALP Step Moves API"
{
    PageType = API;
    Caption = 'Step Moves API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'stepMove';
    EntitySetName = 'stepMoves';
    SourceTable = "ALP Step Move";
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
                field(stepId; Rec."Step Id")
                {
                    Caption = 'Step Id';
                }
                field(toType; Rec."To Type")
                {
                    Caption = 'To Type';
                }
                field(toNo; Rec."To No.")
                {
                    Caption = 'To No.';
                }
                field(fromType; Rec."From Type")
                {
                    Caption = 'From Type';
                    Editable = false;
                }
                field(fromNo; Rec."From No.")
                {
                    Caption = 'From No.';
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
        StepMoveSvc: Codeunit "ALP Step Move Svc";
    begin
        StepMoveSvc.Process(Rec);
        exit(true);
    end;
}
