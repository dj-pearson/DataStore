-- DataStore Manager Pro - Professional Theme Manager
-- Handles dark/light themes, animations, and visual effects for enterprise UI

local ThemeManager = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)
local TweenService = game:GetService("TweenService")

-- Theme state
local themeState = {
    currentTheme = "DARK", -- Default to dark theme
    animationsEnabled = true,
    effectsEnabled = true,
    initialized = false,
    activeAnimations = {} -- Track running animations
}

-- Professional theme configurations
local PROFESSIONAL_THEMES = {
    DARK_PROFESSIONAL = {
        name = "Dark Professional",
        background = {
            primary = Color3.fromRGB(25, 27, 31),
            secondary = Color3.fromRGB(35, 38, 43),
            tertiary = Color3.fromRGB(45, 48, 54),
            elevated = Color3.fromRGB(40, 43, 48)
        },
        text = {
            primary = Color3.fromRGB(255, 255, 255),
            secondary = Color3.fromRGB(200, 203, 209),
            muted = Color3.fromRGB(150, 154, 162),
            accent = Color3.fromRGB(88, 166, 255)
        },
        accent = {
            primary = Color3.fromRGB(88, 166, 255),
            secondary = Color3.fromRGB(255, 138, 101),
            success = Color3.fromRGB(34, 197, 94),
            warning = Color3.fromRGB(251, 146, 60),
            error = Color3.fromRGB(239, 68, 68)
        },
        border = {
            primary = Color3.fromRGB(65, 70, 78),
            secondary = Color3.fromRGB(55, 60, 68),
            accent = Color3.fromRGB(88, 166, 255)
        }
    },
    LIGHT_PROFESSIONAL = {
        name = "Light Professional",
        background = {
            primary = Color3.fromRGB(255, 255, 255),
            secondary = Color3.fromRGB(248, 249, 251),
            tertiary = Color3.fromRGB(241, 243, 246),
            elevated = Color3.fromRGB(255, 255, 255)
        },
        text = {
            primary = Color3.fromRGB(25, 27, 31),
            secondary = Color3.fromRGB(75, 82, 96),
            muted = Color3.fromRGB(125, 133, 147),
            accent = Color3.fromRGB(59, 130, 246)
        },
        accent = {
            primary = Color3.fromRGB(59, 130, 246),
            secondary = Color3.fromRGB(239, 68, 68),
            success = Color3.fromRGB(34, 197, 94),
            warning = Color3.fromRGB(251, 146, 60),
            error = Color3.fromRGB(239, 68, 68)
        },
        border = {
            primary = Color3.fromRGB(229, 231, 235),
            secondary = Color3.fromRGB(209, 213, 219),
            accent = Color3.fromRGB(59, 130, 246)
        }
    }
}

function ThemeManager.initialize()
    print("[THEME_MANAGER] [INFO] Initializing professional theme system...")
    
    -- Load user preferences (would be saved/loaded in production)
    ThemeManager.loadUserPreferences()
    
    -- Initialize animation system
    ThemeManager.initializeAnimations()
    
    themeState.initialized = true
    print("[THEME_MANAGER] [INFO] Theme system initialized with " .. themeState.currentTheme .. " theme")
    
    return true
end

-- Load user theme preferences
function ThemeManager.loadUserPreferences()
    -- In production, this would load from DataStore or plugin settings
    -- For now, detect based on Studio theme
    local studioSettings = settings().Studio
    if studioSettings and studioSettings.Theme then
        local studioTheme = studioSettings.Theme.Name
        if studioTheme == "Dark" then
            themeState.currentTheme = "DARK_PROFESSIONAL"
        else
            themeState.currentTheme = "LIGHT_PROFESSIONAL"
        end
    end
end

-- Initialize animation system
function ThemeManager.initializeAnimations()
    themeState.activeAnimations = {}
    themeState.animationsEnabled = true
    themeState.effectsEnabled = true
end

-- Get current theme
function ThemeManager.getCurrentTheme()
    return PROFESSIONAL_THEMES[themeState.currentTheme]
end

-- Get theme colors for a specific category
function ThemeManager.getThemeColors(category)
    local currentTheme = ThemeManager.getCurrentTheme()
    return currentTheme and currentTheme[category] or {}
end

-- Apply theme to a UI element
function ThemeManager.applyTheme(element, themeConfig)
    if not element or not themeConfig then return end
    
    local theme = ThemeManager.getCurrentTheme()
    if not theme then return end
    
    -- Apply background color
    if themeConfig.background and theme.background[themeConfig.background] then
        element.BackgroundColor3 = theme.background[themeConfig.background]
    end
    
    -- Apply text color
    if themeConfig.textColor and theme.text[themeConfig.textColor] then
        element.TextColor3 = theme.text[themeConfig.textColor]
    end
    
    -- Apply border color
    if themeConfig.borderColor and theme.border[themeConfig.borderColor] then
        element.BorderColor3 = theme.border[themeConfig.borderColor]
    end
