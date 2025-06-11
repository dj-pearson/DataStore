-- DataStore Manager Pro - Advanced Analytics System
-- Implements real performance monitoring and usage analytics

local AdvancedAnalytics = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Analytics configuration
local ANALYTICS_CONFIG = {
    SAMPLING = {
        PERFORMANCE_RATE = 1.0, -- Sample 100% of operations
        ERROR_RATE = 1.0, -- Sample 100% of errors
        USER_ACTION_RATE = 0.1 -- Sample 10% of user actions
    },
    AGGREGATION = {
        WINDOW_SIZE = 300, -- 5 minutes
        RETENTION_HOURS = 24, -- Keep 24 hours of data
        MAX_METRICS_PER_WINDOW = 1000
    },
    THRESHOLDS = {
        SLOW_OPERATION_MS = 1000, -- Operations over 1s are slow
        HIGH_ERROR_RATE = 0.05, -- 5% error rate is high
        HIGH_MEMORY_MB = 100 -- 100MB memory usage is high
    }
}

-- Analytics state
local analyticsState = {
    initialized = false,
    currentWindow = nil,
    windows = {},
    realTimeMetrics = {},
    alerts = {},
    securityManager = nil
}

-- Metric types
local METRIC_TYPES = {
    COUNTER = "counter",
    GAUGE = "gauge", 
    HISTOGRAM = "histogram",
    TIMER = "timer"
}

-- Core analytics initialization
function AdvancedAnalytics.initialize(securityManager)
    print("[ADVANCED_ANALYTICS] [INFO] Initializing advanced analytics system...")
    
    analyticsState.securityManager = securityManager
    
    -- Initialize metrics collection
    AdvancedAnalytics.initializeMetrics()
    
    -- Start background collection
    AdvancedAnalytics.startBackgroundCollection()
    
    analyticsState.initialized = true
    
    print("[ADVANCED_ANALYTICS] [INFO] Advanced analytics system initialized")
    
    -- Log initialization to security audit
    if securityManager then
        securityManager.auditLog("ANALYTICS_INIT", "Advanced Analytics system started")
    end
    
    return true
end

function AdvancedAnalytics.initializeMetrics()
    analyticsState.realTimeMetrics = {
        -- Performance metrics
        operationLatency = {type = METRIC_TYPES.HISTOGRAM, values = {}, count = 0},
        operationCount = {type = METRIC_TYPES.COUNTER, value = 0},
        errorCount = {type = METRIC_TYPES.COUNTER, value = 0},
        errorRate = {type = METRIC_TYPES.GAUGE, value = 0},
        
        -- DataStore metrics
        dataStoreReads = {type = METRIC_TYPES.COUNTER, value = 0},
        dataStoreWrites = {type = METRIC_TYPES.COUNTER, value = 0},
        dataStoreDeletes = {type = METRIC_TYPES.COUNTER, value = 0},
        dataStoreErrors = {type = METRIC_TYPES.COUNTER, value = 0},
        
        -- System metrics
        memoryUsage = {type = METRIC_TYPES.GAUGE, value = 0},
        cpuUsage = {type = METRIC_TYPES.GAUGE, value = 0},
        activeConnections = {type = METRIC_TYPES.GAUGE, value = 0},
        
        -- User metrics
        activeUsers = {type = METRIC_TYPES.GAUGE, value = 1}, -- Default to studio user
        userActions = {type = METRIC_TYPES.COUNTER, value = 0},
        sessionDuration = {type = METRIC_TYPES.GAUGE, value = 0},
        
        -- Security metrics  
        securityEvents = {type = METRIC_TYPES.COUNTER, value = 0},
        accessDenials = {type = METRIC_TYPES.COUNTER, value = 0},
        auditLogSize = {type = METRIC_TYPES.GAUGE, value = 0}
    }
    
    -- Create first time window
    AdvancedAnalytics.createNewWindow()
end

function AdvancedAnalytics.createNewWindow()
    local now = os.time()
    analyticsState.currentWindow = {
        startTime = now,
        endTime = now + ANALYTICS_CONFIG.AGGREGATION.WINDOW_SIZE,
        metrics = Utils.Table.deepCopy(analyticsState.realTimeMetrics),
        alerts = {},
        windowId = #analyticsState.windows + 1
    }
    
    table.insert(analyticsState.windows, analyticsState.currentWindow)
    
    -- Clean up old windows
    AdvancedAnalytics.cleanupOldWindows()
