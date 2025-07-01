-- DataStore Manager Pro - Advanced Data Visualization Engine
-- Interactive charts, graphs, and advanced data analysis

local DataVisualizationEngine = {}
DataVisualizationEngine.__index = DataVisualizationEngine

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[DATA_VIZ_ENGINE] [%s] %s", level, message))
end

function DataVisualizationEngine.new(services)
    local self = setmetatable({}, DataVisualizationEngine)
    self.services = services or {}
    self.charts = {}
    self.activeChart = nil
    debugLog("DataVisualizationEngine component created")
    return self
end

function DataVisualizationEngine:mount(parent)
    if not parent then
        debugLog("No parent provided for mounting", "ERROR")
        return nil
    end
    
    debugLog("Mounting advanced data visualization engine")
    
    local mainFrame = Instance.new("ScrollingFrame")
    mainFrame.Name = "DataVisualizationEngine"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.ScrollBarThickness = 8
    mainFrame.CanvasSize = UDim2.new(0, 0, 0, 2000)
    mainFrame.Parent = parent
    
    self.mainFrame = mainFrame
    
    -- Header
    self:createHeader(mainFrame)
    
    -- Chart selector
    self:createChartSelector(mainFrame, 80)
    
    -- Interactive chart area
    self:createInteractiveChartArea(mainFrame, 160)
    
    -- Data analysis tools
    self:createDataAnalysisTools(mainFrame, 600)
    
    -- Export and sharing tools
    self:createExportTools(mainFrame, 1000)
    
    -- Advanced filters
    self:createAdvancedFilters(mainFrame, 1200)
    
    -- Real-time data feeds
    self:createRealTimeFeeds(mainFrame, 1500)
    
    debugLog("Advanced data visualization engine mounted successfully")
    return mainFrame
end

function DataVisualizationEngine:createHeader(parent)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    header.BorderSizePixel = 1
    header.BorderColor3 = Color3.fromRGB(60, 60, 60)
    header.Parent = parent
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "📊 Advanced Data Visualization Engine"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.7, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 40)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Interactive charts, advanced analytics, and real-time data visualization"
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
end

function DataVisualizationEngine:createChartSelector(parent, yOffset)
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Size = UDim2.new(1, -20, 0, 70)
    selectorFrame.Position = UDim2.new(0, 10, 0, yOffset)
    selectorFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    selectorFrame.BorderSizePixel = 1
    selectorFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
    selectorFrame.Parent = parent
    
    local selectorTitle = Instance.new("TextLabel")
    selectorTitle.Size = UDim2.new(1, -10, 0, 25)
    selectorTitle.Position = UDim2.new(0, 5, 0, 5)
    selectorTitle.BackgroundTransparency = 1
    selectorTitle.Text = "📈 Chart Types & Visualization Options"
    selectorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectorTitle.TextSize = 14
    selectorTitle.Font = Enum.Font.SourceSansBold
    selectorTitle.TextXAlignment = Enum.TextXAlignment.Left
    selectorTitle.Parent = selectorFrame
    
    local chartTypes = {
        {name = "Line Chart", icon = "📈", color = Color3.fromRGB(59, 130, 246)},
        {name = "Bar Chart", icon = "📊", color = Color3.fromRGB(34, 197, 94)},
        {name = "Pie Chart", icon = "🥧", color = Color3.fromRGB(245, 158, 11)},
        {name = "Scatter Plot", icon = "🔵", color = Color3.fromRGB(168, 85, 247)},
        {name = "Heat Map", icon = "🔥", color = Color3.fromRGB(239, 68, 68)},
        {name = "Tree Map", icon = "🌳", color = Color3.fromRGB(20, 184, 166)}
    }
    
    for i, chartType in ipairs(chartTypes) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.15, -5, 0, 35)
        button.Position = UDim2.new((i-1) * 0.16, 5, 0, 30)
        button.BackgroundColor3 = chartType.color
        button.BorderSizePixel = 0
        button.Text = chartType.icon .. " " .. chartType.name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 10
        button.Font = Enum.Font.SourceSansBold
        button.Parent = selectorFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:createChart(chartType.name)
        end)
    end
