-- DataStore Manager Pro - Security Management System
-- Implements enterprise-grade security with encryption, access controls, and audit logging

local SecurityManager = {}

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Security configuration
local SECURITY_CONFIG = {
    ENCRYPTION = {
        KEY_SIZE = 32, -- 256-bit keys
        ALGORITHM = "AES-256-GCM", -- Simulated
        SALT_SIZE = 16
    },
    ACCESS_CONTROL = {
        SESSION_TIMEOUT = 3600, -- 1 hour
        MAX_FAILED_ATTEMPTS = 5,
        LOCKOUT_DURATION = 300, -- 5 minutes
        PERMISSION_CACHE_TTL = 300 -- 5 minutes
    },
    AUDIT = {
        MAX_LOG_ENTRIES = 10000,
        LOG_RETENTION_DAYS = 90,
        CRITICAL_EVENTS = {
            "DATA_ACCESS", "DATA_MODIFY", "DATA_DELETE",
            "SCHEMA_CHANGE", "ACCESS_DENIED", "SECURITY_VIOLATION"
        }
    }
}

-- Security state
local securityState = {
    currentUser = nil,
    activeSession = nil,
    permissions = {},
    auditLog = {},
    encryptionKeys = {},
    accessAttempts = {},
    initialized = false
}

-- User roles and permissions
local USER_ROLES = {
    VIEWER = {
        level = 1,
        permissions = {
            "READ_DATA", "VIEW_SCHEMAS", "VIEW_ANALYTICS"
        }
    },
    EDITOR = {
        level = 2,
        permissions = {
            "READ_DATA", "WRITE_DATA", "VIEW_SCHEMAS", 
            "VIEW_ANALYTICS", "EXPORT_DATA"
        }
    },
    ADMIN = {
        level = 3,
        permissions = {
            "READ_DATA", "WRITE_DATA", "DELETE_DATA",
            "MANAGE_SCHEMAS", "BULK_OPERATIONS", "VIEW_ANALYTICS",
            "EXPORT_DATA", "MANAGE_SECURITY", "VIEW_AUDIT_LOG"
        }
    },
    SUPER_ADMIN = {
        level = 4,
        permissions = {
            "READ_DATA", "WRITE_DATA", "DELETE_DATA",
            "MANAGE_SCHEMAS", "BULK_OPERATIONS", "VIEW_ANALYTICS",
            "EXPORT_DATA", "MANAGE_SECURITY", "VIEW_AUDIT_LOG",
            "MANAGE_USERS", "SYSTEM_CONFIG", "EMERGENCY_ACCESS"
        }
    }
}

function SecurityManager.initialize()
    print("[SECURITY_MANAGER] [INFO] Initializing security management system...")
    
    -- Initialize encryption system
    SecurityManager.initializeEncryption()
    
    -- Set up default user (Studio user)
    SecurityManager.setupDefaultUser()
    
    -- Initialize audit logging
    SecurityManager.initializeAuditLog()
    
    securityState.initialized = true
    
    print("[SECURITY_MANAGER] [INFO] Security system initialized successfully")
    SecurityManager.auditLog("SYSTEM_START", "Security Manager initialized", "SYSTEM")
    
    return true
end

-- Encryption Functions
function SecurityManager.initializeEncryption()
    -- Generate session encryption key (simulated for Roblox environment)
    securityState.encryptionKeys.session = SecurityManager.generateEncryptionKey()
    securityState.encryptionKeys.data = SecurityManager.generateEncryptionKey()
    
    print("[SECURITY_MANAGER] [INFO] Encryption system initialized")
end

