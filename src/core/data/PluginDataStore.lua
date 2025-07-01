-- PluginDataStore.lua
-- Comprehensive plugin data persistence system for DataStore Manager Pro
-- Handles caching, analytics, reports, settings, and historical data

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Import utilities
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)

local PluginDataStore = {}
PluginDataStore.__index = PluginDataStore

-- Plugin DataStore configurations
local PLUGIN_DATASTORES = {
    CACHE = "DataStoreManagerPro_Cache",
    ANALYTICS = "DataStoreManagerPro_Analytics", 
    REPORTS = "DataStoreManagerPro_Reports",
    SETTINGS = "DataStoreManagerPro_Settings",
    HISTORICAL = "DataStoreManagerPro_Historical"
}

local DATA_VERSION = "v2.0"

-- Get user-specific cache prefix to isolate data per developer
local function getUserCachePrefix()
    local StudioService = game:GetService("StudioService")
    
    local userId = "unknown"
    if StudioService then
        local success, result = pcall(function()
            return StudioService:GetUserId()
        end)
        if success and result then
            userId = tostring(result)
        end
    end
    
    return "u" .. userId:sub(-6) .. "_"
end

-- Create short hash for keys to avoid length limits
local function createShortKey(longKey, keyType)
    local hash = 0
    for i = 1, #longKey do
        hash = (hash * 31 + string.byte(longKey, i)) % 1000000
    end
    
    local typePrefix = keyType or "gen"
    return typePrefix .. "_" .. tostring(hash)
end

-- Data expiry configurations
local CACHE_EXPIRY = {
    -- Basic cache data
    DATASTORE_NAMES = 300,     -- 5 minutes
    KEYS_LIST = 180,           -- 3 minutes  
    DATA_CONTENT = 120,        -- 2 minutes
    METADATA = 60,             -- 1 minute
    
    -- Analytics data
    REAL_TIME_STATS = 30,      -- 30 seconds
    HOURLY_ANALYTICS = 3600,   -- 1 hour
    DAILY_ANALYTICS = 86400,   -- 24 hours
    
    -- Reports and settings
    REPORTS = 604800,          -- 7 days
    SETTINGS = 0,              -- Never expire (manual management)
    HISTORICAL = 2592000       -- 30 days
}

function PluginDataStore.new(logger)
    local self = setmetatable({}, PluginDataStore)
    
    self.logger = logger
    self.datastores = {}
    self.initialized = false
    self.memoryCache = {}
    self.userPrefix = getUserCachePrefix()
    
    -- Initialize analytics tracking
    self.analyticsState = {
        sessionStartTime = tick(),
        operations = {
            reads = 0,
            writes = 0,
            errors = 0,
            cacheHits = 0,
            cacheMisses = 0
        },
        realTimeData = {},
        performanceMetrics = {}
    }
    
    -- Initialize all DataStores
    self:initializeDataStores()
    
    return self
end

