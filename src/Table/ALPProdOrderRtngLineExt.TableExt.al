tableextension 50004 "ALP Prod Order Rtng Line Ext" extends "Prod. Order Routing Line"
{
    fields
    {
        field(50000; "ALP Actual Availability"; Decimal)
        {
            Caption = 'Actual Availability';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
        field(50001; "ALP Actual Productivity"; Decimal)
        {
            Caption = 'Actual Productivity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 4;
            Editable = false;
            MinValue = 0;
            MaxValue = 1;
        }
    }
}
