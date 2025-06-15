-- DataStore Manager Pro - Slim View Manager
-- Simplified view manager that delegates to modular view components

local ViewManagerSlim = {}
ViewManagerSlim.__index = ViewManagerSlim

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local ViewRegistry = require(script.Parent.ViewRegistry)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[VIEW_MANAGER_SLIM] [%s] %s", level, message))
end

-- Create new View Manager instance
function ViewManagerSlim.new(uiManager)
    local self = setmetatable({}, ViewManagerSlim)
    
    self.uiManager = uiManager
    self.currentView = nil
    self.mainContentArea = nil
    self.services = uiManager and uiManager.services or {}
    
    -- Initialize view registry
    self.viewRegistry = ViewRegistry.new(self)
    
    debugLog("ViewManagerSlim created with modular view system")
    return self
end

-- Set main content area reference
function ViewManagerSlim:setMainContentArea(contentArea)
    self.mainContentArea = contentArea
end

-- Clear main content
function ViewManagerSlim:clearMainContent()
    if self.mainContentArea then
        for _, child in ipairs(self.mainContentArea:GetChildren()) do
            child:Destroy()
        end
    end
end

-- Create view header (shared utility for all views)
function ViewManagerSlim:createViewHeader(title, subtitle)
    if not self.mainContentArea then
        debugLog("Main content area not set", "ERROR")
        return nil
    end
    
    local header = Instance.new("Frame")
    header.Name = "ViewHeader"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    header.BorderSizePixel = 1
    header.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    header.Parent = self.mainContentArea
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 0, 35)
    titleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, Constants.UI.THEME.SPACING.MEDIUM)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Constants.UI.THEME.FONTS.HEADING
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    
    -- Subtitle (if provided)
    if subtitle then
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Name = "Subtitle"
        subtitleLabel.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE, 0, 25)
        subtitleLabel.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, 45)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Text = subtitle
        subtitleLabel.Font = Constants.UI.THEME.FONTS.BODY
        subtitleLabel.TextSize = 14
        subtitleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
        subtitleLabel.Parent = header
    end
    
    return header
end

-- Create placeholder view for unimplemented features
function ViewManagerSlim:createPlaceholderView(title, description)
    self:clearMainContent()
    
    -- Header
    self:createViewHeader(title, description)
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "PlaceholderContent"
    contentFrame.Size = UDim2.new(1, 0, 1, -80)
    contentFrame.Position = UDim2.new(0, 0, 0, 80)
    contentFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = self.mainContentArea
    
    -- Placeholder content
    local placeholderContainer = Instance.new("Frame")
    placeholderContainer.Size = UDim2.new(0, 400, 0, 300)
    placeholderContainer.Position = UDim2.new(0.5, -200, 0.5, -150)
    placeholderContainer.BackgroundTransparency = 1
    placeholderContainer.Parent = contentFrame
    
    local placeholderIcon = Instance.new("TextLabel")
    placeholderIcon.Size = UDim2.new(1, 0, 0, 80)
    placeholderIcon.Position = UDim2.new(0, 0, 0, 0)
    placeholderIcon.BackgroundTransparency = 1
    placeholderIcon.Text = "🚧"
    placeholderIcon.Font = Constants.UI.THEME.FONTS.UI
    placeholderIcon.TextSize = 60
    placeholderIcon.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    placeholderIcon.TextXAlignment = Enum.TextXAlignment.Center
    placeholderIcon.Parent = placeholderContainer
    
    local placeholderTitle = Instance.new("TextLabel")
    placeholderTitle.Size = UDim2.new(1, 0, 0, 40)
    placeholderTitle.Position = UDim2.new(0, 0, 0, 90)
    placeholderTitle.BackgroundTransparency = 1
    placeholderTitle.Text = title .. " - Coming Soon"
    placeholderTitle.Font = Constants.UI.THEME.FONTS.HEADING
    placeholderTitle.TextSize = 18
    placeholderTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    placeholderTitle.TextXAlignment = Enum.TextXAlignment.Center
    placeholderTitle.Parent = placeholderContainer
    
    local placeholderDesc = Instance.new("TextLabel")
    placeholderDesc.Size = UDim2.new(1, 0, 0, 100)
    placeholderDesc.Position = UDim2.new(0, 0, 0, 140)
    placeholderDesc.BackgroundTransparency = 1
    placeholderDesc.Text = description .. "\n\nThis feature is currently under development and will be available in a future update."
    placeholderDesc.Font = Constants.UI.THEME.FONTS.BODY
    placeholderDesc.TextSize = 14
    placeholderDesc.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    placeholderDesc.TextXAlignment = Enum.TextXAlignment.Center
    placeholderDesc.TextYAlignment = Enum.TextYAlignment.Top
    placeholderDesc.TextWrapped = true
    placeholderDesc.Parent = placeholderContainer
    
    self.currentView = title
    debugLog("Placeholder view created: " .. title)
