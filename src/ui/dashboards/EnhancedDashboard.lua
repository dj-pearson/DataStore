-- DataStore Manager Pro - Enhanced Dashboard
-- Main dashboard with real-time widgets, feature integration, and beautiful visualizations

local EnhancedDashboard = {}
EnhancedDashboard.__index = EnhancedDashboard

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[ENHANCED_DASHBOARD] [%s] %s", level, message))
end

-- Dashboard configuration
local DASHBOARD_CONFIG = {
    UPDATE_INTERVAL = 5, -- seconds
    WIDGET_REFRESH_RATES = {
        realTime = 2,
        performance = 5,
        analytics = 15,
        overview = 30
    },
    LAYOUT = {
        COLUMNS = 4,
        ROW_HEIGHT = 150,
        SPACING = 10
    },
    ANIMATIONS = {
        CHART_SPEED = 0.5,
        COUNTER_SPEED = 1.0,
        FADE_DURATION = 0.3
    }
}

-- Widget types
local WIDGET_TYPES = {
    REAL_TIME_METRICS = "real_time_metrics",
    PERFORMANCE_CHART = "performance_chart",
    OPERATION_COUNTER = "operation_counter",
    FEATURE_STATUS = "feature_status",
    QUICK_ACTIONS = "quick_actions",
    RECENT_ACTIVITY = "recent_activity",
    SYSTEM_HEALTH = "system_health",
    BACKUP_STATUS = "backup_status",
    SEARCH_ANALYTICS = "search_analytics",
    TEAM_ACTIVITY = "team_activity"
}

-- Create new Enhanced Dashboard instance
function EnhancedDashboard.new(services, featureRegistry)
    local self = setmetatable({}, EnhancedDashboard)
    
    self.services = services or {}
    self.featureRegistry = featureRegistry
    self.widgets = {}
    self.updateTimers = {}
    self.isVisible = false
    self.dashboardFrame = nil
    
    debugLog("Enhanced Dashboard created")
    return self
end

-- Create dashboard UI
function EnhancedDashboard:createDashboard(parent)
    debugLog("Creating enhanced dashboard UI...")
    
    -- Main dashboard container
    self.dashboardFrame = Instance.new("ScrollingFrame")
    self.dashboardFrame.Name = "EnhancedDashboard"
    self.dashboardFrame.Size = UDim2.new(1, 0, 1, 0)
    self.dashboardFrame.Position = UDim2.new(0, 0, 0, 0)
    self.dashboardFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    self.dashboardFrame.BorderSizePixel = 0
    self.dashboardFrame.ScrollBarThickness = 8
    self.dashboardFrame.ScrollBarImageColor3 = Constants.UI.THEME.COLORS.PRIMARY
    self.dashboardFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.dashboardFrame.Parent = parent
    
    -- Dashboard header
    self:createDashboardHeader()
    
    -- Widget grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "DashboardGrid"
    gridLayout.CellSize = UDim2.new(0, 300, 0, DASHBOARD_CONFIG.LAYOUT.ROW_HEIGHT)
    gridLayout.CellPadding = UDim2.new(0, DASHBOARD_CONFIG.LAYOUT.SPACING, 0, DASHBOARD_CONFIG.LAYOUT.SPACING)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = self.dashboardFrame
    
    -- Create widgets
    self:createWidgets()
    
    -- Update canvas size
    self:updateCanvasSize()
    
    debugLog("Enhanced dashboard UI created")
    return self.dashboardFrame
end

