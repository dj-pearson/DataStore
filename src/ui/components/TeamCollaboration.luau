-- DataStore Manager Pro - Team Collaboration Dashboard
-- Enterprise team collaboration with real-time sync, shared workspaces, and activity feeds

local TeamCollaboration = {}
TeamCollaboration.__index = TeamCollaboration

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

function TeamCollaboration.new(services)
    local self = setmetatable({}, TeamCollaboration)
    self.services = services or {}
    self.updateInterval = nil
    self.isActive = false
    
    print("[TEAM_COLLABORATION] [INFO] TeamCollaboration component created")
    return self
end

function TeamCollaboration:mount(parent)
    if not parent then
        print("[TEAM_COLLABORATION] [ERROR] No parent provided for mounting")
        return nil
    end

    print("[TEAM_COLLABORATION] [INFO] Mounting team collaboration dashboard")

    -- Create main container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "TeamCollaborationDashboard"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = parent

    -- Create header
    self:createHeader(mainFrame)
    
    -- Create scrollable content
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "CollaborationScroll"
    scrollFrame.Size = UDim2.new(1, -40, 1, -100)
    scrollFrame.Position = UDim2.new(0, 20, 0, 80)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    scrollFrame.Parent = mainFrame

    -- Create sections
    self:createActiveTeamSection(scrollFrame)
    self:createWorkspaceSection(scrollFrame)
    self:createActivityFeedSection(scrollFrame)
    self:createCollaborationToolsSection(scrollFrame)
    self:createTeamStatsSection(scrollFrame)

    -- Start real-time updates
    self:startRealTimeUpdates()
    self.isActive = true

    print("[TEAM_COLLABORATION] [INFO] Team collaboration dashboard mounted successfully")
    return mainFrame
end

function TeamCollaboration:createHeader(parent)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    header.BorderSizePixel = 0
    header.Parent = parent

    -- Header gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
    }
    gradient.Rotation = 90
    gradient.Parent = header

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 400, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "👥 Team Collaboration Hub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = header

    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -440, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 30)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Multi-user workspace management, real-time collaboration, and activity monitoring"
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = header

    -- Status indicator
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(0, 120, 0, 30)
    statusFrame.Position = UDim2.new(1, -140, 0, 15)
    statusFrame.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = header

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 15)
    statusCorner.Parent = statusFrame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 1, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🟢 Online"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = statusFrame
end

function TeamCollaboration:createActiveTeamSection(parent)
    local section = self:createSection(parent, "Active Team Members", "Real-time presence and collaboration status", 0)
    
    -- Team members grid
    local membersGrid = Instance.new("Frame")
    membersGrid.Name = "MembersGrid"
    membersGrid.Size = UDim2.new(1, -40, 0, 120)
    membersGrid.Position = UDim2.new(0, 20, 0, 60)
    membersGrid.BackgroundTransparency = 1
    membersGrid.Parent = section

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 180, 0, 100)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = membersGrid

    -- Get team members data
    local teamMembers = self:getTeamMembersData()
    
    for i, member in ipairs(teamMembers) do
        self:createMemberCard(membersGrid, member, i)
    end
end

