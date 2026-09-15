namespace EDN.SalesManagement;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

permissionset 50100 "EDN Sales Mgt(SUPER)"
{
    Assignable = true;
    Caption = 'Sales Management (SUPER)';

    Permissions =
        tabledata "EDN Neg. Sale Override Log" = RIMD,
        table "EDN Neg. Sale Override Log" = X,
        page "EDN Neg. Sale Override Log" = X,
        codeunit "EDN Availability Calc" = X,
        codeunit "EDN Override Handler" = X,
        codeunit "EDN Availability Check Mgt." = X,
        codeunit "EDN POS Sale Line Fallback" = X,
        codeunit "EDN POS Bin Sale Guard" = X,
        codeunit "EDN Neg. Sale Reconciliation" = X,
        codeunit "EDN Install" = X;
}
