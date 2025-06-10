-- DataStore Manager Pro - Integrated UI Manager
-- Fully integrated UI with all advanced systems following 2.2 Core Principles

local UIManager = {}
UIManager.__index = UIManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[INTEGRATED_UI] [%s] %s", level, message))
end

-- Create new integrated UI Manager instance
function UIManager.new(widget, services, pluginInfo)
    if not widget then
        debugLog("Widget is required for UI Manager", "ERROR")
        return nil
    end
    
    local self = setmetatable({}, UIManager)
    
    self.widget = widget
    self.services = services or {}
    self.pluginInfo = pluginInfo or {}
    self.components = {}
    self.initialized = false
    
    -- Initialize the interface
    local success, error = pcall(function()
        return self:initialize()
    end)
    
    if not success then
        debugLog("UI Manager initialization failed: " .. tostring(error), "ERROR")
        return nil
    end
    
    debugLog("Integrated UI Manager created successfully")
    return self
end

-- Initialize the integrated UI
function UIManager:initialize()
    if self.initialized then return true end
    
    debugLog("Initializing Integrated UI Manager...")
    
    -- Create main frame
    self:createMainFrame()
    
    -- Setup modern layout
    self:setupModernLayout()
    
    -- Initialize feature integrations
    self:initializeIntegrations()
    
    self.initialized = true
    debugLog("Integrated UI Manager initialized successfully")
    return true
end

-- Create main frame with professional styling
function UIManager:createMainFrame()
    -- Main container
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "DataStoreManagerPro"
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.Position = UDim2.new(0, 0, 0, 0)
    self.mainFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.widget
    
    -- Title bar with gradient
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 50)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.mainFrame
    
    -- Add gradient to title bar
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Constants.UI.THEME.COLORS.PRIMARY),
        ColorSequenceKeypoint.new(1, Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY)
    }
    gradient.Rotation = 90
    gradient.Transparency = NumberSequence.new(0.7)
    gradient.Parent = self.titleBar
    
    -- Title with license tier indicator
    self:createTitleWithLicenseIndicator()
    
    -- Content area
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, 0, 1, -80)
    self.contentArea.Position = UDim2.new(0, 0, 0, 50)
    self.contentArea.BackgroundTransparency = 1
    self.contentArea.Parent = self.mainFrame
    
    -- Status bar
    self:createEnhancedStatusBar()
end

-- Create title with license tier indicator
function UIManager:createTitleWithLicenseIndicator()
    local titleContainer = Instance.new("Frame")
    titleContainer.Size = UDim2.new(1, -20, 1, 0)
    titleContainer.Position = UDim2.new(0, 10, 0, 0)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = self.titleBar
    
    -- Main title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 300, 1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📊 " .. (self.pluginInfo.name or "DataStore Manager Pro")
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleContainer
    
    -- License tier badge
    self.licenseBadge = Instance.new("TextLabel")
    self.licenseBadge.Size = UDim2.new(0, 120, 0, 25)
    self.licenseBadge.Position = UDim2.new(1, -130, 0.5, -12)
    self.licenseBadge.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    self.licenseBadge.BorderSizePixel = 0
    self.licenseBadge.Text = "🆓 Free Tier"
    self.licenseBadge.Font = Constants.UI.THEME.FONTS.BODY
    self.licenseBadge.TextSize = 11
    self.licenseBadge.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    self.licenseBadge.Parent = titleContainer
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 12)
    badgeCorner.Parent = self.licenseBadge
    
    -- Update license badge
    self:updateLicenseBadge()
end

-- Update license badge based on current tier
function UIManager:updateLicenseBadge()
    if self.services and self.services["core.licensing.LicenseManager"] then
        local licenseManager = self.services["core.licensing.LicenseManager"]
        local status = licenseManager.getLicenseStatus()
        
        if status and status.tier then
            self.licenseBadge.Text = status.tier.icon .. " " .. status.tier.name
            
            -- Update colors based on tier
            if status.tier.level >= 3 then
                self.licenseBadge.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
            elseif status.tier.level >= 2 then
                self.licenseBadge.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Purple
            elseif status.tier.level >= 1 then
                self.licenseBadge.BackgroundColor3 = Color3.fromRGB(0, 162, 255) -- Blue
            else
                self.licenseBadge.BackgroundColor3 = Color3.fromRGB(108, 117, 125) -- Gray
            end
        end
    end
