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
    mainContainer.CanvasSize = UDim2.new(0, 0, 0, 2000)
    mainContainer.Parent = parentFrame
    
    -- Create header section
    self:createHeaderSection(mainContainer)
    
    -- Create invitation code management section (for root admin)
    self:createInvitationSection(mainContainer)
    
    -- Create join team section (for users to enter codes)
    self:createJoinTeamSection(mainContainer)
    
    -- Create active users section
    self:createActiveUsersSection(mainContainer)
    
    -- Create role overview section
    self:createRoleOverviewSection(mainContainer)
    
    -- Create user management section (for root admin)
    self:createUserManagementSection(mainContainer)
    
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
        
        -- Get available roles from RealUserManager
        local availableRoles = {}
        if self.realUserManager and self.realUserManager.getAvailableRoles then
            local currentUserId = nil
            if self.realUserManager.getCurrentUser then
                local currentUser = self.realUserManager.getCurrentUser()
                if currentUser then
                    currentUserId = currentUser.userId
                end
            end
            
            if currentUserId then
                availableRoles = self.realUserManager.getAvailableRoles(currentUserId)
            end
        end
        
        -- Fallback roles if no real user manager
        if #availableRoles == 0 then
            availableRoles = {
                {name = "ADMIN", displayName = "Administrator", color = Color3.fromRGB(255, 140, 0)},
                {name = "EDITOR", displayName = "Editor", color = Color3.fromRGB(34, 139, 34)},
                {name = "VIEWER", displayName = "Viewer", color = Color3.fromRGB(70, 130, 180)},
                {name = "GUEST", displayName = "Guest", color = Color3.fromRGB(169, 169, 169)}
            }
        end
        
        local dropdownMenu = Instance.new("Frame")
        dropdownMenu.Name = "DropdownMenu"
        dropdownMenu.Size = UDim2.new(0, 160, 0, #availableRoles * 35)
        dropdownMenu.Position = UDim2.new(0, 0, 1, 2)
        dropdownMenu.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
        dropdownMenu.BorderSizePixel = 1
        dropdownMenu.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY or Color3.fromRGB(100, 100, 100)
        dropdownMenu.Parent = roleDropdown
        dropdownMenu.ZIndex = 10
        
        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0, 6)
        menuCorner.Parent = dropdownMenu
        
        for i, roleData in ipairs(availableRoles) do
            local roleOption = Instance.new("Frame")
            roleOption.Name = "RoleOption_" .. roleData.name
            roleOption.Size = UDim2.new(1, 0, 0, 35)
            roleOption.Position = UDim2.new(0, 0, 0, (i-1) * 35)
            roleOption.BackgroundTransparency = 1
            roleOption.Parent = dropdownMenu
            
            local roleButton = Instance.new("TextButton")
            roleButton.Name = "RoleButton"
            roleButton.Size = UDim2.new(1, 0, 1, 0)
            roleButton.Position = UDim2.new(0, 0, 0, 0)
            roleButton.BackgroundTransparency = 1
            roleButton.Text = ""
            roleButton.Parent = roleOption
            
            -- Role color indicator
            local colorIndicator = Instance.new("Frame")
            colorIndicator.Name = "ColorIndicator"
            colorIndicator.Size = UDim2.new(0, 4, 0, 20)
            colorIndicator.Position = UDim2.new(0, 8, 0, 8)
            colorIndicator.BackgroundColor3 = roleData.color or Constants.UI.THEME.COLORS.PRIMARY
            colorIndicator.BorderSizePixel = 0
            colorIndicator.Parent = roleOption
            
            local indicatorCorner = Instance.new("UICorner")
            indicatorCorner.CornerRadius = UDim.new(0, 2)
            indicatorCorner.Parent = colorIndicator
            
            -- Role name
            local roleName = Instance.new("TextLabel")
            roleName.Name = "RoleName"
            roleName.Size = UDim2.new(1, -20, 0, 18)
            roleName.Position = UDim2.new(0, 18, 0, 4)
            roleName.BackgroundTransparency = 1
            roleName.Text = roleData.displayName or roleData.name
            roleName.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
            roleName.TextSize = 12
            roleName.TextXAlignment = Enum.TextXAlignment.Left
            roleName.Font = Enum.Font.GothamBold
            roleName.Parent = roleOption
            
            -- Role description
            local roleDesc = Instance.new("TextLabel")
            roleDesc.Name = "RoleDescription"
            roleDesc.Size = UDim2.new(1, -20, 0, 12)
            roleDesc.Position = UDim2.new(0, 18, 0, 20)
            roleDesc.BackgroundTransparency = 1
            roleDesc.Text = roleData.description or "Role permissions"
            roleDesc.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
            roleDesc.TextSize = 10
            roleDesc.TextXAlignment = Enum.TextXAlignment.Left
            roleDesc.Font = Enum.Font.Gotham
            roleDesc.Parent = roleOption
            
            roleButton.MouseButton1Click:Connect(function()
                selectedRole = roleData.name
                roleDropdown.Text = (roleData.displayName or roleData.name) .. " ▼"
                dropdownMenu:Destroy()
                isDropdownOpen = false
            end)
            
            roleButton.MouseEnter:Connect(function()
                roleOption.BackgroundTransparency = 0.9
                roleOption.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
            end)
            
            roleButton.MouseLeave:Connect(function()
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
    usersFrame.Position = UDim2.new(0, 20, 0, 680)
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
    statsFrame.Position = UDim2.new(0, 20, 0, 1620)
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
        codeText.Text = "Error: Real User Manager not available"
        codeDisplayFrame.Visible = true
        codeText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        return
    end
    
    -- Extract role from dropdown text (handle both "ROLE ▼" and "Display Name ▼" formats)
    local selectedRole = nil
    local dropdownText = roleDropdown.Text
    
    -- Remove the dropdown arrow
    dropdownText = string.gsub(dropdownText, " ▼", "")
    
    -- Try to match against role names first
    local roleNames = {"OWNER", "ADMIN", "EDITOR", "VIEWER", "GUEST"}
    for _, roleName in ipairs(roleNames) do
        if string.upper(dropdownText) == roleName then
            selectedRole = roleName
            break
        end
    end
    
    -- If not found, try to match against display names
    if not selectedRole then
        local roleConfigs = {}
        if self.realUserManager and self.realUserManager.getAllRoleConfigs then
            roleConfigs = self.realUserManager.getAllRoleConfigs()
        end
        
        for roleName, config in pairs(roleConfigs) do
            if config.displayName and config.displayName == dropdownText then
                selectedRole = roleName
                break
            end
        end
    end
    
    -- Validation
    if not selectedRole then
        print("[REAL_USER_COLLABORATION] [ERROR] No valid role selected: " .. tostring(dropdownText))
        codeText.Text = "Error: Please select a valid role first"
        codeDisplayFrame.Visible = true
        codeText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        return
    end
    
    local expiryHours = tonumber(expiryInput.Text) or 24
    
    -- Validate expiry hours
    if expiryHours <= 0 or expiryHours > 168 then -- Max 1 week
        print("[REAL_USER_COLLABORATION] [ERROR] Invalid expiry hours: " .. tostring(expiryHours))
        codeText.Text = "Error: Expiry hours must be between 1 and 168 (1 week)"
        codeDisplayFrame.Visible = true
        codeText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        return
    end
    
    -- Get current user ID (root admin) - try multiple approaches
    local currentUserId = nil
    
    if self.currentUser and self.currentUser.userId then
        currentUserId = self.currentUser.userId
    else
        -- Try to get from real user manager
        local success, currentUser = pcall(function()
            return self.realUserManager.getCurrentUser()
        end)
        if success and currentUser and currentUser.userId then
            currentUserId = currentUser.userId
        else
            -- Fallback to root admin
            if self.realUserManager and self.realUserManager.userState and self.realUserManager.userState.rootAdmin then
                currentUserId = self.realUserManager.userState.rootAdmin.userId
            else
                currentUserId = "studio_user"
            end
        end
    end
    
    print("[REAL_USER_COLLABORATION] [DEBUG] Using user ID: " .. tostring(currentUserId))
    print("[REAL_USER_COLLABORATION] [DEBUG] Selected role: " .. tostring(selectedRole))
    print("[REAL_USER_COLLABORATION] [DEBUG] Expiry hours: " .. tostring(expiryHours))
    
    local success, code, errorMsg = pcall(function()
        return self.realUserManager.createInvitationCode(currentUserId, selectedRole, expiryHours, 1)
    end)
    
    if success and code then
        -- Show the generated code
        codeText.Text = "Generated Code: " .. tostring(code)
        codeText.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
        codeDisplayFrame.Visible = true
        
        -- Reset the role dropdown for next code generation
        roleDropdown.Text = "Select Role ▼"
        
        -- Auto-hide after 30 seconds for security
        task.spawn(function()
            task.wait(30)
            if codeDisplayFrame and codeDisplayFrame.Parent then
                codeDisplayFrame.Visible = false
            end
        end)
        
        print("[REAL_USER_COLLABORATION] [INFO] Invitation code generated: " .. tostring(code))
    else
        local errorMessage = errorMsg or code or "Unknown error"
        print("[REAL_USER_COLLABORATION] [ERROR] Failed to generate invitation code: " .. tostring(errorMessage))
        codeText.Text = "Error: " .. tostring(errorMessage)
        codeDisplayFrame.Visible = true
        codeText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        
        -- Auto-hide error after 10 seconds
        task.spawn(function()
            task.wait(10)
            if codeDisplayFrame and codeDisplayFrame.Parent then
                codeDisplayFrame.Visible = false
            end
        end)
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
    
    -- Create modal overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "UserManagementOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 1000
    overlay.Parent = game:GetService("CoreGui"):FindFirstChild("DataStoreManagerPro")
    
    -- Create dialog
    local dialog = Instance.new("Frame")
    dialog.Name = "UserManagementDialog"
    dialog.Size = UDim2.new(0, 500, 0, 400)
    dialog.Position = UDim2.new(0.5, -250, 0.5, -200)
    dialog.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 1001
    dialog.Parent = overlay
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 12)
    dialogCorner.Parent = dialog
    
    -- Dialog title
    local title = Instance.new("TextLabel")
    title.Name = "DialogTitle"
    title.Size = UDim2.new(1, -60, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "👥 Manage User: " .. user.userName
    title.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = dialog
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 15)
    closeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = dialog
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- User info section
    local userInfo = Instance.new("Frame")
    userInfo.Name = "UserInfo"
    userInfo.Size = UDim2.new(1, -40, 0, 80)
    userInfo.Position = UDim2.new(0, 20, 0, 70)
    userInfo.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    userInfo.BorderSizePixel = 0
    userInfo.Parent = dialog
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = userInfo
    
    -- Current role display
    local currentRoleLabel = Instance.new("TextLabel")
    currentRoleLabel.Name = "CurrentRoleLabel"
    currentRoleLabel.Size = UDim2.new(1, -20, 0, 25)
    currentRoleLabel.Position = UDim2.new(0, 10, 0, 10)
    currentRoleLabel.BackgroundTransparency = 1
    currentRoleLabel.Text = "Current Role: " .. (user.role or "GUEST")
    currentRoleLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    currentRoleLabel.TextSize = 14
    currentRoleLabel.TextXAlignment = Enum.TextXAlignment.Left
    currentRoleLabel.Font = Enum.Font.GothamBold
    currentRoleLabel.Parent = userInfo
    
    -- User details
    local userDetails = Instance.new("TextLabel")
    userDetails.Name = "UserDetails"
    userDetails.Size = UDim2.new(1, -20, 0, 40)
    userDetails.Position = UDim2.new(0, 10, 0, 35)
    userDetails.BackgroundTransparency = 1
    userDetails.Text = "User ID: " .. (user.userId or "Unknown") .. "\nJoined: " .. self:formatLastSeen(user.joinedAt or os.time())
    userDetails.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    userDetails.TextSize = 12
    userDetails.TextXAlignment = Enum.TextXAlignment.Left
    userDetails.TextYAlignment = Enum.TextYAlignment.Top
    userDetails.Font = Enum.Font.Gotham
    userDetails.Parent = userInfo
    
    -- Role change section
    local roleChangeTitle = Instance.new("TextLabel")
    roleChangeTitle.Name = "RoleChangeTitle"
    roleChangeTitle.Size = UDim2.new(1, -40, 0, 25)
    roleChangeTitle.Position = UDim2.new(0, 20, 0, 170)
    roleChangeTitle.BackgroundTransparency = 1
    roleChangeTitle.Text = "🎭 Change Role:"
    roleChangeTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    roleChangeTitle.TextSize = 16
    roleChangeTitle.TextXAlignment = Enum.TextXAlignment.Left
    roleChangeTitle.Font = Enum.Font.GothamBold
    roleChangeTitle.Parent = dialog
    
    -- Role dropdown
    local roleDropdown = Instance.new("TextButton")
    roleDropdown.Name = "RoleDropdown"
    roleDropdown.Size = UDim2.new(0, 200, 0, 35)
    roleDropdown.Position = UDim2.new(0, 20, 0, 200)
    roleDropdown.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    roleDropdown.BorderSizePixel = 0
    roleDropdown.Text = "Select New Role ▼"
    roleDropdown.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    roleDropdown.TextSize = 12
    roleDropdown.Font = Enum.Font.Gotham
    roleDropdown.Parent = dialog
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = roleDropdown
    
    local selectedRole = nil
    local isDropdownOpen = false
    
    -- Get available roles for the current user
    local availableRoles = {}
    if self.realUserManager and self.realUserManager.getAvailableRoles then
        local currentUser = self.realUserManager.getCurrentUser()
        if currentUser then
            availableRoles = self.realUserManager.getAvailableRoles(currentUser.userId)
        end
    end
    
    -- Fallback roles if service not available
    if not availableRoles or #availableRoles == 0 then
        availableRoles = {
            {name = "ADMIN", displayName = "Administrator", description = "Can manage team and perform most operations"},
            {name = "EDITOR", displayName = "Editor", description = "Can read, write, and modify data structures"},
            {name = "VIEWER", displayName = "Viewer", description = "Read-only access to data and analytics"},
            {name = "GUEST", displayName = "Guest", description = "Limited access to basic data viewing"}
        }
    end
    
    -- Role dropdown click handler
    roleDropdown.MouseButton1Click:Connect(function()
        if isDropdownOpen then return end
        isDropdownOpen = true
        
        -- Create dropdown menu
        local dropdownMenu = Instance.new("Frame")
        dropdownMenu.Name = "RoleDropdownMenu"
        dropdownMenu.Size = UDim2.new(0, 200, 0, #availableRoles * 45 + 10)
        dropdownMenu.Position = UDim2.new(0, 20, 0, 240)
                 dropdownMenu.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
         dropdownMenu.BorderSizePixel = 1
         dropdownMenu.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY or Color3.fromRGB(100, 100, 100)
         dropdownMenu.ZIndex = 1002
         dropdownMenu.Parent = dialog
        
        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0, 6)
        menuCorner.Parent = dropdownMenu
        
        for i, roleData in ipairs(availableRoles) do
            local roleOption = Instance.new("Frame")
            roleOption.Name = "RoleOption_" .. roleData.name
            roleOption.Size = UDim2.new(1, -10, 0, 40)
            roleOption.Position = UDim2.new(0, 5, 0, (i-1) * 45 + 5)
            roleOption.BackgroundTransparency = 1
            roleOption.Parent = dropdownMenu
            
            local roleButton = Instance.new("TextButton")
            roleButton.Name = "RoleButton"
            roleButton.Size = UDim2.new(1, 0, 1, 0)
            roleButton.Position = UDim2.new(0, 0, 0, 0)
            roleButton.BackgroundTransparency = 1
            roleButton.Text = ""
            roleButton.Parent = roleOption
            
            -- Role name
            local roleName = Instance.new("TextLabel")
            roleName.Size = UDim2.new(1, -10, 0, 18)
            roleName.Position = UDim2.new(0, 5, 0, 4)
            roleName.BackgroundTransparency = 1
            roleName.Text = roleData.displayName or roleData.name
            roleName.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
            roleName.TextSize = 12
            roleName.TextXAlignment = Enum.TextXAlignment.Left
            roleName.Font = Enum.Font.GothamBold
            roleName.Parent = roleOption
            
            -- Role description
            local roleDesc = Instance.new("TextLabel")
            roleDesc.Size = UDim2.new(1, -10, 0, 15)
            roleDesc.Position = UDim2.new(0, 5, 0, 20)
            roleDesc.BackgroundTransparency = 1
            roleDesc.Text = roleData.description or "Role permissions"
            roleDesc.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
            roleDesc.TextSize = 10
            roleDesc.TextXAlignment = Enum.TextXAlignment.Left
            roleDesc.Font = Enum.Font.Gotham
            roleDesc.Parent = roleOption
            
            roleButton.MouseButton1Click:Connect(function()
                selectedRole = roleData.name
                roleDropdown.Text = (roleData.displayName or roleData.name) .. " ▼"
                dropdownMenu:Destroy()
                isDropdownOpen = false
            end)
            
            roleButton.MouseEnter:Connect(function()
                roleOption.BackgroundTransparency = 0.9
                roleOption.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
            end)
            
            roleButton.MouseLeave:Connect(function()
                roleOption.BackgroundTransparency = 1
            end)
        end
    end)
    
    -- Action buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -40, 0, 50)
    buttonContainer.Position = UDim2.new(0, 20, 0, 320)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    -- Change role button
    local changeRoleButton = Instance.new("TextButton")
    changeRoleButton.Name = "ChangeRoleButton"
    changeRoleButton.Size = UDim2.new(0, 120, 0, 35)
    changeRoleButton.Position = UDim2.new(0, 0, 0, 0)
    changeRoleButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
    changeRoleButton.BorderSizePixel = 0
    changeRoleButton.Text = "🎭 Change Role"
    changeRoleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeRoleButton.TextSize = 12
    changeRoleButton.Font = Enum.Font.GothamBold
    changeRoleButton.Parent = buttonContainer
    
    local changeCorner = Instance.new("UICorner")
    changeCorner.CornerRadius = UDim.new(0, 6)
    changeCorner.Parent = changeRoleButton
    
    -- Remove user button
    local removeButton = Instance.new("TextButton")
    removeButton.Name = "RemoveButton"
    removeButton.Size = UDim2.new(0, 120, 0, 35)
    removeButton.Position = UDim2.new(0, 140, 0, 0)
    removeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    removeButton.BorderSizePixel = 0
    removeButton.Text = "🗑️ Remove User"
    removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeButton.TextSize = 12
    removeButton.Font = Enum.Font.GothamBold
    removeButton.Parent = buttonContainer
    
    local removeCorner = Instance.new("UICorner")
    removeCorner.CornerRadius = UDim.new(0, 6)
    removeCorner.Parent = removeButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 100, 0, 35)
    cancelButton.Position = UDim2.new(1, -100, 0, 0)
    cancelButton.BackgroundColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    cancelButton.BorderSizePixel = 0
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextSize = 12
    cancelButton.Font = Enum.Font.Gotham
    cancelButton.Parent = buttonContainer
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelButton
    
         -- Status display for feedback
     local statusDisplay = Instance.new("TextLabel")
     statusDisplay.Name = "StatusDisplay"
     statusDisplay.Size = UDim2.new(1, -40, 0, 20)
     statusDisplay.Position = UDim2.new(0, 20, 0, 295)
     statusDisplay.BackgroundTransparency = 1
     statusDisplay.Text = ""
     statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
     statusDisplay.TextSize = 11
     statusDisplay.TextXAlignment = Enum.TextXAlignment.Center
     statusDisplay.Font = Enum.Font.Gotham
     statusDisplay.Visible = false
     statusDisplay.Parent = dialog
     
     -- Button handlers
     changeRoleButton.MouseButton1Click:Connect(function()
         -- Clear previous status
         statusDisplay.Visible = false
         
         if not selectedRole then
             statusDisplay.Text = "⚠️ Please select a role first"
             statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.WARNING
             statusDisplay.Visible = true
             print("[REAL_USER_COLLABORATION] [WARN] No role selected")
             return
         end
         
         if selectedRole == user.role then
             statusDisplay.Text = "ℹ️ User already has this role"
             statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
             statusDisplay.Visible = true
             print("[REAL_USER_COLLABORATION] [WARN] User already has this role")
             return
         end
         
         -- Show loading state
         statusDisplay.Text = "🔄 Changing role..."
         statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
         statusDisplay.Visible = true
         changeRoleButton.Text = "🔄 Changing..."
         changeRoleButton.BackgroundColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
         
         -- Change user role
         local success, result = pcall(function()
             local currentUser = self.realUserManager.getCurrentUser()
             if not currentUser then
                 return false, "Current user not found"
             end
             return self.realUserManager.changeUserRole(currentUser.userId, user.userId, selectedRole)
         end)
         
         if success and result then
             statusDisplay.Text = "✅ Role changed successfully!"
             statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
             print("[REAL_USER_COLLABORATION] [INFO] Role changed successfully for " .. user.userName)
             
             -- Close dialog after brief delay
             task.wait(1.5)
             overlay:Destroy()
             
             -- Refresh UI
             if self.refreshUI then
                 self:refreshUI()
             end
         else
             local errorMsg = tostring(result) or "Unknown error occurred"
             statusDisplay.Text = "❌ Failed: " .. errorMsg
             statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.ERROR
             
             -- Reset button
             changeRoleButton.Text = "🎭 Change Role"
             changeRoleButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
             
             print("[REAL_USER_COLLABORATION] [ERROR] Failed to change role: " .. errorMsg)
         end
     end)
    
         removeButton.MouseButton1Click:Connect(function()
         -- Clear previous status
         statusDisplay.Visible = false
         
         -- Confirmation dialog
         statusDisplay.Text = "⚠️ Are you sure? Click again to confirm removal"
         statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.WARNING
         statusDisplay.Visible = true
         
         -- Change button to confirm state
         removeButton.Text = "⚠️ Confirm Remove"
         removeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.WARNING
         
         -- Set up confirmation handler
         local confirmConnection
         confirmConnection = removeButton.MouseButton1Click:Connect(function()
             confirmConnection:Disconnect()
             
             -- Show loading state
             statusDisplay.Text = "🔄 Removing user..."
             statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
             removeButton.Text = "🔄 Removing..."
             removeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
             
             -- Remove user
             local success, result = pcall(function()
                 local currentUser = self.realUserManager.getCurrentUser()
                 if not currentUser then
                     return false, "Current user not found"
                 end
                 return self.realUserManager.removeUser(currentUser.userId, user.userId, "Removed by admin")
             end)
             
             if success and result then
                 statusDisplay.Text = "✅ User removed successfully!"
                 statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
                 print("[REAL_USER_COLLABORATION] [INFO] User removed successfully: " .. user.userName)
                 
                 -- Close dialog after brief delay
                 task.wait(1.5)
                 overlay:Destroy()
                 
                 -- Refresh UI
                 if self.refreshUI then
                     self:refreshUI()
                 end
             else
                 local errorMsg = tostring(result) or "Unknown error occurred"
                 statusDisplay.Text = "❌ Failed: " .. errorMsg
                 statusDisplay.TextColor3 = Constants.UI.THEME.COLORS.ERROR
                 
                 -- Reset button
                 removeButton.Text = "🗑️ Remove User"
                 removeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
                 
                 print("[REAL_USER_COLLABORATION] [ERROR] Failed to remove user: " .. errorMsg)
             end
         end)
         
         -- Reset confirmation after 5 seconds if not clicked
         task.wait(5)
         if confirmConnection.Connected then
             confirmConnection:Disconnect()
             removeButton.Text = "🗑️ Remove User"
             removeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
             statusDisplay.Visible = false
         end
     end)
    
    -- Close handlers
    local function closeDialog()
        overlay:Destroy()
    end
    
    closeButton.MouseButton1Click:Connect(closeDialog)
    cancelButton.MouseButton1Click:Connect(closeDialog)
    overlay.MouseButton1Click:Connect(closeDialog)
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

