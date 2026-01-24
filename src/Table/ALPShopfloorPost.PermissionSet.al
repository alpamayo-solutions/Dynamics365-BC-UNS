permissionset 50042 "ALP Shopfloor Post"
{
    Caption = 'ALP Shopfloor Post';
    Assignable = true;

    Permissions =
        tabledata "ALP Output Inbox" = IMD,
        tabledata "Production Order" = IM,
        tabledata "Work Center" = IM,
        codeunit "ALP Output Ingestion Svc" = X,
        page "ALP Output Inbox API" = X;
}
