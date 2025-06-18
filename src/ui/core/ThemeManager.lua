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

-- Modern UI Polish Features

-- Create glassmorphism effect
function ThemeManager.createGlassmorphismCard(config)
    local card = Instance.new("Frame")
    card.Name = config.name or "GlassmorphismCard"
    card.Size = config.size or UDim2.new(1, 0, 0, 120)
    card.Position = config.position or UDim2.new(0, 0, 0, 0)
    
    -- Semi-transparent background for glass effect
    local theme = ThemeManager.getCurrentTheme()
    card.BackgroundColor3 = theme.background.secondary
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 1
    card.BorderColor3 = Color3.new(1, 1, 1)
    card.BorderTransparency = 0.8
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.cornerRadius or 12)
    corner.Parent = card
    
    -- Subtle gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 0.9))
    }
    gradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(1, 0.95)
    }
    gradient.Rotation = 45
    gradient.Parent = card
    
    -- Add subtle glow effect
    if themeState.effectsEnabled then
        ThemeManager.addGlowEffect(card, "subtle")
    end
    
    return card
end

-- Add glow effect to element
function ThemeManager.addGlowEffect(element, intensity)
    if not themeState.effectsEnabled then return end
    
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "GlowEffect"
    glowFrame.Size = UDim2.new(1, 20, 1, 20)
    glowFrame.Position = UDim2.new(0, -10, 0, -10)
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = element.ZIndex - 1
    glowFrame.Parent = element.Parent
    
    -- Create multiple glow layers for depth
    local glowLayers = intensity == "strong" and 3 or 2
    
    for i = 1, glowLayers do
        local glowLayer = Instance.new("Frame")
        glowLayer.Name = "GlowLayer" .. i
        glowLayer.Size = UDim2.new(1, i * 4, 1, i * 4)
        glowLayer.Position = UDim2.new(0, -i * 2, 0, -i * 2)
        glowLayer.BackgroundColor3 = ThemeManager.getCurrentTheme().accent.primary
        glowLayer.BackgroundTransparency = 0.7 + (i * 0.1)
        glowLayer.BorderSizePixel = 0
        glowLayer.Parent = glowFrame
        
        -- Match corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12 + i * 2)
        corner.Parent = glowLayer
    end
    
    return glowFrame
end

-- Create modern input field with enhanced UX
function ThemeManager.createModernInput(config)
    local inputContainer = Instance.new("Frame")
    inputContainer.Name = config.name or "ModernInput"
    inputContainer.Size = config.size or UDim2.new(1, 0, 0, 48)
    inputContainer.Position = config.position or UDim2.new(0, 0, 0, 0)
    inputContainer.BackgroundTransparency = 1
    
    -- Input field
    local inputField = Instance.new("TextBox")
    inputField.Name = "InputField"
    inputField.Size = UDim2.new(1, 0, 1, 0)
    inputField.Position = UDim2.new(0, 0, 0, 0)
    inputField.PlaceholderText = config.placeholder or "Enter text..."
    inputField.Text = config.defaultText or ""
    inputField.Font = Constants.UI.THEME.FONTS.UI
    inputField.TextSize = 14
    inputField.TextXAlignment = Enum.TextXAlignment.Left
    inputField.ClearTextOnFocus = false
    inputField.Parent = inputContainer
    
    -- Apply theme
    local theme = ThemeManager.getCurrentTheme()
    inputField.BackgroundColor3 = theme.background.tertiary
    inputField.TextColor3 = theme.text.primary
    inputField.PlaceholderColor3 = theme.text.muted
    inputField.BorderSizePixel = 2
    inputField.BorderColor3 = theme.border.secondary
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inputField
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = inputField
    
    -- Focus animations
    if themeState.animationsEnabled then
        inputField.Focused:Connect(function()
            ThemeManager.animateInputFocus(inputField, true)
        end)
        
        inputField.FocusLost:Connect(function()
            ThemeManager.animateInputFocus(inputField, false)
        end)
    end
    
    -- Floating label if specified
    if config.label then
        ThemeManager.addFloatingLabel(inputContainer, inputField, config.label)
    end
    
    return inputContainer, inputField