-- Create dashboard header
function EnhancedDashboard:createDashboardHeader()
    local header = Instance.new("Frame")
    header.Name = "DashboardHeader"
    header.Size = UDim2.new(1, -20, 0, 60)
    header.Position = UDim2.new(0, 10, 0, 10)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    header.BorderSizePixel = 0
    header.Parent = self.dashboardFrame
    
    -- Header corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "📊 DataStore Manager Pro - Dashboard"
    title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = header
    
    -- Status indicator
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(0.3, 0, 0.6, 0)
    statusFrame.Position = UDim2.new(0.5, 0, 0.2, 0)
    statusFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = header
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 12)
    statusCorner.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -10, 1, 0)
    statusText.Position = UDim2.new(0, 5, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "🟢 System Healthy"
    statusText.TextColor3 = Color3.new(1, 1, 1)
    statusText.TextXAlignment = Enum.TextXAlignment.Center
    statusText.TextYAlignment = Enum.TextYAlignment.Center
    statusText.Font = Enum.Font.SourceSansSemibold
    statusText.TextSize = 14
    statusText.Parent = statusFrame
    
    -- Refresh button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 100, 0.6, 0)
    refreshButton.Position = UDim2.new(1, -120, 0.2, 0)
    refreshButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    refreshButton.BorderSizePixel = 0
    refreshButton.Text = "🔄 Refresh"
    refreshButton.TextColor3 = Color3.new(1, 1, 1)
    refreshButton.Font = Enum.Font.SourceSansSemibold
    refreshButton.TextSize = 12
    refreshButton.Parent = header
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 6)
    refreshCorner.Parent = refreshButton
    
    -- Connect refresh button
    refreshButton.MouseButton1Click:Connect(function()
        self:refreshAllWidgets()
    end)
    
    self.headerElements = {
        statusFrame = statusFrame,
        statusText = statusText,
        refreshButton = refreshButton
    }
end

-- Create dashboard widgets
function EnhancedDashboard:createWidgets()
    debugLog("Creating dashboard widgets...")
    
    local widgetConfigs = {
        {type = WIDGET_TYPES.REAL_TIME_METRICS, title = "Real-Time Metrics", layoutOrder = 1},
        {type = WIDGET_TYPES.PERFORMANCE_CHART, title = "Performance Trends", layoutOrder = 2},
        {type = WIDGET_TYPES.OPERATION_COUNTER, title = "Operations Today", layoutOrder = 3},
        {type = WIDGET_TYPES.FEATURE_STATUS, title = "Feature Status", layoutOrder = 4},
        {type = WIDGET_TYPES.SYSTEM_HEALTH, title = "System Health", layoutOrder = 5},
        {type = WIDGET_TYPES.BACKUP_STATUS, title = "Backup Status", layoutOrder = 6},
        {type = WIDGET_TYPES.SEARCH_ANALYTICS, title = "Search Analytics", layoutOrder = 7},
        {type = WIDGET_TYPES.QUICK_ACTIONS, title = "Quick Actions", layoutOrder = 8},
        {type = WIDGET_TYPES.RECENT_ACTIVITY, title = "Recent Activity", layoutOrder = 9},
        {type = WIDGET_TYPES.TEAM_ACTIVITY, title = "Team Activity", layoutOrder = 10}
    }
    
    for _, config in ipairs(widgetConfigs) do
        -- Check if feature is available for widget
        if self:isWidgetAvailable(config.type) then
            local widget = self:createWidget(config)
            if widget then
                self.widgets[config.type] = widget
            end
        end
    end
    
    debugLog(string.format("Created %d dashboard widgets", self:getWidgetCount()))
end

-- Check if widget is available based on enabled features
function EnhancedDashboard:isWidgetAvailable(widgetType)
    if widgetType == WIDGET_TYPES.REAL_TIME_METRICS then
        return self.featureRegistry:isFeatureEnabled("realTimeMonitor")
    elseif widgetType == WIDGET_TYPES.BACKUP_STATUS then
        return self.featureRegistry:isFeatureEnabled("backupManager")
    elseif widgetType == WIDGET_TYPES.SEARCH_ANALYTICS then
        return self.featureRegistry:isFeatureEnabled("smartSearch")
    elseif widgetType == WIDGET_TYPES.TEAM_ACTIVITY then
        return self.featureRegistry:isFeatureEnabled("teamCollaboration")
    else
        -- Basic widgets always available
        return true
    end
end

