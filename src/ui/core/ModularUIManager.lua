-- DataStore Manager Pro - Modular UI Manager
-- Main UI coordinator that uses modular components for better maintainability

local ModularUIManager = {}
ModularUIManager.__index = ModularUIManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

-- Import modular components
local LayoutManager = require(script.Parent.LayoutManager)
local NavigationManager = require(script.Parent.NavigationManager)
local DataExplorerManager = require(script.Parent.DataExplorerManager)
local EditorManager = require(script.Parent.EditorManager)
local ViewManager = require(script.Parent.ViewManager)
local NotificationManager = require(script.Parent.NotificationManager)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[MODULAR_UI_MANAGER] [%s] %s", level, message))
end

-- Create new Modular UI Manager instance
function ModularUIManager.new(widget, services, pluginInfo)
    if not widget then
        debugLog("Widget is required for UI Manager", "ERROR")
        return nil
    end
    
    debugLog("Creating new Modular UI Manager instance")
    
    local self = setmetatable({}, ModularUIManager)
    
    self.widget = widget
    self.services = services or {}
    self.pluginInfo = pluginInfo or {}
    self.initialized = false
    self.isMockMode = false
    self.startTime = os.time()
    
    -- Initialize modular components
    self.layoutManager = LayoutManager.new(self)
    self.navigationManager = NavigationManager.new(self)
    self.dataExplorerManager = DataExplorerManager.new(self)
    self.editorManager = EditorManager.new(self)
    self.viewManager = ViewManager.new(self)
    self.notificationManager = NotificationManager.new(self)
    
    -- Explicitly set DataStore Manager service if available
    local dataStoreManager = self.services and (self.services.DataStoreManager or self.services["core.data.DataStoreManager"])
    if dataStoreManager then
        debugLog("Connecting DataStore Manager service to DataExplorerManager")
        self.dataExplorerManager:setDataStoreManagerService(dataStoreManager)
    else
        debugLog("⚠️ DataStore Manager service not found during component initialization", "WARN")
    end
    
    debugLog("Modular components initialized")
    
    -- Initialize the interface
    local initSuccess = self:initialize()
    
    if not initSuccess then
        debugLog("Modular UI Manager initialization failed", "ERROR")
        self.initialized = false
        self.isMockMode = true
        debugLog("Returning ModularUIManager in fallback mode")
    else
        debugLog("Modular UI Manager instance creation completed successfully")
    end
    
    return self
end

-- Initialize the UI
function ModularUIManager:initialize()
    debugLog("Initializing Modular UI Manager...")
    
    if self.initialized then
        debugLog("Modular UI Manager already initialized")
        return true
    end
    
    local serviceCount = 0
    if self.services then
        for _ in pairs(self.services) do
            serviceCount = serviceCount + 1
        end
    end
    debugLog("Services count: " .. serviceCount)
    
    -- Create main frame using LayoutManager
    debugLog("Creating main frame...")
    local success1, error1 = pcall(function()
        self.layoutManager:createMainFrame(self.widget, self.pluginInfo)
    end)
    
    if not success1 then
        debugLog("Failed to create main frame: " .. tostring(error1), "ERROR")
        return false
    end
    
    debugLog("Main frame created, setting up layout...")
    
    -- Setup basic layout (only if not in mock mode)
    if not self.isMockMode then
        local success2, error2 = pcall(function()
            self:setupLayout()
        end)
        
        if not success2 then
            debugLog("Failed to setup layout: " .. tostring(error2), "ERROR")
            return false
        end
    else
        debugLog("Skipping layout setup in mock mode")
    end
    
    -- Set up component references
    self:setupComponentReferences()
    
    self.initialized = true
    debugLog("Modular UI Manager initialized successfully")
    return true
end

