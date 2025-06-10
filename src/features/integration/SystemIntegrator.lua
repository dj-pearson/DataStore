-- DataStore Manager Pro - System Integrator
-- Connects all advanced systems following the 2.2 Core Principles
-- Demonstrates full integration of Reliability, Performance, UX, and Commercial systems

local SystemIntegrator = {}

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[SYSTEM_INTEGRATOR] [%s] %s", level, message))
end

-- Integration state
local integrationState = {
    initialized = false,
    services = {},
    connections = {},
    analytics = nil,
    search = nil,
    licensing = nil,
    errorHandler = nil
}

function SystemIntegrator.initialize(services)
    if integrationState.initialized then
        debugLog("System already integrated")
        return true
    end
    
    debugLog("Initializing comprehensive system integration...")
    
    integrationState.services = services or {}
    
    -- Initialize core integrations
    local success = SystemIntegrator.initializeCoreIntegrations()
    if not success then
        debugLog("Failed to initialize core integrations", "ERROR")
        return false
    end
    
    -- Setup cross-system connections
    SystemIntegrator.setupCrossSystemConnections()
    
    -- Initialize real-time monitoring
    SystemIntegrator.initializeRealTimeMonitoring()
    
    -- Setup automated workflows
    SystemIntegrator.setupAutomatedWorkflows()
    
    integrationState.initialized = true
    debugLog("🎉 System integration completed successfully!")
    
    return true
end

-- Initialize core system integrations
function SystemIntegrator.initializeCoreIntegrations()
    debugLog("Setting up core system integrations...")
    
    -- Initialize Analytics Integration
    local analyticsSuccess = SystemIntegrator.initializeAnalyticsIntegration()
    if not analyticsSuccess then
        debugLog("Analytics integration failed", "WARN")
    end
    
    -- Initialize Search Integration
    local searchSuccess = SystemIntegrator.initializeSearchIntegration()
    if not searchSuccess then
        debugLog("Search integration failed", "WARN")
    end
    
    -- Initialize License Integration
    local licenseSuccess = SystemIntegrator.initializeLicenseIntegration()
    if not licenseSuccess then
        debugLog("License integration failed", "WARN")
    end
    
    -- Initialize Error Handler Integration
    local errorSuccess = SystemIntegrator.initializeErrorIntegration()
    if not errorSuccess then
        debugLog("Error handler integration failed", "WARN")
    end
    
    return analyticsSuccess or searchSuccess or licenseSuccess or errorSuccess
end

-- Initialize Analytics Integration (Performance Principle)
function SystemIntegrator.initializeAnalyticsIntegration()
    local perfAnalyzer = integrationState.services["features.analytics.PerformanceAnalyzer"]
    local advancedAnalytics = integrationState.services["features.analytics.AdvancedAnalytics"]
    
    if perfAnalyzer or advancedAnalytics then
        integrationState.analytics = perfAnalyzer or advancedAnalytics
        debugLog("✅ Analytics integration ready - Performance monitoring active")
        
        -- Setup performance tracking for all operations
        SystemIntegrator.setupPerformanceTracking()
        
        return true
    end
    
    debugLog("❌ Analytics services not available", "WARN")
    return false
end

-- Initialize Search Integration (UX Principle)
function SystemIntegrator.initializeSearchIntegration()
    local searchService = integrationState.services["features.search.SearchService"]
    local advancedSearch = integrationState.services["features.search.AdvancedSearch"]
    
    if searchService or advancedSearch then
        integrationState.search = searchService or advancedSearch
        debugLog("✅ Search integration ready - Advanced search capabilities active")
        
        -- Setup search performance monitoring
        SystemIntegrator.setupSearchMonitoring()
        
        return true
    end
    
    debugLog("❌ Search services not available", "WARN")
    return false
end

-- Initialize License Integration (Commercial Principle)
function SystemIntegrator.initializeLicenseIntegration()
    local licenseManager = integrationState.services["core.licensing.LicenseManager"]
    
    if licenseManager then
        integrationState.licensing = licenseManager
        debugLog("✅ License integration ready - Feature gating active")
        
        -- Setup license usage tracking
        SystemIntegrator.setupLicenseTracking()
        
        return true
    end
    
    debugLog("❌ License manager not available", "WARN")
    return false
