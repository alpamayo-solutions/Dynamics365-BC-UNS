page 50020 "ALP Integration Inbox List"
{
    PageType = List;
    Caption = 'ALP Integration Inbox';
    SourceTable = "ALP Integration Inbox";
    ApplicationArea = Manufacturing;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field("Message Id"; Rec."Message Id")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Unique identifier for the message';
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Type of message received';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Production Order number';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Operation number within the routing';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Processing status of the message';
                    StyleExpr = StatusStyle;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'When the message was received';
                }
                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'When the message was processed';
                }
                field(Error; Rec.Error)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Error message if processing failed';
                }
                field(Warning; Rec.Warning)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Warning';
                    ToolTip = 'Warning message (e.g., WorkCenter mismatch)';
                    StyleExpr = WarningStyle;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Notes; Notes)
            {
                ApplicationArea = Manufacturing;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ViewExecutionData)
            {
                ApplicationArea = Manufacturing;
                Caption = 'View Execution Data';
                ToolTip = 'View the execution data for this message';
                Image = View;
                Enabled = HasExecutionData;

                trigger OnAction()
                var
                    OpExec: Record "ALP Operation Execution";
                begin
                    if OpExec.Get(Rec."Order No.", Rec."Operation No.") then
                        Page.Run(0, OpExec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ViewExecutionData_Promoted; ViewExecutionData)
                {
                }
            }
        }
    }

    var
        StatusStyle: Text;
        WarningStyle: Text;
        HasExecutionData: Boolean;

    trigger OnAfterGetRecord()
    var
        OpExec: Record "ALP Operation Execution";
    begin
        case Rec.Status of
            Rec.Status::Received:
                StatusStyle := 'Ambiguous';
            Rec.Status::Processed:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
        end;

        if Rec.Warning <> '' then
            WarningStyle := 'Attention'
        else
            WarningStyle := '';

        HasExecutionData := OpExec.Get(Rec."Order No.", Rec."Operation No.");
    end;
}