end

-- Animate input field focus
function ThemeManager.animateInputFocus(inputField, focused)
    local theme = ThemeManager.getCurrentTheme()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local targetColor = focused and theme.accent.primary or theme.border.secondary
    local targetTransparency = focused and 0 or 0.3
    
    local tween = TweenService:Create(inputField, tweenInfo, {
        BorderColor3 = targetColor,
        BackgroundTransparency = targetTransparency
    })
    
    tween:Play()
end

-- Add floating label to input
function ThemeManager.addFloatingLabel(container, inputField, labelText)
    local label = Instance.new("TextLabel")
    label.Name = "FloatingLabel"
    label.Size = UDim2.new(0, 0, 0, 16)
    label.Position = UDim2.new(0, 12, 0, 16)
    label.Text = labelText
    label.Font = Constants.UI.THEME.FONTS.UI
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    -- Apply theme
    local theme = ThemeManager.getCurrentTheme()
    label.TextColor3 = theme.text.muted
    
    -- Auto-size the label
    label.AutomaticSize = Enum.AutomaticSize.X
    
    -- Animate label on focus
    if themeState.animationsEnabled then
        inputField.Focused:Connect(function()
            ThemeManager.animateFloatingLabel(label, true)
        end)
        
        inputField.FocusLost:Connect(function()
            if inputField.Text == "" then
                ThemeManager.animateFloatingLabel(label, false)
            end
        end)
        
        -- Check initial state
        if inputField.Text ~= "" then
            ThemeManager.animateFloatingLabel(label, true)
        end
    end
    
    return label
end

-- Animate floating label
function ThemeManager.animateFloatingLabel(label, focused)
    local theme = ThemeManager.getCurrentTheme()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local targetPosition, targetSize, targetColor
    
    if focused then
        targetPosition = UDim2.new(0, 12, 0, -8)
        targetSize = 10
        targetColor = theme.accent.primary
    else
        targetPosition = UDim2.new(0, 12, 0, 16)
        targetSize = 12
        targetColor = theme.text.muted
    end
    
    local positionTween = TweenService:Create(label, tweenInfo, {
        Position = targetPosition,
        TextSize = targetSize,
        TextColor3 = targetColor
    })
    
    positionTween:Play()
end

-- Create modern toggle switch
function ThemeManager.createModernToggle(config)
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Name = config.name or "ModernToggle"
    toggleContainer.Size = UDim2.new(0, 52, 0, 28)
    toggleContainer.Position = config.position or UDim2.new(0, 0, 0, 0)
    toggleContainer.BackgroundTransparency = 1
    
    -- Toggle track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 1, 0)
    track.Position = UDim2.new(0, 0, 0, 0)
    track.BorderSizePixel = 0
    track.Parent = toggleContainer
    
    -- Apply theme
    local theme = ThemeManager.getCurrentTheme()
    track.BackgroundColor3 = config.enabled and theme.accent.primary or theme.border.primary
    
    -- Rounded track
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    -- Toggle thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, 24, 0, 24)
    thumb.Position = config.enabled and UDim2.new(1, -26, 0, 2) or UDim2.new(0, 2, 0, 2)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = toggleContainer
    
    -- Rounded thumb
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb
    
    -- Add shadow to thumb
    if themeState.effectsEnabled then
        ThemeManager.addShadowEffect(thumb, "small")
    end
    
    -- Click handler
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = toggleContainer
    
    local enabled = config.enabled or false
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        ThemeManager.animateToggle(track, thumb, enabled, theme)
        
        if config.onToggle then
            config.onToggle(enabled)
        end
    end)
    
    return toggleContainer, enabled
end

-- Animate toggle switch
function ThemeManager.animateToggle(track, thumb, enabled, theme)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    local trackColor = enabled and theme.accent.primary or theme.border.primary
    local thumbPosition = enabled and UDim2.new(1, -26, 0, 2) or UDim2.new(0, 2, 0, 2)
    
    local trackTween = TweenService:Create(track, tweenInfo, {
        BackgroundColor3 = trackColor
    })
    
    local thumbTween = TweenService:Create(thumb, tweenInfo, {
        Position = thumbPosition
    })
    
    trackTween:Play()
    thumbTween:Play()
