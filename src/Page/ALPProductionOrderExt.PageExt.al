pageextension 50021 "ALP Production Order Ext" extends "Released Production Order"
{
    layout
    {
        addafter(General)
        {
            group(ShopfloorExecution)
            {
                Caption = 'Shopfloor Execution';

                field("ALP Last Exec Update At"; Rec."ALP Last Exec Update At")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Timestamp of the last execution update received from the shopfloor system';
                    Editable = false;
                }
                field("ALP Execution Source"; Rec."ALP Execution Source")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Identifier of the shopfloor system that sent the last update';
                    Editable = false;
                }
            }
        }
    }
}
