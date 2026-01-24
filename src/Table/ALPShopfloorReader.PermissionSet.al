permissionset 50041 "ALP Shopfloor Reader"
{
    Caption = 'ALP Shopfloor Reader';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = R,
        tabledata "ALP Operation Execution" = R,
        tabledata "ALP Output Inbox" = R,
        page "ALP Integration Inbox List" = X,
        page "ALP Output Inbox List" = X;
}
