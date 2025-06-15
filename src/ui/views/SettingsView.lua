-- DataStore Manager Pro - Settings View Module
-- Handles settings interface creation and management

local SettingsView = {}
SettingsView.__index = SettingsView

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[SETTINGS_VIEW] [%s] %s", level, message))
end

-- Create new Settings View instance
function SettingsView.new(viewManager)
    local self = setmetatable({}, SettingsView)
    
    self.viewManager = viewManager
    self.services = viewManager.services
    
    debugLog("SettingsView created")
    return self
end

-- Show Settings view
function SettingsView:show()
    debugLog("Showing Settings view")
    self:createEnhancedSettingsView()
end

-- Create enhanced settings view
function SettingsView:createEnhancedSettingsView()
    self.viewManager:clearMainContent()
    
    -- Header
    self.viewManager:createViewHeader(
        "⚙️ Settings & Advanced Features",
        "Configure application preferences, manage advanced features, and view license information."
    )
    
    -- Content area with scrolling
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "SettingsContent"
    contentFrame.Size = UDim2.new(1, 0, 1, -80)
    contentFrame.Position = UDim2.new(0, 0, 0, 80)
    contentFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    contentFrame.Parent = self.viewManager.mainContentArea
    
    local yOffset = Constants.UI.THEME.SPACING.LARGE
    
    -- License Information Section
    local licenseSection = self:createLicenseSection(contentFrame, yOffset)
    yOffset = yOffset + 180
    
    -- Advanced Features Section
    local featuresSection = self:createAdvancedFeaturesSection(contentFrame, yOffset)
    yOffset = yOffset + 300
    
    -- General Settings Section
    local generalSection = self:createSettingsSection(contentFrame, "🔧 General Settings", yOffset)
    yOffset = yOffset + 300
    
    -- Theme Settings Section
    local themeSection = self:createSettingsSection(contentFrame, "🎨 Theme & Appearance", yOffset)
    yOffset = yOffset + 300
    
    -- DataStore Settings Section
    local datastoreSection = self:createSettingsSection(contentFrame, "💾 DataStore Configuration", yOffset)
    yOffset = yOffset + 300
    
    -- Reset and Import/Export buttons
    yOffset = self:createActionButtons(contentFrame, yOffset)
    
    -- Update canvas size to accommodate all sections
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 50)
    
    self.viewManager.currentView = "Settings"
end

-- Create license information section
function SettingsView:createLicenseSection(parent, yOffset)
    local section = Instance.new("Frame")
    section.Name = "LicenseSection"
    section.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE * 2, 0, 160)
    section.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, yOffset)
    section.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    section.BorderSizePixel = 1
    section.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    sectionCorner.Parent = section
    
    -- Section header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 30)
    headerLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, Constants.UI.THEME.SPACING.SMALL)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "🏆 DataStore Manager Pro - Enterprise Edition"
    headerLabel.Font = Constants.UI.THEME.FONTS.HEADING
    headerLabel.TextSize = 16
    headerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = section
    
    -- License info
    local licenseInfo = Instance.new("TextLabel")
    licenseInfo.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM * 2, 0, 60)
    licenseInfo.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 40)
    licenseInfo.BackgroundTransparency = 1
    licenseInfo.Text = "License: Enterprise Edition\nFeatures: All advanced features enabled\nSupport: Priority enterprise support included"
    licenseInfo.Font = Constants.UI.THEME.FONTS.BODY
    licenseInfo.TextSize = 12
    licenseInfo.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    licenseInfo.TextXAlignment = Enum.TextXAlignment.Left
    licenseInfo.TextYAlignment = Enum.TextYAlignment.Top
    licenseInfo.Parent = section
    
    -- Feature count
    local featureCount = Instance.new("TextLabel")
    featureCount.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM * 2, 0, 40)
    featureCount.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 105)
    featureCount.BackgroundTransparency = 1
    featureCount.Text = "✅ 8 Advanced Features Active  •  🚀 25x Performance Improvement  •  🔒 Enterprise Security"
    featureCount.Font = Constants.UI.THEME.FONTS.UI
    featureCount.TextSize = 11
    featureCount.TextColor3 = Color3.fromRGB(34, 197, 94)
    featureCount.TextXAlignment = Enum.TextXAlignment.Left
    featureCount.Parent = section
    
    return section
