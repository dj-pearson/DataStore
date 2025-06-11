-- DataStore Manager Pro - Advanced Bulk Operations Manager
-- High-performance bulk operations with progress tracking, rollback, and smart batching

local BulkOperationsManager = {}
BulkOperationsManager.__index = BulkOperationsManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[BULK_OPERATIONS_MANAGER] [%s] %s", level, message))
end

-- Bulk operations configuration
local BULK_CONFIG = {
    DEFAULT_BATCH_SIZE = 10,
    MAX_BATCH_SIZE = 100,
    MIN_BATCH_SIZE = 1,
    DEFAULT_DELAY = 0.1, -- seconds between batches
    MAX_CONCURRENT_OPERATIONS = 5,
    ROLLBACK_TIMEOUT = 300, -- 5 minutes
    PROGRESS_UPDATE_INTERVAL = 1, -- second
    MAX_RETRY_ATTEMPTS = 3,
    ADAPTIVE_BATCHING = true
}

-- Operation types
local OPERATION_TYPES = {
    CREATE = "create",
    UPDATE = "update",
    DELETE = "delete",
    COPY = "copy",
    MIGRATE = "migrate",
    BACKUP = "backup",
    RESTORE = "restore"
}

-- Operation status
local OPERATION_STATUS = {
    PENDING = "pending",
    RUNNING = "running",
    COMPLETED = "completed",
    FAILED = "failed",
    CANCELLED = "cancelled",
    ROLLING_BACK = "rolling_back",
    ROLLED_BACK = "rolled_back"
}

-- Create new Bulk Operations Manager instance
function BulkOperationsManager.new(services)
    local self = setmetatable({}, BulkOperationsManager)
    
    self.services = services or {}
    self.activeOperations = {}
    self.operationHistory = {}
    self.progressCallbacks = {}
    self.rollbackData = {}
    
    debugLog("Bulk Operations Manager created")
    return self
end

