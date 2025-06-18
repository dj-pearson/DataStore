-- DataStore Manager Pro - User Preferences Manager
-- Handles user customization preferences for modern UI features

local UserPreferencesManager = {}
UserPreferencesManager.__index = UserPreferencesManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)
local ThemeManager = require(script.Parent.ThemeManager)
local LayoutManager = require(script.Parent.LayoutManager)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[USER_PREFERENCES] [%s] %s", level, message))
end

-- Default preferences configuration
local DEFAULT_PREFERENCES = {
    theme = {
        name = "DARK_PROFESSIONAL",
        customColors = {},
        animationsEnabled = true,
        effectsEnabled = true,
        reducedMotion = false
    },
    layout = {
        breakpoint = "auto", -- auto, mobile, tablet, desktop, large
        scaleFactor = 1.0,
        compactMode = false,
        sidebarCollapsed = false
    },
    accessibility = {
        enabled = false,
        highContrast = false,
        largeText = false,
        focusIndicators = true,
        screenReaderMode = false,
        keyboardNavigation = true
    },
    notifications = {
        enabled = true,
        position = "top-right", -- top-right, top-left, bottom-right, bottom-left
        duration = 5,
        soundEnabled = false,
        animations = true
    },
    performance = {
        maxAnimations = 10,
        lowPowerMode = false,
        preloadAssets = true,
        cacheSize = 100
    },
    ui = {
        showTooltips = true,
        autoSave = true,
        confirmDialogs = true,
        modernEffects = true,
        glassmorphism = true
    }
}

-- Preferences state
local preferencesState = {
    current = {},
    loaded = false,
    changed = false,
    autoSaveEnabled = true,
    changeCallbacks = {}
}

-- Initialize User Preferences Manager
function UserPreferencesManager.initialize()
    debugLog("Initializing User Preferences Manager")
    
    -- Load user preferences
    UserPreferencesManager.loadPreferences()
    
    -- Apply loaded preferences
    UserPreferencesManager.applyAllPreferences()
    
    -- Start auto-save if enabled
    if preferencesState.current.ui.autoSave then
        UserPreferencesManager.startAutoSave()
    end
    
    debugLog("User Preferences Manager initialized")
    return true
end

-- Load user preferences
function UserPreferencesManager.loadPreferences()
    -- In production, would load from DataStore or plugin settings
    -- For now, use defaults and detect some system preferences
    preferencesState.current = Utils.deepCopy(DEFAULT_PREFERENCES)
    
    -- Auto-detect theme based on Studio theme
    local studioSettings = settings().Studio
    if studioSettings and studioSettings.Theme then
        local studioTheme = studioSettings.Theme.Name
        if studioTheme == "Dark" then
            preferencesState.current.theme.name = "DARK_PROFESSIONAL"
        else
            preferencesState.current.theme.name = "LIGHT_PROFESSIONAL"
        end
    end
    
    -- Auto-detect accessibility needs
    -- In production, would check system accessibility settings
    
    preferencesState.loaded = true
    debugLog("Preferences loaded with theme: " .. preferencesState.current.theme.name)
end

-- Save user preferences
function UserPreferencesManager.savePreferences()
    if not preferencesState.loaded then return false end
    
    -- In production, would save to DataStore or plugin settings
    debugLog("Preferences saved")
    preferencesState.changed = false
    
    -- Trigger save callbacks
    UserPreferencesManager.triggerCallbacks("save", preferencesState.current)
    return true
end

-- Apply all preferences
function UserPreferencesManager.applyAllPreferences()
    if not preferencesState.loaded then return end
    
    UserPreferencesManager.applyThemePreferences()
    UserPreferencesManager.applyLayoutPreferences()
    UserPreferencesManager.applyAccessibilityPreferences()
    UserPreferencesManager.applyUIPreferences()
    
    debugLog("All preferences applied")
end

-- Apply theme preferences
function UserPreferencesManager.applyThemePreferences()
    local themePrefs = preferencesState.current.theme
    
    -- Switch theme
    ThemeManager.switchTheme(themePrefs.name)
    
    -- Configure animations
    if not themePrefs.animationsEnabled or themePrefs.reducedMotion then
        ThemeManager.toggleAnimations()
    end
    
    debugLog("Theme preferences applied: " .. themePrefs.name)
end

