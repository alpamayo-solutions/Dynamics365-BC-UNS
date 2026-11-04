permissionset 50040 "ALP Shopfloor View"
{
    Caption = 'ALP Shopfloor View';
    Assignable = true;

    Permissions =
        tabledata "ALP Shopfloor Setup" = R,
        tabledata "ALP Step Finish" = R,
        tabledata "ALP Person Time Entry" = R,
        tabledata "ALP Order Note" = R,
        tabledata "ALP Step Move" = R,
        tabledata "Production Order" = R,
        tabledata "Prod. Order Line" = R,
        tabledata "Prod. Order Routing Line" = R,
        tabledata "Prod. Order Component" = R,
        tabledata "Work Center" = R,
        tabledata "Machine Center" = R,
        tabledata "Work Shift" = R,
        tabledata "Shop Calendar" = R,
        tabledata "Shop Calendar Working Days" = R,
        tabledata "Routing Header" = R,
        tabledata "Capacity Unit of Measure" = R,
        tabledata Item = R,
        page "ALP Shopfloor Setup" = X,
        page "ALP Step Finishes" = X,
        page "ALP Person Time Entries" = X,
        page "ALP Production Orders API" = X,
        page "ALP Prod Order Routing API" = X,
        page "ALP Prod Order Components API" = X,
        page "ALP Routings API" = X,
        page "ALP Work Centers API" = X,
        page "ALP Machine Centers API" = X,
        page "ALP Work Shifts API" = X,
        page "ALP Shop Calendars API" = X,
        page "ALP Shop Cal Working Days API" = X,
        page "ALP Items API" = X,
        codeunit "ALP Step Resolver" = X;
}
