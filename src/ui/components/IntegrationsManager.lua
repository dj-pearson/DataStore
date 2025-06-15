-- DataStore Manager Pro - Integrations Manager UI
-- Interface for managing OAuth connections to third-party services

local IntegrationsManager = {}
IntegrationsManager.__index = IntegrationsManager

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

function IntegrationsManager.new(services, themeManager)
    local self = setmetatable({}, IntegrationsManager)
    
    self.services = services
    self.themeManager = themeManager
    self.theme = themeManager:getCurrentTheme()
    
    -- Get OAuth manager from services
    self.oauthManager = nil
    for serviceName, service in pairs(services) do
        if serviceName:find("OAuthManager") then
            self.oauthManager = service
            break
        end
    end
    
    if not self.oauthManager then
        -- Try to load OAuth manager
        local success, OAuthManager = pcall(require, pluginRoot.features.integration.OAuthManager)
        if success then
            self.oauthManager = OAuthManager
            self.oauthManager.initialize()
        end
    end
    
    self.mainFrame = nil
    self.providersFrame = nil
    self.activeConnections = {}
    
    return self
end

-- Create the main integrations interface
function IntegrationsManager:createInterface(parent)
    self.mainFrame = Instance.new("ScrollingFrame")
    self.mainFrame.Name = "IntegrationsManager"
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.Position = UDim2.new(0, 0, 0, 0)
    self.mainFrame.BackgroundColor3 = self.theme.colors.background
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.ScrollBarThickness = 6
    self.mainFrame.Parent = parent
    
    self:createHeader()
    self:createProvidersSection()
    self:refreshProviders()
    
    return self.mainFrame
end

-- Create header section
function IntegrationsManager:createHeader()
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, -20, 0, 120)
    headerFrame.Position = UDim2.new(0, 10, 0, 10)
    headerFrame.BackgroundColor3 = Color3.fromRGB(45, 85, 255)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = self.mainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = headerFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔗 Third-Party Integrations"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerFrame
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -20, 0, 60)
    description.Position = UDim2.new(0, 10, 0, 50)
    description.BackgroundTransparency = 1
    description.Text = "Connect your DataStore Manager to external services for notifications, backups, and collaboration. Each integration uses secure OAuth 2.0 authentication."
    description.TextColor3 = Color3.fromRGB(220, 220, 220)
    description.TextWrapped = true
    description.Font = Enum.Font.Gotham
    description.TextSize = 14
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.Parent = headerFrame
end

-- Create providers section
function IntegrationsManager:createProvidersSection()
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 140)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "📋 Available Integrations"
    sectionTitle.TextColor3 = self.theme.colors.textPrimary
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = self.mainFrame
    
    self.providersFrame = Instance.new("Frame")
    self.providersFrame.Name = "ProvidersFrame"
    self.providersFrame.Size = UDim2.new(1, -20, 0, 500) -- Will be adjusted based on content
    self.providersFrame.Position = UDim2.new(0, 10, 0, 180)
    self.providersFrame.BackgroundTransparency = 1
    self.providersFrame.Parent = self.mainFrame
end

