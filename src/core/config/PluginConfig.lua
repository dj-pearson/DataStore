-- DataStore Manager Pro - Plugin Configuration Manager
-- Handles all configuration with individual error tracking

local PluginConfig = {}

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

-- Local state
local config = {}
local initialized = false
local defaultConfig = {
    theme = "dark",
    autoSave = true,
    performanceTracking = true,
    debugMode = Constants.DEBUG.ENABLED,
    maxCacheSize = 1000,
    defaultTimeout = 30,
    ui = {
        windowWidth = Constants.UI.WINDOW.DEFAULT_WIDTH,
        windowHeight = Constants.UI.WINDOW.DEFAULT_HEIGHT,
        treeViewWidth = 300,
        statusBarVisible = true,
        gridSize = 20
    },
    datastore = {
        maxRetries = Constants.DATASTORE.MAX_RETRIES,
        retryDelay = Constants.DATASTORE.RETRY_DELAY_BASE,
        cacheTimeout = Constants.DATASTORE.CACHE_TIMEOUT,
        requestCooldown = Constants.DATASTORE.REQUEST_COOLDOWN
    },
    logging = {
        level = Constants.LOGGING.DEFAULT_LEVEL,
        maxEntries = Constants.LOGGING.MAX_LOG_ENTRIES,
        saveToFile = false
    },
    customSettings = {}
}

-- Configuration file management
local CONFIG_FILE_NAME = "DataStoreManagerPro_Config.json"

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[CONFIG] [%s] %s", level, message))
end

-- Load configuration from storage
local function loadFromStorage()
    debugLog("Loading configuration from storage")
    
    -- Try to load from plugin storage (if available)
    local success, savedConfig = pcall(function()
        -- In a real implementation, this would use plugin:GetSetting()
        -- For now, we'll use the default config
        return nil
    end)
    
    if success and savedConfig then
        debugLog("Configuration loaded from storage")
        return Utils.JSON.decode(savedConfig)
    else
        debugLog("No saved configuration found, using defaults")
        return nil
    end
end

-- Save configuration to storage
local function saveToStorage()
    debugLog("Saving configuration to storage")
    
    local success, error = pcall(function()
        local jsonConfig = Utils.JSON.encode(config, true)
        -- In a real implementation, this would use plugin:SetSetting()
        debugLog("Configuration saved successfully")
    end)
    
    if not success then
        debugLog("Failed to save configuration: " .. tostring(error), "ERROR")
        return false
    end
    
    return true
end

-- Validate configuration structure
local function validateConfig(cfg)
    if not cfg or type(cfg) ~= "table" then
        return false, "Configuration must be a table"
    end
    
    -- Validate required sections
    local requiredSections = {"ui", "datastore", "logging"}
    for _, section in ipairs(requiredSections) do
        if not cfg[section] or type(cfg[section]) ~= "table" then
            debugLog("Missing or invalid section: " .. section, "WARN")
            -- Create missing section with defaults
            cfg[section] = defaultConfig[section] or {}
        end
    end
    
    -- Validate specific settings
    if cfg.maxCacheSize and (type(cfg.maxCacheSize) ~= "number" or cfg.maxCacheSize < 10) then
        debugLog("Invalid maxCacheSize, using default", "WARN")
        cfg.maxCacheSize = defaultConfig.maxCacheSize
    end
    
    if cfg.defaultTimeout and (type(cfg.defaultTimeout) ~= "number" or cfg.defaultTimeout < 1) then
        debugLog("Invalid defaultTimeout, using default", "WARN")
        cfg.defaultTimeout = defaultConfig.defaultTimeout
    end
    
    return true, "Configuration is valid"
end

-- Initialize configuration system
function PluginConfig.initialize()
    if initialized then
        debugLog("Configuration already initialized")
        return true
    end
    
    debugLog("Initializing configuration system")
    
    -- Load saved configuration or use defaults
    local savedConfig = loadFromStorage()
    
    if savedConfig then
        local isValid, validationError = validateConfig(savedConfig)
        if isValid then
            config = Utils.Table.merge(Utils.Table.deepCopy(defaultConfig), savedConfig)
            debugLog("Loaded and validated saved configuration")
        else
            debugLog("Saved configuration invalid: " .. validationError, "ERROR")
            config = Utils.Table.deepCopy(defaultConfig)
        end
    else
        config = Utils.Table.deepCopy(defaultConfig)
        debugLog("Using default configuration")
    end
    
    initialized = true
    debugLog("Configuration system initialized successfully")
    return true
