-- DataStore Manager Pro - Performance Dashboard
-- Real-time performance monitoring and optimization dashboard

local PerformanceDashboard = {}
PerformanceDashboard.__index = PerformanceDashboard

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[PERFORMANCE_DASHBOARD] [%s] %s", level, message))
end

-- Create new Performance Dashboard
function PerformanceDashboard.new(services)
    local self = setmetatable({}, PerformanceDashboard)
    
    self.services = services or {}
    self.isVisible = false
    self.refreshInterval = 2 -- seconds
    self.refreshConnection = nil
    
    -- UI elements
    self.gui = nil
    self.metricsFrame = nil
    self.alertsFrame = nil
    self.recommendationsFrame = nil
    self.chartsFrame = nil
    
    -- Data history for charts
    self.metricsHistory = {
        responseTime = {},
        memoryUsage = {},
        cacheHitRate = {},
        throughput = {}
    }
    
    debugLog("Performance Dashboard created")
    return self
end

-- Initialize the dashboard
function PerformanceDashboard:initialize(parent)
    self:createUI(parent)
    self:startRefreshTimer()
    debugLog("Performance Dashboard initialized")
end

-- Create the UI
function PerformanceDashboard:createUI(parent)
    -- Main dashboard frame
    self.gui = Instance.new("Frame")
    self.gui.Name = "PerformanceDashboard"
    self.gui.Size = UDim2.new(1, 0, 1, 0)
    self.gui.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    self.gui.BorderSizePixel = 0
    self.gui.Parent = parent
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    title.BorderSizePixel = 0
    title.Text = "🚀 Performance Monitor - Real-Time Analytics"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = self.gui
    
    -- Create sections
    self:createMetricsSection()
    self:createAlertsSection()
    self:createRecommendationsSection()
    self:createChartsSection()
    self:createControlsSection()
end

-- Create metrics section
function PerformanceDashboard:createMetricsSection()
    self.metricsFrame = Instance.new("Frame")
    self.metricsFrame.Name = "MetricsSection"
    self.metricsFrame.Size = UDim2.new(0.48, 0, 0.35, 0)
    self.metricsFrame.Position = UDim2.new(0.01, 0, 0.08, 0)
    self.metricsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    self.metricsFrame.BorderSizePixel = 1
    self.metricsFrame.BorderColor3 = Color3.fromRGB(70, 70, 75)
    self.metricsFrame.Parent = self.gui
    
    -- Metrics title
    local metricsTitle = Instance.new("TextLabel")
    metricsTitle.Name = "Title"
    metricsTitle.Size = UDim2.new(1, 0, 0, 25)
    metricsTitle.Position = UDim2.new(0, 0, 0, 0)
    metricsTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    metricsTitle.BorderSizePixel = 0
    metricsTitle.Text = "📊 Real-Time Metrics"
    metricsTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
    metricsTitle.TextScaled = true
    metricsTitle.Font = Enum.Font.SourceSansBold
    metricsTitle.Parent = self.metricsFrame
    
    -- Scrolling frame for metrics
    local metricsScroll = Instance.new("ScrollingFrame")
    metricsScroll.Name = "MetricsScroll"
    metricsScroll.Size = UDim2.new(1, 0, 1, -25)
    metricsScroll.Position = UDim2.new(0, 0, 0, 25)
    metricsScroll.BackgroundTransparency = 1
    metricsScroll.ScrollBarThickness = 6
    metricsScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    metricsScroll.Parent = self.metricsFrame
    
    self.metricsContainer = metricsScroll
end

