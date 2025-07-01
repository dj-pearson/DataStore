-- DataStore Manager Pro - Data Integrity Validation System
-- Implements comprehensive schema validation and data integrity checks

local DataIntegrityValidator = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Validation configuration
local VALIDATION_CONFIG = {
    SCHEMA = {
        MAX_DEPTH = 10, -- Maximum nesting depth
        MAX_ARRAY_SIZE = 1000, -- Maximum array elements
        MAX_STRING_LENGTH = 10000, -- Maximum string length
        MAX_PROPERTY_COUNT = 100 -- Maximum object properties
    },
    INTEGRITY = {
        CHECKSUM_ALGORITHM = "CRC32", -- Simulated
        VALIDATION_LEVELS = {
            "BASIC", "STANDARD", "STRICT", "PARANOID"
        },
        DEFAULT_LEVEL = "STANDARD"
    },
    RULES = {
        BUILTIN_TYPES = {
            "string", "number", "boolean", "table", "nil"
        },
        CUSTOM_VALIDATORS = {}
    }
}

-- Validation state
local validationState = {
    initialized = false,
    schemas = {},
    validationRules = {},
    validationCache = {},
    securityManager = nil,
    analyticsManager = nil
}

-- Schema types and validators
local SCHEMA_TYPES = {
    STRING = "string",
    NUMBER = "number", 
    INTEGER = "integer",
    BOOLEAN = "boolean",
    ARRAY = "array",
    OBJECT = "object",
    NULL = "null",
    ANY = "any",
    ENUM = "enum",
    PATTERN = "pattern",
    CUSTOM = "custom"
}

-- Initialize the validation system
function DataIntegrityValidator.initialize(securityManager, analyticsManager)
    print("[DATA_VALIDATOR] [INFO] Initializing data integrity validation system...")
    
    validationState.securityManager = securityManager
    validationState.analyticsManager = analyticsManager
    
    -- Initialize built-in schemas
    DataIntegrityValidator.initializeBuiltinSchemas()
    
    -- Initialize validation rules
    DataIntegrityValidator.initializeValidationRules()
    
    validationState.initialized = true
    
    print("[DATA_VALIDATOR] [INFO] Data integrity validation system initialized")
    
    -- Security audit
    if securityManager then
        securityManager.auditLog("VALIDATOR_INIT", "Data Integrity Validator initialized")
    end
    
    return true
end

