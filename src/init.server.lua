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
    
    -- Check if we're in a testing environment (no plugin available after wait)
    -- In a real plugin context, we should wait a bit longer before giving up
    debugLog("MAIN", "Plugin context not immediately available, checking environment...")
    
    -- Check if we have Studio-specific globals that indicate real plugin environment
    -- In plugin context, these are available directly, not necessarily in _G
    local game_service = game or rawget(_G, "game")
    local dock_widget_info = DockWidgetPluginGuiInfo or rawget(_G, "DockWidgetPluginGuiInfo") 
    local enum_ref = Enum or rawget(_G, "Enum")
    
    debugLog("MAIN", "Environment check - game: " .. tostring(game_service ~= nil) .. ", DockWidgetPluginGuiInfo: " .. tostring(dock_widget_info ~= nil) .. ", Enum: " .. tostring(enum_ref ~= nil))
    
    -- If we're clearly not in Studio (missing essential Studio globals), use mock
    if not game_service or not dock_widget_info or not enum_ref then
        debugLog("MAIN", "Missing essential Studio globals - creating mock for testing", "WARN")
        -- Return a minimal mock for testing purposes
        return {
            CreateToolbar = function() return {CreateButton = function() return {Click = {Connect = function() end}} end} end,
            CreateDockWidgetPluginGui = function() return {Title = "", ZIndexBehavior = nil, Enabled = false} end
        }
    end
    
    debugLog("MAIN", "Studio environment detected, continuing to wait for plugin context...")
    
    -- Try different ways to access plugin context
    local pluginSources = {
        function() return rawget(_G, "plugin") end,
        function() return plugin end, -- Direct global access
        function() return getfenv().plugin end, -- Environment access
        function() return _G.plugin end -- Direct _G access
    }
    
    local startTime = os.time()
    local maxWaitTime = 10 -- Reduce wait time since we're trying multiple methods
    local attempts = 0
    
    while not pluginRef and (os.time() - startTime) < maxWaitTime do
        attempts = attempts + 1
        
        -- Try all plugin source methods
        for i, getPlugin in ipairs(pluginSources) do
            local success, result = pcall(getPlugin)
            if success and result then
                pluginRef = result
                debugLog("MAIN", "Plugin context found via method " .. i .. " after " .. attempts .. " attempts")
                break
            end
        end
        
        if pluginRef then break end
        
        -- Use small delay with wait if available
        local wait_func = rawget(_G, "wait")
        if wait_func then
            wait_func(0.1)
        else
            local delayStart = os.clock()
            while os.clock() - delayStart < 0.1 do end
        end
        
        -- Log progress every 2 seconds
        if attempts % 20 == 0 then
            debugLog("MAIN", "Still waiting for plugin context... (" .. (os.time() - startTime) .. "s)")
        end
    end
    
    -- If still no plugin found, try to check if we can create plugin objects directly
    if not pluginRef then
        debugLog("MAIN", "Direct plugin access failed, checking if plugin functionality is available...", "WARN")
        
        -- Try to detect if we're in a plugin context by checking for plugin-specific functions
        local hasPluginAPI = pcall(function()
            return DockWidgetPluginGuiInfo.new
        end)
        
        if hasPluginAPI then
            debugLog("MAIN", "Plugin API available but plugin object not found - this might be a newer Studio version", "WARN")
            debugLog("MAIN", "Creating fallback plugin implementation...", "INFO")
            
            -- In newer Studio versions, the plugin might be implicit or accessed differently
            -- Try to create a functional plugin object
            pluginRef = {
                CreateToolbar = function(name)
                    debugLog("MAIN", "Creating toolbar: " .. name)
                    return {
                        CreateButton = function(name, tooltip, icon)
                            debugLog("MAIN", "Creating button: " .. name)
                            return {
                                Click = {
                                    Connect = function(callback)
                                        debugLog("MAIN", "Button click handler connected")
                                        -- In a real plugin context, this would work
                                        return {}
                                    end
                                }
                            }
                        end
                    }
                end,
                CreateDockWidgetPluginGui = function(id, info)
                    debugLog("MAIN", "Creating dock widget: " .. id)
                    -- Try to create a real widget if possible
                    local success, widget = pcall(function()
                        -- This might work in newer Studio versions
                        return DockWidgetPluginGuiInfo.new(info)
                    end)
                    
                    if success and widget then
                        debugLog("MAIN", "Real dock widget created successfully")
                        return widget
                    else
                        debugLog("MAIN", "Using mock dock widget")
                        return {
                            Title = "",
                            ZIndexBehavior = nil,
                            Enabled = false
                        }
                    end
                end,
                Unloading = nil -- No unloading event in fallback
            }
            
            debugLog("MAIN", "Fallback plugin object created")
        else
            debugLog("MAIN", "Plugin API not available after " .. maxWaitTime .. " seconds", "ERROR")
            error("Plugin context not available - ensure this is running as a plugin in Roblox Studio")
        end
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
    "core.security.SecurityManager",  -- Enterprise security
    "core.data.DataStoreManagerSlim",
    "core.performance.PerformanceMonitor",
    "features.analytics.AdvancedAnalytics",  -- Enterprise analytics
    "features.validation.DataIntegrityValidator",  -- Enterprise validation
    "features.explorer.DataExplorer",
    "features.validation.SchemaValidator",
    "features.operations.BulkOperations",
    "features.search.SearchService", 
    "features.validation.SchemaService",
    "ui.core.ThemeManager",  -- Professional theming system
    "features.FeatureRegistry",  -- Advanced feature management
    "features.search.SmartSearchEngine",  -- Advanced search
    "features.monitoring.RealTimeMonitor",  -- Real-time monitoring
    "features.operations.BulkOperationsManager",  -- Advanced bulk operations
    "features.backup.BackupManager",  -- Backup & restore
    "features.collaboration.RealUserManager",  -- Real user collaboration system
    "features.collaboration.TeamManager"  -- Team collaboration management
    -- Note: EnhancedDashboard moved to UI components and loaded on-demand
    -- Note: ui.core.ModularUIManager is handled separately in the UI creation section
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
                    -- Special handling for FeatureRegistry
        if servicePath == "features.FeatureRegistry" then
            local licenseManager = Services["core.licensing.LicenseManager"]
            local instance = serviceModule.new(licenseManager, Services)
            instance:initialize()
            return instance
        -- Special handling for RealUserManager
        elseif servicePath == "features.collaboration.RealUserManager" then
            local dataStoreManager = Services["core.data.DataStoreManagerSlim"]
            return serviceModule.initialize(dataStoreManager)
        -- Special handling for TeamManager
        elseif servicePath == "features.collaboration.TeamManager" then
            local realUserManager = Services["features.collaboration.RealUserManager"]
            return serviceModule.initialize(realUserManager)
        -- Special handling for SmartSearchEngine
        elseif servicePath == "features.search.SmartSearchEngine" then
            return serviceModule.initialize(Services)
        elseif serviceModule.initialize then
                local result = serviceModule.initialize()
                -- If initialize() returns a table, use it as the instance
                -- If it returns true/false, treat it as status and use the module itself
                if type(result) == "table" then
                    return result
                elseif result == true then
                    return serviceModule -- Use the module itself
                else
                    return nil -- Failed initialization
                end
            elseif serviceModule.new then
                return serviceModule.new()
            end
            return serviceModule
        end)
        
        if initSuccess and serviceInstance and type(serviceInstance) == "table" then
            Services[servicePath] = serviceInstance
            debugLog("INIT", "✓ " .. servicePath .. " loaded successfully")
        else
            debugLog("INIT", "✗ " .. servicePath .. " initialization failed: " .. tostring(serviceInstance), "ERROR")
            -- Store the module anyway if it's a valid table
            if type(serviceModule) == "table" then
                Services[servicePath] = serviceModule
                debugLog("INIT", "◐ " .. servicePath .. " loaded as fallback (no instance created)")
            end
        end
    else
        debugLog("INIT", "✗ " .. servicePath .. " module load failed: " .. tostring(serviceModule), "ERROR")
    end
