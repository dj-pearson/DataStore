-- Analytics Service for DataStore Manager Pro
-- Tracks usage patterns, data size trends, and performance metrics
-- Part of Phase 2.3: Advanced Features

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local AnalyticsService = {}

function AnalyticsService.new()
    local self = setmetatable({}, {__index = AnalyticsService})
    
    -- Analytics storage
    self.data = {
        operations = {
            total = 0,
            byType = {},
            byDataStore = {},
            errors = {},
            timeline = {}
        },
        performance = {
            latency = {samples = {}, average = 0, min = math.huge, max = 0},
            throughput = {current = 0, history = {}}
        },
        dataInsights = {
            totalDataStores = 0,
            totalKeys = 0,
            totalSize = 0,
            sizeDistribution = {},
            dataStoreMetrics = {}
        },
        usagePatterns = {
            peakHours = {},
            commonOperations = {},
            accessFrequency = {}
        }
    }
    
    self.sessionStart = os.time()
    debugLog("Analytics Service initialized", "INFO")
    return self
end

-- Track an operation
function AnalyticsService:trackOperation(operation, dataStore, key, startTime, endTime, size, success, error)
    local latency = endTime - startTime
    local timestamp = os.time()
    
    -- Update counters
    self.data.operations.total = self.data.operations.total + 1
    self.data.operations.byType[operation] = (self.data.operations.byType[operation] or 0) + 1
    self.data.operations.byDataStore[dataStore] = (self.data.operations.byDataStore[dataStore] or 0) + 1
    
    -- Track timeline
    table.insert(self.data.operations.timeline, {
        operation = operation,
        dataStore = dataStore,
        key = key,
        timestamp = timestamp,
        latency = latency,
        success = success
    })
    
    -- Track errors
    if not success and error then
        table.insert(self.data.operations.errors, {
            operation = operation,
            dataStore = dataStore,
            key = key,
            error = error,
            timestamp = timestamp
        })
    end
    
    -- Update performance metrics
    self:updatePerformanceMetrics(latency)
    
    -- Track data insights
    if size then
        self:trackDataSize(dataStore, key, size)
    end
    
    -- Track usage patterns
    self:trackUsagePattern(operation, dataStore, timestamp)
end

-- Update performance metrics
function AnalyticsService:updatePerformanceMetrics(latency)
    local perf = self.data.performance.latency
    
    table.insert(perf.samples, latency)
    if #perf.samples > 100 then -- Keep last 100 samples
        table.remove(perf.samples, 1)
    end
    
    perf.min = math.min(perf.min, latency)
    perf.max = math.max(perf.max, latency)
    
    -- Calculate average
    local sum = 0
    for _, sample in ipairs(perf.samples) do
        sum = sum + sample
    end
    perf.average = sum / #perf.samples
end

-- Track data size insights
function AnalyticsService:trackDataSize(dataStore, _, size)
    local insights = self.data.dataInsights
    
    insights.totalSize = insights.totalSize + size
    insights.totalKeys = insights.totalKeys + 1
    
    -- Size distribution
    local category = self:getSizeCategory(size)
    insights.sizeDistribution[category] = (insights.sizeDistribution[category] or 0) + 1
    
    -- DataStore metrics
    if not insights.dataStoreMetrics[dataStore] then
        insights.dataStoreMetrics[dataStore] = {
            keyCount = 0,
            totalSize = 0,
            averageSize = 0
        }
    end
    
    local metrics = insights.dataStoreMetrics[dataStore]
    metrics.keyCount = metrics.keyCount + 1
    metrics.totalSize = metrics.totalSize + size
    metrics.averageSize = metrics.totalSize / metrics.keyCount
end

-- Categorize data size
function AnalyticsService:getSizeCategory(size)
    if size < 1024 then
        return "Small (<1KB)"
    elseif size < 10240 then
        return "Medium (1-10KB)"
    elseif size < 102400 then
        return "Large (10-100KB)"
    else
        return "XLarge (>100KB)"
    end
end

-- Track usage patterns
function AnalyticsService:trackUsagePattern(operation, dataStore, timestamp)
    local patterns = self.data.usagePatterns
    
    -- Peak hours (by hour of day)
    local hour = tonumber(os.date("%H", timestamp))
    patterns.peakHours[hour] = (patterns.peakHours[hour] or 0) + 1
    
    -- Common operations
    patterns.commonOperations[operation] = (patterns.commonOperations[operation] or 0) + 1
    
    -- Access frequency
    patterns.accessFrequency[dataStore] = (patterns.accessFrequency[dataStore] or 0) + 1
end

