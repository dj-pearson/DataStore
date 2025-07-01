-- DataStore Manager Pro - Enhanced Layout Manager
-- Modern responsive layout system with adaptive design and accessibility

local LayoutManager = {}
LayoutManager.__index = LayoutManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)
local ThemeManager = require(script.Parent.ThemeManager)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[LAYOUT_MANAGER] [%s] %s", level, message))
end

-- Layout state and configuration
local layoutState = {
    currentBreakpoint = "desktop",
    screenSize = {width = 1920, height = 1080},
    scaleFactor = 1,
    adaptiveMode = true,
    accessibilityMode = false,
    initialized = false
}

-- Responsive breakpoints
local BREAKPOINTS = {
    mobile = {minWidth = 0, maxWidth = 768, scaleFactor = 0.8},
    tablet = {minWidth = 769, maxWidth = 1024, scaleFactor = 0.9},
    desktop = {minWidth = 1025, maxWidth = 1440, scaleFactor = 1.0},
    large = {minWidth = 1441, maxWidth = 9999, scaleFactor = 1.1}
}

-- Layout patterns for responsive design
local LAYOUT_PATTERNS = {
    GRID = {
        mobile = {columns = 1, spacing = 8},
        tablet = {columns = 2, spacing = 12},
        desktop = {columns = 3, spacing = 16},
        large = {columns = 4, spacing = 20}
    },
    SIDEBAR = {
        mobile = {width = 0, collapsed = true},
        tablet = {width = 200, collapsed = false},
        desktop = {width = 250, collapsed = false},
        large = {width = 300, collapsed = false}
    },
    CARDS = {
        mobile = {minWidth = 280, maxWidth = 350, spacing = 8},
        tablet = {minWidth = 300, maxWidth = 400, spacing = 12},
        desktop = {minWidth = 320, maxWidth = 450, spacing = 16},
        large = {minWidth = 350, maxWidth = 500, spacing = 20}
    }
}

-- Create new Layout Manager instance
function LayoutManager.new(uiManager)
    local self = setmetatable({}, LayoutManager)
    
    self.uiManager = uiManager
    self.mainFrame = nil
    self.mainContainer = nil
    self.mainContentArea = nil
    self.statusLabel = nil
    
    debugLog("LayoutManager created")
    return self
end

-- Initialize Layout Manager
function LayoutManager.initialize()
    debugLog("Initializing Enhanced Layout Manager with responsive design")
    
    -- Detect initial screen size
    LayoutManager.updateScreenSize()
    
    -- Initialize responsive system
    LayoutManager.initializeResponsiveSystem()
    
    layoutState.initialized = true
    debugLog("Layout Manager initialized with " .. layoutState.currentBreakpoint .. " breakpoint")
    
    return true
end

-- Initialize responsive system
function LayoutManager.initializeResponsiveSystem()
    -- Monitor screen size changes (in production, would use viewport change events)
    spawn(function()
        while layoutState.initialized do
            LayoutManager.updateScreenSize()
            wait(1) -- Check every second
        end
    end)
end

-- Update screen size and breakpoint
function LayoutManager.updateScreenSize()
    -- Use safe default viewport size instead of camera access
    local viewportSize = {X = 1200, Y = 800} -- Safe default size
    
    -- Try to get viewport size safely without camera access
    local success, result = pcall(function()
        local gui = game:GetService("GuiService")
        return gui:GetGuiInset()
    end)
    
    if success and result then
        -- Use safe alternative to camera viewport
        layoutState.screenSize.width = viewportSize.X
        layoutState.screenSize.height = viewportSize.Y
    else
        -- Use default safe values
        layoutState.screenSize.width = 1200
        layoutState.screenSize.height = 800
    end
    
    -- Determine current breakpoint
    local newBreakpoint = LayoutManager.determineBreakpoint(layoutState.screenSize.width)
    
    if newBreakpoint ~= layoutState.currentBreakpoint then
        layoutState.currentBreakpoint = newBreakpoint
        layoutState.scaleFactor = BREAKPOINTS[newBreakpoint].scaleFactor
        debugLog("Breakpoint changed to: " .. newBreakpoint)
        
        -- Trigger responsive layout updates
        LayoutManager.triggerResponsiveUpdate()
    end
end

-- Determine breakpoint based on width
function LayoutManager.determineBreakpoint(width)
    for name, config in pairs(BREAKPOINTS) do
        if width >= config.minWidth and width <= config.maxWidth then
            return name
        end
    end
    return "desktop" -- Default fallback
