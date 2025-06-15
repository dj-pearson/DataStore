-- DataStore Manager Pro - View Registry
-- Manages registration and creation of modular view components

local ViewRegistry = {}
ViewRegistry.__index = ViewRegistry

-- Import view modules
local AnalyticsView = require(script.Parent.Parent.views.AnalyticsView)
local SettingsView = require(script.Parent.Parent.views.SettingsView)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[VIEW_REGISTRY] [%s] %s", level, message))
end

-- Create new View Registry instance
function ViewRegistry.new(viewManager)
    local self = setmetatable({}, ViewRegistry)
    
    self.viewManager = viewManager
    self.registeredViews = {}
    
    -- Register all available views
    self:registerViews()
    
    debugLog("ViewRegistry created with " .. #self.registeredViews .. " views")
    return self
end

-- Register all available view modules
function ViewRegistry:registerViews()
    -- Register Analytics View
    self:registerView("Analytics", AnalyticsView)
    
    -- Register Settings View
    self:registerView("Settings", SettingsView)
    
    debugLog("All view modules registered successfully")
end

-- Register a single view module
function ViewRegistry:registerView(viewName, viewModule)
    if not viewModule then
        debugLog("Failed to register view '" .. viewName .. "' - module is nil", "ERROR")
        return false
    end
    
    self.registeredViews[viewName] = {
        module = viewModule,
        instance = nil
    }
    
    debugLog("Registered view: " .. viewName)
    return true
end

-- Get or create view instance
function ViewRegistry:getView(viewName)
    local viewData = self.registeredViews[viewName]
    if not viewData then
        debugLog("View '" .. viewName .. "' not found in registry", "ERROR")
        return nil
    end
    
    -- Create instance if it doesn't exist
    if not viewData.instance then
        local success, result = pcall(function()
            return viewData.module.new(self.viewManager)
        end)
        
        if success then
            viewData.instance = result
            debugLog("Created new instance for view: " .. viewName)
        else
            debugLog("Failed to create instance for view '" .. viewName .. "': " .. tostring(result), "ERROR")
            return nil
        end
    end
    
    return viewData.instance
end

-- Show a registered view
function ViewRegistry:showView(viewName)
    local viewInstance = self:getView(viewName)
    if not viewInstance then
        debugLog("Cannot show view '" .. viewName .. "' - instance creation failed", "ERROR")
        return false
    end
    
    -- Call the view's show method
    local success, result = pcall(function()
        viewInstance:show()
    end)
    
    if success then
        debugLog("Successfully showed view: " .. viewName)
        return true
    else
        debugLog("Failed to show view '" .. viewName .. "': " .. tostring(result), "ERROR")
        return false
    end
end

-- Check if a view is registered
function ViewRegistry:isViewRegistered(viewName)
    return self.registeredViews[viewName] ~= nil
end

-- Get list of all registered view names
function ViewRegistry:getRegisteredViewNames()
    local names = {}
    for viewName, _ in pairs(self.registeredViews) do
        table.insert(names, viewName)
    end
    return names
end

-- Clear all view instances (useful for cleanup or refresh)
function ViewRegistry:clearViewInstances()
    for viewName, viewData in pairs(self.registeredViews) do
        viewData.instance = nil
    end
    debugLog("Cleared all view instances")
end

-- Clear specific view instance
function ViewRegistry:clearViewInstance(viewName)
    local viewData = self.registeredViews[viewName]
    if viewData then
        viewData.instance = nil
        debugLog("Cleared instance for view: " .. viewName)
        return true
    end
    return false
end

return ViewRegistry 