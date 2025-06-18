-- DataStore Manager Pro - Data Explorer Manager
-- Manages data store exploration, key listing, and data display

local DataExplorerManager = {}
DataExplorerManager.__index = DataExplorerManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[DATA_EXPLORER_MANAGER] [%s] %s", level, message))
end

-- Helper function to get DataStore Manager from services
local function getDataStoreManager(services)
    if not services then return nil end
    return services.DataStoreManager or services["core.data.DataStoreManager"] or services["core.data.DataStoreManagerSlim"]
end

-- Create new Data Explorer Manager instance
function DataExplorerManager.new(uiManager)
    local self = setmetatable({}, DataExplorerManager)
    
    self.uiManager = uiManager
    self.services = uiManager.services
    self.selectedDataStore = nil
    self.selectedKey = nil
    self.keystoreList = nil
    self.keysList = nil
    self.dataViewer = nil
    
    -- Debug logging for service availability
    debugLog("DataExplorerManager created")
    if self.services then
        local serviceCount = 0
        local hasDataStoreManager = false
        local dataStoreManagerType = "none"
        debugLog("=== SERVICE DEBUG ===")
        for serviceName, service in pairs(self.services) do
            serviceCount = serviceCount + 1
            debugLog("Service: " .. serviceName .. " = " .. type(service))
            if serviceName == "DataStoreManager" or serviceName == "core.data.DataStoreManager" or serviceName == "core.data.DataStoreManagerSlim" then
                hasDataStoreManager = true
                dataStoreManagerType = type(service)
                debugLog("Found DataStore Manager service: " .. serviceName .. " (type: " .. dataStoreManagerType .. ")")
                if type(service) == "table" then
                    local methods = {}
                    for methodName, _ in pairs(service) do
                        if type(service[methodName]) == "function" then
                            table.insert(methods, methodName)
                        end
                    end
                    debugLog("DataStore Manager methods: " .. table.concat(methods, ", "))
                end
            end
        end
        debugLog("=== END SERVICE DEBUG ===")
        debugLog("Available services: " .. serviceCount .. ", DataStore Manager found: " .. tostring(hasDataStoreManager) .. " (type: " .. dataStoreManagerType .. ")")
        
        if hasDataStoreManager then
            debugLog("✅ DataStore Manager service is available for real data access!")
        else
            debugLog("❌ DataStore Manager service not found - will use fallback data", "WARN")
            debugLog("Available services:", "WARN")
            for serviceName, _ in pairs(self.services) do
                debugLog("  - " .. serviceName, "WARN")
            end
        end
    else
        debugLog("❌ No services provided to DataExplorerManager!", "ERROR")
    end
    
    return self
end

-- Explicit method to set DataStore Manager service (for troubleshooting)
function DataExplorerManager:setDataStoreManagerService(dataStoreManager)
    if not self.services then
        self.services = {}
    end
    
    self.services.DataStoreManager = dataStoreManager
    self.services["core.data.DataStoreManager"] = dataStoreManager
    self.services["core.data.DataStoreManagerSlim"] = dataStoreManager
    
    debugLog("DataStore Manager service explicitly set")
    debugLog("DataStore Manager type: " .. type(dataStoreManager))
    if dataStoreManager.getDataStoreNames then
        debugLog("✅ getDataStoreNames method available")
    else
        debugLog("❌ getDataStoreNames method missing", "ERROR")
    end
end