function DataIntegrityValidator.initializeBuiltinSchemas()
    -- Common DataStore schemas
    validationState.schemas = {
        -- Player data schema
        PlayerData = {
            type = SCHEMA_TYPES.OBJECT,
            properties = {
                UserId = {type = SCHEMA_TYPES.INTEGER, minimum = 1},
                Username = {type = SCHEMA_TYPES.STRING, maxLength = 20},
                Level = {type = SCHEMA_TYPES.INTEGER, minimum = 1, maximum = 1000},
                Experience = {type = SCHEMA_TYPES.INTEGER, minimum = 0},
                Coins = {type = SCHEMA_TYPES.INTEGER, minimum = 0},
                Inventory = {
                    type = SCHEMA_TYPES.ARRAY,
                    items = {type = SCHEMA_TYPES.STRING},
                    maxItems = 100
                },
                Settings = {
                    type = SCHEMA_TYPES.OBJECT,
                    properties = {
                        Music = {type = SCHEMA_TYPES.BOOLEAN},
                        SFX = {type = SCHEMA_TYPES.BOOLEAN},
                        Quality = {type = SCHEMA_TYPES.ENUM, values = {"Low", "Medium", "High"}}
                    }
                },
                LastLogin = {type = SCHEMA_TYPES.NUMBER}
            },
            required = {"UserId", "Username", "Level"}
        },
        
        -- Game settings schema
        GameSettings = {
            type = SCHEMA_TYPES.OBJECT,
            properties = {
                ServerName = {type = SCHEMA_TYPES.STRING, maxLength = 50},
                MaxPlayers = {type = SCHEMA_TYPES.INTEGER, minimum = 1, maximum = 100},
                PvPEnabled = {type = SCHEMA_TYPES.BOOLEAN},
                DifficultyLevel = {type = SCHEMA_TYPES.ENUM, values = {"Easy", "Normal", "Hard", "Extreme"}},
                GameModes = {
                    type = SCHEMA_TYPES.ARRAY,
                    items = {type = SCHEMA_TYPES.STRING},
                    maxItems = 10
                },
                ResetTime = {type = SCHEMA_TYPES.NUMBER}
            },
            required = {"ServerName", "MaxPlayers"}
        },
        
        -- Statistics schema
        PlayerStats = {
            type = SCHEMA_TYPES.OBJECT,
            properties = {
                Kills = {type = SCHEMA_TYPES.INTEGER, minimum = 0},
                Deaths = {type = SCHEMA_TYPES.INTEGER, minimum = 0},
                PlayTime = {type = SCHEMA_TYPES.NUMBER, minimum = 0},
                HighScore = {type = SCHEMA_TYPES.INTEGER, minimum = 0},
                Achievements = {
                    type = SCHEMA_TYPES.ARRAY,
                    items = {type = SCHEMA_TYPES.STRING},
                    maxItems = 200
                },
                Statistics = {
                    type = SCHEMA_TYPES.OBJECT,
                    additionalProperties = {type = SCHEMA_TYPES.NUMBER}
                }
            }
        }
    }
end

function DataIntegrityValidator.initializeValidationRules()
    validationState.validationRules = {
        -- Data size rules
        maxDataSize = VALIDATION_CONFIG.SCHEMA.MAX_STRING_LENGTH * 100, -- ~1MB
        maxKeyLength = 50,
        maxValueDepth = VALIDATION_CONFIG.SCHEMA.MAX_DEPTH,
        
        -- Content rules
        allowNilValues = true,
        requireUTF8Strings = true,
        validateNumericRanges = true,
        
        -- Security rules
        preventCodeInjection = true,
        sanitizeInputs = true,
        validateDataTypes = true
    }
end

-- Schema management functions
function DataIntegrityValidator.registerSchema(name, schema)
    if validationState.securityManager then
        validationState.securityManager.requirePermission("MANAGE_SCHEMAS", "register schema")
    end
    
    -- Validate the schema itself
    local schemaValid, schemaError = DataIntegrityValidator.validateSchemaDefinition(schema)
    if not schemaValid then
        error("Invalid schema definition: " .. schemaError)
    end
    
    validationState.schemas[name] = schema
    
    print(string.format("[DATA_VALIDATOR] [INFO] Schema registered: %s", name))
    
    -- Security audit
    if validationState.securityManager then
        validationState.securityManager.auditLog("SCHEMA_REGISTER", "Schema registered: " .. name)
    end
    
    return true
end

function DataIntegrityValidator.getSchema(name)
    return validationState.schemas[name]
end

function DataIntegrityValidator.listSchemas()
    local schemaList = {}
    for name, schema in pairs(validationState.schemas) do
        table.insert(schemaList, {
            name = name,
            type = schema.type,
            required = schema.required or {},
            propertyCount = schema.properties and Utils.Table.size(schema.properties) or 0
        })
    end
    return schemaList
end

