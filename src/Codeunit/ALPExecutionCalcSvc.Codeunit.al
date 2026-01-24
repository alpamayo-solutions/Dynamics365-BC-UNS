codeunit 50012 "ALP Execution Calc Svc"
{
    procedure UpdateProductionOrderAggregates(var ProdOrder: Record "Production Order")
    var
        RoutingLine: Record "Prod. Order Routing Line";
        WeightedAvailSum: Decimal;
        WeightedProdSum: Decimal;
        TotalParts: Integer;
        TotalRejected: Integer;
    begin
        RoutingLine.SetRange(Status, RoutingLine.Status::Released);
        RoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");

        if RoutingLine.FindSet() then
            repeat
                TotalParts += RoutingLine."ALP nParts";
                TotalRejected += RoutingLine."ALP nRejected";

                // Weight by nParts for availability/productivity
                if RoutingLine."ALP nParts" > 0 then begin
                    WeightedAvailSum += RoutingLine."ALP Actual Availability" * RoutingLine."ALP nParts";
                    WeightedProdSum += RoutingLine."ALP Actual Productivity" * RoutingLine."ALP nParts";
                end;
            until RoutingLine.Next() = 0;

        // Store totals
        ProdOrder."ALP Exec Total Parts" := TotalParts;
        ProdOrder."ALP Exec Total Rejected" := TotalRejected;

        // Calculate weighted averages (fall back to 0 if no weight)
        if TotalParts > 0 then begin
            ProdOrder."ALP Exec Weighted Avail" := WeightedAvailSum / TotalParts;
            ProdOrder."ALP Exec Weighted Prod" := WeightedProdSum / TotalParts;
        end else begin
            ProdOrder."ALP Exec Weighted Avail" := 0;
            ProdOrder."ALP Exec Weighted Prod" := 0;
        end;

        ProdOrder.Modify(true);
    end;

    procedure CalcProgressPct(ProdOrder: Record "Production Order"): Decimal
    var
        QtyGood: Integer;
        QtyPlanned: Decimal;
        Progress: Decimal;
    begin
        QtyGood := GetQtyGood(ProdOrder);
        QtyPlanned := ProdOrder.Quantity;

        if QtyPlanned <= 0 then
            exit(0);

        Progress := QtyGood / QtyPlanned;

        // Clamp to 0..1
        if Progress < 0 then
            Progress := 0;
        if Progress > 1 then
            Progress := 1;

        exit(Progress);
    end;

    procedure GetQtyGood(ProdOrder: Record "Production Order"): Integer
    begin
        exit(ProdOrder."ALP Exec Total Parts" - ProdOrder."ALP Exec Total Rejected");
    end;
}
