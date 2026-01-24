page 50021 "ALP Output Inbox List"
{
    PageType = List;
    Caption = 'ALP Output Inbox';
    SourceTable = "ALP Output Inbox";
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
                field("Qty. Produced"; Rec."Qty. Produced")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Quantity produced';
                }
                field("Qty. Rejected"; Rec."Qty. Rejected")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Quantity rejected';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Date for posting the output';
                }
                field("Source Timestamp"; Rec."Source Timestamp")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Timestamp from the source system';
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Source system identifier';
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
            action(ViewProductionOrder)
            {
                ApplicationArea = Manufacturing;
                Caption = 'View Production Order';
                ToolTip = 'View the production order for this output';
                Image = View;
                Enabled = HasProductionOrder;

                trigger OnAction()
                var
                    ProdOrder: Record "Production Order";
                begin
                    ProdOrder.SetRange("No.", Rec."Order No.");
                    if ProdOrder.FindFirst() then
                        Page.Run(Page::"Released Production Order", ProdOrder);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ViewProductionOrder_Promoted; ViewProductionOrder)
                {
                }
            }
        }
    }

    var
        StatusStyle: Text;
        HasProductionOrder: Boolean;

    trigger OnAfterGetRecord()
    var
        ProdOrder: Record "Production Order";
    begin
        case Rec.Status of
            Rec.Status::Received:
                StatusStyle := 'Ambiguous';
            Rec.Status::Processed:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
        end;

        ProdOrder.SetRange("No.", Rec."Order No.");
        HasProductionOrder := not ProdOrder.IsEmpty();
    end;
}
