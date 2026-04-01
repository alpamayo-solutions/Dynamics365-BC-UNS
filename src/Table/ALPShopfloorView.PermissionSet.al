permissionset 50040 "ALP Shopfloor View"
{
    Caption = 'ALP Shopfloor View';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = R,
        tabledata "ALP Execution Correction" = R,
        tabledata "ALP Operation Execution" = R,
        tabledata "ALP UNS Topic Mapping" = R,
        tabledata "ALP Work Log Entry" = R,
        tabledata "Production Order" = R,
        tabledata "Prod. Order Routing Line" = R,
        tabledata "Prod. Order Component" = R,
        tabledata "Work Center" = R,
        tabledata "Work Shift" = R,
        tabledata "Shop Calendar" = R,
        tabledata "Shop Calendar Working Days" = R,
        tabledata "Routing Header" = R,
        tabledata Item = R,
        page "ALP Integration Inbox List" = X,
        page "ALP Integration Inbox API" = X,
        page "ALP Execution Corrections API" = X,
        page "ALP Prod Order Routing API" = X,
        page "ALP Prod Order Components API" = X,
        page "ALP Production Orders API" = X,
        page "ALP Routings API" = X,
        page "ALP Work Centers API" = X,
        page "ALP Work Shifts API" = X,
        page "ALP Shop Calendars API" = X,
        page "ALP Shop Calendar Working Days API" = X,
        page "ALP Work Log Entries API" = X,
        page "ALP Items API" = X,
        page "ALP UNS Topic Mapping List" = X,
        page "ALP UNS Topic Mapping API" = X,
        report "ALP Daily Exec Performance" = X;
}