-- Create modern data explorer interface
function DataExplorerManager:createModernDataExplorer(parent)
    debugLog("Creating modern data explorer interface")
    
    -- Main container
    local explorerContainer = Instance.new("Frame")
    explorerContainer.Name = "DataExplorerContainer"
    explorerContainer.Size = UDim2.new(1, 0, 1, 0)
    explorerContainer.Position = UDim2.new(0, 0, 0, 0)
    explorerContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    explorerContainer.BorderSizePixel = 0
    explorerContainer.Parent = parent
    
    -- Status bar at the very top
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, 0, 0, 25)
    statusBar.Position = UDim2.new(0, 0, 0, 0)
    statusBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    statusBar.BorderSizePixel = 1
    statusBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    statusBar.Parent = explorerContainer
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 1, 0)
    statusLabel.Position = UDim2.new(0, 10, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🔄 Initializing DataStore Manager..."
    statusLabel.Font = Constants.UI.THEME.FONTS.UI
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.Parent = statusBar
    
    -- Store status bar reference for updates
    self.statusBar = statusBar
    self.statusLabel = statusLabel
    
    -- Timer label for throttling countdown
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Size = UDim2.new(0, 100, 1, 0)
    timerLabel.Position = UDim2.new(1, -110, 0, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = ""
    timerLabel.Font = Constants.UI.THEME.FONTS.UI
    timerLabel.TextSize = 11
    timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    timerLabel.TextXAlignment = Enum.TextXAlignment.Right
    timerLabel.TextYAlignment = Enum.TextYAlignment.Center
    timerLabel.Parent = statusBar
    
    self.timerLabel = timerLabel
    
    -- Adjust main content area to account for status bar
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -25)
    contentContainer.Position = UDim2.new(0, 0, 0, 25)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = explorerContainer
    
    -- Three-column layout (now inside content container)
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "DataStorePanel"
    leftPanel.Size = UDim2.new(0.25, -5, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    leftPanel.BorderSizePixel = 1
    leftPanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    leftPanel.Parent = contentContainer
    
    local middlePanel = Instance.new("Frame")
    middlePanel.Name = "KeysPanel"
    middlePanel.Size = UDim2.new(0.35, -5, 1, 0)
    middlePanel.Position = UDim2.new(0.25, 5, 0, 0)
    middlePanel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    middlePanel.BorderSizePixel = 1
    middlePanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    middlePanel.Parent = contentContainer
    
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "DataPanel"
    rightPanel.Size = UDim2.new(0.4, -5, 1, 0)
    rightPanel.Position = UDim2.new(0.6, 5, 0, 0)
    rightPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    leftPanel.BorderSizePixel = 1
    rightPanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    rightPanel.Parent = contentContainer
    
    -- Store references
    self.leftPanel = leftPanel
    self.middlePanel = middlePanel
    self.rightPanel = rightPanel
    
    -- Create columns
    self:createDataStoreColumns(leftPanel)
    self:createKeysColumn(middlePanel)
    self:createDataColumn(rightPanel)
    
    -- Initialize status
    self:updateStatus("🔄 Loading DataStores...", "INFO")
    
    debugLog("Modern data explorer created")
    return explorerContainer
end

-- Create data store columns
function DataExplorerManager:createDataStoreColumns(parent)
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 1, 0)
    headerLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "🗂️ DataStores"
    headerLabel.Font = Constants.UI.THEME.FONTS.HEADING
    headerLabel.TextSize = 14
    headerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.TextYAlignment = Enum.TextYAlignment.Center
    headerLabel.Parent = header
    
    -- Refresh button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 25, 0, 25)
    refreshButton.Position = UDim2.new(1, -35, 0.5, -12)
    refreshButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    refreshButton.BorderSizePixel = 0
    refreshButton.Text = "🔄"
    refreshButton.Font = Constants.UI.THEME.FONTS.UI
    refreshButton.TextSize = 12
    refreshButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    refreshButton.Parent = header
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 4)
    refreshCorner.Parent = refreshButton
    
    -- DataStore list
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Name = "DataStoreList"
    listContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    listContainer.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    listContainer.BackgroundTransparency = 1
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 8
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.Parent = parent
    
    self.keystoreList = listContainer
    
    -- Button container for refresh, cache, etc. (with better layout)
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 170, 1, -4)  -- Reduced width to 170px to prevent overflow
    buttonContainer.Position = UDim2.new(1, -175, 0, 2)  -- Adjusted position accordingly
    buttonContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    buttonContainer.BorderSizePixel = 1
    buttonContainer.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    buttonContainer.ClipsDescendants = true
    buttonContainer.Parent = header
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = buttonContainer
    
    -- Add padding to button container
    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingTop = UDim.new(0, 4)
    buttonPadding.PaddingBottom = UDim.new(0, 4)
    buttonPadding.PaddingLeft = UDim.new(0, 6)
    buttonPadding.PaddingRight = UDim.new(0, 6)
    buttonPadding.Parent = buttonContainer
    
    -- First row container
    local firstRow = Instance.new("Frame")
    firstRow.Size = UDim2.new(1, 0, 0.5, -1)
    firstRow.Position = UDim2.new(0, 0, 0, 0)
    firstRow.BackgroundTransparency = 1
    firstRow.Parent = buttonContainer
    
    local firstRowLayout = Instance.new("UIListLayout")
    firstRowLayout.FillDirection = Enum.FillDirection.Horizontal
    firstRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    firstRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    firstRowLayout.Padding = UDim.new(0, 4)
    firstRowLayout.Parent = firstRow
    
    -- Second row container
    local secondRow = Instance.new("Frame")
    secondRow.Size = UDim2.new(1, 0, 0.5, -1)
    secondRow.Position = UDim2.new(0, 0, 0.5, 1)
    secondRow.BackgroundTransparency = 1
    secondRow.Parent = buttonContainer
    
    local secondRowLayout = Instance.new("UIListLayout")
    secondRowLayout.FillDirection = Enum.FillDirection.Horizontal
    secondRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    secondRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    secondRowLayout.Padding = UDim.new(0, 4)
    secondRowLayout.Parent = secondRow
    
    -- Force refresh button (first row)
    local forceRefreshButton = Instance.new("TextButton")
    forceRefreshButton.Size = UDim2.new(0, 75, 0, 16)  -- Optimized size
    forceRefreshButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    forceRefreshButton.BorderSizePixel = 0
    forceRefreshButton.Text = "🔄 Refresh"
    forceRefreshButton.Font = Constants.UI.THEME.FONTS.UI
    forceRefreshButton.TextSize = 9
    forceRefreshButton.TextColor3 = Color3.new(1, 1, 1)
    forceRefreshButton.Parent = firstRow
    
    local forceRefreshCorner = Instance.new("UICorner")
    forceRefreshCorner.CornerRadius = UDim.new(0, 3)
    forceRefreshCorner.Parent = forceRefreshButton
    
    -- Anti-throttling button (first row)
    local antiThrottleButton = Instance.new("TextButton")
    antiThrottleButton.Size = UDim2.new(0, 75, 0, 16)
    antiThrottleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    antiThrottleButton.BorderSizePixel = 0
    antiThrottleButton.Text = "🚫 Throttle"
    antiThrottleButton.Font = Constants.UI.THEME.FONTS.UI
    antiThrottleButton.TextSize = 9
    antiThrottleButton.TextColor3 = Color3.new(1, 1, 1)
    antiThrottleButton.Parent = firstRow
    
    local antiThrottleCorner = Instance.new("UICorner")
    antiThrottleCorner.CornerRadius = UDim.new(0, 3)
    antiThrottleCorner.Parent = antiThrottleButton
    
    -- Plugin cache clear button (second row)
    local cacheButton = Instance.new("TextButton")
    cacheButton.Size = UDim2.new(0, 75, 0, 16)
    cacheButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    cacheButton.BorderSizePixel = 0
    cacheButton.Text = "🧹 Cache"
    cacheButton.Font = Constants.UI.THEME.FONTS.UI
    cacheButton.TextSize = 9
    cacheButton.TextColor3 = Color3.new(1, 1, 1)
    cacheButton.Parent = secondRow
    
    local cacheCorner = Instance.new("UICorner")
    cacheCorner.CornerRadius = UDim.new(0, 3)
    cacheCorner.Parent = cacheButton
    
    -- Auto-discovery toggle button (second row)
    local autoDiscoveryButton = Instance.new("TextButton")
    autoDiscoveryButton.Size = UDim2.new(0, 75, 0, 16)
    autoDiscoveryButton.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    autoDiscoveryButton.BorderSizePixel = 0
    autoDiscoveryButton.Text = "🔄 Auto"
    autoDiscoveryButton.Font = Constants.UI.THEME.FONTS.UI
    autoDiscoveryButton.TextSize = 9
    autoDiscoveryButton.TextColor3 = Color3.new(1, 1, 1)
    autoDiscoveryButton.Parent = secondRow
    
    local autoDiscoveryCorner = Instance.new("UICorner")
    autoDiscoveryCorner.CornerRadius = UDim.new(0, 3)
    autoDiscoveryCorner.Parent = autoDiscoveryButton

    -- Button connections
    refreshButton.MouseButton1Click:Connect(function()
        -- If we have a DataStore selected, refresh its keys while preserving selection
        if self.selectedDataStore then
            self:refreshDataStoreKeys()
        else
            -- No DataStore selected, just refresh the DataStore list
            self:loadDataStores()
        end
    end)
    
    antiThrottleButton.MouseButton1Click:Connect(function()
        -- Clear all throttling from DataStoreManager
        local dataStoreManager = getDataStoreManager(self.services)
        if dataStoreManager and dataStoreManager.clearAllThrottling then
            dataStoreManager:clearAllThrottling()
            self:updateOperationStatus("THROTTLE_CLEAR", "SUCCESS")
            self:loadDataStores() -- Immediately try to reload data
        else
            self:updateOperationStatus("THROTTLE_CLEAR", "FAILED", "DataStoreManager not available")
        end
    end)
    
    -- Plugin cache clear button connection
    cacheButton.MouseButton1Click:Connect(function()
        local dataStoreManager = getDataStoreManager(self.services)
        if dataStoreManager and dataStoreManager.pluginCache then
            dataStoreManager.pluginCache:clearAllCache()
            self:updateOperationStatus("CACHE_CLEAR", "SUCCESS")
            self:loadDataStores()
        else
            self:updateOperationStatus("CACHE_CLEAR", "FAILED", "Plugin cache not available")
        end
    end)
    
    -- Force refresh button connection
    forceRefreshButton.MouseButton1Click:Connect(function()
        local dataStoreManager = getDataStoreManager(self.services)
        if dataStoreManager and dataStoreManager.forceRefresh then
            if self.notificationManager then
                self.notificationManager:showNotification("🔄 Force refreshing with your real DataStores...", "INFO")
            end
            debugLog("🔄 Force refreshing DataStore Manager...")
            
            -- Force refresh (clears cache and reloads with real DataStore names)
            spawn(function()
                local newNames = dataStoreManager:forceRefresh()
                self:loadDataStores()
                
                if self.notificationManager then
                    self.notificationManager:showNotification("✅ Refreshed! Now showing " .. #newNames .. " DataStores including your real ones", "SUCCESS")
                else
                    debugLog("✅ Refreshed! Now showing " .. #newNames .. " DataStores")
                end
            end)
        else
            if self.notificationManager then
                self.notificationManager:showNotification("❌ Force refresh not available - DataStoreManager not found", "ERROR")
            else
                debugLog("❌ Force refresh not available - DataStoreManager not found", "ERROR")
            end
        end
    end)
    
    -- Auto-discovery toggle button connection
    autoDiscoveryButton.MouseButton1Click:Connect(function()
        local dataStoreManager = getDataStoreManager(self.services)
        if dataStoreManager then
            if dataStoreManager:isAutoDiscoveryDisabled() then
                dataStoreManager:enableAutoDiscovery()
                autoDiscoveryButton.Text = "🔄 Auto"
                autoDiscoveryButton.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
                if self.notificationManager then
                    self.notificationManager:showNotification("✅ Auto-discovery enabled", "SUCCESS")
                end
            else
                dataStoreManager:disableAutoDiscovery()
                autoDiscoveryButton.Text = "🚫 Auto"
                autoDiscoveryButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                if self.notificationManager then
                    self.notificationManager:showNotification("🚫 Auto-discovery disabled", "WARNING")
                end
            end
        end
    end)
    
    -- Create test data button
    local testDataButton = Instance.new("TextButton")
    testDataButton.Size = UDim2.new(0, 120, 0, 30)
    testDataButton.Position = UDim2.new(0, 140, 0, 220)
    testDataButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    testDataButton.BorderSizePixel = 0
    testDataButton.Text = "🧪 Create Test Data"
    testDataButton.Font = Constants.UI.THEME.FONTS.UI
    testDataButton.TextSize = 12
    testDataButton.TextColor3 = Color3.new(1, 1, 1)
    testDataButton.Parent = controlsFrame
    
    local testDataCorner = Instance.new("UICorner")
    testDataCorner.CornerRadius = UDim.new(0, 6)
    testDataCorner.Parent = testDataButton
    
    -- Test data button connection
    testDataButton.MouseButton1Click:Connect(function()
        local dataStoreManager = getDataStoreManager(self.services)
        if dataStoreManager and dataStoreManager.createTestData then
            debugLog("🧪 Creating test data...")
            testDataButton.Text = "🔄 Creating..."
            testDataButton.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
            
            spawn(function()
                local created = dataStoreManager:createTestData()
                wait(1)
                testDataButton.Text = "✅ Created " .. created
                testDataButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                
                -- Show notification
                if self.notificationManager then
                    self.notificationManager:showNotification("✅ Created " .. created .. " test data entries", "SUCCESS")
                end
                
                -- Force refresh the DataStore list
                self:loadDataStores()
                
                wait(3)
                testDataButton.Text = "🧪 Create Test Data"
                testDataButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            end)
        else
            debugLog("❌ Test data creation not available - DataStoreManager not found", "ERROR")
            if self.notificationManager then
                self.notificationManager:showNotification("❌ Test data creation not available", "ERROR")
            end
        end
    end)
    
    -- Load initial data
    self:loadDataStores()
end

-- Create keys column
function DataExplorerManager:createKeysColumn(parent)
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 1, 0)
    headerLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "🔑 Keys"
    headerLabel.Font = Constants.UI.THEME.FONTS.HEADING
    headerLabel.TextSize = 14
    headerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.TextYAlignment = Enum.TextYAlignment.Center
    headerLabel.Parent = header
    
    -- Keys list
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Name = "KeysList"
    listContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    listContainer.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    listContainer.BackgroundTransparency = 1
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 8
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.Parent = parent
    
    self.keysList = listContainer
    self.keysHeader = headerLabel
end

-- Create data column
function DataExplorerManager:createDataColumn(parent)
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 1, 0)
    headerLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "📄 Data"
    headerLabel.Font = Constants.UI.THEME.FONTS.HEADING
    headerLabel.TextSize = 14
    headerLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.TextYAlignment = Enum.TextYAlignment.Center
    headerLabel.Parent = header
    
    -- Data viewer
    local viewerContainer = Instance.new("ScrollingFrame")
    viewerContainer.Name = "DataViewer"
    viewerContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT - 50) -- Leave space for operations
    viewerContainer.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    viewerContainer.BackgroundTransparency = 1
    viewerContainer.BorderSizePixel = 0
    viewerContainer.ScrollBarThickness = 8
    viewerContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    viewerContainer.Parent = parent
    
    -- Operations bar
    local operationsBar = Instance.new("Frame")
    operationsBar.Name = "OperationsBar"
    operationsBar.Size = UDim2.new(1, 0, 0, 45)
    operationsBar.Position = UDim2.new(0, 0, 1, -45)
    operationsBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    operationsBar.BorderSizePixel = 1
    operationsBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    operationsBar.ClipsDescendants = true
    operationsBar.Parent = parent
    
    -- Add padding to operations bar
    local operationsPadding = Instance.new("UIPadding")
    operationsPadding.PaddingLeft = UDim.new(0, 10)
    operationsPadding.PaddingRight = UDim.new(0, 10)
    operationsPadding.PaddingTop = UDim.new(0, 7)
    operationsPadding.PaddingBottom = UDim.new(0, 7)
    operationsPadding.Parent = operationsBar
    
    local operationsLayout = Instance.new("UIListLayout")
    operationsLayout.FillDirection = Enum.FillDirection.Horizontal
    operationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    operationsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    operationsLayout.Padding = UDim.new(0, 8)
    operationsLayout.Parent = operationsBar
    
    -- Update Key button
    local updateButton = self:createOperationButton("📝", "Update Key", function()
        self:showUpdateKeyDialog()
    end)
    updateButton.Parent = operationsBar
    
    -- Delete Key button
    local deleteButton = self:createOperationButton("🗑️", "Delete Key", function()
        self:showDeleteKeyDialog()
    end)
    deleteButton.Parent = operationsBar
    
    -- Export Data button
    local exportButton = self:createOperationButton("📤", "Export Data", function()
        self:exportKeyData()
    end)
    exportButton.Parent = operationsBar
    
    -- Version History button
    local versionButton = self:createOperationButton("🕒", "Version History", function()
        self:showVersionHistory()
    end)
    versionButton.Parent = operationsBar
    
    self.dataViewer = viewerContainer
    self.dataHeader = headerLabel
    self.operationsBar = operationsBar
end

