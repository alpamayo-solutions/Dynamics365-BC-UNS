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
        field(50006; "ALP Exec Total Parts"; Integer)
        {
            Caption = 'Total Parts Produced';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50007; "ALP Exec Total Rejected"; Integer)
        {
            Caption = 'Total Parts Rejected';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50008; "ALP Exec Weighted Avail"; Decimal)
        {
            Caption = 'Weighted Availability';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50009; "ALP Exec Weighted Prod"; Decimal)
        {
            Caption = 'Weighted Productivity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
    }
}