-- Create alerts section
function PerformanceDashboard:createAlertsSection()
    self.alertsFrame = Instance.new("Frame")
    self.alertsFrame.Name = "AlertsSection"
    self.alertsFrame.Size = UDim2.new(0.48, 0, 0.35, 0)
    self.alertsFrame.Position = UDim2.new(0.51, 0, 0.08, 0)
    self.alertsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    self.alertsFrame.BorderSizePixel = 1
    self.alertsFrame.BorderColor3 = Color3.fromRGB(70, 70, 75)
    self.alertsFrame.Parent = self.gui
    
    -- Alerts title
    local alertsTitle = Instance.new("TextLabel")
    alertsTitle.Name = "Title"
    alertsTitle.Size = UDim2.new(1, 0, 0, 25)
    alertsTitle.Position = UDim2.new(0, 0, 0, 0)
    alertsTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    alertsTitle.BorderSizePixel = 0
    alertsTitle.Text = "⚠️ Performance Alerts"
    alertsTitle.TextColor3 = Color3.fromRGB(255, 200, 200)
    alertsTitle.TextScaled = true
    alertsTitle.Font = Enum.Font.SourceSansBold
    alertsTitle.Parent = self.alertsFrame
    
    -- Scrolling frame for alerts
    local alertsScroll = Instance.new("ScrollingFrame")
    alertsScroll.Name = "AlertsScroll"
    alertsScroll.Size = UDim2.new(1, 0, 1, -25)
    alertsScroll.Position = UDim2.new(0, 0, 0, 25)
    alertsScroll.BackgroundTransparency = 1
    alertsScroll.ScrollBarThickness = 6
    alertsScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    alertsScroll.Parent = self.alertsFrame
    
    self.alertsContainer = alertsScroll
end

-- Create recommendations section
function PerformanceDashboard:createRecommendationsSection()
    self.recommendationsFrame = Instance.new("Frame")
    self.recommendationsFrame.Name = "RecommendationsSection"
    self.recommendationsFrame.Size = UDim2.new(0.48, 0, 0.25, 0)
    self.recommendationsFrame.Position = UDim2.new(0.01, 0, 0.45, 0)
    self.recommendationsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    self.recommendationsFrame.BorderSizePixel = 1
    self.recommendationsFrame.BorderColor3 = Color3.fromRGB(70, 70, 75)
    self.recommendationsFrame.Parent = self.gui
    
    -- Recommendations title
    local recTitle = Instance.new("TextLabel")
    recTitle.Name = "Title"
    recTitle.Size = UDim2.new(1, 0, 0, 25)
    recTitle.Position = UDim2.new(0, 0, 0, 0)
    recTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    recTitle.BorderSizePixel = 0
    recTitle.Text = "💡 Optimization Recommendations"
    recTitle.TextColor3 = Color3.fromRGB(200, 255, 200)
    recTitle.TextScaled = true
    recTitle.Font = Enum.Font.SourceSansBold
    recTitle.Parent = self.recommendationsFrame
    
    -- Scrolling frame for recommendations
    local recScroll = Instance.new("ScrollingFrame")
    recScroll.Name = "RecommendationsScroll"
    recScroll.Size = UDim2.new(1, 0, 1, -25)
    recScroll.Position = UDim2.new(0, 0, 0, 25)
    recScroll.BackgroundTransparency = 1
    recScroll.ScrollBarThickness = 6
    recScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    recScroll.Parent = self.recommendationsFrame
    
    self.recommendationsContainer = recScroll
end