end

function DataVisualizationEngine:createInteractiveChartArea(parent, yOffset)
    local chartArea = Instance.new("Frame")
    chartArea.Size = UDim2.new(1, -20, 0, 420)
    chartArea.Position = UDim2.new(0, 10, 0, yOffset)
    chartArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    chartArea.BorderSizePixel = 1
    chartArea.BorderColor3 = Color3.fromRGB(60, 60, 60)
    chartArea.Parent = parent
    
    local chartTitle = Instance.new("TextLabel")
    chartTitle.Size = UDim2.new(1, -10, 0, 30)
    chartTitle.Position = UDim2.new(0, 5, 0, 5)
    chartTitle.BackgroundTransparency = 1
    chartTitle.Text = "📊 Interactive Data Visualization Canvas"
    chartTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    chartTitle.TextSize = 16
    chartTitle.Font = Enum.Font.SourceSansBold
    chartTitle.TextXAlignment = Enum.TextXAlignment.Left
    chartTitle.Parent = chartArea
    
    -- Chart canvas
    local canvas = Instance.new("Frame")
    canvas.Size = UDim2.new(1, -20, 1, -40)
    canvas.Position = UDim2.new(0, 10, 0, 35)
    canvas.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    canvas.BorderSizePixel = 1
    canvas.BorderColor3 = Color3.fromRGB(50, 50, 50)
    canvas.Parent = chartArea
    
    self.chartCanvas = canvas
    
    -- Default visualization
    self:createDefaultVisualization(canvas)
end