function PluginDataStore:initializeDataStores()
    local initialized = 0
    
    for storeName, storeKey in pairs(PLUGIN_DATASTORES) do
        local success, result = pcall(function()
            self.datastores[storeName] = DataStoreService:GetDataStore(storeKey)
            return true
        end)
        
        if success then
            initialized = initialized + 1
            if self.logger then
                self.logger:info("PLUGIN_DATASTORE", "✅ " .. storeName .. " DataStore initialized")
            end
        else
            if self.logger then
                self.logger:warn("PLUGIN_DATASTORE", "⚠️ Failed to initialize " .. storeName .. ": " .. tostring(result))
            end
        end
    end
    
    self.initialized = initialized > 0
    
    if self.logger then
        self.logger:info("PLUGIN_DATASTORE", "🎯 Plugin DataStore system initialized (" .. initialized .. "/" .. #PLUGIN_DATASTORES .. " stores)")
    end
end

-- ==================== CACHE MANAGEMENT ====================

-- Cache game DataStore names
function PluginDataStore:cacheDataStoreNames(names)
    if not self.initialized or not names then return false end
    
    local cacheData = {
        names = names,
        timestamp = tick(),
        version = DATA_VERSION,
        type = "datastore_names"
    }
    
    local key = createShortKey(self.userPrefix .. "datastore_names", "dsn")
    return self:saveToDataStore("CACHE", key, cacheData)
end

-- Cache DataStore keys
function PluginDataStore:cacheDataStoreKeys(datastoreName, keys, scope)
    if not self.initialized or not datastoreName or not keys then return false end
    
    local cacheData = {
        keys = keys,
        datastoreName = datastoreName,
        scope = scope,
        timestamp = tick(),
        version = DATA_VERSION,
        type = "keys_list"
    }
    
    local key = createShortKey(self.userPrefix .. "keys_" .. datastoreName .. "_" .. (scope or "global"), "key")
    return self:saveToDataStore("CACHE", key, cacheData)
end

-- Cache data content
function PluginDataStore:cacheDataContent(datastoreName, key, data, metadata, scope)
    if not self.initialized then
        self:initialize()
    end
    
    -- Get or create datastore
    if not self.datastores[datastoreName] then
        self.datastores[datastoreName] = DataStoreService:GetDataStore(datastoreName, scope)
    end
    
    -- Use UpdateAsync instead of SetAsync for compliance
    local success, result = pcall(function()
        return self.datastores[datastoreName]:UpdateAsync(key, function(currentValue)
            return data -- Return the new data value
        end)
    end)
    
    if success then
        -- Update local cache
        if not self.memoryCache[datastoreName] then
            self.memoryCache[datastoreName] = {}
        end
        
        self.memoryCache[datastoreName][key] = {
            data = data,
            metadata = metadata or {
                cached = true,
                timestamp = tick(),
                source = "plugin"
            },
            cached = true,
            timestamp = tick()
        }
        
        self.analyticsState.operations.writes = self.analyticsState.operations.writes + 1
        self.analyticsState.operations.cacheHits = self.analyticsState.operations.cacheHits + 1
        self.handlers.info(self, "CACHE", "Data cached for " .. datastoreName .. "/" .. key)
        return true, result
    else
        self.analyticsState.operations.errors = self.analyticsState.operations.errors + 1
        self.analyticsState.operations.cacheMisses = self.analyticsState.operations.cacheMisses + 1
        self.handlers.warn(self, "CACHE", "Failed to cache data: " .. tostring(result))
        return false, result
    end
end

-- Get cached DataStore names
function PluginDataStore:getCachedDataStoreNames()
    local key = createShortKey(self.userPrefix .. "datastore_names", "dsn")
    local data = self:getFromDataStore("CACHE", key)
    
    if data and self:isCacheValid(data, CACHE_EXPIRY.DATASTORE_NAMES) then
        self.analyticsState.operations.cacheHits = self.analyticsState.operations.cacheHits + 1
        return data.names, true
    end
    
    self.analyticsState.operations.cacheMisses = self.analyticsState.operations.cacheMisses + 1
    return nil, false
end

-- Get cached DataStore keys
function PluginDataStore:getCachedDataStoreKeys(datastoreName, scope)
    if not datastoreName then return nil, false end
    
    local key = createShortKey(self.userPrefix .. "keys_" .. datastoreName .. "_" .. (scope or "global"), "key")
    local data = self:getFromDataStore("CACHE", key)
    
    if data and self:isCacheValid(data, CACHE_EXPIRY.KEYS_LIST) then
        self.analyticsState.operations.cacheHits = self.analyticsState.operations.cacheHits + 1
        return data.keys, true
    end
    
    self.analyticsState.operations.cacheMisses = self.analyticsState.operations.cacheMisses + 1
    return nil, false
end

-- Get cached data content
function PluginDataStore:getCachedDataContent(datastoreName, key, scope)
    if not datastoreName or not key then return nil, nil, false end
    
    local cacheKey = createShortKey(self.userPrefix .. "data_" .. datastoreName .. "_" .. (scope or "global") .. "_" .. key, "dat")
    local data = self:getFromDataStore("CACHE", cacheKey)
    
    if data and self:isCacheValid(data, CACHE_EXPIRY.DATA_CONTENT) then
        self.analyticsState.operations.cacheHits = self.analyticsState.operations.cacheHits + 1
        return data.data, data.metadata, true
    end
    
    self.analyticsState.operations.cacheMisses = self.analyticsState.operations.cacheMisses + 1
    return nil, nil, false
end

-- ==================== ANALYTICS MANAGEMENT ====================

-- Save real-time analytics data
function PluginDataStore:saveRealTimeAnalytics(analysisData)
    if not self.initialized or not analysisData then return false end
    
    local timestamp = tick()
    local analyticsData = {
        timestamp = timestamp,
        sessionTime = timestamp - self.analyticsState.sessionStartTime,
        data = analysisData,
        operations = Utils.deepCopy(self.analyticsState.operations),
        version = DATA_VERSION,
        type = "realtime_analytics"
    }
    
    -- Store with timestamp-based key for chronological ordering
    local key = "rt_" .. tostring(math.floor(timestamp))
    local success = self:saveToDataStore("ANALYTICS", key, analyticsData)
    
    if success then
        -- Update real-time cache
        self.analyticsState.realTimeData[key] = analyticsData
        
        -- Clean old real-time data (keep last 100 entries)
        self:cleanOldRealTimeData()
        
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "📊 Real-time analytics saved")
        end
    end
    
    return success
