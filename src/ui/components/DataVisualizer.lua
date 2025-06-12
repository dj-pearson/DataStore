-- DataVisualizer Component - Native Roblox UI Implementation
local DataVisualizer = {}
DataVisualizer.__index = DataVisualizer

function DataVisualizer.new(props)
    local self = setmetatable({}, DataVisualizer)
    
    self.props = props or {}
    self.analyticsService = props.analyticsService
    self.onExportData = props.onExportData
    self.services = props.services
    
    -- State
    self.selectedStore = nil
    self.selectedMetric = "requests"
    self.selectedChartType = "line"
    self.timeRange = "1h"
    self.data = {}
    self.loading = false
    
    -- Available metrics
    self.metrics = {
        requests = { name = "Requests", unit = "requests", color = Color3.fromRGB(0, 120, 215) },
        size = { name = "Data Size", unit = "bytes", color = Color3.fromRGB(0, 180, 120) },
        errors = { name = "Errors", unit = "errors", color = Color3.fromRGB(215, 60, 60) },
        responseTime = { name = "Response Time", unit = "ms", color = Color3.fromRGB(180, 120, 0) },
        cacheHits = { name = "Cache Hits", unit = "hits", color = Color3.fromRGB(120, 60, 180) },
        budgetUsage = { name = "Budget Usage", unit = "%", color = Color3.fromRGB(60, 120, 180) }
    }
    
    -- Chart types
    self.chartTypes = {
        line = { name = "Line Chart", icon = "📈" },
        bar = { name = "Bar Chart", icon = "📊" },
        pie = { name = "Pie Chart", icon = "🥧" }
    }
    
    return self
end

function DataVisualizer:mount(parent)
    self.parent = parent
    self:createUI()
    self:loadData()
end

function DataVisualizer:createUI()
    -- Main container
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "DataVisualizerFrame"
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.parent
    
    -- Header
    self:createHeader()
    
    -- Controls
    self:createControls()
    
    -- Chart area
    self:createChartArea()
    
    -- Stats panel
    self:createStatsPanel()
end

function DataVisualizer:createHeader()
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    header.BorderSizePixel = 0
    header.Parent = self.mainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "📊 Data Analytics Dashboard"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
end

function DataVisualizer:createControls()
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(1, 0, 0, 80)
    controls.Position = UDim2.new(0, 0, 0, 60)
    controls.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    controls.BorderSizePixel = 0
    controls.Parent = self.mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = controls
    
    -- Metric selector
    self:createDropdown(controls, "Metric", self.metrics, self.selectedMetric, function(value)
        self.selectedMetric = value
        self:loadData()
    end)
    
    -- Chart type selector
    self:createDropdown(controls, "Chart Type", self.chartTypes, self.selectedChartType, function(value)
        self.selectedChartType = value
        self:updateChart()
    end)
    
    -- Time range selector
    local timeRanges = {
        ["1h"] = { name = "Last Hour" },
        ["24h"] = { name = "Last 24 Hours" },
        ["7d"] = { name = "Last 7 Days" }
    }
    self:createDropdown(controls, "Time Range", timeRanges, self.timeRange, function(value)
        self.timeRange = value
        self:loadData()
    end)
    
    -- Export button
    self:createButton(controls, "Export Data", function()
        if self.onExportData then
            self.onExportData(self.data)
        end
    end)
end

function DataVisualizer:createDropdown(parent, label, options, selected, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 150, 1, -20)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, 0, 0, 20)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelText.TextSize = 12
    labelText.Font = Enum.Font.SourceSans
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = container
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.Position = UDim2.new(0, 0, 0, 25)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(100, 100, 100)
    button.Text = options[selected] and options[selected].name or selected
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSans
    button.Parent = container
    
    -- Simple dropdown behavior (cycles through options)
    button.MouseButton1Click:Connect(function()
        local keys = {}
        for key, _ in pairs(options) do
            table.insert(keys, key)
        end
        
        local currentIndex = 1
        for i, key in ipairs(keys) do
            if key == selected then
                currentIndex = i
                break
            end
        end
        
        local nextIndex = (currentIndex % #keys) + 1
        local nextKey = keys[nextIndex]
        button.Text = options[nextKey].name
        callback(nextKey)
    end)
end

function DataVisualizer:createButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSans
    button.Parent = parent
    
    button.MouseButton1Click:Connect(callback)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(0, 140, 235)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end)
