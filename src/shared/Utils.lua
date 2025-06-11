-- DataStore Manager Pro - Shared Utilities
-- Common utility functions organized by category

local Utils = {}

-- Import services we'll need
local HttpService = game:GetService("HttpService")

-- String utilities
Utils.String = {}

function Utils.String.isEmpty(str)
    return not str or str == ""
end

function Utils.String.trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$")
end

function Utils.String.split(str, delimiter)
    if not str then return {} end
    delimiter = delimiter or ","
    
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    
    return result
end

function Utils.String.startsWith(str, prefix)
    if not str or not prefix then return false end
    return str:sub(1, #prefix) == prefix
end

function Utils.String.endsWith(str, suffix)
    if not str or not suffix then return false end
    return str:sub(-#suffix) == suffix
end

function Utils.String.truncate(str, maxLength, suffix)
    if not str then return "" end
    suffix = suffix or "..."
    
    if #str <= maxLength then
        return str
    end
    
    return str:sub(1, maxLength - #suffix) .. suffix
end

-- Table utilities
Utils.Table = {}

function Utils.Table.isEmpty(tbl)
    return not tbl or next(tbl) == nil
end

function Utils.Table.size(tbl)
    if not tbl then return 0 end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function Utils.Table.deepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    
    local copy = {}
    for key, value in pairs(tbl) do
        copy[Utils.Table.deepCopy(key)] = Utils.Table.deepCopy(value)
    end
    
    return copy
end

function Utils.Table.merge(target, source)
    if not target then 
        target = {}
    end
    if not source then 
        return target 
    end
    
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            target[key] = Utils.Table.merge(target[key], value)
        else
            target[key] = value
        end
    end
    
    return target
end

function Utils.Table.find(tbl, predicate)
    if not tbl or not predicate then return nil end
    
    for key, value in pairs(tbl) do
        if predicate(value, key) then
            return value, key
        end
    end
    
    return nil
end

function Utils.Table.filter(tbl, predicate)
    if not tbl then return {} end
    
    local result = {}
    for key, value in pairs(tbl) do
        if not predicate or predicate(value, key) then
            result[key] = value
        end
    end
    
    return result
end

function Utils.Table.map(tbl, transformer)
    if not tbl then return {} end
    
    local result = {}
    for key, value in pairs(tbl) do
        result[key] = transformer and transformer(value, key) or value
    end
    
    return result
end

-- JSON utilities
Utils.JSON = {}

function Utils.JSON.encode(data, pretty)
    if not data then return "{}" end
    
    local success, result = pcall(function()
        if pretty then
            -- Simple pretty print (Roblox doesn't have built-in pretty JSON)
            return HttpService:JSONEncode(data)
        else
            return HttpService:JSONEncode(data)
        end
    end)
    
    return success and result or "{}"
end

function Utils.JSON.decode(jsonString)
    if Utils.String.isEmpty(jsonString) then
        return nil, "Empty JSON string"
    end
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    return success and result or nil, success and nil or result
end

function Utils.JSON.isValid(jsonString)
    local data, error = Utils.JSON.decode(jsonString)
    return data ~= nil, error
end

-- Time utilities
Utils.Time = {}

function Utils.Time.getCurrentTimestamp()
    return tick()
end

function Utils.Time.formatTimestamp(timestamp, format)
    format = format or "%Y-%m-%d %H:%M:%S"
    return os.date(format, timestamp)
end

function Utils.Time.getElapsedTime(startTime)
    return tick() - startTime
end

function Utils.Time.formatDuration(seconds)
    if seconds < 60 then
        return string.format("%.1fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.1fm", seconds / 60)
    else
        return string.format("%.1fh", seconds / 3600)
    end
end

-- Performance utilities
Utils.Performance = {}

function Utils.Performance.measureExecutionTime(func, args)
    local startTime = tick()
    local results = {func(unpack(args or {}))}
    local endTime = tick()
    
    return endTime - startTime, unpack(results)
end

function Utils.Performance.createDebounce(func, delay)
    local lastCall = 0
    
    return function(...)
        local args = {...}
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(unpack(args))
        end
    end
end

function Utils.Performance.createThrottle(func, delay)
    local lastCall = 0
    local pending = false
    
    return function(...)
        local args = {...}
        local now = tick()
        
        if now - lastCall >= delay then
            lastCall = now
            return func(unpack(args))
        elseif not pending then
            pending = true
            spawn(function()
                wait(delay - (now - lastCall))
                pending = false
                lastCall = tick()
                func(unpack(args))
            end)
        end
    end
end

-- Validation utilities
Utils.Validation = {}

function Utils.Validation.isString(value)
    return type(value) == "string"
end

function Utils.Validation.isNumber(value)
    return type(value) == "number"
end

function Utils.Validation.isTable(value)
    return type(value) == "table"
end

function Utils.Validation.isFunction(value)
    return type(value) == "function"
end

function Utils.Validation.isValidDataStoreKey(key)
    if not Utils.Validation.isString(key) then
        return false, "Key must be a string"
    end
    
    if #key == 0 then
        return false, "Key cannot be empty"
    end
    
    if #key > 50 then
        return false, "Key cannot exceed 50 characters"
    end
    
    -- Check for invalid characters
    if key:match("[^%w_%-]") then
        return false, "Key contains invalid characters (use only letters, numbers, underscore, hyphen)"
    end
    
    return true
end

function Utils.Validation.isValidDataStoreData(data)
    if data == nil then
        return true -- nil is valid
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if not success then
        return false, "Data cannot be JSON encoded"
    end
    
    if #encoded > 4000000 then -- 4MB limit
        return false, "Data exceeds 4MB limit"
    end
    
    return true
end

-- Error handling utilities
Utils.Error = {}

function Utils.Error.createErrorInfo(code, message, context)
    return {
        code = code or "UNKNOWN",
        message = message or "An unknown error occurred",
        context = context or {},
        timestamp = Utils.Time.getCurrentTimestamp(),
        stack = debug.traceback()
    }
end

function Utils.Error.safeCall(func, errorHandler, ...)
    local args = {...}
    local success, result = pcall(func, unpack(args))
    
    if success then
        return result
    else
        if errorHandler then
            errorHandler(result)
        end
        return nil
    end
end

function Utils.Error.retryWithBackoff(func, maxRetries, baseDelay, ...)
    maxRetries = maxRetries or 3
    baseDelay = baseDelay or 1
    
    local args = {...}
    local lastError = nil
    
    for attempt = 1, maxRetries do
        local success, result = pcall(func, unpack(args))
        
        if success then
            return result
        else
            lastError = result
            
            if attempt < maxRetries then
                local delay = baseDelay * (2 ^ (attempt - 1)) -- Exponential backoff
                wait(delay)
            end
        end
    end
    
    error("Failed after " .. maxRetries .. " attempts. Last error: " .. tostring(lastError))
end

-- UI utilities
Utils.UI = {}

function Utils.UI.createGUID()
    return HttpService:GenerateGUID(false)
end

function Utils.UI.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.UI.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function Utils.UI.formatBytes(bytes)
    local units = {"B", "KB", "MB", "GB"}
    local size = bytes
    local unitIndex = 1
    
    while size >= 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format("%.1f %s", size, units[unitIndex])
end

-- Encoding utilities
Utils.Encoding = {}

function Utils.Encoding.base64Encode(data)
    if not data then return "" end
    
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local encoded = ""
    
    for i = 1, #data, 3 do
        local a, b, c = string.byte(data, i, i + 2)
        b = b or 0
        c = c or 0
        
        local bitmap = a * 65536 + b * 256 + c
        
        for j = 0, 3 do
            if i + j <= #data then
                local index = math.floor(bitmap / (64 ^ (3 - j))) % 64 + 1
                encoded = encoded .. charset:sub(index, index)
            else
                encoded = encoded .. "="
            end
        end
    end
    
    return encoded
end

function Utils.Encoding.base64Decode(encoded)
    if not encoded then return "" end
    
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local decoded = ""
    
    -- Remove padding
    encoded = encoded:gsub("=", "")
    
    for i = 1, #encoded, 4 do
        local a, b, c, d = encoded:byte(i, i + 3)
        
        -- Convert characters to indices
        a = charset:find(string.char(a or 65)) - 1  -- Default to 'A' if nil
        b = b and (charset:find(string.char(b)) - 1) or 0
        c = c and (charset:find(string.char(c)) - 1) or 0  
        d = d and (charset:find(string.char(d)) - 1) or 0
        
        local bitmap = a * 262144 + b * 4096 + c * 64 + d  -- 2^18, 2^12, 2^6, 2^0
        
        decoded = decoded .. string.char(math.floor(bitmap / 65536) % 256)  -- Get high byte
        if i + 1 <= #encoded then
            decoded = decoded .. string.char(math.floor(bitmap / 256) % 256)  -- Get middle byte
        end
        if i + 2 <= #encoded then
            decoded = decoded .. string.char(bitmap % 256)  -- Get low byte
        end
    end
    
    return decoded
end

-- Serialization utilities
Utils.Serialization = {}

function Utils.Serialization.serializeTable(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    
    return HttpService:JSONEncode(tbl)
end

function Utils.Serialization.deserializeTable(str)
    if not str or str == "" then
        return nil
    end
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    
    return success and result or nil
end

-- Add backward compatibility aliases
Utils.base64Encode = Utils.Encoding.base64Encode
Utils.base64Decode = Utils.Encoding.base64Decode
Utils.serializeTable = Utils.Serialization.serializeTable
Utils.deserializeTable = Utils.Serialization.deserializeTable

-- Debug utilities
Utils.Debug = {}

function Utils.Debug.dumpTable(tbl, indent, maxDepth)
    indent = indent or 0
    maxDepth = maxDepth or 5
    
    if indent > maxDepth then
        return "..."
    end
    
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    
    local result = "{\n"
    local indentStr = string.rep("  ", indent + 1)
    
    for key, value in pairs(tbl) do
        result = result .. indentStr .. tostring(key) .. " = "
        
        if type(value) == "table" then
            result = result .. Utils.Debug.dumpTable(value, indent + 1, maxDepth)
        else
            result = result .. tostring(value)
        end
        
        result = result .. ",\n"
    end
    
    result = result .. string.rep("  ", indent) .. "}"
    return result
end

function Utils.Debug.getMemoryUsage()
    -- Force garbage collection and get memory count
    local collectgc = collectgarbage
    local _ = collectgc("collect")
    local memoryKB = collectgc("count")
    return memoryKB * 1024 -- Convert KB to bytes
end

function Utils.Debug.benchmark(name, func, iterations)
    iterations = iterations or 1
    
    local startTime = tick()
    local startMemory = Utils.Debug.getMemoryUsage()
    
    for _ = 1, iterations do
        func()
    end
    
    local endTime = tick()
    local endMemory = Utils.Debug.getMemoryUsage()
    
    local result = {
        name = name,
        iterations = iterations,
        totalTime = endTime - startTime,
        averageTime = (endTime - startTime) / iterations,
        memoryDelta = endMemory - startMemory
    }
    
    print(string.format(
        "Benchmark [%s]: %d iterations, %.3fms total, %.3fms avg, %s memory delta",
        result.name,
        result.iterations,
        result.totalTime * 1000,
        result.averageTime * 1000,
        Utils.UI.formatBytes(result.memoryDelta)
    ))
    
    return result
end

return Utils 