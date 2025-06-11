# Manual DataStore Setup Guide

## Why Manual Setup is Needed

The **🔍 Discover** button only works when the plugin runs on a **server** (in a published game). In Studio, the plugin runs on the **client side**, where DataStore access is not available.

## 🎯 Quick Setup for Your Game

Based on your screenshot, here's how to add your real DataStore names:

### Step 1: Run This Script

Copy and paste this script into Studio's **Command Bar** and press Enter:

```lua
-- Add your real DataStore names to the plugin
local DataStoreManager = require(game.ServerScriptService.DataStoreManagerPro.core.data.DataStoreManager)
local dsManager = DataStoreManager.new()

-- Your actual DataStore names (from your screenshot)
local yourDataStores = {
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

print("🎯 Adding your real DataStore names...")
dsManager:addKnownDataStores(yourDataStores)
print("✅ Done! Refresh the plugin to see your DataStores.")
```

### Step 2: Refresh the Plugin

After running the script:

1. **Close and reopen** the DataStore Manager Pro plugin
2. **Your real DataStores** should now appear in the list
3. **Click on them** to see your actual data

## 🔧 For Other Games

If you have different DataStore names, modify the `yourDataStores` table:

```lua
local yourDataStores = {
    "YourDataStoreName1",
    "YourDataStoreName2",
    "YourDataStoreName3"
    -- Add your actual DataStore names here
}
```

## 🎮 In Published Games

When your game is published and running on Roblox servers:

- The **🔍 Discover** button will work automatically
- It will find your real DataStores without manual setup
- The plugin will cache the discovered names for future use

## ⚠️ Important Notes

1. **Studio Limitation**: DataStore discovery only works in published games, not in Studio
2. **Server vs Client**: The plugin runs on client in Studio, but DataStores need server access
3. **Manual Setup**: Use the script above to manually register your DataStore names in Studio
4. **Persistent Cache**: Once added, your DataStore names will be remembered across Studio sessions

## 🔍 Troubleshooting

### "DataStore not found" errors

- This is normal in Studio - DataStores may not be accessible
- Use the manual setup script above
- Test in a published game for full functionality

### Plugin shows fallback data

- Run the manual setup script
- Clear cache using the **🧹 Cache** button
- Refresh the plugin

### Discovery button shows warning

- This is expected in Studio
- Use manual setup instead
- Discovery will work in published games

### Too many API calls / Throttling in published game

- Click the **🚫 Auto** button to disable automatic discovery
- This prevents the plugin from making excessive API calls
- Use manual setup instead for better performance
