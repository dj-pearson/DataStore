local HttpService = game:GetService("HttpService")
local Logger = require(script.Parent.Parent.logging.Logger)

local AnalyticsService = {}
AnalyticsService.__index = AnalyticsService

-- Constants
local METRICS_RETENTION = {
    ["1h"] = 3600, -- 1 hour
    ["24h"] = 86400, -- 24 hours
    ["7d"] = 604800, -- 7 days
    ["30d"] = 2592000 -- 30 days
}

local METRIC_TYPES = {
    REQUESTS = "requests",
    SIZE = "size",
    ERRORS = "errors",
    RESPONSE_TIME = "responseTime",
    CACHE_HITS = "cacheHits"
}

function AnalyticsService.new()
    local self = setmetatable({}, AnalyticsService)
    
    -- Initialize metrics storage
    self.metrics = {
        [METRIC_TYPES.REQUESTS] = {},
        [METRIC_TYPES.SIZE] = {},
        [METRIC_TYPES.ERRORS] = {},
        [METRIC_TYPES.RESPONSE_TIME] = {},
        [METRIC_TYPES.CACHE_HITS] = {}
    }
    
    -- Initialize store-specific metrics
    self.storeMetrics = {}
    
    -- Initialize aggregation cache
    self.aggregationCache = {}
    
    -- Start cleanup task
    self:startCleanupTask()
    
    return self
end

-- Record a metric
function AnalyticsService:recordMetric(storeName, metricType, value, timestamp)
    timestamp = timestamp or os.time()
    storeName = storeName or "DefaultStore"
    
    -- Initialize store metrics if needed
    if not self.storeMetrics[storeName] then
        self.storeMetrics[storeName] = {
            [METRIC_TYPES.REQUESTS] = {},
            [METRIC_TYPES.SIZE] = {},
            [METRIC_TYPES.ERRORS] = {},
            [METRIC_TYPES.RESPONSE_TIME] = {},
            [METRIC_TYPES.CACHE_HITS] = {}
        }
    end
    
    -- Record global metric
    table.insert(self.metrics[metricType], {
        timestamp = timestamp,
        value = value
    })
    
    -- Record store-specific metric
    table.insert(self.storeMetrics[storeName][metricType], {
        timestamp = timestamp,
        value = value
    })
    
    -- Clear aggregation cache for this metric
    self.aggregationCache[metricType] = nil
    self.aggregationCache[storeName] = self.aggregationCache[storeName] or {}
    self.aggregationCache[storeName][metricType] = nil
    
    Logger:debug("Recorded metric", {
        store = storeName,
        type = metricType,
        value = value,
        timestamp = timestamp
    })
end

-- Get metrics for a specific time range
function AnalyticsService:getMetrics(storeName, metricType, timeRange, interval)
    local cacheKey = string.format("%s_%s_%s_%s", storeName, metricType, timeRange, interval)
    
    -- Check cache first
    if self.aggregationCache[cacheKey] then
        return self.aggregationCache[cacheKey]
    end
    
    local metrics = storeName and self.storeMetrics[storeName][metricType] or self.metrics[metricType]
    if not metrics then
        return {}
    end
    
    local now = os.time()
    local startTime = now - METRICS_RETENTION[timeRange]
    local aggregatedData = self:aggregateMetrics(metrics, startTime, now, interval)
    
    -- Cache the result
    self.aggregationCache[cacheKey] = aggregatedData
    
    return aggregatedData
end

