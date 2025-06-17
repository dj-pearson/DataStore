-- DataStore Manager Pro - Analytics View Module
-- Handles analytics dashboard creation and management

local AnalyticsView = {}
AnalyticsView.__index = AnalyticsView

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[ANALYTICS_VIEW] [%s] %s", level, message))
end

-- Create new Analytics View instance
function AnalyticsView.new(viewManager)
    local self = setmetatable({}, AnalyticsView)
    
    self.viewManager = viewManager
    self.services = viewManager.services
    
    debugLog("AnalyticsView created")
    return self
end

-- Show Analytics view
function AnalyticsView:show()
    debugLog("Showing Analytics view")
    self:createRealAnalyticsView()
end

-- Create real analytics view
function AnalyticsView:createRealAnalyticsView()
    self.viewManager:clearMainContent()
    
    -- Header
    self.viewManager:createViewHeader("📊 Data Analytics Dashboard", "Real-time analytics and insights for your DataStore operations")
    
    -- Content area
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "AnalyticsContent"
    contentFrame.Size = UDim2.new(1, 0, 1, -80)
    contentFrame.Position = UDim2.new(0, 0, 0, 80)
    contentFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    contentFrame.Parent = self.viewManager.mainContentArea
    
    local yOffset = Constants.UI.THEME.SPACING.LARGE
    
    -- Get real analytics data
    local analyticsCards = self:getRealAnalyticsData()
    
    for _, card in ipairs(analyticsCards) do
        local cardFrame = self:createAnalyticsCard(card, yOffset, contentFrame)
        yOffset = yOffset + 220
    end
    
    -- Real-time chart section
    local chartSection = self:createChartSection(yOffset, contentFrame)
    yOffset = yOffset + 300
    
    -- Update canvas size
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    
    self.viewManager.currentView = "Analytics"
    debugLog("Real analytics view created")
end

-- Create analytics card
function AnalyticsView:createAnalyticsCard(cardData, yOffset, parent)
    local card = Instance.new("Frame")
    card.Name = cardData.title:gsub("[^%w]", "") .. "Card"
    card.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE * 2, 0, 200)
    card.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, yOffset)
    card.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    card.BorderSizePixel = 1
    card.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    cardCorner.Parent = card
    
    -- Card header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = cardData.color
    header.BorderSizePixel = 0
    header.Parent = card
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    headerCorner.Parent = header
    
    -- Mask bottom corners of header
    local headerMask = Instance.new("Frame")
    headerMask.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    headerMask.Position = UDim2.new(0, 0, 1, -Constants.UI.THEME.SIZES.BORDER_RADIUS)
    headerMask.BackgroundColor3 = cardData.color
    headerMask.BorderSizePixel = 0
    headerMask.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = cardData.title
    title.Font = Constants.UI.THEME.FONTS.HEADING
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(1, -20, 0, 20)
    description.Position = UDim2.new(0, 10, 0, 25)
    description.BackgroundTransparency = 1
    description.Text = cardData.description
    description.Font = Constants.UI.THEME.FONTS.BODY
    description.TextSize = 12
    description.TextColor3 = Color3.fromRGB(255, 255, 255)
    description.TextTransparency = 0.3
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Parent = header
    
    -- Metrics grid
    local metricsContainer = Instance.new("Frame")
    metricsContainer.Size = UDim2.new(1, -20, 1, -60)
    metricsContainer.Position = UDim2.new(0, 10, 0, 55)
    metricsContainer.BackgroundTransparency = 1
    metricsContainer.Parent = card
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -5, 0.5, -5)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = metricsContainer
    
    for _, metric in ipairs(cardData.metrics) do
        local metricFrame = Instance.new("Frame")
        metricFrame.BackgroundTransparency = 1
        metricFrame.Parent = metricsContainer
        
        local metricLabel = Instance.new("TextLabel")
        metricLabel.Size = UDim2.new(1, 0, 0, 20)
        metricLabel.BackgroundTransparency = 1
        metricLabel.Text = metric[1]
        metricLabel.Font = Constants.UI.THEME.FONTS.BODY
        metricLabel.TextSize = 11
        metricLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        metricLabel.TextXAlignment = Enum.TextXAlignment.Left
        metricLabel.Parent = metricFrame
        
        local metricValue = Instance.new("TextLabel")
        metricValue.Size = UDim2.new(1, 0, 0, 25)
        metricValue.Position = UDim2.new(0, 0, 0, 20)
        metricValue.BackgroundTransparency = 1
        metricValue.Text = metric[2]
        metricValue.Font = Constants.UI.THEME.FONTS.HEADING
        metricValue.TextSize = 18
        metricValue.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        metricValue.TextXAlignment = Enum.TextXAlignment.Left
        metricValue.Parent = metricFrame
        
        local metricChange = Instance.new("TextLabel")
        metricChange.Size = UDim2.new(1, 0, 0, 15)
        metricChange.Position = UDim2.new(0, 0, 0, 45)
        metricChange.BackgroundTransparency = 1
        metricChange.Text = metric[3]
        metricChange.Font = Constants.UI.THEME.FONTS.UI
        metricChange.TextSize = 10
        metricChange.TextColor3 = metric[3]:find("↗️") and Color3.fromRGB(87, 242, 135) or 
                                 metric[3]:find("↘️") and Color3.fromRGB(248, 113, 113) or 
                                 Constants.UI.THEME.COLORS.TEXT_SECONDARY
        metricChange.TextXAlignment = Enum.TextXAlignment.Left
        metricChange.Parent = metricFrame
    end
    
    return card
