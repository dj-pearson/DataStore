-- DataStore Manager Pro - Core DataStore Manager
-- Robust DataStore operations with enterprise features

local DataStoreManager = {}
DataStoreManager.__index = DataStoreManager

-- Import services
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

-- Local state
local cache = {}
local operationLog = {}
local initialized = false
local requestBudget = Constants.DATASTORE.REQUEST_BUDGET_LIMIT
local lastRequestTime = 0

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[DATASTORE_MANAGER] [%s] %s", level, message))
end

-- Request budget management
local function checkRequestBudget()
    local now = tick()
    local timeSinceLastRequest = now - lastRequestTime
    
    -- Replenish budget over time
    if timeSinceLastRequest >= Constants.DATASTORE.REQUEST_COOLDOWN then
        requestBudget = math.min(
            requestBudget + math.floor(timeSinceLastRequest / Constants.DATASTORE.REQUEST_COOLDOWN),
            Constants.DATASTORE.REQUEST_BUDGET_LIMIT
        )
        lastRequestTime = now
    end
    
    return requestBudget > 0
end

local function consumeRequestBudget()
    if requestBudget > 0 then
        requestBudget = requestBudget - 1
        lastRequestTime = tick()
        return true
    end
    return false
end

-- Initialize DataStore Manager
function DataStoreManager.initialize()
    local self = setmetatable({}, DataStoreManager)
    
    debugLog("Initializing DataStore Manager")
    
    -- Initialize plugin's own DataStore for smart caching
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
    
    -- Cache for DataStore instances and data
    self.datastoreCache = {}
    self.dataCache = {}
    self.keyListCache = {}
    
    -- Request budget tracking
    self.requestBudget = {
        read = 0,
        write = 0,
        list = 0,
        lastReset = tick()
    }
    
    self.sessionId = HttpService:GenerateGUID()
    
    initialized = true
    debugLog("DataStore Manager initialized successfully")
    return self
end

-- Get DataStore with caching
function DataStoreManager.getDataStore(name, scope)
    if not initialized then
        debugLog("DataStore Manager not initialized", "ERROR")
        return nil
    end
    
    local key = name .. ":" .. (scope or "global")
    
    if not cache[key] then
        debugLog("Creating new DataStore connection: " .. key)
        
        local success, store = pcall(function()
            return DataStoreService:GetDataStore(name, scope)
        end)
        
        if success then
            cache[key] = {
                store = store,
                created = tick(),
                lastAccessed = tick(),
                requestCount = 0
            }
            debugLog("DataStore created successfully: " .. key)
        else
            debugLog("Failed to create DataStore: " .. tostring(store), "ERROR")
            return nil
        end
    else
        -- Update access time
        cache[key].lastAccessed = tick()
    end
    
    cache[key].requestCount = cache[key].requestCount + 1
    return cache[key].store
end

-- Enhanced read operation
function DataStoreManager.readData(storeName, key, options)
    if not initialized then
        debugLog("DataStore Manager not initialized", "ERROR")
        return nil, "DataStore Manager not initialized"
    end
    
    options = options or {}
    
    -- Validate inputs
    local isValidKey, keyError = Utils.Validation.isValidDataStoreKey(key)
    if not isValidKey then
        debugLog("Invalid key: " .. keyError, "ERROR")
        return nil, keyError
    end
    
    local operation = {
        type = "READ",
        store = storeName,
        key = key,
        timestamp = tick(),
        attempts = 0,
        success = false
    }
    
    local function attempt()
        operation.attempts = operation.attempts + 1
        
        -- Check request budget
        if not checkRequestBudget() then
            local error = "Request budget exceeded. Please wait before making more requests."
            debugLog(error, "WARN")
            return nil, error
        end
        
        local store = DataStoreManager.getDataStore(storeName, options.scope)
        if not store then
            local error = "Failed to get DataStore: " .. storeName
            operation.error = error
            DataStoreManager.logOperation(operation)
            return nil, error
        end
        
        local success, result = pcall(function()
            consumeRequestBudget()
            return store:GetAsync(key)
        end)
        
        if success then
            operation.success = true
            operation.result = result
            operation.latency = (tick() - operation.timestamp) * 1000 -- Convert to ms
            DataStoreManager.logOperation(operation)
            
            debugLog(string.format(
                "Read successful: %s[%s] in %.2fms", 
                storeName, 
                key, 
                operation.latency
            ))
            
            return result, nil
        else
            operation.error = result
            
            -- Handle specific errors
            if tostring(result):find("budget") or tostring(result):find("quota") then
                requestBudget = 0 -- Force budget reset
            end
            
            if operation.attempts < Constants.DATASTORE.MAX_RETRIES then
                debugLog(string.format(
                    "Read attempt %d failed, retrying: %s", 
                    operation.attempts, 
                    tostring(result)
                ), "WARN")
                
                wait(Constants.DATASTORE.RETRY_DELAY_BASE * operation.attempts)
                return attempt()
            else
                operation.success = false
                operation.latency = (tick() - operation.timestamp) * 1000
                DataStoreManager.logOperation(operation)
                
                debugLog(string.format(
                    "Read failed after %d attempts: %s", 
                    operation.attempts, 
                    tostring(result)
                ), "ERROR")
                
                return nil, result
            end
        end
    end
    
    return attempt()
end

-- Enhanced write operation
function DataStoreManager.writeData(storeName, key, value, options)
    if not initialized then
        debugLog("DataStore Manager not initialized", "ERROR")
        return false, "DataStore Manager not initialized"
    end
    
    options = options or {}
    
    -- Validate inputs
    local isValidKey, keyError = Utils.Validation.isValidDataStoreKey(key)
    if not isValidKey then
        debugLog("Invalid key: " .. keyError, "ERROR")
        return false, keyError
    end
    
    local isValidData, dataError = Utils.Validation.isValidDataStoreData(value)
    if not isValidData then
        debugLog("Invalid data: " .. dataError, "ERROR")
        return false, dataError
    end
    
    local operation = {
        type = "WRITE",
        store = storeName,
        key = key,
        timestamp = tick(),
        attempts = 0,
        success = false,
        dataSize = #HttpService:JSONEncode(value)
    }
    
    local function attempt()
        operation.attempts = operation.attempts + 1
        
        -- Check request budget
        if not checkRequestBudget() then
            local error = "Request budget exceeded. Please wait before making more requests."
            debugLog(error, "WARN")
            return false, error
        end
        
        local store = DataStoreManager.getDataStore(storeName, options.scope)
        if not store then
            local error = "Failed to get DataStore: " .. storeName
            operation.error = error
            DataStoreManager.logOperation(operation)
            return false, error
        end
        
        local success, result = pcall(function()
            consumeRequestBudget()
            return store:SetAsync(key, value, options.userIds, options.metadata)
        end)
        
        if success then
            operation.success = true
            operation.latency = (tick() - operation.timestamp) * 1000
            DataStoreManager.logOperation(operation)
            
            debugLog(string.format(
                "Write successful: %s[%s] (%s) in %.2fms", 
                storeName, 
                key, 
                Utils.UI.formatBytes(operation.dataSize),
                operation.latency
            ))
            
            return true, nil
        else
            operation.error = result
            
            -- Handle specific errors
            if tostring(result):find("budget") or tostring(result):find("quota") then
                requestBudget = 0 -- Force budget reset
            end
            
            if operation.attempts < Constants.DATASTORE.MAX_RETRIES then
                debugLog(string.format(
                    "Write attempt %d failed, retrying: %s", 
                    operation.attempts, 
                    tostring(result)
                ), "WARN")
                
                wait(Constants.DATASTORE.RETRY_DELAY_BASE * operation.attempts)
                return attempt()
            else
                operation.success = false
                operation.latency = (tick() - operation.timestamp) * 1000
                DataStoreManager.logOperation(operation)
                
                debugLog(string.format(
                    "Write failed after %d attempts: %s", 
                    operation.attempts, 
                    tostring(result)
                ), "ERROR")
                
                return false, result
            end
        end
    end
    
    return attempt()
end

-- Delete operation
function DataStoreManager.deleteData(storeName, key, options)
    if not initialized then
        debugLog("DataStore Manager not initialized", "ERROR")
        return false, "DataStore Manager not initialized"
    end
    
    -- Deletion is done by setting to nil
    return DataStoreManager.writeData(storeName, key, nil, options)