end

-- Initialize Error Handler Integration (Reliability Principle)
function SystemIntegrator.initializeErrorIntegration()
    local errorHandler = integrationState.services["core.error.ErrorHandler"]
    
    if errorHandler then
        integrationState.errorHandler = errorHandler
        debugLog("✅ Error handling integration ready - Enhanced reliability active")
        
        -- Setup error tracking and recovery
        SystemIntegrator.setupErrorTracking()
        
        return true
    end
    
    debugLog("❌ Error handler not available", "WARN")
    return false
end

-- Setup performance tracking for all operations
function SystemIntegrator.setupPerformanceTracking()
    if not integrationState.analytics then return end
    
    debugLog("Setting up comprehensive performance tracking...")
    
    -- Create performance wrapper for critical operations
    SystemIntegrator.performanceWrapper = function(operationType, dataStore, operation)
        local startTime = tick()
        local success, result, size = false, nil, 0
        
        -- Execute operation with error handling
        local errorInfo = nil
        if integrationState.errorHandler then
            success, result = integrationState.errorHandler.safeOperation(operation, 3, {
                operation = operationType,
                dataStore = dataStore
            })
            
            if not success and result and result.error then
                errorInfo = result.error
            end
        else
            success, result = pcall(operation)
        end
        
        local endTime = tick()
        
        -- Calculate data size if possible
        if success and result and type(result) == "string" then
            size = #result
        elseif success and result and type(result) == "table" then
            local jsonSize = pcall(function()
                return #game:GetService("HttpService"):JSONEncode(result)
            end)
            size = jsonSize or 0
        end
        
        -- Track with analytics
        integrationState.analytics:trackOperation(
            operationType,
            dataStore,
            "integrated_operation",
            startTime,
            endTime,
            size,
            success,
            errorInfo and tostring(errorInfo) or nil
        )
        
        -- Track with license manager if available
        if integrationState.licensing and success then
            integrationState.licensing.trackOperation(operationType, dataStore)
        end
        
        debugLog(string.format("Performance tracked: %s on %s (%.2fms, %s)", 
            operationType, dataStore, (endTime - startTime) * 1000, success and "success" or "failed"))
        
        return success, result
    end
    
    debugLog("Performance tracking configured")
end

-- Setup search performance monitoring
function SystemIntegrator.setupSearchMonitoring()
    if not integrationState.search or not integrationState.analytics then return end
    
    debugLog("Setting up search performance monitoring...")
    
    -- Wrap search operations with performance tracking
    local originalSearch = integrationState.search.search
    if originalSearch then
        integrationState.search.search = function(self, query, options)
            local startTime = tick()
            local result = originalSearch(self, query, options)
            local endTime = tick()
            
            -- Track search performance
            integrationState.analytics:trackOperation(
                "search",
                "advanced_search",
                "search_operation",
                startTime,
                endTime,
                query and #query or 0,
                result and result.success or false,
                result and result.error or nil
            )
            
            return result
        end
        
        debugLog("Search monitoring configured")
    end
end

-- Setup license usage tracking
function SystemIntegrator.setupLicenseTracking()
    if not integrationState.licensing then return end
    
    debugLog("Setting up license usage tracking...")
    
    -- Monitor feature access attempts
    SystemIntegrator.trackFeatureUsage = function(featureName, granted)
        if granted then
            debugLog(string.format("Feature accessed: %s", featureName))
        else
            debugLog(string.format("Feature access denied: %s (upgrade required)", featureName))
            
            -- Track upgrade opportunity
            if integrationState.analytics then
                integrationState.analytics:trackOperation(
                    "feature_access_denied",
                    featureName,
                    "license_check",
                    tick(),
                    tick(),
                    0,
                    false,
                    "Feature requires higher license tier"
                )
            end
        end
    end
    
    -- Wrap license checks
    local originalHasAccess = integrationState.licensing.hasFeatureAccess
    if originalHasAccess then
        integrationState.licensing.hasFeatureAccess = function(featureName)
            local hasAccess = originalHasAccess(featureName)
            SystemIntegrator.trackFeatureUsage(featureName, hasAccess)
            return hasAccess
        end
        
        debugLog("License tracking configured")
    end