end

-- Create chart section
function AnalyticsView:createChartSection(yOffset, parent)
    local section = Instance.new("Frame")
    section.Name = "ChartSection"
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
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 40)
    header.Position = UDim2.new(0, 10, 0, 10)
    header.BackgroundTransparency = 1
    header.Text = "📈 Real-Time Performance Chart"
    header.Font = Constants.UI.THEME.FONTS.HEADING
    header.TextSize = 16
    header.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = section
    
    -- Chart placeholder
    local chartArea = Instance.new("Frame")
    chartArea.Size = UDim2.new(1, -20, 1, -60)
    chartArea.Position = UDim2.new(0, 10, 0, 50)
    chartArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    chartArea.BorderSizePixel = 1
    chartArea.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    chartArea.Parent = section
    
    local chartCorner = Instance.new("UICorner")
    chartCorner.CornerRadius = UDim.new(0, 4)
    chartCorner.Parent = chartArea
    
    local chartPlaceholder = Instance.new("TextLabel")
    chartPlaceholder.Size = UDim2.new(1, 0, 1, 0)
    chartPlaceholder.BackgroundTransparency = 1
    chartPlaceholder.Text = "📊 Real-time performance chart will be displayed here\n\nShowing DataStore operation latency, success rates,\nand throughput over time"
    chartPlaceholder.Font = Constants.UI.THEME.FONTS.BODY
    chartPlaceholder.TextSize = 14
    chartPlaceholder.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    chartPlaceholder.TextXAlignment = Enum.TextXAlignment.Center
    chartPlaceholder.TextYAlignment = Enum.TextYAlignment.Center
    chartPlaceholder.Parent = chartArea
    
    return section
end

