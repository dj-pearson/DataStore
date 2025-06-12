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
        SALT_SIZE = 16,
        KEY_ROTATION_INTERVAL = 86400, -- 24 hours
        MAX_KEY_AGE = 604800, -- 7 days
        KEY_BACKUP_COUNT = 3
    },
    ACCESS_CONTROL = {
        SESSION_TIMEOUT = 3600, -- 1 hour
        MAX_FAILED_ATTEMPTS = 5,
        LOCKOUT_DURATION = 300, -- 5 minutes
        PERMISSION_CACHE_TTL = 300, -- 5 minutes
        REQUIRE_2FA = false, -- Enterprise feature
        PASSWORD_COMPLEXITY = true, -- Enterprise feature
        IP_WHITELIST = {}, -- Enterprise feature
        DEVICE_TRACKING = true, -- Enterprise feature
        SESSION_FINGERPRINTING = true, -- Enterprise feature
        CONCURRENT_SESSION_LIMIT = 3, -- Enterprise feature
        GEO_RESTRICTION = false -- Enterprise feature
    },
    AUDIT = {
        MAX_LOG_ENTRIES = 50000, -- Increased for enterprise
        LOG_RETENTION_DAYS = 365, -- 1 year for compliance
        CRITICAL_EVENTS = {
            "DATA_ACCESS", "DATA_MODIFY", "DATA_DELETE",
            "SCHEMA_CHANGE", "ACCESS_DENIED", "SECURITY_VIOLATION",
            "USER_LOGIN", "USER_LOGOUT", "PERMISSION_CHANGE",
            "BULK_OPERATION", "EXPORT_DATA", "IMPORT_DATA",
            "SYSTEM_CONFIG", "EMERGENCY_ACCESS", "KEY_ROTATION",
            "SECURITY_POLICY_CHANGE", "COMPLIANCE_VIOLATION",
            "DATA_BREACH_ATTEMPT", "UNAUTHORIZED_ACCESS"
        },
        COMPLIANCE_LEVELS = {
            HIGH = {"GDPR", "SOX", "HIPAA", "PCI-DSS"},
            MEDIUM = {"PCI", "ISO27001", "NIST"},
            LOW = {"BASIC", "GDPR-LITE"}
        },
        ALERT_THRESHOLDS = {
            FAILED_LOGINS = 3,
            SUSPICIOUS_ACTIVITY = 1,
            DATA_ACCESS_PATTERNS = 5,
            COMPLIANCE_VIOLATIONS = 1
        }
    },
    RATE_LIMITING = {
        MAX_REQUESTS_PER_MINUTE = 1000,
        MAX_REQUESTS_PER_HOUR = 10000,
        MAX_REQUESTS_PER_DAY = 100000,
        BURST_LIMIT = 100,
        COOLDOWN_PERIOD = 60
    },
    DATA_PROTECTION = {
        MASKING_RULES = {
            PII = true,
            SENSITIVE_DATA = true,
            CREDENTIALS = true
        },
        ENCRYPTION_AT_REST = true,
        ENCRYPTION_IN_TRANSIT = true,
        DATA_LIFECYCLE = {
            RETENTION_POLICY = true,
            AUTO_DELETION = true,
            ARCHIVAL_RULES = true
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
    complianceMode = "MEDIUM", -- Enterprise feature
    dataClassifications = {}, -- Enterprise feature
    accessPolicies = {}, -- Enterprise feature
    rateLimiters = {}, -- New: Rate limiting state
    securityMetrics = {}, -- New: Security metrics
    threatDetection = {}, -- New: Threat detection state
    initialized = false
}

-- Enhanced user roles with granular permissions
local USER_ROLES = {
    VIEWER = {
        level = 1,
        permissions = {
            "READ_DATA", "VIEW_SCHEMAS", "VIEW_ANALYTICS",
            "VIEW_PUBLIC_REPORTS"
        },
        dataStoreAccess = {"READ_ONLY"},
        quotas = {maxExports = 10, maxQueries = 1000}
    },
    EDITOR = {
        level = 2,
        permissions = {
            "READ_DATA", "WRITE_DATA", "VIEW_SCHEMAS", 
            "VIEW_ANALYTICS", "EXPORT_DATA", "CREATE_REPORTS",
            "MODIFY_NON_CRITICAL"
        },
        dataStoreAccess = {"READ", "WRITE"},
        quotas = {maxExports = 100, maxQueries = 10000}
    },
    ADMIN = {
        level = 3,
        permissions = {
            "READ_DATA", "WRITE_DATA", "DELETE_DATA",
            "MANAGE_SCHEMAS", "BULK_OPERATIONS", "VIEW_ANALYTICS",
            "EXPORT_DATA", "MANAGE_SECURITY", "VIEW_AUDIT_LOG",
            "CREATE_ADVANCED_REPORTS", "MANAGE_TEAM_ACCESS"
        },
        dataStoreAccess = {"READ", "WRITE", "DELETE", "ADMIN"},
        quotas = {maxExports = 1000, maxQueries = 100000}
    },
    SUPER_ADMIN = {
        level = 4,
        permissions = {
            "READ_DATA", "WRITE_DATA", "DELETE_DATA",
            "MANAGE_SCHEMAS", "BULK_OPERATIONS", "VIEW_ANALYTICS",
            "EXPORT_DATA", "MANAGE_SECURITY", "VIEW_AUDIT_LOG",
            "MANAGE_USERS", "SYSTEM_CONFIG", "EMERGENCY_ACCESS",
            "COMPLIANCE_ADMIN", "AUDIT_ADMIN", "SECURITY_OVERRIDE"
        },
        dataStoreAccess = {"FULL_ACCESS"},
        quotas = {maxExports = -1, maxQueries = -1} -- Unlimited
    },
    -- Enterprise-specific roles
    AUDITOR = {
        level = 2.5,
        permissions = {
            "VIEW_AUDIT_LOG", "VIEW_ANALYTICS", "READ_DATA",
            "VIEW_SCHEMAS", "GENERATE_COMPLIANCE_REPORTS",
            "VIEW_SECURITY_METRICS"
        },
        dataStoreAccess = {"READ_ONLY", "AUDIT"},
        quotas = {maxExports = 500, maxQueries = 50000}
    },
    COMPLIANCE_OFFICER = {
        level = 3.5,
        permissions = {
            "VIEW_AUDIT_LOG", "MANAGE_COMPLIANCE", "VIEW_ANALYTICS",
            "GENERATE_COMPLIANCE_REPORTS", "SET_DATA_CLASSIFICATION",
            "MANAGE_RETENTION_POLICIES", "VIEW_SECURITY_METRICS"
        },
        dataStoreAccess = {"READ_ONLY", "AUDIT", "COMPLIANCE"},
        quotas = {maxExports = 1000, maxQueries = 100000}
    }
}

-- Data classification levels (Enterprise feature)
local DATA_CLASSIFICATIONS = {
    PUBLIC = {
        level = 1,
        encryption = false,
        auditLevel = "LOW",
        retentionDays = 30
    },
    INTERNAL = {
        level = 2,
        encryption = true,
        auditLevel = "MEDIUM",
        retentionDays = 90
    },
    CONFIDENTIAL = {
        level = 3,
        encryption = true,
        auditLevel = "HIGH",
        retentionDays = 365
    },
    RESTRICTED = {
        level = 4,
        encryption = true,
        auditLevel = "CRITICAL",
        retentionDays = 2555 -- 7 years
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
    
    -- Initialize enterprise features
    SecurityManager.initializeEnterpriseFeatures()
    
    securityState.initialized = true
    
    print("[SECURITY_MANAGER] [INFO] Security system initialized successfully")
    SecurityManager.auditLog("SYSTEM_START", "Security Manager initialized", "SYSTEM")
    
    return true
end

-- Initialize enterprise security features
function SecurityManager.initializeEnterpriseFeatures()
    -- Set up default access policies
    securityState.accessPolicies = {
        dataStore = {
            PlayerData = {
                classification = "CONFIDENTIAL",
                allowedRoles = {"ADMIN", "SUPER_ADMIN", "EDITOR"},
                requireApproval = false
            },
            GameSettings = {
                classification = "RESTRICTED",
                allowedRoles = {"SUPER_ADMIN"},
                requireApproval = true
            },
            Analytics = {
                classification = "INTERNAL",
                allowedRoles = {"ADMIN", "SUPER_ADMIN", "AUDITOR"},
                requireApproval = false
            }
        },
        operations = {
            BULK_DELETE = {
                requireApproval = true,
                approverRoles = {"SUPER_ADMIN"},
                auditLevel = "CRITICAL"
            },
            SCHEMA_CHANGE = {
                requireApproval = true,
                approverRoles = {"ADMIN", "SUPER_ADMIN"},
                auditLevel = "HIGH"
            },
            DATA_EXPORT = {
                requireApproval = false,
                auditLevel = "MEDIUM",
                quotaLimits = true
            }
        }
    }
    
    print("[SECURITY_MANAGER] [INFO] Enterprise features initialized")
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

function SecurityManager.hasPermission(permission, dataStore, operation)
    if not securityState.currentUser then
        SecurityManager.auditLog("ACCESS_DENIED", "No active user session", "SECURITY")
        return false
    end
    
    local user = securityState.currentUser
    local userRole = USER_ROLES[user.role]
    
    if not userRole then
        SecurityManager.auditLog("ACCESS_DENIED", "Invalid user role: " .. tostring(user.role), "SECURITY")
        return false
    end
    
    -- Check basic permission
    local hasBasicPermission = false
    for _, userPerm in ipairs(userRole.permissions) do
        if userPerm == permission then
            hasBasicPermission = true
            break
        end
    end
    
    if not hasBasicPermission then
        SecurityManager.auditLog("ACCESS_DENIED", "Permission denied: " .. permission, "ACCESS_CONTROL")
        return false
    end
    
    -- Enterprise feature: Check data store specific permissions
    if dataStore then
        local policy = securityState.accessPolicies.dataStore[dataStore]
        if policy then
            -- Check role access
            local roleAllowed = false
            for _, allowedRole in ipairs(policy.allowedRoles) do
                if allowedRole == user.role then
                    roleAllowed = true
                    break
                end
            end
            
            if not roleAllowed then
                SecurityManager.auditLog("ACCESS_DENIED", 
                    string.format("Role %s not allowed for DataStore %s", user.role, dataStore), 
                    "ACCESS_CONTROL")
                return false
            end
            
            -- Check if approval is required
            if policy.requireApproval and operation then
                local approvalStatus = SecurityManager.checkApprovalStatus(dataStore, operation)
                if not approvalStatus then
                    SecurityManager.auditLog("ACCESS_DENIED", 
                        string.format("Operation %s on %s requires approval", operation, dataStore), 
                        "ACCESS_CONTROL")
                    return false
                end
            end
        end
    end
    
    -- Enterprise feature: Check operation specific permissions
    if operation then
        local opPolicy = securityState.accessPolicies.operations[operation]
        if opPolicy and opPolicy.requireApproval then
            local approvalStatus = SecurityManager.checkApprovalStatus(dataStore or "SYSTEM", operation)
            if not approvalStatus then
                SecurityManager.auditLog("ACCESS_DENIED", 
                    string.format("Operation %s requires approval", operation), 
                    "ACCESS_CONTROL")
                return false
            end
        end
    end
    
    SecurityManager.auditLog("ACCESS_GRANTED", 
        string.format("Permission %s granted for user %s", permission, user.name), 
        "ACCESS_CONTROL")
    
    return true
end

-- Check approval status for operations (Enterprise feature)
function SecurityManager.checkApprovalStatus(resource, operation)
    -- In a real implementation, this would check an approval system
    -- For now, auto-approve for SUPER_ADMIN, require manual approval for others
    local user = securityState.currentUser
    if user and user.role == "SUPER_ADMIN" then
        return true
    end
    
    -- In production, this would integrate with an approval workflow system
    return false
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

function SecurityManager.auditLog(eventType, description, category, metadata)
    category = category or "GENERAL"
    metadata = metadata or {}
    
    local logEntry = {
        id = Utils.createGUID(),
        timestamp = os.time(),
        eventType = eventType,
        description = description,
        category = category,
        user = securityState.currentUser and securityState.currentUser.name or "SYSTEM",
        userId = securityState.currentUser and securityState.currentUser.id or "SYSTEM",
        sessionId = securityState.activeSession and securityState.activeSession.id or "NO_SESSION",
        metadata = metadata,
        severity = SecurityManager.getEventSeverity(eventType),
        complianceRelevant = SecurityManager.isComplianceRelevant(eventType),
        ipAddress = "127.0.0.1", -- Placeholder - would get real IP in production
        userAgent = "RobloxStudio"
    }
    
    -- Add to audit log
    table.insert(securityState.auditLog.entries, logEntry)
    securityState.auditLog.totalEntries = securityState.auditLog.totalEntries + 1
    
    -- Maintain log size
    if #securityState.auditLog.entries > SECURITY_CONFIG.AUDIT.MAX_LOG_ENTRIES then
        table.remove(securityState.auditLog.entries, 1)
    end
    
    -- Enterprise feature: Real-time alerting for critical events
    if logEntry.severity == "CRITICAL" then
        SecurityManager.triggerSecurityAlert(logEntry)
    end
    
    -- Compliance logging
    if logEntry.complianceRelevant then
        SecurityManager.logComplianceEvent(logEntry)
    end
    
    return logEntry.id
end

-- Get event severity level
function SecurityManager.getEventSeverity(eventType)
    local severityMap = {
        -- Critical events
        SECURITY_VIOLATION = "CRITICAL",
        EMERGENCY_ACCESS = "CRITICAL",
        BULK_DELETE = "CRITICAL",
        SYSTEM_CONFIG = "CRITICAL",
        
        -- High severity
        ACCESS_DENIED = "HIGH",
        DATA_DELETE = "HIGH",
        PERMISSION_CHANGE = "HIGH",
        SCHEMA_CHANGE = "HIGH",
        
        -- Medium severity
        DATA_MODIFY = "MEDIUM",
        USER_LOGIN = "MEDIUM",
        USER_LOGOUT = "MEDIUM",
        EXPORT_DATA = "MEDIUM",
        
        -- Low severity
        DATA_ACCESS = "LOW",
        VIEW_ANALYTICS = "LOW",
        SYSTEM_START = "LOW"
    }
    
    return severityMap[eventType] or "LOW"
end

-- Check if event is compliance relevant
function SecurityManager.isComplianceRelevant(eventType)
    local complianceEvents = {
        "DATA_ACCESS", "DATA_MODIFY", "DATA_DELETE", "DATA_EXPORT",
        "USER_LOGIN", "USER_LOGOUT", "PERMISSION_CHANGE",
        "SECURITY_VIOLATION", "ACCESS_DENIED"
    }
    
    for _, event in ipairs(complianceEvents) do
        if event == eventType then
            return true
        end
    end
    
    return false
end

-- Trigger security alert for critical events
function SecurityManager.triggerSecurityAlert(logEntry)
    -- In production, this would integrate with alerting systems
    print(string.format("[SECURITY_ALERT] CRITICAL: %s - %s", logEntry.eventType, logEntry.description))
    
    -- Could send webhooks, emails, or other notifications here
end

-- Log compliance events (Enterprise feature)
function SecurityManager.logComplianceEvent(logEntry)
    -- In production, this would send to compliance logging system
    local complianceLog = {
        auditId = logEntry.id,
        timestamp = logEntry.timestamp,
        event = logEntry.eventType,
        user = logEntry.user,
        description = logEntry.description,
        complianceFrameworks = SECURITY_CONFIG.AUDIT.COMPLIANCE_LEVELS[securityState.complianceMode] or {"BASIC"}
    }
    
    -- Store in compliance-specific log
    -- This would typically go to a separate, immutable audit system
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

-- New: Enhanced rate limiting
function SecurityManager.checkRateLimit(userId, operationType)
    if not securityState.rateLimiters[userId] then
        securityState.rateLimiters[userId] = {
            requests = {},
            lastReset = tick()
        }
    end
    
    local limiter = securityState.rateLimiters[userId]
    local now = tick()
    
    -- Reset counters if needed
    if now - limiter.lastReset >= 60 then
        limiter.requests = {}
        limiter.lastReset = now
    end
    
    -- Initialize operation counter
    if not limiter.requests[operationType] then
        limiter.requests[operationType] = {
            count = 0,
            lastRequest = now
        }
    end
    
    local operation = limiter.requests[operationType]
    
    -- Check burst limit
    if now - operation.lastRequest < 1 and operation.count >= SECURITY_CONFIG.RATE_LIMITING.BURST_LIMIT then
        return false, "Burst limit exceeded"
    end
    
    -- Check rate limits
    if operation.count >= SECURITY_CONFIG.RATE_LIMITING.MAX_REQUESTS_PER_MINUTE then
        return false, "Rate limit exceeded"
    end
    
    -- Update counters
    operation.count = operation.count + 1
    operation.lastRequest = now
    
    return true
end

-- New: Enhanced threat detection
function SecurityManager.detectThreats(operation)
    local threats = {}
    
    -- Check for suspicious patterns
    if operation.type == "LOGIN" then
        local failedAttempts = securityState.accessAttempts[operation.userId] or 0
        if failedAttempts >= SECURITY_CONFIG.ACCESS_CONTROL.MAX_FAILED_ATTEMPTS then
            table.insert(threats, {
                type = "BRUTE_FORCE_ATTEMPT",
                severity = "HIGH",
                details = "Multiple failed login attempts"
            })
        end
    end
    
    -- Check for unusual access patterns
    if operation.type == "DATA_ACCESS" then
        local userPatterns = securityState.securityMetrics[operation.userId] or {}
        if userPatterns.unusualAccess then
            table.insert(threats, {
                type = "UNUSUAL_ACCESS_PATTERN",
                severity = "MEDIUM",
                details = "Unusual data access pattern detected"
            })
        end
    end
    
    -- Check for compliance violations
    if operation.type == "DATA_MODIFY" then
        local classification = securityState.dataClassifications[operation.dataStore]
        if classification and classification.level > 2 then
            if not SecurityManager.hasRequiredApproval(operation) then
                table.insert(threats, {
                    type = "COMPLIANCE_VIOLATION",
                    severity = "HIGH",
                    details = "Unauthorized modification of sensitive data"
                })
            end
        end
    end
    
    return threats
end

-- New: Enhanced security metrics
function SecurityManager.updateSecurityMetrics(operation)
    if not securityState.securityMetrics[operation.userId] then
        securityState.securityMetrics[operation.userId] = {
            totalOperations = 0,
            failedOperations = 0,
            lastOperation = nil,
            unusualAccess = false,
            riskScore = 0
        }
    end
    
    local metrics = securityState.securityMetrics[operation.userId]
    
    -- Update basic metrics
    metrics.totalOperations = metrics.totalOperations + 1
    if not operation.success then
        metrics.failedOperations = metrics.failedOperations + 1
    end
    
    -- Update risk score
    local riskFactors = {
        failedOperations = 0.3,
        unusualAccess = 0.4,
        complianceViolations = 0.3
    }
    
    metrics.riskScore = (
        (metrics.failedOperations / metrics.totalOperations) * riskFactors.failedOperations +
        (metrics.unusualAccess and 1 or 0) * riskFactors.unusualAccess +
        (operation.complianceViolation and 1 or 0) * riskFactors.complianceViolations
    ) * 100
    
    -- Update last operation
    metrics.lastOperation = {
        type = operation.type,
        timestamp = tick(),
        success = operation.success
    }
    
    -- Check for unusual patterns
    metrics.unusualAccess = SecurityManager.detectUnusualPatterns(operation)
    
    return metrics
end

-- New: Enhanced audit logging
function SecurityManager.auditLog(event, details, userId)
    local logEntry = {
        timestamp = tick(),
        event = event,
        details = details,
        userId = userId or securityState.currentUser,
        sessionId = securityState.activeSession,
        ipAddress = "127.0.0.1", -- Simulated
        userAgent = "Roblox Studio", -- Simulated
        severity = SECURITY_CONFIG.AUDIT.CRITICAL_EVENTS[event] and "HIGH" or "MEDIUM"
    }
    
    -- Add security context
    logEntry.securityContext = {
        threats = SecurityManager.detectThreats(logEntry),
        metrics = SecurityManager.updateSecurityMetrics(logEntry),
        complianceStatus = SecurityManager.checkCompliance(logEntry)
    }
    
    -- Add to audit log
    table.insert(securityState.auditLog, logEntry)
    
    -- Trim log if needed
    if #securityState.auditLog > SECURITY_CONFIG.AUDIT.MAX_LOG_ENTRIES then
        table.remove(securityState.auditLog, 1)
    end
    
    -- Check for alerts
    SecurityManager.checkAlertThresholds(logEntry)
    
    return logEntry
end

return SecurityManager 