end

function AdvancedAnalytics.cleanupOldWindows()
    local cutoffTime = os.time() - (ANALYTICS_CONFIG.AGGREGATION.RETENTION_HOURS * 3600)
    local keptWindows = {}
    
    for _, window in ipairs(analyticsState.windows) do
        if window.startTime > cutoffTime then
            table.insert(keptWindows, window)
        end
    end
    
    analyticsState.windows = keptWindows
end

-- Background collection thread
function AdvancedAnalytics.startBackgroundCollection()
    spawn(function()
        while analyticsState.initialized do
            -- Collect system metrics every 30 seconds
            AdvancedAnalytics.collectSystemMetrics()
            
            -- Check for window rotation
            local now = os.time()
            if analyticsState.currentWindow and now >= analyticsState.currentWindow.endTime then
                AdvancedAnalytics.rotateWindow()
            end
            
            -- Check for alerts
            AdvancedAnalytics.checkAlerts()
            
            wait(30)
        end
    end)
end

function AdvancedAnalytics.collectSystemMetrics()
    -- Memory usage
    local memoryBytes = Utils.Debug.getMemoryUsage()
    AdvancedAnalytics.recordGauge("memoryUsage", memoryBytes / (1024 * 1024)) -- Convert to MB
    
    -- Security metrics
    if analyticsState.securityManager then
        local securityStatus = analyticsState.securityManager.getSecurityStatus()
        AdvancedAnalytics.recordGauge("auditLogSize", securityStatus.auditLogEntries or 0)
    end
    
    -- Calculate error rate
    local operations = analyticsState.realTimeMetrics.operationCount.value
    local errors = analyticsState.realTimeMetrics.errorCount.value
    local errorRate = operations > 0 and (errors / operations) or 0
    AdvancedAnalytics.recordGauge("errorRate", errorRate)
end

function AdvancedAnalytics.rotateWindow()
    -- Save current window
    if analyticsState.currentWindow then
        AdvancedAnalytics.finalizeWindow(analyticsState.currentWindow)
    end
    
    -- Create new window
    AdvancedAnalytics.createNewWindow()
    
    print("[ADVANCED_ANALYTICS] [INFO] Analytics window rotated")
end

function AdvancedAnalytics.finalizeWindow(window)
    -- Calculate aggregated metrics
    window.summary = {
        totalOperations = window.metrics.operationCount.value,
        averageLatency = AdvancedAnalytics.calculateAverageLatency(window.metrics.operationLatency),
        errorRate = window.metrics.errorRate.value,
        peakMemoryMB = window.metrics.memoryUsage.value,
        userActions = window.metrics.userActions.value
    }
    
    -- Check for performance issues
    AdvancedAnalytics.analyzePerformance(window)
end

function AdvancedAnalytics.calculateAverageLatency(latencyMetric)
    if latencyMetric.count == 0 then return 0 end
    
    local sum = 0
    for _, value in ipairs(latencyMetric.values) do
        sum = sum + value
    end
    
    return sum / latencyMetric.count
end

-- Metric recording functions
function AdvancedAnalytics.recordCounter(metricName, increment)
    increment = increment or 1
    
    if not analyticsState.realTimeMetrics[metricName] then
        print("[ADVANCED_ANALYTICS] [WARN] Unknown counter metric: " .. metricName)
        return
    end
    
    analyticsState.realTimeMetrics[metricName].value = analyticsState.realTimeMetrics[metricName].value + increment
end

function AdvancedAnalytics.recordGauge(metricName, value)
    if not analyticsState.realTimeMetrics[metricName] then
        print("[ADVANCED_ANALYTICS] [WARN] Unknown gauge metric: " .. metricName)
        return
    end
    
    analyticsState.realTimeMetrics[metricName].value = value
end

function AdvancedAnalytics.recordHistogram(metricName, value)
    if not analyticsState.realTimeMetrics[metricName] then
        print("[ADVANCED_ANALYTICS] [WARN] Unknown histogram metric: " .. metricName)
        return
    end
    
    local metric = analyticsState.realTimeMetrics[metricName]
    table.insert(metric.values, value)
    metric.count = metric.count + 1
    
    -- Keep only recent values to prevent memory issues
    if #metric.values > 1000 then
        table.remove(metric.values, 1)
    end
end

function AdvancedAnalytics.recordTimer(metricName, startTime)
    local duration = (os.clock() - startTime) * 1000 -- Convert to milliseconds
    AdvancedAnalytics.recordHistogram(metricName, duration)
    return duration