-- Get real analytics data from AdvancedAnalytics
function AnalyticsView:getRealAnalyticsData()
    local analyticsService = self.services and self.services["features.analytics.AdvancedAnalytics"]
    local dataStoreService = self.services and self.services["core.data.DataStoreManagerSlim"]
    
    -- Default fallback data
    local defaultCards = {
        {
            title = "📈 Performance Metrics",
            description = "DataStore operation performance and latency analysis",
            metrics = {
                {"Total Operations", "No data", "→ 0%"},
                {"Avg Response Time", "No data", "→ 0%"},
                {"Success Rate", "No data", "→ 0%"},
                {"Memory Usage", "No data", "→ 0%"}
            },
            color = Constants.UI.THEME.COLORS.SUCCESS or Color3.fromRGB(87, 242, 135)
        },
        {
            title = "💾 Storage Analytics",
            description = "DataStore usage patterns and storage optimization",
            metrics = {
                {"Total DataStores", "No data", "→ 0%"},
                {"Total Keys", "No data", "→ 0%"},
                {"Active Players", "No data", "→ 0%"},
                {"Cache Hit Rate", "No data", "→ 0%"}
            },
            color = Constants.UI.THEME.COLORS.INFO or Color3.fromRGB(114, 137, 218)
        },
        {
            title = "🔍 Player Analytics",
            description = "Player behavior and economy health analysis",
            metrics = {
                {"Players Analyzed", "No data", "→ 0%"},
                {"Total Currency", "No data", "→ 0%"},
                {"Avg Player Level", "No data", "→ 0%"},
                {"Suspicious Activities", "No data", "→ 0%"}
            },
            color = Constants.UI.THEME.COLORS.WARNING or Color3.fromRGB(254, 231, 92)
        }
    }
    
    -- Try to get real data from analytics service
    if analyticsService and analyticsService.getMetrics then
        local performanceMetrics = analyticsService.getMetrics("performance", 3600) -- Last hour
        local businessMetrics = analyticsService.getMetrics("business", 3600)
        
        -- Get DataStore stats if available
        local dsStats = nil
        if dataStoreService and dataStoreService.getStats then
            dsStats = dataStoreService:getStats()
        end
        
        -- Update performance metrics with real data
        if dsStats then
            defaultCards[1].metrics = {
                {"Total Operations", tostring(dsStats.operations.total or 0), self:formatChange(dsStats.operations.total)},
                {"Avg Response Time", string.format("%.1fms", dsStats.operations.averageLatency or 0), self:formatChange(dsStats.operations.averageLatency, "ms")},
                {"Success Rate", string.format("%.1f%%", dsStats.operations.successRate or 0), self:formatChange(dsStats.operations.successRate, "%")},
                {"Memory Usage", string.format("%.1f MB", game:GetService("Stats"):GetTotalMemoryUsageMb()), "→ 0%"}
            }
        end
        
        -- Update storage analytics with real data
        if dataStoreService then
            local dataStoreNames = dataStoreService:getDataStoreNames()
            local totalKeys = 0
            local activeUsers = #game:GetService("Players"):GetPlayers()
            
            if dataStoreNames then
                for _, dsName in ipairs(dataStoreNames) do
                    local keys = dataStoreService:getKeys(dsName, "global", 100)
                    if keys then
                        totalKeys = totalKeys + #keys
                    end
                end
            end
            
            local cacheHitRate = dsStats and dsStats.cache and dsStats.cache.totalRequests > 0 and 
                               (dsStats.cache.hits / dsStats.cache.totalRequests * 100) or 0
            
            defaultCards[2].metrics = {
                {"Total DataStores", tostring(dataStoreNames and #dataStoreNames or 0), "→ 0%"},
                {"Total Keys", tostring(totalKeys), self:formatChange(totalKeys)},
                {"Active Players", tostring(activeUsers), self:formatChange(activeUsers)},
                {"Cache Hit Rate", string.format("%.1f%%", cacheHitRate), self:formatChange(cacheHitRate, "%")}
            }
        end
        
        -- Update player analytics with business metrics
        if businessMetrics then
            local playersAnalyzed = businessMetrics.total_players_analyzed and businessMetrics.total_players_analyzed.summary.avg or 0
            local totalCurrency = businessMetrics.total_currency_circulation and businessMetrics.total_currency_circulation.summary.sum or 0
            local avgLevel = businessMetrics.average_player_level and businessMetrics.average_player_level.summary.avg or 0
            local suspiciousActivities = businessMetrics.suspicious_activities and businessMetrics.suspicious_activities.summary.sum or 0
            
            defaultCards[3].metrics = {
                {"Players Analyzed", tostring(math.floor(playersAnalyzed)), self:formatChange(playersAnalyzed)},
                {"Total Currency", self:formatNumber(totalCurrency), self:formatChange(totalCurrency)},
                {"Avg Player Level", string.format("%.1f", avgLevel), self:formatChange(avgLevel)},
                {"Suspicious Activities", tostring(math.floor(suspiciousActivities)), self:formatChange(suspiciousActivities, "alert")}
            }
        end
    end
    
    return defaultCards
end

-- Format numbers for display
function AnalyticsView:formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- Format change indicators
function AnalyticsView:formatChange(value, suffix)
    suffix = suffix or ""
    
    if not value or value == 0 then
        return "→ 0" .. suffix
    elseif value > 0 then
        return "↗️ +" .. self:formatNumber(value) .. suffix
    else
        return "↘️ " .. self:formatNumber(value) .. suffix
    end
end

return AnalyticsView 