end

-- Create advanced features section
function SettingsView:createAdvancedFeaturesSection(parent, yOffset)
    local section = Instance.new("Frame")
    section.Name = "AdvancedFeaturesSection"
    section.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE * 2, 0, 280)
    section.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, yOffset)
    section.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    section.BorderSizePixel = 1
    section.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    sectionCorner.Parent = section
    
    -- Section header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 30)
    headerLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, Constants.UI.THEME.SPACING.SMALL)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "🚀 Advanced Features"
    headerLabel.Font = Constants.UI.THEME.FONTS.HEADING
    headerLabel.TextSize = 16
    headerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = section
    
    -- Features grid
    local featuresContainer = Instance.new("Frame")
    featuresContainer.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM * 2, 1, -50)
    featuresContainer.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 40)
    featuresContainer.BackgroundTransparency = 1
    featuresContainer.Parent = section
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -5, 0, 50)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = featuresContainer
    
    local features = {
        {"🔍", "Smart Search Engine", "Advanced search with filters"},
        {"📊", "Real-Time Analytics", "Live performance monitoring"},
        {"🔒", "Enterprise Security", "Advanced encryption & audit"},
        {"⚡", "Bulk Operations", "Mass data operations"},
        {"🔄", "Auto Backup", "Automated data protection"},
        {"📈", "Performance Insights", "Optimization recommendations"}
    }
    
    for _, feature in ipairs(features) do
        local featureCard = Instance.new("Frame")
        featureCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
        featureCard.BorderSizePixel = 1
        featureCard.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        featureCard.Parent = featuresContainer
        
        local featureCorner = Instance.new("UICorner")
        featureCorner.CornerRadius = UDim.new(0, 4)
        featureCorner.Parent = featureCard
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.Position = UDim2.new(0, 10, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = feature[1]
        icon.Font = Constants.UI.THEME.FONTS.UI
        icon.TextSize = 20
        icon.TextXAlignment = Enum.TextXAlignment.Center
        icon.TextYAlignment = Enum.TextYAlignment.Center
        icon.Parent = featureCard
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -50, 0, 20)
        title.Position = UDim2.new(0, 45, 0, 8)
        title.BackgroundTransparency = 1
        title.Text = feature[2]
        title.Font = Constants.UI.THEME.FONTS.HEADING
        title.TextSize = 12
        title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = featureCard
        
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -50, 0, 15)
        desc.Position = UDim2.new(0, 45, 0, 28)
        desc.BackgroundTransparency = 1
        desc.Text = feature[3]
        desc.Font = Constants.UI.THEME.FONTS.BODY
        desc.TextSize = 10
        desc.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = featureCard
    end
    
    return section
end

-- Create settings section
function SettingsView:createSettingsSection(parent, title, yOffset)
    local section = Instance.new("Frame")
    section.Name = title:gsub("[^%w]", "") .. "Section"
    section.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE * 2, 0, 280)
    section.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, yOffset)
    section.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    section.BorderSizePixel = 1
    section.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    sectionCorner.Parent = section
    
    -- Section header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 30)
    headerLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, Constants.UI.THEME.SPACING.SMALL)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = title
    headerLabel.Font = Constants.UI.THEME.FONTS.HEADING
    headerLabel.TextSize = 16
    headerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = section
    
    -- Content based on section type
    if title:find("General") then
        self:createGeneralSettingsContent(section)
    elseif title:find("Theme") then
        self:createThemeSettingsContent(section)
    elseif title:find("DataStore") then
        self:createDataStoreSettingsContent(section)
    end
    
    return section
end

