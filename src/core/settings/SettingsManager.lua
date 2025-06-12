-- DataStore Manager Pro - Settings Manager
-- Central orchestrator for all application settings and preferences
-- Provides unified API for theme, general, and advanced settings

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local SettingsManager = {}

-- Settings structure version for migration
local SETTINGS_VERSION = "1.0.0"

-- Default settings configuration
local DEFAULT_SETTINGS = {
    version = SETTINGS_VERSION,
    lastModified = 0,
    
    -- Theme & Appearance Settings
    theme = {
        selectedTheme = "dark_professional",
        customColors = {
            primary = "#3B82F6",
            secondary = "#10B981",
            accent = "#8B5CF6"
        },
        typography = {
            fontFamily = "Roboto",
            fontSize = 1.0, -- scaling factor
            codeFont = "Fira Code",
            lineHeight = 1.4
        },
        layout = {
            sidebarWidth = 250,
            contentSpacing = "comfortable", -- compact, comfortable, spacious
            iconSize = 1.0,
            animations = true
        }
    },
    
    -- General Application Preferences
    general = {
        startup = {
            rememberLastDataStore = true,
            defaultView = "DataExplorer",
            autoConnect = true,
            showWelcome = true
        },
        autoSave = {
            frequency = 60, -- seconds
            backupRetention = 7, -- days
            exportFormat = "json",
            crashRecovery = true
        },
        notifications = {
            soundEnabled = true,
            duration = 5, -- seconds
            position = "top-right",
            types = {
                success = true,
                warning = true,
                error = true,
                info = false
            }
        },
        language = {
            interface = "en",
            dateFormat = "MM/DD/YYYY",
            numberFormat = "US",
            currency = "USD"
        }
    },
    
    -- DataStore Configuration
    datastore = {
        connection = {
            timeout = 30,
            retryAttempts = 3,
            rateLimitMode = "adaptive",
            connectionPoolSize = 5
        },
        cache = {
            memorySizeLimit = 100, -- MB
            defaultExpiration = 300, -- seconds
            autoClearOnStartup = false,
            persistentCacheEnabled = true
        },
        validation = {
            realTimeValidation = true,
            enforcementLevel = "permissive",
            autoFixSuggestions = true,
            validationErrorNotifications = true
        },
        defaults = {
            scope = "global",
            keyNamingConvention = "camelCase",
            backupNamingPattern = "{datastore}_{timestamp}",
            exportTemplate = "standard"
        }
    },
    
    -- Security & Privacy
    security = {
        sessionTimeout = 3600, -- seconds
        autoLogout = true,
        encryptLocalData = true,
        auditLogging = true,
        privacyMode = false
    },
    
    -- Workflow & Automation
    workflow = {
        shortcuts = {
            refresh = "Ctrl+R",
            search = "Ctrl+F",
            newDataStore = "Ctrl+N",
            export = "Ctrl+E"
        },
        automation = {
            autoRefreshInterval = 30,
            batchOperationSize = 100,
            smartSuggestions = true
        }
    },
    
    -- Analytics & Monitoring
    analytics = {
        enableTracking = true,
        performanceMonitoring = true,
        errorReporting = true,
        usageStatistics = false
    }
}

function SettingsManager.new(pluginContext)
    local self = setmetatable({}, {__index = SettingsManager})
    
    self.plugin = pluginContext
    self.settings = Utils.deepCopy(DEFAULT_SETTINGS)
    self.customThemes = {}
    self.changeCallbacks = {}
    self.isLoaded = false
    
    -- Load settings from persistent storage
    self:loadSettings()
    
    debugLog("Settings Manager initialized", "INFO")
    return self
end

