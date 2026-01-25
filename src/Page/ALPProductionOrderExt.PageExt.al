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
