table 50008 "ALP Execution Time Attribution"
{
    Caption = 'ALP Execution Time Attribution';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Attribution Type"; Enum "ALP Time Attribution Type")
        {
            Caption = 'Attribution Type';
            DataClassification = CustomerContent;
        }
        field(3; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(5; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
        }
        field(6; "Operator Id"; Code[20])
        {
            Caption = 'Operator Id';
            DataClassification = CustomerContent;
        }
        field(7; "Attributed Seconds"; Decimal)
        {
            Caption = 'Attributed Seconds';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(8; "Calculated At"; DateTime)
        {
            Caption = 'Calculated At';
            DataClassification = SystemMetadata;
        }
        field(9; "Interval Count"; Integer)
        {
            Caption = 'Interval Count';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Attribution; "Attribution Type", "Order No.", "Operation No.", "Work Center No.", "Operator Id")
        {
        }
    }
}
