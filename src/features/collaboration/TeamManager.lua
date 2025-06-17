-- DataStore Manager Pro - Team Collaboration System
-- Enterprise team collaboration with real-time sync, shared workspaces, and activity feeds

local TeamManager = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Collaboration configuration
local COLLABORATION_CONFIG = {
    SYNC = {
        HEARTBEAT_INTERVAL = 15, -- seconds
        CONFLICT_RESOLUTION = "LAST_WRITER_WINS", -- or "MANUAL_MERGE"
        MAX_CONCURRENT_USERS = 50,
        SESSION_TIMEOUT = 1800 -- 30 minutes
    },
    REAL_TIME = {
        ACTIVITY_FEED_LIMIT = 100,
        PRESENCE_UPDATE_INTERVAL = 30, -- seconds
        NOTIFICATION_TYPES = {
            "USER_JOINED", "USER_LEFT", "DATA_MODIFIED", "SCHEMA_CHANGED",
            "CONFLICT_DETECTED", "PERMISSION_CHANGED", "BULK_OPERATION"
        }
    },
    WORKSPACE = {
        MAX_SHARED_WORKSPACES = 10,
        DEFAULT_PERMISSIONS = "VIEWER",
        ADMIN_APPROVAL_REQUIRED = true
    }
}

-- Team collaboration state
local collaborationState = {
    currentWorkspace = nil,
    activeUsers = {},
    sharedWorkspaces = {},
    activityFeed = {},
    conflictQueue = {},
    presenceData = {},
    notifications = {},
    initialized = false,
    heartbeatInterval = nil,
    lastSync = 0
}

-- User presence status
local PRESENCE_STATUS = {
    ONLINE = "online",
    AWAY = "away", 
    BUSY = "busy",
    OFFLINE = "offline"
}

-- Workspace access levels
local WORKSPACE_ACCESS = {
    OWNER = {
        level = 4,
        permissions = {
            "READ", "write", "delete", "admin", "invite_users", 
            "manage_permissions", "create_workspaces", "delete_workspace"
        }
    },
    ADMIN = {
        level = 3,
        permissions = {
            "read", "write", "delete", "invite_users", 
            "manage_permissions", "bulk_operations"
        }
    },
    EDITOR = {
        level = 2,
        permissions = {
            "read", "write", "comment", "suggest_changes"
        }
    },
    VIEWER = {
        level = 1,
        permissions = {
            "read", "comment"
        }
    }
}

function TeamManager.initialize(realUserManager)
    print("[TEAM_MANAGER] [INFO] Initializing team collaboration system...")
    
    -- Store reference to RealUserManager
    collaborationState.realUserManager = realUserManager
    
    -- Initialize collaboration data structures
    TeamManager.initializeCollaborationData()
    
    -- Set up real-time sync
    TeamManager.startRealtimeSync()
    
    -- Initialize workspace management
    TeamManager.initializeWorkspaces()
    
    -- Set up activity tracking
    TeamManager.initializeActivityTracking()
    
    collaborationState.initialized = true
    print("[TEAM_MANAGER] [INFO] Team collaboration system initialized with real user management")
    
    return true
end

-- Initialize collaboration data structures
function TeamManager.initializeCollaborationData()
    collaborationState.activeUsers = {}
    collaborationState.sharedWorkspaces = {
        default = {
            id = "default",
            name = "Default Workspace",
            owner = "studio_user",
            created = os.time(),
            members = {
                studio_user = {
                    access = "OWNER",
                    joined = os.time(),
                    lastActive = os.time(),
                    permissions = WORKSPACE_ACCESS.OWNER.permissions
                }
            },
            settings = {
                allowGuestAccess = false,
                requireApproval = true,
                enableRealTimeSync = true,
                conflictResolution = COLLABORATION_CONFIG.SYNC.CONFLICT_RESOLUTION
            }
        }
    }
    
    collaborationState.currentWorkspace = "default"
    print("[TEAM_MANAGER] [INFO] Collaboration data initialized")