end

-- Setup error tracking and recovery
function SystemIntegrator.setupErrorTracking()
    if not integrationState.errorHandler then return end
    
    debugLog("Setting up error tracking and recovery...")
    
    -- Enhanced error handling with analytics integration
    SystemIntegrator.handleError = function(error, context)
        local errorResult = integrationState.errorHandler.handleError(error, context)
        
        -- Track error with analytics if available
        if integrationState.analytics and errorResult.error then
            integrationState.analytics:trackOperation(
                context.operation or "unknown",
                context.dataStore or "unknown",
                "error_occurred",
                tick(),
                tick(),
                0,
                false,
                errorResult.error.userMessage or tostring(error)
            )
        end
        
        debugLog(string.format("Integrated error handling: %s", errorResult.error.userMessage))
        return errorResult
    end
    
    debugLog("Error tracking configured")
end

-- Setup cross-system connections
function SystemIntegrator.setupCrossSystemConnections()
    debugLog("Setting up cross-system connections...")
    
    -- Connect analytics to license recommendations
    if integrationState.analytics and integrationState.licensing then
        SystemIntegrator.setupAnalyticsLicenseConnection()
    end
    
    -- Connect search to analytics tracking
    if integrationState.search and integrationState.analytics then
        SystemIntegrator.setupSearchAnalyticsConnection()
    end
    
    -- Connect error handling to all systems
    if integrationState.errorHandler then
        SystemIntegrator.setupErrorSystemConnections()
    end
    
    debugLog("Cross-system connections established")
end

-- Connect analytics to license recommendations
function SystemIntegrator.setupAnalyticsLicenseConnection()
    debugLog("Connecting analytics to license system...")
    
    -- Create smart upgrade recommendations based on usage patterns
    SystemIntegrator.generateSmartRecommendations = function()
        local usageStats = integrationState.licensing.getUsageStatistics()
        local performanceReport = integrationState.analytics:generatePerformanceReport()
        
        local recommendations = {}
        
        -- High usage patterns suggest upgrade
        if usageStats.utilizationRate and usageStats.utilizationRate.operations > 0.8 then
            table.insert(recommendations, {
                type = "upgrade",
                priority = "high",
                title = "High Usage Detected",
                description = "You're using 80%+ of your operation limit. Consider upgrading for unlimited operations.",
                feature = "operationLimits",
                evidence = {
                    usage = usageStats.utilizationRate.operations,
                    totalOps = usageStats.operationsThisHour
                }
            })
        end
        
        -- Performance issues might benefit from enterprise features
        if performanceReport.latency and performanceReport.latency.average > 100 then
            table.insert(recommendations, {
                type = "feature",
                priority = "medium",
                title = "Performance Optimization Available",
                description = "Advanced caching and optimization features could improve your response times.",
                feature = "performanceOptimization",
                evidence = {
                    averageLatency = performanceReport.latency.average,
                    trend = performanceReport.latency.trend
                }
            })
        end
        
        return recommendations
    end
    
    debugLog("Analytics-license connection established")
end

-- Connect search to analytics tracking
function SystemIntegrator.setupSearchAnalyticsConnection()
    debugLog("Connecting search to analytics system...")
    
    -- Enhanced search with usage insights
    SystemIntegrator.getSearchInsights = function()
        if not integrationState.search.getSearchHistory then
            return {}
        end
        
        local searchHistory = integrationState.search:getSearchHistory()
        local insights = {}
        
        -- Analyze search patterns
        local queryTypes = {}
        local frequentQueries = {}
        
        for _, search in ipairs(searchHistory) do
            local query = search.query or ""
            frequentQueries[query] = (frequentQueries[query] or 0) + 1
            
            if search.options and search.options.scope then
                queryTypes[search.options.scope] = (queryTypes[search.options.scope] or 0) + 1
            end
        end
        
        -- Generate insights
        table.insert(insights, {
            type = "usage_pattern",
            title = "Search Usage Analysis",
            data = {
                totalSearches = #searchHistory,
                queryTypes = queryTypes,
                topQueries = frequentQueries
            }
        })
        
        return insights
    end
    
    debugLog("Search-analytics connection established")
