-- DataStore Manager Pro - Join Team Dialog
-- Simple interface for team members to join using invitation codes

local JoinTeamDialog = {}
JoinTeamDialog.__index = JoinTeamDialog

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Component configuration
local DIALOG_CONFIG = {
    SIZE = {
        WIDTH = 400,
        HEIGHT = 300
    },
    ANIMATION = {
        DURATION = 0.3,
        STYLE = "Quad"
    }
}

function JoinTeamDialog.new(plugin, themeManager, userManager)
    local self = setmetatable({}, JoinTeamDialog)
    
    self.plugin = plugin
    self.themeManager = themeManager
    self.userManager = userManager
    self.theme = themeManager:getCurrentTheme()
    
    self.isOpen = false
    self.mainFrame = nil
    self.codeInput = nil
    self.usernameInput = nil
    
    return self
end

-- Show the join team dialog
function JoinTeamDialog:show()
    if self.isOpen then
        return
    end
    
    self.isOpen = true
    self:createDialog()
end

-- Hide the dialog
function JoinTeamDialog:hide()
    if not self.isOpen or not self.mainFrame then
        return
    end
    
    self.isOpen = false
    
    -- Animate out
    self.mainFrame:TweenPosition(
        UDim2.new(0.5, 0, 1.5, 0),
        "Out",
        DIALOG_CONFIG.ANIMATION.STYLE,
        DIALOG_CONFIG.ANIMATION.DURATION,
        true,
        function()
            if self.mainFrame then
                self.mainFrame:Destroy()
                self.mainFrame = nil
            end
        end
    )
end

-- Create the main dialog
function JoinTeamDialog:createDialog()
    -- Create backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "JoinTeamBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1000
    backdrop.Parent = game.CoreGui
    
    -- Create main dialog frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "JoinTeamDialog"
    self.mainFrame.Size = UDim2.new(0, DIALOG_CONFIG.SIZE.WIDTH, 0, DIALOG_CONFIG.SIZE.HEIGHT)
    self.mainFrame.Position = UDim2.new(0.5, -DIALOG_CONFIG.SIZE.WIDTH/2, 1.5, 0) -- Start off-screen
    self.mainFrame.BackgroundColor3 = self.theme.colors.surface
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.ZIndex = 1001
    self.mainFrame.Parent = backdrop
    
    -- Add drop shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = 1000
    shadow.Parent = self.mainFrame
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.mainFrame
    
    -- Create dialog content
    self:createDialogContent()
    
    -- Animate in
    self.mainFrame:TweenPosition(
        UDim2.new(0.5, -DIALOG_CONFIG.SIZE.WIDTH/2, 0.5, -DIALOG_CONFIG.SIZE.HEIGHT/2),
        "Out",
        DIALOG_CONFIG.ANIMATION.STYLE,
        DIALOG_CONFIG.ANIMATION.DURATION,
        true
    )
    
    -- Click backdrop to close
    backdrop.MouseButton1Click:Connect(function()
        self:hide()
    end)
end

