-- DataStore Manager Pro - Comprehensive Error Handler
-- Implements Reliability-First principle with user-friendly error management

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local ErrorHandler = {}

-- Error categories and user-friendly messages
local ERROR_CATEGORIES = {
    DATASTORE_API = {
        name = "DataStore API",
        icon = "🔧",
        description = "Issues with Roblox DataStore service"
    },
    NETWORK = {
        name = "Network",
        icon = "📡",
        description = "Connection or request timeout issues"
    },
    DATA_VALIDATION = {
        name = "Data Validation",
        icon = "✅",
        description = "Data format or size validation errors"
    },
    PERMISSIONS = {
        name = "Permissions",
        icon = "🔒",
        description = "Access or authorization issues"
    },
    PLUGIN = {
        name = "Plugin",
        icon = "🔌",
        description = "Internal plugin errors"
    },
    USER_INPUT = {
        name = "User Input",
        icon = "⌨️",
        description = "Invalid user input or configuration"
    }
}

-- Known error patterns and solutions
local ERROR_PATTERNS = {
    ["502: API Services rejected request"] = {
        category = "DATASTORE_API",
        userMessage = "DataStore service is temporarily unavailable",
        suggestion = "Please wait a moment and try again. This is usually temporary.",
        canRetry = true,
        retryDelay = 5
    },
    ["104: Cannot write to DataStore from studio"] = {
        category = "DATASTORE_API", 
        userMessage = "DataStore access is disabled in Studio",
        suggestion = "Enable 'Allow HTTP Requests' and 'Enable Studio Access to API Services' in Game Settings.",
        canRetry = false,
        fixInstructions = {
            "Go to Game Settings → Security",
            "Enable 'Allow HTTP Requests'",
            "Enable 'Enable Studio Access to API Services'",
            "Restart Studio and try again"
        }
    },
    ["Request was throttled"] = {
        category = "DATASTORE_API",
        userMessage = "Too many requests - API limit reached",
        suggestion = "Please wait before making more requests. Consider reducing operation frequency.",
        canRetry = true,
        retryDelay = 10
    },
    ["Data too large"] = {
        category = "DATA_VALIDATION",
        userMessage = "Data exceeds 4MB size limit",
        suggestion = "Break down large data into smaller chunks or compress the data.",
        canRetry = false
    },
    ["Key name too long"] = {
        category = "DATA_VALIDATION", 
        userMessage = "Key name exceeds 50 character limit",
        suggestion = "Use shorter, descriptive key names (max 50 characters).",
        canRetry = false
    },
    ["Invalid JSON"] = {
        category = "DATA_VALIDATION",
        userMessage = "Data contains invalid JSON format",
        suggestion = "Check for special characters or circular references in your data.",
        canRetry = false
    }
}

function ErrorHandler.initialize()
    print("[ERROR_HANDLER] [INFO] Error Handler initialized with user-friendly error management")
    return true
end

-- Main error handling function
function ErrorHandler.handleError(error, context)
    context = context or {}
    
    local errorInfo = ErrorHandler.analyzeError(error, context)
    
    -- Log the error with full details
    print(string.format("[ERROR_HANDLER] [ERROR] Error handled: %s [%s]", errorInfo.userMessage, errorInfo.category.name))
    
    -- Return structured error information
    return {
        success = false,
        error = errorInfo,
        timestamp = os.time(),
        context = context
    }
end

-- Analyze error and provide user-friendly information
function ErrorHandler.analyzeError(error, context)
    local errorString = tostring(error)
    local errorInfo = {
        originalError = errorString,
        category = ERROR_CATEGORIES.PLUGIN, -- Default category
        userMessage = "An unexpected error occurred",
        suggestion = "Please try again or contact support if the issue persists.",
        canRetry = true,
        retryDelay = 1,
        severity = "medium",
        fixInstructions = nil
    }
    
    -- Check against known error patterns
    for pattern, info in pairs(ERROR_PATTERNS) do
        if string.find(errorString, pattern, 1, true) then
            errorInfo.category = ERROR_CATEGORIES[info.category]
            errorInfo.userMessage = info.userMessage
            errorInfo.suggestion = info.suggestion
            errorInfo.canRetry = info.canRetry
            errorInfo.retryDelay = info.retryDelay or 1
            errorInfo.fixInstructions = info.fixInstructions
            errorInfo.severity = info.severity or "medium"
            break
        end
    end
    
    -- Context-specific adjustments
    if context.operation then
        errorInfo.operation = context.operation
        errorInfo.userMessage = string.format("%s during %s operation", errorInfo.userMessage, context.operation)
    end
    
    if context.dataStore then
        errorInfo.dataStore = context.dataStore
    end
    
    if context.key then
        errorInfo.key = context.key
    end
    
    return errorInfo
