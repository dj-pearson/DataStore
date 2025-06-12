local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local UI = Framework.UI
local Button = UI.Button
local SelectInput = UI.SelectInput
local Chart = UI.Chart
local Table = UI.Table

local DataVisualizer = Roact.PureComponent:extend("DataVisualizer")

function DataVisualizer:init()
    self.state = {
        selectedStore = nil,
        selectedMetric = "requests",
        selectedChartType = "line",
        timeRange = "1h",
        data = {},
        loading = false,
        showDistribution = false,
        showTrends = false,
        customWidgets = {},
        zoomLevel = 1,
        panOffset = Vector2.new(0, 0),
        selectedPoint = nil,
        hoveredPoint = nil,
        annotations = {},
        isDragging = false,
        dragStart = Vector2.new(0, 0),
        showTooltip = false,
        tooltipPosition = Vector2.new(0, 0),
        tooltipData = nil,
        comparisonPoints = {},
        selectedRegion = nil,
        regionStart = nil,
        regionEnd = nil,
        isSelectingRegion = false,
        showComparison = false,
        comparisonMetrics = {},
        regionAnnotations = {}
    }

    -- Available metrics with descriptions and units
    self.metrics = {
        requests = {
            name = "Requests",
            description = "Total number of DataStore requests",
            unit = "requests",
            color = Color3.fromRGB(0, 120, 215)
        },
        size = {
            name = "Data Size",
            description = "Total size of stored data",
            unit = "bytes",
            color = Color3.fromRGB(0, 180, 120)
        },
        errors = {
            name = "Errors",
            description = "Number of failed requests",
            unit = "errors",
            color = Color3.fromRGB(215, 60, 60)
        },
        responseTime = {
            name = "Response Time",
            description = "Average response time",
            unit = "ms",
            color = Color3.fromRGB(180, 120, 0)
        },
        cacheHits = {
            name = "Cache Hits",
            description = "Number of cache hits",
            unit = "hits",
            color = Color3.fromRGB(120, 60, 180)
        },
        budgetUsage = {
            name = "Budget Usage",
            description = "DataStore budget usage",
            unit = "%",
            color = Color3.fromRGB(60, 120, 180)
        },
        concurrentUsers = {
            name = "Concurrent Users",
            description = "Number of active users",
            unit = "users",
            color = Color3.fromRGB(180, 60, 120)
        },
        dataOperations = {
            name = "Data Operations",
            description = "Read/Write operations",
            unit = "ops",
            color = Color3.fromRGB(120, 180, 60)
        }
    }

    -- Available chart types
    self.chartTypes = {
        line = {
            name = "Line Chart",
            description = "Shows trends over time",
            icon = "📈"
        },
        bar = {
            name = "Bar Chart",
            description = "Compares values across categories",
            icon = "📊"
        },
        pie = {
            name = "Pie Chart",
            description = "Shows proportion distribution",
            icon = "🥧"
        },
        area = {
            name = "Area Chart",
            description = "Shows cumulative values",
            icon = "📑"
        },
        scatter = {
            name = "Scatter Plot",
            description = "Shows correlation between metrics",
            icon = "🔍"
        },
        heatmap = {
            name = "Heat Map",
            description = "Shows intensity of values",
            icon = "🔥"
        }
    }

    -- Time ranges with intervals
    self.timeRanges = {
        ["1h"] = { name = "Last Hour", interval = 60 },
        ["24h"] = { name = "Last 24 Hours", interval = 3600 },
        ["7d"] = { name = "Last 7 Days", interval = 86400 },
        ["30d"] = { name = "Last 30 Days", interval = 86400 }
    }

    -- Bind methods
    self.onStoreChange = function(store)
        self:setState({ selectedStore = store })
        self:loadData()
    end

    self.onMetricChange = function(metric)
        self:setState({ selectedMetric = metric })
        self:loadData()
    end

    self.onChartTypeChange = function(chartType)
        self:setState({ selectedChartType = chartType })
        self:loadData()
    end

    self.onTimeRangeChange = function(timeRange)
        self:setState({ timeRange = timeRange })
        self:loadData()
    end

    self.onToggleDistribution = function()
        self:setState({ showDistribution = not self.state.showDistribution })
    end

    self.onToggleTrends = function()
        self:setState({ showTrends = not self.state.showTrends })
    end

    self.onAddWidget = function(widgetType)
        local newWidget = {
            id = os.time(),
            type = widgetType,
            metric = self.state.selectedMetric,
            timeRange = self.state.timeRange
        }
        self:setState({
            customWidgets = { unpack(self.state.customWidgets), newWidget }
        })
    end

    self.onRemoveWidget = function(widgetId)
        self:setState({
            customWidgets = table.filter(self.state.customWidgets, function(w)
                return w.id ~= widgetId
            end)
        })
    end

    self.onZoomIn = function()
        self:setState({
            zoomLevel = math.min(self.state.zoomLevel * 1.2, 5)
        })
    end

    self.onZoomOut = function()
        self:setState({
            zoomLevel = math.max(self.state.zoomLevel / 1.2, 0.2)
        })
    end

    self.onResetZoom = function()
        self:setState({
            zoomLevel = 1,
            panOffset = Vector2.new(0, 0)
        })
    end

    self.onMouseWheel = function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if input.Position.Z > 0 then
                self.onZoomIn()
            else
                self.onZoomOut()
            end
        end
    end

    self.onMouseDown = function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:setState({
                isDragging = true,
                dragStart = Vector2.new(input.Position.X, input.Position.Y)
            })
        end
    end

    self.onMouseMove = function(input)
        if self.state.isDragging then
            local delta = Vector2.new(
                input.Position.X - self.state.dragStart.X,
                input.Position.Y - self.state.dragStart.Y
            )
            self:setState({
                panOffset = self.state.panOffset + delta,
                dragStart = Vector2.new(input.Position.X, input.Position.Y)
            })
        end

        if self.state.hoveredPoint then
            self:setState({
                tooltipPosition = Vector2.new(input.Position.X, input.Position.Y)
            })
        end
    end

    self.onMouseUp = function()
        self:setState({
            isDragging = false
        })
    end

    self.onPointHover = function(point)
        self:setState({
            hoveredPoint = point,
            showTooltip = true,
            tooltipData = {
                timestamp = point.timestamp,
                value = point.value,
                metadata = point.metadata
            }
        })
    end

    self.onPointLeave = function()
        self:setState({
            hoveredPoint = nil,
            showTooltip = false
        })
    end

    self.onPointClick = function(point)
        self:setState({
            selectedPoint = point
        })
    end

    self.onAddAnnotation = function()
        if self.state.selectedPoint then
            local newAnnotation = {
                id = os.time(),
                point = self.state.selectedPoint,
                text = "",
                color = Color3.fromRGB(255, 255, 255)
            }
            self:setState({
                annotations = { unpack(self.state.annotations), newAnnotation }
            })
        end
    end

    self.onRemoveAnnotation = function(annotationId)
        self:setState({
            annotations = table.filter(self.state.annotations, function(a)
                return a.id ~= annotationId
            end)
        })
    end

    self.onEditAnnotation = function(annotationId, text)
        self:setState({
            annotations = table.map(self.state.annotations, function(a)
                if a.id == annotationId then
                    return { unpack(a), text = text }
                end
                return a
            end)
        })
    end

    self.onStartRegionSelection = function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right click
            self:setState({
                isSelectingRegion = true,
                regionStart = Vector2.new(input.Position.X, input.Position.Y),
                regionEnd = Vector2.new(input.Position.X, input.Position.Y)
            })
        end
    end

    self.onUpdateRegionSelection = function(input)
        if self.state.isSelectingRegion then
            self:setState({
                regionEnd = Vector2.new(input.Position.X, input.Position.Y)
            })
        end
    end

    self.onEndRegionSelection = function()
        if self.state.isSelectingRegion then
            local startX = math.min(self.state.regionStart.X, self.state.regionEnd.X)
            local endX = math.max(self.state.regionStart.X, self.state.regionEnd.X)
            
            -- Find data points within region
            local pointsInRegion = {}
            for _, point in ipairs(self.state.data) do
                if point.x >= startX and point.x <= endX then
                    table.insert(pointsInRegion, point)
                end
            end

            -- Calculate region statistics
            local stats = self:calculateRegionStats(pointsInRegion)

            -- Add region annotation
            local newRegion = {
                id = os.time(),
                start = self.state.regionStart,
                endPoint = self.state.regionEnd,
                points = pointsInRegion,
                stats = stats,
                color = Color3.fromRGB(255, 255, 255)
            }

            self:setState({
                isSelectingRegion = false,
                selectedRegion = newRegion,
                regionAnnotations = { unpack(self.state.regionAnnotations), newRegion }
            })
        end
    end

    self.onAddComparisonPoint = function(point)
        if #self.state.comparisonPoints < 2 then
            self:setState({
                comparisonPoints = { unpack(self.state.comparisonPoints), point },
                showComparison = #self.state.comparisonPoints + 1 >= 2
            })
        end
    end

    self.onRemoveComparisonPoint = function(pointId)
        self:setState({
            comparisonPoints = table.filter(self.state.comparisonPoints, function(p)
                return p.id ~= pointId
            end),
            showComparison = #self.state.comparisonPoints - 1 >= 2
        })
    end

    self.onClearComparison = function()
        self:setState({
            comparisonPoints = {},
            showComparison = false,
            comparisonMetrics = {}
        })
    end

    self.calculateRegionStats = function(points)
        if #points == 0 then return nil end

        local sum = 0
        local min = math.huge
        local max = -math.huge
        local values = {}

        for _, point in ipairs(points) do
            sum = sum + point.value
            min = math.min(min, point.value)
            max = math.max(max, point.value)
            table.insert(values, point.value)
        end

        -- Calculate standard deviation
        local mean = sum / #points
        local variance = 0
        for _, value in ipairs(values) do
            variance = variance + (value - mean) ^ 2
        end
        local stdDev = math.sqrt(variance / #points)

        return {
            count = #points,
            sum = sum,
            mean = mean,
            min = min,
            max = max,
            stdDev = stdDev,
            range = max - min
        }
    end

    self.calculateComparisonMetrics = function()
        if #self.state.comparisonPoints ~= 2 then return end

        local point1 = self.state.comparisonPoints[1]
        local point2 = self.state.comparisonPoints[2]

        local metrics = {
            timeDiff = point2.timestamp - point1.timestamp,
            valueDiff = point2.value - point1.value,
            percentChange = ((point2.value - point1.value) / point1.value) * 100,
            rateOfChange = (point2.value - point1.value) / (point2.timestamp - point1.timestamp)
        }

        self:setState({
            comparisonMetrics = metrics
        })
    end

    self.loadData = function()
        self:setState({ loading = true })
        
        -- Simulate data loading
        task.spawn(function()
            local data = self:generateMockData()
            self:setState({
                data = data,
                loading = false
            })
        end)
    end
end

function DataVisualizer:generateMockData()
    local data = {}
    local now = os.time()
    local interval = self.timeRanges[self.state.timeRange].interval
    local points = self:getPointCount()
    
    for i = 1, points do
        local timestamp = now - (points - i) * interval
        local value = self:generateMockValue(i, points)
        table.insert(data, {
            timestamp = timestamp,
            value = value,
            metadata = self:generateMockMetadata()
        })
    end
    
    return data
end

function DataVisualizer:generateMockValue(index, totalPoints)
    local baseValue = math.random(50, 200)
    local trend = math.sin(index / totalPoints * math.pi * 2) * 50
    local noise = math.random(-10, 10)
    return baseValue + trend + noise
end

function DataVisualizer:generateMockMetadata()
    return {
        distribution = {
            mean = math.random(100, 200),
            median = math.random(100, 200),
            stdDev = math.random(10, 30)
        },
        trends = {
            direction = math.random() > 0.5 and "up" or "down",
            magnitude = math.random(5, 20),
            confidence = math.random(70, 95)
        }
    }
end

function DataVisualizer:getPointCount()
    local range = self.timeRanges[self.state.timeRange]
    if range.name == "Last Hour" then
        return 60
    elseif range.name == "Last 24 Hours" then
        return 24
    elseif range.name == "Last 7 Days" then
        return 7
    else
        return 30
    end
end

function DataVisualizer:renderChart()
    local data = self.state.data
    if not data or #data == 0 then
        return Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "No data available",
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 16,
            Font = Enum.Font.SourceSans,
            BackgroundTransparency = 1
        })
    end

    -- Create chart placeholder based on selected type
    local chartTypeName = self.chartTypes[self.state.selectedChartType].name
    local chartIcon = self.chartTypes[self.state.selectedChartType].icon

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(100, 100, 100)
    }, {
        ChartPlaceholder = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = string.format("%s %s\n(Implementation in progress)\n\nMetric: %s\nTime Range: %s\nZoom: %.1fx", 
                chartIcon, 
                chartTypeName,
                self.metrics[self.state.selectedMetric].name,
                self.timeRanges[self.state.timeRange].name,
                self.state.zoomLevel
            ),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 16,
            Font = Enum.Font.SourceSans,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center
        })
    })
