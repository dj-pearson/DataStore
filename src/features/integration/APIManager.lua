-- DataStore Manager Pro - Safe Data Export/Import System
-- Local data serialization and backup without external APIs

local DataExportManager = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)
local HttpService = game:GetService("HttpService") -- Only for JSON operations

-- Safe export configuration
local EXPORT_CONFIG = {
    FORMATS = {
        JSON = "json",
        CSV = "csv",
        TXT = "txt"
    },
    LIMITS = {
        MAX_EXPORT_SIZE = 10485760, -- 10MB
        MAX_KEYS_PER_EXPORT = 1000,
        VALIDATION_REQUIRED = true
    },
    SAFETY = {
        SANITIZE_DATA = true,
        LOG_OPERATIONS = true,
        REQUIRE_CONFIRMATION = true
    }
}

-- Export state
local exportState = {
    recentExports = {},
    exportHistory = {},
    validationRules = {},
    initialized = false
}

function DataExportManager.initialize()
    print("[DATA_EXPORT] [INFO] Initializing safe data export system...")
    
    -- Initialize validation
    DataExportManager.initializeValidation()
    
    -- Set up export logging
    DataExportManager.initializeLogging()
    
    exportState.initialized = true
    print("[DATA_EXPORT] [INFO] Safe data export system initialized")
    
    return true
end

-- Initialize data validation for exports
function DataExportManager.initializeValidation()
    exportState.validationRules = {
        validateExportData = function(data)
            local success, jsonStr = pcall(function()
                return HttpService:JSONEncode(data)
            end)
            
            if not success then
                return false, "Data cannot be serialized to JSON"
            end
            
            if #jsonStr > EXPORT_CONFIG.LIMITS.MAX_EXPORT_SIZE then
                return false, "Export data too large (max 10MB)"
            end
            
            return true, jsonStr
        end,
        
        sanitizeData = function(data)
            -- Remove any potentially sensitive information
            if type(data) == "table" then
                local sanitized = {}
                for key, value in pairs(data) do
                    if type(key) == "string" and not key:lower():match("password") and not key:lower():match("secret") then
                        sanitized[key] = type(value) == "table" and DataExportManager.sanitizeData(value) or value
                    end
                end
                return sanitized
            end
            return data
        end
    }
    
    print("[DATA_EXPORT] [INFO] Export validation rules initialized")
end

-- Initialize export logging
function DataExportManager.initializeLogging()
    exportState.recentExports = {}
    exportState.exportHistory = {}
    print("[DATA_EXPORT] [INFO] Export logging initialized")
end

-- Safely export DataStore data to JSON
function DataExportManager.exportDataStoreToJSON(datastoreName, keys, options)
    options = options or {}
    
    if #keys > EXPORT_CONFIG.LIMITS.MAX_KEYS_PER_EXPORT then
        return false, "Too many keys to export (max " .. EXPORT_CONFIG.LIMITS.MAX_KEYS_PER_EXPORT .. ")"
    end
    
    local exportData = {
        metadata = {
            datastoreName = datastoreName,
            exportTime = os.time(),
            keyCount = #keys,
            format = "DataStoreManagerPro_Export_v1"
        },
        data = {}
    }
    
    -- Export each key safely
    for _, key in ipairs(keys) do
        local success, data = pcall(function()
            local datastore = game:GetService("DataStoreService"):GetDataStore(datastoreName)
            return datastore:GetAsync(key)
        end)
        
        if success and data ~= nil then
            -- Sanitize data if required
            if EXPORT_CONFIG.SAFETY.SANITIZE_DATA then
                data = exportState.validationRules.sanitizeData(data)
            end
            
            exportData.data[key] = data
        end
    end
    
    -- Validate export data
    local valid, result = exportState.validationRules.validateExportData(exportData)
    if not valid then
        return false, result
    end
    
    -- Log export operation
    table.insert(exportState.recentExports, {
        datastore = datastoreName,
        keyCount = #keys,
        success = true,
        timestamp = os.time()
    })
    
    return true, result
end

-- Get export statistics
function DataExportManager.getExportStats()
    local total = #exportState.recentExports
    local successful = 0
    
    for _, export in ipairs(exportState.recentExports) do
        if export.success then
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

-- Format data for display
function DataExportManager.formatDataForDisplay(data)
    if type(data) == "table" then
        local success, formatted = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        return success and formatted or "Invalid data format"
    end
    return tostring(data)
end

return DataExportManager 