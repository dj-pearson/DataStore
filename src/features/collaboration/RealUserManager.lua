-- DataStore Manager Pro - Real User Collaboration System
-- Manages real users with invitation codes and role-based permissions

local RealUserManager = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Real user configuration
local USER_CONFIG = {
    INVITATION = {
        CODE_LENGTH = 8,
        CODE_EXPIRY_HOURS = 24,
        MAX_PENDING_INVITES = 10,
        CODE_COMPLEXITY = true -- Mix of letters and numbers
    },
    SESSION = {
        HEARTBEAT_INTERVAL = 30, -- seconds
        SESSION_TIMEOUT = 3600, -- 1 hour
        MAX_CONCURRENT_SESSIONS = 5
    },
    PERMISSIONS = {
        OWNER = {
            level = 5,
            displayName = "Owner",
            description = "Full system access - can manage everything",
            color = Color3.fromRGB(220, 20, 60), -- Crimson
            permissions = {
                "FULL_ACCESS", "MANAGE_USERS", "GENERATE_CODES", 
                "ASSIGN_ROLES", "DELETE_DATA", "ADMIN_OVERRIDE",
                "VIEW_ALL_DATASTORES", "BULK_OPERATIONS", "EXPORT_DATA",
                "INVITE_USERS", "SYSTEM_SETTINGS", "SECURITY_MANAGEMENT"
            },
            features = {
                dataExplorer = "full",
                analytics = "full", 
                search = "full",
                bulkOperations = true,
                userManagement = true,
                systemSettings = true,
                exportData = true,
                deleteData = true
            }
        },
        ADMIN = {
            level = 4,
            displayName = "Administrator",
            description = "Can manage team and perform most operations", 
            color = Color3.fromRGB(255, 140, 0), -- Orange
            permissions = {
                "READ_DATA", "WRITE_DATA", "VIEW_ANALYTICS", 
                "INVITE_USERS", "MANAGE_TEAM", "BULK_OPERATIONS",
                "VIEW_AUDIT_LOG", "SCHEMA_MANAGEMENT", "GENERATE_CODES",
                "EXPORT_LIMITED"
            },
            features = {
                dataExplorer = "full",
                analytics = "full",
                search = "full", 
                bulkOperations = true,
                userManagement = true,
                systemSettings = false,
                exportData = true,
                deleteData = false
            }
        },
        EDITOR = {
            level = 3,
            displayName = "Editor",
            description = "Can read, write, and modify data structures",
            color = Color3.fromRGB(34, 139, 34), -- Forest Green
            permissions = {
                "READ_DATA", "WRITE_DATA", "VIEW_ANALYTICS",
                "MODIFY_SCHEMA", "EXPORT_LIMITED", "VIEW_SCHEMA"
            },
            features = {
                dataExplorer = "readWrite",
                analytics = "limited",
                search = "full",
                bulkOperations = false,
                userManagement = false,
                systemSettings = false,
                exportData = false,
                deleteData = false
            }
        },
        VIEWER = {
            level = 2,
            displayName = "Viewer",
            description = "Read-only access to data and analytics",
            color = Color3.fromRGB(70, 130, 180), -- Steel Blue
            permissions = {
                "READ_DATA", "VIEW_ANALYTICS", "VIEW_SCHEMA"
            },
            features = {
                dataExplorer = "readOnly",
                analytics = "limited",
                search = "limited",
                bulkOperations = false,
                userManagement = false,
                systemSettings = false,
                exportData = false,
                deleteData = false
            }
        },
        GUEST = {
            level = 1,
            displayName = "Guest",
            description = "Limited access to basic data viewing",
            color = Color3.fromRGB(169, 169, 169), -- Dark Gray
            permissions = {
                "READ_DATA_LIMITED", "VIEW_PUBLIC_ANALYTICS"
            },
            features = {
                dataExplorer = "limited",
                analytics = "basic",
                search = "basic",
                bulkOperations = false,
                userManagement = false,
                systemSettings = false,
                exportData = false,
                deleteData = false
            }
        }
    }
}

-- Real user state
local userState = {
    isInitialized = false,
    rootAdmin = nil,
    activeUsers = {},
    pendingInvitations = {},
    userSessions = {},
    invitationCodes = {},
    roleAssignments = {},
    collaborationData = {},
    heartbeatInterval = nil,
    pluginDataStore = nil
}

