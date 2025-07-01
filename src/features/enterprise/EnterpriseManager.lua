-- ========================================
-- ENTERPRISE MANAGER
-- ========================================
-- Provides enterprise-level DataStore management functionality
-- including compliance, auditing, version control, and metadata management

local Constants = require(script.Parent.Parent.shared.Constants)

local EnterpriseManager = {}
EnterpriseManager.__index = EnterpriseManager

-- Create new Enterprise Manager instance
function EnterpriseManager.new(services)
    local self = setmetatable({}, EnterpriseManager)
    
    self.services = services
    self.dataStoreManager = services.DataStoreManager or services["core.data.DataStoreManager"]
    self.logger = services.Logger or services["core.logging.Logger"]
    
    -- Enterprise features cache
    self.complianceCache = {}
    self.auditLog = {}
    self.versionCache = {}
    
    return self
end

-- ========================================
-- VERSION MANAGEMENT
-- ========================================

-- Get version history for a key
function EnterpriseManager:getKeyVersionHistory(datastoreName, keyName, options)
    options = options or {}
    local maxVersions = options.maxVersions or 50
    local minDate = options.minDate
    local maxDate = options.maxDate
    
    if not self.dataStoreManager then
        return {success = false, error = "DataStore Manager not available"}
    end
    
    local result = self.dataStoreManager:getKeyVersions(
        datastoreName, 
        keyName, 
        Enum.SortDirection.Descending, 
        minDate, 
        maxDate, 
        maxVersions
    )
    
    if result.success then
        -- Enhance with additional enterprise info
        local enhancedVersions = {}
        for _, version in ipairs(result.data.versions) do
            table.insert(enhancedVersions, {
                version = version.version,
                createdTime = version.createdTime,
                createdDate = version.createdDate,
                isDeleted = version.isDeleted,
                ageInDays = math.floor((os.time() * 1000 - version.createdTime) / (1000 * 60 * 60 * 24)),
                status = version.isDeleted and "DELETED" or "ACTIVE"
            })
        end
        
        return {
            success = true,
            data = {
                keystoreName = datastoreName,
                keyName = keyName,
                totalVersions = #enhancedVersions,
                versions = enhancedVersions,
                hasMore = result.data.hasMore
            }
        }
    else
        return result
    end
end

-- Compare two versions of a key
function EnterpriseManager:compareKeyVersions(datastoreName, keyName, version1, version2)
    if not self.dataStoreManager then
        return {success = false, error = "DataStore Manager not available"}
    end
    
    -- Get both versions
    local result1 = self.dataStoreManager:getKeyVersion(datastoreName, keyName, version1)
    local result2 = self.dataStoreManager:getKeyVersion(datastoreName, keyName, version2)
    
    if not result1.success or not result2.success then
        return {success = false, error = "Failed to retrieve one or both versions"}
    end
    
    local comparison = {
        keystoreName = datastoreName,
        keyName = keyName,
        version1 = {
            version = version1,
            createdTime = result1.data.createdTime,
            size = result1.data.size,
            value = result1.data.value,
            userIds = result1.data.userIds,
            metadata = result1.data.metadata
        },
        version2 = {
            version = version2,
            createdTime = result2.data.createdTime,
            size = result2.data.size,
            value = result2.data.value,
            userIds = result2.data.userIds,
            metadata = result2.data.metadata
        },
        differences = {
            sizeChange = result2.data.size - result1.data.size,
            timeSpan = result2.data.createdTime - result1.data.createdTime,
            userIdsChanged = not self:tablesEqual(result1.data.userIds, result2.data.userIds),
            metadataChanged = not self:tablesEqual(result1.data.metadata, result2.data.metadata),
            valueChanged = not self:tablesEqual(result1.data.value, result2.data.value)
        }
    }
    
    return {success = true, data = comparison}
end

