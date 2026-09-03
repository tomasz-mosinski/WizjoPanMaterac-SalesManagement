namespace EDN.SalesManagement;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Setup;
using System.Security.AccessControl;


tableextension 50104 "EDN POS Store Ext" extends "NPR POS Store"
{
    fields
    {
        field(60100; "EDN Block Mode"; Enum "EDN Block Mode")
        {
            Caption = 'Block Sale Below Stock';
            DataClassification = CustomerContent;
        }
        field(60101; "EDN Include Reservations"; Boolean)
        {
            Caption = 'Include Reservations';
            DataClassification = CustomerContent;
            InitValue = true;
            ObsoleteReason = 'POS availability is now driven by the "Allowed for POS Sale" flag on bins; order reservations are no longer subtracted.';
            ObsoleteState = Pending;
            ObsoleteTag = '1.0.5.0';
        }
        field(60102; "EDN Include Open POS Sales"; Boolean)
        {
            Caption = 'Include Open Sales';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(60103; "EDN Override Permission"; Code[20])
        {
            Caption = 'Override Permission Set';
            DataClassification = CustomerContent;
            TableRelation = "Aggregate Permission Set"."Role ID";
            ValidateTableRelation = false;
        }
        field(60104; "EDN Override Action"; Enum "EDN Override Action")
        {
            Caption = 'Action When Sale Is Allowed';
            DataClassification = CustomerContent;
            InitValue = "Log Only";

            trigger OnValidate()
            begin
                if "EDN Override Action" <> "EDN Override Action"::"Auto Positive Adjustment" then begin
                    "EDN Adjustment Jnl. Template" := '';
                    "EDN Adjustment Jnl. Batch" := '';
                end;
            end;
        }
        field(60105; "EDN Adjustment Jnl. Template"; Code[10])
        {
            Caption = 'Adjustment Journal Template';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Template" where(Type = const(Item));

            trigger OnValidate()
            begin
                if "EDN Adjustment Jnl. Template" = '' then
                    "EDN Adjustment Jnl. Batch" := '';
            end;
        }
        field(60106; "EDN Adjustment Jnl. Batch"; Code[10])
        {
            Caption = 'Adjustment Journal Batch';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Batch".Name
                where("Journal Template Name" = field("EDN Adjustment Jnl. Template"));
        }
        field(60107; "EDN Adjustment Reason Code"; Code[10])
        {
            Caption = 'Adjustment Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(60108; "EDN Incl. Pending POS Entries"; Boolean)
        {
            Caption = 'Include Unposted POS Entries';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(60109; "EDN Block When No Bin"; Boolean)
        {
            Caption = 'Block Sale When No Bin';
            DataClassification = CustomerContent;
            InitValue = false;
            ObsoleteReason = 'An empty bin on a bin mandatory location now always blocks the sale; there is no location-level fallback.';
            ObsoleteState = Pending;
            ObsoleteTag = '1.0.5.0';
        }
    }

    internal procedure IsConfigurationRisky(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if not InventorySetup."Prevent Negative Inventory" then
            exit(false);

        if "EDN Block Mode" = "EDN Block Mode"::Disabled then
            exit(true);

        if "EDN Override Action" = "EDN Override Action"::"Auto Positive Adjustment" then
            exit(false);

        if "EDN Block Mode" = "EDN Block Mode"::Warning then
            exit(true);

        exit("EDN Override Permission" <> '');
    end;
}