-- Initialize the real user system
function RealUserManager.initialize(dataStoreManager)
    print("[REAL_USER_MANAGER] [INFO] Initializing real user collaboration system...")
    
    -- Set up plugin DataStore for persistent user data
    if dataStoreManager and dataStoreManager.getPluginDataStore then
        userState.pluginDataStore = dataStoreManager:getPluginDataStore()
    else
        userState.pluginDataStore = dataStoreManager
    end
    
    -- Initialize root admin (current Studio user)
    RealUserManager.initializeRootAdmin()
    
    -- Load existing user data
    RealUserManager.loadUserData()
    
    -- Start session management
    RealUserManager.startSessionManagement()
    
    userState.isInitialized = true
    print("[REAL_USER_MANAGER] [INFO] Real user system initialized successfully")
    
    return RealUserManager -- Return the module itself
end

-- Initialize root admin user
function RealUserManager.initializeRootAdmin()
    local StudioService = game:GetService("StudioService")
    local Players = game:GetService("Players")
    
    local userId = "studio_user"
    local userName = "Studio Developer"
    
    -- Try to get real Studio user info
    local success, studioUserId = pcall(function()
        return StudioService:GetUserId()
    end)
    
    if success and studioUserId and studioUserId > 0 then
        userId = "user_" .. tostring(studioUserId)
        
        -- Try to get username
        local nameSuccess, playerName = pcall(function()
            return Players:GetNameFromUserIdAsync(studioUserId)
        end)
        
        if nameSuccess and playerName then
            userName = playerName
        end
    end
    
    userState.rootAdmin = {
        userId = userId,
        userName = userName,
        role = "OWNER",
        permissions = USER_CONFIG.PERMISSIONS.OWNER.permissions,
        joinedAt = os.time(),
        lastActive = os.time(),
        sessionId = RealUserManager.generateSessionId(),
        isRootAdmin = true,
        status = "online"
    }
    
    -- Add to active users
    userState.activeUsers[userId] = userState.rootAdmin
    
    print("[REAL_USER_MANAGER] [INFO] Root admin initialized: " .. userName .. " (" .. userId .. ")")
end

-- Generate secure session ID
function RealUserManager.generateSessionId()
    return "session_" .. os.time() .. "_" .. math.random(100000, 999999)
end

