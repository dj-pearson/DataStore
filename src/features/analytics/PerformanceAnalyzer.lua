-- Advanced Performance Analytics System
-- Tracks usage patterns, data trends, and performance metrics
-- Part of DataStore Manager Pro - Phase 2.3

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local PerformanceAnalyzer = {}

function PerformanceAnalyzer.new()
    local self = setmetatable({}, {__index = PerformanceAnalyzer})
    
    -- Analytics data storage
    self.analytics = {
        -- Operation tracking
        operations = {
            total = 0,
            byType = {},
            byDataStore = {},
            byTimeframe = {},
            errors = {}
        },
        
        -- Performance metrics
        performance = {
            latency = {
                average = 0,
                min = math.huge,
                max = 0,
                samples = {}
            },
            throughput = {
                requestsPerSecond = 0,
                bytesPerSecond = 0,
                history = {}
            }
        },
        
        -- Data insights
        dataInsights = {
            totalDataStores = 0,
            totalKeys = 0,
            totalSize = 0,
            averageKeySize = 0,
            dataTypes = {},
            sizeDistribution = {},
            growthTrends = {}
        },
        
        -- Usage patterns
        usagePatterns = {
            peakHours = {},
            commonOperations = {},
            userBehavior = {},
            accessFrequency = {}
        },
        
        -- Session tracking
        session = {
            startTime = os.time(),
            operationsThisSession = 0,
            dataExplored = {},
            timeSpent = {}
        }
    }
    
    -- Performance tracking
    self.performanceBuffer = {}
    self.metricsUpdateInterval = 5 -- seconds
    self.lastMetricsUpdate = os.time()
    
    debugLog("Performance Analyzer initialized with advanced analytics", "INFO")
    return self
end

-- Track operation performance
function PerformanceAnalyzer:trackOperation(operationType, dataStore, key, startTime, endTime, dataSize, success, errorMessage)
    local latency = endTime - startTime
    local currentTime = os.time()
    
    -- Update operation counters
    self.analytics.operations.total = self.analytics.operations.total + 1
    self.analytics.operations.byType[operationType] = (self.analytics.operations.byType[operationType] or 0) + 1
    self.analytics.operations.byDataStore[dataStore] = (self.analytics.operations.byDataStore[dataStore] or 0) + 1
    self.analytics.session.operationsThisSession = self.analytics.session.operationsThisSession + 1
    
    -- Track errors
    if not success and errorMessage then
        table.insert(self.analytics.operations.errors, {
            type = operationType,
            dataStore = dataStore,
            key = key,
            error = errorMessage,
            timestamp = currentTime
        })
    end
    
    -- Update performance metrics
    self:updateLatencyMetrics(latency)
    
    -- Track data size if provided
    if dataSize then
        self:trackDataSize(dataStore, key, dataSize)
    end
    
    -- Track usage patterns
    self:trackUsagePattern(operationType, dataStore, currentTime)
    
    -- Update timeframe tracking
    self:updateTimeframeTracking(currentTime)
    
    debugLog(string.format("Tracked operation: %s on %s (%.2fms, %s)", 
        operationType, dataStore, latency * 1000, success and "success" or "error"))
end

-- Update latency metrics
function PerformanceAnalyzer:updateLatencyMetrics(latency)
    local perf = self.analytics.performance.latency
    
    -- Update min/max
    perf.min = math.min(perf.min, latency)
    perf.max = math.max(perf.max, latency)
    
    -- Add to samples and maintain buffer size
    table.insert(perf.samples, latency)
    if #perf.samples > 1000 then
        table.remove(perf.samples, 1)
    end
    
    -- Calculate running average
    local sum = 0
    for _, sample in ipairs(perf.samples) do
        sum = sum + sample
    end
    perf.average = sum / #perf.samples
end

