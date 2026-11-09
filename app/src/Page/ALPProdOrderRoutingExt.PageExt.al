pageextension 50101 "ALP Prod. Order Routing Ext" extends "Prod. Order Routing"
{
    layout
    {
        addlast(Control1)
        {
            field("ALP Exec. Finished"; Rec."ALP Exec. Finished")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies that the step was finished in the shop floor Execution app.';
            }
            field("ALP Exec. Finished At"; Rec."ALP Exec. Finished At")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies when the step was finished in the Execution app.';
            }
            field("ALP Output Qty."; Rec."ALP Output Qty.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the good quantity reported by the Execution app.';
            }
            field("ALP Scrap Qty."; Rec."ALP Scrap Qty.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the scrap quantity reported by the Execution app.';
            }
            field("ALP Planned Start"; Rec."ALP Planned Start")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the start of the step in the station fine plan of the Execution app.';
            }
            field("ALP Queue Position"; Rec."ALP Queue Position")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the position of the step in the station queue of the Execution app.';
            }
        }
    }
}