end

-- Trigger responsive layout updates
function LayoutManager.triggerResponsiveUpdate()
    -- In production, would notify all responsive components
    debugLog("Triggering responsive layout update for " .. layoutState.currentBreakpoint)
end

-- Create responsive grid layout
function LayoutManager.createResponsiveGrid(parent, config)
    local gridContainer = Instance.new("Frame")
    gridContainer.Name = config.name or "ResponsiveGrid"
    gridContainer.Size = config.size or UDim2.new(1, 0, 1, 0)
    gridContainer.Position = config.position or UDim2.new(0, 0, 0, 0)
    gridContainer.BackgroundTransparency = 1
    gridContainer.Parent = parent
    
    -- Create UIGridLayout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Parent = gridContainer
    
    -- Apply responsive grid settings
    LayoutManager.updateResponsiveGrid(gridLayout, config.pattern or "GRID")
    
    -- Add padding if specified
    if config.padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, config.padding)
        padding.PaddingBottom = UDim.new(0, config.padding)
        padding.PaddingLeft = UDim.new(0, config.padding)
        padding.PaddingRight = UDim.new(0, config.padding)
        padding.Parent = gridContainer
    end
    
    -- Store reference for responsive updates
    gridContainer:SetAttribute("LayoutPattern", config.pattern or "GRID")
    gridContainer:SetAttribute("IsResponsive", true)
    
    return gridContainer, gridLayout
end

-- Update responsive grid based on current breakpoint
function LayoutManager.updateResponsiveGrid(gridLayout, patternName)
    local pattern = LAYOUT_PATTERNS[patternName]
    if not pattern then return end
    
    local currentPattern = pattern[layoutState.currentBreakpoint]
    if not currentPattern then return end
    
    -- Update grid properties
    gridLayout.CellSize = UDim2.new(
        1 / currentPattern.columns, -currentPattern.spacing,
        0, 120 * layoutState.scaleFactor
    )
    gridLayout.CellPadding = UDim2.new(0, currentPattern.spacing, 0, currentPattern.spacing)
    
    debugLog(string.format("Updated grid: %d columns, %dpx spacing", 
        currentPattern.columns, currentPattern.spacing))
end

-- Create responsive sidebar
function LayoutManager.createResponsiveSidebar(parent, config)
    local sidebarContainer = Instance.new("Frame")
    sidebarContainer.Name = config.name or "ResponsiveSidebar"
    sidebarContainer.BackgroundTransparency = 1
    sidebarContainer.Parent = parent
    
    -- Create actual sidebar
    local sidebar = ThemeManager.createProfessionalCard({
        name = "SidebarCard",
        background = "secondary",
        borderColor = "primary",
        cornerRadius = 0
    })
    sidebar.Parent = sidebarContainer
    
    -- Apply responsive sidebar settings
    LayoutManager.updateResponsiveSidebar(sidebarContainer, sidebar, config.pattern or "SIDEBAR")
    
    -- Store reference for responsive updates
    sidebarContainer:SetAttribute("LayoutPattern", config.pattern or "SIDEBAR")
    sidebarContainer:SetAttribute("IsResponsive", true)
    
    return sidebarContainer, sidebar
end

-- Instance methods for ModularUIManager integration

-- Create main frame
function LayoutManager:createMainFrame(widget, pluginInfo)
    if not widget then
        debugLog("Widget is required for main frame creation", "ERROR")
        return false
    end
    
    self.mainFrame = widget
    debugLog("Main frame reference set")
    return true
end

-- Setup layout
function LayoutManager:setupLayout()
    if not self.mainFrame then
        debugLog("Main frame not set", "ERROR")
        return false
    end
    
    -- Create main container
    self.mainContainer = Instance.new("Frame")
    self.mainContainer.Name = "MainContainer"
    self.mainContainer.Size = UDim2.new(1, 0, 1, 0)
    self.mainContainer.Position = UDim2.new(0, 0, 0, 0)
    self.mainContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.mainContainer.BorderSizePixel = 0
    self.mainContainer.Parent = self.mainFrame
    
    debugLog("Main container created")
    return true
end

