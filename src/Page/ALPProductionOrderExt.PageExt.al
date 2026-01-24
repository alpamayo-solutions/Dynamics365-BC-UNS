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
            group(ShopfloorExecutionKPIs)
            {
                Caption = 'Execution KPIs';

                field("ALP Exec Qty. Produced"; Rec."ALP Exec Qty. Produced")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Qty. Produced';
                    ToolTip = 'Total quantity produced across all operations';
                    Editable = false;
                }
                field("ALP Exec Qty. Rejected"; Rec."ALP Exec Qty. Rejected")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Qty. Rejected';
                    ToolTip = 'Total quantity rejected across all operations';
                    Editable = false;
                }
                field(ALPQtyGood; QtyGood)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Qty. Good';
                    ToolTip = 'Total quantity good (Produced - Rejected)';
                    Editable = false;
                }
                field(ALPProgressPct; ProgressPct)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Progress %';
                    ToolTip = 'Completion percentage based on good quantity vs planned quantity';
                    Editable = false;
                    DecimalPlaces = 0 : 1;
                }
                field("ALP Exec Weighted Avail"; Rec."ALP Exec Weighted Avail")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Availability';
                    ToolTip = 'Quantity-weighted average availability across operations';
                    Editable = false;
                }
                field("ALP Exec Weighted Prod"; Rec."ALP Exec Weighted Prod")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Productivity';
                    ToolTip = 'Quantity-weighted average productivity across operations';
                    Editable = false;
                }
            }
            group(ShopfloorOutput)
            {
                Caption = 'Shopfloor Output';

                field("ALP Total Qty. Produced"; Rec."ALP Total Qty. Produced")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Total Qty. Produced';
                    ToolTip = 'Total quantity produced reported from the shopfloor system';
                    Editable = false;
                }
                field("ALP Total Qty. Rejected"; Rec."ALP Total Qty. Rejected")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Total Qty. Rejected';
                    ToolTip = 'Total quantity rejected reported from the shopfloor system';
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

    trigger OnAfterGetRecord()
    begin
        QtyGood := Rec."ALP Exec Qty. Produced" - Rec."ALP Exec Qty. Rejected";
        if Rec.Quantity > 0 then
            ProgressPct := Round((QtyGood / Rec.Quantity) * 100, 0.1)
        else
            ProgressPct := 0;
        if ProgressPct > 100 then
            ProgressPct := 100;
    end;

    var
        QtyGood: Integer;
        ProgressPct: Decimal;
}