end

-- Show Analytics view (delegated to modular system)
function ViewManagerSlim:showAnalyticsView()
    debugLog("Showing Analytics view via modular system")
    if self.viewRegistry:showView("Analytics") then
        self.currentView = "Analytics"
    else
        self:createPlaceholderView("Analytics", "Advanced analytics dashboard with real-time metrics")
    end
end

-- Show Settings view (delegated to modular system)
function ViewManagerSlim:showSettingsView()
    debugLog("Showing Settings view via modular system")
    if self.viewRegistry:showView("Settings") then
        self.currentView = "Settings"
    else
        self:createPlaceholderView("Settings", "Configure application preferences and advanced features")
    end
end

-- Show Real-Time Monitor view
function ViewManagerSlim:showRealTimeMonitorView()
    debugLog("Showing Real-Time Monitor view")
    self:createPlaceholderView("Real-Time Monitor", "Live monitoring of DataStore operations and performance metrics")
end

-- Show Schema Builder view
function ViewManagerSlim:showSchemaBuilderView()
    debugLog("Showing Schema Builder view")
    self:createPlaceholderView("Schema Builder", "Visual schema creation and validation tools")
end

-- Show Bulk Operations view
function ViewManagerSlim:showBulkOperationsView()
    debugLog("Showing Bulk Operations view")
    self:createPlaceholderView("Bulk Operations", "Mass operations for DataStore management")
end

-- Show Data Health view
function ViewManagerSlim:showDataHealthView()
    debugLog("Showing Data Health view")
    self:createPlaceholderView("Data Health", "Automated data integrity and health monitoring")
end

-- Show Team Collaboration view
function ViewManagerSlim:showTeamCollaborationView()
    debugLog("Showing Team Collaboration view")
    self:createPlaceholderView("Team Collaboration", "Collaborative DataStore management and team features")
end

-- Show Enterprise view
function ViewManagerSlim:showEnterpriseView()
    debugLog("Showing Enterprise view")
    self:createPlaceholderView("Enterprise", "Enterprise-grade features and compliance tools")
end

-- Show Integrations view
function ViewManagerSlim:showIntegrationsView()
    debugLog("Showing Integrations view")
    self:createPlaceholderView("Integrations", "Third-party integrations and API connections")
end

-- Show Security view
function ViewManagerSlim:showSecurityView()
    debugLog("Showing Security view")
    self:createPlaceholderView("Security", "Advanced security features and access control")
end

-- Show Data Visualization view
function ViewManagerSlim:showDataVisualizationView()
    debugLog("Showing Data Visualization view")
    self:createPlaceholderView("Data Visualization", "Advanced data visualization and charting tools")
end

-- Show Advanced Search view
function ViewManagerSlim:showAdvancedSearchView()
    debugLog("Showing Advanced Search view")
    self:createPlaceholderView("Advanced Search", "Powerful search and filtering capabilities")
end