-- Apply layout preferences
function UserPreferencesManager.applyLayoutPreferences()
    local layoutPrefs = preferencesState.current.layout
    
    -- Apply scale factor if not auto
    if layoutPrefs.scaleFactor ~= 1.0 then
        -- In production, would apply custom scaling
        debugLog("Custom scale factor applied: " .. layoutPrefs.scaleFactor)
    end
    
    -- Apply compact mode
    if layoutPrefs.compactMode then
        -- In production, would enable compact layouts
        debugLog("Compact mode enabled")
    end
    
    debugLog("Layout preferences applied")
end

-- Apply accessibility preferences
function UserPreferencesManager.applyAccessibilityPreferences()
    local accessibilityPrefs = preferencesState.current.accessibility
    
    if accessibilityPrefs.enabled then
        LayoutManager.enableAccessibilityMode()
        
        -- Apply high contrast if enabled
        if accessibilityPrefs.highContrast then
            -- In production, would apply high contrast theme
            debugLog("High contrast mode enabled")
        end
        
        -- Apply large text if enabled
        if accessibilityPrefs.largeText then
            -- In production, would increase text sizes
            debugLog("Large text mode enabled")
        end
        
        debugLog("Accessibility preferences applied")
    end
end

-- Apply UI preferences
function UserPreferencesManager.applyUIPreferences()
    local uiPrefs = preferencesState.current.ui
    
    -- Configure modern effects
    if not uiPrefs.modernEffects then
        -- In production, would disable effects
        debugLog("Modern effects disabled")
    end
    
    if not uiPrefs.glassmorphism then
        -- In production, would disable glassmorphism
        debugLog("Glassmorphism disabled")
    end
    
    debugLog("UI preferences applied")
end

-- Get preference value
function UserPreferencesManager.getPreference(category, key)
    if not preferencesState.loaded then return nil end
    
    local categoryPrefs = preferencesState.current[category]
    if not categoryPrefs then return nil end
    
    return categoryPrefs[key]
end

-- Set preference value
function UserPreferencesManager.setPreference(category, key, value)
    if not preferencesState.loaded then return false end
    
    local categoryPrefs = preferencesState.current[category]
    if not categoryPrefs then return false end
    
    local oldValue = categoryPrefs[key]
    categoryPrefs[key] = value
    preferencesState.changed = true
    
    -- Apply the specific preference change
    UserPreferencesManager.applyPreferenceChange(category, key, value, oldValue)
    
    -- Trigger change callbacks
    UserPreferencesManager.triggerCallbacks("change", {
        category = category,
        key = key,
        value = value,
        oldValue = oldValue
    })
    
    debugLog(string.format("Preference changed: %s.%s = %s", category, key, tostring(value)))
    return true
end

-- Apply specific preference change
function UserPreferencesManager.applyPreferenceChange(category, key, value, oldValue)
    if category == "theme" then
        if key == "name" then
            ThemeManager.switchTheme(value)
        elseif key == "animationsEnabled" then
            if value ~= ThemeManager.areAnimationsEnabled() then
                ThemeManager.toggleAnimations()
            end
        end
    elseif category == "accessibility" then
        if key == "enabled" and value and not oldValue then
            LayoutManager.enableAccessibilityMode()
        end
    elseif category == "layout" then
        if key == "scaleFactor" then
            -- In production, would update scale factor
            debugLog("Scale factor updated to: " .. value)
        end
    end
end

-- Get all preferences
function UserPreferencesManager.getAllPreferences()
    return Utils.deepCopy(preferencesState.current)
end

-- Set multiple preferences
function UserPreferencesManager.setPreferences(preferences)
    if not preferencesState.loaded then return false end
    
    local changed = false
    
    for category, categoryPrefs in pairs(preferences) do
        if preferencesState.current[category] then
            for key, value in pairs(categoryPrefs) do
                if preferencesState.current[category][key] ~= value then
                    preferencesState.current[category][key] = value
                    changed = true
                end
            end
        end
    end
    
    if changed then
        preferencesState.changed = true
        UserPreferencesManager.applyAllPreferences()
        
        -- Trigger change callbacks
        UserPreferencesManager.triggerCallbacks("bulk_change", preferences)
        debugLog("Bulk preferences updated")
    end
    
    return changed
end

-- Reset preferences to defaults
function UserPreferencesManager.resetToDefaults()
    preferencesState.current = Utils.deepCopy(DEFAULT_PREFERENCES)
    preferencesState.changed = true
    
    UserPreferencesManager.applyAllPreferences()
    
    -- Trigger reset callbacks
    UserPreferencesManager.triggerCallbacks("reset", preferencesState.current)
    debugLog("Preferences reset to defaults")
