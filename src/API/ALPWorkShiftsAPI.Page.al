page 50037 "ALP Work Shifts API"
{
    PageType = API;
    Caption = 'Work Shifts API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'workShift';
    EntitySetName = 'workShifts';
    SourceTable = "Work Shift";
    DelayedInsert = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(startingTime; Rec."Starting Time")
                {
                    Caption = 'Starting Time';
                }
                field(endingTime; Rec."Ending Time")
                {
                    Caption = 'Ending Time';
                }
            }
        }
    }
}
