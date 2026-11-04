/// <summary>
/// Log of step-finish commands from the Execution app. One row per received command, including
/// idempotent repeats (Result = Duplicate), so every call is traceable.
/// </summary>
table 50101 "ALP Step Finish"
{
    Caption = 'Step Finish';
    DataClassification = CustomerContent;
    LookupPageId = "ALP Step Finishes";
    DrillDownPageId = "ALP Step Finishes";

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
        field(4; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." where(Status = filter(Released | Finished));
            ValidateTableRelation = false;
        }
        field(5; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(6; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(7; "Ran On Type"; Text[20])
        {
            Caption = 'Ran On Type';
        }
        field(8; "Ran On No."; Code[20])
        {
            Caption = 'Ran On No.';
        }
        field(9; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(10; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
        }
        field(11; "Setup Minutes"; Decimal)
        {
            Caption = 'Setup Minutes';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(12; "Run Minutes"; Decimal)
        {
            Caption = 'Run Minutes';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(13; "Output Quantity"; Decimal)
        {
            Caption = 'Output Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(14; "Scrap Quantity"; Decimal)
        {
            Caption = 'Scrap Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(15; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
            TableRelation = Scrap;
        }
        field(16; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = Employee;
        }
        field(20; Result; Enum "ALP Command Result")
        {
            Caption = 'Result';
            DataClassification = SystemMetadata;
        }
        field(21; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(22; "Capacity Ledger Entry No."; Integer)
        {
            Caption = 'Capacity Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(23; "Received At"; DateTime)
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
        key(Step; "Prod. Order No.", "Routing Reference No.", "Operation No.")
        {
        }
    }
}
