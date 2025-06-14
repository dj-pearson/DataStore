-- DataStore Manager Pro - Real User Collaboration UI
-- User interface for real user management with invitation codes

local RealUserCollaboration = {}
RealUserCollaboration.__index = RealUserCollaboration

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

function RealUserCollaboration.new(services)
    local self = setmetatable({}, RealUserCollaboration)
    
    self.services = services
    self.isActive = true
    self.updateInterval = nil
    self.realUserManager = services and services["features.collaboration.RealUserManager"]
    self.currentUser = nil
    
    -- Initialize current user info
    if self.realUserManager and self.realUserManager.getCurrentUser then
        self.currentUser = self.realUserManager:getCurrentUser()
    end
    
    print("[REAL_USER_COLLABORATION] [INFO] Real User Collaboration component created")
    
    return self
end

function RealUserCollaboration:mount(parentFrame)
    self:clearContent(parentFrame)
    
    -- Create main container
    local mainContainer = Instance.new("ScrollingFrame")
    mainContainer.Name = "RealUserCollaborationContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    mainContainer.BorderSizePixel = 0
    mainContainer.ScrollBarThickness = 8
    mainContainer.CanvasSize = UDim2.new(0, 0, 0, 1200)
    mainContainer.Parent = parentFrame
    
    -- Create header section
    self:createHeaderSection(mainContainer)
    
    -- Create invitation code management section
    self:createInvitationSection(mainContainer)
    
    -- Create active users section
    self:createActiveUsersSection(mainContainer)
    
    -- Create user statistics section
    self:createUserStatsSection(mainContainer)
    
    -- Start real-time updates
    self:startRealTimeUpdates()
    
    print("[REAL_USER_COLLABORATION] [INFO] Real user collaboration interface mounted successfully")
end

function RealUserCollaboration:createHeaderSection(parent)
    -- Header container
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderSection"
    headerFrame.Size = UDim2.new(1, -40, 0, 120)
    headerFrame.Position = UDim2.new(0, 20, 0, 20)
    headerFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = headerFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 32)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "👥 Real User Collaboration"
    title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = headerFrame
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -40, 0, 48)
    description.Position = UDim2.new(0, 20, 0, 55)
    description.BackgroundTransparency = 1
    description.Text = "Manage real team members with invitation codes and role-based permissions.\nReplace fake data with actual user collaboration."
    description.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    description.TextSize = 14
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.TextWrapped = true
    description.Font = Enum.Font.Gotham
    description.Parent = headerFrame
end