-- Create dialog content
function JoinTeamDialog:createDialogContent()
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    header.BorderSizePixel = 0
    header.Parent = self.mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Clip bottom corners of header
    local headerClip = Instance.new("Frame")
    headerClip.Size = UDim2.new(1, 0, 0, 30)
    headerClip.Position = UDim2.new(0, 0, 1, -30)
    headerClip.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    headerClip.BorderSizePixel = 0
    headerClip.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🤝 Join Team Collaboration"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 20)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:hide()
    end)
    
    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -80)
    content.Position = UDim2.new(0, 20, 0, 70)
    content.BackgroundTransparency = 1
    content.Parent = self.mainFrame
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, 0, 0, 60)
    instructions.Position = UDim2.new(0, 0, 0, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Enter the invitation code provided by your team admin to join the DataStore collaboration project."
    instructions.TextColor3 = self.theme.colors.textSecondary
    instructions.TextWrapped = true
    instructions.Font = Enum.Font.Gotham
    instructions.TextSize = 14
    instructions.TextXAlignment = Enum.TextXAlignment.Left
    instructions.TextYAlignment = Enum.TextYAlignment.Top
    instructions.Parent = content
    
    -- Username input
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "UsernameLabel"
    usernameLabel.Size = UDim2.new(1, 0, 0, 20)
    usernameLabel.Position = UDim2.new(0, 0, 0, 70)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = "Your Display Name:"
    usernameLabel.TextColor3 = self.theme.colors.textPrimary
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextSize = 14
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.Parent = content
    
    self.usernameInput = Instance.new("TextBox")
    self.usernameInput.Name = "UsernameInput"
    self.usernameInput.Size = UDim2.new(1, 0, 0, 35)
    self.usernameInput.Position = UDim2.new(0, 0, 0, 95)
    self.usernameInput.BackgroundColor3 = self.theme.colors.backgroundSecondary
    self.usernameInput.BorderSizePixel = 0
    self.usernameInput.Text = ""
    self.usernameInput.PlaceholderText = "Enter your name (e.g., John Developer)"
    self.usernameInput.TextColor3 = self.theme.colors.textPrimary
    self.usernameInput.PlaceholderColor3 = self.theme.colors.textSecondary
    self.usernameInput.Font = Enum.Font.Gotham
    self.usernameInput.TextSize = 14
    self.usernameInput.Parent = content
    
    local usernameCorner = Instance.new("UICorner")
    usernameCorner.CornerRadius = UDim.new(0, 6)
    usernameCorner.Parent = self.usernameInput
    
    -- Code input
    local codeLabel = Instance.new("TextLabel")
    codeLabel.Name = "CodeLabel"
    codeLabel.Size = UDim2.new(1, 0, 0, 20)
    codeLabel.Position = UDim2.new(0, 0, 0, 140)
    codeLabel.BackgroundTransparency = 1
    codeLabel.Text = "Invitation Code:"
    codeLabel.TextColor3 = self.theme.colors.textPrimary
    codeLabel.Font = Enum.Font.Gotham
    codeLabel.TextSize = 14
    codeLabel.TextXAlignment = Enum.TextXAlignment.Left
    codeLabel.Parent = content
    
    self.codeInput = Instance.new("TextBox")
    self.codeInput.Name = "CodeInput"
    self.codeInput.Size = UDim2.new(0.65, 0, 0, 35)
    self.codeInput.Position = UDim2.new(0, 0, 0, 165)
    self.codeInput.BackgroundColor3 = self.theme.colors.backgroundSecondary
    self.codeInput.BorderSizePixel = 0
    self.codeInput.Text = ""
    self.codeInput.PlaceholderText = "Enter 8-character code"
    self.codeInput.TextColor3 = self.theme.colors.textPrimary
    self.codeInput.PlaceholderColor3 = self.theme.colors.textSecondary
    self.codeInput.Font = Enum.Font.RobotoMono
    self.codeInput.TextSize = 16
    self.codeInput.Parent = content
    
    local codeCorner = Instance.new("UICorner")
    codeCorner.CornerRadius = UDim.new(0, 6)
    codeCorner.Parent = self.codeInput
    
    -- Auto-format code input (uppercase, 8 chars max)
    self.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
        local text = self.codeInput.Text
        text = string.upper(text)
        text = string.sub(text, 1, 8)
        self.codeInput.Text = text
    end)
    
    -- Join button
    local joinBtn = Instance.new("TextButton")
    joinBtn.Name = "JoinButton"
    joinBtn.Size = UDim2.new(0.3, -10, 0, 35)
    joinBtn.Position = UDim2.new(0.7, 10, 0, 165)
    joinBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    joinBtn.Text = "🚀 Join Team"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.TextScaled = true
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Parent = content
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 6)
    joinCorner.Parent = joinBtn
    
    joinBtn.MouseButton1Click:Connect(function()
        self:attemptJoin()
    end)
    
    -- Status message area
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Name = "StatusLabel"
    self.statusLabel.Size = UDim2.new(1, 0, 0, 20)
    self.statusLabel.Position = UDim2.new(0, 0, 1, -25)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = ""
    self.statusLabel.TextColor3 = self.theme.colors.textSecondary
    self.statusLabel.Font = Enum.Font.Gotham
    self.statusLabel.TextSize = 12
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.statusLabel.Parent = content
    
    -- Focus on username input
    self.usernameInput:CaptureFocus()
end

-- Attempt to join team with the provided code
function JoinTeamDialog:attemptJoin()
    local code = self.codeInput.Text
    local username = self.usernameInput.Text
    
    -- Validate inputs
    if not code or code == "" then
        self:showStatus("Please enter an invitation code", Color3.fromRGB(231, 76, 60))
        return
    end
    
    if not username or username == "" then
        self:showStatus("Please enter your display name", Color3.fromRGB(231, 76, 60))
        return
    end
    
    if string.len(code) ~= 8 then
        self:showStatus("Invitation code must be 8 characters", Color3.fromRGB(231, 76, 60))
        return
    end
    
    self:showStatus("Joining team...", Color3.fromRGB(52, 152, 219))
    
    -- Generate a user ID based on username and timestamp
    local userId = "user_" .. string.gsub(username, " ", "_"):lower() .. "_" .. os.time()
    
    local newUserData = {
        userId = userId,
        userName = username
    }
    
    -- Attempt to use the invitation code
    local success, result = self.userManager:useInvitationCode(code, newUserData)
    
    if success then
        self:showStatus("Successfully joined the team!", Color3.fromRGB(46, 204, 113))
        
        -- Show welcome message
        task.wait(1)
        self:showStatus("Welcome to the team, " .. username .. "!", Color3.fromRGB(46, 204, 113))
        
        -- Close dialog after success
        task.wait(2)
        self:hide()
        
        -- Trigger UI refresh if needed
        if self.onJoinSuccess then
            self.onJoinSuccess(result)
        end
    else
        local errorMsg = result or "Failed to join team"
        self:showStatus("Error: " .. errorMsg, Color3.fromRGB(231, 76, 60))
    end
end

-- Show status message
function JoinTeamDialog:showStatus(message, color)
    self.statusLabel.Text = message
    self.statusLabel.TextColor3 = color or self.theme.colors.textSecondary
end

-- Set join success callback
function JoinTeamDialog:setJoinSuccessCallback(callback)
    self.onJoinSuccess = callback
end

-- Cleanup
function JoinTeamDialog:destroy()
    if self.mainFrame then
        self.mainFrame:Destroy()
        self.mainFrame = nil
    end
    self.isOpen = false
end

return JoinTeamDialog 