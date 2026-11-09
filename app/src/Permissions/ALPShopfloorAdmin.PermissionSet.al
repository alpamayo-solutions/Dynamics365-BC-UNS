permissionset 50042 "ALP Shopfloor Admin"
{
    Caption = 'ALP Shopfloor Admin';
    Assignable = true;
    IncludedPermissionSets = "ALP Shopfloor View";

#pragma warning disable AL0432
    // The 1.x tables stay until a later version removes them; only admins can see what is left in them.
    Permissions =
        tabledata "ALP Shopfloor Setup" = RIMD,
        tabledata "Production Order" = RM,
        tabledata "ALP Integration Inbox" = RD,
        tabledata "ALP Operation Execution" = RD,
        tabledata "ALP UNS Topic Mapping" = RD,
        tabledata "ALP Work Log Entry" = RD,
        tabledata "ALP Execution Correction" = RD,
        tabledata "ALP Execution Time Attribution" = RD;
#pragma warning restore AL0432
}
