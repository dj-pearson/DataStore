-- DataStore Manager Pro - License Management System
-- Implements Commercial Viability principle with feature gating and user experience

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)

local LicenseManager = {}

-- License tiers and their capabilities
local LICENSE_TIERS = {
    FREE = {
        level = 0,
        name = "Free Trial",
        icon = "🆓",
        description = "Basic DataStore operations",
        features = {
            "basicDataExplorer",
            "simpleDataEditing",
            "basicSearch"
        },
        limits = {
            maxDataStores = 3,
            maxOperationsPerHour = 100,
            maxConcurrentKeys = 50
        }
    },
    BASIC = {
        level = 1,
        name = "Basic Edition",
        icon = "⭐",
        description = "Essential DataStore management",
        price = 19.99,
        features = {
            "basicDataExplorer",
            "simpleDataEditing",
            "basicSearch",
            "advancedSearch",
            "dataExport",
            "operationHistory"
        },
        limits = {
            maxDataStores = 10,
            maxOperationsPerHour = 500,
            maxConcurrentKeys = 200
        }
    },
    PROFESSIONAL = {
        level = 2,
        name = "Professional Edition", 
        icon = "💼",
        description = "Advanced features for professionals",
        price = 49.99,
        features = {
            "basicDataExplorer",
            "simpleDataEditing",
            "basicSearch",
            "advancedSearch",
            "dataExport",
            "operationHistory",
            "schemaValidation",
            "performanceMonitoring",
            "bulkOperations",
            "advancedAnalytics",
            "errorReporting",
            "dataVisualization"
        },
        limits = {
            maxDataStores = 50,
            maxOperationsPerHour = 2000,
            maxConcurrentKeys = 1000
        }
    },
    ENTERPRISE = {
        level = 3,
        name = "Enterprise Edition",
        icon = "🏢",
        description = "Full-featured enterprise solution",
        price = 99.99,
        features = {
            "basicDataExplorer",
            "simpleDataEditing", 
            "basicSearch",
            "advancedSearch",
            "dataExport",
            "operationHistory",
            "schemaValidation",
            "performanceMonitoring",
            "bulkOperations", 
            "advancedAnalytics",
            "errorReporting",
            "dataVisualization",
            "teamCollaboration",
            "customReporting",
            "apiAccess",
            "prioritySupport",
            "customIntegrations"
        },
        limits = {
            maxDataStores = -1, -- Unlimited
            maxOperationsPerHour = -1, -- Unlimited
            maxConcurrentKeys = -1 -- Unlimited
        }
    }
}

-- Feature requirements mapping
local FEATURE_REQUIREMENTS = {
    -- Basic features (Free tier)
    basicDataExplorer = 0,
    simpleDataEditing = 0,
    basicSearch = 0,
    
    -- Basic Edition features
    advancedSearch = 1,
    dataExport = 1,
    operationHistory = 1,
    
    -- Professional Edition features
    schemaValidation = 2,
    performanceMonitoring = 2,
    bulkOperations = 2,
    advancedAnalytics = 2,
    errorReporting = 2,
    dataVisualization = 2,
    
    -- Enterprise features
    teamCollaboration = 3,
    customReporting = 3,
    apiAccess = 3,
    prioritySupport = 3,
    customIntegrations = 3
}

function LicenseManager.initialize()
    print("[LICENSE_MANAGER] [INFO] License Manager initialized with tiered licensing system")
    
    -- Initialize with free tier
    LicenseManager.currentTier = LICENSE_TIERS.FREE
    LicenseManager.activationTime = os.time()
    LicenseManager.usageTracking = {
        operationsThisHour = 0,
        activeDataStores = {},
        featuresUsed = {},
        lastHourReset = os.time()
    }
    
    return true
end

-- Check if user has access to a specific feature
function LicenseManager.hasFeatureAccess(featureName)
    local requiredLevel = FEATURE_REQUIREMENTS[featureName]
    if not requiredLevel then
        print("[LICENSE_MANAGER] [WARN] Unknown feature: " .. featureName)
        return false
    end
    
    local currentLevel = LicenseManager.currentTier.level
    local hasAccess = currentLevel >= requiredLevel
    
    -- Track feature usage attempts
    LicenseManager.usageTracking.featuresUsed[featureName] = (LicenseManager.usageTracking.featuresUsed[featureName] or 0) + 1
    
    if not hasAccess then
        print(string.format("[LICENSE_MANAGER] [INFO] Feature '%s' requires %s tier (current: %s)", 
            featureName, 
            LicenseManager.getTierNameByLevel(requiredLevel),
            LicenseManager.currentTier.name))
    end
    
    return hasAccess
end

-- Check usage limits
function LicenseManager.checkUsageLimit(limitType, currentValue)
    local limit = LicenseManager.currentTier.limits[limitType]
    
    if limit == -1 then -- Unlimited
        return true, -1
    end
    
    local isWithinLimit = currentValue < limit
    local remaining = math.max(0, limit - currentValue)
    
    if not isWithinLimit then
        print(string.format("[LICENSE_MANAGER] [WARN] Usage limit exceeded: %s (%d/%d)", limitType, currentValue, limit))
    end
    
    return isWithinLimit, remaining
