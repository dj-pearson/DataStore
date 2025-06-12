-- DataStore Manager Pro - Player Insights Dashboard
-- Visual dashboard for player analytics, behavior insights, and game development metrics

local PlayerInsightsDashboard = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

local debugLog = Utils.debugLog

-- Dashboard state
local dashboardState = {
    isVisible = false,
    widget = nil,
    playerAnalytics = nil,
    refreshTimer = nil,
    selectedTimeframe = "24h",
    selectedMetric = "currency"
}

-- Initialize dashboard
function PlayerInsightsDashboard.initialize(widget, playerAnalytics)
    dashboardState.widget = widget
    dashboardState.playerAnalytics = playerAnalytics
    
    debugLog("Player Insights Dashboard initialized")
    return true
end

-- Create main dashboard UI
function PlayerInsightsDashboard.createDashboard(parent)
    if dashboardState.dashboardFrame then
        dashboardState.dashboardFrame:Destroy()
    end
    
    -- Main dashboard frame
    local dashboardFrame = Instance.new("Frame")
    dashboardFrame.Name = "PlayerInsightsDashboard"
    dashboardFrame.Size = UDim2.new(1, 0, 1, 0)
    dashboardFrame.Position = UDim2.new(0, 0, 0, 0)
    dashboardFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    dashboardFrame.BorderSizePixel = 0
    dashboardFrame.Parent = parent
    
    dashboardState.dashboardFrame = dashboardFrame
    
    -- Header
    PlayerInsightsDashboard.createHeader(dashboardFrame)
    
    -- Content area (scrollable)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ContentScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, -80)
    scrollFrame.Position = UDim2.new(0, 0, 0, 80)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    scrollFrame.Parent = dashboardFrame
    
    -- Create dashboard sections
    PlayerInsightsDashboard.createOverviewSection(scrollFrame)
    PlayerInsightsDashboard.createTopPlayersSection(scrollFrame)
    PlayerInsightsDashboard.createDataChangesSection(scrollFrame)
    PlayerInsightsDashboard.createEconomyHealthSection(scrollFrame)
    PlayerInsightsDashboard.createAlertsSection(scrollFrame)
    
    -- Start auto-refresh
    PlayerInsightsDashboard.startAutoRefresh()
    
    debugLog("Player Insights Dashboard UI created")
end

-- Create header with controls
function PlayerInsightsDashboard.createHeader(parent)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    header.BorderSizePixel = 1
    header.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    header.Parent = parent
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 400, 1, -20)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🎮 Player Insights Dashboard"
    title.Font = Constants.UI.THEME.FONTS.HEADING
    title.TextSize = 18
    title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0, 500, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 45)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Advanced player behavior analysis, top performers, and economy insights"
    subtitle.Font = Constants.UI.THEME.FONTS.BODY
    subtitle.TextSize = 12
    subtitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    -- Controls
    PlayerInsightsDashboard.createHeaderControls(header)
end

-- Create header controls
function PlayerInsightsDashboard.createHeaderControls(parent)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(0, 400, 0, 60)
    controlsFrame.Position = UDim2.new(1, -420, 0, 10)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = parent
    
    -- Timeframe selector
    local timeframeLabel = Instance.new("TextLabel")
    timeframeLabel.Size = UDim2.new(0, 80, 0, 25)
    timeframeLabel.Position = UDim2.new(0, 0, 0, 0)
    timeframeLabel.BackgroundTransparency = 1
    timeframeLabel.Text = "Timeframe:"
    timeframeLabel.Font = Constants.UI.THEME.FONTS.BODY
    timeframeLabel.TextSize = 12
    timeframeLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    timeframeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeframeLabel.Parent = controlsFrame
    
    local timeframes = {"1h", "24h", "7d", "30d"}
    for i, timeframe in ipairs(timeframes) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 40, 0, 25)
        button.Position = UDim2.new(0, 80 + (i-1) * 45, 0, 0)
        button.BackgroundColor3 = timeframe == dashboardState.selectedTimeframe and 
            Constants.UI.THEME.COLORS.PRIMARY or Constants.UI.THEME.COLORS.BUTTON_HOVER
        button.BorderSizePixel = 0
        button.Text = timeframe
        button.Font = Constants.UI.THEME.FONTS.UI
        button.TextSize = 10
        button.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
        button.Parent = controlsFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            PlayerInsightsDashboard.setTimeframe(timeframe)
        end)
    end
    
    -- Refresh button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 80, 0, 25)
    refreshButton.Position = UDim2.new(0, 280, 0, 0)
    refreshButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    refreshButton.BorderSizePixel = 0
    refreshButton.Text = "🔄 Refresh"
    refreshButton.Font = Constants.UI.THEME.FONTS.UI
    refreshButton.TextSize = 10
    refreshButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    refreshButton.Parent = controlsFrame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 4)
    refreshCorner.Parent = refreshButton
    
    refreshButton.MouseButton1Click:Connect(function()
        PlayerInsightsDashboard.refreshData()
    end)
    
    -- Export button
    local exportButton = Instance.new("TextButton")
    exportButton.Size = UDim2.new(0, 70, 0, 25)
    exportButton.Position = UDim2.new(0, 280, 0, 30)
    exportButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    exportButton.BorderSizePixel = 0
    exportButton.Text = "📊 Export"
    exportButton.Font = Constants.UI.THEME.FONTS.UI
    exportButton.TextSize = 10
    exportButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    exportButton.Parent = controlsFrame
    
    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, 4)
    exportCorner.Parent = exportButton
    
    exportButton.MouseButton1Click:Connect(function()
        PlayerInsightsDashboard.exportData()
    end)