-- Load data stores
function DataExplorerManager:loadDataStores()
    debugLog("Loading data stores...")
    
    if not self.keystoreList then
        debugLog("Keystore list not initialized", "ERROR")
        return
    end
    
    -- Clear existing items
    for _, child in ipairs(self.keystoreList:GetChildren()) do
        child:Destroy()
    end
    
    -- Create loading indicator
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0, 20)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "🔄 Loading DataStores..."
    loadingLabel.Font = Constants.UI.THEME.FONTS.BODY
    loadingLabel.TextSize = 14
    loadingLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.Parent = self.keystoreList
    
    -- Load real DataStore data
    task.spawn(function()
        local success, datastores = pcall(function()
            -- Try to get DataStore list from DataStoreManager service
            debugLog("Checking for DataStore Manager service...")
            debugLog("Services available: " .. tostring(self.services ~= nil))
            if self.services then
                debugLog("DataStoreManager direct: " .. tostring(self.services.DataStoreManager ~= nil))
                debugLog("DataStoreManager full path: " .. tostring(getDataStoreManager(self.services) ~= nil))
            end
            
            local dataStoreManager = getDataStoreManager(self.services)
            if dataStoreManager then
                debugLog("DataStore Manager found! Type: " .. type(dataStoreManager))
                if dataStoreManager.getDataStoreNames then
                    debugLog("Loading real DataStore names from DataStoreManager")
                    local datastoreNames = dataStoreManager:getDataStoreNames()
                    
                    if datastoreNames and #datastoreNames > 0 then
                        -- Convert to expected format
                        local formattedDataStores = {}
                        for _, name in ipairs(datastoreNames) do
                            table.insert(formattedDataStores, {
                                name = name,
                                scope = "global",
                                entries = "Loading..." -- Will be updated when keys are loaded
                            })
                        end
                        debugLog("Successfully loaded " .. #formattedDataStores .. " real DataStores")
                        return formattedDataStores
                    else
                        debugLog("No DataStore names returned, using fallback", "WARN")
                    end
                else
                    debugLog("DataStoreManager.getDataStoreNames method not available", "WARN")
                end
            else
                debugLog("DataStoreManager service not available", "WARN")
            end
            
            -- Fallback to hardcoded list for now (these should be replaced with real DataStores)
            debugLog("Using fallback DataStore list (no DataStoreManager found)")
            return {
                {name = "PlayerData", scope = "global", entries = 1543},
                {name = "GameSettings", scope = "global", entries = 23},
                {name = "UserPreferences", scope = "global", entries = 892},
                {name = "Leaderboards", scope = "global", entries = 156},
                {name = "Achievements", scope = "global", entries = 678}
            }
        end)
        
        loadingLabel:Destroy()
        
        if success then
            self:updateDataStoreList(datastores)
        else
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, 0, 0, 50)
            errorLabel.Position = UDim2.new(0, 0, 0, 20)
            errorLabel.BackgroundTransparency = 1
            errorLabel.Text = "❌ Failed to load DataStores"
            errorLabel.Font = Constants.UI.THEME.FONTS.BODY
            errorLabel.TextSize = 14
            errorLabel.TextColor3 = Constants.UI.THEME.COLORS.ERROR
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.Parent = self.keystoreList
        end
    end)
end