function TeamCollaboration:createMemberCard(parent, member, index)
    local card = Instance.new("Frame")
    card.Name = "MemberCard" .. index
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    -- Status indicator
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 12, 0, 12)
    statusDot.Position = UDim2.new(1, -20, 0, 8)
    statusDot.BackgroundColor3 = member.status == "online" and Color3.fromRGB(34, 197, 94) or 
                                 member.status == "away" and Color3.fromRGB(245, 158, 11) or
                                 Color3.fromRGB(107, 114, 128)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 6)
    dotCorner.Parent = statusDot

    -- Avatar
    local avatar = Instance.new("TextLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 30, 0, 30)
    avatar.Position = UDim2.new(0, 10, 0, 10)
    avatar.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    avatar.BorderSizePixel = 0
    avatar.Text = member.avatar or "👤"
    avatar.TextColor3 = Color3.fromRGB(255, 255, 255)
    avatar.TextSize = 16
    avatar.Font = Enum.Font.Gotham
    avatar.Parent = card

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 15)
    avatarCorner.Parent = avatar

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -50, 0, 20)
    nameLabel.Position = UDim2.new(0, 45, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = member.name or "Unknown User"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = card

    -- Role
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Size = UDim2.new(1, -50, 0, 15)
    roleLabel.Position = UDim2.new(0, 45, 0, 28)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = member.role or "Member"
    roleLabel.TextColor3 = Color3.fromRGB(168, 85, 247)
    roleLabel.TextSize = 10
    roleLabel.TextXAlignment = Enum.TextXAlignment.Left
    roleLabel.Font = Enum.Font.Gotham
    roleLabel.Parent = card

    -- Current activity
    local activityLabel = Instance.new("TextLabel")
    activityLabel.Name = "ActivityLabel"
    activityLabel.Size = UDim2.new(1, -20, 0, 15)
    activityLabel.Position = UDim2.new(0, 10, 0, 50)
    activityLabel.BackgroundTransparency = 1
    activityLabel.Text = member.activity or "Idle"
    activityLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    activityLabel.TextSize = 9
    activityLabel.TextXAlignment = Enum.TextXAlignment.Left
    activityLabel.Font = Enum.Font.Gotham
    activityLabel.Parent = card

    -- Last seen
    local lastSeenLabel = Instance.new("TextLabel")
    lastSeenLabel.Name = "LastSeenLabel"
    lastSeenLabel.Size = UDim2.new(1, -20, 0, 15)
    lastSeenLabel.Position = UDim2.new(0, 10, 0, 70)
    lastSeenLabel.BackgroundTransparency = 1
    lastSeenLabel.Text = "Last seen: " .. (member.lastSeen or "now")
    lastSeenLabel.TextColor3 = Color3.fromRGB(107, 114, 128)
    lastSeenLabel.TextSize = 8
    lastSeenLabel.TextXAlignment = Enum.TextXAlignment.Left
    lastSeenLabel.Font = Enum.Font.Gotham
    lastSeenLabel.Parent = card
end

function TeamCollaboration:createWorkspaceSection(parent)
    local section = self:createSection(parent, "Shared Workspaces", "Manage collaborative workspaces and permissions", 200)
    
    -- Workspace controls
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "WorkspaceControls"
    controlsFrame.Size = UDim2.new(1, -40, 0, 40)
    controlsFrame.Position = UDim2.new(0, 20, 0, 60)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = section

    -- Create workspace button
    local createButton = self:createButton(controlsFrame, "➕ Create Workspace", UDim2.new(0, 150, 0, 30), UDim2.new(0, 0, 0, 5))
    createButton.MouseButton1Click:Connect(function()
        self:showCreateWorkspaceDialog()
    end)

    -- Invite users button
    local inviteButton = self:createButton(controlsFrame, "👥 Invite Users", UDim2.new(0, 120, 0, 30), UDim2.new(0, 160, 0, 5))
    inviteButton.MouseButton1Click:Connect(function()
        self:showInviteUsersDialog()
    end)

    -- Workspaces list
    local workspacesList = Instance.new("ScrollingFrame")
    workspacesList.Name = "WorkspacesList"
    workspacesList.Size = UDim2.new(1, -40, 0, 120)
    workspacesList.Position = UDim2.new(0, 20, 0, 110)
    workspacesList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    workspacesList.BorderSizePixel = 0
    workspacesList.ScrollBarThickness = 6
    workspacesList.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    workspacesList.CanvasSize = UDim2.new(0, 0, 0, 0)
    workspacesList.Parent = section

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = workspacesList

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = workspacesList

    -- Get workspaces data
    local workspaces = self:getWorkspacesData()
    
    for i, workspace in ipairs(workspaces) do
        self:createWorkspaceItem(workspacesList, workspace, i)
    end

    -- Update canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        workspacesList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
end

function TeamCollaboration:createWorkspaceItem(parent, workspace, index)
    local item = Instance.new("Frame")
    item.Name = "WorkspaceItem" .. index
    item.Size = UDim2.new(1, 0, 0, 50)
    item.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    item.BorderSizePixel = 0
    item.LayoutOrder = index
    item.Parent = parent

    -- Workspace icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    icon.BorderSizePixel = 0
    icon.Text = "🏢"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 14
    icon.Font = Enum.Font.Gotham
    icon.Parent = item

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = icon

    -- Workspace name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 200, 0, 20)
    nameLabel.Position = UDim2.new(0, 50, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = workspace.name or "Unnamed Workspace"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = item

    -- Members count
    local membersLabel = Instance.new("TextLabel")
    membersLabel.Name = "MembersLabel"
    membersLabel.Size = UDim2.new(0, 150, 0, 15)
    membersLabel.Position = UDim2.new(0, 50, 0, 28)
    membersLabel.BackgroundTransparency = 1
    membersLabel.Text = string.format("%d members • %s activity", workspace.members or 1, workspace.activity or "low")
    membersLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    membersLabel.TextSize = 10
    membersLabel.TextXAlignment = Enum.TextXAlignment.Left
    membersLabel.Font = Enum.Font.Gotham
    membersLabel.Parent = item

    -- Status indicator
    local statusColor = workspace.activity == "high" and Color3.fromRGB(34, 197, 94) or
                       workspace.activity == "medium" and Color3.fromRGB(245, 158, 11) or
                       Color3.fromRGB(107, 114, 128)

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -20, 0, 21)
    statusDot.BackgroundColor3 = statusColor
    statusDot.BorderSizePixel = 0
    statusDot.Parent = item

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusDot

    -- Click handler
    local button = Instance.new("TextButton")
    button.Name = "ClickHandler"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = item

    button.MouseButton1Click:Connect(function()
        self:selectWorkspace(workspace)
    end)
