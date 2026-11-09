page 50102 "ALP Person Time Entries"
{
    PageType = List;
    Caption = 'Execution Person Time';
    SourceTable = "ALP Person Time Entry";
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
                field("Employee No."; Rec."Employee No.")
                {
                    ToolTip = 'Specifies the employee who worked on the step.';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ToolTip = 'Specifies the production order.';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ToolTip = 'Specifies the operation.';
                }
                field("Work Place Type"; Rec."Work Place Type")
                {
                    ToolTip = 'Specifies whether the person worked at a work center or a machine center.';
                }
                field("Work Place No."; Rec."Work Place No.")
                {
                    ToolTip = 'Specifies the work or machine center.';
                }
                field("Started At"; Rec."Started At")
                {
                    ToolTip = 'Specifies when the time slice started.';
                }
                field("Ended At"; Rec."Ended At")
                {
                    ToolTip = 'Specifies when the time slice ended.';
                }
                field(Minutes; Rec.Minutes)
                {
                    ToolTip = 'Specifies the length of the time slice in minutes.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies whether the slice counts (Active), was replaced by a later revision (Superseded), or was cancelled.';
                }
                field("Session Id"; Rec."Session Id")
                {
                    ToolTip = 'Specifies the Execution app session the slice belongs to.';
                }
            }
        }
    }
}
