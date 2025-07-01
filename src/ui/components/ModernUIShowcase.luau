-- DataStore Manager Pro - Modern UI Showcase
-- Demonstrates all modern UI polish features and components

local ModernUIShowcase = {}
ModernUIShowcase.__index = ModernUIShowcase

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)
local ThemeManager = require(script.Parent.Parent.core.ThemeManager)
local LayoutManager = require(script.Parent.Parent.core.LayoutManager)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[MODERN_UI_SHOWCASE] [%s] %s", level, message))
end

-- Create new Modern UI Showcase
function ModernUIShowcase.new(services)
    local self = setmetatable({}, ModernUIShowcase)
    
    self.services = services or {}
    self.isVisible = false
    self.showcaseData = {
        progressValue = 0.7,
        toggleStates = {
            animations = true,
            darkMode = true,
            notifications = true,
            accessibility = false
        },
        formData = {
            username = "",
            email = "",
            preferences = {}
        }
    }
    
    -- UI elements
    self.gui = nil
    self.sections = {}
    
    debugLog("Modern UI Showcase created")
    return self
end

-- Initialize the showcase
function ModernUIShowcase:initialize(parent)
    self:createShowcaseUI(parent)
    debugLog("Modern UI Showcase initialized")
end

-- Create the main showcase UI
function ModernUIShowcase:createShowcaseUI(parent)
    -- Main showcase container
    self.gui = Instance.new("ScrollingFrame")
    self.gui.Name = "ModernUIShowcase"
    self.gui.Size = UDim2.new(1, 0, 1, 0)
    self.gui.Position = UDim2.new(0, 0, 0, 0)
    self.gui.BackgroundTransparency = 1
    self.gui.ScrollBarThickness = 8
    self.gui.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    self.gui.Parent = parent
    
    -- Showcase content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ShowcaseContent"
    contentContainer.Size = UDim2.new(1, 0, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = self.gui
    
    -- Auto-sizing layout
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.Padding = UDim.new(0, 24)
    mainLayout.Parent = contentContainer
    
    -- Update canvas size when content changes
    mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.gui.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 48)
    end)
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 24)
    padding.PaddingBottom = UDim.new(0, 24)
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.Parent = contentContainer
    
    -- Create showcase sections
    self:createHeaderSection(contentContainer)
    self:createGlassmorphismSection(contentContainer)
    self:createModernInputsSection(contentContainer)
    self:createInteractiveElementsSection(contentContainer)
    self:createNotificationSection(contentContainer)
    self:createResponsiveLayoutSection(contentContainer)
    self:createAnimationShowcaseSection(contentContainer)
    self:createAccessibilitySection(contentContainer)
end

-- Create header section
function ModernUIShowcase:createHeaderSection(parent)
    local headerSection = Instance.new("Frame")
    headerSection.Name = "HeaderSection"
    headerSection.Size = UDim2.new(1, 0, 0, 120)
    headerSection.BackgroundTransparency = 1
    headerSection.Parent = parent
    
    -- Header card with glassmorphism
    local headerCard = ThemeManager.createGlassmorphismCard({
        name = "HeaderCard",
        size = UDim2.new(1, 0, 1, 0),
        cornerRadius = 16
    })
    headerCard.Parent = headerSection
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.Text = "🎨 Modern UI Showcase"
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 28
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerCard
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -40, 0, 30)
    subtitle.Position = UDim2.new(0, 20, 0, 65)
    subtitle.Text = "Experience the latest in modern UI design with glassmorphism, animations, and responsive layouts"
    subtitle.Font = Constants.UI.THEME.FONTS.UI
    subtitle.TextSize = 14
    subtitle.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    subtitle.BackgroundTransparency = 1
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextWrapped = true
    subtitle.Parent = headerCard
    
    -- Add glow effect to header
    if ThemeManager.areAnimationsEnabled() then
        ThemeManager.addGlowEffect(headerCard, "subtle")
    end
    
    self.sections.header = headerSection
