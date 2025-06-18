-- PluginAnalyticsService.lua
-- Comprehensive analytics service for DataStore Manager Pro
-- Collects, analyzes, and persists plugin usage data and game DataStore analytics

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

local PluginAnalyticsService = {}
PluginAnalyticsService.__index = PluginAnalyticsService

-- Analytics collection intervals (in seconds)
local COLLECTION_INTERVALS = {
    REAL_TIME = 30,        -- Real-time stats every 30 seconds
    HOURLY_SUMMARY = 3600, -- Hourly summaries
    DAILY_SUMMARY = 86400, -- Daily summaries
    PERFORMANCE_SAMPLE = 60 -- Performance metrics every minute
}

function PluginAnalyticsService.new(pluginDataStore, logger)
    local self = setmetatable({}, PluginAnalyticsService)
    
    self.pluginDataStore = pluginDataStore
    self.logger = logger
    self.isActive = false
    
    -- Analytics state tracking
    self.analyticsState = {
        -- Session tracking
        sessionId = tostring(tick()) .. "_" .. tostring(math.random(1000, 9999)),
        sessionStartTime = tick(),
        lastRealTimeCollection = 0,
        lastHourlyCollection = 0,
        lastDailyCollection = 0,
        lastPerformanceCollection = 0,
        
        -- Usage metrics
        usage = {
            -- UI interactions
            viewChanges = 0,
            buttonClicks = 0,
            searchQueries = 0,
            dataRefreshes = 0,
            settingsChanges = 0,
            
            -- DataStore operations
            datastoreConnections = 0,
            keysExplored = 0,
            dataViewed = 0,
            dataModified = 0,
            
            -- Analysis operations
            analysisRuns = 0,
            reportsGenerated = 0,
            anomaliesDetected = 0,
            
            -- Error tracking
            errors = {},
            warnings = {},
        },
        
        -- Performance tracking
        performance = {
            averageResponseTime = 0,
            totalRequests = 0,
            successfulRequests = 0,
            failedRequests = 0,
            cacheHitRate = 0,
            memoryUsage = 0,
            
            -- Operation timings
            operationTimes = {},
            slowOperations = {},
        },
        
        -- DataStore analytics
        datastoreAnalytics = {
            totalDataStores = 0,
            totalKeys = 0,
            totalDataSize = 0,
            
            -- Pattern analysis
            keyPatterns = {},
            dataPatterns = {},
            accessPatterns = {},
            
            -- Anomaly detection
            anomalies = {},
            suspiciousActivity = {},
        },
        
        -- User behavior
        userBehavior = {
            mostUsedFeatures = {},
            navigationPaths = {},
            timeSpentInViews = {},
            preferredSettings = {},
        }
    }
    
    -- Collection connections
    self.connections = {}
    
    return self
end

-- ==================== LIFECYCLE MANAGEMENT ====================

-- Start analytics collection
function PluginAnalyticsService:start()
    if self.isActive then
        return true
    end
    
    self.isActive = true
    self.analyticsState.sessionStartTime = tick()
    
    -- Start collection loops
    self:startRealTimeCollection()
    self:startPerformanceCollection()
    
    if self.logger then
        self.logger:info("ANALYTICS", "🚀 Plugin analytics service started (Session: " .. self.analyticsState.sessionId .. ")")
    end
    
    return true
end

-- Stop analytics collection
function PluginAnalyticsService:stop()
    if not self.isActive then
        return true
    end
    
    self.isActive = false
    
    -- Save final analytics snapshot
    self:saveCurrentAnalytics()
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    if self.logger then
        self.logger:info("ANALYTICS", "⏹️ Plugin analytics service stopped")
    end
    
    return true
end

-- ==================== DATA COLLECTION ====================