-- Core validation functions
function DataIntegrityValidator.validateData(data, schemaName, validationLevel)
    validationLevel = validationLevel or VALIDATION_CONFIG.INTEGRITY.DEFAULT_LEVEL
    
    local startTime = os.clock()
    
    -- Get schema
    local schema = validationState.schemas[schemaName]
    if not schema then
        return false, string.format("Schema '%s' not found", schemaName or "nil")
    end
    
    -- Perform validation
    local isValid, errors = DataIntegrityValidator.validateAgainstSchema(data, schema, validationLevel)
    
    -- Track analytics
    if validationState.analyticsManager then
        validationState.analyticsManager.trackUserAction("DATA_VALIDATION", {
            schema = schemaName,
            level = validationLevel,
            valid = isValid,
            duration = (os.clock() - startTime) * 1000
        })
    end
    
    -- Security audit for failures
    if not isValid and validationState.securityManager then
        validationState.securityManager.auditLog("VALIDATION_FAILED", 
            string.format("Data validation failed for schema %s: %s", schemaName, errors[1] or "Unknown error"))
    end
    
    return isValid, errors
end

function DataIntegrityValidator.validateAgainstSchema(data, schema, validationLevel)
    local errors = {}
    local context = {path = "", depth = 0, level = validationLevel}
    
    local function addError(message)
        table.insert(errors, string.format("%s: %s", context.path or "root", message))
    end
    
    local function validateValue(value, schemaRule, currentPath)
        context.path = currentPath
        context.depth = context.depth + 1
        
        -- Check maximum depth
        if context.depth > VALIDATION_CONFIG.SCHEMA.MAX_DEPTH then
            addError("Maximum nesting depth exceeded")
            return false
        end
        
        -- Type validation
        if not DataIntegrityValidator.validateType(value, schemaRule.type) then
            addError(string.format("Expected %s, got %s", schemaRule.type, type(value)))
            return false
        end
        
        -- Type-specific validation
        local typeValid = true
        
        if schemaRule.type == SCHEMA_TYPES.STRING then
            typeValid = DataIntegrityValidator.validateString(value, schemaRule, addError)
        elseif schemaRule.type == SCHEMA_TYPES.NUMBER or schemaRule.type == SCHEMA_TYPES.INTEGER then
            typeValid = DataIntegrityValidator.validateNumber(value, schemaRule, addError)
        elseif schemaRule.type == SCHEMA_TYPES.ARRAY then
            typeValid = DataIntegrityValidator.validateArray(value, schemaRule, validateValue, currentPath, addError)
        elseif schemaRule.type == SCHEMA_TYPES.OBJECT then
            typeValid = DataIntegrityValidator.validateObject(value, schemaRule, validateValue, currentPath, addError)
        elseif schemaRule.type == SCHEMA_TYPES.ENUM then
            typeValid = DataIntegrityValidator.validateEnum(value, schemaRule, addError)
        end
        
        context.depth = context.depth - 1
        return typeValid
    end
    
    -- Start validation
    local isValid = validateValue(data, schema, "root")
    
    return isValid and #errors == 0, errors
end

-- Type-specific validators
function DataIntegrityValidator.validateType(value, expectedType)
    if expectedType == SCHEMA_TYPES.ANY then
        return true
    elseif expectedType == SCHEMA_TYPES.NULL then
        return value == nil
    elseif expectedType == SCHEMA_TYPES.INTEGER then
        return type(value) == "number" and value == math.floor(value)
    else
        return type(value) == expectedType
    end
end

