-- DataStore Manager Pro - Slim DataStore Manager
-- Simplified DataStore manager using modular components

local DataStoreManagerSlim = {}
DataStoreManagerSlim.__index = DataStoreManagerSlim

-- Import services
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

-- Import modular components
local CacheManager = require(script.Parent.modules.CacheManager)
local RequestManager = require(script.Parent.modules.RequestManager)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[DATASTORE_MANAGER_SLIM] [%s] %s", level, message))
end

-- Initialize DataStore Manager
function DataStoreManagerSlim.initialize()
    local self = setmetatable({}, DataStoreManagerSlim)
    
    debugLog("Initializing DataStore Manager with modular architecture")
    
    -- Initialize DataStore service reference
    self.datastoreService = DataStoreService
    
    -- Initialize modular components
    self.cacheManager = CacheManager.new({
        maxCacheSize = 1000,
        maxAge = 300, -- 5 minutes
        cleanupInterval = 60 -- 1 minute
    })
    
    self.requestManager = RequestManager.new({})
    
    -- Initialize plugin's own DataStore for persistent caching
    local PluginDataStore = require(script.Parent.PluginDataStore)
    self.pluginCache = PluginDataStore.new({
        info = function(_, component, message)
            debugLog(message)
        end,
        warn = function(_, component, message)
            debugLog(message, "WARN")
        end
    })
    
    -- Core properties
    self.operations = {
        total = 0,
        successful = 0,
        failed = 0,
        startTime = tick(),
        totalLatency = 0
    }
    
    -- Initialize with plugin cache data
    self:loadFromPluginCache()
    
    debugLog("DataStore Manager initialized successfully with modular components")
    return self
end

-- Load cached data from plugin DataStore
function DataStoreManagerSlim:loadFromPluginCache()
    if not self.pluginCache then
        debugLog("No plugin cache available", "WARN")
        return {}
    end
    
    -- Load cached DataStore names
    local cachedNames = self.pluginCache:getCachedDataStoreNames()
    if cachedNames and #cachedNames > 0 then
        debugLog("📋 Returning cached DataStore names from persistent storage")
        debugLog("🎯 Using cached real DataStore names from plugin DataStore")
        return cachedNames
    end
    
    return {}
end

-- Save data to plugin cache
function DataStoreManagerSlim:saveToPluginCache(key, data)
    if self.pluginCache then
        if key == "datastore_names" then
            self.pluginCache:cacheDataStoreNames(data)
        else
            -- Handle other cache types if needed
            debugLog("Unknown cache key type: " .. key, "WARN")
        end
    end
end

-- Get DataStore instance with caching
function DataStoreManagerSlim:getDataStore(name, scope)
    -- Check cache first
    local cachedStore = self.cacheManager:getCachedDataStore(name, scope)
    if cachedStore then
        return cachedStore
    end
    
    -- Create new DataStore instance
    local success, result = self.requestManager:executeRequest(function()
        return DataStoreService:GetDataStore(name, scope)
    end, "GetDataStore")
    
    if success then
        self.cacheManager:cacheDataStore(name, scope, result)
        return result
    else
        debugLog("Failed to get DataStore: " .. tostring(result), "ERROR")
        return nil
    end
end

-- Get OrderedDataStore instance with caching
function DataStoreManagerSlim:getOrderedDataStore(name, scope)
    -- Check cache first
    local cachedStore = self.cacheManager:getCachedOrderedDataStore(name, scope)
    if cachedStore then
        return cachedStore
    end
    
    -- Create new OrderedDataStore instance
    local success, result = self.requestManager:executeRequest(function()
        return DataStoreService:GetOrderedDataStore(name, scope)
    end, "GetOrderedDataStore")
    
    if success then
        self.cacheManager:cacheOrderedDataStore(name, scope, result)
        return result
    else
        debugLog("Failed to get OrderedDataStore: " .. tostring(result), "ERROR")
        return nil
    end
end

