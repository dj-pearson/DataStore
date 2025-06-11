-- Advanced Search & Filtering Service
-- Search across keys, filter by data type, regex matching
-- Part of DataStore Manager Pro - Phase 2.3

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local SearchService = {}

function SearchService.new()
    local self = setmetatable({}, {__index = SearchService})
    
    -- Search state
    self.searchHistory = {}
    self.savedQueries = {}
    self.lastResults = {}
    
    -- Search configuration
    self.maxResults = 100
    self.searchTimeout = 10
    
    debugLog("Search Service initialized", "INFO")
    return self
end

-- Main search function
function SearchService:search(query, options)
    local startTime = tick()
    options = options or {}
    
    -- Default search options
    local searchOptions = {
        scope = options.scope or "keys", -- "keys", "values", "both"
        dataStores = options.dataStores or {},
        dataTypes = options.dataTypes or {},
        caseSensitive = options.caseSensitive or false,
        useRegex = options.useRegex or false,
        maxResults = options.maxResults or self.maxResults
    }
    
    debugLog(string.format("Searching: '%s' (scope: %s)", query, searchOptions.scope), "INFO")
    
    -- Validate query
    if not query or query == "" then
        return {
            success = false,
            error = "Search query cannot be empty",
            results = {}
        }
    end
    
    -- Add to search history
    self:addToHistory(query, searchOptions)
    
    -- Perform search
    local results = {}
    if searchOptions.scope == "keys" then
        results = self:searchKeys(query, searchOptions)
    elseif searchOptions.scope == "values" then
        results = self:searchValues(query, searchOptions)
    elseif searchOptions.scope == "both" then
        local keyResults = self:searchKeys(query, searchOptions)
        local valueResults = self:searchValues(query, searchOptions)
        results = self:mergeResults(keyResults, valueResults)
    end
    
    -- Apply filters
    results = self:applyFilters(results, searchOptions)
    
    -- Sort by relevance
    table.sort(results, function(a, b)
        return (a.relevance or 0) > (b.relevance or 0)
    end)
    
    -- Limit results
    if #results > searchOptions.maxResults then
        results = {table.unpack(results, 1, searchOptions.maxResults)}
    end
    
    local searchTime = tick() - startTime
    self.lastResults = results
    
    debugLog(string.format("Search completed in %.2fms, found %d results", searchTime * 1000, #results), "INFO")
    
    return {
        success = true,
        results = results,
        searchTime = searchTime,
        totalResults = #results,
        query = query,
        options = searchOptions
    }
end

-- Search in DataStore keys
function SearchService:searchKeys(query, options)
    local results = {}
    
    -- Get DataStore Manager
    local dataStoreManager = self:getDataStoreManager()
    if not dataStoreManager then
        debugLog("DataStore Manager not available", "WARN")
        return results
    end
    
    -- Determine which DataStores to search
    local dataStoresToSearch = options.dataStores
    if #dataStoresToSearch == 0 then
        dataStoresToSearch = dataStoreManager:getDataStoreNames() or {}
    end
    
    -- Search each DataStore
    for _, dataStoreName in ipairs(dataStoresToSearch) do
        local keys = dataStoreManager:getDataStoreKeys(dataStoreName)
        
        if keys then
            for _, key in ipairs(keys) do
                if self:matchesQuery(key, query, options) then
                    table.insert(results, {
                        type = "key",
                        dataStore = dataStoreName,
                        key = key,
                        match = key,
                        relevance = self:calculateRelevance(key, query)
                    })
                end
            end
        end
    end
    
    return results
end

-- Search in DataStore values
function SearchService:searchValues(query, options)
    local results = {}
    
    -- Get DataStore Manager
    local dataStoreManager = self:getDataStoreManager()
    if not dataStoreManager then
        debugLog("DataStore Manager not available", "WARN")
        return results
    end
    
    -- Determine which DataStores to search
    local dataStoresToSearch = options.dataStores
    if #dataStoresToSearch == 0 then
        dataStoresToSearch = dataStoreManager:getDataStoreNames() or {}
    end
    
    -- Search each DataStore
    for _, dataStoreName in ipairs(dataStoresToSearch) do
        local keys = dataStoreManager:getDataStoreKeys(dataStoreName)
        
        if keys then
            for _, key in ipairs(keys) do
                -- Get data for key
                local success, data, dataType, size = pcall(function()
                    return dataStoreManager:getDataInfo(dataStoreName, key)
                end)
                
                if success and data then
                    local matchInfo = self:searchInData(data, query, options)
                    if matchInfo.found then
                        table.insert(results, {
                            type = "value",
                            dataStore = dataStoreName,
                            key = key,
                            data = data,
                            dataType = dataType,
                            size = size,
                            matches = matchInfo.matches,
                            relevance = matchInfo.relevance
                        })
                    end
                end
            end
        end
    end
    
    return results
end

-- Search within data
function SearchService:searchInData(data, query, options)
    local matches = {}
    local found = false
    local totalRelevance = 0
    
    -- Convert data to searchable text
    local searchText = self:dataToText(data)
    
    if self:matchesQuery(searchText, query, options) then
        found = true
        table.insert(matches, {
            path = "root",
            value = data,
            match = searchText
        })
        totalRelevance = self:calculateRelevance(searchText, query)
    end
    
    -- If data is table, search recursively
    if type(data) == "table" then
        local tableMatches = self:searchInTable(data, query, options, "")
        for _, match in ipairs(tableMatches) do
            table.insert(matches, match)
            found = true
            totalRelevance = totalRelevance + (match.relevance or 0)
        end
    end
    
    return {
        found = found,
        matches = matches,
        relevance = totalRelevance
    }
end

-- Search in table recursively
function SearchService:searchInTable(tbl, query, options, path)
    local matches = {}
    
    for key, value in pairs(tbl) do
        local currentPath = path == "" and tostring(key) or path .. "." .. tostring(key)
        
        -- Search in key
        if self:matchesQuery(tostring(key), query, options) then
            table.insert(matches, {
                path = currentPath,
                type = "key",
                value = key,
                match = tostring(key),
                relevance = self:calculateRelevance(tostring(key), query)
            })
        end
        
        -- Search in value
        if type(value) == "table" then
            local subMatches = self:searchInTable(value, query, options, currentPath)
            for _, match in ipairs(subMatches) do
                table.insert(matches, match)
            end
        else
            local valueStr = tostring(value)
            if self:matchesQuery(valueStr, query, options) then
                table.insert(matches, {
                    path = currentPath,
                    type = "value",
                    value = value,
                    match = valueStr,
                    relevance = self:calculateRelevance(valueStr, query)
                })
            end
        end
    end
    
    return matches
end

-- Check if text matches query
function SearchService:matchesQuery(text, query, options)
    if not text or not query then
        return false
    end
    
    local searchText = options.caseSensitive and text or string.lower(text)
    local searchQuery = options.caseSensitive and query or string.lower(query)
    
    if options.useRegex then
        -- Use Lua patterns (simplified regex)
        local success, result = pcall(function()
            return string.find(searchText, searchQuery) ~= nil
        end)
        return success and result
    else
        -- Simple substring search
        return string.find(searchText, searchQuery, 1, true) ~= nil
    end
end

-- Calculate relevance score
function SearchService:calculateRelevance(text, query)
    if not text or not query then
        return 0
    end
    
    local searchText = string.lower(text)
    local searchQuery = string.lower(query)
    
    -- Exact match = 100
    if searchText == searchQuery then
        return 100
    end
    
    -- Starts with query = 80
    if string.sub(searchText, 1, #searchQuery) == searchQuery then
        return 80
    end
    
    -- Contains query = based on position and ratio
    local pos = string.find(searchText, searchQuery, 1, true)
    if pos then
        local lengthRatio = #searchQuery / #searchText
        return math.floor(60 * lengthRatio + (50 - pos))
    end
    
    return 0
end

-- Convert data to searchable text
function SearchService:dataToText(data)
    if type(data) == "string" then
        return data
    elseif type(data) == "number" or type(data) == "boolean" then
        return tostring(data)
    elseif type(data) == "table" then
        local success, jsonText = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        return success and jsonText or tostring(data)
    else
        return tostring(data)
    end
end

-- Apply filters to results
function SearchService:applyFilters(results, options)
    local filtered = {}
    
    for _, result in ipairs(results) do
        local include = true
        
        -- Filter by data type
        if #options.dataTypes > 0 and result.dataType then
            include = false
            for _, allowedType in ipairs(options.dataTypes) do
                if result.dataType == allowedType then
                    include = true
                    break
                end
            end
        end
        
        if include then
            table.insert(filtered, result)
        end
    end
    
    return filtered
end

-- Merge two result sets
function SearchService:mergeResults(results1, results2)
    local merged = {}
    local seen = {}
    
    -- Add from first set
    for _, result in ipairs(results1) do
        local key = result.dataStore .. ":" .. result.key
        if not seen[key] then
            table.insert(merged, result)
            seen[key] = true
        end
    end
    
    -- Add from second set
    for _, result in ipairs(results2) do
        local key = result.dataStore .. ":" .. result.key
        if not seen[key] then
            table.insert(merged, result)
            seen[key] = true
        end
    end
    
    return merged
end

-- Add search to history
function SearchService:addToHistory(query, options)
    table.insert(self.searchHistory, 1, {
        query = query,
        options = options,
        timestamp = tick()
    })
    
    -- Keep only last 50
    if #self.searchHistory > 50 then
        table.remove(self.searchHistory, 51)
    end
end

-- Get search suggestions
function SearchService:getSuggestions(partial)
    local suggestions = {}
    
    -- From history
    for _, item in ipairs(self.searchHistory) do
        if string.find(string.lower(item.query), string.lower(partial), 1, true) then
            table.insert(suggestions, {
                type = "history",
                text = item.query,
                score = 80
            })
        end
    end
    
    -- From saved queries
    for name, queryData in pairs(self.savedQueries) do
        if string.find(string.lower(name), string.lower(partial), 1, true) then
            table.insert(suggestions, {
                type = "saved",
                name = name,
                text = queryData.query,
                score = 90
            })
        end
    end
    
    -- Sort by score
    table.sort(suggestions, function(a, b) return a.score > b.score end)
    
    return suggestions
end

-- Save query
function SearchService:saveQuery(name, query, options)
    self.savedQueries[name] = {
        query = query,
        options = options,
        saved = tick()
    }
    debugLog(string.format("Saved search query: %s", name), "INFO")
end

-- Get saved queries
function SearchService:getSavedQueries()
    return self.savedQueries
end

-- Delete saved query
function SearchService:deleteSavedQuery(name)
    if self.savedQueries[name] then
        self.savedQueries[name] = nil
        debugLog(string.format("Deleted saved query: %s", name), "INFO")
        return true
    end
    return false
end

-- Get search history
function SearchService:getSearchHistory()
    return self.searchHistory
end

-- Clear search history
function SearchService:clearHistory()
    self.searchHistory = {}
    debugLog("Search history cleared", "INFO")
end

-- Get DataStore Manager reference
function SearchService:getDataStoreManager()
    return self.dataStoreManager
end

-- Set DataStore Manager reference
function SearchService:setDataStoreManager(manager)
    self.dataStoreManager = manager
    debugLog("DataStore Manager connected to Search Service", "INFO")
end

-- Export search results
function SearchService:exportResults(results, format)
    format = format or "json"
    
    if format == "json" then
        return HttpService:JSONEncode(results)
    elseif format == "csv" then
        local csv = "DataStore,Key,Type,Match,Relevance\n"
        for _, result in ipairs(results) do
            csv = csv .. string.format("%s,%s,%s,%s,%.1f\n",
                result.dataStore or "",
                result.key or "",
                result.type or "",
                result.match or "",
                result.relevance or 0
            )
        end
        return csv
    end
    
    return results
end

function SearchService:cleanup()
    if self.searchHistory then
        self.searchHistory = nil
    end
    if self.savedQueries then
        self.savedQueries = nil
    end
    if self.lastResults then
        self.lastResults = nil
    end
    debugLog("Search Service cleanup complete", "INFO")
end

-- Static cleanup for service-level cleanup
function SearchService.cleanup()
    debugLog("Search Service cleanup complete", "INFO")
end

return SearchService 