end

-- Track operation for usage limits
function LicenseManager.trackOperation(_, dataStore)
    local currentTime = os.time()
    local tracking = LicenseManager.usageTracking
    
    -- Reset hourly counter if needed
    if currentTime - tracking.lastHourReset > 3600 then -- 1 hour
        tracking.operationsThisHour = 0
        tracking.lastHourReset = currentTime
    end
    
    -- Track operation
    tracking.operationsThisHour = tracking.operationsThisHour + 1
    
    -- Track active DataStores
    tracking.activeDataStores[dataStore] = currentTime
    
    -- Check limits
    local withinLimit, remaining = LicenseManager.checkUsageLimit("maxOperationsPerHour", tracking.operationsThisHour)
    
    if not withinLimit then
        return false, "Hourly operation limit exceeded"
    end
    
    return true, remaining
end

-- Get available tiers for upgrade
function LicenseManager.getAvailableUpgrades()
    local currentLevel = LicenseManager.currentTier.level
    local upgrades = {}
    
    for _, tier in pairs(LICENSE_TIERS) do
        if tier.level > currentLevel then
            table.insert(upgrades, {
                tier = tier,
                benefits = LicenseManager.getUpgradeBenefits(tier),
                savings = LicenseManager.calculateSavings(tier)
            })
        end
    end
    
    -- Sort by tier level
    table.sort(upgrades, function(a, b) return a.tier.level < b.tier.level end)
    
    return upgrades
end

-- Get benefits of upgrading to a specific tier
function LicenseManager.getUpgradeBenefits(targetTier)
    local currentFeatures = LicenseManager.currentTier.features
    local targetFeatures = targetTier.features
    local newFeatures = {}
    
    for _, feature in ipairs(targetFeatures) do
        local hasFeature = false
        for _, currentFeature in ipairs(currentFeatures) do
            if currentFeature == feature then
                hasFeature = true
                break
            end
        end
        
        if not hasFeature then
            table.insert(newFeatures, feature)
        end
    end
    
    return {
        newFeatures = newFeatures,
        limitsUpgrade = {
            dataStores = {
                from = LicenseManager.currentTier.limits.maxDataStores,
                to = targetTier.limits.maxDataStores
            },
            operations = {
                from = LicenseManager.currentTier.limits.maxOperationsPerHour,
                to = targetTier.limits.maxOperationsPerHour
            }
        }
    }
end

-- Show upgrade prompt for a specific feature
function LicenseManager.showUpgradePrompt(featureName, context)
    local requiredLevel = FEATURE_REQUIREMENTS[featureName]
    local requiredTier = LicenseManager.getTierByLevel(requiredLevel)
    
    if not requiredTier then
        return false
    end
    
    local upgradeInfo = {
        feature = featureName,
        currentTier = LicenseManager.currentTier,
        requiredTier = requiredTier,
        context = context or {},
        benefits = LicenseManager.getUpgradeBenefits(requiredTier),
        savings = LicenseManager.calculateSavings(requiredTier)
    }
    
    -- Log the upgrade prompt for analytics
    print(string.format("[LICENSE_MANAGER] [INFO] Upgrade prompt shown for feature: %s (requires %s)", 
        featureName, requiredTier.name))
    
    -- Return upgrade prompt information for UI display
    return {
        title = string.format("Upgrade to %s %s", requiredTier.icon, requiredTier.name),
        message = string.format("The '%s' feature requires %s or higher.", 
            LicenseManager.getFeatureDisplayName(featureName), 
            requiredTier.name),
        price = requiredTier.price,
        benefits = upgradeInfo.benefits.newFeatures,
        ctaText = string.format("Upgrade for $%.2f", requiredTier.price),
        upgradeUrl = LicenseManager.getUpgradeUrl(requiredTier, featureName)
    }
end

-- Get feature display name
function LicenseManager.getFeatureDisplayName(featureName)
    local displayNames = {
        basicDataExplorer = "Data Explorer",
        simpleDataEditing = "Data Editing",
        basicSearch = "Basic Search",
        advancedSearch = "Advanced Search",
        dataExport = "Data Export",
        operationHistory = "Operation History",
        schemaValidation = "Schema Validation",
        performanceMonitoring = "Performance Monitoring",
        bulkOperations = "Bulk Operations",
        advancedAnalytics = "Advanced Analytics",
        errorReporting = "Error Reporting",
        dataVisualization = "Data Visualization",
        teamCollaboration = "Team Collaboration",
        customReporting = "Custom Reporting",
        apiAccess = "API Access",
        prioritySupport = "Priority Support",
        customIntegrations = "Custom Integrations"
    }
    
    return displayNames[featureName] or featureName
end

