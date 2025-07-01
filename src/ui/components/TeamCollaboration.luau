-- DataStore Manager Pro - Personal Workspace
-- Safe single-user workspace without collaboration features

local PersonalWorkspace = {}
PersonalWorkspace.__index = PersonalWorkspace

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

function PersonalWorkspace.new(services)
    local self = setmetatable({}, PersonalWorkspace)
    
    self.services = services or {}
    
    print("[PERSONAL_WORKSPACE] [INFO] Personal workspace component created")
    
    return self
end

function PersonalWorkspace:mount(parent)
    if not parent then
        print("[PERSONAL_WORKSPACE] [ERROR] No parent provided for mounting")
        return
    end
    
    print("[PERSONAL_WORKSPACE] [INFO] Mounting personal workspace")
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "PersonalWorkspace"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = parent
    
    -- Create content
    self:createHeader(mainFrame)
    self:createWorkspaceSettings(mainFrame)
    
    print("[PERSONAL_WORKSPACE] [INFO] Personal workspace mounted successfully")
    
    return mainFrame
end

function PersonalWorkspace:createHeader(parent)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.Parent = parent
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "🔧 Personal Workspace"
    title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Manage your personal DataStore workspace and preferences"
    subtitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 14
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
end

function PersonalWorkspace:createWorkspaceSettings(parent)
    local settings = Instance.new("Frame")
    settings.Size = UDim2.new(1, -40, 0, 200)
    settings.Position = UDim2.new(0, 20, 0, 100)
    settings.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    settings.BorderSizePixel = 1
    settings.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    settings.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = settings
    
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, -20, 0, 30)
    settingsTitle.Position = UDim2.new(0, 10, 0, 10)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Text = "⚙️ Workspace Settings"
    settingsTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.TextSize = 16
    settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingsTitle.Parent = settings
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 0, 120)
    infoText.Position = UDim2.new(0, 10, 0, 50)
    infoText.BackgroundTransparency = 1
    infoText.Text = "🔒 Your workspace is private and secure.\n📊 All data stays local to your Studio session.\n⚙️ Configure preferences in the Settings tab.\n🔧 Use DataStore tools for safe data management."
    infoText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 12
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.TextWrapped = true
    infoText.Parent = settings
end

return PersonalWorkspace