end

function DataVisualizer:renderDistribution()
    if not self.state.showDistribution then
        return nil
    end

    local data = self.state.data
    if not data or #data == 0 then
        return nil
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0
    }, {
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            Text = "Distribution Analysis",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            Font = Enum.Font.SourceSansBold,
            BackgroundTransparency = 1
        }),
        
        Content = Roact.createElement("Frame", {
            Size = UDim2.new(1, -20, 1, -40),
            Position = UDim2.new(0, 10, 0, 35),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(100, 100, 100)
        }, {
            PlaceholderText = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = "Distribution Chart\n(Implementation in progress)",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center
            })
        })
    })
end

function DataVisualizer:renderTrends()
    if not self.state.showTrends then
        return nil
    end

    local data = self.state.data
    if not data or #data == 0 then
        return nil
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0
    }, {
        Title = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            Text = "Trend Analysis",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            Font = Enum.Font.SourceSansBold,
            BackgroundTransparency = 1
        }),
        
        Content = Roact.createElement("Frame", {
            Size = UDim2.new(1, -20, 1, -40),
            Position = UDim2.new(0, 10, 0, 35),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(100, 100, 100)
        }, {
            PlaceholderText = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                Text = "Trend Chart\n(Implementation in progress)",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center
            })
        })
    })