end

-- Create overview section
function PlayerInsightsDashboard.createOverviewSection(parent)
    local section = PlayerInsightsDashboard.createSection(parent, "📊 Overview", 0, 200)
    
    -- Get analytics data
    local report = dashboardState.playerAnalytics and dashboardState.playerAnalytics.generateReport() or {}
    local summary = report.summary or {}
    
    -- Overview cards
    local cardsFrame = Instance.new("Frame")
    cardsFrame.Size = UDim2.new(1, -40, 0, 120)
    cardsFrame.Position = UDim2.new(0, 20, 0, 60)
    cardsFrame.BackgroundTransparency = 1
    cardsFrame.Parent = section
    
    -- Create metric cards
    PlayerInsightsDashboard.createMetricCard(cardsFrame, "Players Analyzed", tostring(summary.totalPlayersAnalyzed or 0), "👥", 0)
    PlayerInsightsDashboard.createMetricCard(cardsFrame, "Active Alerts", tostring(summary.activeAlerts or 0), "🚨", 1)
    PlayerInsightsDashboard.createMetricCard(cardsFrame, "Data Changes", tostring(summary.recentDataChanges or 0), "📝", 2)
    PlayerInsightsDashboard.createMetricCard(cardsFrame, "Suspicious Activity", tostring(summary.suspiciousActivities or 0), "⚠️", 3)
end

-- Create top players section
function PlayerInsightsDashboard.createTopPlayersSection(parent)
    local section = PlayerInsightsDashboard.createSection(parent, "🏆 Top Players", 220, 300)
    
    -- Get top players data
    local report = dashboardState.playerAnalytics and dashboardState.playerAnalytics.generateReport() or {}
    local topPlayers = report.topPlayers or {}
    
    -- Create tabs for different categories
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, -40, 0, 30)
    tabsFrame.Position = UDim2.new(0, 20, 0, 50)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = section
    
    local categories = {"Currency", "Levels", "Activity"}
    for i, category in ipairs(categories) do
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0, 100, 0, 25)
        tab.Position = UDim2.new(0, (i-1) * 105, 0, 0)
        tab.BackgroundColor3 = i == 1 and Constants.UI.THEME.COLORS.PRIMARY or Constants.UI.THEME.COLORS.BUTTON_HOVER
        tab.BorderSizePixel = 0
        tab.Text = category
        tab.Font = Constants.UI.THEME.FONTS.UI
        tab.TextSize = 11
        tab.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
        tab.Parent = tabsFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = tab
    end
    
    -- Top players list
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, -40, 0, 200)
    listFrame.Position = UDim2.new(0, 20, 0, 90)
    listFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    listFrame.BorderSizePixel = 1
    listFrame.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    listFrame.ScrollBarThickness = 6
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.Parent = section
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = listFrame
    
    -- Populate with currency leaders (example)
    PlayerInsightsDashboard.populateTopPlayersList(listFrame, topPlayers.currency)
end

-- Create data changes section
function PlayerInsightsDashboard.createDataChangesSection(parent)
    local section = PlayerInsightsDashboard.createSection(parent, "📈 Data Changes & Anomalies", 540, 250)
    
    -- Get data changes
    local report = dashboardState.playerAnalytics and dashboardState.playerAnalytics.generateReport() or {}
    local dataChanges = report.dataChanges or {}
    
    -- Recent changes list
    local changesFrame = Instance.new("ScrollingFrame")
    changesFrame.Size = UDim2.new(1, -40, 0, 180)
    changesFrame.Position = UDim2.new(0, 20, 0, 50)
    changesFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    changesFrame.BorderSizePixel = 1
    changesFrame.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    changesFrame.ScrollBarThickness = 6
    changesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    changesFrame.Parent = section
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = changesFrame
    
    -- Populate changes list
    PlayerInsightsDashboard.populateDataChangesList(changesFrame, dataChanges)
end