end

-- Create professional button with theme and animations
function ThemeManager.createProfessionalButton(config)
    local button = Instance.new("TextButton")
    button.Name = config.name or "ProfessionalButton"
    button.Size = config.size or UDim2.new(0, 120, 0, 36)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.Text = config.text or "Button"
    button.Font = Constants.UI.THEME.FONTS.UI
    button.TextSize = config.textSize or 14
    
    -- Apply theme
    ThemeManager.applyTheme(button, {
        background = config.background or "secondary",
        textColor = config.textColor or "primary",
        borderColor = config.borderColor or "primary"
    })
    
    button.BorderSizePixel = 1
    button.BackgroundTransparency = config.transparency or 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.cornerRadius or 6)
    corner.Parent = button
    
    -- Add professional hover effects
    if themeState.animationsEnabled then
        ThemeManager.addHoverEffects(button, config.hoverEffect or "scale")
    end
    
    return button
end

-- Add hover effects to an element
function ThemeManager.addHoverEffects(element, effectType)
    if not themeState.animationsEnabled then return end
    
    local originalSize = element.Size
    local originalTransparency = element.BackgroundTransparency
    
    element.MouseEnter:Connect(function()
        ThemeManager.animateHover(element, effectType, "enter")
    end)
    
    element.MouseLeave:Connect(function()
        ThemeManager.animateHover(element, effectType, "leave", originalSize, originalTransparency)
    end)
end

-- Animate hover effects
function ThemeManager.animateHover(element, effectType, direction, originalSize, originalTransparency)
    if not themeState.animationsEnabled then return end
    
    local tweenInfo = TweenInfo.new(
        Constants.UI.THEME.ANIMATIONS.DURATIONS.FAST,
        Constants.UI.THEME.ANIMATIONS.EASING_STYLES.EASE_OUT,
        Enum.EasingDirection.Out
    )
    
    local targetProperties = {}
    
    if effectType == "scale" then
        if direction == "enter" then
            targetProperties.Size = UDim2.new(
                originalSize.X.Scale * Constants.UI.THEME.ANIMATIONS.EFFECTS.HOVER_SCALE,
                originalSize.X.Offset * Constants.UI.THEME.ANIMATIONS.EFFECTS.HOVER_SCALE,
                originalSize.Y.Scale * Constants.UI.THEME.ANIMATIONS.EFFECTS.HOVER_SCALE,
                originalSize.Y.Offset * Constants.UI.THEME.ANIMATIONS.EFFECTS.HOVER_SCALE
            )
        else
            targetProperties.Size = originalSize
        end
    elseif effectType == "fade" then
        if direction == "enter" then
            targetProperties.BackgroundTransparency = Constants.UI.THEME.ANIMATIONS.EFFECTS.FADE_TRANSPARENCY
        else
            targetProperties.BackgroundTransparency = originalTransparency or 0
        end
    end
    
    local tween = TweenService:Create(element, tweenInfo, targetProperties)
    
    -- Clean up previous animation
    if themeState.activeAnimations[element] then
        themeState.activeAnimations[element]:Cancel()
    end
    
    themeState.activeAnimations[element] = tween
    tween:Play()
    
    tween.Completed:Connect(function()
        themeState.activeAnimations[element] = nil
    end)
end

-- Create professional card with theme
function ThemeManager.createProfessionalCard(config)
    local card = Instance.new("Frame")
    card.Name = config.name or "ProfessionalCard"
    card.Size = config.size or UDim2.new(1, 0, 0, 120)
    card.Position = config.position or UDim2.new(0, 0, 0, 0)
    
    -- Apply theme
    ThemeManager.applyTheme(card, {
        background = config.background or "secondary",
        borderColor = config.borderColor or "primary"
    })
    
    card.BorderSizePixel = config.borderWidth or 1
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.cornerRadius or 8)
    corner.Parent = card
    
    -- Add shadow effect if enabled
    if themeState.effectsEnabled and config.shadow then
        ThemeManager.addShadowEffect(card, config.shadow)
    end
    
    -- Add gradient if specified
    if config.gradient then
        ThemeManager.addGradientEffect(card, config.gradient)
    end
    
    return card
end

