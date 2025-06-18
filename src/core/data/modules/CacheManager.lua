-- DataStore Manager Pro - Cache Manager Module
-- Handles all caching operations for DataStore data and metadata

local CacheManager = {}
CacheManager.__index = CacheManager

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[CACHE_MANAGER] [%s] %s", level, message))
end

-- Create new Cache Manager instance
function CacheManager.new(config)
    local self = setmetatable({}, CacheManager)
    
    self.config = config or {}
    self.dataCache = {}
    self.keyListCache = {}
    self.datastoreCache = {}
    self.orderedDataStoreCache = {}
    self.cacheStats = {
        hits = 0,
        misses = 0,
        evictions = 0,
        totalSize = 0
    }
    
    -- Cache configuration
    self.maxCacheSize = self.config.maxCacheSize or 1000
    self.maxAge = self.config.maxAge or 300 -- 5 minutes
    self.cleanupInterval = self.config.cleanupInterval or 60 -- 1 minute
    
    -- Start cleanup timer
    self:startCleanupTimer()
    
    debugLog("CacheManager initialized with max size: " .. self.maxCacheSize)
    return self
end

-- Cache data with expiration
function CacheManager:cacheData(datastoreName, key, data, metadata)
    local cacheKey = datastoreName .. ":" .. key
    local now = tick()
    
    -- Check if cache is full
    if self:getCacheSize() >= self.maxCacheSize then
        self:evictOldestEntry()
    end
    
    self.dataCache[cacheKey] = {
        data = data,
        metadata = metadata or {},
        timestamp = now,
        accessCount = 1,
        lastAccessed = now
    }
    
    self.cacheStats.totalSize = self.cacheStats.totalSize + 1
    debugLog("Cached data for " .. cacheKey)
end

-- Get cached data
function CacheManager:getCachedData(datastoreName, key)
    local cacheKey = datastoreName .. ":" .. key
    local cached = self.dataCache[cacheKey]
    
    if not cached then
        self.cacheStats.misses = self.cacheStats.misses + 1
        return nil
    end
    
    -- Check if expired
    if self:isExpired(cached) then
        self:removeCachedData(datastoreName, key)
        self.cacheStats.misses = self.cacheStats.misses + 1
        return nil
    end
    
    -- Update access statistics
    cached.accessCount = cached.accessCount + 1
    cached.lastAccessed = tick()
    self.cacheStats.hits = self.cacheStats.hits + 1
    
    return cached.data, cached.metadata
end

