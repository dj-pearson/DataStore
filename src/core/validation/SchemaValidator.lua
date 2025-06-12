local HttpService = game:GetService("HttpService")
local Logger = require(script.Parent.Parent.logging.Logger)

local SchemaValidator = {}
SchemaValidator.__index = SchemaValidator

-- Schema types and validators
local TYPE_VALIDATORS = {
    string = function(value)
        return type(value) == "string"
    end,
    number = function(value)
        return type(value) == "number"
    end,
    boolean = function(value)
        return type(value) == "boolean"
    end,
    table = function(value)
        return type(value) == "table"
    end,
    array = function(value)
        return type(value) == "table" and #value > 0
    end,
    object = function(value)
        return type(value) == "table" and not (#value > 0)
    end,
    any = function()
        return true
    end
}

-- Schema constraints
local CONSTRAINT_VALIDATORS = {
    min = function(value, constraint)
        return value >= constraint
    end,
    max = function(value, constraint)
        return value <= constraint
    end,
    length = function(value, constraint)
        return #value == constraint
    end,
    minLength = function(value, constraint)
        return #value >= constraint
    end,
    maxLength = function(value, constraint)
        return #value <= constraint
    end,
    pattern = function(value, constraint)
        return string.match(value, constraint) ~= nil
    end,
    enum = function(value, constraint)
        for _, v in ipairs(constraint) do
            if value == v then
                return true
            end
        end
        return false
    end,
    required = function(value, constraint)
        return not constraint or value ~= nil
    end
}

function SchemaValidator.new()
    local self = setmetatable({}, SchemaValidator)
    self.schemas = {}
    self.versions = {}
    self.migrations = {}
    return self
end

-- Register a new schema
function SchemaValidator:registerSchema(name, schema, version)
    if not name or not schema then
        error("Schema name and definition are required")
    end

    version = version or "1.0.0"
    self.schemas[name] = schema
    self.versions[name] = version

    Logger:info("Registered schema", {
        name = name,
        version = version
    })
end

-- Register a migration between schema versions
function SchemaValidator:registerMigration(name, fromVersion, toVersion, migrationFn)
    if not name or not fromVersion or not toVersion or not migrationFn then
        error("Migration name, versions, and function are required")
    end

    self.migrations[name] = self.migrations[name] or {}
    self.migrations[name][fromVersion] = self.migrations[name][fromVersion] or {}
    self.migrations[name][fromVersion][toVersion] = migrationFn

    Logger:info("Registered migration", {
        name = name,
        fromVersion = fromVersion,
        toVersion = toVersion
    })
end

-- Validate data against a schema
function SchemaValidator:validate(name, data)
    local schema = self.schemas[name]
    if not schema then
        error("Schema not found: " .. tostring(name))
    end

    local errors = {}
    local function validateField(field, value, fieldSchema, path)
        path = path or field

        -- Check type
        local typeValidator = TYPE_VALIDATORS[fieldSchema.type]
        if not typeValidator then
            table.insert(errors, {
                path = path,
                message = "Invalid type: " .. tostring(fieldSchema.type)
            })
            return false
        end

        if not typeValidator(value) then
            table.insert(errors, {
                path = path,
                message = "Expected type " .. fieldSchema.type .. ", got " .. type(value)
            })
            return false
        end

        -- Check constraints
        for constraint, constraintValue in pairs(fieldSchema) do
            if constraint ~= "type" and CONSTRAINT_VALIDATORS[constraint] then
                if not CONSTRAINT_VALIDATORS[constraint](value, constraintValue) then
                    table.insert(errors, {
                        path = path,
                        message = "Constraint violation: " .. constraint
                    })
                    return false
                end
            end
        end

        -- Recursively validate nested objects
        if fieldSchema.type == "object" and fieldSchema.properties then
            for propName, propSchema in pairs(fieldSchema.properties) do
                local propValue = value[propName]
                validateField(propName, propValue, propSchema, path .. "." .. propName)
            end
        end

        -- Validate array items
        if fieldSchema.type == "array" and fieldSchema.items then
            for i, item in ipairs(value) do
                validateField(i, item, fieldSchema.items, path .. "[" .. i .. "]")
            end
        end

        return true
    end

    local isValid = validateField("root", data, schema)
    return isValid, errors
end

-- Migrate data between schema versions
function SchemaValidator:migrate(name, data, targetVersion)
    local currentVersion = self.versions[name]
    if not currentVersion then
        error("Schema not found: " .. tostring(name))
    end

    if currentVersion == targetVersion then
        return data
    end

    local migrations = self.migrations[name]
    if not migrations or not migrations[currentVersion] or not migrations[currentVersion][targetVersion] then
        error("Migration not found from " .. currentVersion .. " to " .. targetVersion)
    end

    local migrationFn = migrations[currentVersion][targetVersion]
    local success, result = pcall(migrationFn, data)
    
    if not success then
        error("Migration failed: " .. tostring(result))
    end

    Logger:info("Migrated data", {
        name = name,
        fromVersion = currentVersion,
        toVersion = targetVersion
    })

    return result
end

-- Generate schema documentation
function SchemaValidator:generateDocumentation(name)
    local schema = self.schemas[name]
    if not schema then
        error("Schema not found: " .. tostring(name))
    end

    local function generateFieldDocs(fieldSchema, path, level)
        level = level or 0
        local indent = string.rep("  ", level)
        local docs = {}

        -- Add field description
        if fieldSchema.description then
            table.insert(docs, indent .. "Description: " .. fieldSchema.description)
        end

        -- Add type information
        table.insert(docs, indent .. "Type: " .. fieldSchema.type)

        -- Add constraints
        for constraint, value in pairs(fieldSchema) do
            if constraint ~= "type" and constraint ~= "description" and CONSTRAINT_VALIDATORS[constraint] then
                table.insert(docs, indent .. "Constraint: " .. constraint .. " = " .. tostring(value))
            end
        end

        -- Add nested object documentation
        if fieldSchema.type == "object" and fieldSchema.properties then
            table.insert(docs, indent .. "Properties:")
            for propName, propSchema in pairs(fieldSchema.properties) do
                table.insert(docs, indent .. "  " .. propName .. ":")
                local propDocs = generateFieldDocs(propSchema, path .. "." .. propName, level + 2)
                for _, doc in ipairs(propDocs) do
                    table.insert(docs, doc)
                end
            end
        end

        -- Add array item documentation
        if fieldSchema.type == "array" and fieldSchema.items then
            table.insert(docs, indent .. "Items:")
            local itemDocs = generateFieldDocs(fieldSchema.items, path .. "[]", level + 2)
            for _, doc in ipairs(itemDocs) do
                table.insert(docs, doc)
            end
        end

        return docs
    end

    local docs = {
        "Schema: " .. name,
        "Version: " .. self.versions[name],
        "",
        "Structure:"
    }

    local fieldDocs = generateFieldDocs(schema)
    for _, doc in ipairs(fieldDocs) do
        table.insert(docs, doc)
    end

    return table.concat(docs, "\n")
end

-- Export schema to JSON
function SchemaValidator:exportSchema(name)
    local schema = self.schemas[name]
    if not schema then
        error("Schema not found: " .. tostring(name))
    end

    return HttpService:JSONEncode({
        name = name,
        version = self.versions[name],
        schema = schema
    })
end

-- Import schema from JSON
function SchemaValidator:importSchema(jsonString)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)

    if not success then
        error("Invalid JSON: " .. tostring(data))
    end

    if not data.name or not data.schema then
        error("Invalid schema format")
    end

    self:registerSchema(data.name, data.schema, data.version)
    return true
end

return SchemaValidator 