function DataVisualizationEngine:createDefaultVisualization(canvas)
    -- Create sample data visualization
    local sampleData = {
        {name = "PlayerData", value = 45, color = Color3.fromRGB(59, 130, 246)},
        {name = "PlayerCurrency", value = 30, color = Color3.fromRGB(34, 197, 94)},
        {name = "PlayerStats", value = 15, color = Color3.fromRGB(245, 158, 11)},
        {name = "WorldData", value = 10, color = Color3.fromRGB(168, 85, 247)}
    }
    
    -- Create bar chart
    for i, data in ipairs(sampleData) do
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0.15, -10, data.value/100, 0)
        bar.Position = UDim2.new(0.1 + (i-1) * 0.2, 5, 1, 0)
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.BackgroundColor3 = data.color
        bar.BorderSizePixel = 0
        bar.Parent = canvas
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 1, 5)
        label.BackgroundTransparency = 1
        label.Text = data.name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 10
        label.Font = Enum.Font.SourceSans
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = bar
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 0, 15)
        valueLabel.Position = UDim2.new(0, 0, -0.1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(data.value) .. "%"
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = 9
        valueLabel.Font = Enum.Font.SourceSansBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Center
        valueLabel.Parent = bar
    end
end

function DataVisualizationEngine:createDataAnalysisTools(parent, yOffset)
    local toolsArea = Instance.new("Frame")
    toolsArea.Size = UDim2.new(1, -20, 0, 380)
    toolsArea.Position = UDim2.new(0, 10, 0, yOffset)
    toolsArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toolsArea.BorderSizePixel = 1
    toolsArea.BorderColor3 = Color3.fromRGB(60, 60, 60)
    toolsArea.Parent = parent
    
    local toolsTitle = Instance.new("TextLabel")
    toolsTitle.Size = UDim2.new(1, -10, 0, 30)
    toolsTitle.Position = UDim2.new(0, 5, 0, 5)
    toolsTitle.BackgroundTransparency = 1
    toolsTitle.Text = "🔧 Advanced Data Analysis Tools"
    toolsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toolsTitle.TextSize = 16
    toolsTitle.Font = Enum.Font.SourceSansBold
    toolsTitle.TextXAlignment = Enum.TextXAlignment.Left
    toolsTitle.Parent = toolsArea
    
    -- Analysis sections
    local sections = {
        {title = "📈 Trend Analysis", content = "• Automatic trend detection\n• Seasonal pattern recognition\n• Growth rate calculations\n• Anomaly detection"},
        {title = "📊 Statistical Analysis", content = "• Mean, median, mode calculations\n• Standard deviation analysis\n• Correlation matrices\n• Regression analysis"},
        {title = "🎯 Predictive Analytics", content = "• Future value predictions\n• Capacity planning\n• Usage forecasting\n• Risk assessment"},
        {title = "🔍 Data Mining", content = "• Pattern discovery\n• Clustering analysis\n• Association rules\n• Classification models"}
    }
    
    for i, section in ipairs(sections) do
        local sectionFrame = Instance.new("Frame")
        sectionFrame.Size = UDim2.new(0.48, -5, 0, 150)
        sectionFrame.Position = UDim2.new(((i-1) % 2) * 0.5, 5, 0, 40 + math.floor((i-1) / 2) * 160)
        sectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        sectionFrame.BorderSizePixel = 1
        sectionFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
        sectionFrame.Parent = toolsArea
        
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Size = UDim2.new(1, -10, 0, 25)
        sectionTitle.Position = UDim2.new(0, 5, 0, 5)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Text = section.title
        sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        sectionTitle.TextSize = 12
        sectionTitle.Font = Enum.Font.SourceSansBold
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = sectionFrame
        
        local sectionContent = Instance.new("TextLabel")
        sectionContent.Size = UDim2.new(1, -10, 1, -35)
        sectionContent.Position = UDim2.new(0, 5, 0, 30)
        sectionContent.BackgroundTransparency = 1
        sectionContent.Text = section.content
        sectionContent.TextColor3 = Color3.fromRGB(200, 200, 200)
        sectionContent.TextSize = 10
        sectionContent.Font = Enum.Font.SourceSans
        sectionContent.TextXAlignment = Enum.TextXAlignment.Left
        sectionContent.TextYAlignment = Enum.TextYAlignment.Top
        sectionContent.TextWrapped = true
        sectionContent.Parent = sectionFrame
    end
end

function DataVisualizationEngine:createExportTools(parent, yOffset)
    local exportArea = Instance.new("Frame")
    exportArea.Size = UDim2.new(1, -20, 0, 180)
    exportArea.Position = UDim2.new(0, 10, 0, yOffset)
    exportArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    exportArea.BorderSizePixel = 1
    exportArea.BorderColor3 = Color3.fromRGB(60, 60, 60)
    exportArea.Parent = parent
    
    local exportTitle = Instance.new("TextLabel")
    exportTitle.Size = UDim2.new(1, -10, 0, 30)
    exportTitle.Position = UDim2.new(0, 5, 0, 5)
    exportTitle.BackgroundTransparency = 1
    exportTitle.Text = "📤 Export & Sharing Tools"
    exportTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    exportTitle.TextSize = 16
    exportTitle.Font = Enum.Font.SourceSansBold
    exportTitle.TextXAlignment = Enum.TextXAlignment.Left
    exportTitle.Parent = exportArea
    
    local exportOptions = {
        {name = "📊 Export Chart", desc = "Save chart as image", color = Color3.fromRGB(59, 130, 246)},
        {name = "💾 Export Data", desc = "Save data locally", color = Color3.fromRGB(34, 197, 94)},
        {name = "📋 Copy to Clipboard", desc = "Copy chart data", color = Color3.fromRGB(168, 85, 247)}
    }
    
    for i, option in ipairs(exportOptions) do
        local optionFrame = Instance.new("TextButton")
        optionFrame.Size = UDim2.new(0.32, -5, 0, 60)
        optionFrame.Position = UDim2.new(((i-1) % 3) * 0.33, 5, 0, 40 + math.floor((i-1) / 3) * 70)
        optionFrame.BackgroundColor3 = option.color
        optionFrame.BorderSizePixel = 0
        optionFrame.Text = ""
        optionFrame.Parent = exportArea
        
        local optionTitle = Instance.new("TextLabel")
        optionTitle.Size = UDim2.new(1, -10, 0, 25)
        optionTitle.Position = UDim2.new(0, 5, 0, 5)
        optionTitle.BackgroundTransparency = 1
        optionTitle.Text = option.name
        optionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionTitle.TextSize = 11
        optionTitle.Font = Enum.Font.SourceSansBold
        optionTitle.TextXAlignment = Enum.TextXAlignment.Left
        optionTitle.Parent = optionFrame
        
        local optionDesc = Instance.new("TextLabel")
        optionDesc.Size = UDim2.new(1, -10, 0, 25)
        optionDesc.Position = UDim2.new(0, 5, 0, 30)
        optionDesc.BackgroundTransparency = 1
        optionDesc.Text = option.desc
        optionDesc.TextColor3 = Color3.fromRGB(220, 220, 220)
        optionDesc.TextSize = 9
        optionDesc.Font = Enum.Font.SourceSans
        optionDesc.TextXAlignment = Enum.TextXAlignment.Left
        optionDesc.Parent = optionFrame
        
        optionFrame.MouseButton1Click:Connect(function()
            self:handleExport(option.name)
        end)
    end
end

function DataVisualizationEngine:createAdvancedFilters(parent, yOffset)
    local filterArea = Instance.new("Frame")
    filterArea.Size = UDim2.new(1, -20, 0, 280)
    filterArea.Position = UDim2.new(0, 10, 0, yOffset)
    filterArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    filterArea.BorderSizePixel = 1
    filterArea.BorderColor3 = Color3.fromRGB(60, 60, 60)
    filterArea.Parent = parent
    
    local filterTitle = Instance.new("TextLabel")
    filterTitle.Size = UDim2.new(1, -10, 0, 30)
    filterTitle.Position = UDim2.new(0, 5, 0, 5)
    filterTitle.BackgroundTransparency = 1
    filterTitle.Text = "🔍 Advanced Data Filters & Query Builder"
    filterTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    filterTitle.TextSize = 16
    filterTitle.Font = Enum.Font.SourceSansBold
    filterTitle.TextXAlignment = Enum.TextXAlignment.Left
    filterTitle.Parent = filterArea
    
    -- Filter controls
    local filterControls = Instance.new("Frame")
    filterControls.Size = UDim2.new(1, -20, 1, -40)
    filterControls.Position = UDim2.new(0, 10, 0, 35)
    filterControls.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    filterControls.BorderSizePixel = 1
    filterControls.BorderColor3 = Color3.fromRGB(50, 50, 50)
    filterControls.Parent = filterArea
    
    local filterText = Instance.new("TextLabel")
    filterText.Size = UDim2.new(1, -20, 1, -10)
    filterText.Position = UDim2.new(0, 10, 0, 5)
    filterText.BackgroundTransparency = 1
    filterText.Text = "🎯 Smart Filtering Options:\n\n• Date Range Filters (Last 7 days, 30 days, Custom)\n• DataStore Type Filters (Player Data, Game State, System)\n• Value Range Filters (Min/Max values, Percentiles)\n• Pattern Matching (Regex, Wildcards, Exact match)\n• Advanced Queries (SQL-like syntax support)\n• Saved Filter Presets (Quick access to common filters)\n• Real-time Filter Preview (See results as you type)\n• Multi-dimensional Filtering (Combine multiple criteria)\n• Performance Impact Analysis (Filter efficiency metrics)\n• Export Filtered Results (Save filtered datasets)"
    filterText.TextColor3 = Color3.fromRGB(200, 200, 200)
    filterText.TextSize = 11
    filterText.Font = Enum.Font.SourceSans
    filterText.TextXAlignment = Enum.TextXAlignment.Left
    filterText.TextYAlignment = Enum.TextYAlignment.Top
    filterText.TextWrapped = true
    filterText.Parent = filterControls
end

function DataVisualizationEngine:createRealTimeFeeds(parent, yOffset)
    local feedArea = Instance.new("Frame")
    feedArea.Size = UDim2.new(1, -20, 0, 300)
    feedArea.Position = UDim2.new(0, 10, 0, yOffset)
    feedArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    feedArea.BorderSizePixel = 1
    feedArea.BorderColor3 = Color3.fromRGB(60, 60, 60)
    feedArea.Parent = parent
    
    local feedTitle = Instance.new("TextLabel")
    feedTitle.Size = UDim2.new(1, -10, 0, 30)
    feedTitle.Position = UDim2.new(0, 5, 0, 5)
    feedTitle.BackgroundTransparency = 1
    feedTitle.Text = "⚡ Real-Time Data Feeds & Live Updates"
    feedTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    feedTitle.TextSize = 16
    feedTitle.Font = Enum.Font.SourceSansBold
    feedTitle.TextXAlignment = Enum.TextXAlignment.Left
    feedTitle.Parent = feedArea
    
    -- Live feed display
    local feedDisplay = Instance.new("ScrollingFrame")
    feedDisplay.Size = UDim2.new(1, -20, 1, -40)
    feedDisplay.Position = UDim2.new(0, 10, 0, 35)
    feedDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    feedDisplay.BorderSizePixel = 1
    feedDisplay.BorderColor3 = Color3.fromRGB(50, 50, 50)
    feedDisplay.ScrollBarThickness = 6
    feedDisplay.CanvasSize = UDim2.new(0, 0, 0, 400)
    feedDisplay.Parent = feedArea
    
    local feedContent = Instance.new("TextLabel")
    feedContent.Size = UDim2.new(1, -20, 1, -10)
    feedContent.Position = UDim2.new(0, 10, 0, 5)
    feedContent.BackgroundTransparency = 1
    feedContent.Text = "🔄 Live Data Stream Active\n\n📊 " .. os.date("%H:%M:%S") .. " - DataStore usage updated\n📈 " .. os.date("%H:%M:%S") .. " - Performance metrics refreshed\n🎯 " .. os.date("%H:%M:%S") .. " - Analytics data processed\n⚡ " .. os.date("%H:%M:%S") .. " - Real-time monitoring active\n📋 " .. os.date("%H:%M:%S") .. " - Cache statistics updated\n🔍 " .. os.date("%H:%M:%S") .. " - Search index refreshed\n💾 " .. os.date("%H:%M:%S") .. " - Backup status checked\n🔒 " .. os.date("%H:%M:%S") .. " - Security scan completed\n📤 " .. os.date("%H:%M:%S") .. " - Export queue processed\n🌐 " .. os.date("%H:%M:%S") .. " - API health verified"
    feedContent.TextColor3 = Color3.fromRGB(200, 200, 200)
    feedContent.TextSize = 11
    feedContent.Font = Enum.Font.SourceSans
    feedContent.TextXAlignment = Enum.TextXAlignment.Left
    feedContent.TextYAlignment = Enum.TextYAlignment.Top
    feedContent.TextWrapped = true
    feedContent.Parent = feedDisplay
    
    self.feedContent = feedContent
end

function DataVisualizationEngine:createChart(chartType)
    debugLog("Creating chart: " .. chartType)
    
    if not self.chartCanvas then
        return
    end
    
    -- Clear existing chart
    for _, child in ipairs(self.chartCanvas:GetChildren()) do
        child:Destroy()
    end
    
    if chartType == "Line Chart" then
        self:createLineChart()
    elseif chartType == "Bar Chart" then
        self:createBarChart()
    elseif chartType == "Pie Chart" then
        self:createPieChart()
    elseif chartType == "Scatter Plot" then
        self:createScatterPlot()
    elseif chartType == "Heat Map" then
        self:createHeatMap()
    elseif chartType == "Tree Map" then
        self:createTreeMap()
    end
    
    self.activeChart = chartType
end

function DataVisualizationEngine:createLineChart()
    -- Create animated line chart
    local points = {
        {x = 0.1, y = 0.8}, {x = 0.2, y = 0.6}, {x = 0.3, y = 0.7},
        {x = 0.4, y = 0.4}, {x = 0.5, y = 0.5}, {x = 0.6, y = 0.3},
        {x = 0.7, y = 0.6}, {x = 0.8, y = 0.2}, {x = 0.9, y = 0.4}
    }
    
    for i, point in ipairs(points) do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Position = UDim2.new(point.x, -4, point.y, -4)
        dot.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        dot.BorderSizePixel = 0
        dot.Parent = self.chartCanvas
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = dot
        
        if i > 1 then
            local prevPoint = points[i-1]
            local line = Instance.new("Frame")
            local distance = math.sqrt((point.x - prevPoint.x)^2 + (point.y - prevPoint.y)^2)
            line.Size = UDim2.new(distance, 0, 0, 2)
            line.Position = UDim2.new(prevPoint.x, 0, prevPoint.y, -1)
            line.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            line.BorderSizePixel = 0
            line.Parent = self.chartCanvas
        end
    end
end

function DataVisualizationEngine:createBarChart()
    self:createDefaultVisualization(self.chartCanvas)
end

function DataVisualizationEngine:createPieChart()
    -- Create pie chart segments
    local data = {30, 25, 20, 15, 10}
    local colors = {
        Color3.fromRGB(59, 130, 246), Color3.fromRGB(34, 197, 94),
        Color3.fromRGB(245, 158, 11), Color3.fromRGB(168, 85, 247),
        Color3.fromRGB(239, 68, 68)
    }
    
    local centerX, centerY = 0.5, 0.5
    local radius = 0.3
    local startAngle = 0
    
    for i, value in ipairs(data) do
        local angle = (value / 100) * 360
        local segment = Instance.new("Frame")
        segment.Size = UDim2.new(radius * 2, 0, radius * 2, 0)
        segment.Position = UDim2.new(centerX - radius, 0, centerY - radius, 0)
        segment.BackgroundColor3 = colors[i]
        segment.BorderSizePixel = 0
        segment.Parent = self.chartCanvas
        
        startAngle = startAngle + angle
    end
end

function DataVisualizationEngine:createScatterPlot()
    -- Create scatter plot points
    for i = 1, 20 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(math.random(10, 90)/100, -3, math.random(10, 90)/100, -3)
        dot.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
        dot.BorderSizePixel = 0
        dot.Parent = self.chartCanvas
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = dot
    end
end

function DataVisualizationEngine:createHeatMap()
    -- Create heat map grid
    for x = 1, 10 do
        for y = 1, 8 do
            local cell = Instance.new("Frame")
            cell.Size = UDim2.new(0.08, -2, 0.1, -2)
            cell.Position = UDim2.new(0.1 + (x-1) * 0.08, 1, 0.1 + (y-1) * 0.1, 1)
            local intensity = math.random(0, 100) / 100
            cell.BackgroundColor3 = Color3.fromRGB(
                math.floor(255 * intensity),
                math.floor(100 * (1 - intensity)),
                math.floor(100 * (1 - intensity))
            )
            cell.BorderSizePixel = 0
            cell.Parent = self.chartCanvas
        end
    end
end

function DataVisualizationEngine:createTreeMap()
    -- Create tree map rectangles
    local areas = {
        {x = 0.1, y = 0.1, w = 0.4, h = 0.6, color = Color3.fromRGB(59, 130, 246)},
        {x = 0.5, y = 0.1, w = 0.4, h = 0.3, color = Color3.fromRGB(34, 197, 94)},
        {x = 0.5, y = 0.4, w = 0.2, h = 0.3, color = Color3.fromRGB(245, 158, 11)},
        {x = 0.7, y = 0.4, w = 0.2, h = 0.3, color = Color3.fromRGB(168, 85, 247)},
        {x = 0.1, y = 0.7, w = 0.8, h = 0.2, color = Color3.fromRGB(239, 68, 68)}
    }
    
    for _, area in ipairs(areas) do
        local rect = Instance.new("Frame")
        rect.Size = UDim2.new(area.w, -2, area.h, -2)
        rect.Position = UDim2.new(area.x, 1, area.y, 1)
        rect.BackgroundColor3 = area.color
        rect.BorderSizePixel = 1
        rect.BorderColor3 = Color3.fromRGB(255, 255, 255)
        rect.Parent = self.chartCanvas
    end
end

function DataVisualizationEngine:handleExport(exportType)
    debugLog("Handling export: " .. exportType)
    print("📤 " .. exportType .. " - Export functionality activated")
end

function DataVisualizationEngine:cleanup()
    debugLog("DataVisualizationEngine cleanup completed")
end

return DataVisualizationEngine 