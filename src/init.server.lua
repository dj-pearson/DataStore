-- DataStore Manager Pro - Main Entry Point
-- Modular initialization with granular error handling for easy debugging

local PLUGIN_INFO = {
    name = "DataStore Manager Pro",
    version = "1.0.0",
    id = "DataStoreManagerPro",
    author = "YourStudioName",
    description = "Professional DataStore management for Roblox Studio"
}

-- Debug logging system
local function debugLog(component, message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[%s] [%s] %s: %s", timestamp, level, component, message))
end

debugLog("MAIN", "Starting " .. PLUGIN_INFO.name .. " v" .. PLUGIN_INFO.version)

-- Wait for plugin context to be available
local function waitForPlugin()
    debugLog("MAIN", "Waiting for plugin context...")
    
    -- First, check if plugin is immediately available
    local pluginRef = rawget(_G, "plugin")
    if pluginRef then
        debugLog("MAIN", "Plugin context found immediately")
        return pluginRef
    end
    
    -- If not available, check if we're in a proper plugin environment
    local scriptRef = rawget(_G, "script")
    if not scriptRef or not scriptRef.Parent then
        debugLog("MAIN", "Not running in plugin context - creating mock for testing", "WARN")
        -- Return a minimal mock for testing purposes
        return {
            CreateToolbar = function() return {CreateButton = function() return {Click = {Connect = function() end}} end} end,
            CreateDockWidgetPluginGui = function() return {Title = "", ZIndexBehavior = nil, Enabled = false} end
        }
    end
    
    -- Wait for plugin context with timeout
    local startTime = os.time()
    local maxWaitTime = 10 -- 10 seconds max wait
    
    while not pluginRef and (os.time() - startTime) < maxWaitTime do
        -- Use small delay
        local delayStart = os.clock()
        while os.clock() - delayStart < 0.1 do end
        
        pluginRef = rawget(_G, "plugin")
        if pluginRef then
            debugLog("MAIN", "Plugin context found after " .. (os.time() - startTime) .. " seconds")
            break
        end
    end
    
    if not pluginRef then
        debugLog("MAIN", "Plugin context not available after " .. maxWaitTime .. " seconds", "ERROR")
        error("Plugin context not available - ensure this is running as a plugin in Roblox Studio")
    end
    
    -- Validate plugin methods (only if it's not our test mock)
    if pluginRef.CreateToolbar and type(pluginRef.CreateToolbar) == "function" then
        local requiredMethods = {"CreateToolbar", "CreateDockWidgetPluginGui"}
        for _, method in ipairs(requiredMethods) do
            if not pluginRef[method] or type(pluginRef[method]) ~= "function" then
                debugLog("MAIN", "Plugin missing method: " .. method, "WARN")
                -- Don't error, just warn - some test environments might not have all methods
            end
        end
        
        -- Use typeof if available, otherwise fall back to type
        local typeChecker = rawget(_G, "typeof") or type
        debugLog("MAIN", "Plugin context validated successfully (type: " .. typeChecker(pluginRef) .. ")")
    else
        debugLog("MAIN", "Using mock plugin context for testing", "INFO")
    end
    
    return pluginRef
end

-- Validate plugin context
local pluginObject = waitForPlugin()

-- Service loader with detailed error reporting
local Services = {}
local serviceLoadOrder = {
    "shared.Constants",
    "shared.Utils", 
    "shared.Types",
    "core.config.PluginConfig",
    "core.error.ErrorHandler",
    "core.logging.Logger",
    "core.licensing.LicenseManager",
    "core.data.DataStoreManager",
    "core.performance.PerformanceMonitor",
    "features.explorer.DataExplorer",
    "features.validation.SchemaValidator",
    "features.analytics.PerformanceAnalyzer",
    "features.operations.BulkOperations",
    "features.analytics.AnalyticsService",
    "features.search.SearchService", 
    "features.validation.SchemaService",
    "ui.core.UIManager"
}

-- Helper function to split path
local function splitPath(path, delimiter)
    delimiter = delimiter or "."
    local result = {}
    for match in path:gmatch("([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end
    return result
end

-- Initialize services in order
for _, servicePath in ipairs(serviceLoadOrder) do
    local loadSuccess, serviceModule = pcall(function()
        local pathParts = splitPath(servicePath, ".")
        local currentScript = rawget(_G, "script") or script
        
        for _, part in ipairs(pathParts) do
            currentScript = currentScript:FindFirstChild(part)
            if not currentScript then
                error("Module not found: " .. servicePath)
            end
        end
        
        return require(currentScript)
    end)
    
    if loadSuccess and serviceModule then
        -- Try to initialize if the service has an init function
        local initSuccess, serviceInstance = pcall(function()
            if serviceModule.initialize then
                return serviceModule.initialize()
            end
            return serviceModule
        end)
        
        if initSuccess then
            Services[servicePath] = serviceInstance
            debugLog("INIT", "✓ " .. servicePath .. " loaded successfully")
        else
            debugLog("INIT", "✗ " .. servicePath .. " initialization failed: " .. tostring(serviceInstance), "ERROR")
        end
    else
        debugLog("INIT", "✗ " .. servicePath .. " module load failed: " .. tostring(serviceModule), "ERROR")
    end
end

-- Set up service references after all services are loaded
if Services["features.explorer.DataExplorer"] and Services["core.data.DataStoreManager"] then
    Services["features.explorer.DataExplorer"]:setDataStoreManager(Services["core.data.DataStoreManager"])
    debugLog("INIT", "✓ DataExplorer connected to DataStoreManager")
end

-- Create plugin UI
local uiSuccess, uiError = pcall(function()
    debugLog("MAIN", "Creating plugin toolbar and button...")
    local toolbar = pluginObject:CreateToolbar("DataStore Manager Pro")
    debugLog("MAIN", "Toolbar created: " .. tostring(toolbar))
    
    local button = toolbar:CreateButton(
        "DataStore Manager",
        "Open DataStore Manager Pro",
        ""
    )
    debugLog("MAIN", "Button created: " .. tostring(button))

    -- Use globals with fallback for linter compatibility
    local DockWidgetInfo = rawget(_G, "DockWidgetPluginGuiInfo") or DockWidgetPluginGuiInfo
    local EnumRef = rawget(_G, "Enum") or Enum
    
    local widgetInfo = DockWidgetInfo.new(
        EnumRef.InitialDockState.Float,
        false,  -- Initially hidden
        false,  -- Don't override saved state
        1200,   -- Default width
        800,    -- Default height
        600,    -- Min width
        400     -- Min height
    )

    local widget = pluginObject:CreateDockWidgetPluginGui(PLUGIN_INFO.id, widgetInfo)
    widget.Title = PLUGIN_INFO.name
    widget.ZIndexBehavior = EnumRef.ZIndexBehavior.Sibling

    -- Try to get UI Manager from services first
    local uiManager = Services["ui.core.UIManager"]
    
    if not uiManager then
        debugLog("MAIN", "UI Manager not found in services", "ERROR")
        debugLog("MAIN", "Attempting direct UI Manager load...", "INFO")
        
        -- Fallback: Load UIManager directly
        local currentScript = rawget(_G, "script") or script
        local UIManagerModule = require(currentScript.ui.core.UIManager)
        debugLog("MAIN", "Direct UI Manager load successful, creating instance...", "INFO")
        
        local managerSuccess, result = pcall(function()
            local serviceCount = 0
            for _ in pairs(Services) do
                serviceCount = serviceCount + 1
            end
            debugLog("MAIN", "Creating UI Manager instance with " .. serviceCount .. " services", "INFO")
            return UIManagerModule.new(widget, Services, PLUGIN_INFO)
        end)
        
        if managerSuccess and result and result.refresh then
            uiManager = result
            debugLog("MAIN", "Fallback UI Manager instance created successfully", "INFO")
            
            button.Click:Connect(function()
                debugLog("MAIN", "Plugin button clicked! Toggling widget...")
                widget.Enabled = not widget.Enabled
                debugLog("MAIN", "Widget enabled: " .. tostring(widget.Enabled))
                if widget.Enabled and uiManager.refresh then
                    uiManager:refresh()
                end
            end)
            
            debugLog("MAIN", "Button click handler connected successfully")
            
            -- Store references for cleanup
            Services._ui = {
                toolbar = toolbar,
                button = button,
                widget = widget,
                interface = uiManager
            }
        else
            if managerSuccess then
                debugLog("MAIN", "UI Manager created but missing refresh method: " .. tostring(result), "ERROR")
            else
                debugLog("MAIN", "Failed to create fallback UI Manager: " .. tostring(result), "ERROR")
            end
            
            -- Create a minimal click handler without refresh
            button.Click:Connect(function()
                debugLog("MAIN", "Plugin button clicked! Toggling widget...")
                widget.Enabled = not widget.Enabled
                debugLog("MAIN", "Widget enabled: " .. tostring(widget.Enabled))
            end)
            
            debugLog("MAIN", "Basic click handler connected (no UI Manager)")
            return
        end
    else
        debugLog("MAIN", "UI Manager found in services")
        
        button.Click:Connect(function()
            debugLog("MAIN", "Plugin button clicked! Toggling widget...")
            widget.Enabled = not widget.Enabled
            debugLog("MAIN", "Widget enabled: " .. tostring(widget.Enabled))
            if widget.Enabled and uiManager.refresh then
                uiManager:refresh()
            end
        end)
        
        debugLog("MAIN", "Button click handler connected successfully")
        
        -- Store references for cleanup
        Services._ui = {
            toolbar = toolbar,
            button = button,
            widget = widget,
            interface = uiManager
        }
    end
end)

if not uiSuccess then
    debugLog("MAIN", "UI creation failed: " .. tostring(uiError), "ERROR")
end

-- Plugin cleanup handler (only if Unloading event exists)
if pluginObject.Unloading and pluginObject.Unloading.Connect then
    pluginObject.Unloading:Connect(function()
        debugLog("MAIN", "Plugin unloading - cleaning up services")
        
        for servicePath, service in pairs(Services) do
            -- Check if service has cleanup method and is actually a service instance
            if service and type(service) == "table" and service.cleanup and type(service.cleanup) == "function" then
                local cleanupSuccess, cleanupError = pcall(service.cleanup, service)
                if cleanupSuccess then
                    debugLog("CLEANUP", "✓ " .. servicePath .. " cleaned up")
                else
                    debugLog("CLEANUP", "✗ " .. servicePath .. " cleanup failed: " .. tostring(cleanupError), "ERROR")
                end
            elseif service and type(service) == "table" then
                debugLog("CLEANUP", "◦ " .. servicePath .. " (no cleanup method)")
            end
        end
        
        debugLog("MAIN", "Plugin cleanup completed")
    end)
else
    debugLog("MAIN", "No Unloading event available (mock mode) - cleanup will be manual", "INFO")
end

debugLog("MAIN", "🎉 " .. PLUGIN_INFO.name .. " initialization completed!") 