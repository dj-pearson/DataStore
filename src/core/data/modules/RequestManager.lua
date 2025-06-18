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
    local errorRate = 0
    if self.stats.totalRequests > 0 then
        successRate = (self.stats.successfulRequests / self.stats.totalRequests) * 100
        errorRate = (self.stats.failedRequests / self.stats.totalRequests)
    end
    
    return {
        totalRequests = self.stats.totalRequests,
        successfulRequests = self.stats.successfulRequests,
        failedRequests = self.stats.failedRequests,
        throttledRequests = self.stats.throttledRequests,
        successRate = successRate,
        errorRate = errorRate,
        averageLatency = self.stats.averageLatency,
        currentBudget = self.requestBudget,
        maxBudget = Constants.DATASTORE.REQUEST_BUDGET_LIMIT,
        isThrottled = self.isThrottled,
        throttleTimeRemaining = math.max(0, self.throttleEndTime - tick()),
        queuedRequests = #self.requestQueue
    }
end

-- Get average response time for performance monitoring
function RequestManager:getAverageResponseTime()
    return self.stats.averageLatency * 1000 -- Convert to milliseconds
end

-- Get error rate for performance monitoring
function RequestManager:getErrorRate()
    if self.stats.totalRequests > 0 then
        return self.stats.failedRequests / self.stats.totalRequests
    end
    return 0
end

-- Increase throttling for performance optimization
function RequestManager:increaseThrottling()
    local currentDelay = Constants.DATASTORE.REQUEST_COOLDOWN or 0.1
    local newDelay = math.min(currentDelay * 1.5, 2.0) -- Max 2 second delay
    
    -- Update the constants (in a real implementation, this would be configurable)
    self.config.requestCooldown = newDelay
    
    debugLog(string.format("Increased throttling delay from %.2fs to %.2fs", currentDelay, newDelay))
    return newDelay
end

-- Decrease throttling for performance optimization
function RequestManager:decreaseThrottling()
    local currentDelay = self.config.requestCooldown or Constants.DATASTORE.REQUEST_COOLDOWN or 0.1
    local newDelay = math.max(currentDelay * 0.8, 0.05) -- Min 0.05 second delay
    
    self.config.requestCooldown = newDelay
    
    debugLog(string.format("Decreased throttling delay from %.2fs to %.2fs", currentDelay, newDelay))
    return newDelay
end

-- Adaptive throttling based on error rates
function RequestManager:adaptiveThrottling()
    local stats = self:getStats()
    
    -- If error rate is high, increase throttling
    if stats.errorRate > 0.1 then -- 10% error rate
        self:increaseThrottling()
        debugLog("Adaptive throttling: Increased due to high error rate")
    elseif stats.errorRate < 0.02 and stats.averageLatency < 0.1 then -- 2% error rate and fast responses
        self:decreaseThrottling()
        debugLog("Adaptive throttling: Decreased due to low error rate and fast responses")
    end
end

-- Optimize request timing based on historical data
function RequestManager:optimizeRequestTiming()
    if #self.requestHistory < 10 then
        return -- Need more data
    end
    
    -- Analyze recent request patterns
    local recentRequests = {}
    local cutoff = tick() - 300 -- Last 5 minutes
    
    for _, request in ipairs(self.requestHistory) do
        if request.timestamp >= cutoff then
            table.insert(recentRequests, request)
        end
    end
    
    if #recentRequests < 5 then
        return
    end
    
    -- Calculate average latency for recent requests
    local totalLatency = 0
    local successCount = 0
    
    for _, request in ipairs(recentRequests) do
        if request.success then
            totalLatency = totalLatency + request.latency
            successCount = successCount + 1
        end
    end
    
    if successCount > 0 then
        local avgLatency = totalLatency / successCount
        
        -- If average latency is high, suggest increasing delays
        if avgLatency > 0.5 then -- 500ms
            self:increaseThrottling()
            debugLog("Optimized timing: Increased throttling due to high latency")
        elseif avgLatency < 0.1 then -- 100ms
            self:decreaseThrottling()
            debugLog("Optimized timing: Decreased throttling due to low latency")
        end
    end
end