end

-- Export preferences
function UserPreferencesManager.exportPreferences()
    if not preferencesState.loaded then return nil end
    
    local exportData = {
        version = "1.0",
        timestamp = os.time(),
        preferences = Utils.deepCopy(preferencesState.current)
    }
    
    -- In production, would return JSON string
    debugLog("Preferences exported")
    return exportData
end

-- Import preferences
function UserPreferencesManager.importPreferences(importData)
    if not importData or not importData.preferences then return false end
    
    -- Validate import data
    if not UserPreferencesManager.validatePreferences(importData.preferences) then
        debugLog("Invalid preferences data", "ERROR")
        return false
    end
    
    preferencesState.current = Utils.deepCopy(importData.preferences)
    preferencesState.changed = true
    
    UserPreferencesManager.applyAllPreferences()
    
    -- Trigger import callbacks
    UserPreferencesManager.triggerCallbacks("import", importData.preferences)
    debugLog("Preferences imported successfully")
    return true
end

-- Validate preferences data
function UserPreferencesManager.validatePreferences(preferences)
    -- Check if all required categories exist
    for category, _ in pairs(DEFAULT_PREFERENCES) do
        if not preferences[category] then
            debugLog("Missing category: " .. category, "WARN")
            return false
        end
    end
    
    -- Validate specific values
    local themePrefs = preferences.theme
    if themePrefs then
        if themePrefs.name ~= "DARK_PROFESSIONAL" and themePrefs.name ~= "LIGHT_PROFESSIONAL" then
            debugLog("Invalid theme name: " .. tostring(themePrefs.name), "WARN")
            return false
        end
    end
    
    return true
end

-- Create preferences UI
function UserPreferencesManager.createPreferencesUI(parent)
    local preferencesContainer = Instance.new("ScrollingFrame")
    preferencesContainer.Name = "PreferencesUI"
    preferencesContainer.Size = UDim2.new(1, 0, 1, 0)
    preferencesContainer.Position = UDim2.new(0, 0, 0, 0)
    preferencesContainer.BackgroundTransparency = 1
    preferencesContainer.ScrollBarThickness = 8
    preferencesContainer.Parent = parent
    
    -- Preferences content
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "PreferencesContent"
    contentContainer.Size = UDim2.new(1, 0, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = preferencesContainer
    
    -- Auto-sizing layout
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.Padding = UDim.new(0, 16)
    mainLayout.Parent = contentContainer
    
    -- Update canvas size
    mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        preferencesContainer.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 32)
    end)
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 16)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.PaddingLeft = UDim.new(0, 16)
    padding.PaddingRight = UDim.new(0, 16)
    padding.Parent = contentContainer
    
    -- Create preference sections
    UserPreferencesManager.createThemeSection(contentContainer)
    UserPreferencesManager.createLayoutSection(contentContainer)
    UserPreferencesManager.createAccessibilitySection(contentContainer)
    UserPreferencesManager.createNotificationSection(contentContainer)
    UserPreferencesManager.createPerformanceSection(contentContainer)
    UserPreferencesManager.createActionButtons(contentContainer)
    
    return preferencesContainer
end