-- Create charts section
function PerformanceDashboard:createChartsSection()
    self.chartsFrame = Instance.new("Frame")
    self.chartsFrame.Name = "ChartsSection"
    self.chartsFrame.Size = UDim2.new(0.48, 0, 0.25, 0)
    self.chartsFrame.Position = UDim2.new(0.51, 0, 0.45, 0)
    self.chartsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    self.chartsFrame.BorderSizePixel = 1
    self.chartsFrame.BorderColor3 = Color3.fromRGB(70, 70, 75)
    self.chartsFrame.Parent = self.gui
    
    -- Charts title
    local chartsTitle = Instance.new("TextLabel")
    chartsTitle.Name = "Title"
    chartsTitle.Size = UDim2.new(1, 0, 0, 25)
    chartsTitle.Position = UDim2.new(0, 0, 0, 0)
    chartsTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    chartsTitle.BorderSizePixel = 0
    chartsTitle.Text = "📈 Performance Trends"
    chartsTitle.TextColor3 = Color3.fromRGB(200, 255, 255)
    chartsTitle.TextScaled = true
    chartsTitle.Font = Enum.Font.SourceSansBold
    chartsTitle.Parent = self.chartsFrame
    
    -- Chart container
    local chartContainer = Instance.new("Frame")
    chartContainer.Name = "ChartContainer"
    chartContainer.Size = UDim2.new(1, 0, 1, -25)
    chartContainer.Position = UDim2.new(0, 0, 0, 25)
    chartContainer.BackgroundTransparency = 1
    chartContainer.Parent = self.chartsFrame
    
    self.chartContainer = chartContainer
end

-- Create controls section
function PerformanceDashboard:createControlsSection()
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsSection"
    controlsFrame.Size = UDim2.new(1, 0, 0.22, 0)
    controlsFrame.Position = UDim2.new(0, 0, 0.72, 0)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    controlsFrame.BorderSizePixel = 1
    controlsFrame.BorderColor3 = Color3.fromRGB(70, 70, 75)
    controlsFrame.Parent = self.gui
    
    -- Controls title
    local controlsTitle = Instance.new("TextLabel")
    controlsTitle.Name = "Title"
    controlsTitle.Size = UDim2.new(1, 0, 0, 25)
    controlsTitle.Position = UDim2.new(0, 0, 0, 0)
    controlsTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    controlsTitle.BorderSizePixel = 0
    controlsTitle.Text = "🎛️ Performance Controls"
    controlsTitle.TextColor3 = Color3.fromRGB(255, 255, 200)
    controlsTitle.TextScaled = true
    controlsTitle.Font = Enum.Font.SourceSansBold
    controlsTitle.Parent = controlsFrame
    
    -- Create control buttons
    self:createControlButtons(controlsFrame)
end

-- Create control buttons
function PerformanceDashboard:createControlButtons(parent)
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -10, 1, -30)
    buttonContainer.Position = UDim2.new(0, 5, 0, 25)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = parent
    
    local buttons = {
        {text = "🔄 Refresh", color = Color3.fromRGB(100, 150, 255), action = "refresh"},
        {text = "🧹 Clear Cache", color = Color3.fromRGB(255, 150, 100), action = "clearCache"},
        {text = "⚡ Optimize", color = Color3.fromRGB(100, 255, 150), action = "optimize"},
        {text = "📊 Export Data", color = Color3.fromRGB(255, 255, 100), action = "export"},
        {text = "🔧 Settings", color = Color3.fromRGB(200, 100, 255), action = "settings"}
    }
    
    for i, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.action .. "Button"
        button.Size = UDim2.new(0.18, 0, 0.4, 0)
        button.Position = UDim2.new((i-1) * 0.2, 0, 0.1, 0)
        button.BackgroundColor3 = buttonData.color
        button.BorderSizePixel = 0
        button.Text = buttonData.text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSansBold
        button.Parent = buttonContainer
        
        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        -- Connect button action
        button.MouseButton1Click:Connect(function()
            self:handleButtonClick(buttonData.action)
        end)
        
        -- Hover effects
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.new(
                math.min(1, buttonData.color.R + 0.1),
                math.min(1, buttonData.color.G + 0.1),
                math.min(1, buttonData.color.B + 0.1)
            )
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = buttonData.color
        end)
    end
    
    -- Status indicator
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.55, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🟢 System Status: Healthy"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.Parent = buttonContainer
    
    self.statusLabel = statusLabel
end