-- Create main content area
function LayoutManager:createMainContentArea(parent)
    if not parent then
        debugLog("Parent required for main content area", "ERROR")
        return false
    end
    
    self.mainContentArea = Instance.new("Frame")
    self.mainContentArea.Name = "MainContentArea"
    self.mainContentArea.Size = UDim2.new(1, -250, 1, -40)
    self.mainContentArea.Position = UDim2.new(0, 250, 0, 0)
    self.mainContentArea.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    self.mainContentArea.BorderSizePixel = 0
    self.mainContentArea.Parent = parent
    
    -- Create status bar
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Name = "StatusLabel"
    self.statusLabel.Size = UDim2.new(1, 0, 0, 30)
    self.statusLabel.Position = UDim2.new(0, 0, 1, -30)
    self.statusLabel.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    self.statusLabel.BorderSizePixel = 1
    self.statusLabel.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    self.statusLabel.Text = "Ready"
    self.statusLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    self.statusLabel.TextSize = 12
    self.statusLabel.Font = Constants.UI.THEME.FONTS.BODY
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.Parent = parent
    
    debugLog("Main content area created")
    return true
end

-- Get main container
function LayoutManager:getMainContainer()
    return self.mainContainer
end

-- Get main content area
function LayoutManager:getMainContentArea()
    return self.mainContentArea
end

-- Get status label
function LayoutManager:getStatusLabel()
    return self.statusLabel
end

-- Set visibility
function LayoutManager:setVisible(visible)
    if self.mainFrame then
        self.mainFrame.Enabled = visible
    end
end

-- Cleanup
function LayoutManager:destroy()
    self.mainFrame = nil
    self.mainContainer = nil
    self.mainContentArea = nil
    self.statusLabel = nil
    debugLog("LayoutManager destroyed")
end

-- Update responsive sidebar based on current breakpoint
function LayoutManager.updateResponsiveSidebar(container, sidebar, patternName)
    local pattern = LAYOUT_PATTERNS[patternName]
    if not pattern then return end
    
    local currentPattern = pattern[layoutState.currentBreakpoint]
    if not currentPattern then return end
    
    if currentPattern.collapsed then
        -- Hide sidebar on mobile
        container.Size = UDim2.new(0, 0, 1, 0)
        container.Visible = false
    else
        -- Show sidebar with appropriate width
        container.Size = UDim2.new(0, currentPattern.width * layoutState.scaleFactor, 1, 0)
        container.Visible = true
        sidebar.Size = UDim2.new(1, 0, 1, 0)
    end
    
    debugLog(string.format("Updated sidebar: width=%dpx, collapsed=%s", 
        currentPattern.width, tostring(currentPattern.collapsed)))
end

-- Create adaptive card layout
function LayoutManager.createAdaptiveCards(parent, config)
    local cardsContainer = Instance.new("Frame")
    cardsContainer.Name = config.name or "AdaptiveCards"
    cardsContainer.Size = config.size or UDim2.new(1, 0, 1, 0)
    cardsContainer.Position = config.position or UDim2.new(0, 0, 0, 0)
    cardsContainer.BackgroundTransparency = 1
    cardsContainer.Parent = parent
    
    -- Create UIListLayout for cards
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Wraps = true
    listLayout.Parent = cardsContainer
    
    -- Apply responsive card settings
    LayoutManager.updateAdaptiveCards(listLayout, config.pattern or "CARDS")
    
    -- Store reference for responsive updates
    cardsContainer:SetAttribute("LayoutPattern", config.pattern or "CARDS")
    cardsContainer:SetAttribute("IsResponsive", true)
    
    return cardsContainer, listLayout
end

-- Update adaptive cards based on current breakpoint
function LayoutManager.updateAdaptiveCards(listLayout, patternName)
    local pattern = LAYOUT_PATTERNS[patternName]
    if not pattern then return end
    
    local currentPattern = pattern[layoutState.currentBreakpoint]
    if not currentPattern then return end
    
    -- Update card spacing
    listLayout.Padding = UDim.new(0, currentPattern.spacing)
    
    debugLog(string.format("Updated cards: minWidth=%dpx, maxWidth=%dpx, spacing=%dpx", 
        currentPattern.minWidth, currentPattern.maxWidth, currentPattern.spacing))
end