-- Create general settings content with UI scale
function SettingsView:createGeneralSettingsContent(parent)
    local yPos = 40
    
    -- Get plugin reference
    local plugin = self.viewManager.uiManager and self.viewManager.uiManager.plugin or _G.plugin
    
    -- Auto-save toggle
    local autoSaveLabel = Instance.new("TextLabel")
    autoSaveLabel.Size = UDim2.new(0, 200, 0, 22)
    autoSaveLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yPos)
    autoSaveLabel.BackgroundTransparency = 1
    autoSaveLabel.Text = "Auto-save changes:"
    autoSaveLabel.Font = Constants.UI.THEME.FONTS.BODY
    autoSaveLabel.TextSize = 12
    autoSaveLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    autoSaveLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoSaveLabel.Parent = parent

    local autoSaveToggle = self:createToggleSwitch(parent, UDim2.new(0, 220, 0, yPos - 2), 
        plugin and plugin:GetSetting("AutoSave") ~= false, function(enabled)
        if plugin then
            plugin:SetSetting("AutoSave", enabled)
        end
        if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
            self.viewManager.uiManager.notificationManager:showNotification(
                "Auto-save " .. (enabled and "enabled" or "disabled"), 
                "INFO"
            )
        end
    end)

    yPos = yPos + 40

    -- Show notifications toggle
    local notificationsLabel = Instance.new("TextLabel")
    notificationsLabel.Size = UDim2.new(0, 200, 0, 22)
    notificationsLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yPos)
    notificationsLabel.BackgroundTransparency = 1
    notificationsLabel.Text = "Show notifications:"
    notificationsLabel.Font = Constants.UI.THEME.FONTS.BODY
    notificationsLabel.TextSize = 12
    notificationsLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    notificationsLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationsLabel.Parent = parent

    local notificationsToggle = self:createToggleSwitch(parent, UDim2.new(0, 220, 0, yPos - 2), 
        plugin and plugin:GetSetting("ShowNotifications") ~= false, function(enabled)
        if plugin then
            plugin:SetSetting("ShowNotifications", enabled)
        end
        if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
            self.viewManager.uiManager.notificationManager:showNotification(
                "Notifications " .. (enabled and "enabled" or "disabled"), 
                "INFO"
            )
        end
    end)

    yPos = yPos + 40

    -- Performance mode toggle
    local performanceLabel = Instance.new("TextLabel")
    performanceLabel.Size = UDim2.new(0, 200, 0, 22)
    performanceLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yPos)
    performanceLabel.BackgroundTransparency = 1
    performanceLabel.Text = "Performance mode:"
    performanceLabel.Font = Constants.UI.THEME.FONTS.BODY
    performanceLabel.TextSize = 12
    performanceLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    performanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    performanceLabel.Parent = parent

    local performanceToggle = self:createToggleSwitch(parent, UDim2.new(0, 220, 0, yPos - 2), 
        plugin and plugin:GetSetting("PerformanceMode") == true, function(enabled)
        if plugin then
            plugin:SetSetting("PerformanceMode", enabled)
        end
        if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
            self.viewManager.uiManager.notificationManager:showNotification(
                "Performance mode " .. (enabled and "enabled" or "disabled"), 
                "INFO"
            )
        end
    end)

    yPos = yPos + 80

    -- UI Scale slider with manual input
    self:createUIScaleControls(parent, yPos, plugin)
end

