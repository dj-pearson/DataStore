-- DataStore Manager Pro - Logging System
-- Comprehensive logging with multiple outputs and filtering

local Logger = {}

-- Import dependencies (with proper script handling)
local script_ref = rawget(_G, "script") or script
local Constants = require(script_ref.Parent.Parent.Parent.shared.Constants)
local Utils = require(script_ref.Parent.Parent.Parent.shared.Utils)

-- Local state
local logs = {}
local initialized = false
local logLevel = Constants.LOGGING.DEFAULT_LEVEL
local logCallbacks = {}

-- Log levels (from Constants but local for performance)
local LOG_LEVELS = Constants.LOGGING.LEVELS

-- Color codes for console output
local LEVEL_COLORS = {
    [LOG_LEVELS.TRACE] = "🔍",
    [LOG_LEVELS.DEBUG] = "🐛", 
    [LOG_LEVELS.INFO] = "ℹ️",
    [LOG_LEVELS.WARN] = "⚠️",
    [LOG_LEVELS.ERROR] = "❌",
    [LOG_LEVELS.FATAL] = "💀"
}

local LEVEL_NAMES = {
    [LOG_LEVELS.TRACE] = "TRACE",
    [LOG_LEVELS.DEBUG] = "DEBUG",
    [LOG_LEVELS.INFO] = "INFO",
    [LOG_LEVELS.WARN] = "WARN",
    [LOG_LEVELS.ERROR] = "ERROR",
    [LOG_LEVELS.FATAL] = "FATAL"
}

-- Initialize logging system
function Logger.initialize()
    if initialized then
        return true
    end
    
    print("[LOGGER] [INFO] Initializing logging system")
    
    -- Load log level from configuration if available
    -- This will be set up properly once PluginConfig is available
    logLevel = Constants.LOGGING.DEFAULT_LEVEL
    
    initialized = true
    print("[LOGGER] [INFO] Logging system initialized successfully")
    return true
end

-- Core logging function
local function writeLog(level, component, message, data)
    if not initialized or level < logLevel then
        return
    end
    
    local logEntry = {
        id = Utils.UI.createGUID(),
        timestamp = Utils.Time.getCurrentTimestamp(),
        level = level,
        levelName = LEVEL_NAMES[level],
        component = component or "UNKNOWN",
        message = message or "",
        data = data,
        formatted = nil -- Will be set when needed
    }
    
    -- Add to log storage
    table.insert(logs, logEntry)
    
    -- Maintain log size
    if #logs > Constants.LOGGING.MAX_LOG_ENTRIES then
        table.remove(logs, 1)
    end
    
    -- Format for console output
    local timeStr = Utils.Time.formatTimestamp(logEntry.timestamp, "%H:%M:%S")
    local icon = LEVEL_COLORS[level] or "📝"
    local formattedMessage = string.format(
        "[%s] %s [%s] %s: %s",
        timeStr,
        icon,
        logEntry.levelName,
        logEntry.component,
        logEntry.message
    )
    
    -- Add data if present
    if data and type(data) == "table" and not Utils.Table.isEmpty(data) then
        formattedMessage = formattedMessage .. "\nData: " .. Utils.JSON.encode(data)
    end
    
    logEntry.formatted = formattedMessage
    
    -- Output to console (with linter-safe warn function)
    local warn_func = rawget(_G, "warn") or print
    if level >= LOG_LEVELS.ERROR then
        warn_func(formattedMessage)
    else
        print(formattedMessage)
    end
    
    -- Trigger callbacks
    for _, callback in ipairs(logCallbacks) do
        local success, err = pcall(callback, logEntry)
        if not success then
            print("[LOGGER] [ERROR] Log callback failed: " .. tostring(err))
        end
    end
end

-- Public logging functions
function Logger.trace(component, message, data)
    writeLog(LOG_LEVELS.TRACE, component, message, data)
end

function Logger.debug(component, message, data)
    writeLog(LOG_LEVELS.DEBUG, component, message, data)
end

function Logger.info(component, message, data)
    writeLog(LOG_LEVELS.INFO, component, message, data)
end