-- Track data size insights
function PerformanceAnalyzer:trackDataSize(dataStore, _, size)
    local insights = self.analytics.dataInsights
    
    -- Update totals
    insights.totalSize = insights.totalSize + size
    insights.totalKeys = insights.totalKeys + 1
    insights.averageKeySize = insights.totalSize / insights.totalKeys
    
    -- Track size distribution
    local sizeCategory = self:categorizeSizeRange(size)
    insights.sizeDistribution[sizeCategory] = (insights.sizeDistribution[sizeCategory] or 0) + 1
    
    -- Track per-DataStore metrics
    if not insights.dataStoreMetrics then
        insights.dataStoreMetrics = {}
    end
    
    if not insights.dataStoreMetrics[dataStore] then
        insights.dataStoreMetrics[dataStore] = {
            keyCount = 0,
            totalSize = 0,
            averageSize = 0,
            lastAccessed = os.time()
        }
    end
    
    local dsMetrics = insights.dataStoreMetrics[dataStore]
    dsMetrics.keyCount = dsMetrics.keyCount + 1
    dsMetrics.totalSize = dsMetrics.totalSize + size
    dsMetrics.averageSize = dsMetrics.totalSize / dsMetrics.keyCount
    dsMetrics.lastAccessed = os.time()
end

-- Categorize data size ranges
function PerformanceAnalyzer:categorizeSizeRange(size)
    if size < 1024 then
        return "Small (< 1KB)"
    elseif size < 10 * 1024 then
        return "Medium (1-10KB)"
    elseif size < 100 * 1024 then
        return "Large (10-100KB)"
    else
        return "XLarge (> 100KB)"
    end
end

-- Track usage patterns
function PerformanceAnalyzer:trackUsagePattern(operationType, dataStore, timestamp)
    local patterns = self.analytics.usagePatterns
    local hour = tonumber(os.date("%H", timestamp))
    
    -- Track peak hours
    patterns.peakHours[hour] = (patterns.peakHours[hour] or 0) + 1
    
    -- Track common operations
    patterns.commonOperations[operationType] = (patterns.commonOperations[operationType] or 0) + 1
    
    -- Track DataStore access frequency
    patterns.accessFrequency[dataStore] = (patterns.accessFrequency[dataStore] or 0) + 1
end

-- Update timeframe tracking
function PerformanceAnalyzer:updateTimeframeTracking(timestamp)
    local timeframes = self.analytics.operations.byTimeframe
    local timeframe = os.date("%Y-%m-%d %H", timestamp) -- Hourly buckets
    
    -- Track by timeframe
    timeframes[timeframe] = (timeframes[timeframe] or 0) + 1
end

-- Get comprehensive analytics report
function PerformanceAnalyzer:getAnalyticsReport()
    local report = {
        summary = self:generateSummaryReport(),
        performance = self:generatePerformanceReport(),
        dataInsights = self:generateDataInsightsReport(),
        usagePatterns = self:generateUsagePatternsReport(),
        trends = self:generateTrendsReport(),
        recommendations = self:generateRecommendations()
    }
    
    return report
end

-- Generate summary report
function PerformanceAnalyzer:generateSummaryReport()
    local ops = self.analytics.operations
    local session = self.analytics.session
    
    return {
        totalOperations = ops.total,
        sessionOperations = session.operationsThisSession,
        sessionDuration = os.time() - session.startTime,
        errorRate = #ops.errors / math.max(ops.total, 1) * 100,
        averageLatency = self.analytics.performance.latency.average * 1000, -- Convert to ms
        dataStoresExplored = self.analytics.dataInsights.totalDataStores,
        totalKeysAccessed = self.analytics.dataInsights.totalKeys
    }
end

-- Generate performance report
function PerformanceAnalyzer:generatePerformanceReport()
    local perf = self.analytics.performance
    
    return {
        latency = {
            average = perf.latency.average * 1000,
            min = perf.latency.min * 1000,
            max = perf.latency.max * 1000,
            samples = #perf.latency.samples
        },
        throughput = perf.throughput,
        recentPerformance = self:getRecentPerformanceTrend()
    }
end

