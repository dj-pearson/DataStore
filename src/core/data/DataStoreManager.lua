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
        startTime = tick()
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

-- Get list of DataStore names (limited to common ones since Roblox doesn't provide enumeration)
function DataStoreManager:getDataStoreNames()
    debugLog("Getting DataStore names")
    
    -- Since Roblox doesn't provide a way to enumerate all DataStores,
    -- we'll return a list of common DataStore names that developers typically use
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
    
    -- For now, just return the common DataStore names for exploration
    -- In a production environment, you could implement tracking of which DataStores are actually used
    debugLog("Returning " .. #commonDataStores .. " common DataStore names for exploration")
    return commonDataStores
end

-- Get keys for a specific DataStore
function DataStoreManager:getDataStoreKeys(datastoreName, scope, maxKeys)
    debugLog("Getting keys for DataStore: " .. datastoreName)
    
    maxKeys = maxKeys or 50
    scope = scope or ""
    
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
    
    if success then
        debugLog("Retrieved " .. #result .. " keys for " .. datastoreName)
        return result
    else
        debugLog("Failed to list keys for " .. datastoreName .. ": " .. tostring(result), "ERROR")
        return {}
    end
end

-- Get data info for a specific key
function DataStoreManager:getDataInfo(datastoreName, key, scope)
    debugLog("Getting data info for: " .. datastoreName .. " -> " .. key)
    
    local data, error
    local success, result = pcall(function()
        local store = DataStoreService:GetDataStore(datastoreName, scope or "")
        return store:GetAsync(key)
    end)
    
    if success then
        data = result
    else
        error = tostring(result)
        debugLog("Failed to read data: " .. error, "ERROR")
        return {
            exists = false,
            error = error
        }
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
function DataStoreManager:trackOperation(success)
    self.operations.total = self.operations.total + 1
    
    if success then
        self.operations.successful = self.operations.successful + 1
    else
        self.operations.failed = self.operations.failed + 1
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
    local avgLatency = runtime / math.max(self.operations.total, 1) * 1000 -- ms
    
    return {
        totalOperations = self.operations.total,
        successfulOperations = self.operations.successful,
        failedOperations = self.operations.failed,
        successRate = successRate,
        averageLatency = avgLatency,
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

return DataStoreManager 