end

function TeamCollaboration:createActivityFeedSection(parent)
    local section = self:createSection(parent, "Team Activity Feed", "Real-time collaboration events and notifications", 400)
    
    -- Activity feed
    local activityFeed = Instance.new("ScrollingFrame")
    activityFeed.Name = "ActivityFeed"
    activityFeed.Size = UDim2.new(1, -40, 0, 150)
    activityFeed.Position = UDim2.new(0, 20, 0, 60)
    activityFeed.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    activityFeed.BorderSizePixel = 0
    activityFeed.ScrollBarThickness = 6
    activityFeed.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    activityFeed.CanvasSize = UDim2.new(0, 0, 0, 0)
    activityFeed.Parent = section

    local feedCorner = Instance.new("UICorner")
    feedCorner.CornerRadius = UDim.new(0, 8)
    feedCorner.Parent = activityFeed

    local feedLayout = Instance.new("UIListLayout")
    feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
    feedLayout.Padding = UDim.new(0, 1)
    feedLayout.Parent = activityFeed

    -- Get activity data
    local activities = self:getActivityData()
    
    for i, activity in ipairs(activities) do
        self:createActivityItem(activityFeed, activity, i)
    end

    -- Update canvas size
    feedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        activityFeed.CanvasSize = UDim2.new(0, 0, 0, feedLayout.AbsoluteContentSize.Y)
    end)
end

function TeamCollaboration:createActivityItem(parent, activity, index)
    local item = Instance.new("Frame")
    item.Name = "ActivityItem" .. index
    item.Size = UDim2.new(1, 0, 0, 40)
    item.BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(28, 28, 28)
    item.BorderSizePixel = 0
    item.LayoutOrder = index
    item.Parent = parent

    -- Activity icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Position = UDim2.new(0, 10, 0, 7)
    icon.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    icon.BorderSizePixel = 0
    icon.Text = activity.icon or "📝"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 12
    icon.Font = Enum.Font.Gotham
    icon.Parent = item

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 12)
    iconCorner.Parent = icon

    -- Activity description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -120, 0, 20)
    description.Position = UDim2.new(0, 45, 0, 5)
    description.BackgroundTransparency = 1
    description.Text = activity.description or "Unknown activity"
    description.TextColor3 = Color3.fromRGB(255, 255, 255)
    description.TextSize = 11
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Font = Enum.Font.Gotham
    description.Parent = item

    -- Timestamp
    local timestamp = Instance.new("TextLabel")
    timestamp.Name = "Timestamp"
    timestamp.Size = UDim2.new(0, 100, 0, 15)
    timestamp.Position = UDim2.new(1, -110, 0, 5)
    timestamp.BackgroundTransparency = 1
    timestamp.Text = activity.timestamp or "now"
    timestamp.TextColor3 = Color3.fromRGB(107, 114, 128)
    timestamp.TextSize = 9
    timestamp.TextXAlignment = Enum.TextXAlignment.Right
    timestamp.Font = Enum.Font.Gotham
    timestamp.Parent = item

    -- User
    local user = Instance.new("TextLabel")
    user.Name = "User"
    user.Size = UDim2.new(1, -120, 0, 15)
    user.Position = UDim2.new(0, 45, 0, 22)
    user.BackgroundTransparency = 1
    user.Text = "by " .. (activity.user or "Unknown")
    user.TextColor3 = Color3.fromRGB(180, 180, 180)
    user.TextSize = 9
    user.TextXAlignment = Enum.TextXAlignment.Left
    user.Font = Enum.Font.Gotham
    user.Parent = item