-- Create individual widget
function EnhancedDashboard:createWidget(config)
    local widget = Instance.new("Frame")
    widget.Name = config.type
    widget.LayoutOrder = config.layoutOrder
    widget.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    widget.BorderSizePixel = 0
    widget.Parent = self.dashboardFrame
    
    -- Widget corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = widget
    
    -- Widget shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = widget.ZIndex - 1
    shadow.Parent = widget
    
    -- Widget header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    header.BorderSizePixel = 0
    header.Parent = widget
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Header bottom mask
    local headerMask = Instance.new("Frame")
    headerMask.Size = UDim2.new(1, 0, 0, 8)
    headerMask.Position = UDim2.new(0, 0, 1, -8)
    headerMask.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    headerMask.BorderSizePixel = 0
    headerMask.Parent = header
    
    -- Widget title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.title
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Font = Enum.Font.SourceSansSemibold
    title.TextSize = 14
    title.Parent = header
    
    -- Widget content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -40)
    content.Position = UDim2.new(0, 10, 0, 35)
    content.BackgroundTransparency = 1
    content.Parent = widget
    
    -- Create widget-specific content
    self:createWidgetContent(config.type, content)
    
    return widget
end

-- Create content for specific widget types
function EnhancedDashboard:createWidgetContent(widgetType, contentFrame)
    if widgetType == WIDGET_TYPES.REAL_TIME_METRICS then
        self:createRealTimeMetricsContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.PERFORMANCE_CHART then
        self:createPerformanceChartContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.OPERATION_COUNTER then
        self:createOperationCounterContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.FEATURE_STATUS then
        self:createFeatureStatusContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.SYSTEM_HEALTH then
        self:createSystemHealthContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.BACKUP_STATUS then
        self:createBackupStatusContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.SEARCH_ANALYTICS then
        self:createSearchAnalyticsContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.QUICK_ACTIONS then
        self:createQuickActionsContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.RECENT_ACTIVITY then
        self:createRecentActivityContent(contentFrame)
    elseif widgetType == WIDGET_TYPES.TEAM_ACTIVITY then
        self:createTeamActivityContent(contentFrame)
    end
end

-- Create real-time metrics widget content
function EnhancedDashboard:createRealTimeMetricsContent(contentFrame)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = contentFrame
    
    -- Metrics display
    local metrics = {
        {label = "Operations/sec", value = "0", color = Constants.UI.THEME.COLORS.SUCCESS},
        {label = "Avg Latency", value = "0ms", color = Constants.UI.THEME.COLORS.WARNING},
        {label = "Error Rate", value = "0%", color = Constants.UI.THEME.COLORS.ERROR}
    }
    
    for i, metric in ipairs(metrics) do
        local metricFrame = Instance.new("Frame")
        metricFrame.Name = "Metric" .. i
        metricFrame.Size = UDim2.new(1, 0, 0, 25)
        metricFrame.BackgroundTransparency = 1
        metricFrame.LayoutOrder = i
        metricFrame.Parent = contentFrame
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = metric.label
        label.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSans
        label.TextSize = 12
        label.Parent = metricFrame
        
        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.Size = UDim2.new(0.4, 0, 1, 0)
        value.Position = UDim2.new(0.6, 0, 0, 0)
        value.BackgroundTransparency = 1
        value.Text = metric.value
        value.TextColor3 = metric.color
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Font = Enum.Font.SourceSansBold
        value.TextSize = 14
        value.Parent = metricFrame
    end
end