end

function DataVisualizer:createChartArea()
    local chartArea = Instance.new("Frame")
    chartArea.Name = "ChartArea"
    chartArea.Size = UDim2.new(0.7, -10, 1, -150)
    chartArea.Position = UDim2.new(0, 10, 0, 140)
    chartArea.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    chartArea.BorderSizePixel = 1
    chartArea.BorderColor3 = Color3.fromRGB(100, 100, 100)
    chartArea.Parent = self.mainFrame
    
    self.chartFrame = chartArea
    self:updateChart()
end

function DataVisualizer:createStatsPanel()
    local statsPanel = Instance.new("Frame")
    statsPanel.Name = "StatsPanel"
    statsPanel.Size = UDim2.new(0.3, -10, 1, -150)
    statsPanel.Position = UDim2.new(0.7, 0, 0, 140)
    statsPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    statsPanel.BorderSizePixel = 1
    statsPanel.BorderColor3 = Color3.fromRGB(100, 100, 100)
    statsPanel.Parent = self.mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Statistics"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = statsPanel
    
    self.statsFrame = statsPanel
    self:updateStats()
end

function DataVisualizer:loadData()
    self.loading = true
    
    -- Generate mock data for demonstration
    local mockData = {}
    local timePoints = 20
    local baseValue = 100
    
    for i = 1, timePoints do
        local timestamp = os.time() - (timePoints - i) * 300 -- 5-minute intervals
        local value = baseValue + math.random(-20, 20) + math.sin(i / 3) * 10
        
        table.insert(mockData, {
            timestamp = timestamp,
            value = math.max(0, value)
        })
    end
    
    self.data = mockData
    self.loading = false
    
    self:updateChart()
    self:updateStats()
end

function DataVisualizer:updateChart()
    if not self.chartFrame then return end
    
    -- Clear existing chart
    for _, child in ipairs(self.chartFrame:GetChildren()) do
        if child.Name ~= "UICorner" then
            child:Destroy()
        end
    end
    
    -- Create simple chart visualization
    local chartTitle = Instance.new("TextLabel")
    chartTitle.Size = UDim2.new(1, -20, 0, 30)
    chartTitle.Position = UDim2.new(0, 10, 0, 10)
    chartTitle.BackgroundTransparency = 1
    chartTitle.Text = string.format("%s - %s", 
        self.metrics[self.selectedMetric].name,
        self.chartTypes[self.selectedChartType].name
    )
    chartTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    chartTitle.TextSize = 14
    chartTitle.Font = Enum.Font.SourceSansBold
    chartTitle.TextXAlignment = Enum.TextXAlignment.Left
    chartTitle.Parent = self.chartFrame
    
    -- Simple data visualization
    if #self.data > 0 then
        self:drawSimpleChart()
    else
        local noDataLabel = Instance.new("TextLabel")
        noDataLabel.Size = UDim2.new(1, 0, 1, -40)
        noDataLabel.Position = UDim2.new(0, 0, 0, 40)
        noDataLabel.BackgroundTransparency = 1
        noDataLabel.Text = "No data available"
        noDataLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noDataLabel.TextSize = 16
        noDataLabel.Font = Enum.Font.SourceSans
        noDataLabel.Parent = self.chartFrame
    end
end

function DataVisualizer:drawSimpleChart()
    local chartContainer = Instance.new("Frame")
    chartContainer.Size = UDim2.new(1, -40, 1, -80)
    chartContainer.Position = UDim2.new(0, 20, 0, 50)
    chartContainer.BackgroundTransparency = 1
    chartContainer.Parent = self.chartFrame
    
    if self.selectedChartType == "line" then
        self:drawLineChart(chartContainer)
    elseif self.selectedChartType == "bar" then
        self:drawBarChart(chartContainer)
    else
        self:drawPlaceholderChart(chartContainer)
    end
