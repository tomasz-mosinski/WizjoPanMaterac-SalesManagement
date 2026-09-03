namespace EDN.SalesManagement;

enum 50102 "EDN Override Reason"
{
    Access = Public;
    Caption = 'Override Reason';
    Extensible = true;

    value(0; "Cashier Confirmed")
    {
        Caption = 'Cashier Confirmed';
    }

    value(1; "Permission Override")
    {
        Caption = 'Permission Override';
    }

    value(2; "Offline Mode")
    {
        Caption = 'Offline Mode';
    }
}
