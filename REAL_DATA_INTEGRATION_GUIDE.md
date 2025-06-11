# Real DataStore Integration Guide

## Overview

The DataStore Manager Pro plugin now includes smart caching and auto-detection features to work seamlessly with your real DataStore data while minimizing API throttling.

## 🎯 DataStore Discovery System

### Method 1: Automatic Discovery (Recommended)

Click the **🔍 Discover Real** button in the plugin to automatically find your DataStores:

1. **Open the plugin** in your game (not in Studio with no game)
2. **Click "🔍 Discover Real"** button in the Data Explorer
3. **Wait for discovery** - it will test common DataStore name patterns
4. **Your real DataStores** will appear in the list automatically

**Discovery finds DataStores like:**

- PlayerData, PlayerData_v1, PlayerData_v2, etc.
- PlayerCurrency, PlayerStats, PlayerInventory
- TimedBuilding, WorldData, UniqueItemIds
- And many more common patterns

### Method 2: Auto-Detection During Use

The plugin also automatically detects DataStores when:

- Real data is successfully retrieved from a DataStore
- Real keys are successfully listed from a DataStore

**How it works:**

1. When you access real data through the plugin, it automatically registers the DataStore as "real"
2. Real DataStores are prioritized and cached persistently
3. Your real DataStores will appear at the top of the list

## 🔧 Manual Registration (If Needed)

If auto-detection doesn't work or you want to pre-register DataStores:

### Method 3: Manual Setup (Studio)

**For Studio use**, see the detailed guide: `MANUAL_DATASTORE_SETUP.md`

Quick setup for your game:

1. **Copy the script** from the manual setup guide
2. **Edit the DataStore names** to match your game
3. **Run in Command Bar** in Studio
4. **Refresh the plugin** to see your DataStores

### Method 4: Direct API Registration

```lua
local DataStoreManager = require(game.ServerScriptService.DataStoreManagerPro.core.data.DataStoreManager)
local dsManager = DataStoreManager.new()

-- Add multiple DataStores at once
dsManager:addKnownDataStores({
    "PlayerCurrency",
    "PlayerData_v1",
    "TimedBuilding",
    "UniqueItemIds"
})

-- Or add one at a time
dsManager:registerRealDataStore("YourDataStoreName")
```

## 🚫 Throttling Solutions

### Automatic Throttling Protection

- Global 10-second cooldown between API calls
- Smart caching prevents repeated requests
- Persistent cache survives Studio restarts

### Manual Throttle Clearing

If you get stuck in throttling, use the refresh button in the Data Explorer or run:

```lua
local dsManager = DataStoreManager.new()
dsManager:clearAllThrottling()
```

## 💾 Smart Caching System

### Cache Layers

1. **Memory Cache**: Fast access during current session
2. **Persistent Cache**: Survives Studio restarts using plugin's own DataStore
3. **User Isolation**: Each developer's cache is separate

### Cache Expiry Times

- DataStore Names: 5 minutes
- Key Lists: 3 minutes
- Data Content: 2 minutes

### Key Length Protection

- Automatically handles Roblox's 50-character key limit
- Uses smart hashing for long cache keys
- Maintains backward compatibility

## 🔍 Troubleshooting

### "Key name exceeds 50 character limit"

✅ **Fixed**: The plugin now automatically handles long keys with smart hashing.

### Data Appears Once Then Disappears

✅ **Fixed**: Real data is now cached persistently and auto-registered.

### Enterprise Tab Errors

✅ **Fixed**: Logger format errors have been resolved.

### Still Getting Throttled Data

1. Wait 10+ seconds between operations
2. Use the refresh button instead of clicking rapidly
3. Check if background processes are making API calls
4. Clear throttling manually if needed

## 🎉 Best Practices

1. **Let Auto-Detection Work**: Just use the plugin normally, it will detect real DataStores
2. **Wait Between Operations**: Give the API time to respond
3. **Use Cached Data**: The plugin prioritizes cached real data
4. **Monitor Console**: Check for throttling messages and errors
5. **Refresh Wisely**: Use the refresh button sparingly

## 📊 Cache Statistics

You can check cache performance:

```lua
local dsManager = DataStoreManager.new()
local stats = dsManager.pluginCache:getCacheStats()
print("Cache entries:", stats.memoryEntries)
print("Cache size:", stats.estimatedSize, "bytes")
```

## 🧹 Cache Management

Clear all caches if needed:

```lua
local dsManager = DataStoreManager.new()
dsManager:clearAllCaches()
```

---

**Note**: The plugin uses its own DataStore (`DataStoreManagerPro_Cache`) to store cache data. This is isolated per user and won't interfere with your game's DataStores.

### ✅ **Enhanced Debug Output**

The console will now show detailed service information:

```
=== SERVICE DEBUG ===
Service: core.data.DataStoreManager = table
DataStore Manager methods: initialize, getDataStoreNames, getDataStoreKeys, getDataInfo
=== END SERVICE DEBUG ===
✅ DataStore Manager service is available for real data access!
```

## Support

If you encounter issues with real data integration:

1. Check console logs for detailed error messages
2. Look for the debugging messages above
3. Verify Studio/game DataStore settings
4. Ensure proper service initialization order
5. Try the manual tests provided in the debugging section