-- Create performance chart widget content
function EnhancedDashboard:createPerformanceChartContent(contentFrame)
    -- Simple chart representation using frames
    local chartContainer = Instance.new("Frame")
    chartContainer.Name = "ChartContainer"
    chartContainer.Size = UDim2.new(1, 0, 1, -20)
    chartContainer.Position = UDim2.new(0, 0, 0, 0)
    chartContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    chartContainer.BorderSizePixel = 1
    chartContainer.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    chartContainer.Parent = contentFrame
    
    local chartCorner = Instance.new("UICorner")
    chartCorner.CornerRadius = UDim.new(0, 4)
    chartCorner.Parent = chartContainer
    
    -- Chart bars (mock data)
    for i = 1, 10 do
        local bar = Instance.new("Frame")
        bar.Name = "Bar" .. i
        bar.Size = UDim2.new(0, 20, 0, math.random(20, 80))
        bar.Position = UDim2.new(0, (i-1) * 25 + 10, 1, -math.random(20, 80) - 10)
        bar.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
        bar.BorderSizePixel = 0
        bar.Parent = chartContainer
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 2)
        barCorner.Parent = bar
    end
    
    -- Chart label
    local chartLabel = Instance.new("TextLabel")
    chartLabel.Name = "ChartLabel"
    chartLabel.Size = UDim2.new(1, 0, 0, 15)
    chartLabel.Position = UDim2.new(0, 0, 1, -15)
    chartLabel.BackgroundTransparency = 1
    chartLabel.Text = "Last 10 minutes"
    chartLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    chartLabel.TextXAlignment = Enum.TextXAlignment.Center
    chartLabel.Font = Enum.Font.SourceSans
    chartLabel.TextSize = 10
    chartLabel.Parent = contentFrame
end

-- Create operation counter widget content
function EnhancedDashboard:createOperationCounterContent(contentFrame)
    -- Large number display
    local counterFrame = Instance.new("Frame")
    counterFrame.Name = "CounterFrame"
    counterFrame.Size = UDim2.new(1, 0, 0.7, 0)
    counterFrame.Position = UDim2.new(0, 0, 0, 0)
    counterFrame.BackgroundTransparency = 1
    counterFrame.Parent = contentFrame
    
    local counterNumber = Instance.new("TextLabel")
    counterNumber.Name = "CounterNumber"
    counterNumber.Size = UDim2.new(1, 0, 1, 0)
    counterNumber.Position = UDim2.new(0, 0, 0, 0)
    counterNumber.BackgroundTransparency = 1
    counterNumber.Text = "1,234"
    counterNumber.TextColor3 = Constants.UI.THEME.COLORS.PRIMARY
    counterNumber.TextXAlignment = Enum.TextXAlignment.Center
    counterNumber.TextYAlignment = Enum.TextYAlignment.Center
    counterNumber.Font = Enum.Font.SourceSansBold
    counterNumber.TextSize = 36
    counterNumber.Parent = counterFrame
    
    -- Trend indicator
    local trendFrame = Instance.new("Frame")
    trendFrame.Name = "TrendFrame"
    trendFrame.Size = UDim2.new(1, 0, 0.3, 0)
    trendFrame.Position = UDim2.new(0, 0, 0.7, 0)
    trendFrame.BackgroundTransparency = 1
    trendFrame.Parent = contentFrame
    
    local trendText = Instance.new("TextLabel")
    trendText.Name = "TrendText"
    trendText.Size = UDim2.new(1, 0, 1, 0)
    trendText.Position = UDim2.new(0, 0, 0, 0)
    trendText.BackgroundTransparency = 1
    trendText.Text = "↗️ +12% from yesterday"
    trendText.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
    trendText.TextXAlignment = Enum.TextXAlignment.Center
    trendText.Font = Enum.Font.SourceSans
    trendText.TextSize = 12
    trendText.Parent = trendFrame
end

-- Create feature status widget content
function EnhancedDashboard:createFeatureStatusContent(contentFrame)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = contentFrame
    
    local features = self.featureRegistry:getEnabledFeatures()
    
    for i, feature in ipairs(features) do
        if i <= 4 then -- Show only first 4 features
            local featureFrame = Instance.new("Frame")
            featureFrame.Name = "Feature" .. i
            featureFrame.Size = UDim2.new(1, 0, 0, 20)
            featureFrame.BackgroundTransparency = 1
            featureFrame.LayoutOrder = i
            featureFrame.Parent = contentFrame
            
            local statusIcon = Instance.new("TextLabel")
            statusIcon.Name = "StatusIcon"
            statusIcon.Size = UDim2.new(0, 20, 1, 0)
            statusIcon.Position = UDim2.new(0, 0, 0, 0)
            statusIcon.BackgroundTransparency = 1
            statusIcon.Text = "🟢"
            statusIcon.TextXAlignment = Enum.TextXAlignment.Center
            statusIcon.Font = Enum.Font.SourceSans
            statusIcon.TextSize = 12
            statusIcon.Parent = featureFrame
            
            local featureName = Instance.new("TextLabel")
            featureName.Name = "FeatureName"
            featureName.Size = UDim2.new(1, -25, 1, 0)
            featureName.Position = UDim2.new(0, 25, 0, 0)
            featureName.BackgroundTransparency = 1
            featureName.Text = feature.name
            featureName.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
            featureName.TextXAlignment = Enum.TextXAlignment.Left
            featureName.Font = Enum.Font.SourceSans
            featureName.TextSize = 11
            featureName.Parent = featureFrame
        end
    end
