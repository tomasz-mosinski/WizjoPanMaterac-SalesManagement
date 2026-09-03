namespace EDN.SalesManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

codeunit 50100 "EDN Availability Calc"
{
    Access = Public;
    Permissions = tabledata Item = r,
                  tabledata "Item Ledger Entry" = r,
                  tabledata "Reservation Entry" = r,
                  tabledata "Inventory Setup" = r,
                  tabledata Location = r,
                  tabledata Bin = r,
                  tabledata "Bin Content" = r,
                  tabledata "Warehouse Entry" = r,
                  tabledata "Warehouse Activity Line" = r,
                  tabledata "Warehouse Journal Line" = r,
                  tabledata "Serial No. Information" = r,
                  tabledata "Lot No. Information" = r,
                  tabledata "NPR POS Sale Line" = r,
                  tabledata "NPR POS Entry" = r,
                  tabledata "NPR POS Entry Sales Line" = r;

    var
        InventorySetupGlobal: Record "Inventory Setup";
        LocationCache: Record Location;
        BinCache: Record Bin;
        InventorySetupFetched: Boolean;
        LocationCacheLoaded: Boolean;
        LocationCacheCode: Code[10];
        BinCacheLoaded: Boolean;
        BinCacheLocation: Code[10];
        BinCacheCode: Code[20];


    procedure GetAvailableQty(
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        BinCode: Code[20];
        POSStore: Record "NPR POS Store";
        ExcludeRegisterNo: Code[10];
        ExcludeSalesTicketNo: Code[20]): Decimal
    var
        Available: Decimal;
    begin
        Available := CalcInventory(ItemNo, VariantCode, LocationCode, BinCode);

        if POSStore."EDN Incl. Pending POS Entries" then
            Available -= CalcPendingPOSEntryQty(ItemNo, VariantCode, LocationCode, BinCode);

        if POSStore."EDN Include Open POS Sales" then
            Available -= CalcOpenPOSQty(
                ItemNo, VariantCode, LocationCode, BinCode, ExcludeRegisterNo, ExcludeSalesTicketNo);

        exit(Available);
    end;


    procedure LocationRequiresBin(LocationCode: Code[10]): Boolean
    begin
        if not GetLocation(LocationCode) then
            exit(false);
        exit(
            LocationCache."Bin Mandatory" and
            not LocationCache."Directed Put-away and Pick" and
            not LocationCache."NPR No Whse. Entr. for POS");
    end;

    procedure IsBinMode(LocationCode: Code[10]; BinCode: Code[20]): Boolean
    begin
        exit((BinCode <> '') and LocationRequiresBin(LocationCode));
    end;


    procedure IsPOSSaleBin(LocationCode: Code[10]; BinCode: Code[20]): Boolean
    begin
        if BinCode = '' then
            exit(false);
        if not GetBin(LocationCode, BinCode) then
            exit(false);
        exit(BinCache."EDN Allow POS Sale");
    end;


    procedure GetEffectiveBinCode(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Code[20]
    begin
        if not IsBinMode(LocationCode, BinCode) then
            exit('');
        exit(BinCode);
    end;


    procedure CalcBinAvailToPick(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Decimal
    var
        BinContent: Record "Bin Content";
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(0);

        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        if not BinContent.FindFirst() then
            exit(0);

        exit(BinContent.CalcQtyAvailToPick(0));
    end;


    procedure CalcInventory(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if BinCode <> '' then
            exit(CalcBinAvailToPick(ItemNo, VariantCode, LocationCode, BinCode));

        ItemLedgerEntry.SetCurrentKey("Item No.", "Variant Code", Open, "Location Code");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.CalcSums(Quantity);
        exit(ItemLedgerEntry.Quantity);
    end;


    procedure CalcPendingPOSEntryQty(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Decimal
    var
        POSEntrySalesLine: Record "NPR POS Entry Sales Line";
        PendingQty: Decimal;
        LineBin: Code[20];
        BinMode: Boolean;
    begin
        BinMode := BinCode <> '';

        POSEntrySalesLine.SetRange("Item Entry No.", 0);
        POSEntrySalesLine.SetRange("No.", ItemNo);
        POSEntrySalesLine.SetRange("Variant Code", VariantCode);
        POSEntrySalesLine.SetRange("Location Code", LocationCode);
        POSEntrySalesLine.SetLoadFields(
            "POS Entry No.", "Item Entry No.", "No.", "Variant Code", "Location Code", "Bin Code", Quantity);
        if not POSEntrySalesLine.FindSet(false) then
            exit(0);

        repeat
            if BinMode then begin
                TryResolveLineBin(
                    POSEntrySalesLine."No.", POSEntrySalesLine."Variant Code",
                    POSEntrySalesLine."Location Code", POSEntrySalesLine."Bin Code", LineBin);
                if LineBin = BinCode then
                    AddPendingLineQty(POSEntrySalesLine, PendingQty);
            end else
                AddPendingLineQty(POSEntrySalesLine, PendingQty);
        until POSEntrySalesLine.Next() = 0;

        exit(PendingQty);
    end;

    local procedure AddPendingLineQty(var POSEntrySalesLine: Record "NPR POS Entry Sales Line"; var PendingQty: Decimal)
    var
        POSEntry: Record "NPR POS Entry";
        ReservationEntry: Record "Reservation Entry";
    begin
        POSEntry.SetLoadFields("Entry No.", "Sales Document Type", "Sales Document No.");
        if not POSEntry.Get(POSEntrySalesLine."POS Entry No.") then begin
            PendingQty += POSEntrySalesLine.Quantity;
            exit;
        end;

        if POSEntry."Sales Document No." = '' then begin
            PendingQty += POSEntrySalesLine.Quantity;
            exit;
        end;

        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", POSEntry."Sales Document Type");
        ReservationEntry.SetRange("Source ID", POSEntry."Sales Document No.");
        ReservationEntry.SetRange(
            "Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", POSEntrySalesLine."No.");
        ReservationEntry.SetRange("Variant Code", POSEntrySalesLine."Variant Code");
        if not ReservationEntry.IsEmpty() then begin
            ReservationEntry.CalcSums("Quantity (Base)");
            PendingQty += -ReservationEntry."Quantity (Base)";
        end;
    end;


    procedure CalcOpenPOSQty(
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        BinCode: Code[20];
        ExcludeRegisterNo: Code[10];
        ExcludeSalesTicketNo: Code[20]): Decimal
    var
        SaleLinePOS: Record "NPR POS Sale Line";
        OpenQty: Decimal;
        LineBin: Code[20];
        BinMode: Boolean;
        CountLine: Boolean;
    begin
        BinMode := BinCode <> '';

        SaleLinePOS.SetRange("Line Type", SaleLinePOS."Line Type"::Item);
        SaleLinePOS.SetRange("No.", ItemNo);
        SaleLinePOS.SetRange("Variant Code", VariantCode);
        SaleLinePOS.SetRange("Location Code", LocationCode);
        SaleLinePOS.SetFilter("Quantity (Base)", '>%1', 0);
        SaleLinePOS.SetLoadFields("Register No.", "Sales Ticket No.", "Bin Code", "Quantity (Base)");
        if not SaleLinePOS.FindSet(false) then
            exit(0);

        repeat
            CountLine := not ((SaleLinePOS."Register No." = ExcludeRegisterNo) and
                              (SaleLinePOS."Sales Ticket No." = ExcludeSalesTicketNo));
            if CountLine and BinMode then begin
                TryResolveLineBin(
                    ItemNo, VariantCode, LocationCode, SaleLinePOS."Bin Code", LineBin);
                CountLine := LineBin = BinCode;
            end;
            if CountLine then
                OpenQty += SaleLinePOS."Quantity (Base)";
        until SaleLinePOS.Next() = 0;

        exit(OpenQty);
    end;


    procedure GetCurrentSaleQty(CurrentLine: Record "NPR POS Sale Line"; EffectiveBinCode: Code[20]): Decimal
    var
        SaleLinePOS: Record "NPR POS Sale Line";
    begin
        SaleLinePOS.SetRange("Register No.", CurrentLine."Register No.");
        SaleLinePOS.SetRange("Sales Ticket No.", CurrentLine."Sales Ticket No.");
        SaleLinePOS.SetRange("Line Type", SaleLinePOS."Line Type"::Item);
        SaleLinePOS.SetRange("No.", CurrentLine."No.");
        SaleLinePOS.SetRange("Variant Code", CurrentLine."Variant Code");
        if EffectiveBinCode <> '' then
            SaleLinePOS.SetRange("Bin Code", EffectiveBinCode);
        SaleLinePOS.SetFilter("Quantity (Base)", '>%1', 0);
        SaleLinePOS.SetFilter(SystemId, '<>%1', CurrentLine.SystemId);
        SaleLinePOS.CalcSums("Quantity (Base)");
        exit(SaleLinePOS."Quantity (Base)");
    end;


    procedure IsPreventNegativeActive(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(false);

        case Item."Prevent Negative Inventory" of
            Item."Prevent Negative Inventory"::Yes:
                exit(true);
            Item."Prevent Negative Inventory"::No:
                exit(false);
        end;

        EnsureInventorySetup();
        exit(InventorySetupGlobal."Prevent Negative Inventory");
    end;


    local procedure TryResolveLineBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; LineBin: Code[20]; var ResolvedBin: Code[20]): Boolean
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        ResolvedBin := LineBin;
        if ResolvedBin <> '' then
            exit(true);
        exit(WMSManagement.GetDefaultBin(ItemNo, VariantCode, LocationCode, ResolvedBin));
    end;

    local procedure EnsureInventorySetup()
    begin
        if InventorySetupFetched then
            exit;
        InventorySetupGlobal.Get();
        InventorySetupFetched := true;
    end;

    local procedure GetLocation(LocationCode: Code[10]): Boolean
    begin
        if LocationCode = '' then
            exit(false);
        if LocationCacheLoaded and (LocationCacheCode = LocationCode) then
            exit(true);
        LocationCacheLoaded := LocationCache.Get(LocationCode);
        if LocationCacheLoaded then
            LocationCacheCode := LocationCode
        else
            LocationCacheCode := '';
        exit(LocationCacheLoaded);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20]): Boolean
    begin
        if (LocationCode = '') or (BinCode = '') then
            exit(false);
        if BinCacheLoaded and (BinCacheLocation = LocationCode) and (BinCacheCode = BinCode) then
            exit(true);
        BinCacheLoaded := BinCache.Get(LocationCode, BinCode);
        if BinCacheLoaded then begin
            BinCacheLocation := LocationCode;
            BinCacheCode := BinCode;
        end else begin
            BinCacheLocation := '';
            BinCacheCode := '';
        end;
        exit(BinCacheLoaded);
    end;
}