end

-- Create modern progress bar
function ThemeManager.createModernProgressBar(config)
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = config.name or "ModernProgressBar"
    progressContainer.Size = config.size or UDim2.new(1, 0, 0, 8)
    progressContainer.Position = config.position or UDim2.new(0, 0, 0, 0)
    progressContainer.BackgroundTransparency = 1
    
    -- Progress track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 1, 0)
    track.Position = UDim2.new(0, 0, 0, 0)
    track.BorderSizePixel = 0
    track.Parent = progressContainer
    
    -- Apply theme
    local theme = ThemeManager.getCurrentTheme()
    track.BackgroundColor3 = theme.background.tertiary
    
    -- Rounded track
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    -- Progress fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(config.progress or 0, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = config.color or theme.accent.primary
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    -- Rounded fill
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    -- Add gradient effect
    if config.gradient then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, theme.accent.primary),
            ColorSequenceKeypoint.new(1, theme.accent.secondary)
        }
        gradient.Parent = fill
    end
    
    -- Update progress function
    local function updateProgress(progress)
        progress = math.clamp(progress, 0, 1)
        
        if themeState.animationsEnabled then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(fill, tweenInfo, {
                Size = UDim2.new(progress, 0, 1, 0)
            })
            tween:Play()
        else
            fill.Size = UDim2.new(progress, 0, 1, 0)
        end
    end
    
    return progressContainer, updateProgress
end

-- Create modern tooltip
function ThemeManager.createModernTooltip(targetElement, tooltipText)
    if not targetElement or not tooltipText then return end
    
    local tooltip = Instance.new("Frame")
    tooltip.Name = "ModernTooltip"
    tooltip.Size = UDim2.new(0, 0, 0, 32)
    tooltip.BackgroundTransparency = 1
    tooltip.Visible = false
    tooltip.ZIndex = 1000
    tooltip.Parent = targetElement.Parent
    
    -- Tooltip background
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 16, 1, 0)
    bg.Position = UDim2.new(0, -8, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    bg.BackgroundTransparency = 0.1
    bg.BorderSizePixel = 0
    bg.Parent = tooltip
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bg
    
    -- Tooltip text
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(1, -16, 1, 0)
    text.Position = UDim2.new(0, 8, 0, 0)
    text.Text = tooltipText
    text.Font = Constants.UI.THEME.FONTS.UI
    text.TextSize = 12
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.BackgroundTransparency = 1
    text.TextXAlignment = Enum.TextXAlignment.Center
    text.Parent = tooltip
    
    -- Auto-size tooltip
    text.AutomaticSize = Enum.AutomaticSize.X
    tooltip.AutomaticSize = Enum.AutomaticSize.X
    
    -- Show/hide handlers
    local showConnection, hideConnection
    
    showConnection = targetElement.MouseEnter:Connect(function()
        tooltip.Visible = true
        
        -- Position tooltip above target
        local targetPos = targetElement.AbsolutePosition
        local targetSize = targetElement.AbsoluteSize
        tooltip.Position = UDim2.new(0, targetPos.X + targetSize.X/2 - tooltip.AbsoluteSize.X/2, 0, targetPos.Y - 40)
        
        if themeState.animationsEnabled then
            ThemeManager.fadeIn(tooltip, 0.2)
        end
    end)
    
    hideConnection = targetElement.MouseLeave:Connect(function()
        if themeState.animationsEnabled then
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(tooltip, tweenInfo, {
                BackgroundTransparency = 1
            })
            tween:Play()
            tween.Completed:Connect(function()
                tooltip.Visible = false
                tooltip.BackgroundTransparency = 0
            end)
        else
            tooltip.Visible = false
        end
    end)
    
    -- Cleanup function
    tooltip.AncestryChanged:Connect(function()
        if not tooltip.Parent then
            showConnection:Disconnect()
            hideConnection:Disconnect()
        end
    end)
    
    return tooltip
end

-- Create modern notification
function ThemeManager.createModernNotification(config)
    local notification = Instance.new("Frame")
    notification.Name = "ModernNotification"
    notification.Size = UDim2.new(0, 320, 0, 80)
    notification.Position = UDim2.new(1, -340, 0, 20)
    notification.BackgroundTransparency = 1
    notification.ZIndex = 1000
    
    -- Notification card
    local card = ThemeManager.createGlassmorphismCard({
        name = "NotificationCard",
        size = UDim2.new(1, 0, 1, 0),
        cornerRadius = 12
    })
    card.Parent = notification
    
    -- Icon
    if config.icon then
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 16, 0, 16)
        icon.Text = config.icon
        icon.Font = Constants.UI.THEME.FONTS.UI
        icon.TextSize = 18
        icon.BackgroundTransparency = 1
        icon.Parent = card
        
        -- Color based on type
        local theme = ThemeManager.getCurrentTheme()
        if config.type == "success" then
            icon.TextColor3 = theme.accent.success
        elseif config.type == "warning" then
            icon.TextColor3 = theme.accent.warning
        elseif config.type == "error" then
            icon.TextColor3 = theme.accent.error
        else
            icon.TextColor3 = theme.accent.primary
        end
    end
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 0, 20)
    title.Position = UDim2.new(0, 48, 0, 12)
    title.Text = config.title or "Notification"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 14
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = card
    
    -- Message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -60, 0, 36)
    message.Position = UDim2.new(0, 48, 0, 32)
    message.Text = config.message or ""
    message.Font = Constants.UI.THEME.FONTS.UI
    message.TextSize = 12
    message.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    message.BackgroundTransparency = 1
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.TextWrapped = true
    message.Parent = card
    
    -- Auto-dismiss after duration
    local duration = config.duration or 5
    
    spawn(function()
        wait(duration)
        ThemeManager.dismissNotification(notification)
    end)
    
    -- Slide in animation
    if themeState.animationsEnabled then
        ThemeManager.slideIn(notification, "right", 0.3)
    end
    
    return notification