end

-- High-level tracking functions
function AdvancedAnalytics.trackDataStoreOperation(operation, dataStore, key, startTime, success, error)
    -- Record latency
    local duration = AdvancedAnalytics.recordTimer("operationLatency", startTime)
    
    -- Record operation count
    AdvancedAnalytics.recordCounter("operationCount")
    
    -- Record operation type
    if operation == "read" then
        AdvancedAnalytics.recordCounter("dataStoreReads")
    elseif operation == "write" then
        AdvancedAnalytics.recordCounter("dataStoreWrites")
    elseif operation == "delete" then
        AdvancedAnalytics.recordCounter("dataStoreDeletes")
    end
    
    -- Record errors
    if not success then
        AdvancedAnalytics.recordCounter("errorCount")
        AdvancedAnalytics.recordCounter("dataStoreErrors")
        
        -- Log error details
        print(string.format("[ADVANCED_ANALYTICS] [ERROR] DataStore %s failed: %s -> %s (%dms) - %s", 
            operation, dataStore, key or "N/A", math.floor(duration), error or "Unknown error"))
    end
    
    -- Security audit
    if analyticsState.securityManager then
        analyticsState.securityManager.auditLog("DATA_" .. string.upper(operation), 
            string.format("DataStore: %s, Key: %s, Duration: %dms, Success: %s", 
                dataStore, key or "N/A", math.floor(duration), tostring(success)))
    end
end

function AdvancedAnalytics.trackUserAction(action, context)
    AdvancedAnalytics.recordCounter("userActions")
    
    -- Sample user actions to avoid overwhelming logs
    if math.random() < ANALYTICS_CONFIG.SAMPLING.USER_ACTION_RATE then
        print(string.format("[ADVANCED_ANALYTICS] [INFO] User action: %s - %s", action, 
            context and Utils.JSON.encode(context) or "No context"))
    end
end

function AdvancedAnalytics.trackSecurityEvent(eventType, severity)
    AdvancedAnalytics.recordCounter("securityEvents")
    
    if severity == "ERROR" or severity == "CRITICAL" then
        AdvancedAnalytics.recordCounter("accessDenials")
    end
    
    print(string.format("[ADVANCED_ANALYTICS] [SECURITY] %s event: %s", severity, eventType))
end

-- Alert system
function AdvancedAnalytics.checkAlerts()
    local alerts = {}
    
    -- Check performance thresholds
    local avgLatency = AdvancedAnalytics.calculateAverageLatency(analyticsState.realTimeMetrics.operationLatency)
    if avgLatency > ANALYTICS_CONFIG.THRESHOLDS.SLOW_OPERATION_MS then
        table.insert(alerts, {
            type = "PERFORMANCE",
            severity = "WARNING", 
            message = string.format("High average latency: %.1fms", avgLatency),
            metric = "operationLatency",
            value = avgLatency,
            threshold = ANALYTICS_CONFIG.THRESHOLDS.SLOW_OPERATION_MS
        })
    end
    
    -- Check error rate
    local errorRate = analyticsState.realTimeMetrics.errorRate.value
    if errorRate > ANALYTICS_CONFIG.THRESHOLDS.HIGH_ERROR_RATE then
        table.insert(alerts, {
            type = "RELIABILITY",
            severity = "ERROR",
            message = string.format("High error rate: %.1f%%", errorRate * 100),
            metric = "errorRate", 
            value = errorRate,
            threshold = ANALYTICS_CONFIG.THRESHOLDS.HIGH_ERROR_RATE
        })
    end
    
    -- Check memory usage
    local memoryMB = analyticsState.realTimeMetrics.memoryUsage.value
    if memoryMB > ANALYTICS_CONFIG.THRESHOLDS.HIGH_MEMORY_MB then
        table.insert(alerts, {
            type = "RESOURCE",
            severity = "WARNING",
            message = string.format("High memory usage: %.1fMB", memoryMB),
            metric = "memoryUsage",
            value = memoryMB,
            threshold = ANALYTICS_CONFIG.THRESHOLDS.HIGH_MEMORY_MB
        })
    end
    
    -- Process new alerts
    for _, alert in ipairs(alerts) do
        AdvancedAnalytics.processAlert(alert)
    end
end

