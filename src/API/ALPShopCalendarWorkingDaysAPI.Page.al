page 50039 "ALP Shop Calendar Working Days API"
{
    PageType = API;
    Caption = 'Shop Calendar Working Days API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'shopCalendarWorkingDay';
    EntitySetName = 'shopCalendarWorkingDays';
    SourceTable = "Shop Calendar Working Days";
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
                field(shopCalendarCode; Rec."Shop Calendar Code")
                {
                    Caption = 'Shop Calendar Code';
                }
                field(day; Rec.Day)
                {
                    Caption = 'Day';
                }
                field(workShiftCode; Rec."Work Shift Code")
                {
                    Caption = 'Work Shift Code';
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
