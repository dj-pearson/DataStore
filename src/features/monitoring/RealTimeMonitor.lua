-- DataStore Manager Pro - Real-Time Monitoring System
-- Live monitoring of DataStore operations, performance metrics, and system health

local RealTimeMonitor = {}
RealTimeMonitor.__index = RealTimeMonitor

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[REAL_TIME_MONITOR] [%s] %s", level, message))
end

-- Monitoring configuration
local MONITOR_CONFIG = {
    UPDATE_INTERVAL = 2, -- seconds
    MAX_DATA_POINTS = 60, -- 2 minutes of data at 2-second intervals
    ALERT_THRESHOLDS = {
        HIGH_LATENCY = 1000, -- milliseconds
        ERROR_RATE = 0.05, -- 5%
        MEMORY_USAGE = 0.8, -- 80%
        REQUEST_RATE = 100 -- requests per second
    },
    METRICS = {
        "operations_per_second",
        "average_latency",
        "error_rate",
        "memory_usage",
        "active_connections",
        "cache_hit_rate",
        "datastore_size",
        "concurrent_operations"
    }
}

-- Create new Real-Time Monitor instance
function RealTimeMonitor.new(services)
    local self = setmetatable({}, RealTimeMonitor)
    
    self.services = services or {}
    self.isActive = false
    self.updateInterval = nil
    self.metrics = {}
    self.alerts = {}
    self.listeners = {}
    
    -- Initialize metrics storage
    for _, metric in ipairs(MONITOR_CONFIG.METRICS) do
        self.metrics[metric] = {
            current = 0,
            history = {},
            trend = "stable",
            lastUpdate = 0
        }
    end
    
    debugLog("Real-Time Monitor created")
    return self
end

-- Start monitoring
function RealTimeMonitor:start()
    if self.isActive then
        debugLog("Monitor already active")
        return
    end
    
    debugLog("Starting real-time monitoring...")
    
    self.isActive = true
    self.updateInterval = task.spawn(function()
        while self.isActive do
            self:collectMetrics()
            self:analyzeMetrics()
            self:checkAlerts()
            self:notifyListeners()
            
            task.wait(MONITOR_CONFIG.UPDATE_INTERVAL)
        end
    end)
    
    debugLog("Real-time monitoring started")
end

-- Stop monitoring
function RealTimeMonitor:stop()
    if not self.isActive then
        return
    end
    
    debugLog("Stopping real-time monitoring...")
    
    self.isActive = false
    if self.updateInterval then
        task.cancel(self.updateInterval)
        self.updateInterval = nil
    end
    
    debugLog("Real-time monitoring stopped")
end

-- Collect current metrics
function RealTimeMonitor:collectMetrics()
    local currentTime = os.time()
    
    -- Collect operations per second
    self:updateMetric("operations_per_second", self:getOperationsPerSecond())
    
    -- Collect average latency
    self:updateMetric("average_latency", self:getAverageLatency())
    
    -- Collect error rate
    self:updateMetric("error_rate", self:getErrorRate())
    
    -- Collect memory usage
    self:updateMetric("memory_usage", self:getMemoryUsage())
    
    -- Collect active connections
    self:updateMetric("active_connections", self:getActiveConnections())
    
    -- Collect cache hit rate
    self:updateMetric("cache_hit_rate", self:getCacheHitRate())
    
    -- Collect datastore size
    self:updateMetric("datastore_size", self:getDataStoreSize())
    
    -- Collect concurrent operations
    self:updateMetric("concurrent_operations", self:getConcurrentOperations())
end

-- Update a specific metric
function RealTimeMonitor:updateMetric(metricName, value)
    local metric = self.metrics[metricName]
    if not metric then
        return
    end
    
    local currentTime = os.time()
    
    -- Update current value
    local previousValue = metric.current
    metric.current = value
    metric.lastUpdate = currentTime
    
    -- Add to history
    table.insert(metric.history, {
        timestamp = currentTime,
        value = value
    })
    
    -- Maintain history size
    if #metric.history > MONITOR_CONFIG.MAX_DATA_POINTS then
        table.remove(metric.history, 1)
    end
    
    -- Calculate trend
    metric.trend = self:calculateTrend(metric.history)
    
    debugLog(string.format("Metric updated: %s = %.2f (trend: %s)", metricName, value, metric.trend))
