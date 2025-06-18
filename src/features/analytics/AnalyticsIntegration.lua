-- AnalyticsIntegration.lua
-- Integration example showing how to use the enhanced plugin DataStore system
-- with analytics collection, reporting, and persistent data storage

local HttpService = game:GetService("HttpService")

local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Import our enhanced systems
local PluginDataStore = require(pluginRoot.core.data.PluginDataStore)
local PluginAnalyticsService = require(script.Parent.PluginAnalyticsService)
local ReportManager = require(script.Parent.ReportManager)

local AnalyticsIntegration = {}
AnalyticsIntegration.__index = AnalyticsIntegration

function AnalyticsIntegration.new(plugin)
    local self = setmetatable({}, AnalyticsIntegration)
    
    self.plugin = plugin
    
    -- Initialize logger
    self.logger = {
        info = function(_, component, message)
            print("[" .. component .. "] [INFO] " .. message)
        end,
        warn = function(_, component, message)
            print("[" .. component .. "] [WARN] " .. message)
        end,
        debug = function(_, component, message)
            print("[" .. component .. "] [DEBUG] " .. message)
        end,
        error = function(_, component, message)
            print("[" .. component .. "] [ERROR] " .. message)
        end
    }
    
    -- Initialize the plugin DataStore system
    self.pluginDataStore = PluginDataStore.new(self.logger)
    
    -- Initialize analytics service
    self.analyticsService = PluginAnalyticsService.new(self.pluginDataStore, self.logger)
    
    -- Initialize report manager
    self.reportManager = ReportManager.new(self.pluginDataStore, self.analyticsService, self.logger)
    
    -- Load saved settings
    self:loadPluginSettings()
    
    return self
end

-- ==================== LIFECYCLE MANAGEMENT ====================

-- Start the analytics integration
function AnalyticsIntegration:start()
    self.logger:info("INTEGRATION", "🚀 Starting analytics integration...")
    
    -- Start analytics collection
    local success = self.analyticsService:start()
    
    if success then
        self.logger:info("INTEGRATION", "✅ Analytics integration started successfully")
        
        -- Generate an initial report to test the system
        self:generateInitialReport()
        
        return true
    else
        self.logger:error("INTEGRATION", "❌ Failed to start analytics integration")
        return false
    end
end

-- Stop the analytics integration
function AnalyticsIntegration:stop()
    self.logger:info("INTEGRATION", "⏹️ Stopping analytics integration...")
    
    -- Save current settings
    self:savePluginSettings()
    
    -- Generate final session report
    self:generateSessionReport()
    
    -- Stop analytics collection
    local success = self.analyticsService:stop()
    
    if success then
        self.logger:info("INTEGRATION", "✅ Analytics integration stopped successfully")
        return true
    else
        self.logger:error("INTEGRATION", "❌ Failed to stop analytics integration cleanly")
        return false
    end
end

-- ==================== SETTINGS MANAGEMENT ====================

-- Load plugin settings from persistent storage
function AnalyticsIntegration:loadPluginSettings()
    self.logger:info("INTEGRATION", "📥 Loading plugin settings...")
    
    local settings = self.pluginDataStore:loadSettings()
    
    if settings then
        self.settings = settings
        self.logger:info("INTEGRATION", "✅ Plugin settings loaded successfully")
    else
        -- Use default settings
        self.settings = self:getDefaultSettings()
        self.logger:info("INTEGRATION", "ℹ️ Using default plugin settings")
    end
    
    return self.settings
end

-- Save plugin settings to persistent storage
function AnalyticsIntegration:savePluginSettings()
    self.logger:info("INTEGRATION", "💾 Saving plugin settings...")
    
    local success = self.pluginDataStore:saveSettings(self.settings)
    
    if success then
        self.logger:info("INTEGRATION", "✅ Plugin settings saved successfully")
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to save plugin settings")
    end
    
    return success
end

-- Get default settings
function AnalyticsIntegration:getDefaultSettings()
    return {
        analytics = {
            enabled = true,
            collectDetailedMetrics = true,
            generateDailyReports = true,
            retainDataDays = 30
        },
        
        dataStore = {
            cacheTimeout = 300,
            enablePersistentCache = true,
            autoBackup = true
        },
        
        reporting = {
            autoGenerateReports = true,
            reportFrequency = "daily",
            includePerformanceMetrics = true,
            includeUsageAnalytics = true
        },
        
        ui = {
            showAnalyticsDashboard = true,
            showPerformanceIndicators = true,
            enableNotifications = true
        }
    }
