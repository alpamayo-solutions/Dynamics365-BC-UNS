page 50023 "ALP UNS Topic Mapping List"
{
    PageType = List;
    Caption = 'UNS Topic Mappings';
    SourceTable = "ALP UNS Topic Mapping";
    ApplicationArea = Manufacturing;
    UsageCategory = Administration;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field("UNS Topic"; Rec."UNS Topic")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'UNS topic path (e.g., mb/v1/nw/edge/filling/k5/assembly)';
                    StyleExpr = StatusStyle;
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Target Work Center in Business Central';
                    StyleExpr = StatusStyle;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Mapping status (Active/Inactive)';
                    StyleExpr = StatusStyle;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Human-readable description of this mapping';
                }
                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Source system identifier';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Date from which this mapping is valid';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Date until which this mapping is valid (0D = no end)';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'When this mapping was created';
                    Visible = false;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Who created this mapping';
                    Visible = false;
                }
                field("Modified At"; Rec."Modified At")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'When this mapping was last modified';
                    Visible = false;
                }
                field("Modified By"; Rec."Modified By")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Who last modified this mapping';
                    Visible = false;
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
        area(Processing)
        {
            action(Activate)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Activate';
                ToolTip = 'Set the selected mapping(s) to Active status';
                Image = Approve;
                Enabled = CanActivate;

                trigger OnAction()
                var
                    UNSTopicMapping: Record "ALP UNS Topic Mapping";
                begin
                    CurrPage.SetSelectionFilter(UNSTopicMapping);
                    UNSTopicMapping.ModifyAll(Status, UNSTopicMapping.Status::Active);
                    CurrPage.Update(false);
                end;
            }
            action(Deactivate)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Deactivate';
                ToolTip = 'Set the selected mapping(s) to Inactive status';
                Image = Reject;
                Enabled = CanDeactivate;

                trigger OnAction()
                var
                    UNSTopicMapping: Record "ALP UNS Topic Mapping";
                begin
                    CurrPage.SetSelectionFilter(UNSTopicMapping);
                    UNSTopicMapping.ModifyAll(Status, UNSTopicMapping.Status::Inactive);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Activate_Promoted; Activate)
                {
                }
                actionref(Deactivate_Promoted; Deactivate)
                {
                }
            }
        }
    }

    var
        StatusStyle: Text;
        CanActivate: Boolean;
        CanDeactivate: Boolean;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Active:
                StatusStyle := 'Favorable';
            Rec.Status::Inactive:
                StatusStyle := 'Subordinate';
        end;

        CanActivate := Rec.Status = Rec.Status::Inactive;
        CanDeactivate := Rec.Status = Rec.Status::Active;
    end;
}
