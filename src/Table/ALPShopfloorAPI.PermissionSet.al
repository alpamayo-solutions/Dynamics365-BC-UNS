permissionset 50040 "ALP Shopfloor API"
{
    Caption = 'ALP Shopfloor API';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = RIMD,
        tabledata "ALP Operation Execution" = RIMD,
        tabledata "ALP Output Inbox" = RIMD,
        tabledata "Production Order" = RIM,
        tabledata "Prod. Order Routing Line" = R,
        tabledata "Prod. Order Component" = R,
        tabledata "Work Center" = RIM,
        codeunit "ALP Execution Ingestion Svc" = X,
        codeunit "ALP Output Ingestion Svc" = X,
        page "ALP Execution Events API" = X,
        page "ALP Integration Inbox List" = X,
        page "ALP Integration Inbox API" = X,
        page "ALP Output Inbox List" = X,
        page "ALP Output Inbox API" = X,
        page "ALP Prod Order Routing API" = X,
        page "ALP Prod Order Components API" = X,
        page "ALP Production Orders API" = X,
        page "ALP Work Centers API" = X;
}
