-- ========================================
-- ENTERPRISE VIEW
-- ========================================
-- Provides enterprise-level UI for DataStore management including
-- version control, compliance, auditing, and metadata management

local Constants = require(script.Parent.Parent.shared.Constants)

local EnterpriseView = {}
EnterpriseView.__index = EnterpriseView

-- Create new Enterprise View instance
function EnterpriseView.new(services)
    local self = setmetatable({}, EnterpriseView)
    
    self.services = services
    self.enterpriseManager = services.EnterpriseManager or services["features.enterprise.EnterpriseManager"]
    self.themeManager = services.ThemeManager or services["ui.core.ThemeManager"]
    
    return self
end

-- Create enterprise dashboard
function EnterpriseView:createEnterpriseDashboard(parent)
    local enterpriseFrame = Instance.new("ScrollingFrame")
    enterpriseFrame.Name = "EnterpriseFrame"
    enterpriseFrame.Size = UDim2.new(1, 0, 1, 0)
    enterpriseFrame.Position = UDim2.new(0, 0, 0, 0)
    enterpriseFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    enterpriseFrame.BorderSizePixel = 0
    enterpriseFrame.ScrollBarThickness = 8
    enterpriseFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    enterpriseFrame.Parent = parent
    
    local yOffset = 20
    
    -- Enterprise Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -40, 0, 40)
    header.Position = UDim2.new(0, 20, 0, yOffset)
    header.BackgroundTransparency = 1
    header.Text = "🏢 Enterprise DataStore Management"
    header.Font = Constants.UI.THEME.FONTS.HEADING
    header.TextSize = 24
    header.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = enterpriseFrame
    yOffset = yOffset + 60
    
    -- Feature Categories
    local categories = {
        {
            title = "📊 Data Analytics & Insights",
            description = "Advanced analytics, usage patterns, and performance insights",
            features = {
                "DataStore usage analysis",
                "Key pattern recognition", 
                "Performance metrics",
                "Storage optimization recommendations"
            }
        },
        {
            title = "⚖️ Compliance & Auditing",
            description = "GDPR compliance, data tracking, and audit trails",
            features = {
                "GDPR compliance reports",
                "User data tracking for copyright/IP",
                "Audit logging and data lineage",
                "Data export for compliance requests"
            }
        },
        {
            title = "🕒 Version Management",
            description = "Complete version control with history and rollback",
            features = {
                "Key version history tracking",
                "Point-in-time data recovery",
                "Version comparison tools",
                "Automated backup creation"
            }
        },
        {
            title = "🔍 Advanced Operations",
            description = "Enterprise-grade DataStore operations",
            features = {
                "Bulk operations with metadata",
                "Advanced search and filtering",
                "Pagination support",
                "Custom metadata management"
            }
        }
    }
    
    for _, category in ipairs(categories) do
        local categoryCard = self:createFeatureCard(category, yOffset)
        categoryCard.Parent = enterpriseFrame
        yOffset = yOffset + 200
    end
    
    -- Action Center
    local actionCenter = self:createActionCenter(yOffset)
    actionCenter.Parent = enterpriseFrame
    yOffset = yOffset + 250
    
    -- Update canvas size
    enterpriseFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    
    return enterpriseFrame
end

-- Create feature card
function EnterpriseView:createFeatureCard(category, yPosition)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -40, 0, 180)
    card.Position = UDim2.new(0, 20, 0, yPosition)
    card.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    card.BorderSizePixel = 1
    card.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = category.title
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 16
    title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(1, -20, 0, 20)
    description.Position = UDim2.new(0, 10, 0, 45)
    description.BackgroundTransparency = 1
    description.Text = category.description
    description.Font = Constants.UI.THEME.FONTS.BODY
    description.TextSize = 12
    description.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Parent = card
    
    -- Features list
    local featuresY = 75
    for _, feature in ipairs(category.features) do
        local featureLabel = Instance.new("TextLabel")
        featureLabel.Size = UDim2.new(1, -30, 0, 20)
        featureLabel.Position = UDim2.new(0, 20, 0, featuresY)
        featureLabel.BackgroundTransparency = 1
        featureLabel.Text = "• " .. feature
        featureLabel.Font = Constants.UI.THEME.FONTS.BODY
        featureLabel.TextSize = 11
        featureLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        featureLabel.TextXAlignment = Enum.TextXAlignment.Left
        featureLabel.Parent = card
        featuresY = featuresY + 22
    end
    
    return card
end