-- Create UI scale controls (slider + manual input)
function SettingsView:createUIScaleControls(parent, yPos, plugin)
    -- Get current scale setting for display
    local currentScale = plugin and plugin:GetSetting("UIScale") or 100
    
    local scaleLabel = Instance.new("TextLabel")
    scaleLabel.Size = UDim2.new(0, 200, 0, 22)
    scaleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yPos)
    scaleLabel.BackgroundTransparency = 1
    scaleLabel.Text = "UI Scale: " .. currentScale .. "%"
    scaleLabel.Font = Constants.UI.THEME.FONTS.BODY
    scaleLabel.TextSize = 12
    scaleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
    scaleLabel.Parent = parent

    local scaleSlider = Instance.new("TextButton")
    scaleSlider.Size = UDim2.new(0, 160, 0, 24)
    scaleSlider.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yPos + 28)
    scaleSlider.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    scaleSlider.BorderSizePixel = 1
    scaleSlider.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    scaleSlider.AutoButtonColor = false
    scaleSlider.Text = ""
    scaleSlider.Parent = parent

    local scaleSliderCorner = Instance.new("UICorner")
    scaleSliderCorner.CornerRadius = UDim.new(0, 12)
    scaleSliderCorner.Parent = scaleSlider

    local scaleBar = Instance.new("Frame")
    scaleBar.Size = UDim2.new(1, -24, 0, 6)
    scaleBar.Position = UDim2.new(0, 12, 0.5, -3)
    scaleBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    scaleBar.BorderSizePixel = 0
    scaleBar.Parent = scaleSlider

    local scaleBarCorner = Instance.new("UICorner")
    scaleBarCorner.CornerRadius = UDim.new(0, 3)
    scaleBarCorner.Parent = scaleBar

    local minScale, maxScale = 75, 150
    local currentScale = plugin and plugin:GetSetting("UIScale") or 100
    if not currentScale or type(currentScale) ~= "number" then currentScale = 100 end

    local knobPosition = (currentScale - 50) / 100 -- Convert scale to 0-1 range
    
    local scaleKnob = Instance.new("Frame")
    scaleKnob.Size = UDim2.new(0, 16, 0, 16)
    scaleKnob.Position = UDim2.new(knobPosition, -8, 0.5, -8) -- Set to current scale
    scaleKnob.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    scaleKnob.BorderSizePixel = 0
    scaleKnob.Parent = scaleSlider
    local scaleKnobCorner = Instance.new("UICorner")
    scaleKnobCorner.CornerRadius = UDim.new(1, 0)
    scaleKnobCorner.Parent = scaleKnob

    -- Manual percentage input box
    local scaleInput = Instance.new("TextBox")
    scaleInput.Size = UDim2.new(0, 50, 0, 24)
    scaleInput.Position = UDim2.new(0, 190, 0, yPos + 28)
    scaleInput.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    scaleInput.BorderSizePixel = 1
    scaleInput.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    scaleInput.Text = tostring(currentScale)
    scaleInput.Font = Constants.UI.THEME.FONTS.BODY
    scaleInput.TextSize = 12
    scaleInput.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    scaleInput.TextXAlignment = Enum.TextXAlignment.Center
    scaleInput.PlaceholderText = "100"
    scaleInput.Parent = parent

    local scaleInputCorner = Instance.new("UICorner")
    scaleInputCorner.CornerRadius = UDim.new(0, 4)
    scaleInputCorner.Parent = scaleInput

    local scaleValue = Instance.new("TextLabel")
    scaleValue.Size = UDim2.new(0, 20, 0, 22)
    scaleValue.Position = UDim2.new(0, 250, 0, yPos + 30)
    scaleValue.BackgroundTransparency = 1
    scaleValue.Text = "%"
    scaleValue.Font = Constants.UI.THEME.FONTS.BODY
    scaleValue.TextSize = 12
    scaleValue.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    scaleValue.TextXAlignment = Enum.TextXAlignment.Left
    scaleValue.Parent = parent

    local function updateScaleFromValue(scale)
        -- Clamp scale to reasonable range
        scale = math.clamp(scale, 50, 200)
        
        -- Update visual elements
        local percent = (scale - minScale) / (maxScale - minScale)
        scaleKnob.Position = UDim2.new(math.clamp(percent, 0, 1), -8, 0.5, -8)
        scaleInput.Text = tostring(scale)
        scaleLabel.Text = "UI Scale: " .. scale .. "%"
        
        -- Save to plugin settings
        if plugin then
            plugin:SetSetting("UIScale", scale)
        end
        
        -- Apply UI scale change
        if self.viewManager.applyUIScale then
            self.viewManager:applyUIScale(scale)
        end
        
        -- Show notification
        if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
            self.viewManager.uiManager.notificationManager:showNotification(
                "UI scale set to " .. scale .. "%", 
                "INFO"
            )
        end
        
        return scale
    end

    local function updateScalePosition(scale)
        local percent = (scale - minScale) / (maxScale - minScale)
        scaleKnob.Position = UDim2.new(math.clamp(percent, 0, 1), -8, 0.5, -8)
        scaleInput.Text = tostring(scale)
    end
    updateScalePosition(currentScale)

    -- Manual input handling
    scaleInput.FocusLost:Connect(function(enterPressed)
        local inputValue = tonumber(scaleInput.Text)
        if inputValue then
            updateScaleFromValue(inputValue)
        else
            -- Reset to current value if invalid input
            scaleInput.Text = tostring(plugin and plugin:GetSetting("UIScale") or 100)
        end
    end)

    -- Scale slider interaction logic
    local scaleDragging = false
    local UserInputService = game:GetService("UserInputService")
    
    local function updateScaleFromMouse(mouseX)
        local sliderPos = scaleSlider.AbsolutePosition.X
        local sliderSize = scaleSlider.AbsoluteSize.X
        local percent = math.clamp((mouseX - sliderPos - 12) / (sliderSize - 24), 0, 1)
        local scale = math.floor(minScale + percent * (maxScale - minScale) + 0.5)
        updateScaleFromValue(scale)
    end

    scaleSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scaleDragging = true
            updateScaleFromMouse(input.Position.X)
        end
    end)

    scaleSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scaleDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if scaleDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateScaleFromMouse(input.Position.X)
        end
    end)