-- Create responsive navigation bar
function LayoutManager.createResponsiveNavigation(parent, config)
    local navContainer = Instance.new("Frame")
    navContainer.Name = config.name or "ResponsiveNavigation"
    navContainer.Size = UDim2.new(1, 0, 0, 48 * layoutState.scaleFactor)
    navContainer.Position = UDim2.new(0, 0, 0, 0)
    navContainer.Parent = parent
    
    -- Apply theme
    ThemeManager.applyTheme(navContainer, {
        background = "primary",
        borderColor = "primary"
    })
    
    navContainer.BorderSizePixel = 1
    
    -- Create navigation content
    local navContent = Instance.new("Frame")
    navContent.Name = "NavigationContent"
    navContent.Size = UDim2.new(1, -32, 1, 0)
    navContent.Position = UDim2.new(0, 16, 0, 0)
    navContent.BackgroundTransparency = 1
    navContent.Parent = navContainer
    
    -- Logo/Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = config.title or "DataStore Manager Pro"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 16 * layoutState.scaleFactor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = navContent
    
    -- Apply theme to title
    ThemeManager.applyTheme(title, {textColor = "primary"})
    
    -- Navigation buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Name = "ButtonsContainer"
    buttonsContainer.Size = UDim2.new(1, -220, 1, 0)
    buttonsContainer.Position = UDim2.new(0, 220, 0, 0)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = navContent
    
    -- Create responsive navigation layout
    LayoutManager.updateResponsiveNavigation(navContainer, buttonsContainer)
    
    return navContainer, buttonsContainer
end

-- Update responsive navigation based on current breakpoint
function LayoutManager.updateResponsiveNavigation(navContainer, buttonsContainer)
    local isMobile = layoutState.currentBreakpoint == "mobile"
    
    if isMobile then
        -- Mobile: Show hamburger menu
        LayoutManager.createMobileMenu(buttonsContainer)
    else
        -- Desktop: Show full navigation
        LayoutManager.createDesktopMenu(buttonsContainer)
    end
end

-- Create mobile hamburger menu
function LayoutManager.createMobileMenu(container)
    -- Clear existing content
    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end
    
    -- Hamburger menu button
    local hamburgerButton = ThemeManager.createProfessionalButton({
        name = "HamburgerMenu",
        text = "☰",
        size = UDim2.new(0, 40, 0, 32),
        position = UDim2.new(1, -50, 0, 8),
        background = "tertiary",
        textColor = "primary"
    })
    hamburgerButton.Parent = container
    
    -- Add click handler for mobile menu
    hamburgerButton.MouseButton1Click:Connect(function()
        LayoutManager.toggleMobileMenu(container)
    end)
    
    debugLog("Created mobile navigation menu")
end

