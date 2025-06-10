-- Schema Builder & Validation Service
-- Define data schemas and validate data structure
-- Part of DataStore Manager Pro - Phase 2.3

local HttpService = game:GetService("HttpService")

-- Get shared utilities  
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local SchemaService = {}

function SchemaService.new()
    local self = setmetatable({}, {__index = SchemaService})
    
    -- Schema storage
    self.schemas = {}
    self.validationResults = {}
    
    -- Built-in templates
    self.templates = {
        player = {
            name = "Player Data Schema",
            description = "Standard player data structure",
            schema = {
                type = "object",
                properties = {
                    userId = {type = "number", required = true},
                    username = {type = "string", required = true},
                    level = {type = "number", minimum = 1, maximum = 100},
                    coins = {type = "number", minimum = 0},
                    inventory = {type = "array", items = {type = "string"}},
                    settings = {
                        type = "object",
                        properties = {
                            music = {type = "boolean"},
                            difficulty = {type = "string", enum = {"easy", "medium", "hard"}}
                        }
                    }
                }
            }
        },
        gameState = {
            name = "Game State Schema", 
            description = "Game configuration and state",
            schema = {
                type = "object",
                properties = {
                    version = {type = "string", required = true},
                    maxPlayers = {type = "number", minimum = 1, maximum = 50},
                    gameMode = {type = "string", enum = {"survival", "creative", "adventure"}}
                }
            }
        }
    }
    
    debugLog("Schema Service initialized", "INFO")
    return self
end

-- Create new schema
function SchemaService:createSchema(name, description)
    local schemaId = "schema_" .. tostring(tick())
    self.schemas[schemaId] = {
        id = schemaId,
        name = name,
        description = description,
        schema = {type = "object", properties = {}}
    }
    return schemaId
end

-- Add property to schema
function SchemaService:addProperty(schemaId, propertyName, propertyType, options)
    local schema = self.schemas[schemaId]
    if not schema then
        return false, "Schema not found"
    end
    
    options = options or {}
    
    local property = {
        type = propertyType,
        description = options.description,
        required = options.required or false
    }
    
    -- Add type-specific constraints
    if propertyType == "string" then
        property.minLength = options.minLength
        property.maxLength = options.maxLength
        property.enum = options.enum
    elseif propertyType == "number" then
        property.minimum = options.minimum
        property.maximum = options.maximum
    elseif propertyType == "array" then
        property.items = options.items or {type = "string"}
        property.minItems = options.minItems
        property.maxItems = options.maxItems
    elseif propertyType == "object" then
        property.properties = options.properties or {}
    end
    
    schema.schema.properties[propertyName] = property
    schema.modified = tick()
    
    debugLog(string.format("Added property '%s' to schema '%s'", propertyName, schema.name), "INFO")
    return true
end

-- Validate data against schema
function SchemaService:validateData(schemaId, data)
    local schema = self.schemas[schemaId]
    if not schema then
        return {
            valid = false,
            errors = {"Schema not found"},
            warnings = {}
        }
    end
    
    local result = {
        valid = true,
        errors = {},
        warnings = {}
    }
    
    self:validateValue(data, schema.schema, "", result)
    
    result.valid = #result.errors == 0
    
    -- Store validation result
    self.validationResults[schemaId] = self.validationResults[schemaId] or {}
    table.insert(self.validationResults[schemaId], {
        timestamp = tick(),
        result = result,
        dataSize = #HttpService:JSONEncode(data or {})
    })
    
    debugLog(string.format("Validated data against schema '%s': %s", 
        schema.name, result.valid and "VALID" or "INVALID"), "INFO")
    
    return result
end

-- Validate individual value
function SchemaService:validateValue(value, schemaProperty, path, result)
    local valueType = type(value)
    
    -- Handle nil values
    if value == nil then
        if schemaProperty.required then
            table.insert(result.errors, string.format("Required property '%s' is missing", path))
        end
        return
    end
    
    -- Validate type
    if not self:validateType(value, schemaProperty.type) then
        table.insert(result.errors, string.format("Property '%s' should be %s but got %s", 
            path, schemaProperty.type, valueType))
        return
    end
    
    -- Type-specific validation
    if schemaProperty.type == "string" then
        self:validateString(value, schemaProperty, path, result)
    elseif schemaProperty.type == "number" then
        self:validateNumber(value, schemaProperty, path, result)
    elseif schemaProperty.type == "array" then
        self:validateArray(value, schemaProperty, path, result)
    elseif schemaProperty.type == "object" then
        self:validateObject(value, schemaProperty, path, result)
    end
end

-- Validate type
function SchemaService:validateType(value, expectedType)
    local actualType = type(value)
    
    if expectedType == "array" then
        return actualType == "table" and self:isArray(value)
    elseif expectedType == "object" then
        return actualType == "table" and not self:isArray(value)
    else
        return actualType == expectedType
    end
end

-- Check if table is array
function SchemaService:isArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    
    local count = 0
    for k, v in pairs(tbl) do
        count = count + 1
        if type(k) ~= "number" or k ~= count then
            return false
        end
    end
    
    return true
end