-- Create theme preferences section
function UserPreferencesManager.createThemeSection(parent)
    local themeSection = ThemeManager.createProfessionalCard({
        name = "ThemeSection",
        size = UDim2.new(1, 0, 0, 200),
        background = "secondary",
        cornerRadius = 12
    })
    themeSection.Parent = parent
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "🎨 Theme Preferences"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 18
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = themeSection
    
    -- Theme selector
    local themeToggle, themeEnabled = ThemeManager.createModernToggle({
        name = "ThemeToggle",
        position = UDim2.new(0, 20, 0, 50),
        enabled = preferencesState.current.theme.name == "DARK_PROFESSIONAL",
        onToggle = function(enabled)
            local newTheme = enabled and "DARK_PROFESSIONAL" or "LIGHT_PROFESSIONAL"
            UserPreferencesManager.setPreference("theme", "name", newTheme)
        end
    })
    themeToggle.Parent = themeSection
    
    local themeLabel = Instance.new("TextLabel")
    themeLabel.Name = "ThemeLabel"
    themeLabel.Size = UDim2.new(0, 200, 0, 28)
    themeLabel.Position = UDim2.new(0, 80, 0, 50)
    themeLabel.Text = "Dark Theme"
    themeLabel.Font = Constants.UI.THEME.FONTS.UI
    themeLabel.TextSize = 14
    themeLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    themeLabel.BackgroundTransparency = 1
    themeLabel.TextXAlignment = Enum.TextXAlignment.Left
    themeLabel.Parent = themeSection
    
    -- Animations toggle
    local animationsToggle, animationsEnabled = ThemeManager.createModernToggle({
        name = "AnimationsToggle",
        position = UDim2.new(0, 20, 0, 90),
        enabled = preferencesState.current.theme.animationsEnabled,
        onToggle = function(enabled)
            UserPreferencesManager.setPreference("theme", "animationsEnabled", enabled)
        end
    })
    animationsToggle.Parent = themeSection
    
    local animationsLabel = Instance.new("TextLabel")
    animationsLabel.Name = "AnimationsLabel"
    animationsLabel.Size = UDim2.new(0, 200, 0, 28)
    animationsLabel.Position = UDim2.new(0, 80, 0, 90)
    animationsLabel.Text = "Enable Animations"
    animationsLabel.Font = Constants.UI.THEME.FONTS.UI
    animationsLabel.TextSize = 14
    animationsLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    animationsLabel.BackgroundTransparency = 1
    animationsLabel.TextXAlignment = Enum.TextXAlignment.Left
    animationsLabel.Parent = themeSection
    
    -- Effects toggle
    local effectsToggle, effectsEnabled = ThemeManager.createModernToggle({
        name = "EffectsToggle",
        position = UDim2.new(0, 20, 0, 130),
        enabled = preferencesState.current.theme.effectsEnabled,
        onToggle = function(enabled)
            UserPreferencesManager.setPreference("theme", "effectsEnabled", enabled)
        end
    })
    effectsToggle.Parent = themeSection
    
    local effectsLabel = Instance.new("TextLabel")
    effectsLabel.Name = "EffectsLabel"
    effectsLabel.Size = UDim2.new(0, 200, 0, 28)
    effectsLabel.Position = UDim2.new(0, 80, 0, 130)
    effectsLabel.Text = "Enable Visual Effects"
    effectsLabel.Font = Constants.UI.THEME.FONTS.UI
    effectsLabel.TextSize = 14
    effectsLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    effectsLabel.BackgroundTransparency = 1
    effectsLabel.TextXAlignment = Enum.TextXAlignment.Left
    effectsLabel.Parent = themeSection
end

-- Create layout preferences section
function UserPreferencesManager.createLayoutSection(parent)
    local layoutSection = ThemeManager.createProfessionalCard({
        name = "LayoutSection",
        size = UDim2.new(1, 0, 0, 160),
        background = "secondary",
        cornerRadius = 12
    })
    layoutSection.Parent = parent
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "📱 Layout Preferences"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 18
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = layoutSection
    
    -- Compact mode toggle
    local compactToggle, compactEnabled = ThemeManager.createModernToggle({
        name = "CompactToggle",
        position = UDim2.new(0, 20, 0, 50),
        enabled = preferencesState.current.layout.compactMode,
        onToggle = function(enabled)
            UserPreferencesManager.setPreference("layout", "compactMode", enabled)
        end
    })
    compactToggle.Parent = layoutSection
    
    local compactLabel = Instance.new("TextLabel")
    compactLabel.Name = "CompactLabel"
    compactLabel.Size = UDim2.new(0, 200, 0, 28)
    compactLabel.Position = UDim2.new(0, 80, 0, 50)
    compactLabel.Text = "Compact Mode"
    compactLabel.Font = Constants.UI.THEME.FONTS.UI
    compactLabel.TextSize = 14
    compactLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    compactLabel.BackgroundTransparency = 1
    compactLabel.TextXAlignment = Enum.TextXAlignment.Left
    compactLabel.Parent = layoutSection
    
    -- Scale factor display
    local scaleLabel = Instance.new("TextLabel")
    scaleLabel.Name = "ScaleLabel"
    scaleLabel.Size = UDim2.new(1, -20, 0, 20)
    scaleLabel.Position = UDim2.new(0, 10, 0, 90)
    scaleLabel.Text = "UI Scale: " .. string.format("%.1f", preferencesState.current.layout.scaleFactor) .. "x"
    scaleLabel.Font = Constants.UI.THEME.FONTS.UI
    scaleLabel.TextSize = 14
    scaleLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    scaleLabel.BackgroundTransparency = 1
    scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
    scaleLabel.Parent = layoutSection
    
    -- Scale progress bar
    local scaleProgress, updateScale = ThemeManager.createModernProgressBar({
        name = "ScaleProgress",
        size = UDim2.new(0.8, 0, 0, 6),
        position = UDim2.new(0, 20, 0, 120),
        progress = (preferencesState.current.layout.scaleFactor - 0.5) / 1.5, -- 0.5 to 2.0 range
        gradient = true
    })
    scaleProgress.Parent = layoutSection
