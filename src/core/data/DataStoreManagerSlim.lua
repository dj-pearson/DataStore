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
        return
    end
    
    -- Load cached DataStore names
    local cachedNames = self.pluginCache:get("datastore_names")
    if cachedNames then
        debugLog("📋 Returning cached DataStore names from persistent storage")
        debugLog("🎯 Using cached real DataStore names from plugin DataStore")
        return cachedNames
    end
    
    return {}
end

-- Save data to plugin cache
function DataStoreManagerSlim:saveToPluginCache(key, data)
    if self.pluginCache then
        self.pluginCache:set(key, data)
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
        -- Cache the result
        local metadata = {
            fetchTime = tick(),
            source = "datastore"
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
    
    -- For now, return empty list as DataStore discovery requires special permissions
    -- In a real implementation, this would use DataStore enumeration APIs
    local discoveredNames = {}
    
    -- Save to plugin cache
    self:saveToPluginCache("datastore_names", discoveredNames)
    
    return discoveredNames
end

-- Get keys from DataStore (limited functionality)
function DataStoreManagerSlim:getKeys(datastoreName, scope, limit)
    -- Check cache first
    local cachedKeys = self.cacheManager:getCachedKeyList(datastoreName)
    if cachedKeys then
        return cachedKeys
    end
    
    -- For now, return empty list as key enumeration requires special APIs
    -- In a real implementation, this would use DataStore key enumeration
    local keys = {}
    
    -- Cache the result
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
        self.pluginCache:remove("datastore_names")
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

-- Cleanup method
function DataStoreManagerSlim:cleanup()
    debugLog("Cleaning up DataStore Manager")
    
    -- Get final stats
    local stats = self:getStats()
    debugLog(string.format(
        "Final stats - Operations: %d, Success rate: %.1f%%, Avg latency: %.2fms",
        stats.operations.total,
        stats.operations.successRate,
        stats.operations.averageLatency * 1000
    ))
    
    -- Clear all caches
    self.cacheManager:clearAllCaches()
    
    debugLog("DataStore Manager cleanup complete")
end

return DataStoreManagerSlim 