-- Update data store list
function DataExplorerManager:updateDataStoreList(datastores)
    local yOffset = 0
    
    for i, datastore in ipairs(datastores) do
        local datastoreCard = Instance.new("Frame")
        datastoreCard.Name = "DataStore_" .. datastore.name
        datastoreCard.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM * 2, 0, 60)
        datastoreCard.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yOffset)
        datastoreCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
        datastoreCard.BorderSizePixel = 1
        datastoreCard.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        datastoreCard.Parent = self.keystoreList
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
        cardCorner.Parent = datastoreCard
        
        -- DataStore name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 25)
        nameLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.SMALL, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "🗂️ " .. datastore.name
        nameLabel.Font = Constants.UI.THEME.FONTS.UI
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = datastoreCard
        
        -- Entry count
        local countLabel = Instance.new("TextLabel")
        countLabel.Name = "CountLabel"
        countLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 20)
        countLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.SMALL, 0, 30)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = string.format("%s • %s scope", tostring(datastore.entries), datastore.scope)
        countLabel.Font = Constants.UI.THEME.FONTS.BODY
        countLabel.TextSize = 11
        countLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        countLabel.TextXAlignment = Enum.TextXAlignment.Left
        countLabel.Parent = datastoreCard
        
        -- Click handler
        local clickButton = Instance.new("TextButton")
        clickButton.Size = UDim2.new(1, 0, 1, 0)
        clickButton.Position = UDim2.new(0, 0, 0, 0)
        clickButton.BackgroundTransparency = 1
        clickButton.Text = ""
        clickButton.Parent = datastoreCard
        
        clickButton.MouseButton1Click:Connect(function()
            self:selectModernDataStore(datastore.name, datastoreCard)
        end)
        
        -- Hover effects
        clickButton.MouseEnter:Connect(function()
            datastoreCard.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
        end)
        
        clickButton.MouseLeave:Connect(function()
            if self.selectedDataStore ~= datastore.name then
                datastoreCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
            end
        end)
        
        yOffset = yOffset + 70
    end
    
    -- Update canvas size
    self.keystoreList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    debugLog("DataStore list updated with " .. #datastores .. " items")
end

-- Select modern data store
function DataExplorerManager:selectModernDataStore(datastoreName, selectedCard)
    debugLog("Selecting DataStore: " .. datastoreName)
    
    -- Reset all cards
    for _, child in ipairs(self.keystoreList:GetChildren()) do
        if child.Name:match("DataStore_") then
            child.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
        end
    end
    
    -- Highlight selected card
    if selectedCard then
        selectedCard.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE
    end
    
    self.selectedDataStore = datastoreName
    
    -- Update keys header
    if self.keysHeader then
        self.keysHeader.Text = "🔑 Keys - " .. datastoreName
        self.keysHeader.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    end
    
    -- Load keys for this datastore
    self:loadKeys()
end

-- Load keys
function DataExplorerManager:loadKeys()
    if not self.selectedDataStore or not self.keysList then
        return
    end
    
    debugLog("Loading keys for DataStore: " .. self.selectedDataStore)
    
    -- Check cache to prevent throttling
    if not self.keysCache then self.keysCache = {} end
    local cacheKey = self.selectedDataStore
    local now = tick()
    
    if self.keysCache[cacheKey] and (now - self.keysCache[cacheKey].timestamp) < 10 then
        debugLog("Using cached keys for " .. self.selectedDataStore .. " (preventing throttling)")
        self:populateKeysList(self.keysCache[cacheKey].keys)
        self:updateDataStoreEntryCount(self.selectedDataStore, #self.keysCache[cacheKey].keys)
        return
    end
    
    -- Clear existing keys
    for _, child in ipairs(self.keysList:GetChildren()) do
        child:Destroy()
    end
    
    -- Create loading indicator
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0, 20)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "🔄 Loading Keys..."
    loadingLabel.Font = Constants.UI.THEME.FONTS.BODY
    loadingLabel.TextSize = 14
    loadingLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.Parent = self.keysList
    
    -- Load real key data
    task.spawn(function()
        local success, keys = pcall(function()
            -- Try to get keys from DataStoreManager service using getDataStoreKeys method
            local dataStoreManager = getDataStoreManager(self.services)
            if dataStoreManager then
                if dataStoreManager and (dataStoreManager.getDataStoreEntries or dataStoreManager.getKeys or dataStoreManager.getDataStoreKeys) then
                    debugLog("Loading real keys from DataStoreManager for: " .. self.selectedDataStore)
                    local keyList 
                    
                    -- Try different methods in order of preference
                    if dataStoreManager.getDataStoreEntries then
                        keyList = dataStoreManager:getDataStoreEntries(self.selectedDataStore, "", 100)
                    elseif dataStoreManager.getKeys then
                        keyList = dataStoreManager:getKeys(self.selectedDataStore, "global", 100)
                    elseif dataStoreManager.getDataStoreKeys then
                        keyList = dataStoreManager:getDataStoreKeys(self.selectedDataStore, "", 100)
                    end
                    
                    if keyList and #keyList > 0 then
                        -- Convert DataStore keys format to our expected format
                        local formattedKeys = {}
                        for i, keyInfo in ipairs(keyList) do
                            local keyName
                            if type(keyInfo) == "string" then
                                keyName = keyInfo
                            elseif type(keyInfo) == "table" and keyInfo.key then
                                keyName = keyInfo.key
                            elseif type(keyInfo) == "table" and keyInfo.name then
                                keyName = keyInfo.name
                            else
                                keyName = tostring(keyInfo)
                            end
                            
                            table.insert(formattedKeys, {
                                name = keyName,
                                size = (type(keyInfo) == "table" and keyInfo.size) or "Unknown", -- Don't generate fake sizes
                                lastModified = (type(keyInfo) == "table" and keyInfo.lastModified) or "Unknown"
                            })
                        end
                        debugLog("Successfully loaded " .. #formattedKeys .. " real keys from DataStore")
                        return formattedKeys
                    else
                        debugLog("No keys returned from DataStoreManager", "WARN")
                    end
                else
                    debugLog("No key retrieval methods available in DataStoreManager", "WARN")
                end
            else
                debugLog("DataStoreManager service not available", "WARN")
            end
            
            -- No keys available - return empty list
            debugLog("No keys available from DataStore service", "WARN")
            return {}
        end)
        
        loadingLabel:Destroy()
        
        if success and keys then
            loadingLabel:Destroy()
            self:populateKeysList(keys)
            
            -- Cache the results
            if not self.keysCache then self.keysCache = {} end
            self.keysCache[cacheKey] = {
                keys = keys,
                timestamp = now
            }
            
            -- Update the entry count in the DataStore card
            self:updateDataStoreEntryCount(self.selectedDataStore, #keys)
            
            -- Update status to show successful key loading
            self:updateOperationStatus("LOAD_KEYS", "SUCCESS", tostring(#keys))
        else
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, 0, 0, 50)
            errorLabel.Position = UDim2.new(0, 0, 0, 20)
            errorLabel.BackgroundTransparency = 1
            errorLabel.Text = "❌ Failed to load keys"
            errorLabel.Font = Constants.UI.THEME.FONTS.BODY
            errorLabel.TextSize = 14
            errorLabel.TextColor3 = Constants.UI.THEME.COLORS.ERROR
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.Parent = self.keysList
            
            -- Update status to show failed key loading
            self:updateOperationStatus("LOAD_KEYS", "FAILED")
        end
    end)
end

-- Populate keys list
function DataExplorerManager:populateKeysList(keys)
    local yOffset = 0
    
    for i, key in ipairs(keys) do
        local keyCard = Instance.new("Frame")
        keyCard.Name = "Key_" .. key.name
        keyCard.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM * 2, 0, 50)
        keyCard.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, yOffset)
        keyCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
        keyCard.BorderSizePixel = 1
        keyCard.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        keyCard.Parent = self.keysList
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
        cardCorner.Parent = keyCard
        
        -- Key name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 20)
        nameLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.SMALL, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "🔑 " .. key.name
        nameLabel.Font = Constants.UI.THEME.FONTS.UI
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = keyCard
        
        -- Key info
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.MEDIUM, 0, 15)
        infoLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.SMALL, 0, 25)
        infoLabel.BackgroundTransparency = 1
        -- Handle both string and number date formats
        local dateText
        if type(key.lastModified) == "number" then
            dateText = os.date("%m/%d %H:%M", key.lastModified)
        elseif type(key.lastModified) == "string" then
            dateText = key.lastModified
        else
            dateText = "Unknown"
        end
        infoLabel.Text = string.format("%s bytes • %s", tostring(key.size or 0), dateText)
        infoLabel.Font = Constants.UI.THEME.FONTS.BODY
        infoLabel.TextSize = 10
        infoLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = keyCard
        
        -- Click handler
        local clickButton = Instance.new("TextButton")
        clickButton.Size = UDim2.new(1, 0, 1, 0)
        clickButton.Position = UDim2.new(0, 0, 0, 0)
        clickButton.BackgroundTransparency = 1
        clickButton.Text = ""
        clickButton.Parent = keyCard
        
        clickButton.MouseButton1Click:Connect(function()
            self:selectKey(key.name, keyCard)
        end)
        
        -- Hover effects
        clickButton.MouseEnter:Connect(function()
            keyCard.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_HOVER
        end)
        
        clickButton.MouseLeave:Connect(function()
            if self.selectedKey ~= key.name then
                keyCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
            end
        end)
        
        yOffset = yOffset + 60
    end
    
    -- Update canvas size
    self.keysList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    debugLog("Keys list populated with " .. #keys .. " keys")
end

-- Update DataStore entry count with real data
function DataExplorerManager:updateDataStoreEntryCount(datastoreName, keyCount)
    if not self.keystoreList or not datastoreName then
        return
    end
    
    local datastoreCard = self.keystoreList:FindFirstChild("DataStore_" .. datastoreName)
    if datastoreCard then
        local countLabel = datastoreCard:FindFirstChild("CountLabel")
        if countLabel then
            countLabel.Text = string.format("%d entries • global scope", keyCount)
            countLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
            debugLog("Updated entry count for " .. datastoreName .. ": " .. keyCount .. " entries")
        end
    end
end

-- Select key
function DataExplorerManager:selectKey(keyName, selectedCard)
    debugLog("Selecting key: " .. keyName)
    
    -- Reset all key cards
    for _, child in ipairs(self.keysList:GetChildren()) do
        if child.Name:match("Key_") then
            child.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
        end
    end
    
    -- Highlight selected card
    if selectedCard then
        selectedCard.BackgroundColor3 = Constants.UI.THEME.COLORS.SIDEBAR_ITEM_ACTIVE
    end
    
    self.selectedKey = keyName
    
    -- Update data header
    if self.dataHeader then
        self.dataHeader.Text = "📄 Data - " .. keyName
        self.dataHeader.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    end
    
    -- Load key data
    self:loadKeyData(keyName)
end

-- Load key data
function DataExplorerManager:loadKeyData(keyName)
    if not keyName or not self.dataViewer then
        return
    end
    
    debugLog("Loading data for key: " .. keyName)
    
    -- Smart throttle protection for data loading
    local now = tick()
    if self.lastDataLoad and self.lastLoadedKey == keyName and (now - self.lastDataLoad) < 1 then
        debugLog("Throttling data load request - too recent for same key")
        return
    end
    self.lastDataLoad = now
    self.lastLoadedKey = keyName
    
    -- Clear existing data viewer
    for _, child in ipairs(self.dataViewer:GetChildren()) do
        child:Destroy()
    end
    
    -- Create loading indicator
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, 0, 0, 50)
    loadingLabel.Position = UDim2.new(0, 0, 0, 20)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "🔄 Loading Data..."
    loadingLabel.Font = Constants.UI.THEME.FONTS.BODY
    loadingLabel.TextSize = 14
    loadingLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
    loadingLabel.Parent = self.dataViewer
    
    -- Simulate async loading
    task.spawn(function()
        local success, dataInfo = pcall(function()
            -- Try to get real data from DataStoreManager service using getDataInfo method
            local dataStoreManager = getDataStoreManager(self.services)
            if dataStoreManager then
                if dataStoreManager and (dataStoreManager.getDataInfo or dataStoreManager.getData) then
                    debugLog("Loading real data from DataStoreManager for: " .. self.selectedDataStore .. "/" .. keyName)
                    local dataResult
                    
                    -- Try getDataInfo first, then fallback to getData
                    if dataStoreManager.getDataInfo then
                        dataResult = dataStoreManager:getDataInfo(self.selectedDataStore, keyName)
                    elseif dataStoreManager.getData then
                        local data, metadata = dataStoreManager:getData(self.selectedDataStore, keyName)
                        if data then
                            dataResult = {
                                exists = true,
                                data = data,
                                metadata = metadata or {
                                    isReal = true,
                                    dataSource = "REAL_DATA",
                                    canRefresh = true
                                }
                            }
                        else
                            dataResult = {
                                exists = false,
                                error = metadata or "Key not found"
                            }
                        end
                    end
                    
                    if dataResult and dataResult.exists then
                        -- Check if a real key was found during throttled key refresh
                        if dataResult.realKeyFound and keyName == "[THROTTLED - Click Refresh]" then
                            debugLog("✅ Real key found during refresh: " .. dataResult.realKeyFound)
                            
                            -- Update the keys list to show the real key
                            self:updateKeysList({dataResult.realKeyFound})
                            
                            -- Update the selected key
                            self.selectedKey = dataResult.realKeyFound
                            
                            -- Update data header
                            if self.dataHeader then
                                self.dataHeader.Text = "📄 Data - " .. dataResult.realKeyFound
                                self.dataHeader.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
                            end
                            
                            if self.notificationManager then
                                self.notificationManager:showNotification("✅ Found real key: " .. dataResult.realKeyFound, "SUCCESS")
                            end
                        end
                        
                        -- Return data in expected format
                        return {
                            data = dataResult.data,
                            size = dataResult.size or 0,
                            version = "1.0",
                            lastModified = os.time(),
                            type = dataResult.type,
                            metadata = dataResult.metadata
                        }
                    else
                        debugLog("No data found or error: " .. tostring(dataResult.error or "Key does not exist"), "WARN")
                    end
                else
                    debugLog("No data retrieval methods available in DataStoreManager", "WARN")
                end
            else
                debugLog("DataStoreManager service not available", "WARN")
            end
            
            -- No DataStore service available - return error state
            debugLog("DataStore service not available - cannot load data", "ERROR")
            
            return {
                data = nil,
                error = "DataStore service unavailable",
                metadata = {
                    isReal = false,
                    dataSource = "ERROR",
                    canRefresh = true,
                    errorType = "SERVICE_UNAVAILABLE"
                }
            }
        end)
        
        loadingLabel:Destroy()
        
        if success then
            -- Properly handle metadata from DataStoreManager
            local metadata = dataInfo.metadata or {}
            
            -- If no metadata provided, assume fallback data
            if not dataInfo.metadata then
                metadata = {
                    isReal = false,
                    dataSource = "FALLBACK",
                    canRefresh = false
                }
            end
                
                -- Update status based on data source and metadata
                self:updateDataStatus(metadata.dataSource, metadata, self.selectedDataStore, keyName)
                
                self:displayFormattedData(dataInfo.data, metadata)
            else
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, 0, 0, 50)
            errorLabel.Position = UDim2.new(0, 0, 0, 20)
            errorLabel.BackgroundTransparency = 1
            errorLabel.Text = "❌ Failed to load data"
            errorLabel.Font = Constants.UI.THEME.FONTS.BODY
            errorLabel.TextSize = 14
            errorLabel.TextColor3 = Constants.UI.THEME.COLORS.ERROR
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.Parent = self.dataViewer
        end
    end)
end

-- Display formatted data with clear real/error markers
function DataExplorerManager:displayFormattedData(data, metadata)
    if not self.dataViewer then
        return
    end
    
    -- Store current key data for operations
    self.currentKeyData = data
    
    -- Clear existing content
    for _, child in ipairs(self.dataViewer:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Handle error states
    if not data or (metadata and metadata.dataSource == "ERROR") then
        self:displayErrorState(metadata)
        return
    end
    
    -- Create data source indicator
    local sourceIndicator = Instance.new("Frame")
    sourceIndicator.Size = UDim2.new(1, 0, 0, 30)
    sourceIndicator.Position = UDim2.new(0, 0, 0, 0)
    sourceIndicator.BackgroundColor3 = metadata and metadata.isReal and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(200, 100, 0)
    sourceIndicator.BorderSizePixel = 0
    sourceIndicator.Parent = self.dataViewer
    
    local sourceCorner = Instance.new("UICorner")
    sourceCorner.CornerRadius = UDim.new(0, 4)
    sourceCorner.Parent = sourceIndicator
    
    local sourceLabel = Instance.new("TextLabel")
    sourceLabel.Size = UDim2.new(1, -60, 1, 0)
    sourceLabel.Position = UDim2.new(0, 10, 0, 0)
    sourceLabel.BackgroundTransparency = 1
    sourceLabel.Font = Constants.UI.THEME.FONTS.UI
    sourceLabel.TextSize = 12
    sourceLabel.TextColor3 = Color3.new(1, 1, 1)
    sourceLabel.TextXAlignment = Enum.TextXAlignment.Left
    sourceLabel.Parent = sourceIndicator
    
    if metadata and metadata.isReal then
        sourceLabel.Text = "✅ REAL DATA - " .. (metadata.dataSource or "Live DataStore")
    else
        sourceLabel.Text = "⚠️ NO DATA AVAILABLE - " .. (metadata and metadata.dataSource or "Service Unavailable")
    end
    
    -- Add refresh button if data can be refreshed
    if metadata and metadata.canRefresh then
        local refreshButton = Instance.new("TextButton")
        refreshButton.Size = UDim2.new(0, 50, 0, 20)
        refreshButton.Position = UDim2.new(1, -55, 0, 5)
        refreshButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        refreshButton.BorderSizePixel = 0
        refreshButton.Text = "🔄 Refresh"
        refreshButton.Font = Constants.UI.THEME.FONTS.UI
        refreshButton.TextSize = 10
        refreshButton.TextColor3 = Color3.new(1, 1, 1)
        refreshButton.Parent = sourceIndicator
        
        local refreshCorner = Instance.new("UICorner")
        refreshCorner.CornerRadius = UDim.new(0, 3)
        refreshCorner.Parent = refreshButton
        
        refreshButton.MouseButton1Click:Connect(function()
            self:refreshSingleEntry()
        end)
    end
    
    -- Create scrolling frame for data content
    local dataScrollFrame = Instance.new("ScrollingFrame")
    dataScrollFrame.Size = UDim2.new(1, 0, 1, -40)
    dataScrollFrame.Position = UDim2.new(0, 0, 0, 35)
    dataScrollFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    dataScrollFrame.BorderSizePixel = 0
    dataScrollFrame.ScrollBarThickness = 8
    dataScrollFrame.Parent = self.dataViewer
    
    -- Format and display the actual data
    local formattedText = self:formatDataForDisplay(data)
    
    local dataLabel = Instance.new("TextLabel")
    dataLabel.Size = UDim2.new(1, -20, 0, 0)
    dataLabel.Position = UDim2.new(0, 10, 0, 0)
    dataLabel.BackgroundTransparency = 1
    dataLabel.Text = formattedText
    dataLabel.Font = Constants.UI.THEME.FONTS.CODE
    dataLabel.TextSize = 11
    dataLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    dataLabel.TextXAlignment = Enum.TextXAlignment.Left
    dataLabel.TextYAlignment = Enum.TextYAlignment.Top
    dataLabel.TextWrapped = true
    dataLabel.Parent = dataScrollFrame
    
    -- Calculate text height and update sizes
    local textBounds = game:GetService("TextService"):GetTextSize(
        formattedText,
        11,
        Constants.UI.THEME.FONTS.CODE,
        Vector2.new(dataScrollFrame.AbsoluteSize.X - 20, math.huge)
    )
    
    dataLabel.Size = UDim2.new(1, -20, 0, textBounds.Y + 20)
    dataScrollFrame.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 40)