-- Start real-time data collection
function PluginAnalyticsService:startRealTimeCollection()
    local connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Real-time collection
        if currentTime - self.analyticsState.lastRealTimeCollection >= COLLECTION_INTERVALS.REAL_TIME then
            self:collectRealTimeData()
            self.analyticsState.lastRealTimeCollection = currentTime
        end
        
        -- Hourly collection
        if currentTime - self.analyticsState.lastHourlyCollection >= COLLECTION_INTERVALS.HOURLY_SUMMARY then
            self:generateHourlySummary()
            self.analyticsState.lastHourlyCollection = currentTime
        end
        
        -- Daily collection
        if currentTime - self.analyticsState.lastDailyCollection >= COLLECTION_INTERVALS.DAILY_SUMMARY then
            self:generateDailySummary()
            self.analyticsState.lastDailyCollection = currentTime
        end
    end)
    
    table.insert(self.connections, connection)
end

-- Start performance monitoring
function PluginAnalyticsService:startPerformanceCollection()
    local connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        if currentTime - self.analyticsState.lastPerformanceCollection >= COLLECTION_INTERVALS.PERFORMANCE_SAMPLE then
            self:collectPerformanceMetrics()
            self.analyticsState.lastPerformanceCollection = currentTime
        end
    end)
    
    table.insert(self.connections, connection)
end

-- Collect real-time analytics data
function PluginAnalyticsService:collectRealTimeData()
    if not self.isActive then return end
    
    local currentTime = tick()
    local sessionDuration = currentTime - self.analyticsState.sessionStartTime
    
    -- Collect current state
    local realTimeData = {
        sessionId = self.analyticsState.sessionId,
        timestamp = currentTime,
        sessionDuration = sessionDuration,
        
        -- Current usage snapshot
        usage = Utils.deepCopy(self.analyticsState.usage),
        performance = Utils.deepCopy(self.analyticsState.performance),
        datastoreAnalytics = Utils.deepCopy(self.analyticsState.datastoreAnalytics),
        
        -- System info
        systemInfo = self:collectSystemInfo(),
    }
    
    -- Save to plugin DataStore
    if self.pluginDataStore then
        self.pluginDataStore:saveRealTimeAnalytics(realTimeData)
    end
    
    if self.logger then
        self.logger:info("ANALYTICS", "📊 Real-time data collected (Session: " .. string.format("%.1f", sessionDuration) .. "s)")
    end
end

-- Generate hourly summary
function PluginAnalyticsService:generateHourlySummary()
    if not self.isActive then return end
    
    local currentTime = tick()
    local hour = math.floor(currentTime / 3600)
    
    local hourlySummary = {
        hour = hour,
        timestamp = currentTime,
        sessionId = self.analyticsState.sessionId,
        
        -- Aggregated metrics
        totalInteractions = self:getTotalInteractions(),
        topFeatures = self:getTopFeatures(),
        performanceSummary = self:getPerformanceSummary(),
        errorSummary = self:getErrorSummary(),
        
        -- DataStore insights
        datastoreInsights = self:getDataStoreInsights(),
        
        -- User behavior patterns
        behaviorPatterns = self:getBehaviorPatterns(),
    }
    
    -- Save hourly summary
    if self.pluginDataStore then
        self.pluginDataStore:saveHourlyAnalytics(hourlySummary)
    end
    
    if self.logger then
        self.logger:info("ANALYTICS", "📈 Hourly summary generated (Hour: " .. hour .. ")")
    end
end

-- Generate daily summary
function PluginAnalyticsService:generateDailySummary()
    if not self.isActive then return end
    
    local currentTime = tick()
    local day = math.floor(currentTime / 86400)
    
    local dailySummary = {
        day = day,
        timestamp = currentTime,
        sessionId = self.analyticsState.sessionId,
        
        -- Daily aggregates
        totalSessions = 1, -- This would be aggregated across multiple sessions
        totalSessionTime = currentTime - self.analyticsState.sessionStartTime,
        totalInteractions = self:getTotalInteractions(),
        
        -- Feature usage analysis
        featureUsageAnalysis = self:getFeatureUsageAnalysis(),
        
        -- Performance analysis
        performanceAnalysis = self:getPerformanceAnalysis(),
        
        -- DataStore analysis
        datastoreAnalysis = self:getDataStoreAnalysis(),
        
        -- Insights and recommendations
        insights = self:generateInsights(),
        recommendations = self:generateRecommendations(),
    }
    
    -- Save daily summary
    if self.pluginDataStore then
        self.pluginDataStore:saveDailyAnalytics(dailySummary)
    end
    
    if self.logger then
        self.logger:info("ANALYTICS", "📊 Daily summary generated (Day: " .. day .. ")")
    end
