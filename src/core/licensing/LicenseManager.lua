-- DataStore Manager Pro - Safe Feature Management
-- Feature access management without real money transactions

local FeatureManager = {}

-- Safe feature configuration
local FEATURE_TIERS = {
    BASIC = {
        name = "Basic",
        features = {"basic_datastore_access", "simple_editing", "basic_export"}
    },
    STANDARD = {
        name = "Standard", 
        features = {"advanced_search", "bulk_operations", "schema_validation"}
    },
    PREMIUM = {
        name = "Premium",
        features = {"analytics", "backup_restore", "advanced_tools"}
    }
}

-- Feature state
local featureState = {
    currentTier = "BASIC",
    enabledFeatures = {},
    initialized = false
}

function FeatureManager.initialize()
    -- Initialize with basic features enabled
    featureState.enabledFeatures = FEATURE_TIERS.BASIC.features
    featureState.initialized = true
    
    print("[FEATURE_MANAGER] [INFO] Feature management initialized with basic tier")
    return true
end

-- Check if feature is available
function FeatureManager.isFeatureEnabled(featureName)
    if not featureState.initialized then
        FeatureManager.initialize()
    end
    
    for _, feature in ipairs(featureState.enabledFeatures) do
        if feature == featureName then
            return true
        end
    end
    
    return false
end

-- Get available features
function FeatureManager.getAvailableFeatures()
    return featureState.enabledFeatures or FEATURE_TIERS.BASIC.features
end

-- Get feature information
function FeatureManager.getFeatureInfo(featureName)
    return {
        available = FeatureManager.isFeatureEnabled(featureName),
        tier = featureState.currentTier,
        description = "Feature access based on current configuration"
    }
end

return FeatureManager 