end

-- Save hourly analytics summary
function PluginDataStore:saveHourlyAnalytics(summaryData)
    if not self.initialized or not summaryData then return false end
    
    local timestamp = tick()
    local hour = math.floor(timestamp / 3600) * 3600 -- Round to hour
    
    local analyticsData = {
        timestamp = timestamp,
        hour = hour,
        summary = summaryData,
        version = DATA_VERSION,
        type = "hourly_analytics"
    }
    
    local key = "hr_" .. tostring(hour)
    return self:saveToDataStore("ANALYTICS", key, analyticsData)
end

-- Save daily analytics summary
function PluginDataStore:saveDailyAnalytics(summaryData)
    if not self.initialized or not summaryData then return false end
    
    local timestamp = tick()
    local day = math.floor(timestamp / 86400) * 86400 -- Round to day
    
    local analyticsData = {
        timestamp = timestamp,
        day = day,
        summary = summaryData,
        version = DATA_VERSION,
        type = "daily_analytics"
    }
    
    local key = "dy_" .. tostring(day)
    return self:saveToDataStore("ANALYTICS", key, analyticsData)
end

-- Get analytics data by time range
function PluginDataStore:getAnalytics(timeRange, analyticsType)
    if not self.initialized then return {} end
    
    local results = {}
    local keyPrefix = ""
    
    if analyticsType == "realtime" then
        keyPrefix = "rt_"
    elseif analyticsType == "hourly" then
        keyPrefix = "hr_"
    elseif analyticsType == "daily" then
        keyPrefix = "dy_"
    else
        return {}
    end
    
    -- Get data from the appropriate timeframe
    local currentTime = tick()
    local startTime = currentTime - (timeRange or 86400) -- Default to last 24 hours
    
    -- This would need to be implemented with proper key iteration
    -- For now, return cached real-time data if available
    if analyticsType == "realtime" and self.analyticsState.realTimeData then
        for key, data in pairs(self.analyticsState.realTimeData) do
            if data.timestamp >= startTime then
                table.insert(results, data)
            end
        end
    end
    
    return results
end