end

-- Collect performance metrics
function PluginAnalyticsService:collectPerformanceMetrics()
    if not self.isActive then return end
    
    -- Get plugin DataStore stats if available
    local datastoreStats = nil
    if self.pluginDataStore and self.pluginDataStore.getStats then
        datastoreStats = self.pluginDataStore:getStats()
    end
    
    -- Update performance state
    if datastoreStats then
        self.analyticsState.performance.cacheHitRate = datastoreStats.analytics.cacheHitRate or 0
        self.analyticsState.performance.memoryUsage = datastoreStats.memory.estimatedSize or 0
        
        -- Update operation metrics
        if datastoreStats.analytics.operations then
            local ops = datastoreStats.analytics.operations
            self.analyticsState.performance.totalRequests = ops.reads + ops.writes
            self.analyticsState.performance.successfulRequests = ops.reads + ops.writes - ops.errors
            self.analyticsState.performance.failedRequests = ops.errors
        end
    end
    
    -- Collect garbage collection info
    collectgarbage("collect")
    local memoryUsage = collectgarbage("count")
    self.analyticsState.performance.memoryUsage = memoryUsage
    
    if self.logger then
        self.logger:debug("ANALYTICS", "⚡ Performance metrics updated")
    end
end

-- ==================== EVENT TRACKING ====================

-- Track UI interaction
function PluginAnalyticsService:trackUIInteraction(interactionType, details)
    if not self.isActive then return end
    
    local usage = self.analyticsState.usage
    
    if interactionType == "view_change" then
        usage.viewChanges = usage.viewChanges + 1
    elseif interactionType == "button_click" then
        usage.buttonClicks = usage.buttonClicks + 1
    elseif interactionType == "search_query" then
        usage.searchQueries = usage.searchQueries + 1
    elseif interactionType == "data_refresh" then
        usage.dataRefreshes = usage.dataRefreshes + 1
    elseif interactionType == "settings_change" then
        usage.settingsChanges = usage.settingsChanges + 1
    end
    
    -- Track feature usage
    if details and details.feature then
        local features = self.analyticsState.userBehavior.mostUsedFeatures
        features[details.feature] = (features[details.feature] or 0) + 1
    end
    
    -- Track navigation paths
    if details and details.fromView and details.toView then
        local paths = self.analyticsState.userBehavior.navigationPaths
        local pathKey = details.fromView .. " -> " .. details.toView
        paths[pathKey] = (paths[pathKey] or 0) + 1
    end
end

-- Track DataStore operation
function PluginAnalyticsService:trackDataStoreOperation(operationType, details)
    if not self.isActive then return end
    
    local usage = self.analyticsState.usage
    local analytics = self.analyticsState.datastoreAnalytics
    
    if operationType == "connection" then
        usage.datastoreConnections = usage.datastoreConnections + 1
    elseif operationType == "keys_explored" then
        usage.keysExplored = usage.keysExplored + 1
        if details and details.keyCount then
            analytics.totalKeys = analytics.totalKeys + details.keyCount
        end
    elseif operationType == "data_viewed" then
        usage.dataViewed = usage.dataViewed + 1
        if details and details.dataSize then
            analytics.totalDataSize = analytics.totalDataSize + details.dataSize
        end
    elseif operationType == "data_modified" then
        usage.dataModified = usage.dataModified + 1
    end
    
    -- Track key patterns
    if details and details.keyName then
        local patterns = analytics.keyPatterns
        local pattern = self:extractKeyPattern(details.keyName)
        patterns[pattern] = (patterns[pattern] or 0) + 1
    end
    
    -- Track access patterns
    if details and details.datastoreName then
        local patterns = analytics.accessPatterns
        patterns[details.datastoreName] = (patterns[details.datastoreName] or 0) + 1
    end
