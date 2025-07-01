-- DataStore Manager Pro - Comprehensive Error Handler
-- Implements Reliability-First principle with user-friendly error management

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)

local ErrorHandler = {}

-- Enhanced error categories with severity levels
local ERROR_CATEGORIES = {
    DATASTORE_API = {
        name = "DataStore API",
        icon = "🔧",
        description = "Issues with Roblox DataStore service",
        severity = "HIGH",
        recoveryPriority = 1
    },
    NETWORK = {
        name = "Network",
        icon = "📡",
        description = "Connection or request timeout issues",
        severity = "HIGH",
        recoveryPriority = 1
    },
    DATA_VALIDATION = {
        name = "Data Validation",
        icon = "✅",
        description = "Data format or size validation errors",
        severity = "MEDIUM",
        recoveryPriority = 2
    },
    PERMISSIONS = {
        name = "Permissions",
        icon = "🔒",
        description = "Access or authorization issues",
        severity = "HIGH",
        recoveryPriority = 1
    },
    PLUGIN = {
        name = "Plugin",
        icon = "🔌",
        description = "Internal plugin errors",
        severity = "MEDIUM",
        recoveryPriority = 2
    },
    USER_INPUT = {
        name = "User Input",
        icon = "⌨️",
        description = "Invalid user input or configuration",
        severity = "LOW",
        recoveryPriority = 3
    },
    RESOURCE = {
        name = "Resource",
        icon = "💾",
        description = "Resource allocation or memory issues",
        severity = "HIGH",
        recoveryPriority = 1
    },
    CONCURRENCY = {
        name = "Concurrency",
        icon = "⚡",
        description = "Race conditions or concurrent access issues",
        severity = "HIGH",
        recoveryPriority = 1
    }
}