end

-- Create enhanced status bar with performance metrics
function UIManager:createEnhancedStatusBar()
    self.statusBar = Instance.new("Frame")
    self.statusBar.Name = "StatusBar"
    self.statusBar.Size = UDim2.new(1, 0, 0, 30)
    self.statusBar.Position = UDim2.new(0, 0, 1, -30)
    self.statusBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.statusBar.BorderSizePixel = 1
    self.statusBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    self.statusBar.Parent = self.mainFrame
    
    -- Status sections
    self:createStatusSections()
end

-- Create status sections with real-time data
function UIManager:createStatusSections()
    -- Main status
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Size = UDim2.new(0, 200, 1, 0)
    self.statusLabel.Position = UDim2.new(0, 10, 0, 0)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = "🟢 Ready"
    self.statusLabel.Font = Constants.UI.THEME.FONTS.BODY
    self.statusLabel.TextSize = 12
    self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.Parent = self.statusBar
    
    -- Performance indicator
    self.perfIndicator = Instance.new("TextLabel")
    self.perfIndicator.Size = UDim2.new(0, 120, 1, 0)
    self.perfIndicator.Position = UDim2.new(0, 220, 0, 0)
    self.perfIndicator.BackgroundTransparency = 1
    self.perfIndicator.Text = "⚡ 0ms"
    self.perfIndicator.Font = Constants.UI.THEME.FONTS.BODY
    self.perfIndicator.TextSize = 12
    self.perfIndicator.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    self.perfIndicator.TextXAlignment = Enum.TextXAlignment.Left
    self.perfIndicator.Parent = self.statusBar
    
    -- Operations counter
    self.opsCounter = Instance.new("TextLabel")
    self.opsCounter.Size = UDim2.new(0, 100, 1, 0)
    self.opsCounter.Position = UDim2.new(0, 350, 0, 0)
    self.opsCounter.BackgroundTransparency = 1
    self.opsCounter.Text = "📊 0 ops"
    self.opsCounter.Font = Constants.UI.THEME.FONTS.BODY
    self.opsCounter.TextSize = 12
    self.opsCounter.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    self.opsCounter.TextXAlignment = Enum.TextXAlignment.Left
    self.opsCounter.Parent = self.statusBar
    
    -- License usage indicator
    self.usageIndicator = Instance.new("TextLabel")
    self.usageIndicator.Size = UDim2.new(1, -470, 1, 0)
    self.usageIndicator.Position = UDim2.new(0, 460, 0, 0)
    self.usageIndicator.BackgroundTransparency = 1
    self.usageIndicator.Text = "💎 0% usage"
    self.usageIndicator.Font = Constants.UI.THEME.FONTS.BODY
    self.usageIndicator.TextSize = 12
    self.usageIndicator.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    self.usageIndicator.TextXAlignment = Enum.TextXAlignment.Right
    self.usageIndicator.Parent = self.statusBar
end

-- Setup modern layout with sidebar navigation
function UIManager:setupModernLayout()
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = self.contentArea
    
    -- Create sidebar
    self:createModernSidebar(mainContainer)
    
    -- Create main content area
    self:createMainContentArea(mainContainer)
    
    -- Show default view
    self:showDataExplorerView()
end