-- Setup layout using LayoutManager
function ModularUIManager:setupLayout()
    debugLog("Setting up modular layout")
    
    -- Setup base layout
    local success = self.layoutManager:setupLayout()
    if not success then
        debugLog("Failed to setup base layout", "ERROR")
        return
    end
    
    local mainContainer = self.layoutManager:getMainContainer()
    if not mainContainer then
        debugLog("Main container not available", "ERROR")
        return
    end
    
    -- Create sidebar navigation using NavigationManager
    debugLog("Creating sidebar navigation...")
    local success1, error1 = pcall(function()
        self.navigationManager:createSidebarNavigation(mainContainer)
    end)
    if not success1 then
        debugLog("Failed to create sidebar: " .. tostring(error1), "ERROR")
        return
    end
    debugLog("Sidebar navigation created successfully")
    
    -- Create main content area using LayoutManager
    debugLog("Creating main content area...")
    local success2, error2 = pcall(function()
        self.layoutManager:createMainContentArea(mainContainer)
    end)
    if not success2 then
        debugLog("Failed to create main content area: " .. tostring(error2), "ERROR")
        return
    end
    debugLog("Main content area created successfully")
    
    -- Show default view
    local success, error = pcall(function()
        self:showDataExplorerView()
    end)
    
    if not success then
        debugLog("Failed to show Data Explorer view: " .. tostring(error), "ERROR")
        -- Fallback: create simple content
        self:createFallbackContent()
    end
    
    debugLog("Modular layout setup complete")
end

-- Setup component references
function ModularUIManager:setupComponentReferences()
    debugLog("Setting up component references")
    
    -- Set layout references for other components
    local mainContentArea = self.layoutManager:getMainContentArea()
    self.viewManager:setMainContentArea(mainContentArea)
    
    -- Set status label reference for notifications
    local statusLabel = self.layoutManager:getStatusLabel()
    self.notificationManager:setStatusLabel(statusLabel)
    
    debugLog("Component references configured")
end

-- Create fallback content
function ModularUIManager:createFallbackContent()
    local mainContentArea = self.layoutManager:getMainContentArea()
    if not mainContentArea then
        return
    end
    
    local fallbackLabel = Instance.new("TextLabel")
    fallbackLabel.Size = UDim2.new(1, 0, 1, 0)
    fallbackLabel.Position = UDim2.new(0, 0, 0, 0)
    fallbackLabel.BackgroundTransparency = 1
    fallbackLabel.Text = "⚠️ Modern UI Loading Error\n\nFallback interface active.\nCheck console for details."
    fallbackLabel.Font = Constants.UI.THEME.FONTS.BODY
    fallbackLabel.TextSize = 16
    fallbackLabel.TextColor3 = Constants.UI.THEME.COLORS.WARNING
    fallbackLabel.TextWrapped = true
    fallbackLabel.TextXAlignment = Enum.TextXAlignment.Center
    fallbackLabel.TextYAlignment = Enum.TextYAlignment.Center
    fallbackLabel.Parent = mainContentArea
end

-- View management methods (delegated to ViewManager)
function ModularUIManager:showDataExplorerView()
    debugLog("Showing Data Explorer view")
    self.viewManager:clearMainContent()
    
    local mainContentArea = self.layoutManager:getMainContentArea()
    if mainContentArea then
        self.dataExplorerManager:createModernDataExplorer(mainContentArea)
    end
end

function ModularUIManager:showAdvancedSearchView()
    self.viewManager:showAdvancedSearchView()
end

function ModularUIManager:showAnalyticsView()
    self.viewManager:showAnalyticsView()
end

function ModularUIManager:showRealTimeMonitorView()
    self.viewManager:showRealTimeMonitorView()
end

function ModularUIManager:showDataVisualizationView()
    self.viewManager:showDataVisualizationView()
end

function ModularUIManager:showTeamCollaborationView()
    self.viewManager:showTeamCollaborationView()
end

function ModularUIManager:showSchemaBuilderView()
    self.viewManager:showSchemaBuilderView()
end

-- Sessions functionality now integrated into Team Collaboration view
function ModularUIManager:showSessionsView()
    -- Redirect to the unified Team & Sessions view
    self.viewManager:showTeamCollaborationView()
end

function ModularUIManager:showSecurityView()
    self.viewManager:showSecurityView()
end

function ModularUIManager:showEnterpriseView()
    self.viewManager:showEnterpriseView()
end

function ModularUIManager:showIntegrationsView()
    self.viewManager:showIntegrationsView()
end

function ModularUIManager:showSettingsView()
    self.viewManager:showSettingsView()
end

-- Editor methods (delegated to EditorManager)
function ModularUIManager:editSelectedKey()
    self.editorManager:editSelectedKey()
end

function ModularUIManager:createNewKey()
    self.editorManager:createNewKey()
end

