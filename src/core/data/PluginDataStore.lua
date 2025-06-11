-- PluginDataStore.lua
-- Smart caching system using plugin's own DataStore to minimize API calls

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local PluginDataStore = {}
PluginDataStore.__index = PluginDataStore

-- Plugin's own DataStore for caching (user-specific to prevent data mixing)
local PLUGIN_DATASTORE_NAME = "DataStoreManagerPro_Cache"
local CACHE_VERSION = "v1.2"

-- Get user-specific cache prefix to isolate data per developer
local function getUserCachePrefix()
    local Players = game:GetService("Players")
    local StudioService = game:GetService("StudioService")
    
    -- Try to get current user ID for cache isolation
    local userId = "unknown"
    if StudioService then
        -- In Studio, try to get the current user
        local success, result = pcall(function()
            return StudioService:GetUserId()
        end)
        if success and result then
            userId = tostring(result)
        end
    end
    
    -- Use shorter prefix to avoid key length issues
    return "u" .. userId:sub(-6) .. "_" -- Use last 6 digits of user ID
end

-- Create a short hash for long cache keys to stay under 50 character limit
local function createShortCacheKey(longKey)
    -- Simple hash function to create shorter keys
    local hash = 0
    for i = 1, #longKey do
        hash = (hash * 31 + string.byte(longKey, i)) % 1000000
    end
    
    -- Create a short key with type prefix and hash
    local keyType = ""
    if longKey:find("datastore_names") then
        keyType = "dsn"
    elseif longKey:find("keys_") then
        keyType = "key"
    elseif longKey:find("data_") then
        keyType = "dat"
    else
        keyType = "unk"
    end
    
    return keyType .. "_" .. tostring(hash)
end

-- Cache expiry times (in seconds)
local CACHE_EXPIRY = {
    DATASTORE_NAMES = 300,    -- 5 minutes
    KEYS_LIST = 180,          -- 3 minutes  
    DATA_CONTENT = 120,       -- 2 minutes
    METADATA = 60             -- 1 minute
}

function PluginDataStore.new(logger)
    local self = setmetatable({}, PluginDataStore)
    
    self.logger = logger
    self.pluginStore = nil
    self.initialized = false
    self.memoryCache = {} -- In-memory cache for faster access
    self.userPrefix = getUserCachePrefix() -- User-specific cache isolation
    
    -- Initialize plugin DataStore
    self:initialize()
    
    return self
end

function PluginDataStore:initialize()
    local success, result = pcall(function()
        self.pluginStore = DataStoreService:GetDataStore(PLUGIN_DATASTORE_NAME)
        return true
    end)
    
    if success then
        self.initialized = true
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "✅ Plugin DataStore initialized successfully")
        end
    else
        if self.logger then
            self.logger:warn("PLUGIN_DATASTORE", "⚠️ Plugin DataStore initialization failed: " .. tostring(result))
        end
    end
end

-- Cache real DataStore names when successfully retrieved
function PluginDataStore:cacheDataStoreNames(names)
    if not self.initialized or not names then return false end
    
    local cacheData = {
        names = names,
        timestamp = tick(),
        version = CACHE_VERSION,
        type = "datastore_names",
        originalKey = "datastore_names" -- Store original key for reference
    }
    
    local longKey = self.userPrefix .. "datastore_names"
    local shortKey = createShortCacheKey(longKey)
    
    -- Store in memory cache with both keys for lookup
    self.memoryCache[longKey] = cacheData
    self.memoryCache[shortKey] = cacheData
    
    -- Store in persistent DataStore with short key
    local success, error = pcall(function()
        self.pluginStore:SetAsync(shortKey, cacheData)
    end)
    
    if success then
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "✅ Cached " .. #names .. " DataStore names")
        end
        return true
    else
        if self.logger then
            self.logger:warn("PLUGIN_DATASTORE", "Failed to cache DataStore names: " .. tostring(error))
        end
        return false
    end
end

