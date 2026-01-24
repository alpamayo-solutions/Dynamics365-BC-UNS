table 50003 "ALP Output Inbox"
{
    Caption = 'ALP Output Inbox';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Message Id"; Guid)
        {
            Caption = 'Message Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
            TableRelation = "Production Order"."No.";
        }
        field(3; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Qty. Produced"; Decimal)
        {
            Caption = 'Quantity Produced';
            DataClassification = SystemMetadata;
            MinValue = 0;
            DecimalPlaces = 0 : 5;
        }
        field(5; "Qty. Rejected"; Decimal)
        {
            Caption = 'Quantity Rejected';
            DataClassification = SystemMetadata;
            MinValue = 0;
            DecimalPlaces = 0 : 5;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(7; "Source Timestamp"; DateTime)
        {
            Caption = 'Source Timestamp';
            DataClassification = SystemMetadata;
        }
        field(8; Source; Code[20])
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;
        }
        field(9; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
        field(10; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }
        field(11; Status; Enum "ALP Integration Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(12; Error; Text[2048])
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
        key(OrderStatus; "Order No.", Status)
        {
            SumIndexFields = "Qty. Produced", "Qty. Rejected";
        }
    }
}
