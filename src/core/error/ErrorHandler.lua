-- DataStore Manager Pro - Error Handler
-- Centralized error management with detailed tracking and reporting

local ErrorHandler = {}

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

-- Local state
local errorLog = {}
local errorStats = {}
local errorCallbacks = {}
local initialized = false

-- Error severity levels
local SEVERITY_LEVELS = {
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    CRITICAL = 4
}

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[ERROR_HANDLER] [%s] %s", level, message))
end

-- Get severity level from error code
local function getSeverityLevel(errorCode)
    -- DataStore errors
    if errorCode:match("^DS") then
        if errorCode == Constants.ERRORS.DATASTORE_QUOTA_EXCEEDED then
            return SEVERITY_LEVELS.HIGH
        elseif errorCode == Constants.ERRORS.DATASTORE_ACCESS_DENIED then
            return SEVERITY_LEVELS.CRITICAL
        else
            return SEVERITY_LEVELS.MEDIUM
        end
    end
    
    -- UI errors
    if errorCode:match("^UI") then
        return SEVERITY_LEVELS.LOW
    end
    
    -- License errors
    if errorCode:match("^LIC") then
        return SEVERITY_LEVELS.HIGH
    end
    
    -- General errors
    if errorCode:match("^GEN") then
        return SEVERITY_LEVELS.CRITICAL
    end
    
    return SEVERITY_LEVELS.MEDIUM
end

-- Get suggested actions for error codes
local function getSuggestedActions(errorCode)
    local actions = {
        [Constants.ERRORS.DATASTORE_QUOTA_EXCEEDED] = {
            "Wait for request budget to refill",
            "Reduce operation frequency",
            "Implement request queuing"
        },
        [Constants.ERRORS.DATASTORE_ACCESS_DENIED] = {
            "Check if Studio has DataStore access enabled",
            "Verify game is published",
            "Check team access permissions"
        },
        [Constants.ERRORS.DATASTORE_DATA_TOO_LARGE] = {
            "Reduce data size",
            "Split large objects into smaller chunks",
            "Use compression if applicable"
        },
        [Constants.ERRORS.LICENSE_INVALID] = {
            "Check license key format",
            "Verify purchase status",
            "Contact support if issue persists"
        },
        [Constants.ERRORS.LICENSE_EXPIRED] = {
            "Renew license subscription",
            "Check billing information",
            "Contact support for extension"
        },
        [Constants.ERRORS.UI_COMPONENT_FAILED] = {
            "Restart plugin",
            "Check Studio version compatibility",
            "Clear plugin cache"
        }
    }
    
    return actions[errorCode] or {
        "Check plugin console for details",
        "Restart the plugin",
        "Contact support if issue persists"
    }
end

-- Initialize error handler
function ErrorHandler.initialize()
    if initialized then
        debugLog("Error handler already initialized")
        return true
    end
    
    debugLog("Initializing error handling system")
    
    -- Initialize stats
    errorStats = {
        totalErrors = 0,
        errorsByCode = {},
        errorsBySeverity = {
            [SEVERITY_LEVELS.LOW] = 0,
            [SEVERITY_LEVELS.MEDIUM] = 0,
            [SEVERITY_LEVELS.HIGH] = 0,
            [SEVERITY_LEVELS.CRITICAL] = 0
        },
        lastReset = Utils.Time.getCurrentTimestamp()
    }
    
    initialized = true
    debugLog("Error handling system initialized successfully")
    return true
end

-- Create structured error information
function ErrorHandler.createError(code, message, context, severity)
    local errorInfo = {
        id = Utils.UI.createGUID(),
        code = code or Constants.ERRORS.UNKNOWN,
        message = message or "An unknown error occurred",
        context = context or {},
        severity = severity or getSeverityLevel(code or Constants.ERRORS.UNKNOWN),
        timestamp = Utils.Time.getCurrentTimestamp(),
        stack = debug.traceback(),
        suggestedActions = getSuggestedActions(code or Constants.ERRORS.UNKNOWN),
        resolved = false,
        reportedByUser = false
    }
    
    return errorInfo
end