end

function DataVisualizer:renderCustomWidgets()
    local widgets = {}
    
    for _, widget in ipairs(self.state.customWidgets) do
        table.insert(widgets, Roact.createElement("Frame", {
            Size = UDim2.new(0.5, -10, 0, 150),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            LayoutOrder = widget.id
        }, {
            Header = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1
            }, {
                Title = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, -40, 1, 0),
                    Text = self.metrics[widget.metric].name,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    Font = Enum.Font.SourceSansBold,
                    BackgroundTransparency = 1
                }),
                
                RemoveButton = Roact.createElement("TextButton", {
                    Size = UDim2.new(0, 30, 1, 0),
                    Position = UDim2.new(1, -30, 0, 0),
                    Text = "×",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 20,
                    Font = Enum.Font.SourceSansBold,
                    BackgroundTransparency = 1,
                    [Roact.Event.Activated] = function()
                        self.onRemoveWidget(widget.id)
                    end
                })
            }),
            
            Content = Roact.createElement("Frame", {
                Size = UDim2.new(1, -20, 1, -40),
                Position = UDim2.new(0, 10, 0, 35),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(100, 100, 100)
            }, {
                PlaceholderText = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = string.format("Widget: %s\n(Implementation in progress)", widget.type),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 12,
                    Font = Enum.Font.SourceSans,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center
                })
            })
        }))
    end
    
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, #widgets > 0 and 170 or 0),
        BackgroundTransparency = 1
    }, {
        Layout = Roact.createElement("UIGridLayout", {
            CellSize = UDim2.new(0.5, -10, 0, 150),
            CellPadding = UDim2.new(0, 10, 0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        
        Widgets = Roact.createFragment(widgets)
    })
end

function DataVisualizer:renderTooltip()
    if not self.state.showTooltip or not self.state.tooltipData then
        return nil
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(0, 200, 0, 100),
        Position = UDim2.new(0, self.state.tooltipPosition.X, 0, self.state.tooltipPosition.Y),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(100, 100, 100)
    }, {
        Layout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 5)
        }),

        Time = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Text = os.date("%Y-%m-%d %H:%M:%S", self.state.tooltipData.timestamp),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 14,
            Font = Enum.Font.SourceSans,
            BackgroundTransparency = 1
        }),

        Value = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Text = string.format("%.2f %s", 
                self.state.tooltipData.value,
                self.metrics[self.state.selectedMetric].unit
            ),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            Font = Enum.Font.SourceSansBold,
            BackgroundTransparency = 1
        }),

        Metadata = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            Text = string.format(
                "Mean: %.2f\nStdDev: %.2f",
                self.state.tooltipData.metadata.distribution.mean,
                self.state.tooltipData.metadata.distribution.stdDev
            ),
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 12,
            Font = Enum.Font.SourceSans,
            BackgroundTransparency = 1,
            TextYAlignment = Enum.TextYAlignment.Top
        })
    })