-- Create modern sidebar with feature access indicators
function UIManager:createModernSidebar(parent)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 220, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    sidebar.BorderSizePixel = 1
    sidebar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    sidebar.Parent = parent
    
    -- Navigation container
    local navContainer = Instance.new("ScrollingFrame")
    navContainer.Name = "NavigationContainer"
    navContainer.Size = UDim2.new(1, -10, 1, -20)
    navContainer.Position = UDim2.new(0, 5, 0, 10)
    navContainer.BackgroundTransparency = 1
    navContainer.BorderSizePixel = 0
    navContainer.ScrollBarThickness = 4
    navContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    navContainer.Parent = sidebar
    
    self.navContainer = navContainer
    
    -- Create navigation items with feature access checking
    self:createNavigationItems()
end

-- Create navigation items with license-aware features
function UIManager:createNavigationItems()
    local navItems = {
        {icon = "📊", text = "Data Explorer", feature = "basicDataExplorer", action = "showDataExplorerView"},
        {icon = "🔍", text = "Advanced Search", feature = "advancedSearch", action = "showAdvancedSearchView"},
        {icon = "📈", text = "Analytics", feature = "performanceMonitoring", action = "showAnalyticsView"},
        {icon = "🛡️", text = "Schema Builder", feature = "schemaValidation", action = "showSchemaBuilderView"},
        {icon = "⚡", text = "Bulk Operations", feature = "bulkOperations", action = "showBulkOperationsView"},
        {icon = "👥", text = "Team Features", feature = "teamCollaboration", action = "showTeamFeaturesView"},
        {icon = "⚙️", text = "Settings", feature = "basicDataExplorer", action = "showSettingsView"} -- Settings always available
    }
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = self.navContainer
    
    for i, item in ipairs(navItems) do
        self:createNavItem(item, i)
    end
    
    -- Update canvas size
    self.navContainer.CanvasSize = UDim2.new(0, 0, 0, #navItems * 45)
end

-- Create individual navigation item with license checking
function UIManager:createNavItem(itemData, index)
    local hasAccess = true
    local isUpgradeRequired = false
    
    -- Check license access
    if self.services and self.services["core.licensing.LicenseManager"] then
        local licenseManager = self.services["core.licensing.LicenseManager"]
        hasAccess = licenseManager.hasFeatureAccess(itemData.feature)
        isUpgradeRequired = not hasAccess
    end
    
    local navItem = Instance.new("TextButton")
    navItem.Name = itemData.text:gsub(" ", "")
    navItem.Size = UDim2.new(1, -4, 0, 40)
    navItem.Position = UDim2.new(0, 2, 0, 0)
    navItem.BackgroundColor3 = hasAccess and Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY or Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    navItem.BackgroundTransparency = hasAccess and 1 or 0.8
    navItem.BorderSizePixel = 0
    navItem.Text = ""
    navItem.LayoutOrder = index
    navItem.Parent = self.navContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    corner.Parent = navItem
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.Position = UDim2.new(0, 15, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = itemData.icon
    icon.Font = Constants.UI.THEME.FONTS.BODY
    icon.TextSize = 16
    icon.TextColor3 = hasAccess and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    icon.Parent = navItem
    
    -- Text
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(1, -80, 1, 0)
    text.Position = UDim2.new(0, 50, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = itemData.text
    text.Font = Constants.UI.THEME.FONTS.BODY
    text.TextSize = 13
    text.TextColor3 = hasAccess and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = navItem
    
    -- Access indicator
    if isUpgradeRequired then
        local lockIcon = Instance.new("TextLabel")
        lockIcon.Size = UDim2.new(0, 20, 0, 20)
        lockIcon.Position = UDim2.new(1, -25, 0.5, -10)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Text = "🔒"
        lockIcon.Font = Constants.UI.THEME.FONTS.BODY
        lockIcon.TextSize = 12
        lockIcon.TextColor3 = Constants.UI.THEME.COLORS.WARNING
        lockIcon.Parent = navItem
    end
    
    -- Click handler
    navItem.MouseButton1Click:Connect(function()
        if hasAccess then
            self:setActiveNavItem(navItem, icon, text)
            if self[itemData.action] then
                self[itemData.action](self)
            end
        else
            -- Show upgrade prompt
            if self.services and self.services["core.licensing.LicenseManager"] then
                local licenseManager = self.services["core.licensing.LicenseManager"]
                local upgradePrompt = licenseManager.showUpgradePrompt(itemData.feature, {feature = itemData.text})
                if upgradePrompt then
                    self:showUpgradeDialog(upgradePrompt)
                end
            end
        end
    end)
    
    -- Hover effects (only for accessible items)
    if hasAccess then
        navItem.MouseEnter:Connect(function()
            navItem.BackgroundTransparency = 0.8
            navItem.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
        end)
        
        navItem.MouseLeave:Connect(function()
            if navItem ~= self.currentNavItem then
                navItem.BackgroundTransparency = 1
            end
        end)
    end
end

-- Create main content area
function UIManager:createMainContentArea(parent)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "MainContentArea"
    contentArea.Size = UDim2.new(1, -220, 1, 0)
    contentArea.Position = UDim2.new(0, 220, 0, 0)
    contentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    contentArea.BorderSizePixel = 0
    contentArea.Parent = parent
    
    self.mainContentArea = contentArea
end

-- Initialize feature integrations
function UIManager:initializeIntegrations()
    -- Setup real-time status updates
    self:setupStatusUpdates()
    
    -- Initialize search integration
    self:initializeSearchIntegration()
    
    -- Initialize analytics integration
    self:initializeAnalyticsIntegration()
    
    debugLog("Feature integrations initialized")
end

-- Setup real-time status updates
function UIManager:setupStatusUpdates()
    -- Update status every 5 seconds
    spawn(function()
        while self.initialized do
            self:updateRealTimeStatus()
            wait(5)
        end
    end)
end

-- Update real-time status indicators
function UIManager:updateRealTimeStatus()
    -- Update license badge
    self:updateLicenseBadge()
    
    -- Update performance metrics
    if self.services and self.services["features.analytics.PerformanceAnalyzer"] then
        local perfAnalyzer = self.services["features.analytics.PerformanceAnalyzer"]
        local summaryReport = perfAnalyzer:generateSummaryReport()
        
        -- Update performance indicator
        if summaryReport.averageLatency then
            local latencyColor = Constants.UI.THEME.COLORS.SUCCESS
            if summaryReport.averageLatency > 100 then
                latencyColor = Constants.UI.THEME.COLORS.ERROR
            elseif summaryReport.averageLatency > 50 then
                latencyColor = Constants.UI.THEME.COLORS.WARNING
            end
            
            self.perfIndicator.Text = string.format("⚡ %.1fms", summaryReport.averageLatency)
            self.perfIndicator.TextColor3 = latencyColor
        end
        
        -- Update operations counter
        if summaryReport.totalOperations then
            self.opsCounter.Text = string.format("📊 %d ops", summaryReport.totalOperations)
        end
    end
    
    -- Update license usage
    if self.services and self.services["core.licensing.LicenseManager"] then
        local licenseManager = self.services["core.licensing.LicenseManager"]
        local usageStats = licenseManager.getUsageStatistics()
        
        if usageStats.utilizationRate then
            local maxUtilization = math.max(
                usageStats.utilizationRate.operations or 0,
                usageStats.utilizationRate.dataStores or 0
            )
            
            local usageColor = Constants.UI.THEME.COLORS.SUCCESS
            if maxUtilization > 0.8 then
                usageColor = Constants.UI.THEME.COLORS.ERROR
            elseif maxUtilization > 0.6 then
                usageColor = Constants.UI.THEME.COLORS.WARNING
            end
            
            self.usageIndicator.Text = string.format("💎 %.0f%% usage", maxUtilization * 100)
            self.usageIndicator.TextColor3 = usageColor
        end
    end
end

-- Initialize search integration
function UIManager:initializeSearchIntegration()
    -- This will be called when search interface is created
    debugLog("Search integration ready")
end

-- Initialize analytics integration  
function UIManager:initializeAnalyticsIntegration()
    -- This will be called when analytics interface is created
    debugLog("Analytics integration ready")
end

-- Set active navigation item
function UIManager:setActiveNavItem(navItem, iconLabel, textLabel)
    -- Reset all nav items
    for _, child in ipairs(self.navContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundTransparency = 1
            local icon = child:FindFirstChild("Icon")
            local text = child:FindFirstChild("Text")
            if icon then icon.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY end
            if text then text.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY end
        end
    end
    
    -- Set active state
    navItem.BackgroundTransparency = 0
    navItem.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE
    iconLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    textLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    
    self.currentNavItem = navItem
    debugLog("Switched to: " .. textLabel.Text)
end

-- View switching methods
function UIManager:showDataExplorerView()
    self:clearMainContent()
    self:createDataExplorerInterface()
end

function UIManager:showAdvancedSearchView()
    self:clearMainContent()
    self:createAdvancedSearchInterface()
end

function UIManager:showAnalyticsView()
    self:clearMainContent()
    self:createAnalyticsDashboard()
end

function UIManager:showSchemaBuilderView()
    self:clearMainContent()
    self:createPlaceholderView("🛡️ Schema Builder", "Define and validate DataStore schemas (Professional feature)")
end

function UIManager:showBulkOperationsView()
    self:clearMainContent()
    self:createPlaceholderView("⚡ Bulk Operations", "Batch edit, delete, and export operations (Professional feature)")
end

function UIManager:showTeamFeaturesView()
    self:clearMainContent()
    self:createPlaceholderView("👥 Team Features", "Collaboration and access management (Enterprise feature)")
end

function UIManager:showSettingsView()
    self:clearMainContent()
    self:createSettingsInterface()
end

-- Clear main content area
function UIManager:clearMainContent()
    if not self.mainContentArea then return end
    
    for _, child in ipairs(self.mainContentArea:GetChildren()) do
        child:Destroy()
    end
end

-- Create placeholder view for premium features
function UIManager:createPlaceholderView(title, description)
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    header.BorderSizePixel = 0
    header.Parent = self.mainContentArea
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -80)
    content.Position = UDim2.new(0, 0, 0, 80)
    content.BackgroundTransparency = 1
    content.Parent = self.mainContentArea
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -40, 0, 100)
    descLabel.Position = UDim2.new(0, 20, 0, 20)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.Font = Constants.UI.THEME.FONTS.BODY
    descLabel.TextSize = 16
    descLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextWrapped = true
    descLabel.Parent = content
end

-- Refresh interface
function UIManager:refresh()
    debugLog("Refreshing integrated UI")
    self:updateRealTimeStatus()
    self:updateLicenseBadge()
end

-- Show notification with enhanced styling
function UIManager:showNotification(message, type)
    type = type or "INFO"
    
    local color = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    local prefix = "ℹ️"
    
    if type == "WARNING" then
        color = Constants.UI.THEME.COLORS.WARNING
        prefix = "⚠️"
    elseif type == "ERROR" then
        color = Constants.UI.THEME.COLORS.ERROR
        prefix = "❌"
    elseif type == "SUCCESS" then
        color = Constants.UI.THEME.COLORS.SUCCESS
        prefix = "✅"
    end
    
    self.statusLabel.Text = prefix .. " " .. message
    self.statusLabel.TextColor3 = color
    
    -- Clear after 5 seconds
    spawn(function()
        wait(5)
        self.statusLabel.Text = "🟢 Ready"
        self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    end)
    
    debugLog("Notification: " .. message .. " (" .. type .. ")")
end

-- Cleanup
function UIManager:destroy()
    debugLog("Destroying Integrated UI Manager")
    
    self.initialized = false
    
    if self.mainFrame then
        self.mainFrame:Destroy()
        self.mainFrame = nil
    end
    
    -- Clear all references
    self.components = {}
    self.services = {}
    
    debugLog("Integrated UI Manager destroyed")
end

-- Include additional methods from the base UIManager for interface creation
-- These would include createDataExplorerInterface, createAdvancedSearchInterface, 
-- createAnalyticsDashboard, etc. from the previous implementation

return UIManager 