page 50039 "ALP UNS Topic Mapping API"
{
    PageType = API;
    Caption = 'UNS Topic Mapping API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'unsTopicMapping';
    EntitySetName = 'unsTopicMappings';
    SourceTable = "ALP UNS Topic Mapping";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(unsTopic; Rec."UNS Topic")
                {
                    Caption = 'UNS Topic';
                }
                field(workCenterNo; Rec."Work Center No.")
                {
                    Caption = 'Work Center No.';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(sourceSystem; Rec."Source System")
                {
                    Caption = 'Source System';
                }
                field(validFrom; Rec."Valid From")
                {
                    Caption = 'Valid From';
                }
                field(validTo; Rec."Valid To")
                {
                    Caption = 'Valid To';
                }
                field(createdAt; Rec."Created At")
                {
                    Caption = 'Created At';
                    Editable = false;
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                    Editable = false;
                }
                field(modifiedAt; Rec."Modified At")
                {
                    Caption = 'Modified At';
                    Editable = false;
                }
                field(modifiedBy; Rec."Modified By")
                {
                    Caption = 'Modified By';
                    Editable = false;
                }
            }
        }
    }
}
