permissionset 50041 "ALP Shopfloor Exec"
{
    Caption = 'ALP Shopfloor Exec';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = IMD,
        tabledata "ALP Execution Correction" = IMD,
        tabledata "ALP Execution Time Attribution" = RIMD,
        tabledata "ALP Operation Execution" = IMD,
        tabledata "ALP UNS Topic Mapping" = RIMD,
        tabledata "ALP Work Log Entry" = RIMD,
        tabledata "Prod. Order Routing Line" = M,
        codeunit "ALP Execution Ingestion Svc" = X,
        codeunit "ALP Execution Correction Svc" = X,
        codeunit "ALP Execution Attribution Svc" = X,
        codeunit "ALP Execution Calc Svc" = X,
        codeunit "ALP Work Log Svc" = X,
        page "ALP Execution Events API" = X,
        page "ALP Execution Corrections API" = X,
        page "ALP Exec Time Attr API" = X,
        page "ALP Work Log Entries API" = X,
        page "ALP UNS Topic Mapping API" = X;
}