end

-- Create accessibility preferences section
function UserPreferencesManager.createAccessibilitySection(parent)
    local accessibilitySection = ThemeManager.createProfessionalCard({
        name = "AccessibilitySection",
        size = UDim2.new(1, 0, 0, 200),
        background = "secondary",
        cornerRadius = 12
    })
    accessibilitySection.Parent = parent
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "♿ Accessibility Preferences"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 18
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = accessibilitySection
    
    -- Accessibility toggles
    local accessibilityToggles = {
        {name = "Enable Accessibility", key = "enabled", position = 50},
        {name = "High Contrast", key = "highContrast", position = 90},
        {name = "Large Text", key = "largeText", position = 130}
    }
    
    for _, toggleData in ipairs(accessibilityToggles) do
        local toggle, enabled = ThemeManager.createModernToggle({
            name = toggleData.key .. "Toggle",
            position = UDim2.new(0, 20, 0, toggleData.position),
            enabled = preferencesState.current.accessibility[toggleData.key],
            onToggle = function(enabled)
                UserPreferencesManager.setPreference("accessibility", toggleData.key, enabled)
            end
        })
        toggle.Parent = accessibilitySection
        
        local label = Instance.new("TextLabel")
        label.Name = toggleData.key .. "Label"
        label.Size = UDim2.new(0, 200, 0, 28)
        label.Position = UDim2.new(0, 80, 0, toggleData.position)
        label.Text = toggleData.name
        label.Font = Constants.UI.THEME.FONTS.UI
        label.TextSize = 14
        label.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = accessibilitySection
    end
end

-- Create notification preferences section
function UserPreferencesManager.createNotificationSection(parent)
    local notificationSection = ThemeManager.createProfessionalCard({
        name = "NotificationSection",
        size = UDim2.new(1, 0, 0, 120),
        background = "secondary",
        cornerRadius = 12
    })
    notificationSection.Parent = parent
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "🔔 Notification Preferences"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 18
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notificationSection
    
    -- Notifications enabled toggle
    local notificationsToggle, notificationsEnabled = ThemeManager.createModernToggle({
        name = "NotificationsToggle",
        position = UDim2.new(0, 20, 0, 50),
        enabled = preferencesState.current.notifications.enabled,
        onToggle = function(enabled)
            UserPreferencesManager.setPreference("notifications", "enabled", enabled)
        end
    })
    notificationsToggle.Parent = notificationSection
    
    local notificationsLabel = Instance.new("TextLabel")
    notificationsLabel.Name = "NotificationsLabel"
    notificationsLabel.Size = UDim2.new(0, 200, 0, 28)
    notificationsLabel.Position = UDim2.new(0, 80, 0, 50)
    notificationsLabel.Text = "Enable Notifications"
    notificationsLabel.Font = Constants.UI.THEME.FONTS.UI
    notificationsLabel.TextSize = 14
    notificationsLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    notificationsLabel.BackgroundTransparency = 1
    notificationsLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationsLabel.Parent = notificationSection
end

-- Create performance preferences section
function UserPreferencesManager.createPerformanceSection(parent)
    local performanceSection = ThemeManager.createProfessionalCard({
        name = "PerformanceSection",
        size = UDim2.new(1, 0, 0, 120),
        background = "secondary",
        cornerRadius = 12
    })
    performanceSection.Parent = parent
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "⚡ Performance Preferences"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 18
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = performanceSection
    
    -- Low power mode toggle
    local lowPowerToggle, lowPowerEnabled = ThemeManager.createModernToggle({
        name = "LowPowerToggle",
        position = UDim2.new(0, 20, 0, 50),
        enabled = preferencesState.current.performance.lowPowerMode,
        onToggle = function(enabled)
            UserPreferencesManager.setPreference("performance", "lowPowerMode", enabled)
        end
    })
    lowPowerToggle.Parent = performanceSection
    
    local lowPowerLabel = Instance.new("TextLabel")
    lowPowerLabel.Name = "LowPowerLabel"
    lowPowerLabel.Size = UDim2.new(0, 200, 0, 28)
    lowPowerLabel.Position = UDim2.new(0, 80, 0, 50)
    lowPowerLabel.Text = "Low Power Mode"
    lowPowerLabel.Font = Constants.UI.THEME.FONTS.UI
    lowPowerLabel.TextSize = 14
    lowPowerLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    lowPowerLabel.BackgroundTransparency = 1
    lowPowerLabel.TextXAlignment = Enum.TextXAlignment.Left
    lowPowerLabel.Parent = performanceSection