-- Create economy health section
function PlayerInsightsDashboard.createEconomyHealthSection(parent)
    local section = PlayerInsightsDashboard.createSection(parent, "💰 Economy Health", 810, 200)
    
    -- Get economy data
    local report = dashboardState.playerAnalytics and dashboardState.playerAnalytics.generateReport() or {}
    local economyHealth = report.economyHealth or {}
    
    -- Economy metrics
    local metricsFrame = Instance.new("Frame")
    metricsFrame.Size = UDim2.new(1, -40, 0, 120)
    metricsFrame.Position = UDim2.new(0, 20, 0, 60)
    metricsFrame.BackgroundTransparency = 1
    metricsFrame.Parent = section
    
    -- Economy health cards
    PlayerInsightsDashboard.createEconomyCard(metricsFrame, "Total Currency", PlayerInsightsDashboard.formatNumber(economyHealth.totalCurrency or 0), 0)
    PlayerInsightsDashboard.createEconomyCard(metricsFrame, "Average Wealth", PlayerInsightsDashboard.formatNumber(economyHealth.averageWealth or 0), 1)
    PlayerInsightsDashboard.createEconomyCard(metricsFrame, "Wealth Inequality", string.format("%.1f%%", (economyHealth.giniCoefficient or 0) * 100), 2)
    PlayerInsightsDashboard.createEconomyCard(metricsFrame, "Inflation Rate", string.format("%.1f%%", economyHealth.inflationRate or 0), 3)
end

-- Create alerts section
function PlayerInsightsDashboard.createAlertsSection(parent)
    local section = PlayerInsightsDashboard.createSection(parent, "🚨 Active Alerts & Recommendations", 1030, 150)
    
    -- Get alerts data
    local report = dashboardState.playerAnalytics and dashboardState.playerAnalytics.generateReport() or {}
    local alerts = report.alerts or {}
    local recommendations = report.recommendations or {}
    
    -- Alerts list
    local alertsFrame = Instance.new("ScrollingFrame")
    alertsFrame.Size = UDim2.new(1, -40, 0, 80)
    alertsFrame.Position = UDim2.new(0, 20, 0, 50)
    alertsFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    alertsFrame.BorderSizePixel = 1
    alertsFrame.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    alertsFrame.ScrollBarThickness = 6
    alertsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    alertsFrame.Parent = section
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = alertsFrame
    
    -- Populate alerts
    PlayerInsightsDashboard.populateAlertsList(alertsFrame, alerts, recommendations)
end

-- Helper functions for creating UI elements

function PlayerInsightsDashboard.createSection(parent, title, yPosition, height)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. title:gsub("[^%w]", "")
    section.Size = UDim2.new(1, -40, 0, height)
    section.Position = UDim2.new(0, 20, 0, yPosition)
    section.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    section.BorderSizePixel = 1
    section.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    section.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = section
    
    -- Section header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    header.BorderSizePixel = 0
    header.Parent = section
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Fix corner for just top
    local headerBottomCover = Instance.new("Frame")
    headerBottomCover.Size = UDim2.new(1, 0, 0, 8)
    headerBottomCover.Position = UDim2.new(0, 0, 1, -8)
    headerBottomCover.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    headerBottomCover.BorderSizePixel = 0
    headerBottomCover.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    
    return section
end

function PlayerInsightsDashboard.createMetricCard(parent, title, value, icon, index)
    local cardWidth = (parent.AbsoluteSize.X - 60) / 4
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, cardWidth, 1, 0)
    card.Position = UDim2.new(0, index * (cardWidth + 15), 0, 0)
    card.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    card.BorderSizePixel = 1
    card.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 15, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.Font = Constants.UI.THEME.FONTS.UI
    iconLabel.TextSize = 18
    iconLabel.TextColor3 = Constants.UI.THEME.COLORS.PRIMARY
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.Parent = card
    
    -- Value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -60, 0, 30)
    valueLabel.Position = UDim2.new(0, 50, 0, 10)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.Font = Constants.UI.THEME.FONTS.HEADING
    valueLabel.TextSize = 20
    valueLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.Parent = card
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 15, 0, 45)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Constants.UI.THEME.FONTS.BODY
    titleLabel.TextSize = 11
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = card
end

function PlayerInsightsDashboard.createEconomyCard(parent, title, value, index)
    PlayerInsightsDashboard.createMetricCard(parent, title, value, "💰", index)
end

-- Utility functions

function PlayerInsightsDashboard.formatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(math.floor(number))
    end
end

function PlayerInsightsDashboard.setTimeframe(timeframe)
    dashboardState.selectedTimeframe = timeframe
    PlayerInsightsDashboard.refreshData()
end

function PlayerInsightsDashboard.refreshData()
    -- Refresh analytics data and update UI
    if dashboardState.playerAnalytics then
        -- Trigger analytics refresh
        -- Update all UI elements with new data
        debugLog("Refreshing player insights data for timeframe: " .. dashboardState.selectedTimeframe)
    end
