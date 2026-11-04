pageextension 50100 "ALP Released Prod. Order Ext" extends "Released Production Order"
{
    layout
    {
        addlast(General)
        {
            field("ALP Held"; Rec."ALP Held")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies that the order is on hold: the shop floor Execution app accepts no new work on it.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            group(ALPShopfloor)
            {
                Caption = 'Shop Floor Execution';

                action(ALPHold)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Hold';
                    Image = Pause;
                    ToolTip = 'Put the order on hold. The Execution app shows it as held and accepts no finishes for it.';
                    Enabled = not Rec."ALP Held";

                    trigger OnAction()
                    begin
                        SetHeld(true);
                    end;
                }
                action(ALPReleaseHold)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Release Hold';
                    Image = Start;
                    ToolTip = 'Take the order off hold.';
                    Enabled = Rec."ALP Held";

                    trigger OnAction()
                    begin
                        SetHeld(false);
                    end;
                }
                action(ALPStepFinishes)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Step Finishes';
                    Image = OutputJournal;
                    ToolTip = 'View the steps of this order finished in the Execution app.';
                    RunObject = page "ALP Step Finishes";
                    RunPageLink = "Prod. Order No." = field("No.");
                }
                action(ALPPersonTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Person Time';
                    Image = Timesheet;
                    ToolTip = 'View the time people spent on this order in the Execution app.';
                    RunObject = page "ALP Person Time Entries";
                    RunPageLink = "Prod. Order No." = field("No.");
                }
            }
        }
    }

    local procedure SetHeld(Held: Boolean)
    begin
        Rec."ALP Held" := Held;
        Rec.Modify(true);
        CurrPage.Update(false);
    end;
}
