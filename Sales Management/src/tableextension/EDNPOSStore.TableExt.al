namespace EDN.SalesManagement;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Setup;
using System.Security.AccessControl;


tableextension 50104 "EDN POS Store" extends "NPR POS Store"
{
    fields
    {
        field(50100; "EDN Block Mode"; Enum "EDN Block Mode")
        {
            Caption = 'Block Sale Below Stock';
            DataClassification = CustomerContent;
        }
        field(50102; "EDN Include Open POS Sales"; Boolean)
        {
            Caption = 'Include Open Sales';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(50103; "EDN Override Permission"; Code[20])
        {
            Caption = 'Override Permission Set';
            DataClassification = CustomerContent;
            TableRelation = "Aggregate Permission Set"."Role ID";
            ValidateTableRelation = false;
        }
        field(50104; "EDN Override Action"; Enum "EDN Override Action")
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
        field(50105; "EDN Adjustment Jnl. Template"; Code[10])
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
        field(50106; "EDN Adjustment Jnl. Batch"; Code[10])
        {
            Caption = 'Adjustment Journal Batch';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Batch".Name
                where("Journal Template Name" = field("EDN Adjustment Jnl. Template"));
        }
        field(50107; "EDN Adjustment Reason Code"; Code[10])
        {
            Caption = 'Adjustment Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(50108; "EDN Incl. Pending POS Entries"; Boolean)
        {
            Caption = 'Include Unposted POS Entries';
            DataClassification = CustomerContent;
            InitValue = true;
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
