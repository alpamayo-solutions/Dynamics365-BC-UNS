/// <summary>
/// Company-wide settings for the Execution app integration.
/// Post Output is off by default: the extension then only records execution facts on the routing line
/// and never posts. When on, a finished step posts an output journal line (see ALP Step Finish Svc).
/// </summary>
table 50100 "ALP Shopfloor Setup"
{
    Caption = 'Shopfloor Execution Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Post Output"; Boolean)
        {
            Caption = 'Post Output';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetOrInit()
    begin
        if Get() then
            exit;
        Init();
        Insert();
    end;
}