function RealUserCollaboration:createInvitationSection(parent)
    -- Invitation section container
    local inviteFrame = Instance.new("Frame")
    inviteFrame.Name = "InvitationSection"
    inviteFrame.Size = UDim2.new(1, -40, 0, 280)
    inviteFrame.Position = UDim2.new(0, 20, 0, 160)
    inviteFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    inviteFrame.BorderSizePixel = 0
    inviteFrame.Parent = parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = inviteFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -40, 0, 28)
    sectionTitle.Position = UDim2.new(0, 20, 0, 15)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "🎟️ Generate Invitation Codes"
    sectionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = inviteFrame
    
    -- Role selection
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Size = UDim2.new(0, 100, 0, 30)
    roleLabel.Position = UDim2.new(0, 20, 0, 55)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = "Role:"
    roleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    roleLabel.TextSize = 14
    roleLabel.TextXAlignment = Enum.TextXAlignment.Left
    roleLabel.Font = Enum.Font.Gotham
    roleLabel.Parent = inviteFrame
    
    local roleDropdown = Instance.new("TextButton")
    roleDropdown.Name = "RoleDropdown"
    roleDropdown.Size = UDim2.new(0, 120, 0, 30)
    roleDropdown.Position = UDim2.new(0, 130, 0, 55)
    roleDropdown.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    roleDropdown.BorderSizePixel = 0
    roleDropdown.Text = "EDITOR ▼"
    roleDropdown.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    roleDropdown.TextSize = 12
    roleDropdown.Font = Enum.Font.Gotham
    roleDropdown.Parent = inviteFrame
    
    local roleCorner = Instance.new("UICorner")
    roleCorner.CornerRadius = UDim.new(0, 6)
    roleCorner.Parent = roleDropdown
    
    -- Expiry hours input
    local expiryLabel = Instance.new("TextLabel")
    expiryLabel.Name = "ExpiryLabel"
    expiryLabel.Size = UDim2.new(0, 100, 0, 30)
    expiryLabel.Position = UDim2.new(0, 270, 0, 55)
    expiryLabel.BackgroundTransparency = 1
    expiryLabel.Text = "Expires (hrs):"
    expiryLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    expiryLabel.TextSize = 14
    expiryLabel.TextXAlignment = Enum.TextXAlignment.Left
    expiryLabel.Font = Enum.Font.Gotham
    expiryLabel.Parent = inviteFrame
    
    local expiryInput = Instance.new("TextBox")
    expiryInput.Name = "ExpiryInput"
    expiryInput.Size = UDim2.new(0, 60, 0, 30)
    expiryInput.Position = UDim2.new(0, 380, 0, 55)
    expiryInput.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    expiryInput.BorderSizePixel = 0
    expiryInput.Text = "24"
    expiryInput.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    expiryInput.TextSize = 12
    expiryInput.Font = Enum.Font.Gotham
    expiryInput.PlaceholderText = "24"
    expiryInput.Parent = inviteFrame
    
    local expiryCorner = Instance.new("UICorner")
    expiryCorner.CornerRadius = UDim.new(0, 6)
    expiryCorner.Parent = expiryInput
    
    -- Generate button
    local generateButton = Instance.new("TextButton")
    generateButton.Name = "GenerateButton"
    generateButton.Size = UDim2.new(0, 140, 0, 35)
    generateButton.Position = UDim2.new(0, 20, 0, 100)
    generateButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    generateButton.BorderSizePixel = 0
    generateButton.Text = "🎟️ Generate Code"
    generateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    generateButton.TextSize = 14
    generateButton.Font = Enum.Font.GothamBold
    generateButton.Parent = inviteFrame
    
    local generateCorner = Instance.new("UICorner")
    generateCorner.CornerRadius = UDim.new(0, 8)
    generateCorner.Parent = generateButton
    
    -- Generated code display
    local codeDisplayFrame = Instance.new("Frame")
    codeDisplayFrame.Name = "CodeDisplay"
    codeDisplayFrame.Size = UDim2.new(1, -40, 0, 80)
    codeDisplayFrame.Position = UDim2.new(0, 20, 0, 150)
    codeDisplayFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    codeDisplayFrame.BorderSizePixel = 0
    codeDisplayFrame.Visible = false
    codeDisplayFrame.Parent = inviteFrame
    
    local codeCorner = Instance.new("UICorner")
    codeCorner.CornerRadius = UDim.new(0, 8)
    codeCorner.Parent = codeDisplayFrame
    
    local codeText = Instance.new("TextLabel")
    codeText.Name = "CodeText"
    codeText.Size = UDim2.new(1, -20, 0, 30)
    codeText.Position = UDim2.new(0, 10, 0, 10)
    codeText.BackgroundTransparency = 1
    codeText.Text = "Generated Code: ABC12345"
    codeText.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
    codeText.TextSize = 16
    codeText.TextXAlignment = Enum.TextXAlignment.Center
    codeText.Font = Enum.Font.GothamBold
    codeText.Parent = codeDisplayFrame
    
    local codeInstructions = Instance.new("TextLabel")
    codeInstructions.Name = "Instructions"
    codeInstructions.Size = UDim2.new(1, -20, 0, 35)
    codeInstructions.Position = UDim2.new(0, 10, 0, 40)
    codeInstructions.BackgroundTransparency = 1
    codeInstructions.Text = "Share this code with team members. They can use it to join your workspace."
    codeInstructions.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    codeInstructions.TextSize = 12
    codeInstructions.TextXAlignment = Enum.TextXAlignment.Center
    codeInstructions.TextWrapped = true
    codeInstructions.Font = Enum.Font.Gotham
    codeInstructions.Parent = codeDisplayFrame
    
    -- Connect generate button
    generateButton.MouseButton1Click:Connect(function()
        self:generateInvitationCode(roleDropdown, expiryInput, codeDisplayFrame, codeText)
    end)
    
    -- Role dropdown functionality
    local selectedRole = "EDITOR"
    local isDropdownOpen = false
    
    roleDropdown.MouseButton1Click:Connect(function()
        if isDropdownOpen then return end
        isDropdownOpen = true
        
        local roles = {"ADMIN", "EDITOR", "VIEWER", "GUEST"}
        local dropdownMenu = Instance.new("Frame")
        dropdownMenu.Name = "DropdownMenu"
        dropdownMenu.Size = UDim2.new(0, 120, 0, #roles * 25)
        dropdownMenu.Position = UDim2.new(0, 0, 1, 2)
        dropdownMenu.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
        dropdownMenu.BorderSizePixel = 1
        dropdownMenu.BorderColor3 = Constants.UI.THEME.COLORS.BORDER
        dropdownMenu.Parent = roleDropdown
        dropdownMenu.ZIndex = 10
        
        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0, 6)
        menuCorner.Parent = dropdownMenu
        
        for i, role in ipairs(roles) do
            local roleOption = Instance.new("TextButton")
            roleOption.Name = "RoleOption_" .. role
            roleOption.Size = UDim2.new(1, 0, 0, 25)
            roleOption.Position = UDim2.new(0, 0, 0, (i-1) * 25)
            roleOption.BackgroundTransparency = 1
            roleOption.Text = role
            roleOption.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
            roleOption.TextSize = 12
            roleOption.Font = Enum.Font.Gotham
            roleOption.Parent = dropdownMenu
            
            roleOption.MouseButton1Click:Connect(function()
                selectedRole = role
                roleDropdown.Text = role .. " ▼"
                dropdownMenu:Destroy()
                isDropdownOpen = false
            end)
            
            roleOption.MouseEnter:Connect(function()
                roleOption.BackgroundTransparency = 0.9
                roleOption.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
            end)
            
            roleOption.MouseLeave:Connect(function()
                roleOption.BackgroundTransparency = 1
            end)
        end
        
        -- Close dropdown when clicking elsewhere
        task.wait(0.1)
        local connection
        connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dropdownMenu:Destroy()
                isDropdownOpen = false
                connection:Disconnect()
            end
        end)
    end)