-- Aggregate metrics for visualization
function AnalyticsService:aggregateMetrics(metrics, startTime, endTime, interval)
    local aggregated = {}
    local buckets = {}
    
    -- Create time buckets
    for time = startTime, endTime, interval do
        buckets[time] = {
            sum = 0,
            count = 0,
            min = math.huge,
            max = -math.huge
        }
    end
    
    -- Aggregate metrics into buckets
    for _, metric in ipairs(metrics) do
        if metric.timestamp >= startTime and metric.timestamp <= endTime then
            local bucketTime = math.floor(metric.timestamp / interval) * interval
            local bucket = buckets[bucketTime]
            
            if bucket then
                bucket.sum = bucket.sum + metric.value
                bucket.count = bucket.count + 1
                bucket.min = math.min(bucket.min, metric.value)
                bucket.max = math.max(bucket.max, metric.value)
            end
        end
    end
    
    -- Convert buckets to array format
    for time, bucket in pairs(buckets) do
        if bucket.count > 0 then
            table.insert(aggregated, {
                timestamp = time,
                value = bucket.sum / bucket.count,
                min = bucket.min,
                max = bucket.max,
                count = bucket.count
            })
        end
    end
    
    -- Sort by timestamp
    table.sort(aggregated, function(a, b)
        return a.timestamp < b.timestamp
    end)
    
    return aggregated
end

-- Get summary statistics
function AnalyticsService:getSummary(storeName, timeRange)
    local summary = {
        totalRequests = 0,
        averageResponseTime = 0,
        errorRate = 0,
        cacheHitRate = 0,
        totalSize = 0
    }
    
    local now = os.time()
    local startTime = now - METRICS_RETENTION[timeRange]
    
    -- Calculate statistics for each metric type
    for metricType, metrics in pairs(storeName and self.storeMetrics[storeName] or self.metrics) do
        local relevantMetrics = {}
        for _, metric in ipairs(metrics) do
            if metric.timestamp >= startTime and metric.timestamp <= now then
                table.insert(relevantMetrics, metric)
            end
        end
        
        if #relevantMetrics > 0 then
            if metricType == METRIC_TYPES.REQUESTS then
                summary.totalRequests = #relevantMetrics
            elseif metricType == METRIC_TYPES.RESPONSE_TIME then
                local sum = 0
                for _, metric in ipairs(relevantMetrics) do
                    sum = sum + metric.value
                end
                summary.averageResponseTime = sum / #relevantMetrics
            elseif metricType == METRIC_TYPES.ERRORS then
                summary.errorRate = (#relevantMetrics / summary.totalRequests) * 100
            elseif metricType == METRIC_TYPES.CACHE_HITS then
                summary.cacheHitRate = (#relevantMetrics / summary.totalRequests) * 100
            elseif metricType == METRIC_TYPES.SIZE then
                local sum = 0
                for _, metric in ipairs(relevantMetrics) do
                    sum = sum + metric.value
                end
                summary.totalSize = sum
            end
        end
    end
    
    return summary
end

-- Cleanup old metrics
function AnalyticsService:cleanupOldMetrics()
    local now = os.time()
    
    for metricType, metrics in pairs(self.metrics) do
        local newMetrics = {}
        for _, metric in ipairs(metrics) do
            if now - metric.timestamp <= METRICS_RETENTION["30d"] then
                table.insert(newMetrics, metric)
            end
        end
        self.metrics[metricType] = newMetrics
    end
    
    for storeName, storeData in pairs(self.storeMetrics) do
        for metricType, metrics in pairs(storeData) do
            local newMetrics = {}
            for _, metric in ipairs(metrics) do
                if now - metric.timestamp <= METRICS_RETENTION["30d"] then
                    table.insert(newMetrics, metric)
                end
            end
            storeData[metricType] = newMetrics
        end
    end
    
    -- Clear aggregation cache
    self.aggregationCache = {}
end

-- Start cleanup task
function AnalyticsService:startCleanupTask()
    task.spawn(function()
        while true do
            self:cleanupOldMetrics()
            task.wait(3600) -- Run cleanup every hour
        end
    end)
end

-- Export metrics to JSON
function AnalyticsService:exportMetrics(storeName, timeRange)
    local metrics = {}
    
    for metricType, _ in pairs(METRIC_TYPES) do
        metrics[metricType] = self:getMetrics(storeName, metricType, timeRange, 3600)
    end
    
    return HttpService:JSONEncode({
        store = storeName,
        timeRange = timeRange,
        metrics = metrics,
        summary = self:getSummary(storeName, timeRange)
    })
end

return AnalyticsService 