end

-- Create glassmorphism section
function ModernUIShowcase:createGlassmorphismSection(parent)
    local glassSection = Instance.new("Frame")
    glassSection.Name = "GlassmorphismSection"
    glassSection.Size = UDim2.new(1, 0, 0, 300)
    glassSection.BackgroundTransparency = 1
    glassSection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("✨ Glassmorphism Effects", glassSection)
    
    -- Create responsive grid for glass cards
    local gridContainer, gridLayout = LayoutManager.createResponsiveGrid(glassSection, {
        name = "GlassCardsGrid",
        size = UDim2.new(1, 0, 1, -40),
        position = UDim2.new(0, 0, 0, 40),
        pattern = "GRID",
        padding = 16
    })
    
    -- Create glass cards with different effects
    local glassCards = {
        {title = "Subtle Glass", description = "Light glassmorphism effect", intensity = "subtle"},
        {title = "Strong Glass", description = "Bold glassmorphism effect", intensity = "strong"},
        {title = "Gradient Glass", description = "Glass with gradient overlay", gradient = true},
        {title = "Interactive Glass", description = "Glass with hover effects", interactive = true}
    }
    
    for i, cardData in ipairs(glassCards) do
        local glassCard = ThemeManager.createGlassmorphismCard({
            name = "GlassCard" .. i,
            size = UDim2.new(1, 0, 0, 120),
            cornerRadius = 12
        })
        glassCard.Parent = gridContainer
        
        -- Add glow effect based on intensity
        if cardData.intensity == "strong" then
            ThemeManager.addGlowEffect(glassCard, "strong")
        elseif cardData.intensity == "subtle" then
            ThemeManager.addGlowEffect(glassCard, "subtle")
        end
        
        -- Card content
        local cardTitle = Instance.new("TextLabel")
        cardTitle.Name = "CardTitle"
        cardTitle.Size = UDim2.new(1, -20, 0, 24)
        cardTitle.Position = UDim2.new(0, 10, 0, 10)
        cardTitle.Text = cardData.title
        cardTitle.Font = Constants.UI.THEME.FONTS.UI
        cardTitle.TextSize = 16
        cardTitle.TextColor3 = ThemeManager.getCurrentTheme().text.primary
        cardTitle.BackgroundTransparency = 1
        cardTitle.TextXAlignment = Enum.TextXAlignment.Left
        cardTitle.Parent = glassCard
        
        local cardDesc = Instance.new("TextLabel")
        cardDesc.Name = "CardDescription"
        cardDesc.Size = UDim2.new(1, -20, 0, 60)
        cardDesc.Position = UDim2.new(0, 10, 0, 40)
        cardDesc.Text = cardData.description
        cardDesc.Font = Constants.UI.THEME.FONTS.UI
        cardDesc.TextSize = 12
        cardDesc.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
        cardDesc.BackgroundTransparency = 1
        cardDesc.TextXAlignment = Enum.TextXAlignment.Left
        cardDesc.TextWrapped = true
        cardDesc.Parent = glassCard
        
        -- Add interactive effects
        if cardData.interactive then
            ThemeManager.addHoverEffects(glassCard, "scale")
        end
    end
    
    self.sections.glassmorphism = glassSection
end