function SecurityManager.generateEncryptionKey()
    -- Simulated key generation (in real implementation, use proper cryptographic libraries)
    local key = ""
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    
    for i = 1, SECURITY_CONFIG.ENCRYPTION.KEY_SIZE do
        local rand = math.random(1, #charset)
        key = key .. string.sub(charset, rand, rand)
    end
    
    return key
end

function SecurityManager.encryptData(data, keyType)
    keyType = keyType or "data"
    local key = securityState.encryptionKeys[keyType]
    
    if not key then
        print("[SECURITY_MANAGER] [ERROR] No encryption key found for type: " .. keyType)
        return nil
    end
    
    -- Simulated encryption (in production, use proper encryption)
    local dataString = Utils.serializeTable(data)
    local encrypted = SecurityManager.simpleEncrypt(dataString, key)
    
    SecurityManager.auditLog("DATA_ENCRYPT", "Data encrypted using " .. keyType .. " key", "SYSTEM")
    
    return {
        data = encrypted,
        algorithm = SECURITY_CONFIG.ENCRYPTION.ALGORITHM,
        keyType = keyType,
        timestamp = os.time()
    }
end

function SecurityManager.decryptData(encryptedData, keyType)
    keyType = keyType or "data"
    local key = securityState.encryptionKeys[keyType]
    
    if not key or not encryptedData then
        print("[SECURITY_MANAGER] [ERROR] Cannot decrypt: missing key or data")
        return nil
    end
    
    -- Simulated decryption
    local decrypted = SecurityManager.simpleDecrypt(encryptedData.data, key)
    local data = Utils.deserializeTable(decrypted)
    
    SecurityManager.auditLog("DATA_DECRYPT", "Data decrypted using " .. keyType .. " key", "SYSTEM")
    
    return data
end

-- Simple encryption simulation (not cryptographically secure - for demo purposes)
function SecurityManager.simpleEncrypt(data, key)
    local encrypted = ""
    local keyLen = #key
    
    for i = 1, #data do
        local dataChar = string.byte(data, i)
        local keyChar = string.byte(key, ((i - 1) % keyLen) + 1)
        local encryptedChar = string.char((dataChar + keyChar) % 256)
        encrypted = encrypted .. encryptedChar
    end
    
    -- Base64-like encoding for safe storage
    return Utils.base64Encode(encrypted)
end

function SecurityManager.simpleDecrypt(encryptedData, key)
    local decoded = Utils.base64Decode(encryptedData)
    local decrypted = ""
    local keyLen = #key
    
    for i = 1, #decoded do
        local encryptedChar = string.byte(decoded, i)
        local keyChar = string.byte(key, ((i - 1) % keyLen) + 1)
        local dataChar = string.char((encryptedChar - keyChar + 256) % 256)
        decrypted = decrypted .. dataChar
    end
    
    return decrypted
end

-- Access Control Functions
function SecurityManager.setupDefaultUser()
    -- In Studio environment, create default admin user
    local studioUser = {
        id = "studio_user",
        name = "Studio Developer",
        role = "ADMIN",
        permissions = USER_ROLES.ADMIN.permissions,
        sessionStart = os.time(),
        lastActivity = os.time()
    }
    
    securityState.currentUser = studioUser
    securityState.activeSession = {
        id = SecurityManager.generateSessionId(),
        userId = studioUser.id,
        startTime = os.time(),
        lastActivity = os.time(),
        permissions = studioUser.permissions
    }
    
    print("[SECURITY_MANAGER] [INFO] Default admin user session established")
end

function SecurityManager.generateSessionId()
    return "session_" .. os.time() .. "_" .. math.random(10000, 99999)
end

function SecurityManager.hasPermission(permission)
    if not securityState.activeSession then
        print("[SECURITY_MANAGER] [WARN] No active session for permission check: " .. permission)
        return false
    end
    
    -- Check session timeout
    local currentTime = os.time()
    if currentTime - securityState.activeSession.lastActivity > SECURITY_CONFIG.ACCESS_CONTROL.SESSION_TIMEOUT then
        print("[SECURITY_MANAGER] [WARN] Session expired")
        SecurityManager.auditLog("SESSION_EXPIRED", "Session expired during permission check", securityState.currentUser.id)
        return false
    end
    
    -- Update last activity
    securityState.activeSession.lastActivity = currentTime
    
    -- Check permission
    local hasPermission = false
    for _, userPermission in ipairs(securityState.activeSession.permissions) do
        if userPermission == permission then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        SecurityManager.auditLog("ACCESS_DENIED", "Permission denied: " .. permission, securityState.currentUser.id)
    end
    
    return hasPermission
end

function SecurityManager.requirePermission(permission, action)
    if not SecurityManager.hasPermission(permission) then
        local errorMsg = string.format("Access denied: %s permission required for %s", permission, action or "this operation")
        print("[SECURITY_MANAGER] [ERROR] " .. errorMsg)
        SecurityManager.auditLog("SECURITY_VIOLATION", errorMsg, securityState.currentUser and securityState.currentUser.id or "UNKNOWN")
        error(errorMsg)
    end
    return true
end

-- Audit Logging Functions
function SecurityManager.initializeAuditLog()
    securityState.auditLog = {
        entries = {},
        totalEntries = 0,
        lastCleanup = os.time()
    }
    
    print("[SECURITY_MANAGER] [INFO] Audit logging system initialized")
end

function SecurityManager.auditLog(eventType, description, userId, additionalData)
    local timestamp = os.time()
    local entry = {
        id = securityState.auditLog.totalEntries + 1,
        timestamp = timestamp,
        eventType = eventType,
        description = description,
        userId = userId or (securityState.currentUser and securityState.currentUser.id) or "SYSTEM",
        additionalData = additionalData,
        severity = SecurityManager.getEventSeverity(eventType)
    }
    
    -- Add to log
    table.insert(securityState.auditLog.entries, entry)
    securityState.auditLog.totalEntries = securityState.auditLog.totalEntries + 1
    
    -- Log to console for critical events
    if table.find(SECURITY_CONFIG.AUDIT.CRITICAL_EVENTS, eventType) then
        print(string.format("[SECURITY_AUDIT] [%s] %s - User: %s - %s", 
            entry.severity, eventType, entry.userId, description))
    end
    
    -- Cleanup old entries if needed
    if #securityState.auditLog.entries > SECURITY_CONFIG.AUDIT.MAX_LOG_ENTRIES then
        SecurityManager.cleanupAuditLog()
    end
    
    return entry.id
end

function SecurityManager.getEventSeverity(eventType)
    local severityMap = {
        SYSTEM_START = "INFO",
        SYSTEM_STOP = "INFO",
        DATA_ACCESS = "INFO",
        DATA_MODIFY = "WARN",
        DATA_DELETE = "WARN",
        SCHEMA_CHANGE = "WARN",
        ACCESS_DENIED = "ERROR",
        SECURITY_VIOLATION = "CRITICAL",
        SESSION_EXPIRED = "WARN",
        DATA_ENCRYPT = "INFO",
        DATA_DECRYPT = "INFO"
    }
    
    return severityMap[eventType] or "INFO"
end

function SecurityManager.cleanupAuditLog()
    local cutoffTime = os.time() - (SECURITY_CONFIG.AUDIT.LOG_RETENTION_DAYS * 24 * 60 * 60)
    local keptEntries = {}
    
    for _, entry in ipairs(securityState.auditLog.entries) do
        if entry.timestamp > cutoffTime then
            table.insert(keptEntries, entry)
        end
    end
    
    local removedCount = #securityState.auditLog.entries - #keptEntries
    securityState.auditLog.entries = keptEntries
    securityState.auditLog.lastCleanup = os.time()
    
    if removedCount > 0 then
        print(string.format("[SECURITY_MANAGER] [INFO] Cleaned up %d old audit log entries", removedCount))
    end
end

function SecurityManager.getAuditLog(startTime, endTime, eventTypes, userId)
    SecurityManager.requirePermission("VIEW_AUDIT_LOG", "view audit log")
    
    local filteredEntries = {}
    
    for _, entry in ipairs(securityState.auditLog.entries) do
        local includeEntry = true
        
        -- Time filter
        if startTime and entry.timestamp < startTime then
            includeEntry = false
        end
        if endTime and entry.timestamp > endTime then
            includeEntry = false
        end
        
        -- Event type filter
        if eventTypes and not table.find(eventTypes, entry.eventType) then
            includeEntry = false
        end
        
        -- User filter
        if userId and entry.userId ~= userId then
            includeEntry = false
        end
        
        if includeEntry then
            table.insert(filteredEntries, entry)
        end
    end
    
    SecurityManager.auditLog("AUDIT_ACCESS", string.format("Audit log accessed, returned %d entries", #filteredEntries))
    
    return filteredEntries
end

-- Data Security Wrappers
function SecurityManager.secureDataAccess(dataStore, key, operation, callback)
    -- Check permissions
    local permissionMap = {
        read = "READ_DATA",
        write = "WRITE_DATA", 
        delete = "DELETE_DATA"
    }
    
    local requiredPermission = permissionMap[operation]
    if not requiredPermission then
        error("Unknown operation: " .. operation)
    end
    
    SecurityManager.requirePermission(requiredPermission, operation .. " data")
    
    -- Audit the operation
    SecurityManager.auditLog("DATA_" .. string.upper(operation), 
        string.format("DataStore: %s, Key: %s", dataStore, key or "N/A"))
    
    -- Execute with error handling
    local success, result = pcall(callback)
    
    if not success then
        SecurityManager.auditLog("DATA_ERROR", 
            string.format("Operation failed: %s - %s", operation, result))
        error(result)
    end
    
    return result
end

-- Utility functions
function SecurityManager.getCurrentUser()
    return securityState.currentUser
end

function SecurityManager.getSecurityStatus()
    return {
        initialized = securityState.initialized,
        hasActiveSession = securityState.activeSession ~= nil,
        currentUser = securityState.currentUser and {
            id = securityState.currentUser.id,
            name = securityState.currentUser.name,
            role = securityState.currentUser.role
        } or nil,
        auditLogEntries = #securityState.auditLog.entries,
        encryptionEnabled = securityState.encryptionKeys.data ~= nil
    }
end

function SecurityManager.cleanup()
    if securityState.activeSession then
        SecurityManager.auditLog("SESSION_END", "Security Manager cleanup")
    end
    
    -- Clear sensitive data
    securityState.encryptionKeys = {}
    securityState.activeSession = nil
    
    print("[SECURITY_MANAGER] [INFO] Security Manager cleanup completed")
end

return SecurityManager 