-- Load settings from plugin storage
function SettingsManager:loadSettings()
    if not self.plugin then
        debugLog("No plugin context available for settings loading", "WARN")
        return false
    end
    
    local success, savedSettings = pcall(function()
        local settingsData = self.plugin:GetSetting("DataStoreManagerSettings")
        if settingsData then
            return HttpService:JSONDecode(settingsData)
        end
        return nil
    end)
    
    if success and savedSettings then
        -- Validate and migrate settings if needed
        self:validateAndMigrateSettings(savedSettings)
        debugLog("Settings loaded successfully", "INFO")
    else
        debugLog("Using default settings (no saved settings found)", "INFO")
    end
    
    self.isLoaded = true
    return true
end

-- Save settings to plugin storage
function SettingsManager:saveSettings()
    if not self.plugin then
        debugLog("No plugin context available for settings saving", "WARN")
        return false
    end
    
    -- Update last modified timestamp
    self.settings.lastModified = tick()
    
    local success, error = pcall(function()
        local settingsData = HttpService:JSONEncode(self.settings)
        self.plugin:SetSetting("DataStoreManagerSettings", settingsData)
    end)
    
    if success then
        debugLog("Settings saved successfully", "INFO")
        self:notifySettingsChanged("settings_saved")
        return true
    else
        debugLog("Failed to save settings: " .. tostring(error), "ERROR")
        return false
    end
end

-- Validate and migrate settings from older versions
function SettingsManager:validateAndMigrateSettings(loadedSettings)
    if not loadedSettings.version then
        debugLog("Migrating settings from pre-versioned format", "INFO")
        -- Migration logic for old settings
        self.settings = self:mergeSettings(DEFAULT_SETTINGS, loadedSettings)
    elseif loadedSettings.version ~= SETTINGS_VERSION then
        debugLog("Migrating settings from version " .. loadedSettings.version .. " to " .. SETTINGS_VERSION, "INFO")
        self.settings = self:migrateSettingsVersion(loadedSettings)
    else
        self.settings = self:mergeSettings(DEFAULT_SETTINGS, loadedSettings)
    end
end

-- Merge loaded settings with defaults to ensure all fields exist
function SettingsManager:mergeSettings(defaults, loaded)
    local result = Utils.deepCopy(defaults)
    
    for key, value in pairs(loaded) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = self:mergeSettings(result[key], value)
        else
            result[key] = value
        end
    end
    
    return result
end

-- Migrate settings between versions
function SettingsManager:migrateSettingsVersion(oldSettings)
    -- Future migration logic will go here
    -- For now, just merge with defaults
    return self:mergeSettings(DEFAULT_SETTINGS, oldSettings)
end

-- Get setting value by path (e.g., "theme.selectedTheme")
function SettingsManager:getSetting(path)
    local keys = string.split(path, ".")
    local current = self.settings
    
    for _, key in ipairs(keys) do
        if type(current) == "table" and current[key] ~= nil then
            current = current[key]
        else
            debugLog("Setting path not found: " .. path, "WARN")
            return nil
        end
    end
    
    return current
end

