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
            if serviceName == "DataStoreManager" or serviceName == "core.data.DataStoreManager" then
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
    
    -- Three-column layout
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "DataStorePanel"
    leftPanel.Size = UDim2.new(0.25, -5, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    leftPanel.BorderSizePixel = 1
    leftPanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    leftPanel.Parent = explorerContainer
    
    local middlePanel = Instance.new("Frame")
    middlePanel.Name = "KeysPanel"
    middlePanel.Size = UDim2.new(0.35, -5, 1, 0)
    middlePanel.Position = UDim2.new(0.25, 5, 0, 0)
    middlePanel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    middlePanel.BorderSizePixel = 1
    middlePanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    middlePanel.Parent = explorerContainer
    
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "DataPanel"
    rightPanel.Size = UDim2.new(0.4, -5, 1, 0)
    rightPanel.Position = UDim2.new(0.6, 5, 0, 0)
    rightPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    leftPanel.BorderSizePixel = 1
    rightPanel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    rightPanel.Parent = explorerContainer
    
    -- Store references
    self.leftPanel = leftPanel
    self.middlePanel = middlePanel
    self.rightPanel = rightPanel
    
    -- Create columns
    self:createDataStoreColumns(leftPanel)
    self:createKeysColumn(middlePanel)
    self:createDataColumn(rightPanel)
    
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
    
    -- Button container for better layout
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 400, 1, 0)
    buttonContainer.Position = UDim2.new(1, -410, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = header
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 5)
    buttonLayout.Parent = buttonContainer
    
    -- Force refresh button (replaces discovery to avoid throttling)
    local forceRefreshButton = Instance.new("TextButton")
    forceRefreshButton.Size = UDim2.new(0, 110, 0, 25)
    forceRefreshButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    forceRefreshButton.BorderSizePixel = 0
    forceRefreshButton.Text = "🔄 Refresh"
    forceRefreshButton.Font = Constants.UI.THEME.FONTS.UI
    forceRefreshButton.TextSize = 10
    forceRefreshButton.TextColor3 = Color3.new(1, 1, 1)
    forceRefreshButton.Parent = buttonContainer
    
    local forceRefreshCorner = Instance.new("UICorner")
    forceRefreshCorner.CornerRadius = UDim.new(0, 4)
    forceRefreshCorner.Parent = forceRefreshButton
    
    -- Anti-throttling button
    local antiThrottleButton = Instance.new("TextButton")
    antiThrottleButton.Size = UDim2.new(0, 90, 0, 25)
    antiThrottleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    antiThrottleButton.BorderSizePixel = 0
    antiThrottleButton.Text = "🚫 Throttle"
    antiThrottleButton.Font = Constants.UI.THEME.FONTS.UI
    antiThrottleButton.TextSize = 10
    antiThrottleButton.TextColor3 = Color3.new(1, 1, 1)
    antiThrottleButton.Parent = buttonContainer
    
    local antiThrottleCorner = Instance.new("UICorner")
    antiThrottleCorner.CornerRadius = UDim.new(0, 4)
    antiThrottleCorner.Parent = antiThrottleButton
    
    -- Plugin cache clear button
    local cacheButton = Instance.new("TextButton")
    cacheButton.Size = UDim2.new(0, 85, 0, 25)
    cacheButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    cacheButton.BorderSizePixel = 0
    cacheButton.Text = "🧹 Cache"
    cacheButton.Font = Constants.UI.THEME.FONTS.UI
    cacheButton.TextSize = 10
    cacheButton.TextColor3 = Color3.new(1, 1, 1)
    cacheButton.Parent = buttonContainer
    
    local cacheCorner = Instance.new("UICorner")
    cacheCorner.CornerRadius = UDim.new(0, 4)
    cacheCorner.Parent = cacheButton
    
    -- Auto-discovery toggle button
    local autoDiscoveryButton = Instance.new("TextButton")
    autoDiscoveryButton.Size = UDim2.new(0, 75, 0, 25)
    autoDiscoveryButton.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    autoDiscoveryButton.BorderSizePixel = 0
    autoDiscoveryButton.Text = "🔄 Auto"
    autoDiscoveryButton.Font = Constants.UI.THEME.FONTS.UI
    autoDiscoveryButton.TextSize = 10
    autoDiscoveryButton.TextColor3 = Color3.new(1, 1, 1)
    autoDiscoveryButton.Parent = buttonContainer
    
    local autoDiscoveryCorner = Instance.new("UICorner")
    autoDiscoveryCorner.CornerRadius = UDim.new(0, 4)
    autoDiscoveryCorner.Parent = autoDiscoveryButton

    -- Button connections
    refreshButton.MouseButton1Click:Connect(function()
        self:loadDataStores()
    end)
    
    antiThrottleButton.MouseButton1Click:Connect(function()
        -- Clear all throttling from DataStoreManager
        local dataStoreManager = self.services and self.services["core.data.DataStoreManager"]
        if dataStoreManager and dataStoreManager.clearAllThrottling then
            dataStoreManager:clearAllThrottling()
            self:loadDataStores() -- Immediately try to reload data
            if self.notificationManager then
                self.notificationManager:showNotification("🚫 All throttling cleared - trying real data now!", "SUCCESS")
            else
                debugLog("🚫 All throttling cleared - trying real data now!")
            end
        else
            if self.notificationManager then
                self.notificationManager:showNotification("❌ Cannot clear throttling - DataStoreManager not available", "ERROR")
            else
                debugLog("❌ Cannot clear throttling - DataStoreManager not available", "ERROR")
            end
        end
    end)
    
    -- Plugin cache clear button connection
    cacheButton.MouseButton1Click:Connect(function()
        local dataStoreManager = self.services and self.services["core.data.DataStoreManager"]
        if dataStoreManager and dataStoreManager.pluginCache then
            dataStoreManager.pluginCache:clearAllCache()
            debugLog("🧹 Plugin cache cleared - fresh data will be loaded on next request")
            self:loadDataStores()
            if self.notificationManager then
                self.notificationManager:showNotification("🧹 Plugin cache cleared - fresh data will be loaded!", "SUCCESS")
            else
                debugLog("🧹 Plugin cache cleared successfully!")
            end
        else
            if self.notificationManager then
                self.notificationManager:showNotification("❌ Cannot clear cache - Plugin cache not available", "ERROR")
            else
                debugLog("❌ Cannot clear cache - Plugin cache not available", "ERROR")
            end
        end
    end)
    
    -- Force refresh button connection
    forceRefreshButton.MouseButton1Click:Connect(function()
        local dataStoreManager = self.services and self.services["core.data.DataStoreManager"]
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
        local dataStoreManager = self.services and self.services["core.data.DataStoreManager"]
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
    viewerContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    viewerContainer.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    viewerContainer.BackgroundTransparency = 1
    viewerContainer.BorderSizePixel = 0
    viewerContainer.ScrollBarThickness = 8
    viewerContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    viewerContainer.Parent = parent
    
    self.dataViewer = viewerContainer
    self.dataHeader = headerLabel
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
                debugLog("DataStoreManager full path: " .. tostring(self.services["core.data.DataStoreManager"] ~= nil))
            end
            
            if self.services and (self.services.DataStoreManager or self.services["core.data.DataStoreManager"]) then
                local dataStoreManager = self.services.DataStoreManager or self.services["core.data.DataStoreManager"]
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
            if self.services and (self.services.DataStoreManager or self.services["core.data.DataStoreManager"]) then
                local dataStoreManager = self.services.DataStoreManager or self.services["core.data.DataStoreManager"]
                if dataStoreManager and (dataStoreManager.getDataStoreEntries or dataStoreManager.getDataStoreKeys) then
                    debugLog("Loading real keys from DataStoreManager for: " .. self.selectedDataStore)
                    local keyList = dataStoreManager.getDataStoreEntries and dataStoreManager:getDataStoreEntries(self.selectedDataStore, "", 100) or dataStoreManager:getDataStoreKeys(self.selectedDataStore, "", 100)
                    
                    if keyList and #keyList > 0 then
                        -- Convert DataStore keys format to our expected format
                        local formattedKeys = {}
                        for i, keyInfo in ipairs(keyList) do
                            table.insert(formattedKeys, {
                                name = keyInfo.key,
                                size = math.random(100, 5000), -- Unknown size until we read the data
                                lastModified = keyInfo.lastModified or "Unknown"
                            })
                        end
                        debugLog("Successfully loaded " .. #formattedKeys .. " real keys")
                        return formattedKeys
                    else
                        debugLog("No keys returned from DataStoreManager", "WARN")
                    end
                else
                    debugLog("DataStoreManager.getDataStoreKeys method not available", "WARN")
                end
            else
                debugLog("DataStoreManager service not available", "WARN")
            end
            
            -- Fallback to mock keys for demo (these should be replaced with real keys)
            debugLog("Using fallback keys list (no DataStoreManager.getKeys found)")
            local mockKeys = {}
            
            -- Generate different keys based on DataStore name
            if self.selectedDataStore == "PlayerData" then
                for i = 1, 8 do
                    table.insert(mockKeys, {
                        name = "Player_" .. string.format("%09d", 123456780 + i),
                        size = math.random(800, 2500),
                        lastModified = os.time() - math.random(0, 86400 * 7)
                    })
                end
            elseif self.selectedDataStore == "PlayerStats" then
                for i = 1, 6 do
                    table.insert(mockKeys, {
                        name = "Stats_" .. string.format("%09d", 123456780 + i),
                        size = math.random(300, 1200),
                        lastModified = os.time() - math.random(0, 86400 * 14)
                    })
                end
            elseif self.selectedDataStore == "GameSettings" then
                local settingKeys = {"ServerConfig", "EventSettings", "GlobalSettings", "MatchmakingConfig", "EconomySettings"}
                for i, keyName in ipairs(settingKeys) do
                    table.insert(mockKeys, {
                        name = keyName,
                        size = math.random(200, 800),
                        lastModified = os.time() - math.random(0, 86400 * 3)
                    })
                end
            else
                for i = 1, 12 do
                    table.insert(mockKeys, {
                        name = "Key_" .. i,
                        size = math.random(100, 5000),
                        lastModified = os.time() - math.random(0, 86400 * 30)
                    })
                end
            end
            return mockKeys
        end)
        
        loadingLabel:Destroy()
        
        if success then
            -- Cache the keys to prevent throttling
            self.keysCache[cacheKey] = {
                keys = keys,
                timestamp = tick()
            }
            
            self:populateKeysList(keys)
            -- Update the entry count in the DataStore card
            self:updateDataStoreEntryCount(self.selectedDataStore, #keys)
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
        infoLabel.Text = string.format("%d bytes • %s", key.size, dateText)
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
    
    -- Throttle protection for data loading
    local now = tick()
    if self.lastDataLoad and (now - self.lastDataLoad) < 1 then
        debugLog("Throttling data load request - too recent")
        return
    end
    self.lastDataLoad = now
    
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
            if self.services and (self.services.DataStoreManager or self.services["core.data.DataStoreManager"]) then
                local dataStoreManager = self.services.DataStoreManager or self.services["core.data.DataStoreManager"]
                if dataStoreManager and dataStoreManager.getDataInfo then
                    debugLog("Loading real data from DataStoreManager for: " .. self.selectedDataStore .. "/" .. keyName)
                    local dataResult = dataStoreManager:getDataInfo(self.selectedDataStore, keyName)
                    
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
                    debugLog("DataStoreManager.getDataInfo method not available", "WARN")
                end
            else
                debugLog("DataStoreManager service not available", "WARN")
            end
            
            -- Fallback to mock data for demo (this should be replaced with real data)
            debugLog("Using fallback data (no DataStoreManager.getData found)")
            
            -- Generate different data based on DataStore name and key
            local fallbackData
            
            if self.selectedDataStore == "PlayerData" and keyName:match("Player_") then
                local playerId = keyName:match("Player_(%d+)")
                fallbackData = {
                    playerId = tonumber(playerId) or 123456789,
                    playerName = "TestPlayer" .. (playerId and playerId:sub(-3) or "123"),
                    level = math.random(1, 100),
                    experience = math.random(0, 50000),
                    coins = math.random(100, 10000),
                    inventory = {
                        {itemId = "sword_001", quantity = 1, equipped = true},
                        {itemId = "potion_heal", quantity = 5, equipped = false},
                        {itemId = "armor_chest", quantity = 1, equipped = true}
                    },
                    settings = {
                        musicEnabled = true,
                        soundEnabled = true,
                        difficulty = "Normal"
                    },
                    joinDate = "2024-01-15T10:30:00Z",
                    lastLogin = "2024-01-20T14:45:30Z"
                }
            elseif self.selectedDataStore == "PlayerStats" and keyName:match("Stats_") then
                local playerId = keyName:match("Stats_(%d+)")
                fallbackData = {
                    playerId = tonumber(playerId) or 123456789,
                    stats = {
                        gamesPlayed = math.random(1, 500),
                        gamesWon = math.random(1, 250),
                        totalPlayTime = math.random(3600, 360000),
                        highScore = math.random(1000, 100000),
                        achievements = math.random(5, 50)
                    },
                    rankings = {
                        globalRank = math.random(1, 10000),
                        seasonRank = math.random(1, 1000),
                        weeklyRank = math.random(1, 100)
                    },
                    performance = {
                        accuracy = math.random(60, 95) / 100,
                        avgKillsPerGame = math.random(5, 25),
                        survivabilityRate = math.random(40, 80) / 100
                    },
                    lastUpdated = "2024-01-20T16:30:00Z"
                }
            elseif self.selectedDataStore == "GameSettings" then
                if keyName == "ServerConfig" then
                    fallbackData = {
                        maxPlayers = 50,
                        gameMode = "Classic",
                        mapRotation = {"Forest Temple", "Ice Caverns", "Desert Ruins"},
                        eventActive = false,
                        maintenanceMode = false,
                        version = "2.1.5"
                    }
                elseif keyName == "EventSettings" then
                    fallbackData = {
                        currentEvent = "Winter Festival",
                        eventStart = "2024-01-01T00:00:00Z",
                        eventEnd = "2024-01-31T23:59:59Z",
                        bonusMultiplier = 2.0,
                        specialRewards = true,
                        participantCount = math.random(1000, 5000)
                    }
                else
                    fallbackData = {
                        setting = keyName,
                        value = "Sample configuration value",
                        lastModified = "2024-01-20T12:00:00Z",
                        configType = "system"
                    }
                end
            else
                fallbackData = {
                    message = "Sample fallback data for " .. (self.selectedDataStore or "Unknown"),
                    key = keyName,
                    timestamp = "2024-01-20T12:00:00Z",
                    dataStoreType = self.selectedDataStore,
                    note = "This is demonstration data - real DataStore access not available"
                }
            end
            
            return {
                data = fallbackData,
                size = string.len(tostring(fallbackData)) or 1247,
                version = "1.0",
                lastModified = os.time()
            }
        end)
        
        loadingLabel:Destroy()
        
                    if success then
                self:displayFormattedData(dataInfo.data, dataInfo.metadata or {
                    isReal = dataInfo.metadata and dataInfo.metadata.isReal or false,
                    dataSource = dataInfo.metadata and dataInfo.metadata.dataSource or "FALLBACK",
                    canRefresh = dataInfo.metadata and dataInfo.metadata.canRefresh or false
                })
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

-- Display formatted data with clear real/fallback markers
function DataExplorerManager:displayFormattedData(data, metadata)
    if not self.dataViewer then
        return
    end
    
    -- Clear existing content
    for _, child in ipairs(self.dataViewer:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Create data source indicator
    local sourceIndicator = Instance.new("Frame")
    sourceIndicator.Size = UDim2.new(1, 0, 0, 30)
    sourceIndicator.Position = UDim2.new(0, 0, 0, 0)
    sourceIndicator.BackgroundColor3 = metadata and metadata.isReal and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(150, 50, 0)
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
        sourceLabel.Text = "⚠️ FALLBACK DATA - " .. (metadata and metadata.dataSource or "Throttled/Demo")
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

-- Refresh a single entry
function DataExplorerManager:refreshSingleEntry()
    if not self.selectedDataStore then
        debugLog("No DataStore selected for refresh", "WARN")
        return
    end
    
    debugLog("🔄 Refreshing DataStore: " .. self.selectedDataStore)
    
    -- Get DataStore Manager service
    local dataStoreManager = self.services and (self.services.DataStoreManager or self.services["core.data.DataStoreManager"])
    if not dataStoreManager then
        debugLog("DataStoreManager not available", "ERROR")
        return
    end
    
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
        loadingLabel.Text = "🔄 Refreshing real data from " .. self.selectedDataStore .. "..."
        loadingLabel.Font = Constants.UI.THEME.FONTS.UI
        loadingLabel.TextSize = 14
        loadingLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
        loadingLabel.TextYAlignment = Enum.TextYAlignment.Center
        loadingLabel.Parent = self.dataViewer
    end
    
    -- Clear any throttling for this DataStore
    if dataStoreManager.clearThrottling then
        dataStoreManager:clearThrottling()
    end
    
    -- Perform refresh in background
    task.spawn(function()
        debugLog("🔄 Starting refresh for " .. self.selectedDataStore)
        
        -- Use the DataStoreManager's discovery method to find real keys
        local realKeys = dataStoreManager:getDataStoreEntries(self.selectedDataStore, "", 10)
        
        if realKeys and #realKeys > 0 then
            -- Check if we got real keys (not throttled)
            local hasRealKeys = false
            local firstRealKey = nil
            
            for _, keyData in ipairs(realKeys) do
                if keyData.isReal and keyData.key ~= "[THROTTLED - Click Refresh]" then
                    hasRealKeys = true
                    firstRealKey = keyData.key
                    break
                end
            end
            
            if hasRealKeys and firstRealKey then
                debugLog("✅ Found real key: " .. firstRealKey .. " in " .. self.selectedDataStore)
                
                -- Get the actual data for this key using refreshSingleEntry
                local refreshResult = dataStoreManager:refreshSingleEntry(self.selectedDataStore, firstRealKey, "")
                
                if refreshResult and refreshResult.success then
                    debugLog("✅ Successfully refreshed real data for " .. firstRealKey)
                    
                    -- Update the keys list to show the real key
                    self:updateKeysList({firstRealKey})
                    
                    -- Update display with real data
                    self:displayFormattedData(refreshResult.data, refreshResult.metadata)
                    
                    if self.notificationManager then
                        self.notificationManager:showNotification("✅ Found real data in " .. self.selectedDataStore .. "!", "SUCCESS")
                    end
                    
                    return
                else
                    debugLog("⚠️ Key " .. firstRealKey .. " refresh failed: " .. (refreshResult and refreshResult.error or "Unknown error"))
                end
            else
                debugLog("⚠️ No real keys found, trying direct DataStore access...")
                
                -- Try direct access to common key patterns
                local commonKeys = {"Player_" .. game.Players.LocalPlayer.UserId, "default", "global", "data", "config"}
                
                for _, testKey in ipairs(commonKeys) do
                    local refreshResult = dataStoreManager:refreshSingleEntry(self.selectedDataStore, testKey, "")
                    
                    if refreshResult and refreshResult.success then
                        debugLog("✅ Found real data with key: " .. testKey)
                        
                        -- Update the keys list to show the real key
                        self:updateKeysList({testKey})
                        
                        -- Update display with real data
                        self:displayFormattedData(refreshResult.data, refreshResult.metadata)
                        
                        if self.notificationManager then
                            self.notificationManager:showNotification("✅ Found real data in " .. self.selectedDataStore .. "!", "SUCCESS")
                        end
                        
                        return
                    end
                end
            end
        end
        
        -- If we get here, refresh failed
        debugLog("❌ Refresh failed for " .. self.selectedDataStore)
        
        -- Show error message
        self:displayFormattedData({
            ERROR = true,
            message = "Could not access real data from " .. self.selectedDataStore,
            reason = "DataStore may be empty, throttled, or doesn't exist",
            suggestion = "Try again in a few seconds, or check if this DataStore has data in your published game"
        }, {
            dataSource = "REFRESH_FAILED",
            isReal = false,
            canRefresh = true
        })
        
        if self.notificationManager then
            self.notificationManager:showNotification("❌ Could not access real data from " .. self.selectedDataStore, "ERROR")
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

return DataExplorerManager 