end

function RealUserCollaboration:createActiveUsersSection(parent)
    -- Active users section
    local usersFrame = Instance.new("Frame")
    usersFrame.Name = "ActiveUsersSection"
    usersFrame.Size = UDim2.new(1, -40, 0, 300)
    usersFrame.Position = UDim2.new(0, 20, 0, 460)
    usersFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    usersFrame.BorderSizePixel = 0
    usersFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = usersFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -40, 0, 28)
    sectionTitle.Position = UDim2.new(0, 20, 0, 15)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "👥 Active Team Members"
    sectionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = usersFrame
    
    -- Users list
    local usersList = Instance.new("ScrollingFrame")
    usersList.Name = "UsersList"
    usersList.Size = UDim2.new(1, -40, 0, 240)
    usersList.Position = UDim2.new(0, 20, 0, 50)
    usersList.BackgroundTransparency = 1
    usersList.BorderSizePixel = 0
    usersList.ScrollBarThickness = 6
    usersList.CanvasSize = UDim2.new(0, 0, 0, 0)
    usersList.Parent = usersFrame
    
    -- Populate users list
    self:updateUsersList(usersList)
end

function RealUserCollaboration:createUserStatsSection(parent)
    -- User stats section
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "UserStatsSection"
    statsFrame.Size = UDim2.new(1, -40, 0, 150)
    statsFrame.Position = UDim2.new(0, 20, 0, 780)
    statsFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = statsFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -40, 0, 28)
    sectionTitle.Position = UDim2.new(0, 20, 0, 15)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "📊 User Statistics"
    sectionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = statsFrame
    
    -- Stats content
    local statsContent = Instance.new("Frame")
    statsContent.Name = "StatsContent"
    statsContent.Size = UDim2.new(1, -40, 0, 100)
    statsContent.Position = UDim2.new(0, 20, 0, 45)
    statsContent.BackgroundTransparency = 1
    statsContent.Parent = statsFrame
    
    -- Update stats
    self:updateUserStats(statsContent)
end