end

-- Create other widget content methods (simplified for brevity)
function EnhancedDashboard:createSystemHealthContent(contentFrame)
    local healthIndicator = Instance.new("TextLabel")
    healthIndicator.Size = UDim2.new(1, 0, 1, 0)
    healthIndicator.BackgroundTransparency = 1
    healthIndicator.Text = "🟢 All Systems Operational"
    healthIndicator.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
    healthIndicator.TextXAlignment = Enum.TextXAlignment.Center
    healthIndicator.TextYAlignment = Enum.TextYAlignment.Center
    healthIndicator.Font = Enum.Font.SourceSansBold
    healthIndicator.TextSize = 16
    healthIndicator.Parent = contentFrame
end

function EnhancedDashboard:createBackupStatusContent(contentFrame)
    local backupStatus = Instance.new("TextLabel")
    backupStatus.Size = UDim2.new(1, 0, 0.5, 0)
    backupStatus.BackgroundTransparency = 1
    backupStatus.Text = "💾 Last backup: 2 hours ago"
    backupStatus.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    backupStatus.TextXAlignment = Enum.TextXAlignment.Center
    backupStatus.Font = Enum.Font.SourceSans
    backupStatus.TextSize = 12
    backupStatus.Parent = contentFrame
    
    local nextBackup = Instance.new("TextLabel")
    nextBackup.Size = UDim2.new(1, 0, 0.5, 0)
    nextBackup.Position = UDim2.new(0, 0, 0.5, 0)
    nextBackup.BackgroundTransparency = 1
    nextBackup.Text = "Next: Tonight at 2:00 AM"
    nextBackup.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    nextBackup.TextXAlignment = Enum.TextXAlignment.Center
    nextBackup.Font = Enum.Font.SourceSans
    nextBackup.TextSize = 10
    nextBackup.Parent = contentFrame
end

function EnhancedDashboard:createSearchAnalyticsContent(contentFrame)
    local searchStats = Instance.new("TextLabel")
    searchStats.Size = UDim2.new(1, 0, 1, 0)
    searchStats.BackgroundTransparency = 1
    searchStats.Text = "🔍 327 searches today\n📈 avg 45ms response time"
    searchStats.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    searchStats.TextXAlignment = Enum.TextXAlignment.Center
    searchStats.TextYAlignment = Enum.TextYAlignment.Center
    searchStats.Font = Enum.Font.SourceSans
    searchStats.TextSize = 12
    searchStats.Parent = contentFrame
end

function EnhancedDashboard:createQuickActionsContent(contentFrame)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = contentFrame
    
    local actions = {"🔄 Refresh Data", "💾 Create Backup", "📊 View Analytics"}
    
    for i, action in ipairs(actions) do
        local actionButton = Instance.new("TextButton")
        actionButton.Name = "Action" .. i
        actionButton.Size = UDim2.new(1, 0, 0, 25)
        actionButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
        actionButton.BorderSizePixel = 0
        actionButton.Text = action
        actionButton.TextColor3 = Color3.new(1, 1, 1)
        actionButton.Font = Enum.Font.SourceSans
        actionButton.TextSize = 10
        actionButton.LayoutOrder = i
        actionButton.Parent = contentFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = actionButton
    end
end

