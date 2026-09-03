namespace EDN.SalesManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 50100 "EDN Neg. Sale Override Log"
{
    Caption = 'Negative Sale Override Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "EDN Neg. Sale Override Log";
    LookupPageId = "EDN Neg. Sale Override Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Register No."; Code[10])
        {
            Caption = 'POS Unit No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "NPR POS Unit";
        }
        field(11; "Sales Ticket No."; Code[20])
        {
            Caption = 'Sales Ticket No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "Sale Date"; Date)
        {
            Caption = 'Sale Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "Sale Line No."; Integer)
        {
            Caption = 'Sale Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; "POS Store Code"; Code[10])
        {
            Caption = 'POS Store Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "NPR POS Store";
        }
        field(15; "Sale Line SystemId"; Guid)
        {
            Caption = 'Sale Line SystemId';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Item;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Location;
        }
        field(25; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(23; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Line Unit of Measure';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(30; "Available Qty (Base)"; Decimal)
        {
            Caption = 'Available Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(31; "Requested Qty (Base)"; Decimal)
        {
            Caption = 'Requested Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(32; "Shortfall Qty (Base)"; Decimal)
        {
            Caption = 'Shortfall Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(33; "Reserved Qty (Base)"; Decimal)
        {
            Caption = 'Of Which Reserved';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            ObsoleteReason = 'Order reservations are no longer part of the POS availability calculation.';
            ObsoleteState = Pending;
            ObsoleteTag = '1.0.5.0';
        }
        field(34; "Pending POS Qty (Base)"; Decimal)
        {
            Caption = 'Of Which Unposted POS Entries';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(40; "Override Reason"; Enum "EDN Override Reason")
        {
            Caption = 'Override Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "Override Action Taken"; Enum "EDN Override Action")
        {
            Caption = 'Action Taken';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(51; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60; "Prevent Neg. Inv. Active"; Boolean)
        {
            Caption = 'Prevent Neg. Inventory Active';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(61; "Adjustment Posted"; Boolean)
        {
            Caption = 'Adjustment Posted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(62; "Adjustment Document No."; Code[20])
        {
            Caption = 'Adjustment Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(63; "Adjustment Error"; Text[250])
        {
            Caption = 'Adjustment Error';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70; "POS Entry No."; Integer)
        {
            Caption = 'POS Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "NPR POS Entry";
        }
        field(71; "POS Entry Post Failed"; Boolean)
        {
            Caption = 'POS Entry Posting Failed';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ItemLocation; "Item No.", "Location Code", "Bin Code", "Created At")
        {
            SumIndexFields = "Shortfall Qty (Base)";
        }
        key(Sale; "Register No.", "Sales Ticket No.")
        {
        }
        key(StoreDate; "POS Store Code", "Created At")
        {
            SumIndexFields = "Shortfall Qty (Base)";
        }
        key(Failed; "POS Entry Post Failed", "Created At")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Item No.", "Shortfall Qty (Base)", "User ID")
        {
        }
    }

    internal procedure InitFromSaleLine(SaleLinePOS: Record "NPR POS Sale Line"; POSStoreCode: Code[10])
    begin
        Init();
        "Register No." := SaleLinePOS."Register No.";
        "Sales Ticket No." := SaleLinePOS."Sales Ticket No.";
        "Sale Date" := SaleLinePOS.Date;
        "Sale Line No." := SaleLinePOS."Line No.";
        "Sale Line SystemId" := SaleLinePOS.SystemId;
        "POS Store Code" := POSStoreCode;
        "Item No." := SaleLinePOS."No.";
        "Variant Code" := SaleLinePOS."Variant Code";
        "Location Code" := SaleLinePOS."Location Code";
        "Bin Code" := SaleLinePOS."Bin Code";
        "Item Description" := SaleLinePOS.Description;
        "Unit of Measure Code" := SaleLinePOS."Unit of Measure Code";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Created At" := CurrentDateTime();
    end;
}
