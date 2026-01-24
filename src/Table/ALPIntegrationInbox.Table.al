table 50001 "ALP Integration Inbox"
{
    Caption = 'ALP Integration Inbox';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Message Id"; Guid)
        {
            Caption = 'Message Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Message Type"; Code[50])
        {
            Caption = 'Message Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
        field(6; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }
        field(7; Status; Enum "ALP Integration Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(8; Error; Text[2048])
        {
            Caption = 'Error';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Message Id")
        {
            Clustered = true;
        }
        key(OrderOp; "Order No.", "Operation No.")
        {
        }
        key(Status; Status, "Received At")
        {
        }
    }
}
