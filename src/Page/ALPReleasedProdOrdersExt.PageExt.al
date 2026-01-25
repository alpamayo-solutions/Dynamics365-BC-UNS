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
                StyleExpr = Rec."ALP Exec Qty. Produced" >= Rec.Quantity;
            }
        }
    }
}
