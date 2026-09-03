namespace EDN.SalesManagement;

using Microsoft.Warehouse.Structure;

Tableextension 50103 "EDN Bin Ext" extends Bin
{
    fields
    {
        field(60100; "EDN Allow POS Sale"; Boolean)
        {
            Caption = 'Allowed for POS Sale';
            DataClassification = CustomerContent;
            ToolTip = 'Stock in this bin counts as available for POS sales. Mark the sales floor bins. If no bin at a location is marked, POS sales from that location are blocked.';
        }
    }
}