end

function TeamCollaboration:createCollaborationToolsSection(parent)
    local section = self:createSection(parent, "Collaboration Tools", "Real-time editing, conflict resolution, and sync controls", 600)
    
    -- Tools grid
    local toolsGrid = Instance.new("Frame")
    toolsGrid.Name = "ToolsGrid"
    toolsGrid.Size = UDim2.new(1, -40, 0, 100)
    toolsGrid.Position = UDim2.new(0, 20, 0, 60)
    toolsGrid.BackgroundTransparency = 1
    toolsGrid.Parent = section

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 150, 0, 80)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = toolsGrid

    -- Collaboration tools
    local tools = {
        {name = "Real-Time Sync", icon = "🔄", description = "Enable live collaboration", status = "active"},
        {name = "Conflict Resolution", icon = "⚖️", description = "Manage data conflicts", status = "monitoring"},
        {name = "Version Control", icon = "📋", description = "Track changes", status = "enabled"},
        {name = "Session Management", icon = "👥", description = "Manage user sessions", status = "active"}
    }

    for i, tool in ipairs(tools) do
        self:createToolCard(toolsGrid, tool, i)
    end
end

function TeamCollaboration:createToolCard(parent, tool, index)
    local card = Instance.new("Frame")
    card.Name = "ToolCard" .. index
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    -- Tool icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = tool.icon
    icon.TextColor3 = Color3.fromRGB(59, 130, 246)
    icon.TextSize = 18
    icon.Font = Enum.Font.Gotham
    icon.Parent = card

    -- Tool name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -50, 0, 20)
    nameLabel.Position = UDim2.new(0, 10, 0, 45)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = tool.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 11
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = card

    -- Status indicator
    local statusColor = tool.status == "active" and Color3.fromRGB(34, 197, 94) or
                       tool.status == "monitoring" and Color3.fromRGB(245, 158, 11) or
                       Color3.fromRGB(59, 130, 246)

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -15, 0, 10)
    statusDot.BackgroundColor3 = statusColor
    statusDot.BorderSizePixel = 0
    statusDot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 4)
    dotCorner.Parent = statusDot
end

function TeamCollaboration:createTeamStatsSection(parent)
    local section = self:createSection(parent, "Team Statistics", "Collaboration metrics and performance insights", 800)
    
    -- Stats grid
    local statsGrid = Instance.new("Frame")
    statsGrid.Name = "StatsGrid"
    statsGrid.Size = UDim2.new(1, -40, 0, 120)
    statsGrid.Position = UDim2.new(0, 20, 0, 60)
    statsGrid.BackgroundTransparency = 1
    statsGrid.Parent = section

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 180, 0, 100)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = statsGrid

    -- Get team statistics
    local stats = self:getTeamStats()
    
    for i, stat in ipairs(stats) do
        self:createStatCard(statsGrid, stat, i)
    end
end