-- Add shadow effect to element
function ThemeManager.addShadowEffect(element, shadowType)
    if not themeState.effectsEnabled then return end
    
    local shadowConfig = Constants.UI.THEME.EFFECTS.SHADOWS[shadowType:upper()]
    if not shadowConfig then return end
    
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = element.Size
    shadow.Position = shadowConfig.offset
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = shadowConfig.transparency
    shadow.BorderSizePixel = 0
    shadow.ZIndex = element.ZIndex - 1
    
    -- Match corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = shadow
    
    shadow.Parent = element.Parent
end

-- Add gradient effect to element
function ThemeManager.addGradientEffect(element, gradientType)
    local gradientConfig = Constants.UI.THEME.EFFECTS.GRADIENTS[gradientType:upper()]
    if not gradientConfig then return end
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = gradientConfig
    gradient.Rotation = 45 -- Professional diagonal gradient
    gradient.Parent = element
end

-- Create professional status indicator
function ThemeManager.createStatusIndicator(status, size)
    local indicator = Instance.new("Frame")
    indicator.Name = "StatusIndicator"
    indicator.Size = UDim2.new(0, size or 8, 0, size or 8)
    indicator.BorderSizePixel = 0
    
    local theme = ThemeManager.getCurrentTheme()
    if status == "online" or status == "success" then
        indicator.BackgroundColor3 = theme.accent.success
    elseif status == "warning" then
        indicator.BackgroundColor3 = theme.accent.warning
    elseif status == "error" or status == "offline" then
        indicator.BackgroundColor3 = theme.accent.error
    else
        indicator.BackgroundColor3 = theme.text.muted
    end
    
    -- Make it circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = indicator
    
    return indicator
end

-- Switch theme
function ThemeManager.switchTheme(themeName)
    if PROFESSIONAL_THEMES[themeName] then
        themeState.currentTheme = themeName
        print("[THEME_MANAGER] [INFO] Switched to " .. themeName .. " theme")
        -- In production, would trigger UI refresh
        return true
    end
    return false
end

-- Toggle between dark and light themes
function ThemeManager.toggleTheme()
    if themeState.currentTheme == "DARK_PROFESSIONAL" then
        return ThemeManager.switchTheme("LIGHT_PROFESSIONAL")
    else
        return ThemeManager.switchTheme("DARK_PROFESSIONAL")
    end
end

-- Professional fade in animation
function ThemeManager.fadeIn(element, duration)
    if not themeState.animationsEnabled then 
        element.BackgroundTransparency = 0
        return 
    end
    
    element.BackgroundTransparency = 1
    
    local tweenInfo = TweenInfo.new(
        duration or Constants.UI.THEME.ANIMATIONS.DURATIONS.NORMAL,
        Constants.UI.THEME.ANIMATIONS.EASING_STYLES.EASE_OUT
    )
    
    local tween = TweenService:Create(element, tweenInfo, {
        BackgroundTransparency = 0
    })
    
    tween:Play()
    return tween
end

-- Professional slide in animation
function ThemeManager.slideIn(element, direction, duration)
    if not themeState.animationsEnabled then return end
    
    local originalPosition = element.Position
    local startPosition
    
    if direction == "left" then
        startPosition = UDim2.new(originalPosition.X.Scale - 1, originalPosition.X.Offset, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "right" then
        startPosition = UDim2.new(originalPosition.X.Scale + 1, originalPosition.X.Offset, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "top" then
        startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, originalPosition.Y.Scale - 1, originalPosition.Y.Offset)
    else -- bottom
        startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, originalPosition.Y.Scale + 1, originalPosition.Y.Offset)
    end
    
    element.Position = startPosition
    
    local tweenInfo = TweenInfo.new(
        duration or Constants.UI.THEME.ANIMATIONS.DURATIONS.NORMAL,
        Constants.UI.THEME.ANIMATIONS.EASING_STYLES.EASE_OUT
    )
    
    local tween = TweenService:Create(element, tweenInfo, {
        Position = originalPosition
    })
    
    tween:Play()
    return tween
end

-- Get current theme name
function ThemeManager.getCurrentThemeName()
    return themeState.currentTheme
end

-- Check if animations are enabled
function ThemeManager.areAnimationsEnabled()
    return themeState.animationsEnabled
end

-- Toggle animations
function ThemeManager.toggleAnimations()
    themeState.animationsEnabled = not themeState.animationsEnabled
    print("[THEME_MANAGER] [INFO] Animations " .. (themeState.animationsEnabled and "enabled" or "disabled"))
end

-- Cleanup function
function ThemeManager.cleanup()
    -- Cancel all active animations
    for element, tween in pairs(themeState.activeAnimations) do
        if tween then
            tween:Cancel()
        end
    end
    
    themeState.activeAnimations = {}
    themeState.initialized = false
    print("[THEME_MANAGER] [INFO] Theme manager cleanup completed")
end

return ThemeManager 