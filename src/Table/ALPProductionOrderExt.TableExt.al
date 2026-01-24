tableextension 50003 "ALP Production Order Ext" extends "Production Order"
{
    fields
    {
        field(50000; "ALP Last Exec Update At"; DateTime)
        {
            Caption = 'Last Execution Update At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(50001; "ALP Execution Source"; Code[20])
        {
            Caption = 'Execution Source';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