function Logger.warn(component, message, data)
    writeLog(LOG_LEVELS.WARN, component, message, data)
end

function Logger.error(component, message, data)
    writeLog(LOG_LEVELS.ERROR, component, message, data)
end

function Logger.fatal(component, message, data)
    writeLog(LOG_LEVELS.FATAL, component, message, data)
end

-- Convenience function for performance logging
function Logger.performance(component, operation, duration, additionalData)
    local data = Utils.Table.merge({
        operation = operation,
        duration = duration,
        unit = "ms"
    }, additionalData or {})
    
    if duration > 1000 then -- > 1 second
        Logger.warn(component, string.format("Slow operation: %s took %.2fms", operation, duration), data)
    else
        Logger.debug(component, string.format("Performance: %s took %.2fms", operation, duration), data)
    end
end

-- Log with custom level
function Logger.log(level, component, message, data)
    if type(level) == "string" then
        level = LOG_LEVELS[level:upper()] or LOG_LEVELS.INFO
    end
    writeLog(level, component, message, data)
end

-- Set log level
function Logger.setLevel(level)
    if type(level) == "string" then
        level = LOG_LEVELS[level:upper()]
    end
    
    if level and level >= LOG_LEVELS.TRACE and level <= LOG_LEVELS.FATAL then
        logLevel = level
        Logger.info("LOGGER", "Log level set to " .. LEVEL_NAMES[level])
        return true
    else
        Logger.error("LOGGER", "Invalid log level: " .. tostring(level))
        return false
    end
end

-- Get current log level
function Logger.getLevel()
    return logLevel, LEVEL_NAMES[logLevel]
end

-- Get recent logs
function Logger.getRecentLogs(count, levelFilter)
    if not initialized then
        return {}
    end
    
    count = count or 50
    local recentLogs = {}
    
    -- Filter and collect logs
    for i = #logs, math.max(1, #logs - count * 2), -1 do -- Get more than needed to account for filtering
        local log = logs[i]
        
        if not levelFilter or log.level >= levelFilter then
            table.insert(recentLogs, log)
            
            if #recentLogs >= count then
                break
            end
        end
    end
    
    return recentLogs
end

-- Search logs
function Logger.searchLogs(query, options)
    if not initialized or not query or query == "" then
        return {}
    end
    
    options = options or {}
    local levelFilter = options.levelFilter
    local componentFilter = options.componentFilter
    local timeRange = options.timeRange
    local caseSensitive = options.caseSensitive or false
    
    if not caseSensitive then
        query = query:lower()
    end
    
    local results = {}
    
    for _, log in ipairs(logs) do
        -- Apply filters
        local shouldInclude = true
        
        -- Check all filter conditions
        if levelFilter and log.level < levelFilter then
            -- Skip: level too low
        elseif componentFilter and log.component ~= componentFilter then
            -- Skip: component doesn't match
        elseif timeRange and (log.timestamp < timeRange.start or log.timestamp > timeRange.endTime) then
            -- Skip: outside time range
        else
            -- Only set shouldInclude after all checks pass
            shouldInclude = shouldInclude -- Keep the original value if no exclusions
        end
        
        -- Set shouldInclude to false if any filter matched
        if (levelFilter and log.level < levelFilter) or 
           (componentFilter and log.component ~= componentFilter) or
           (timeRange and (log.timestamp < timeRange.start or log.timestamp > timeRange.endTime)) then
            shouldInclude = false
        end
        
        if shouldInclude then
            -- Search in message
            local searchText = log.message
            if not caseSensitive then
                searchText = searchText:lower()
            end
            
            if searchText:find(query, 1, true) then -- Plain text search
                table.insert(results, log)
            end
        end
    end
    
    return results
end