end

-- Calculate trend for a metric
function RealTimeMonitor:calculateTrend(history)
    if #history < 5 then
        return "stable"
    end
    
    -- Use last 5 data points to determine trend
    local recent = {}
    for i = math.max(1, #history - 4), #history do
        table.insert(recent, history[i].value)
    end
    
    -- Simple trend calculation
    local sum = 0
    for i = 2, #recent do
        sum = sum + (recent[i] - recent[i-1])
    end
    
    local avgChange = sum / (#recent - 1)
    
    if avgChange > 0.05 then
        return "increasing"
    elseif avgChange < -0.05 then
        return "decreasing"
    else
        return "stable"
    end
end

-- Analyze metrics for patterns and anomalies
function RealTimeMonitor:analyzeMetrics()
    for metricName, metric in pairs(self.metrics) do
        if #metric.history >= 10 then
            -- Check for anomalies
            local anomaly = self:detectAnomaly(metric.history)
            if anomaly then
                self:triggerAlert("anomaly", string.format("Anomaly detected in %s", metricName), "warning")
            end
            
            -- Check for sustained high values
            if self:isSustainedHigh(metric.history) then
                self:triggerAlert("sustained_high", string.format("Sustained high values in %s", metricName), "warning")
            end
        end
    end
end

-- Detect anomalies in metric data
function RealTimeMonitor:detectAnomaly(history)
    if #history < 10 then
        return false
    end
    
    -- Calculate mean and standard deviation
    local sum = 0
    local count = #history
    
    for _, dataPoint in ipairs(history) do
        sum = sum + dataPoint.value
    end
    
    local mean = sum / count
    local varianceSum = 0
    
    for _, dataPoint in ipairs(history) do
        varianceSum = varianceSum + math.pow(dataPoint.value - mean, 2)
    end
    
    local standardDeviation = math.sqrt(varianceSum / count)
    
    -- Check if current value is more than 2 standard deviations from mean
    local currentValue = history[#history].value
    return math.abs(currentValue - mean) > (2 * standardDeviation)
end

-- Check if metric has sustained high values
function RealTimeMonitor:isSustainedHigh(history)
    if #history < 5 then
        return false
    end
    
    -- Check last 5 values
    local threshold = self:calculateThreshold(history)
    local highCount = 0
    
    for i = math.max(1, #history - 4), #history do
        if history[i].value > threshold then
            highCount = highCount + 1
        end
    end
    
    return highCount >= 4 -- 4 out of 5 values are high
end

-- Calculate threshold for sustained high detection
function RealTimeMonitor:calculateThreshold(history)
    -- Use 75th percentile as threshold
    local values = {}
    for _, dataPoint in ipairs(history) do
        table.insert(values, dataPoint.value)
    end
    
    table.sort(values)
    local index = math.ceil(#values * 0.75)
    return values[index] or 0
end

-- Check alert conditions
function RealTimeMonitor:checkAlerts()
    -- High latency alert
    if self.metrics.average_latency.current > MONITOR_CONFIG.ALERT_THRESHOLDS.HIGH_LATENCY then
        self:triggerAlert("high_latency", 
            string.format("High latency detected: %.2fms", self.metrics.average_latency.current), 
            "error")
    end
    
    -- High error rate alert
    if self.metrics.error_rate.current > MONITOR_CONFIG.ALERT_THRESHOLDS.ERROR_RATE then
        self:triggerAlert("high_error_rate", 
            string.format("High error rate: %.1f%%", self.metrics.error_rate.current * 100), 
            "error")
    end
    
    -- High memory usage alert
    if self.metrics.memory_usage.current > MONITOR_CONFIG.ALERT_THRESHOLDS.MEMORY_USAGE then
        self:triggerAlert("high_memory", 
            string.format("High memory usage: %.1f%%", self.metrics.memory_usage.current * 100), 
            "warning")
    end
    
    -- High request rate alert
    if self.metrics.operations_per_second.current > MONITOR_CONFIG.ALERT_THRESHOLDS.REQUEST_RATE then
        self:triggerAlert("high_request_rate", 
            string.format("High request rate: %.1f ops/sec", self.metrics.operations_per_second.current), 
            "info")
    end
end

-- Trigger an alert
function RealTimeMonitor:triggerAlert(alertType, message, severity)
    local alertId = alertType .. "_" .. os.time()
    
    -- Check cooldown to prevent spam
    local lastAlert = self.alerts[alertType] and self.alerts[alertType].timestamp or 0
    if os.time() - lastAlert < 30 then -- 30 second cooldown
        return
    end
    
    local alert = {
        id = alertId,
        type = alertType,
        message = message,
        severity = severity,
        timestamp = os.time(),
        acknowledged = false
    }
    
    self.alerts[alertType] = alert
    
    debugLog(string.format("Alert triggered: %s - %s", severity:upper(), message))
    
    -- Notify listeners
    self:notifyListeners("alert", alert)
end

-- Add event listener
function RealTimeMonitor:addEventListener(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    
    table.insert(self.listeners[event], callback)
end

-- Notify listeners
function RealTimeMonitor:notifyListeners(event, data)
    if not self.listeners[event] then
        return
    end
    
    for _, callback in ipairs(self.listeners[event]) do
        local success, error = pcall(callback, data)
        if not success then
            debugLog("Error in listener callback: " .. tostring(error), "ERROR")
        end
    end
end

-- Get current metrics summary
function RealTimeMonitor:getMetricsSummary()
    local summary = {
        timestamp = os.time(),
        status = "healthy", -- will be determined by analysis
        metrics = {}
    }
    
    for metricName, metric in pairs(self.metrics) do
        summary.metrics[metricName] = {
            current = metric.current,
            trend = metric.trend,
            lastUpdate = metric.lastUpdate
        }
    end
    
    -- Determine overall status
    summary.status = self:determineOverallStatus()
    
    return summary
end

-- Determine overall system status
function RealTimeMonitor:determineOverallStatus()
    local errorCount = 0
    local warningCount = 0
    
    -- Check thresholds
    if self.metrics.error_rate.current > MONITOR_CONFIG.ALERT_THRESHOLDS.ERROR_RATE then
        errorCount = errorCount + 1
    end
    
    if self.metrics.average_latency.current > MONITOR_CONFIG.ALERT_THRESHOLDS.HIGH_LATENCY then
        errorCount = errorCount + 1
    end
    
    if self.metrics.memory_usage.current > MONITOR_CONFIG.ALERT_THRESHOLDS.MEMORY_USAGE then
        warningCount = warningCount + 1
    end
    
    if errorCount > 0 then
        return "critical"
    elseif warningCount > 0 then
        return "warning"
    else
        return "healthy"
    end
end

-- Get metric history for charts
function RealTimeMonitor:getMetricHistory(metricName, duration)
    local metric = self.metrics[metricName]
    if not metric then
        return {}
    end
    
    duration = duration or 300 -- 5 minutes default
    local cutoff = os.time() - duration
    
    local filteredHistory = {}
    for _, dataPoint in ipairs(metric.history) do
        if dataPoint.timestamp >= cutoff then
            table.insert(filteredHistory, dataPoint)
        end
    end
    
    return filteredHistory
end

-- Metric collection methods (these would integrate with actual DataStore services)
function RealTimeMonitor:getOperationsPerSecond()
    -- Mock implementation - would integrate with actual metrics
    return math.random(5, 25) + math.sin(os.time() / 10) * 5
end

function RealTimeMonitor:getAverageLatency()
    -- Mock implementation
    return math.random(50, 200) + math.sin(os.time() / 15) * 30
end

function RealTimeMonitor:getErrorRate()
    -- Mock implementation
    return math.random(0, 5) / 100 -- 0-5%
end

function RealTimeMonitor:getMemoryUsage()
    -- Mock implementation
    return 0.3 + math.random(0, 40) / 100 -- 30-70%
end

function RealTimeMonitor:getActiveConnections()
    -- Mock implementation
    return math.random(1, 10)
end

function RealTimeMonitor:getCacheHitRate()
    -- Mock implementation
    return 0.7 + math.random(0, 25) / 100 -- 70-95%
end

function RealTimeMonitor:getDataStoreSize()
    -- Mock implementation - in MB
    return math.random(10, 100)
end

function RealTimeMonitor:getConcurrentOperations()
    -- Mock implementation
    return math.random(0, 5)
end

-- Acknowledge alert
function RealTimeMonitor:acknowledgeAlert(alertType)
    if self.alerts[alertType] then
        self.alerts[alertType].acknowledged = true
        debugLog("Alert acknowledged: " .. alertType)
        return true
    end
    return false
end

-- Get active alerts
function RealTimeMonitor:getActiveAlerts()
    local activeAlerts = {}
    for _, alert in pairs(self.alerts) do
        if not alert.acknowledged and (os.time() - alert.timestamp) < 300 then -- 5 minutes
            table.insert(activeAlerts, alert)
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(activeAlerts, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return activeAlerts
end

-- Generate performance report
function RealTimeMonitor:generatePerformanceReport(duration)
    duration = duration or 3600 -- 1 hour default
    local cutoff = os.time() - duration
    
    local report = {
        period = {
            start = cutoff,
            endTime = os.time(),
            duration = duration
        },
        summary = {},
        metrics = {}
    }
    
    -- Calculate summary statistics for each metric
    for metricName, metric in pairs(self.metrics) do
        local relevantData = {}
        for _, dataPoint in ipairs(metric.history) do
            if dataPoint.timestamp >= cutoff then
                table.insert(relevantData, dataPoint.value)
            end
        end
        
        if #relevantData > 0 then
            table.sort(relevantData)
            
            report.metrics[metricName] = {
                min = relevantData[1],
                max = relevantData[#relevantData],
                avg = self:calculateAverage(relevantData),
                p50 = relevantData[math.ceil(#relevantData * 0.5)],
                p95 = relevantData[math.ceil(#relevantData * 0.95)],
                p99 = relevantData[math.ceil(#relevantData * 0.99)],
                dataPoints = #relevantData
            }
        end
    end
    
    -- Overall summary
    report.summary = {
        totalDataPoints = self:getTotalDataPoints(cutoff),
        alertsTriggered = self:getAlertsInPeriod(cutoff),
        overallStatus = self:determineOverallStatus(),
        recommendations = self:generateRecommendations()
    }
    
    return report
end

-- Helper methods
function RealTimeMonitor:calculateAverage(values)
    local sum = 0
    for _, value in ipairs(values) do
        sum = sum + value
    end
    return #values > 0 and (sum / #values) or 0
end

function RealTimeMonitor:getTotalDataPoints(cutoff)
    local total = 0
    for _, metric in pairs(self.metrics) do
        for _, dataPoint in ipairs(metric.history) do
            if dataPoint.timestamp >= cutoff then
                total = total + 1
            end
        end
    end
    return total
end

function RealTimeMonitor:getAlertsInPeriod(cutoff)
    local count = 0
    for _, alert in pairs(self.alerts) do
        if alert.timestamp >= cutoff then
            count = count + 1
        end
    end
    return count
end

function RealTimeMonitor:generateRecommendations()
    local recommendations = {}
    
    -- Check for performance issues
    if self.metrics.average_latency.current > 500 then
        table.insert(recommendations, "Consider optimizing DataStore operations to reduce latency")
    end
    
    if self.metrics.error_rate.current > 0.02 then
        table.insert(recommendations, "Investigate and fix error sources to improve reliability")
    end
    
    if self.metrics.memory_usage.current > 0.7 then
        table.insert(recommendations, "Monitor memory usage and consider optimization")
    end
    
    if #recommendations == 0 then
        table.insert(recommendations, "System is performing well - no immediate action needed")
    end
    
    return recommendations
end

-- Cleanup
function RealTimeMonitor:destroy()
    self:stop()
    self.metrics = {}
    self.alerts = {}
    self.listeners = {}
    debugLog("Real-Time Monitor destroyed")
end

return RealTimeMonitor 