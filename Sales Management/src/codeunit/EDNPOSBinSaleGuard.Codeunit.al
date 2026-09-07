namespace EDN.SalesManagement;

codeunit 50106 "EDN POS Bin Sale Guard"
{
    Access = Internal;
    Permissions = tabledata "NPR POS Sale Line" = r;
    SingleInstance = true;

    var
        AvailabilityCalc: Codeunit "EDN Availability Calc";
        BypassActive: Boolean;
        PaymentBlockedByBinErr: Label 'Payment cannot be taken for this sale. Item %1 is on bin %2, which is not enabled for POS sales (Allowed for POS Sale = No). Move the item to a sales floor bin marked "Allowed for POS Sale", or remove the line.', Comment = '%1 = Item No., %2 = bin code';


    /// <summary>
    /// Turns the bin-check bypass on or off for the current POS session. The "convert POS line to sales
    /// order" flow sets it while it puts the reservation bin on a line and collects the deposit, then
    /// clears it (also in its error path). Any switch back to the Sale view clears it defensively.
    /// </summary>
    procedure SetBypassBinCheckForPayment(NewValue: Boolean)
    begin
        BypassActive := NewValue;
    end;

    procedure BypassBinCheckForPaymentActive(): Boolean
    begin
        exit(BypassActive);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NPR POS Front End Management", 'OnBeforeChangeToPaymentView', '', false, false)]
    local procedure BlockPaymentViewWhenLineOnForbiddenBin(POSSession: Codeunit "NPR POS Session")
    var
        SalePOS: Record "NPR POS Sale";
        POSSale: Codeunit "NPR POS Sale";
        BinCode: Code[20];
        ItemNo: Code[20];
    begin
        if BypassActive then
            exit;

        POSSession.GetSale(POSSale);
        POSSale.GetCurrentSale(SalePOS);

        if AnyItemLineOnForbiddenBin(SalePOS."Register No.", SalePOS."Sales Ticket No.", BinCode, ItemNo) then
            Error(PaymentBlockedByBinErr, ItemNo, BinCode);
    end;

    [EventSubscriber(ObjectType::Table, Database::"NPR POS Sale Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockPaymentLineWhenLineOnForbiddenBin(var Rec: Record "NPR POS Sale Line")
    var
        BinCode: Code[20];
        ItemNo: Code[20];
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Line Type" <> Rec."Line Type"::"POS Payment" then
            exit;
        if BypassActive then
            exit;

        if AnyItemLineOnForbiddenBin(Rec."Register No.", Rec."Sales Ticket No.", BinCode, ItemNo) then
            Error(PaymentBlockedByBinErr, ItemNo, BinCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NPR POS Front End Management", 'OnBeforeChangeToSaleView', '', false, false)]
    local procedure ClearBypassOnSaleView(POSSession: Codeunit "NPR POS Session")
    begin
        BypassActive := false;
    end;


    local procedure AnyItemLineOnForbiddenBin(RegisterNo: Code[10]; SalesTicketNo: Code[20]; var BinCode: Code[20]; var ItemNo: Code[20]): Boolean
    var
        SaleLinePOS: Record "NPR POS Sale Line";
    begin
        if RegisterNo = '' then
            exit(false);

        SaleLinePOS.SetRange("Register No.", RegisterNo);
        SaleLinePOS.SetRange("Sales Ticket No.", SalesTicketNo);
        SaleLinePOS.SetRange("Line Type", SaleLinePOS."Line Type"::Item);
        SaleLinePOS.SetFilter("Bin Code", '<>%1', '');
        if SaleLinePOS.FindSet() then
            repeat
                if AvailabilityCalc.LocationRequiresBin(SaleLinePOS."Location Code") then
                    if not AvailabilityCalc.IsPOSSaleBin(SaleLinePOS."Location Code", SaleLinePOS."Bin Code") then begin
                        BinCode := SaleLinePOS."Bin Code";
                        ItemNo := SaleLinePOS."No.";
                        exit(true);
                    end;
            until SaleLinePOS.Next() = 0;

        exit(false);
    end;
}
