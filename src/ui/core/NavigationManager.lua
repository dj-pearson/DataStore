-- DataStore Manager Pro - Navigation Manager
-- Manages sidebar navigation and tab systems

local NavigationManager = {}
NavigationManager.__index = NavigationManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[NAVIGATION_MANAGER] [%s] %s", level, message))
end

-- Create new Navigation Manager instance
function NavigationManager.new(uiManager)
    local self = setmetatable({}, NavigationManager)
    
    self.uiManager = uiManager
    self.currentNavItem = nil
    self.navContainer = nil
    self.currentTab = nil
    
    debugLog("NavigationManager created")
    return self
end

-- Create sidebar navigation
function NavigationManager:createSidebarNavigation(parent)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, Constants.UI.THEME.SIZES.SIDEBAR_WIDTH, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_BACKGROUND
    sidebar.BorderSizePixel = 0
    sidebar.Parent = parent
    
    self.sidebar = sidebar
    
    -- Sidebar header
    local sidebarHeader = Instance.new("Frame")
    sidebarHeader.Name = "Header"
    sidebarHeader.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    sidebarHeader.Position = UDim2.new(0, 0, 0, 0)
    sidebarHeader.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_BACKGROUND
    sidebarHeader.BorderSizePixel = 0
    sidebarHeader.Parent = sidebar
    
    -- Plugin title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 1, 0)
    titleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "DataStore Manager Pro"
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = sidebarHeader
    
    -- Navigation items container (ScrollingFrame)
    local navContainer = Instance.new("ScrollingFrame")
    navContainer.Name = "Navigation"
    navContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    navContainer.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    navContainer.BackgroundTransparency = 1
    navContainer.BorderSizePixel = 0
    navContainer.ScrollBarThickness = 6
    navContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    navContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navContainer.Parent = sidebar
    
    -- Add UIListLayout for vertical stacking
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = navContainer
    
    -- Add UIPadding for top/bottom/side spacing
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = navContainer
    
    self.navContainer = navContainer
    
    -- Create navigation items (all tabs, including Settings)
    self:createNavigationItems()
    
    return sidebar
end

-- Create navigation items
function NavigationManager:createNavigationItems()
    local navItems = {
        {icon = "🗂️", text = "Data Explorer", callback = function() self.uiManager:showDataExplorerView() end},
        {icon = "🔍", text = "Advanced Search", callback = function() self.uiManager:showAdvancedSearchView() end},
        {icon = "📊", text = "Analytics", callback = function() self.uiManager:showAnalyticsView() end},
        {icon = "⚡", text = "Real-Time Monitor", callback = function() self.uiManager:showRealTimeMonitorView() end},
        {icon = "📈", text = "Data Visualization", callback = function() self.uiManager:showDataVisualizationView() end},
        {icon = "👥", text = "Team Collaboration", callback = function() self.uiManager:showTeamCollaborationView() end},
        {icon = "🏗️", text = "Schema Builder", callback = function() self.uiManager:showSchemaBuilderView() end},
        {icon = "👥", text = "Sessions", callback = function() self.uiManager:showSessionsView() end},
        {icon = "🔒", text = "Security", callback = function() self.uiManager:showSecurityView() end},
        {icon = "🏢", text = "Enterprise", callback = function() self.uiManager:showEnterpriseView() end},
        {icon = "🔗", text = "Integrations", callback = function() self.uiManager:showIntegrationsView() end},
        {icon = "⚙️", text = "Settings", callback = function() self.uiManager:showSettingsView() end},
    }
    
    for i, item in ipairs(navItems) do
        self:createNavItem(self.navContainer, item.icon, item.text, i == 1, item.callback)
    end
end

