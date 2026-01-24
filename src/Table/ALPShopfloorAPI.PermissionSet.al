permissionset 50040 "ALP Shopfloor API"
{
    Caption = 'ALP Shopfloor API';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = RIMD,
        tabledata "ALP Operation Execution" = RIMD,
        codeunit "ALP Execution Ingestion Svc" = X,
        page "ALP Execution Events API" = X,
        page "ALP Integration Inbox List" = X;
}