end

function DataVisualizer:drawLineChart(container)
    local maxValue = 0
    for _, point in ipairs(self.data) do
        maxValue = math.max(maxValue, point.value)
    end
    
    for i = 1, #self.data - 1 do
        local point1 = self.data[i]
        local point2 = self.data[i + 1]
        
        local x1 = (i - 1) / (#self.data - 1)
        local y1 = 1 - (point1.value / maxValue)
        local x2 = i / (#self.data - 1)
        local y2 = 1 - (point2.value / maxValue)
        
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 2, 0, math.abs(y2 - y1) * container.AbsoluteSize.Y + 10)
        line.Position = UDim2.new(x1, 0, math.min(y1, y2), 0)
        line.BackgroundColor3 = self.metrics[self.selectedMetric].color
        line.BorderSizePixel = 0
        line.Parent = container
    end
end

function DataVisualizer:drawBarChart(container)
    local maxValue = 0
    for _, point in ipairs(self.data) do
        maxValue = math.max(maxValue, point.value)
    end
    
    local barWidth = 1 / #self.data * 0.8
    
    for i, point in ipairs(self.data) do
        local height = point.value / maxValue
        local x = (i - 1) / #self.data + (1 / #self.data - barWidth) / 2
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(barWidth, 0, height, 0)
        bar.Position = UDim2.new(x, 0, 1 - height, 0)
        bar.BackgroundColor3 = self.metrics[self.selectedMetric].color
        bar.BorderSizePixel = 0
        bar.Parent = container
    end
end

function DataVisualizer:drawPlaceholderChart(container)
    local placeholder = Instance.new("TextLabel")
    placeholder.Size = UDim2.new(1, 0, 1, 0)
    placeholder.BackgroundTransparency = 1
    placeholder.Text = string.format("%s Chart\n(Implementation in progress)", 
        self.chartTypes[self.selectedChartType].name)
    placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
    placeholder.TextSize = 16
    placeholder.Font = Enum.Font.SourceSans
    placeholder.Parent = container
end

function DataVisualizer:updateStats()
    if not self.statsFrame then return end
    
    -- Clear existing stats
    for _, child in ipairs(self.statsFrame:GetChildren()) do
        if child.Name ~= "UICorner" and not child.Name:find("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Calculate stats
    local total = 0
    local min = math.huge
    local max = -math.huge
    
    for _, point in ipairs(self.data) do
        total = total + point.value
        min = math.min(min, point.value)
        max = math.max(max, point.value)
    end
    
    local average = #self.data > 0 and total / #self.data or 0
    
    local stats = {
        { label = "Total", value = string.format("%.0f", total) },
        { label = "Average", value = string.format("%.1f", average) },
        { label = "Minimum", value = string.format("%.0f", min == math.huge and 0 or min) },
        { label = "Maximum", value = string.format("%.0f", max == -math.huge and 0 or max) },
        { label = "Data Points", value = tostring(#self.data) }
    }
    
    for i, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(1, -20, 0, 30)
        statFrame.Position = UDim2.new(0, 10, 0, 40 + (i - 1) * 35)
        statFrame.BackgroundTransparency = 1
        statFrame.Parent = self.statsFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = stat.label .. ":"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.TextSize = 12
        label.Font = Enum.Font.SourceSans
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = statFrame
        
        local value = Instance.new("TextLabel")
        value.Size = UDim2.new(0.4, 0, 1, 0)
        value.Position = UDim2.new(0.6, 0, 0, 0)
        value.BackgroundTransparency = 1
        value.Text = stat.value
        value.TextColor3 = Color3.fromRGB(255, 255, 255)
        value.TextSize = 12
        value.Font = Enum.Font.SourceSansBold
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Parent = statFrame
    end
end

function DataVisualizer:destroy()
    if self.mainFrame then
        self.mainFrame:Destroy()
    end
end

return DataVisualizer 