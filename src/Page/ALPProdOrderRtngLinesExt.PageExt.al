pageextension 50022 "ALP Prod Order Rtng Lines Ext" extends "Prod. Order Routing"
{
    layout
    {
        addlast(Control1)
        {
            field("ALP nParts"; Rec."ALP nParts")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Parts Produced';
                ToolTip = 'Number of parts produced at this operation';
                Editable = false;
            }
            field("ALP nRejected"; Rec."ALP nRejected")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Parts Rejected';
                ToolTip = 'Number of parts rejected at this operation';
                Editable = false;
            }
            field(ALPQtyGoodOp; Rec."ALP nParts" - Rec."ALP nRejected")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Good Parts';
                ToolTip = 'Good parts at this operation (produced minus rejected)';
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
