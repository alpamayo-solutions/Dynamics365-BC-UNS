tableextension 50004 "ALP Prod Order Rtng Line Ext" extends "Prod. Order Routing Line"
{
    fields
    {
        field(50000; "ALP Actual Availability"; Decimal)
        {
            Caption = 'Actual Availability';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50001; "ALP Actual Productivity"; Decimal)
        {
            Caption = 'Actual Productivity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50002; "ALP nParts"; Integer)
        {
            Caption = 'Parts Produced';
            DataClassification = CustomerContent;
            Editable = false;
            MinValue = 0;
        }
        field(50003; "ALP nRejected"; Integer)
        {
            Caption = 'Parts Rejected';
            DataClassification = CustomerContent;
            Editable = false;
            MinValue = 0;
        }
        field(50004; "ALP Source Timestamp"; DateTime)
        {
            Caption = 'Execution Source Timestamp';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(ALPProdOrder; Status, "Prod. Order No.")
        {
        }
    }
}