-- Cache key list
function CacheManager:cacheKeyList(datastoreName, keys, metadata)
    local now = tick()
    
    self.keyListCache[datastoreName] = {
        keys = keys,
        metadata = metadata or {},
        timestamp = now,
        lastAccessed = now
    }
    
    debugLog("Cached key list for " .. datastoreName .. " (" .. #keys .. " keys)")
end

-- Get cached key list
function CacheManager:getCachedKeyList(datastoreName)
    local cached = self.keyListCache[datastoreName]
    
    if not cached then
        return nil
    end
    
    -- Check if expired
    if self:isExpired(cached) then
        self.keyListCache[datastoreName] = nil
        return nil
    end
    
    cached.lastAccessed = tick()
    return cached.keys, cached.metadata
end

-- Cache DataStore instance
function CacheManager:cacheDataStore(datastoreName, scope, datastoreInstance)
    local cacheKey = datastoreName .. ":" .. (scope or "global")
    local now = tick()
    
    self.datastoreCache[cacheKey] = {
        store = datastoreInstance,
        created = now,
        lastAccessed = now,
        requestCount = 0
    }
    
    debugLog("Cached DataStore instance: " .. cacheKey)
end

-- Get cached DataStore instance
function CacheManager:getCachedDataStore(datastoreName, scope)
    local cacheKey = datastoreName .. ":" .. (scope or "global")
    local cached = self.datastoreCache[cacheKey]
    
    if cached then
        cached.lastAccessed = tick()
        cached.requestCount = cached.requestCount + 1
        return cached.store
    end
    
    return nil
end

-- Cache OrderedDataStore instance
function CacheManager:cacheOrderedDataStore(datastoreName, scope, datastoreInstance)
    local cacheKey = datastoreName .. ":" .. (scope or "global")
    local now = tick()
    
    self.orderedDataStoreCache[cacheKey] = {
        store = datastoreInstance,
        created = now,
        lastAccessed = now,
        requestCount = 0
    }
    
    debugLog("Cached OrderedDataStore instance: " .. cacheKey)
end

-- Get cached OrderedDataStore instance
function CacheManager:getCachedOrderedDataStore(datastoreName, scope)
    local cacheKey = datastoreName .. ":" .. (scope or "global")
    local cached = self.orderedDataStoreCache[cacheKey]
    
    if cached then
        cached.lastAccessed = tick()
        cached.requestCount = cached.requestCount + 1
        return cached.store
    end
    
    return nil
end

-- Remove cached data
function CacheManager:removeCachedData(datastoreName, key)
    local cacheKey = datastoreName .. ":" .. key
    if self.dataCache[cacheKey] then
        self.dataCache[cacheKey] = nil
        self.cacheStats.totalSize = self.cacheStats.totalSize - 1
        debugLog("Removed cached data for " .. cacheKey)
    end
end

-- Clear cache for specific DataStore
function CacheManager:clearDataStoreCache(datastoreName)
    local cleared = 0
    
    -- Clear data cache
    for cacheKey, _ in pairs(self.dataCache) do
        if cacheKey:find("^" .. datastoreName .. ":") then
            self.dataCache[cacheKey] = nil
            cleared = cleared + 1
        end
    end
    
    -- Clear key list cache
    if self.keyListCache[datastoreName] then
        self.keyListCache[datastoreName] = nil
        cleared = cleared + 1
    end
    
    self.cacheStats.totalSize = self.cacheStats.totalSize - cleared
    debugLog("Cleared cache for " .. datastoreName .. " (" .. cleared .. " entries)")
    return cleared
end

-- Clear all caches
function CacheManager:clearAllCaches()
    local totalCleared = self.cacheStats.totalSize
    
    self.dataCache = {}
    self.keyListCache = {}
    self.datastoreCache = {}
    self.orderedDataStoreCache = {}
    self.cacheStats.totalSize = 0
    self.cacheStats.evictions = self.cacheStats.evictions + totalCleared
    
    debugLog("Cleared all caches (" .. totalCleared .. " entries)")
    return totalCleared
end

-- Check if cache entry is expired
function CacheManager:isExpired(cacheEntry)
    return (tick() - cacheEntry.timestamp) > self.maxAge
end

-- Get current cache size
function CacheManager:getCacheSize()
    return self.cacheStats.totalSize
end

-- Evict oldest cache entry
function CacheManager:evictOldestEntry()
    if self.evictionStrategy == "LFU" then
        self:evictLFUEntry()
    else
        -- Original LRU strategy
        local oldestKey = nil
        local oldestTime = math.huge
        
        for cacheKey, cached in pairs(self.dataCache) do
            if cached.lastAccessed < oldestTime then
                oldestTime = cached.lastAccessed
                oldestKey = cacheKey
            end
        end
        
        if oldestKey then
            self.dataCache[oldestKey] = nil
            self.cacheStats.totalSize = self.cacheStats.totalSize - 1
            self.cacheStats.evictions = self.cacheStats.evictions + 1
            debugLog("Evicted oldest cache entry: " .. oldestKey)
        end
    end
end

-- Cleanup expired entries
function CacheManager:cleanupExpiredEntries()
    local cleaned = 0
    local now = tick()
    
    -- Clean data cache
    for cacheKey, cached in pairs(self.dataCache) do
        if self:isExpired(cached) then
            self.dataCache[cacheKey] = nil
            cleaned = cleaned + 1
        end
    end
    
    -- Clean key list cache
    for datastoreName, cached in pairs(self.keyListCache) do
        if self:isExpired(cached) then
            self.keyListCache[datastoreName] = nil
            cleaned = cleaned + 1
        end
    end
    
    self.cacheStats.totalSize = self.cacheStats.totalSize - cleaned
    
    if cleaned > 0 then
        debugLog("Cleaned up " .. cleaned .. " expired cache entries")
    end
    
    return cleaned
end

-- Start automatic cleanup timer
function CacheManager:startCleanupTimer()
    spawn(function()
        while true do
            wait(self.cleanupInterval)
            self:cleanupExpiredEntries()
        end
    end)
    
    debugLog("Started automatic cache cleanup timer")
end

-- Get cache statistics
function CacheManager:getStats()
    local hitRate = 0
    local missRate = 0
    local totalRequests = self.cacheStats.hits + self.cacheStats.misses
    
    if totalRequests > 0 then
        hitRate = self.cacheStats.hits / totalRequests
        missRate = self.cacheStats.misses / totalRequests
    end
    
    return {
        hits = self.cacheStats.hits,
        misses = self.cacheStats.misses,
        evictions = self.cacheStats.evictions,
        totalSize = self.cacheStats.totalSize,
        hitRate = hitRate,
        missRate = missRate,
        maxSize = self.maxCacheSize,
        maxAge = self.maxAge,
        size = self:getCacheSize()
    }
end

-- Increase cache size for performance optimization
function CacheManager:increaseCacheSize(percentage)
    percentage = percentage or 0.2 -- Default 20% increase
    local oldSize = self.maxCacheSize
    self.maxCacheSize = math.floor(self.maxCacheSize * (1 + percentage))
    
    debugLog(string.format("Increased cache size from %d to %d (%.1f%% increase)", 
        oldSize, self.maxCacheSize, percentage * 100))
    
    return self.maxCacheSize
end

-- Decrease cache size for memory optimization
function CacheManager:decreaseCacheSize(percentage)
    percentage = percentage or 0.1 -- Default 10% decrease
    local oldSize = self.maxCacheSize
    self.maxCacheSize = math.max(100, math.floor(self.maxCacheSize * (1 - percentage)))
    
    -- Force cleanup if current size exceeds new limit
    while self:getCacheSize() > self.maxCacheSize do
        self:evictOldestEntry()
    end
    
    debugLog(string.format("Decreased cache size from %d to %d (%.1f%% decrease)", 
        oldSize, self.maxCacheSize, percentage * 100))
    
    return self.maxCacheSize
end

-- Optimize cache based on usage patterns
function CacheManager:optimizeCache()
    local stats = self:getStats()
    
    -- If hit rate is low and we have room, try different strategies
    if stats.hitRate < 0.7 then
        -- Strategy 1: Increase cache age for better retention
        if self.maxAge < 600 then -- Less than 10 minutes
            self.maxAge = math.min(600, self.maxAge * 1.5)
            debugLog("Increased cache age to " .. self.maxAge .. " seconds for better retention")
        end
        
        -- Strategy 2: Implement smarter eviction (LFU instead of LRU)
        self:switchToLFUEviction()
    end
    
    -- If memory usage is high, be more aggressive with cleanup
    if stats.totalSize > stats.maxSize * 0.9 then
        self:aggressiveCleanup()
    end
end

-- Switch to Least Frequently Used eviction strategy
function CacheManager:switchToLFUEviction()
    self.evictionStrategy = "LFU"
    debugLog("Switched to LFU (Least Frequently Used) eviction strategy")
end

-- Evict entry using LFU strategy
function CacheManager:evictLFUEntry()
    local leastUsedKey = nil
    local leastUsedCount = math.huge
    
    for cacheKey, cached in pairs(self.dataCache) do
        if cached.accessCount < leastUsedCount then
            leastUsedCount = cached.accessCount
            leastUsedKey = cacheKey
        end
    end
    
    if leastUsedKey then
        self.dataCache[leastUsedKey] = nil
        self.cacheStats.totalSize = self.cacheStats.totalSize - 1
        self.cacheStats.evictions = self.cacheStats.evictions + 1
        debugLog("Evicted least frequently used cache entry: " .. leastUsedKey)
    end
end

-- Aggressive cleanup for memory pressure
function CacheManager:aggressiveCleanup()
    local cleaned = 0
    local targetSize = math.floor(self.maxCacheSize * 0.7) -- Clean to 70% capacity
    
    -- First, remove expired entries
    cleaned = cleaned + self:cleanupExpiredEntries()
    
    -- If still over target, remove least useful entries
    while self:getCacheSize() > targetSize do
        self:evictOldestEntry()
        cleaned = cleaned + 1
    end
    
    debugLog("Aggressive cleanup completed, removed " .. cleaned .. " entries")
    return cleaned
end

-- Preload frequently accessed data
function CacheManager:preloadFrequentData(dataStoreManager)
    if not dataStoreManager then
        return
    end
    
    -- Analyze access patterns and preload top accessed keys
    local accessPatterns = self:analyzeAccessPatterns()
    
    for _, pattern in ipairs(accessPatterns) do
        if pattern.frequency > 10 then -- Frequently accessed
            spawn(function()
                local data = dataStoreManager:getData(pattern.datastoreName, pattern.key)
                if data then
                    self:cacheData(pattern.datastoreName, pattern.key, data)
                    debugLog("Preloaded frequent data: " .. pattern.datastoreName .. ":" .. pattern.key)
                end
            end)
        end
    end
end

-- Analyze access patterns for optimization
function CacheManager:analyzeAccessPatterns()
    local patterns = {}
    local patternMap = {}
    
    -- Analyze current cache for access patterns
    for cacheKey, cached in pairs(self.dataCache) do
        local datastoreName, key = cacheKey:match("^([^:]+):(.+)$")
        if datastoreName and key then
            local patternKey = datastoreName .. ":" .. key
            if not patternMap[patternKey] then
                patternMap[patternKey] = {
                    datastoreName = datastoreName,
                    key = key,
                    frequency = 0,
                    lastAccessed = 0
                }
            end
            
            patternMap[patternKey].frequency = patternMap[patternKey].frequency + cached.accessCount
            patternMap[patternKey].lastAccessed = math.max(patternMap[patternKey].lastAccessed, cached.lastAccessed)
        end
    end
    
    -- Convert to sorted array
    for _, pattern in pairs(patternMap) do
        table.insert(patterns, pattern)
    end
    
    -- Sort by frequency
    table.sort(patterns, function(a, b)
        return a.frequency > b.frequency
    end)
    
    return patterns
end

-- Get cache performance recommendations
function CacheManager:getPerformanceRecommendations()
    local stats = self:getStats()
    local recommendations = {}
    
    if stats.hitRate < 0.5 then
        table.insert(recommendations, {
            type = "critical",
            title = "Very Low Cache Hit Rate",
            description = "Consider increasing cache size or reviewing caching strategy",
            action = "increase_cache_size"
        })
    elseif stats.hitRate < 0.7 then
        table.insert(recommendations, {
            type = "warning",
            title = "Low Cache Hit Rate",
            description = "Cache effectiveness could be improved",
            action = "optimize_cache_strategy"
        })
    end
    
    if stats.totalSize > stats.maxSize * 0.9 then
        table.insert(recommendations, {
            type = "warning",
            title = "Cache Near Capacity",
            description = "Consider increasing cache size or reducing retention time",
            action = "increase_cache_size"
        })
    end
    
    if stats.evictions > stats.hits * 0.1 then
        table.insert(recommendations, {
            type = "info",
            title = "High Eviction Rate",
            description = "Cache may be too small for current workload",
            action = "increase_cache_size"
        })
    end
    
    return recommendations
end

-- Update cache configuration
function CacheManager:updateConfig(newConfig)
    if newConfig.maxCacheSize then
        self.maxCacheSize = newConfig.maxCacheSize
    end
    
    if newConfig.maxAge then
        self.maxAge = newConfig.maxAge
    end
    
    if newConfig.cleanupInterval then
        self.cleanupInterval = newConfig.cleanupInterval
    end
    
    debugLog("Cache configuration updated")
end

return CacheManager 