-- Create desktop menu
function LayoutManager.createDesktopMenu(container)
    -- Clear existing content
    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end
    
    -- Desktop navigation buttons
    local navButtons = {"Dashboard", "Analytics", "Settings", "Help"}
    
    for i, buttonText in ipairs(navButtons) do
        local button = ThemeManager.createProfessionalButton({
            name = buttonText .. "Button",
            text = buttonText,
            size = UDim2.new(0, 80, 0, 32),
            position = UDim2.new(1, -((#navButtons - i + 1) * 90), 0, 8),
            background = "tertiary",
            textColor = "primary"
        })
        button.Parent = container
    end
    
    debugLog("Created desktop navigation menu")
end

-- Toggle mobile menu
function LayoutManager.toggleMobileMenu(container)
    -- In production, would show/hide mobile menu overlay
    debugLog("Mobile menu toggled")
end

-- Create responsive modal
function LayoutManager.createResponsiveModal(parent, config)
    local modalOverlay = Instance.new("Frame")
    modalOverlay.Name = config.name or "ResponsiveModal"
    modalOverlay.Size = UDim2.new(1, 0, 1, 0)
    modalOverlay.Position = UDim2.new(0, 0, 0, 0)
    modalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    modalOverlay.BackgroundTransparency = 0.5
    modalOverlay.ZIndex = 1000
    modalOverlay.Parent = parent
    
    -- Modal container
    local modalContainer = Instance.new("Frame")
    modalContainer.Name = "ModalContainer"
    modalContainer.BackgroundTransparency = 1
    modalContainer.Parent = modalOverlay
    
    -- Modal content
    local modalContent = ThemeManager.createGlassmorphismCard({
        name = "ModalContent",
        cornerRadius = 16
    })
    modalContent.Parent = modalContainer
    
    -- Apply responsive modal sizing
    LayoutManager.updateResponsiveModal(modalContainer, modalContent)
    
    -- Close button
    local closeButton = ThemeManager.createProfessionalButton({
        name = "CloseButton",
        text = "✕",
        size = UDim2.new(0, 32, 0, 32),
        position = UDim2.new(1, -40, 0, 8),
        background = "tertiary",
        textColor = "primary"
    })
    closeButton.Parent = modalContent
    
    -- Close modal on click
    closeButton.MouseButton1Click:Connect(function()
        LayoutManager.closeModal(modalOverlay)
    end)
    
    -- Close on overlay click
    modalOverlay.MouseButton1Click:Connect(function()
        LayoutManager.closeModal(modalOverlay)
    end)
    
    -- Prevent modal content clicks from closing modal
    modalContent.MouseButton1Click:Connect(function() end)
    
    -- Show modal with animation
    if ThemeManager.areAnimationsEnabled() then
        ThemeManager.fadeIn(modalOverlay, 0.3)
        ThemeManager.slideIn(modalContent, "bottom", 0.4)
    end
    
    return modalOverlay, modalContent
end

-- Update responsive modal based on current breakpoint
function LayoutManager.updateResponsiveModal(container, content)
    local isMobile = layoutState.currentBreakpoint == "mobile"
    
    if isMobile then
        -- Mobile: Full screen modal
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Position = UDim2.new(0, 0, 0, 0)
        content.Size = UDim2.new(1, -20, 1, -40)
        content.Position = UDim2.new(0, 10, 0, 20)
    else
        -- Desktop: Centered modal
        local modalWidth = math.min(600 * layoutState.scaleFactor, layoutState.screenSize.width * 0.8)
        local modalHeight = math.min(400 * layoutState.scaleFactor, layoutState.screenSize.height * 0.8)
        
        container.Size = UDim2.new(0, modalWidth, 0, modalHeight)
        container.Position = UDim2.new(0.5, -modalWidth/2, 0.5, -modalHeight/2)
        content.Size = UDim2.new(1, 0, 1, 0)
        content.Position = UDim2.new(0, 0, 0, 0)
    end
end

-- Close modal with animation
function LayoutManager.closeModal(modal)
    if ThemeManager.areAnimationsEnabled() then
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = game:GetService("TweenService"):Create(modal, tweenInfo, {
            BackgroundTransparency = 1
        })
        
        tween:Play()
        tween.Completed:Connect(function()
            modal:Destroy()
        end)
    else
        modal:Destroy()
    end
end

-- Create responsive form layout
function LayoutManager.createResponsiveForm(parent, config)
    local formContainer = Instance.new("ScrollingFrame")
    formContainer.Name = config.name or "ResponsiveForm"
    formContainer.Size = config.size or UDim2.new(1, 0, 1, 0)
    formContainer.Position = config.position or UDim2.new(0, 0, 0, 0)
    formContainer.BackgroundTransparency = 1
    formContainer.ScrollBarThickness = 6
    formContainer.Parent = parent
    
    -- Form content
    local formContent = Instance.new("Frame")
    formContent.Name = "FormContent"
    formContent.Size = UDim2.new(1, 0, 0, 0)
    formContent.BackgroundTransparency = 1
    formContent.Parent = formContainer
    
    -- Auto-sizing layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 16 * layoutState.scaleFactor)
    listLayout.Parent = formContent
    
    -- Update canvas size when content changes
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        formContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 32)
    end)
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 16 * layoutState.scaleFactor)
    padding.PaddingBottom = UDim.new(0, 16 * layoutState.scaleFactor)
    padding.PaddingLeft = UDim.new(0, 16 * layoutState.scaleFactor)
    padding.PaddingRight = UDim.new(0, 16 * layoutState.scaleFactor)
    padding.Parent = formContent
    
    return formContainer, formContent
end

-- Get current breakpoint
function LayoutManager.getCurrentBreakpoint()
    return layoutState.currentBreakpoint
end

-- Get scale factor
function LayoutManager.getScaleFactor()
    return layoutState.scaleFactor
end

-- Check if mobile layout
function LayoutManager.isMobileLayout()
    return layoutState.currentBreakpoint == "mobile"
end

-- Enable accessibility mode
function LayoutManager.enableAccessibilityMode()
    layoutState.accessibilityMode = true
    debugLog("Accessibility mode enabled")
    
    -- Apply accessibility enhancements to all responsive elements
    LayoutManager.applyAccessibilityEnhancements()
end

-- Apply accessibility enhancements
function LayoutManager.applyAccessibilityEnhancements()
    -- Increase scale factor for better readability
    layoutState.scaleFactor = layoutState.scaleFactor * 1.2
    
    -- Update all responsive layouts
    LayoutManager.triggerResponsiveUpdate()
    
    debugLog("Applied accessibility enhancements")
end

-- Cleanup function
function LayoutManager.cleanup()
    layoutState.initialized = false
    debugLog("Layout Manager cleanup complete")
end

return LayoutManager 