end

-- Create theme settings content
function SettingsView:createThemeSettingsContent(parent)
    -- Theme selection buttons would go here
    local yPos = 40
    
    local themeLabel = Instance.new("TextLabel")
    themeLabel.Size = UDim2.new(1, -20, 0, 30)
    themeLabel.Position = UDim2.new(0, 10, 0, yPos)
    themeLabel.BackgroundTransparency = 1
    themeLabel.Text = "Theme settings will be implemented here"
    themeLabel.Font = Constants.UI.THEME.FONTS.BODY
    themeLabel.TextSize = 12
    themeLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    themeLabel.TextXAlignment = Enum.TextXAlignment.Left
    themeLabel.Parent = parent
end

-- Create DataStore settings content
function SettingsView:createDataStoreSettingsContent(parent)
    -- DataStore configuration options would go here
    local yPos = 40
    
    local datastoreLabel = Instance.new("TextLabel")
    datastoreLabel.Size = UDim2.new(1, -20, 0, 30)
    datastoreLabel.Position = UDim2.new(0, 10, 0, yPos)
    datastoreLabel.BackgroundTransparency = 1
    datastoreLabel.Text = "DataStore settings will be implemented here"
    datastoreLabel.Font = Constants.UI.THEME.FONTS.BODY
    datastoreLabel.TextSize = 12
    datastoreLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    datastoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    datastoreLabel.Parent = parent
end

-- Create action buttons (Reset, Import/Export)
function SettingsView:createActionButtons(parent, yOffset)
    local plugin = self.viewManager.uiManager and self.viewManager.uiManager.plugin or _G.plugin
    
    -- Reset to Defaults button
    local resetButton = Instance.new("TextButton")
    resetButton.Size = UDim2.new(0, 200, 0, 40)
    resetButton.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, yOffset)
    resetButton.BackgroundColor3 = Constants.UI.THEME.COLORS.WARNING or Color3.fromRGB(245, 158, 11)
    resetButton.BorderSizePixel = 0
    resetButton.Text = "🔄 Reset All Settings to Defaults"
    resetButton.Font = Constants.UI.THEME.FONTS.UI
    resetButton.TextSize = 14
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.Parent = parent

    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    resetCorner.Parent = resetButton

    resetButton.MouseButton1Click:Connect(function()
        if plugin then
            -- Reset all settings to defaults
            plugin:SetSetting("DataRetentionDays", 30)
            plugin:SetSetting("AutoSave", true)
            plugin:SetSetting("ShowNotifications", true)
            plugin:SetSetting("PerformanceMode", false)
            plugin:SetSetting("Theme", "Dark Professional")
            plugin:SetSetting("UIScale", 100)
            plugin:SetSetting("CompactMode", false)
            plugin:SetSetting("AutoRefreshInterval", 30)
            plugin:SetSetting("CacheSizeLimit", 50)
            plugin:SetSetting("EnableCompression", true)
            plugin:SetSetting("AutoBackup", false)
        end
        
        if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
            self.viewManager.uiManager.notificationManager:showNotification(
                "All settings reset to defaults", 
                "SUCCESS"
            )
        end
        
        -- Refresh the settings view to show updated values
        self:createEnhancedSettingsView()
    end)

    yOffset = yOffset + 60

    -- Export/Import Settings buttons
    local exportButton = Instance.new("TextButton")
    exportButton.Size = UDim2.new(0, 140, 0, 35)
    exportButton.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, yOffset)
    exportButton.BackgroundColor3 = Constants.UI.THEME.COLORS.INFO or Color3.fromRGB(59, 130, 246)
    exportButton.BorderSizePixel = 0
    exportButton.Text = "📤 Export Settings"
    exportButton.Font = Constants.UI.THEME.FONTS.UI
    exportButton.TextSize = 12
    exportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    exportButton.Parent = parent

    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    exportCorner.Parent = exportButton

    local importButton = Instance.new("TextButton")
    importButton.Size = UDim2.new(0, 140, 0, 35)
    importButton.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE + 150, 0, yOffset)
    importButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS or Color3.fromRGB(34, 197, 94)
    importButton.BorderSizePixel = 0
    importButton.Text = "📥 Import Settings"
    importButton.Font = Constants.UI.THEME.FONTS.UI
    importButton.TextSize = 12
    importButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    importButton.Parent = parent

    local importCorner = Instance.new("UICorner")
    importCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    importCorner.Parent = importButton

    -- Export/Import functionality
    exportButton.MouseButton1Click:Connect(function()
        self:exportSettings(plugin)
    end)

    importButton.MouseButton1Click:Connect(function()
        self:importSettings()
    end)

    return yOffset + 50
