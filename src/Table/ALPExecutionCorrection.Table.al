table 50007 "ALP Execution Correction"
{
    Caption = 'ALP Execution Correction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Correction Id"; Text[50])
        {
            Caption = 'Correction Id';
            DataClassification = SystemMetadata;
        }
        field(3; Action; Text[30])
        {
            Caption = 'Action';
            DataClassification = CustomerContent;
        }
        field(4; "Target Event Ids"; Text[250])
        {
            Caption = 'Target Event Ids';
            DataClassification = CustomerContent;
        }
        field(5; "Requested By"; Text[100])
        {
            Caption = 'Requested By';
            DataClassification = CustomerContent;
        }
        field(6; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
            DataClassification = CustomerContent;
        }
        field(7; "Reason Code"; Code[50])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
        }
        field(8; "Reason Text"; Text[250])
        {
            Caption = 'Reason Text';
            DataClassification = CustomerContent;
        }
        field(9; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
        }
        field(10; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No.";
        }
        field(11; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(12; "Operator Id"; Code[20])
        {
            Caption = 'Operator Id';
            DataClassification = CustomerContent;
        }
        field(13; "Shift Code"; Code[10])
        {
            Caption = 'Shift Code';
            DataClassification = CustomerContent;
        }
        field(14; "Event Type"; Text[20])
        {
            Caption = 'Event Type';
            DataClassification = CustomerContent;
        }
        field(15; "Replacement Start Time"; DateTime)
        {
            Caption = 'Replacement Start Time';
            DataClassification = CustomerContent;
        }
        field(16; "Replacement End Time"; DateTime)
        {
            Caption = 'Replacement End Time';
            DataClassification = CustomerContent;
        }
        field(17; Processed; Boolean)
        {
            Caption = 'Processed';
            DataClassification = SystemMetadata;
        }
        field(18; Error; Text[250])
        {
            Caption = 'Error';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(CorrectionId; "Correction Id")
        {
        }
    }
}