function TeamCollaboration:createStatCard(parent, stat, index)
    local card = Instance.new("Frame")
    card.Name = "StatCard" .. index
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    -- Stat icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Position = UDim2.new(0, 15, 0, 15)
    icon.BackgroundTransparency = 1
    icon.Text = stat.icon
    icon.TextColor3 = stat.color
    icon.TextSize = 16
    icon.Font = Enum.Font.Gotham
    icon.Parent = card

    -- Stat value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(1, -50, 0, 25)
    valueLabel.Position = UDim2.new(0, 45, 0, 15)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = stat.value
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextSize = 18
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = card

    -- Stat label
    local labelText = Instance.new("TextLabel")
    labelText.Name = "LabelText"
    labelText.Size = UDim2.new(1, -20, 0, 20)
    labelText.Position = UDim2.new(0, 15, 0, 45)
    labelText.BackgroundTransparency = 1
    labelText.Text = stat.label
    labelText.TextColor3 = Color3.fromRGB(180, 180, 180)
    labelText.TextSize = 11
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.Parent = card

    -- Trend indicator
    if stat.trend then
        local trendLabel = Instance.new("TextLabel")
        trendLabel.Name = "TrendLabel"
        trendLabel.Size = UDim2.new(1, -20, 0, 15)
        trendLabel.Position = UDim2.new(0, 15, 0, 70)
        trendLabel.BackgroundTransparency = 1
        trendLabel.Text = stat.trend
        trendLabel.TextColor3 = stat.trend:find("↑") and Color3.fromRGB(34, 197, 94) or
                               stat.trend:find("↓") and Color3.fromRGB(239, 68, 68) or
                               Color3.fromRGB(107, 114, 128)
        trendLabel.TextSize = 9
        trendLabel.TextXAlignment = Enum.TextXAlignment.Left
        trendLabel.Font = Enum.Font.Gotham
        trendLabel.Parent = card
    end
end

-- Helper function to create sections
function TeamCollaboration:createSection(parent, title, subtitle, yOffset)
    local section = Instance.new("Frame")
    section.Name = title:gsub("%s+", "")
    section.Size = UDim2.new(1, 0, 0, 180)
    section.Position = UDim2.new(0, 0, 0, yOffset)
    section.BackgroundTransparency = 1
    section.Parent = parent

    -- Section header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    header.BorderSizePixel = 0
    header.Parent = section

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = header

    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, -20, 0, 15)
    subtitleLabel.Position = UDim2.new(0, 15, 0, 30)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitleLabel.TextSize = 10
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Parent = header

    return section
end

-- Helper function to create buttons
function TeamCollaboration:createButton(parent, text, size, position)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(79, 150, 255)
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    end)

    return button
end

-- Data retrieval functions
function TeamCollaboration:getTeamMembersData()
    local teamManager = self.services and self.services["features.collaboration.TeamManager"]
    
    if teamManager and teamManager.getTeamMembers then
        local members = teamManager:getTeamMembers()
        if members and #members > 0 then
            return members
        end
    end
    
    -- Default team members data
    return {
        {name = "Studio Developer", role = "Owner", status = "online", avatar = "👨‍💻", activity = "Editing DataStore schema", lastSeen = "now"},
        {name = "Team Lead", role = "Admin", status = "away", avatar = "👩‍💼", activity = "Reviewing analytics", lastSeen = "5 min ago"},
        {name = "Developer", role = "Editor", status = "online", avatar = "👨‍💻", activity = "Testing integrations", lastSeen = "now"},
        {name = "QA Tester", role = "Viewer", status = "offline", avatar = "🧪", activity = "Idle", lastSeen = "2 hours ago"}
    }
end

function TeamCollaboration:getWorkspacesData()
    local teamManager = self.services and self.services["features.collaboration.TeamManager"]
    
    if teamManager and teamManager.getWorkspaces then
        local workspaces = teamManager:getWorkspaces()
        if workspaces and #workspaces > 0 then
            return workspaces
        end
    end
    
    -- Default workspaces data
    return {
        {name = "Production DataStores", members = 4, activity = "high", lastModified = "2 min ago"},
        {name = "Development Environment", members = 2, activity = "medium", lastModified = "15 min ago"},
        {name = "Testing Workspace", members = 1, activity = "low", lastModified = "1 hour ago"}
    }
