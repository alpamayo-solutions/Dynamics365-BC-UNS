tableextension 50003 "ALP Production Order Ext" extends "Production Order"
{
    fields
    {
        field(50000; "ALP Last Exec Update At"; DateTime)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Last Execution Update At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(50001; "ALP Execution Source"; Code[20])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Execution Source';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50006; "ALP Exec Qty. Produced"; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Execution Quantity Produced';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50007; "ALP Exec Qty. Rejected"; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Execution Quantity Rejected';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50008; "ALP Exec Weighted Avail"; Decimal)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Weighted Availability';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50009; "ALP Exec Weighted Prod"; Decimal)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Weighted Productivity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        // 2.0: an order on hold accepts no new execution facts from the Execution app.
        field(50100; "ALP Held"; Boolean)
        {
            Caption = 'On Hold';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
