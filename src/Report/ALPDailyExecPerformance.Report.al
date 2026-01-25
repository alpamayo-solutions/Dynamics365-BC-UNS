report 50051 "ALP Daily Exec Performance"
{
    Caption = 'Daily Work Order Execution Performance';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Manufacturing;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(ProductionOrder; "Production Order")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", Status;

            column(No_; "No.") { }
            column(Description; Description) { }
            column(SourceNo; "Source No.") { }
            column(Quantity; Quantity) { }
            column(DueDate; "Due Date") { }
            column(QtyProduced; QtyProduced) { }
            column(QtyRejected; QtyRejected) { }
            column(QtyGood; QtyGood) { }
            column(ProgressPct; ProgressPct) { }
            column(AvgAvailability; AvgAvailability) { }
            column(AvgProductivity; AvgProductivity) { }
            column(LastUpdateAt; LastUpdateAt) { }
            column(WorkCenters; WorkCenters) { }
            column(ReportDateCaption; ReportDateCaption) { }
            column(CompanyName; CompanyName()) { }

            // i18n labels for report layout
            column(ReportTitleLbl; ReportTitleLbl) { }
            column(ReportDateLbl; ReportDateLbl) { }
            column(ExportedLbl; ExportedLbl) { }
            column(BroughtToYouByLbl; BroughtToYouByLbl) { }
            column(AlpamayoLbl; AlpamayoLbl) { }
            column(AlpamayoUrlLbl; AlpamayoUrlLbl) { }
            column(PageLbl; PageLbl) { }
            column(OfLbl; OfLbl) { }
            column(OrderNoLbl; OrderNoLbl) { }
            column(ItemLbl; ItemLbl) { }
            column(PlannedLbl; PlannedLbl) { }
            column(ProducedLbl; ProducedLbl) { }
            column(RejectedLbl; RejectedLbl) { }
            column(GoodLbl; GoodLbl) { }
            column(ProgressLbl; ProgressLbl) { }
            column(AvailLbl; AvailLbl) { }
            column(ProdLbl; ProdLbl) { }
            column(LastUpdateLbl; LastUpdateLbl) { }
            column(WorkCentersLbl; WorkCentersLbl) { }

            trigger OnPreDataItem()
            var
                OrderFilter: Text;
            begin
                OrderFilter := BuildAggregatesAndGetOrderFilter();
                if OrderFilter = '' then
                    CurrReport.Break();
                SetFilter("No.", OrderFilter);
            end;

            trigger OnAfterGetRecord()
            begin
                LookupAggregates("No.", Quantity);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ReportDateField; ReportDate)
                    {
                        Caption = 'Report Date';
                        ToolTip = 'Date to report on (default: today)';
                        ApplicationArea = Manufacturing;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if ReportDate = 0D then
                ReportDate := Today();
        end;
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './src/Report/ALPDailyExecPerformance.rdl';
        }
        layout(ExcelLayout)
        {
            Type = Excel;
            LayoutFile = './src/Report/ALPDailyExecPerformance.xlsx';
        }
    }

    var
        // Pre-aggregated data dictionaries (built once, looked up per order)
        OrderQtyProduced: Dictionary of [Code[20], Integer];
        OrderQtyRejected: Dictionary of [Code[20], Integer];
        OrderWeightedAvail: Dictionary of [Code[20], Decimal];
        OrderWeightedProd: Dictionary of [Code[20], Decimal];
        OrderLastUpdate: Dictionary of [Code[20], DateTime];
        OrderWorkCenters: Dictionary of [Code[20], Text[250]];
        ReportDate: Date;
        QtyProduced: Integer;
        QtyRejected: Integer;
        QtyGood: Integer;
        ProgressPct: Decimal;
        AvgAvailability: Decimal;
        AvgProductivity: Decimal;
        LastUpdateAt: DateTime;
        WorkCenters: Text[250];
        ReportDateCaption: Text;

        // i18n labels
        ReportTitleLbl: Label 'Daily Work Order Execution Performance', Comment = 'Report title shown in header';
        ReportDateLbl: Label 'Report Date:', Comment = 'Label prefix for the report date';
        ExportedLbl: Label 'Exported:', Comment = 'Label prefix for export timestamp';
        BroughtToYouByLbl: Label 'Brought to you by', Comment = 'Footer branding text before company name';
        AlpamayoLbl: Label 'Alpamayo', Comment = 'Company name in footer, locked', Locked = true;
        AlpamayoUrlLbl: Label 'alpamayo-solutions.com', Comment = 'Company URL in footer, locked', Locked = true;
        PageLbl: Label 'Page', Comment = 'Page number prefix';
        OfLbl: Label 'of', Comment = 'Page X of Y separator';
        OrderNoLbl: Label 'Order No.', Comment = 'Column header for production order number';
        ItemLbl: Label 'Item', Comment = 'Column header for item/source number';
        PlannedLbl: Label 'Planned', Comment = 'Column header for planned quantity';
        ProducedLbl: Label 'Produced', Comment = 'Column header for produced quantity';
        RejectedLbl: Label 'Rejected', Comment = 'Column header for rejected quantity';
        GoodLbl: Label 'Good', Comment = 'Column header for good quantity (produced minus rejected)';
        ProgressLbl: Label 'Progress', Comment = 'Column header for progress percentage';
        AvailLbl: Label 'Avail.', Comment = 'Column header for availability percentage (abbreviated)';
        ProdLbl: Label 'Prod.', Comment = 'Column header for productivity percentage (abbreviated)';
        LastUpdateLbl: Label 'Last Update', Comment = 'Column header for last update timestamp';
        WorkCentersLbl: Label 'Work Centers', Comment = 'Column header for work centers list';

    local procedure BuildAggregatesAndGetOrderFilter(): Text
    var
        Execution: Record "ALP Operation Execution";
        OrderFilter: TextBuilder;
        StartDT, EndDT : DateTime;
        OrderNo: Code[20];
        CurrQtyProd, CurrQtyRej : Integer;
        CurrWeightedAvail, CurrWeightedProd : Decimal;
        CurrLastUpdate: DateTime;
        CurrWC: Text[250];
    begin
        if ReportDate = 0D then
            ReportDate := Today();

        ReportDateCaption := Format(ReportDate);

        StartDT := CreateDateTime(ReportDate, 0T);
        EndDT := CreateDateTime(ReportDate, 235959.999T);

        // Clear dictionaries
        Clear(OrderQtyProduced);
        Clear(OrderQtyRejected);
        Clear(OrderWeightedAvail);
        Clear(OrderWeightedProd);
        Clear(OrderLastUpdate);
        Clear(OrderWorkCenters);

        // Single pass through execution records
        Execution.SetCurrentKey("Source Timestamp");
        Execution.SetFilter("Source Timestamp", '%1..%2', StartDT, EndDT);

        if Execution.FindSet() then
            repeat
                OrderNo := Execution."Order No.";

                // Get current aggregates or initialize
                if not OrderQtyProduced.Get(OrderNo, CurrQtyProd) then
                    CurrQtyProd := 0;
                if not OrderQtyRejected.Get(OrderNo, CurrQtyRej) then
                    CurrQtyRej := 0;
                if not OrderWeightedAvail.Get(OrderNo, CurrWeightedAvail) then
                    CurrWeightedAvail := 0;
                if not OrderWeightedProd.Get(OrderNo, CurrWeightedProd) then
                    CurrWeightedProd := 0;
                if not OrderLastUpdate.Get(OrderNo, CurrLastUpdate) then
                    CurrLastUpdate := 0DT;
                if not OrderWorkCenters.Get(OrderNo, CurrWC) then
                    CurrWC := '';

                // Accumulate
                CurrQtyProd += Execution."Qty. Produced";
                CurrQtyRej += Execution."Qty. Rejected";

                if Execution."Qty. Produced" > 0 then begin
                    CurrWeightedAvail += Execution.Availability * Execution."Qty. Produced";
                    CurrWeightedProd += Execution.Productivity * Execution."Qty. Produced";
                end;

                if Execution."Source Timestamp" > CurrLastUpdate then
                    CurrLastUpdate := Execution."Source Timestamp";

                // Append work center if not already in list
                if Execution."Work Center No." <> '' then
                    if StrPos(CurrWC, Execution."Work Center No.") = 0 then begin
                        if CurrWC <> '' then
                            CurrWC += ', ';
                        CurrWC := CopyStr(CurrWC + Execution."Work Center No.", 1, 250);
                    end;

                // Store back
                OrderQtyProduced.Set(OrderNo, CurrQtyProd);
                OrderQtyRejected.Set(OrderNo, CurrQtyRej);
                OrderWeightedAvail.Set(OrderNo, CurrWeightedAvail);
                OrderWeightedProd.Set(OrderNo, CurrWeightedProd);
                OrderLastUpdate.Set(OrderNo, CurrLastUpdate);
                OrderWorkCenters.Set(OrderNo, CurrWC);
            until Execution.Next() = 0;

        // Build order filter from dictionary keys
        foreach OrderNo in OrderQtyProduced.Keys do begin
            if OrderFilter.Length > 0 then
                OrderFilter.Append('|');
            OrderFilter.Append(OrderNo);
        end;

        exit(OrderFilter.ToText());
    end;

    local procedure LookupAggregates(OrderNo: Code[20]; PlannedQty: Decimal)
    var
        TotalParts: Integer;
        WeightedAvail, WeightedProd : Decimal;
    begin
        // Reset values
        QtyProduced := 0;
        QtyRejected := 0;
        QtyGood := 0;
        ProgressPct := 0;
        AvgAvailability := 0;
        AvgProductivity := 0;
        LastUpdateAt := 0DT;
        WorkCenters := '';

        // Lookup from pre-aggregated dictionaries
        if not OrderQtyProduced.Get(OrderNo, QtyProduced) then
            exit;

        OrderQtyRejected.Get(OrderNo, QtyRejected);
        OrderWeightedAvail.Get(OrderNo, WeightedAvail);
        OrderWeightedProd.Get(OrderNo, WeightedProd);
        OrderLastUpdate.Get(OrderNo, LastUpdateAt);
        OrderWorkCenters.Get(OrderNo, WorkCenters);

        QtyGood := QtyProduced - QtyRejected;
        TotalParts := QtyProduced;

        if PlannedQty > 0 then
            ProgressPct := QtyGood / PlannedQty
        else
            ProgressPct := 0;

        if ProgressPct > 1 then
            ProgressPct := 1;

        if TotalParts > 0 then begin
            AvgAvailability := WeightedAvail / TotalParts;
            AvgProductivity := WeightedProd / TotalParts;
        end;
    end;
}
