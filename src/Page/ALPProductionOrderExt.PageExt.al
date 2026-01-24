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
            group(ShopfloorExecutionKPIs)
            {
                Caption = 'Execution KPIs';

                field("ALP Exec Total Parts"; Rec."ALP Exec Total Parts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Total Parts';
                    ToolTip = 'Total parts produced across all operations';
                    Editable = false;
                }
                field("ALP Exec Total Rejected"; Rec."ALP Exec Total Rejected")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Total Rejected';
                    ToolTip = 'Total rejected parts across all operations';
                    Editable = false;
                }
                field(ALPQtyGood; QtyGood)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Good Parts';
                    ToolTip = 'Total good parts (Total - Rejected)';
                    Editable = false;
                }
                field(ALPProgressPct; ProgressPct)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Progress %';
                    ToolTip = 'Completion percentage based on good parts vs planned quantity';
                    Editable = false;
                    DecimalPlaces = 0 : 1;
                }
                field("ALP Exec Weighted Avail"; Rec."ALP Exec Weighted Avail")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Availability';
                    ToolTip = 'Parts-weighted average availability across operations';
                    Editable = false;
                }
                field("ALP Exec Weighted Prod"; Rec."ALP Exec Weighted Prod")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Productivity';
                    ToolTip = 'Parts-weighted average productivity across operations';
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
        QtyGood := Rec."ALP Exec Total Parts" - Rec."ALP Exec Total Rejected";
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