function ModularUIManager:deleteSelectedKey()
    self.editorManager:deleteSelectedKey()
end

function ModularUIManager:openDataEditor(mode, keyName, dataInfo)
    self.editorManager:openDataEditor(mode, keyName, dataInfo)
end

-- Notification methods (delegated to NotificationManager)
function ModularUIManager:showNotification(message, type)
    self.notificationManager:showNotification(message, type)
end

function ModularUIManager:setStatus(text, color)
    self.notificationManager:setStatus(text, color)
end

-- Component management
function ModularUIManager:addComponent(name, component)
    -- For backward compatibility
    debugLog("Component added: " .. name)
end

function ModularUIManager:removeComponent(name)
    -- For backward compatibility
    debugLog("Component removed: " .. name)
end

function ModularUIManager:getComponent(name)
    -- Return modular components by name
    if name == "navigation" then
        return self.navigationManager
    elseif name == "dataExplorer" then
        return self.dataExplorerManager
    elseif name == "editor" then
        return self.editorManager
    elseif name == "view" then
        return self.viewManager
    elseif name == "notification" then
        return self.notificationManager
    elseif name == "layout" then
        return self.layoutManager
    end
    return nil
end

-- Utility methods
function ModularUIManager:refresh()
    debugLog("Refreshing UI...")
    if self.dataExplorerManager then
        self.dataExplorerManager:loadDataStores()
    end
    self:showNotification("🔄 UI refreshed", "INFO")
end

function ModularUIManager:setVisible(visible)
    if self.layoutManager then
        self.layoutManager:setVisible(visible)
    end
end

function ModularUIManager:onClose()
    debugLog("UI closing...")
    self:setVisible(false)
end

function ModularUIManager:destroy()
    debugLog("Destroying Modular UI Manager...")
    
    -- Destroy all modular components
    if self.layoutManager then
        self.layoutManager:destroy()
    end
    
    if self.notificationManager then
        self.notificationManager:clearAllNotifications()
    end
    
    if self.editorManager then
        self.editorManager:closeDataEditor()
    end
    
    -- Clear references
    self.layoutManager = nil
    self.navigationManager = nil
    self.dataExplorerManager = nil
    self.editorManager = nil
    self.viewManager = nil
    self.notificationManager = nil
    
    self.initialized = false
    debugLog("Modular UI Manager destroyed")
end

-- Generate services text (for compatibility)
function ModularUIManager:generateServicesText()
    local servicesText = "Services Status:\n"
    if self.services then
        for serviceName, service in pairs(self.services) do
            servicesText = servicesText .. "• " .. serviceName .. ": " .. (service and "Available" or "Unavailable") .. "\n"
        end
    else
        servicesText = servicesText .. "No services configured"
    end
    return servicesText
end

-- Test services connection (for compatibility)
function ModularUIManager:testServicesConnection()
    debugLog("Testing services connection...")
    self:showNotification("🔗 Services connection test completed", "INFO")
end

