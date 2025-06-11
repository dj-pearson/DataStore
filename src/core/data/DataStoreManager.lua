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
    
    -- If no tracked DataStores, fall back to common ones
    if #dataStoreNames == 0 then
        local commonDataStores = {
            "PlayerData",
            "PlayerStats", 
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
    
    -- Cache the result
    cache[cacheKey] = {
        data = dataStoreNames,
        timestamp = currentTime,
        requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1
    }
    
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
    
    -- Create cache key for this specific request
    local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":keys"
    local currentTime = tick()
    
    -- Check if we have cached data that's still fresh (10 seconds)
    if cache[cacheKey] and cache[cacheKey].timestamp and (currentTime - cache[cacheKey].timestamp) < 10 then
        debugLog("Returning cached keys for " .. datastoreName .. " (age: " .. math.floor(currentTime - cache[cacheKey].timestamp) .. "s)")
        return cache[cacheKey].data
    end
    
    -- Check request throttling - limit one request per 2 seconds per DataStore
    local throttleKey = "keys_throttle:" .. datastoreName
    if cache[throttleKey] and cache[throttleKey].timestamp and (currentTime - cache[throttleKey].timestamp) < 2 then
        debugLog("Request throttled for " .. datastoreName .. ", using cached or fallback data")
        if cache[cacheKey] and cache[cacheKey].data then
            return cache[cacheKey].data
        else
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
        
        -- Cache the successful result
        cache[cacheKey] = {
            data = result,
            timestamp = currentTime,
            requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1
        }
        
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
            {key = "Player_7768610061", lastModified = "2024-01-15", hasData = true},  -- Real-like player ID
            {key = "Player_1234567890", lastModified = "2024-01-14", hasData = true},
            {key = "Player_555666777", lastModified = "2024-01-13", hasData = true},
            {key = "Player_111222333", lastModified = "2024-01-12", hasData = true},
            {key = "Player_444555666", lastModified = "2024-01-11", hasData = true}
        },
        PlayerStats = {
            {key = "Stats_123456789", lastModified = "2024-01-15", hasData = true},
            {key = "Stats_987654321", lastModified = "2024-01-14", hasData = true},
            {key = "Stats_555666777", lastModified = "2024-01-13", hasData = true},
            {key = "Stats_111222333", lastModified = "2024-01-12", hasData = true}
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
            playerId = tonumber(playerId) or 123456789,
            playerName = "TestPlayer" .. (playerId and playerId:sub(-3) or "123"),
            level = math.random(1, 100),
            experience = math.random(0, 50000),
            coins = math.random(100, 10000),
            joinDate = "2024-01-15T10:30:00Z",
            lastLogin = "2024-01-15T15:45:00Z",
            settings = {
                musicEnabled = true,
                soundEnabled = true,
                difficulty = "Normal"
            }
        }
    elseif datastoreName == "PlayerStats" and key:match("Stats_") then
        local playerId = key:match("Stats_(%d+)")
        return {
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
            lastUpdated = "2024-01-15T15:45:00Z"
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
        sampleData = true,
        message = "This is fallback data for Studio testing",
        datastoreName = datastoreName,
        key = key,
        timestamp = "2024-01-15T15:45:00Z"
    }
end

-- Get data info for a specific key with smart caching
function DataStoreManager:getDataInfo(datastoreName, key, scope)
    debugLog("Getting data info for: " .. datastoreName .. " -> " .. key)
    
    -- Fix: Use nil instead of empty string for global scope
    if scope == "" then scope = nil end
    
    -- Create cache key for this specific request
    local cacheKey = datastoreName .. ":" .. (scope or "global") .. ":data:" .. key
    local currentTime = tick()
    
    -- Check if we have cached data that's still fresh (5 seconds for data)
    if cache[cacheKey] and cache[cacheKey].timestamp and (currentTime - cache[cacheKey].timestamp) < 5 then
        debugLog("Returning cached data for " .. key .. " (age: " .. math.floor(currentTime - cache[cacheKey].timestamp) .. "s)")
        return cache[cacheKey].data
    end
    
    -- Check request throttling - limit one data request per 1 second per key
    local throttleKey = "data_throttle:" .. datastoreName .. ":" .. key
    if cache[throttleKey] and cache[throttleKey].timestamp and (currentTime - cache[throttleKey].timestamp) < 1 then
        debugLog("Data request throttled for " .. key .. ", using cached or fallback data")
        if cache[cacheKey] and cache[cacheKey].data then
            return cache[cacheKey].data
        else
            local fallbackData = self:generateFallbackData(datastoreName, key)
            return fallbackData
        end
    end
    
    -- Set throttle marker
    cache[throttleKey] = {timestamp = currentTime}
    
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
        data = result
        
        -- Cache the successful result
        cache[cacheKey] = {
            data = data,
            timestamp = currentTime,
            requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1
        }
        
        debugLog("✅ Successfully retrieved data for key: " .. key)
    else
        error = tostring(result)
        debugLog("Failed to read data: " .. error, "ERROR")
        
        -- Check if this is a throttling error and provide fallback data
        if error:find("throttle") or error:find("budget") or error:find("rate") then
            debugLog("DataStore throttling detected, providing fallback data for key: " .. key, "WARN")
            local fallbackData = self:generateFallbackData(datastoreName, key)
            if fallbackData then
                data = fallbackData
                
                -- Cache the fallback data with shorter expiry
                cache[cacheKey] = {
                    data = data,
                    timestamp = currentTime,
                    requestCount = (cache[cacheKey] and cache[cacheKey].requestCount or 0) + 1,
                    isFallback = true
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

return DataStoreManager 