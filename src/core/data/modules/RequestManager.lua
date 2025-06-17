-- DataStore Manager Pro - Request Manager Module
-- Handles API rate limiting, request budgets, and throttling

local RequestManager = {}
RequestManager.__index = RequestManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[REQUEST_MANAGER] [%s] %s", level, message))
end

-- Create new Request Manager instance
function RequestManager.new(config)
    local self = setmetatable({}, RequestManager)
    
    self.config = config or {}
    
    -- Request budget tracking
    self.requestBudget = Constants.DATASTORE.REQUEST_BUDGET_LIMIT
    self.lastRequestTime = 0
    self.requestHistory = {}
    
    -- Throttling state
    self.isThrottled = false
    self.throttleEndTime = 0
    self.throttleReason = nil
    
    -- Request statistics
    self.stats = {
        totalRequests = 0,
        successfulRequests = 0,
        failedRequests = 0,
        throttledRequests = 0,
        averageLatency = 0,
        totalLatency = 0
    }
    
    -- Request queue for throttled operations
    self.requestQueue = {}
    self.isProcessingQueue = false
    
    debugLog("RequestManager initialized with budget limit: " .. self.requestBudget)
    return self
end

-- Check if request can be made
function RequestManager:canMakeRequest()
    local now = tick()
    
    -- Check if currently throttled
    if self.isThrottled and now < self.throttleEndTime then
        return false, "THROTTLED", "Request throttled: " .. (self.throttleReason or "Rate limit exceeded")
    elseif self.isThrottled and now >= self.throttleEndTime then
        -- Throttle period has ended
        self:clearThrottle()
    end
    
    -- Check request budget
    if not self:checkRequestBudget() then
        return false, "BUDGET_EXCEEDED", "Request budget exceeded"
    end
    
    return true, "OK", "Request allowed"
end

-- Check and update request budget
function RequestManager:checkRequestBudget()
    local now = tick()
    local timeSinceLastRequest = now - self.lastRequestTime
    
    -- Replenish budget over time
    if timeSinceLastRequest >= Constants.DATASTORE.REQUEST_COOLDOWN then
        local replenishAmount = math.floor(timeSinceLastRequest / Constants.DATASTORE.REQUEST_COOLDOWN)
        self.requestBudget = math.min(
            self.requestBudget + replenishAmount,
            Constants.DATASTORE.REQUEST_BUDGET_LIMIT
        )
    end
    
    return self.requestBudget > 0
end

-- Consume request budget
function RequestManager:consumeRequestBudget()
    if self.requestBudget > 0 then
        self.requestBudget = self.requestBudget - 1
        self.lastRequestTime = tick()
        return true
    end
    return false
end

-- Execute request with budget management
function RequestManager:executeRequest(requestFunc, requestType, retryCount)
    retryCount = retryCount or 0
    local startTime = tick()
    
    -- Check if request can be made
    local canMake, reason, message = self:canMakeRequest()
    if not canMake then
        self.stats.throttledRequests = self.stats.throttledRequests + 1
        return false, reason, message
    end
    
    -- Consume budget
    if not self:consumeRequestBudget() then
        self.stats.throttledRequests = self.stats.throttledRequests + 1
        return false, "BUDGET_EXCEEDED", "Request budget exhausted"
    end
    
    -- Execute the request
    self.stats.totalRequests = self.stats.totalRequests + 1
    local success, result = pcall(requestFunc)
    local endTime = tick()
    local latency = endTime - startTime
    
    -- Update statistics
    self.stats.totalLatency = self.stats.totalLatency + latency
    self.stats.averageLatency = self.stats.totalLatency / self.stats.totalRequests
    
    if success then
        self.stats.successfulRequests = self.stats.successfulRequests + 1
        self:recordSuccessfulRequest(requestType, latency)
        return true, result
    else
        self.stats.failedRequests = self.stats.failedRequests + 1
        local errorType, errorMessage = self:handleRequestError(result, requestType)
        
        -- Implement retry logic for certain errors
        if self:shouldRetry(errorType, retryCount) then
            local retryDelay = self:calculateRetryDelay(retryCount)
            debugLog(string.format("Retrying request after %ds (attempt %d)", retryDelay, retryCount + 1))
            
            wait(retryDelay)
            return self:executeRequest(requestFunc, requestType, retryCount + 1)
        end
        
        return false, errorType, errorMessage
    end
end

-- Handle request errors and categorize them
function RequestManager:handleRequestError(error, requestType)
    local errorMessage = tostring(error)
    local errorType = "UNKNOWN"
    
    -- Categorize errors
    if errorMessage:find("budget") or errorMessage:find("quota") or errorMessage:find("throttled") then
        errorType = "THROTTLED"
        self:setThrottle(10, "DataStore API throttled")
    elseif errorMessage:find("not found") then
        errorType = "NOT_FOUND"
    elseif errorMessage:find("invalid") then
        errorType = "INVALID_INPUT"
    elseif errorMessage:find("timeout") then
        errorType = "TIMEOUT"
    elseif errorMessage:find("network") or errorMessage:find("connection") then
        errorType = "NETWORK_ERROR"
    end
    
    debugLog(string.format(
        "Request failed: %s - Type: %s - Message: %s",
        requestType or "unknown",
        errorType,
        errorMessage
    ), "ERROR")
    
    return errorType, errorMessage