-- Cache real keys for a DataStore
function PluginDataStore:cacheDataStoreKeys(datastoreName, keys, scope)
    if not self.initialized or not datastoreName or not keys then return false end
    
    local longKey = self.userPrefix .. "keys_" .. datastoreName .. "_" .. (scope or "global")
    local shortKey = createShortCacheKey(longKey)
    local cacheData = {
        keys = keys,
        datastoreName = datastoreName,
        scope = scope,
        timestamp = tick(),
        version = CACHE_VERSION,
        type = "keys_list",
        originalKey = longKey -- Store original key for reference
    }
    
    -- Store in memory cache with both keys for lookup
    self.memoryCache[longKey] = cacheData
    self.memoryCache[shortKey] = cacheData
    
    -- Store in persistent DataStore with short key
    local success, error = pcall(function()
        self.pluginStore:SetAsync(shortKey, cacheData)
    end)
    
    if success then
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "✅ Cached " .. #keys .. " keys for " .. datastoreName)
        end
        return true
    else
        if self.logger then
            self.logger:warn("PLUGIN_DATASTORE", "Failed to cache keys for " .. datastoreName .. ": " .. tostring(error))
        end
        return false
    end
end

-- Cache real data content
function PluginDataStore:cacheDataContent(datastoreName, key, data, metadata, scope)
    if not self.initialized or not datastoreName or not key then return false end
    
    local longKey = self.userPrefix .. "data_" .. datastoreName .. "_" .. (scope or "global") .. "_" .. key
    local shortKey = createShortCacheKey(longKey)
    local cacheData = {
        data = data,
        metadata = metadata,
        datastoreName = datastoreName,
        key = key,
        scope = scope,
        timestamp = tick(),
        version = CACHE_VERSION,
        type = "data_content",
        originalKey = longKey -- Store original key for reference
    }
    
    -- Store in memory cache with both keys for lookup
    self.memoryCache[longKey] = cacheData
    self.memoryCache[shortKey] = cacheData
    
    -- Store in persistent DataStore (async to avoid blocking)
    spawn(function()
        local success, error = pcall(function()
            self.pluginStore:SetAsync(shortKey, cacheData)
        end)
        
        if success then
            if self.logger then
                self.logger:info("PLUGIN_DATASTORE", "✅ Cached data for " .. datastoreName .. "/" .. key)
            end
        else
            if self.logger then
                self.logger:warn("PLUGIN_DATASTORE", "Failed to cache data: " .. tostring(error))
            end
        end
    end)
    
    return true
end

-- Get cached DataStore names
function PluginDataStore:getCachedDataStoreNames()
    local longKey = self.userPrefix .. "datastore_names"
    local shortKey = createShortCacheKey(longKey)
    
    -- Check memory cache first (try both keys)
    local memoryData = self.memoryCache[longKey] or self.memoryCache[shortKey]
    if memoryData and self:isCacheValid(memoryData, CACHE_EXPIRY.DATASTORE_NAMES) then
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "📋 Returning cached DataStore names from memory")
        end
        return memoryData.names, true
    end
    
    -- Check persistent cache with short key
    if not self.initialized then return nil, false end
    
    local success, cacheData = pcall(function()
        return self.pluginStore:GetAsync(shortKey)
    end)
    
    if success and cacheData and self:isCacheValid(cacheData, CACHE_EXPIRY.DATASTORE_NAMES) then
        -- Update memory cache with both keys
        self.memoryCache[longKey] = cacheData
        self.memoryCache[shortKey] = cacheData
        
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "📋 Returning cached DataStore names from persistent storage")
        end
        return cacheData.names, true
    end
    
    return nil, false
end

-- Get cached keys for a DataStore
function PluginDataStore:getCachedDataStoreKeys(datastoreName, scope)
    if not datastoreName then return nil, false end
    
    local longKey = self.userPrefix .. "keys_" .. datastoreName .. "_" .. (scope or "global")
    local shortKey = createShortCacheKey(longKey)
    
    -- Check memory cache first (try both keys)
    local memoryData = self.memoryCache[longKey] or self.memoryCache[shortKey]
    if memoryData and self:isCacheValid(memoryData, CACHE_EXPIRY.KEYS_LIST) then
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "🔑 Returning cached keys for " .. datastoreName .. " from memory")
        end
        return memoryData.keys, true
    end
    
    -- Check persistent cache with short key
    if not self.initialized then return nil, false end
    
    local success, cacheData = pcall(function()
        return self.pluginStore:GetAsync(shortKey)
    end)
    
    if success and cacheData and self:isCacheValid(cacheData, CACHE_EXPIRY.KEYS_LIST) then
        -- Update memory cache with both keys
        self.memoryCache[longKey] = cacheData
        self.memoryCache[shortKey] = cacheData
        
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "🔑 Returning cached keys for " .. datastoreName .. " from persistent storage")
        end
        return cacheData.keys, true
    end
    
    return nil, false