-- Clean old real-time data
function PluginDataStore:cleanOldRealTimeData()
    local maxEntries = 100
    local count = 0
    
    for key, _ in pairs(self.analyticsState.realTimeData) do
        count = count + 1
    end
    
    if count > maxEntries then
        -- Remove oldest entries
        local sortedKeys = {}
        for key, data in pairs(self.analyticsState.realTimeData) do
            table.insert(sortedKeys, {key = key, timestamp = data.timestamp})
        end
        
        table.sort(sortedKeys, function(a, b) return a.timestamp < b.timestamp end)
        
        -- Remove excess entries
        for i = 1, count - maxEntries do
            local key = sortedKeys[i].key
            self.analyticsState.realTimeData[key] = nil
        end
    end
end

-- ==================== REPORTS MANAGEMENT ====================

-- Save analysis report
function PluginDataStore:saveReport(reportData, reportName)
    if not self.initialized or not reportData then return false end
    
    local timestamp = tick()
    local report = {
        name = reportName or ("Report_" .. tostring(timestamp)),
        timestamp = timestamp,
        data = reportData,
        version = DATA_VERSION,
        type = "analysis_report"
    }
    
    local key = "rpt_" .. createShortKey(report.name .. "_" .. tostring(timestamp), "rpt")
    local success = self:saveToDataStore("REPORTS", key, report)
    
    if success and self.logger then
        self.logger:info("PLUGIN_DATASTORE", "📋 Report saved: " .. report.name)
    end
    
    return success
end

-- Get saved reports
function PluginDataStore:getReports(limit)
    if not self.initialized then return {} end
    
    -- This would need proper implementation with key listing
    -- For now, return empty array
    return {}
end

-- Delete old reports
function PluginDataStore:cleanOldReports(maxAge)
    if not self.initialized then return false end
    
    maxAge = maxAge or CACHE_EXPIRY.REPORTS
    local cutoffTime = tick() - maxAge
    
    -- Implementation would require key iteration
    -- This is a placeholder
    return true
end

-- ==================== SETTINGS MANAGEMENT ====================

-- Save plugin settings
function PluginDataStore:saveSettings(settings)
    if not self.initialized or not settings then return false end
    
    local settingsData = {
        settings = settings,
        timestamp = tick(),
        version = DATA_VERSION,
        type = "plugin_settings"
    }
    
    local key = self.userPrefix .. "settings"
    local success = self:saveToDataStore("SETTINGS", key, settingsData)
    
    if success and self.logger then
        self.logger:info("PLUGIN_DATASTORE", "⚙️ Settings saved successfully")
    end
    
    return success
end

-- Load plugin settings
function PluginDataStore:loadSettings()
    if not self.initialized then return nil end
    
    local key = self.userPrefix .. "settings"
    local data = self:getFromDataStore("SETTINGS", key)
    
    if data and data.settings then
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "⚙️ Settings loaded successfully")
        end
        return data.settings
    end
    
    return nil
end

-- ==================== HISTORICAL DATA MANAGEMENT ====================

-- Save historical snapshot
function PluginDataStore:saveHistoricalSnapshot(snapshotData, category)
    if not self.initialized or not snapshotData then return false end
    
    local timestamp = tick()
    local snapshot = {
        timestamp = timestamp,
        category = category or "general",
        data = snapshotData,
        version = DATA_VERSION,
        type = "historical_snapshot"
    }
    
    local key = "hist_" .. (category or "gen") .. "_" .. tostring(timestamp)
    local success = self:saveToDataStore("HISTORICAL", key, snapshot)
    
    if success and self.logger then
        self.logger:info("PLUGIN_DATASTORE", "📈 Historical snapshot saved: " .. (category or "general"))
    end
    
    return success
end

-- Get historical data
function PluginDataStore:getHistoricalData(category, timeRange)
    if not self.initialized then return {} end
    
    -- Implementation would require proper key iteration
    -- This is a placeholder
    return {}
end