-- Create modern inputs section
function ModernUIShowcase:createModernInputsSection(parent)
    local inputsSection = Instance.new("Frame")
    inputsSection.Name = "ModernInputsSection"
    inputsSection.Size = UDim2.new(1, 0, 0, 400)
    inputsSection.BackgroundTransparency = 1
    inputsSection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("📝 Modern Input Fields", inputsSection)
    
    -- Inputs container
    local inputsContainer = Instance.new("Frame")
    inputsContainer.Name = "InputsContainer"
    inputsContainer.Size = UDim2.new(1, 0, 1, -40)
    inputsContainer.Position = UDim2.new(0, 0, 0, 40)
    inputsContainer.BackgroundTransparency = 1
    inputsContainer.Parent = inputsSection
    
    -- Create responsive form
    local formContainer, formContent = LayoutManager.createResponsiveForm(inputsContainer, {
        name = "ModernInputsForm"
    })
    
    -- Username input with floating label
    local usernameContainer, usernameField = ThemeManager.createModernInput({
        name = "UsernameInput",
        placeholder = "Enter username",
        label = "Username",
        parent = formContent
    })
    usernameContainer.Parent = formContent
    
    -- Remove email validation and replace with username validation
    ThemeManager.createModernTooltip(usernameField, "Please enter a valid username")
    
    -- Password input
    local passwordContainer, passwordField = ThemeManager.createModernInput({
        name = "PasswordInput",
        placeholder = "Enter your password",
        label = "Password",
        size = UDim2.new(0.8, 0, 0, 48)
    })
    passwordContainer.Parent = formContent
    passwordField.TextTransparency = 0.5 -- Simulate password masking
    
    self.sections.inputs = inputsSection
end

-- Create interactive elements section
function ModernUIShowcase:createInteractiveElementsSection(parent)
    local interactiveSection = Instance.new("Frame")
    interactiveSection.Name = "InteractiveElementsSection"
    interactiveSection.Size = UDim2.new(1, 0, 0, 300)
    interactiveSection.BackgroundTransparency = 1
    interactiveSection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("🎛️ Interactive Elements", interactiveSection)
    
    -- Elements container
    local elementsContainer = Instance.new("Frame")
    elementsContainer.Name = "ElementsContainer"
    elementsContainer.Size = UDim2.new(1, 0, 1, -40)
    elementsContainer.Position = UDim2.new(0, 0, 0, 40)
    elementsContainer.BackgroundTransparency = 1
    elementsContainer.Parent = interactiveSection
    
    -- Create grid layout
    local gridContainer, gridLayout = LayoutManager.createResponsiveGrid(elementsContainer, {
        name = "InteractiveGrid",
        pattern = "CARDS",
        padding = 16
    })
    
    -- Toggle switches
    local toggleCard = ThemeManager.createProfessionalCard({
        name = "ToggleCard",
        size = UDim2.new(1, 0, 0, 180),
        background = "secondary",
        cornerRadius = 12
    })
    toggleCard.Parent = gridContainer
    
    local toggleTitle = Instance.new("TextLabel")
    toggleTitle.Name = "ToggleTitle"
    toggleTitle.Size = UDim2.new(1, -20, 0, 30)
    toggleTitle.Position = UDim2.new(0, 10, 0, 10)
    toggleTitle.Text = "Toggle Switches"
    toggleTitle.Font = Constants.UI.THEME.FONTS.UI
    toggleTitle.TextSize = 16
    toggleTitle.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    toggleTitle.BackgroundTransparency = 1
    toggleTitle.TextXAlignment = Enum.TextXAlignment.Left
    toggleTitle.Parent = toggleCard
    
    -- Create toggle switches
    local toggles = {
        {name = "Animations", key = "animations"},
        {name = "Dark Mode", key = "darkMode"},
        {name = "Notifications", key = "notifications"}
    }
    
    for i, toggleData in ipairs(toggles) do
        local toggleContainer, enabled = ThemeManager.createModernToggle({
            name = toggleData.name .. "Toggle",
            position = UDim2.new(0, 20, 0, 40 + (i * 40)),
            enabled = self.showcaseData.toggleStates[toggleData.key],
            onToggle = function(newState)
                self.showcaseData.toggleStates[toggleData.key] = newState
                debugLog(toggleData.name .. " toggled: " .. tostring(newState))
            end
        })
        toggleContainer.Parent = toggleCard
        
        -- Toggle label
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "ToggleLabel"
        toggleLabel.Size = UDim2.new(0, 150, 0, 28)
        toggleLabel.Position = UDim2.new(0, 80, 0, 40 + (i * 40))
        toggleLabel.Text = toggleData.name
        toggleLabel.Font = Constants.UI.THEME.FONTS.UI
        toggleLabel.TextSize = 14
        toggleLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = toggleCard
    end
    
    -- Progress bars
    local progressCard = ThemeManager.createProfessionalCard({
        name = "ProgressCard",
        size = UDim2.new(1, 0, 0, 180),
        background = "secondary",
        cornerRadius = 12
    })
    progressCard.Parent = gridContainer
    
    local progressTitle = Instance.new("TextLabel")
    progressTitle.Name = "ProgressTitle"
    progressTitle.Size = UDim2.new(1, -20, 0, 30)
    progressTitle.Position = UDim2.new(0, 10, 0, 10)
    progressTitle.Text = "Progress Indicators"
    progressTitle.Font = Constants.UI.THEME.FONTS.UI
    progressTitle.TextSize = 16
    progressTitle.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    progressTitle.BackgroundTransparency = 1
    progressTitle.TextXAlignment = Enum.TextXAlignment.Left
    progressTitle.Parent = progressCard
    
    -- Create progress bars
    local progressBars = {
        {name = "Standard", progress = 0.7, color = nil},
        {name = "Success", progress = 0.9, color = ThemeManager.getCurrentTheme().accent.success},
        {name = "Warning", progress = 0.5, color = ThemeManager.getCurrentTheme().accent.warning},
        {name = "Gradient", progress = 0.8, gradient = true}
    }
    
    for i, progressData in ipairs(progressBars) do
        local progressContainer, updateProgress = ThemeManager.createModernProgressBar({
            name = progressData.name .. "Progress",
            size = UDim2.new(0.8, 0, 0, 8),
            position = UDim2.new(0, 20, 0, 50 + (i * 30)),
            progress = progressData.progress,
            color = progressData.color,
            gradient = progressData.gradient
        })
        progressContainer.Parent = progressCard
        
        -- Progress label
        local progressLabel = Instance.new("TextLabel")
        progressLabel.Name = "ProgressLabel"
        progressLabel.Size = UDim2.new(0, 100, 0, 20)
        progressLabel.Position = UDim2.new(0, 20, 0, 35 + (i * 30))
        progressLabel.Text = progressData.name .. " (" .. math.floor(progressData.progress * 100) .. "%)"
        progressLabel.Font = Constants.UI.THEME.FONTS.UI
        progressLabel.TextSize = 12
        progressLabel.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
        progressLabel.BackgroundTransparency = 1
        progressLabel.TextXAlignment = Enum.TextXAlignment.Left
        progressLabel.Parent = progressCard
    end
    
    self.sections.interactive = interactiveSection