function AdvancedAnalytics.processAlert(alert)
    alert.timestamp = os.time()
    alert.id = #analyticsState.alerts + 1
    
    table.insert(analyticsState.alerts, alert)
    
    -- Log alert
    print(string.format("[ADVANCED_ANALYTICS] [ALERT] %s: %s", alert.severity, alert.message))
    
    -- Security audit for critical alerts
    if analyticsState.securityManager and alert.severity == "ERROR" then
        analyticsState.securityManager.auditLog("PERFORMANCE_ALERT", alert.message)
    end
    
    -- Keep only recent alerts
    if #analyticsState.alerts > 100 then
        table.remove(analyticsState.alerts, 1)
    end
end

-- Performance analysis
function AdvancedAnalytics.analyzePerformance(window)
    local analysis = {
        windowId = window.windowId,
        timeRange = {window.startTime, window.endTime},
        performance = "GOOD", -- Default
        issues = {}
    }
    
    -- Analyze latency
    if window.summary.averageLatency > ANALYTICS_CONFIG.THRESHOLDS.SLOW_OPERATION_MS then
        analysis.performance = "DEGRADED"
        table.insert(analysis.issues, {
            type = "HIGH_LATENCY",
            value = window.summary.averageLatency,
            impact = "Operations are taking longer than expected"
        })
    end
    
    -- Analyze error rate
    if window.summary.errorRate > ANALYTICS_CONFIG.THRESHOLDS.HIGH_ERROR_RATE then
        analysis.performance = window.summary.errorRate > 0.2 and "CRITICAL" or "DEGRADED"
        table.insert(analysis.issues, {
            type = "HIGH_ERROR_RATE",
            value = window.summary.errorRate,
            impact = "Many operations are failing"
        })
    end
    
    window.analysis = analysis
    
    if analysis.performance ~= "GOOD" then
        print(string.format("[ADVANCED_ANALYTICS] [ANALYSIS] Window %d performance: %s (%d issues)", 
            window.windowId, analysis.performance, #analysis.issues))
    end
end

-- Data export functions
function AdvancedAnalytics.getMetricsSummary(timeRange)
    if analyticsState.securityManager then
        analyticsState.securityManager.requirePermission("VIEW_ANALYTICS", "view metrics summary")
    end
    
    local summary = {
        currentMetrics = analyticsState.realTimeMetrics,
        recentAlerts = analyticsState.alerts,
        windowCount = #analyticsState.windows,
        timeRange = timeRange or {os.time() - 3600, os.time()} -- Default to last hour
    }
    
    -- Add windowed data
    summary.windows = {}
    for _, window in ipairs(analyticsState.windows) do
        if not timeRange or (window.startTime >= timeRange[1] and window.endTime <= timeRange[2]) then
            table.insert(summary.windows, {
                windowId = window.windowId,
                timeRange = {window.startTime, window.endTime},
                summary = window.summary,
                analysis = window.analysis
            })
        end
    end
    
    return summary
end

function AdvancedAnalytics.exportMetrics(format, timeRange)
    if analyticsState.securityManager then
        analyticsState.securityManager.requirePermission("EXPORT_DATA", "export analytics metrics")
    end
    
    local data = AdvancedAnalytics.getMetricsSummary(timeRange)
    
    if format == "json" then
        return Utils.JSON.encode(data, true)
    elseif format == "csv" then
        return AdvancedAnalytics.convertToCSV(data)
    else
        error("Unsupported export format: " .. tostring(format))
    end
end

function AdvancedAnalytics.convertToCSV(data)
    local csv = "WindowId,StartTime,EndTime,Operations,AvgLatency,ErrorRate,MemoryMB,UserActions\n"
    
    for _, window in ipairs(data.windows) do
        csv = csv .. string.format("%d,%d,%d,%d,%.2f,%.4f,%.1f,%d\n",
            window.windowId,
            window.timeRange[1],
            window.timeRange[2], 
            window.summary.totalOperations or 0,
            window.summary.averageLatency or 0,
            window.summary.errorRate or 0,
            window.summary.peakMemoryMB or 0,
            window.summary.userActions or 0
        )
    end
    
    return csv
end

-- Cleanup function
function AdvancedAnalytics.cleanup()
    analyticsState.initialized = false
    
    print("[ADVANCED_ANALYTICS] [INFO] Advanced Analytics cleanup completed")
    
    if analyticsState.securityManager then
        analyticsState.securityManager.auditLog("ANALYTICS_STOP", "Advanced Analytics system stopped")
    end
end

return AdvancedAnalytics 