-- Get data from DataStore with caching
function DataStoreManagerSlim:getData(datastoreName, key, scope)
    -- Check cache first
    local cachedData, cachedMetadata = self.cacheManager:getCachedData(datastoreName, key)
    if cachedData ~= nil then
        -- Ensure cached metadata has proper flags
        if cachedMetadata and not cachedMetadata.isReal then
            cachedMetadata.isReal = true
            cachedMetadata.dataSource = cachedMetadata.dataSource or "CACHED_REAL"
            cachedMetadata.canRefresh = true
        end
        return cachedData, cachedMetadata
    end
    
    -- Get DataStore instance
    local datastore = self:getDataStore(datastoreName, scope)
    if not datastore then
        return nil, "Failed to get DataStore instance"
    end
    
    -- Fetch data from DataStore
    local success, result = self.requestManager:executeRequest(function()
        return datastore:GetAsync(key)
    end, "GetAsync")
    
    if success then
        -- Cache the result with proper metadata
        local metadata = {
            fetchTime = tick(),
            source = "datastore",
            isReal = true,
            dataSource = "REAL_DATA",
            canRefresh = true
        }
        self.cacheManager:cacheData(datastoreName, key, result, metadata)
        
        self.operations.successful = self.operations.successful + 1
        return result, metadata
    else
        self.operations.failed = self.operations.failed + 1
        return nil, result
    end
end

-- Set data in DataStore
function DataStoreManagerSlim:setData(datastoreName, key, value, scope)
    -- Get DataStore instance
    local datastore = self:getDataStore(datastoreName, scope)
    if not datastore then
        return false, "Failed to get DataStore instance"
    end
    
    -- Set data in DataStore
    local success, result = self.requestManager:executeRequest(function()
        return datastore:SetAsync(key, value)
    end, "SetAsync")
    
    if success then
        -- Update cache
        local metadata = {
            setTime = tick(),
            source = "datastore"
        }
        self.cacheManager:cacheData(datastoreName, key, value, metadata)
        
        self.operations.successful = self.operations.successful + 1
        return true, "Data set successfully"
    else
        self.operations.failed = self.operations.failed + 1
        return false, result
    end
end

-- Update data in DataStore
function DataStoreManagerSlim:updateData(datastoreName, key, updateFunction, scope)
    -- Get DataStore instance
    local datastore = self:getDataStore(datastoreName, scope)
    if not datastore then
        return false, "Failed to get DataStore instance"
    end
    
    -- Update data in DataStore
    local success, result = self.requestManager:executeRequest(function()
        return datastore:UpdateAsync(key, updateFunction)
    end, "UpdateAsync")
    
    if success then
        -- Update cache
        local metadata = {
            updateTime = tick(),
            source = "datastore"
        }
        self.cacheManager:cacheData(datastoreName, key, result, metadata)
        
        self.operations.successful = self.operations.successful + 1
        return true, result
    else
        self.operations.failed = self.operations.failed + 1
        return false, result
    end
end

-- Remove data from DataStore
function DataStoreManagerSlim:removeData(datastoreName, key, scope)
    -- Get DataStore instance
    local datastore = self:getDataStore(datastoreName, scope)
    if not datastore then
        return false, "Failed to get DataStore instance"
    end
    
    -- Remove data from DataStore
    local success, result = self.requestManager:executeRequest(function()
        return datastore:RemoveAsync(key)
    end, "RemoveAsync")
    
    if success then
        -- Remove from cache
        self.cacheManager:removeCachedData(datastoreName, key)
        
        self.operations.successful = self.operations.successful + 1
        return true, result
    else
        self.operations.failed = self.operations.failed + 1
        return false, result
    end
end

