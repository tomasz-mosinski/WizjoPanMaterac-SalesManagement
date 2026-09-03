namespace EDN.SalesManagement;

codeunit 50103 "EDN Neg. Sale Reconciliation"
{
    Access = Public;
    Permissions = tabledata "EDN Neg. Sale Override Log" = rm,
                  tabledata "NPR POS Entry" = r,
                  tabledata "NPR POS Entry Sales Line" = r;
    TableNo = "EDN Neg. Sale Override Log";

    var
        ReconciledMsg: Label 'Entries checked: %1. Marked as probably unposted: %2.', Comment = '%1 = number checked, %2 = number marked';

    trigger OnRun()
    begin
        RunReconciliation(GetDefaultGracePeriod());
    end;


    procedure RunReconciliation(GracePeriod: Duration) FlaggedCount: Integer
    var
        OverrideLog: Record "EDN Neg. Sale Override Log";
        CheckedCount: Integer;
    begin
        OverrideLog.SetRange("Prevent Neg. Inv. Active", true);
        OverrideLog.SetRange("Adjustment Posted", false);
        OverrideLog.SetRange("POS Entry Post Failed", false);
        OverrideLog.SetFilter("Created At", '<%1', CurrentDateTime() - GracePeriod);
        if not OverrideLog.FindSet(true) then
            exit(0);

        repeat
            CheckedCount += 1;
            if IsLikelyUnposted(OverrideLog) then begin
                OverrideLog."POS Entry Post Failed" := true;
                OverrideLog.Modify(true);
                FlaggedCount += 1;
            end;
        until OverrideLog.Next() = 0;

        if GuiAllowed() then
            Message(ReconciledMsg, CheckedCount, FlaggedCount);
    end;


    local procedure IsLikelyUnposted(OverrideLog: Record "EDN Neg. Sale Override Log"): Boolean
    var
        AvailabilityCalc: Codeunit "EDN Availability Calc";
        PendingQty: Decimal;
        InventoryQty: Decimal;
        EffBinCode: Code[20];
    begin
        EffBinCode := AvailabilityCalc.GetEffectiveBinCode(
            OverrideLog."Item No.", OverrideLog."Variant Code", OverrideLog."Location Code", OverrideLog."Bin Code");

        PendingQty := AvailabilityCalc.CalcPendingPOSEntryQty(
            OverrideLog."Item No.", OverrideLog."Variant Code", OverrideLog."Location Code", EffBinCode);
        if PendingQty <= 0 then
            exit(false);

        InventoryQty := AvailabilityCalc.CalcInventory(
            OverrideLog."Item No.", OverrideLog."Variant Code", OverrideLog."Location Code", EffBinCode);

        exit(InventoryQty < PendingQty);
    end;


    procedure FlagEntriesForSale(RegisterNo: Code[10]; SalesTicketNo: Code[20]; POSEntryNo: Integer)
    var
        OverrideLog: Record "EDN Neg. Sale Override Log";
    begin
        OverrideLog.SetRange("Register No.", RegisterNo);
        OverrideLog.SetRange("Sales Ticket No.", SalesTicketNo);
        if not OverrideLog.FindSet(true) then
            exit;

        repeat
            OverrideLog."POS Entry No." := POSEntryNo;
            OverrideLog."POS Entry Post Failed" := true;
            OverrideLog.Modify(true);
        until OverrideLog.Next() = 0;
    end;


    local procedure GetDefaultGracePeriod(): Duration
    begin
        exit(2 * 60 * 60 * 1000);
    end;
}