end

-- Connect error handling to all systems
function SystemIntegrator.setupErrorSystemConnections()
    debugLog("Connecting error handling to all systems...")
    
    -- Centralized error reporting with system context
    SystemIntegrator.reportSystemError = function(error, systemName, context)
        local enhancedContext = Utils.Table.merge(context or {}, {
            system = systemName,
            timestamp = tick(),
            integrationState = {
                analyticsActive = integrationState.analytics ~= nil,
                searchActive = integrationState.search ~= nil,
                licensingActive = integrationState.licensing ~= nil
            }
        })
        
        return SystemIntegrator.handleError(error, enhancedContext)
    end
    
    debugLog("Error system connections established")
end

-- Initialize real-time monitoring
function SystemIntegrator.initializeRealTimeMonitoring()
    debugLog("Initializing real-time system monitoring...")
    
    -- System health monitoring
    SystemIntegrator.systemHealth = {
        lastCheck = tick(),
        status = {
            analytics = "unknown",
            search = "unknown", 
            licensing = "unknown",
            errorHandling = "unknown"
        },
        metrics = {
            operationsPerMinute = 0,
            averageLatency = 0,
            errorRate = 0,
            uptime = 0
        }
    }
    
    -- Start monitoring loop
    spawn(function()
        while integrationState.initialized do
            SystemIntegrator.updateSystemHealth()
            wait(30) -- Update every 30 seconds
        end
    end)
    
    debugLog("Real-time monitoring started")
end

-- Update system health metrics
function SystemIntegrator.updateSystemHealth()
    local health = SystemIntegrator.systemHealth
    local currentTime = tick()
    
    -- Check system status
    health.status.analytics = integrationState.analytics and "active" or "inactive"
    health.status.search = integrationState.search and "active" or "inactive"
    health.status.licensing = integrationState.licensing and "active" or "inactive"
    health.status.errorHandling = integrationState.errorHandler and "active" or "inactive"
    
    -- Update metrics
    if integrationState.analytics then
        local summary = integrationState.analytics:generateSummaryReport()
        health.metrics.averageLatency = summary.averageLatency or 0
        health.metrics.errorRate = summary.errorRate or 0
        
        -- Calculate operations per minute
        local timeDiff = (currentTime - health.lastCheck) / 60 -- Convert to minutes
        if timeDiff > 0 then
            health.metrics.operationsPerMinute = (summary.sessionOperations or 0) / timeDiff
        end
    end
    
    health.metrics.uptime = currentTime - (integrationState.startTime or currentTime)
    health.lastCheck = currentTime
    
    -- Log health summary periodically
    if health.lastCheck % 300 < 30 then -- Every 5 minutes
        debugLog(string.format("System Health: Latency=%.1fms, ErrorRate=%.1f%%, OpsPM=%.1f", 
            health.metrics.averageLatency,
            health.metrics.errorRate,
            health.metrics.operationsPerMinute))
    end
end

-- Setup automated workflows
function SystemIntegrator.setupAutomatedWorkflows()
    debugLog("Setting up automated workflows...")
    
    -- Auto-optimization workflow
    SystemIntegrator.autoOptimization = function()
        if not integrationState.analytics then return end
        
        local recommendations = integrationState.analytics:generateRecommendations()
        
        for _, rec in ipairs(recommendations) do
            if rec.type == "performance" and rec.priority == "high" then
                debugLog("Auto-optimization triggered: " .. rec.title)
                -- Could implement automatic performance tuning here
            end
        end
    end
    
    -- Auto-upgrade prompting workflow
    SystemIntegrator.autoUpgradePrompting = function()
        if not integrationState.licensing or not integrationState.analytics then return end
        
        local smartRecs = SystemIntegrator.generateSmartRecommendations()
        
        for _, rec in ipairs(smartRecs) do
            if rec.type == "upgrade" and rec.priority == "high" then
                debugLog("Auto-upgrade prompt triggered: " .. rec.title)
                -- UI system would show upgrade prompts here
            end
        end
    end
    
    -- Schedule workflows
    spawn(function()
        while integrationState.initialized do
            SystemIntegrator.autoOptimization()
            SystemIntegrator.autoUpgradePrompting()
            wait(120) -- Run every 2 minutes
        end
    end)
    
    debugLog("Automated workflows configured")
