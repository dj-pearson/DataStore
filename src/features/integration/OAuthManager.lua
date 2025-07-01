-- DataStore Manager Pro - Safe Data Store Operations
-- Compliant data operations for Roblox DataStores only

local DataStoreOperations = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

local debugLog = Utils.debugLog

-- Safe DataStore configuration
local DATASTORE_CONFIG = {
    OPERATIONS = {
        READ_ONLY = true, -- Safe viewing of data
        BACKUP_ENABLED = true,
        VALIDATION_REQUIRED = true
    },
    LIMITS = {
        MAX_KEY_SIZE = 50, -- characters
        MAX_DATA_SIZE = 4194304, -- 4MB Roblox limit
        REQUEST_BUDGET_THRESHOLD = 5
    },
    SECURITY = {
        VALIDATE_ALL_INPUTS = true,
        LOG_ALL_OPERATIONS = true,
        REQUIRE_CONFIRMATION = true
    }
}

-- Safe operations state
local operationsState = {
    availableStores = {},
    recentOperations = {},
    validationRules = {},
    initialized = false
}

-- Initialize safe DataStore operations
function DataStoreOperations.initialize()
    debugLog("Initializing safe DataStore operations...")
    
    -- Initialize validation rules
    DataStoreOperations.initializeValidation()
    
    -- Set up operation logging
    DataStoreOperations.initializeLogging()
    
    operationsState.initialized = true
    debugLog("Safe DataStore operations initialized")
    
    return true
end

-- Initialize data validation
function DataStoreOperations.initializeValidation()
    operationsState.validationRules = {
        keyValidation = function(key)
            if type(key) ~= "string" then
                return false, "Key must be a string"
            end
            if #key > DATASTORE_CONFIG.LIMITS.MAX_KEY_SIZE then
                return false, "Key too long (max " .. DATASTORE_CONFIG.LIMITS.MAX_KEY_SIZE .. " characters)"
            end
            if key:match("[^%w_%-]") then
                return false, "Key contains invalid characters (use only letters, numbers, _, -)"
            end
            return true
        end,
        
        dataValidation = function(data)
            local success, jsonStr = pcall(function()
                return game:GetService("HttpService"):JSONEncode(data)
            end)
            
            if not success then
                return false, "Data is not JSON serializable"
            end
            
            if #jsonStr > DATASTORE_CONFIG.LIMITS.MAX_DATA_SIZE then
                return false, "Data too large (max 4MB)"
            end
            
            return true
        end
    }
    
    debugLog("Data validation rules initialized")
end

-- Initialize operation logging
function DataStoreOperations.initializeLogging()
    operationsState.recentOperations = {}
    debugLog("Operation logging initialized")
end

-- Safely get available DataStores
function DataStoreOperations.getAvailableStores()
    -- Return only safe, local DataStore names for viewing
    return {
        "PlayerData",
        "GameSettings", 
        "UserPreferences",
        "Leaderboards",
        "Achievements"
    }
end

-- Safely read data from DataStore
function DataStoreOperations.safeReadData(datastoreName, key)
    -- Validate inputs
    local valid, error = operationsState.validationRules.keyValidation(key)
    if not valid then
        return false, error
    end
    
    -- Check request budget
    local budget = game:GetService("DataStoreService"):GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
    if budget < DATASTORE_CONFIG.LIMITS.REQUEST_BUDGET_THRESHOLD then
        return false, "Insufficient request budget"
    end
    
    -- Safe data reading with proper error handling
    local success, result = pcall(function()
        local datastore = game:GetService("DataStoreService"):GetDataStore(datastoreName)
        return datastore:GetAsync(key)
    end)
    
    -- Log operation
    table.insert(operationsState.recentOperations, {
        operation = "READ",
        datastore = datastoreName,
        key = key,
        success = success,
        timestamp = os.time()
    })
    
    if success then
        debugLog("Successfully read data from " .. datastoreName .. "/" .. key)
        return true, result
    else
        debugLog("Failed to read data: " .. tostring(result))
        return false, result
    end
end

-- Get recent operations log
function DataStoreOperations.getOperationLog()
    return operationsState.recentOperations
end

-- Get operation statistics
function DataStoreOperations.getOperationStats()
    local total = #operationsState.recentOperations
    local successful = 0
    
    for _, op in ipairs(operationsState.recentOperations) do
        if op.success then
            successful = successful + 1
        end
    end
    
    return {
        total = total,
        successful = successful,
        failed = total - successful,
        successRate = total > 0 and (successful / total * 100) or 0
    }
end

return DataStoreOperations