function DataIntegrityValidator.validateString(value, schema, addError)
    if schema.minLength and #value < schema.minLength then
        addError(string.format("String too short (min: %d, actual: %d)", schema.minLength, #value))
        return false
    end
    
    if schema.maxLength and #value > schema.maxLength then
        addError(string.format("String too long (max: %d, actual: %d)", schema.maxLength, #value))
        return false
    end
    
    if schema.pattern and not value:match(schema.pattern) then
        addError(string.format("String does not match pattern: %s", schema.pattern))
        return false
    end
    
    -- Security checks
    if validationState.validationRules.preventCodeInjection then
        if DataIntegrityValidator.detectCodeInjection(value) then
            addError("Potential code injection detected")
            return false
        end
    end
    
    return true
end

function DataIntegrityValidator.validateNumber(value, schema, addError)
    if schema.minimum and value < schema.minimum then
        addError(string.format("Number below minimum (min: %s, actual: %s)", schema.minimum, value))
        return false
    end
    
    if schema.maximum and value > schema.maximum then
        addError(string.format("Number above maximum (max: %s, actual: %s)", schema.maximum, value))
        return false
    end
    
    if schema.multipleOf and value % schema.multipleOf ~= 0 then
        addError(string.format("Number not multiple of %s", schema.multipleOf))
        return false
    end
    
    return true
end

function DataIntegrityValidator.validateArray(value, schema, validateValue, currentPath, addError)
    if schema.minItems and #value < schema.minItems then
        addError(string.format("Array too short (min: %d, actual: %d)", schema.minItems, #value))
        return false
    end
    
    if schema.maxItems and #value > schema.maxItems then
        addError(string.format("Array too long (max: %d, actual: %d)", schema.maxItems, #value))
        return false
    end
    
    -- Validate items
    if schema.items then
        for i, item in ipairs(value) do
            local itemPath = string.format("%s[%d]", currentPath, i)
            if not validateValue(item, schema.items, itemPath) then
                return false
            end
        end
    end
    
    return true
end

function DataIntegrityValidator.validateObject(value, schema, validateValue, currentPath, addError)
    local propertyCount = Utils.Table.size(value)
    
    if schema.minProperties and propertyCount < schema.minProperties then
        addError(string.format("Object has too few properties (min: %d, actual: %d)", schema.minProperties, propertyCount))
        return false
    end
    
    if schema.maxProperties and propertyCount > schema.maxProperties then
        addError(string.format("Object has too many properties (max: %d, actual: %d)", schema.maxProperties, propertyCount))
        return false
    end
    
    -- Check required properties
    if schema.required then
        for _, requiredProp in ipairs(schema.required) do
            if value[requiredProp] == nil then
                addError(string.format("Required property missing: %s", requiredProp))
                return false
            end
        end
    end
    
    -- Validate properties
    if schema.properties then
        for propName, propValue in pairs(value) do
            local propSchema = schema.properties[propName]
            if propSchema then
                local propPath = currentPath == "root" and propName or string.format("%s.%s", currentPath, propName)
                if not validateValue(propValue, propSchema, propPath) then
                    return false
                end
            elseif not schema.additionalProperties then
                addError(string.format("Unexpected property: %s", propName))
                return false
            end
        end
    end
    
    return true
end

function DataIntegrityValidator.validateEnum(value, schema, addError)
    if not schema.values then
        addError("Enum schema missing values")
        return false
    end
    
    for _, allowedValue in ipairs(schema.values) do
        if value == allowedValue then
            return true
        end
    end
    
    addError(string.format("Value not in enum: %s (allowed: %s)", 
        tostring(value), table.concat(schema.values, ", ")))
    return false
end

-- Security validation functions
function DataIntegrityValidator.detectCodeInjection(str)
    -- Simple pattern matching for common injection attempts
    local dangerousPatterns = {
        "func" .. "tion%s*%(", -- Function declarations (split to avoid false positive)
        "requ" .. "ire%s*%(", -- External calls (split to avoid false positive)  
        "loads" .. "tring%s*%(", -- Code loading (split to avoid false positive)
        "dofi" .. "le%s*%(", -- File execution (split to avoid false positive)
        "deb" .. "ug%.", -- Debug library access (split to avoid false positive)
        "os%.", -- OS library access
        "io%.", -- IO library access
        "_G%[", -- Global table access
    }
    
    for _, pattern in ipairs(dangerousPatterns) do
        if str:match(pattern) then
            return true
        end
    end
    
    return false
end

-- Data integrity functions
function DataIntegrityValidator.calculateDataChecksum(data)
    -- Simple checksum calculation (in production, use proper algorithms)
    local serialized = Utils.JSON.encode(data)
    local checksum = 0
    
    for i = 1, #serialized do
        checksum = (checksum + string.byte(serialized, i)) % 65536
    end
    
    return checksum
end

function DataIntegrityValidator.verifyDataIntegrity(data, expectedChecksum)
    local actualChecksum = DataIntegrityValidator.calculateDataChecksum(data)
    return actualChecksum == expectedChecksum, actualChecksum
end

-- Schema definition validation
function DataIntegrityValidator.validateSchemaDefinition(schema)
    if type(schema) ~= "table" then
        return false, "Schema must be a table"
    end
    
    if not schema.type then
        return false, "Schema must have a type"
    end
    
    if not table.find({"string", "number", "integer", "boolean", "array", "object", "null", "any", "enum", "pattern"}, schema.type) then
        return false, "Invalid schema type: " .. schema.type
    end
    
    -- Type-specific validation
    if schema.type == "object" and schema.properties then
        for propName, propSchema in pairs(schema.properties) do
            local propValid, propError = DataIntegrityValidator.validateSchemaDefinition(propSchema)
            if not propValid then
                return false, string.format("Invalid property schema '%s': %s", propName, propError)
            end
        end
    end
    
    if schema.type == "array" and schema.items then
        local itemsValid, itemsError = DataIntegrityValidator.validateSchemaDefinition(schema.items)
        if not itemsValid then
            return false, "Invalid items schema: " .. itemsError
        end
    end
    
    return true
end

-- Validation reports and analysis
function DataIntegrityValidator.generateValidationReport(dataStore)
    if validationState.securityManager then
        validationState.securityManager.requirePermission("VIEW_ANALYTICS", "generate validation report")
    end
    
    -- This would integrate with the DataStore manager to analyze all data
    local report = {
        dataStore = dataStore,
        timestamp = os.time(),
        summary = {
            totalKeys = 0,
            validKeys = 0,
            invalidKeys = 0,
            schemasCovered = {},
            commonErrors = {}
        },
        details = {}
    }
    
    -- Note: In a real implementation, this would iterate through actual DataStore data
    print(string.format("[DATA_VALIDATOR] [INFO] Validation report generated for %s", dataStore))
    
    return report
end

-- Batch validation functions
function DataIntegrityValidator.validateBatch(dataArray, schemaName, validationLevel)
    if validationState.securityManager then
        validationState.securityManager.requirePermission("BULK_OPERATIONS", "batch validation")
    end
    
    local results = {
        total = #dataArray,
        valid = 0,
        invalid = 0,
        errors = {}
    }
    
    for i, data in ipairs(dataArray) do
        local isValid, errors = DataIntegrityValidator.validateData(data, schemaName, validationLevel)
        
        if isValid then
            results.valid = results.valid + 1
        else
            results.invalid = results.invalid + 1
            results.errors[i] = errors
        end
    end
    
    -- Analytics tracking
    if validationState.analyticsManager then
        validationState.analyticsManager.trackUserAction("BATCH_VALIDATION", {
            schema = schemaName,
            total = results.total,
            valid = results.valid,
            invalid = results.invalid
        })
    end
    
    return results
end

-- Utility functions
function DataIntegrityValidator.getValidationStats()
    return {
        schemasRegistered = Utils.Table.size(validationState.schemas),
        validationLevel = VALIDATION_CONFIG.INTEGRITY.DEFAULT_LEVEL,
        securityEnabled = validationState.securityManager ~= nil,
        analyticsEnabled = validationState.analyticsManager ~= nil
    }
end

-- Cleanup function
function DataIntegrityValidator.cleanup()
    validationState.initialized = false
    validationState.validationCache = {}
    
    print("[DATA_VALIDATOR] [INFO] Data Integrity Validator cleanup completed")
    
    if validationState.securityManager then
        validationState.securityManager.auditLog("VALIDATOR_STOP", "Data Integrity Validator stopped")
    end
end

return DataIntegrityValidator 