-- Clean old historical data
function PluginDataStore:cleanOldHistoricalData(maxAge)
    if not self.initialized then return false end
    
    maxAge = maxAge or CACHE_EXPIRY.HISTORICAL
    -- Implementation placeholder
    return true
end

-- ==================== UTILITY METHODS ====================

-- Generic save to DataStore
function PluginDataStore:saveToDataStore(storeName, key, data)
    if not self.initialized or not self.datastores[storeName] then return false end
    
    local success, error = pcall(function()
        self.datastores[storeName]:SetAsync(key, data)
    end)
    
    if success then
        self.analyticsState.operations.writes = self.analyticsState.operations.writes + 1
        -- Cache in memory for faster access
        self.memoryCache[storeName .. "_" .. key] = data
        return true
    else
        self.analyticsState.operations.errors = self.analyticsState.operations.errors + 1
        if self.logger then
            self.logger:warn("PLUGIN_DATASTORE", "Failed to save to " .. storeName .. ": " .. tostring(error))
        end
        return false
    end
end

-- Generic get from DataStore
function PluginDataStore:getFromDataStore(storeName, key)
    if not self.initialized or not self.datastores[storeName] then return nil end
    
    -- Check memory cache first
    local memKey = storeName .. "_" .. key
    if self.memoryCache[memKey] then
        return self.memoryCache[memKey]
    end
    
    local success, data = pcall(function()
        return self.datastores[storeName]:GetAsync(key)
    end)
    
    if success and data then
        self.analyticsState.operations.reads = self.analyticsState.operations.reads + 1
        -- Cache in memory
        self.memoryCache[memKey] = data
        return data
    else
        if not success then
            self.analyticsState.operations.errors = self.analyticsState.operations.errors + 1
        end
        return nil
    end
end

-- Check if cache entry is still valid
function PluginDataStore:isCacheValid(cacheData, maxAge)
    if not cacheData or not cacheData.timestamp then return false end
    
    local age = tick() - cacheData.timestamp
    return age < maxAge and cacheData.version == DATA_VERSION
end

-- Get cache and analytics statistics
function PluginDataStore:getStats()
    local memoryCount = 0
    local totalSize = 0
    
    for _, data in pairs(self.memoryCache) do
        memoryCount = memoryCount + 1
        if data and type(data) == "table" then
            local success, json = pcall(function()
                return HttpService:JSONEncode(data)
            end)
            if success then
                totalSize = totalSize + #json
            end
        end
    end
    
    return {
        initialized = self.initialized,
        datastores = self.datastores,
        version = DATA_VERSION,
        memory = {
            entries = memoryCount,
            estimatedSize = totalSize
        },
        analytics = {
            sessionTime = tick() - self.analyticsState.sessionStartTime,
            operations = Utils.deepCopy(self.analyticsState.operations),
            cacheHitRate = self.analyticsState.operations.cacheHits / 
                          math.max(1, self.analyticsState.operations.cacheHits + self.analyticsState.operations.cacheMisses)
        }
    }
end

-- Clear all cached data
function PluginDataStore:clearAllCache()
    self.memoryCache = {}
    
    if self.logger then
        self.logger:info("PLUGIN_DATASTORE", "🧹 All cache cleared")
    end
    
    return true
end

-- Record performance metric
function PluginDataStore:recordPerformance(operation, duration, success)
    if not self.analyticsState.performanceMetrics[operation] then
        self.analyticsState.performanceMetrics[operation] = {
            totalCalls = 0,
            totalDuration = 0,
            successCount = 0,
            errorCount = 0
        }
    end
    
    local metric = self.analyticsState.performanceMetrics[operation]
    metric.totalCalls = metric.totalCalls + 1
    metric.totalDuration = metric.totalDuration + duration
    
    if success then
        metric.successCount = metric.successCount + 1
    else
        metric.errorCount = metric.errorCount + 1
    end
end

return PluginDataStore 