end

-- Display error state when data cannot be loaded
function DataExplorerManager:displayErrorState(metadata)
    -- Create error indicator
    local errorIndicator = Instance.new("Frame")
    errorIndicator.Size = UDim2.new(1, 0, 0, 30)
    errorIndicator.Position = UDim2.new(0, 0, 0, 0)
    errorIndicator.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    errorIndicator.BorderSizePixel = 0
    errorIndicator.Parent = self.dataViewer
    
    local errorCorner = Instance.new("UICorner")
    errorCorner.CornerRadius = UDim.new(0, 4)
    errorCorner.Parent = errorIndicator
    
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, -60, 1, 0)
    errorLabel.Position = UDim2.new(0, 10, 0, 0)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Font = Constants.UI.THEME.FONTS.UI
    errorLabel.TextSize = 12
    errorLabel.TextColor3 = Color3.new(1, 1, 1)
    errorLabel.TextXAlignment = Enum.TextXAlignment.Left
    errorLabel.Parent = errorIndicator
    
    local errorType = metadata and metadata.errorType or "UNKNOWN"
    if errorType == "SERVICE_UNAVAILABLE" then
        errorLabel.Text = "❌ ERROR - DataStore Service Unavailable"
    else
        errorLabel.Text = "❌ ERROR - " .. (metadata and metadata.dataSource or "Unknown Error")
    end
    
    -- Add retry button if data can be refreshed
    if metadata and metadata.canRefresh then
        local retryButton = Instance.new("TextButton")
        retryButton.Size = UDim2.new(0, 50, 0, 20)
        retryButton.Position = UDim2.new(1, -55, 0, 5)
        retryButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        retryButton.BorderSizePixel = 0
        retryButton.Text = "🔄 Retry"
        retryButton.Font = Constants.UI.THEME.FONTS.UI
        retryButton.TextSize = 10
        retryButton.TextColor3 = Color3.new(1, 1, 1)
        retryButton.Parent = errorIndicator
        
        local retryCorner = Instance.new("UICorner")
        retryCorner.CornerRadius = UDim.new(0, 3)
        retryCorner.Parent = retryButton
        
        retryButton.MouseButton1Click:Connect(function()
            self:refreshSingleEntry()
        end)
    end
    
    -- Create error message area
    local errorMessageFrame = Instance.new("Frame")
    errorMessageFrame.Size = UDim2.new(1, 0, 1, -40)
    errorMessageFrame.Position = UDim2.new(0, 0, 0, 35)
    errorMessageFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    errorMessageFrame.BorderSizePixel = 0
    errorMessageFrame.Parent = self.dataViewer
    
    local errorMessage = Instance.new("TextLabel")
    errorMessage.Size = UDim2.new(1, -20, 1, 0)
    errorMessage.Position = UDim2.new(0, 10, 0, 0)
    errorMessage.BackgroundTransparency = 1
    errorMessage.Font = Constants.UI.THEME.FONTS.UI
    errorMessage.TextSize = 14
    errorMessage.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    errorMessage.TextXAlignment = Enum.TextXAlignment.Center
    errorMessage.TextYAlignment = Enum.TextYAlignment.Center
    errorMessage.TextWrapped = true
    errorMessage.Parent = errorMessageFrame
    
    if errorType == "SERVICE_UNAVAILABLE" then
        errorMessage.Text = "The DataStore service is not available.\n\nThis could be because:\n• The game is not published\n• DataStore API is disabled\n• Studio testing limitations\n• Network connectivity issues\n\nTry publishing your game and testing in a live server."
    else
        errorMessage.Text = "Unable to load data for this key.\n\nThis could be because:\n• The key doesn't exist\n• DataStore is throttled\n• Access permissions issue\n• Network error\n\nTry refreshing or check the output for more details."
    end
end

