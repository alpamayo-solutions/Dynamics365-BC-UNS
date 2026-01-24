pageextension 50022 "ALP Prod Order Rtng Lines Ext" extends "Prod. Order Routing"
{
    layout
    {
        addlast(Control1)
        {
            field("ALP Qty. Produced"; Rec."ALP Qty. Produced")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Qty. Produced';
                ToolTip = 'Quantity produced at this operation';
                Editable = false;
            }
            field("ALP Qty. Rejected"; Rec."ALP Qty. Rejected")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Qty. Rejected';
                ToolTip = 'Quantity rejected at this operation';
                Editable = false;
            }
            field(ALPQtyGood; Rec."ALP Qty. Produced" - Rec."ALP Qty. Rejected")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Qty. Good';
                ToolTip = 'Quantity good at this operation (produced minus rejected)';
                Editable = false;
            }
            field("ALP Actual Availability"; Rec."ALP Actual Availability")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Availability';
                ToolTip = 'Actual availability ratio from shopfloor execution (0-1)';
                Editable = false;
            }
            field("ALP Actual Productivity"; Rec."ALP Actual Productivity")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Productivity';
                ToolTip = 'Actual productivity ratio from shopfloor execution (0-1)';
                Editable = false;
            }
            field("ALP Source Timestamp"; Rec."ALP Source Timestamp")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Last Update';
                ToolTip = 'Timestamp of the last execution update from the shopfloor system';
                Editable = false;
            }
        }
    }
}
