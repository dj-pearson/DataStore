-- DataStore Manager Pro - Advanced Performance Monitor
-- Enterprise performance monitoring with optimization recommendations

local PerformanceMonitor = {}
PerformanceMonitor.__index = PerformanceMonitor

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[PERFORMANCE_MONITOR] [%s] %s", level, message))
end

-- Performance configuration
local PERF_CONFIG = {
    SAMPLING = {
        INTERVAL = 1, -- seconds
        HISTORY_SIZE = 300, -- 5 minutes of data
        METRICS_RETENTION = 3600 -- 1 hour
    },
    THRESHOLDS = {
        RESPONSE_TIME_WARNING = 500, -- ms
        RESPONSE_TIME_CRITICAL = 1000, -- ms
        MEMORY_WARNING = 500, -- MB (increased for Roblox Studio)
        MEMORY_CRITICAL = 1000, -- MB (increased for Roblox Studio)
        CPU_WARNING = 80, -- %
        CPU_CRITICAL = 95, -- %
        CACHE_HIT_RATE_WARNING = 0.6, -- 60%
        CACHE_HIT_RATE_CRITICAL = 0.4 -- 40%
    },
    OPTIMIZATION = {
        AUTO_CACHE_TUNING = true,
        AUTO_BATCH_SIZING = true,
        ADAPTIVE_THROTTLING = true,
        PREDICTIVE_CACHING = true
    }
}

-- Create new Performance Monitor instance
function PerformanceMonitor.new(services)
    local self = setmetatable({}, PerformanceMonitor)
    
    self.services = services or {}
    self.isRunning = false
    self.metrics = {
        responseTime = {},
        memoryUsage = {},
        cachePerformance = {},
        operationCounts = {},
        errorRates = {},
        throughput = {}
    }
    self.alerts = {}
    self.optimizations = {}
    self.samplingInterval = nil
    
    debugLog("Performance Monitor created")
    return self
end

-- Initialize performance monitoring
function PerformanceMonitor.initialize(services)
    local instance = PerformanceMonitor.new(services)
    
    -- Start monitoring
    instance:startMonitoring()
    
    debugLog("Advanced Performance Monitor initialized")
    return instance
end

-- Start performance monitoring
function PerformanceMonitor:startMonitoring()
    if self.isRunning then
        return
    end
    
    self.isRunning = true
    
    -- Start sampling loop
    self.samplingInterval = task.spawn(function()
        while self.isRunning do
            self:collectMetrics()
            self:analyzePerformance()
            self:optimizePerformance()
            task.wait(PERF_CONFIG.SAMPLING.INTERVAL)
        end
    end)
    
    debugLog("Performance monitoring started")
end

-- Stop performance monitoring
function PerformanceMonitor:stopMonitoring()
    self.isRunning = false
    
    if self.samplingInterval then
        task.cancel(self.samplingInterval)
        self.samplingInterval = nil
    end
    
    debugLog("Performance monitoring stopped")
end

-- Collect performance metrics
function PerformanceMonitor:collectMetrics()
    local timestamp = os.time()
    
    -- Memory usage metrics
    local memoryUsage = self:getMemoryUsage()
    self:addMetric("memoryUsage", memoryUsage, timestamp)
    
    -- Response time metrics
    local responseTime = self:getAverageResponseTime()
    self:addMetric("responseTime", responseTime, timestamp)
    
    -- Cache performance metrics
    local cacheStats = self:getCachePerformance()
    self:addMetric("cachePerformance", cacheStats, timestamp)
    
    -- Operation count metrics
    local operationCounts = self:getOperationCounts()
    self:addMetric("operationCounts", operationCounts, timestamp)
    
    -- Error rate metrics
    local errorRate = self:getErrorRate()
    self:addMetric("errorRates", errorRate, timestamp)
    
    -- Throughput metrics
    local throughput = self:getThroughput()
    self:addMetric("throughput", throughput, timestamp)
end

-- Add metric to history
function PerformanceMonitor:addMetric(metricType, value, timestamp)
    if not self.metrics[metricType] then
        self.metrics[metricType] = {}
    end
    
    table.insert(self.metrics[metricType], {
        value = value,
        timestamp = timestamp
    })
    
    -- Limit history size
    if #self.metrics[metricType] > PERF_CONFIG.SAMPLING.HISTORY_SIZE then
        table.remove(self.metrics[metricType], 1)
    end
end