end

-- Track analysis operation
function PluginAnalyticsService:trackAnalysisOperation(operationType, details)
    if not self.isActive then return end
    
    local usage = self.analyticsState.usage
    
    if operationType == "analysis_run" then
        usage.analysisRuns = usage.analysisRuns + 1
    elseif operationType == "report_generated" then
        usage.reportsGenerated = usage.reportsGenerated + 1
    elseif operationType == "anomaly_detected" then
        usage.anomaliesDetected = usage.anomaliesDetected + 1
        
        -- Store anomaly details
        if details then
            table.insert(self.analyticsState.datastoreAnalytics.anomalies, {
                timestamp = tick(),
                type = details.type or "unknown",
                severity = details.severity or "low",
                details = details
            })
        end
    end
end

-- Track performance operation
function PluginAnalyticsService:trackPerformanceOperation(operationType, duration, success)
    if not self.isActive then return end
    
    local performance = self.analyticsState.performance
    
    -- Update totals
    performance.totalRequests = performance.totalRequests + 1
    if success then
        performance.successfulRequests = performance.successfulRequests + 1
    else
        performance.failedRequests = performance.failedRequests + 1
    end
    
    -- Update average response time
    local totalTime = performance.averageResponseTime * (performance.totalRequests - 1)
    performance.averageResponseTime = (totalTime + duration) / performance.totalRequests
    
    -- Track operation times
    if not performance.operationTimes[operationType] then
        performance.operationTimes[operationType] = {
            count = 0,
            totalTime = 0,
            averageTime = 0,
            maxTime = 0,
            minTime = math.huge
        }
    end
    
    local opTime = performance.operationTimes[operationType]
    opTime.count = opTime.count + 1
    opTime.totalTime = opTime.totalTime + duration
    opTime.averageTime = opTime.totalTime / opTime.count
    opTime.maxTime = math.max(opTime.maxTime, duration)
    opTime.minTime = math.min(opTime.minTime, duration)
    
    -- Track slow operations
    if duration > 5 then -- Operations taking more than 5 seconds
        table.insert(performance.slowOperations, {
            operation = operationType,
            duration = duration,
            timestamp = tick(),
            success = success
        })
        
        -- Keep only last 50 slow operations
        if #performance.slowOperations > 50 then
            table.remove(performance.slowOperations, 1)
        end
    end
    
    -- Record in plugin DataStore if available
    if self.pluginDataStore and self.pluginDataStore.recordPerformance then
        self.pluginDataStore:recordPerformance(operationType, duration, success)
    end
end

-- Track error occurrence
function PluginAnalyticsService:trackError(errorType, errorMessage, context)
    if not self.isActive then return end
    
    local errorEntry = {
        type = errorType,
        message = errorMessage,
        context = context,
        timestamp = tick(),
        sessionId = self.analyticsState.sessionId
    }
    
    table.insert(self.analyticsState.usage.errors, errorEntry)
    
    -- Keep only last 100 errors
    if #self.analyticsState.usage.errors > 100 then
        table.remove(self.analyticsState.usage.errors, 1)
    end
    
    if self.logger then
        self.logger:warn("ANALYTICS", "❌ Error tracked: " .. errorType .. " - " .. errorMessage)
    end
end

-- Track warning occurrence
function PluginAnalyticsService:trackWarning(warningType, warningMessage, context)
    if not self.isActive then return end
    
    local warningEntry = {
        type = warningType,
        message = warningMessage,
        context = context,
        timestamp = tick(),
        sessionId = self.analyticsState.sessionId
    }
    
    table.insert(self.analyticsState.usage.warnings, warningEntry)
    
    -- Keep only last 100 warnings
    if #self.analyticsState.usage.warnings > 100 then
        table.remove(self.analyticsState.usage.warnings, 1)
    end
end

-- ==================== DATA ANALYSIS ====================

