pageextension 50023 "ALP Released Prod. Orders Ext" extends "Released Production Orders"
{
    layout
    {
        addafter(Quantity)
        {
            field("ALP Exec Qty. Produced"; Rec."ALP Exec Qty. Produced")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Qty. Produced';
                ToolTip = 'Total quantity produced as reported from shopfloor';
                Editable = false;
                Style = Favorable;
                StyleExpr = Rec."ALP Exec Qty. Produced" > 0;
            }
        }
        addfirst(factboxes)
        {
            part(ALPExecFactBox; "ALP Prod. Order Exec FactBox")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Execution';
                SubPageLink = Status = field(Status), "No." = field("No.");
            }
        }
    }
}