end

function DataVisualizer:renderAnnotations()
    if not self.state.annotations or #self.state.annotations == 0 then
        return nil
    end

    local annotations = {}
    for _, annotation in ipairs(self.state.annotations) do
        table.insert(annotations, Roact.createElement("Frame", {
            Size = UDim2.new(0, 150, 0, 60),
            Position = UDim2.new(0, annotation.point.x, 0, annotation.point.y),
            BackgroundColor3 = annotation.color,
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(100, 100, 100)
        }, {
            Layout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, 5)
            }),

            Text = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, -10, 0, 40),
                Position = UDim2.new(0, 5, 0, 5),
                Text = annotation.text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1,
                TextWrapped = true
            }),

            RemoveButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -25, 0, 5),
                Text = "×",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                Font = Enum.Font.SourceSansBold,
                BackgroundTransparency = 1,
                [Roact.Event.Activated] = function()
                    self.onRemoveAnnotation(annotation.id)
                end
            })
        }))
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    }, {
        Annotations = Roact.createFragment(annotations)
    })
end

function DataVisualizer:renderRegionSelection()
    if not self.state.isSelectingRegion then return nil end

    local start = self.state.regionStart
    local endPoint = self.state.regionEnd
    local width = math.abs(endPoint.X - start.X)
    local height = math.abs(endPoint.Y - start.Y)
    local position = UDim2.new(0, math.min(start.X, endPoint.X), 0, math.min(start.Y, endPoint.Y))

    return Roact.createElement("Frame", {
        Size = UDim2.new(0, width, 0, height),
        Position = position,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(255, 255, 255)
    })
