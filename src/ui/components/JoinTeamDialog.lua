-- DataStore Manager Pro - Safe User Information Dialog
-- Safe user information without team collaboration features

local UserInfoDialog = {}
UserInfoDialog.__index = UserInfoDialog

function UserInfoDialog.new(parent, services)
    local self = setmetatable({}, UserInfoDialog)
    
    self.parent = parent
    self.services = services or {}
    self.dialogVisible = false
    self.dialogContainer = nil
    
    return self
end

function UserInfoDialog:showDialog()
    if self.dialogVisible then
        return
    end
    
    self.dialogVisible = true
    
    -- Create safe user info dialog
    local backdrop = Instance.new("Frame")
    backdrop.Name = "UserInfoBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.ZIndex = 1000
    backdrop.Parent = self.parent
    
    self.dialogContainer = backdrop
    
    -- Create dialog content
    self:createDialog()
end

function UserInfoDialog:createDialog()
    local dialog = Instance.new("Frame")
    dialog.Name = "UserInfoDialog"
    dialog.Size = UDim2.new(0, 400, 0, 300)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -150)
    dialog.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 1001
    dialog.Parent = self.dialogContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = dialog
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -40, 0, 40)
    header.Position = UDim2.new(0, 20, 0, 20)
    header.BackgroundTransparency = 1
    header.Text = "ℹ️ User Information"
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = dialog
    
    -- Content
    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -40, 0, 150)
    content.Position = UDim2.new(0, 20, 0, 80)
    content.BackgroundTransparency = 1
    content.Text = "🔒 This is your personal workspace.\n📊 All data remains local to Studio.\n⚙️ No external connections are made.\n🛡️ Your workspace is private and secure."
    content.TextColor3 = Color3.fromRGB(200, 200, 200)
    content.Font = Enum.Font.Gotham
    content.TextSize = 14
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.Parent = dialog
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 35)
    closeButton.Position = UDim2.new(0.5, -50, 1, -60)
    closeButton.BackgroundColor3 = Color3.fromRGB(67, 133, 255)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = dialog
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:hideDialog()
    end)
end

function UserInfoDialog:hideDialog()
    if self.dialogContainer then
        self.dialogContainer:Destroy()
        self.dialogContainer = nil
    end
    self.dialogVisible = false
end

return UserInfoDialog 