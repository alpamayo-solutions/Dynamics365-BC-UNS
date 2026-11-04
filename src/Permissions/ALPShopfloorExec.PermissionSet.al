/// <summary>
/// For the Execution app's integration user (Entra app). Together with ALP Shopfloor View it covers reading the
/// order book and every write of the Execution app. Posting output (Setup: Post Output) additionally needs the
/// standard permissions to post output journals, for example D365 MFG, EDIT / D365 BUS FULL ACCESS.
/// </summary>
permissionset 50041 "ALP Shopfloor Exec"
{
    Caption = 'ALP Shopfloor Exec';
    Assignable = true;
    IncludedPermissionSets = "ALP Shopfloor View";

    Permissions =
        tabledata "ALP Shopfloor Setup" = RI,
        tabledata "ALP Step Finish" = RI,
        tabledata "ALP Person Time Entry" = RIM,
        tabledata "ALP Order Note" = RID,
        tabledata "ALP Step Move" = RI,
        tabledata "Prod. Order Routing Line" = RM,
        tabledata "Record Link" = RIMD,
        tabledata Employee = R,
        tabledata Scrap = R,
        tabledata "Capacity Ledger Entry" = R,
        tabledata "Item Ledger Entry" = R,
        tabledata "Source Code Setup" = R,
        codeunit "ALP Step Finish Svc" = X,
        codeunit "ALP Person Time Svc" = X,
        codeunit "ALP Order Note Svc" = X,
        codeunit "ALP Step Move Svc" = X,
        page "ALP Step Finishes API" = X,
        page "ALP Person Times API" = X,
        page "ALP Order Notes API" = X,
        page "ALP Step Moves API" = X,
        page "ALP Step Plans API" = X;
}