end

function DataVisualizer:renderRegionAnnotations()
    if not self.state.regionAnnotations or #self.state.regionAnnotations == 0 then
        return nil
    end

    local annotations = {}
    for _, region in ipairs(self.state.regionAnnotations) do
        local width = math.abs(region.endPoint.X - region.start.X)
        local height = math.abs(region.endPoint.Y - region.start.Y)
        local position = UDim2.new(0, math.min(region.start.X, region.endPoint.X), 0, math.min(region.start.Y, region.endPoint.Y))

        table.insert(annotations, Roact.createElement("Frame", {
            Size = UDim2.new(0, width, 0, height),
            Position = position,
            BackgroundColor3 = region.color,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 1,
            BorderColor3 = region.color
        }, {
            Stats = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 80),
                Position = UDim2.new(0, 0, 0, -80),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(100, 100, 100)
            }, {
                Layout = Roact.createElement("UIListLayout", {
                    Padding = UDim.new(0, 5)
                }),

                Count = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = string.format("Points: %d", region.stats.count),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    Font = Enum.Font.SourceSans,
                    BackgroundTransparency = 1
                }),

                Mean = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = string.format("Mean: %.2f", region.stats.mean),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    Font = Enum.Font.SourceSans,
                    BackgroundTransparency = 1
                }),

                Range = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = string.format("Range: %.2f", region.stats.range),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12,
                    Font = Enum.Font.SourceSans,
                    BackgroundTransparency = 1
                })
            })
        }))
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    }, {
        Annotations = Roact.createFragment(annotations)
    })
end

function DataVisualizer:renderComparison()
    if not self.state.showComparison then return nil end

    local metrics = self.state.comparisonMetrics or {}

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(100, 100, 100)
    }, {
        Layout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 10)
        }),

        Header = Roact.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Text = "Point Comparison",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 16,
            Font = Enum.Font.SourceSansBold,
            BackgroundTransparency = 1
        }),

        Metrics = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, -20),
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIGridLayout", {
                CellSize = UDim2.new(0.5, -5, 0, 20),
                CellPadding = UDim2.new(0, 5, 0, 5)
            }),

            TimeDiff = Roact.createElement("TextLabel", {
                Text = string.format("Time Diff: %.1f s", metrics.timeDiff or 0),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),

            ValueDiff = Roact.createElement("TextLabel", {
                Text = string.format("Value Diff: %.2f", metrics.valueDiff or 0),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),

            PercentChange = Roact.createElement("TextLabel", {
                Text = string.format("Change: %.1f%%", metrics.percentChange or 0),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),

            RateOfChange = Roact.createElement("TextLabel", {
                Text = string.format("Rate: %.2f/s", metrics.rateOfChange or 0),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            })
        }),

        ClearButton = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 100, 0, 20),
            Position = UDim2.new(1, -110, 0, 5),
            Text = "Clear",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            Font = Enum.Font.SourceSans,
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            [Roact.Event.Activated] = self.onClearComparison
        })
    })
