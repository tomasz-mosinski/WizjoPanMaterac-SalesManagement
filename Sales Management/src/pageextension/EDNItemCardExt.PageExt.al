namespace EDN.SalesManagement;

using Microsoft.Inventory.Item;

pageextension 50102 "EDN Item Card Ext" extends "Item Card"
{
    layout
    {
        addafter("Inventory")
        {
            field("EDN Allow POS Negative"; Rec."EDN Allow POS Negative")
            {
                ApplicationArea = All;
                ToolTip = 'Lets the POS sell this item without enough stock, with no warning and no block. Use it for services, deposits and vouchers.';
            }
        }
    }
}
