-- DataStore Manager Pro - Safe Plugin Workspace
-- Single-user workspace management without external collaboration

local SafeWorkspace = {}
SafeWorkspace.__index = SafeWorkspace

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

function SafeWorkspace.new(parent, services)
    local self = setmetatable({}, SafeWorkspace)
    
    self.parent = parent
    self.services = services or {}
    self.theme = Constants.UI.THEME
    
    return self
end

function SafeWorkspace:render()
    -- Clear existing content
    for _, child in ipairs(self.parent:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Create main container
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Position = UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = self.theme.colors.backgroundPrimary
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 8
    container.CanvasSize = UDim2.new(0, 0, 0, 400)
    container.Parent = self.parent
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "🔧 Personal Workspace"
    title.TextColor3 = self.theme.colors.textPrimary
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(1, -40, 0, 40)
    description.Position = UDim2.new(0, 20, 0, 60)
    description.BackgroundTransparency = 1
    description.Text = "Manage your personal DataStore workspace and preferences."
    description.TextColor3 = self.theme.colors.textSecondary
    description.Font = Enum.Font.Gotham
    description.TextSize = 14
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = container
    
    -- Create workspace settings section
    self:createWorkspaceSettings(container)
    
    return container
end

function SafeWorkspace:createWorkspaceSettings(parent)
    -- Workspace settings frame
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -40, 0, 200)
    section.Position = UDim2.new(0, 20, 0, 120)
    section.BackgroundColor3 = self.theme.colors.backgroundSecondary
    section.BorderSizePixel = 1
    section.BorderColor3 = self.theme.colors.borderPrimary
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 10)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "⚙️ Workspace Settings"
    sectionTitle.TextColor3 = self.theme.colors.textPrimary
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 16
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    -- Personal preferences info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -20, 0, 80)
    infoLabel.Position = UDim2.new(0, 10, 0, 50)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "🔒 Your workspace is private and secure.\n📊 All data stays local to your Studio session.\n⚙️ Configure preferences in the Settings tab."
    infoLabel.TextColor3 = self.theme.colors.textSecondary
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.TextWrapped = true
    infoLabel.Parent = section
end

return SafeWorkspace