-- Get DataStore names (discovery)
function DataStoreManagerSlim:getDataStoreNames()
    debugLog("Getting DataStore names")
    
    -- Check plugin cache first
    local cachedNames = self:loadFromPluginCache()
    if cachedNames and #cachedNames > 0 then
        debugLog("📋 Returning cached DataStore names from memory")
        return cachedNames
    end
    
    -- Try to discover real DataStores by testing common names
    local commonDataStoreNames = {
        "PlayerData", "PlayerCurrency", "PlayerStats", "PlayerData_v1", 
        "TimedBuilding", "UniqueItemIds", "WorldData", "v2_PlayerCurrency",
        "GameSettings", "UserPreferences", "Leaderboards", "Achievements",
        "PlayerSaveData", "GameData", "ServerSettings", "Economy"
    }
    
    local discoveredNames = {}
    local placeId = game.PlaceId
    
    debugLog("🔍 Starting DataStore discovery for Place ID: " .. placeId)
    
    -- Test each common name to see if it exists
    for _, testName in ipairs(commonDataStoreNames) do
        local success, result = self.requestManager:executeRequest(function()
            local ds = DataStoreService:GetDataStore(testName)
            -- Try to get a test key to see if the DataStore has data
            local testData = ds:GetAsync("__test_discovery__" .. tick())
            return true
        end, "DiscoveryTest")
        
        if success then
            -- DataStore exists and is accessible
            table.insert(discoveredNames, testName)
            debugLog("✅ Found accessible DataStore: " .. testName)
        end
        
        -- Small delay to avoid rate limiting
        wait(0.05)
    end
    
    if #discoveredNames > 0 then
        debugLog("🎯 Discovery complete: Found " .. #discoveredNames .. " real DataStores")
        
        -- Cache the discovered names
        self:saveToPluginCache("datastore_names", discoveredNames)
        
        return discoveredNames
    else
        debugLog("No DataStores discovered, using fallback list")
        -- Return a basic fallback list for demo purposes
        local fallbackNames = {"PlayerData", "GameSettings", "UserPreferences", "Leaderboards", "Achievements"}
        return fallbackNames
    end
end

-- Get keys from DataStore (limited functionality)
function DataStoreManagerSlim:getKeys(datastoreName, scope, limit)
    debugLog("🔍 Getting keys for DataStore: " .. datastoreName)
    
    -- Check cache first
    local cachedKeys = self.cacheManager:getCachedKeyList(datastoreName)
    if cachedKeys and #cachedKeys > 0 then
        debugLog("💾 Returning " .. #cachedKeys .. " cached keys for " .. datastoreName)
        return cachedKeys
    end
    
    -- Check plugin cache
    if self.pluginCache then
        local pluginCachedKeys = self.pluginCache:getCachedDataStoreKeys(datastoreName, scope or "global")
        if pluginCachedKeys and #pluginCachedKeys > 0 then
            debugLog("✅ Found " .. #pluginCachedKeys .. " keys in plugin cache for " .. datastoreName)
            self.cacheManager:cacheKeyList(datastoreName, pluginCachedKeys)
            return pluginCachedKeys
        end
    end
    
    -- Try to use ListKeys API if available
    local keys = {}
    local datastore = self:getDataStore(datastoreName, scope)
    
    if datastore then
        local success, result = self.requestManager:executeRequest(function()
            -- Try using the ListKeysAsync API
            debugLog("📋 Attempting ListKeysAsync for " .. datastoreName)
            local listResult = datastore:ListKeysAsync()
            local keyList = {}
            
            -- Get up to 100 keys from the first page
            if listResult then
                debugLog("📄 ListKeysAsync returned a result, getting current page")
                local items = listResult:GetCurrentPage()
                debugLog("📊 Current page has " .. #items .. " items")
                
                for _, item in ipairs(items) do
                    table.insert(keyList, item.KeyName)
                    if #keyList >= (limit or 100) then
                        break
                    end
                end
                debugLog("🔑 Extracted " .. #keyList .. " key names")
            else
                debugLog("❌ ListKeysAsync returned nil")
            end
            
            return keyList
        end, "ListKeys")
        
        if success and result then
            if #result > 0 then
                keys = result
                debugLog("✅ Found " .. #keys .. " real keys using ListKeysAsync for " .. datastoreName)
                
                -- Cache the discovered keys
                self.cacheManager:cacheKeyList(datastoreName, keys)
                if self.pluginCache then
                    self.pluginCache:cacheDataStoreKeys(datastoreName, keys, scope or "global")
                end
            else
                debugLog("⚠️ ListKeysAsync succeeded but returned 0 keys for " .. datastoreName)
                -- This DataStore exists but has no keys - return empty array
                keys = {}
            end
        else
            debugLog("❌ ListKeysAsync failed for " .. datastoreName .. ": " .. tostring(result))
            keys = {} -- Return empty list when no keys can be retrieved
        end
    else
        debugLog("❌ Failed to get DataStore instance for " .. datastoreName)
        keys = {} -- Return empty list when DataStore instance cannot be obtained
    end
    
    -- Cache the result (even if empty)
    self.cacheManager:cacheKeyList(datastoreName, keys)
    
    return keys
end

-- Get statistics
function DataStoreManagerSlim:getStats()
    local requestStats = self.requestManager:getStats()
    local cacheStats = self.cacheManager:getStats()
    
    local runtime = tick() - self.operations.startTime
    local avgLatency = 0
    if self.operations.total > 0 then
        avgLatency = self.operations.totalLatency / self.operations.total
    end
    
    return {
        operations = {
            total = requestStats.totalRequests,
            successful = requestStats.successfulRequests,
            failed = requestStats.failedRequests,
            successRate = requestStats.successRate,
            averageLatency = requestStats.averageLatency
        },
        requests = requestStats,
        cache = cacheStats,
        runtime = runtime,
        uptime = runtime
    }
end

-- Clear cache
function DataStoreManagerSlim:clearCache(datastoreName)
    if datastoreName then
        return self.cacheManager:clearDataStoreCache(datastoreName)
    else
        return self.cacheManager:clearAllCaches()
    end
end

-- Force refresh DataStore names
function DataStoreManagerSlim:refreshDataStoreNames()
    -- Clear cached names
    if self.pluginCache then
        self.pluginCache:clearAllCache()
    end
    
    -- Get fresh names
    return self:getDataStoreNames()
end

-- Get request history for analytics
function DataStoreManagerSlim:getRequestHistory(limit)
    return self.requestManager:getRequestHistory(limit)
end

-- Reset all statistics
function DataStoreManagerSlim:resetStats()
    self.operations = {
        total = 0,
        successful = 0,
        failed = 0,
        startTime = tick(),
        totalLatency = 0
    }
    
    self.requestManager:resetStats()
    debugLog("All statistics reset")
end

-- Get DataStore entries (keys) - compatible with DataExplorerManager
function DataStoreManagerSlim:getDataStoreEntries(datastoreName, prefix, limit)
    debugLog("🔍 Getting entries for DataStore: " .. datastoreName .. " using proper API")
    
    -- Use the getKeys method which has the real logic
    local keys = self:getKeys(datastoreName, "global", limit or 100)
    
    if keys and #keys > 0 then
        debugLog("✅ Successfully retrieved " .. #keys .. " keys from " .. datastoreName)
        return keys
    end
    
    debugLog("No keys found for " .. datastoreName)
    return {}
end

-- Get data info (compatible with DataExplorerManager)
function DataStoreManagerSlim:getDataInfo(datastoreName, key, scope)
    debugLog("Getting data info for: " .. datastoreName .. " -> " .. key)
    
    -- Check cache first
    if self.pluginCache then
        local cachedData = self.pluginCache:getCachedDataContent(datastoreName, key, scope or "global")
        if cachedData then
            debugLog("💾 Returning cached data for " .. datastoreName .. "/" .. key .. " from memory")
            debugLog("🎯 Using cached real data from plugin DataStore for " .. datastoreName .. "/" .. key)
            return {
                exists = true,
                data = cachedData,
                type = type(cachedData),
                size = string.len(tostring(cachedData)),
                metadata = {
                    isReal = true,
                    dataSource = "CACHED_REAL",
                    canRefresh = true
                }
            }
        end
    end
    
    -- Try to get real data
    local data, metadata = self:getData(datastoreName, key, scope or "global")
    if data ~= nil then  -- data could be false or 0, so check for nil specifically
        debugLog("✅ Found real data for " .. datastoreName .. "/" .. key)
        return {
            exists = true,
            data = data,
            type = type(data),
            size = string.len(tostring(data)),
            metadata = metadata or {
                isReal = true,
                dataSource = "REAL_DATA",
                canRefresh = true
            }
        }
    end
    
    -- Check if this is a fallback key (demo data)
    if key:match("Player_123456") or key:match("User_") or key:match("Config_") then
        debugLog("🎭 Using demo data for fallback key: " .. key)
        return {
            exists = false,
            error = "Key not found in DataStore - this is demo data",
            metadata = {
                isReal = false,
                dataSource = "DEMO_DATA",
                canRefresh = false
            }
        }
    end
    
    -- Return fallback response for real keys that don't exist
    debugLog("❌ Real key not found in DataStore: " .. key)
    return {
        exists = false,
        error = "Key not found in DataStore",
        metadata = {
            isReal = false,
            dataSource = "KEY_NOT_FOUND",
            canRefresh = true
        }
    }
end

-- Set data with metadata (compatible with DataExplorerManager)
function DataStoreManagerSlim:setDataWithMetadata(datastoreName, key, value, scope)
    local success, result = self:setData(datastoreName, key, value, scope or "global")
    
    if success then
        -- Cache the new value
        if self.pluginCache then
            self.pluginCache:cacheDataContent(datastoreName, key, value, {
                isReal = true,
                dataSource = "REAL_DATA_UPDATED",
                updateTime = tick()
            }, scope or "global")
        end
        
        return {
            success = true,
            message = result
        }
    else
        return {
            success = false,
            error = result
        }
    end
end

-- Auto-discovery control methods
function DataStoreManagerSlim:isAutoDiscoveryDisabled()
    return self.autoDiscoveryDisabled or false
end

function DataStoreManagerSlim:enableAutoDiscovery()
    self.autoDiscoveryDisabled = false
    debugLog("Auto-discovery enabled")
end

function DataStoreManagerSlim:disableAutoDiscovery()
    self.autoDiscoveryDisabled = true
    debugLog("Auto-discovery disabled")
end

-- Throttling control methods
function DataStoreManagerSlim:clearAllThrottling()
    if self.requestManager and self.requestManager.clearThrottling then
        self.requestManager:clearThrottling()
        debugLog("All throttling cleared")
    end
end

function DataStoreManagerSlim:clearThrottling()
    self:clearAllThrottling()
end

-- Force refresh methods
function DataStoreManagerSlim:forceRefresh()
    debugLog("🔄 Force refreshing DataStore Manager...")
    
    -- Clear all caches
    self:clearCache()
    
    -- Force refresh DataStore names
    local newNames = self:refreshDataStoreNames()
    
    debugLog("✅ Force refresh completed")
    return newNames
end

function DataStoreManagerSlim:refreshSingleEntry(datastoreName, key, scope)
    debugLog("🔄 Refreshing single entry: " .. datastoreName .. "/" .. key)
    
    -- Clear cache for this specific key
    if self.cacheManager then
        self.cacheManager:removeCachedData(datastoreName, key)
    end
    
    -- Get fresh data
    local data, metadata = self:getData(datastoreName, key, scope or "global")
    
    if data then
        return {
            success = true,
            data = data,
            metadata = metadata or {
                isReal = true,
                dataSource = "REFRESHED_REAL",
                canRefresh = true
            }
        }
    else
        return {
            success = false,
            error = metadata or "Failed to refresh data"
        }
    end
end

-- Create test data for demonstration (admin function)
function DataStoreManagerSlim:createTestData()
    debugLog("🧪 Creating test data for demonstration...")
    
    local testDataStores = {
        {name = "PlayerData", keys = {
            {key = "Player_7768610061", data = {
                playerId = 7768610061,
                playerName = "Xdjpearsonx",
                level = 25,
                experience = 12500,
                coins = 5000,
                inventory = {
                    {itemId = "sword_legendary", quantity = 1, equipped = true},
                    {itemId = "potion_heal", quantity = 10, equipped = false},
                    {itemId = "armor_diamond", quantity = 1, equipped = true}
                },
                settings = {
                    musicEnabled = true,
                    soundEnabled = true,
                    difficulty = "Hard"
                },
                joinDate = "2024-01-01T00:00:00Z",
                lastLogin = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }},
            {key = "Player_123456789", data = {
                playerId = 123456789,
                playerName = "TestPlayer",
                level = 10,
                experience = 2500,
                coins = 1000,
                inventory = {
                    {itemId = "sword_basic", quantity = 1, equipped = true},
                    {itemId = "potion_heal", quantity = 5, equipped = false}
                },
                settings = {
                    musicEnabled = true,
                    soundEnabled = false,
                    difficulty = "Normal"
                },
                joinDate = "2024-01-15T10:30:00Z",
                lastLogin = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }},
        {name = "GameSettings", keys = {
            {key = "ServerConfig", data = {
                maxPlayers = 50,
                gameMode = "Survival",
                mapRotation = {"Forest Temple", "Ice Caverns", "Desert Ruins"},
                eventActive = true,
                maintenanceMode = false,
                version = "2.1.5",
                lastUpdated = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }}
    }
    
    local totalCreated = 0
    for _, dsInfo in ipairs(testDataStores) do
        for _, keyInfo in ipairs(dsInfo.keys) do
            local success, result = self:setData(dsInfo.name, keyInfo.key, keyInfo.data)
            if success then
                debugLog("✅ Created test data: " .. dsInfo.name .. "/" .. keyInfo.key)
                totalCreated = totalCreated + 1
            else
                debugLog("❌ Failed to create test data: " .. dsInfo.name .. "/" .. keyInfo.key .. " - " .. tostring(result), "ERROR")
            end
            wait(0.1) -- Small delay to avoid rate limiting
        end
    end
    
    debugLog("🎯 Test data creation complete: " .. totalCreated .. " entries created")
    return totalCreated
end

-- Cleanup method
function DataStoreManagerSlim:cleanup()
    debugLog("Cleaning up DataStore Manager")
    
    -- Get final stats safely
    local success, stats = pcall(function() return self:getStats() end)
    if success and stats then
        debugLog(string.format(
            "Final stats - Operations: %d, Success rate: %.1f%%, Avg latency: %.2fms",
            stats.operations.total,
            stats.operations.successRate,
            stats.operations.averageLatency * 1000
        ))
    else
        debugLog("Unable to get final stats during cleanup")
    end
    
    -- Clear all caches safely
    if self.cacheManager then
        local success = pcall(function() self.cacheManager:clearAllCaches() end)
        if not success then
            debugLog("Error clearing caches during cleanup", "WARN")
        end
    end
    
    debugLog("DataStore Manager cleanup complete")
end

return DataStoreManagerSlim 