end

-- Dismiss notification with animation
function ThemeManager.dismissNotification(notification)
    if themeState.animationsEnabled then
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(notification, tweenInfo, {
            Position = UDim2.new(1, 20, notification.Position.Y.Scale, notification.Position.Y.Offset)
        })
        
        tween:Play()
        tween.Completed:Connect(function()
            notification:Destroy()
        end)
    else
        notification:Destroy()
    end
end

-- Accessibility improvements
function ThemeManager.addAccessibilityFeatures(element, config)
    -- Add focus indicators for keyboard navigation
    if config.focusable then
        ThemeManager.addFocusIndicator(element)
    end
    
    -- Add high contrast support
    if config.highContrast then
        ThemeManager.addHighContrastSupport(element)
    end
    
    -- Add screen reader support
    if config.screenReader then
        element.Name = config.screenReader.name or element.Name
        -- In production, would add proper accessibility attributes
    end
end

-- Add focus indicator for keyboard navigation
function ThemeManager.addFocusIndicator(element)
    local focusIndicator = Instance.new("Frame")
    focusIndicator.Name = "FocusIndicator"
    focusIndicator.Size = UDim2.new(1, 4, 1, 4)
    focusIndicator.Position = UDim2.new(0, -2, 0, -2)
    focusIndicator.BackgroundTransparency = 1
    focusIndicator.BorderSizePixel = 2
    focusIndicator.BorderColor3 = ThemeManager.getCurrentTheme().accent.primary
    focusIndicator.ZIndex = element.ZIndex + 1
    focusIndicator.Visible = false
    focusIndicator.Parent = element
    
    -- Rounded corners to match element
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = focusIndicator
    
    -- Show/hide focus indicator (would be connected to actual focus events in production)
    return focusIndicator
end

-- Add high contrast support
function ThemeManager.addHighContrastSupport(element)
    -- Store original colors
    local originalBg = element.BackgroundColor3
    local originalText = element.TextColor3
    
    -- Function to toggle high contrast
    local function toggleHighContrast(enabled)
        if enabled then
            element.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            element.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            element.BackgroundColor3 = originalBg
            element.TextColor3 = originalText
        end
    end
    
    return toggleHighContrast
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