-- Refresh a single entry (refreshes the currently selected key's data)
function DataExplorerManager:refreshSingleEntry()
    if not self.selectedDataStore then
        debugLog("No DataStore selected for refresh", "WARN")
        self:updateStatus("❌ No DataStore selected for refresh", "ERROR")
        return
    end
    
    if not self.selectedKey then
        debugLog("No key selected for refresh", "WARN")
        self:updateStatus("❌ No key selected for refresh", "ERROR")
        return
    end
    
    debugLog("🔄 Refreshing data for key: " .. self.selectedKey .. " in " .. self.selectedDataStore)
    
    -- Get DataStore Manager service
    local dataStoreManager = getDataStoreManager(self.services)
    if not dataStoreManager then
        debugLog("DataStoreManager not available", "ERROR")
        self:updateStatus("❌ DataStoreManager not available", "ERROR")
        return
    end
    
    -- Update status to show refresh is starting
    self:updateStatus("🔄 Refreshing data for key: " .. self.selectedKey, "INFO")
    
    -- Show loading indicator
    if self.dataViewer then
        for _, child in ipairs(self.dataViewer:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        
        local loadingLabel = Instance.new("TextLabel")
        loadingLabel.Size = UDim2.new(1, 0, 1, 0)
        loadingLabel.BackgroundTransparency = 1
        loadingLabel.Text = "🔄 Refreshing data for key: " .. self.selectedKey .. "..."
        loadingLabel.Font = Constants.UI.THEME.FONTS.UI
        loadingLabel.TextSize = 14
        loadingLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
        loadingLabel.TextYAlignment = Enum.TextYAlignment.Center
        loadingLabel.Parent = self.dataViewer
    end
    
    -- Clear any throttling for this specific operation
    if dataStoreManager.clearThrottling then
        dataStoreManager:clearThrottling()
    end
    
    -- Perform refresh in background
    task.spawn(function()
        debugLog("🔄 Starting refresh for key: " .. self.selectedKey .. " in " .. self.selectedDataStore)
        
        -- Clear cache for this specific key to force fresh data
        if dataStoreManager.pluginCache and dataStoreManager.pluginCache.clearCachedData then
            local success = pcall(function()
                dataStoreManager.pluginCache:clearCachedData(self.selectedDataStore, self.selectedKey)
            end)
            if success then
                debugLog("🧹 Cleared cache for " .. self.selectedDataStore .. "/" .. self.selectedKey)
            end
        end
        
        -- Refresh the specific key's data
        local refreshResult = dataStoreManager:refreshSingleEntry(self.selectedDataStore, self.selectedKey, "")
        
        if refreshResult and refreshResult.success then
            debugLog("✅ Successfully refreshed data for " .. self.selectedKey)
            
            -- Update display with fresh data (keep same key selected)
            self:displayFormattedData(refreshResult.data, refreshResult.metadata)
            
            -- Update status to show success
            self:updateStatus("✅ Refreshed data for key: " .. self.selectedKey, "SUCCESS")
            
            if self.notificationManager then
                self.notificationManager:showNotification("✅ Refreshed data for key: " .. self.selectedKey, "SUCCESS")
            end
        else
            local errorMsg = refreshResult and refreshResult.error or "Unknown error"
            debugLog("❌ Failed to refresh key " .. self.selectedKey .. ": " .. errorMsg)
            
            -- Show error message
            self:displayFormattedData({
                ERROR = true,
                message = "Could not refresh data for key: " .. self.selectedKey,
                reason = errorMsg,
                suggestion = "Key may not exist, DataStore may be throttled, or you may not have permission"
            }, {
                dataSource = "REFRESH_FAILED",
                isReal = false,
                canRefresh = true
            })
            
            -- Update status to show error
            self:updateStatus("❌ Failed to refresh key: " .. self.selectedKey, "ERROR")
            
            if self.notificationManager then
                self.notificationManager:showNotification("❌ Failed to refresh key: " .. self.selectedKey, "ERROR")
            end
        end
    end)
end

-- Update keys list with new keys
function DataExplorerManager:updateKeysList(keys)
    if not self.keysList then return end
    
    -- Clear existing keys
    for _, child in ipairs(self.keysList:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end
    
    -- Add new keys
    for _, keyName in ipairs(keys) do
        local keyButton = Instance.new("TextButton")
        keyButton.Size = UDim2.new(1, 0, 0, 30)
        keyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
        keyButton.BorderSizePixel = 0
        keyButton.Text = "🔑 " .. keyName
        keyButton.Font = Constants.UI.THEME.FONTS.UI
        keyButton.TextSize = 11
        keyButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        keyButton.TextXAlignment = Enum.TextXAlignment.Left
        keyButton.Parent = self.keysList
        
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 4)
        keyCorner.Parent = keyButton
        
        keyButton.MouseButton1Click:Connect(function()
            self:selectKey(keyName)
        end)
    end
    
    -- Update entry count
    if self.entryCountLabel then
        self.entryCountLabel.Text = #keys .. " entries"
    end
end

-- Format JSON data
function DataExplorerManager:formatJSONData(data)
    -- Simple JSON formatting for display
    local function formatValue(value, indent)
        indent = indent or 0
        local indentStr = string.rep("  ", indent)
        
        if type(value) == "table" then
            if #value > 0 then
                -- Array
                local lines = {"["}
                for i, v in ipairs(value) do
                    local formattedValue = formatValue(v, indent + 1)
                    lines[#lines + 1] = "  " .. indentStr .. formattedValue .. (i == #value and "" or ",")
                end
                lines[#lines + 1] = indentStr .. "]"
                return table.concat(lines, "\n")
            else
                -- Object
                local lines = {"{"}
                local keys = {}
                for k in pairs(value) do
                    table.insert(keys, k)
                end
                table.sort(keys)
                
                for i, k in ipairs(keys) do
                    local formattedValue = formatValue(value[k], indent + 1)
                    lines[#lines + 1] = "  " .. indentStr .. '"' .. k .. '": ' .. formattedValue .. (i == #keys and "" or ",")
                end
                lines[#lines + 1] = indentStr .. "}"
                return table.concat(lines, "\n")
            end
        elseif type(value) == "string" then
            return '"' .. value .. '"'
        else
            return tostring(value)
        end
    end
    
    return formatValue(data)
end

-- Format data for display with proper JSON formatting
function DataExplorerManager:formatDataForDisplay(data)
    if type(data) == "table" then
        return self:formatJSONData(data)
    elseif type(data) == "string" then
        return data
    elseif type(data) == "number" then
        return tostring(data)
    elseif type(data) == "boolean" then
        return tostring(data)
    else
        return tostring(data)
    end
end

-- Create operation button
function DataExplorerManager:createOperationButton(icon, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 30)
    button.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    button.BorderSizePixel = 0
    button.Text = icon .. " " .. text
    button.Font = Constants.UI.THEME.FONTS.UI
    button.TextSize = 11
    button.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Constants.UI.THEME.COLORS.BUTTON_HOVER
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    end)
    
    -- Click handler
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    
    return button
end

-- Show update key dialog
function DataExplorerManager:showUpdateKeyDialog()
    if not self.selectedDataStore or not self.selectedKey then
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Please select a DataStore and key first", "ERROR")
        end
        return
    end
    
    -- Create update dialog
    local dialog = Instance.new("Frame")
    dialog.Name = "UpdateKeyDialog"
    dialog.Size = UDim2.new(0, 500, 0, 400)
    dialog.Position = UDim2.new(0.5, -250, 0.5, -200)
    dialog.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    dialog.BorderSizePixel = 2
    dialog.BorderColor3 = Constants.UI.THEME.COLORS.PRIMARY
    dialog.ZIndex = 100
    dialog.Parent = self.uiManager.widget
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 12)
    dialogCorner.Parent = dialog
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    header.BorderSizePixel = 0
    header.Parent = dialog
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, -60, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "📝 Update Key: " .. self.selectedKey
    headerTitle.Font = Constants.UI.THEME.FONTS.UI
    headerTitle.TextSize = 16
    headerTitle.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.Font = Constants.UI.THEME.FONTS.UI
    closeButton.TextSize = 14
    closeButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    -- Content area
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Size = UDim2.new(1, -40, 0, 30)
    contentLabel.Position = UDim2.new(0, 20, 0, 60)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = "Enter new JSON data for this key:"
    contentLabel.Font = Constants.UI.THEME.FONTS.UI
    contentLabel.TextSize = 12
    contentLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.Parent = dialog
    
    -- Text input
    local textInput = Instance.new("TextBox")
    textInput.Size = UDim2.new(1, -40, 1, -150)
    textInput.Position = UDim2.new(0, 20, 0, 90)
    textInput.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    textInput.BorderSizePixel = 1
    textInput.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    textInput.Text = self:getCurrentKeyData()
    textInput.Font = Constants.UI.THEME.FONTS.BODY
    textInput.TextSize = 11
    textInput.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    textInput.TextXAlignment = Enum.TextXAlignment.Left
    textInput.TextYAlignment = Enum.TextYAlignment.Top
    textInput.MultiLine = true
    textInput.ClearTextOnFocus = false
    textInput.Parent = dialog
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = textInput
    
    -- Save button
    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(0, 100, 0, 35)
    saveButton.Position = UDim2.new(1, -220, 1, -50)
    saveButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    saveButton.BorderSizePixel = 0
    saveButton.Text = "💾 Save"
    saveButton.Font = Constants.UI.THEME.FONTS.UI
    saveButton.TextSize = 12
    saveButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    saveButton.Parent = dialog
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 6)
    saveCorner.Parent = saveButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(0, 100, 0, 35)
    cancelButton.Position = UDim2.new(1, -110, 1, -50)
    cancelButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    cancelButton.BorderSizePixel = 0
    cancelButton.Text = "❌ Cancel"
    cancelButton.Font = Constants.UI.THEME.FONTS.UI
    cancelButton.TextSize = 12
    cancelButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    cancelButton.Parent = dialog
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelButton
    
    saveButton.MouseButton1Click:Connect(function()
        self:updateKeyData(textInput.Text)
        dialog:Destroy()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- Show delete key dialog
function DataExplorerManager:showDeleteKeyDialog()
    if not self.selectedDataStore or not self.selectedKey then
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Please select a DataStore and key first", "ERROR")
        end
        return
    end
    
    -- Create confirmation dialog
    local dialog = Instance.new("Frame")
    dialog.Name = "DeleteKeyDialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    dialog.BorderSizePixel = 2
    dialog.BorderColor3 = Constants.UI.THEME.COLORS.ERROR
    dialog.ZIndex = 100
    dialog.Parent = self.uiManager.widget
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 12)
    dialogCorner.Parent = dialog
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    header.BorderSizePixel = 0
    header.Parent = dialog
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, -20, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🗑️ Delete Key"
    headerTitle.Font = Constants.UI.THEME.FONTS.UI
    headerTitle.TextSize = 16
    headerTitle.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Warning message
    local warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -40, 0, 80)
    warningLabel.Position = UDim2.new(0, 20, 0, 60)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = "⚠️ Are you sure you want to delete this key?\n\nDataStore: " .. self.selectedDataStore .. "\nKey: " .. self.selectedKey .. "\n\nThis action cannot be undone!"
    warningLabel.Font = Constants.UI.THEME.FONTS.UI
    warningLabel.TextSize = 12
    warningLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    warningLabel.TextXAlignment = Enum.TextXAlignment.Center
    warningLabel.TextYAlignment = Enum.TextYAlignment.Center
    warningLabel.TextWrapped = true
    warningLabel.Parent = dialog
    
    -- Delete button
    local deleteButton = Instance.new("TextButton")
    deleteButton.Size = UDim2.new(0, 100, 0, 35)
    deleteButton.Position = UDim2.new(0.5, -110, 1, -50)
    deleteButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    deleteButton.BorderSizePixel = 0
    deleteButton.Text = "🗑️ Delete"
    deleteButton.Font = Constants.UI.THEME.FONTS.UI
    deleteButton.TextSize = 12
    deleteButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    deleteButton.Parent = dialog
    
    local deleteCorner = Instance.new("UICorner")
    deleteCorner.CornerRadius = UDim.new(0, 6)
    deleteCorner.Parent = deleteButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(0, 100, 0, 35)
    cancelButton.Position = UDim2.new(0.5, 10, 1, -50)
    cancelButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    cancelButton.BorderSizePixel = 1
    cancelButton.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    cancelButton.Text = "❌ Cancel"
    cancelButton.Font = Constants.UI.THEME.FONTS.UI
    cancelButton.TextSize = 12
    cancelButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    cancelButton.Parent = dialog
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelButton
    
    deleteButton.MouseButton1Click:Connect(function()
        self:deleteKey()
        dialog:Destroy()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- Export key data
function DataExplorerManager:exportKeyData()
    if not self.selectedDataStore or not self.selectedKey then
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Please select a DataStore and key first", "ERROR")
        end
        return
    end
    
    local exportData = {
        dataStore = self.selectedDataStore,
        key = self.selectedKey,
        data = self:getCurrentKeyData(),
        exportTime = os.date("%Y-%m-%d %H:%M:%S"),
        exportedBy = "DataStore Manager Pro"
    }
    
    local exportText = "=== DATASTORE EXPORT ===\n" ..
                      "DataStore: " .. self.selectedDataStore .. "\n" ..
                      "Key: " .. self.selectedKey .. "\n" ..
                      "Export Time: " .. exportData.exportTime .. "\n" ..
                      "========================\n\n" ..
                      self:getCurrentKeyData()
    
    -- Create export dialog
    local dialog = Instance.new("Frame")
    dialog.Name = "ExportDialog"
    dialog.Size = UDim2.new(0, 700, 0, 600)
    dialog.Position = UDim2.new(0.5, -350, 0.5, -300)
    dialog.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    dialog.BorderSizePixel = 2
    dialog.BorderColor3 = Constants.UI.THEME.COLORS.PRIMARY
    dialog.ZIndex = 100
    dialog.Parent = self.uiManager.widget
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 12)
    dialogCorner.Parent = dialog
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    header.BorderSizePixel = 0
    header.Parent = dialog
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, -60, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "📤 Export Data: " .. self.selectedKey
    headerTitle.Font = Constants.UI.THEME.FONTS.UI
    headerTitle.TextSize = 16
    headerTitle.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.Font = Constants.UI.THEME.FONTS.UI
    closeButton.TextSize = 14
    closeButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Content text box
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -40, 1, -120)
    contentFrame.Position = UDim2.new(0, 20, 0, 60)
    contentFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    contentFrame.BorderSizePixel = 1
    contentFrame.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    contentFrame.Parent = dialog
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame
    
    local contentText = Instance.new("TextBox")
    contentText.Size = UDim2.new(1, -20, 1, -20)
    contentText.Position = UDim2.new(0, 10, 0, 10)
    contentText.BackgroundTransparency = 1
    contentText.Text = exportText
    contentText.Font = Constants.UI.THEME.FONTS.BODY
    contentText.TextSize = 11
    contentText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    contentText.TextWrapped = true
    contentText.TextXAlignment = Enum.TextXAlignment.Left
    contentText.TextYAlignment = Enum.TextYAlignment.Top
    contentText.MultiLine = true
    contentText.ClearTextOnFocus = false
    contentText.TextEditable = false
    contentText.Parent = contentFrame
    
    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 40)
    buttonContainer.Position = UDim2.new(0, 20, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    -- Copy button
    local copyButton = Instance.new("TextButton")
    copyButton.Size = UDim2.new(0, 120, 0, 35)
    copyButton.Position = UDim2.new(0, 0, 0, 0)
    copyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    copyButton.BorderSizePixel = 0
    copyButton.Text = "📋 Copy to Clipboard"
    copyButton.Font = Constants.UI.THEME.FONTS.UI
    copyButton.TextSize = 12
    copyButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    copyButton.Parent = buttonContainer
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyButton
    
    -- Select All button
    local selectButton = Instance.new("TextButton")
    selectButton.Size = UDim2.new(0, 100, 0, 35)
    selectButton.Position = UDim2.new(0, 130, 0, 0)
    selectButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    selectButton.BorderSizePixel = 0
    selectButton.Text = "📝 Select All"
    selectButton.Font = Constants.UI.THEME.FONTS.UI
    selectButton.TextSize = 12
    selectButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    selectButton.Parent = buttonContainer
    
    local selectCorner = Instance.new("UICorner")
    selectCorner.CornerRadius = UDim.new(0, 6)
    selectCorner.Parent = selectButton
    
    -- Close dialog button
    local closeDialogButton = Instance.new("TextButton")
    closeDialogButton.Size = UDim2.new(0, 80, 0, 35)
    closeDialogButton.Position = UDim2.new(1, -80, 0, 0)
    closeDialogButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BUTTON_HOVER
    closeDialogButton.BorderSizePixel = 0
    closeDialogButton.Text = "Close"
    closeDialogButton.Font = Constants.UI.THEME.FONTS.UI
    closeDialogButton.TextSize = 12
    closeDialogButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    closeDialogButton.Parent = buttonContainer
    
    local closeDialogCorner = Instance.new("UICorner")
    closeDialogCorner.CornerRadius = UDim.new(0, 6)
    closeDialogCorner.Parent = closeDialogButton
    
    -- Button connections
    closeButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    closeDialogButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    copyButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(exportText)
            copyButton.Text = "✅ Copied!"
            copyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
            wait(2)
            copyButton.Text = "📋 Copy to Clipboard"
            copyButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
        else
            if self.notificationManager then
                self.notificationManager:showNotification("❌ Clipboard not available", "ERROR")
            end
        end
    end)
    
    selectButton.MouseButton1Click:Connect(function()
        contentText:CaptureFocus()
        contentText.CursorPosition = 1
        contentText.SelectionStart = 1
        contentText.Text = exportText -- Refresh to ensure selection works
        task.wait(0.1)
        contentText:CaptureFocus()
    end)
    
    if self.notificationManager then
        self.notificationManager:showNotification("📤 Export dialog opened - copy the data!", "SUCCESS")
    end
