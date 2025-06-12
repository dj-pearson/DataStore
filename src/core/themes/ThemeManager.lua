-- DataStore Manager Pro - Theme Manager
-- Handles theme switching, custom theme creation, and visual customization

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local ThemeManager = {}

-- Built-in theme definitions
local BUILT_IN_THEMES = {
    dark_professional = {
        id = "dark_professional",
        name = "Dark Professional",
        description = "The default professional dark theme optimized for extended use",
        isBuiltIn = true,
        colors = {
            -- Primary colors
            primary = "#3B82F6",
            primaryHover = "#2563EB",
            primaryActive = "#1D4ED8",
            secondary = "#10B981",
            accent = "#8B5CF6",
            
            -- Background colors
            backgroundPrimary = "#1F2937",
            backgroundSecondary = "#374151",
            backgroundTertiary = "#4B5563",
            
            -- Text colors
            textPrimary = "#F9FAFB",
            textSecondary = "#D1D5DB",
            textOnPrimary = "#FFFFFF",
            
            -- Border colors
            borderPrimary = "#6B7280",
            borderSecondary = "#9CA3AF",
            
            -- Status colors
            success = "#10B981",
            warning = "#F59E0B",
            error = "#EF4444",
            info = "#3B82F6",
            
            -- Interactive colors
            sidebarItemHover = "#4B5563",
            buttonHover = "#374151"
        },
        fonts = {
            heading = "Roboto",
            body = "Roboto",
            ui = "Roboto",
            code = "RobotoMono"
        },
        layout = {
            sidebarWidth = 250,
            contentSpacing = "comfortable",
            borderRadius = 6,
            animations = true
        }
    },
    
    light_clean = {
        id = "light_clean",
        name = "Light Clean", 
        description = "Clean and bright light theme for daytime use",
        isBuiltIn = true,
        colors = {
            -- Primary colors
            primary = "#2563EB",
            primaryHover = "#1D4ED8",
            primaryActive = "#1E40AF",
            secondary = "#059669",
            accent = "#7C3AED",
            
            -- Background colors
            backgroundPrimary = "#FFFFFF",
            backgroundSecondary = "#F3F4F6",
            backgroundTertiary = "#E5E7EB",
            
            -- Text colors
            textPrimary = "#111827",
            textSecondary = "#6B7280",
            textOnPrimary = "#FFFFFF",
            
            -- Border colors
            borderPrimary = "#D1D5DB",
            borderSecondary = "#9CA3AF",
            
            -- Status colors
            success = "#059669",
            warning = "#D97706",
            error = "#DC2626",
            info = "#2563EB",
            
            -- Interactive colors
            sidebarItemHover = "#E5E7EB",
            buttonHover = "#F3F4F6"
        },
        fonts = {
            heading = "Roboto",
            body = "Roboto", 
            ui = "Roboto",
            code = "RobotoMono"
        },
        layout = {
            sidebarWidth = 250,
            contentSpacing = "comfortable",
            borderRadius = 6,
            animations = true
        }
    },
    
    high_contrast = {
        id = "high_contrast",
        name = "High Contrast",
        description = "High contrast theme for accessibility and low vision users",
        isBuiltIn = true,
        colors = {
            -- Primary colors
            primary = "#0066FF",
            primaryHover = "#0052CC",
            primaryActive = "#003D99",
            secondary = "#00CC66",
            accent = "#CC00FF",
            
            -- Background colors
            backgroundPrimary = "#000000",
            backgroundSecondary = "#1A1A1A",
            backgroundTertiary = "#333333",
            
            -- Text colors
            textPrimary = "#FFFFFF",
            textSecondary = "#CCCCCC",
            textOnPrimary = "#FFFFFF",
            
            -- Border colors
            borderPrimary = "#FFFFFF",
            borderSecondary = "#CCCCCC",
            
            -- Status colors
            success = "#00FF00",
            warning = "#FFAA00",
            error = "#FF0000",
            info = "#00AAFF",
            
            -- Interactive colors
            sidebarItemHover = "#444444",
            buttonHover = "#2A2A2A"
        },
        fonts = {
            heading = "Roboto",
            body = "Roboto",
            ui = "Roboto", 
            code = "RobotoMono"
        },
        layout = {
            sidebarWidth = 250,
            contentSpacing = "spacious",
            borderRadius = 2,
            animations = false
        }
    }
}

function ThemeManager.new(settingsManager)
    local self = setmetatable({}, {__index = ThemeManager})
    
    self.settingsManager = settingsManager
    self.currentTheme = nil
    self.customThemes = {}
    self.themeChangeCallbacks = {}
    
    -- Load current theme
    self:loadCurrentTheme()
    
    debugLog("Theme Manager initialized with theme: " .. (self.currentTheme and self.currentTheme.id or "none"), "INFO")
    return self