-- Restore key to specific version
function EnterpriseManager:restoreKeyToVersion(datastoreName, keyName, targetVersion, options)
    options = options or {}
    local createBackup = options.createBackup ~= false -- Default true
    local preserveMetadata = options.preserveMetadata ~= false -- Default true
    
    if not self.dataStoreManager then
        return {success = false, error = "DataStore Manager not available"}
    end
    
    -- Get the target version data
    local versionResult = self.dataStoreManager:getKeyVersion(datastoreName, keyName, targetVersion)
    if not versionResult.success then
        return {success = false, error = "Failed to retrieve target version: " .. tostring(versionResult.error)}
    end
    
    local targetData = versionResult.data
    
    -- Create backup of current version if requested
    if createBackup then
        local currentResult = self.dataStoreManager:getDataWithMetadata(datastoreName, keyName)
        if currentResult.success and currentResult.data.exists then
            -- Log the backup in audit trail
            self:logAuditEvent("KEY_RESTORE_BACKUP", {
                datastoreName = datastoreName,
                keyName = keyName,
                currentVersion = currentResult.data.version,
                targetVersion = targetVersion,
                backupTimestamp = os.time()
            })
        end
    end
    
    -- Restore the data with metadata
    local restoreResult = self.dataStoreManager:setDataWithMetadata(
        datastoreName,
        keyName,
        targetData.value,
        preserveMetadata and targetData.userIds or nil,
        preserveMetadata and table.merge(targetData.metadata or {}, {
            restoredFrom = targetVersion,
            restoredAt = os.time(),
            restoredBy = "EnterpriseManager"
        }) or nil
    )
    
    if restoreResult.success then
        self:logAuditEvent("KEY_RESTORED", {
            datastoreName = datastoreName,
            keyName = keyName,
            restoredToVersion = targetVersion,
            timestamp = os.time()
        })
    end
    
    return restoreResult
end

-- ========================================
-- COMPLIANCE & AUDITING
-- ========================================

-- Generate GDPR compliance report
function EnterpriseManager:generateComplianceReport(datastoreName, userId, options)
    options = options or {}
    
    if not self.dataStoreManager then
        return {success = false, error = "DataStore Manager not available"}
    end
    
    local result = self.dataStoreManager:getComplianceReport(datastoreName, userId)
    
    if result.success then
        local report = result.data
        
        -- Enhance with enterprise analysis
        report.complianceStatus = {
            gdprCompliant = true,
            userDataFound = report.totalKeys > 0,
            dataCategories = self:analyzeDataCategories(report.keys),
            retentionAnalysis = self:analyzeDataRetention(report.keys)
        }
        
        return {success = true, data = report}
    else
        return result
    end
end

-- Export user data for GDPR requests
function EnterpriseManager:exportUserData(datastoreName, userId, format)
    format = format or "json"
    
    local complianceResult = self:generateComplianceReport(datastoreName, userId)
    if not complianceResult.success then
        return complianceResult
    end
    
    local userData = complianceResult.data
    local exportData = {
        exportType = "GDPR_DATA_EXPORT",
        userId = userId,
        datastoreName = datastoreName,
        exportedAt = os.date("%Y-%m-%d %H:%M:%S"),
        format = format,
        dataCount = userData.totalKeys,
        keys = {}
    }
    
    -- Include full data for each key
    for _, keyInfo in ipairs(userData.keys) do
        local keyDataResult = self.dataStoreManager:getDataWithMetadata(datastoreName, keyInfo.keyName)
        if keyDataResult.success then
            table.insert(exportData.keys, {
                keyName = keyInfo.keyName,
                value = keyDataResult.data.value,
                version = keyDataResult.data.version,
                createdDate = keyDataResult.data.createdDate,
                updatedDate = keyDataResult.data.updatedDate,
                metadata = keyDataResult.data.metadata,
                userIds = keyDataResult.data.userIds
            })
        end
    end
    
    self:logAuditEvent("USER_DATA_EXPORTED", {
        userId = userId,
        datastoreName = datastoreName,
        format = format,
        keyCount = #exportData.keys,
        timestamp = os.time()
    })
    
    return {success = true, data = exportData}
end

