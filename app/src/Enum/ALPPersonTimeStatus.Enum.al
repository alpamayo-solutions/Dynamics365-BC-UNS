enum 50101 "ALP Person Time Status"
{
    Extensible = false;
    Caption = 'Person Time Status';

    value(0; Active)
    {
        Caption = 'Active';
    }
    value(1; Superseded)
    {
        Caption = 'Superseded';
    }
    value(2; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