-- Execute bulk operation
function BulkOperationsManager:executeBulkOperation(operationType, items, options)
    options = options or {}
    
    -- Validate operation
    local validationResult = self:validateOperation(operationType, items, options)
    if not validationResult.valid then
        debugLog("Operation validation failed: " .. validationResult.error, "ERROR")
        return {
            success = false,
            error = validationResult.error,
            operationId = nil
        }
    end
    
    -- Create operation
    local operation = self:createOperation(operationType, items, options)
    
    debugLog(string.format("Starting bulk operation: %s with %d items", operationType, #items))
    
    -- Execute operation asynchronously
    task.spawn(function()
        self:executeOperation(operation)
    end)
    
    return {
        success = true,
        operationId = operation.id,
        estimatedDuration = self:estimateDuration(operation)
    }
end

-- Validate bulk operation
function BulkOperationsManager:validateOperation(operationType, items, options)
    -- Check operation type
    local validType = false
    for _, validOpType in pairs(OPERATION_TYPES) do
        if operationType == validOpType then
            validType = true
            break
        end
    end
    
    if not validType then
        return {valid = false, error = "Invalid operation type: " .. tostring(operationType)}
    end
    
    -- Check items
    if not items or #items == 0 then
        return {valid = false, error = "No items provided for bulk operation"}
    end
    
    if #items > 10000 then
        return {valid = false, error = "Too many items - maximum 10,000 items per operation"}
    end
    
    -- Validate batch size
    local batchSize = options.batchSize or BULK_CONFIG.DEFAULT_BATCH_SIZE
    if batchSize < BULK_CONFIG.MIN_BATCH_SIZE or batchSize > BULK_CONFIG.MAX_BATCH_SIZE then
        return {valid = false, error = "Invalid batch size - must be between " .. BULK_CONFIG.MIN_BATCH_SIZE .. " and " .. BULK_CONFIG.MAX_BATCH_SIZE}
    end
    
    -- Operation-specific validation
    if operationType == OPERATION_TYPES.CREATE or operationType == OPERATION_TYPES.UPDATE then
        for i, item in ipairs(items) do
            if not item.key or not item.value then
                return {valid = false, error = "Item " .. i .. " missing key or value"}
            end
        end
    elseif operationType == OPERATION_TYPES.DELETE then
        for i, item in ipairs(items) do
            if not item.key then
                return {valid = false, error = "Item " .. i .. " missing key"}
            end
        end
    end
    
    return {valid = true}
end

-- Create operation object
function BulkOperationsManager:createOperation(operationType, items, options)
    local operationId = Utils.createGUID()
    
    local operation = {
        id = operationId,
        type = operationType,
        items = items,
        options = options,
        status = OPERATION_STATUS.PENDING,
        progress = {
            total = #items,
            processed = 0,
            successful = 0,
            failed = 0,
            percentage = 0
        },
        timing = {
            created = os.time(),
            started = nil,
            completed = nil,
            duration = 0
        },
        batches = {},
        errors = {},
        results = {},
        rollbackData = {},
        canRollback = operationType ~= OPERATION_TYPES.DELETE -- Most operations can be rolled back except delete
    }
    
    -- Prepare batches
    operation.batches = self:prepareBatches(items, options.batchSize or BULK_CONFIG.DEFAULT_BATCH_SIZE)
    
    -- Store operation
    self.activeOperations[operationId] = operation
    
    return operation
end

-- Prepare items into batches
function BulkOperationsManager:prepareBatches(items, batchSize)
    local batches = {}
    local currentBatch = {}
    
    for i, item in ipairs(items) do
        table.insert(currentBatch, item)
        
        if #currentBatch >= batchSize or i == #items then
            table.insert(batches, {
                items = currentBatch,
                index = #batches + 1,
                status = "pending",
                startTime = nil,
                endTime = nil,
                results = {},
                errors = {}
            })
            currentBatch = {}
        end
    end
    
    debugLog(string.format("Prepared %d batches with batch size %d", #batches, batchSize))
    return batches
end

-- Execute operation
function BulkOperationsManager:executeOperation(operation)
    debugLog(string.format("Executing operation %s (%s)", operation.id, operation.type))
    
    operation.status = OPERATION_STATUS.RUNNING
    operation.timing.started = os.time()
    
    -- Execute batches
    for batchIndex, batch in ipairs(operation.batches) do
        if operation.status == OPERATION_STATUS.CANCELLED then
            debugLog("Operation cancelled, stopping execution")
            break
        end
        
        debugLog(string.format("Processing batch %d/%d", batchIndex, #operation.batches))
        
        batch.status = "running"
        batch.startTime = os.time()
        
        -- Execute batch
        local batchResult = self:executeBatch(operation.type, batch, operation.options)
        
        batch.endTime = os.time()
        batch.status = batchResult.success and "completed" or "failed"
        batch.results = batchResult.results or {}
        batch.errors = batchResult.errors or {}
        
        -- Update progress
        self:updateProgress(operation, batch)
        
        -- Store rollback data if needed
        if operation.canRollback and batchResult.rollbackData then
            for _, rollbackItem in ipairs(batchResult.rollbackData) do
                table.insert(operation.rollbackData, rollbackItem)
            end
        end
        
        -- Adaptive batching - adjust batch size based on performance
        if BULK_CONFIG.ADAPTIVE_BATCHING and batchIndex < #operation.batches then
            self:adjustBatchSize(operation, batch, batchIndex)
        end
        
        -- Delay between batches
        if batchIndex < #operation.batches then
            local delay = operation.options.delay or BULK_CONFIG.DEFAULT_DELAY
            task.wait(delay)
        end
    end
    
    -- Complete operation
    self:completeOperation(operation)
end

-- Execute a single batch
function BulkOperationsManager:executeBatch(operationType, batch, options)
    local results = {}
    local errors = {}
    local rollbackData = {}
    local successCount = 0
    
    for _, item in ipairs(batch.items) do
        local success, result, rollback = self:executeItem(operationType, item, options)
        
        if success then
            successCount = successCount + 1
            table.insert(results, result)
            if rollback then
                table.insert(rollbackData, rollback)
            end
        else
            table.insert(errors, {
                item = item,
                error = result
            })
        end
    end
    
    return {
        success = successCount == #batch.items,
        successCount = successCount,
        totalCount = #batch.items,
        results = results,
        errors = errors,
        rollbackData = #rollbackData > 0 and rollbackData or nil
    }
end

-- Execute a single item
function BulkOperationsManager:executeItem(operationType, item, options)
    local retryCount = 0
    local maxRetries = options.maxRetries or BULK_CONFIG.MAX_RETRY_ATTEMPTS
    
    while retryCount <= maxRetries do
        local success, result, rollback = self:performItemOperation(operationType, item, options)
        
        if success then
            return true, result, rollback
        else
            retryCount = retryCount + 1
            if retryCount <= maxRetries then
                debugLog(string.format("Retrying item operation (attempt %d/%d): %s", retryCount, maxRetries, tostring(result)))
                task.wait(0.1 * retryCount) -- Exponential backoff
            end
        end
    end
    
    return false, "Max retries exceeded", nil
end

-- Perform actual item operation
function BulkOperationsManager:performItemOperation(operationType, item, options)
    -- Mock implementation - would integrate with actual DataStore services
    debugLog(string.format("Performing %s operation on key: %s", operationType, item.key or "unknown"))
    
    -- Simulate operation delay
    task.wait(math.random(1, 50) / 1000) -- 1-50ms
    
    -- Simulate occasional failures
    local success = math.random() > 0.05 -- 95% success rate
    
    if not success then
        return false, "Simulated operation failure", nil
    end
    
    local result = {
        key = item.key,
        operation = operationType,
        timestamp = os.time()
    }
    
    local rollback = nil
    if operationType == OPERATION_TYPES.UPDATE then
        -- For updates, store the previous value for rollback
        rollback = {
            key = item.key,
            previousValue = "mock_previous_value",
            operation = "rollback_update"
        }
    elseif operationType == OPERATION_TYPES.CREATE then
        -- For creates, store delete operation for rollback
        rollback = {
            key = item.key,
            operation = "rollback_create"
        }
    end
    
    return true, result, rollback
end

-- Update operation progress
function BulkOperationsManager:updateProgress(operation, completedBatch)
    local totalProcessed = 0
    local totalSuccessful = 0
    local totalFailed = 0
    
    for _, batch in ipairs(operation.batches) do
        if batch.status == "completed" or batch.status == "failed" then
            totalProcessed = totalProcessed + #batch.items
            totalSuccessful = totalSuccessful + #batch.results
            totalFailed = totalFailed + #batch.errors
        end
    end
    
    operation.progress.processed = totalProcessed
    operation.progress.successful = totalSuccessful
    operation.progress.failed = totalFailed
    operation.progress.percentage = (totalProcessed / operation.progress.total) * 100
    
    -- Notify progress callbacks
    if self.progressCallbacks[operation.id] then
        for _, callback in ipairs(self.progressCallbacks[operation.id]) do
            local success, error = pcall(callback, operation.progress)
            if not success then
                debugLog("Error in progress callback: " .. tostring(error), "ERROR")
            end
        end
    end
    
    debugLog(string.format("Progress updated: %.1f%% (%d/%d)", 
        operation.progress.percentage, operation.progress.processed, operation.progress.total))
end

-- Adjust batch size based on performance
function BulkOperationsManager:adjustBatchSize(operation, completedBatch, batchIndex)
    local batchDuration = completedBatch.endTime - completedBatch.startTime
    local itemsPerSecond = #completedBatch.items / batchDuration
    
    -- Target 2-5 seconds per batch
    local targetDuration = 3
    local optimalBatchSize = math.floor(itemsPerSecond * targetDuration)
    
    -- Clamp to valid range
    optimalBatchSize = math.max(BULK_CONFIG.MIN_BATCH_SIZE, 
        math.min(BULK_CONFIG.MAX_BATCH_SIZE, optimalBatchSize))
    
    -- Adjust remaining batches if batch size changed significantly
    local currentBatchSize = #completedBatch.items
    if math.abs(optimalBatchSize - currentBatchSize) > 2 then
        debugLog(string.format("Adjusting batch size from %d to %d based on performance", 
            currentBatchSize, optimalBatchSize))
        
        -- Redistribute remaining items
        self:redistributeBatches(operation, batchIndex + 1, optimalBatchSize)
    end
end

-- Redistribute remaining batches with new batch size
function BulkOperationsManager:redistributeBatches(operation, startIndex, newBatchSize)
    if startIndex >= #operation.batches then
        return
    end
    
    -- Collect all remaining items
    local remainingItems = {}
    for i = startIndex, #operation.batches do
        for _, item in ipairs(operation.batches[i].items) do
            table.insert(remainingItems, item)
        end
    end
    
    -- Remove old batches
    for i = #operation.batches, startIndex, -1 do
        table.remove(operation.batches, i)
    end
    
    -- Create new batches
    local newBatches = self:prepareBatches(remainingItems, newBatchSize)
    for i, batch in ipairs(newBatches) do
        batch.index = startIndex + i - 1
        table.insert(operation.batches, batch)
    end
end

-- Complete operation
function BulkOperationsManager:completeOperation(operation)
    operation.timing.completed = os.time()
    operation.timing.duration = operation.timing.completed - operation.timing.started
    
    if operation.progress.failed == 0 then
        operation.status = OPERATION_STATUS.COMPLETED
    else
        operation.status = OPERATION_STATUS.FAILED
    end
    
    debugLog(string.format("Operation %s completed: %s (%.1fs, %d/%d successful)", 
        operation.id, operation.status, operation.timing.duration, 
        operation.progress.successful, operation.progress.total))
    
    -- Move to history
    self.operationHistory[operation.id] = operation
    self.activeOperations[operation.id] = nil
    
    -- Clean up progress callbacks
    self.progressCallbacks[operation.id] = nil
end

-- Cancel operation
function BulkOperationsManager:cancelOperation(operationId)
    local operation = self.activeOperations[operationId]
    if not operation then
        return false, "Operation not found or already completed"
    end
    
    if operation.status ~= OPERATION_STATUS.RUNNING and operation.status ~= OPERATION_STATUS.PENDING then
        return false, "Operation cannot be cancelled in current status: " .. operation.status
    end
    
    operation.status = OPERATION_STATUS.CANCELLED
    debugLog("Operation cancelled: " .. operationId)
    
    return true
end

-- Rollback operation
function BulkOperationsManager:rollbackOperation(operationId)
    local operation = self.operationHistory[operationId] or self.activeOperations[operationId]
    if not operation then
        return false, "Operation not found"
    end
    
    if not operation.canRollback then
        return false, "Operation cannot be rolled back"
    end
    
    if #operation.rollbackData == 0 then
        return false, "No rollback data available"
    end
    
    debugLog("Starting rollback for operation: " .. operationId)
    
    -- Create rollback operation
    local rollbackItems = {}
    for _, rollbackItem in ipairs(operation.rollbackData) do
        table.insert(rollbackItems, rollbackItem)
    end
    
    local rollbackOptions = {
        batchSize = operation.options.batchSize or BULK_CONFIG.DEFAULT_BATCH_SIZE,
        delay = operation.options.delay or BULK_CONFIG.DEFAULT_DELAY,
        isRollback = true,
        originalOperationId = operationId
    }
    
    -- Execute rollback
    return self:executeBulkOperation("rollback", rollbackItems, rollbackOptions)
end

-- Get operation status
function BulkOperationsManager:getOperationStatus(operationId)
    local operation = self.activeOperations[operationId] or self.operationHistory[operationId]
    if not operation then
        return nil
    end
    
    return {
        id = operation.id,
        type = operation.type,
        status = operation.status,
        progress = operation.progress,
        timing = operation.timing,
        canRollback = operation.canRollback,
        errors = operation.errors
    }
end

-- Add progress callback
function BulkOperationsManager:addProgressCallback(operationId, callback)
    if not self.progressCallbacks[operationId] then
        self.progressCallbacks[operationId] = {}
    end
    
    table.insert(self.progressCallbacks[operationId], callback)
end

-- Get active operations
function BulkOperationsManager:getActiveOperations()
    local operations = {}
    for id, operation in pairs(self.activeOperations) do
        table.insert(operations, {
            id = id,
            type = operation.type,
            status = operation.status,
            progress = operation.progress,
            timing = operation.timing
        })
    end
    
    return operations
end

-- Get operation history
function BulkOperationsManager:getOperationHistory(limit)
    limit = limit or 50
    
    local history = {}
    for id, operation in pairs(self.operationHistory) do
        table.insert(history, {
            id = id,
            type = operation.type,
            status = operation.status,
            progress = operation.progress,
            timing = operation.timing
        })
    end
    
    -- Sort by completion time (newest first)
    table.sort(history, function(a, b)
        return a.timing.completed > b.timing.completed
    end)
    
    -- Limit results
    local limitedHistory = {}
    for i = 1, math.min(limit, #history) do
        table.insert(limitedHistory, history[i])
    end
    
    return limitedHistory
end

-- Estimate operation duration
function BulkOperationsManager:estimateDuration(operation)
    -- Base estimate: 50ms per item + batch overhead
    local baseTimePerItem = 0.05 -- 50ms
    local batchOverhead = 0.1 -- 100ms per batch
    
    local totalItems = operation.progress.total
    local numBatches = #operation.batches
    local delay = operation.options.delay or BULK_CONFIG.DEFAULT_DELAY
    
    local estimatedTime = (totalItems * baseTimePerItem) + 
                         (numBatches * batchOverhead) + 
                         ((numBatches - 1) * delay)
    
    return math.ceil(estimatedTime)
end

-- Get statistics
function BulkOperationsManager:getStatistics()
    local stats = {
        active = {
            total = 0,
            byType = {},
            byStatus = {}
        },
        historical = {
            total = 0,
            successful = 0,
            failed = 0,
            totalItemsProcessed = 0,
            averageDuration = 0
        }
    }
    
    -- Active operations stats
    for _, operation in pairs(self.activeOperations) do
        stats.active.total = stats.active.total + 1
        stats.active.byType[operation.type] = (stats.active.byType[operation.type] or 0) + 1
        stats.active.byStatus[operation.status] = (stats.active.byStatus[operation.status] or 0) + 1
    end
    
    -- Historical stats
    local totalDuration = 0
    for _, operation in pairs(self.operationHistory) do
        stats.historical.total = stats.historical.total + 1
        stats.historical.totalItemsProcessed = stats.historical.totalItemsProcessed + operation.progress.total
        totalDuration = totalDuration + operation.timing.duration
        
        if operation.status == OPERATION_STATUS.COMPLETED then
            stats.historical.successful = stats.historical.successful + 1
        else
            stats.historical.failed = stats.historical.failed + 1
        end
    end
    
    if stats.historical.total > 0 then
        stats.historical.averageDuration = totalDuration / stats.historical.total
    end
    
    return stats
end

-- Cleanup completed operations
function BulkOperationsManager:cleanup(maxAge)
    maxAge = maxAge or 86400 -- 24 hours default
    local cutoff = os.time() - maxAge
    
    local cleaned = 0
    for id, operation in pairs(self.operationHistory) do
        if operation.timing.completed and operation.timing.completed < cutoff then
            self.operationHistory[id] = nil
            cleaned = cleaned + 1
        end
    end
    
    debugLog(string.format("Cleaned up %d old operations", cleaned))
    return cleaned
end

return BulkOperationsManager 