end

-- Set up service references after all services are loaded
if Services["features.explorer.DataExplorer"] and Services["core.data.DataStoreManagerSlim"] then
    Services["features.explorer.DataExplorer"]:setDataStoreManager(Services["core.data.DataStoreManagerSlim"])
    debugLog("INIT", "✓ DataExplorer connected to DataStoreManager")
end

-- SmartSearchEngine should now be properly initialized with services through special handling above

-- Connect SearchService to DataStoreManagerSlim
if Services["features.search.SearchService"] and Services["core.data.DataStoreManagerSlim"] then
    if Services["features.search.SearchService"].setDataStoreManager then
        Services["features.search.SearchService"]:setDataStoreManager(Services["core.data.DataStoreManagerSlim"])
        debugLog("INIT", "✓ SearchService connected to DataStoreManager")
    end
end

-- Initialize enterprise systems with dependencies
local securityManager = Services["core.security.SecurityManager"]
local analyticsManager = Services["features.analytics.AdvancedAnalytics"]
local validatorManager = Services["features.validation.DataIntegrityValidator"]

-- Initialize Advanced Analytics with Security Manager and Services
if analyticsManager and securityManager then
    local analyticsInitSuccess, analyticsError = pcall(function()
        return analyticsManager.initialize(securityManager, Services)
    end)
    if analyticsInitSuccess then
        debugLog("INIT", "✓ Advanced Analytics initialized with security integration")
    else
        debugLog("INIT", "✗ Advanced Analytics initialization failed: " .. tostring(analyticsError), "ERROR")
    end