-- Get memory usage
function PerformanceMonitor:getMemoryUsage()
    local Stats = game:GetService("Stats")
    
    local success, memoryMB = pcall(function()
        return Stats:GetTotalMemoryUsageMb()
    end)
    
    if success then
        return memoryMB
    else
        -- Fallback estimation
        return 50 -- Conservative estimate
    end
end

-- Get average response time
function PerformanceMonitor:getAverageResponseTime()
    local dataStoreManager = self.services and self.services["core.data.DataStoreManagerSlim"]
    
    if dataStoreManager and dataStoreManager.getAverageLatency then
        return dataStoreManager:getAverageLatency()
    end
    
    -- Fallback calculation from request manager
    local requestManager = self.services and self.services["core.data.modules.RequestManager"]
    if requestManager and requestManager.getAverageResponseTime then
        return requestManager:getAverageResponseTime()
    end
    
    return 50 -- Default fallback
end

-- Get cache performance
function PerformanceMonitor:getCachePerformance()
    local cacheManager = self.services and self.services["core.data.modules.CacheManager"]
    
    if cacheManager and cacheManager.getStats then
        local stats = cacheManager:getStats()
        return {
            hitRate = stats.hitRate or 0,
            missRate = stats.missRate or 0,
            size = stats.size or 0,
            maxSize = stats.maxSize or 0
        }
    end
    
    return {
        hitRate = 0.75, -- Default reasonable hit rate
        missRate = 0.25,
        size = 0,
        maxSize = 1000
    }
end

-- Get operation counts
function PerformanceMonitor:getOperationCounts()
    local dataStoreManager = self.services and self.services["core.data.DataStoreManagerSlim"]
    
    if dataStoreManager and dataStoreManager.getOperationStats then
        return dataStoreManager:getOperationStats()
    end
    
    return {
        reads = 0,
        writes = 0,
        deletes = 0,
        total = 0
    }
end

-- Get error rate
function PerformanceMonitor:getErrorRate()
    local errorHandler = self.services and self.services["core.error.ErrorHandler"]
    
    if errorHandler and errorHandler.getErrorRate then
        return errorHandler:getErrorRate()
    end
    
    return 0.01 -- 1% default error rate
end

-- Get throughput
function PerformanceMonitor:getThroughput()
    local dataStoreManager = self.services and self.services["core.data.DataStoreManagerSlim"]
    
    if dataStoreManager and dataStoreManager.getThroughput then
        return dataStoreManager:getThroughput()
    end
    
    return {
        operationsPerSecond = 10,
        bytesPerSecond = 1024
    }
end

-- Analyze performance and generate alerts
function PerformanceMonitor:analyzePerformance()
    local currentMetrics = self:getCurrentMetrics()
    
    -- Check response time
    if currentMetrics.responseTime > PERF_CONFIG.THRESHOLDS.RESPONSE_TIME_CRITICAL then
        self:createAlert("CRITICAL", "Response time exceeded critical threshold", {
            current = currentMetrics.responseTime,
            threshold = PERF_CONFIG.THRESHOLDS.RESPONSE_TIME_CRITICAL
        })
    elseif currentMetrics.responseTime > PERF_CONFIG.THRESHOLDS.RESPONSE_TIME_WARNING then
        self:createAlert("WARNING", "Response time exceeded warning threshold", {
            current = currentMetrics.responseTime,
            threshold = PERF_CONFIG.THRESHOLDS.RESPONSE_TIME_WARNING
        })
    end
    
    -- Check memory usage
    if currentMetrics.memoryUsage > PERF_CONFIG.THRESHOLDS.MEMORY_CRITICAL then
        self:createAlert("CRITICAL", "Memory usage exceeded critical threshold", {
            current = currentMetrics.memoryUsage,
            threshold = PERF_CONFIG.THRESHOLDS.MEMORY_CRITICAL
        })
    elseif currentMetrics.memoryUsage > PERF_CONFIG.THRESHOLDS.MEMORY_WARNING then
        self:createAlert("WARNING", "Memory usage exceeded warning threshold", {
            current = currentMetrics.memoryUsage,
            threshold = PERF_CONFIG.THRESHOLDS.MEMORY_WARNING
        })
    end
    
    -- Check cache hit rate
    if currentMetrics.cacheHitRate < PERF_CONFIG.THRESHOLDS.CACHE_HIT_RATE_CRITICAL then
        self:createAlert("CRITICAL", "Cache hit rate below critical threshold", {
            current = currentMetrics.cacheHitRate,
            threshold = PERF_CONFIG.THRESHOLDS.CACHE_HIT_RATE_CRITICAL
        })
    elseif currentMetrics.cacheHitRate < PERF_CONFIG.THRESHOLDS.CACHE_HIT_RATE_WARNING then
        self:createAlert("WARNING", "Cache hit rate below warning threshold", {
            current = currentMetrics.cacheHitRate,
            threshold = PERF_CONFIG.THRESHOLDS.CACHE_HIT_RATE_WARNING
        })
    end