end

-- Create notification section
function ModernUIShowcase:createNotificationSection(parent)
    local notificationSection = Instance.new("Frame")
    notificationSection.Name = "NotificationSection"
    notificationSection.Size = UDim2.new(1, 0, 0, 200)
    notificationSection.BackgroundTransparency = 1
    notificationSection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("🔔 Modern Notifications", notificationSection)
    
    -- Notification demo container
    local demoContainer = ThemeManager.createProfessionalCard({
        name = "NotificationDemo",
        size = UDim2.new(1, 0, 1, -40),
        position = UDim2.new(0, 0, 0, 40),
        background = "secondary",
        cornerRadius = 12
    })
    demoContainer.Parent = notificationSection
    
    -- Demo buttons
    local notificationTypes = {
        {text = "Success", type = "success", icon = "✅", message = "Operation completed successfully!"},
        {text = "Warning", type = "warning", icon = "⚠️", message = "Please review your settings."},
        {text = "Error", type = "error", icon = "❌", message = "An error occurred. Please try again."},
        {text = "Info", type = "info", icon = "ℹ️", message = "Here's some helpful information."}
    }
    
    for i, notifData in ipairs(notificationTypes) do
        local notifButton = ThemeManager.createProfessionalButton({
            name = notifData.type .. "NotificationButton",
            text = notifData.text .. " Notification",
            size = UDim2.new(0, 180, 0, 36),
            position = UDim2.new(0, 20 + ((i-1) * 200), 0, 60),
            background = "tertiary",
            textColor = "primary"
        })
        notifButton.Parent = demoContainer
        
        -- Add click handler
        notifButton.MouseButton1Click:Connect(function()
            self:showDemoNotification(notifData)
        end)
    end
    
    -- Demo description
    local demoDesc = Instance.new("TextLabel")
    demoDesc.Name = "DemoDescription"
    demoDesc.Size = UDim2.new(1, -40, 0, 40)
    demoDesc.Position = UDim2.new(0, 20, 0, 20)
    demoDesc.Text = "Click the buttons below to see different notification styles with glassmorphism effects and smooth animations."
    demoDesc.Font = Constants.UI.THEME.FONTS.UI
    demoDesc.TextSize = 14
    demoDesc.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    demoDesc.BackgroundTransparency = 1
    demoDesc.TextWrapped = true
    demoDesc.Parent = demoContainer
    
    self.sections.notifications = notificationSection