end

function PlayerInsightsDashboard.exportData()
    if dashboardState.playerAnalytics then
        local report = dashboardState.playerAnalytics.generateReport()
        local exportData = game:GetService("HttpService"):JSONEncode(report)
        
        -- Create export dialog
        PlayerInsightsDashboard.showExportDialog(exportData)
    end
end

function PlayerInsightsDashboard.showExportDialog(data)
    -- Create a simple export dialog
    debugLog("Exporting player analytics data (" .. string.len(data) .. " characters)")
    print("Player Analytics Export Data:")
    print(data)
end

function PlayerInsightsDashboard.populateTopPlayersList(listFrame, playersData)
    -- Clear existing items
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Add list layout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = listFrame
    
    -- Populate with player data (example structure)
    if playersData and type(playersData) == "table" then
        local ySize = 0
        for category, players in pairs(playersData) do
            if type(players) == "table" then
                for i, player in ipairs(players) do
                    if i <= 10 then -- Top 10
                        local item = Instance.new("Frame")
                        item.Size = UDim2.new(1, -10, 0, 25)
                        item.BackgroundColor3 = i % 2 == 0 and Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY or Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
                        item.BorderSizePixel = 0
                        item.LayoutOrder = i
                        item.Parent = listFrame
                        
                        local rankLabel = Instance.new("TextLabel")
                        rankLabel.Size = UDim2.new(0, 30, 1, 0)
                        rankLabel.Position = UDim2.new(0, 5, 0, 0)
                        rankLabel.BackgroundTransparency = 1
                        rankLabel.Text = "#" .. i
                        rankLabel.Font = Constants.UI.THEME.FONTS.UI
                        rankLabel.TextSize = 11
                        rankLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
                        rankLabel.TextXAlignment = Enum.TextXAlignment.Left
                        rankLabel.Parent = item
                        
                        local playerLabel = Instance.new("TextLabel")
                        playerLabel.Size = UDim2.new(0, 150, 1, 0)
                        playerLabel.Position = UDim2.new(0, 40, 0, 0)
                        playerLabel.BackgroundTransparency = 1
                        playerLabel.Text = "Player " .. (player.playerId or "Unknown")
                        playerLabel.Font = Constants.UI.THEME.FONTS.UI
                        playerLabel.TextSize = 11
                        playerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
                        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
                        playerLabel.Parent = item
                        
                        local valueLabel = Instance.new("TextLabel")
                        valueLabel.Size = UDim2.new(0, 100, 1, 0)
                        valueLabel.Position = UDim2.new(1, -105, 0, 0)
                        valueLabel.BackgroundTransparency = 1
                        valueLabel.Text = PlayerInsightsDashboard.formatNumber(player.value or 0)
                        valueLabel.Font = Constants.UI.THEME.FONTS.UI
                        valueLabel.TextSize = 11
                        valueLabel.TextColor3 = Constants.UI.THEME.COLORS.PRIMARY
                        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                        valueLabel.Parent = item
                        
                        ySize = ySize + 27
                    end
                end
                break -- Only show first category for now
            end
        end
        
        listFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
    end
end

function PlayerInsightsDashboard.populateDataChangesList(listFrame, changesData)
    -- Implementation for populating data changes list
    -- Similar to top players list but showing recent changes
end

function PlayerInsightsDashboard.populateAlertsList(listFrame, alerts, recommendations)
    -- Implementation for populating alerts and recommendations
    -- Show active alerts and actionable recommendations
end

function PlayerInsightsDashboard.startAutoRefresh()
    if dashboardState.refreshTimer then
        dashboardState.refreshTimer:Disconnect()
    end
    
    dashboardState.refreshTimer = game:GetService("RunService").Heartbeat:Connect(function()
        -- Auto-refresh every 30 seconds
        if tick() % 30 < 0.1 then
            PlayerInsightsDashboard.refreshData()
        end
    end)
end

function PlayerInsightsDashboard.show()
    dashboardState.isVisible = true
    if dashboardState.dashboardFrame then
        dashboardState.dashboardFrame.Visible = true
    end
end

function PlayerInsightsDashboard.hide()
    dashboardState.isVisible = false
    if dashboardState.dashboardFrame then
        dashboardState.dashboardFrame.Visible = false
    end
end

function PlayerInsightsDashboard.cleanup()
    if dashboardState.refreshTimer then
        dashboardState.refreshTimer:Disconnect()
        dashboardState.refreshTimer = nil
    end
    
    if dashboardState.dashboardFrame then
        dashboardState.dashboardFrame:Destroy()
        dashboardState.dashboardFrame = nil
    end
end

return PlayerInsightsDashboard 