// This table stores STATIC integration configuration only.
// It maps UNS topic paths to ERP Work Centers.
// Work Center No. may be empty for discovered-but-unmapped topics.
// Operation No. is resolved DYNAMICALLY at execution time based on Production Order context.
table 50005 "ALP UNS Topic Mapping"
{
    Caption = 'UNS Topic Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "UNS Topic"; Text[250])
        {
            Caption = 'UNS Topic';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center"."No.";

            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
                WorkCenterBlockedErr: Label 'Work Center %1 is blocked.', Comment = '%1 = Work Center No.';
            begin
                if "Work Center No." <> '' then begin
                    WorkCenter.Get("Work Center No.");
                    if WorkCenter.Blocked then
                        Error(WorkCenterBlockedErr, "Work Center No.");
                end;
            end;
        }
        field(4; Status; Enum "ALP UNS Mapping Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            InitValue = Active;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(6; "Source System"; Code[20])
        {
            Caption = 'Source System';
            DataClassification = CustomerContent;
        }
        field(7; "Valid From"; Date)
        {
            Caption = 'Valid From';
            DataClassification = CustomerContent;
        }
        field(8; "Valid To"; Date)
        {
            Caption = 'Valid To';
            DataClassification = CustomerContent;
        }
        field(9; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12; "Modified By"; Code[50])
        {
            Caption = 'Modified By';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "UNS Topic")
        {
            Clustered = true;
        }
        key(WorkCenter; "Work Center No.")
        {
        }
        key(Status; Status)
        {
        }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        "Modified At" := CurrentDateTime();
        "Modified By" := CopyStr(UserId(), 1, MaxStrLen("Modified By"));
    end;

    trigger OnModify()
    begin
        "Modified At" := CurrentDateTime();
        "Modified By" := CopyStr(UserId(), 1, MaxStrLen("Modified By"));
    end;
}
