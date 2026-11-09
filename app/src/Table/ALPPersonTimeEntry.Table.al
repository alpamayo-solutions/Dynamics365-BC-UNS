/// <summary>
/// Person time on a step, one row per time slice of an Execution app person session.
/// A new revision of a session (different Session Key) supersedes the earlier rows of the same Session Id;
/// rows are never edited in place so the history stays auditable.
/// </summary>
table 50102 "ALP Person Time Entry"
{
    Caption = 'Person Time Entry';
    DataClassification = CustomerContent;
    LookupPageId = "ALP Person Time Entries";
    DrillDownPageId = "ALP Person Time Entries";

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
        field(3; "Session Id"; Text[50])
        {
            Caption = 'Session Id';
            DataClassification = SystemMetadata;
        }
        field(4; "Session Key"; Text[100])
        {
            Caption = 'Session Key';
            DataClassification = SystemMetadata;
        }
        field(5; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = Employee;
        }
        field(6; "Step Id"; Text[100])
        {
            Caption = 'Step Id';
        }
        field(7; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        field(8; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(9; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(10; "Work Place Type"; Text[20])
        {
            Caption = 'Work Place Type';
        }
        field(11; "Work Place No."; Code[20])
        {
            Caption = 'Work Place No.';
        }
        field(12; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(13; "Ended At"; DateTime)
        {
            Caption = 'Ended At';
        }
        field(14; Minutes; Decimal)
        {
            Caption = 'Minutes';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
        field(15; Status; Enum "ALP Person Time Status")
        {
            Caption = 'Status';
        }
        field(16; Cancelled; Boolean)
        {
            Caption = 'Cancel Session';
            DataClassification = SystemMetadata;
        }
        field(17; Result; Enum "ALP Command Result")
        {
            Caption = 'Result';
            DataClassification = SystemMetadata;
        }
        field(18; "Received At"; DateTime)
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
        key(Session; "Session Id", Status)
        {
        }
        key(Step; "Prod. Order No.", "Routing Reference No.", "Operation No.", Status)
        {
            SumIndexFields = Minutes;
        }
    }
}