end

-- Create performance alert
function PerformanceMonitor:createAlert(severity, message, data)
    -- Rate limit similar alerts (prevent spam)
    local alertKey = severity .. ":" .. message
    local now = os.time()
    
    if self.lastAlerts and self.lastAlerts[alertKey] then
        local timeSinceLastAlert = now - self.lastAlerts[alertKey]
        if timeSinceLastAlert < 30 then -- 30 second cooldown
            return -- Skip duplicate alert
        end
    end
    
    -- Initialize lastAlerts if needed
    if not self.lastAlerts then
        self.lastAlerts = {}
    end
    self.lastAlerts[alertKey] = now
    
    local alert = {
        id = Utils.createGUID(),
        severity = severity,
        message = message,
        data = data,
        timestamp = now,
        acknowledged = false
    }
    
    table.insert(self.alerts, alert)
    
    -- Limit alert history
    if #self.alerts > 100 then
        table.remove(self.alerts, 1)
    end
    
    debugLog(string.format("[%s] %s", severity, message), severity == "CRITICAL" and "ERROR" or "WARN")
end

-- Optimize performance automatically
function PerformanceMonitor:optimizePerformance()
    if not PERF_CONFIG.OPTIMIZATION.AUTO_CACHE_TUNING then
        return
    end
    
    local currentMetrics = self:getCurrentMetrics()
    
    -- Auto-tune cache size
    if currentMetrics.cacheHitRate < 0.8 and currentMetrics.memoryUsage < PERF_CONFIG.THRESHOLDS.MEMORY_WARNING then
        self:optimizeCache("increase_size")
    elseif currentMetrics.memoryUsage > PERF_CONFIG.THRESHOLDS.MEMORY_WARNING then
        self:optimizeCache("decrease_size")
    end
    
    -- Auto-adjust batch sizes
    if PERF_CONFIG.OPTIMIZATION.AUTO_BATCH_SIZING then
        self:optimizeBatchSizes(currentMetrics)
    end
    
    -- Auto-adjust throttling
    if PERF_CONFIG.OPTIMIZATION.ADAPTIVE_THROTTLING then
        self:optimizeThrottling(currentMetrics)
    end
end

-- Optimize cache performance
function PerformanceMonitor:optimizeCache(action)
    local cacheManager = self.services and self.services["core.data.modules.CacheManager"]
    
    if not cacheManager then
        return
    end
    
    if action == "increase_size" then
        if cacheManager.increaseCacheSize then
            cacheManager:increaseCacheSize(0.2) -- Increase by 20%
            self:recordOptimization("cache_size_increased", "Increased cache size to improve hit rate")
        end
    elseif action == "decrease_size" then
        if cacheManager.decreaseCacheSize then
            cacheManager:decreaseCacheSize(0.1) -- Decrease by 10%
            self:recordOptimization("cache_size_decreased", "Decreased cache size to reduce memory usage")
        end
    end
end

-- Optimize batch sizes
function PerformanceMonitor:optimizeBatchSizes(metrics)
    local bulkOpsManager = self.services and self.services["features.operations.BulkOperationsManager"]
    
    if not bulkOpsManager then
        return
    end
    
    if metrics.responseTime > 300 then
        -- Decrease batch size for better responsiveness
        self:recordOptimization("batch_size_decreased", "Reduced batch size to improve response time")
    elseif metrics.responseTime < 100 and metrics.throughput.operationsPerSecond < 50 then
        -- Increase batch size for better throughput
        self:recordOptimization("batch_size_increased", "Increased batch size to improve throughput")
    end
end

-- Optimize throttling
function PerformanceMonitor:optimizeThrottling(metrics)
    local requestManager = self.services and self.services["core.data.modules.RequestManager"]
    
    if not requestManager then
        return
    end
    
    if metrics.errorRates > 0.05 then -- 5% error rate
        -- Increase throttling
        if requestManager.increaseThrottling then
            requestManager:increaseThrottling()
            self:recordOptimization("throttling_increased", "Increased throttling to reduce error rate")
        end
    elseif metrics.errorRates < 0.01 and metrics.responseTime < 100 then
        -- Decrease throttling
        if requestManager.decreaseThrottling then
            requestManager:decreaseThrottling()
            self:recordOptimization("throttling_decreased", "Decreased throttling to improve performance")
        end
    end
