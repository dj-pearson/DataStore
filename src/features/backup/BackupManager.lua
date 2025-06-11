-- DataStore Manager Pro - Advanced Backup Manager
-- Automated backups, incremental backups, compression, and restore functionality

local BackupManager = {}
BackupManager.__index = BackupManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[BACKUP_MANAGER] [%s] %s", level, message))
end

-- Backup configuration
local BACKUP_CONFIG = {
    DEFAULT_SCHEDULE = "daily", -- daily, weekly, hourly
    MAX_BACKUPS = 30, -- Maximum number of backups to keep
    COMPRESSION_ENABLED = true,
    INCREMENTAL_BACKUPS = true,
    BACKUP_FORMATS = {"json", "compressed", "incremental"},
    AUTO_CLEANUP_ENABLED = true,
    VERIFICATION_ENABLED = true,
    ENCRYPTION_ENABLED = false -- Enterprise feature
}

-- Backup types
local BACKUP_TYPES = {
    FULL = "full",
    INCREMENTAL = "incremental",
    DIFFERENTIAL = "differential",
    MANUAL = "manual",
    SCHEDULED = "scheduled"
}

-- Backup status
local BACKUP_STATUS = {
    PENDING = "pending",
    RUNNING = "running",
    COMPLETED = "completed",
    FAILED = "failed",
    VERIFYING = "verifying",
    VERIFIED = "verified",
    CORRUPTED = "corrupted"
}

-- Create new Backup Manager instance
function BackupManager.new(services)
    local self = setmetatable({}, BackupManager)
    
    self.services = services or {}
    self.backups = {}
    self.schedules = {}
    self.settings = {
        autoBackup = true,
        compressionLevel = 6, -- 1-9 scale
        maxBackups = BACKUP_CONFIG.MAX_BACKUPS,
        backupLocation = "DataStoreBackups",
        includeMetadata = true,
        verifyBackups = true
    }
    
    -- Initialize backup storage
    self:initializeBackupStorage()
    
    debugLog("Backup Manager created")
    return self
end

-- Initialize backup storage
function BackupManager:initializeBackupStorage()
    -- In a real implementation, this would set up file system or cloud storage
    self.backupStorage = {
        location = self.settings.backupLocation,
        available = true,
        freeSpace = 1000000000, -- 1GB mock free space
        usedSpace = 0
    }
    
    debugLog("Backup storage initialized at: " .. self.backupStorage.location)
end

-- Create backup
function BackupManager:createBackup(options)
    options = options or {}
    
    local backupId = Utils.createGUID()
    local backupType = options.type or BACKUP_TYPES.MANUAL
    local format = options.format or "json"
    local includeData = options.includeData ~= false
    local includeMetadata = options.includeMetadata ~= false
    
    debugLog(string.format("Starting backup creation: %s (%s)", backupId, backupType))
    
    local backup = {
        id = backupId,
        type = backupType,
        format = format,
        status = BACKUP_STATUS.PENDING,
        created = os.time(),
        completed = nil,
        size = 0,
        compressedSize = 0,
        compressionRatio = 0,
        dataStores = {},
        metadata = {
            version = "1.0",
            creator = "DataStore Manager Pro",
            includeData = includeData,
            includeMetadata = includeMetadata,
            originalSize = 0,
            checksum = nil
        },
        verification = {
            verified = false,
            verificationTime = nil,
            integrity = "unknown"
        },
        progress = {
            percentage = 0,
            currentDataStore = nil,
            processed = 0,
            total = 0
        }
    }
    
    self.backups[backupId] = backup
    
    -- Execute backup asynchronously
    task.spawn(function()
        self:executeBackup(backup, options)
    end)
    
    return {
        success = true,
        backupId = backupId,
        estimatedSize = self:estimateBackupSize(options)
    }
end