end

-- Update a specific setting
function AnalyticsIntegration:updateSetting(category, key, value)
    if not self.settings[category] then
        self.settings[category] = {}
    end
    
    local oldValue = self.settings[category][key]
    self.settings[category][key] = value
    
    -- Track the settings change
    if self.analyticsService then
        self.analyticsService:trackUIInteraction("settings_change", {
            category = category,
            key = key,
            oldValue = oldValue,
            newValue = value
        })
    end
    
    self.logger:info("INTEGRATION", "⚙️ Setting updated: " .. category .. "." .. key .. " = " .. tostring(value))
    
    -- Auto-save settings if enabled
    if self.settings.dataStore and self.settings.dataStore.autoBackup then
        self:savePluginSettings()
    end
end

-- ==================== REPORT GENERATION ====================

-- Generate initial report on startup
function AnalyticsIntegration:generateInitialReport()
    self.logger:info("INTEGRATION", "📊 Generating initial session report...")
    
    local report = self.reportManager:generateReport("DAILY_SUMMARY", {
        includeHistoricalData = false,
        timeRange = 86400 -- Last 24 hours
    })
    
    if report then
        self.logger:info("INTEGRATION", "✅ Initial report generated: " .. report.id)
        return report
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to generate initial report")
        return nil
    end
end

-- Generate session report on shutdown
function AnalyticsIntegration:generateSessionReport()
    self.logger:info("INTEGRATION", "📊 Generating final session report...")
    
    local report = self.reportManager:generateReport("USAGE_ANALYTICS", {
        sessionOnly = true,
        includeRecommendations = true
    })
    
    if report then
        self.logger:info("INTEGRATION", "✅ Session report generated: " .. report.id)
        return report
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to generate session report")
        return nil
    end
end

-- Generate performance analysis report
function AnalyticsIntegration:generatePerformanceReport()
    self.logger:info("INTEGRATION", "📊 Generating performance analysis report...")
    
    local report = self.reportManager:generateReport("PERFORMANCE_ANALYSIS", {
        includeDetailedMetrics = true,
        timeRange = 3600 -- Last hour
    })
    
    if report then
        self.logger:info("INTEGRATION", "✅ Performance report generated: " .. report.id)
        return report
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to generate performance report")
        return nil
    end
end

-- Generate custom analysis report
function AnalyticsIntegration:generateCustomReport(analysisType, options)
    self.logger:info("INTEGRATION", "📊 Generating custom analysis report: " .. analysisType)
    
    options = options or {}
    options.analysisType = analysisType
    
    local report = self.reportManager:generateReport("CUSTOM_ANALYSIS", options)
    
    if report then
        self.logger:info("INTEGRATION", "✅ Custom report generated: " .. report.id)
        return report
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to generate custom report")
        return nil
    end
end

-- ==================== DATA RETRIEVAL ====================

-- Get current analytics snapshot
function AnalyticsIntegration:getCurrentAnalytics()
    if not self.analyticsService then
        return nil
    end
    
    return self.analyticsService:getAnalyticsReport()
end

-- Get plugin DataStore statistics
function AnalyticsIntegration:getDataStoreStats()
    if not self.pluginDataStore then
        return nil
    end
    
    return self.pluginDataStore:getStats()
end

-- Get saved reports with optional filtering
function AnalyticsIntegration:getSavedReports(filter)
    if not self.reportManager then
        return {}
    end
    
    return self.reportManager:getSavedReports(filter)
end

-- Get historical analytics data
function AnalyticsIntegration:getHistoricalAnalytics(timeRange, analyticsType)
    if not self.pluginDataStore then
        return {}
    end
    
    return self.pluginDataStore:getAnalytics(timeRange, analyticsType)
end

-- ==================== CACHE MANAGEMENT ====================

-- Clear all cached data
function AnalyticsIntegration:clearCache()
    self.logger:info("INTEGRATION", "🧹 Clearing all cached data...")
    
    local success = self.pluginDataStore:clearAllCache()
    
    if success then
        self.logger:info("INTEGRATION", "✅ Cache cleared successfully")
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to clear cache")
    end
    
    return success
