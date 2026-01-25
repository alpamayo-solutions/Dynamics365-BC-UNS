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
        field(50006; "ALP Exec Qty. Produced"; Integer)
        {
            Caption = 'Execution Quantity Produced';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50007; "ALP Exec Qty. Rejected"; Integer)
        {
            Caption = 'Execution Quantity Rejected';
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
