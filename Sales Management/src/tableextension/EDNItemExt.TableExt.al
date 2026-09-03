namespace EDN.SalesManagement;

using Microsoft.Inventory.Item;

tableextension 50102 "EDN Item Ext" extends Item
{
    fields
    {
        field(60100; "EDN Allow POS Negative"; Boolean)
        {
            Caption = 'Allow POS Sale Below Zero';
            DataClassification = CustomerContent;
        }
    }
}
