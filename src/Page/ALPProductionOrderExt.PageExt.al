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
            group(ShopfloorOutput)
            {
                Caption = 'Shopfloor Output';

                field("ALP Total Output Qty"; Rec."ALP Total Output Qty")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Total Output';
                    ToolTip = 'Total output quantity reported from the shopfloor system';
                    Editable = false;
                }
                field("ALP Total Scrap Qty"; Rec."ALP Total Scrap Qty")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Total Scrap';
                    ToolTip = 'Total scrap quantity reported from the shopfloor system';
                    Editable = false;
                }
                field("ALP Last Output Update At"; Rec."ALP Last Output Update At")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Timestamp of the last output update received from the shopfloor system';
                    Editable = false;
                }
                field("ALP Output Source"; Rec."ALP Output Source")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Identifier of the shopfloor system that sent the last output update';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        addlast(Navigation)
        {
            group(ALPShopfloor)
            {
                Caption = 'Shopfloor';
                Image = Journals;

                action(ALPViewIntegrationInbox)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Execution Events';
                    ToolTip = 'View execution events (performance metrics) for this production order';
                    Image = Log;
                    RunObject = page "ALP Integration Inbox List";
                    RunPageLink = "Order No." = field("No.");
                }
                action(ALPViewOutputInbox)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Output Events';
                    ToolTip = 'View output events (quantities) for this production order';
                    Image = OutputJournal;
                    RunObject = page "ALP Output Inbox List";
                    RunPageLink = "Order No." = field("No.");
                }
            }
        }
        addlast(Promoted)
        {
            group(Category_Shopfloor)
            {
                Caption = 'Shopfloor';

                actionref(ALPViewIntegrationInbox_Promoted; ALPViewIntegrationInbox)
                {
                }
                actionref(ALPViewOutputInbox_Promoted; ALPViewOutputInbox)
                {
                }
            }
        }
    }
}
