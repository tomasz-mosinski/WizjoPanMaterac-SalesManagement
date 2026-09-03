namespace EDN.SalesManagement;

using Microsoft.Inventory.Setup;

codeunit 50102 "EDN Install"
{
    Access = Internal;
    Permissions = tabledata "NPR POS Store" = rm,
                  tabledata "Inventory Setup" = rm;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);

        if AppInfo.DataVersion().Major() > 0 then
            exit;

        InitializePOSStoreDefaults();
        EnableTableEventHook();
    end;


    local procedure EnableTableEventHook()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if not InventorySetup.Get() then
            exit;
        InventorySetup."EDN Use Fallback Hook" := true;
        InventorySetup.Modify(false);
    end;

    local procedure InitializePOSStoreDefaults()
    var
        POSStore: Record "NPR POS Store";
    begin
        if POSStore.FindSet(true) then
            repeat
                POSStore."EDN Block Mode" := POSStore."EDN Block Mode"::Disabled;
                POSStore."EDN Incl. Pending POS Entries" := true;
                POSStore."EDN Include Open POS Sales" := true;
                POSStore."EDN Override Action" := POSStore."EDN Override Action"::"Log Only";
                POSStore.Modify(false);
            until POSStore.Next() = 0;
    end;
}
