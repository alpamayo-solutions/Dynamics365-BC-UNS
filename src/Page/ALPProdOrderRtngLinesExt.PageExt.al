pageextension 50022 "ALP Prod Order Rtng Lines Ext" extends "Prod. Order Routing"
{
    layout
    {
        addlast(Control1)
        {
            field("ALP Actual Availability"; Rec."ALP Actual Availability")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Actual Availability';
                ToolTip = 'Actual availability ratio from shopfloor execution (0-1)';
                Editable = false;
            }
            field("ALP Actual Productivity"; Rec."ALP Actual Productivity")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Actual Productivity';
                ToolTip = 'Actual productivity ratio from shopfloor execution (0-1)';
                Editable = false;
            }
        }
    }
}
