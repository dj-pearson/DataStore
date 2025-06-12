-- DataStore Manager Pro - Feature Registry
-- Central registry for all advanced features with dynamic loading and integration

local FeatureRegistry = {}
FeatureRegistry.__index = FeatureRegistry

-- Import dependencies
local Constants = require(script.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[FEATURE_REGISTRY] [%s] %s", level, message))
end

-- Feature definitions
local FEATURES = {
    -- Core Features
    realTimeMonitor = {
        name = "Real-Time Monitor",
        description = "Live monitoring of DataStore operations with performance metrics",
        module = "features.monitoring.RealTimeMonitor",
        category = "monitoring",
        license = "enterprise",
        dependencies = {},
        settings = {
            autoStart = true,
            updateInterval = 2,
            alertThresholds = {
                latency = 1000,
                errorRate = 0.05
            }
        },
        ui = {
            icon = "📊",
            navItem = true,
            dashboard = true,
            realTimeWidget = true
        }
    },
    
    bulkOperations = {
        name = "Advanced Bulk Operations",
        description = "High-performance bulk operations with progress tracking and rollback",
        module = "features.operations.BulkOperationsManager",
        category = "operations",
        license = "professional",
        dependencies = {},
        settings = {
            maxBatchSize = 100,
            defaultDelay = 0.1,
            enableRollback = true
        },
        ui = {
            icon = "⚡",
            navItem = true,
            progressTracking = true,
            operationHistory = true
        }
    },
    
    backupManager = {
        name = "Backup & Restore",
        description = "Automated backups with compression and incremental support",
        module = "features.backup.BackupManager",
        category = "backup",
        license = "professional",
        dependencies = {},
        settings = {
            autoBackup = true,
            schedule = "daily",
            compression = true,
            maxBackups = 30
        },
        ui = {
            icon = "💾",
            navItem = true,
            scheduler = true,
            restoreWizard = true
        }
    },
    
    smartSearch = {
        name = "Smart Search Engine",
        description = "Intelligent search with filters, suggestions, and analytics",
        module = "features.search.SmartSearchEngine",
        category = "search",
        license = "basic",
        dependencies = {},
        settings = {
            enableSuggestions = true,
            cacheResults = true,
            analytics = true
        },
        ui = {
            icon = "🔍",
            searchBar = true,
            advancedFilters = true,
            suggestions = true
        }
    },
    
    teamCollaboration = {
        name = "Team Collaboration",
        description = "Multi-user workspace management and real-time collaboration",
        module = "features.collaboration.TeamManager",
        category = "collaboration",
        license = "enterprise",
        dependencies = {"realTimeMonitor"},
        settings = {
            realTimeSync = true,
            conflictResolution = "auto",
            maxUsers = 50
        },
        ui = {
            icon = "👥",
            navItem = true,
            userPresence = true,
            activityFeed = true
        }
    },
    
    advancedAnalytics = {
        name = "Advanced Analytics",
        description = "Enterprise analytics with custom dashboards and reporting",
        module = "features.analytics.AdvancedAnalytics",
        category = "analytics",
        license = "enterprise",
        dependencies = {"realTimeMonitor"},
        settings = {
            customDashboards = true,
            predictiveAnalytics = true,
            complianceReporting = true
        },
        ui = {
            icon = "📈",
            navItem = true,
            customDashboards = true,
            reportBuilder = true
        }
    },
    
    securityManager = {
        name = "Security & Compliance",
        description = "Advanced security features with audit logging and compliance",
        module = "features.security.SecurityManager",
        category = "security",
        license = "enterprise",
        dependencies = {"advancedAnalytics"},
        settings = {
            auditLogging = true,
            encryptionAtRest = true,
            complianceMode = "gdpr"
        },
        ui = {
            icon = "🛡️",
            navItem = true,
            auditLog = true,
            securityDashboard = true
        }
    },
    
    apiIntegration = {
        name = "API Integration",
        description = "REST API endpoints for external integrations",
        module = "features.integration.APIManager",
        category = "integration",
        license = "enterprise",
        dependencies = {"securityManager"},
        settings = {
            enableAPI = true,
            rateLimit = 1000,
            authentication = "bearer"
        },
        ui = {
            icon = "🔌",
            navItem = true,
            apiDocumentation = true,
            endpointTesting = true
        }
    }
}

-- Create new Feature Registry instance
function FeatureRegistry.new(licenseManager, services)
    local self = setmetatable({}, FeatureRegistry)
    
    self.licenseManager = licenseManager
    self.services = services or {}
    self.loadedFeatures = {}
    self.enabledFeatures = {}
    self.featureSettings = {}
    self.dependencies = {}
    
    debugLog("Feature Registry created")
    return self
end

-- Initialize feature registry
function FeatureRegistry:initialize()
    debugLog("Initializing Feature Registry...")
    
    -- Load feature settings
    self:loadFeatureSettings()
    
    -- Check license compatibility
    self:checkLicenseCompatibility()
    
    -- Resolve dependencies
    self:resolveDependencies()
    
    -- Load enabled features
    self:loadEnabledFeatures()
    
    debugLog("Feature Registry initialized")
    return true
end

-- Load feature settings
function FeatureRegistry:loadFeatureSettings()
    -- In real implementation, would load from persistent storage
    self.featureSettings = {
        realTimeMonitor = {enabled = true, autoStart = true},
        bulkOperations = {enabled = true},
        backupManager = {enabled = true, autoBackup = true},
        smartSearch = {enabled = true, enableSuggestions = true},
        teamCollaboration = {enabled = false}, -- Requires enterprise license
        advancedAnalytics = {enabled = false}, -- Requires enterprise license
        securityManager = {enabled = false}, -- Requires enterprise license
        apiIntegration = {enabled = false} -- Requires enterprise license
    }
    
    debugLog("Feature settings loaded")
end

-- Check license compatibility
function FeatureRegistry:checkLicenseCompatibility()
    local currentLicense = "basic"
    if self.licenseManager and self.licenseManager.getLicenseStatus then
        local status = self.licenseManager.getLicenseStatus()
        currentLicense = status.tier and status.tier.name and status.tier.name:lower() or "basic"
    end
    
    debugLog(string.format("Checking license compatibility (current: %s)", currentLicense))
    
    for featureId, feature in pairs(FEATURES) do
        local isCompatible = self:isLicenseCompatible(feature.license, currentLicense)
        
        if not isCompatible and self.featureSettings[featureId] and self.featureSettings[featureId].enabled then
            debugLog(string.format("Feature %s disabled - incompatible license (%s required, %s available)", 
                featureId, feature.license, currentLicense), "WARN")
            self.featureSettings[featureId].enabled = false
        end
    end
end

-- Check if license is compatible with feature
function FeatureRegistry:isLicenseCompatible(requiredLicense, currentLicense)
    local licenseHierarchy = {
        basic = 1,
        professional = 2,
        enterprise = 3
    }
    
    local required = licenseHierarchy[requiredLicense] or 1
    local current = licenseHierarchy[currentLicense] or 1
    
    return current >= required
end

-- Resolve feature dependencies
function FeatureRegistry:resolveDependencies()
    debugLog("Resolving feature dependencies...")
    
    for featureId, feature in pairs(FEATURES) do
        if self.featureSettings[featureId] and self.featureSettings[featureId].enabled then
            for _, dependency in ipairs(feature.dependencies) do
                if not self.featureSettings[dependency] or not self.featureSettings[dependency].enabled then
                    debugLog(string.format("Feature %s disabled - missing dependency: %s", featureId, dependency), "WARN")
                    self.featureSettings[featureId].enabled = false
                    break
                end
            end
        end
    end
end

-- Load enabled features
function FeatureRegistry:loadEnabledFeatures()
    debugLog("Loading enabled features...")
    
    for featureId, feature in pairs(FEATURES) do
        if self.featureSettings[featureId] and self.featureSettings[featureId].enabled then
            local success = self:loadFeature(featureId, feature)
            if success then
                self.enabledFeatures[featureId] = true
                debugLog(string.format("Feature loaded: %s", feature.name))
            end
        end
    end
    
    debugLog(string.format("Loaded %d features", self:getEnabledFeatureCount()))
end

-- Load individual feature
function FeatureRegistry:loadFeature(featureId, feature)
    local success, featureModule = pcall(function()
        -- In real implementation, would use require() with the module path
        -- For now, return a mock feature instance
        return self:createMockFeature(featureId, feature)
    end)
    
    if success then
        -- Initialize feature if it has an initialize method
        if featureModule.initialize then
            local initSuccess = pcall(function()
                featureModule:initialize(self.services)
            end)
            
            if not initSuccess then
                debugLog(string.format("Failed to initialize feature: %s", featureId), "ERROR")
                return false
            end
        end
        
        self.loadedFeatures[featureId] = featureModule
        return true
    else
        debugLog(string.format("Failed to load feature module: %s", featureId), "ERROR")
        return false
    end
end

-- Create mock feature for demonstration
function FeatureRegistry:createMockFeature(featureId, feature)
    local mockFeature = {
        id = featureId,
        name = feature.name,
        description = feature.description,
        category = feature.category,
        settings = feature.settings,
        isActive = false
    }
    
    -- Add common methods
    mockFeature.initialize = function(self, services)
        self.services = services
        self.isActive = true
        return true
    end
    
    mockFeature.start = function(self)
        self.isActive = true
        return true
    end
    
    mockFeature.stop = function(self)
        self.isActive = false
        return true
    end
    
    mockFeature.getStatus = function(self)
        return {
            active = self.isActive,
            name = self.name,
            category = self.category
        }
    end
    
    -- Add feature-specific methods
    if featureId == "realTimeMonitor" then
        mockFeature.getMetrics = function(self)
            return {
                operationsPerSecond = math.random(5, 25),
                averageLatency = math.random(50, 200),
                errorRate = math.random(0, 5) / 100
            }
        end
        
        mockFeature.addEventListener = function(self, event, callback)
            -- Mock event listener
            return true
        end
    elseif featureId == "bulkOperations" then
        mockFeature.executeBulkOperation = function(self, operation, items, options)
            return {
                success = true,
                operationId = Utils.createGUID(),
                estimatedDuration = #items * 0.1
            }
        end
        
        mockFeature.getActiveOperations = function(self)
            return {}
        end
    elseif featureId == "backupManager" then
        mockFeature.createBackup = function(self, options)
            return {
                success = true,
                backupId = Utils.createGUID(),
                estimatedSize = math.random(1000000, 50000000)
            }
        end
        
        mockFeature.getBackups = function(self, options)
            return {}
        end
    elseif featureId == "smartSearch" then
        mockFeature.search = function(self, query, options)
            return {
                success = true,
                results = {},
                metadata = {
                    totalResults = 0,
                    responseTime = math.random(10, 100)
                }
            }
        end
        
        mockFeature.getSuggestions = function(self, partialQuery, options)
            return {}
        end
    end
    
    return mockFeature
end

-- Get feature by ID
function FeatureRegistry:getFeature(featureId)
    return self.loadedFeatures[featureId]
end

-- Get all enabled features
function FeatureRegistry:getEnabledFeatures()
    local features = {}
    for featureId, _ in pairs(self.enabledFeatures) do
        local feature = self.loadedFeatures[featureId]
        if feature then
            table.insert(features, {
                id = featureId,
                name = feature.name,
                category = feature.category,
                status = feature:getStatus()
            })
        end
    end
    return features
end

-- Get features by category
function FeatureRegistry:getFeaturesByCategory(category)
    local features = {}
    for featureId, feature in pairs(self.loadedFeatures) do
        if feature.category == category then
            table.insert(features, {
                id = featureId,
                name = feature.name,
                status = feature:getStatus()
            })
        end
    end
    return features
end

-- Get navigation items for enabled features
function FeatureRegistry:getNavigationItems()
    local navItems = {}
    
    for featureId, _ in pairs(self.enabledFeatures) do
        local featureConfig = FEATURES[featureId]
        if featureConfig and featureConfig.ui and featureConfig.ui.navItem then
            table.insert(navItems, {
                id = featureId,
                icon = featureConfig.ui.icon,
                text = featureConfig.name,
                action = "show" .. featureId:gsub("^%l", string.upper) .. "View",
                category = featureConfig.category
            })
        end
    end
    
    -- Sort by category and name
    table.sort(navItems, function(a, b)
        if a.category == b.category then
            return a.text < b.text
        end
        return a.category < b.category
    end)
    
    return navItems
end

-- Enable feature
function FeatureRegistry:enableFeature(featureId)
    local feature = FEATURES[featureId]
    if not feature then
        return false, "Feature not found: " .. tostring(featureId)
    end
    
    -- Check license compatibility
    local currentLicense = self.licenseManager and self.licenseManager:getCurrentLicense() or "basic"
    if not self:isLicenseCompatible(feature.license, currentLicense) then
        return false, string.format("Feature requires %s license (current: %s)", feature.license, currentLicense)
    end
    
    -- Check dependencies
    for _, dependency in ipairs(feature.dependencies) do
        if not self.enabledFeatures[dependency] then
            return false, "Missing dependency: " .. dependency
        end
    end
    
    -- Load feature if not already loaded
    if not self.loadedFeatures[featureId] then
        local success = self:loadFeature(featureId, feature)
        if not success then
            return false, "Failed to load feature"
        end
    end
    
    self.enabledFeatures[featureId] = true
    self.featureSettings[featureId] = self.featureSettings[featureId] or {}
    self.featureSettings[featureId].enabled = true
    
    debugLog(string.format("Feature enabled: %s", feature.name))
    return true
end

-- Disable feature
function FeatureRegistry:disableFeature(featureId)
    if not self.enabledFeatures[featureId] then
        return false, "Feature not enabled: " .. tostring(featureId)
    end
    
    -- Check if other features depend on this one
    for otherFeatureId, otherFeature in pairs(FEATURES) do
        if self.enabledFeatures[otherFeatureId] then
            for _, dependency in ipairs(otherFeature.dependencies) do
                if dependency == featureId then
                    return false, string.format("Feature is required by: %s", otherFeature.name)
                end
            end
        end
    end
    
    -- Stop feature if it's active
    local feature = self.loadedFeatures[featureId]
    if feature and feature.stop then
        feature:stop()
    end
    
    self.enabledFeatures[featureId] = nil
    self.featureSettings[featureId] = self.featureSettings[featureId] or {}
    self.featureSettings[featureId].enabled = false
    
    debugLog(string.format("Feature disabled: %s", featureId))
    return true
end

-- Get feature settings
function FeatureRegistry:getFeatureSettings(featureId)
    return self.featureSettings[featureId] or {}
end

-- Update feature settings
function FeatureRegistry:updateFeatureSettings(featureId, settings)
    self.featureSettings[featureId] = self.featureSettings[featureId] or {}
    
    for key, value in pairs(settings) do
        self.featureSettings[featureId][key] = value
    end
    
    -- Apply settings to loaded feature
    local feature = self.loadedFeatures[featureId]
    if feature and feature.updateSettings then
        feature:updateSettings(self.featureSettings[featureId])
    end
    
    debugLog(string.format("Settings updated for feature: %s", featureId))
end

-- Get feature statistics
function FeatureRegistry:getFeatureStatistics()
    local stats = {
        total = 0,
        enabled = 0,
        byCategory = {},
        byLicense = {}
    }
    
    for featureId, feature in pairs(FEATURES) do
        stats.total = stats.total + 1
        
        -- Count by category
        stats.byCategory[feature.category] = (stats.byCategory[feature.category] or 0) + 1
        
        -- Count by license
        stats.byLicense[feature.license] = (stats.byLicense[feature.license] or 0) + 1
        
        -- Count enabled
        if self.enabledFeatures[featureId] then
            stats.enabled = stats.enabled + 1
        end
    end
    
    return stats
end

-- Get enabled feature count
function FeatureRegistry:getEnabledFeatureCount()
    local count = 0
    for _ in pairs(self.enabledFeatures) do
        count = count + 1
    end
    return count
end

-- Check if feature is enabled
function FeatureRegistry:isFeatureEnabled(featureId)
    return self.enabledFeatures[featureId] == true
end

-- Check if feature is available (license compatible)
function FeatureRegistry:isFeatureAvailable(featureId)
    local feature = FEATURES[featureId]
    if not feature then
        return false
    end
    
    local currentLicense = self.licenseManager and self.licenseManager:getCurrentLicense() or "basic"
    return self:isLicenseCompatible(feature.license, currentLicense)
end

-- Get all available features (license compatible)
function FeatureRegistry:getAvailableFeatures()
    local currentLicense = self.licenseManager and self.licenseManager:getCurrentLicense() or "basic"
    local available = {}
    
    for featureId, feature in pairs(FEATURES) do
        if self:isLicenseCompatible(feature.license, currentLicense) then
            table.insert(available, {
                id = featureId,
                name = feature.name,
                description = feature.description,
                category = feature.category,
                license = feature.license,
                enabled = self.enabledFeatures[featureId] == true
            })
        end
    end
    
    return available
end

-- Start all enabled features
function FeatureRegistry:startEnabledFeatures()
    debugLog("Starting enabled features...")
    
    local startedCount = 0
    for featureId, _ in pairs(self.enabledFeatures) do
        local feature = self.loadedFeatures[featureId]
        if feature and feature.start then
            local success = pcall(function()
                feature:start()
            end)
            
            if success then
                startedCount = startedCount + 1
                debugLog(string.format("Started feature: %s", featureId))
            else
                debugLog(string.format("Failed to start feature: %s", featureId), "ERROR")
            end
        end
    end
    
    debugLog(string.format("Started %d features", startedCount))
    return startedCount
end

-- Stop all features
function FeatureRegistry:stopAllFeatures()
    debugLog("Stopping all features...")
    
    local stoppedCount = 0
    for featureId, feature in pairs(self.loadedFeatures) do
        if feature and feature.stop then
            local success = pcall(function()
                feature:stop()
            end)
            
            if success then
                stoppedCount = stoppedCount + 1
                debugLog(string.format("Stopped feature: %s", featureId))
            end
        end
    end
    
    debugLog(string.format("Stopped %d features", stoppedCount))
    return stoppedCount
end

return FeatureRegistry 