end

function TeamCollaboration:getActivityData()
    local teamManager = self.services and self.services["features.collaboration.TeamManager"]
    
    if teamManager and teamManager.getActivityFeed then
        local activities = teamManager:getActivityFeed(10)
        if activities and #activities > 0 then
            return activities
        end
    end
    
    -- Default activity data
    return {
        {icon = "📝", description = "Schema updated for PlayerData", user = "Studio Developer", timestamp = "2 min ago"},
        {icon = "👥", description = "Team Lead joined workspace", user = "System", timestamp = "5 min ago"},
        {icon = "🔄", description = "Real-time sync enabled", user = "Studio Developer", timestamp = "10 min ago"},
        {icon = "📊", description = "Analytics dashboard accessed", user = "Team Lead", timestamp = "15 min ago"},
        {icon = "🔍", description = "DataStore search performed", user = "Developer", timestamp = "20 min ago"},
        {icon = "⚙️", description = "Settings updated", user = "Studio Developer", timestamp = "25 min ago"}
    }
end

function TeamCollaboration:getTeamStats()
    local teamManager = self.services and self.services["features.collaboration.TeamManager"]
    
    if teamManager and teamManager.getCollaborationStats then
        local stats = teamManager:getCollaborationStats()
        if stats then
            return {
                {icon = "👥", value = tostring(stats.totalMembers or 4), label = "Team Members", color = Color3.fromRGB(59, 130, 246), trend = "↑ +1 this week"},
                {icon = "🏢", value = tostring(stats.totalWorkspaces or 3), label = "Active Workspaces", color = Color3.fromRGB(168, 85, 247), trend = "→ No change"},
                {icon = "📝", value = tostring(stats.totalActivities or 156), label = "Team Activities", color = Color3.fromRGB(34, 197, 94), trend = "↑ +23 today"},
                {icon = "🔄", value = tostring(stats.syncOperations or 89), label = "Sync Operations", color = Color3.fromRGB(245, 158, 11), trend = "↑ +12 today"}
            }
        end
    end
    
    -- Default stats
    return {
        {icon = "👥", value = "4", label = "Team Members", color = Color3.fromRGB(59, 130, 246), trend = "↑ +1 this week"},
        {icon = "🏢", value = "3", label = "Active Workspaces", color = Color3.fromRGB(168, 85, 247), trend = "→ No change"},
        {icon = "📝", value = "156", label = "Team Activities", color = Color3.fromRGB(34, 197, 94), trend = "↑ +23 today"},
        {icon = "🔄", value = "89", label = "Sync Operations", color = Color3.fromRGB(245, 158, 11), trend = "↑ +12 today"}
    }
end

-- Dialog functions
function TeamCollaboration:showCreateWorkspaceDialog()
    print("[TEAM_COLLABORATION] [INFO] Opening create workspace dialog")
    -- Implementation for workspace creation dialog
end

function TeamCollaboration:showInviteUsersDialog()
    print("[TEAM_COLLABORATION] [INFO] Opening invite users dialog")
    -- Implementation for user invitation dialog
end

function TeamCollaboration:selectWorkspace(workspace)
    print("[TEAM_COLLABORATION] [INFO] Selected workspace:", workspace.name)
    -- Implementation for workspace selection
end

-- Real-time updates
function TeamCollaboration:startRealTimeUpdates()
    if self.updateInterval then
        task.cancel(self.updateInterval)
    end
    
    self.updateInterval = task.spawn(function()
        while self.isActive do
            self:updateTeamData()
            task.wait(5) -- Update every 5 seconds
        end
    end)
    
    print("[TEAM_COLLABORATION] [INFO] Real-time updates started")
end

function TeamCollaboration:updateTeamData()
    -- Update team member presence
    -- Update activity feed
    -- Update workspace status
    -- This would integrate with the TeamManager service
end

function TeamCollaboration:cleanup()
    self.isActive = false
    
    if self.updateInterval then
        task.cancel(self.updateInterval)
        self.updateInterval = nil
    end
    
    print("[TEAM_COLLABORATION] [INFO] Team collaboration component cleanup completed")
end

return TeamCollaboration