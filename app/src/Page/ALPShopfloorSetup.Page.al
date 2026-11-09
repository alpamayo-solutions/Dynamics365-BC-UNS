page 50100 "ALP Shopfloor Setup"
{
    PageType = Card;
    Caption = 'Shopfloor Execution Setup';
    SourceTable = "ALP Shopfloor Setup";
    UsageCategory = Administration;
    ApplicationArea = Manufacturing;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Post Output"; Rec."Post Output")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether a step finished in the PREKIT Execution app posts an output journal line (output, scrap, setup and run time, finished). When off, the facts are only recorded on the routing line and nothing is posted.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrInit();
    end;
}