function RealUserCollaboration:generateInvitationCode(roleDropdown, expiryInput, codeDisplayFrame, codeText)
    if not self.realUserManager then
        print("[REAL_USER_COLLABORATION] [ERROR] Real User Manager not available")
        return
    end
    
    local selectedRole = string.match(roleDropdown.Text, "(%w+)")
    local expiryHours = tonumber(expiryInput.Text) or 24
    
    -- Get current user ID (root admin)
    local currentUserId = self.currentUser and self.currentUser.userId or "studio_user"
    
    local success, result = pcall(function()
        return self.realUserManager.createInvitationCode(currentUserId, selectedRole, expiryHours, 1)
    end)
    
    if success and result then
        -- Show the generated code
        codeText.Text = "Generated Code: " .. result
        codeDisplayFrame.Visible = true
        
        -- Auto-hide after 30 seconds
        task.spawn(function()
            task.wait(30)
            codeDisplayFrame.Visible = false
        end)
        
        print("[REAL_USER_COLLABORATION] [INFO] Invitation code generated: " .. result)
    else
        print("[REAL_USER_COLLABORATION] [ERROR] Failed to generate invitation code: " .. tostring(result))
        codeText.Text = "Error: " .. tostring(result)
        codeDisplayFrame.Visible = true
        codeText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
    end
end

function RealUserCollaboration:updateUsersList(usersList)
    -- Clear existing users
    for _, child in pairs(usersList:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("UserCard_") then
            child:Destroy()
        end
    end
    
    if not self.realUserManager then
        return
    end
    
    local users = {}
    local success, result = pcall(function()
        return self.realUserManager.getActiveUsers()
    end)
    
    if success and result then
        users = result
    end
    
    local yOffset = 0
    
    for i, user in ipairs(users) do
        local userCard = self:createUserCard(user, i)
        userCard.Position = UDim2.new(0, 0, 0, yOffset)
        userCard.Parent = usersList
        
        yOffset = yOffset + 70
    end
    
    -- Update canvas size
    usersList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function RealUserCollaboration:createUserCard(user, index)
    local userCard = Instance.new("Frame")
    userCard.Name = "UserCard_" .. index
    userCard.Size = UDim2.new(1, -10, 0, 60)
    userCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    userCard.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = userCard
    
    -- Status indicator
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 12, 0, 12)
    statusDot.Position = UDim2.new(0, 15, 0, 24)
    statusDot.BackgroundColor3 = user.status == "online" and Color3.fromRGB(34, 197, 94) or 
                                   user.status == "away" and Color3.fromRGB(245, 158, 11) or 
                                   Color3.fromRGB(156, 163, 175)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = userCard
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0.5, 0)
    dotCorner.Parent = statusDot
    
    -- User name
    local userName = Instance.new("TextLabel")
    userName.Name = "UserName"
    userName.Size = UDim2.new(0, 200, 0, 20)
    userName.Position = UDim2.new(0, 35, 0, 10)
    userName.BackgroundTransparency = 1
    userName.Text = user.userName .. (user.isRootAdmin and " 👑" or "")
    userName.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    userName.TextSize = 14
    userName.TextXAlignment = Enum.TextXAlignment.Left
    userName.Font = Enum.Font.GothamBold
    userName.Parent = userCard
    
    -- User role
    local userRole = Instance.new("TextLabel")
    userRole.Name = "UserRole"
    userRole.Size = UDim2.new(0, 200, 0, 16)
    userRole.Position = UDim2.new(0, 35, 0, 32)
    userRole.BackgroundTransparency = 1
    userRole.Text = user.role .. " • " .. user.status
    userRole.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    userRole.TextSize = 12
    userRole.TextXAlignment = Enum.TextXAlignment.Left
    userRole.Font = Enum.Font.Gotham
    userRole.Parent = userCard
    
    -- Last seen
    local lastSeen = Instance.new("TextLabel")
    lastSeen.Name = "LastSeen"
    lastSeen.Size = UDim2.new(0, 150, 0, 16)
    lastSeen.Position = UDim2.new(1, -165, 0, 32)
    lastSeen.BackgroundTransparency = 1
    lastSeen.Text = self:formatLastSeen(user.lastActive)
    lastSeen.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    lastSeen.TextSize = 11
    lastSeen.TextXAlignment = Enum.TextXAlignment.Right
    lastSeen.Font = Enum.Font.Gotham
    lastSeen.Parent = userCard
    
    -- Action buttons (for non-root admin users)
    if not user.isRootAdmin then
        local actionButton = Instance.new("TextButton")
        actionButton.Name = "ActionButton"
        actionButton.Size = UDim2.new(0, 80, 0, 25)
        actionButton.Position = UDim2.new(1, -95, 0, 5)
        actionButton.BackgroundColor3 = Constants.UI.THEME.COLORS.WARNING
        actionButton.BorderSizePixel = 0
        actionButton.Text = "Manage"
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.TextSize = 11
        actionButton.Font = Enum.Font.Gotham
        actionButton.Parent = userCard
        
        local actionCorner = Instance.new("UICorner")
        actionCorner.CornerRadius = UDim.new(0, 4)
        actionCorner.Parent = actionButton
        
        actionButton.MouseButton1Click:Connect(function()
            self:showUserManagementDialog(user)
        end)
    end
    
    return userCard