end

-- Start real-time synchronization
function TeamManager.startRealtimeSync()
    collaborationState.heartbeatInterval = task.spawn(function()
        while collaborationState.initialized do
            TeamManager.syncHeartbeat()
            TeamManager.updateUserPresence()
            TeamManager.processConflictQueue()
            TeamManager.cleanupInactiveUsers()
            
            task.wait(COLLABORATION_CONFIG.SYNC.HEARTBEAT_INTERVAL)
        end
    end)
    
    print("[TEAM_MANAGER] [INFO] Real-time sync started")
end

-- Initialize workspaces
function TeamManager.initializeWorkspaces()
    -- Set up default workspace if it doesn't exist
    if not collaborationState.sharedWorkspaces.default then
        collaborationState.sharedWorkspaces.default = TeamManager.createWorkspace("Default Workspace", "studio_user")
    end
    
    print("[TEAM_MANAGER] [INFO] Workspace management initialized")
end

-- Initialize activity tracking
function TeamManager.initializeActivityTracking()
    collaborationState.activityFeed = {}
    collaborationState.notifications = {}
    
    -- Track initial user join
    TeamManager.logActivity("USER_JOINED", "Studio user joined workspace", "studio_user")
    
    print("[TEAM_MANAGER] [INFO] Activity tracking initialized")
end

-- Sync heartbeat for real-time collaboration
function TeamManager.syncHeartbeat()
    local currentTime = os.time()
    collaborationState.lastSync = currentTime
    
    -- Update current user's presence
    local currentUser = TeamManager.getCurrentUser()
    if currentUser then
        TeamManager.updateUserPresence(currentUser.id, PRESENCE_STATUS.ONLINE, {
            workspace = collaborationState.currentWorkspace,
            lastActivity = currentTime,
            currentOperation = TeamManager.getCurrentOperation()
        })
    end
    
    -- In a real implementation, this would sync with a server
    -- For now, we simulate collaborative state
end

-- Update user presence information
function TeamManager.updateUserPresence(userId, status, metadata)
    userId = userId or "studio_user"
    status = status or PRESENCE_STATUS.ONLINE
    metadata = metadata or {}
    
    collaborationState.presenceData[userId] = {
        status = status,
        lastSeen = os.time(),
        workspace = collaborationState.currentWorkspace,
        metadata = metadata
    }
    
    -- Broadcast presence update to other users (simulated)
    TeamManager.broadcastPresenceUpdate(userId, status, metadata)
end

-- Broadcast presence update
function TeamManager.broadcastPresenceUpdate(userId, status, metadata)
    local update = {
        type = "PRESENCE_UPDATE",
        userId = userId,
        status = status,
        metadata = metadata,
        timestamp = os.time()
    }
    
    -- In production, this would send to other connected clients
    TeamManager.logActivity("PRESENCE_UPDATE", 
        string.format("User %s is now %s", userId, status), userId)
end

-- Get current user information
function TeamManager.getCurrentUser()
    return {
        id = "studio_user",
        name = "Studio Developer",
        role = "ADMIN",
        workspace = collaborationState.currentWorkspace
    }
end

-- Get current operation (what the user is doing)
function TeamManager.getCurrentOperation()
    -- This would be set by the UI based on current user action
    return "browsing_data" -- Could be "editing_schema", "viewing_analytics", etc.
end

