namespace EDN.SalesManagement;

using Microsoft.Sales.Customer;

pageextension 50100 "EDN Customer Card" extends "Customer Card"
{
    layout
    {
        addafter(Name)
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