-- Set setting value by path
function SettingsManager:setSetting(path, value)
    local keys = string.split(path, ".")
    local current = self.settings
    
    -- Navigate to parent of target key
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    -- Set the final value
    local finalKey = keys[#keys]
    local oldValue = current[finalKey]
    current[finalKey] = value
    
    -- Auto-save settings
    self:saveSettings()
    
    -- Notify listeners of the change
    self:notifySettingsChanged(path, oldValue, value)
    
    debugLog("Setting updated: " .. path .. " = " .. tostring(value), "INFO")
end

-- Get entire settings category
function SettingsManager:getSettingsCategory(category)
    return self.settings[category] and Utils.deepCopy(self.settings[category]) or nil
end

-- Update entire settings category
function SettingsManager:updateSettingsCategory(category, newSettings)
    if self.settings[category] then
        local oldSettings = Utils.deepCopy(self.settings[category])
        self.settings[category] = newSettings
        self:saveSettings()
        self:notifySettingsChanged(category, oldSettings, newSettings)
        debugLog("Settings category updated: " .. category, "INFO")
    else
        debugLog("Settings category not found: " .. category, "WARN")
    end
end

-- Register callback for settings changes
function SettingsManager:onSettingsChanged(callback)
    table.insert(self.changeCallbacks, callback)
end

-- Notify all listeners of settings changes
function SettingsManager:notifySettingsChanged(path, oldValue, newValue)
    for _, callback in ipairs(self.changeCallbacks) do
        pcall(function()
            callback(path, oldValue, newValue)
        end)
    end
end

-- Reset settings to defaults
function SettingsManager:resetToDefaults()
    self.settings = Utils.deepCopy(DEFAULT_SETTINGS)
    self:saveSettings()
    self:notifySettingsChanged("reset_to_defaults")
    debugLog("Settings reset to defaults", "INFO")
end

-- Reset specific category to defaults
function SettingsManager:resetCategoryToDefaults(category)
    if DEFAULT_SETTINGS[category] then
        local oldSettings = Utils.deepCopy(self.settings[category])
        self.settings[category] = Utils.deepCopy(DEFAULT_SETTINGS[category])
        self:saveSettings()
        self:notifySettingsChanged(category, oldSettings, self.settings[category])
        debugLog("Settings category reset to defaults: " .. category, "INFO")
    end
end

-- Export settings to file
function SettingsManager:exportSettings()
    local exportData = {
        version = SETTINGS_VERSION,
        exportDate = os.date("%Y-%m-%d %H:%M:%S"),
        settings = self.settings,
        customThemes = self.customThemes
    }
    
    return HttpService:JSONEncode(exportData)
end

-- Import settings from file data
function SettingsManager:importSettings(settingsData)
    local success, importData = pcall(function()
        return HttpService:JSONDecode(settingsData)
    end)
    
    if not success then
        debugLog("Failed to parse imported settings data", "ERROR")
        return false
    end
    
    if importData.settings then
        self:validateAndMigrateSettings(importData.settings)
        if importData.customThemes then
            self.customThemes = importData.customThemes
        end
        self:saveSettings()
        self:notifySettingsChanged("settings_imported")
        debugLog("Settings imported successfully", "INFO")
        return true
    else
        debugLog("Invalid settings format in import data", "ERROR")
        return false
    end
end

-- Get settings summary for display
function SettingsManager:getSettingsSummary()
    return {
        version = self.settings.version,
        lastModified = self.settings.lastModified,
        theme = self.settings.theme.selectedTheme,
        categoriesCount = 0, -- Will be calculated
        customThemesCount = #self.customThemes
    }
end

-- Validate setting value
function SettingsManager:validateSetting(path, value)
    -- Basic validation logic
    -- This could be extended with more sophisticated validation
    if path:match("^theme%.fontSize$") then
        return type(value) == "number" and value >= 0.5 and value <= 2.0
    elseif path:match("^general%.autoSave%.frequency$") then
        return type(value) == "number" and value >= 10 and value <= 600
    elseif path:match("^datastore%.connection%.timeout$") then
        return type(value) == "number" and value >= 5 and value <= 120
    end
    
    return true -- Default: allow all values
end

-- Get all available themes
function SettingsManager:getAvailableThemes()
    local themes = {
        {
            id = "dark_professional",
            name = "Dark Professional",
            description = "The default professional dark theme",
            isBuiltIn = true
        },
        {
            id = "light_clean",
            name = "Light Clean",
            description = "Clean and bright light theme",
            isBuiltIn = true
        },
        {
            id = "high_contrast",
            name = "High Contrast",
            description = "High contrast theme for accessibility",
            isBuiltIn = true
        }
    }
    
    -- Add custom themes
    for themeId, themeData in pairs(self.customThemes) do
        table.insert(themes, {
            id = themeId,
            name = themeData.name,
            description = themeData.description,
            isBuiltIn = false
        })
    end
    
    return themes
end

-- Cleanup function
function SettingsManager:cleanup()
    self:saveSettings()
    self.changeCallbacks = {}
    debugLog("Settings Manager cleanup complete", "INFO")
end

return SettingsManager 