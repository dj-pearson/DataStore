-- DataStore Manager Pro - Data Explorer
-- Feature module for browsing and exploring DataStore data

local DataExplorer = {}
DataExplorer.__index = DataExplorer

-- Debug logging
local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[DATA_EXPLORER] [%s] %s", level, message))
end

-- Initialize the Data Explorer
function DataExplorer.initialize()
    local self = setmetatable({}, DataExplorer)
    
    debugLog("Initializing Data Explorer (Basic Mode)")
    
    -- Explorer state
    self.currentDataStore = nil
    self.currentScope = "global"
    self.selectedKey = nil
    self.explorerData = {
        datastores = {},
        keys = {},
        currentData = nil
    }
    
    -- UI callbacks
    self.uiCallbacks = {}
    
    return self
end

-- Set DataStore Manager reference
function DataExplorer:setDataStoreManager(manager)
    self.dataStoreManager = manager
    debugLog("DataStore Manager reference set")
end

-- Set UI Manager reference for callbacks
function DataExplorer:setUIManager(uiManager)
    self.uiManager = uiManager
    debugLog("UI Manager reference set")
end

-- Get list of available DataStores
function DataExplorer:getDataStores()
    debugLog("Getting DataStore list")
    
    if not self.dataStoreManager then
        debugLog("DataStore Manager not available", "ERROR")
        return {}
    end
    
    local success, datastores = pcall(function()
        return self.dataStoreManager:getDataStoreNames()
    end)
    
    if success then
        self.explorerData.datastores = datastores
        debugLog("Retrieved " .. #datastores .. " DataStores")
        return datastores
    else
        debugLog("Failed to get DataStores: " .. tostring(datastores), "ERROR")
        return {}
    end
end

-- Select a DataStore and load its keys
function DataExplorer:selectDataStore(datastoreName, scope)
    debugLog("Selecting DataStore: " .. datastoreName)
    
    if not self.dataStoreManager then
        debugLog("DataStore Manager not available", "ERROR")
        return false
    end
    
    scope = scope or "global"
    self.currentDataStore = datastoreName
    self.currentScope = scope
    
    -- Load keys for this DataStore
    return self:loadKeys()
end

-- Load keys for the current DataStore
function DataExplorer:loadKeys()
    if not self.currentDataStore then
        debugLog("No DataStore selected", "WARN")
        return false
    end
    
    debugLog("Loading keys for DataStore: " .. self.currentDataStore)
    
    local success, keys = pcall(function()
        return self.dataStoreManager:getDataStoreKeys(self.currentDataStore, self.currentScope)
    end)
    
    if success then
        self.explorerData.keys = keys
        debugLog("Loaded " .. #keys .. " keys")
        
        -- Notify UI of update
        if self.uiCallbacks.onKeysLoaded then
            self.uiCallbacks.onKeysLoaded(keys)
        end
        
        return true
    else
        debugLog("Failed to load keys: " .. tostring(keys), "ERROR")
        self.explorerData.keys = {}
        return false
    end
end

-- Select and load data for a specific key
function DataExplorer:selectKey(key)
    if not self.currentDataStore or not key then
        debugLog("DataStore or key not specified", "WARN")
        return false
    end
    
    debugLog("Selecting key: " .. key)
    self.selectedKey = key
    
    local success, dataInfo = pcall(function()
        return self.dataStoreManager:getDataInfo(self.currentDataStore, key, self.currentScope)
    end)
    
    if success then
        self.explorerData.currentData = dataInfo
        debugLog("Loaded data for key: " .. key .. " (Type: " .. dataInfo.type .. ", Size: " .. dataInfo.size .. ")")
        
        -- Notify UI of update
        if self.uiCallbacks.onDataLoaded then
            self.uiCallbacks.onDataLoaded(dataInfo)
        end
        
        return true
    else
        debugLog("Failed to load data for key: " .. tostring(dataInfo), "ERROR")
        return false
    end
end

-- Get current explorer state
function DataExplorer:getState()
    return {
        currentDataStore = self.currentDataStore,
        currentScope = self.currentScope,
        selectedKey = self.selectedKey,
        keystores = self.explorerData.datastores,
        keys = self.explorerData.keys,
        currentData = self.explorerData.currentData
    }
end

-- Get selected data (for UI compatibility)
function DataExplorer:getSelectedData()
    return self.explorerData.currentData
end

-- Register UI callback
function DataExplorer:registerCallback(eventName, callback)
    self.uiCallbacks[eventName] = callback
    debugLog("Registered callback for: " .. eventName)
end

-- Search for keys matching a pattern
function DataExplorer:searchKeys(pattern)
    if not self.explorerData.keys then
        debugLog("No keys loaded to search", "WARN")
        return {}
    end
    
    debugLog("Searching keys with pattern: " .. pattern)
    
    local matchingKeys = {}
    pattern = pattern:lower()
    
    for _, keyInfo in ipairs(self.explorerData.keys) do
        if keyInfo.key:lower():find(pattern, 1, true) then
            table.insert(matchingKeys, keyInfo)
        end
    end
    
    debugLog("Found " .. #matchingKeys .. " matching keys")
    return matchingKeys
end

-- Refresh current DataStore data
function DataExplorer:refresh()
    debugLog("Refreshing explorer data")
    
    if self.dataStoreManager then
        self.dataStoreManager:clearCache()
    end
    
    if self.currentDataStore then
        self:loadKeys()
    end
    
    if self.selectedKey then
        self:selectKey(self.selectedKey)
    end
    
    debugLog("Explorer data refreshed")
end

-- Get formatted data for display
function DataExplorer:getFormattedData(data, format)
    format = format or "auto"
    
    if not data then
        return "No data"
    end
    
    if format == "json" or (format == "auto" and type(data) == "table") then
        local HttpService = game:GetService("HttpService")
        local success, jsonString = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        
        if success then
            -- Pretty print JSON with basic formatting
            return self:formatJSON(jsonString)
        else
            return tostring(data)
        end
    else
        return tostring(data)
    end
end

-- Basic JSON formatter
function DataExplorer:formatJSON(jsonString)
    local formatted = jsonString
    local indent = 0
    local result = ""
    local inString = false
    local escapeNext = false
    
    for i = 1, #formatted do
        local char = formatted:sub(i, i)
        
        if escapeNext then
            result = result .. char
            escapeNext = false
        elseif char == "\\" and inString then
            result = result .. char
            escapeNext = true
        elseif char == '"' and not escapeNext then
            result = result .. char
            inString = not inString
        elseif not inString then
            if char == "{" or char == "[" then
                result = result .. char .. "\n" .. string.rep("  ", indent + 1)
                indent = indent + 1
            elseif char == "}" or char == "]" then
                indent = indent - 1
                result = result .. "\n" .. string.rep("  ", indent) .. char
            elseif char == "," then
                result = result .. char .. "\n" .. string.rep("  ", indent)
            else
                result = result .. char
            end
        else
            result = result .. char
        end
    end
    
    return result
end

-- Export current DataStore data
function DataExplorer:exportData(format)
    format = format or "json"
    
    if not self.explorerData.keys or #self.explorerData.keys == 0 then
        debugLog("No data to export", "WARN")
        return nil
    end
    
    debugLog("Exporting data in format: " .. format)
    
    local exportData = {
        dataStore = self.currentDataStore,
        scope = self.currentScope,
        exportTime = os.date("%Y-%m-%d %H:%M:%S"),
        keys = {}
    }
    
    -- Export all key data
    for _, keyInfo in ipairs(self.explorerData.keys) do
        local success, data = pcall(function()
            return self.dataStoreManager:getData(self.currentDataStore, keyInfo.key, self.currentScope)
        end)
        
        if success then
            exportData.keys[keyInfo.key] = data
        end
    end
    
    debugLog("Exported " .. #self.explorerData.keys .. " keys")
    return exportData
end

-- Save key data to DataStore
function DataExplorer:saveKeyData(dataStoreName, keyName, data, callback)
    debugLog("Saving data for key: " .. keyName .. " in DataStore: " .. dataStoreName)
    
    if not dataStoreName or not keyName or not data then
        callback(false, "Invalid parameters for saving data")
        return
    end
    
    -- Get DataStore service
    local dataStoreService = game:GetService("DataStoreService")
    
    task.spawn(function()
        local success, result = pcall(function()
            local dataStore = dataStoreService:GetDataStore(dataStoreName)
            dataStore:SetAsync(keyName, data)
            return "Data saved successfully"
        end)
        
        if success then
            debugLog("Successfully saved data for key: " .. keyName)
            -- Update cached data if this key is currently selected
            if self.currentData and self.currentData[keyName] then
                self.currentData[keyName] = {
                    data = data,
                    type = type(data),
                    size = self:calculateDataSize(data),
                    exists = true
                }
            end
            callback(true, result)
        else
            debugLog("Failed to save data for key: " .. keyName .. " - " .. tostring(result), "WARN")
            callback(false, "Failed to save data: " .. tostring(result))
        end
    end)
end

-- Delete key from DataStore
function DataExplorer:deleteKeyData(dataStoreName, keyName, callback)
    debugLog("Deleting key: " .. keyName .. " from DataStore: " .. dataStoreName)
    
    if not dataStoreName or not keyName then
        callback(false, "Invalid parameters for deleting data")
        return
    end
    
    -- Get DataStore service
    local dataStoreService = game:GetService("DataStoreService")
    
    task.spawn(function()
        local success, result = pcall(function()
            local dataStore = dataStoreService:GetDataStore(dataStoreName)
            dataStore:RemoveAsync(keyName)
            return "Key deleted successfully"
        end)
        
        if success then
            debugLog("Successfully deleted key: " .. keyName)
            -- Remove from cached data
            if self.currentData and self.currentData[keyName] then
                self.currentData[keyName] = nil
            end
            callback(true, result)
        else
            debugLog("Failed to delete key: " .. keyName .. " - " .. tostring(result), "WARN")
            callback(false, "Failed to delete key: " .. tostring(result))
        end
    end)
end

-- Calculate data size for display
function DataExplorer:calculateDataSize(data)
    if not data then
        return "0 bytes"
    end
    
    local HttpService = game:GetService("HttpService")
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        local size = #jsonString
        if size < 1024 then
            return size .. " bytes"
        elseif size < 1024 * 1024 then
            return math.floor(size / 1024 * 100) / 100 .. " KB"
        else
            return math.floor(size / (1024 * 1024) * 100) / 100 .. " MB"
        end
    else
        return "Unknown"
    end
end

function DataExplorer.cleanup()
    debugLog("Data Explorer cleanup complete")
end

return DataExplorer 