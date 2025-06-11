-- DataStore Manager Pro - Layout Manager
-- Manages UI layout creation and organization

local LayoutManager = {}
LayoutManager.__index = LayoutManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[LAYOUT_MANAGER] [%s] %s", level, message))
end

-- Create new Layout Manager instance
function LayoutManager.new(uiManager)
    local self = setmetatable({}, LayoutManager)
    
    self.uiManager = uiManager
    self.mainFrame = nil
    self.contentArea = nil
    self.mainContentArea = nil
    
    debugLog("LayoutManager created")
    return self
end

-- Create main frame
function LayoutManager:createMainFrame(widget, pluginInfo)
    debugLog("Creating main frame")
    
    -- Check if widget is a valid GUI object
    local widgetType = rawget(_G, "typeof") and typeof(widget) or type(widget)
    debugLog("Widget type: " .. widgetType)
    
    -- PluginGui objects in Roblox have typeof "userdata" but are valid GUI containers
    local isPluginGui = false
    if widgetType == "userdata" then
        local hasClassName, className = pcall(function() return widget.ClassName end)
        local hasEnabled = pcall(function() return widget.Enabled end)
        local hasTitle = pcall(function() return widget.Title end)
        
        if hasClassName then
            debugLog("Widget ClassName: " .. tostring(className))
            if className == "DockWidgetPluginGui" or className == "PluginGui" then
                isPluginGui = hasEnabled or hasTitle
                debugLog("ClassName: " .. tostring(className) .. ", IsValid: " .. tostring(isPluginGui))
            end
        end
    end
    
    local isValidWidget = (widgetType == "Instance") or isPluginGui
    
    if not isValidWidget then
        debugLog("Widget is not a valid GUI container, entering mock mode", "WARN")
        -- Create mock elements for testing
        self.mainFrame = {Name = "DataStoreManagerPro", Size = "Mock", Parent = "Mock"}
        self.titleBar = {Name = "TitleBar"}
        self.titleLabel = {Name = "TitleLabel", Text = "Mock UI"}
        self.contentArea = {Name = "ContentArea"}
        self.statusBar = {Name = "StatusBar"}
        self.statusLabel = {Name = "StatusLabel", Text = "🟢 Ready (Mock)"}
        debugLog("Mock UI elements created for testing")
        return
    end
    
    debugLog("Valid widget detected, proceeding with real UI creation")
    
    -- Main container
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "DataStoreManagerPro"
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.Position = UDim2.new(0, 0, 0, 0)
    self.mainFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = widget
    
    -- Title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.titleBar.BorderSizePixel = 1
    self.titleBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    self.titleBar.Parent = self.mainFrame
    
    -- Title text
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(1, -20, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 10, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = pluginInfo.name or "DataStore Manager Pro"
    self.titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    self.titleLabel.TextSize = 16
    self.titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Parent = self.titleBar
    
    -- Content area
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, 0, 1, -(Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT + Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT))
    self.contentArea.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.contentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.contentArea.BorderSizePixel = 0
    self.contentArea.Parent = self.mainFrame
    
    -- Status bar
    self.statusBar = Instance.new("Frame")
    self.statusBar.Name = "StatusBar"
    self.statusBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.Position = UDim2.new(0, 0, 1, -Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.statusBar.BorderSizePixel = 1
    self.statusBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    self.statusBar.Parent = self.mainFrame
    
    -- Status text
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Name = "StatusLabel"
    self.statusLabel.Size = UDim2.new(1, -20, 1, 0)
    self.statusLabel.Position = UDim2.new(0, 10, 0, 0)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = "🟢 Ready"
    self.statusLabel.Font = Constants.UI.THEME.FONTS.BODY
    self.statusLabel.TextSize = 12
    self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.Parent = self.statusBar
    
    debugLog("Main frame created successfully")
end

-- Setup modern professional layout with sidebar
function LayoutManager:setupLayout()
    debugLog("Setting up modern professional layout")
    
    if not self.contentArea then
        debugLog("Content area not available", "ERROR")
        return false
    end
    
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = self.contentArea
    
    self.mainContainer = mainContainer
    
    debugLog("Modern professional layout setup complete")
    return true
end

-- Create main content area
function LayoutManager:createMainContentArea(parent)
    local mainContentArea = Instance.new("Frame")
    mainContentArea.Name = "MainContentArea"
    mainContentArea.Size = UDim2.new(1, -Constants.UI.THEME.SIZES.SIDEBAR_WIDTH, 1, 0)
    mainContentArea.Position = UDim2.new(0, Constants.UI.THEME.SIZES.SIDEBAR_WIDTH, 0, 0)
    mainContentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    mainContentArea.BorderSizePixel = 0
    mainContentArea.Parent = parent
    
    self.mainContentArea = mainContentArea
    
    debugLog("Main content area created")
    return mainContentArea
end

-- Get layout components
function LayoutManager:getMainFrame()
    return self.mainFrame
end

function LayoutManager:getContentArea()
    return self.contentArea
end

function LayoutManager:getMainContentArea()
    return self.mainContentArea
end

function LayoutManager:getStatusLabel()
    return self.statusLabel
end

function LayoutManager:getTitleLabel()
    return self.titleLabel
end

function LayoutManager:getMainContainer()
    return self.mainContainer
end

-- Set visible
function LayoutManager:setVisible(visible)
    if self.mainFrame and self.mainFrame.Visible ~= nil then
        self.mainFrame.Visible = visible
    end
end

-- Destroy layout
function LayoutManager:destroy()
    if self.mainFrame then
        self.mainFrame:Destroy()
        self.mainFrame = nil
    end
    
    self.contentArea = nil
    self.mainContentArea = nil
    self.statusLabel = nil
    self.titleLabel = nil
    
    debugLog("Layout destroyed")
end

return LayoutManager 