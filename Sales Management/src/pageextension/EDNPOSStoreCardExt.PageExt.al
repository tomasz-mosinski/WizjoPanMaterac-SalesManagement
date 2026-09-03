namespace EDN.SalesManagement;

pageextension 50106 "EDN POS Store Card Ext" extends "NPR POS Store Card"
{
    layout
    {
        addlast(content)
        {
            group("EDN EDNAvailabilityBlock")
            {
                Caption = 'Block Sale Below Stock';

                field("EDN Block Mode"; Rec."EDN Block Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sets how the POS reacts when someone tries to sell more than the available stock. Hard Block stops the sale, Warning Only lets the cashier continue.';

                    trigger OnValidate()
                    begin
                        RefreshVisibility();
                        WarnIfInconsistent();
                    end;
                }
                field("EDN Include Pending POS Entries"; Rec."EDN Incl. Pending POS Entries")
                {
                    ApplicationArea = All;
                    Enabled = BlockEnabled;
                    ToolTip = 'Subtracts quantities from sales that are already finished at the POS but not yet posted by the job queue. If you turn this off, the same item can be sold twice on the same day.';
                }
                field("EDN Include Open POS Sales"; Rec."EDN Include Open POS Sales")
                {
                    ApplicationArea = All;
                    Enabled = BlockEnabled;
                    ToolTip = 'Subtracts quantities held in open sales on other POS units. With a very high number of open sales, this can slow down the POS.';
                }
                field("EDN Override Permission"; Rec."EDN Override Permission")
                {
                    ApplicationArea = All;
                    Enabled = BlockEnabled;
                    ToolTip = 'Users with this permission set can sell the item without enough stock, and they are not asked to confirm.';

                    trigger OnValidate()
                    begin
                        WarnIfInconsistent();
                    end;
                }
                field("EDN Override Action"; Rec."EDN Override Action")
                {
                    ApplicationArea = All;
                    Enabled = BlockEnabled;
                    ToolTip = 'Sets what happens after a sale is allowed. Post Positive Adjustment corrects the stock at once, so the POS entry can be posted without an error.';

                    trigger OnValidate()
                    begin
                        RefreshVisibility();
                        WarnIfInconsistent();
                    end;
                }
                field("EDN Adjustment Jnl. Template"; Rec."EDN Adjustment Jnl. Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Item journal template used to post the correcting adjustments.';
                    Visible = ShowAdjustmentFields;
                }
                field("EDN Adjustment Jnl. Batch"; Rec."EDN Adjustment Jnl. Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Item journal batch used to post the correcting adjustments.';
                    Visible = ShowAdjustmentFields;
                }
                field("EDN Adjustment Reason Code"; Rec."EDN Adjustment Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reason code written on the adjustment, so that you can find these shortfalls in reports.';
                    Visible = ShowAdjustmentFields;
                }
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
                Caption = 'Override Log';
                Image = ErrorLog;
                RunObject = page "EDN Neg. Sale Override Log";
                RunPageLink = "POS Store Code" = field(Code);
                ToolTip = 'Shows the cases where a sale below stock was allowed in this store.';
            }
        }
    }

    var
        ShowAdjustmentFields: Boolean;
        BlockEnabled: Boolean;
        InconsistentMsg: Label 'This setup lets the cashier finish a sale below stock, but Prevent Negative Inventory is turned on in Inventory Setup.\\As a result, the receipt is printed, but the POS entry will not post during the job queue run.\\We recommend that you select Hard Block, or the action Post Positive Adjustment.';

    trigger OnAfterGetRecord()
    begin
        RefreshVisibility();
    end;

    trigger OnOpenPage()
    begin
        RefreshVisibility();
    end;

    local procedure RefreshVisibility()
    begin
        BlockEnabled := Rec."EDN Block Mode" <> Rec."EDN Block Mode"::Disabled;
        ShowAdjustmentFields :=
            Rec."EDN Override Action" = Rec."EDN Override Action"::"Auto Positive Adjustment";
    end;

    local procedure WarnIfInconsistent()
    begin
        if Rec.IsConfigurationRisky() then
            Message(InconsistentMsg);
    end;
}