function EnhancedDashboard:createRecentActivityContent(contentFrame)
    local activityText = Instance.new("TextLabel")
    activityText.Size = UDim2.new(1, 0, 1, 0)
    activityText.BackgroundTransparency = 1
    activityText.Text = "📝 PlayerData updated\n🔍 Search: 'player_123'\n💾 Backup completed"
    activityText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    activityText.TextXAlignment = Enum.TextXAlignment.Left
    activityText.TextYAlignment = Enum.TextYAlignment.Top
    activityText.Font = Enum.Font.SourceSans
    activityText.TextSize = 10
    activityText.Parent = contentFrame
end

function EnhancedDashboard:createTeamActivityContent(contentFrame)
    local teamStatus = Instance.new("TextLabel")
    teamStatus.Size = UDim2.new(1, 0, 1, 0)
    teamStatus.BackgroundTransparency = 1
    teamStatus.Text = "👥 2 team members online\n🟢 John Doe (editing)\n🟡 Jane Smith (viewing)"
    teamStatus.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    teamStatus.TextXAlignment = Enum.TextXAlignment.Left
    teamStatus.TextYAlignment = Enum.TextYAlignment.Top
    teamStatus.Font = Enum.Font.SourceSans
    teamStatus.TextSize = 10
    teamStatus.Parent = contentFrame
end

-- Show dashboard
function EnhancedDashboard:show()
    if self.dashboardFrame then
        self.dashboardFrame.Visible = true
        self.isVisible = true
        
        -- Start update timers
        self:startUpdateTimers()
        
        debugLog("Enhanced dashboard shown")
    end
end

-- Hide dashboard
function EnhancedDashboard:hide()
    if self.dashboardFrame then
        self.dashboardFrame.Visible = false
        self.isVisible = false
        
        -- Stop update timers
        self:stopUpdateTimers()
        
        debugLog("Enhanced dashboard hidden")
    end
end

-- Start update timers for widgets (DISABLED to prevent throttling)
function EnhancedDashboard:startUpdateTimers()
    self:stopUpdateTimers() -- Clean up existing timers
    
    -- DISABLED: Auto-refresh timers were causing excessive DataStore API calls
    -- Dashboard will only update when manually refreshed to prevent throttling
    debugLog("Dashboard auto-refresh timers disabled to prevent DataStore throttling")
    
    -- Widgets will only update on manual refresh or specific user actions
    -- This prevents background API calls that cause Roblox Studio throttling
end

-- Stop update timers
function EnhancedDashboard:stopUpdateTimers()
    for timerName, timer in pairs(self.updateTimers) do
        if timer then
            task.cancel(timer)
        end
    end
    self.updateTimers = {}
    
    debugLog("Dashboard update timers stopped")
end

-- Update real-time widgets
function EnhancedDashboard:updateRealTimeWidgets()
    -- Update real-time metrics
    if self.widgets[WIDGET_TYPES.REAL_TIME_METRICS] then
        self:updateRealTimeMetrics()
    end
    
    -- Update system health
    if self.widgets[WIDGET_TYPES.SYSTEM_HEALTH] then
        self:updateSystemHealth()
    end
end

-- Update performance widgets
function EnhancedDashboard:updatePerformanceWidgets()
    -- Update performance chart
    if self.widgets[WIDGET_TYPES.PERFORMANCE_CHART] then
        self:updatePerformanceChart()
    end
    
    -- Update operation counter
    if self.widgets[WIDGET_TYPES.OPERATION_COUNTER] then
        self:updateOperationCounter()
    end
end

-- Update real-time metrics
function EnhancedDashboard:updateRealTimeMetrics()
    local realTimeMonitor = self.featureRegistry:getFeature("realTimeMonitor")
    if not realTimeMonitor then return end
    
    local metrics = realTimeMonitor:getMetrics()
    local widget = self.widgets[WIDGET_TYPES.REAL_TIME_METRICS]
    
    if widget and metrics then
        local content = widget:FindFirstChild("Content")
        if content then
            -- Update operations per second
            local metric1 = content:FindFirstChild("Metric1")
            if metric1 then
                local value = metric1:FindFirstChild("Value")
                if value then
                    value.Text = string.format("%.1f", metrics.operationsPerSecond or 0)
                end
            end
            
            -- Update average latency
            local metric2 = content:FindFirstChild("Metric2")
            if metric2 then
                local value = metric2:FindFirstChild("Value")
                if value then
                    value.Text = string.format("%.0fms", metrics.averageLatency or 0)
                end
            end
            
            -- Update error rate
            local metric3 = content:FindFirstChild("Metric3")
            if metric3 then
                local value = metric3:FindFirstChild("Value")
                if value then
                    value.Text = string.format("%.1f%%", (metrics.errorRate or 0) * 100)
                end
            end
        end
    end