-- Create sidebar navigation with Join Team option
function ModularUIManager:createSidebarNavigation()
    print("[MODULAR_UI_MANAGER] [INFO] Creating sidebar navigation...")
    
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 200, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = self.theme.colors.backgroundSecondary
    sidebar.BorderSizePixel = 0
    sidebar.Parent = self.mainFrame
    
    -- Add top section for branding/title
    local titleSection = Instance.new("Frame")
    titleSection.Name = "TitleSection"
    titleSection.Size = UDim2.new(1, 0, 0, 60)
    titleSection.Position = UDim2.new(0, 0, 0, 0)
    titleSection.BackgroundColor3 = self.theme.colors.primary
    titleSection.BorderSizePixel = 0
    titleSection.Parent = sidebar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "DataStore Manager Pro"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleSection
    
    -- Add collaboration section
    local collabSection = Instance.new("Frame")
    collabSection.Name = "CollaborationSection"
    collabSection.Size = UDim2.new(1, 0, 0, 80)
    collabSection.Position = UDim2.new(0, 0, 0, 60)
    collabSection.BackgroundColor3 = Color3.fromRGB(45, 85, 255)
    collabSection.BorderSizePixel = 0
    collabSection.Parent = sidebar
    
    -- Join Team button (prominent)
    local joinTeamBtn = Instance.new("TextButton")
    joinTeamBtn.Name = "JoinTeamButton"
    joinTeamBtn.Size = UDim2.new(1, -20, 0, 35)
    joinTeamBtn.Position = UDim2.new(0, 10, 0, 10)
    joinTeamBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    joinTeamBtn.Text = "🤝 Join Team"
    joinTeamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinTeamBtn.TextScaled = true
    joinTeamBtn.Font = Enum.Font.GothamBold
    joinTeamBtn.Parent = collabSection
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 6)
    joinCorner.Parent = joinTeamBtn
    
    -- Info text
    local joinInfo = Instance.new("TextLabel")
    joinInfo.Name = "JoinInfo"
    joinInfo.Size = UDim2.new(1, -20, 0, 25)
    joinInfo.Position = UDim2.new(0, 10, 0, 50)
    joinInfo.BackgroundTransparency = 1
    joinInfo.Text = "Have an invitation code? Join here!"
    joinInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    joinInfo.TextSize = 11
    joinInfo.Font = Enum.Font.Gotham
    joinInfo.TextXAlignment = Enum.TextXAlignment.Center
    joinInfo.Parent = collabSection
    
    -- Connect Join Team button
    joinTeamBtn.MouseButton1Click:Connect(function()
        self:showJoinTeamDialog()
    end)
    
    -- Navigation buttons container
    local navContainer = Instance.new("ScrollingFrame")
    navContainer.Name = "NavigationContainer"
    navContainer.Size = UDim2.new(1, 0, 1, -140) -- Leave space for title and collaboration sections
    navContainer.Position = UDim2.new(0, 0, 0, 140)
    navContainer.BackgroundTransparency = 1
    navContainer.BorderSizePixel = 0
    navContainer.ScrollBarThickness = 4
    navContainer.Parent = sidebar
    
    -- Navigation items
    local navItems = {
        {id = "dataExplorer", text = "📊 Data Explorer", icon = "📊"},
        {id = "teamCollaboration", text = "🤝 Team & Sessions", icon = "🤝"},
        {id = "schemaBuilder", text = "🏗️ Schema Builder", icon = "🏗️"},
        {id = "bulkOperations", text = "⚡ Bulk Operations", icon = "⚡"},
        {id = "analytics", text = "📈 Analytics", icon = "📈"},
        {id = "monitoring", text = "🔍 Monitoring", icon = "🔍"},
        {id = "backup", text = "💾 Backup", icon = "💾"},
        {id = "settings", text = "⚙️ Settings", icon = "⚙️"}
    }
    
    -- Create navigation buttons
    local yPosition = 0
    for i, item in ipairs(navItems) do
        local button = self:createNavButton(item, yPosition)
        button.Parent = navContainer
        yPosition = yPosition + 45
    end
    
    -- Set canvas size for scrolling
    navContainer.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    
    print("[MODULAR_UI_MANAGER] [INFO] Sidebar navigation created successfully")
    return sidebar
end

-- Show Join Team dialog
function ModularUIManager:showJoinTeamDialog()
    -- Lazy load the JoinTeamDialog component
    if not self.joinTeamDialog then
        local success, JoinTeamDialog = pcall(require, script.Parent.Parent.components.JoinTeamDialog)
        
        if success then
            -- Get user manager from services
            local userManager = nil
            for serviceName, service in pairs(self.services) do
                if serviceName:find("RealUserManager") then
                    userManager = service
                    break
                end
            end
            
            if userManager then
                self.joinTeamDialog = JoinTeamDialog.new(self.plugin, self.themeManager, userManager)
                
                -- Set success callback to refresh UI
                self.joinTeamDialog:setJoinSuccessCallback(function(newUser)
                    print("[MODULAR_UI_MANAGER] [INFO] New team member joined: " .. newUser.userName)
                    self:refreshTeamView()
                end)
            else
                print("[MODULAR_UI_MANAGER] [ERROR] RealUserManager not found in services")
                return
            end
        else
            print("[MODULAR_UI_MANAGER] [ERROR] Failed to load JoinTeamDialog: " .. tostring(JoinTeamDialog))
            return
        end
    end
    
    self.joinTeamDialog:show()
end

-- Refresh team collaboration view
function ModularUIManager:refreshTeamView()
    if self.currentView == "teamCollaboration" then
        self:showView("teamCollaboration")
    end
end

return ModularUIManager 