end

-- Get comprehensive system status
function SystemIntegrator.getSystemStatus()
    return {
        initialized = integrationState.initialized,
        systemHealth = SystemIntegrator.systemHealth,
        activeServices = {
            analytics = integrationState.analytics ~= nil,
            search = integrationState.search ~= nil,
            licensing = integrationState.licensing ~= nil,
            errorHandling = integrationState.errorHandler ~= nil
        },
        integrationLevel = SystemIntegrator.calculateIntegrationLevel(),
        recommendations = integrationState.analytics and SystemIntegrator.generateSmartRecommendations() or {}
    }
end

-- Calculate integration level (0-100%)
function SystemIntegrator.calculateIntegrationLevel()
    local activeCount = 0
    local totalCount = 4 -- analytics, search, licensing, error handling
    
    if integrationState.analytics then activeCount = activeCount + 1 end
    if integrationState.search then activeCount = activeCount + 1 end
    if integrationState.licensing then activeCount = activeCount + 1 end
    if integrationState.errorHandler then activeCount = activeCount + 1 end
    
    return math.floor((activeCount / totalCount) * 100)
end

-- Execute integrated operation (demonstrates all principles working together)
function SystemIntegrator.executeIntegratedOperation(operationType, dataStore, operation, options)
    options = options or {}
    
    debugLog(string.format("Executing integrated operation: %s on %s", operationType, dataStore))
    
    -- 1. Check license access (Commercial Principle)
    if integrationState.licensing then
        local hasAccess = integrationState.licensing.hasFeatureAccess(options.requiredFeature or "basicDataExplorer")
        if not hasAccess then
            local upgradePrompt = integrationState.licensing.showUpgradePrompt(options.requiredFeature or "basicDataExplorer")
            return false, {
                type = "license_required",
                upgradePrompt = upgradePrompt,
                message = "This operation requires a higher license tier"
            }
        end
    end
    
    -- 2. Execute with performance monitoring (Performance Principle)
    local success, result
    if SystemIntegrator.performanceWrapper then
        success, result = SystemIntegrator.performanceWrapper(operationType, dataStore, operation)
    else
        success, result = pcall(operation)
    end
    
    -- 3. Handle errors gracefully (Reliability Principle)
    if not success and integrationState.errorHandler then
        local errorResult = SystemIntegrator.handleError(result, {
            operation = operationType,
            dataStore = dataStore
        })
        return false, errorResult
    end
    
    -- 4. Provide user feedback (UX Principle)
    local userFeedback = {
        type = success and "success" or "error",
        message = success and 
            string.format("✅ %s operation completed successfully", operationType) or
            string.format("❌ %s operation failed", operationType),
        data = result
    }
    
    debugLog(string.format("Integrated operation completed: %s (%s)", 
        operationType, success and "success" or "failed"))
    
    return success, userFeedback
end

-- Cleanup
function SystemIntegrator.cleanup()
    debugLog("Cleaning up system integration...")
    
    integrationState.initialized = false
    
    -- Clear all connections
    for name, connection in pairs(integrationState.connections) do
        if connection.disconnect then
            connection:disconnect()
        end
    end
    
    -- Clear references
    integrationState.services = {}
    integrationState.connections = {}
    integrationState.analytics = nil
    integrationState.search = nil
    integrationState.licensing = nil
    integrationState.errorHandler = nil
    
    debugLog("System integration cleanup complete")
end

return SystemIntegrator 