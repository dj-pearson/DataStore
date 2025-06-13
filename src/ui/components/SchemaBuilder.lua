-- Schema Builder & Validation Service
-- Define data schemas and validate data structure
-- Part of DataStore Manager Pro - Phase 2.3

local HttpService = game:GetService("HttpService")

-- Get shared utilities
local pluginRoot = script.Parent.Parent.Parent
local Constants = require(pluginRoot.shared.Constants)
local Utils = require(pluginRoot.shared.Utils)

local debugLog = Utils.debugLog

local SchemaBuilder = {}

function SchemaBuilder.new()
    local self = setmetatable({}, {__index = SchemaBuilder})
    
    -- Schema storage
    self.schemas = {}
    self.validationResults = {}
    
    -- Built-in data types
    self.dataTypes = {
        "string",
        "number", 
        "boolean",
        "table",
        "array",
        "object",
        "nil"
    }
    
    -- Schema templates
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
                    gameMode = {type = "string", enum = {"survival", "creative", "adventure"}},
                    worldSettings = {
                        type = "object",
                        properties = {
                            spawnPoint = {
                                type = "object",
                                properties = {
                                    x = {type = "number"},
                                    y = {type = "number"},
                                    z = {type = "number"}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    debugLog("Schema Builder initialized with templates", "INFO")
    return self
end

-- Create a new schema
function SchemaBuilder:createSchema(name, description)
    local schema = {
        id = self:generateSchemaId(),
        name = name,
        description = description or "",
        version = "1.0.0",
        created = tick(),
        modified = tick(),
        schema = {
            type = "object",
            properties = {}
        }
    }
    
    self.schemas[schema.id] = schema
    debugLog(string.format("Created new schema: %s", name), "INFO")
    
    return schema.id
end

-- Generate unique schema ID
function SchemaBuilder:generateSchemaId()
    return "schema_" .. tostring(tick()):gsub("%.", "_")
end

-- Add property to schema
function SchemaBuilder:addProperty(schemaId, propertyName, propertyType, options)
    local schema = self.schemas[schemaId]
    if not schema then
        return false, "Schema not found"
    end
    
    options = options or {}
    
    local property = {
        type = propertyType,
        description = options.description,
        required = options.required or false,
        default = options.default
    }
    
    -- Add type-specific constraints
    if propertyType == "string" then
        property.minLength = options.minLength
        property.maxLength = options.maxLength
        property.pattern = options.pattern
        property.enum = options.enum
    elseif propertyType == "number" then
        property.minimum = options.minimum
        property.maximum = options.maximum
        property.multipleOf = options.multipleOf
    elseif propertyType == "array" then
        property.items = options.items or {type = "string"}
        property.minItems = options.minItems
        property.maxItems = options.maxItems
        property.uniqueItems = options.uniqueItems
    elseif propertyType == "object" then
        property.properties = options.properties or {}
        property.additionalProperties = options.additionalProperties
    end
    
    schema.schema.properties[propertyName] = property
    schema.modified = tick()
    
    debugLog(string.format("Added property '%s' to schema '%s'", propertyName, schema.name), "INFO")
    return true
end

-- Remove property from schema
function SchemaBuilder:removeProperty(schemaId, propertyName)
    local schema = self.schemas[schemaId]
    if not schema then
        return false, "Schema not found"
    end
    
    if schema.schema.properties[propertyName] then
        schema.schema.properties[propertyName] = nil
        schema.modified = tick()
        debugLog(string.format("Removed property '%s' from schema '%s'", propertyName, schema.name), "INFO")
        return true
    end
    
    return false, "Property not found"
end

-- Validate data against schema
function SchemaBuilder:validateData(schemaId, data)
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
        warnings = {},
        details = {}
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
function SchemaBuilder:validateValue(value, schemaProperty, path, result)
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
function SchemaBuilder:validateType(value, expectedType)
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
function SchemaBuilder:isArray(tbl)
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
function SchemaBuilder:validateString(value, schema, path, result)
    local str = tostring(value)
    
    if schema.minLength and #str < schema.minLength then
        table.insert(result.errors, string.format("Property '%s' is too short (min: %d)", path, schema.minLength))
    end
    
    if schema.maxLength and #str > schema.maxLength then
        table.insert(result.errors, string.format("Property '%s' is too long (max: %d)", path, schema.maxLength))
    end
    
    if schema.pattern then
        if not string.find(str, schema.pattern) then
            table.insert(result.errors, string.format("Property '%s' does not match pattern", path))
        end
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
function SchemaBuilder:validateNumber(value, schema, path, result)
    if schema.minimum and value < schema.minimum then
        table.insert(result.errors, string.format("Property '%s' is below minimum (%d)", path, schema.minimum))
    end
    
    if schema.maximum and value > schema.maximum then
        table.insert(result.errors, string.format("Property '%s' is above maximum (%d)", path, schema.maximum))
    end
    
    if schema.multipleOf and value % schema.multipleOf ~= 0 then
        table.insert(result.errors, string.format("Property '%s' must be multiple of %d", path, schema.multipleOf))
    end
end

-- Validate array
function SchemaBuilder:validateArray(value, schema, path, result)
    if schema.minItems and #value < schema.minItems then
        table.insert(result.errors, string.format("Array '%s' has too few items (min: %d)", path, schema.minItems))
    end
    
    if schema.maxItems and #value > schema.maxItems then
        table.insert(result.errors, string.format("Array '%s' has too many items (max: %d)", path, schema.maxItems))
    end
    
    if schema.uniqueItems then
        local seen = {}
        for i, item in ipairs(value) do
            local itemStr = HttpService:JSONEncode(item)
            if seen[itemStr] then
                table.insert(result.errors, string.format("Array '%s' has duplicate items", path))
                break
            end
            seen[itemStr] = true
        end
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
function SchemaBuilder:validateObject(value, schema, path, result)
    if schema.properties then
        -- Validate defined properties
        for propName, propSchema in pairs(schema.properties) do
            local propPath = path == "" and propName or path .. "." .. propName
            self:validateValue(value[propName], propSchema, propPath, result)
        end
        
        -- Check for additional properties
        if schema.additionalProperties == false then
            for propName in pairs(value) do
                if not schema.properties[propName] then
                    table.insert(result.warnings, string.format("Unexpected property '%s' in object '%s'", 
                        propName, path))
                end
            end
        end
    end
end

-- Get schema by ID
function SchemaBuilder:getSchema(schemaId)
    return self.schemas[schemaId]
end

-- Get all schemas
function SchemaBuilder:getAllSchemas()
    local schemaList = {}
    for id, schema in pairs(self.schemas) do
        table.insert(schemaList, {
            id = id,
            name = schema.name,
            description = schema.description,
            version = schema.version,
            created = schema.created,
            modified = schema.modified
        })
    end
    
    table.sort(schemaList, function(a, b) return a.created > b.created end)
    return schemaList
end

-- Delete schema
function SchemaBuilder:deleteSchema(schemaId)
    if self.schemas[schemaId] then
        local schemaName = self.schemas[schemaId].name
        self.schemas[schemaId] = nil
        self.validationResults[schemaId] = nil
        debugLog(string.format("Deleted schema: %s", schemaName), "INFO")
        return true
    end
    return false
end

-- Clone schema
function SchemaBuilder:cloneSchema(schemaId, newName)
    local originalSchema = self.schemas[schemaId]
    if not originalSchema then
        return nil, "Schema not found"
    end
    
    local newSchemaId = self:generateSchemaId()
    local clonedSchema = {
        id = newSchemaId,
        name = newName,
        description = originalSchema.description .. " (Copy)",
        version = "1.0.0",
        created = tick(),
        modified = tick(),
        schema = Utils.deepCopy(originalSchema.schema)
    }
    
    self.schemas[newSchemaId] = clonedSchema
    debugLog(string.format("Cloned schema '%s' to '%s'", originalSchema.name, newName), "INFO")
    
    return newSchemaId
end

-- Get schema templates
function SchemaBuilder:getTemplates()
    return self.templates
end

-- Create schema from template
function SchemaBuilder:createFromTemplate(templateName, schemaName)
    local template = self.templates[templateName]
    if not template then
        return nil, "Template not found"
    end
    
    local schemaId = self:generateSchemaId()
    local schema = {
        id = schemaId,
        name = schemaName,
        description = template.description,
        version = "1.0.0",
        created = tick(),
        modified = tick(),
        schema = Utils.deepCopy(template.schema)
    }
    
    self.schemas[schemaId] = schema
    debugLog(string.format("Created schema '%s' from template '%s'", schemaName, templateName), "INFO")
    
    return schemaId
end

-- Import schema from JSON
function SchemaBuilder:importSchema(jsonStr, name)
    local success, schemaData = pcall(function()
        return HttpService:JSONDecode(jsonStr)
    end)
    
    if not success then
        return nil, "Invalid JSON format"
    end
    
    local schemaId = self:generateSchemaId()
    local schema = {
        id = schemaId,
        name = name,
        description = schemaData.description or "Imported schema",
        version = schemaData.version or "1.0.0",
        created = tick(),
        modified = tick(),
        schema = schemaData.schema or schemaData
    }
    
    self.schemas[schemaId] = schema
    debugLog(string.format("Imported schema: %s", name), "INFO")
    
    return schemaId
end

-- Export schema to JSON
function SchemaBuilder:exportSchema(schemaId)
    local schema = self.schemas[schemaId]
    if not schema then
        return nil, "Schema not found"
    end
    
    return HttpService:JSONEncode(schema)
end

-- Get validation statistics
function SchemaBuilder:getValidationStats(schemaId)
    local results = self.validationResults[schemaId] or {}
    
    local stats = {
        totalValidations = #results,
        successfulValidations = 0,
        failedValidations = 0,
        averageDataSize = 0,
        lastValidation = nil
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

function SchemaBuilder.cleanup()
    debugLog("Schema Builder cleanup complete", "INFO")
end

return SchemaBuilder 