end

-- Create user-friendly error message
function ErrorHandler.formatUserMessage(errorInfo)
    local message = string.format("%s %s", errorInfo.category.icon, errorInfo.userMessage)
    
    if errorInfo.suggestion then
        message = message .. "\n\n💡 " .. errorInfo.suggestion
    end
    
    if errorInfo.fixInstructions then
        message = message .. "\n\n🔧 How to fix:\n"
        for i, instruction in ipairs(errorInfo.fixInstructions) do
            message = message .. string.format("%d. %s\n", i, instruction)
        end
    end
    
    if errorInfo.canRetry then
        message = message .. string.format("\n🔄 You can retry this operation in %d seconds.", errorInfo.retryDelay)
    end
    
    return message
end

-- Safe operation wrapper with automatic retry
function ErrorHandler.safeOperation(operation, maxRetries, context)
    maxRetries = maxRetries or 3
    context = context or {}
    
    for attempt = 1, maxRetries do
        local success, result = pcall(operation)
        
        if success then
            return true, result
        else
            local errorInfo = ErrorHandler.analyzeError(result, context)
            
            -- Check if we should retry
            if attempt < maxRetries and errorInfo.canRetry then
                print(string.format("[ERROR_HANDLER] [WARN] Retry attempt %d/%d after error: %s", attempt, maxRetries, errorInfo.userMessage))
                -- Safe wait function
                local wait_func = rawget(_G, "wait")
                if wait_func then
                    wait_func(errorInfo.retryDelay)
                else
                    local startTime = os.clock()
                    while os.clock() - startTime < errorInfo.retryDelay do end
                end
            else
                -- Final failure
                return false, ErrorHandler.handleError(result, context)
            end
        end
    end
    
    return false, ErrorHandler.handleError("Max retries exceeded", context)
end

-- Operation recovery suggestions
function ErrorHandler.getRecoverySuggestions(errorInfo)
    local suggestions = {}
    
    if errorInfo.category == ERROR_CATEGORIES.DATASTORE_API then
        table.insert(suggestions, {
            icon = "⚙️",
            title = "Check Game Settings",
            description = "Verify DataStore API access is enabled",
            action = "open_settings"
        })
        
        table.insert(suggestions, {
            icon = "🔄",
            title = "Retry Operation",
            description = "Try the operation again after a short wait",
            action = "retry"
        })
    end
    
    if errorInfo.category == ERROR_CATEGORIES.DATA_VALIDATION then
        table.insert(suggestions, {
            icon = "📏",
            title = "Check Data Size",
            description = "Ensure data is under 4MB limit",
            action = "validate_data"
        })
        
        table.insert(suggestions, {
            icon = "🔍",
            title = "Inspect Data Format",
            description = "Verify JSON structure is valid",
            action = "inspect_data"
        })
    end
    
    if errorInfo.category == ERROR_CATEGORIES.NETWORK then
        table.insert(suggestions, {
            icon = "📡",
            title = "Check Connection",
            description = "Verify internet connectivity",
            action = "check_connection"
        })
    end
    
    return suggestions
end

-- Get error statistics for analytics
function ErrorHandler.getErrorStatistics()
    -- This would integrate with your analytics system
    return {
        totalErrors = 0,
        errorsByCategory = {},
        errorsByOperation = {},
        mostCommonErrors = {},
        averageRecoveryTime = 0
    }
end

-- Create error report for support
function ErrorHandler.createErrorReport(errorInfo)
    return {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        category = errorInfo.category.name,
        userMessage = errorInfo.userMessage,
        originalError = errorInfo.originalError,
        context = errorInfo.context or {},
        canRetry = errorInfo.canRetry,
        severity = errorInfo.severity,
        pluginVersion = Constants.PLUGIN_VERSION or "unknown",
        studioVersion = "unknown" -- Studio version detection not available in plugin context
    }
end

function ErrorHandler.cleanup()
    print("[ERROR_HANDLER] [INFO] Error Handler cleanup complete")
end

return ErrorHandler 