end

function DataVisualizer:renderControls()
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0
    }, {
        Layout = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10)
        }),
        
        StoreSelector = Roact.createElement("Frame", {
            Size = UDim2.new(0.2, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Label = Roact.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                Text = "Store:",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),
            
            Dropdown = Roact.createElement("TextButton", {
                Size = UDim2.new(1, -90, 1, 0),
                Position = UDim2.new(0, 90, 0, 0),
                Text = self.state.selectedStore or "Select Store",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = function()
                    -- Show store selection dropdown
                end
            })
        }),
        
        MetricSelector = Roact.createElement("Frame", {
            Size = UDim2.new(0.2, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Label = Roact.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                Text = "Metric:",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),
            
            Dropdown = Roact.createElement("TextButton", {
                Size = UDim2.new(1, -90, 1, 0),
                Position = UDim2.new(0, 90, 0, 0),
                Text = self.metrics[self.state.selectedMetric].name,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = function()
                    -- Show metric selection dropdown
                end
            })
        }),
        
        ChartTypeSelector = Roact.createElement("Frame", {
            Size = UDim2.new(0.2, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Label = Roact.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                Text = "Chart:",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),
            
            Dropdown = Roact.createElement("TextButton", {
                Size = UDim2.new(1, -90, 1, 0),
                Position = UDim2.new(0, 90, 0, 0),
                Text = self.chartTypes[self.state.selectedChartType].name,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = function()
                    -- Show chart type selection dropdown
                end
            })
        }),
        
        TimeRangeSelector = Roact.createElement("Frame", {
            Size = UDim2.new(0.2, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Label = Roact.createElement("TextLabel", {
                Size = UDim2.new(0, 80, 1, 0),
                Text = "Time:",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundTransparency = 1
            }),
            
            Dropdown = Roact.createElement("TextButton", {
                Size = UDim2.new(1, -90, 1, 0),
                Position = UDim2.new(0, 90, 0, 0),
                Text = self.timeRanges[self.state.timeRange].name,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = function()
                    -- Show time range selection dropdown
                end
            })
        }),
        
        ActionButtons = Roact.createElement("Frame", {
            Size = UDim2.new(0.2, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10)
            }),
            
            DistributionButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0.5, -5, 1, 0),
                Text = "Distribution",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundColor3 = self.state.showDistribution and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = self.onToggleDistribution
            }),
            
            TrendsButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0.5, -5, 1, 0),
                Text = "Trends",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                BackgroundColor3 = self.state.showTrends and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = self.onToggleTrends
            })
        }),
        
        InteractiveControls = Roact.createElement("Frame", {
            Size = UDim2.new(0.2, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5)
            }),

            ZoomInButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0.33, -5, 1, 0),
                Text = "+",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                Font = Enum.Font.SourceSansBold,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = self.onZoomIn
            }),

            ZoomOutButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0.33, -5, 1, 0),
                Text = "-",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                Font = Enum.Font.SourceSansBold,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = self.onZoomOut
            }),

            ResetButton = Roact.createElement("TextButton", {
                Size = UDim2.new(0.33, -5, 1, 0),
                Text = "↺",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                Font = Enum.Font.SourceSansBold,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                [Roact.Event.Activated] = self.onResetZoom
            })
        })
    })
end

function DataVisualizer:render()
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        [Roact.Event.InputBegan] = function(_, input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                self.onStartRegionSelection(input)
            end
        end,
        [Roact.Event.InputChanged] = function(_, input)
            self.onUpdateRegionSelection(input)
        end,
        [Roact.Event.InputEnded] = function()
            self.onEndRegionSelection()
        end
    }, {
        Layout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 10)
        }),

        Controls = self:renderControls(),
        Chart = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 300),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0
        }, {
            self:renderChart(),
            self:renderAnnotations(),
            self:renderRegionSelection(),
            self:renderRegionAnnotations()
        }),
        Distribution = self:renderDistribution(),
        Trends = self:renderTrends(),
        CustomWidgets = self:renderCustomWidgets(),
        Tooltip = self:renderTooltip(),
        Comparison = self:renderComparison()
    })
end

return withContext({
    Theme = ContextServices.Theme,
    Localization = ContextServices.Localization
})(DataVisualizer) 