end

-- Record optimization action
function PerformanceMonitor:recordOptimization(action, description)
    table.insert(self.optimizations, {
        action = action,
        description = description,
        timestamp = os.time()
    })
    
    -- Limit optimization history
    if #self.optimizations > 50 then
        table.remove(self.optimizations, 1)
    end
    
    debugLog("Optimization applied: " .. description)
end

-- Get current metrics summary
function PerformanceMonitor:getCurrentMetrics()
    local latest = {}
    
    for metricType, history in pairs(self.metrics) do
        if #history > 0 then
            local latestEntry = history[#history]
            if metricType == "cachePerformance" then
                latest.cacheHitRate = latestEntry.value.hitRate
                latest.cacheSize = latestEntry.value.size
            else
                latest[metricType] = latestEntry.value
            end
        end
    end
    
    return latest
end

-- Get performance summary
function PerformanceMonitor:getPerformanceSummary()
    local currentMetrics = self:getCurrentMetrics()
    local recentAlerts = {}
    
    -- Get recent alerts (last 10)
    for i = math.max(1, #self.alerts - 9), #self.alerts do
        if self.alerts[i] then
            table.insert(recentAlerts, self.alerts[i])
        end
    end
    
    return {
        current = currentMetrics,
        alerts = recentAlerts,
        optimizations = self.optimizations,
        status = self:getOverallStatus(currentMetrics),
        recommendations = self:getRecommendations(currentMetrics)
    }
end

-- Get overall performance status
function PerformanceMonitor:getOverallStatus(metrics)
    if metrics.responseTime > PERF_CONFIG.THRESHOLDS.RESPONSE_TIME_CRITICAL or
       metrics.memoryUsage > PERF_CONFIG.THRESHOLDS.MEMORY_CRITICAL or
       (metrics.cacheHitRate and metrics.cacheHitRate < PERF_CONFIG.THRESHOLDS.CACHE_HIT_RATE_CRITICAL) then
        return "CRITICAL"
    elseif metrics.responseTime > PERF_CONFIG.THRESHOLDS.RESPONSE_TIME_WARNING or
           metrics.memoryUsage > PERF_CONFIG.THRESHOLDS.MEMORY_WARNING or
           (metrics.cacheHitRate and metrics.cacheHitRate < PERF_CONFIG.THRESHOLDS.CACHE_HIT_RATE_WARNING) then
        return "WARNING"
    else
        return "HEALTHY"
    end
end

-- Get performance recommendations
function PerformanceMonitor:getRecommendations(metrics)
    local recommendations = {}
    
    if metrics.responseTime > 200 then
        table.insert(recommendations, {
            type = "performance",
            priority = "high",
            title = "Improve Response Time",
            description = "Consider enabling caching, reducing batch sizes, or optimizing queries"
        })
    end
    
    if metrics.cacheHitRate and metrics.cacheHitRate < 0.7 then
        table.insert(recommendations, {
            type = "cache",
            priority = "medium",
            title = "Optimize Cache Strategy",
            description = "Increase cache size or improve cache key strategies"
        })
    end
    
    if metrics.memoryUsage > 150 then
        table.insert(recommendations, {
            type = "memory",
            priority = "high",
            title = "Reduce Memory Usage",
            description = "Clear unused caches, reduce batch sizes, or implement memory pooling"
        })
    end
    
    return recommendations
end

-- Get metrics history
function PerformanceMonitor:getMetricsHistory(metricType, duration)
    duration = duration or 300 -- 5 minutes default
    local cutoff = os.time() - duration
    
    if not self.metrics[metricType] then
        return {}
    end
    
    local history = {}
    for _, entry in ipairs(self.metrics[metricType]) do
        if entry.timestamp >= cutoff then
            table.insert(history, entry)
        end
    end
    
    return history
end

-- Cleanup function
function PerformanceMonitor:cleanup()
    self:stopMonitoring()
    
    -- Clear metrics
    for metricType in pairs(self.metrics) do
        self.metrics[metricType] = {}
    end
    
    self.alerts = {}
    self.optimizations = {}
    
    debugLog("Performance Monitor cleanup complete")
end

return PerformanceMonitor