end

-- Get cached data content
function PluginDataStore:getCachedDataContent(datastoreName, key, scope)
    if not datastoreName or not key then return nil, nil, false end
    
    local longKey = self.userPrefix .. "data_" .. datastoreName .. "_" .. (scope or "global") .. "_" .. key
    local shortKey = createShortCacheKey(longKey)
    
    -- Check memory cache first (try both keys)
    local memoryData = self.memoryCache[longKey] or self.memoryCache[shortKey]
    if memoryData and self:isCacheValid(memoryData, CACHE_EXPIRY.DATA_CONTENT) then
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "💾 Returning cached data for " .. datastoreName .. "/" .. key .. " from memory")
        end
        return memoryData.data, memoryData.metadata, true
    end
    
    -- Check persistent cache with short key
    if not self.initialized then return nil, nil, false end
    
    local success, cacheData = pcall(function()
        return self.pluginStore:GetAsync(shortKey)
    end)
    
    if success and cacheData and self:isCacheValid(cacheData, CACHE_EXPIRY.DATA_CONTENT) then
        -- Update memory cache with both keys
        self.memoryCache[longKey] = cacheData
        self.memoryCache[shortKey] = cacheData
        
        if self.logger then
            self.logger:info("PLUGIN_DATASTORE", "💾 Returning cached data for " .. datastoreName .. "/" .. key .. " from persistent storage")
        end
        return cacheData.data, cacheData.metadata, true
    end
    
    return nil, nil, false
end

-- Check if cache entry is still valid
function PluginDataStore:isCacheValid(cacheData, maxAge)
    if not cacheData or not cacheData.timestamp then return false end
    
    local age = tick() - cacheData.timestamp
    return age < maxAge and cacheData.version == CACHE_VERSION
end

-- Make a lightweight verification call to check if data has changed
function PluginDataStore:verifyDataFreshness(datastoreName, key, scope, cachedMetadata)
    if not self.initialized then return false end
    
    -- Make a minimal API call to check metadata only
    local success, currentMetadata = pcall(function()
        local store = DataStoreService:GetDataStore(datastoreName, scope)
        -- Use GetVersionAsync for lightweight metadata check
        local keyInfo = store:GetAsync(key)
        return keyInfo and {
            version = keyInfo.Version or 1,
            timestamp = keyInfo.CreatedTime or tick()
        } or nil
    end)
    
    if success and currentMetadata and cachedMetadata then
        -- Compare versions to see if data changed
        local versionChanged = currentMetadata.version ~= cachedMetadata.version
        local timestampChanged = currentMetadata.timestamp ~= cachedMetadata.timestamp
        
        if self.logger then
            if versionChanged or timestampChanged then
                self.logger:info("PLUGIN_DATASTORE", "🔄 Data changed for " .. datastoreName .. "/" .. key .. " - cache invalid")
            else
                self.logger:info("PLUGIN_DATASTORE", "✅ Data unchanged for " .. datastoreName .. "/" .. key .. " - cache valid")
            end
        end
        
        return not (versionChanged or timestampChanged)
    end
    
    return false
end

-- Clear all cached data (useful for debugging)
function PluginDataStore:clearAllCache()
    -- Clear memory cache
    self.memoryCache = {}
    
    if not self.initialized then return false end
    
    -- Clear persistent cache (this is more complex, so we'll just mark it as cleared)
    local success = pcall(function()
        self.pluginStore:SetAsync("cache_cleared", {
            timestamp = tick(),
            version = CACHE_VERSION
        })
    end)
    
    if self.logger then
        if success then
            self.logger:info("PLUGIN_DATASTORE", "🧹 All cache cleared successfully")
        else
            self.logger:warn("PLUGIN_DATASTORE", "Failed to clear persistent cache")
        end
    end
    
    return success
end

-- Get cache statistics
function PluginDataStore:getCacheStats()
    local memoryCount = 0
    local totalSize = 0
    
    for key, data in pairs(self.memoryCache) do
        memoryCount = memoryCount + 1
        if data.data then
            totalSize = totalSize + #HttpService:JSONEncode(data.data)
        end
    end
    
    return {
        memoryEntries = memoryCount,
        estimatedSize = totalSize,
        initialized = self.initialized,
        version = CACHE_VERSION
    }
end

return PluginDataStore 