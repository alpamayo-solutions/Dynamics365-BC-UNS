/// <summary>
/// Log of step-move commands: the Execution app rerouted a not-yet-started step to another work or machine center.
/// </summary>
table 50104 "ALP Step Move"
{
    Caption = 'Step Move';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Event Id"; Text[100])
        {
            Caption = 'Event Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Step Id"; Text[100])
        {
            Caption = 'Step Id';
        }
        field(4; "To Type"; Text[20])
        {
            Caption = 'To Type';
        }
        field(5; "To No."; Code[20])
        {
            Caption = 'To No.';
        }
        field(6; "From Type"; Text[20])
        {
            Caption = 'From Type';
        }
        field(7; "From No."; Code[20])
        {
            Caption = 'From No.';
        }
        field(8; Result; Enum "ALP Command Result")
        {
            Caption = 'Result';
            DataClassification = SystemMetadata;
        }
        field(9; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(EventId; "Event Id")
        {
        }
    }
}