-- Export logs
function Logger.exportLogs(format, options)
    if not initialized then
        return nil
    end
    
    format = format or "json"
    options = options or {}
    
    local logsToExport = logs
    
    -- Apply filters
    if options.levelFilter then
        logsToExport = Utils.Table.filter(logsToExport, function(log)
            return log.level >= options.levelFilter
        end)
    end
    
    if options.timeRange then
        logsToExport = Utils.Table.filter(logsToExport, function(log)
            return log.timestamp >= options.timeRange.start and log.timestamp <= options.timeRange.endTime
        end)
    end
    
    if format == "json" then
        return Utils.JSON.encode({
            exportedAt = Utils.Time.getCurrentTimestamp(),
            totalLogs = #logsToExport,
            logs = logsToExport
        }, true)
    elseif format == "csv" then
        local csv = "Timestamp,Level,Component,Message\n"
        for _, log in ipairs(logsToExport) do
            csv = csv .. string.format(
                "%s,%s,%s,%s\n",
                Utils.Time.formatTimestamp(log.timestamp),
                log.levelName,
                log.component,
                log.message:gsub(",", ";"):gsub("\n", " ") -- Escape problematic characters
            )
        end
        return csv
    elseif format == "text" then
        local text = ""
        for _, log in ipairs(logsToExport) do
            text = text .. (log.formatted or log.message) .. "\n"
        end
        return text
    end
    
    return nil
end

-- Clear logs
function Logger.clearLogs()
    if not initialized then
        return false
    end
    
    local count = #logs
    logs = {}
    Logger.info("LOGGER", "Cleared " .. count .. " log entries")
    return true
end

-- Get log statistics
function Logger.getStatistics()
    if not initialized then
        return {}
    end
    
    local stats = {
        totalLogs = #logs,
        logsByLevel = {},
        logsByComponent = {},
        oldestLog = nil,
        newestLog = nil
    }
    
    -- Initialize level counts
    for _, name in pairs(LEVEL_NAMES) do
        stats.logsByLevel[name] = 0
    end
    
    -- Analyze logs
    for _, log in ipairs(logs) do
        -- Count by level
        stats.logsByLevel[log.levelName] = stats.logsByLevel[log.levelName] + 1
        
        -- Count by component
        stats.logsByComponent[log.component] = (stats.logsByComponent[log.component] or 0) + 1
        
        -- Track time range
        if not stats.oldestLog or log.timestamp < stats.oldestLog then
            stats.oldestLog = log.timestamp
        end
        
        if not stats.newestLog or log.timestamp > stats.newestLog then
            stats.newestLog = log.timestamp
        end
    end
    
    return stats
end

-- Register log callback
function Logger.onLog(callback)
    if not callback or type(callback) ~= "function" then
        Logger.error("LOGGER", "Invalid callback provided")
        return false
    end
    
    table.insert(logCallbacks, callback)
    Logger.debug("LOGGER", "Log callback registered")
    return true
end

-- Performance measurement wrapper
function Logger.measurePerformance(component, operation, func, ...)
    local args = {...}
    local startTime = os.time()
    
    local results = {func(unpack(args))}
    
    local duration = (os.time() - startTime) * 1000 -- Convert to milliseconds
    Logger.performance(component, operation, duration)
    
    return unpack(results)
end

-- Create scoped logger for a component
function Logger.createScope(component)
    return {
        trace = function(message, data) Logger.trace(component, message, data) end,
        debug = function(message, data) Logger.debug(component, message, data) end,
        info = function(message, data) Logger.info(component, message, data) end,
        warn = function(message, data) Logger.warn(component, message, data) end,
        error = function(message, data) Logger.error(component, message, data) end,
        fatal = function(message, data) Logger.fatal(component, message, data) end,
        performance = function(operation, duration, data) 
            Logger.performance(component, operation, duration, data) 
        end
    }
end

-- Cleanup
function Logger.cleanup()
    if not initialized then
        return
    end
    
    Logger.info("LOGGER", "Cleaning up logging system")
    
    local stats = Logger.getStatistics()
    print(string.format(
        "[LOGGER] [INFO] Final stats - Total logs: %d, Errors: %d, Warnings: %d",
        stats.totalLogs,
        stats.logsByLevel.ERROR or 0,
        stats.logsByLevel.WARN or 0
    ))
    
    logs = {}
    logCallbacks = {}
    initialized = false
    
    print("[LOGGER] [INFO] Logging cleanup complete")
end

return Logger 