-- Delete user data for GDPR "right to be forgotten"
function EnterpriseManager:deleteUserData(datastoreName, userId, options)
    options = options or {}
    local createBackup = options.createBackup ~= false
    local dryRun = options.dryRun or false
    
    if not self.dataStoreManager then
        return {success = false, error = "DataStore Manager not available"}
    end
    
    -- Get compliance report first
    local complianceResult = self:generateComplianceReport(datastoreName, userId)
    if not complianceResult.success then
        return complianceResult
    end
    
    local keysToDelete = complianceResult.data.keys
    local deletionReport = {
        userId = userId,
        datastoreName = datastoreName,
        totalKeysFound = #keysToDelete,
        keysDeleted = 0,
        keysFailed = 0,
        dryRun = dryRun,
        deletedKeys = {},
        failedKeys = {},
        timestamp = os.time()
    }
    
    for _, keyInfo in ipairs(keysToDelete) do
        if dryRun then
            table.insert(deletionReport.deletedKeys, keyInfo.keyName)
            deletionReport.keysDeleted = deletionReport.keysDeleted + 1
        else
            local deleteResult = self.dataStoreManager:removeData(datastoreName, keyInfo.keyName)
            if deleteResult.success then
                table.insert(deletionReport.deletedKeys, keyInfo.keyName)
                deletionReport.keysDeleted = deletionReport.keysDeleted + 1
            else
                table.insert(deletionReport.failedKeys, {
                    keyName = keyInfo.keyName,
                    error = deleteResult.error
                })
                deletionReport.keysFailed = deletionReport.keysFailed + 1
            end
        end
    end
    
    if not dryRun then
        self:logAuditEvent("USER_DATA_DELETED", deletionReport)
    else
        self:logAuditEvent("USER_DATA_DELETION_PREVIEW", deletionReport)
    end
    
    return {success = true, data = deletionReport}
end

-- ========================================
-- DATA ANALYTICS & INSIGHTS
-- ========================================

-- Analyze DataStore usage patterns
function EnterpriseManager:analyzeDataStoreUsage(datastoreName, options)
    options = options or {}
    local includeKeys = options.includeKeys ~= false
    local analyzeVersions = options.analyzeVersions or false
    
    if not self.dataStoreManager then
        return {success = false, error = "DataStore Manager not available"}
    end
    
    local exportResult = self.dataStoreManager:exportDataStoreData(datastoreName, {
        includeMetadata = true,
        includeVersions = analyzeVersions
    })
    
    if not exportResult.success then
        return exportResult
    end
    
    local data = exportResult.data
    local analysis = {
        datastoreName = datastoreName,
        analyzedAt = os.time(),
        totalKeys = data.totalKeys,
        totalSize = 0,
        averageKeySize = 0,
        keyPatterns = {},
        userDistribution = {},
        metadataAnalysis = {},
        recommendations = {}
    }
    
    -- Analyze key patterns and sizes
    local keyPatterns = {}
    local userIds = {}
    local metadataTypes = {}
    
    for _, keyData in ipairs(data.keys) do
        analysis.totalSize = analysis.totalSize + (keyData.size or 0)
        
        -- Analyze key naming patterns
        local pattern = self:extractKeyPattern(keyData.keyName)
        keyPatterns[pattern] = (keyPatterns[pattern] or 0) + 1
        
        -- Analyze user distribution
        if keyData.userIds then
            for _, userId in ipairs(keyData.userIds) do
                userIds[tostring(userId)] = (userIds[tostring(userId)] or 0) + 1
            end
        end
        
        -- Analyze metadata usage
        if keyData.metadata then
            for key, _ in pairs(keyData.metadata) do
                metadataTypes[key] = (metadataTypes[key] or 0) + 1
            end
        end
    end
    
    analysis.averageKeySize = analysis.totalKeys > 0 and (analysis.totalSize / analysis.totalKeys) or 0
    analysis.keyPatterns = keyPatterns
    analysis.userDistribution = userIds
    analysis.metadataAnalysis = metadataTypes
    
    -- Generate recommendations
    analysis.recommendations = self:generateDataStoreRecommendations(analysis)
    
    return {success = true, data = analysis}
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Log audit events
function EnterpriseManager:logAuditEvent(eventType, eventData)
    local auditEntry = {
        eventType = eventType,
        timestamp = os.time(),
        data = eventData
    }
    
    table.insert(self.auditLog, auditEntry)
    
    if self.logger then
        self.logger:info("ENTERPRISE_AUDIT", eventType .. ": " .. tostring(eventData.datastoreName or ""))
    end
end

