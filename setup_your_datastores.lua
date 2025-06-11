-- Quick Setup Script for Your Real DataStores
-- Copy this entire script and paste it into Studio's Command Bar, then press Enter

print("🎯 Setting up your real DataStore names...")

-- Get the DataStore Manager
local success, dataStoreManager = pcall(function()
    return require(game.ServerScriptService.DataStoreManagerPro.src.core.data.DataStoreManager)
end)

if not success then
    print("❌ Could not find DataStore Manager. Make sure the plugin is installed correctly.")
    return
end

-- Create manager instance
local dsManager = dataStoreManager.initialize()

-- Your actual DataStore names (from your screenshot)
local yourRealDataStores = {
    "PlayerCurrency",
    "PlayerData", 
    "PlayerData_v1",
    "PlayerStats",
    "TimedBuilding",
    "UniqueItemIds", 
    "WorldData",
    "v2_PlayerCurrency",
    "v2_WorldData",
    "v3_PlayerCurrency", 
    "v3_WorldData",
    "v4_PlayerCurrency",
    "v4_PlayerData",
    "v4_WorldData"
}

-- Add them to the plugin
if dsManager and dsManager.addKnownDataStores then
    local addSuccess, addError = pcall(function()
        dsManager:addKnownDataStores(yourRealDataStores)
    end)
    
    if addSuccess then
        print("✅ Successfully added " .. #yourRealDataStores .. " real DataStore names!")
        print("📋 Added DataStores:")
        for i, name in ipairs(yourRealDataStores) do
            print("  " .. i .. ". " .. name)
        end
        print("")
        print("🔄 Now close and reopen the DataStore Manager Pro plugin to see your real DataStores!")
    else
        print("❌ Failed to add DataStores: " .. tostring(addError))
    end
else
    print("❌ DataStore Manager methods not available. Plugin may not be loaded correctly.")
end 