end

-- Create responsive layout section
function ModernUIShowcase:createResponsiveLayoutSection(parent)
    local responsiveSection = Instance.new("Frame")
    responsiveSection.Name = "ResponsiveLayoutSection"
    responsiveSection.Size = UDim2.new(1, 0, 0, 250)
    responsiveSection.BackgroundTransparency = 1
    responsiveSection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("📱 Responsive Design", responsiveSection)
    
    -- Responsive demo container
    local responsiveDemo = ThemeManager.createProfessionalCard({
        name = "ResponsiveDemo",
        size = UDim2.new(1, 0, 1, -40),
        position = UDim2.new(0, 0, 0, 40),
        background = "secondary",
        cornerRadius = 12
    })
    responsiveDemo.Parent = responsiveSection
    
    -- Current breakpoint display
    local breakpointDisplay = Instance.new("TextLabel")
    breakpointDisplay.Name = "BreakpointDisplay"
    breakpointDisplay.Size = UDim2.new(1, -40, 0, 30)
    breakpointDisplay.Position = UDim2.new(0, 20, 0, 20)
    breakpointDisplay.Text = "Current Breakpoint: " .. LayoutManager.getCurrentBreakpoint():upper() .. " (Scale: " .. string.format("%.1f", LayoutManager.getScaleFactor()) .. "x)"
    breakpointDisplay.Font = Constants.UI.THEME.FONTS.UI
    breakpointDisplay.TextSize = 16
    breakpointDisplay.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    breakpointDisplay.BackgroundTransparency = 1
    breakpointDisplay.TextXAlignment = Enum.TextXAlignment.Left
    breakpointDisplay.Parent = responsiveDemo
    
    -- Responsive grid demo
    local responsiveGrid, gridLayout = LayoutManager.createResponsiveGrid(responsiveDemo, {
        name = "ResponsiveGridDemo",
        size = UDim2.new(1, -40, 1, -80),
        position = UDim2.new(0, 20, 0, 60),
        pattern = "GRID",
        padding = 8
    })
    
    -- Add demo cards to grid
    for i = 1, 6 do
        local demoCard = ThemeManager.createProfessionalCard({
            name = "DemoCard" .. i,
            size = UDim2.new(1, 0, 0, 80),
            background = "tertiary",
            cornerRadius = 8
        })
        demoCard.Parent = responsiveGrid
        
        local cardLabel = Instance.new("TextLabel")
        cardLabel.Name = "CardLabel"
        cardLabel.Size = UDim2.new(1, 0, 1, 0)
        cardLabel.Text = "Card " .. i
        cardLabel.Font = Constants.UI.THEME.FONTS.UI
        cardLabel.TextSize = 14
        cardLabel.TextColor3 = ThemeManager.getCurrentTheme().text.primary
        cardLabel.BackgroundTransparency = 1
        cardLabel.Parent = demoCard
    end
    
    self.sections.responsive = responsiveSection