-- Validate string
function SchemaService:validateString(value, schema, path, result)
    local str = tostring(value)
    
    if schema.minLength and #str < schema.minLength then
        table.insert(result.errors, string.format("Property '%s' is too short (min: %d)", path, schema.minLength))
    end
    
    if schema.maxLength and #str > schema.maxLength then
        table.insert(result.errors, string.format("Property '%s' is too long (max: %d)", path, schema.maxLength))
    end
    
    if schema.enum then
        local found = false
        for _, allowed in ipairs(schema.enum) do
            if str == allowed then
                found = true
                break
            end
        end
        if not found then
            table.insert(result.errors, string.format("Property '%s' must be one of: %s", 
                path, table.concat(schema.enum, ", ")))
        end
    end
end

-- Validate number
function SchemaService:validateNumber(value, schema, path, result)
    if schema.minimum and value < schema.minimum then
        table.insert(result.errors, string.format("Property '%s' is below minimum (%d)", path, schema.minimum))
    end
    
    if schema.maximum and value > schema.maximum then
        table.insert(result.errors, string.format("Property '%s' is above maximum (%d)", path, schema.maximum))
    end
end

-- Validate array
function SchemaService:validateArray(value, schema, path, result)
    if schema.minItems and #value < schema.minItems then
        table.insert(result.errors, string.format("Array '%s' has too few items (min: %d)", path, schema.minItems))
    end
    
    if schema.maxItems and #value > schema.maxItems then
        table.insert(result.errors, string.format("Array '%s' has too many items (max: %d)", path, schema.maxItems))
    end
    
    -- Validate each item
    if schema.items then
        for i, item in ipairs(value) do
            local itemPath = path .. "[" .. i .. "]"
            self:validateValue(item, schema.items, itemPath, result)
        end
    end
end

-- Validate object
function SchemaService:validateObject(value, schema, path, result)
    if schema.properties then
        -- Validate defined properties
        for propName, propSchema in pairs(schema.properties) do
            local propPath = path == "" and propName or path .. "." .. propName
            self:validateValue(value[propName], propSchema, propPath, result)
        end
    end
end

-- Get schema by ID
function SchemaService:getSchema(schemaId)
    return self.schemas[schemaId]
end

-- Get all schemas
function SchemaService:getAllSchemas()
    local schemaList = {}
    for id, schema in pairs(self.schemas) do
        table.insert(schemaList, {
            id = id,
            name = schema.name,
            description = schema.description,
            created = schema.created,
            modified = schema.modified
        })
    end
    
    table.sort(schemaList, function(a, b) return a.created > b.created end)
    return schemaList
end

-- Delete schema
function SchemaService:deleteSchema(schemaId)
    if self.schemas[schemaId] then
        local schemaName = self.schemas[schemaId].name
        self.schemas[schemaId] = nil
        self.validationResults[schemaId] = nil
        debugLog(string.format("Deleted schema: %s", schemaName), "INFO")
        return true
    end
    return false
end

-- Get templates
function SchemaService:getTemplates()
    return self.templates
end

-- Create schema from template
function SchemaService:createFromTemplate(templateName, schemaName)
    local template = self.templates[templateName]
    if not template then
        return nil, "Template not found"
    end
    
    local schemaId = self:createSchema(schemaName, template.description)
    local schema = self.schemas[schemaId]
    schema.schema = Utils.deepCopy(template.schema)
    
    debugLog(string.format("Created schema '%s' from template '%s'", schemaName, templateName), "INFO")
    return schemaId
end

-- Export schema to JSON
function SchemaService:exportSchema(schemaId)
    local schema = self.schemas[schemaId]
    if not schema then
        return nil, "Schema not found"
    end
    
    return HttpService:JSONEncode(schema)
end

-- Import schema from JSON
function SchemaService:importSchema(jsonStr, name)
    local success, schemaData = pcall(function()
        return HttpService:JSONDecode(jsonStr)
    end)
    
    if not success then
        return nil, "Invalid JSON format"
    end
    
    local schemaId = self:createSchema(name, schemaData.description or "Imported schema")
    local schema = self.schemas[schemaId]
    schema.schema = schemaData.schema or schemaData
    schema.version = schemaData.version or "1.0.0"
    
    debugLog(string.format("Imported schema: %s", name), "INFO")
    return schemaId
end

-- Get validation statistics
function SchemaService:getValidationStats(schemaId)
    local results = self.validationResults[schemaId] or {}
    
    local stats = {
        totalValidations = #results,
        successfulValidations = 0,
        failedValidations = 0,
        averageDataSize = 0,
        lastValidation = nil,
        successRate = 0
    }
    
    local totalSize = 0
    for _, result in ipairs(results) do
        if result.result.valid then
            stats.successfulValidations = stats.successfulValidations + 1
        else
            stats.failedValidations = stats.failedValidations + 1
        end
        totalSize = totalSize + result.dataSize
        stats.lastValidation = result.timestamp
    end
    
    if #results > 0 then
        stats.averageDataSize = totalSize / #results
        stats.successRate = stats.successfulValidations / #results * 100
    end
    
    return stats
end

function SchemaService.cleanup()
    debugLog("Schema Service cleanup complete", "INFO")
end

return SchemaService 