end

-- Set throttle state
function RequestManager:setThrottle(duration, reason)
    self.isThrottled = true
    self.throttleEndTime = tick() + duration
    self.throttleReason = reason
    
    debugLog(string.format("Throttling enabled for %ds: %s", duration, reason), "WARN")
end

-- Clear throttle state
function RequestManager:clearThrottle()
    self.isThrottled = false
    self.throttleEndTime = 0
    self.throttleReason = nil
    
    debugLog("Throttling cleared")
    
    -- Process any queued requests
    if #self.requestQueue > 0 then
        self:processRequestQueue()
    end
end

-- Queue request for later execution
function RequestManager:queueRequest(requestFunc, requestType, callback)
    table.insert(self.requestQueue, {
        func = requestFunc,
        type = requestType,
        callback = callback,
        queueTime = tick()
    })
    
    debugLog("Request queued: " .. (requestType or "unknown"))
end

-- Process queued requests
function RequestManager:processRequestQueue()
    if self.isProcessingQueue or #self.requestQueue == 0 then
        return
    end
    
    self.isProcessingQueue = true
    debugLog("Processing " .. #self.requestQueue .. " queued requests")
    
    spawn(function()
        while #self.requestQueue > 0 do
            local request = table.remove(self.requestQueue, 1)
            
            -- Check if request is still valid (not too old)
            local requestAge = tick() - request.queueTime
            if requestAge > 300 then -- 5 minutes max queue time
                debugLog("Discarding old queued request: " .. (request.type or "unknown"))
                if request.callback then
                    request.callback(false, "TIMEOUT", "Request expired in queue")
                end
                continue
            end
            
            -- Execute the request
            local success, result, errorMessage = self:executeRequest(request.func, request.type)
            
            if request.callback then
                request.callback(success, result, errorMessage)
            end
            
            -- Small delay between queued requests
            wait(0.1)
        end
        
        self.isProcessingQueue = false
        debugLog("Finished processing request queue")
    end)
end

-- Record successful request for analytics
function RequestManager:recordSuccessfulRequest(requestType, latency)
    table.insert(self.requestHistory, {
        type = requestType,
        timestamp = tick(),
        latency = latency,
        success = true
    })
    
    -- Keep only recent history (last 1000 requests)
    if #self.requestHistory > 1000 then
        table.remove(self.requestHistory, 1)
    end
end

-- Determine if request should be retried
function RequestManager:shouldRetry(errorType, retryCount)
    local maxRetries = Constants.DATASTORE.MAX_RETRIES or 3
    
    if retryCount >= maxRetries then
        return false
    end
    
    -- Retry on certain error types
    local retryableErrors = {
        "TIMEOUT",
        "NETWORK_ERROR",
        "THROTTLED"
    }
    
    for _, retryableError in ipairs(retryableErrors) do
        if errorType == retryableError then
            return true
        end
    end
    
    return false
end

-- Calculate retry delay with exponential backoff
function RequestManager:calculateRetryDelay(retryCount)
    local baseDelay = Constants.DATASTORE.RETRY_DELAY_BASE or 1
    return baseDelay * (2 ^ retryCount) + math.random(0, 1000) / 1000 -- Add jitter
end

-- Get current request statistics
function RequestManager:getStats()
    local successRate = 0
    if self.stats.totalRequests > 0 then
        successRate = (self.stats.successfulRequests / self.stats.totalRequests) * 100
    end
    
    return {
        totalRequests = self.stats.totalRequests,
        successfulRequests = self.stats.successfulRequests,
        failedRequests = self.stats.failedRequests,
        throttledRequests = self.stats.throttledRequests,
        successRate = successRate,
        averageLatency = self.stats.averageLatency,
        currentBudget = self.requestBudget,
        maxBudget = Constants.DATASTORE.REQUEST_BUDGET_LIMIT,
        isThrottled = self.isThrottled,
        throttleTimeRemaining = math.max(0, self.throttleEndTime - tick()),
        queuedRequests = #self.requestQueue
    }
end

-- Get recent request history
function RequestManager:getRequestHistory(limit)
    limit = limit or 100
    local history = {}
    local startIndex = math.max(1, #self.requestHistory - limit + 1)
    
    for i = startIndex, #self.requestHistory do
        table.insert(history, self.requestHistory[i])
    end
    
    return history
end

-- Reset statistics
function RequestManager:resetStats()
    self.stats = {
        totalRequests = 0,
        successfulRequests = 0,
        failedRequests = 0,
        throttledRequests = 0,
        averageLatency = 0,
        totalLatency = 0
    }
    
    self.requestHistory = {}
    debugLog("Request statistics reset")
end

-- Force clear throttling (admin function)
function RequestManager:forceCleanThrottle()
    self:clearThrottle()
    self.requestBudget = Constants.DATASTORE.REQUEST_BUDGET_LIMIT
    debugLog("Throttling forcefully cleared and budget reset")
end

-- Get active request count for monitoring
function RequestManager:getActiveRequestCount()
    return #self.requestQueue
end

-- Alias for clearThrottle (compatibility)
function RequestManager:clearThrottling()
    self:clearThrottle()
end

return RequestManager 