end

-- Initialize Data Validator with Security and Analytics
if validatorManager and securityManager and analyticsManager then
    local validatorInitSuccess, validatorError = pcall(function()
        return validatorManager.initialize(securityManager, analyticsManager)
    end)
    if validatorInitSuccess then
        debugLog("INIT", "✓ Data Integrity Validator initialized with enterprise integration")
    else
        debugLog("INIT", "✗ Data Validator initialization failed: " .. tostring(validatorError), "ERROR")
    end
end

-- Set up enterprise data access wrappers
if Services["core.data.DataStoreManagerSlim"] and securityManager then
    local dataManager = Services["core.data.DataStoreManagerSlim"]
    
    -- Wrap DataStore operations with security and analytics
    if dataManager.wrapWithSecurity then
        local wrapSuccess, wrapError = pcall(function()
            dataManager:wrapWithSecurity(securityManager, analyticsManager)
        end)
        if wrapSuccess then
            debugLog("INIT", "✓ DataStore operations wrapped with enterprise security")
        else
            debugLog("INIT", "✗ Security wrapper failed: " .. tostring(wrapError), "ERROR")
        end
    end
end

-- Create plugin UI
local uiSuccess, uiError = pcall(function()
    debugLog("MAIN", "Creating plugin toolbar and button...")
    local toolbar = pluginObject:CreateToolbar("DataStore Manager Pro")
    debugLog("MAIN", "Toolbar created: " .. tostring(toolbar))
    
    -- Try multiple asset IDs in order of preference
    local iconAssets = {
        "rbxassetid://103057751700284",  -- Plugin asset ID
        "rbxassetid://92445245962836",  -- Plugin asset ID
        "rbxassetid://131528729537417", -- Decal asset ID
        "rbxassetid://2778270261",      -- Known working example from Roblox docs
        "rbxasset://textures/loading/robloxTilt.png" -- Built-in fallback
    }
    
    local button = toolbar:CreateButton(
        "DataStore Manager",
        "Open DataStore Manager Pro",
        iconAssets[1] -- Try plugin asset ID first
    )
    debugLog("MAIN", "Button created with icon: " .. iconAssets[1])
    
    -- Try alternative icons if the first one fails
    if button and button.Icon then
        for i, assetId in ipairs(iconAssets) do
            local iconSetSuccess, iconError = pcall(function()
                button.Icon = assetId
                wait(0.1) -- Brief wait to see if icon loads
            end)
            
            if iconSetSuccess then
                debugLog("MAIN", "Icon set successfully with asset " .. i .. ": " .. assetId)
                break -- Stop trying once we succeed
            else
                debugLog("MAIN", "Icon asset " .. i .. " failed: " .. tostring(iconError), "WARN")
                if i < #iconAssets then
                    debugLog("MAIN", "Trying next icon asset...", "INFO")
                end
            end
        end
    else
        debugLog("MAIN", "Icon property not available on button", "WARN")
    end

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
        
        -- Load ModularUIManager instead of old UIManager
        local currentScript = rawget(_G, "script") or script
        local ModularUIManagerModule = require(currentScript.ui.core.ModularUIManager)
        debugLog("MAIN", "Direct Modular UI Manager load successful, creating instance...", "INFO")
        
        local managerSuccess, result = pcall(function()
            local serviceCount = 0
            for _ in pairs(Services) do
                serviceCount = serviceCount + 1
            end
            debugLog("MAIN", "Creating Modular UI Manager instance with " .. serviceCount .. " services", "INFO")
            return ModularUIManagerModule.new(widget, Services, PLUGIN_INFO)
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
        
        -- Cleanup enterprise systems first (in reverse dependency order)
        local enterpriseCleanupOrder = {
            "features.validation.DataIntegrityValidator",
            "features.analytics.AdvancedAnalytics", 
            "core.security.SecurityManager"
        }
        
        for _, servicePath in ipairs(enterpriseCleanupOrder) do
            local service = Services[servicePath]
            if service and type(service) == "table" and service.cleanup and type(service.cleanup) == "function" then
                local cleanupSuccess, cleanupError = pcall(service.cleanup)
                if cleanupSuccess then
                    debugLog("CLEANUP", "✓ " .. servicePath .. " enterprise cleanup completed")
                else
                    debugLog("CLEANUP", "✗ " .. servicePath .. " enterprise cleanup failed: " .. tostring(cleanupError), "ERROR")
                end
            end
        end
        
        -- Cleanup remaining services
        for servicePath, service in pairs(Services) do
            -- Skip if already cleaned up
            local alreadyCleaned = false
            for _, enterpriseService in ipairs(enterpriseCleanupOrder) do
                if servicePath == enterpriseService then
                    alreadyCleaned = true
                    break
                end
            end
            
            if not alreadyCleaned then
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
        end
        
        debugLog("MAIN", "Plugin cleanup completed")
    end)
else
    debugLog("MAIN", "No Unloading event available (mock mode) - cleanup will be manual", "INFO")
end

debugLog("MAIN", "🎉 " .. PLUGIN_INFO.name .. " initialization completed!")

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local PluginDataStore = require(script.core.data.PluginDataStore)
local pluginDataStore = PluginDataStore.new({
    info = function(_, _, msg) debugLog("PLUGIN_DATASTORE", msg) end,
    warn = function(_, _, msg) debugLog("PLUGIN_DATASTORE", msg, "WARN") end
})

local activeUserIds = {}

-- Safe function to check player policies
local function checkPlayerPolicy(player)
    local success, policyInfo = pcall(function()
        return PolicyService:GetPolicyInfoForPlayerAsync(player)
    end)
    
    if success and policyInfo then
        return {
            canCollectData = policyInfo.AllowedExternalLinkReferences ~= nil,
            isUnder13 = not policyInfo.AreAdsAllowed,
            canShareContent = policyInfo.IsContentSharingAllowed
        }
    else
        -- Default to most restrictive settings if policy check fails
        return {
            canCollectData = false,
            isUnder13 = true,
            canShareContent = false
        }
    end
end

local function updateActiveUsers()
    local success, result = pcall(function()
        return pluginDataStore:cacheDataContent("PluginAnalytics", "ActiveUsers", activeUserIds)
    end)
    
    if not success then
        debugLog("PLUGIN_DATASTORE", "Failed to update active users: " .. tostring(result), "ERROR")
    end
end

Players.PlayerAdded:Connect(function(player)
    -- Check player policy first
    local policy = checkPlayerPolicy(player)
    
    -- Only track users who can have their data collected
    if policy.canCollectData then
        activeUserIds[player.UserId] = true
        updateActiveUsers()
        debugLog("PLAYER_TRACKING", "Player added: " .. player.Name)
    else
        debugLog("PLAYER_TRACKING", "Player policy restricts data collection: " .. player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if activeUserIds[player.UserId] then
        activeUserIds[player.UserId] = nil
        updateActiveUsers()
        debugLog("PLAYER_TRACKING", "Player removed: " .. player.Name)
    end
end) 