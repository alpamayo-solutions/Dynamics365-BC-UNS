permissionset 50042 "ALP Shopfloor Admin"
{
    Caption = 'ALP Shopfloor Admin';
    Assignable = true;
    IncludedPermissionSets = "ALP Shopfloor View";

    Permissions =
        tabledata "ALP Shopfloor Setup" = RIMD,
        tabledata "Production Order" = RM;
}