end

-- Load current theme from settings
function ThemeManager:loadCurrentTheme()
    if not self.settingsManager then
        debugLog("No settings manager available for theme loading", "WARN")
        self:setTheme("dark_professional")
        return
    end
    
    local selectedThemeId = self.settingsManager:getSetting("theme.selectedTheme")
    if selectedThemeId then
        self:setTheme(selectedThemeId)
    else
        self:setTheme("dark_professional")
    end
end

-- Set active theme
function ThemeManager:setTheme(themeId)
    local theme = self:getTheme(themeId)
    if not theme then
        debugLog("Theme not found: " .. tostring(themeId), "ERROR")
        return false
    end
    
    local previousTheme = self.currentTheme
    self.currentTheme = theme
    
    -- Save to settings
    if self.settingsManager then
        self.settingsManager:setSetting("theme.selectedTheme", themeId)
    end
    
    -- Apply theme to Constants for immediate effect
    self:applyThemeToConstants(theme)
    
    -- Notify listeners
    self:notifyThemeChanged(previousTheme, theme)
    
    debugLog("Theme changed to: " .. theme.name, "INFO")
    return true
end

-- Apply theme to Constants module for immediate UI updates
function ThemeManager:applyThemeToConstants(theme)
    if not Constants.UI or not Constants.UI.THEME then return end
    
    -- Update colors
    if theme.colors then
        for colorKey, colorValue in pairs(theme.colors) do
            local constantKey = colorKey:gsub("(%l)(%u)", "%1_%2"):upper()
            if Constants.UI.THEME.COLORS[constantKey] then
                Constants.UI.THEME.COLORS[constantKey] = Color3.fromHex(colorValue)
            end
        end
    end
    
    -- Update fonts
    if theme.fonts then
        if theme.fonts.heading then Constants.UI.THEME.FONTS.HEADING = Enum.Font[theme.fonts.heading] or Enum.Font.Roboto end
        if theme.fonts.body then Constants.UI.THEME.FONTS.BODY = Enum.Font[theme.fonts.body] or Enum.Font.Roboto end
        if theme.fonts.ui then Constants.UI.THEME.FONTS.UI = Enum.Font[theme.fonts.ui] or Enum.Font.Roboto end
    end
    
    -- Update layout values
    if theme.layout then
        if theme.layout.sidebarWidth then Constants.UI.THEME.SIDEBAR_WIDTH = theme.layout.sidebarWidth end
        if theme.layout.borderRadius then Constants.UI.THEME.CORNER_RADIUS = theme.layout.borderRadius end
    end
end

-- Get theme by ID (built-in or custom)
function ThemeManager:getTheme(themeId)
    -- Check built-in themes first
    if BUILT_IN_THEMES[themeId] then
        return BUILT_IN_THEMES[themeId]
    end
    
    -- Check custom themes
    if self.customThemes[themeId] then
        return self.customThemes[themeId]
    end
    
    return nil
end

-- Get all available themes
function ThemeManager:getAllThemes()
    local themes = {}
    
    -- Add built-in themes
    for _, theme in pairs(BUILT_IN_THEMES) do
        table.insert(themes, theme)
    end
    
    -- Add custom themes
    for _, theme in pairs(self.customThemes) do
        table.insert(themes, theme)
    end
    
    return themes
end

-- Create custom theme
function ThemeManager:createCustomTheme(themeData)
    -- Validate theme data
    if not themeData.id or not themeData.name then
        debugLog("Invalid theme data: missing id or name", "ERROR")
        return false
    end
    
    -- Ensure it doesn't conflict with built-in themes
    if BUILT_IN_THEMES[themeData.id] then
        debugLog("Cannot override built-in theme: " .. themeData.id, "ERROR")
        return false
    end
    
    -- Set defaults for missing fields
    local theme = Utils.deepCopy(BUILT_IN_THEMES.dark_professional)
    theme.id = themeData.id
    theme.name = themeData.name
    theme.description = themeData.description or "Custom theme"
    theme.isBuiltIn = false
    
    -- Apply custom values
    if themeData.colors then
        theme.colors = Utils.deepCopy(theme.colors)
        for key, value in pairs(themeData.colors) do
            theme.colors[key] = value
        end
    end
    
    if themeData.fonts then
        theme.fonts = Utils.deepCopy(theme.fonts)
        for key, value in pairs(themeData.fonts) do
            theme.fonts[key] = value
        end
    end
    
    if themeData.layout then
        theme.layout = Utils.deepCopy(theme.layout)
        for key, value in pairs(themeData.layout) do
            theme.layout[key] = value
        end
    end
    
    -- Store custom theme
    self.customThemes[themeData.id] = theme
    
    -- Save to settings
    if self.settingsManager then
        local customThemes = self.settingsManager:getSetting("customThemes") or {}
        customThemes[themeData.id] = theme
        self.settingsManager:setSetting("customThemes", customThemes)
    end
    
    debugLog("Custom theme created: " .. theme.name, "INFO")
    return true
