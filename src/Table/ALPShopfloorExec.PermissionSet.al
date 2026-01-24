permissionset 50041 "ALP Shopfloor Exec"
{
    Caption = 'ALP Shopfloor Exec';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = IMD,
        tabledata "ALP Operation Execution" = IMD,
        tabledata "Prod. Order Routing Line" = M,
        codeunit "ALP Execution Ingestion Svc" = X,
        codeunit "ALP Execution Calc Svc" = X,
        page "ALP Execution Events API" = X;
}
