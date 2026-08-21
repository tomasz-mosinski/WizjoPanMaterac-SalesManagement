namespace EDN.SalesManagement;

using Microsoft.Sales.Customer;

tableextension 50100 "EDN Customer" extends Customer
{
    fields
    {
        field(50100; "EDN Symbol"; Text[30])
        {
            Caption = 'Symbol';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies additional number/identifier of the customer.';
        }
        field(50101; "EDN Analytics"; Text[30])
        {
            Caption = 'Analytics';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies additional number/identifier of the customer.';
        }
    }
}