end

-- Get cache statistics
function AnalyticsIntegration:getCacheStats()
    if not self.pluginDataStore then
        return {}
    end
    
    local stats = self.pluginDataStore:getStats()
    return stats.memory or {}
end

-- ==================== HISTORICAL DATA MANAGEMENT ====================

-- Save historical snapshot manually
function AnalyticsIntegration:saveHistoricalSnapshot(category)
    self.logger:info("INTEGRATION", "📈 Saving historical snapshot: " .. (category or "general"))
    
    local analyticsData = self:getCurrentAnalytics()
    if not analyticsData then
        self.logger:warn("INTEGRATION", "⚠️ No analytics data available for snapshot")
        return false
    end
    
    local success = self.pluginDataStore:saveHistoricalSnapshot(analyticsData, category)
    
    if success then
        self.logger:info("INTEGRATION", "✅ Historical snapshot saved")
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to save historical snapshot")
    end
    
    return success
end

-- Clean old historical data
function AnalyticsIntegration:cleanOldData(maxAge)
    self.logger:info("INTEGRATION", "🧹 Cleaning old historical data...")
    
    maxAge = maxAge or (self.settings.analytics.retainDataDays * 86400) -- Convert days to seconds
    
    local success = self.pluginDataStore:cleanOldHistoricalData(maxAge)
    
    if success then
        self.logger:info("INTEGRATION", "✅ Old data cleaned successfully")
    else
        self.logger:warn("INTEGRATION", "⚠️ Failed to clean old data")
    end
    
    return success
end

-- ==================== EVENT TRACKING ====================

-- Track UI interaction (convenience method)
function AnalyticsIntegration:trackUIEvent(eventType, details)
    if self.analyticsService then
        self.analyticsService:trackUIInteraction(eventType, details)
    end
end

-- Track DataStore operation (convenience method)
function AnalyticsIntegration:trackDataStoreEvent(eventType, details)
    if self.analyticsService then
        self.analyticsService:trackDataStoreOperation(eventType, details)
    end
end

-- Track error (convenience method)
function AnalyticsIntegration:trackError(errorType, errorMessage, context)
    if self.analyticsService then
        self.analyticsService:trackError(errorType, errorMessage, context)
    end
end

-- Track performance (convenience method)
function AnalyticsIntegration:trackPerformance(operation, duration, success)
    if self.analyticsService then
        self.analyticsService:trackPerformanceOperation(operation, duration, success)
    end
end

-- ==================== UTILITY METHODS ====================

-- Export analytics data
function AnalyticsIntegration:exportAnalyticsData(format)
    format = format or "json"
    
    local data = {
        settings = self.settings,
        currentAnalytics = self:getCurrentAnalytics(),
        datastoreStats = self:getDataStoreStats(),
        savedReports = self:getSavedReports(),
        exportTimestamp = tick(),
        exportFormat = format
    }
    
    if format == "json" then
        return HttpService:JSONEncode(data)
    else
        -- Add other format support as needed
        return tostring(data)
    end
end

-- Import analytics data
function AnalyticsIntegration:importAnalyticsData(jsonData)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonData)
    end)
    
    if not success then
        self.logger:error("INTEGRATION", "❌ Failed to parse import data")
        return false
    end
    
    -- Import settings if available
    if data.settings then
        self.settings = data.settings
        self:savePluginSettings()
    end
    
    self.logger:info("INTEGRATION", "✅ Analytics data imported successfully")
    return true
end

-- Get system status
function AnalyticsIntegration:getSystemStatus()
    return {
        pluginDataStore = {
            initialized = self.pluginDataStore.initialized,
            stats = self:getDataStoreStats()
        },
        
        analyticsService = {
            active = self.analyticsService.isActive,
            sessionId = self.analyticsService.analyticsState.sessionId,
            sessionDuration = tick() - self.analyticsService.analyticsState.sessionStartTime
        },
        
        reportManager = {
            available = self.reportManager ~= nil,
            cachedReports = self.reportManager and #self.reportManager.reportCache or 0
        },
        
        settings = {
            loaded = self.settings ~= nil,
            autoSave = self.settings and self.settings.dataStore and self.settings.dataStore.autoBackup or false
        }
    }
end

return AnalyticsIntegration 