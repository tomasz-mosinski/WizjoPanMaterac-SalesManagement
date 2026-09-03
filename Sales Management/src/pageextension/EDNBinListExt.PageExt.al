namespace EDN.SalesManagement;

using Microsoft.Warehouse.Structure;

pageextension 50103 "EDN Bin List Ext" extends "Bin List"
{
    layout
    {
        addlast(Control1)
        {
            field("EDN Allow POS Sale"; Rec."EDN Allow POS Sale")
            {
                ApplicationArea = All;
                ToolTip = 'Stock in this bin counts as available for POS sales. Mark the sales floor bins. If no bin at a location is marked, POS sales from that location are blocked.';
            }
        }
    }
}
