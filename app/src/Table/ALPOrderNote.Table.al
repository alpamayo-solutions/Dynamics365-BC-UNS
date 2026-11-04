/// <summary>
/// A note written by an operator in the Execution app. The text is stored as a standard record link
/// note on the production order, so it shows in the order's Notes FactBox. Deleting this row removes that note.
/// </summary>
table 50103 "ALP Order Note"
{
    Caption = 'Order Note';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Note Id"; Text[100])
        {
            Caption = 'Note Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        field(4; "Note Text"; Text[2048])
        {
            Caption = 'Text';
        }
        field(5; Author; Text[100])
        {
            Caption = 'Author';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Record Link Id"; Integer)
        {
            Caption = 'Record Link Id';
            DataClassification = SystemMetadata;
        }
        field(7; Result; Enum "ALP Command Result")
        {
            Caption = 'Result';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(NoteId; "Note Id")
        {
        }
    }

    trigger OnDelete()
    var
        RecordLink: Record "Record Link";
    begin
        if "Record Link Id" = 0 then
            exit;
        if RecordLink.Get("Record Link Id") then
            RecordLink.Delete();
    end;
}
