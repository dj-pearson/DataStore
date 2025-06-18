-- Advanced Search & Filtering Service
-- Search across keys, filter by data type, regex matching
-- Part of DataStore Manager Pro - Phase 2.3

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local AdvancedSearch = {}

function AdvancedSearch.new()
    local self = setmetatable({}, {__index = AdvancedSearch})
    
    -- Search state
    self.searchHistory = {}
    self.savedQueries = {}
    self.searchResults = {}
    self.lastSearchTime = 0
    
    -- Search configuration
    self.maxResults = 100
    self.searchTimeout = 10 -- seconds
    
    debugLog("Advanced Search initialized", "INFO")
    return self
end

-- Main search function
function AdvancedSearch:search(query, options)
    local startTime = tick()
    options = options or {}
    
    -- Default search options
    local searchOptions = {
        scope = options.scope or "keys", -- "keys", "values", "both"
        dataStores = options.dataStores or {}, -- Empty = all DataStores
        dataTypes = options.dataTypes or {}, -- Empty = all types
        caseSensitive = options.caseSensitive or false,
        useRegex = options.useRegex or false,
        maxResults = options.maxResults or self.maxResults,
        includeMetadata = options.includeMetadata or false
    }
    
    debugLog(string.format("Starting search: '%s' with scope: %s", query, searchOptions.scope), "INFO")
    
    -- Validate query
    if not query or query == "" then
        return {
            success = false,
            error = "Search query cannot be empty",
            results = {},
            metadata = {}
        }
    end
    
    -- Save to search history
    self:addToHistory(query, searchOptions)
    
    -- Perform search based on scope
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
    
    -- Apply post-processing filters
    results = self:applyFilters(results, searchOptions)
    
    -- Sort and limit results
    results = self:sortResults(results, options.sortBy or "relevance")
    if #results > searchOptions.maxResults then
        results = {table.unpack(results, 1, searchOptions.maxResults)}
    end
    
    local endTime = tick()
    local searchTime = endTime - startTime
    
    debugLog(string.format("Search completed in %.2fms, found %d results", searchTime * 1000, #results), "INFO")
    
    return {
        success = true,
        results = results,
        metadata = {
            query = query,
            options = searchOptions,
            searchTime = searchTime,
            totalResults = #results,
            timestamp = tick()
        }
    }
end

-- Search in DataStore keys
function AdvancedSearch:searchKeys(query, options)
    local results = {}
    local dataStoreManager = self:getDataStoreManager()
    
    if not dataStoreManager then
        debugLog("DataStore Manager not available for key search", "WARN")
        return results
    end
    
    -- Get DataStores to search
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
function AdvancedSearch:searchValues(query, options)
    local results = {}
    local dataStoreManager = self:getDataStoreManager()
    
    if not dataStoreManager then
        debugLog("DataStore Manager not available for value search", "WARN")
        return results
    end
    
    -- Get DataStores to search
    local dataStoresToSearch = options.dataStores
    if #dataStoresToSearch == 0 then
        dataStoresToSearch = dataStoreManager:getDataStoreNames() or {}
    end
    
    -- Search each DataStore
    for _, dataStoreName in ipairs(dataStoresToSearch) do
        local keys = dataStoreManager:getDataStoreKeys(dataStoreName)
        
        if keys then
            for _, key in ipairs(keys) do
                -- Get data for each key
                local success, data, dataType, size = pcall(function()
                    return dataStoreManager:getDataInfo(dataStoreName, key)
                end)
                
                if success and data then
                    local matchResult = self:searchInData(data, query, options)
                    if matchResult.found then
                        table.insert(results, {
                            type = "value",
                            dataStore = dataStoreName,
                            key = key,
                            data = data,
                            dataType = dataType,
                            size = size,
                            matches = matchResult.matches,
                            relevance = matchResult.relevance
                        })
                    end
                end
            end
        end
    end
    
    return results
end

-- Search within data structure
function AdvancedSearch:searchInData(data, query, options)
    local matches = {}
    local found = false
    local totalRelevance = 0
    
    -- Convert data to searchable string
    local searchableText = self:dataToSearchableText(data)
    
    if self:matchesQuery(searchableText, query, options) then
        found = true
        table.insert(matches, {
            path = "root",
            value = data,
            match = searchableText
        })
        totalRelevance = self:calculateRelevance(searchableText, query)
    end
    
    -- If data is a table, search recursively
    if type(data) == "table" then
        local tableMatches = self:searchInTable(data, query, options, "")
        for _, match in ipairs(tableMatches) do
            table.insert(matches, match)
            found = true
            totalRelevance = totalRelevance + match.relevance
        end
    end
    
    return {
        found = found,
        matches = matches,
        relevance = totalRelevance
    }
end

-- Search recursively in table
function AdvancedSearch:searchInTable(tbl, query, options, path)
    local matches = {}
    
    for key, value in pairs(tbl) do
        local currentPath = path == "" and tostring(key) or path .. "." .. tostring(key)
        
        -- Search in key name
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
            -- Recursive search
            local subMatches = self:searchInTable(value, query, options, currentPath)
            for _, match in ipairs(subMatches) do
                table.insert(matches, match)
            end
        else
            -- Search in primitive value
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
function AdvancedSearch:matchesQuery(text, query, options)
    if not text or not query then
        return false
    end
    
    local searchText = options.caseSensitive and text or string.lower(text)
    local searchQuery = options.caseSensitive and query or string.lower(query)
    
    if options.useRegex then
        -- Use pattern matching (Lua patterns, not full regex)
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
function AdvancedSearch:calculateRelevance(text, query)
    if not text or not query then
        return 0
    end
    
    local searchText = string.lower(text)
    local searchQuery = string.lower(query)
    
    -- Exact match gets highest score
    if searchText == searchQuery then
        return 100
    end
    
    -- Starts with query gets high score
    if string.sub(searchText, 1, #searchQuery) == searchQuery then
        return 80
    end
    
    -- Contains query gets medium score
    if string.find(searchText, searchQuery, 1, true) then
        -- Score based on position and length ratio
        local pos = string.find(searchText, searchQuery, 1, true)
        local lengthRatio = #searchQuery / #searchText
        return math.floor(60 * lengthRatio + (50 - pos))
    end
    
    return 0
end

-- Convert data to searchable text
function AdvancedSearch:dataToSearchableText(data)
    if type(data) == "string" then
        return data
    elseif type(data) == "number" then
        return tostring(data)
    elseif type(data) == "boolean" then
        return tostring(data)
    elseif type(data) == "table" then
        -- Convert table to JSON-like string for searching
        local success, jsonText = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        if success then
            return jsonText
        else
            return tostring(data)
        end
    else
        return tostring(data)
    end
end

-- Apply additional filters
function AdvancedSearch:applyFilters(results, options)
    local filteredResults = {}
    
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
            table.insert(filteredResults, result)
        end
    end
    
    return filteredResults
end

-- Sort results
function AdvancedSearch:sortResults(results, sortBy)
    if sortBy == "relevance" then
        table.sort(results, function(a, b)
            return (a.relevance or 0) > (b.relevance or 0)
        end)
    elseif sortBy == "dataStore" then
        table.sort(results, function(a, b)
            if a.dataStore == b.dataStore then
                return (a.key or "") < (b.key or "")
            end
            return (a.dataStore or "") < (b.dataStore or "")
        end)
    elseif sortBy == "key" then
        table.sort(results, function(a, b)
            return (a.key or "") < (b.key or "")
        end)
    elseif sortBy == "size" then
        table.sort(results, function(a, b)
            return (a.size or 0) > (b.size or 0)
        end)
    end
    
    return results
end

-- Merge search results
function AdvancedSearch:mergeResults(results1, results2)
    local merged = {}
    local seen = {}
    
    -- Add results from first set
    for _, result in ipairs(results1) do
        local key = result.dataStore .. ":" .. result.key
        if not seen[key] then
            table.insert(merged, result)
            seen[key] = true
        end
    end
    
    -- Add results from second set
    for _, result in ipairs(results2) do
        local key = result.dataStore .. ":" .. result.key
        if not seen[key] then
            table.insert(merged, result)
            seen[key] = true
        else
            -- Merge match information
            for i, existingResult in ipairs(merged) do
                if existingResult.dataStore == result.dataStore and existingResult.key == result.key then
                    if result.matches then
                        existingResult.matches = existingResult.matches or {}
                        for _, match in ipairs(result.matches) do
                            table.insert(existingResult.matches, match)
                        end
                    end
                    existingResult.relevance = (existingResult.relevance or 0) + (result.relevance or 0)
                    break
                end
            end
        end
    end
    
    return merged
end

-- Add to search history
function AdvancedSearch:addToHistory(query, options)
    table.insert(self.searchHistory, 1, {
        query = query,
        options = options,
        timestamp = tick()
    })
    
    -- Keep only last 50 searches
    if #self.searchHistory > 50 then
        table.remove(self.searchHistory, 51)
    end
end

-- Get search suggestions
function AdvancedSearch:getSearchSuggestions(partialQuery)
    local suggestions = {}
    
    -- From search history
    for _, historyItem in ipairs(self.searchHistory) do
        if string.find(string.lower(historyItem.query), string.lower(partialQuery), 1, true) then
            table.insert(suggestions, {
                type = "history",
                text = historyItem.query,
                relevance = 80
            })
        end
    end
    
    -- From saved queries
    for name, query in pairs(self.savedQueries) do
        if string.find(string.lower(name), string.lower(partialQuery), 1, true) or
           string.find(string.lower(query), string.lower(partialQuery), 1, true) then
            table.insert(suggestions, {
                type = "saved",
                name = name,
                text = query,
                relevance = 90
            })
        end
    end
    
    -- Sort by relevance
    table.sort(suggestions, function(a, b)
        return a.relevance > b.relevance
    end)
    
    return suggestions
end

-- Save search query
function AdvancedSearch:saveQuery(name, query, options)
    self.savedQueries[name] = {
        query = query,
        options = options,
        saved = tick()
    }
    debugLog(string.format("Saved search query: %s", name), "INFO")
end

-- Get saved queries
function AdvancedSearch:getSavedQueries()
    return self.savedQueries
end

-- Delete saved query
function AdvancedSearch:deleteSavedQuery(name)
    self.savedQueries[name] = nil
    debugLog(string.format("Deleted saved query: %s", name), "INFO")
end

-- Get search statistics
function AdvancedSearch:getSearchStats()
    return {
        totalSearches = #self.searchHistory,
        savedQueries = Utils.tableLength(self.savedQueries),
        lastSearchTime = self.lastSearchTime,
        mostSearchedTerms = self:getMostSearchedTerms()
    }
end

-- Get most searched terms
function AdvancedSearch:getMostSearchedTerms()
    local termCounts = {}
    
    for _, historyItem in ipairs(self.searchHistory) do
        local query = historyItem.query
        termCounts[query] = (termCounts[query] or 0) + 1
    end
    
    local terms = {}
    for term, count in pairs(termCounts) do
        table.insert(terms, {term = term, count = count})
    end
    
    table.sort(terms, function(a, b) return a.count > b.count end)
    
    return terms
end

-- Get DataStore Manager reference
function AdvancedSearch:getDataStoreManager()
    -- Try to get from services first, then fallback to direct reference
    if self.services and self.services["core.data.DataStoreManagerSlim"] then
        return self.services["core.data.DataStoreManagerSlim"]
    end
    return self.dataStoreManager
end

-- Set DataStore Manager reference
function AdvancedSearch:setDataStoreManager(manager)
    self.dataStoreManager = manager
    debugLog("DataStore Manager reference set for search", "INFO")
end

-- Set services reference
function AdvancedSearch:setServices(services)
    self.services = services
    debugLog("Services reference set for AdvancedSearch", "INFO")
end

-- Initialize with services
function AdvancedSearch.initialize(services)
    local instance = AdvancedSearch.new()
    instance:setServices(services)
    debugLog("Advanced Search initialized with services")
    return instance
end

-- Clear search history
function AdvancedSearch:clearHistory()
    self.searchHistory = {}
    debugLog("Search history cleared", "INFO")
end

-- Export search results
function AdvancedSearch:exportResults(results, format)
    format = format or "json"
    
    if format == "json" then
        return HttpService:JSONEncode(results)
    elseif format == "csv" then
        local csv = "DataStore,Key,Type,Match,Relevance\n"
        for _, result in ipairs(results) do
            csv = csv .. string.format("%s,%s,%s,%s,%.2f\n",
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

function AdvancedSearch.cleanup()
    debugLog("Advanced Search cleanup complete", "INFO")
end

return AdvancedSearch 