end

-- Delete custom theme
function ThemeManager:deleteCustomTheme(themeId)
    if BUILT_IN_THEMES[themeId] then
        debugLog("Cannot delete built-in theme: " .. themeId, "ERROR")
        return false
    end
    
    if not self.customThemes[themeId] then
        debugLog("Custom theme not found: " .. themeId, "ERROR")
        return false
    end
    
    -- Remove from memory
    self.customThemes[themeId] = nil
    
    -- Remove from settings
    if self.settingsManager then
        local customThemes = self.settingsManager:getSetting("customThemes") or {}
        customThemes[themeId] = nil
        self.settingsManager:setSetting("customThemes", customThemes)
    end
    
    -- Switch to default theme if this was the active theme
    if self.currentTheme and self.currentTheme.id == themeId then
        self:setTheme("dark_professional")
    end
    
    debugLog("Custom theme deleted: " .. themeId, "INFO")
    return true
end

-- Export theme to JSON
function ThemeManager:exportTheme(themeId)
    local theme = self:getTheme(themeId)
    if not theme then
        debugLog("Theme not found for export: " .. themeId, "ERROR")
        return nil
    end
    
    local exportData = {
        version = "1.0.0",
        exportDate = os.date("%Y-%m-%d %H:%M:%S"),
        theme = theme
    }
    
    return HttpService:JSONEncode(exportData)
end

-- Import theme from JSON
function ThemeManager:importTheme(themeData)
    local success, parsedData = pcall(function()
        return HttpService:JSONDecode(themeData)
    end)
    
    if not success or not parsedData.theme then
        debugLog("Invalid theme import data", "ERROR")
        return false
    end
    
    return self:createCustomTheme(parsedData.theme)
end

-- Get theme preview data
function ThemeManager:getThemePreview(themeId)
    local theme = self:getTheme(themeId)
    if not theme then return nil end
    
    return {
        id = theme.id,
        name = theme.name,
        description = theme.description,
        isBuiltIn = theme.isBuiltIn,
        primaryColor = theme.colors.primary,
        backgroundColor = theme.colors.backgroundPrimary,
        textColor = theme.colors.textPrimary
    }
end

-- Register callback for theme changes
function ThemeManager:onThemeChanged(callback)
    table.insert(self.themeChangeCallbacks, callback)
end

-- Notify listeners of theme changes
function ThemeManager:notifyThemeChanged(oldTheme, newTheme)
    for _, callback in ipairs(self.themeChangeCallbacks) do
        pcall(function()
            callback(oldTheme, newTheme)
        end)
    end
end

-- Get current theme
function ThemeManager:getCurrentTheme()
    return self.currentTheme
end

-- Get theme customization options
function ThemeManager:getCustomizationOptions()
    return {
        colors = {
            "primary", "secondary", "accent",
            "backgroundPrimary", "backgroundSecondary", "backgroundTertiary",
            "textPrimary", "textSecondary",
            "success", "warning", "error", "info"
        },
        fonts = {
            "heading", "body", "ui", "code"
        },
        layout = {
            "sidebarWidth", "contentSpacing", "borderRadius", "animations"
        }
    }
end

-- Validate theme data
function ThemeManager:validateThemeData(themeData)
    if not themeData.id or type(themeData.id) ~= "string" then
        return false, "Invalid or missing theme ID"
    end
    
    if not themeData.name or type(themeData.name) ~= "string" then
        return false, "Invalid or missing theme name"
    end
    
    if themeData.colors then
        for colorKey, colorValue in pairs(themeData.colors) do
            if type(colorValue) ~= "string" or not colorValue:match("^#%x%x%x%x%x%x$") then
                return false, "Invalid color value for " .. colorKey
            end
        end
    end
    
    return true, "Valid"
end

-- Reset theme to default
function ThemeManager:resetToDefault()
    self:setTheme("dark_professional")
end

-- Cleanup function
function ThemeManager:cleanup()
    self.themeChangeCallbacks = {}
    debugLog("Theme Manager cleanup complete", "INFO")
end

return ThemeManager 