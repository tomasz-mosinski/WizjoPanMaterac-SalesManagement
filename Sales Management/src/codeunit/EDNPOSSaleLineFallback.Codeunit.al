namespace EDN.SalesManagement;

using Microsoft.Inventory.Setup;

codeunit 50105 "EDN POS Sale Line Fallback"
{
    Access = Internal;
    Permissions = tabledata "NPR POS Sale Line" = r;
    SingleInstance = true;

    var
        MarkerActive: Boolean;
        MarkerSystemId: Guid;
        MarkerNo: Code[20];
        MarkerVariant: Code[10];
        MarkerLocation: Code[10];
        MarkerUoM: Code[10];
        MarkerQtyBase: Decimal;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NPR POS Sale Line", 'OnAfterSetQuantityBeforeCommit', '', false, false)]
    local procedure NprOnAfterSetQuantityBeforeCommit(var SaleLinePOS: Record "NPR POS Sale Line"; xSaleLinePOS: Record "NPR POS Sale Line")
    begin
        HandlePublicSetEvent(SaleLinePOS);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NPR POS Sale Line", 'OnAfterSetUoMBeforeCommit', '', false, false)]
    local procedure NprOnAfterSetUoMBeforeCommit(var SaleLinePOS: Record "NPR POS Sale Line"; xSaleLinePOS: Record "NPR POS Sale Line")
    begin
        HandlePublicSetEvent(SaleLinePOS);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NPR POS Sale Line", 'OnAfterSetLocationBeforeCommit', '', false, false)]
    local procedure NprOnAfterSetLocationBeforeCommit(var SaleLinePOS: Record "NPR POS Sale Line"; xSaleLinePOS: Record "NPR POS Sale Line")
    begin
        HandlePublicSetEvent(SaleLinePOS);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NPR POS Sale Line", 'OnAfterInsertPOSSaleLineBeforeCommit', '', false, false)]
    local procedure NprOnAfterInsertPOSSaleLineBeforeCommit(var SaleLinePOS: Record "NPR POS Sale Line")
    var
        CheckMgt: Codeunit "EDN Availability Check Mgt.";
    begin
        if SaleLinePOS.IsTemporary() then
            exit;
        if not IsNprEventModeEnabled() then
            exit;
        ClearMarker();
        CheckMgt.CheckLine(SaleLinePOS);
    end;

    local procedure HandlePublicSetEvent(var SaleLinePOS: Record "NPR POS Sale Line")
    var
        CheckMgt: Codeunit "EDN Availability Check Mgt.";
    begin
        if SaleLinePOS.IsTemporary() then
            exit;
        if not IsNprEventModeEnabled() then
            exit;
        if TryConsumeMarker(SaleLinePOS) then
            exit;
        CheckMgt.CheckLine(SaleLinePOS);
    end;


    [EventSubscriber(ObjectType::Table, Database::"NPR POS Sale Line", 'OnAfterValidateEvent', 'Quantity', false, false)]
    local procedure OnAfterValidateQuantity(var Rec: Record "NPR POS Sale Line"; var xRec: Record "NPR POS Sale Line")
    var
        CheckMgt: Codeunit "EDN Availability Check Mgt.";
    begin
        if Rec.IsTemporary() then
            exit;
        ClearMarker();
        if not IsFallbackEnabled() then
            exit;
        if IsNullGuid(Rec.SystemId) and IsNprEventModeEnabled() then
            exit;

        if Rec.Quantity = xRec.Quantity then
            exit;

        CheckMgt.CheckLine(Rec);

        if not IsNullGuid(Rec.SystemId) then
            ArmMarker(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"NPR POS Sale Line", 'OnAfterValidateEvent', 'Variant Code', false, false)]
    local procedure OnAfterValidateVariantCode(var Rec: Record "NPR POS Sale Line"; var xRec: Record "NPR POS Sale Line")
    var
        CheckMgt: Codeunit "EDN Availability Check Mgt.";
    begin
        if Rec.IsTemporary() then
            exit;

        ClearMarker();

        if not IsFallbackEnabled() then
            exit;
        if IsNullGuid(Rec.SystemId) and IsNprEventModeEnabled() then
            exit;
        if Rec."Variant Code" = xRec."Variant Code" then
            exit;
        if Rec.Quantity = 0 then
            exit;

        CheckMgt.CheckLine(Rec);

        if not IsNullGuid(Rec.SystemId) then
            ArmMarker(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"NPR POS Sale Line", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure OnAfterValidateLocationCode(var Rec: Record "NPR POS Sale Line"; var xRec: Record "NPR POS Sale Line")
    var
        CheckMgt: Codeunit "EDN Availability Check Mgt.";
    begin
        if Rec.IsTemporary() then
            exit;

        ClearMarker();

        if not IsFallbackEnabled() then
            exit;
        if IsNullGuid(Rec.SystemId) and IsNprEventModeEnabled() then
            exit;
        if Rec."Location Code" = xRec."Location Code" then
            exit;
        if Rec.Quantity = 0 then
            exit;

        CheckMgt.CheckLine(Rec);

        if not IsNullGuid(Rec.SystemId) then
            ArmMarker(Rec);
    end;


    local procedure ClearMarker()
    begin
        MarkerActive := false;
        Clear(MarkerSystemId);
        MarkerNo := '';
        MarkerVariant := '';
        MarkerLocation := '';
        MarkerUoM := '';
        MarkerQtyBase := 0;
    end;

    local procedure ArmMarker(SaleLinePOS: Record "NPR POS Sale Line")
    begin
        MarkerActive := true;
        MarkerSystemId := SaleLinePOS.SystemId;
        MarkerNo := SaleLinePOS."No.";
        MarkerVariant := SaleLinePOS."Variant Code";
        MarkerLocation := SaleLinePOS."Location Code";
        MarkerUoM := SaleLinePOS."Unit of Measure Code";
        MarkerQtyBase := SaleLinePOS."Quantity (Base)";
    end;

    local procedure MarkerMatches(SaleLinePOS: Record "NPR POS Sale Line"): Boolean
    begin
        exit(
            MarkerActive and
            (MarkerSystemId = SaleLinePOS.SystemId) and
            (MarkerNo = SaleLinePOS."No.") and
            (MarkerVariant = SaleLinePOS."Variant Code") and
            (MarkerLocation = SaleLinePOS."Location Code") and
            (MarkerUoM = SaleLinePOS."Unit of Measure Code") and
            (MarkerQtyBase = SaleLinePOS."Quantity (Base)"));
    end;

    local procedure TryConsumeMarker(SaleLinePOS: Record "NPR POS Sale Line"): Boolean
    var
        Hit: Boolean;
    begin
        Hit := MarkerMatches(SaleLinePOS);
        ClearMarker();
        exit(Hit);
    end;


    local procedure IsNprEventModeEnabled(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if not InventorySetup.Get() then
            exit(false);
        exit(InventorySetup."EDN Use NPR POS Events");
    end;

    local procedure IsFallbackEnabled(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if not InventorySetup.Get() then
            exit(false);
        exit(InventorySetup."EDN Use Fallback Hook");
    end;
}
