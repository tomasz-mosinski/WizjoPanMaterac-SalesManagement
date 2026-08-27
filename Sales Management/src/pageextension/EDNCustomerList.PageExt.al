namespace EDN.SalesManagement;

using Microsoft.Sales.Customer;

pageextension 50101 "EDN Customer List" extends "Customer List"
{
    layout
    {
        addafter("No.")
        {

            field("EDN Symbol"; Rec."EDN Symbol")
            {
                ApplicationArea = All;
            }
            field("EDN Analytics"; Rec."EDN Analytics")
            {
                ApplicationArea = All;
            }
        }
    }
}