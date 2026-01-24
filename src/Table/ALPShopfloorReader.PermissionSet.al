permissionset 50041 "ALP Shopfloor Reader"
{
    Caption = 'ALP Shopfloor Reader';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = R,
        tabledata "ALP Operation Execution" = R,
        page "ALP Integration Inbox List" = X;
}