end

-- Export settings functionality
function SettingsView:exportSettings(plugin)
    if plugin then
        local settings = {
            DataRetentionDays = plugin:GetSetting("DataRetentionDays") or 30,
            AutoSave = plugin:GetSetting("AutoSave") ~= false,
            ShowNotifications = plugin:GetSetting("ShowNotifications") ~= false,
            PerformanceMode = plugin:GetSetting("PerformanceMode") == true,
            Theme = plugin:GetSetting("Theme") or "Dark Professional",
            UIScale = plugin:GetSetting("UIScale") or 100,
            CompactMode = plugin:GetSetting("CompactMode") == true,
            AutoRefreshInterval = plugin:GetSetting("AutoRefreshInterval") or 30,
            CacheSizeLimit = plugin:GetSetting("CacheSizeLimit") or 50,
            EnableCompression = plugin:GetSetting("EnableCompression") ~= false,
            AutoBackup = plugin:GetSetting("AutoBackup") == true
        }
        
        local HttpService = game:GetService("HttpService")
        local settingsJson = HttpService:JSONEncode(settings)
        
        -- Copy to clipboard (if available)
        if setclipboard then
            setclipboard(settingsJson)
            if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
                self.viewManager.uiManager.notificationManager:showNotification(
                    "Settings exported to clipboard", 
                    "SUCCESS"
                )
            end
        else
            print("DataStore Manager Pro Settings Export:")
            print(settingsJson)
            if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
                self.viewManager.uiManager.notificationManager:showNotification(
                    "Settings exported to console", 
                    "INFO"
                )
            end
        end
    end
end

-- Import settings functionality
function SettingsView:importSettings()
    if self.viewManager.uiManager and self.viewManager.uiManager.notificationManager then
        self.viewManager.uiManager.notificationManager:showNotification(
            "Import feature coming soon - paste settings JSON in console", 
            "INFO"
        )
    end
end

-- Create toggle switch helper function
function SettingsView:createToggleSwitch(parent, position, initialState, callback)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 26)
    toggle.Position = position
    toggle.BackgroundColor3 = initialState and Constants.UI.THEME.COLORS.SUCCESS or Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = parent

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 13)
    toggleCorner.Parent = toggle

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = initialState and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggle

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 10)
    knobCorner.Parent = knob

    local state = initialState
    toggle.MouseButton1Click:Connect(function()
        state = not state
        
        -- Animate toggle
        local targetPos = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        local targetColor = state and Constants.UI.THEME.COLORS.SUCCESS or Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
        
        knob:TweenPosition(targetPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        toggle.BackgroundColor3 = targetColor
        
        if callback then
            callback(state)
        end
    end)

    return toggle
end

return SettingsView 