page 50022 "ALP Prod. Order Exec FactBox"
{
    Caption = 'Execution Performance';
    PageType = CardPart;
    SourceTable = "Production Order";
    Editable = false;

    layout
    {
        area(content)
        {
            group(Quantities)
            {
                Caption = 'Quantities';
                ShowCaption = false;

                field(QtyPlanned; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Planned';
                    ToolTip = 'Planned quantity for the production order';
                    DecimalPlaces = 0 : 0;
                }
                field(QtyProduced; Rec."ALP Exec Qty. Produced")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Produced';
                    ToolTip = 'Total quantity produced across all operations';
                }
                field(QtyRejected; Rec."ALP Exec Qty. Rejected")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Rejected';
                    ToolTip = 'Total quantity rejected across all operations';
                    Style = Unfavorable;
                    StyleExpr = Rec."ALP Exec Qty. Rejected" > 0;
                }
                field(QtyGood; QtyGood)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Good';
                    ToolTip = 'Total good quantity (Produced - Rejected)';
                    Style = Favorable;
                    StyleExpr = QtyGood > 0;
                }
            }
            group(Progress)
            {
                Caption = 'Progress';
                ShowCaption = false;

                field(ProgressPct; ProgressPct)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Completion';
                    ToolTip = 'Completion percentage based on good quantity vs planned quantity';
                    DecimalPlaces = 0 : 1;
                    Style = Favorable;
                    StyleExpr = ProgressPct >= 100;
                }
            }
            group(OEE)
            {
                Caption = 'OEE Metrics';
                ShowCaption = false;

                field(Availability; AvailabilityPct)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Availability';
                    ToolTip = 'Quantity-weighted average availability across operations';
                    DecimalPlaces = 0 : 1;
                }
                field(Productivity; ProductivityPct)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Productivity';
                    ToolTip = 'Quantity-weighted average productivity across operations';
                    DecimalPlaces = 0 : 1;
                }
            }
            group(Timestamp)
            {
                Caption = 'Last Update';
                ShowCaption = false;

                field(LastUpdate; Rec."ALP Last Exec Update At")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Last Update';
                    ToolTip = 'Timestamp of the last execution update received';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcKPIs();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalcKPIs();
    end;

    local procedure CalcKPIs()
    begin
        QtyGood := Rec."ALP Exec Qty. Produced" - Rec."ALP Exec Qty. Rejected";

        if Rec.Quantity > 0 then
            ProgressPct := Round((QtyGood / Rec.Quantity) * 100, 0.1)
        else
            ProgressPct := 0;

        if ProgressPct > 100 then
            ProgressPct := 100;

        if Rec."ALP Exec Qty. Produced" > 0 then begin
            AvailabilityPct := Round(Rec."ALP Exec Weighted Avail" * 100, 0.1);
            ProductivityPct := Round(Rec."ALP Exec Weighted Prod" * 100, 0.1);
        end else begin
            AvailabilityPct := 0;
            ProductivityPct := 0;
        end;
    end;

    var
        QtyGood: Integer;
        ProgressPct: Decimal;
        AvailabilityPct: Decimal;
        ProductivityPct: Decimal;
}
