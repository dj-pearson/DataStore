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

function ModularUIManager:showSessionsView()
    self.viewManager:showSessionsView()
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

return ModularUIManager 