-- DataStore Manager Pro - Smart Search Engine
-- Advanced search with intelligent filtering, auto-suggestions, and performance optimization

local SmartSearchEngine = {}
SmartSearchEngine.__index = SmartSearchEngine

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[SMART_SEARCH_ENGINE] [%s] %s", level, message))
end

-- Create new Smart Search Engine instance
function SmartSearchEngine.new(services)
    local self = setmetatable({}, SmartSearchEngine)
    
    self.services = services or {}
    self.searchCache = {}
    self.suggestionCache = {}
    self.searchHistory = {}
    self.indexedData = {}
    
    debugLog("Smart Search Engine created")
    return self
end

-- Main search function
function SmartSearchEngine:search(query, options)
    options = options or {}
    
    local startTime = tick()
    
    -- Validate query
    if not query or #query < 2 then
        return {
            success = false,
            error = "Query too short - minimum 2 characters",
            results = {},
            metadata = {}
        }
    end
    
    debugLog(string.format("Executing search: '%s'", query))
    
    -- Get real DataStore manager
    local dataStoreManager = self:getDataStoreManager()
    local results = {}
    
    if dataStoreManager then
        -- Perform real search
        results = self:performRealSearch(query, options, dataStoreManager)
        debugLog(string.format("Real search found %d results", #results))
    else
        -- Fallback to basic results when no DataStore manager available
        debugLog("No DataStore manager available, using fallback results", "WARN")
        results = {
            {
                dataStore = "No DataStores",
                key = "No data available",
                matchType = "info",
                matchField = "status",
                relevance = 0.0,
                snippet = "Connect to DataStores to search real data",
                match = "No data"
            }
        }
    end
    
    local endTime = tick()
    local responseTime = (endTime - startTime) * 1000
    
    debugLog(string.format("Search completed: %d results in %.2fms", #results, responseTime))
    
    -- Store in search history
    self:addToSearchHistory(query, options, #results)
    
    return {
        success = true,
        query = query,
        results = results,
        metadata = {
            totalResults = #results,
            responseTime = responseTime,
            searchType = options.searchType or "contains",
            filters = options.filters or {},
            timestamp = os.time(),
            hasRealData = dataStoreManager ~= nil
        }
    }
end

-- Perform real search across DataStores
function SmartSearchEngine:performRealSearch(query, options, dataStoreManager)
    local results = {}
    local searchType = options.searchType or "contains"
    local maxResults = options.maxResults or 50
    local searchScope = options.scope or "both" -- "keys", "values", "both"
    
    -- Get available DataStores
    local dataStoreNames = dataStoreManager:getDataStoreNames()
    if not dataStoreNames or #dataStoreNames == 0 then
        debugLog("No DataStores available to search", "WARN")
        return results
    end
    
    debugLog(string.format("Searching %d DataStores with scope: %s", #dataStoreNames, searchScope))
    
    -- Search each DataStore
    for _, dataStoreName in ipairs(dataStoreNames) do
        if #results >= maxResults then break end
        
        local dsResults = self:searchDataStore(dataStoreName, query, searchType, searchScope, dataStoreManager)
        for _, result in ipairs(dsResults) do
            if #results >= maxResults then break end
            table.insert(results, result)
        end
    end
    
    -- Sort by relevance
    table.sort(results, function(a, b)
        return (a.relevance or 0) > (b.relevance or 0)
    end)
    
    return results
end

-- Search within a specific DataStore
function SmartSearchEngine:searchDataStore(dataStoreName, query, searchType, searchScope, dataStoreManager)
    local results = {}
    
    -- Get keys for this DataStore
    local keys = dataStoreManager:getKeys(dataStoreName, "global", 100)
    if not keys or #keys == 0 then
        return results
    end
    
    debugLog(string.format("Searching DataStore '%s' with %d keys", dataStoreName, #keys))
    
    for _, key in ipairs(keys) do
        -- Search in key names if scope includes keys
        if searchScope == "keys" or searchScope == "both" then
            if self:matchesSearch(key, query, searchType) then
                local relevance = self:calculateRelevance(key, query, "key")
                table.insert(results, {
                    dataStore = dataStoreName,
                    key = key,
                    matchType = "key",
                    matchField = "key",
                    relevance = relevance,
                    snippet = string.format("Key '%s' matches '%s'", key, query),
                    match = key
                })
            end
        end
        
        -- Search in values if scope includes values
        if searchScope == "values" or searchScope == "both" then
            local success, data = pcall(function()
                return dataStoreManager:getData(dataStoreName, key)
            end)
            
            if success and data then
                local valueMatches = self:searchInValue(data, query, searchType)
                for _, match in ipairs(valueMatches) do
                    table.insert(results, {
                        dataStore = dataStoreName,
                        key = key,
                        matchType = "value",
                        matchField = match.field,
                        relevance = match.relevance,
                        snippet = match.snippet,
                        match = match.value,
                        dataType = type(data)
                    })
                end
            end
        end
    end
    
    return results
end

-- Check if text matches search query
function SmartSearchEngine:matchesSearch(text, query, searchType)
    if not text or not query then return false end
    
    text = tostring(text):lower()
    query = query:lower()
    
    if searchType == "exact" then
        return text == query
    elseif searchType == "startswith" then
        return string.sub(text, 1, #query) == query
    elseif searchType == "endswith" then
        return string.sub(text, -#query) == query
    elseif searchType == "regex" then
        local success, result = pcall(function()
            return string.match(text, query) ~= nil
        end)
        return success and result
    else -- "contains" (default)
        return string.find(text, query, 1, true) ~= nil
    end
end

-- Search within a data value
function SmartSearchEngine:searchInValue(data, query, searchType)
    local matches = {}
    
    if type(data) == "string" then
        if self:matchesSearch(data, query, searchType) then
            table.insert(matches, {
                field = "value",
                value = data,
                relevance = self:calculateRelevance(data, query, "string"),
                snippet = self:createSnippet(data, query)
            })
        end
    elseif type(data) == "number" then
        local numStr = tostring(data)
        if self:matchesSearch(numStr, query, searchType) then
            table.insert(matches, {
                field = "value",
                value = numStr,
                relevance = self:calculateRelevance(numStr, query, "number"),
                snippet = string.format("Number value: %s", numStr)
            })
        end
    elseif type(data) == "table" then
        local tableMatches = self:searchInTable(data, query, searchType, "")
        for _, match in ipairs(tableMatches) do
            table.insert(matches, match)
        end
    end
    
    return matches
end

-- Search within a table structure
function SmartSearchEngine:searchInTable(data, query, searchType, path)
    local matches = {}
    
    for key, value in pairs(data) do
        local currentPath = path == "" and tostring(key) or (path .. "." .. tostring(key))
        
        -- Search in key names
        if self:matchesSearch(tostring(key), query, searchType) then
            table.insert(matches, {
                field = currentPath,
                value = tostring(key),
                relevance = self:calculateRelevance(tostring(key), query, "key"),
                snippet = string.format("Key '%s' in %s", tostring(key), currentPath)
            })
        end
        
        -- Search in values
        if type(value) == "string" then
            if self:matchesSearch(value, query, searchType) then
                table.insert(matches, {
                    field = currentPath,
                    value = value,
                    relevance = self:calculateRelevance(value, query, "string"),
                    snippet = self:createSnippet(value, query)
                })
            end
        elseif type(value) == "number" then
            local numStr = tostring(value)
            if self:matchesSearch(numStr, query, searchType) then
                table.insert(matches, {
                    field = currentPath,
                    value = numStr,
                    relevance = self:calculateRelevance(numStr, query, "number"),
                    snippet = string.format("%s = %s", currentPath, numStr)
                })
            end
        elseif type(value) == "table" then
            -- Recursive search in nested tables
            local nestedMatches = self:searchInTable(value, query, searchType, currentPath)
            for _, match in ipairs(nestedMatches) do
                table.insert(matches, match)
            end
        end
    end
    
    return matches
end

-- Calculate search relevance score
function SmartSearchEngine:calculateRelevance(text, query, matchType)
    if not text or not query then return 0 end
    
    text = tostring(text):lower()
    query = query:lower()
    
    local relevance = 0
    
    -- Exact match gets highest score
    if text == query then
        relevance = 100
    -- Starts with query gets high score
    elseif string.sub(text, 1, #query) == query then
        relevance = 80
    -- Ends with query gets medium-high score
    elseif string.sub(text, -#query) == query then
        relevance = 70
    -- Contains query gets medium score
    elseif string.find(text, query, 1, true) then
        relevance = 50
    end
    
    -- Adjust based on match type
    if matchType == "key" then
        relevance = relevance * 1.2 -- Keys are more important
    elseif matchType == "string" then
        relevance = relevance * 1.0 -- Normal weight
    elseif matchType == "number" then
        relevance = relevance * 0.9 -- Numbers slightly less important
    end
    
    -- Adjust based on text length (shorter matches are more relevant)
    local lengthFactor = math.max(0.5, 1 - (#text - #query) / 100)
    relevance = relevance * lengthFactor
    
    return math.min(100, math.max(0, relevance))
end

-- Create snippet showing match context
function SmartSearchEngine:createSnippet(text, query)
    if not text or not query then return "" end
    
    local lowerText = string.lower(text)
    local lowerQuery = string.lower(query)
    
    local startPos = string.find(lowerText, lowerQuery, 1, true)
    if not startPos then
        return string.sub(text, 1, 50) .. (string.len(text) > 50 and "..." or "")
    end
    
    -- Get context around the match
    local contextStart = math.max(1, startPos - 20)
    local contextEnd = math.min(string.len(text), startPos + string.len(query) + 20)
    
    local snippet = string.sub(text, contextStart, contextEnd)
    
    -- Add ellipsis if we truncated
    if contextStart > 1 then
        snippet = "..." .. snippet
    end
    if contextEnd < string.len(text) then
        snippet = snippet .. "..."
    end
    
    return snippet
end

-- Add search to history
function SmartSearchEngine:addToSearchHistory(query, options, resultCount)
    table.insert(self.searchHistory, 1, {
        query = query,
        options = options,
        resultCount = resultCount,
        timestamp = os.time()
    })
    
    -- Keep only last 100 searches
    if #self.searchHistory > 100 then
        table.remove(self.searchHistory, 101)
    end
end

-- Generate search suggestions
function SmartSearchEngine:getSuggestions(partialQuery, options)
    options = options or {}
    local limit = options.limit or 10
    
    if #partialQuery < 1 then
        return {}
    end
    
    local suggestions = {}
    
    -- Get suggestions from search history
    for _, historyItem in ipairs(self.searchHistory) do
        if string.find(string.lower(historyItem.query), string.lower(partialQuery), 1, true) then
            table.insert(suggestions, {
                text = historyItem.query,
                type = "history",
                score = 80,
                resultCount = historyItem.resultCount
            })
        end
    end
    
    -- Get DataStore manager for real suggestions
    local dataStoreManager = self:getDataStoreManager()
    if dataStoreManager then
        local realSuggestions = self:generateRealSuggestions(partialQuery, dataStoreManager)
        for _, suggestion in ipairs(realSuggestions) do
            table.insert(suggestions, suggestion)
        end
    end
    
    -- Sort by score and limit
    table.sort(suggestions, function(a, b) return a.score > b.score end)
    
    local result = {}
    for i = 1, math.min(limit, #suggestions) do
        table.insert(result, suggestions[i])
    end
    
    return result
end

-- Generate suggestions based on real DataStore data
function SmartSearchEngine:generateRealSuggestions(partialQuery, dataStoreManager)
    local suggestions = {}
    local lowerPartial = string.lower(partialQuery)
    
    -- Get DataStore names as suggestions
    local dataStoreNames = dataStoreManager:getDataStoreNames()
    if dataStoreNames then
        for _, dsName in ipairs(dataStoreNames) do
            if string.find(string.lower(dsName), lowerPartial, 1, true) then
                table.insert(suggestions, {
                    text = dsName,
                    type = "datastore",
                    score = 90,
                    description = "DataStore name"
                })
            end
        end
    end
    
    -- Get common key patterns as suggestions
    local keyPatterns = self:getCommonKeyPatterns(dataStoreManager)
    for _, pattern in ipairs(keyPatterns) do
        if string.find(string.lower(pattern), lowerPartial, 1, true) then
            table.insert(suggestions, {
                text = pattern,
                type = "pattern",
                score = 70,
                description = "Common key pattern"
            })
        end
    end
    
    return suggestions
end

-- Get common key patterns from DataStores
function SmartSearchEngine:getCommonKeyPatterns(dataStoreManager)
    local patterns = {}
    local dataStoreNames = dataStoreManager:getDataStoreNames()
    
    if dataStoreNames then
        for _, dsName in ipairs(dataStoreNames) do
            local keys = dataStoreManager:getKeys(dsName, "global", 50)
            if keys then
                for _, key in ipairs(keys) do
                    -- Extract patterns (prefixes before numbers or underscores)
                    local pattern = string.match(key, "^([%a_]+)")
                    if pattern and #pattern > 2 then
                        patterns[pattern] = true
                    end
                end
            end
        end
    end
    
    local result = {}
    for pattern in pairs(patterns) do
        table.insert(result, pattern)
    end
    
    return result
end

-- Get search analytics
function SmartSearchEngine:getSearchAnalytics()
    local totalSearches = #self.searchHistory
    local queryCount = {}
    local totalResponseTime = 0
    
    -- Analyze search history
    for _, historyItem in ipairs(self.searchHistory) do
        local query = historyItem.query
        queryCount[query] = (queryCount[query] or 0) + 1
    end
    
    -- Get popular queries
    local popularQueries = {}
    for query, count in pairs(queryCount) do
        table.insert(popularQueries, {query = query, count = count})
    end
    table.sort(popularQueries, function(a, b) return a.count > b.count end)
    
    return {
        totalSearches = totalSearches,
        popularQueries = popularQueries,
        averageResponseTime = totalResponseTime / math.max(1, totalSearches),
        cacheHitRate = 0.0, -- TODO: Implement caching
        uniqueQueries = Utils.tableLength(queryCount)
    }
end

-- Get DataStore Manager reference
function SmartSearchEngine:getDataStoreManager()
    local hasServices = self.services and true or false
    local dataStoreManager = self.services and self.services["core.data.DataStoreManagerSlim"]
    local hasDataStoreManager = dataStoreManager and true or false
    
    debugLog(string.format("getDataStoreManager - hasServices: %s, hasDataStoreManager: %s", tostring(hasServices), tostring(hasDataStoreManager)))
    
    if self.services then
        debugLog("Available services:")
        for serviceName, _ in pairs(self.services) do
            if string.find(serviceName, "DataStore") then
                debugLog("  - " .. serviceName)
            end
        end
    end
    
    return dataStoreManager
end

-- Initialize with services
function SmartSearchEngine.initialize(services)
    local instance = SmartSearchEngine.new(services)
    debugLog("Smart Search Engine initialized with services")
    return instance
end

return SmartSearchEngine 