function RealUserCollaboration:refreshUI()
    -- Find the main container and remount the component
    local gui = game:GetService("CoreGui"):FindFirstChild("DataStoreManagerPro")
    if gui then
        local container = gui:FindFirstChild("RealUserCollaborationContainer", true)
        if container and container.Parent then
            self:mount(container.Parent)
        end
    end
    print("[REAL_USER_COLLABORATION] [INFO] UI refreshed after user management action")
end

function RealUserCollaboration:cleanup()
    self.isActive = false
    
    if self.updateInterval then
        task.cancel(self.updateInterval)
        self.updateInterval = nil
    end
    
    print("[REAL_USER_COLLABORATION] [INFO] Real user collaboration component cleanup completed")
end

-- Create join team section (where users enter invitation codes)
function RealUserCollaboration:createJoinTeamSection(parent)
    local joinFrame = Instance.new("Frame")
    joinFrame.Name = "JoinTeamSection"
    joinFrame.Size = UDim2.new(1, -40, 0, 200)
    joinFrame.Position = UDim2.new(0, 20, 0, 460)
    joinFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    joinFrame.BorderSizePixel = 0
    joinFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = joinFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -40, 0, 28)
    sectionTitle.Position = UDim2.new(0, 20, 0, 15)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "🚪 Join Team"
    sectionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = joinFrame
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, -40, 0, 30)
    instructions.Position = UDim2.new(0, 20, 0, 50)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Have an invitation code? Enter it below to join the team:"
    instructions.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    instructions.TextSize = 14
    instructions.TextXAlignment = Enum.TextXAlignment.Left
    instructions.Font = Enum.Font.Gotham
    instructions.Parent = joinFrame
    
    -- Code input
    local codeLabel = Instance.new("TextLabel")
    codeLabel.Name = "CodeLabel"
    codeLabel.Size = UDim2.new(0, 100, 0, 30)
    codeLabel.Position = UDim2.new(0, 20, 0, 90)
    codeLabel.BackgroundTransparency = 1
    codeLabel.Text = "Invitation Code:"
    codeLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    codeLabel.TextSize = 14
    codeLabel.TextXAlignment = Enum.TextXAlignment.Left
    codeLabel.Font = Enum.Font.Gotham
    codeLabel.Parent = joinFrame
    
    local codeInput = Instance.new("TextBox")
    codeInput.Name = "CodeInput"
    codeInput.Size = UDim2.new(0, 150, 0, 30)
    codeInput.Position = UDim2.new(0, 140, 0, 90)
    codeInput.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    codeInput.BorderSizePixel = 0
    codeInput.Text = ""
    codeInput.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    codeInput.TextSize = 12
    codeInput.Font = Enum.Font.Gotham
    codeInput.PlaceholderText = "Enter 8-character code"
    codeInput.Parent = joinFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = codeInput
    
    -- Join button
    local joinButton = Instance.new("TextButton")
    joinButton.Name = "JoinButton"
    joinButton.Size = UDim2.new(0, 100, 0, 30)
    joinButton.Position = UDim2.new(0, 310, 0, 90)
    joinButton.BackgroundColor3 = Constants.UI.THEME.COLORS.PRIMARY
    joinButton.BorderSizePixel = 0
    joinButton.Text = "🚪 Join Team"
    joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinButton.TextSize = 12
    joinButton.Font = Enum.Font.GothamBold
    joinButton.Parent = joinFrame
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 6)
    joinCorner.Parent = joinButton
    
    -- Status display
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusDisplay"
    statusFrame.Size = UDim2.new(1, -40, 0, 40)
    statusFrame.Position = UDim2.new(0, 20, 0, 140)
    statusFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    statusFrame.BorderSizePixel = 0
    statusFrame.Visible = false
    statusFrame.Parent = joinFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -20, 1, 0)
    statusText.Position = UDim2.new(0, 10, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Status message"
    statusText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    statusText.TextSize = 12
    statusText.TextXAlignment = Enum.TextXAlignment.Center
    statusText.Font = Enum.Font.Gotham
    statusText.Parent = statusFrame
    
    -- Connect join button
    joinButton.MouseButton1Click:Connect(function()
        self:joinTeamWithCode(codeInput, statusFrame, statusText)
    end)
end

-- Create user management section (for root admin to manage users)
function RealUserCollaboration:createUserManagementSection(parent)
    local mgmtFrame = Instance.new("Frame")
    mgmtFrame.Name = "UserManagementSection"
    mgmtFrame.Size = UDim2.new(1, -40, 0, 200)
    mgmtFrame.Position = UDim2.new(0, 20, 0, 1400)
    mgmtFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    mgmtFrame.BorderSizePixel = 0
    mgmtFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mgmtFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -40, 0, 28)
    sectionTitle.Position = UDim2.new(0, 20, 0, 15)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "⚙️ User Management (Admin Only)"
    sectionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = mgmtFrame
    
    -- User selection dropdown placeholder
    local userLabel = Instance.new("TextLabel")
    userLabel.Name = "UserLabel"
    userLabel.Size = UDim2.new(0, 80, 0, 30)
    userLabel.Position = UDim2.new(0, 20, 0, 60)
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "Select User:"
    userLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    userLabel.TextSize = 14
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.Font = Enum.Font.Gotham
    userLabel.Parent = mgmtFrame
    
    local userDropdown = Instance.new("TextButton")
    userDropdown.Name = "UserDropdown"
    userDropdown.Size = UDim2.new(0, 150, 0, 30)
    userDropdown.Position = UDim2.new(0, 110, 0, 60)
    userDropdown.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    userDropdown.BorderSizePixel = 0
    userDropdown.Text = "Select User ▼"
    userDropdown.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    userDropdown.TextSize = 12
    userDropdown.Font = Enum.Font.Gotham
    userDropdown.Parent = mgmtFrame
    
    local userDropCorner = Instance.new("UICorner")
    userDropCorner.CornerRadius = UDim.new(0, 6)
    userDropCorner.Parent = userDropdown
    
    -- Placeholder text for user management
    local placeholderText = Instance.new("TextLabel")
    placeholderText.Name = "PlaceholderText"
    placeholderText.Size = UDim2.new(1, -40, 0, 100)
    placeholderText.Position = UDim2.new(0, 20, 0, 100)
    placeholderText.BackgroundTransparency = 1
    placeholderText.Text = "👥 Once team members join using invitation codes, you'll be able to:\n• Change their roles (Admin, Editor, Viewer, Guest)\n• Remove users from the team\n• View their activity and permissions"
    placeholderText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
    placeholderText.TextSize = 14
    placeholderText.TextXAlignment = Enum.TextXAlignment.Left
    placeholderText.TextYAlignment = Enum.TextYAlignment.Top
    placeholderText.TextWrapped = true
    placeholderText.Font = Enum.Font.Gotham
    placeholderText.Parent = mgmtFrame