-- Generate invitation code
function RealUserManager.generateInvitationCode()
    local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code = ""
    
    for i = 1, USER_CONFIG.INVITATION.CODE_LENGTH do
        local randomIndex = math.random(1, #characters)
        code = code .. string.sub(characters, randomIndex, randomIndex)
    end
    
    return code
end

-- Create invitation code (only root admin or users with GENERATE_CODES permission)
function RealUserManager.createInvitationCode(inviterUserId, targetRole, expiryHours, maxUses)
    local inviter = userState.activeUsers[inviterUserId]
    if not inviter then
        return nil, "Inviter not found or not active"
    end
    
    -- Check permissions
    if not RealUserManager.hasPermission(inviterUserId, "GENERATE_CODES") then
        return nil, "Insufficient permissions to generate invitation codes"
    end
    
    -- Validate target role
    if not USER_CONFIG.PERMISSIONS[targetRole] then
        return nil, "Invalid role specified"
    end
    
    -- Check if inviter can assign this role
    local inviterLevel = USER_CONFIG.PERMISSIONS[inviter.role].level
    local targetLevel = USER_CONFIG.PERMISSIONS[targetRole].level
    
    if targetLevel >= inviterLevel then
        return nil, "Cannot assign role equal to or higher than your own"
    end
    
    -- Generate unique code
    local code = RealUserManager.generateInvitationCode()
    local attempts = 0
    while userState.invitationCodes[code] and attempts < 10 do
        code = RealUserManager.generateInvitationCode()
        attempts = attempts + 1
    end
    
    if attempts >= 10 then
        return nil, "Failed to generate unique invitation code"
    end
    
    -- Create invitation
    local invitation = {
        code = code,
        inviterUserId = inviterUserId,
        inviterName = inviter.userName,
        targetRole = targetRole,
        createdAt = os.time(),
        expiresAt = os.time() + ((expiryHours or USER_CONFIG.INVITATION.CODE_EXPIRY_HOURS) * 3600),
        maxUses = maxUses or 1,
        currentUses = 0,
        isActive = true,
        usedBy = {}
    }
    
    userState.invitationCodes[code] = invitation
    
    -- Save to persistent storage
    RealUserManager.saveUserData()
    
    print("[REAL_USER_MANAGER] [INFO] Invitation code generated: " .. code .. " (Role: " .. targetRole .. ")")
    
    return code, invitation
end

-- Use invitation code to join
function RealUserManager.useInvitationCode(code, newUserData)
    local invitation = userState.invitationCodes[code]
    if not invitation then
        return false, "Invalid invitation code"
    end
    
    -- Check if code is still active
    if not invitation.isActive then
        return false, "Invitation code has been deactivated"
    end
    
    -- Check expiry
    if os.time() > invitation.expiresAt then
        invitation.isActive = false
        RealUserManager.saveUserData()
        return false, "Invitation code has expired"
    end
    
    -- Check usage limit
    if invitation.currentUses >= invitation.maxUses then
        invitation.isActive = false
        RealUserManager.saveUserData()
        return false, "Invitation code has reached maximum uses"
    end
    
    -- Create new user
    local userId = newUserData.userId or ("user_" .. os.time() .. "_" .. math.random(1000, 9999))
    
    -- Check if user already exists
    if userState.activeUsers[userId] then
        return false, "User already exists in the system"
    end
    
    local newUser = {
        userId = userId,
        userName = newUserData.userName or ("User_" .. string.sub(userId, -4)),
        role = invitation.targetRole,
        permissions = USER_CONFIG.PERMISSIONS[invitation.targetRole].permissions,
        joinedAt = os.time(),
        lastActive = os.time(),
        sessionId = RealUserManager.generateSessionId(),
        invitedBy = invitation.inviterUserId,
        invitationCode = code,
        status = "online",
        isRootAdmin = false
    }
    
    -- Add to active users
    userState.activeUsers[userId] = newUser
    
    -- Update invitation usage
    invitation.currentUses = invitation.currentUses + 1
    table.insert(invitation.usedBy, {
        userId = userId,
        userName = newUser.userName,
        usedAt = os.time()
    })
    
    -- Deactivate if max uses reached
    if invitation.currentUses >= invitation.maxUses then
        invitation.isActive = false
    end
    
    -- Save to persistent storage
    RealUserManager.saveUserData()
    
    -- Log the event
    RealUserManager.logUserActivity("USER_JOINED", userId, "User joined using invitation code: " .. code)
    
    print("[REAL_USER_MANAGER] [INFO] New user joined: " .. newUser.userName .. " (Role: " .. newUser.role .. ")")
    
    return true, newUser
end

-- Check if user has specific permission
function RealUserManager.hasPermission(userId, permission)
    local user = userState.activeUsers[userId]
    if not user then
        return false
    end
    
    -- Root admin always has all permissions
    if user.isRootAdmin then
        return true
    end
    
    -- Check if user has the specific permission
    for _, userPermission in ipairs(user.permissions) do
        if userPermission == permission or userPermission == "FULL_ACCESS" then
            return true
        end
    end
    
    return false
end

-- Change user role (only by users with higher permissions)
function RealUserManager.changeUserRole(adminUserId, targetUserId, newRole)
    local admin = userState.activeUsers[adminUserId]
    local target = userState.activeUsers[targetUserId]
    
    if not admin or not target then
        return false, "User not found"
    end
    
    -- Check admin permissions
    if not RealUserManager.hasPermission(adminUserId, "ASSIGN_ROLES") then
        return false, "Insufficient permissions to change user roles"
    end
    
    -- Check role hierarchy
    local adminLevel = USER_CONFIG.PERMISSIONS[admin.role].level
    local targetLevel = USER_CONFIG.PERMISSIONS[target.role].level
    local newRoleLevel = USER_CONFIG.PERMISSIONS[newRole].level
    
    if not admin.isRootAdmin then
        if targetLevel >= adminLevel then
            return false, "Cannot modify user with equal or higher role"
        end
        
        if newRoleLevel >= adminLevel then
            return false, "Cannot assign role equal to or higher than your own"
        end
    end
    
    -- Update user role
    local oldRole = target.role
    target.role = newRole
    target.permissions = USER_CONFIG.PERMISSIONS[newRole].permissions
    
    -- Save changes
    RealUserManager.saveUserData()
    
    -- Log the change
    RealUserManager.logUserActivity("ROLE_CHANGED", adminUserId, 
        string.format("Changed %s role from %s to %s", target.userName, oldRole, newRole))
    
    print("[REAL_USER_MANAGER] [INFO] Role changed for " .. target.userName .. ": " .. oldRole .. " -> " .. newRole)
    
    return true, "Role updated successfully"
end

-- Remove user (only by admins)
function RealUserManager.removeUser(adminUserId, targetUserId, reason)
    local admin = userState.activeUsers[adminUserId]
    local target = userState.activeUsers[targetUserId]
    
    if not admin or not target then
        return false, "User not found"
    end
    
    -- Root admin cannot be removed
    if target.isRootAdmin then
        return false, "Cannot remove root admin"
    end
    
    -- Check admin permissions
    if not RealUserManager.hasPermission(adminUserId, "MANAGE_USERS") then
        return false, "Insufficient permissions to remove users"
    end
    
    -- Check hierarchy
    local adminLevel = USER_CONFIG.PERMISSIONS[admin.role].level
    local targetLevel = USER_CONFIG.PERMISSIONS[target.role].level
    
    if not admin.isRootAdmin and targetLevel >= adminLevel then
        return false, "Cannot remove user with equal or higher role"
    end
    
    -- Remove user
    userState.activeUsers[targetUserId] = nil
    
    -- Save changes
    RealUserManager.saveUserData()
    
    -- Log the removal
    RealUserManager.logUserActivity("USER_REMOVED", adminUserId, 
        string.format("Removed user %s. Reason: %s", target.userName, reason or "No reason provided"))
    
    print("[REAL_USER_MANAGER] [INFO] User removed: " .. target.userName .. " by " .. admin.userName)
    
    return true, "User removed successfully"
end

-- Get all active users
function RealUserManager.getActiveUsers()
    local users = {}
    for userId, user in pairs(userState.activeUsers) do
        -- Create safe copy without sensitive data
        table.insert(users, {
            userId = user.userId,
            userName = user.userName,
            role = user.role,
            joinedAt = user.joinedAt,
            lastActive = user.lastActive,
            status = user.status,
            isRootAdmin = user.isRootAdmin or false
        })
    end
    
    -- Sort by role level (highest first)
    table.sort(users, function(a, b)
        local aLevel = USER_CONFIG.PERMISSIONS[a.role] and USER_CONFIG.PERMISSIONS[a.role].level or 0
        local bLevel = USER_CONFIG.PERMISSIONS[b.role] and USER_CONFIG.PERMISSIONS[b.role].level or 0
        return aLevel > bLevel
    end)
    
    return users
end

-- Get active invitation codes (for admins)
function RealUserManager.getActiveInvitationCodes(adminUserId)
    if not RealUserManager.hasPermission(adminUserId, "GENERATE_CODES") then
        return {}
    end
    
    local activeCodes = {}
    for code, invitation in pairs(userState.invitationCodes) do
        if invitation.isActive and os.time() <= invitation.expiresAt then
            table.insert(activeCodes, {
                code = code,
                targetRole = invitation.targetRole,
                createdAt = invitation.createdAt,
                expiresAt = invitation.expiresAt,
                maxUses = invitation.maxUses,
                currentUses = invitation.currentUses,
                inviterName = invitation.inviterName
            })
        end
    end
    
    return activeCodes
end

-- Start session management
function RealUserManager.startSessionManagement()
    userState.heartbeatInterval = task.spawn(function()
        while userState.isInitialized do
            RealUserManager.updateUserPresence()
            RealUserManager.cleanupExpiredCodes()
            RealUserManager.cleanupInactiveSessions()
            task.wait(USER_CONFIG.SESSION.HEARTBEAT_INTERVAL)
        end
    end)
    
    print("[REAL_USER_MANAGER] [INFO] Session management started")
end

-- Update user presence
function RealUserManager.updateUserPresence()
    local currentTime = os.time()
    
    for userId, user in pairs(userState.activeUsers) do
        -- Update root admin as always active
        if user.isRootAdmin then
            user.lastActive = currentTime
            user.status = "online"
        else
            -- Check if user has been inactive
            if currentTime - user.lastActive > USER_CONFIG.SESSION.SESSION_TIMEOUT then
                user.status = "offline"
            elseif currentTime - user.lastActive > 300 then -- 5 minutes
                user.status = "away"
            else
                user.status = "online"
            end
        end
    end
end

-- Cleanup expired invitation codes
function RealUserManager.cleanupExpiredCodes()
    local currentTime = os.time()
    local removedCodes = {}
    
    for code, invitation in pairs(userState.invitationCodes) do
        if currentTime > invitation.expiresAt then
            invitation.isActive = false
            table.insert(removedCodes, code)
        end
    end
    
    if #removedCodes > 0 then
        RealUserManager.saveUserData()
        print("[REAL_USER_MANAGER] [INFO] Expired " .. #removedCodes .. " invitation codes")
    end
end

-- Cleanup inactive sessions
function RealUserManager.cleanupInactiveSessions()
    local currentTime = os.time()
    local removedUsers = {}
    
    for userId, user in pairs(userState.activeUsers) do
        if not user.isRootAdmin and currentTime - user.lastActive > (USER_CONFIG.SESSION.SESSION_TIMEOUT * 2) then
            table.insert(removedUsers, userId)
        end
    end
    
    for _, userId in ipairs(removedUsers) do
        local user = userState.activeUsers[userId]
        RealUserManager.logUserActivity("SESSION_TIMEOUT", userId, "User session timed out: " .. user.userName)
        userState.activeUsers[userId] = nil
    end
    
    if #removedUsers > 0 then
        RealUserManager.saveUserData()
        print("[REAL_USER_MANAGER] [INFO] Cleaned up " .. #removedUsers .. " inactive user sessions")
    end
end

-- Log user activity
function RealUserManager.logUserActivity(activityType, userId, description)
    local activity = {
        type = activityType,
        userId = userId,
        description = description,
        timestamp = os.time()
    }
    
    -- In a real implementation, this would integrate with the audit system
    print("[REAL_USER_MANAGER] [ACTIVITY] " .. activityType .. ": " .. description)
end

-- Save user data to persistent storage
function RealUserManager.saveUserData()
    if not userState.pluginDataStore then
        print("[REAL_USER_MANAGER] [WARN] No plugin DataStore available for saving user data")
        return false
    end
    
    local dataToSave = {
        users = {},
        invitations = userState.invitationCodes,
        lastSaved = os.time()
    }
    
    -- Save only persistent user data (exclude sensitive session info)
    for userId, user in pairs(userState.activeUsers) do
        if not user.isRootAdmin then -- Don't save root admin to allow for Studio user changes
            dataToSave.users[userId] = {
                userId = user.userId,
                userName = user.userName,
                role = user.role,
                joinedAt = user.joinedAt,
                invitedBy = user.invitedBy,
                invitationCode = user.invitationCode
            }
        end
    end
    
    local success, error = pcall(function()
        if userState.pluginDataStore.SetAsync then
            userState.pluginDataStore:SetAsync("RealUserData", dataToSave)
        else
            -- Fallback for different DataStore interface
            userState.pluginDataStore.SetAsync(userState.pluginDataStore, "RealUserData", dataToSave)
        end
    end)
    
    if success then
        print("[REAL_USER_MANAGER] [INFO] User data saved successfully")
        return true
    else
        print("[REAL_USER_MANAGER] [ERROR] Failed to save user data: " .. tostring(error))
        return false
    end
end

-- Load user data from persistent storage
function RealUserManager.loadUserData()
    if not userState.pluginDataStore then
        print("[REAL_USER_MANAGER] [INFO] No plugin DataStore available, starting fresh")
        return
    end
    
    local success, savedData = pcall(function()
        if userState.pluginDataStore.GetAsync then
            return userState.pluginDataStore:GetAsync("RealUserData")
        else
            -- Fallback for different DataStore interface
            return userState.pluginDataStore.GetAsync(userState.pluginDataStore, "RealUserData")
        end
    end)
    
    if success and savedData then
        -- Restore invitation codes
        userState.invitationCodes = savedData.invitations or {}
        
        -- Restore users (but mark them as offline initially)
        for userId, userData in pairs(savedData.users or {}) do
            local user = {
                userId = userData.userId,
                userName = userData.userName,
                role = userData.role,
                permissions = USER_CONFIG.PERMISSIONS[userData.role].permissions,
                joinedAt = userData.joinedAt,
                lastActive = os.time() - 3600, -- Mark as last seen 1 hour ago
                sessionId = RealUserManager.generateSessionId(),
                invitedBy = userData.invitedBy,
                invitationCode = userData.invitationCode,
                status = "offline",
                isRootAdmin = false
            }
            
            userState.activeUsers[userId] = user
        end
        
        local userCount = 0
        local inviteCount = 0
        for _ in pairs(savedData.users or {}) do userCount = userCount + 1 end
        for _ in pairs(savedData.invitations or {}) do inviteCount = inviteCount + 1 end
        
        print("[REAL_USER_MANAGER] [INFO] Loaded " .. userCount .. " users and " .. inviteCount .. " invitation codes")
    else
        print("[REAL_USER_MANAGER] [INFO] No saved user data found, starting fresh")
    end
end

-- Get current user (root admin)
function RealUserManager.getCurrentUser()
    return userState.rootAdmin
end

-- Get available roles for assignment (based on current user's level)
function RealUserManager.getAvailableRoles(currentUserId)
    local currentUser = userState.activeUsers[currentUserId]
    if not currentUser then
        return {}
    end
    
    local currentLevel = USER_CONFIG.PERMISSIONS[currentUser.role].level
    local availableRoles = {}
    
    for roleName, roleConfig in pairs(USER_CONFIG.PERMISSIONS) do
        -- Can only assign roles lower than own level (unless root admin)
        if currentUser.isRootAdmin or roleConfig.level < currentLevel then
            table.insert(availableRoles, {
                name = roleName,
                displayName = roleConfig.displayName,
                description = roleConfig.description,
                level = roleConfig.level,
                color = roleConfig.color
            })
        end
    end
    
    -- Sort by level (highest first)
    table.sort(availableRoles, function(a, b) return a.level > b.level end)
    
    return availableRoles
end

-- Check feature access for a user
function RealUserManager.hasFeatureAccess(userId, featureName, accessLevel)
    local user = userState.activeUsers[userId]
    if not user then
        return false
    end
    
    -- Root admin always has full access
    if user.isRootAdmin then
        return true
    end
    
    local roleConfig = USER_CONFIG.PERMISSIONS[user.role]
    if not roleConfig or not roleConfig.features then
        return false
    end
    
    local featureAccess = roleConfig.features[featureName]
    if not featureAccess then
        return false
    end
    
    -- Boolean features (true/false)
    if type(featureAccess) == "boolean" then
        return featureAccess
    end
    
    -- String-based access levels
    if type(featureAccess) == "string" then
        if accessLevel == "any" then
            return featureAccess ~= "none"
        elseif accessLevel == "full" then
            return featureAccess == "full"
        elseif accessLevel == "readWrite" then
            return featureAccess == "full" or featureAccess == "readWrite"
        elseif accessLevel == "readOnly" then
            return featureAccess ~= "none"
        elseif accessLevel == "limited" then
            return featureAccess ~= "none"
        end
    end
    
    return false
end

-- Get role configuration
function RealUserManager.getRoleConfig(roleName)
    return USER_CONFIG.PERMISSIONS[roleName]
end

-- Get all role configurations
function RealUserManager.getAllRoleConfigs()
    return USER_CONFIG.PERMISSIONS
end

-- Get user statistics
function RealUserManager.getUserStats()
    local stats = {
        totalUsers = 0,
        onlineUsers = 0,
        byRole = {},
        activeInvitations = 0
    }
    
    -- Count users
    for userId, user in pairs(userState.activeUsers) do
        stats.totalUsers = stats.totalUsers + 1
        
        if user.status == "online" then
            stats.onlineUsers = stats.onlineUsers + 1
        end
        
        -- Count by role
        stats.byRole[user.role] = (stats.byRole[user.role] or 0) + 1
    end
    
    -- Count active invitations
    for code, invitation in pairs(userState.invitationCodes) do
        if invitation.isActive and os.time() <= invitation.expiresAt then
            stats.activeInvitations = stats.activeInvitations + 1
        end
    end
    
    return stats
end

-- Cleanup function
function RealUserManager.cleanup()
    userState.isInitialized = false
    
    if userState.heartbeatInterval then
        task.cancel(userState.heartbeatInterval)
        userState.heartbeatInterval = nil
    end
    
    -- Save final state
    RealUserManager.saveUserData()
    
    print("[REAL_USER_MANAGER] [INFO] Real user manager cleanup completed")
end

return RealUserManager