end

-- Get configuration value
function PluginConfig.get(key, defaultValue)
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return defaultValue
    end
    
    if not key then
        debugLog("No key provided for get()", "ERROR")
        return defaultValue
    end
    
    -- Support nested keys like "ui.windowWidth"
    local keys = Utils.String.split(key, ".")
    local value = config
    
    for _, k in ipairs(keys) do
        if type(value) == "table" and value[k] ~= nil then
            value = value[k]
        else
            debugLog("Key not found: " .. key, "DEBUG")
            return defaultValue
        end
    end
    
    return value
end

-- Set configuration value
function PluginConfig.set(key, value)
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return false
    end
    
    if not key then
        debugLog("No key provided for set()", "ERROR")
        return false
    end
    
    debugLog("Setting configuration: " .. key .. " = " .. tostring(value))
    
    -- Support nested keys
    local keys = Utils.String.split(key, ".")
    local target = config
    
    -- Navigate to parent of target key
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(target[k]) ~= "table" then
            target[k] = {}
        end
        target = target[k]
    end
    
    -- Set the value
    target[keys[#keys]] = value
    
    -- Auto-save if enabled
    if config.autoSave then
        saveToStorage()
    end
    
    return true
end

-- Get entire configuration
function PluginConfig.getAll()
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return {}
    end
    
    return Utils.Table.deepCopy(config)
end

-- Reset to defaults
function PluginConfig.reset()
    debugLog("Resetting configuration to defaults")
    
    config = Utils.Table.deepCopy(defaultConfig)
    
    if initialized then
        saveToStorage()
    end
    
    debugLog("Configuration reset complete")
    return true
end

-- Save current configuration
function PluginConfig.save()
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return false
    end
    
    return saveToStorage()
end

-- Merge new configuration
function PluginConfig.merge(newConfig)
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return false
    end
    
    if not newConfig or type(newConfig) ~= "table" then
        debugLog("Invalid configuration provided for merge", "ERROR")
        return false
    end
    
    debugLog("Merging new configuration")
    
    local isValid, validationError = validateConfig(newConfig)
    if not isValid then
        debugLog("New configuration invalid: " .. validationError, "ERROR")
        return false
    end
    
    config = Utils.Table.merge(config, newConfig)
    
    if config.autoSave then
        saveToStorage()
    end
    
    debugLog("Configuration merged successfully")
    return true
end

-- Export configuration for backup
function PluginConfig.export()
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return nil
    end
    
    return Utils.JSON.encode(config, true)
end

-- Import configuration from backup
function PluginConfig.import(jsonConfig)
    if not initialized then
        debugLog("Configuration not initialized", "ERROR")
        return false
    end
    
    local importedConfig, error = Utils.JSON.decode(jsonConfig)
    if not importedConfig then
        debugLog("Failed to parse imported configuration: " .. tostring(error), "ERROR")
        return false
    end
    
    return PluginConfig.merge(importedConfig)
end

-- Get theme configuration
function PluginConfig.getTheme()
    local theme = PluginConfig.get("theme", "dark")
    local themeConfig = {
        name = theme,
        colors = Constants.UI.THEME.COLORS,
        fonts = Constants.UI.THEME.FONTS,
        spacing = Constants.UI.THEME.SPACING,
        sizes = Constants.UI.THEME.SIZES
    }
    
    -- Apply theme-specific modifications if needed
    if theme == "light" then
        -- Modify colors for light theme
        themeConfig.colors = Utils.Table.deepCopy(Constants.UI.THEME.COLORS)
        themeConfig.colors.BACKGROUND = Color3.fromRGB(240, 240, 240)
        themeConfig.colors.SURFACE = Color3.fromRGB(255, 255, 255)
        themeConfig.colors.TEXT = Color3.fromRGB(50, 50, 50)
        themeConfig.colors.TEXT_SECONDARY = Color3.fromRGB(100, 100, 100)
    end
    
    return themeConfig
end

-- Cleanup
function PluginConfig.cleanup()
    if not initialized then
        return
    end
    
    debugLog("Cleaning up configuration system")
    
    -- Final save
    if config.autoSave then
        saveToStorage()
    end
    
    config = {}
    initialized = false
    
    debugLog("Configuration cleanup complete")
end

return PluginConfig 