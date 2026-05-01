table 50006 "ALP Work Log Entry"
{
    Caption = 'ALP Work Log Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Message Id"; Text[50])
        {
            Caption = 'Message Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
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
            TableRelation = "Work Center";
        }
        field(6; "Operator Id"; Code[20])
        {
            Caption = 'Operator Id';
            DataClassification = CustomerContent;
        }
        field(7; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
        }
        field(8; "Shift Code"; Code[10])
        {
            Caption = 'Shift Code';
            DataClassification = CustomerContent;
        }
        field(9; "Event Type"; Enum "ALP Work Log Event Type")
        {
            Caption = 'Event Type';
            DataClassification = CustomerContent;
        }
        field(10; "Disruption Code"; Code[20])
        {
            Caption = 'Disruption Code';
            DataClassification = CustomerContent;
        }
        field(11; "Start Time"; DateTime)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;
        }
        field(12; "End Time"; DateTime)
        {
            Caption = 'End Time';
            DataClassification = CustomerContent;
        }
        field(13; "Duration Sec"; Integer)
        {
            Caption = 'Duration (Seconds)';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(14; Source; Text[50])
        {
            Caption = 'Source';
            DataClassification = CustomerContent;
        }
        field(15; Status; Enum "ALP Work Log Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(16; "End Message Id"; Text[50])
        {
            Caption = 'End Message Id';
            DataClassification = SystemMetadata;
        }
        field(17; "Correction Id"; Text[50])
        {
            Caption = 'Correction Id';
            DataClassification = SystemMetadata;
        }
        field(18; "Invalidated By Correction Id"; Text[50])
        {
            Caption = 'Invalidated By Correction Id';
            DataClassification = SystemMetadata;
        }
        field(19; "Replaces Entry No."; Integer)
        {
            Caption = 'Replaces Entry No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(OrderOp; "Order No.", "Operation No.", Status)
        {
        }
        key(OpenIntervalByStart; "Order No.", "Operation No.", "Event Type", Status, "Start Time")
        {
        }
        key(MessageId; "Message Id")
        {
        }
        key(EndMessageId; "End Message Id")
        {
        }
        key(CorrectionId; "Correction Id")
        {
        }
    }
}