-- Log an error
function ErrorHandler.logError(code, message, context, severity)
    if not initialized then
        debugLog("Error handler not initialized", "ERROR")
        return nil
    end
    
    local errorInfo = ErrorHandler.createError(code, message, context, severity)
    
    -- Add to error log
    table.insert(errorLog, errorInfo)
    
    -- Maintain log size
    if #errorLog > Constants.LOGGING.MAX_LOG_ENTRIES then
        table.remove(errorLog, 1)
    end
    
    -- Update statistics
    errorStats.totalErrors = errorStats.totalErrors + 1
    errorStats.errorsByCode[errorInfo.code] = (errorStats.errorsByCode[errorInfo.code] or 0) + 1
    errorStats.errorsBySeverity[errorInfo.severity] = errorStats.errorsBySeverity[errorInfo.severity] + 1
    
    -- Log to console based on severity
    local logLevel = "INFO"
    if errorInfo.severity >= SEVERITY_LEVELS.HIGH then
        logLevel = "ERROR"
    elseif errorInfo.severity >= SEVERITY_LEVELS.MEDIUM then
        logLevel = "WARN"
    end
    
    debugLog(string.format(
        "Error logged [%s]: %s - %s", 
        errorInfo.code, 
        errorInfo.message,
        errorInfo.id
    ), logLevel)
    
    -- Trigger callbacks
    for _, callback in ipairs(errorCallbacks) do
        local success, err = pcall(callback, errorInfo)
        if not success then
            debugLog("Error callback failed: " .. tostring(err), "ERROR")
        end
    end
    
    -- Auto-resolve low severity errors after some time
    if errorInfo.severity == SEVERITY_LEVELS.LOW then
        spawn(function()
            wait(300) -- 5 minutes
            ErrorHandler.resolveError(errorInfo.id)
        end)
    end
    
    return errorInfo
end

-- Handle caught exceptions
function ErrorHandler.handleException(exception, operation, context)
    local errorCode = Constants.ERRORS.UNKNOWN
    local message = tostring(exception)
    
    -- Try to determine error code from exception message
    if message:find("budget") or message:find("quota") then
        errorCode = Constants.ERRORS.DATASTORE_QUOTA_EXCEEDED
    elseif message:find("access") or message:find("permission") then
        errorCode = Constants.ERRORS.DATASTORE_ACCESS_DENIED
    elseif message:find("too large") or message:find("size") then
        errorCode = Constants.ERRORS.DATASTORE_DATA_TOO_LARGE
    elseif message:find("key") then
        errorCode = Constants.ERRORS.DATASTORE_KEY_NOT_FOUND
    end
    
    local fullContext = Utils.Table.merge({
        operation = operation,
        originalError = exception
    }, context or {})
    
    return ErrorHandler.logError(errorCode, message, fullContext)
end

-- Resolve an error
function ErrorHandler.resolveError(errorId, resolution)
    if not initialized then
        debugLog("Error handler not initialized", "ERROR")
        return false
    end
    
    for _, error in ipairs(errorLog) do
        if error.id == errorId then
            error.resolved = true
            error.resolvedAt = Utils.Time.getCurrentTimestamp()
            error.resolution = resolution or "Manually resolved"
            
            debugLog("Error resolved: " .. errorId)
            return true
        end
    end
    
    debugLog("Error not found for resolution: " .. errorId, "WARN")
    return false
end

-- Get error by ID
function ErrorHandler.getError(errorId)
    if not initialized then
        return nil
    end
    
    for _, error in ipairs(errorLog) do
        if error.id == errorId then
            return error
        end
    end
    
    return nil
end

-- Get recent errors
function ErrorHandler.getRecentErrors(count, severityFilter)
    if not initialized then
        return {}
    end
    
    count = count or 10
    local recentErrors = {}
    
    -- Get errors in reverse chronological order
    for i = #errorLog, math.max(1, #errorLog - count + 1), -1 do
        local error = errorLog[i]
        
        if not severityFilter or error.severity >= severityFilter then
            table.insert(recentErrors, error)
        end
        
        if #recentErrors >= count then
            break
        end
    end
    
    return recentErrors
end

