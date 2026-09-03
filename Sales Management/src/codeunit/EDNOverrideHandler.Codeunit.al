namespace EDN.SalesManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

codeunit 50104 "EDN Override Handler"
{
    Access = Public;
    Permissions = tabledata "EDN Neg. Sale Override Log" = rim,
                  tabledata "Item Journal Line" = rimd,
                  tabledata Location = r,
                  tabledata "Bin Content" = r;

    var
        AvailabilityCalc: Codeunit "EDN Availability Calc";
        AdjustmentDocNoLbl: Label 'EDNNEG%1', Locked = true;
        AdjustmentDescLbl: Label 'Automatic adjustment - POS sale below stock';
        AdjustmentFailedLbl: Label 'The stock adjustment for %1 could not be posted: %2', Comment = '%1 = Item No., %2 = error text';


    procedure HandleOverride(
        SaleLinePOS: Record "NPR POS Sale Line";
        POSStore: Record "NPR POS Store";
        AvailableBase: Decimal;
        RequestedBase: Decimal;
        Reason: Enum "EDN Override Reason")
    var
        OverrideLog: Record "EDN Neg. Sale Override Log";
        ShortfallBase: Decimal;
        PreventActive: Boolean;
    begin
        if POSStore."EDN Override Action" = POSStore."EDN Override Action"::"None" then
            exit;

        ShortfallBase := RequestedBase - AvailableBase;
        if ShortfallBase <= 0 then
            exit;

        PreventActive := AvailabilityCalc.IsPreventNegativeActive(SaleLinePOS."No.");

        WriteLog(OverrideLog, SaleLinePOS, POSStore,
                 AvailableBase, RequestedBase, ShortfallBase, Reason, PreventActive);

        if POSStore."EDN Override Action" <> POSStore."EDN Override Action"::"Auto Positive Adjustment" then
            exit;
        if not PreventActive then
            exit;

        PostAdjustment(OverrideLog, POSStore, ShortfallBase);
    end;

    local procedure WriteLog(
        var OverrideLog: Record "EDN Neg. Sale Override Log";
        SaleLinePOS: Record "NPR POS Sale Line";
        POSStore: Record "NPR POS Store";
        AvailableBase: Decimal;
        RequestedBase: Decimal;
        ShortfallBase: Decimal;
        Reason: Enum "EDN Override Reason";
        PreventActive: Boolean)
    begin
        OverrideLog.InitFromSaleLine(SaleLinePOS, POSStore.Code);

        OverrideLog."Available Qty (Base)" := AvailableBase;
        OverrideLog."Requested Qty (Base)" := RequestedBase;
        OverrideLog."Shortfall Qty (Base)" := ShortfallBase;
        OverrideLog."Pending POS Qty (Base)" :=
            AvailabilityCalc.CalcPendingPOSEntryQty(
                SaleLinePOS."No.", SaleLinePOS."Variant Code", SaleLinePOS."Location Code",
                AvailabilityCalc.GetEffectiveBinCode(
                    SaleLinePOS."No.", SaleLinePOS."Variant Code", SaleLinePOS."Location Code", SaleLinePOS."Bin Code"));
        OverrideLog."Override Reason" := Reason;
        OverrideLog."Override Action Taken" := POSStore."EDN Override Action";
        OverrideLog."Prevent Neg. Inv. Active" := PreventActive;
        OverrideLog.Insert(true);
    end;


    local procedure PostAdjustment(
        var OverrideLog: Record "EDN Neg. Sale Override Log";
        POSStore: Record "NPR POS Store";
        QtyBase: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
        Location: Record Location;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WMSManagement: Codeunit "WMS Management";
        DocumentNo: Code[20];
        BinCodeToUse: Code[20];
    begin
        POSStore.TestField("EDN Adjustment Jnl. Template");
        POSStore.TestField("EDN Adjustment Jnl. Batch");
        Item.Get(OverrideLog."Item No.");

        DocumentNo := CopyStr(StrSubstNo(AdjustmentDocNoLbl, OverrideLog."Entry No."), 1, 20);

        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := POSStore."EDN Adjustment Jnl. Template";
        ItemJnlLine."Journal Batch Name" := POSStore."EDN Adjustment Jnl. Batch";
        ItemJnlLine."Line No." := 10000;
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine.Validate("Item No.", OverrideLog."Item No.");
        ItemJnlLine.Validate("Variant Code", OverrideLog."Variant Code");
        ItemJnlLine.Validate("Location Code", OverrideLog."Location Code");

        BinCodeToUse := OverrideLog."Bin Code";
        if (BinCodeToUse = '') and Location.Get(OverrideLog."Location Code") then
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin(
                    OverrideLog."Item No.", OverrideLog."Variant Code", OverrideLog."Location Code", BinCodeToUse);
        if BinCodeToUse <> '' then
            ItemJnlLine.Validate("Bin Code", BinCodeToUse);

        ItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ItemJnlLine.Validate(Quantity, QtyBase);
        if POSStore."EDN Adjustment Reason Code" <> '' then
            ItemJnlLine.Validate("Reason Code", POSStore."EDN Adjustment Reason Code");
        ItemJnlLine.Description := CopyStr(AdjustmentDescLbl, 1, MaxStrLen(ItemJnlLine.Description));

        if TryPostItemJnlLine(ItemJnlPostLine, ItemJnlLine) then begin
            OverrideLog."Adjustment Posted" := true;
            OverrideLog."Adjustment Document No." := DocumentNo;
        end else
            OverrideLog."Adjustment Error" :=
                CopyStr(GetLastErrorText(), 1, MaxStrLen(OverrideLog."Adjustment Error"));

        OverrideLog.Modify(true);

        if not OverrideLog."Adjustment Posted" then
            Message(AdjustmentFailedLbl, OverrideLog."Item No.", OverrideLog."Adjustment Error");
    end;

    [TryFunction]
    local procedure TryPostItemJnlLine(
        var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;
}