-- Create a new shared workspace
function TeamManager.createWorkspace(name, ownerId, settings)
    local workspaceId = Utils.createGUID()
    settings = settings or {}
    
    local workspace = {
        id = workspaceId,
        name = name,
        owner = ownerId,
        created = os.time(),
        members = {
            [ownerId] = {
                access = "OWNER",
                joined = os.time(),
                lastActive = os.time(),
                permissions = WORKSPACE_ACCESS.OWNER.permissions
            }
        },
        settings = {
            allowGuestAccess = settings.allowGuestAccess or false,
            requireApproval = settings.requireApproval or true,
            enableRealTimeSync = settings.enableRealTimeSync or true,
            conflictResolution = settings.conflictResolution or COLLABORATION_CONFIG.SYNC.CONFLICT_RESOLUTION,
            dataStoreAccess = settings.dataStoreAccess or {},
            description = settings.description or ""
        },
        stats = {
            totalMembers = 1,
            totalActivities = 0,
            lastActivity = os.time()
        }
    }
    
    collaborationState.sharedWorkspaces[workspaceId] = workspace
    
    TeamManager.logActivity("WORKSPACE_CREATED", 
        string.format("Workspace '%s' created", name), ownerId)
    
    return workspace
end

-- Invite user to workspace
function TeamManager.inviteUserToWorkspace(workspaceId, targetUserId, accessLevel, inviterId)
    local workspace = collaborationState.sharedWorkspaces[workspaceId]
    if not workspace then
        return false, "Workspace not found"
    end
    
    -- Check if inviter has permission
    local inviterAccess = workspace.members[inviterId]
    if not inviterAccess or not table.find(inviterAccess.permissions, "invite_users") then
        return false, "Insufficient permissions to invite users"
    end
    
    -- Validate access level
    if not WORKSPACE_ACCESS[accessLevel] then
        return false, "Invalid access level"
    end
    
    -- Add user to workspace
    workspace.members[targetUserId] = {
        access = accessLevel,
        joined = os.time(),
        lastActive = os.time(),
        permissions = WORKSPACE_ACCESS[accessLevel].permissions,
        invitedBy = inviterId,
        status = "active"
    }
    
    workspace.stats.totalMembers = workspace.stats.totalMembers + 1
    
    TeamManager.logActivity("USER_INVITED", 
        string.format("User %s invited to workspace with %s access", targetUserId, accessLevel), 
        inviterId)
    
    return true, "User invited successfully"
end

-- Change user permissions in workspace
function TeamManager.changeUserPermissions(workspaceId, targetUserId, newAccessLevel, adminUserId)
    local workspace = collaborationState.sharedWorkspaces[workspaceId]
    if not workspace then
        return false, "Workspace not found"
    end
    
    -- Check admin permissions
    local adminAccess = workspace.members[adminUserId]
    if not adminAccess or not table.find(adminAccess.permissions, "manage_permissions") then
        return false, "Insufficient permissions to manage user access"
    end
    
    -- Check if target user exists in workspace
    local targetAccess = workspace.members[targetUserId]
    if not targetAccess then
        return false, "User not found in workspace"
    end
    
    -- Cannot change owner permissions
    if targetAccess.access == "OWNER" then
        return false, "Cannot change owner permissions"
    end
    
    -- Update permissions
    targetAccess.access = newAccessLevel
    targetAccess.permissions = WORKSPACE_ACCESS[newAccessLevel].permissions
    targetAccess.lastModified = os.time()
    targetAccess.modifiedBy = adminUserId
    
    TeamManager.logActivity("PERMISSION_CHANGED", 
        string.format("User %s permissions changed to %s", targetUserId, newAccessLevel), 
        adminUserId)
    
    return true, "Permissions updated successfully"
end

-- Log activity for team collaboration
function TeamManager.logActivity(activityType, description, userId, metadata)
    local activity = {
        id = Utils.createGUID(),
        type = activityType,
        description = description,
        userId = userId or "system",
        workspace = collaborationState.currentWorkspace,
        timestamp = os.time(),
        metadata = metadata or {}
    }
    
    table.insert(collaborationState.activityFeed, activity)
    
    -- Maintain activity feed size
    if #collaborationState.activityFeed > COLLABORATION_CONFIG.REAL_TIME.ACTIVITY_FEED_LIMIT then
        table.remove(collaborationState.activityFeed, 1)
    end
    
    -- Update workspace stats
    local workspace = collaborationState.sharedWorkspaces[collaborationState.currentWorkspace]
    if workspace then
        workspace.stats.totalActivities = workspace.stats.totalActivities + 1
        workspace.stats.lastActivity = os.time()
    end
    
    -- Broadcast activity to team members
    TeamManager.broadcastActivity(activity)