end

-- Create animation showcase section
function ModernUIShowcase:createAnimationShowcaseSection(parent)
    local animationSection = Instance.new("Frame")
    animationSection.Name = "AnimationShowcaseSection"
    animationSection.Size = UDim2.new(1, 0, 0, 200)
    animationSection.BackgroundTransparency = 1
    animationSection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("✨ Smooth Animations", animationSection)
    
    -- Animation demo container
    local animationDemo = ThemeManager.createProfessionalCard({
        name = "AnimationDemo",
        size = UDim2.new(1, 0, 1, -40),
        position = UDim2.new(0, 0, 0, 40),
        background = "secondary",
        cornerRadius = 12
    })
    animationDemo.Parent = animationSection
    
    -- Animation demo buttons
    local animationTypes = {
        {text = "Fade In", type = "fadeIn"},
        {text = "Slide Left", type = "slideLeft"},
        {text = "Slide Right", type = "slideRight"},
        {text = "Scale", type = "scale"}
    }
    
    for i, animData in ipairs(animationTypes) do
        local animButton = ThemeManager.createProfessionalButton({
            name = animData.type .. "Button",
            text = animData.text,
            size = UDim2.new(0, 120, 0, 32),
            position = UDim2.new(0, 20 + ((i-1) * 140), 0, 60),
            background = "tertiary",
            textColor = "primary"
        })
        animButton.Parent = animationDemo
        
        -- Add click handler
        animButton.MouseButton1Click:Connect(function()
            self:demonstrateAnimation(animData.type, animButton)
        end)
    end
    
    -- Demo target element
    local demoTarget = ThemeManager.createProfessionalCard({
        name = "AnimationTarget",
        size = UDim2.new(0, 100, 0, 60),
        position = UDim2.new(0.5, -50, 0, 110),
        background = "accent",
        cornerRadius = 8
    })
    demoTarget.Parent = animationDemo
    
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Name = "TargetLabel"
    targetLabel.Size = UDim2.new(1, 0, 1, 0)
    targetLabel.Text = "Demo\nTarget"
    targetLabel.Font = Constants.UI.THEME.FONTS.UI
    targetLabel.TextSize = 12
    targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Parent = demoTarget
    
    self.demoTarget = demoTarget
    self.sections.animations = animationSection
end