-- Apply UI scale changes (preserved from original)
function ViewManagerSlim:applyUIScale(scale)
    local scaleFactor = scale / 100
    debugLog("Applying UI scale: " .. scale .. "% (factor: " .. scaleFactor .. ")")
    
    -- Store original constants if not already stored
    if not _G.ORIGINAL_UI_CONSTANTS then
        _G.ORIGINAL_UI_CONSTANTS = {
            SIZES = {
                BUTTON_HEIGHT = 36,
                INPUT_HEIGHT = 40,
                SIDEBAR_WIDTH = 200,
                TOOLBAR_HEIGHT = 48,
                PANEL_PADDING = 16,
                CARD_PADDING = 20,
                TEXT_SMALL = 11,
                TEXT_MEDIUM = 13,
                TEXT_LARGE = 16
            },
            SPACING = {
                SMALL = 8,
                MEDIUM = 12,
                LARGE = 16,
                XLARGE = 24
            }
        }
    end
    
    -- Update Constants with new scale factor based on originals
    local orig = _G.ORIGINAL_UI_CONSTANTS
    Constants.UI.THEME.SIZES.BUTTON_HEIGHT = math.floor(orig.SIZES.BUTTON_HEIGHT * scaleFactor)
    Constants.UI.THEME.SIZES.INPUT_HEIGHT = math.floor(orig.SIZES.INPUT_HEIGHT * scaleFactor)
    Constants.UI.THEME.SIZES.SIDEBAR_WIDTH = math.floor(orig.SIZES.SIDEBAR_WIDTH * scaleFactor)
    Constants.UI.THEME.SIZES.TOOLBAR_HEIGHT = math.floor(orig.SIZES.TOOLBAR_HEIGHT * scaleFactor)
    Constants.UI.THEME.SIZES.PANEL_PADDING = math.floor(orig.SIZES.PANEL_PADDING * scaleFactor)
    Constants.UI.THEME.SIZES.CARD_PADDING = math.floor(orig.SIZES.CARD_PADDING * scaleFactor)
    
    -- Update text sizes
    Constants.UI.THEME.SIZES.TEXT_SMALL = math.floor(orig.SIZES.TEXT_SMALL * scaleFactor)
    Constants.UI.THEME.SIZES.TEXT_MEDIUM = math.floor(orig.SIZES.TEXT_MEDIUM * scaleFactor)
    Constants.UI.THEME.SIZES.TEXT_LARGE = math.floor(orig.SIZES.TEXT_LARGE * scaleFactor)
    
    -- Update spacing
    Constants.UI.THEME.SPACING.SMALL = math.floor(orig.SPACING.SMALL * scaleFactor)
    Constants.UI.THEME.SPACING.MEDIUM = math.floor(orig.SPACING.MEDIUM * scaleFactor)
    Constants.UI.THEME.SPACING.LARGE = math.floor(orig.SPACING.LARGE * scaleFactor)
    Constants.UI.THEME.SPACING.XLARGE = math.floor(orig.SPACING.XLARGE * scaleFactor)
    
    -- Store scale factor globally for new UI elements
    _G.UI_SCALE_FACTOR = scaleFactor
    _G.CURRENT_UI_SCALE = scale
    
    -- Apply scale to existing UI elements in the current view
    self:applyScaleToExistingElements(scaleFactor)
    
    -- Schedule view refresh to ensure all tabs handle scale changes gracefully
    self:scheduleScaleRefresh()
end

-- Apply scale to existing UI elements
function ViewManagerSlim:applyScaleToExistingElements(scaleFactor)
    -- Store the base scale factor for reference
    if not _G.BASE_UI_SCALE then
        _G.BASE_UI_SCALE = 1.0
    end
    
    -- Calculate relative scale from base
    local relativeScale = scaleFactor / _G.BASE_UI_SCALE
    
    -- Apply scale to text elements in the current view
    if self.mainContentArea then
        self:scaleUIElements(self.mainContentArea, relativeScale)
    end
    
    -- Apply scale to sidebar if available
    if self.uiManager and self.uiManager.navigationManager and self.uiManager.navigationManager.sidebar then
        self:scaleUIElements(self.uiManager.navigationManager.sidebar, relativeScale)
    end
    
    -- Update base scale for next time
    _G.BASE_UI_SCALE = scaleFactor
    
    debugLog("Applied scale factor " .. scaleFactor .. " to existing UI elements")
end

-- Schedule view refresh to handle scale changes gracefully across tabs
function ViewManagerSlim:scheduleScaleRefresh()
    -- Use spawn to avoid blocking the current operation
    spawn(function()
        wait(0.1) -- Small delay to let current scale changes complete
        
        -- Refresh navigation elements with new scale
        if self.uiManager and self.uiManager.navigationManager then
            self.uiManager.navigationManager:refreshNavigation()
        end
        
        -- If currently viewing data explorer, refresh it with new scale
        if self.currentView == "DataExplorer" then
            if self.uiManager and self.uiManager.dataExplorerManager then
                self.uiManager.dataExplorerManager:applyScale(_G.UI_SCALE_FACTOR or 1.0)
            end
        end
        
        -- Update any cached UI elements to use new scale factors
        self:updateCachedUIElements()
        
        debugLog("Scheduled scale refresh completed for current view: " .. (self.currentView or "unknown"))
    end)
end

-- Update cached UI elements with new scale factors
function ViewManagerSlim:updateCachedUIElements()
    -- Clear view instances to force recreation with new scale
    self.viewRegistry:clearViewInstances()
    
    -- Force refresh of current view to apply new constants
    local currentView = self.currentView
    if currentView == "Settings" then
        -- Don't refresh settings while we're in it to avoid infinite loops
        return
    elseif currentView == "Analytics" then
        self:showAnalyticsView()
    end
end

-- Recursively scale UI elements
function ViewManagerSlim:scaleUIElements(parent, scaleFactor)
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

return ViewManagerSlim 