-- Refresh providers display
function IntegrationsManager:refreshProviders()
    if not self.oauthManager then
        self:showNoOAuthManager()
        return
    end
    
    -- Clear existing provider cards
    for _, child in pairs(self.providersFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local providers = self.oauthManager.getAllProviders()
    local yPos = 0
    
    for i, provider in ipairs(providers) do
        local card = self:createProviderCard(provider, yPos)
        card.Parent = self.providersFrame
        yPos = yPos + 120
    end
    
    -- Update frame size and canvas size
    self.providersFrame.Size = UDim2.new(1, -20, 0, yPos)
    self.mainFrame.CanvasSize = UDim2.new(0, 0, 0, 200 + yPos)
end

-- Create provider card
function IntegrationsManager:createProviderCard(provider, yPosition)
    local card = Instance.new("Frame")
    card.Name = provider.id .. "Card"
    card.Size = UDim2.new(1, 0, 0, 100)
    card.Position = UDim2.new(0, 0, 0, yPosition)
    card.BackgroundColor3 = self.theme.colors.surface
    card.BorderSizePixel = 0
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Provider icon and name
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 60, 0, 40)
    iconLabel.Position = UDim2.new(0, 20, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = provider.icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.Parent = card
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(0, 200, 0, 25)
    nameLabel.Position = UDim2.new(0, 90, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = provider.name
    nameLabel.TextColor3 = self.theme.colors.textPrimary
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card
    
    -- Status indicator
    local statusColor = self:getStatusColor(provider.status)
    local statusText = self:getStatusText(provider.status)
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0, 150, 0, 20)
    statusLabel.Position = UDim2.new(0, 90, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = statusText
    statusLabel.TextColor3 = statusColor
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card
    
    -- Connection details for connected providers
    if provider.connected and provider.user then
        local userInfo = self:formatUserInfo(provider)
        local userLabel = Instance.new("TextLabel")
        userLabel.Name = "UserInfo"
        userLabel.Size = UDim2.new(0, 300, 0, 20)
        userLabel.Position = UDim2.new(0, 90, 0, 55)
        userLabel.BackgroundTransparency = 1
        userLabel.Text = userInfo
        userLabel.TextColor3 = self.theme.colors.textSecondary
        userLabel.Font = Enum.Font.Gotham
        userLabel.TextSize = 11
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.Parent = card
    end
    
    -- Action button
    local actionBtn = self:createActionButton(provider)
    actionBtn.Position = UDim2.new(1, -120, 0, 25)
    actionBtn.Parent = card
    
    -- Settings button for connected providers
    if provider.connected then
        local settingsBtn = Instance.new("TextButton")
        settingsBtn.Name = "SettingsButton"
        settingsBtn.Size = UDim2.new(0, 30, 0, 30)
        settingsBtn.Position = UDim2.new(1, -150, 0, 25)
        settingsBtn.BackgroundColor3 = self.theme.colors.backgroundSecondary
        settingsBtn.Text = "⚙️"
        settingsBtn.TextScaled = true
        settingsBtn.Font = Enum.Font.Gotham
        settingsBtn.Parent = card
        
        local settingsCorner = Instance.new("UICorner")
        settingsCorner.CornerRadius = UDim.new(0, 4)
        settingsCorner.Parent = settingsBtn
        
        settingsBtn.MouseButton1Click:Connect(function()
            self:showProviderSettings(provider)
        end)
    end
    
    return card
end

-- Create action button based on provider status
function IntegrationsManager:createActionButton(provider)
    local button = Instance.new("TextButton")
    button.Name = "ActionButton"
    button.Size = UDim2.new(0, 100, 0, 30)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    if provider.status == "NOT_CONFIGURED" then
        button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        button.Text = "🔗 Connect"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        button.MouseButton1Click:Connect(function()
            self:showConnectionDialog(provider)
        end)
        
    elseif provider.status == "CONNECTED" then
        button.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        button.Text = "🔌 Disconnect"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        button.MouseButton1Click:Connect(function()
            self:disconnectProvider(provider)
        end)
        
    elseif provider.status == "ERROR" then
        button.BackgroundColor3 = Color3.fromRGB(243, 156, 18)
        button.Text = "🔄 Retry"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        button.MouseButton1Click:Connect(function()
            self:showConnectionDialog(provider)
        end)
    end
    
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    
    return button
end

-- Show connection dialog
function IntegrationsManager:showConnectionDialog(provider)
    -- Create modal dialog for OAuth configuration
    local modal = self:createModal("Connect to " .. provider.name, 400, 300)
    
    -- Client ID input
    local clientIdLabel = Instance.new("TextLabel")
    clientIdLabel.Size = UDim2.new(1, -40, 0, 20)
    clientIdLabel.Position = UDim2.new(0, 20, 0, 20)
    clientIdLabel.BackgroundTransparency = 1
    clientIdLabel.Text = "Client ID:"
    clientIdLabel.TextColor3 = self.theme.colors.textPrimary
    clientIdLabel.Font = Enum.Font.Gotham
    clientIdLabel.TextSize = 14
    clientIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    clientIdLabel.Parent = modal.content
    
    local clientIdInput = Instance.new("TextBox")
    clientIdInput.Name = "ClientIdInput"
    clientIdInput.Size = UDim2.new(1, -40, 0, 30)
    clientIdInput.Position = UDim2.new(0, 20, 0, 45)
    clientIdInput.BackgroundColor3 = self.theme.colors.backgroundSecondary
    clientIdInput.BorderSizePixel = 0
    clientIdInput.Text = ""
    clientIdInput.PlaceholderText = "Enter your " .. provider.name .. " Client ID"
    clientIdInput.TextColor3 = self.theme.colors.textPrimary
    clientIdInput.Font = Enum.Font.Gotham
    clientIdInput.TextSize = 12
    clientIdInput.Parent = modal.content
    
    local clientIdCorner = Instance.new("UICorner")
    clientIdCorner.CornerRadius = UDim.new(0, 4)
    clientIdCorner.Parent = clientIdInput
    
    -- Client Secret input
    local clientSecretLabel = Instance.new("TextLabel")
    clientSecretLabel.Size = UDim2.new(1, -40, 0, 20)
    clientSecretLabel.Position = UDim2.new(0, 20, 0, 85)
    clientSecretLabel.BackgroundTransparency = 1
    clientSecretLabel.Text = "Client Secret:"
    clientSecretLabel.TextColor3 = self.theme.colors.textPrimary
    clientSecretLabel.Font = Enum.Font.Gotham
    clientSecretLabel.TextSize = 14
    clientSecretLabel.TextXAlignment = Enum.TextXAlignment.Left
    clientSecretLabel.Parent = modal.content
    
    local clientSecretInput = Instance.new("TextBox")
    clientSecretInput.Name = "ClientSecretInput"
    clientSecretInput.Size = UDim2.new(1, -40, 0, 30)
    clientSecretInput.Position = UDim2.new(0, 20, 0, 110)
    clientSecretInput.BackgroundColor3 = self.theme.colors.backgroundSecondary
    clientSecretInput.BorderSizePixel = 0
    clientSecretInput.Text = ""
    clientSecretInput.PlaceholderText = "Enter your " .. provider.name .. " Client Secret"
    clientSecretInput.TextColor3 = self.theme.colors.textPrimary
    clientSecretInput.Font = Enum.Font.Gotham
    clientSecretInput.TextSize = 12
    clientSecretInput.Parent = modal.content
    
    local clientSecretCorner = Instance.new("UICorner")
    clientSecretCorner.CornerRadius = UDim.new(0, 4)
    clientSecretCorner.Parent = clientSecretInput
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, -40, 0, 60)
    instructions.Position = UDim2.new(0, 20, 0, 150)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Create an OAuth app in your " .. provider.name .. " developer settings to get these credentials. The redirect URI should be: http://localhost:8080/callback"
    instructions.TextColor3 = self.theme.colors.textSecondary
    instructions.TextWrapped = true
    instructions.Font = Enum.Font.Gotham
    instructions.TextSize = 11
    instructions.TextXAlignment = Enum.TextXAlignment.Left
    instructions.TextYAlignment = Enum.TextYAlignment.Top
    instructions.Parent = modal.content
    
    -- Connect button
    local connectBtn = Instance.new("TextButton")
    connectBtn.Size = UDim2.new(0, 100, 0, 35)
    connectBtn.Position = UDim2.new(0.5, -50, 1, -45)
    connectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    connectBtn.Text = "🚀 Connect"
    connectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    connectBtn.TextScaled = true
    connectBtn.Font = Enum.Font.GothamBold
    connectBtn.Parent = modal.content
    
    local connectCorner = Instance.new("UICorner")
    connectCorner.CornerRadius = UDim.new(0, 4)
    connectCorner.Parent = connectBtn
    
    connectBtn.MouseButton1Click:Connect(function()
        local clientId = clientIdInput.Text
        local clientSecret = clientSecretInput.Text
        
        if clientId ~= "" and clientSecret ~= "" then
            self:initiateOAuthFlow(provider, {
                clientId = clientId,
                clientSecret = clientSecret
            })
            modal.frame:Destroy()
        end
    end)
end

-- Initiate OAuth flow
function IntegrationsManager:initiateOAuthFlow(provider, config)
    if not self.oauthManager then
        return
    end
    
    local success, flowId = self.oauthManager.startOAuthFlow(provider.id, config)
    
    if success then
        print("[INTEGRATIONS] OAuth flow started for " .. provider.name .. " with flow ID: " .. flowId)
        
        -- Show progress indicator
        task.spawn(function()
            task.wait(3) -- Wait for simulated OAuth flow
            self:refreshProviders()
        end)
    else
        print("[INTEGRATIONS] Failed to start OAuth flow: " .. (flowId or "Unknown error"))
    end
end

-- Helper functions
function IntegrationsManager:getStatusColor(status)
    if status == "CONNECTED" then
        return Color3.fromRGB(46, 204, 113)
    elseif status == "ERROR" then
        return Color3.fromRGB(231, 76, 60)
    else
        return Color3.fromRGB(149, 165, 166)
    end
end

function IntegrationsManager:getStatusText(status)
    if status == "CONNECTED" then
        return "✅ Connected"
    elseif status == "ERROR" then
        return "❌ Error"
    else
        return "⚪ Not Connected"
    end
end

function IntegrationsManager:formatUserInfo(provider)
    local user = provider.user
    if not user then
        return "Connected"
    end
    
    if provider.id == "GITHUB" then
        return "Connected as: " .. (user.login or user.name or "Unknown")
    elseif provider.id == "SLACK" then
        return "Team: " .. (user.team or "Unknown")
    elseif provider.id == "DISCORD" then
        return "User: " .. (user.username or "Unknown")
    elseif provider.id == "MICROSOFT" then
        return "User: " .. (user.displayName or user.mail or "Unknown")
    elseif provider.id == "GOOGLE" then
        return "User: " .. (user.name or user.email or "Unknown")
    elseif provider.id == "DATADOG" then
        return "Org: " .. (user.org and user.org.name or "Unknown")
    else
        return "Connected"
    end
end

function IntegrationsManager:disconnectProvider(provider)
    if self.oauthManager then
        self.oauthManager.revokeConnection(provider.id)
        self:refreshProviders()
    end
end

function IntegrationsManager:showProviderSettings(provider)
    -- Show settings for connected provider
    print("[INTEGRATIONS] Showing settings for " .. provider.name)
end

function IntegrationsManager:showNoOAuthManager()
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, -40, 0, 60)
    errorLabel.Position = UDim2.new(0, 20, 0, 200)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Text = "❌ OAuth Manager not available. Integration features are disabled."
    errorLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
    errorLabel.TextWrapped = true
    errorLabel.Font = Enum.Font.Gotham
    errorLabel.TextSize = 16
    errorLabel.TextXAlignment = Enum.TextXAlignment.Center
    errorLabel.Parent = self.mainFrame
end

function IntegrationsManager:createModal(title, width, height)
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1000
    backdrop.Parent = game.CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    frame.BackgroundColor3 = self.theme.colors.surface
    frame.BorderSizePixel = 0
    frame.ZIndex = 1001
    frame.Parent = backdrop
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 40)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self.theme.colors.textPrimary
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = frame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 15)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        backdrop:Destroy()
    end)
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -60)
    content.Position = UDim2.new(0, 0, 0, 60)
    content.BackgroundTransparency = 1
    content.Parent = frame
    
    return {
        backdrop = backdrop,
        frame = frame,
        content = content
    }
end

return IntegrationsManager 