-- Get unresolved errors
function ErrorHandler.getUnresolvedErrors(severityFilter)
    if not initialized then
        return {}
    end
    
    local unresolved = {}
    
    for _, error in ipairs(errorLog) do
        if not error.resolved and (not severityFilter or error.severity >= severityFilter) then
            table.insert(unresolved, error)
        end
    end
    
    return unresolved
end

-- Get error statistics
function ErrorHandler.getStatistics()
    if not initialized then
        return {}
    end
    
    local stats = Utils.Table.deepCopy(errorStats)
    stats.unresolvedCount = #ErrorHandler.getUnresolvedErrors()
    stats.criticalCount = #ErrorHandler.getUnresolvedErrors(SEVERITY_LEVELS.CRITICAL)
    stats.highPriorityCount = #ErrorHandler.getUnresolvedErrors(SEVERITY_LEVELS.HIGH)
    
    return stats
end

-- Clear resolved errors
function ErrorHandler.clearResolvedErrors()
    if not initialized then
        debugLog("Error handler not initialized", "ERROR")
        return false
    end
    
    local originalCount = #errorLog
    local newLog = {}
    
    for _, error in ipairs(errorLog) do
        if not error.resolved then
            table.insert(newLog, error)
        end
    end
    
    errorLog = newLog
    local clearedCount = originalCount - #errorLog
    
    debugLog("Cleared " .. clearedCount .. " resolved errors")
    return clearedCount
end

-- Export error log
function ErrorHandler.exportErrorLog(format)
    if not initialized then
        return nil
    end
    
    format = format or "json"
    
    local exportData = {
        exportedAt = Utils.Time.getCurrentTimestamp(),
        statistics = ErrorHandler.getStatistics(),
        errors = errorLog
    }
    
    if format == "json" then
        return Utils.JSON.encode(exportData, true)
    elseif format == "csv" then
        -- Simple CSV export
        local csv = "ID,Code,Message,Severity,Timestamp,Resolved\n"
        for _, error in ipairs(errorLog) do
            csv = csv .. string.format(
                "%s,%s,%s,%d,%s,%s\n",
                error.id,
                error.code,
                error.message:gsub(",", ";"), -- Escape commas
                error.severity,
                Utils.Time.formatTimestamp(error.timestamp),
                error.resolved and "Yes" or "No"
            )
        end
        return csv
    end
    
    return nil
end

-- Register error callback
function ErrorHandler.onError(callback)
    if not callback or type(callback) ~= "function" then
        debugLog("Invalid callback provided", "ERROR")
        return false
    end
    
    table.insert(errorCallbacks, callback)
    debugLog("Error callback registered")
    return true
end

-- Safe execution wrapper
function ErrorHandler.safeExecute(operation, func, ...)
    local args = {...}
    local success, result = pcall(func, unpack(args))
    
    if success then
        return result
    else
        ErrorHandler.handleException(result, operation, {
            arguments = args
        })
        return nil
    end
end

-- Reset error statistics
function ErrorHandler.resetStatistics()
    if not initialized then
        debugLog("Error handler not initialized", "ERROR")
        return false
    end
    
    errorStats = {
        totalErrors = 0,
        errorsByCode = {},
        errorsBySeverity = {
            [SEVERITY_LEVELS.LOW] = 0,
            [SEVERITY_LEVELS.MEDIUM] = 0,
            [SEVERITY_LEVELS.HIGH] = 0,
            [SEVERITY_LEVELS.CRITICAL] = 0
        },
        lastReset = Utils.Time.getCurrentTimestamp()
    }
    
    debugLog("Error statistics reset")
    return true
end

-- Cleanup
function ErrorHandler.cleanup()
    if not initialized then
        return
    end
    
    debugLog("Cleaning up error handling system")
    
    -- Log final statistics
    local stats = ErrorHandler.getStatistics()
    debugLog(string.format(
        "Final error stats - Total: %d, Unresolved: %d, Critical: %d",
        stats.totalErrors,
        stats.unresolvedCount,
        stats.criticalCount
    ))
    
    errorLog = {}
    errorStats = {}
    errorCallbacks = {}
    initialized = false
    
    debugLog("Error handling cleanup complete")
end

-- Export severity levels for external use
ErrorHandler.SEVERITY = SEVERITY_LEVELS

return ErrorHandler 