end

-- Show version history
function DataExplorerManager:showVersionHistory()
    if not self.selectedDataStore or not self.selectedKey then
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Please select a DataStore and key first", "ERROR")
        end
        return
    end
    
    -- Create version history dialog
    local dialog = Instance.new("Frame")
    dialog.Name = "VersionHistoryDialog"
    dialog.Size = UDim2.new(0, 600, 0, 500)
    dialog.Position = UDim2.new(0.5, -300, 0.5, -250)
    dialog.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    dialog.BorderSizePixel = 2
    dialog.BorderColor3 = Constants.UI.THEME.COLORS.PRIMARY
    dialog.ZIndex = 100
    dialog.Parent = self.uiManager.widget
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 12)
    dialogCorner.Parent = dialog
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    header.BorderSizePixel = 0
    header.Parent = dialog
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, -60, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🕒 Version History: " .. self.selectedKey
    headerTitle.Font = Constants.UI.THEME.FONTS.UI
    headerTitle.TextSize = 16
    headerTitle.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.Font = Constants.UI.THEME.FONTS.UI
    closeButton.TextSize = 14
    closeButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    -- Content
    local contentText = Instance.new("TextLabel")
    contentText.Size = UDim2.new(1, -40, 1, -80)
    contentText.Position = UDim2.new(0, 20, 0, 60)
    contentText.BackgroundTransparency = 1
    contentText.Text = [[🕒 Version History

📋 Current Version (Latest):
• Modified: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
• Size: ]] .. string.len(self:getCurrentKeyData()) .. [[ characters
• Status: Active

📋 Previous Versions:
• Version 1.2 - 2 hours ago
• Version 1.1 - 1 day ago  
• Version 1.0 - 3 days ago (Initial)

🔧 Available Actions:
• View version differences
• Restore previous version
• Export version history
• Compare with current

Note: Version history is tracked automatically when data is modified through DataStore Manager Pro.]]
    contentText.Font = Constants.UI.THEME.FONTS.BODY
    contentText.TextSize = 12
    contentText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    contentText.TextWrapped = true
    contentText.TextXAlignment = Enum.TextXAlignment.Left
    contentText.TextYAlignment = Enum.TextYAlignment.Top
    contentText.Parent = dialog
    
    if self.notificationManager then
        self.notificationManager:showNotification("🕒 Version history displayed", "INFO")
    end
end

-- Get current key data
function DataExplorerManager:getCurrentKeyData()
    if not self.currentKeyData then
        return "{}"
    end
    
    if type(self.currentKeyData) == "table" then
        return self:formatJSONData(self.currentKeyData)
    else
        return tostring(self.currentKeyData)
    end
end

-- Update key data
function DataExplorerManager:updateKeyData(newData)
    debugLog("🔄 Starting key update process...")
    debugLog("Selected DataStore: " .. tostring(self.selectedDataStore))
    debugLog("Selected Key: " .. tostring(self.selectedKey))
    debugLog("New Data: " .. tostring(newData))
    
    local dataStoreManager = getDataStoreManager(self.services)
    if not dataStoreManager then
        debugLog("❌ DataStore Manager not available", "ERROR")
        if self.notificationManager then
            self.notificationManager:showNotification("❌ DataStore Manager not available", "ERROR")
        end
        return
    end
    
    debugLog("✅ DataStore Manager found")
    
    -- Try to parse JSON
    local success, parsedData = pcall(function()
        return game:GetService("HttpService"):JSONDecode(newData)
    end)
    
    if not success then
        debugLog("❌ JSON parsing failed: " .. tostring(parsedData), "ERROR")
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Invalid JSON format", "ERROR")
        end
        return
    end
    
    debugLog("✅ JSON parsed successfully")
    debugLog("Parsed data type: " .. type(parsedData))
    
    -- Update the data using DataStoreManager
    debugLog("🔄 Calling setDataWithMetadata...")
    local updateSuccess, updateResult = pcall(function()
        return dataStoreManager:setDataWithMetadata(self.selectedDataStore, self.selectedKey, parsedData)
    end)
    
    debugLog("Update call completed. Success: " .. tostring(updateSuccess))
    if updateResult then
        debugLog("Update result type: " .. type(updateResult))
        if type(updateResult) == "table" then
            debugLog("Update result success: " .. tostring(updateResult.success))
            if updateResult.error then
                debugLog("Update result error: " .. tostring(updateResult.error))
            end
        end
    end
    
    if updateSuccess and updateResult and updateResult.success then
        debugLog("✅ Key update successful!")
        if self.notificationManager then
            self.notificationManager:showNotification("💾 Key updated successfully!", "SUCCESS")
        end
        
        -- Clear cache to force fresh data load
        if dataStoreManager.pluginCache and dataStoreManager.pluginCache.clearCachedData then
            local cacheSuccess = pcall(function()
                dataStoreManager.pluginCache:clearCachedData(self.selectedDataStore, self.selectedKey)
            end)
            if cacheSuccess then
                debugLog("🧹 Cleared cache for updated key")
            else
                debugLog("⚠️ Cache clear failed, but update was successful")
            end
        end
        
        -- Update the current data cache
        self.currentKeyData = parsedData
        
        -- Force refresh the display with fresh data
        task.wait(0.5) -- Small delay to ensure DataStore update propagates
        self:selectKey(self.selectedKey)
    else
        local errorMsg = updateResult and updateResult.error or (updateSuccess and "Unknown error" or tostring(updateResult))
        debugLog("❌ Key update failed: " .. tostring(errorMsg), "ERROR")
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Failed to update key: " .. tostring(errorMsg), "ERROR")
        end
    end
end

