enum 50003 "ALP Work Log Status"
{
    Extensible = false;
    Caption = 'Work Log Status';

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Closed)
    {
        Caption = 'Closed';
    }
    value(2; Superseded)
    {
        Caption = 'Superseded';
    }
    value(3; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
