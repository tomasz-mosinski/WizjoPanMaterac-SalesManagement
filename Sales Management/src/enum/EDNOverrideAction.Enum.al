namespace EDN.SalesManagement;

enum 50101 "EDN Override Action"
{
    Access = Public;
    Caption = 'Action When Sale Is Allowed';
    Extensible = true;

    value(0; "None")
    {
        Caption = 'Do Nothing';
    }

    value(1; "Log Only")
    {
        Caption = 'Log Only';
    }

    value(2; "Auto Positive Adjustment")
    {
        Caption = 'Post Positive Adjustment';
    }
}
