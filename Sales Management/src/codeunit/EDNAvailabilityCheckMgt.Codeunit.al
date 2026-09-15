namespace EDN.SalesManagement;

using Microsoft.Inventory.Item;
using System.Security.AccessControl;


codeunit 50101 "EDN Availability Check Mgt."
{
    Access = Public;
    Permissions = tabledata Item = r,
                  tabledata "NPR POS Sale Line" = r,
                  tabledata "NPR POS Unit" = r,
                  tabledata "NPR POS Store" = r,
                  tabledata "Access Control" = r;

    var
        AvailabilityCalc: Codeunit "EDN Availability Calc";
        OverrideHandler: Codeunit "EDN Override Handler";
        BlockedErr: Label 'Not enough stock for %1 (%2).\Available: %3, requested in this sale: %4 %5.', Comment = '%1 = Item No., %2 = description, %3 = available quantity, %4 = requested quantity, %5 = base unit of measure';
        BlockedBinErr: Label 'Not enough stock for %1 (%2) in bin %6.\Available: %3, requested in this sale: %4 %5.', Comment = '%1 = Item No., %2 = description, %3 = available quantity, %4 = requested quantity, %5 = base unit of measure, %6 = bin code';
        WarnQst: Label 'This sale will make the stock of %1 negative.\Available: %2, requested: %3.\\Do you want to continue?', Comment = '%1 = Item No., %2 = available quantity, %3 = requested quantity';
        WarnBinQst: Label 'This sale will make the stock of %1 in bin %4 negative.\Available: %2, requested: %3.\\Do you want to continue?', Comment = '%1 = Item No., %2 = available quantity, %3 = requested quantity, %4 = bin code';
        WarnPreventQst: Label 'This sale will make the stock of %1 negative.\Available: %2, requested: %3.\\Prevent Negative Inventory is turned on. The receipt will be printed, but the sale will not post until someone corrects the stock.\\Do you want to continue?', Comment = '%1 = Item No., %2 = available quantity, %3 = requested quantity';
        WarnPreventBinQst: Label 'This sale will make the stock of %1 in bin %4 negative.\Available: %2, requested: %3.\\Prevent Negative Inventory is turned on. The receipt will be printed, but the sale will not post until someone corrects the stock.\\Do you want to continue?', Comment = '%1 = Item No., %2 = available quantity, %3 = requested quantity, %4 = bin code';
        NoBinErr: Label 'No bin is set on the line for %1. The location requires a bin. Ask an administrator to set a default bin for the item.', Comment = '%1 = Item No.';
        CancelledErr: Label 'The user cancelled the sale.';

    procedure CheckWholeSale(RegisterNo: Code[10]; SalesTicketNo: Code[20])
    var
        SaleLinePOS: Record "NPR POS Sale Line";
    begin
        SaleLinePOS.SetRange("Register No.", RegisterNo);
        SaleLinePOS.SetRange("Sales Ticket No.", SalesTicketNo);
        SaleLinePOS.SetRange("Line Type", SaleLinePOS."Line Type"::Item);
        SaleLinePOS.SetFilter(Quantity, '>%1', 0);
        if SaleLinePOS.FindSet() then
            repeat
                CheckLine(SaleLinePOS);
            until SaleLinePOS.Next() = 0;
    end;

    procedure CheckLine(var SaleLinePOS: Record "NPR POS Sale Line")
    var
        Item: Record Item;
        POSUnit: Record "NPR POS Unit";
        POSStore: Record "NPR POS Store";
        AvailableBase: Decimal;
        RequestedBase: Decimal;
        EffBinCode: Code[20];
    begin
        if not IsLineRelevant(SaleLinePOS, Item) then
            exit;

        if not POSUnit.Get(SaleLinePOS."Register No.") then
            exit;

        if not POSStore.Get(POSUnit."POS Store Code") then
            exit;

        if POSStore."EDN Block Mode" = POSStore."EDN Block Mode"::Disabled then
            exit;

        if SaleLinePOS."Location Code" = '' then
            exit;

        if AvailabilityCalc.LocationRequiresBin(SaleLinePOS."Location Code") then
            if SaleLinePOS."Bin Code" = '' then
                Error(NoBinErr, SaleLinePOS."No.");

        EffBinCode := AvailabilityCalc.GetEffectiveBinCode(SaleLinePOS."No.", SaleLinePOS."Variant Code", SaleLinePOS."Location Code", SaleLinePOS."Bin Code");

        AvailableBase := AvailabilityCalc.GetAvailableQty(SaleLinePOS."No.", SaleLinePOS."Variant Code", SaleLinePOS."Location Code", EffBinCode, POSStore, SaleLinePOS."Register No.", SaleLinePOS."Sales Ticket No.");

        RequestedBase := SaleLinePOS."Quantity (Base)" + AvailabilityCalc.GetCurrentSaleQty(SaleLinePOS, EffBinCode);

        if RequestedBase <= AvailableBase then
            exit;

        if HasOverridePermission(POSStore) then begin
            OverrideHandler.HandleOverride(SaleLinePOS, POSStore, AvailableBase, RequestedBase, Enum::"EDN Override Reason"::"Permission Override");
            exit;
        end;

        case POSStore."EDN Block Mode" of
            POSStore."EDN Block Mode"::"Hard Block":
                if EffBinCode <> '' then
                    Error(BlockedBinErr,
                        SaleLinePOS."No.", SaleLinePOS.Description,
                        AvailableBase, RequestedBase, Item."Base Unit of Measure", EffBinCode)
                else
                    Error(BlockedErr,
                        SaleLinePOS."No.", SaleLinePOS.Description,
                        AvailableBase, RequestedBase, Item."Base Unit of Measure");

            POSStore."EDN Block Mode"::Warning:
                begin
                    if not ConfirmSaleBelowStock(
                        SaleLinePOS, EffBinCode, AvailableBase, RequestedBase)
                    then
                        Error(CancelledErr);

                    OverrideHandler.HandleOverride(
                        SaleLinePOS, POSStore, AvailableBase, RequestedBase,
                        Enum::"EDN Override Reason"::"Cashier Confirmed");
                end;
        end;
    end;

    local procedure IsLineRelevant(SaleLinePOS: Record "NPR POS Sale Line"; var Item: Record Item): Boolean
    begin

        if SaleLinePOS."Line Type" <> SaleLinePOS."Line Type"::Item then
            exit(false);

        if SaleLinePOS."Quantity (Base)" <= 0 then
            exit(false);

        if SaleLinePOS."No." in ['', '*'] then
            exit(false);

        if not Item.Get(SaleLinePOS."No.") then
            exit(false);

        if not Item.IsInventoriableType() then
            exit(false);

        if Item."EDN Allow POS Negative" then
            exit(false);

        exit(true);
    end;

    local procedure ConfirmSaleBelowStock(SaleLinePOS: Record "NPR POS Sale Line"; EffBinCode: Code[20]; AvailableBase: Decimal; RequestedBase: Decimal): Boolean
    var
        ItemNo: Code[20];
        PreventActive: Boolean;
    begin
        ItemNo := SaleLinePOS."No.";
        PreventActive := AvailabilityCalc.IsPreventNegativeActive(ItemNo);

        if EffBinCode <> '' then begin
            if PreventActive then
                exit(Confirm(WarnPreventBinQst, false, ItemNo, AvailableBase, RequestedBase, EffBinCode));

            exit(Confirm(WarnBinQst, false, ItemNo, AvailableBase, RequestedBase, EffBinCode));
        end;

        if PreventActive then
            exit(Confirm(WarnPreventQst, false, ItemNo, AvailableBase, RequestedBase));

        exit(Confirm(WarnQst, false, ItemNo, AvailableBase, RequestedBase));
    end;

    local procedure HasOverridePermission(POSStore: Record "NPR POS Store"): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        if POSStore."EDN Override Permission" = '' then
            exit(false);

        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", POSStore."EDN Override Permission");
        exit(not AccessControl.IsEmpty());
    end;
}
