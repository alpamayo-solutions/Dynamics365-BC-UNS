tableextension 50003 "ALP Production Order Ext" extends "Production Order"
{
    fields
    {
        field(50000; "ALP Last Exec Update At"; DateTime)
        {
            Caption = 'Last Execution Update At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(50001; "ALP Execution Source"; Code[20])
        {
            Caption = 'Execution Source';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50002; "ALP Total Output Qty"; Decimal)
        {
            Caption = 'Total Output Quantity';
            Editable = false;
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("ALP Output Inbox"."Output Quantity" where("Order No." = field("No."), Status = const(Processed)));
        }
        field(50003; "ALP Total Scrap Qty"; Decimal)
        {
            Caption = 'Total Scrap Quantity';
            Editable = false;
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("ALP Output Inbox"."Scrap Quantity" where("Order No." = field("No."), Status = const(Processed)));
        }
        field(50004; "ALP Last Output Update At"; DateTime)
        {
            Caption = 'Last Output Update At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(50005; "ALP Output Source"; Code[20])
        {
            Caption = 'Output Source';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
