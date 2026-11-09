enum 50100 "ALP Command Result"
{
    Extensible = false;
    Caption = 'Command Result';

    value(0; Recorded)
    {
        Caption = 'Recorded';
    }
    value(1; Posted)
    {
        Caption = 'Posted';
    }
    value(2; Duplicate)
    {
        Caption = 'Duplicate';
    }
}