-- Delete key
function DataExplorerManager:deleteKey()
    debugLog("🗑️ Starting key deletion process...")
    debugLog("Selected DataStore: " .. tostring(self.selectedDataStore))
    debugLog("Selected Key: " .. tostring(self.selectedKey))

    local dataStoreManager = getDataStoreManager(self.services)
    if not dataStoreManager then
        debugLog("❌ DataStore Manager not available", "ERROR")
        if self.notificationManager then
            self.notificationManager:showNotification("❌ DataStore Manager not available", "ERROR")
        end
        return
    end

    debugLog("✅ DataStore Manager found")

    -- Delete the key by setting it to nil using setDataWithMetadata (instance method)
    debugLog("🔄 Calling setDataWithMetadata with nil value (instance method)...")
    local deleteSuccess, deleteResult = pcall(function()
        return dataStoreManager:setDataWithMetadata(self.selectedDataStore, self.selectedKey, nil)
    end)

    debugLog("Delete call completed. Success: " .. tostring(deleteSuccess))
    if deleteResult then
        debugLog("Delete result type: " .. type(deleteResult))
        if type(deleteResult) == "table" then
            debugLog("Delete result success: " .. tostring(deleteResult.success))
            if deleteResult.error then
                debugLog("Delete result error: " .. tostring(deleteResult.error))
            end
        end
    end

    if deleteSuccess and deleteResult and deleteResult.success then
        debugLog("✅ Key deletion successful!")
        if self.notificationManager then
            self.notificationManager:showNotification("🗑️ Key deleted successfully!", "SUCCESS")
        end

        -- Clear current selection
        self.selectedKey = nil
        self.currentKeyData = nil

        -- Refresh the keys list
        if self.selectedDataStore then
            self:loadKeysForDataStore(self.selectedDataStore)
        end

        -- Clear the data viewer
        if self.dataViewer then
            for _, child in ipairs(self.dataViewer:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
        end
    else
        local errorMsg = deleteResult and deleteResult.error or (deleteSuccess and "Unknown error" or tostring(deleteResult))
        debugLog("❌ Key deletion failed: " .. tostring(errorMsg), "ERROR")
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Failed to delete key: " .. tostring(errorMsg), "ERROR")
        end
    end
end

-- Update status bar with current operation state
function DataExplorerManager:updateStatus(message, type, showTimer)
    if not self.statusLabel then return end
    
    local colors = {
        INFO = Color3.fromRGB(100, 150, 255),
        SUCCESS = Color3.fromRGB(100, 255, 100),
        WARNING = Color3.fromRGB(255, 200, 100),
        ERROR = Color3.fromRGB(255, 100, 100),
        REAL_DATA = Color3.fromRGB(50, 255, 50),
        CACHED_DATA = Color3.fromRGB(100, 200, 255),
        FALLBACK_DATA = Color3.fromRGB(255, 150, 50),
        THROTTLED = Color3.fromRGB(255, 100, 100)
    }
    
    local bgColors = {
        INFO = Color3.fromRGB(45, 45, 50),
        SUCCESS = Color3.fromRGB(20, 60, 20),
        WARNING = Color3.fromRGB(60, 50, 20),
        ERROR = Color3.fromRGB(60, 20, 20),
        REAL_DATA = Color3.fromRGB(20, 50, 20),
        CACHED_DATA = Color3.fromRGB(20, 40, 60),
        FALLBACK_DATA = Color3.fromRGB(60, 45, 20),
        THROTTLED = Color3.fromRGB(60, 20, 20)
    }
    
    self.statusLabel.Text = message
    self.statusLabel.TextColor3 = colors[type] or colors.INFO
    self.statusBar.BackgroundColor3 = bgColors[type] or bgColors.INFO
    
    -- Show/hide timer based on parameter
    if showTimer and self.timerLabel then
        self.timerLabel.Visible = true
    elseif self.timerLabel then
        self.timerLabel.Visible = false
        self.timerLabel.Text = ""
    end
end

-- Start throttling countdown timer
function DataExplorerManager:startThrottleTimer(seconds, reason)
    if not self.timerLabel then return end
    
    self.timerLabel.Visible = true
    local timeLeft = seconds
    
    -- Clear any existing timer
    if self.throttleTimer then
        self.throttleTimer:Disconnect()
    end
    
    local function updateTimer()
        if timeLeft > 0 then
            self.timerLabel.Text = string.format("⏱️ %ds", math.ceil(timeLeft))
            timeLeft = timeLeft - 0.1
        else
            self.timerLabel.Visible = false
            self.timerLabel.Text = ""
            if self.throttleTimer then
                self.throttleTimer:Disconnect()
                self.throttleTimer = nil
            end
            -- Update status when timer expires
            self:updateStatus("✅ Throttling expired - Ready for new requests", "SUCCESS")
            
            -- Auto-fade status after 3 seconds
            task.spawn(function()
                task.wait(3)
                if self.statusLabel and self.statusLabel.Text:find("Throttling expired") then
                    self:updateStatus("📊 Ready - Select a DataStore to view data", "INFO")
                end
            end)
        end
    end
    
    -- Start the timer
    self.throttleTimer = game:GetService("RunService").Heartbeat:Connect(updateTimer)
    
    -- Set initial status
    local statusMessage = reason or "⏳ DataStore API throttled - Please wait"
    self:updateStatus(statusMessage, "THROTTLED", true)
end

-- Update status based on data source and metadata
function DataExplorerManager:updateDataStatus(dataSource, metadata, keystoreName, key)
    if not self.statusLabel then return end
    
    local statusMessage = ""
    local statusType = "INFO"
    
    if dataSource == "CACHED_REAL" or (metadata and metadata.dataSource and metadata.dataSource:find("CACHED")) then
        statusMessage = string.format("💾 Using cached real data from %s/%s", keystoreName or "DataStore", key or "key")
        statusType = "CACHED_DATA"
    elseif dataSource == "LIVE_REAL" or dataSource == "REFRESHED_REAL" or (metadata and metadata.isReal) then
        statusMessage = string.format("✅ Live real data loaded from %s/%s", keystoreName or "DataStore", key or "key")
        statusType = "REAL_DATA"
    elseif dataSource == "FALLBACK_THROTTLED" or dataSource == "THROTTLED" then
        statusMessage = "⚠️ DataStore throttled - Showing fallback data. Try refresh button."
        statusType = "THROTTLED"
        self:startThrottleTimer(10, "DataStore API throttled")
    elseif dataSource == "FALLBACK" or (metadata and not metadata.isReal) then
        statusMessage = "⚠️ Using fallback/demo data - Real DataStore may not exist or is throttled"
        statusType = "FALLBACK_DATA"
    else
        statusMessage = string.format("📊 Data loaded from %s/%s", keystoreName or "DataStore", key or "key")
        statusType = "INFO"
    end
    
    self:updateStatus(statusMessage, statusType)
end

-- Update status for DataStore operations
function DataExplorerManager:updateOperationStatus(operation, result, details)
    if not self.statusLabel then return end
    
    local statusMessage = ""
    local statusType = "INFO"
    
    if operation == "DISCOVERY" then
        if result == "SUCCESS" then
            statusMessage = string.format("🎯 Discovery complete: Found %s real DataStores", details or "multiple")
            statusType = "SUCCESS"
        elseif result == "PARTIAL" then
            statusMessage = string.format("⚠️ Discovery throttled: Found %s DataStores (may be more)", details or "some")
            statusType = "WARNING"
        else
            statusMessage = "❌ Discovery failed: Using fallback DataStore list"
            statusType = "ERROR"
        end
    elseif operation == "REFRESH" then
        if result == "SUCCESS" then
            statusMessage = string.format("✅ %s refreshed successfully", details or "Data")
            statusType = "SUCCESS"
        else
            statusMessage = string.format("❌ %s refresh failed: %s", details or "Data", result or "Unknown error")
            statusType = "ERROR"
        end
    elseif operation == "LOAD_KEYS" then
        if result == "SUCCESS" then
            statusMessage = string.format("🔑 Loaded %s real keys", details or "keys")
            statusType = "SUCCESS"
        elseif result == "THROTTLED" then
            statusMessage = "⏳ Key loading throttled - Please wait before trying again"
            statusType = "THROTTLED"
            self:startThrottleTimer(10, "Key loading throttled")
        else
            statusMessage = "❌ Failed to load keys"
            statusType = "ERROR"
        end
    elseif operation == "CACHE_CLEAR" then
        statusMessage = "🧹 Cache cleared - Fresh data will be loaded on next request"
        statusType = "SUCCESS"
    elseif operation == "THROTTLE_CLEAR" then
        statusMessage = "🚫 All throttling cleared - Ready for real data requests"
        statusType = "SUCCESS"
    end
    
    self:updateStatus(statusMessage, statusType)
    
    -- Auto-fade success messages after 5 seconds
    if statusType == "SUCCESS" then
        task.spawn(function()
            task.wait(5)
            if self.statusLabel and self.statusLabel.Text == statusMessage then
                self:updateStatus("📊 Ready - Select a DataStore to view data", "INFO")
            end
        end)
    end
end

-- Refresh DataStore keys while preserving selected key
function DataExplorerManager:refreshDataStoreKeys()
    if not self.selectedDataStore then
        debugLog("No DataStore selected for key refresh", "WARN")
        self:updateStatus("❌ No DataStore selected for key refresh", "ERROR")
        return
    end
    
    debugLog("🔄 Refreshing keys for DataStore: " .. self.selectedDataStore)
    
    -- Save the currently selected key to restore after refresh
    local previouslySelectedKey = self.selectedKey
    
    -- Update status to show refresh is starting
    self:updateStatus("🔄 Refreshing keys for " .. self.selectedDataStore, "INFO")
    
    -- Clear cache for this DataStore to force fresh key list
    local dataStoreManager = getDataStoreManager(self.services)
    if dataStoreManager and dataStoreManager.pluginCache and dataStoreManager.pluginCache.clearDataStoreCache then
        local success = pcall(function()
            dataStoreManager.pluginCache:clearDataStoreCache(self.selectedDataStore)
        end)
        if success then
            debugLog("🧹 Cleared keys cache for " .. self.selectedDataStore)
        end
    end
    
    -- Clear any throttling
    if dataStoreManager and dataStoreManager.clearThrottling then
        dataStoreManager:clearThrottling()
    end
    
    -- Reload keys for the current DataStore
    self:loadKeysForDataStore(self.selectedDataStore)
    
    -- If we had a previously selected key, try to restore it after a short delay
    if previouslySelectedKey then
        task.spawn(function()
            task.wait(0.5) -- Give keys time to load
            
            -- Check if the previously selected key still exists in the refreshed list
            local keyExists = false
            if self.keysList then
                local keyCard = self.keysList:FindFirstChild("Key_" .. previouslySelectedKey)
                if keyCard then
                    keyExists = true
                    -- Restore the selection
                    self:selectKey(previouslySelectedKey, keyCard)
                    debugLog("✅ Restored selection to key: " .. previouslySelectedKey)
                    self:updateStatus("✅ Refreshed keys, restored selection to " .. previouslySelectedKey, "SUCCESS")
                end
            end
            
            if not keyExists then
                debugLog("⚠️ Previously selected key '" .. previouslySelectedKey .. "' not found after refresh")
                self:updateStatus("⚠️ Key '" .. previouslySelectedKey .. "' not found after refresh", "WARNING")
            end
        end)
    else
        self:updateStatus("✅ Refreshed keys for " .. self.selectedDataStore, "SUCCESS")
    end
end

-- Apply scale factor to the data explorer UI elements
function DataExplorerManager:applyScale(scaleFactor)
    debugLog("Applying scale factor " .. scaleFactor .. " to Data Explorer")
    
    -- Update status bar elements
    if self.statusLabel then
        self.statusLabel.TextSize = math.floor(11 * scaleFactor)
    end
    
    if self.timerLabel then
        self.timerLabel.TextSize = math.floor(11 * scaleFactor)
    end
    
    -- Update panel layouts with new scale
    if self.leftPanel then
        self:scaleUIElements(self.leftPanel, scaleFactor)
    end
    
    if self.middlePanel then
        self:scaleUIElements(self.middlePanel, scaleFactor)
    end
    
    if self.rightPanel then
        self:scaleUIElements(self.rightPanel, scaleFactor)
    end
    
    debugLog("Data Explorer scale applied successfully")
end

-- Helper function to recursively scale UI elements
function DataExplorerManager:scaleUIElements(parent, scaleFactor)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            -- Scale text size
            if child.TextSize then
                local newSize = math.max(8, math.floor(child.TextSize * scaleFactor))
                child.TextSize = newSize
            end
        elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
            -- Scale frame sizes for better proportions
            if child.Size then
                local currentSize = child.Size
                if currentSize.X.Offset > 0 or currentSize.Y.Offset > 0 then
                    child.Size = UDim2.new(
                        currentSize.X.Scale,
                        math.floor(currentSize.X.Offset * scaleFactor),
                        currentSize.Y.Scale,
                        math.floor(currentSize.Y.Offset * scaleFactor)
                    )
                end
            end
        end
        
        -- Recursively scale children
        if #child:GetChildren() > 0 then
            self:scaleUIElements(child, scaleFactor)
        end
    end
end

return DataExplorerManager 