-- Execute backup
function BackupManager:executeBackup(backup, options)
    backup.status = BACKUP_STATUS.RUNNING
    
    debugLog(string.format("Executing backup %s", backup.id))
    
    local success, error = pcall(function()
        -- Get list of DataStores to backup
        local dataStores = self:getDataStoresToBackup(options)
        backup.progress.total = #dataStores
        
        debugLog(string.format("Backing up %d DataStores", #dataStores))
        
        -- Backup each DataStore
        for i, dataStoreName in ipairs(dataStores) do
            backup.progress.currentDataStore = dataStoreName
            backup.progress.processed = i - 1
            backup.progress.percentage = ((i - 1) / #dataStores) * 100
            
            local dataStoreBackup = self:backupDataStore(dataStoreName, backup, options)
            backup.dataStores[dataStoreName] = dataStoreBackup
            
            -- Update size
            backup.size = backup.size + dataStoreBackup.size
            backup.metadata.originalSize = backup.metadata.originalSize + dataStoreBackup.originalSize
        end
        
        -- Compress if enabled
        if BACKUP_CONFIG.COMPRESSION_ENABLED and backup.format ~= "incremental" then
            self:compressBackup(backup)
        end
        
        -- Generate checksum
        backup.metadata.checksum = self:generateChecksum(backup)
        
        backup.progress.percentage = 100
        backup.completed = os.time()
        backup.status = BACKUP_STATUS.COMPLETED
        
        debugLog(string.format("Backup %s completed successfully (%.2f MB)", 
            backup.id, backup.size / 1024 / 1024))
    end)
    
    if not success then
        backup.status = BACKUP_STATUS.FAILED
        backup.error = error
        debugLog(string.format("Backup %s failed: %s", backup.id, tostring(error)), "ERROR")
    end
    
    -- Verify backup if enabled
    if backup.status == BACKUP_STATUS.COMPLETED and self.settings.verifyBackups then
        task.spawn(function()
            self:verifyBackup(backup.id)
        end)
    end
    
    -- Clean up old backups if auto-cleanup is enabled
    if BACKUP_CONFIG.AUTO_CLEANUP_ENABLED then
        self:cleanupOldBackups()
    end
end

-- Get DataStores to backup
function BackupManager:getDataStoresToBackup(options)
    if options.dataStores then
        return options.dataStores
    end
    
    -- Mock DataStore list - would integrate with actual DataStore service
    return {
        "PlayerData",
        "GameSettings", 
        "UserPreferences",
        "Leaderboards",
        "Achievements",
        "GameState"
    }
end

-- Backup individual DataStore
function BackupManager:backupDataStore(dataStoreName, backup, options)
    debugLog(string.format("Backing up DataStore: %s", dataStoreName))
    
    local dataStoreBackup = {
        name = dataStoreName,
        keys = {},
        metadata = {
            backupTime = os.time(),
            keyCount = 0,
            totalSize = 0
        },
        size = 0,
        originalSize = 0
    }
    
    -- Get keys from DataStore (mock implementation)
    local keys = self:getDataStoreKeys(dataStoreName)
    dataStoreBackup.metadata.keyCount = #keys
    
    -- Backup each key
    for _, key in ipairs(keys) do
        local keyData = self:getKeyData(dataStoreName, key)
        if keyData then
            local keyBackup = {
                key = key,
                value = keyData.value,
                metadata = keyData.metadata,
                size = self:calculateDataSize(keyData.value),
                backupTime = os.time()
            }
            
            dataStoreBackup.keys[key] = keyBackup
            dataStoreBackup.size = dataStoreBackup.size + keyBackup.size
            dataStoreBackup.originalSize = dataStoreBackup.originalSize + keyBackup.size
        end
    end
    
    dataStoreBackup.metadata.totalSize = dataStoreBackup.size
    
    debugLog(string.format("DataStore %s backed up: %d keys, %.2f KB", 
        dataStoreName, #keys, dataStoreBackup.size / 1024))
    
    return dataStoreBackup
end

-- Get DataStore keys (mock implementation)
function BackupManager:getDataStoreKeys(dataStoreName)
    -- Mock implementation - would integrate with actual DataStore service
    local mockKeys = {}
    local keyCount = math.random(10, 100)
    
    for i = 1, keyCount do
        table.insert(mockKeys, string.format("key_%s_%d", dataStoreName, i))
    end
    
    return mockKeys
end

-- Get key data (mock implementation)
function BackupManager:getKeyData(dataStoreName, key)
    -- Mock implementation
    return {
        value = {
            id = key,
            dataStore = dataStoreName,
            data = string.format("Mock data for %s in %s", key, dataStoreName),
            timestamp = os.time()
        },
        metadata = {
            size = math.random(100, 5000),
            lastModified = os.time() - math.random(0, 86400),
            version = 1
        }
    }
end

-- Calculate data size
function BackupManager:calculateDataSize(data)
    -- Simple size calculation - in real implementation would be more accurate
    if type(data) == "string" then
        return #data
    elseif type(data) == "table" then
        local size = 0
        for k, v in pairs(data) do
            size = size + self:calculateDataSize(k) + self:calculateDataSize(v)
        end
        return size
    else
        return string.len(tostring(data))
    end
end

-- Compress backup
function BackupManager:compressBackup(backup)
    debugLog(string.format("Compressing backup %s", backup.id))
    
    backup.status = "compressing"
    
    -- Mock compression - in real implementation would use actual compression
    local compressionRatio = 0.3 + (math.random() * 0.4) -- 30-70% compression
    backup.compressedSize = math.floor(backup.size * compressionRatio)
    backup.compressionRatio = (backup.size - backup.compressedSize) / backup.size
    
    debugLog(string.format("Backup compressed: %.2f MB -> %.2f MB (%.1f%% reduction)", 
        backup.size / 1024 / 1024, backup.compressedSize / 1024 / 1024, 
        backup.compressionRatio * 100))
end

-- Generate checksum
function BackupManager:generateChecksum(backup)
    -- Mock checksum generation
    local checksum = string.format("SHA256_%s_%d", backup.id:sub(1, 8), backup.size)
    debugLog(string.format("Generated checksum for backup %s: %s", backup.id, checksum))
    return checksum
end

-- Verify backup
function BackupManager:verifyBackup(backupId)
    local backup = self.backups[backupId]
    if not backup then
        debugLog("Cannot verify backup - backup not found: " .. tostring(backupId), "ERROR")
        return false
    end
    
    debugLog(string.format("Verifying backup %s", backupId))
    backup.status = BACKUP_STATUS.VERIFYING
    
    -- Mock verification process
    task.wait(1 + math.random() * 2) -- 1-3 seconds
    
    local verificationSuccess = math.random() > 0.05 -- 95% success rate
    
    if verificationSuccess then
        backup.verification.verified = true
        backup.verification.verificationTime = os.time()
        backup.verification.integrity = "valid"
        backup.status = BACKUP_STATUS.VERIFIED
        
        debugLog(string.format("Backup %s verification successful", backupId))
    else
        backup.verification.verified = false
        backup.verification.verificationTime = os.time()
        backup.verification.integrity = "corrupted"
        backup.status = BACKUP_STATUS.CORRUPTED
        
        debugLog(string.format("Backup %s verification failed - backup corrupted", backupId), "ERROR")
    end
    
    return verificationSuccess
end

-- Restore from backup
function BackupManager:restoreFromBackup(backupId, options)
    local backup = self.backups[backupId]
    if not backup then
        return {
            success = false,
            error = "Backup not found: " .. tostring(backupId)
        }
    end
    
    if backup.status ~= BACKUP_STATUS.VERIFIED and backup.status ~= BACKUP_STATUS.COMPLETED then
        return {
            success = false,
            error = "Backup is not in a valid state for restore: " .. backup.status
        }
    end
    
    options = options or {}
    local restoreId = Utils.createGUID()
    
    debugLog(string.format("Starting restore from backup %s (restore ID: %s)", backupId, restoreId))
    
    -- Execute restore asynchronously
    task.spawn(function()
        self:executeRestore(backup, restoreId, options)
    end)
    
    return {
        success = true,
        restoreId = restoreId,
        backupId = backupId
    }
end

-- Execute restore
function BackupManager:executeRestore(backup, restoreId, options)
    debugLog(string.format("Executing restore %s from backup %s", restoreId, backup.id))
    
    local restore = {
        id = restoreId,
        backupId = backup.id,
        status = "running",
        started = os.time(),
        completed = nil,
        progress = {
            percentage = 0,
            currentDataStore = nil,
            processed = 0,
            total = 0
        },
        results = {
            dataStoresRestored = 0,
            keysRestored = 0,
            errors = {}
        }
    }
    
    local success, error = pcall(function()
        local dataStoreNames = {}
        for dataStoreName, _ in pairs(backup.dataStores) do
            table.insert(dataStoreNames, dataStoreName)
        end
        
        restore.progress.total = #dataStoreNames
        
        -- Restore each DataStore
        for i, dataStoreName in ipairs(dataStoreNames) do
            if options.dataStores and not options.dataStores[dataStoreName] then
                -- Skip if specific DataStores were requested and this isn't one
                continue
            end
            
            restore.progress.currentDataStore = dataStoreName
            restore.progress.processed = i - 1
            restore.progress.percentage = ((i - 1) / #dataStoreNames) * 100
            
            local restoreResult = self:restoreDataStore(dataStoreName, backup.dataStores[dataStoreName], options)
            
            if restoreResult.success then
                restore.results.dataStoresRestored = restore.results.dataStoresRestored + 1
                restore.results.keysRestored = restore.results.keysRestored + restoreResult.keysRestored
            else
                table.insert(restore.results.errors, {
                    dataStore = dataStoreName,
                    error = restoreResult.error
                })
            end
        end
        
        restore.progress.percentage = 100
        restore.completed = os.time()
        restore.status = "completed"
        
        debugLog(string.format("Restore %s completed: %d DataStores, %d keys restored", 
            restoreId, restore.results.dataStoresRestored, restore.results.keysRestored))
    end)
    
    if not success then
        restore.status = "failed"
        restore.error = error
        debugLog(string.format("Restore %s failed: %s", restoreId, tostring(error)), "ERROR")
    end
end

-- Restore individual DataStore
function BackupManager:restoreDataStore(dataStoreName, dataStoreBackup, options)
    debugLog(string.format("Restoring DataStore: %s", dataStoreName))
    
    local keysRestored = 0
    local errors = {}
    
    for key, keyBackup in pairs(dataStoreBackup.keys) do
        local success, error = self:restoreKey(dataStoreName, key, keyBackup, options)
        if success then
            keysRestored = keysRestored + 1
        else
            table.insert(errors, {
                key = key,
                error = error
            })
        end
    end
    
    debugLog(string.format("DataStore %s restored: %d keys successful, %d errors", 
        dataStoreName, keysRestored, #errors))
    
    return {
        success = #errors == 0,
        keysRestored = keysRestored,
        errors = errors
    }
end

-- Restore individual key
function BackupManager:restoreKey(dataStoreName, key, keyBackup, options)
    -- Mock restore implementation
    debugLog(string.format("Restoring key %s in DataStore %s", key, dataStoreName))
    
    -- Simulate occasional restore failures
    if math.random() > 0.95 then -- 5% failure rate
        return false, "Mock restore failure"
    end
    
    -- In real implementation, would write to actual DataStore
    task.wait(math.random(1, 10) / 1000) -- 1-10ms delay
    
    return true
end

-- Schedule automatic backups
function BackupManager:scheduleBackup(schedule, options)
    local scheduleId = Utils.createGUID()
    
    local scheduleConfig = {
        id = scheduleId,
        type = schedule.type or "daily", -- daily, weekly, hourly
        time = schedule.time or "02:00", -- 2 AM default
        enabled = schedule.enabled ~= false,
        options = options or {},
        lastRun = nil,
        nextRun = self:calculateNextRun(schedule),
        created = os.time()
    }
    
    self.schedules[scheduleId] = scheduleConfig
    
    debugLog(string.format("Backup scheduled: %s (%s at %s)", 
        scheduleId, scheduleConfig.type, scheduleConfig.time))
    
    return scheduleId
end

-- Calculate next run time
function BackupManager:calculateNextRun(schedule)
    local now = os.time()
    local timeTable = os.date("*t", now)
    
    -- Parse schedule time
    local hour, minute = schedule.time:match("(%d+):(%d+)")
    hour = tonumber(hour) or 2
    minute = tonumber(minute) or 0
    
    -- Calculate next run based on schedule type
    if schedule.type == "daily" then
        local nextRun = os.time({
            year = timeTable.year,
            month = timeTable.month,
            day = timeTable.day,
            hour = hour,
            min = minute,
            sec = 0
        })
        
        -- If time has passed today, schedule for tomorrow
        if nextRun <= now then
            nextRun = nextRun + 86400 -- Add 24 hours
        end
        
        return nextRun
    elseif schedule.type == "weekly" then
        -- Schedule for next Sunday at specified time
        local daysUntilSunday = (7 - timeTable.wday + 1) % 7
        if daysUntilSunday == 0 then daysUntilSunday = 7 end
        
        return now + (daysUntilSunday * 86400) + (hour * 3600) + (minute * 60)
    elseif schedule.type == "hourly" then
        return now + 3600 -- Next hour
    end
    
    return now + 86400 -- Default to daily
end

-- Check and execute scheduled backups
function BackupManager:checkScheduledBackups()
    local now = os.time()
    
    for scheduleId, schedule in pairs(self.schedules) do
        if schedule.enabled and schedule.nextRun <= now then
            debugLog(string.format("Executing scheduled backup: %s", scheduleId))
            
            -- Create backup with scheduled type
            local backupOptions = schedule.options
            backupOptions.type = BACKUP_TYPES.SCHEDULED
            backupOptions.scheduleId = scheduleId
            
            local result = self:createBackup(backupOptions)
            
            if result.success then
                schedule.lastRun = now
                schedule.nextRun = self:calculateNextRun(schedule)
                debugLog(string.format("Scheduled backup created: %s (next run: %s)", 
                    result.backupId, os.date("%c", schedule.nextRun)))
            else
                debugLog(string.format("Scheduled backup failed for schedule %s", scheduleId), "ERROR")
            end
        end
    end
end

-- Clean up old backups
function BackupManager:cleanupOldBackups()
    local sortedBackups = {}
    for id, backup in pairs(self.backups) do
        if backup.status == BACKUP_STATUS.COMPLETED or backup.status == BACKUP_STATUS.VERIFIED then
            table.insert(sortedBackups, {id = id, created = backup.created})
        end
    end
    
    -- Sort by creation time (newest first)
    table.sort(sortedBackups, function(a, b)
        return a.created > b.created
    end)
    
    -- Remove excess backups
    local removedCount = 0
    for i = self.settings.maxBackups + 1, #sortedBackups do
        local backup = sortedBackups[i]
        self.backups[backup.id] = nil
        removedCount = removedCount + 1
        debugLog(string.format("Removed old backup: %s", backup.id))
    end
    
    if removedCount > 0 then
        debugLog(string.format("Cleaned up %d old backups", removedCount))
    end
    
    return removedCount
end

-- Get backup list
function BackupManager:getBackups(options)
    options = options or {}
    
    local backups = {}
    for id, backup in pairs(self.backups) do
        local backupInfo = {
            id = id,
            type = backup.type,
            status = backup.status,
            created = backup.created,
            completed = backup.completed,
            size = backup.size,
            compressedSize = backup.compressedSize,
            compressionRatio = backup.compressionRatio,
            dataStoreCount = 0,
            verification = backup.verification
        }
        
        -- Count DataStores
        for _ in pairs(backup.dataStores) do
            backupInfo.dataStoreCount = backupInfo.dataStoreCount + 1
        end
        
        table.insert(backups, backupInfo)
    end
    
    -- Sort by creation time (newest first)
    table.sort(backups, function(a, b)
        return a.created > b.created
    end)
    
    -- Apply limit if specified
    if options.limit then
        local limitedBackups = {}
        for i = 1, math.min(options.limit, #backups) do
            table.insert(limitedBackups, backups[i])
        end
        return limitedBackups
    end
    
    return backups
end

-- Get backup details
function BackupManager:getBackupDetails(backupId)
    return self.backups[backupId]
end

-- Delete backup
function BackupManager:deleteBackup(backupId)
    local backup = self.backups[backupId]
    if not backup then
        return false, "Backup not found"
    end
    
    self.backups[backupId] = nil
    debugLog(string.format("Backup deleted: %s", backupId))
    
    return true
end

-- Get backup statistics
function BackupManager:getStatistics()
    local stats = {
        total = 0,
        byStatus = {},
        byType = {},
        totalSize = 0,
        totalCompressedSize = 0,
        averageCompressionRatio = 0,
        oldestBackup = nil,
        newestBackup = nil,
        schedules = {
            total = 0,
            enabled = 0,
            disabled = 0
        }
    }
    
    local totalCompressionRatio = 0
    local compressionCount = 0
    local oldestTime = math.huge
    local newestTime = 0
    
    for id, backup in pairs(self.backups) do
        stats.total = stats.total + 1
        stats.byStatus[backup.status] = (stats.byStatus[backup.status] or 0) + 1
        stats.byType[backup.type] = (stats.byType[backup.type] or 0) + 1
        stats.totalSize = stats.totalSize + backup.size
        stats.totalCompressedSize = stats.totalCompressedSize + (backup.compressedSize or backup.size)
        
        if backup.compressionRatio > 0 then
            totalCompressionRatio = totalCompressionRatio + backup.compressionRatio
            compressionCount = compressionCount + 1
        end
        
        if backup.created < oldestTime then
            oldestTime = backup.created
            stats.oldestBackup = backup.created
        end
        
        if backup.created > newestTime then
            newestTime = backup.created
            stats.newestBackup = backup.created
        end
    end
    
    if compressionCount > 0 then
        stats.averageCompressionRatio = totalCompressionRatio / compressionCount
    end
    
    -- Schedule statistics
    for _, schedule in pairs(self.schedules) do
        stats.schedules.total = stats.schedules.total + 1
        if schedule.enabled then
            stats.schedules.enabled = stats.schedules.enabled + 1
        else
            stats.schedules.disabled = stats.schedules.disabled + 1
        end
    end
    
    return stats
end

-- Estimate backup size
function BackupManager:estimateBackupSize(options)
    -- Mock estimation - would calculate based on actual DataStore sizes
    local baseSize = math.random(1000000, 50000000) -- 1-50 MB
    
    if options.includeMetadata then
        baseSize = baseSize * 1.1 -- Add 10% for metadata
    end
    
    if BACKUP_CONFIG.COMPRESSION_ENABLED then
        baseSize = baseSize * 0.6 -- Assume 40% compression
    end
    
    return baseSize
end

return BackupManager 