end

-- Create action buttons section
function UserPreferencesManager.createActionButtons(parent)
    local actionsSection = Instance.new("Frame")
    actionsSection.Name = "ActionsSection"
    actionsSection.Size = UDim2.new(1, 0, 0, 60)
    actionsSection.BackgroundTransparency = 1
    actionsSection.Parent = parent
    
    -- Save button
    local saveButton = ThemeManager.createProfessionalButton({
        name = "SaveButton",
        text = "💾 Save Preferences",
        size = UDim2.new(0, 160, 0, 36),
        position = UDim2.new(0, 20, 0, 12),
        background = "accent",
        textColor = "primary"
    })
    saveButton.Parent = actionsSection
    
    saveButton.MouseButton1Click:Connect(function()
        UserPreferencesManager.savePreferences()
        ThemeManager.createModernNotification({
            title = "Preferences Saved",
            message = "Your preferences have been saved successfully.",
            icon = "💾",
            type = "success",
            duration = 3
        }).Parent = parent.Parent
    end)
    
    -- Reset button
    local resetButton = ThemeManager.createProfessionalButton({
        name = "ResetButton",
        text = "🔄 Reset to Defaults",
        size = UDim2.new(0, 160, 0, 36),
        position = UDim2.new(0, 200, 0, 12),
        background = "secondary",
        textColor = "primary"
    })
    resetButton.Parent = actionsSection
    
    resetButton.MouseButton1Click:Connect(function()
        UserPreferencesManager.resetToDefaults()
        ThemeManager.createModernNotification({
            title = "Preferences Reset",
            message = "All preferences have been reset to defaults.",
            icon = "🔄",
            type = "info",
            duration = 3
        }).Parent = parent.Parent
    end)
    
    -- Export button
    local exportButton = ThemeManager.createProfessionalButton({
        name = "ExportButton",
        text = "📤 Export",
        size = UDim2.new(0, 100, 0, 36),
        position = UDim2.new(0, 380, 0, 12),
        background = "tertiary",
        textColor = "primary"
    })
    exportButton.Parent = actionsSection
    
    exportButton.MouseButton1Click:Connect(function()
        local exportData = UserPreferencesManager.exportPreferences()
        if exportData then
            ThemeManager.createModernNotification({
                title = "Preferences Exported",
                message = "Preferences exported successfully.",
                icon = "📤",
                type = "success",
                duration = 3
            }).Parent = parent.Parent
        end
    end)
end

-- Register change callback
function UserPreferencesManager.onPreferenceChange(callback)
    table.insert(preferencesState.changeCallbacks, callback)
end

-- Trigger callbacks
function UserPreferencesManager.triggerCallbacks(eventType, data)
    for _, callback in ipairs(preferencesState.changeCallbacks) do
        spawn(function()
            callback(eventType, data)
        end)
    end
end

-- Start auto-save
function UserPreferencesManager.startAutoSave()
    spawn(function()
        while preferencesState.autoSaveEnabled do
            wait(30) -- Auto-save every 30 seconds
            if preferencesState.changed then
                UserPreferencesManager.savePreferences()
            end
        end
    end)
end

-- Check if preferences have changed
function UserPreferencesManager.hasChanges()
    return preferencesState.changed
end

-- Get preferences state
function UserPreferencesManager.getState()
    return {
        loaded = preferencesState.loaded,
        changed = preferencesState.changed,
        autoSaveEnabled = preferencesState.autoSaveEnabled
    }
end

-- Cleanup
function UserPreferencesManager.cleanup()
    if preferencesState.changed then
        UserPreferencesManager.savePreferences()
    end
    
    preferencesState.autoSaveEnabled = false
    preferencesState.changeCallbacks = {}
    debugLog("User Preferences Manager cleanup complete")
end

return UserPreferencesManager 