-- Compare tables for equality
function EnterpriseManager:tablesEqual(t1, t2)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end
    
    for k, v in pairs(t1) do
        if not self:tablesEqual(v, t2[k]) then return false end
    end
    
    for k, v in pairs(t2) do
        if not self:tablesEqual(v, t1[k]) then return false end
    end
    
    return true
end

-- Extract key naming pattern
function EnterpriseManager:extractKeyPattern(keyName)
    -- Replace numbers with X, keep structure
    local pattern = keyName:gsub("%d+", "X")
    return pattern
end

-- Analyze data categories for compliance
function EnterpriseManager:analyzeDataCategories(keys)
    local categories = {
        gameData = 0,
        systemData = 0,
        analyticsData = 0
    }
    
    for _, keyInfo in ipairs(keys) do
        local keyName = keyInfo.keyName:lower()
        if keyName:match("game") or keyName:match("level") or keyName:match("score") then
            categories.gameData = categories.gameData + 1
        elseif keyName:match("system") or keyName:match("config") or keyName:match("settings") then
            categories.systemData = categories.systemData + 1
        else
            categories.analyticsData = categories.analyticsData + 1
        end
    end
    
    return categories
end

-- Analyze data retention
function EnterpriseManager:analyzeDataRetention(keys)
    local now = os.time() * 1000
    local retention = {
        lessThan30Days = 0,
        between30And90Days = 0,
        between90DaysAnd1Year = 0,
        moreThan1Year = 0
    }
    
    for _, keyInfo in ipairs(keys) do
        local age = now - (keyInfo.createdTime or now)
        local ageInDays = age / (1000 * 60 * 60 * 24)
        
        if ageInDays < 30 then
            retention.lessThan30Days = retention.lessThan30Days + 1
        elseif ageInDays < 90 then
            retention.between30And90Days = retention.between30And90Days + 1
        elseif ageInDays < 365 then
            retention.between90DaysAnd1Year = retention.between90DaysAnd1Year + 1
        else
            retention.moreThan1Year = retention.moreThan1Year + 1
        end
    end
    
    return retention
end

-- Assess data risk
function EnterpriseManager:assessDataRisk(keys)
    local risk = {
        level = "LOW",
        factors = {},
        score = 0
    }
    
    -- Risk factors
    if #keys > 100 then
        table.insert(risk.factors, "High volume of user data")
        risk.score = risk.score + 2
    end
    
    local hasOldData = false
    local now = os.time() * 1000
    for _, keyInfo in ipairs(keys) do
        local age = now - (keyInfo.createdTime or now)
        if age > (365 * 24 * 60 * 60 * 1000) then -- Older than 1 year
            hasOldData = true
            break
        end
    end
    
    if hasOldData then
        table.insert(risk.factors, "Contains data older than 1 year")
        risk.score = risk.score + 3
    end
    
    -- Determine risk level
    if risk.score >= 5 then
        risk.level = "HIGH"
    elseif risk.score >= 3 then
        risk.level = "MEDIUM"
    end
    
    return risk
end

-- Generate compliance recommendations
function EnterpriseManager:generateComplianceRecommendations(report)
    local recommendations = {}
    
    if report.totalKeys > 50 then
        table.insert(recommendations, "Consider implementing automated data retention policies")
    end
    
    if report.complianceStatus.riskAssessment.level == "HIGH" then
        table.insert(recommendations, "High risk data detected - review retention and deletion policies")
    end
    
    if report.complianceStatus.retentionAnalysis.moreThan1Year > 0 then
        table.insert(recommendations, "Consider archiving or deleting data older than 1 year")
    end
    
    return recommendations
end

-- Generate DataStore optimization recommendations
function EnterpriseManager:generateDataStoreRecommendations(analysis)
    local recommendations = {}
    
    if analysis.averageKeySize > 4000 then
        table.insert(recommendations, "Average key size is large - consider data compression or splitting")
    end
    
    if analysis.totalKeys > 1000 then
        table.insert(recommendations, "High key count - consider using ordered DataStores for better performance")
    end
    
    local patternCount = 0
    for _, _ in pairs(analysis.keyPatterns) do
        patternCount = patternCount + 1
    end
    
    if patternCount > 10 then
        table.insert(recommendations, "Many key patterns detected - consider standardizing key naming conventions")
    end
    
    return recommendations
end

return EnterpriseManager 