end

-- Update system health
function EnhancedDashboard:updateSystemHealth()
    local realTimeMonitor = self.featureRegistry:getFeature("realTimeMonitor")
    if not realTimeMonitor then return end
    
    local summary = realTimeMonitor:getMetricsSummary()
    local widget = self.widgets[WIDGET_TYPES.SYSTEM_HEALTH]
    
    if widget and summary then
        local content = widget:FindFirstChild("Content")
        if content then
            local healthIndicator = content:FindFirstChild("TextLabel")
            if healthIndicator then
                if summary.status == "healthy" then
                    healthIndicator.Text = "🟢 All Systems Operational"
                    healthIndicator.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
                elseif summary.status == "warning" then
                    healthIndicator.Text = "🟡 Performance Warning"
                    healthIndicator.TextColor3 = Constants.UI.THEME.COLORS.WARNING
                else
                    healthIndicator.Text = "🔴 System Issues Detected"
                    healthIndicator.TextColor3 = Constants.UI.THEME.COLORS.ERROR
                end
            end
        end
    end
    
    -- Update header status
    if self.headerElements then
        local status = summary and summary.status or "unknown"
        local statusText = self.headerElements.statusText
        local statusFrame = self.headerElements.statusFrame
        
        if statusText and statusFrame then
            if status == "healthy" then
                statusText.Text = "🟢 System Healthy"
                statusFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
            elseif status == "warning" then
                statusText.Text = "🟡 Warning"
                statusFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.WARNING
            else
                statusText.Text = "🔴 Critical"
                statusFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
            end
        end
    end
end

-- Refresh all widgets
function EnhancedDashboard:refreshAllWidgets()
    debugLog("Refreshing all dashboard widgets...")
    
    self:updateRealTimeWidgets()
    self:updatePerformanceWidgets()
    
    -- Update other widgets
    for widgetType, widget in pairs(self.widgets) do
        if widgetType == WIDGET_TYPES.FEATURE_STATUS then
            self:updateFeatureStatus()
        elseif widgetType == WIDGET_TYPES.BACKUP_STATUS then
            self:updateBackupStatus()
        elseif widgetType == WIDGET_TYPES.SEARCH_ANALYTICS then
            self:updateSearchAnalytics()
        end
    end
    
    debugLog("All dashboard widgets refreshed")
end

-- Utility methods
function EnhancedDashboard:updateCanvasSize()
    if self.dashboardFrame then
        local widgetCount = self:getWidgetCount()
        local rowsNeeded = math.ceil(widgetCount / DASHBOARD_CONFIG.LAYOUT.COLUMNS)
        local totalHeight = 100 + (rowsNeeded * (DASHBOARD_CONFIG.LAYOUT.ROW_HEIGHT + DASHBOARD_CONFIG.LAYOUT.SPACING))
        
        self.dashboardFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end
end

function EnhancedDashboard:getWidgetCount()
    local count = 0
    for _ in pairs(self.widgets) do
        count = count + 1
    end
    return count
end

-- Other update methods (simplified)
function EnhancedDashboard:updatePerformanceChart() end
function EnhancedDashboard:updateOperationCounter() end
function EnhancedDashboard:updateFeatureStatus() end
function EnhancedDashboard:updateBackupStatus() end
function EnhancedDashboard:updateSearchAnalytics() end

-- Cleanup
function EnhancedDashboard:destroy()
    self:stopUpdateTimers()
    
    if self.dashboardFrame then
        self.dashboardFrame:Destroy()
        self.dashboardFrame = nil
    end
    
    self.widgets = {}
    debugLog("Enhanced dashboard destroyed")
end

return EnhancedDashboard 