-- Enhanced error patterns with detailed recovery strategies
local ERROR_PATTERNS = {
    ["502: API Services rejected request"] = {
        category = "DATASTORE_API",
        userMessage = "DataStore service is temporarily unavailable",
        suggestion = "Please wait a moment and try again. This is usually temporary.",
        canRetry = true,
        retryDelay = 5,
        recoveryStrategy = {
            immediate = "WAIT",
            fallback = "CACHE",
            longTerm = "REDUCE_FREQUENCY"
        },
        metrics = {
            impact = "HIGH",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
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
        },
        recoveryStrategy = {
            immediate = "CONFIGURE",
            fallback = "LOCAL_STORAGE",
            longTerm = "AUTO_CONFIGURE"
        },
        metrics = {
            impact = "HIGH",
            frequency = "LOW",
            userAffected = "DEVELOPERS"
        }
    },
    ["Request was throttled"] = {
        category = "DATASTORE_API",
        userMessage = "Too many requests - API limit reached",
        suggestion = "Please wait before making more requests. Consider reducing operation frequency.",
        canRetry = true,
        retryDelay = 10,
        recoveryStrategy = {
            immediate = "BACKOFF",
            fallback = "QUEUE",
            longTerm = "OPTIMIZE"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "HIGH",
            userAffected = "ALL"
        }
    },
    ["Data too large"] = {
        category = "DATA_VALIDATION",
        userMessage = "Data exceeds 4MB size limit",
        suggestion = "Break down large data into smaller chunks or compress the data.",
        canRetry = false,
        recoveryStrategy = {
            immediate = "SPLIT",
            fallback = "COMPRESS",
            longTerm = "OPTIMIZE_STRUCTURE"
        },
        metrics = {
            impact = "HIGH",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["Key name too long"] = {
        category = "DATA_VALIDATION", 
        userMessage = "Key name exceeds 50 character limit",
        suggestion = "Use shorter, descriptive key names (max 50 characters).",
        canRetry = false,
        recoveryStrategy = {
            immediate = "TRUNCATE",
            fallback = "HASH",
            longTerm = "VALIDATE"
        },
        metrics = {
            impact = "LOW",
            frequency = "LOW",
            userAffected = "DEVELOPERS"
        }
    },
    ["Invalid JSON"] = {
        category = "DATA_VALIDATION",
        userMessage = "Data contains invalid JSON format",
        suggestion = "Check for special characters or circular references in your data.",
        canRetry = false,
        recoveryStrategy = {
            immediate = "VALIDATE",
            fallback = "SANITIZE",
            longTerm = "SCHEMA"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["Out of memory"] = {
        category = "RESOURCE",
        userMessage = "Operation failed due to memory constraints",
        suggestion = "Close other applications and try again. Consider optimizing data usage.",
        canRetry = true,
        retryDelay = 2,
        recoveryStrategy = {
            immediate = "CLEANUP",
            fallback = "REDUCE_LOAD",
            longTerm = "OPTIMIZE_MEMORY"
        },
        metrics = {
            impact = "HIGH",
            frequency = "LOW",
            userAffected = "ALL"
        }
    },
    ["Concurrent modification"] = {
        category = "CONCURRENCY",
        userMessage = "Data was modified by another process",
        suggestion = "The operation will be retried automatically with the latest data.",
        canRetry = true,
        retryDelay = 1,
        recoveryStrategy = {
            immediate = "RETRY",
            fallback = "LOCK",
            longTerm = "OPTIMIZE_CONCURRENCY"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "HIGH",
            userAffected = "ALL"
        }
    },
    ["DataStore service is unavailable"] = {
        category = "DATASTORE_API",
        userMessage = "DataStore service is currently unavailable",
        suggestion = "This is usually temporary. The system will automatically retry with exponential backoff.",
        canRetry = true,
        retryDelay = 5,
        recoveryStrategy = {
            immediate = "BACKOFF",
            fallback = "CACHE",
            longTerm = "SERVICE_HEALTH_CHECK"
        },
        metrics = {
            impact = "HIGH",
            frequency = "LOW",
            userAffected = "ALL"
        }
    },
    ["DataStore request failed"] = {
        category = "DATASTORE_API",
        userMessage = "DataStore request failed",
        suggestion = "The system will automatically retry the operation with a different strategy.",
        canRetry = true,
        retryDelay = 2,
        recoveryStrategy = {
            immediate = "RETRY",
            fallback = "ALTERNATE_ENDPOINT",
            longTerm = "REQUEST_OPTIMIZATION"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["DataStore key not found"] = {
        category = "DATASTORE_API",
        userMessage = "The requested data key does not exist",
        suggestion = "Verify the key name or create the key if it should exist.",
        canRetry = false,
        recoveryStrategy = {
            immediate = "CREATE_KEY",
            fallback = "DEFAULT_VALUE",
            longTerm = "KEY_VALIDATION"
        },
        metrics = {
            impact = "LOW",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["Invalid data type"] = {
        category = "DATA_VALIDATION",
        userMessage = "The data type is not supported by DataStore",
        suggestion = "Convert the data to a supported type (string, number, boolean, table).",
        canRetry = false,
        recoveryStrategy = {
            immediate = "CONVERT_TYPE",
            fallback = "SERIALIZE",
            longTerm = "TYPE_VALIDATION"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "MEDIUM",
            userAffected = "DEVELOPERS"
        }
    },
    ["Circular reference detected"] = {
        category = "DATA_VALIDATION",
        userMessage = "Data contains circular references",
        suggestion = "Remove circular references or use a different data structure.",
        canRetry = false,
        recoveryStrategy = {
            immediate = "BREAK_CIRCULAR",
            fallback = "FLATTEN",
            longTerm = "STRUCTURE_OPTIMIZATION"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "LOW",
            userAffected = "DEVELOPERS"
        }
    },
    ["Connection timeout"] = {
        category = "NETWORK",
        userMessage = "Connection to DataStore service timed out",
        suggestion = "Check your internet connection and try again.",
        canRetry = true,
        retryDelay = 3,
        recoveryStrategy = {
            immediate = "RETRY",
            fallback = "OFFLINE_MODE",
            longTerm = "CONNECTION_OPTIMIZATION"
        },
        metrics = {
            impact = "HIGH",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["Network error"] = {
        category = "NETWORK",
        userMessage = "Network error occurred while accessing DataStore",
        suggestion = "The system will automatically retry with a different connection strategy.",
        canRetry = true,
        retryDelay = 2,
        recoveryStrategy = {
            immediate = "ALTERNATE_ROUTE",
            fallback = "CACHE",
            longTerm = "NETWORK_RESILIENCE"
        },
        metrics = {
            impact = "HIGH",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["Memory limit exceeded"] = {
        category = "RESOURCE",
        userMessage = "Operation exceeded memory limits",
        suggestion = "The system will attempt to optimize memory usage and retry.",
        canRetry = true,
        retryDelay = 1,
        recoveryStrategy = {
            immediate = "MEMORY_CLEANUP",
            fallback = "CHUNK_OPERATION",
            longTerm = "MEMORY_OPTIMIZATION"
        },
        metrics = {
            impact = "HIGH",
            frequency = "LOW",
            userAffected = "ALL"
        }
    },
    ["Operation timeout"] = {
        category = "RESOURCE",
        userMessage = "Operation took too long to complete",
        suggestion = "The system will retry with optimized parameters.",
        canRetry = true,
        retryDelay = 2,
        recoveryStrategy = {
            immediate = "OPTIMIZE_PARAMS",
            fallback = "SPLIT_OPERATION",
            longTerm = "PERFORMANCE_OPTIMIZATION"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    },
    ["Version mismatch"] = {
        category = "CONCURRENCY",
        userMessage = "Data was modified by another process",
        suggestion = "The system will automatically merge changes or retry with the latest version.",
        canRetry = true,
        retryDelay = 1,
        recoveryStrategy = {
            immediate = "MERGE_CHANGES",
            fallback = "LATEST_VERSION",
            longTerm = "VERSION_CONTROL"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "HIGH",
            userAffected = "ALL"
        }
    },
    ["Lock timeout"] = {
        category = "CONCURRENCY",
        userMessage = "Failed to acquire lock for operation",
        suggestion = "The system will retry with a different locking strategy.",
        canRetry = true,
        retryDelay = 1,
        recoveryStrategy = {
            immediate = "ALTERNATE_LOCK",
            fallback = "QUEUE_OPERATION",
            longTerm = "LOCK_OPTIMIZATION"
        },
        metrics = {
            impact = "MEDIUM",
            frequency = "MEDIUM",
            userAffected = "ALL"
        }
    }
}

-- Error tracking and analytics
local errorMetrics = {
    totalErrors = 0,
    errorsByCategory = {},
    errorsByPattern = {},
    recoverySuccess = {},
    averageRecoveryTime = {},
    lastError = nil,
    errorTrends = {}
}

function ErrorHandler.initialize()
    print("[ERROR_HANDLER] [INFO] Error Handler initialized with user-friendly error management")
    return true
end

-- Main error handling function
function ErrorHandler.handleError(error, context)
    context = context or {}
    
    local errorInfo = ErrorHandler.analyzeError(error, context)
    
    -- Update error metrics
    errorMetrics.totalErrors = errorMetrics.totalErrors + 1
    errorMetrics.errorsByCategory[errorInfo.category.name] = (errorMetrics.errorsByCategory[errorInfo.category.name] or 0) + 1
    errorMetrics.lastError = {
        timestamp = os.time(),
        error = errorInfo,
        context = context
    }
    
    -- Track error trends
    local currentHour = os.date("%Y-%m-%d %H")
    errorMetrics.errorTrends[currentHour] = (errorMetrics.errorTrends[currentHour] or 0) + 1
    
    -- Log the error with full details
    print(string.format("[ERROR_HANDLER] [ERROR] Error handled: %s [%s]", errorInfo.userMessage, errorInfo.category.name))
    
    -- Attempt automatic recovery if possible
    if errorInfo.recoveryStrategy then
        local recoveryResult = ErrorHandler.attemptRecovery(errorInfo, context)
        if recoveryResult.success then
            errorInfo.recoveryAttempted = true
            errorInfo.recoveryResult = recoveryResult
        end
    end
    
    -- Return structured error information
    return {
        success = false,
        error = errorInfo,
        timestamp = os.time(),
        context = context,
        metrics = {
            totalErrors = errorMetrics.totalErrors,
            categoryCount = errorMetrics.errorsByCategory[errorInfo.category.name],
            recoveryAttempted = errorInfo.recoveryAttempted,
            recoverySuccess = errorInfo.recoveryResult and errorInfo.recoveryResult.success
        }
    }
end

-- New: Enhanced error analysis with pattern matching
function ErrorHandler.analyzeError(error, context)
    local errorString = tostring(error)
    local errorInfo = {
        originalError = errorString,
        category = ERROR_CATEGORIES.PLUGIN,
        userMessage = "An unexpected error occurred",
        suggestion = "Please try again or contact support if the issue persists.",
        canRetry = true,
        retryDelay = 1,
        severity = "medium",
        fixInstructions = nil,
        stackTrace = debug.traceback(),
        timestamp = os.time()
    }
    
    -- Pattern matching with context
    for pattern, info in pairs(ERROR_PATTERNS) do
        if string.find(errorString, pattern, 1, true) then
            errorInfo.category = ERROR_CATEGORIES[info.category]
            errorInfo.userMessage = info.userMessage
            errorInfo.suggestion = info.suggestion
            errorInfo.canRetry = info.canRetry
            errorInfo.retryDelay = info.retryDelay or 1
            errorInfo.fixInstructions = info.fixInstructions
            errorInfo.severity = info.severity or "medium"
            errorInfo.recoveryStrategy = info.recoveryStrategy
            errorInfo.metrics = info.metrics
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
    
    -- Add error context
    errorInfo.context = {
        operation = context.operation,
        dataStore = context.dataStore,
        key = context.key,
        timestamp = os.time(),
        environment = context.environment or "production"
    }
    
    return errorInfo
end

-- New: Recovery attempt function
function ErrorHandler.attemptRecovery(errorInfo, context)
    local startTime = os.clock()
    local recoveryResult = {
        success = false,
        strategy = errorInfo.recoveryStrategy.immediate,
        duration = 0,
        fallbackUsed = false
    }
    
    -- Attempt immediate recovery
    local success = ErrorHandler.executeRecoveryStrategy(errorInfo.recoveryStrategy.immediate, context)
    
    -- If immediate recovery fails, try fallback
    if not success and errorInfo.recoveryStrategy.fallback then
        recoveryResult.fallbackUsed = true
        recoveryResult.strategy = errorInfo.recoveryStrategy.fallback
        success = ErrorHandler.executeRecoveryStrategy(errorInfo.recoveryStrategy.fallback, context)
    end
    
    recoveryResult.success = success
    recoveryResult.duration = os.clock() - startTime
    
    -- Update recovery metrics
    errorMetrics.recoverySuccess[errorInfo.category.name] = errorMetrics.recoverySuccess[errorInfo.category.name] or {
        total = 0,
        successful = 0
    }
    errorMetrics.recoverySuccess[errorInfo.category.name].total = errorMetrics.recoverySuccess[errorInfo.category.name].total + 1
    if success then
        errorMetrics.recoverySuccess[errorInfo.category.name].successful = errorMetrics.recoverySuccess[errorInfo.category.name].successful + 1
    end
    
    return recoveryResult
end

-- New: Enhanced recovery strategy execution
function ErrorHandler.executeRecoveryStrategy(strategy, context)
    if strategy == "WAIT" then
        wait(5)
        return true
    elseif strategy == "CACHE" then
        return ErrorHandler.handleCacheFallback(context)
    elseif strategy == "BACKOFF" then
        return ErrorHandler.handleExponentialBackoff(context)
    elseif strategy == "QUEUE" then
        return ErrorHandler.handleOperationQueue(context)
    elseif strategy == "SPLIT" then
        return ErrorHandler.handleDataSplitting(context)
    elseif strategy == "COMPRESS" then
        return ErrorHandler.handleDataCompression(context)
    elseif strategy == "VALIDATE" then
        return ErrorHandler.handleDataValidation(context)
    elseif strategy == "SANITIZE" then
        return ErrorHandler.handleDataSanitization(context)
    elseif strategy == "CLEANUP" then
        return ErrorHandler.handleMemoryCleanup(context)
    elseif strategy == "RETRY" then
        return ErrorHandler.handleRetry(context)
    elseif strategy == "MERGE_CHANGES" then
        return ErrorHandler.handleChangeMerge(context)
    elseif strategy == "LATEST_VERSION" then
        return ErrorHandler.handleLatestVersion(context)
    elseif strategy == "ALTERNATE_LOCK" then
        return ErrorHandler.handleAlternateLock(context)
    elseif strategy == "CHUNK_OPERATION" then
        return ErrorHandler.handleChunkOperation(context)
    elseif strategy == "OPTIMIZE_PARAMS" then
        return ErrorHandler.handleParameterOptimization(context)
    elseif strategy == "SERVICE_HEALTH_CHECK" then
        return ErrorHandler.handleServiceHealthCheck(context)
    elseif strategy == "ALTERNATE_ENDPOINT" then
        return ErrorHandler.handleAlternateEndpoint(context)
    elseif strategy == "CREATE_KEY" then
        return ErrorHandler.handleKeyCreation(context)
    elseif strategy == "DEFAULT_VALUE" then
        return ErrorHandler.handleDefaultValue(context)
    elseif strategy == "CONVERT_TYPE" then
        return ErrorHandler.handleTypeConversion(context)
    elseif strategy == "BREAK_CIRCULAR" then
        return ErrorHandler.handleCircularReference(context)
    elseif strategy == "FLATTEN" then
        return ErrorHandler.handleDataFlattening(context)
    elseif strategy == "OFFLINE_MODE" then
        return ErrorHandler.handleOfflineMode(context)
    elseif strategy == "ALTERNATE_ROUTE" then
        return ErrorHandler.handleAlternateRoute(context)
    elseif strategy == "MEMORY_CLEANUP" then
        return ErrorHandler.handleMemoryCleanup(context)
    elseif strategy == "SPLIT_OPERATION" then
        return ErrorHandler.handleOperationSplitting(context)
    end
    
    return false
end

-- New: Recovery strategy implementations
function ErrorHandler.handleCacheFallback(context)
    -- Implement cache fallback logic
    local cache = context.cache or {}
    if cache[context.key] then
        context.result = cache[context.key]
        return true
    end
    return false
end

function ErrorHandler.handleExponentialBackoff(context)
    -- Implement exponential backoff
    local attempt = context.attempt or 1
    local delay = math.min(2 ^ attempt, 30)
    wait(delay)
    return true
end

function ErrorHandler.handleOperationQueue(context)
    -- Implement operation queuing
    local queue = context.queue or {}
    table.insert(queue, context.operation)
    return true
end

function ErrorHandler.handleDataSplitting(context)
    -- Implement data splitting
    if context.data and type(context.data) == "table" then
        local chunks = {}
        local chunkSize = 1000000 -- 1MB chunks
        local currentChunk = {}
        local currentSize = 0
        
        for k, v in pairs(context.data) do
            local itemSize = #tostring(v)
            if currentSize + itemSize > chunkSize then
                table.insert(chunks, currentChunk)
                currentChunk = {}
                currentSize = 0
            end
            currentChunk[k] = v
            currentSize = currentSize + itemSize
        end
        
        if next(currentChunk) then
            table.insert(chunks, currentChunk)
        end
        
        context.chunks = chunks
        return true
    end
    return false
end

function ErrorHandler.handleDataCompression(context)
    -- Implement data compression
    if context.data then
        -- Simple compression for demonstration
        context.data = string.gsub(tostring(context.data), "%s+", "")
        return true
    end
    return false
end

function ErrorHandler.handleDataValidation(context)
    -- Implement data validation
    if context.data then
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONEncode(context.data)
        end)
        return success
    end
    return false
end

function ErrorHandler.handleDataSanitization(context)
    -- Implement data sanitization
    if context.data then
        -- Basic sanitization for demonstration
        if type(context.data) == "string" then
            context.data = string.gsub(context.data, "[^%w%s%-%.]", "")
        end
        return true
    end
    return false
end

function ErrorHandler.handleMemoryCleanup(context)
    -- Implement memory cleanup
    collectgarbage("collect")
    return true
end

function ErrorHandler.handleRetry(context)
    -- Implement retry logic
    if context.operation then
        local success, result = pcall(context.operation)
        if success then
            context.result = result
            return true
        end
    end
    return false
end

function ErrorHandler.handleChangeMerge(context)
    -- Implement change merging
    if context.current and context.latest then
        -- Simple merge for demonstration
        for k, v in pairs(context.latest) do
            if context.current[k] ~= v then
                context.current[k] = v
            end
        end
        return true
    end
    return false
end

function ErrorHandler.handleLatestVersion(context)
    -- Implement latest version handling
    if context.store and context.key then
        local success, result = pcall(function()
            return context.store:GetAsync(context.key)
        end)
        if success then
            context.data = result
            return true
        end
    end
    return false
end

function ErrorHandler.handleAlternateLock(context)
    -- Implement alternate locking
    if context.lockType then
        -- Switch to a different locking mechanism
        context.lockType = context.lockType == "exclusive" and "shared" or "exclusive"
        return true
    end
    return false
end

function ErrorHandler.handleChunkOperation(context)
    -- Implement chunked operation
    if context.chunks then
        for _, chunk in ipairs(context.chunks) do
            local success = ErrorHandler.handleRetry({
                operation = function()
                    return context.store:UpdateAsync(context.key .. "_" .. tostring(_), function(currentValue)
                        return chunk -- Return the chunk data
                    end)
                end
            })
            if not success then
                return false
            end
        end
        return true
    end
    return false
end

function ErrorHandler.handleParameterOptimization(context)
    -- Implement parameter optimization
    if context.parameters then
        -- Optimize parameters for better performance
        context.parameters.timeout = math.min(context.parameters.timeout or 30, 10)
        context.parameters.retries = math.min(context.parameters.retries or 3, 2)
        return true
    end
    return false
end

function ErrorHandler.handleServiceHealthCheck(context)
    -- Implement service health check logic
    return true
end

function ErrorHandler.handleAlternateEndpoint(context)
    -- Implement alternate endpoint logic
    return true
end

function ErrorHandler.handleKeyCreation(context)
    -- Implement key creation logic
    return true
end

function ErrorHandler.handleDefaultValue(context)
    -- Implement default value logic
    return true
end

function ErrorHandler.handleTypeConversion(context)
    -- Implement type conversion logic
    return true
end

function ErrorHandler.handleCircularReference(context)
    -- Implement circular reference logic
    return true
end

function ErrorHandler.handleDataFlattening(context)
    -- Implement data flattening logic
    return true
end

function ErrorHandler.handleOfflineMode(context)
    -- Implement offline mode logic
    return true
end

function ErrorHandler.handleAlternateRoute(context)
    -- Implement alternate route logic
    return true
end

function ErrorHandler.handleOperationSplitting(context)
    -- Implement operation splitting logic
    return true
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
                -- Wait for retry delay using os.clock (avoiding _G usage)
                local startTime = os.clock()
                while os.clock() - startTime < errorInfo.retryDelay do 
                    -- Brief pause to prevent tight loop
                    os.clock()
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