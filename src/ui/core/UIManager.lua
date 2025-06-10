-- DataStore Manager Pro - UI Manager
-- Manages the main user interface and coordinates UI components

local UIManager = {}
UIManager.__index = UIManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[UI_MANAGER] [%s] %s", level, message))
end

-- Create new UI Manager instance
function UIManager.new(widget, services, pluginInfo)
    local self = setmetatable({}, UIManager)
    
    self.widget = widget
    self.services = services or {}
    self.pluginInfo = pluginInfo or {}
    self.components = {}
    self.initialized = false
    
    debugLog("Creating new UI Manager instance")
    
    -- Initialize the interface
    self:initialize()
    
    return self
end

-- Initialize the UI
function UIManager:initialize()
    if self.initialized then
        debugLog("UI Manager already initialized")
        return true
    end
    
    debugLog("Initializing UI Manager")
    
    -- Create main frame
    self:createMainFrame()
    
    -- Setup basic layout
    self:setupLayout()
    
    self.initialized = true
    debugLog("UI Manager initialized successfully")
    return true
end

-- Create the main frame
function UIManager:createMainFrame()
    debugLog("Creating main frame")
    
    -- Main container
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "DataStoreManagerPro"
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.Position = UDim2.new(0, 0, 0, 0)
    self.mainFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.widget
    
    -- Title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    self.titleBar.BorderSizePixel = 1
    self.titleBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
    self.titleBar.Parent = self.mainFrame
    
    -- Title text
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(1, -20, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 10, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = self.pluginInfo.name or "DataStore Manager Pro"
    self.titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    self.titleLabel.TextSize = 16
    self.titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Parent = self.titleBar
    
    -- Content area
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, 0, 1, -(Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT + Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT))
    self.contentArea.Position = UDim2.new(0, 0, 0, Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT)
    self.contentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND
    self.contentArea.BorderSizePixel = 0
    self.contentArea.Parent = self.mainFrame
    
    -- Status bar
    self.statusBar = Instance.new("Frame")
    self.statusBar.Name = "StatusBar"
    self.statusBar.Size = UDim2.new(1, 0, 0, Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.Position = UDim2.new(0, 0, 1, -Constants.UI.THEME.SIZES.STATUSBAR_HEIGHT)
    self.statusBar.BackgroundColor3 = Constants.UI.THEME.COLORS.SURFACE
    self.statusBar.BorderSizePixel = 1
    self.statusBar.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
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
    self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.Parent = self.statusBar
    
    debugLog("Main frame created successfully")
end

-- Setup the basic layout
function UIManager:setupLayout()
    debugLog("Setting up basic layout")
    
    -- Create placeholder content
    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Name = "WelcomeLabel"
    welcomeLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
    welcomeLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.Text = "Welcome to DataStore Manager Pro\n\nThis is the foundation interface.\nMore features will be added in subsequent phases."
    welcomeLabel.Font = Constants.UI.THEME.FONTS.BODY
    welcomeLabel.TextSize = 18
    welcomeLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    welcomeLabel.TextWrapped = true
    welcomeLabel.TextXAlignment = Enum.TextXAlignment.Center
    welcomeLabel.TextYAlignment = Enum.TextYAlignment.Center
    welcomeLabel.Parent = self.contentArea
    
    -- Add version info
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionLabel"
    versionLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    versionLabel.Position = UDim2.new(0.1, 0, 0.7, 0)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "Version: " .. (self.pluginInfo.version or "1.0.0")
    versionLabel.Font = Constants.UI.THEME.FONTS.BODY
    versionLabel.TextSize = 14
    versionLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    versionLabel.TextXAlignment = Enum.TextXAlignment.Center
    versionLabel.TextYAlignment = Enum.TextYAlignment.Center
    versionLabel.Parent = self.contentArea
    
    debugLog("Basic layout setup complete")
end

-- Update status bar
function UIManager:setStatus(text, color)
    if self.statusLabel then
        self.statusLabel.Text = text
        self.statusLabel.TextColor3 = color or Constants.UI.THEME.COLORS.TEXT
    end
end

-- Refresh the interface
function UIManager:refresh()
    debugLog("Refreshing UI")
    
    -- Update status based on service states
    if self.services then
        local activeServices = 0
        local totalServices = 0
        
        for serviceName, service in pairs(self.services) do
            if serviceName ~= "_ui" then
                totalServices = totalServices + 1
                if service then
                    activeServices = activeServices + 1
                end
            end
        end
        
        self:setStatus(string.format("🟢 Ready - %d/%d services active", activeServices, totalServices))
    else
        self:setStatus("🟡 Limited functionality - No services available", Constants.UI.THEME.COLORS.WARNING)
    end
    
    debugLog("UI refresh complete")
end

-- Add a component
function UIManager:addComponent(name, component)
    if not name or not component then
        debugLog("Invalid component provided: " .. tostring(name), "ERROR")
        return false
    end
    
    self.components[name] = component
    debugLog("Component added: " .. name)
    return true
end

-- Remove a component
function UIManager:removeComponent(name)
    if not name or not self.components[name] then
        debugLog("Component not found: " .. tostring(name), "WARN")
        return false
    end
    
    local component = self.components[name]
    if component.destroy then
        component:destroy()
    end
    
    self.components[name] = nil
    debugLog("Component removed: " .. name)
    return true
end

-- Get a component
function UIManager:getComponent(name)
    return self.components[name]
end

-- Show/hide the interface
function UIManager:setVisible(visible)
    if self.mainFrame then
        self.mainFrame.Visible = visible
        debugLog("UI visibility set to: " .. tostring(visible))
    end
end

-- Handle widget closing
function UIManager:onClose()
    debugLog("UI closing")
    -- Cleanup or save state if needed
end

-- Cleanup
function UIManager:destroy()
    debugLog("Destroying UI Manager")
    
    -- Destroy all components
    for name, component in pairs(self.components) do
        if component.destroy then
            component:destroy()
        end
    end
    
    -- Clear references
    self.components = {}
    
    if self.mainFrame then
        self.mainFrame:Destroy()
        self.mainFrame = nil
    end
    
    self.initialized = false
    debugLog("UI Manager destroyed")
end

return UIManager 