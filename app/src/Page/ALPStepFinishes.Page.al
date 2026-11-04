page 50101 "ALP Step Finishes"
{
    PageType = List;
    Caption = 'Execution Step Finishes';
    SourceTable = "ALP Step Finish";
    UsageCategory = History;
    ApplicationArea = Manufacturing;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Received At"; Rec."Received At")
                {
                    ToolTip = 'Specifies when Business Central received the finish.';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ToolTip = 'Specifies the production order of the step.';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ToolTip = 'Specifies the operation of the step.';
                }
                field("Ran On Type"; Rec."Ran On Type")
                {
                    ToolTip = 'Specifies whether the step ran on a work center or a machine center.';
                }
                field("Ran On No."; Rec."Ran On No.")
                {
                    ToolTip = 'Specifies the work or machine center the step ran on.';
                }
                field("Started At"; Rec."Started At")
                {
                    ToolTip = 'Specifies when work on the step started.';
                }
                field("Finished At"; Rec."Finished At")
                {
                    ToolTip = 'Specifies when the step was finished.';
                }
                field("Setup Minutes"; Rec."Setup Minutes")
                {
                    ToolTip = 'Specifies the reported setup time in minutes.';
                }
                field("Run Minutes"; Rec."Run Minutes")
                {
                    ToolTip = 'Specifies the reported machine run time in minutes.';
                }
                field("Output Quantity"; Rec."Output Quantity")
                {
                    ToolTip = 'Specifies the good quantity reported.';
                }
                field("Scrap Quantity"; Rec."Scrap Quantity")
                {
                    ToolTip = 'Specifies the scrap quantity reported.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ToolTip = 'Specifies the employee who finished the step.';
                }
                field(Result; Rec.Result)
                {
                    ToolTip = 'Specifies whether the finish was recorded, posted, or was a repeat of an earlier finish.';
                }
                field("Capacity Ledger Entry No."; Rec."Capacity Ledger Entry No.")
                {
                    ToolTip = 'Specifies the capacity ledger entry posted for the finish.';
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ToolTip = 'Specifies the output item ledger entry posted for the finish, on the last operation.';
                }
                field("Event Id"; Rec."Event Id")
                {
                    ToolTip = 'Specifies the Execution app event id that identifies the finish.';
                }
            }
        }
    }
}