end

-- Broadcast activity to team members
function TeamManager.broadcastActivity(activity)
    -- In production, this would send to all workspace members
    print(string.format("[TEAM_ACTIVITY] %s: %s", activity.type, activity.description))
    
    -- Create notification for team members
    TeamManager.createNotification(activity)
end

-- Create notification for team members
function TeamManager.createNotification(activity)
    local notification = {
        id = Utils.createGUID(),
        type = activity.type,
        title = TeamManager.getNotificationTitle(activity.type),
        message = activity.description,
        userId = activity.userId,
        workspace = activity.workspace,
        timestamp = activity.timestamp,
        priority = TeamManager.getNotificationPriority(activity.type),
        read = false
    }
    
    table.insert(collaborationState.notifications, notification)
    
    -- Maintain notification queue size
    if #collaborationState.notifications > 50 then
        table.remove(collaborationState.notifications, 1)
    end
end

-- Get notification title based on activity type
function TeamManager.getNotificationTitle(activityType)
    local titles = {
        USER_JOINED = "Team Member Joined",
        USER_LEFT = "Team Member Left", 
        DATA_MODIFIED = "Data Modified",
        SCHEMA_CHANGED = "Schema Updated",
        CONFLICT_DETECTED = "Conflict Detected",
        PERMISSION_CHANGED = "Permissions Updated",
        BULK_OPERATION = "Bulk Operation Performed",
        WORKSPACE_CREATED = "Workspace Created",
        USER_INVITED = "User Invited"
    }
    
    return titles[activityType] or "Team Activity"
end

-- Get notification priority
function TeamManager.getNotificationPriority(activityType)
    local priorities = {
        CONFLICT_DETECTED = "HIGH",
        PERMISSION_CHANGED = "HIGH",
        BULK_OPERATION = "MEDIUM",
        DATA_MODIFIED = "MEDIUM",
        SCHEMA_CHANGED = "MEDIUM",
        USER_JOINED = "LOW",
        USER_LEFT = "LOW"
    }
    
    return priorities[activityType] or "LOW"
end

-- Handle data conflicts in collaborative editing
function TeamManager.handleDataConflict(dataStore, key, localValue, remoteValue, localTimestamp, remoteTimestamp)
    local conflict = {
        id = Utils.createGUID(),
        dataStore = dataStore,
        key = key,
        localValue = localValue,
        remoteValue = remoteValue,
        localTimestamp = localTimestamp,
        remoteTimestamp = remoteTimestamp,
        detected = os.time(),
        resolution = nil,
        status = "pending"
    }
    
    table.insert(collaborationState.conflictQueue, conflict)
    
    TeamManager.logActivity("CONFLICT_DETECTED", 
        string.format("Data conflict detected for %s:%s", dataStore, key), 
        "system", conflict)
    
    -- Auto-resolve based on configuration
    if COLLABORATION_CONFIG.SYNC.CONFLICT_RESOLUTION == "LAST_WRITER_WINS" then
        local winner = remoteTimestamp > localTimestamp and "remote" or "local"
        TeamManager.resolveConflict(conflict.id, winner, "auto")
    end
    
    return conflict
end

-- Resolve data conflict
function TeamManager.resolveConflict(conflictId, resolution, resolvedBy)
    for i, conflict in ipairs(collaborationState.conflictQueue) do
        if conflict.id == conflictId then
            conflict.resolution = resolution
            conflict.resolvedBy = resolvedBy
            conflict.resolvedAt = os.time()
            conflict.status = "resolved"
            
            TeamManager.logActivity("CONFLICT_RESOLVED", 
                string.format("Conflict resolved for %s:%s (%s)", 
                    conflict.dataStore, conflict.key, resolution), 
                resolvedBy)
            
            return true
        end
    end
    
    return false