end

-- Handle joining team with invitation code
function RealUserCollaboration:joinTeamWithCode(codeInput, statusFrame, statusText)
    if not self.realUserManager then
        statusText.Text = "Error: Real User Manager not available"
        statusText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        statusFrame.Visible = true
        return
    end
    
    local code = string.upper(string.gsub(codeInput.Text, "%s+", ""))
    if #code == 0 then
        statusText.Text = "Please enter an invitation code"
        statusText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        statusFrame.Visible = true
        return
    end
    
    -- Get current Studio user info
    local newUserData = {
        userId = "user_" .. os.time() .. "_" .. math.random(1000, 9999),
        userName = "StudioUser_" .. math.random(1000, 9999)
    }
    
    -- Try to get actual Studio user info
    local success, studioUser = pcall(function()
        local StudioService = game:GetService("StudioService")
        local userId = StudioService:GetUserId()
        if userId and userId > 0 then
            local Players = game:GetService("Players")
            local userName = Players:GetNameFromUserIdAsync(userId)
            return {
                userId = "user_" .. userId,
                userName = userName or ("User_" .. userId)
            }
        end
        return nil
    end)
    
    if success and studioUser then
        newUserData = studioUser
    end
    
    -- Use the invitation code
    local success, result = pcall(function()
        return self.realUserManager.useInvitationCode(code, newUserData)
    end)
    
    if success and result then
        statusText.Text = "✅ Successfully joined the team!"
        statusText.TextColor3 = Constants.UI.THEME.COLORS.SUCCESS
        statusFrame.Visible = true
        codeInput.Text = ""
        
        -- Refresh UI after joining
        task.wait(2)
        if self.refreshUI then
            self:refreshUI()
        end
    else
        local errorMsg = result or "Failed to join team"
        statusText.Text = "❌ " .. tostring(errorMsg)
        statusText.TextColor3 = Constants.UI.THEME.COLORS.ERROR
        statusFrame.Visible = true
    end