end

function RealUserCollaboration:updateUserStats(statsContent)
    -- Clear existing stats
    for _, child in pairs(statsContent:GetChildren()) do
        child:Destroy()
    end
    
    local stats = {totalUsers = 1, onlineUsers = 1, byRole = {OWNER = 1}, activeInvitations = 0}
    
    if self.realUserManager then
        local success, result = pcall(function()
            return self.realUserManager.getUserStats()
        end)
        
        if success and result then
            stats = result
        end
    end
    
    -- Create stat cards
    local statCards = {
        {label = "Total Users", value = tostring(stats.totalUsers), icon = "👥", color = Constants.UI.THEME.COLORS.PRIMARY},
        {label = "Online Users", value = tostring(stats.onlineUsers), icon = "🟢", color = Constants.UI.THEME.COLORS.SUCCESS},
        {label = "Active Invites", value = tostring(stats.activeInvitations), icon = "🎟️", color = Constants.UI.THEME.COLORS.WARNING}
    }
    
    for i, stat in ipairs(statCards) do
        local statCard = Instance.new("Frame")
        statCard.Name = "StatCard_" .. i
        statCard.Size = UDim2.new(0, 150, 0, 80)
        statCard.Position = UDim2.new(0, (i-1) * 160, 0, 10)
        statCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
        statCard.BorderSizePixel = 0
        statCard.Parent = statsContent
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = statCard
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 30, 0, 30)
        icon.Position = UDim2.new(0, 15, 0, 10)
        icon.BackgroundTransparency = 1
        icon.Text = stat.icon
        icon.TextSize = 18
        icon.Parent = statCard
        
        -- Value
        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.Size = UDim2.new(0, 80, 0, 25)
        value.Position = UDim2.new(0, 55, 0, 10)
        value.BackgroundTransparency = 1
        value.Text = stat.value
        value.TextColor3 = stat.color
        value.TextSize = 20
        value.TextXAlignment = Enum.TextXAlignment.Left
        value.Font = Enum.Font.GothamBold
        value.Parent = statCard
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 50)
        label.BackgroundTransparency = 1
        label.Text = stat.label
        label.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = statCard
    end
end

function RealUserCollaboration:formatLastSeen(timestamp)
    local currentTime = os.time()
    local timeDiff = currentTime - timestamp
    
    if timeDiff < 60 then
        return "Just now"
    elseif timeDiff < 3600 then
        return math.floor(timeDiff / 60) .. "m ago"
    elseif timeDiff < 86400 then
        return math.floor(timeDiff / 3600) .. "h ago"
    else
        return math.floor(timeDiff / 86400) .. "d ago"
    end
end

function RealUserCollaboration:showUserManagementDialog(user)
    print("[REAL_USER_COLLABORATION] [INFO] Opening user management for: " .. user.userName)
    -- This would show a dialog for changing roles, removing users, etc.
    -- Implementation would create a modal dialog with role change options
end

function RealUserCollaboration:clearContent(parent)
    for _, child in pairs(parent:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
end

function RealUserCollaboration:startRealTimeUpdates()
    if self.updateInterval then
        task.cancel(self.updateInterval)
    end
    
    self.updateInterval = task.spawn(function()
        while self.isActive do
            -- Find and update users list and stats
            local gui = game:GetService("CoreGui"):FindFirstChild("DataStoreManagerPro")
            if gui then
                local usersList = gui:FindFirstChild("UsersList", true)
                local statsContent = gui:FindFirstChild("StatsContent", true)
                
                if usersList then
                    self:updateUsersList(usersList)
                end
                
                if statsContent then
                    self:updateUserStats(statsContent)
                end
            end
            
            task.wait(5) -- Update every 5 seconds
        end
    end)
    
    print("[REAL_USER_COLLABORATION] [INFO] Real-time updates started")
end

function RealUserCollaboration:cleanup()
    self.isActive = false
    
    if self.updateInterval then
        task.cancel(self.updateInterval)
        self.updateInterval = nil
    end
    
    print("[REAL_USER_COLLABORATION] [INFO] Real user collaboration component cleanup completed")
end

return RealUserCollaboration