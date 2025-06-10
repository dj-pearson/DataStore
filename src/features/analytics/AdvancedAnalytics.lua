-- Advanced Analytics & Insights System
-- Tracks usage patterns, data size trends, and performance metrics
-- Part of DataStore Manager Pro - Phase 2.3

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local AdvancedAnalytics = {}

function AdvancedAnalytics.new()
    local self = setmetatable({}, {__index = AdvancedAnalytics})
    
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
            growthTrends = {},
            dataStoreMetrics = {}
        },
        
        -- Usage patterns
        usagePatterns = {
            peakHours = {},
            commonOperations = {},
            userBehavior = {},
            accessFrequency = {},
            sessionPatterns = {}
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
    
    debugLog("Advanced Analytics initialized with comprehensive tracking", "INFO")
    return self
end

-- Track operation performance and analytics
function AdvancedAnalytics:trackOperation(operationType, dataStore, key, startTime, endTime, dataSize, success, errorMessage)
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
    
    debugLog(string.format("Analytics: Tracked %s operation on %s (%.2fms, %s)", 
        operationType, dataStore, latency * 1000, success and "success" or "error"))
end

-- Update latency metrics
function AdvancedAnalytics:updateLatencyMetrics(latency)
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
function AdvancedAnalytics:trackDataSize(dataStore, key, size)
    local insights = self.analytics.dataInsights
    
    -- Update totals
    insights.totalSize = insights.totalSize + size
    insights.totalKeys = insights.totalKeys + 1
    insights.averageKeySize = insights.totalSize / insights.totalKeys
    
    -- Track size distribution
    local sizeCategory = self:categorizeSizeRange(size)
    insights.sizeDistribution[sizeCategory] = (insights.sizeDistribution[sizeCategory] or 0) + 1
    
    -- Track per-DataStore metrics
    if not insights.dataStoreMetrics[dataStore] then
        insights.dataStoreMetrics[dataStore] = {
            keyCount = 0,
            totalSize = 0,
            averageSize = 0,
            lastAccessed = os.time(),
            keys = {}
        }
    end
    
    local dsMetrics = insights.dataStoreMetrics[dataStore]
    dsMetrics.keyCount = dsMetrics.keyCount + 1
    dsMetrics.totalSize = dsMetrics.totalSize + size
    dsMetrics.averageSize = dsMetrics.totalSize / dsMetrics.keyCount
    dsMetrics.lastAccessed = os.time()
    
    -- Track individual key info
    dsMetrics.keys[key] = {
        size = size,
        lastAccessed = os.time(),
        accessCount = (dsMetrics.keys[key] and dsMetrics.keys[key].accessCount or 0) + 1
    }
end

-- Categorize data size ranges
function AdvancedAnalytics:categorizeSizeRange(size)
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
function AdvancedAnalytics:trackUsagePattern(operationType, dataStore, timestamp)
    local patterns = self.analytics.usagePatterns
    
    -- Track peak hours
    local hour = tonumber(os.date("%H", timestamp))
    patterns.peakHours[hour] = (patterns.peakHours[hour] or 0) + 1
    
    -- Track common operations
    patterns.commonOperations[operationType] = (patterns.commonOperations[operationType] or 0) + 1
    
    -- Track access frequency per DataStore
    patterns.accessFrequency[dataStore] = (patterns.accessFrequency[dataStore] or 0) + 1
end

-- Update timeframe tracking
function AdvancedAnalytics:updateTimeframeTracking(timestamp)
    local timeframe = os.date("%Y-%m-%d %H", timestamp) -- Hourly buckets
    self.analytics.operations.byTimeframe[timeframe] = (self.analytics.operations.byTimeframe[timeframe] or 0) + 1
end

-- Generate comprehensive analytics report
function AdvancedAnalytics:generateReport()
    local ops = self.analytics.operations
    local perf = self.analytics.performance
    local insights = self.analytics.dataInsights
    local patterns = self.analytics.usagePatterns
    local session = self.analytics.session
    local sessionDuration = os.time() - session.startTime
    
    return {
        -- Executive summary
        summary = {
            totalOperations = ops.total,
            sessionDuration = sessionDuration,
            averageLatency = perf.latency.average,
            errorRate = #ops.errors / math.max(ops.total, 1) * 100,
            dataStoresAccessed = Utils.Table.length(insights.dataStoreMetrics)
        },
        
        -- Performance insights
        performance = {
            latency = perf.latency,
            throughput = perf.throughput,
            efficiency = self:calculateEfficiencyMetrics()
        },
        
        -- Data insights
        dataInsights = {
            totalSize = insights.totalSize,
            totalKeys = insights.totalKeys,
            averageKeySize = insights.averageKeySize,
            sizeDistribution = insights.sizeDistribution,
            topDataStores = self:getTopDataStoresBySize()
        },
        
        -- Usage patterns
        usagePatterns = {
            peakHour = self:getPeakUsageHour(),
            mostUsedOperation = self:getMostUsedOperation(),
            mostAccessedDataStore = self:getMostAccessedDataStore(),
            operationDistribution = ops.byType,
            accessFrequency = patterns.accessFrequency
        },
        
        -- Recommendations
        recommendations = self:generateRecommendations(),
        
        -- Raw data for advanced users
        rawData = {
            operations = ops,
            performance = perf,
            patterns = patterns,
            usageDistribution = self:getUsageDistribution()
        }
    }
end

-- Generate trend analysis
function AdvancedAnalytics:generateTrendsStats()
    return {
        performance = self:getPerformanceTrend(),
        usage = self:getUsageTrend(),
        errors = self:getErrorTrend(),
        growth = self:getGrowthTrend(),
        predictions = self:generatePredictions()
    }
end

-- Generate chart data for visualization
function AdvancedAnalytics:generateChartData()
    return {
        latencyOverTime = self:getLatencyChartData(),
        operationsByType = self:getOperationsByTypeChartData(),
        dataStoreSizes = self:getDataStoreSizeChartData(),
        usageHeatmap = self:getUsageHeatmapData(),
        errorTimeline = self:getErrorTimelineData()
    }
end

-- Helper functions for analytics calculations
function AdvancedAnalytics:getTopDataStoresBySize()
    local dataStores = {}
    
    for name, metrics in pairs(self.analytics.dataInsights.dataStoreMetrics) do
        table.insert(dataStores, {
            name = name,
            totalSize = metrics.totalSize,
            keyCount = metrics.keyCount,
            averageSize = metrics.averageSize,
            lastAccessed = metrics.lastAccessed
        })
    end
    
    table.sort(dataStores, function(a, b) return a.totalSize > b.totalSize end)
    return dataStores
end

function AdvancedAnalytics:getTopDataStoresByAccess()
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

function AdvancedAnalytics:getTopDataStoresByKeyCount()
    local dataStores = {}
    
    for name, metrics in pairs(self.analytics.dataInsights.dataStoreMetrics) do
        table.insert(dataStores, {
            name = name,
            keyCount = metrics.keyCount,
            totalSize = metrics.totalSize
        })
    end
    
    table.sort(dataStores, function(a, b) return a.keyCount > b.keyCount end)
    return dataStores
end

function AdvancedAnalytics:getPeakUsageHour()
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

function AdvancedAnalytics:getMostUsedOperation()
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

function AdvancedAnalytics:getMostAccessedDataStore()
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

-- Generate intelligent recommendations
function AdvancedAnalytics:generateRecommendations()
    local recommendations = {}
    
    -- Performance recommendations
    if self.analytics.performance.latency.average > 0.5 then
        table.insert(recommendations, {
            type = "performance",
            priority = "high",
            title = "High Latency Detected",
            description = "Average operation latency is above 500ms. Consider optimizing data structure or checking network conditions.",
            impact = "Performance",
            actionItems = {
                "Check network connectivity",
                "Review data structure complexity",
                "Consider data compression",
                "Implement caching strategies"
            }
        })
    end
    
    -- Data size recommendations
    local avgSize = self.analytics.dataInsights.averageKeySize
    if avgSize > 50 * 1024 then
        table.insert(recommendations, {
            type = "data",
            priority = "medium", 
            title = "Large Data Objects Detected",
            description = "Average key size is " .. math.floor(avgSize / 1024) .. "KB. Consider data optimization.",
            impact = "Storage & Performance",
            actionItems = {
                "Implement data compression",
                "Split large objects into smaller chunks",
                "Remove unnecessary data fields",
                "Use more efficient data formats"
            }
        })
    end
    
    -- Error rate recommendations
    local errorRate = #self.analytics.operations.errors / math.max(self.analytics.operations.total, 1) * 100
    if errorRate > 5 then
        table.insert(recommendations, {
            type = "reliability",
            priority = "high",
            title = "High Error Rate",
            description = string.format("Error rate is %.1f%%. Review error patterns and implement better handling.", errorRate),
            impact = "Reliability",
            actionItems = {
                "Review recent error logs",
                "Implement retry mechanisms",
                "Add data validation",
                "Improve error handling"
            }
        })
    end
    
    -- Usage pattern recommendations
    local peakHour = self:getPeakUsageHour()
    if peakHour.count > self.analytics.operations.total * 0.3 then
        table.insert(recommendations, {
            type = "optimization",
            priority = "low",
            title = "Usage Pattern Optimization",
            description = string.format("%.1f%% of operations occur during hour %d. Consider load balancing.", 
                peakHour.count / self.analytics.operations.total * 100, peakHour.hour),
            impact = "Resource Optimization",
            actionItems = {
                "Implement rate limiting during peak hours",
                "Consider background processing",
                "Optimize for peak usage patterns"
            }
        })
    end
    
    return recommendations
end

-- Calculate efficiency metrics
function AdvancedAnalytics:calculateEfficiencyMetrics()
    local session = self.analytics.session
    local sessionDuration = os.time() - session.startTime
    
    return {
        operationsPerMinute = session.operationsThisSession / math.max(sessionDuration / 60, 1),
        averageOperationTime = self.analytics.performance.latency.average,
        dataProcessingRate = self.analytics.dataInsights.totalSize / math.max(sessionDuration, 1)
    }
end

-- Get usage distribution
function AdvancedAnalytics:getUsageDistribution()
    local total = self.analytics.operations.total
    local distribution = {}
    
    for operation, count in pairs(self.analytics.operations.byType) do
        distribution[operation] = {
            count = count,
            percentage = count / math.max(total, 1) * 100
        }
    end
    
    return distribution
end

-- Stub methods for chart data (would be implemented based on UI requirements)
function AdvancedAnalytics:getLatencyChartData()
    return {} -- Implementation depends on chart library
end

function AdvancedAnalytics:getOperationsByTypeChartData()
    return {} -- Implementation depends on chart library
end

function AdvancedAnalytics:getDataStoreSizeChartData()
    return {} -- Implementation depends on chart library
end

function AdvancedAnalytics:getUsageHeatmapData()
    return {} -- Implementation depends on chart library
end

function AdvancedAnalytics:getErrorTimelineData()
    return {} -- Implementation depends on chart library
end

-- Stub methods for trend analysis (would implement actual trend calculation)
function AdvancedAnalytics:getPerformanceTrend()
    return {} -- Would analyze performance over time
end

function AdvancedAnalytics:getUsageTrend()
    return {} -- Would analyze usage patterns over time
end

function AdvancedAnalytics:getErrorTrend()
    return {} -- Would analyze error patterns over time
end

function AdvancedAnalytics:getGrowthTrend()
    return {} -- Would analyze data growth trends
end

function AdvancedAnalytics:generatePredictions()
    return {} -- Would generate predictions based on trends
end

-- Cleanup function
function AdvancedAnalytics.cleanup()
    debugLog("Advanced Analytics cleanup complete", "INFO")
end

return AdvancedAnalytics 