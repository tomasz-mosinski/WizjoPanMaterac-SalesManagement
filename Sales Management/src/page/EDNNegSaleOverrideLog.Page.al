namespace EDN.SalesManagement;

using Microsoft.Inventory.Ledger;

page 50100 "EDN Neg. Sale Override Log"
{
    ApplicationArea = All;
    Caption = 'Negative Sale Override Log';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "EDN Neg. Sale Override Log";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Created At"; Rec."Created At")
                {
                    ToolTip = 'When the sale below stock was allowed.';
                }
                field("POS Store Code"; Rec."POS Store Code")
                {
                    ToolTip = 'The store where the override happened.';
                }
                field("Register No."; Rec."Register No.")
                {
                    ToolTip = 'The POS unit where the sale was allowed.';
                }
                field("Sales Ticket No."; Rec."Sales Ticket No.")
                {
                    ToolTip = 'The sales ticket that contains the allowed sale.';
                }
                field("Sale Date"; Rec."Sale Date")
                {
                    ToolTip = 'The date of the POS sale.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'The user who made the override.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'The item sold below the available stock.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ToolTip = 'The description of the item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'The variant of the item.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'The location where the shortfall happened.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ToolTip = 'The bin the sale draws from. Set only when the location requires a bin; the availability was then checked for this bin.';
                }
                field("Available Qty (Base)"; Rec."Available Qty (Base)")
                {
                    ToolTip = 'The quantity available in the base unit of measure, after unposted entries and open POS sales are subtracted.';
                }
                field("Pending POS Qty (Base)"; Rec."Pending POS Qty (Base)")
                {
                    ToolTip = 'The quantity in POS sales that are finished but not yet posted.';
                }
                field("Requested Qty (Base)"; Rec."Requested Qty (Base)")
                {
                    ToolTip = 'The total quantity requested in this sale, in the base unit of measure.';
                }
                field("Shortfall Qty (Base)"; Rec."Shortfall Qty (Base)")
                {
                    StyleExpr = ShortfallStyle;
                    ToolTip = 'The size of the shortfall in the base unit of measure.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'The unit of measure used on the sale line.';
                    Visible = false;
                }
                field("Override Reason"; Rec."Override Reason")
                {
                    ToolTip = 'Why the sale was allowed.';
                }
                field("Override Action Taken"; Rec."Override Action Taken")
                {
                    ToolTip = 'The action that the system took.';
                }
                field("Prevent Neg. Inv. Active"; Rec."Prevent Neg. Inv. Active")
                {
                    ToolTip = 'Whether Prevent Negative Inventory was active for this item.';
                }
                field("Adjustment Posted"; Rec."Adjustment Posted")
                {
                    StyleExpr = AdjustmentStyle;
                    ToolTip = 'Whether the adjustment that corrects the stock was posted.';
                }
                field("Adjustment Document No."; Rec."Adjustment Document No.")
                {
                    ToolTip = 'The document number of the adjustment in the item ledger entries.';
                }
                field("Adjustment Error"; Rec."Adjustment Error")
                {
                    ToolTip = 'The error message, if the adjustment failed.';
                }
                field("POS Entry Post Failed"; Rec."POS Entry Post Failed")
                {
                    StyleExpr = PostFailedStyle;
                    ToolTip = 'Whether posting of the POS entry failed.';
                }
                field("POS Entry No."; Rec."POS Entry No.")
                {
                    ToolTip = 'The related POS entry.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Notes; Notes)
            {
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowItemLedgerEntries)
            {
                Caption = 'Item Ledger Entries';
                Image = ItemLedger;
                ToolTip = 'Shows the item ledger entries for the selected item and location.';

                trigger OnAction()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                begin
                    ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
                    ItemLedgerEntry.SetRange("Variant Code", Rec."Variant Code");
                    ItemLedgerEntry.SetRange("Location Code", Rec."Location Code");
                    Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
                end;
            }
            action(RunReconciliation)
            {
                Caption = 'Check Unposted Entries';
                Image = Reconcile;
                ToolTip = 'Goes through the overrides without a stock adjustment and marks those whose sale is still not posted. You can also schedule this in the job queue.';

                trigger OnAction()
                var
                    Reconciliation: Codeunit "EDN Neg. Sale Reconciliation";
                begin
                    Reconciliation.RunReconciliation(2 * 60 * 60 * 1000);
                    CurrPage.Update(false);
                end;
            }
            action(ShowFailedOnly)
            {
                Caption = 'Failed Postings Only';
                Image = FilterLines;
                ToolTip = 'Shows only the sales that failed to post because of a shortfall.';

                trigger OnAction()
                begin
                    Rec.SetRange("POS Entry Post Failed", true);
                    CurrPage.Update(false);
                end;
            }
            action(ClearFilters)
            {
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Shows the full list of entries again.';

                trigger OnAction()
                begin
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ShowItemLedgerEntries_Promoted; ShowItemLedgerEntries) { }
                actionref(RunReconciliation_Promoted; RunReconciliation) { }
                actionref(ShowFailedOnly_Promoted; ShowFailedOnly) { }
            }
        }
    }

    var
        ShortfallStyle: Text;
        AdjustmentStyle: Text;
        PostFailedStyle: Text;

    trigger OnAfterGetRecord()
    begin
        ShortfallStyle := 'Attention';

        if Rec."Prevent Neg. Inv. Active" and not Rec."Adjustment Posted" then
            AdjustmentStyle := 'Unfavorable'
        else
            AdjustmentStyle := 'Favorable';

        if Rec."POS Entry Post Failed" then
            PostFailedStyle := 'Unfavorable'
        else
            PostFailedStyle := 'Standard';
    end;
}