-- Handle button clicks
function PerformanceDashboard:handleButtonClick(action)
    if action == "refresh" then
        self:refreshData()
        debugLog("Manual refresh triggered")
    elseif action == "clearCache" then
        self:clearCaches()
        debugLog("Cache clearing triggered")
    elseif action == "optimize" then
        self:performOptimization()
        debugLog("Optimization triggered")
    elseif action == "export" then
        self:exportData()
        debugLog("Data export triggered")
    elseif action == "settings" then
        self:openSettings()
        debugLog("Settings opened")
    end
end

-- Start refresh timer
function PerformanceDashboard:startRefreshTimer()
    if self.refreshConnection then
        self.refreshConnection:Disconnect()
    end
    
    self.refreshConnection = task.spawn(function()
        while self.isVisible do
            self:refreshData()
            task.wait(self.refreshInterval)
        end
    end)
    
    debugLog("Refresh timer started")
end

-- Refresh dashboard data
function PerformanceDashboard:refreshData()
    self:updateMetrics()
    self:updateAlerts()
    self:updateRecommendations()
    self:updateCharts()
    self:updateStatus()
end

-- Update metrics display
function PerformanceDashboard:updateMetrics()
    if not self.metricsContainer then return end
    
    -- Clear existing metrics
    for _, child in ipairs(self.metricsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get performance data
    local performanceMonitor = self.services and self.services["core.performance.PerformanceMonitor"]
    if not performanceMonitor then
        self:createMetricItem("❌ Performance Monitor", "Not Available", Color3.fromRGB(255, 100, 100), 0)
        return
    end
    
    local summary = performanceMonitor:getPerformanceSummary()
    local yPos = 0
    
    -- Display current metrics
    local metrics = {
        {label = "🚀 Response Time", value = string.format("%.1fms", summary.current.responseTime or 0), color = self:getMetricColor(summary.current.responseTime, 200, 500)},
        {label = "💾 Memory Usage", value = string.format("%.1fMB", summary.current.memoryUsage or 0), color = self:getMetricColor(summary.current.memoryUsage, 100, 200)},
        {label = "📊 Cache Hit Rate", value = string.format("%.1f%%", (summary.current.cacheHitRate or 0) * 100), color = self:getMetricColor((summary.current.cacheHitRate or 0) * 100, 70, 50, true)},
        {label = "⚡ Throughput", value = string.format("%.1f ops/s", summary.current.throughput and summary.current.throughput.operationsPerSecond or 0), color = Color3.fromRGB(100, 200, 255)},
        {label = "📈 Total Operations", value = tostring(summary.current.operationCounts and summary.current.operationCounts.total or 0), color = Color3.fromRGB(200, 200, 200)},
        {label = "❌ Error Rate", value = string.format("%.2f%%", (summary.current.errorRates or 0) * 100), color = self:getMetricColor((summary.current.errorRates or 0) * 100, 5, 10)}
    }
    
    for _, metric in ipairs(metrics) do
        self:createMetricItem(metric.label, metric.value, metric.color, yPos)
        yPos = yPos + 30
    end
    
    -- Update canvas size
    self.metricsContainer.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Create metric item
function PerformanceDashboard:createMetricItem(label, value, color, yPos)
    local metricFrame = Instance.new("Frame")
    metricFrame.Name = "MetricItem"
    metricFrame.Size = UDim2.new(1, -10, 0, 25)
    metricFrame.Position = UDim2.new(0, 5, 0, yPos)
    metricFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    metricFrame.BorderSizePixel = 0
    metricFrame.Parent = self.metricsContainer
    
    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(0.6, 0, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.TextScaled = true
    labelText.Font = Enum.Font.SourceSans
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = metricFrame
    
    local valueText = Instance.new("TextLabel")
    valueText.Name = "Value"
    valueText.Size = UDim2.new(0.35, 0, 1, 0)
    valueText.Position = UDim2.new(0.6, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = value
    valueText.TextColor3 = color
    valueText.TextScaled = true
    valueText.Font = Enum.Font.SourceSansBold
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Parent = metricFrame
end

-- Get metric color based on thresholds
function PerformanceDashboard:getMetricColor(value, warningThreshold, criticalThreshold, inverse)
    if not value then
        return Color3.fromRGB(128, 128, 128)
    end
    
    if inverse then
        -- For metrics where higher is better (like cache hit rate)
        if value >= warningThreshold then
            return Color3.fromRGB(100, 255, 100) -- Green
        elseif value >= criticalThreshold then
            return Color3.fromRGB(255, 255, 100) -- Yellow
        else
            return Color3.fromRGB(255, 100, 100) -- Red
        end
    else
        -- For metrics where lower is better (like response time)
        if value <= warningThreshold then
            return Color3.fromRGB(100, 255, 100) -- Green
        elseif value <= criticalThreshold then
            return Color3.fromRGB(255, 255, 100) -- Yellow
        else
            return Color3.fromRGB(255, 100, 100) -- Red
        end
    end
end

-- Update alerts display
function PerformanceDashboard:updateAlerts()
    if not self.alertsContainer then return end
    
    -- Clear existing alerts
    for _, child in ipairs(self.alertsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get alerts from performance monitor
    local performanceMonitor = self.services and self.services["core.performance.PerformanceMonitor"]
    if not performanceMonitor then
        self:createAlertItem("❌ No Performance Monitor", "Performance monitoring not available", "ERROR", 0)
        return
    end
    
    local summary = performanceMonitor:getPerformanceSummary()
    local alerts = summary.alerts or {}
    local yPos = 0
    
    if #alerts == 0 then
        self:createAlertItem("✅ All Clear", "No performance alerts", "INFO", 0)
        yPos = 30
    else
        for _, alert in ipairs(alerts) do
            self:createAlertItem(alert.message, self:formatTimestamp(alert.timestamp), alert.severity, yPos)
            yPos = yPos + 35
        end
    end
    
    -- Update canvas size
    self.alertsContainer.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Create alert item
function PerformanceDashboard:createAlertItem(message, timestamp, severity, yPos)
    local alertFrame = Instance.new("Frame")
    alertFrame.Name = "AlertItem"
    alertFrame.Size = UDim2.new(1, -10, 0, 30)
    alertFrame.Position = UDim2.new(0, 5, 0, yPos)
    alertFrame.BorderSizePixel = 1
    alertFrame.Parent = self.alertsContainer
    
    -- Set colors based on severity
    local bgColor, borderColor, textColor
    if severity == "CRITICAL" then
        bgColor = Color3.fromRGB(80, 40, 40)
        borderColor = Color3.fromRGB(255, 100, 100)
        textColor = Color3.fromRGB(255, 200, 200)
    elseif severity == "WARNING" then
        bgColor = Color3.fromRGB(80, 70, 40)
        borderColor = Color3.fromRGB(255, 255, 100)
        textColor = Color3.fromRGB(255, 255, 200)
    else
        bgColor = Color3.fromRGB(40, 60, 80)
        borderColor = Color3.fromRGB(100, 150, 255)
        textColor = Color3.fromRGB(200, 220, 255)
    end
    
    alertFrame.BackgroundColor3 = bgColor
    alertFrame.BorderColor3 = borderColor
    
    local messageText = Instance.new("TextLabel")
    messageText.Name = "Message"
    messageText.Size = UDim2.new(0.7, 0, 0.6, 0)
    messageText.Position = UDim2.new(0, 5, 0, 2)
    messageText.BackgroundTransparency = 1
    messageText.Text = message
    messageText.TextColor3 = textColor
    messageText.TextScaled = true
    messageText.Font = Enum.Font.SourceSansBold
    messageText.TextXAlignment = Enum.TextXAlignment.Left
    messageText.Parent = alertFrame
    
    local timestampText = Instance.new("TextLabel")
    timestampText.Name = "Timestamp"
    timestampText.Size = UDim2.new(1, -10, 0.4, 0)
    timestampText.Position = UDim2.new(0, 5, 0.6, 0)
    timestampText.BackgroundTransparency = 1
    timestampText.Text = timestamp
    timestampText.TextColor3 = Color3.fromRGB(150, 150, 150)
    timestampText.TextScaled = true
    timestampText.Font = Enum.Font.SourceSans
    timestampText.TextXAlignment = Enum.TextXAlignment.Left
    timestampText.Parent = alertFrame
end

-- Update recommendations display
function PerformanceDashboard:updateRecommendations()
    if not self.recommendationsContainer then return end
    
    -- Clear existing recommendations
    for _, child in ipairs(self.recommendationsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get recommendations from performance monitor
    local performanceMonitor = self.services and self.services["core.performance.PerformanceMonitor"]
    if not performanceMonitor then
        return
    end
    
    local summary = performanceMonitor:getPerformanceSummary()
    local recommendations = summary.recommendations or {}
    local yPos = 0
    
    if #recommendations == 0 then
        self:createRecommendationItem("✅ Optimal Performance", "System is running optimally", "success", 0)
        yPos = 35
    else
        for _, rec in ipairs(recommendations) do
            self:createRecommendationItem(rec.title, rec.description, rec.priority, yPos)
            yPos = yPos + 40
        end
    end
    
    -- Update canvas size
    self.recommendationsContainer.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Create recommendation item
function PerformanceDashboard:createRecommendationItem(title, description, priority, yPos)
    local recFrame = Instance.new("Frame")
    recFrame.Name = "RecommendationItem"
    recFrame.Size = UDim2.new(1, -10, 0, 35)
    recFrame.Position = UDim2.new(0, 5, 0, yPos)
    recFrame.BorderSizePixel = 1
    recFrame.Parent = self.recommendationsContainer
    
    -- Set colors based on priority
    local bgColor, borderColor, textColor
    if priority == "high" then
        bgColor = Color3.fromRGB(60, 80, 40)
        borderColor = Color3.fromRGB(150, 255, 100)
        textColor = Color3.fromRGB(200, 255, 150)
    elseif priority == "medium" then
        bgColor = Color3.fromRGB(60, 70, 40)
        borderColor = Color3.fromRGB(200, 200, 100)
        textColor = Color3.fromRGB(220, 220, 150)
    else
        bgColor = Color3.fromRGB(50, 60, 70)
        borderColor = Color3.fromRGB(100, 150, 200)
        textColor = Color3.fromRGB(150, 200, 220)
    end
    
    recFrame.BackgroundColor3 = bgColor
    recFrame.BorderColor3 = borderColor
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -10, 0.5, 0)
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = title
    titleText.TextColor3 = textColor
    titleText.TextScaled = true
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = recFrame
    
    local descText = Instance.new("TextLabel")
    descText.Name = "Description"
    descText.Size = UDim2.new(1, -10, 0.5, 0)
    descText.Position = UDim2.new(0, 5, 0.5, 0)
    descText.BackgroundTransparency = 1
    descText.Text = description
    descText.TextColor3 = Color3.fromRGB(180, 180, 180)
    descText.TextScaled = true
    descText.Font = Enum.Font.SourceSans
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.Parent = recFrame
end

-- Update charts display
function PerformanceDashboard:updateCharts()
    if not self.chartContainer then return end
    
    -- Simple text-based chart for now
    for _, child in ipairs(self.chartContainer:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local chartText = Instance.new("TextLabel")
    chartText.Name = "ChartPlaceholder"
    chartText.Size = UDim2.new(1, 0, 1, 0)
    chartText.Position = UDim2.new(0, 0, 0, 0)
    chartText.BackgroundTransparency = 1
    chartText.Text = "📊 Performance trends chart\n(Advanced charting coming soon)"
    chartText.TextColor3 = Color3.fromRGB(150, 150, 150)
    chartText.TextScaled = true
    chartText.Font = Enum.Font.SourceSans
    chartText.Parent = self.chartContainer
end

-- Update status display
function PerformanceDashboard:updateStatus()
    if not self.statusLabel then return end
    
    local performanceMonitor = self.services and self.services["core.performance.PerformanceMonitor"]
    if not performanceMonitor then
        self.statusLabel.Text = "🔴 System Status: Monitor Unavailable"
        self.statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    local summary = performanceMonitor:getPerformanceSummary()
    local status = summary.status or "UNKNOWN"
    
    if status == "HEALTHY" then
        self.statusLabel.Text = "🟢 System Status: Healthy"
        self.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif status == "WARNING" then
        self.statusLabel.Text = "🟡 System Status: Warning"
        self.statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    elseif status == "CRITICAL" then
        self.statusLabel.Text = "🔴 System Status: Critical"
        self.statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        self.statusLabel.Text = "🔵 System Status: Unknown"
        self.statusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    end
end

-- Clear all caches
function PerformanceDashboard:clearCaches()
    local cacheManager = self.services and self.services["core.data.modules.CacheManager"]
    if cacheManager then
        cacheManager:clearAllCaches()
        debugLog("All caches cleared")
    end
end

-- Perform optimization
function PerformanceDashboard:performOptimization()
    local performanceMonitor = self.services and self.services["core.performance.PerformanceMonitor"]
    if performanceMonitor then
        performanceMonitor:optimizePerformance()
        debugLog("Performance optimization triggered")
    end
    
    local cacheManager = self.services and self.services["core.data.modules.CacheManager"]
    if cacheManager then
        cacheManager:optimizeCache()
        debugLog("Cache optimization triggered")
    end
    
    local requestManager = self.services and self.services["core.data.modules.RequestManager"]
    if requestManager then
        requestManager:autoOptimize()
        debugLog("Request manager optimization triggered")
    end
end

-- Export performance data
function PerformanceDashboard:exportData()
    local performanceMonitor = self.services and self.services["core.performance.PerformanceMonitor"]
    if not performanceMonitor then
        debugLog("Cannot export: Performance monitor not available", "ERROR")
        return
    end
    
    local summary = performanceMonitor:getPerformanceSummary()
    local exportData = {
        timestamp = os.time(),
        performance = summary,
        exported_by = "DataStore Manager Pro Performance Dashboard"
    }
    
    -- In a real implementation, this would save to a file or copy to clipboard
    debugLog("Performance data exported (would save to file in production)")
    print("EXPORT DATA:", game:GetService("HttpService"):JSONEncode(exportData))
end

-- Open settings
function PerformanceDashboard:openSettings()
    debugLog("Settings panel would open here (not implemented in this demo)")
end

-- Format timestamp
function PerformanceDashboard:formatTimestamp(timestamp)
    if not timestamp then
        return "Unknown time"
    end
    
    local now = os.time()
    local diff = now - timestamp
    
    if diff < 60 then
        return string.format("%ds ago", diff)
    elseif diff < 3600 then
        return string.format("%dm ago", math.floor(diff / 60))
    else
        return string.format("%dh ago", math.floor(diff / 3600))
    end
end

-- Show dashboard
function PerformanceDashboard:show()
    if self.gui then
        self.gui.Visible = true
        self.isVisible = true
        self:startRefreshTimer()
        debugLog("Performance Dashboard shown")
    end
end

-- Hide dashboard
function PerformanceDashboard:hide()
    if self.gui then
        self.gui.Visible = false
        self.isVisible = false
        if self.refreshConnection then
            task.cancel(self.refreshConnection)
            self.refreshConnection = nil
        end
        debugLog("Performance Dashboard hidden")
    end
end

-- Cleanup
function PerformanceDashboard:cleanup()
    self:hide()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
    debugLog("Performance Dashboard cleanup complete")
end

return PerformanceDashboard 