-- Create accessibility section
function ModernUIShowcase:createAccessibilitySection(parent)
    local accessibilitySection = Instance.new("Frame")
    accessibilitySection.Name = "AccessibilitySection"
    accessibilitySection.Size = UDim2.new(1, 0, 0, 200)
    accessibilitySection.BackgroundTransparency = 1
    accessibilitySection.Parent = parent
    
    -- Section title
    local sectionTitle = self:createSectionTitle("♿ Accessibility Features", accessibilitySection)
    
    -- Accessibility demo container
    local accessibilityDemo = ThemeManager.createProfessionalCard({
        name = "AccessibilityDemo",
        size = UDim2.new(1, 0, 1, -40),
        position = UDim2.new(0, 0, 0, 40),
        background = "secondary",
        cornerRadius = 12
    })
    accessibilityDemo.Parent = accessibilitySection
    
    -- Accessibility toggle
    local accessibilityToggle, accessibilityEnabled = ThemeManager.createModernToggle({
        name = "AccessibilityToggle",
        position = UDim2.new(0, 20, 0, 30),
        enabled = layoutState.accessibilityMode,
        onToggle = function(enabled)
            if enabled then
                LayoutManager.enableAccessibilityMode()
            end
            debugLog("Accessibility mode: " .. tostring(enabled))
        end
    })
    accessibilityToggle.Parent = accessibilityDemo
    
    -- Accessibility label
    local accessibilityLabel = Instance.new("TextLabel")
    accessibilityLabel.Name = "AccessibilityLabel"
    accessibilityLabel.Size = UDim2.new(0, 200, 0, 28)
    accessibilityLabel.Position = UDim2.new(0, 80, 0, 30)
    accessibilityLabel.Text = "Enable Accessibility Mode"
    accessibilityLabel.Font = Constants.UI.THEME.FONTS.UI
    accessibilityLabel.TextSize = 14
    accessibilityLabel.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    accessibilityLabel.BackgroundTransparency = 1
    accessibilityLabel.TextXAlignment = Enum.TextXAlignment.Left
    accessibilityLabel.Parent = accessibilityDemo
    
    -- Accessibility description
    local accessibilityDesc = Instance.new("TextLabel")
    accessibilityDesc.Name = "AccessibilityDescription"
    accessibilityDesc.Size = UDim2.new(1, -40, 0, 80)
    accessibilityDesc.Position = UDim2.new(0, 20, 0, 70)
    accessibilityDesc.Text = "Accessibility mode includes:\n• Increased text and UI scaling\n• High contrast support\n• Focus indicators for keyboard navigation\n• Screen reader compatibility"
    accessibilityDesc.Font = Constants.UI.THEME.FONTS.UI
    accessibilityDesc.TextSize = 12
    accessibilityDesc.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    accessibilityDesc.BackgroundTransparency = 1
    accessibilityDesc.TextXAlignment = Enum.TextXAlignment.Left
    accessibilityDesc.TextYAlignment = Enum.TextYAlignment.Top
    accessibilityDesc.TextWrapped = true
    accessibilityDesc.Parent = accessibilityDemo
    
    self.sections.accessibility = accessibilitySection
end

-- Helper function to create section titles
function ModernUIShowcase:createSectionTitle(text, parent)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "SectionTitle"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = text
    titleLabel.Font = Constants.UI.THEME.FONTS.UI
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = parent
    
    return titleLabel
end

-- Show demo notification
function ModernUIShowcase:showDemoNotification(notificationData)
    local notification = ThemeManager.createModernNotification({
        title = notificationData.text .. " Notification",
        message = notificationData.message,
        icon = notificationData.icon,
        type = notificationData.type,
        duration = 3
    })
    notification.Parent = self.gui.Parent
end

-- Demonstrate animation
function ModernUIShowcase:demonstrateAnimation(animationType, button)
    if not self.demoTarget then return end
    
    -- Reset target position
    self.demoTarget.Position = UDim2.new(0.5, -50, 0, 110)
    self.demoTarget.Size = UDim2.new(0, 100, 0, 60)
    self.demoTarget.BackgroundTransparency = 0
    
    if animationType == "fadeIn" then
        ThemeManager.fadeIn(self.demoTarget, 0.5)
    elseif animationType == "slideLeft" then
        ThemeManager.slideIn(self.demoTarget, "left", 0.5)
    elseif animationType == "slideRight" then
        ThemeManager.slideIn(self.demoTarget, "right", 0.5)
    elseif animationType == "scale" then
        ThemeManager.addHoverEffects(self.demoTarget, "scale")
        -- Simulate hover
        spawn(function()
            wait(0.1)
            ThemeManager.animateHover(self.demoTarget, "scale", "enter")
            wait(1)
            ThemeManager.animateHover(self.demoTarget, "scale", "leave", UDim2.new(0, 100, 0, 60), 0)
        end)
    end
    
    debugLog("Demonstrated " .. animationType .. " animation")
end

-- Show showcase
function ModernUIShowcase:show()
    if self.gui then
        self.gui.Visible = true
        self.isVisible = true
        debugLog("Modern UI Showcase shown")
    end
end

-- Hide showcase
function ModernUIShowcase:hide()
    if self.gui then
        self.gui.Visible = false
        self.isVisible = false
        debugLog("Modern UI Showcase hidden")
    end
end

-- Cleanup
function ModernUIShowcase:cleanup()
    self:hide()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
    debugLog("Modern UI Showcase cleanup complete")
end

return ModernUIShowcase 