-- Generate data insights report
function PerformanceAnalyzer:generateDataInsightsReport()
    local insights = self.analytics.dataInsights
    
    return {
        overview = {
            totalDataStores = insights.totalDataStores,
            totalKeys = insights.totalKeys,
            totalSize = insights.totalSize,
            averageKeySize = insights.averageKeySize
        },
        sizeDistribution = insights.sizeDistribution,
        dataStoreMetrics = insights.dataStoreMetrics or {},
        topDataStoresBySize = self:getTopDataStoresBySize(),
        topDataStoresByAccess = self:getTopDataStoresByAccess()
    }
end

-- Generate usage patterns report
function PerformanceAnalyzer:generateUsagePatternsReport()
    local patterns = self.analytics.usagePatterns
    
    return {
        peakHours = patterns.peakHours,
        commonOperations = patterns.commonOperations,
        accessFrequency = patterns.accessFrequency,
        peakUsageHour = self:getPeakUsageHour(),
        mostUsedOperation = self:getMostUsedOperation(),
        mostAccessedDataStore = self:getMostAccessedDataStore()
    }
end

-- Generate trends report
function PerformanceAnalyzer:generateTrendsReport()
    return {
        performanceTrend = self:getPerformanceTrend(),
        usageTrend = self:getUsageTrend(),
        errorTrend = self:getErrorTrend(),
        growthTrend = self:getGrowthTrend()
    }
end

-- Generate recommendations
function PerformanceAnalyzer:generateRecommendations()
    local recommendations = {}
    
    -- Performance recommendations
    if self.analytics.performance.latency.average > 0.5 then
        table.insert(recommendations, {
            type = "performance",
            priority = "high",
            title = "High Latency Detected",
            description = "Average operation latency is above 500ms. Consider optimizing data structure or checking network conditions.",
            impact = "Performance"
        })
    end
    
    -- Data size recommendations
    local avgSize = self.analytics.dataInsights.averageKeySize
    if avgSize > 50 * 1024 then
        table.insert(recommendations, {
            type = "data",
            priority = "medium",
            title = "Large Data Objects",
            description = "Average key size is " .. math.floor(avgSize / 1024) .. "KB. Consider data compression or restructuring.",
            impact = "Storage & Performance"
        })
    end
    
    -- Error rate recommendations
    local errorRate = #self.analytics.operations.errors / math.max(self.analytics.operations.total, 1) * 100
    if errorRate > 5 then
        table.insert(recommendations, {
            type = "reliability",
            priority = "high",
            title = "High Error Rate",
            description = string.format("Error rate is %.1f%%. Review recent errors and implement better error handling.", errorRate),
            impact = "Reliability"
        })
    end
    
    return recommendations
end

