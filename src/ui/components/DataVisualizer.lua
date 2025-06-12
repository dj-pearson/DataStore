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
        customWidgets = {}
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

    -- Create chart based on selected type
    local chartProps = {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Data = data,
        Metric = self.metrics[self.state.selectedMetric],
        TimeRange = self.timeRanges[self.state.timeRange]
    }

    if self.state.selectedChartType == "line" then
        return Roact.createElement("LineChart", chartProps)
    elseif self.state.selectedChartType == "bar" then
        return Roact.createElement("BarChart", chartProps)
    elseif self.state.selectedChartType == "pie" then
        return Roact.createElement("PieChart", chartProps)
    elseif self.state.selectedChartType == "area" then
        return Roact.createElement("AreaChart", chartProps)
    elseif self.state.selectedChartType == "scatter" then
        return Roact.createElement("ScatterPlot", chartProps)
    else
        return Roact.createElement("HeatMap", chartProps)
    end
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
            BackgroundTransparency = 1
        }, {
            DistributionChart = Roact.createElement("DistributionChart", {
                Size = UDim2.new(1, 0, 1, 0),
                Data = data,
                Metric = self.metrics[self.state.selectedMetric]
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
            BackgroundTransparency = 1
        }, {
            TrendChart = Roact.createElement("TrendChart", {
                Size = UDim2.new(1, 0, 1, 0),
                Data = data,
                Metric = self.metrics[self.state.selectedMetric]
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
                BackgroundTransparency = 1
            }, {
                Widget = Roact.createElement("WidgetChart", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Type = widget.type,
                    Metric = self.metrics[widget.metric],
                    TimeRange = self.timeRanges[widget.timeRange]
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
        })
    })
end

function DataVisualizer:render()
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0
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
            self:renderChart()
        }),
        Distribution = self:renderDistribution(),
        Trends = self:renderTrends(),
        CustomWidgets = self:renderCustomWidgets()
    })
end

return withContext({
    Theme = ContextServices.Theme,
    Localization = ContextServices.Localization
})(DataVisualizer) 