-- Create navigation item
function NavigationManager:createNavItem(parent, icon, text, isActive, callback)
    local navItem = Instance.new("TextButton")
    navItem.Name = text:gsub("%s+", "") .. "NavItem"
    navItem.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.BUTTON_HEIGHT)
    navItem.BackgroundColor3 = isActive and Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE or Color3.fromRGB(0, 0, 0)
    navItem.BackgroundTransparency = isActive and 0 or 1
    navItem.BorderSizePixel = 0
    navItem.Text = ""
    navItem.LayoutOrder = 0
    navItem.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    corner.Parent = navItem
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_MEDIUM, 1, 0)
    iconLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.Font = Constants.UI.THEME.FONTS.UI
    iconLabel.TextSize = Constants.UI.THEME.SIZES.ICON_MEDIUM
    iconLabel.TextColor3 = isActive and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.Parent = navItem
    
    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -Constants.UI.THEME.SIZES.ICON_MEDIUM - Constants.UI.THEME.SPACING.MEDIUM * 2, 1, 0)
    textLabel.Position = UDim2.new(0, Constants.UI.THEME.SIZES.ICON_MEDIUM + Constants.UI.THEME.SPACING.MEDIUM * 2, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.Font = Constants.UI.THEME.FONTS.UI
    textLabel.TextSize = 13
    textLabel.TextColor3 = isActive and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = navItem
    
    -- Hover effects
    navItem.MouseEnter:Connect(function()
        if navItem ~= self.currentNavItem then
            navItem.BackgroundTransparency = 0.8
            navItem.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
        end
    end)
    
    navItem.MouseLeave:Connect(function()
        if navItem ~= self.currentNavItem then
            navItem.BackgroundTransparency = 1
        end
    end)
    
    -- Click handler
    navItem.MouseButton1Click:Connect(function()
        self:setActiveNavItem(navItem, iconLabel, textLabel)
        callback()
    end)
    
    -- Set as current if active
    if isActive then
        self.currentNavItem = navItem
    end
end

-- Set active navigation item
function NavigationManager:setActiveNavItem(navItem, iconLabel, textLabel)
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
    
    -- Set active item
    navItem.BackgroundTransparency = 0
    navItem.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE
    iconLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    textLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.currentNavItem = navItem
end

-- Create tab system
function NavigationManager:createTabSystem(parent)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 1, 0)
    tabContainer.Position = UDim2.new(0, 0, 0, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = parent
    
    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TAB_HEIGHT)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    tabBar.BorderSizePixel = 0
    tabBar.Parent = tabContainer
    
    -- Tab content area
    local tabContentArea = Instance.new("Frame")
    tabContentArea.Name = "TabContentArea"
    tabContentArea.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TAB_HEIGHT)
    tabContentArea.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TAB_HEIGHT)
    tabContentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    tabContentArea.BorderSizePixel = 0
    tabContentArea.Parent = tabContainer
    
    self.tabBar = tabBar
    self.tabContentArea = tabContentArea
    
    return tabContainer
end

-- Create tab
function NavigationManager:createTab(tabBar, name, icon, callback, isActive)
    local existingTabs = {}
    for _, child in ipairs(tabBar:GetChildren()) do
        if child:IsA("TextButton") then
            table.insert(existingTabs, child)
        end
    end
    
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "Tab"
    tabButton.Size = UDim2.new(0, 150, 1, 0)
    tabButton.Position = UDim2.new(0, #existingTabs * 150, 0, 0)
    tabButton.BackgroundColor3 = isActive and Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY or Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    tabButton.BorderSizePixel = 0
    tabButton.Text = icon .. " " .. name
    tabButton.Font = Constants.UI.THEME.FONTS.UI
    tabButton.TextSize = 13
    tabButton.TextColor3 = isActive and Constants.UI.THEME.COLORS.TEXT_PRIMARY or Constants.UI.THEME.COLORS.TEXT_SECONDARY
    tabButton.Parent = tabBar
    
    -- Click handler
    tabButton.MouseButton1Click:Connect(function()
        self:setActiveTab(tabButton, name)
        callback()
    end)
    
    if isActive then
        self.currentTab = tabButton
    end
    
    return tabButton
end

-- Set active tab
function NavigationManager:setActiveTab(tabButton, tabName)
    -- Reset all tabs
    for _, child in ipairs(self.tabBar:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
            child.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        end
    end
    
    -- Set active tab
    tabButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    tabButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.currentTab = tabButton
    
    debugLog("Tab activated: " .. tabName)
end

-- Clear tab content
function NavigationManager:clearTabContent()
    if self.tabContentArea then
        for _, child in ipairs(self.tabContentArea:GetChildren()) do
            child:Destroy()
        end
    end
end

return NavigationManager 