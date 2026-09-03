namespace EDN.SalesManagement;

using Microsoft.Inventory.Setup;

pageextension 50105 "EDN Inventory Setup PageExt" extends "Inventory Setup"
{
    layout
    {
        addlast(General)
        {
            field("EDN Use NPR POS Events"; Rec."EDN Use NPR POS Events")
            {
                ApplicationArea = All;
                ToolTip = 'The primary mechanism. It subscribes to the public NP Retail POS Sale Line events (quantity, unit of measure, location and line insert). Leave it on. It can run together with the table-event fallback without asking the cashier twice.';
            }
            field("EDN Use Fallback Hook"; Rec."EDN Use Fallback Hook")
            {
                ApplicationArea = All;
                ToolTip = 'The default mechanism. It uses standard table events, so it works with any NP Retail version. Turn it off only after you enable the optional NP Retail event subscribers.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("EDN EDNShowOverrideLog")
            {
                ApplicationArea = All;
                Caption = 'POS Override Log';
                Image = ErrorLog;
                RunObject = page "EDN Neg. Sale Override Log";
                ToolTip = 'Shows the cases where a sale below the available stock was allowed at the POS.';
            }
        }
    }
}