-- Get upgrade URL
function LicenseManager.getUpgradeUrl(tier, featureContext)
    local baseUrl = "https://your-store.com/datastore-manager-pro"
    local params = {
        tier = string.lower(tier.name:gsub(" ", "-")),
        source = "plugin",
        feature = featureContext or "general"
    }
    
    local queryString = ""
    for key, value in pairs(params) do
        if queryString == "" then
            queryString = "?" .. key .. "=" .. value
        else
            queryString = queryString .. "&" .. key .. "=" .. value
        end
    end
    
    return baseUrl .. queryString
end

-- Calculate potential savings or value
function LicenseManager.calculateSavings(tier)
    -- Example: Calculate time savings based on tier features
    local timeSavingsPerWeek = 0
    
    if tier.level >= 1 then
        timeSavingsPerWeek = timeSavingsPerWeek + 2 -- Advanced search saves 2 hours/week
    end
    
    if tier.level >= 2 then
        timeSavingsPerWeek = timeSavingsPerWeek + 5 -- Professional features save 5 hours/week
    end
    
    if tier.level >= 3 then
        timeSavingsPerWeek = timeSavingsPerWeek + 8 -- Enterprise features save 8 hours/week
    end
    
    local monthlyValue = timeSavingsPerWeek * 4 * 50 -- Assume $50/hour developer time
    
    return {
        timeSavedPerWeek = timeSavingsPerWeek,
        estimatedMonthlyValue = monthlyValue,
        roi = monthlyValue / (tier.price or 1)
    }
end

-- Get tier by level
function LicenseManager.getTierByLevel(level)
    for _, tier in pairs(LICENSE_TIERS) do
        if tier.level == level then
            return tier
        end
    end
    return nil
end

-- Get tier name by level
function LicenseManager.getTierNameByLevel(level)
    local tier = LicenseManager.getTierByLevel(level)
    return tier and tier.name or "Unknown"
end

-- Get current license status
function LicenseManager.getLicenseStatus()
    local currentTime = os.time()
    local activeDataStoreCount = 0
    
    -- Count active DataStores (accessed in last hour)
    for _, lastAccess in pairs(LicenseManager.usageTracking.activeDataStores) do
        if currentTime - lastAccess < 3600 then
            activeDataStoreCount = activeDataStoreCount + 1
        end
    end
    
    return {
        tier = LicenseManager.currentTier,
        usage = {
            operationsThisHour = LicenseManager.usageTracking.operationsThisHour,
            activeDataStores = activeDataStoreCount,
            featuresUsed = (function()
                local keys = {}
                for key, _ in pairs(LicenseManager.usageTracking.featuresUsed) do
                    table.insert(keys, key)
                end
                return keys
            end)()
        },
        limits = LicenseManager.currentTier.limits,
        activeSince = LicenseManager.activationTime,
        daysActive = math.floor((currentTime - LicenseManager.activationTime) / 86400)
    }
end

-- Get usage statistics for analytics
function LicenseManager.getUsageStatistics()
    local status = LicenseManager.getLicenseStatus()
    
    return {
        tierLevel = status.tier.level,
        tierName = status.tier.name,
        operationsThisHour = status.usage.operationsThisHour,
        activeDataStores = status.usage.activeDataStores,
        featuresAttempted = (function()
            local count = 0
            for _, _ in pairs(LicenseManager.usageTracking.featuresUsed) do
                count = count + 1
            end
            return count
        end)(),
        daysActive = status.daysActive,
        utilizationRate = {
            operations = status.tier.limits.maxOperationsPerHour > 0 and 
                        (status.usage.operationsThisHour / status.tier.limits.maxOperationsPerHour) or 0,
            dataStores = status.tier.limits.maxDataStores > 0 and 
                        (status.usage.activeDataStores / status.tier.limits.maxDataStores) or 0
        }
    }
end

-- Simulate license upgrade (for testing)
function LicenseManager.simulateUpgrade(tierName)
    for _, tier in pairs(LICENSE_TIERS) do
        if tier.name == tierName then
            LicenseManager.currentTier = tier
            Utils.debugLog("Simulated upgrade to " .. tierName, "INFO")
            return true
        end
    end
    return false
end

-- Get feature usage recommendations
function LicenseManager.getFeatureRecommendations()
    local recommendations = {}
    local usage = LicenseManager.usageTracking
    
    -- Recommend upgrade if hitting limits frequently
    if usage.operationsThisHour > LicenseManager.currentTier.limits.maxOperationsPerHour * 0.8 then
        table.insert(recommendations, {
            type = "upgrade",
            priority = "high",
            title = "Consider Upgrading",
            description = "You're using 80% of your hourly operation limit",
            suggestedTier = LicenseManager.getTierByLevel(LicenseManager.currentTier.level + 1)
        })
    end
    
    -- Recommend specific features based on usage patterns
    if usage.featuresUsed.basicSearch and usage.featuresUsed.basicSearch > 10 then
        table.insert(recommendations, {
            type = "feature",
            priority = "medium", 
            title = "Advanced Search Available",
            description = "Unlock regex search and advanced filtering",
            feature = "advancedSearch"
        })
    end
    
    return recommendations
end

function LicenseManager.cleanup()
    Utils.debugLog("License Manager cleanup complete", "INFO")
end

return LicenseManager 