-- Helper functions for analytics
function PerformanceAnalyzer:getRecentPerformanceTrend()
    local samples = self.analytics.performance.latency.samples
    if #samples < 10 then return "insufficient_data" end
    
    local recent = {}
    for i = math.max(1, #samples - 9), #samples do
        table.insert(recent, samples[i])
    end
    
    local recentAvg = 0
    for _, sample in ipairs(recent) do
        recentAvg = recentAvg + sample
    end
    recentAvg = recentAvg / #recent
    
    local overallAvg = self.analytics.performance.latency.average
    
    if recentAvg > overallAvg * 1.2 then
        return "degrading"
    elseif recentAvg < overallAvg * 0.8 then
        return "improving"
    else
        return "stable"
    end
end

function PerformanceAnalyzer:getPeakUsageHour()
    local peakHour = 0
    local maxUsage = 0
    
    for hour, count in pairs(self.analytics.usagePatterns.peakHours) do
        if count > maxUsage then
            maxUsage = count
            peakHour = hour
        end
    end
    
    return {hour = peakHour, count = maxUsage}
end

function PerformanceAnalyzer:getMostUsedOperation()
    local mostUsed = ""
    local maxCount = 0
    
    for operation, count in pairs(self.analytics.usagePatterns.commonOperations) do
        if count > maxCount then
            maxCount = count
            mostUsed = operation
        end
    end
    
    return {operation = mostUsed, count = maxCount}
end

function PerformanceAnalyzer:getMostAccessedDataStore()
    local mostAccessed = ""
    local maxAccess = 0
    
    for dataStore, count in pairs(self.analytics.usagePatterns.accessFrequency) do
        if count > maxAccess then
            maxAccess = count
            mostAccessed = dataStore
        end
    end
    
    return {dataStore = mostAccessed, count = maxAccess}
end

function PerformanceAnalyzer:getTopDataStoresBySize()
    local dataStores = {}
    
    if self.analytics.dataInsights.dataStoreMetrics then
        for name, metrics in pairs(self.analytics.dataInsights.dataStoreMetrics) do
            table.insert(dataStores, {
                name = name,
                totalSize = metrics.totalSize,
                keyCount = metrics.keyCount,
                averageSize = metrics.averageSize
            })
        end
        
        table.sort(dataStores, function(a, b) return a.totalSize > b.totalSize end)
    end
    
    return dataStores
end

function PerformanceAnalyzer:getTopDataStoresByAccess()
    local dataStores = {}
    
    for name, count in pairs(self.analytics.usagePatterns.accessFrequency) do
        table.insert(dataStores, {
            name = name,
            accessCount = count
        })
    end
    
    table.sort(dataStores, function(a, b) return a.accessCount > b.accessCount end)
    return dataStores
end

-- Trend analysis functions
function PerformanceAnalyzer:getPerformanceTrend()
    return self:getRecentPerformanceTrend()
end

function PerformanceAnalyzer:getUsageTrend()
    -- Simple implementation - can be enhanced
    local recentOps = self.analytics.session.operationsThisSession
    local sessionTime = os.time() - self.analytics.session.startTime
    local opsPerMinute = recentOps / math.max(sessionTime / 60, 1)
    
    if opsPerMinute > 10 then
        return "high_activity"
    elseif opsPerMinute > 3 then
        return "moderate_activity"
    else
        return "low_activity"
    end
end

function PerformanceAnalyzer:getErrorTrend()
    local recentErrors = 0
    local currentTime = os.time()
    
    for _, error in ipairs(self.analytics.operations.errors) do
        if currentTime - error.timestamp < 300 then -- Last 5 minutes
            recentErrors = recentErrors + 1
        end
    end
    
    if recentErrors > 3 then
        return "increasing"
    elseif recentErrors > 0 then
        return "stable"
    else
        return "none"
    end
end

function PerformanceAnalyzer:getGrowthTrend()
    -- Placeholder for data growth analysis
    return "stable"
end

-- Export analytics data
function PerformanceAnalyzer:exportAnalytics(format)
    format = format or "json"
    local report = self:getAnalyticsReport()
    
    if format == "json" then
        return HttpService:JSONEncode(report)
    elseif format == "csv" then
        return self:convertToCSV(report)
    else
        return report
    end
end

-- Convert to CSV format
function PerformanceAnalyzer:convertToCSV(report)
    local csv = "Metric,Value\n"
    csv = csv .. "Total Operations," .. report.summary.totalOperations .. "\n"
    csv = csv .. "Session Operations," .. report.summary.sessionOperations .. "\n"
    csv = csv .. "Average Latency (ms)," .. string.format("%.2f", report.summary.averageLatency) .. "\n"
    csv = csv .. "Error Rate (%)," .. string.format("%.2f", report.summary.errorRate) .. "\n"
    csv = csv .. "DataStores Explored," .. report.summary.dataStoresExplored .. "\n"
    csv = csv .. "Total Keys Accessed," .. report.summary.totalKeysAccessed .. "\n"
    
    return csv
end

-- Cleanup function
function PerformanceAnalyzer:cleanup()
    if self.analytics then
        self.analytics = nil
    end
    if self.performanceBuffer then
        self.performanceBuffer = nil
    end
    debugLog("Performance Analyzer cleanup complete", "INFO")
end

-- Static cleanup for service-level cleanup
function PerformanceAnalyzer.cleanup()
    debugLog("Performance Analyzer cleanup complete", "INFO")
end

return PerformanceAnalyzer 