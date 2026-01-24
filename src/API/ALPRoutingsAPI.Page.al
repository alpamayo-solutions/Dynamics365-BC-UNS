page 50037 "ALP Routings API"
{
    PageType = API;
    Caption = 'Routings API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'routing';
    EntitySetName = 'routings';
    SourceTable = "Routing Header";
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
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
            }
        }
    }
}
