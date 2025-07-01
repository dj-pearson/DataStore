-- DataStore Manager Pro - Safe User Management
-- Local user management for plugin functionality only

local SafeUserManager = {}

-- Safe user management for plugin functionality
local userState = {
    currentUser = nil,
    initialized = false
}

function SafeUserManager.initialize()
    -- Initialize safe user management for plugin functionality only
    userState.initialized = true
    return true
end

-- Get current user for plugin functionality
function SafeUserManager.getCurrentUser()
    if not userState.initialized then
        SafeUserManager.initialize()
    end
    
    -- Only track current user for plugin preferences
    if not userState.currentUser then
        userState.currentUser = {
            userId = game:GetService("Players").LocalPlayer.UserId,
            displayName = game:GetService("Players").LocalPlayer.DisplayName,
            preferences = {}
        }
    end
    
    return userState.currentUser
end

-- Save user preferences (local only)
function SafeUserManager.saveUserPreferences(preferences)
    local user = SafeUserManager.getCurrentUser()
    if user then
        user.preferences = preferences
        return true
    end
    return false
end

-- Get user preferences
function SafeUserManager.getUserPreferences()
    local user = SafeUserManager.getCurrentUser()
    return user and user.preferences or {}
end

return SafeUserManager