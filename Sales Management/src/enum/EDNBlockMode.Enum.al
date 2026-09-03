namespace EDN.SalesManagement;

enum 50100 "EDN Block Mode"
{
    Access = Public;
    Caption = 'Block Mode';
    Extensible = true;

    value(0; Disabled)
    {
        Caption = 'Disabled';
    }

    value(1; Warning)
    {
        Caption = 'Warning Only';
    }

    value(2; "Hard Block")
    {
        Caption = 'Hard Block';
    }
}