-- Get performance recommendations
function RequestManager:getPerformanceRecommendations()
    local stats = self:getStats()
    local recommendations = {}
    
    if stats.errorRate > 0.1 then
        table.insert(recommendations, {
            type = "critical",
            title = "High Error Rate",
            description = string.format("Error rate is %.1f%%, consider increasing throttling", stats.errorRate * 100),
            action = "increase_throttling"
        })
    end
    
    if stats.averageLatency > 0.5 then
        table.insert(recommendations, {
            type = "warning",
            title = "High Response Time",
            description = string.format("Average response time is %.2fs, consider optimizing requests", stats.averageLatency),
            action = "optimize_requests"
        })
    end
    
    if stats.throttledRequests > stats.totalRequests * 0.1 then
        table.insert(recommendations, {
            type = "warning",
            title = "High Throttling Rate",
            description = "Many requests are being throttled, consider optimizing request patterns",
            action = "optimize_request_patterns"
        })
    end
    
    if #self.requestQueue > 10 then
        table.insert(recommendations, {
            type = "info",
            title = "Large Request Queue",
            description = "Request queue is getting large, consider implementing request prioritization",
            action = "implement_prioritization"
        })
    end
    
    return recommendations
end

-- Implement request prioritization
function RequestManager:prioritizeRequest(requestFunc, requestType, priority, callback)
    priority = priority or 5 -- Default medium priority (1-10 scale)
    
    local request = {
        func = requestFunc,
        type = requestType,
        callback = callback,
        queueTime = tick(),
        priority = priority
    }
    
    -- Insert request in priority order
    local inserted = false
    for i, queuedRequest in ipairs(self.requestQueue) do
        if priority < queuedRequest.priority then -- Lower number = higher priority
            table.insert(self.requestQueue, i, request)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(self.requestQueue, request)
    end
    
    debugLog(string.format("Priority request queued: %s (priority %d)", requestType or "unknown", priority))
end

-- Batch multiple requests for efficiency
function RequestManager:batchRequests(requests, callback)
    if #requests == 0 then
        if callback then callback(true, {}) end
        return
    end
    
    local results = {}
    local completed = 0
    local hasError = false
    
    local function onRequestComplete(index, success, result, error)
        completed = completed + 1
        results[index] = {
            success = success,
            result = result,
            error = error
        }
        
        if not success then
            hasError = true
        end
        
        -- Check if all requests are complete
        if completed == #requests then
            if callback then
                callback(not hasError, results)
            end
        end
    end
    
    -- Execute all requests with delays
    for i, request in ipairs(requests) do
        spawn(function()
            -- Add small delay between requests to avoid overwhelming the API
            if i > 1 then
                wait((i - 1) * 0.1)
            end
            
            local success, result, error = self:executeRequest(request.func, request.type)
            onRequestComplete(i, success, result, error)
        end)
    end
    
    debugLog("Batch request started with " .. #requests .. " requests")
end

-- Get throughput metrics
function RequestManager:getThroughput()
    if #self.requestHistory < 2 then
        return {
            operationsPerSecond = 0,
            bytesPerSecond = 0
        }
    end
    
    -- Calculate operations per second based on recent history
    local recentRequests = {}
    local cutoff = tick() - 60 -- Last minute
    
    for _, request in ipairs(self.requestHistory) do
        if request.timestamp >= cutoff and request.success then
            table.insert(recentRequests, request)
        end
    end
    
    local operationsPerSecond = #recentRequests / 60
    
    return {
        operationsPerSecond = operationsPerSecond,
        bytesPerSecond = operationsPerSecond * 1024 -- Estimate 1KB per operation
    }
end

-- Monitor and auto-optimize performance
function RequestManager:autoOptimize()
    -- Run adaptive throttling
    self:adaptiveThrottling()
    
    -- Optimize request timing
    self:optimizeRequestTiming()
    
    -- Clean up old queue entries
    local now = tick()
    local originalSize = #self.requestQueue
    
    for i = #self.requestQueue, 1, -1 do
        local request = self.requestQueue[i]
        if now - request.queueTime > 600 then -- 10 minutes
            table.remove(self.requestQueue, i)
            if request.callback then
                request.callback(false, "TIMEOUT", "Request expired in queue")
            end
        end
    end
    
    if #self.requestQueue < originalSize then
        debugLog(string.format("Auto-optimization: Cleaned %d expired requests from queue", 
            originalSize - #self.requestQueue))
    end
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