page 50045 "ALP Exec Time Attr API"
{
    PageType = API;
    Caption = 'Execution Time Attributions API';
    APIPublisher = 'alpamayo';
    APIGroup = 'shopfloor';
    APIVersion = 'v1.0';
    EntityName = 'executionTimeAttribution';
    EntitySetName = 'executionTimeAttributions';
    SourceTable = "ALP Execution Time Attribution";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(attributionType; Rec."Attribution Type")
                {
                    Caption = 'Attribution Type';
                }
                field(orderNo; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(workCenterNo; Rec."Work Center No.")
                {
                    Caption = 'Work Center No.';
                }
                field(operatorId; Rec."Operator Id")
                {
                    Caption = 'Operator Id';
                }
                field(attributedSeconds; Rec."Attributed Seconds")
                {
                    Caption = 'Attributed Seconds';
                }
                field(intervalCount; Rec."Interval Count")
                {
                    Caption = 'Interval Count';
                }
                field(calculatedAt; Rec."Calculated At")
                {
                    Caption = 'Calculated At';
                }
            }
        }
    }
}
