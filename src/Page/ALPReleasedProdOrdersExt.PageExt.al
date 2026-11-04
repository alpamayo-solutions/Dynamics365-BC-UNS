pageextension 50102 "ALP Released Prod. Orders Ext" extends "Released Production Orders"
{
    layout
    {
        addlast(Control1)
        {
            field("ALP Held"; Rec."ALP Held")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies that the order is on hold for the shop floor Execution app.';
            }
        }
    }
}