end

-- Create role overview section (shows what each role can do)
function RealUserCollaboration:createRoleOverviewSection(parent)
    local roleFrame = Instance.new("Frame")
    roleFrame.Name = "RoleOverviewSection"
    roleFrame.Size = UDim2.new(1, -40, 0, 380)
    roleFrame.Position = UDim2.new(0, 20, 0, 1000)
    roleFrame.BackgroundColor3 = Constants.UI.THEME.COLORS.CARD_BACKGROUND
    roleFrame.BorderSizePixel = 0
    roleFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = roleFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -40, 0, 28)
    sectionTitle.Position = UDim2.new(0, 20, 0, 15)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "🎭 Role Permissions Overview"
    sectionTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = roleFrame
    
    -- Get role configurations
    local roleConfigs = {}
    if self.realUserManager and self.realUserManager.getAllRoleConfigs then
        roleConfigs = self.realUserManager.getAllRoleConfigs()
    end
    
    -- Fallback role configs
    if not roleConfigs or not next(roleConfigs) then
        roleConfigs = {
            ADMIN = {displayName = "Administrator", description = "Can manage team and perform most operations", color = Color3.fromRGB(255, 140, 0)},
            EDITOR = {displayName = "Editor", description = "Can read, write, and modify data structures", color = Color3.fromRGB(34, 139, 34)},
            VIEWER = {displayName = "Viewer", description = "Read-only access to data and analytics", color = Color3.fromRGB(70, 130, 180)},
            GUEST = {displayName = "Guest", description = "Limited access to basic data viewing", color = Color3.fromRGB(169, 169, 169)}
        }
    end
    
    -- Create role cards
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "RoleScrollFrame"
    scrollFrame.Size = UDim2.new(1, -40, 0, 320)
    scrollFrame.Position = UDim2.new(0, 20, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = roleFrame
    
    local yOffset = 0
    local roleOrder = {"OWNER", "ADMIN", "EDITOR", "VIEWER", "GUEST"}
    
    for _, roleName in ipairs(roleOrder) do
        local roleConfig = roleConfigs[roleName]
        if roleConfig then
            local roleCard = Instance.new("Frame")
            roleCard.Name = "RoleCard_" .. roleName
            roleCard.Size = UDim2.new(1, -10, 0, 80)
            roleCard.Position = UDim2.new(0, 0, 0, yOffset)
            roleCard.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
            roleCard.BorderSizePixel = 0
            roleCard.Parent = scrollFrame
            
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 8)
            cardCorner.Parent = roleCard
            
            -- Role color bar
            local colorBar = Instance.new("Frame")
            colorBar.Name = "ColorBar"
            colorBar.Size = UDim2.new(0, 6, 1, -20)
            colorBar.Position = UDim2.new(0, 10, 0, 10)
            colorBar.BackgroundColor3 = roleConfig.color or Constants.UI.THEME.COLORS.PRIMARY
            colorBar.BorderSizePixel = 0
            colorBar.Parent = roleCard
            
            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 3)
            barCorner.Parent = colorBar
            
            -- Role name
            local roleName = Instance.new("TextLabel")
            roleName.Name = "RoleName"
            roleName.Size = UDim2.new(0, 150, 0, 20)
            roleName.Position = UDim2.new(0, 25, 0, 10)
            roleName.BackgroundTransparency = 1
            roleName.Text = roleConfig.displayName or roleName
            roleName.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
            roleName.TextSize = 14
            roleName.TextXAlignment = Enum.TextXAlignment.Left
            roleName.Font = Enum.Font.GothamBold
            roleName.Parent = roleCard
            
            -- Role level
            local levelText = Instance.new("TextLabel")
            levelText.Name = "LevelText"
            levelText.Size = UDim2.new(0, 100, 0, 16)
            levelText.Position = UDim2.new(1, -110, 0, 12)
            levelText.BackgroundTransparency = 1
            levelText.Text = "Level " .. (roleConfig.level or "1")
            levelText.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
            levelText.TextSize = 11
            levelText.TextXAlignment = Enum.TextXAlignment.Right
            levelText.Font = Enum.Font.Gotham
            levelText.Parent = roleCard
            
            -- Role description
            local roleDesc = Instance.new("TextLabel")
            roleDesc.Name = "RoleDescription"
            roleDesc.Size = UDim2.new(1, -130, 0, 25)
            roleDesc.Position = UDim2.new(0, 25, 0, 32)
            roleDesc.BackgroundTransparency = 1
            roleDesc.Text = roleConfig.description or "Role permissions"
            roleDesc.TextColor3 = Constants.UI.THEME.COLORS.TEXT_SECONDARY
            roleDesc.TextSize = 12
            roleDesc.TextXAlignment = Enum.TextXAlignment.Left
            roleDesc.TextWrapped = true
            roleDesc.Font = Enum.Font.Gotham
            roleDesc.Parent = roleCard
            
            -- Feature access indicators
            local features = roleConfig.features or {}
            local featureIcons = {
                dataExplorer = "📊",
                analytics = "📈", 
                search = "🔍",
                bulkOperations = "⚡",
                userManagement = "👥",
                systemSettings = "⚙️"
            }
            
            local xOffset = 25
            for featureName, icon in pairs(featureIcons) do
                local access = features[featureName]
                if access and access ~= "none" and access ~= false then
                    local featureIcon = Instance.new("TextLabel")
                    featureIcon.Name = "Feature_" .. featureName
                    featureIcon.Size = UDim2.new(0, 20, 0, 16)
                    featureIcon.Position = UDim2.new(0, xOffset, 0, 60)
                    featureIcon.BackgroundTransparency = 1
                    featureIcon.Text = icon
                    featureIcon.TextSize = 12
                    featureIcon.Parent = roleCard
                    
                    xOffset = xOffset + 25
                end
            end
            
            yOffset = yOffset + 90
        end
    end
    
    -- Update scroll canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

return RealUserCollaboration