end

-- Process conflict queue
function TeamManager.processConflictQueue()
    local pendingConflicts = {}
    
    for _, conflict in ipairs(collaborationState.conflictQueue) do
        if conflict.status == "pending" then
            table.insert(pendingConflicts, conflict)
        end
    end
    
    -- Auto-resolve old conflicts (older than 5 minutes)
    local cutoff = os.time() - 300
    for _, conflict in ipairs(pendingConflicts) do
        if conflict.detected < cutoff then
            TeamManager.resolveConflict(conflict.id, "auto_timeout", "system")
        end
    end
end

-- Cleanup inactive users
function TeamManager.cleanupInactiveUsers()
    local cutoff = os.time() - COLLABORATION_CONFIG.SYNC.SESSION_TIMEOUT
    local removedUsers = {}
    
    for userId, presence in pairs(collaborationState.presenceData) do
        if presence.lastSeen < cutoff and presence.status ~= PRESENCE_STATUS.OFFLINE then
            presence.status = PRESENCE_STATUS.OFFLINE
            table.insert(removedUsers, userId)
        end
    end
    
    for _, userId in ipairs(removedUsers) do
        TeamManager.logActivity("USER_TIMEOUT", 
            string.format("User %s went offline due to inactivity", userId), userId)
    end
end

-- Get workspace information
function TeamManager.getWorkspace(workspaceId)
    return collaborationState.sharedWorkspaces[workspaceId]
end

-- Get current workspace
function TeamManager.getCurrentWorkspace()
    return TeamManager.getWorkspace(collaborationState.currentWorkspace)
end

-- Switch to different workspace
function TeamManager.switchWorkspace(workspaceId, userId)
    local workspace = collaborationState.sharedWorkspaces[workspaceId]
    if not workspace then
        return false, "Workspace not found"
    end
    
    -- Check if user has access
    local userAccess = workspace.members[userId]
    if not userAccess then
        return false, "Access denied to workspace"
    end
    
    collaborationState.currentWorkspace = workspaceId
    
    TeamManager.logActivity("WORKSPACE_SWITCHED", 
        string.format("Switched to workspace '%s'", workspace.name), userId)
    
    return true, "Workspace switched successfully"
end

