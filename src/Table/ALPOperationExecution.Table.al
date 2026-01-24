table 50002 "ALP Operation Execution"
{
    Caption = 'ALP Operation Execution';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(2; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(3; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
        }
        field(10; "nParts"; Integer)
        {
            Caption = 'Parts Produced';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(11; "nRejected"; Integer)
        {
            Caption = 'Parts Rejected';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(12; "Runtime Sec"; Decimal)
        {
            Caption = 'Runtime (Seconds)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            MinValue = 0;
        }
        field(13; "Downtime Sec"; Decimal)
        {
            Caption = 'Downtime (Seconds)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            MinValue = 0;
        }
        field(20; Availability; Decimal)
        {
            Caption = 'Availability';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            MinValue = 0;
            MaxValue = 1;
        }
        field(21; Productivity; Decimal)
        {
            Caption = 'Productivity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            MinValue = 0;
            MaxValue = 1;
        }
        field(22; "Actual Cycle Time Sec"; Decimal)
        {
            Caption = 'Actual Cycle Time (Seconds)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            MinValue = 0;
        }
        field(30; "Source Timestamp"; DateTime)
        {
            Caption = 'Source Timestamp';
            DataClassification = CustomerContent;
        }
        field(31; "Last Update At"; DateTime)
        {
            Caption = 'Last Update At';
            DataClassification = SystemMetadata;
        }
        field(32; Source; Code[20])
        {
            Caption = 'Source';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Order No.", "Operation No.")
        {
            Clustered = true;
        }
        key(WorkCenter; "Work Center No.")
        {
        }
        key(SourceTimestamp; "Source Timestamp")
        {
        }
    }
}