-- Get dashboard data
function AnalyticsService:getDashboardData()
    local sessionDuration = os.time() - self.sessionStart
    local summary = {
        totalOperations = self.data.operations.total,
        sessionDuration = sessionDuration,
        operationsPerMinute = self.data.operations.total / math.max(sessionDuration / 60, 1),
        errorRate = #self.data.operations.errors / math.max(self.data.operations.total, 1) * 100,
        averageLatency = self.data.performance.latency.average > 0 and self.data.performance.latency.average * 1000 or nil,
        dataStoresAccessed = self:getDataStoreCount(),
        totalDataSize = self.data.dataInsights.totalSize > 0 and self.data.dataInsights.totalSize or nil
    }
    -- Remove any summary fields that are nil
    for k, v in pairs(summary) do
        if v == nil then summary[k] = 'Not Available' end
    end
    return {
        summary = summary,
        performance = self:getPerformanceReport(),
        insights = self:getInsightsReport(),
        trends = self:getTrends(),
        recommendations = self:getRecommendations()
    }
end

-- Get unique DataStore count
function AnalyticsService:getDataStoreCount()
    local count = 0
    for _ in pairs(self.data.operations.byDataStore) do
        count = count + 1
    end
    return count
end

-- Get top DataStores by access
function AnalyticsService:getTopDataStores()
    local stores = {}
    for name, count in pairs(self.data.operations.byDataStore) do
        table.insert(stores, {name = name, operations = count})
    end
    
    table.sort(stores, function(a, b) return a.operations > b.operations end)
    
    local top5 = {}
    for i = 1, math.min(5, #stores) do
        table.insert(top5, stores[i])
    end
    
    return top5
end

-- Get trends analysis
function AnalyticsService:getTrends()
    local timeline = self.data.operations.timeline
    if #timeline < 5 then
        return {
            performance = "insufficient_data",
            usage = "insufficient_data",
            errors = "stable"
        }
    end
    
    -- Recent vs overall performance
    local recentSamples = {}
    for i = math.max(1, #timeline - 9), #timeline do
        table.insert(recentSamples, timeline[i].latency)
    end
    
    local recentAvg = 0
    for _, latency in ipairs(recentSamples) do
        recentAvg = recentAvg + latency
    end
    recentAvg = recentAvg / #recentSamples
    
    local overallAvg = self.data.performance.latency.average
    
    local performanceTrend = "stable"
    if recentAvg > overallAvg * 1.2 then
        performanceTrend = "degrading"
    elseif recentAvg < overallAvg * 0.8 then
        performanceTrend = "improving"
    end
    
    return {
        performance = performanceTrend,
        usage = "active",
        errors = #self.data.operations.errors > 0 and "detected" or "none"
    }
end

-- Generate recommendations
function AnalyticsService:getRecommendations()
    local recommendations = {}
    
    -- Performance recommendation
    if self.data.performance.latency.average > 0.5 then
        table.insert(recommendations, {
            type = "performance",
            title = "High Latency",
            description = "Operations are taking longer than expected",
            priority = "high"
        })
    end
    
    -- Error rate recommendation
    local errorRate = #self.data.operations.errors / math.max(self.data.operations.total, 1) * 100
    if errorRate > 5 then
        table.insert(recommendations, {
            type = "reliability",
            title = "High Error Rate",
            description = string.format("%.1f%% of operations failed", errorRate),
            priority = "high"
        })
    end
    
    -- Data size recommendation
    local avgSize = self.data.dataInsights.totalSize / math.max(self.data.dataInsights.totalKeys, 1)
    if avgSize > 50 * 1024 then
        table.insert(recommendations, {
            type = "optimization",
            title = "Large Data Objects",
            description = "Consider optimizing data structure",
            priority = "medium"
        })
    end
    
    return recommendations
end

-- Export analytics data
function AnalyticsService:exportData(format)
    format = format or "json"
    local data = self:getDashboardData()
    
    if format == "json" then
        return HttpService:JSONEncode(data)
    elseif format == "csv" then
        local csv = "Metric,Value\n"
        csv = csv .. "Total Operations," .. data.summary.totalOperations .. "\n"
        csv = csv .. "Average Latency," .. string.format("%.2f", data.summary.averageLatency) .. "\n"
        csv = csv .. "Error Rate," .. string.format("%.2f", data.summary.errorRate) .. "\n"
        return csv
    end
    
    return data
end

function AnalyticsService:cleanup()
    if self.data then
        self.data = nil
    end
    debugLog("Analytics Service cleanup complete", "INFO")
end

-- Static cleanup for service-level cleanup
function AnalyticsService.cleanup()
    debugLog("Analytics Service cleanup complete", "INFO")
end

return AnalyticsService 