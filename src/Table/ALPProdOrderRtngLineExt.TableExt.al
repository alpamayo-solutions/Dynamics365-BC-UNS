tableextension 50004 "ALP Prod Order Rtng Line Ext" extends "Prod. Order Routing Line"
{
    fields
    {
        field(50000; "ALP Actual Availability"; Decimal)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Actual Availability';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50001; "ALP Actual Productivity"; Decimal)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Actual Productivity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50002; "ALP Qty. Produced"; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Quantity Produced';
            DataClassification = CustomerContent;
            Editable = false;
            MinValue = 0;
        }
        field(50003; "ALP Qty. Rejected"; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Quantity Rejected';
            DataClassification = CustomerContent;
            Editable = false;
            MinValue = 0;
        }
        field(50004; "ALP Source Timestamp"; DateTime)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by the Execution app surface in 2.0.';
            ObsoleteTag = '2.0';
            Caption = 'Execution Source Timestamp';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // 2.0: execution facts reported by the PREKIT Execution app for this routing line (step).
        field(50100; "ALP Exec. Finished"; Boolean)
        {
            Caption = 'Execution Finished';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50101; "ALP Exec. Finished At"; DateTime)
        {
            Caption = 'Execution Finished At';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50102; "ALP Output Qty."; Decimal)
        {
            Caption = 'Execution Output Qty.';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(50103; "ALP Scrap Qty."; Decimal)
        {
            Caption = 'Execution Scrap Qty.';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(50104; "ALP Planned Start"; DateTime)
        {
            Caption = 'Fine Plan Start';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50105; "ALP Planned End"; DateTime)
        {
            Caption = 'Fine Plan End';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50106; "ALP Queue Position"; Integer)
        {
            Caption = 'Fine Plan Queue Position';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50107; "ALP Finished By"; Code[20])
        {
            Caption = 'Finished By (Employee)';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            TableRelation = Employee;
        }
    }

    keys
    {
        key(ALPProdOrder; Status, "Prod. Order No.")
        {
        }
    }
}