-- Create action center
function EnterpriseView:createActionCenter(yPosition)
    local actionFrame = Instance.new("Frame")
    actionFrame.Size = UDim2.new(1, -40, 0, 230)
    actionFrame.Position = UDim2.new(0, 20, 0, yPosition)
    actionFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    actionFrame.BorderSizePixel = 1
    actionFrame.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 8)
    actionCorner.Parent = actionFrame
    
    -- Action Center Title
    local actionTitle = Instance.new("TextLabel")
    actionTitle.Size = UDim2.new(1, -20, 0, 30)
    actionTitle.Position = UDim2.new(0, 10, 0, 10)
    actionTitle.BackgroundTransparency = 1
    actionTitle.Text = "⚡ Enterprise Action Center"
    actionTitle.Font = Constants.UI.THEME.FONTS.UI
    actionTitle.TextSize = 16
    actionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    actionTitle.TextXAlignment = Enum.TextXAlignment.Left
    actionTitle.Parent = actionFrame
    
    -- Action buttons
    local actions = {
        {text = "📊 Generate Compliance Report", action = "compliance"},
        {text = "📈 Analyze DataStore Usage", action = "analytics"},
        {text = "🕒 View Version History", action = "versions"},
        {text = "💾 Export Data for Compliance", action = "export"}
    }
    
    local buttonY = 50
    for _, actionData in ipairs(actions) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.48, 0, 0, 35)
        button.Position = UDim2.new(
            (buttonY - 50) % 2 == 0 and 0.02 or 0.5, 
            0, 
            0, 
            buttonY + math.floor((buttonY - 50) / 2) * 45
        )
        button.BackgroundColor3 = Constants.UI.THEME.COLORS.BUTTON_PRIMARY
        button.BorderSizePixel = 0
        button.Text = actionData.text
        button.Font = Constants.UI.THEME.FONTS.UI
        button.TextSize = 12
        button.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
        button.Parent = actionFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Button hover effects
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Constants.UI.THEME.COLORS.BUTTON_HOVER
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Constants.UI.THEME.COLORS.BUTTON_PRIMARY
        end)
        
        buttonY = buttonY + 45
    end
    
    return actionFrame
end

-- Create compliance dashboard
function EnterpriseView:createComplianceDashboard(parent, datastoreName, userId)
    local complianceFrame = Instance.new("ScrollingFrame")
    complianceFrame.Name = "ComplianceFrame"
    complianceFrame.Size = UDim2.new(1, 0, 1, 0)
    complianceFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    complianceFrame.BorderSizePixel = 0
    complianceFrame.ScrollBarThickness = 8
    complianceFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    complianceFrame.Parent = parent
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -40, 0, 40)
    header.Position = UDim2.new(0, 20, 0, 20)
    header.BackgroundTransparency = 1
    header.Text = "⚖️ GDPR Compliance Report"
    header.Font = Constants.UI.THEME.FONTS.HEADING
    header.TextSize = 20
    header.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = complianceFrame
    
    -- Info panel
    local infoPanel = Instance.new("Frame")
    infoPanel.Size = UDim2.new(1, -40, 0, 100)
    infoPanel.Position = UDim2.new(0, 20, 0, 80)
    infoPanel.BackgroundColor3 = Constants.UI.THEME.COLORS.INFO_BACKGROUND
    infoPanel.BorderSizePixel = 1
    infoPanel.BorderColor3 = Constants.UI.THEME.COLORS.INFO_BORDER
    infoPanel.Parent = complianceFrame
    
    local infoPanelCorner = Instance.new("UICorner")
    infoPanelCorner.CornerRadius = UDim.new(0, 6)
    infoPanelCorner.Parent = infoPanel
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 1, -20)
    infoText.Position = UDim2.new(0, 10, 0, 10)
    infoText.BackgroundTransparency = 1
    infoText.Text = string.format("DataStore: %s\nUser ID: %s\nGenerated: %s", 
        datastoreName or "Unknown", 
        userId or "Unknown", 
        os.date("%Y-%m-%d %H:%M:%S")
    )
    infoText.Font = Constants.UI.THEME.FONTS.BODY
    infoText.TextSize = 12
    infoText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.Parent = infoPanel
    
    -- Generate report button
    local generateButton = Instance.new("TextButton")
    generateButton.Size = UDim2.new(0, 200, 0, 40)
    generateButton.Position = UDim2.new(0, 20, 0, 200)
    generateButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    generateButton.BorderSizePixel = 0
    generateButton.Text = "📊 Generate Compliance Report"
    generateButton.Font = Constants.UI.THEME.FONTS.UI
    generateButton.TextSize = 14
    generateButton.TextColor3 = Constants.UI.THEME.COLORS.BUTTON_TEXT
    generateButton.Parent = complianceFrame
    
    local generateCorner = Instance.new("UICorner")
    generateCorner.CornerRadius = UDim.new(0, 6)
    generateCorner.Parent = generateButton
    
    -- Results area (will be populated when report is generated)
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "ResultsFrame"
    resultsFrame.Size = UDim2.new(1, -40, 0, 400)
    resultsFrame.Position = UDim2.new(0, 20, 0, 260)
    resultsFrame.BackgroundTransparency = 1
    resultsFrame.Parent = complianceFrame
    
    return complianceFrame
end

return EnterpriseView 