end

-- List keys operation (if available)
function DataStoreManager.listKeys(storeName, prefix, pageSize, options)
    if not initialized then
        debugLog("DataStore Manager not initialized", "ERROR")
        return {}, "DataStore Manager not initialized"
    end
    
    options = options or {}
    pageSize = pageSize or 100
    
    -- Check request budget
    if not checkRequestBudget() then
        local error = "Request budget exceeded. Please wait before making more requests."
        debugLog(error, "WARN")
        return {}, error
    end
    
    local store = DataStoreManager.getDataStore(storeName, options.scope)
    if not store then
        local error = "Failed to get DataStore: " .. storeName
        debugLog(error, "ERROR")
        return {}, error
    end
    
    local success, result = pcall(function()
        consumeRequestBudget()
        return store:ListKeysAsync(prefix, pageSize)
    end)
    
    if success then
        local keys = {}
        for _, keyInfo in ipairs(result:GetCurrentPage()) do
            table.insert(keys, {
                name = keyInfo.KeyName,
                version = keyInfo.Version,
                metadata = keyInfo.Metadata,
                userIds = keyInfo.UserIds,
                createdTime = keyInfo.CreatedTime,
                updatedTime = keyInfo.UpdatedTime
            })
        end
        
        debugLog(string.format("Listed %d keys for store: %s", #keys, storeName))
        return keys, nil
    else
        debugLog("Failed to list keys: " .. tostring(result), "ERROR")
        return {}, result
    end
end

-- Operation logging
function DataStoreManager.logOperation(operation)
    table.insert(operationLog, operation)
    
    -- Maintain log size
    if #operationLog > Constants.LOGGING.MAX_LOG_ENTRIES then
        table.remove(operationLog, 1)
    end
    
    -- Emit event for monitoring
    if DataStoreManager.onOperation then
        DataStoreManager.onOperation(operation)
    end
end

-- Get statistics
function DataStoreManager.getStatistics()
    if not initialized then
        return {}
    end
    
    local stats = {
        totalOperations = #operationLog,
        successRate = 0,
        averageLatency = 0,
        operationTypes = {},
        recentErrors = {},
        cacheInfo = {
            totalStores = 0,
            totalRequests = 0
        },
        requestBudget = {
            current = requestBudget,
            maximum = Constants.DATASTORE.REQUEST_BUDGET_LIMIT,
            percentageUsed = (1 - requestBudget / Constants.DATASTORE.REQUEST_BUDGET_LIMIT) * 100
        }
    }
    
    local totalLatency = 0
    local successes = 0
    
    for _, op in ipairs(operationLog) do
        -- Success rate
        if op.success then
            successes = successes + 1
        else
            table.insert(stats.recentErrors, op)
        end
        
        -- Operation types
        stats.operationTypes[op.type] = (stats.operationTypes[op.type] or 0) + 1
        
        -- Latency
        if op.latency then
            totalLatency = totalLatency + op.latency
        end
    end
    
    if stats.totalOperations > 0 then
        stats.successRate = successes / stats.totalOperations
        stats.averageLatency = totalLatency / stats.totalOperations
    end
    
    -- Cache statistics
    for _, cacheEntry in pairs(cache) do
        stats.cacheInfo.totalStores = stats.cacheInfo.totalStores + 1
        stats.cacheInfo.totalRequests = stats.cacheInfo.totalRequests + cacheEntry.requestCount
    end
    
    return stats
end

-- Removed duplicate clearCache function - using instance method instead

-- Get operation history
function DataStoreManager.getOperationHistory(count, operationType)
    if not initialized then
        return {}
    end
    
    count = count or 50
    local history = {}
    
    for i = #operationLog, math.max(1, #operationLog - count * 2), -1 do
        local op = operationLog[i]
        
        if not operationType or op.type == operationType then
            table.insert(history, op)
            
            if #history >= count then
                break
            end
        end
    end
    
    return history
end

-- Register operation callback
function DataStoreManager.onOperation(callback)
    DataStoreManager.onOperation = callback
end

-- Cleanup
function DataStoreManager.cleanup()
    if not initialized then
        return
    end
    
    debugLog("Cleaning up DataStore Manager")
    
    local stats = DataStoreManager.getStatistics()
    debugLog(string.format(
        "Final stats - Operations: %d, Success rate: %.1f%%, Avg latency: %.2fms",
        stats.totalOperations,
        (stats.successRate or 0) * 100,
        stats.averageLatency or 0
    ))
    
    cache = {}
    operationLog = {}
    initialized = false
    
    debugLog("DataStore Manager cleanup complete")
end

-- Get list of DataStore names with smart caching (limited to common ones since Roblox doesn't provide enumeration)
function DataStoreManager:getDataStoreNames()
    debugLog("Getting DataStore names")
    
    -- First, check plugin's persistent cache for real data
    if self.pluginCache then
        local cachedNames, isFromCache = self.pluginCache:getCachedDataStoreNames()
        if isFromCache and cachedNames then
            debugLog("🎯 Using cached real DataStore names from plugin DataStore")
            return cachedNames
        end
    end
    
    local cacheKey = "datastore_names"
    local currentTime = tick()
    
    -- Check if we have cached DataStore names that are still fresh (30 seconds)
    if cache[cacheKey] and cache[cacheKey].timestamp and (currentTime - cache[cacheKey].timestamp) < 30 then
        debugLog("Returning cached DataStore names (age: " .. math.floor(currentTime - cache[cacheKey].timestamp) .. "s)")
        return cache[cacheKey].data
    end
    
    -- Check if we have any tracked DataStores from cache
    local trackedDataStores = {}
    for key, _ in pairs(cache) do
        local storeName = key:split(":")[1]
        if storeName and not trackedDataStores[storeName] and not key:find("throttle") then
            trackedDataStores[storeName] = true
        end
    end
    
    -- Convert tracked DataStores to array
    local dataStoreNames = {}
    for storeName, _ in pairs(trackedDataStores) do
        table.insert(dataStoreNames, storeName)
    end
    
    -- If no tracked DataStores, try to discover real ones first, then fall back to common ones
    if #dataStoreNames == 0 then
        debugLog("No tracked DataStores found, checking discovery options...")
        
        -- Use improved discovery system that tests your specific DataStore names
        if not self:isAutoDiscoveryDisabled() then
            -- Check if discovery was run recently
            local discoveryKey = "discovery_cooldown"
            local currentTime = tick()
            local shouldDiscover = not cache[discoveryKey] or not cache[discoveryKey].timestamp or (currentTime - cache[discoveryKey].timestamp) >= 300
            
            if shouldDiscover then
                debugLog("Attempting DataStore discovery...")
                local discoveredDataStores = self:discoverRealDataStores()
                
                if #discoveredDataStores > 0 then
                    debugLog("🎯 Discovered " .. #discoveredDataStores .. " real DataStores!")
                    dataStoreNames = discoveredDataStores
                else
                    debugLog("No real DataStores discovered, using common fallback names")
                end
            else
                debugLog("Discovery on cooldown - using cached results or fallback names")
                local cachedResults = cache[discoveryKey] and cache[discoveryKey].results
                if cachedResults and #cachedResults > 0 then
                    dataStoreNames = cachedResults
                    debugLog("Using cached discovery results: " .. #cachedResults .. " DataStores")
                end
            end
        else
            debugLog("Auto-discovery disabled - using fallback names")
        end
        
        -- Use fallback names if discovery didn't find anything or we're on client
        if #dataStoreNames == 0 then
            -- Your actual DataStore names from screenshot + common fallback names
            local commonDataStores = {
                -- Real DataStores from your game (from screenshot)
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
                "v4_WorldData",
                
                -- Common fallback names for other games
                "GameSettings",
                "Leaderboard",
                "PlayerInventory",
                "GameData",
                "UserPreferences",
                "ServerData",
                "PlayerSaves",
                "Achievements"
            }
            
            dataStoreNames = commonDataStores
        end
    end
    
    -- Cache the result
    cache[cacheKey] = {
        data = dataStoreNames,
        timestamp = currentTime,
        requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1
    }
    
    -- Cache in plugin's persistent DataStore for future sessions
    if self.pluginCache and #dataStoreNames > 0 then
        self.pluginCache:cacheDataStoreNames(dataStoreNames)
    end
    
    debugLog("Returning " .. #dataStoreNames .. " DataStore names (" .. (#trackedDataStores > 0 and "from cache usage" or "common") .. ")")
    return dataStoreNames
end

-- Quick check if a DataStore has any data (for discovery)
function DataStoreManager:quickCheckDataStoreExists(datastoreName)
    local success, result = pcall(function()
        -- Use nil for global scope instead of empty string
        local store = DataStoreService:GetDataStore(datastoreName, nil)
        local keyPages = store:ListKeysAsync()
        local currentPage = keyPages:GetCurrentPage()
        return #currentPage > 0
    end)
    
    return success and result
end

-- Get keys for a specific DataStore with smart caching
function DataStoreManager:getDataStoreKeys(datastoreName, scope, maxKeys)
    debugLog("Getting keys for DataStore: " .. datastoreName)
    
    maxKeys = maxKeys or 50
    -- Fix: Use nil instead of empty string for global scope
    if scope == "" then scope = nil end
    
    -- First, check plugin's persistent cache for real data
    if self.pluginCache then
        local cachedKeys, isFromCache = self.pluginCache:getCachedDataStoreKeys(datastoreName, scope)
        if isFromCache and cachedKeys then
            debugLog("🎯 Using cached real keys from plugin DataStore for " .. datastoreName)
            return cachedKeys
        end
    end
    
    -- Global API throttling - prevent any API call if last call was too recent
    local globalThrottleKey = "global_api_throttle"
    local currentTime = tick()
    if cache[globalThrottleKey] and cache[globalThrottleKey].timestamp and (currentTime - cache[globalThrottleKey].timestamp) < 10 then
        local waitTime = 10 - (currentTime - cache[globalThrottleKey].timestamp)
        debugLog("Global API throttling active - last request " .. string.format("%.1f", currentTime - cache[globalThrottleKey].timestamp) .. "s ago")
        
        -- Return cached data if available, otherwise fallback
        local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":keys"
        if cache[cacheKey] and cache[cacheKey].data then
            debugLog("Returning cached data due to global throttling")
            return cache[cacheKey].data
        else
            debugLog("No cached data available, returning fallback")
            return self:generateFallbackKeys(datastoreName)
        end
    end
    
    -- Create cache key for this specific request
    local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":keys"
    local currentTime = tick()
    
    -- Check if we have cached data that's still fresh
    -- Use shorter cache for fallback data to retry getting real data sooner
    local cacheExpiry = cache[cacheKey] and cache[cacheKey].isFallback and 3 or 15  -- 3s for fallback, 15s for real
    if cache[cacheKey] and cache[cacheKey].timestamp and (currentTime - cache[cacheKey].timestamp) < cacheExpiry then
        local dataType = cache[cacheKey].isFallback and "fallback" or "real"
        debugLog("Returning cached " .. dataType .. " keys for " .. datastoreName .. " (age: " .. math.floor(currentTime - cache[cacheKey].timestamp) .. "s)")
        return cache[cacheKey].data
    end
    
    -- Check request throttling - limit one request per 5 seconds per DataStore (increased from 2s)
    local throttleKey = "keys_throttle:" .. datastoreName
    if cache[throttleKey] and cache[throttleKey].timestamp and (currentTime - cache[throttleKey].timestamp) < 5 then
        debugLog("Request throttled for " .. datastoreName .. ", using cached data if available")
        if cache[cacheKey] and cache[cacheKey].data then
            return cache[cacheKey].data
        else
            -- Only return fallback if we've never gotten real data
            local fallbackKeys = self:generateFallbackKeys(datastoreName)
            if #fallbackKeys > 0 then
                debugLog("Returning " .. #fallbackKeys .. " fallback keys for " .. datastoreName)
                return fallbackKeys
            end
            return {}
        end
    end
    
    -- Set throttle marker
    cache[throttleKey] = {timestamp = currentTime}
    
    -- Set global API throttle timestamp to prevent rapid successive calls
    cache[globalThrottleKey] = {timestamp = currentTime}
    debugLog("Setting global API throttle timestamp - no more API calls for 10 seconds")
    
    local startTime = tick()
    local success, result = pcall(function()
        local store = DataStoreService:GetDataStore(datastoreName, scope)
        local keyPages = store:ListKeysAsync()
        local currentPage = keyPages:GetCurrentPage()
        
        local keys = {}
        for _, keyInfo in ipairs(currentPage) do
            table.insert(keys, {
                key = keyInfo.KeyName,
                lastModified = "Unknown", -- DataStoreKey doesn't have UpdatedTime
                hasData = true
            })
            
            if #keys >= maxKeys then
                break
            end
        end
        
        return keys
    end)
    
    -- Track this operation for analytics
    local operationTime = (tick() - startTime) * 1000 -- Convert to ms
    self:trackOperation(success, operationTime)
    
    if success then
        debugLog("✅ Retrieved " .. #result .. " keys for " .. datastoreName)
        
        -- Auto-register this DataStore as real since we got real keys
        if #result > 0 then
            self:registerRealDataStore(datastoreName)
        end
        
        -- Cache the successful result in memory
        cache[cacheKey] = {
            data = result,
            timestamp = currentTime,
            requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1
        }
        
        -- Cache real data in plugin's persistent DataStore for future sessions
        if self.pluginCache and #result > 0 then
            self.pluginCache:cacheDataStoreKeys(datastoreName, result, scope)
        end
        
        return result
    else
        local errorMessage = tostring(result)
        debugLog("Failed to list keys for " .. datastoreName .. ": " .. errorMessage, "ERROR")
        
        -- Check if this is a throttling error
        if errorMessage:find("throttle") or errorMessage:find("budget") or errorMessage:find("rate") then
            debugLog("DataStore throttling detected, providing fallback data for Studio testing", "WARN")
            
            -- Return sample data for Studio testing based on DataStore name
            local fallbackKeys = self:generateFallbackKeys(datastoreName)
            if #fallbackKeys > 0 then
                debugLog("Returning " .. #fallbackKeys .. " fallback keys for " .. datastoreName)
                
                -- Cache the fallback data with shorter expiry
                cache[cacheKey] = {
                    data = fallbackKeys,
                    timestamp = currentTime,
                    requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1,
                    isFallback = true
                }
                
                return fallbackKeys
            end
        end
        
        return {}
    end
end

-- Generate fallback keys for Studio testing when throttled
function DataStoreManager:generateFallbackKeys(datastoreName)
    local fallbackData = {
        PlayerData = {
            {key = "[THROTTLED] StudioTest_001", lastModified = "2024-01-15", hasData = true, isFallback = true},
            {key = "[THROTTLED] StudioTest_002", lastModified = "2024-01-14", hasData = true, isFallback = true},
            {key = "[THROTTLED] StudioTest_003", lastModified = "2024-01-13", hasData = true, isFallback = true},
            {key = "[THROTTLED] StudioTest_004", lastModified = "2024-01-12", hasData = true, isFallback = true},
            {key = "[THROTTLED] StudioTest_005", lastModified = "2024-01-11", hasData = true, isFallback = true}
        },
        PlayerStats = {
            {key = "Stats_123456789", lastModified = "2024-01-15", hasData = true, isReal = true}, -- Your real key
            {key = "[THROTTLED] Stats_002", lastModified = "2024-01-14", hasData = true, isFallback = true},
            {key = "[THROTTLED] Stats_003", lastModified = "2024-01-13", hasData = true, isFallback = true},
            {key = "[THROTTLED] Stats_004", lastModified = "2024-01-12", hasData = true, isFallback = true}
        },
        GameSettings = {
            {key = "ServerConfig", lastModified = "2024-01-15", hasData = true},
            {key = "EventSettings", lastModified = "2024-01-14", hasData = true},
            {key = "GlobalSettings", lastModified = "2024-01-13", hasData = true}
        },
        Inventory = {
            {key = "Inv_123456789", lastModified = "2024-01-15", hasData = true},
            {key = "Inv_987654321", lastModified = "2024-01-14", hasData = true},
            {key = "Inv_555666777", lastModified = "2024-01-13", hasData = true}
        },
        Achievements = {
            {key = "Ach_123456789", lastModified = "2024-01-15", hasData = true},
            {key = "Ach_987654321", lastModified = "2024-01-14", hasData = true}
        }
    }
    
    return fallbackData[datastoreName] or {}
end

-- Generate fallback data for Studio testing when throttled
function DataStoreManager:generateFallbackData(datastoreName, key)
    -- Generate realistic sample data based on DataStore name and key pattern
    if datastoreName == "PlayerData" and key:match("Player_") then
        local playerId = key:match("Player_(%d+)")
        return {
            ["STUDIO_FALLBACK"] = true,
            ["WARNING"] = "This is fallback data for Studio testing - Real DataStore was throttled",
            playerId = tonumber(playerId) or 123456789,
            playerName = "StudioTestPlayer" .. (playerId and playerId:sub(-3) or "123"),
            level = math.random(1, 100),
            experience = math.random(0, 50000),
            coins = math.random(100, 10000),
            joinDate = "2024-01-15T10:30:00Z",
            lastLogin = "2024-01-15T15:45:00Z",
            settings = {
                musicEnabled = true,
                soundEnabled = true,
                difficulty = "Normal"
            },
            ["_metadata"] = {
                dataSource = "Studio Fallback",
                throttled = true,
                timestamp = os.date("%Y-%m-%dT%H:%M:%SZ")
            }
        }
    elseif datastoreName == "PlayerStats" and key:match("Stats_") then
        local playerId = key:match("Stats_(%d+)")
        return {
            ["STUDIO_FALLBACK"] = true,
            ["WARNING"] = "This is fallback data for Studio testing - Real DataStore was throttled",
            playerId = tonumber(playerId) or 123456789,
            stats = {
                gamesPlayed = math.random(1, 500),
                gamesWon = math.random(1, 250),
                totalPlayTime = math.random(3600, 360000), -- 1-100 hours in seconds
                highScore = math.random(1000, 100000),
                achievements = math.random(5, 50)
            },
            rankings = {
                globalRank = math.random(1, 10000),
                seasonRank = math.random(1, 1000),
                weeklyRank = math.random(1, 100)
            },
            lastUpdated = "2024-01-15T15:45:00Z",
            ["_metadata"] = {
                dataSource = "Studio Fallback",
                throttled = true,
                timestamp = os.date("%Y-%m-%dT%H:%M:%SZ")
            }
        }
    elseif datastoreName == "GameSettings" then
        if key == "ServerConfig" then
            return {
                maxPlayers = 50,
                gameMode = "Classic",
                mapRotation = {"Map1", "Map2", "Map3"},
                eventActive = false,
                maintenanceMode = false
            }
        elseif key == "EventSettings" then
            return {
                currentEvent = "Winter Festival",
                eventStart = "2024-01-01T00:00:00Z",
                eventEnd = "2024-01-31T23:59:59Z",
                bonusMultiplier = 2.0,
                specialRewards = true
            }
        end
    end
    
    -- Fallback for unknown patterns
    return {
        ["STUDIO_FALLBACK"] = true,
        ["WARNING"] = "This is fallback data for Studio testing - Real DataStore was throttled",
        sampleData = true,
        message = "This is fallback data for Studio testing",
        datastoreName = datastoreName,
        key = key,
        timestamp = "2024-01-15T15:45:00Z",
        ["_metadata"] = {
            dataSource = "Studio Fallback",
            throttled = true,
            timestamp = os.date("%Y-%m-%dT%H:%M:%SZ")
        }
    }
end

-- Get data info for a specific key with smart caching
function DataStoreManager:getDataInfo(datastoreName, key, scope)
    debugLog("Getting data info for: " .. datastoreName .. " -> " .. key)
    
    -- Fix: Use nil instead of empty string for global scope
    if scope == "" then scope = nil end
    
    -- Check if this is a throttled key that needs refresh
    if key == "[THROTTLED - Click Refresh]" then
        debugLog("🔄 Throttled key selected - attempting to find real data for " .. datastoreName)
        
        -- Try to find real keys by attempting direct access with common key patterns
        local commonKeys = {"Player_" .. game.Players.LocalPlayer.UserId, "default", "global", "data", "config", "settings"}
        
        for _, testKey in ipairs(commonKeys) do
            local refreshResult = self:refreshSingleEntry(datastoreName, testKey, scope)
            
            if refreshResult and refreshResult.success then
                debugLog("✅ Found real data with key: " .. testKey .. " for " .. datastoreName)
                
                return {
                    exists = true,
                    type = type(refreshResult.data),
                    size = type(refreshResult.data) == "string" and #refreshResult.data or 100,
                    preview = type(refreshResult.data) == "string" and string.sub(refreshResult.data, 1, 100) or "Real data found",
                    data = refreshResult.data,
                    metadata = refreshResult.metadata,
                    realKeyFound = testKey  -- Include the real key that was found
                }
            end
        end
        
        -- If no real data found, return throttled message
        return {
            exists = false,
            type = "throttled",
            size = 0,
            preview = "⚠️ API Throttled - No real data found",
            data = {
                THROTTLED = true,
                message = "This DataStore was throttled and no real data could be found with common key patterns.",
                datastoreName = datastoreName,
                canRefresh = true,
                suggestion = "Try using the main refresh button or check if this DataStore has data in your published game."
            },
            metadata = {
                dataSource = "THROTTLED_NO_DATA",
                isReal = false,
                canRefresh = true
            }
        }
    end
    
    -- First, check plugin's persistent cache for real data
    if self.pluginCache then
        local cachedData, cachedMetadata, isFromCache = self.pluginCache:getCachedDataContent(datastoreName, key, scope)
        if isFromCache and cachedData then
            debugLog("🎯 Using cached real data from plugin DataStore for " .. datastoreName .. "/" .. key)
            return {
                exists = true,
                type = type(cachedData),
                size = type(cachedData) == "string" and #cachedData or 100,
                preview = type(cachedData) == "string" and string.sub(cachedData, 1, 100) or "Cached data",
                data = cachedData,
                metadata = cachedMetadata
            }
        end
    end
    
    -- Global API throttling - prevent any API call if last call was too recent
    local globalThrottleKey = "global_api_throttle"
    local currentTime = tick()
    if cache[globalThrottleKey] and cache[globalThrottleKey].timestamp and (currentTime - cache[globalThrottleKey].timestamp) < 10 then
        debugLog("Global API throttling active for getDataInfo - last request " .. string.format("%.1f", currentTime - cache[globalThrottleKey].timestamp) .. "s ago")
        
        -- Return cached data if available, otherwise fallback
        local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":data:" .. key
        if cache[cacheKey] and cache[cacheKey].data then
            debugLog("Returning cached data due to global throttling")
            return cache[cacheKey].data
        else
            debugLog("No cached data available, returning fallback for key: " .. key)
            return {
                exists = true,
                type = "table",
                size = 250,
                preview = "⚠️ FALLBACK DATA (API Throttled)",
                data = self:generateFallbackData(datastoreName, key),
                metadata = {
                    dataSource = "FALLBACK_THROTTLED",
                    isReal = false,
                    canRefresh = true
                }
            }
        end
    end
    
    -- Create cache key for this specific request
    local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":data:" .. key
    
    -- Check if we have cached data that's still fresh (5 seconds for data)
    if cache[cacheKey] and cache[cacheKey].timestamp and (currentTime - cache[cacheKey].timestamp) < 5 then
        debugLog("Returning cached data for " .. key .. " (age: " .. math.floor(currentTime - cache[cacheKey].timestamp) .. "s)")
        return cache[cacheKey].data
    end
    
    -- Check request throttling - limit one data request per 3 seconds per key (increased from 1s)
    local throttleKey = "data_throttle:" .. datastoreName .. ":" .. key
    if cache[throttleKey] and cache[throttleKey].timestamp and (currentTime - cache[throttleKey].timestamp) < 3 then
        debugLog("Data request throttled for " .. key .. ", using cached data if available")
        if cache[cacheKey] and cache[cacheKey].data then
            return cache[cacheKey].data
        else
            -- Only return fallback if we've never gotten real data for this key
            local fallbackData = self:generateFallbackData(datastoreName, key)
            return {
                exists = true,
                type = "table",
                size = 200,
                preview = "⚠️ FALLBACK DATA (Throttled)",
                data = fallbackData,
                metadata = {
                    dataSource = "FALLBACK_THROTTLED",
                    isReal = false,
                    canRefresh = true
                }
            }
        end
    end
    
    -- Set throttle marker
    cache[throttleKey] = {timestamp = currentTime}
    
    -- Set global API throttle timestamp to prevent rapid successive calls
    cache[globalThrottleKey] = {timestamp = currentTime}
    debugLog("Setting global API throttle timestamp for getDataInfo - no more API calls for 10 seconds")
    
    local data, error
    local startTime = tick()
    local success, result = pcall(function()
        local store = DataStoreService:GetDataStore(datastoreName, scope)
        return store:GetAsync(key)
    end)
    
    -- Track this operation for analytics
    local operationTime = (tick() - startTime) * 1000 -- Convert to ms
    self:trackOperation(success, operationTime)
    
    if success then
        if result ~= nil then
            data = result
            debugLog("✅ Successfully retrieved real data for key: " .. key)
            
            -- Auto-register this DataStore as real since we got real data
            self:registerRealDataStore(datastoreName)
            
            -- Cache the successful result in memory
            cache[cacheKey] = {
                data = data,
                timestamp = currentTime,
                requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1,
                isReal = true
            }
            
            -- Cache real data in plugin's persistent DataStore for future sessions
            if self.pluginCache then
                local metadata = {
                    version = 1,
                    timestamp = currentTime,
                    size = type(data) == "string" and #data or 100
                }
                self.pluginCache:cacheDataContent(datastoreName, key, data, metadata, scope)
            end
        else
            debugLog("No data found for key: " .. key .. " (key does not exist)")
            return {
                error = "Key does not exist",
                key = key,
                datastoreName = datastoreName
            }
        end
    else
        error = tostring(result)
        debugLog("Failed to read data: " .. error, "ERROR")
        
        -- Check if this is a throttling error and provide fallback data
        if error:find("throttle") or error:find("budget") or error:find("rate") then
            debugLog("DataStore throttling detected, providing fallback data for key: " .. key, "WARN")
            local fallbackData = self:generateFallbackData(datastoreName, key)
            if fallbackData then
                data = fallbackData
                
                -- Cache the fallback data with shorter expiry and clear marking
                cache[cacheKey] = {
                    data = data,
                    timestamp = currentTime,
                    requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1,
                    isFallback = true,
                    isThrottled = true
                }
            else
                return {
                    exists = false,
                    error = error
                }
            end
        else
            return {
                exists = false,
                error = error
            }
        end
    end
    
    local dataType = type(data)
    local dataSize = 0
    local preview = "No data"
    
    if data then
        if dataType == "string" then
            dataSize = #data
            preview = string.sub(data, 1, 100) .. (string.len(data) > 100 and "..." or "")
        elseif dataType == "table" then
            local jsonSuccess, jsonData = pcall(function()
                return HttpService:JSONEncode(data)
            end)
            
            if jsonSuccess then
                dataSize = #jsonData
                -- Count table fields manually since Utils might not be available
                local fieldCount = 0
                for _ in pairs(data) do
                    fieldCount = fieldCount + 1
                end
                preview = "Table with " .. fieldCount .. " fields"
            else
                preview = "Complex table data"
                dataSize = 100 -- Estimate
            end
        elseif dataType == "number" then
            preview = tostring(data)
            dataSize = #preview

        end
    end
    
    return {
        exists = data ~= nil,
        type = dataType,
        size = dataSize,
        preview = preview,
        data = data
    }
end

-- Track operation statistics
function DataStoreManager:trackOperation(success, latencyMs)
    self.operations.total = self.operations.total + 1
    
    if success then
        self.operations.successful = self.operations.successful + 1
    else
        self.operations.failed = self.operations.failed + 1
    end
    
    -- Track latency for accurate analytics
    if latencyMs then
        if not self.operations.totalLatency then
            self.operations.totalLatency = 0
        end
        self.operations.totalLatency = self.operations.totalLatency + latencyMs
    end
    
    -- Update request budget tracking
    self.requestBudget.read = self.requestBudget.read + 1
    
    -- Reset budget counters every minute
    if tick() - self.requestBudget.lastReset > 60 then
        self.requestBudget = {
            read = 0,
            write = 0,
            list = 0,
            lastReset = tick()
        }
    end
end

-- Clear all throttling (manual override for testing)
function DataStoreManager:clearAllThrottling()
    debugLog("Clearing all throttling - manual override for testing", "WARN")
    
    -- Clear all throttle-related cache entries
    local keysToRemove = {}
    for key, _ in pairs(cache) do
        if key:find("throttle") or key:find("global_api") then
            table.insert(keysToRemove, key)
        end
    end
    
    for _, key in ipairs(keysToRemove) do
        cache[key] = nil
    end
    
    debugLog("Cleared " .. #keysToRemove .. " throttling cache entries")
    debugLog("✅ All throttling cleared - API calls should work normally now")
end

-- Get operation statistics
function DataStoreManager:getStats()
    local runtime = tick() - self.operations.startTime
    local successRate = self.operations.total > 0 and (self.operations.successful / self.operations.total * 100) or 0
    
    -- Calculate real average latency from tracked operations
    local avgLatency = 0
    if self.operations.total > 0 and self.operations.totalLatency then
        avgLatency = self.operations.totalLatency / self.operations.total
    end
    
    return {
        totalOperations = self.operations.total,
        successfulOperations = self.operations.successful,
        failedOperations = self.operations.failed,
        successRate = successRate,
        averageLatency = avgLatency, -- Real average latency in ms
        runtime = runtime,
        requestBudget = self.requestBudget
    }
end

-- Clear caches
function DataStoreManager:clearCache()
    debugLog("Clearing all caches")
    self.dataCache = {}
    self.keyListCache = {}
    debugLog("Caches cleared successfully")
end

-- ========================================
-- ENTERPRISE DATASTORE OPERATIONS
-- ========================================

-- Get key versions with metadata
function DataStoreManager:getKeyVersions(datastoreName, keyName, sortDirection, minDate, maxDate, pageSize)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    sortDirection = sortDirection or Enum.SortDirection.Descending
    pageSize = pageSize or 10
    
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local pages = datastore:ListVersionsAsync(keyName, sortDirection, minDate, maxDate, pageSize)
        
        local versions = {}
        local currentPage = pages:GetCurrentPage()
        
        for _, versionInfo in ipairs(currentPage) do
            table.insert(versions, {
                version = versionInfo.Version,
                createdTime = versionInfo.CreatedTime,
                isDeleted = versionInfo.IsDeleted,
                createdDate = os.date("%Y-%m-%d %H:%M:%S", versionInfo.CreatedTime / 1000)
            })
        end
        
        return {
            versions = versions,
            hasMore = not pages.IsFinished,
            pages = pages
        }
    end)
    
    if success then
        self:logOperation("getKeyVersions", true, 0)
        return {success = true, data = result}
    else
        self:logOperation("getKeyVersions", false, 0)
        return {success = false, error = result}
    end
end

-- Get specific version of a key
function DataStoreManager:getKeyVersion(datastoreName, keyName, version)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local value, keyInfo = datastore:GetVersionAsync(keyName, version)
        
        return {
            value = value,
            version = keyInfo.Version,
            createdTime = keyInfo.CreatedTime,
            updatedTime = keyInfo.UpdatedTime,
            userIds = keyInfo:GetUserIds(),
            metadata = keyInfo:GetMetadata(),
            size = string.len(game:GetService("HttpService"):JSONEncode(value or {}))
        }
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("getKeyVersion", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("getKeyVersion", false, latency)
        return {success = false, error = result}
    end
end

-- Get key version at specific timestamp
function DataStoreManager:getKeyVersionAtTime(datastoreName, keyName, timestamp)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local value, keyInfo = datastore:GetVersionAtTimeAsync(keyName, timestamp)
        
        return {
            value = value,
            version = keyInfo and keyInfo.Version,
            createdTime = keyInfo and keyInfo.CreatedTime,
            updatedTime = keyInfo and keyInfo.UpdatedTime,
            userIds = keyInfo and keyInfo:GetUserIds(),
            metadata = keyInfo and keyInfo:GetMetadata(),
            size = string.len(game:GetService("HttpService"):JSONEncode(value or {}))
        }
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("getKeyVersionAtTime", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("getKeyVersionAtTime", false, latency)
        return {success = false, error = result}
    end
end

-- Remove specific version (enterprise cleanup)
function DataStoreManager:removeKeyVersion(datastoreName, keyName, version)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        datastore:RemoveVersionAsync(keyName, version)
        return true
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("removeKeyVersion", true, latency)
        return {success = true}
    else
        self:logOperation("removeKeyVersion", false, latency)
        return {success = false, error = result}
    end
end

-- Advanced key listing with pagination and filtering
function DataStoreManager:listKeysAdvanced(datastoreName, prefix, pageSize, cursor, excludeDeleted)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    prefix = prefix or ""
    pageSize = pageSize or 50
    excludeDeleted = excludeDeleted or false
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local pages = datastore:ListKeysAsync(prefix, pageSize, cursor, excludeDeleted)
        
        local keys = {}
        local currentPage = pages:GetCurrentPage()
        
        for _, keyInfo in ipairs(currentPage) do
            table.insert(keys, {
                key = keyInfo.KeyName,
                lastModified = keyInfo.LastModified,
                size = keyInfo.Size or 0,
                lastModifiedDate = os.date("%Y-%m-%d %H:%M:%S", (keyInfo.LastModified or 0) / 1000)
            })
        end
        
        return {
            keys = keys,
            hasMore = not pages.IsFinished,
            cursor = pages:GetCurrentPage()[#pages:GetCurrentPage()] and pages:GetCurrentPage()[#pages:GetCurrentPage()].KeyName,
            pages = pages
        }
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("listKeysAdvanced", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("listKeysAdvanced", false, latency)
        return {success = false, error = result}
    end
end

-- Set data with metadata and user tracking (GDPR compliance)
function DataStoreManager:setDataWithMetadata(datastoreName, keyName, value, userIds, metadata)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        
        local setOptions = nil
        if metadata then
            setOptions = Instance.new("DataStoreSetOptions")
            setOptions:SetMetadata(metadata)
        end
        
        local resultValue = datastore:SetAsync(keyName, value, userIds, setOptions)
        return resultValue
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("setDataWithMetadata", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("setDataWithMetadata", false, latency)
        return {success = false, error = result}
    end
end

-- Get data with full metadata (enterprise info)
function DataStoreManager:getDataWithMetadata(datastoreName, keyName, options)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local value, keyInfo = datastore:GetAsync(keyName, options)
        
        return {
            value = value,
            exists = value ~= nil,
            version = keyInfo and keyInfo.Version,
            createdTime = keyInfo and keyInfo.CreatedTime,
            updatedTime = keyInfo and keyInfo.UpdatedTime,
            userIds = keyInfo and keyInfo:GetUserIds() or {},
            metadata = keyInfo and keyInfo:GetMetadata() or {},
            size = value and string.len(game:GetService("HttpService"):JSONEncode(value)) or 0,
            createdDate = keyInfo and keyInfo.CreatedTime and os.date("%Y-%m-%d %H:%M:%S", keyInfo.CreatedTime / 1000),
            updatedDate = keyInfo and keyInfo.UpdatedTime and os.date("%Y-%m-%d %H:%M:%S", keyInfo.UpdatedTime / 1000)
        }
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("getDataWithMetadata", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("getDataWithMetadata", false, latency)
        return {success = false, error = result}
    end
end

-- Update data with metadata preservation
function DataStoreManager:updateDataWithMetadata(datastoreName, keyName, transformFunction)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        
        local function updateCallback(currentValue, keyInfo)
            local newValue, userIds, metadata = transformFunction(currentValue, keyInfo)
            return newValue, userIds or (keyInfo and keyInfo:GetUserIds()), metadata or (keyInfo and keyInfo:GetMetadata())
        end
        
        local updatedValue, keyInfo = datastore:UpdateAsync(keyName, updateCallback)
        
        return {
            value = updatedValue,
            version = keyInfo.Version,
            createdTime = keyInfo.CreatedTime,
            updatedTime = keyInfo.UpdatedTime,
            userIds = keyInfo:GetUserIds(),
            metadata = keyInfo:GetMetadata()
        }
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("updateDataWithMetadata", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("updateDataWithMetadata", false, latency)
        return {success = false, error = result}
    end
end

-- Get compliance report for GDPR/data tracking
function DataStoreManager:getComplianceReport(datastoreName, userId)
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local report = {
            userId = userId,
            datastoreName = datastoreName,
            keys = {},
            totalKeys = 0,
            generatedAt = os.date("%Y-%m-%d %H:%M:%S")
        }
        
        -- List all keys and check for user data
        local pages = datastore:ListKeysAsync("", 100, "", false)
        
        while true do
            local currentPage = pages:GetCurrentPage()
            
            for _, keyInfo in ipairs(currentPage) do
                local value, keyInfoDetails = datastore:GetAsync(keyInfo.KeyName)
                
                if keyInfoDetails then
                    local userIds = keyInfoDetails:GetUserIds()
                    local metadata = keyInfoDetails:GetMetadata()
                    
                    -- Check if this key contains the specified user's data
                    local containsUser = false
                    if userIds then
                        for _, id in ipairs(userIds) do
                            if tostring(id) == tostring(userId) then
                                containsUser = true
                                break
                            end
                        end
                    end
                    
                    if containsUser then
                        table.insert(report.keys, {
                            keyName = keyInfo.KeyName,
                            version = keyInfoDetails.Version,
                            createdTime = keyInfoDetails.CreatedTime,
                            updatedTime = keyInfoDetails.UpdatedTime,
                            userIds = userIds,
                            metadata = metadata,
                            dataSize = value and string.len(game:GetService("HttpService"):JSONEncode(value)) or 0
                        })
                        report.totalKeys = report.totalKeys + 1
                    end
                end
            end
            
            if pages.IsFinished then
                break
            else
                pages:AdvanceToNextPageAsync()
            end
        end
        
        return report
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("getComplianceReport", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("getComplianceReport", false, latency)
        return {success = false, error = result}
    end
end

-- Bulk data export for compliance
function DataStoreManager:exportDataStoreData(datastoreName, options)
    options = options or {}
    local includeMetadata = options.includeMetadata or true
    local includeVersions = options.includeVersions or false
    local prefix = options.prefix or ""
    
    if not self.datastoreService then
        return {success = false, error = "DataStore service not initialized"}
    end
    
    local startTime = tick()
    local success, result = pcall(function()
        local datastore = self.datastoreService:GetDataStore(datastoreName)
        local exportData = {
            datastoreName = datastoreName,
            exportedAt = os.date("%Y-%m-%d %H:%M:%S"),
            totalKeys = 0,
            keys = {}
        }
        
        -- List all keys with optional prefix filter
        local pages = datastore:ListKeysAsync(prefix, 100, "", false)
        
        while true do
            local currentPage = pages:GetCurrentPage()
            
            for _, keyInfo in ipairs(currentPage) do
                local value, keyInfoDetails = datastore:GetAsync(keyInfo.KeyName)
                
                local keyData = {
                    keyName = keyInfo.KeyName,
                    value = value,
                    size = keyInfo.Size or 0
                }
                
                if includeMetadata and keyInfoDetails then
                    keyData.version = keyInfoDetails.Version
                    keyData.createdTime = keyInfoDetails.CreatedTime
                    keyData.updatedTime = keyInfoDetails.UpdatedTime
                    keyData.userIds = keyInfoDetails:GetUserIds()
                    keyData.metadata = keyInfoDetails:GetMetadata()
                end
                
                table.insert(exportData.keys, keyData)
                exportData.totalKeys = exportData.totalKeys + 1
            end
            
            if pages.IsFinished then
                break
            else
                pages:AdvanceToNextPageAsync()
            end
        end
        
        return exportData
    end)
    
    local latency = (tick() - startTime) * 1000
    
    if success then
        self:logOperation("exportDataStoreData", true, latency)
        return {success = true, data = result}
    else
        self:logOperation("exportDataStoreData", false, latency)
        return {success = false, error = result}
    end
end

-- Discover real DataStores using Roblox Open Cloud API
function DataStoreManager:discoverRealDataStores()
    debugLog("🔍 Starting DataStore discovery using Open Cloud API...")
    
    -- DataStore discovery will work in Studio plugins
    
    -- Check discovery cooldown (prevent running too frequently)
    local discoveryKey = "discovery_cooldown"
    local currentTime = tick()
    if cache[discoveryKey] and cache[discoveryKey].timestamp and (currentTime - cache[discoveryKey].timestamp) < 300 then -- 5 minute cooldown
        local waitTime = 300 - (currentTime - cache[discoveryKey].timestamp)
        debugLog("🕒 Discovery on cooldown - last run " .. math.floor(currentTime - cache[discoveryKey].timestamp) .. "s ago (wait " .. math.floor(waitTime) .. "s)")
        return cache[discoveryKey].results or {}
    end
    
    -- Set discovery cooldown
    cache[discoveryKey] = {
        timestamp = currentTime,
        results = {}
    }
    
    -- Try to get the universe ID for this experience
    local universeId = nil
    local success, gameService = pcall(function()
        return game:GetService("GameService")
    end)
    
    if success and gameService then
        local gameSuccess, gameId = pcall(function()
            return game.GameId
        end)
        if gameSuccess and gameId and gameId > 0 then
            universeId = gameId
            debugLog("🌍 Found Universe ID: " .. tostring(universeId))
        end
    end
    
    -- If we can't get universe ID, try alternative methods
    if not universeId then
        local placeSuccess, placeId = pcall(function()
            return game.PlaceId
        end)
        if placeSuccess and placeId and placeId > 0 then
            debugLog("🏠 Found Place ID: " .. tostring(placeId) .. " (will use for DataStore access)")
            -- In Studio/game context, we can still access DataStores even without universe ID
        else
            debugLog("❌ Cannot determine Universe/Place ID - using fallback discovery")
            return self:fallbackDataStoreDiscovery()
        end
    end
    
    -- Try to use DataStoreService to list actual DataStores
    local discoveredDataStores = {}
    
    -- Method 1: Try to access known DataStore patterns and see which ones exist
    local testPatterns = {
        -- Your specific DataStores from screenshot
        "PlayerCurrency", "PlayerData", "PlayerData_v1", "PlayerStats",
        "TimedBuilding", "UniqueItemIds", "WorldData",
        "v2_PlayerCurrency", "v2_WorldData", "v3_PlayerCurrency", 
        "v3_WorldData", "v4_PlayerCurrency", "v4_PlayerData", "v4_WorldData",
        
        -- Common patterns
        "GameSettings", "Leaderboard", "PlayerInventory", "GameData"
    }
    
    debugLog("🔍 Testing " .. #testPatterns .. " potential DataStore names...")
    
    for i, datastoreName in ipairs(testPatterns) do
        if i > 8 then -- Limit to prevent excessive API calls
            debugLog("⚠️ Reached test limit (8), stopping to prevent throttling")
            break
        end
        
        -- Test if DataStore exists by trying to access it
        local testSuccess, hasData = pcall(function()
            local store = DataStoreService:GetDataStore(datastoreName)
            -- Try to list keys to see if DataStore exists and has data
            local keyPages = store:ListKeysAsync()
            local currentPage = keyPages:GetCurrentPage()
            return #currentPage > 0
        end)
        
        if testSuccess then
            if hasData then
                debugLog("✅ Found real DataStore with data: " .. datastoreName)
                table.insert(discoveredDataStores, datastoreName)
                self:registerRealDataStore(datastoreName)
            else
                -- DataStore exists but is empty - still add it
                debugLog("📭 Found real DataStore (empty): " .. datastoreName)
                table.insert(discoveredDataStores, datastoreName)
                self:registerRealDataStore(datastoreName)
            end
        else
            debugLog("❌ DataStore not accessible: " .. datastoreName)
        end
        
        -- Small delay to avoid rapid API calls
        wait(0.2)
    end
    
    debugLog("🎯 Discovery complete: Found " .. #discoveredDataStores .. " real DataStores")
    
    -- Cache the discovery results
    if cache[discoveryKey] then
        cache[discoveryKey].results = discoveredDataStores
    end
    
    return discoveredDataStores
end

-- Fallback discovery method when we can't determine universe ID
function DataStoreManager:fallbackDataStoreDiscovery()
    debugLog("🔄 Using fallback DataStore discovery...")
    
    -- Return your known DataStore names directly
    local knownDataStores = {
        "PlayerCurrency", "PlayerData", "PlayerData_v1", "PlayerStats",
        "TimedBuilding", "UniqueItemIds", "WorldData",
        "v2_PlayerCurrency", "v2_WorldData", "v3_PlayerCurrency", 
        "v3_WorldData", "v4_PlayerCurrency", "v4_PlayerData", "v4_WorldData"
    }
    
    debugLog("📋 Using " .. #knownDataStores .. " known DataStore names")
    return knownDataStores
end

-- Manually register real DataStore names (for when user has real data)
function DataStoreManager:registerRealDataStore(datastoreName)
    if not datastoreName or datastoreName == "" then
        debugLog("Cannot register empty DataStore name", "ERROR")
        return false
    end
    
    debugLog("🎯 Manually registering real DataStore: " .. datastoreName)
    
    -- Get current cached DataStore names
    local currentNames = self:getDataStoreNames()
    
    -- Check if already exists
    for _, name in ipairs(currentNames) do
        if name == datastoreName then
            debugLog("DataStore " .. datastoreName .. " already registered")
            return true
        end
    end
    
    -- Add to the list
    table.insert(currentNames, 1, datastoreName) -- Add at beginning for priority
    
    -- Update memory cache
    local cacheKey = "datastore_names"
    cache[cacheKey] = {
        data = currentNames,
        timestamp = tick(),
        requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1,
        hasRealData = true -- Mark as containing real data
    }
    
    -- Update plugin's persistent cache
    if self.pluginCache then
        self.pluginCache:cacheDataStoreNames(currentNames)
        debugLog("✅ Real DataStore " .. datastoreName .. " cached persistently")
    end
    
    debugLog("✅ Successfully registered real DataStore: " .. datastoreName)
    return true
end

-- Add specific DataStore names to discovery (for user's known DataStores)
function DataStoreManager:addKnownDataStores(datastoreNames)
    if type(datastoreNames) == "string" then
        datastoreNames = {datastoreNames}
    end
    
    debugLog("📝 Adding " .. #datastoreNames .. " known DataStore names")
    
    for _, datastoreName in ipairs(datastoreNames) do
        debugLog("🎯 Testing known DataStore: " .. datastoreName)
        
        -- Try to access the DataStore to verify it exists
        local success, hasData = pcall(function()
            local store = DataStoreService:GetDataStore(datastoreName)
            local keyPages = store:ListKeysAsync()
            local currentPage = keyPages:GetCurrentPage()
            return #currentPage > 0
        end)
        
        if success then
            if hasData then
                debugLog("✅ Confirmed real DataStore with data: " .. datastoreName)
            else
                debugLog("📭 Confirmed real DataStore (empty): " .. datastoreName)
            end
            
            -- Register this as a real DataStore
            self:registerRealDataStore(datastoreName)
        else
            debugLog("❌ Could not access DataStore: " .. datastoreName)
        end
        
        wait(0.1) -- Small delay to avoid rapid API calls
    end
    
    debugLog("✅ Finished adding known DataStores")
end

-- Disable automatic discovery (for performance)
function DataStoreManager:disableAutoDiscovery()
    debugLog("🚫 Disabling automatic DataStore discovery")
    cache["auto_discovery_disabled"] = {
        timestamp = tick(),
        disabled = true
    }
end

-- Enable automatic discovery
function DataStoreManager:enableAutoDiscovery()
    debugLog("✅ Enabling automatic DataStore discovery")
    cache["auto_discovery_disabled"] = nil
end

-- Check if auto discovery is disabled
function DataStoreManager:isAutoDiscoveryDisabled()
    return cache["auto_discovery_disabled"] and cache["auto_discovery_disabled"].disabled
end

-- Clear all caches and force refresh (for testing)
function DataStoreManager:clearAllCaches()
    debugLog("🧹 Clearing all caches")
    
    -- Clear memory cache
    local clearedCount = 0
    for key, _ in pairs(cache) do
        cache[key] = nil
        clearedCount = clearedCount + 1
    end
    
    -- Clear plugin cache if available
    if self.pluginCache and self.pluginCache.clearAllCache then
        self.pluginCache:clearAllCache()
    end
    
    debugLog("✅ Cleared " .. clearedCount .. " cache entries")
    return clearedCount
end

-- Force refresh DataStore names (clears cache and reloads)
function DataStoreManager:forceRefresh()
    debugLog("🔄 Force refreshing DataStore Manager...")
    
    -- Clear all caches
    self:clearAllCaches()
    
    -- Force reload DataStore names
    local newNames = self:getDataStoreNames()
    debugLog("✅ Force refresh completed - loaded " .. #newNames .. " DataStore names")
    
    return newNames
end

-- Get DataStore entries using proper Roblox API approach
function DataStoreManager:getDataStoreEntries(datastoreName, scope, maxKeys)
    debugLog("🔍 Getting entries for DataStore: " .. datastoreName .. " using proper API")
    
    maxKeys = maxKeys or 50
    -- Fix: Use nil instead of empty string for global scope
    if scope == "" then scope = nil end
    
    -- First, check plugin's persistent cache for real data
    if self.pluginCache then
        local cachedKeys, isFromCache = self.pluginCache:getCachedDataStoreKeys(datastoreName, scope)
        if isFromCache and cachedKeys then
            debugLog("🎯 Using cached real keys from plugin DataStore for " .. datastoreName)
            -- Format cached keys with real data markers
            local formattedKeys = {}
            for _, keyName in ipairs(cachedKeys) do
                table.insert(formattedKeys, {
                    key = keyName,
                    lastModified = "Real DataStore (Cached)",
                    hasData = true,
                    isReal = true,
                    dataSource = "CACHED_REAL"
                })
            end
            return formattedKeys
        end
    end
    
    -- Check if this is one of your known real DataStores
    local knownRealDataStores = {
        "PlayerCurrency", "PlayerData", "PlayerData_v1", "PlayerStats", 
        "TimedBuilding", "UniqueItemIds", "WorldData",
        "v2_PlayerCurrency", "v2_WorldData", "v3_PlayerCurrency", "v3_WorldData",
        "v4_PlayerCurrency", "v4_PlayerData", "v4_WorldData"
    }
    
    local isRealDataStore = false
    for _, realName in ipairs(knownRealDataStores) do
        if datastoreName == realName then
            isRealDataStore = true
            break
        end
    end
    
    if isRealDataStore then
        debugLog("🎯 Attempting to access real DataStore: " .. datastoreName)
        
        -- Try to get the actual DataStore
        local success, datastore = pcall(function()
            return game:GetService("DataStoreService"):GetDataStore(datastoreName, scope)
        end)
        
        if success and datastore then
            -- Try to list keys with throttling protection
            local keySuccess, keyResult = pcall(function()
                return datastore:ListKeysAsync()
            end)
            
            if keySuccess and keyResult then
                local keys = {}
                local pages = keyResult
                
                -- Get first page of keys
                local pageSuccess, pageItems = pcall(function()
                    return pages:GetCurrentPage()
                end)
                
                if pageSuccess and pageItems then
                    for _, keyInfo in ipairs(pageItems) do
                        table.insert(keys, {
                            key = keyInfo.KeyName,
                            lastModified = "Real DataStore",
                            hasData = true,
                            isReal = true,
                            dataSource = "LIVE_REAL"
                        })
                        if #keys >= maxKeys then break end
                    end
                    
                    if #keys > 0 then
                        debugLog("✅ Successfully retrieved " .. #keys .. " real keys from " .. datastoreName)
                        
                        -- Cache the real keys (extract just the key names for caching)
                        if self.pluginCache then
                            local keyNames = {}
                            for _, keyData in ipairs(keys) do
                                table.insert(keyNames, keyData.key)
                            end
                            self.pluginCache:cacheDataStoreKeys(datastoreName, scope, keyNames)
                        end
                        
                        return keys
                    end
                end
            end
            
            -- If we get here, the DataStore exists but ListKeysAsync was throttled or failed
            debugLog("⚠️ Real DataStore " .. datastoreName .. " was throttled - providing fallback with refresh option")
            return {{
                key = "[THROTTLED - Click Refresh]",
                lastModified = "API Throttled",
                hasData = false,
                isReal = false,
                dataSource = "THROTTLED",
                canRefresh = true
            }}
        end
    else
        debugLog("⚠️ " .. datastoreName .. " is not a known real DataStore - using fallback")
        return nil -- Let caller handle fallback
    end
    
    return nil
end

-- Refresh a single DataStore entry (bypasses throttling by targeting one specific key)
function DataStoreManager:refreshSingleEntry(datastoreName, key, scope)
    debugLog("🔄 Refreshing single entry: " .. datastoreName .. "/" .. key)
    
    -- Fix: Use nil instead of empty string for global scope
    if scope == "" then scope = nil end
    
    -- Clear any cached data for this specific key
    local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":data:" .. key
    cache[cacheKey] = nil
    
    -- Try to get the actual data from DataStore
    local success, datastore = pcall(function()
        return game:GetService("DataStoreService"):GetDataStore(datastoreName, scope)
    end)
    
    if success and datastore then
        local dataSuccess, result = pcall(function()
            return datastore:GetAsync(key)
        end)
        
        if dataSuccess then
            if result ~= nil then
                debugLog("✅ Successfully refreshed real data for " .. datastoreName .. "/" .. key)
                
                -- Cache the real data
                cache[cacheKey] = {
                    data = result,
                    timestamp = tick(),
                    isReal = true,
                    dataSource = "REFRESHED_REAL"
                }
                
                -- Also cache in plugin DataStore
                if self.pluginCache then
                    local metadata = {
                        version = 1,
                        timestamp = tick(),
                        size = type(result) == "string" and #result or 100,
                        dataSource = "REFRESHED_REAL"
                    }
                    self.pluginCache:cacheDataContent(datastoreName, key, result, metadata, scope)
                end
                
                return {
                    success = true,
                    data = result,
                    metadata = {
                        dataSource = "REFRESHED_REAL",
                        isReal = true,
                        timestamp = os.date("%Y-%m-%dT%H:%M:%SZ"),
                        datastoreName = datastoreName,
                        key = key
                    }
                }
            else
                debugLog("⚠️ Key " .. key .. " does not exist in " .. datastoreName)
                return {
                    success = false,
                    error = "Key does not exist",
                    metadata = {
                        dataSource = "REAL_EMPTY",
                        isReal = true,
                        datastoreName = datastoreName,
                        key = key
                    }
                }
            end
        else
            local errorMsg = tostring(result)
            debugLog("❌ Failed to refresh " .. datastoreName .. "/" .. key .. ": " .. errorMsg)
            return {
                success = false,
                error = errorMsg,
                metadata = {
                    dataSource = "REFRESH_FAILED",
                    isReal = false,
                    datastoreName = datastoreName,
                    key = key
                }
            }
        end
    else
        debugLog("❌ Could not access DataStore: " .. datastoreName)
        return {
            success = false,
            error = "Could not access DataStore",
            metadata = {
                dataSource = "ACCESS_FAILED",
                isReal = false,
                datastoreName = datastoreName,
                key = key
            }
        }
    end
end

-- Clear throttling for refresh attempts
function DataStoreManager:clearThrottling()
    debugLog("🚫 Clearing throttling for refresh attempt")
    
    -- Clear global throttling
    cache["global_api_throttle"] = nil
    
    -- Clear discovery throttling
    cache["discovery_cooldown"] = nil
    
    -- Clear any data throttling
    for key, _ in pairs(cache) do
        if key:match("data_throttle:") or key:match("_throttle") then
            cache[key] = nil
        end
    end
    
    debugLog("✅ Throttling cleared - refresh should work now")
end

return DataStoreManager 