-- Get total interactions count
function PluginAnalyticsService:getTotalInteractions()
    local usage = self.analyticsState.usage
    return usage.viewChanges + usage.buttonClicks + usage.searchQueries + 
           usage.dataRefreshes + usage.settingsChanges + usage.datastoreConnections
end

-- Get top used features
function PluginAnalyticsService:getTopFeatures(limit)
    limit = limit or 10
    local features = self.analyticsState.userBehavior.mostUsedFeatures
    
    local sortedFeatures = {}
    for feature, count in pairs(features) do
        table.insert(sortedFeatures, {feature = feature, count = count})
    end
    
    table.sort(sortedFeatures, function(a, b) return a.count > b.count end)
    
    local topFeatures = {}
    for i = 1, math.min(limit, #sortedFeatures) do
        table.insert(topFeatures, sortedFeatures[i])
    end
    
    return topFeatures
end

-- Get performance summary
function PluginAnalyticsService:getPerformanceSummary()
    local performance = self.analyticsState.performance
    
    return {
        averageResponseTime = performance.averageResponseTime,
        totalRequests = performance.totalRequests,
        successRate = performance.totalRequests > 0 and 
                     (performance.successfulRequests / performance.totalRequests) or 0,
        cacheHitRate = performance.cacheHitRate,
        slowOperationsCount = #performance.slowOperations,
        memoryUsage = performance.memoryUsage
    }
end

-- Get error summary
function PluginAnalyticsService:getErrorSummary()
    local errors = self.analyticsState.usage.errors
    local warnings = self.analyticsState.usage.warnings
    
    -- Group errors by type
    local errorTypes = {}
    for _, error in ipairs(errors) do
        errorTypes[error.type] = (errorTypes[error.type] or 0) + 1
    end
    
    -- Group warnings by type
    local warningTypes = {}
    for _, warning in ipairs(warnings) do
        warningTypes[warning.type] = (warningTypes[warning.type] or 0) + 1
    end
    
    return {
        totalErrors = #errors,
        totalWarnings = #warnings,
        errorTypes = errorTypes,
        warningTypes = warningTypes,
        recentErrors = #errors > 5 and {table.unpack(errors, #errors - 4)} or errors
    }
end

-- Get DataStore insights
function PluginAnalyticsService:getDataStoreInsights()
    local analytics = self.analyticsState.datastoreAnalytics
    
    return {
        totalDataStores = analytics.totalDataStores,
        totalKeys = analytics.totalKeys,
        totalDataSize = analytics.totalDataSize,
        averageDataSize = analytics.totalKeys > 0 and (analytics.totalDataSize / analytics.totalKeys) or 0,
        topKeyPatterns = self:getTopKeyPatterns(5),
        topDataStores = self:getTopDataStores(5),
        anomaliesCount = #analytics.anomalies
    }
end

-- Get behavior patterns
function PluginAnalyticsService:getBehaviorPatterns()
    local behavior = self.analyticsState.userBehavior
    
    return {
        topNavigationPaths = self:getTopNavigationPaths(5),
        mostUsedFeatures = self:getTopFeatures(5),
        sessionDuration = tick() - self.analyticsState.sessionStartTime
    }
end

-- Generate insights from collected data
function PluginAnalyticsService:generateInsights()
    local insights = {}
    
    -- Performance insights
    local performance = self.analyticsState.performance
    if performance.averageResponseTime > 2 then
        table.insert(insights, {
            type = "performance",
            severity = "warning",
            message = "Average response time is high (" .. string.format("%.2f", performance.averageResponseTime) .. "s)"
        })
    end
    
    -- Usage insights
    local usage = self.analyticsState.usage
    if usage.errors and #usage.errors > 10 then
        table.insert(insights, {
            type = "reliability",
            severity = "warning",
            message = "High error rate detected (" .. #usage.errors .. " errors in session)"
        })
    end
    
    -- DataStore insights
    local analytics = self.analyticsState.datastoreAnalytics
    if #analytics.anomalies > 0 then
        table.insert(insights, {
            type = "data",
            severity = "info",
            message = #analytics.anomalies .. " data anomalies detected"
        })
    end
    
    return insights
end

-- Generate recommendations
function PluginAnalyticsService:generateRecommendations()
    local recommendations = {}
    
    -- Performance recommendations
    local performance = self.analyticsState.performance
    if performance.cacheHitRate < 0.8 then
        table.insert(recommendations, {
            type = "performance",
            priority = "medium",
            message = "Consider increasing cache size to improve performance",
            action = "increase_cache_size"
        })
    end
    
    -- Usage recommendations
    local topFeatures = self:getTopFeatures(3)
    if #topFeatures > 0 then
        table.insert(recommendations, {
            type = "usage",
            priority = "low",
            message = "Your most used feature is: " .. topFeatures[1].feature,
            action = "feature_optimization"
        })
    end
    
    return recommendations
end

-- Get feature usage analysis
function PluginAnalyticsService:getFeatureUsageAnalysis()
    return {
        topFeatures = self:getTopFeatures(10),
        totalFeatures = self:countUniqueFeatures(),
        usageDistribution = self:getUsageDistribution()
    }
end

-- Get performance analysis
function PluginAnalyticsService:getPerformanceAnalysis()
    local performance = self.analyticsState.performance
    
    return {
        summary = self:getPerformanceSummary(),
        operationBreakdown = performance.operationTimes,
        slowOperations = performance.slowOperations,
        performanceScore = self:calculatePerformanceScore()
    }
end

-- Get DataStore analysis
function PluginAnalyticsService:getDataStoreAnalysis()
    local analytics = self.analyticsState.datastoreAnalytics
    
    return {
        summary = self:getDataStoreInsights(),
        keyPatterns = analytics.keyPatterns,
        accessPatterns = analytics.accessPatterns,
        anomalies = analytics.anomalies,
        dataDistribution = self:getDataDistribution()
    }
end

-- ==================== UTILITY METHODS ====================

-- Extract pattern from key name
function PluginAnalyticsService:extractKeyPattern(keyName)
    if not keyName then return "unknown" end
    
    -- Look for common patterns
    if keyName:match("^player_(%d+)") then
        return "player_id"
    elseif keyName:match("^user_(%d+)") then
        return "user_id"
    elseif keyName:match("^data_(%w+)") then
        return "data_prefix"
    elseif keyName:match("(%d+)$") then
        return "numeric_suffix"
    elseif keyName:match("^(%w+)_") then
        return keyName:match("^(%w+)_") .. "_prefix"
    else
        return "custom"
    end
end

-- Get top key patterns
function PluginAnalyticsService:getTopKeyPatterns(limit)
    limit = limit or 10
    local patterns = self.analyticsState.datastoreAnalytics.keyPatterns
    
    local sortedPatterns = {}
    for pattern, count in pairs(patterns) do
        table.insert(sortedPatterns, {pattern = pattern, count = count})
    end
    
    table.sort(sortedPatterns, function(a, b) return a.count > b.count end)
    
    local topPatterns = {}
    for i = 1, math.min(limit, #sortedPatterns) do
        table.insert(topPatterns, sortedPatterns[i])
    end
    
    return topPatterns
end

-- Get top DataStores by access
function PluginAnalyticsService:getTopDataStores(limit)
    limit = limit or 10
    local patterns = self.analyticsState.datastoreAnalytics.accessPatterns
    
    local sortedDataStores = {}
    for datastoreName, count in pairs(patterns) do
        table.insert(sortedDataStores, {datastore = datastoreName, count = count})
    end
    
    table.sort(sortedDataStores, function(a, b) return a.count > b.count end)
    
    local topDataStores = {}
    for i = 1, math.min(limit, #sortedDataStores) do
        table.insert(topDataStores, sortedDataStores[i])
    end
    
    return topDataStores
end

-- Get top navigation paths
function PluginAnalyticsService:getTopNavigationPaths(limit)
    limit = limit or 10
    local paths = self.analyticsState.userBehavior.navigationPaths
    
    local sortedPaths = {}
    for path, count in pairs(paths) do
        table.insert(sortedPaths, {path = path, count = count})
    end
    
    table.sort(sortedPaths, function(a, b) return a.count > b.count end)
    
    local topPaths = {}
    for i = 1, math.min(limit, #sortedPaths) do
        table.insert(topPaths, sortedPaths[i])
    end
    
    return topPaths
end

-- Count unique features used
function PluginAnalyticsService:countUniqueFeatures()
    local count = 0
    for _ in pairs(self.analyticsState.userBehavior.mostUsedFeatures) do
        count = count + 1
    end
    return count
end

-- Get usage distribution
function PluginAnalyticsService:getUsageDistribution()
    local totalUsage = 0
    local features = self.analyticsState.userBehavior.mostUsedFeatures
    
    for _, count in pairs(features) do
        totalUsage = totalUsage + count
    end
    
    local distribution = {}
    for feature, count in pairs(features) do
        distribution[feature] = totalUsage > 0 and (count / totalUsage) or 0
    end
    
    return distribution
end

-- Get data distribution
function PluginAnalyticsService:getDataDistribution()
    local analytics = self.analyticsState.datastoreAnalytics
    local totalAccess = 0
    
    for _, count in pairs(analytics.accessPatterns) do
        totalAccess = totalAccess + count
    end
    
    local distribution = {}
    for datastore, count in pairs(analytics.accessPatterns) do
        distribution[datastore] = totalAccess > 0 and (count / totalAccess) or 0
    end
    
    return distribution
end

-- Collect system information
function PluginAnalyticsService:collectSystemInfo()
    return {
        memoryUsage = collectgarbage("count"),
        timestamp = tick(),
        placeId = game.PlaceId,
        gameId = game.GameId
    }
end

-- Save current analytics to plugin DataStore
function PluginAnalyticsService:saveCurrentAnalytics()
    if not self.pluginDataStore then return false end
    
    local currentAnalytics = {
        sessionId = self.analyticsState.sessionId,
        timestamp = tick(),
        sessionDuration = tick() - self.analyticsState.sessionStartTime,
        state = Utils.deepCopy(self.analyticsState)
    }
    
    return self.pluginDataStore:saveHistoricalSnapshot(currentAnalytics, "session_analytics")
end

-- Get comprehensive analytics report
function PluginAnalyticsService:getAnalyticsReport()
    return {
        sessionInfo = {
            sessionId = self.analyticsState.sessionId,
            startTime = self.analyticsState.sessionStartTime,
            duration = tick() - self.analyticsState.sessionStartTime,
            isActive = self.isActive
        },
        
        usage = Utils.deepCopy(self.analyticsState.usage),
        performance = self:getPerformanceSummary(),
        datastoreAnalytics = self:getDataStoreInsights(),
        userBehavior = self:getBehaviorPatterns(),
        
        insights = self:generateInsights(),
        recommendations = self:generateRecommendations(),
        
        summary = {
            totalInteractions = self:getTotalInteractions(),
            topFeatures = self:getTopFeatures(5),
            errorRate = self:getErrorRate(),
            performanceScore = self:calculatePerformanceScore()
        }
    }
end

-- Calculate error rate
function PluginAnalyticsService:getErrorRate()
    local totalInteractions = self:getTotalInteractions()
    local totalErrors = #self.analyticsState.usage.errors
    
    if totalInteractions > 0 then
        return totalErrors / totalInteractions
    else
        return 0
    end
end

-- Calculate performance score (0-100)
function PluginAnalyticsService:calculatePerformanceScore()
    local performance = self.analyticsState.performance
    local score = 100
    
    -- Deduct points for slow response times
    if performance.averageResponseTime > 1 then
        score = score - math.min(30, performance.averageResponseTime * 10)
    end
    
    -- Deduct points for failed requests
    if performance.totalRequests > 0 then
        local failureRate = performance.failedRequests / performance.totalRequests
        score = score - (failureRate * 40)
    end
    
    -- Deduct points for low cache hit rate
    if performance.cacheHitRate < 0.8 then
        score = score - ((0.8 - performance.cacheHitRate) * 20)
    end
    
    return math.max(0, math.min(100, score))
end

return PluginAnalyticsService 