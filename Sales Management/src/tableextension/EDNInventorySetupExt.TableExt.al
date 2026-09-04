namespace EDN.SalesManagement;

using Microsoft.Inventory.Setup;

tableextension 50101 "EDN Inventory Setup Ext" extends "Inventory Setup"
{
    fields
    {
        field(50100; "EDN Use Fallback Hook"; Boolean)
        {
            Caption = 'Check POS Using Table Events';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'The default mechanism. It uses standard table events, so it works with any NP Retail version. Turn it off only after you enable the optional NP Retail event subscribers from the optional folder, otherwise the cashier is asked to confirm twice.';
        }
        field(50101; "EDN Use NPR POS Events"; Boolean)
        {
            Caption = 'Check POS Using NP Retail Events';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'The primary mechanism. It subscribes to the public NP Retail POS Sale Line events (quantity, unit of measure, location and line insert). Leave it on. It can run together with the table-event fallback without asking the cashier twice.';
        }
    }
}
