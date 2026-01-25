permissionset 50040 "ALP Shopfloor View"
{
    Caption = 'ALP Shopfloor View';
    Assignable = true;

    Permissions =
        tabledata "ALP Integration Inbox" = R,
        tabledata "ALP Operation Execution" = R,
        tabledata "Production Order" = R,
        tabledata "Prod. Order Routing Line" = R,
        tabledata "Prod. Order Component" = R,
        tabledata "Work Center" = R,
        tabledata "Routing Header" = R,
        tabledata Item = R,
        page "ALP Integration Inbox List" = X,
        page "ALP Prod. Order Exec FactBox" = X,
        page "ALP Integration Inbox API" = X,
        page "ALP Prod Order Routing API" = X,
        page "ALP Prod Order Components API" = X,
        page "ALP Production Orders API" = X,
        page "ALP Routings API" = X,
        page "ALP Work Centers API" = X,
        page "ALP Items API" = X,
        report "ALP Daily Exec Performance" = X;
}