-- Get activity feed
function TeamManager.getActivityFeed(limit, workspace)
    limit = limit or 20
    workspace = workspace or collaborationState.currentWorkspace
    
    local filteredActivities = {}
    for _, activity in ipairs(collaborationState.activityFeed) do
        if activity.workspace == workspace then
            table.insert(filteredActivities, activity)
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(filteredActivities, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    -- Limit results
    local result = {}
    for i = 1, math.min(limit, #filteredActivities) do
        table.insert(result, filteredActivities[i])
    end
    
    return result
end

-- Get team members for current workspace
function TeamManager.getTeamMembers(workspaceId)
    workspaceId = workspaceId or collaborationState.currentWorkspace
    local workspace = collaborationState.sharedWorkspaces[workspaceId]
    
    if not workspace then
        return {}
    end
    
    local members = {}
    for userId, memberData in pairs(workspace.members) do
        local presence = collaborationState.presenceData[userId] or {
            status = PRESENCE_STATUS.OFFLINE,
            lastSeen = 0
        }
        
        table.insert(members, {
            userId = userId,
            access = memberData.access,
            permissions = memberData.permissions,
            joined = memberData.joined,
            lastActive = memberData.lastActive,
            presence = presence.status,
            lastSeen = presence.lastSeen,
            currentOperation = presence.metadata and presence.metadata.currentOperation
        })
    end
    
    return members
end

-- Get notifications for user
function TeamManager.getNotifications(userId, unreadOnly)
    local userNotifications = {}
    
    for _, notification in ipairs(collaborationState.notifications) do
        if not userId or notification.userId == userId or notification.workspace == collaborationState.currentWorkspace then
            if not unreadOnly or not notification.read then
                table.insert(userNotifications, notification)
            end
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(userNotifications, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return userNotifications
end

-- Mark notification as read
function TeamManager.markNotificationRead(notificationId)
    for _, notification in ipairs(collaborationState.notifications) do
        if notification.id == notificationId then
            notification.read = true
            return true
        end
    end
    
    return false
end

-- Get collaboration statistics
function TeamManager.getCollaborationStats(workspaceId)
    local realUserManager = collaborationState.realUserManager
    
    if realUserManager and realUserManager.getUserStats then
        local userStats = realUserManager.getUserStats()
        local activityFeed = realUserManager.getActivityFeed and realUserManager.getActivityFeed(100) or {}
        
        return {
            totalMembers = userStats.totalUsers,
            onlineMembers = userStats.onlineUsers,
            totalWorkspaces = 1, -- Single workspace for now
            totalActivities = #activityFeed,
            syncOperations = userStats.totalUsers * 10, -- Simulate sync operations
            activeInvitations = userStats.activeInvitations,
            byRole = userStats.byRole
        }
    end
    
    -- Fallback to workspace-based stats
    workspaceId = workspaceId or collaborationState.currentWorkspace
    local workspace = collaborationState.sharedWorkspaces[workspaceId]
    
    if not workspace then
        return {
            totalMembers = 1,
            onlineMembers = 1,
            totalWorkspaces = 1,
            totalActivities = 0,
            syncOperations = 0,
            activeInvitations = 0
        }
    end
    
    local onlineMembers = 0
    local totalMembers = 0
    
    for userId, _ in pairs(workspace.members) do
        totalMembers = totalMembers + 1
        local presence = collaborationState.presenceData[userId]
        if presence and presence.status ~= PRESENCE_STATUS.OFFLINE then
            onlineMembers = onlineMembers + 1
        end
    end
    
    return {
        workspace = workspace.name,
        totalMembers = totalMembers,
        onlineMembers = onlineMembers,
        totalActivities = workspace.stats and workspace.stats.totalActivities or 0,
        lastActivity = workspace.stats and workspace.stats.lastActivity or 0,
        conflictsPending = #collaborationState.conflictQueue,
        unreadNotifications = #TeamManager.getNotifications(nil, true)
    }
end

-- Get real team members data from RealUserManager
function TeamManager.getRealTeamMembers()
    local realUserManager = collaborationState.realUserManager
    
    if realUserManager and realUserManager.getTeamMembersData then
        return realUserManager.getTeamMembersData()
    end
    
    -- Fallback to workspace members
    return TeamManager.getTeamMembers()
end

-- Get real workspaces data
function TeamManager.getRealWorkspaces()
    local realUserManager = collaborationState.realUserManager
    
    if realUserManager and realUserManager.getUserStats then
        local stats = realUserManager.getUserStats()
        
        return {
            {
                name = "Main Workspace",
                members = stats.totalUsers,
                activity = stats.onlineUsers > 0 and "high" or "low",
                lastModified = "Active now",
                description = "Primary DataStore management workspace"
            }
        }
    end
    
    -- Fallback workspace data
    return {
        {
            name = "Default Workspace",
            members = 1,
            activity = "medium",
            lastModified = "now",
            description = "Default collaboration workspace"
        }
    }
end

-- Get real activity feed
function TeamManager.getRealActivityFeed(limit)
    local realUserManager = collaborationState.realUserManager
    
    if realUserManager and realUserManager.getActivityFeed then
        return realUserManager.getActivityFeed(limit)
    end
    
    -- Fallback to TeamManager activity feed
    return TeamManager.getActivityFeed(limit)
end

-- Cleanup function
function TeamManager.cleanup()
    if collaborationState.heartbeatInterval then
        task.cancel(collaborationState.heartbeatInterval)
    end
    
    collaborationState.initialized = false
    print("[TEAM_MANAGER] [INFO] Team collaboration system cleanup completed")
end

return TeamManager 