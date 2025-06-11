-- DataStore Manager Pro - API Integration System
-- Enterprise API integration with REST endpoints, webhooks, and third-party connectors

local APIManager = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)
local HttpService = game:GetService("HttpService")

-- API configuration
local API_CONFIG = {
    ENDPOINTS = {
        BASE_URL = "/api/v1",
        RATE_LIMIT = 1000, -- requests per hour
        MAX_PAYLOAD_SIZE = 1048576, -- 1MB
        TIMEOUT_SECONDS = 30
    },
    WEBHOOKS = {
        MAX_WEBHOOKS = 50,
        RETRY_ATTEMPTS = 3,
        RETRY_DELAY = 5, -- seconds
        TIMEOUT_SECONDS = 10
    },
    INTEGRATIONS = {
        SUPPORTED_PLATFORMS = {
            "SLACK", "DISCORD", "TEAMS", "DATADOG", "SPLUNK", 
            "PROMETHEUS", "GRAFANA", "ELASTICSEARCH", "CUSTOM"
        },
        CONFIG_ENCRYPTION = true,
        CREDENTIAL_MASKING = true
    },
    SECURITY = {
        API_KEY_LENGTH = 32,
        JWT_EXPIRY = 3600, -- 1 hour
        REQUIRE_HTTPS = true,
        CORS_ENABLED = true
    }
}

-- API state
local apiState = {
    endpoints = {},
    webhooks = {},
    integrations = {},
    apiKeys = {},
    rateLimits = {},
    requestLog = {},
    initialized = false,
    server = nil -- Would be actual HTTP server in production
}

-- HTTP methods
local HTTP_METHODS = {
    GET = "GET",
    POST = "POST", 
    PUT = "PUT",
    DELETE = "DELETE",
    PATCH = "PATCH"
}

-- Integration platform configurations
local INTEGRATION_PLATFORMS = {
    SLACK = {
        name = "Slack",
        type = "CHAT",
        webhookUrl = true,
        supportedEvents = {"ALERT", "DATA_CHANGE", "USER_ACTIVITY", "SYSTEM_EVENT"},
        configFields = {"webhook_url", "channel", "username", "icon_emoji"},
        testEndpoint = "/test"
    },
    DISCORD = {
        name = "Discord",
        type = "CHAT",
        webhookUrl = true,
        supportedEvents = {"ALERT", "DATA_CHANGE", "USER_ACTIVITY", "SYSTEM_EVENT"},
        configFields = {"webhook_url", "username", "avatar_url"},
        testEndpoint = "/test"
    },
    DATADOG = {
        name = "Datadog",
        type = "MONITORING",
        apiKey = true,
        supportedEvents = {"METRICS", "LOGS", "ALERTS"},
        configFields = {"api_key", "app_key", "site", "service"},
        testEndpoint = "/v1/validate"
    },
    GRAFANA = {
        name = "Grafana",
        type = "VISUALIZATION",
        apiKey = true,
        supportedEvents = {"METRICS", "ANNOTATIONS"},
        configFields = {"api_url", "api_key", "org_id"},
        testEndpoint = "/api/health"
    },
    PROMETHEUS = {
        name = "Prometheus",
        type = "MONITORING", 
        pushGateway = true,
        supportedEvents = {"METRICS"},
        configFields = {"push_gateway_url", "job_name", "instance"},
        testEndpoint = "/metrics"
    }
}

function APIManager.initialize()
    print("[API_MANAGER] [INFO] Initializing API integration system...")
    
    -- Initialize API endpoints
    APIManager.initializeEndpoints()
    
    -- Set up webhook system
    APIManager.initializeWebhooks()
    
    -- Initialize integrations
    APIManager.initializeIntegrations()
    
    -- Set up API security
    APIManager.initializeAPISecurity()
    
    -- Start API server (simulated)
    APIManager.startAPIServer()
    
    apiState.initialized = true
    print("[API_MANAGER] [INFO] API integration system initialized")
    
    return true
end

-- Initialize API endpoints
function APIManager.initializeEndpoints()
    apiState.endpoints = {
        -- Data endpoints
        {
            path = "/datastores",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetDataStores,
            description = "List all DataStores",
            permissions = {"READ_DATA"}
        },
        {
            path = "/datastores/{name}/keys",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetKeys,
            description = "List keys in a DataStore",
            permissions = {"READ_DATA"}
        },
        {
            path = "/datastores/{name}/keys/{key}",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetData,
            description = "Get data for a specific key",
            permissions = {"READ_DATA"}
        },
        {
            path = "/datastores/{name}/keys/{key}",
            method = HTTP_METHODS.PUT,
            handler = APIManager.handlePutData,
            description = "Set data for a specific key",
            permissions = {"WRITE_DATA"}
        },
        {
            path = "/datastores/{name}/keys/{key}",
            method = HTTP_METHODS.DELETE,
            handler = APIManager.handleDeleteData,
            description = "Delete a specific key",
            permissions = {"DELETE_DATA"}
        },
        
        -- Analytics endpoints
        {
            path = "/analytics/metrics",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetMetrics,
            description = "Get analytics metrics",
            permissions = {"VIEW_ANALYTICS"}
        },
        {
            path = "/analytics/reports",
            method = HTTP_METHODS.POST,
            handler = APIManager.handleGenerateReport,
            description = "Generate custom report",
            permissions = {"CREATE_REPORTS"}
        },
        
        -- Security endpoints
        {
            path = "/security/audit",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetAuditLog,
            description = "Get audit log entries",
            permissions = {"VIEW_AUDIT_LOG"}
        },
        {
            path = "/security/permissions",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetPermissions,
            description = "Get user permissions",
            permissions = {"MANAGE_SECURITY"}
        },
        
        -- Team collaboration endpoints
        {
            path = "/team/workspaces",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetWorkspaces,
            description = "List team workspaces",
            permissions = {"VIEW_WORKSPACES"}
        },
        {
            path = "/team/activity",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetActivity,
            description = "Get team activity feed",
            permissions = {"VIEW_TEAM_ACTIVITY"}
        },
        
        -- Integration management endpoints
        {
            path = "/integrations",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetIntegrations,
            description = "List configured integrations",
            permissions = {"MANAGE_INTEGRATIONS"}
        },
        {
            path = "/integrations",
            method = HTTP_METHODS.POST,
            handler = APIManager.handleCreateIntegration,
            description = "Create new integration",
            permissions = {"MANAGE_INTEGRATIONS"}
        },
        {
            path = "/webhooks",
            method = HTTP_METHODS.GET,
            handler = APIManager.handleGetWebhooks,
            description = "List configured webhooks",
            permissions = {"MANAGE_WEBHOOKS"}
        },
        {
            path = "/webhooks",
            method = HTTP_METHODS.POST,
            handler = APIManager.handleCreateWebhook,
            description = "Create new webhook",
            permissions = {"MANAGE_WEBHOOKS"}
        }
    }
    
    print("[API_MANAGER] [INFO] API endpoints initialized (" .. #apiState.endpoints .. " endpoints)")
end

-- Initialize webhook system
function APIManager.initializeWebhooks()
    apiState.webhooks = {}
    
    -- Example webhook configurations
    local defaultWebhooks = {
        {
            id = "alerts",
            name = "Security Alerts",
            url = "https://hooks.slack.com/services/example",
            events = {"SECURITY_VIOLATION", "ACCESS_DENIED", "CRITICAL_ERROR"},
            enabled = false,
            format = "slack",
            created = os.time()
        },
        {
            id = "data_changes",
            name = "Data Modifications",
            url = "https://discord.com/api/webhooks/example",
            events = {"DATA_MODIFY", "DATA_DELETE", "BULK_OPERATION"},
            enabled = false,
            format = "discord",
            created = os.time()
        }
    }
    
    for _, webhook in ipairs(defaultWebhooks) do
        apiState.webhooks[webhook.id] = webhook
    end
    
    print("[API_MANAGER] [INFO] Webhook system initialized")
end

-- Initialize integrations
function APIManager.initializeIntegrations()
    apiState.integrations = {}
    
    -- Create sample integration configurations (disabled by default)
    for platformId, platform in pairs(INTEGRATION_PLATFORMS) do
        apiState.integrations[platformId:lower()] = {
            id = platformId:lower(),
            platform = platformId,
            name = platform.name,
            type = platform.type,
            enabled = false,
            config = {},
            events = platform.supportedEvents,
            status = "NOT_CONFIGURED",
            created = os.time(),
            lastTest = 0,
            testResults = nil
        }
    end
    
    print("[API_MANAGER] [INFO] Integration platforms initialized")
end

-- Initialize API security
function APIManager.initializeAPISecurity()
    -- Generate master API key
    apiState.apiKeys = {
        master = {
            key = APIManager.generateAPIKey(),
            permissions = {"*"}, -- All permissions
            created = os.time(),
            lastUsed = 0,
            enabled = true,
            description = "Master API Key"
        }
    }
    
    apiState.rateLimits = {}
    apiState.requestLog = {}
    
    print("[API_MANAGER] [INFO] API security initialized")
end

-- Generate API key
function APIManager.generateAPIKey()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local key = "dsm_" -- DataStore Manager prefix
    
    for i = 1, API_CONFIG.SECURITY.API_KEY_LENGTH do
        local rand = math.random(1, #charset)
        key = key .. string.sub(charset, rand, rand)
    end
    
    return key
end

-- Start API server (simulated)
function APIManager.startAPIServer()
    -- In production, this would start an actual HTTP server
    -- For now, we simulate API availability
    apiState.server = {
        running = true,
        port = 8080,
        started = os.time(),
        requests_handled = 0
    }
    
    print("[API_MANAGER] [INFO] API server started (simulated)")
end

-- Handle API request (main router)
function APIManager.handleAPIRequest(method, path, headers, body, apiKey)
    -- Rate limiting
    if not APIManager.checkRateLimit(apiKey) then
        return APIManager.createErrorResponse(429, "Rate limit exceeded")
    end
    
    -- Authentication
    local authResult = APIManager.authenticateRequest(apiKey)
    if not authResult.success then
        return APIManager.createErrorResponse(401, authResult.error)
    end
    
    -- Find matching endpoint
    local endpoint = APIManager.findEndpoint(method, path)
    if not endpoint then
        return APIManager.createErrorResponse(404, "Endpoint not found")
    end
    
    -- Check permissions
    if not APIManager.checkEndpointPermissions(endpoint, authResult.permissions) then
        return APIManager.createErrorResponse(403, "Insufficient permissions")
    end
    
    -- Execute handler
    local success, response = pcall(endpoint.handler, path, headers, body)
    if not success then
        print("[API_MANAGER] [ERROR] Handler error: " .. tostring(response))
        return APIManager.createErrorResponse(500, "Internal server error")
    end
    
    -- Log request
    APIManager.logAPIRequest(method, path, apiKey, response.status)
    
    return response
end

-- Authenticate API request
function APIManager.authenticateRequest(apiKey)
    if not apiKey then
        return {success = false, error = "API key required"}
    end
    
    for keyId, keyData in pairs(apiState.apiKeys) do
        if keyData.key == apiKey and keyData.enabled then
            keyData.lastUsed = os.time()
            return {
                success = true,
                keyId = keyId,
                permissions = keyData.permissions
            }
        end
    end
    
    return {success = false, error = "Invalid API key"}
end

-- Check rate limits
function APIManager.checkRateLimit(apiKey)
    local now = os.time()
    local hour = math.floor(now / 3600)
    local limitKey = apiKey .. "_" .. hour
    
    local current = apiState.rateLimits[limitKey] or 0
    if current >= API_CONFIG.ENDPOINTS.RATE_LIMIT then
        return false
    end
    
    apiState.rateLimits[limitKey] = current + 1
    return true
end

-- Find matching endpoint
function APIManager.findEndpoint(method, path)
    for _, endpoint in ipairs(apiState.endpoints) do
        if endpoint.method == method and APIManager.matchPath(endpoint.path, path) then
            return endpoint
        end
    end
    return nil
end

-- Match path with parameters
function APIManager.matchPath(pattern, path)
    -- Simple pattern matching (in production, use proper router)
    local patternParts = Utils.String.split(pattern, "/")
    local pathParts = Utils.String.split(path, "/")
    
    if #patternParts ~= #pathParts then
        return false
    end
    
    for i, part in ipairs(patternParts) do
        if not (part:match("^{.+}$") or part == pathParts[i]) then
            return false
        end
    end
    
    return true
end

-- Check endpoint permissions
function APIManager.checkEndpointPermissions(endpoint, userPermissions)
    for _, requiredPerm in ipairs(endpoint.permissions or {}) do
        local hasPermission = false
        for _, userPerm in ipairs(userPermissions) do
            if userPerm == "*" or userPerm == requiredPerm then
                hasPermission = true
                break
            end
        end
        if not hasPermission then
            return false
        end
    end
    return true
end

-- Create error response
function APIManager.createErrorResponse(status, message)
    return {
        status = status,
        headers = {"Content-Type: application/json"},
        body = HttpService:JSONEncode({
            error = true,
            status = status,
            message = message,
            timestamp = os.time()
        })
    }
end

-- Create success response
function APIManager.createSuccessResponse(data, status)
    return {
        status = status or 200,
        headers = {"Content-Type: application/json"},
        body = HttpService:JSONEncode({
            error = false,
            data = data,
            timestamp = os.time()
        })
    }
end

-- Endpoint handlers
function APIManager.handleGetDataStores(path, headers, body)
    -- Mock DataStore list
    local datastores = {"PlayerData", "GameSettings", "Analytics", "Leaderboards"}
    return APIManager.createSuccessResponse(datastores)
end

function APIManager.handleGetMetrics(path, headers, body)
    -- Mock metrics data
    local metrics = {
        performance = {
            latency_avg = 45,
            error_rate = 0.02,
            throughput = 150
        },
        security = {
            failed_logins = 2,
            active_sessions = 15,
            encryption_coverage = 98
        },
        business = {
            active_users = 25,
            revenue_impact = 2500,
            roi = 165
        }
    }
    return APIManager.createSuccessResponse(metrics)
end

function APIManager.handleGetAuditLog(path, headers, body)
    -- Mock audit log
    local auditLog = {
        {
            id = "audit_001",
            timestamp = os.time() - 300,
            event = "DATA_ACCESS",
            user = "john_doe",
            description = "Accessed PlayerData store"
        },
        {
            id = "audit_002", 
            timestamp = os.time() - 150,
            event = "PERMISSION_CHANGE",
            user = "admin",
            description = "Updated user permissions"
        }
    }
    return APIManager.createSuccessResponse(auditLog)
end

-- Webhook management
function APIManager.createWebhook(config)
    local webhook = {
        id = Utils.createGUID(),
        name = config.name,
        url = config.url,
        events = config.events or {},
        enabled = config.enabled or false,
        format = config.format or "json",
        secret = config.secret,
        created = os.time(),
        lastTriggered = 0,
        deliveryCount = 0,
        failureCount = 0
    }
    
    apiState.webhooks[webhook.id] = webhook
    return webhook
end

-- Trigger webhook
function APIManager.triggerWebhook(eventType, eventData)
    local triggeredWebhooks = 0
    
    for _, webhook in pairs(apiState.webhooks) do
        if webhook.enabled and table.find(webhook.events, eventType) then
            APIManager.deliverWebhook(webhook, eventType, eventData)
            triggeredWebhooks = triggeredWebhooks + 1
        end
    end
    
    return triggeredWebhooks
end

-- Deliver webhook
function APIManager.deliverWebhook(webhook, eventType, eventData)
    local payload = {
        event = eventType,
        data = eventData,
        timestamp = os.time(),
        webhook_id = webhook.id
    }
    
    -- Format payload based on webhook format
    if webhook.format == "slack" then
        payload = APIManager.formatSlackPayload(eventType, eventData)
    elseif webhook.format == "discord" then
        payload = APIManager.formatDiscordPayload(eventType, eventData)
    end
    
    -- In production, this would make actual HTTP request
    print(string.format("[API_MANAGER] [WEBHOOK] Delivering %s to %s", eventType, webhook.url))
    
    webhook.lastTriggered = os.time()
    webhook.deliveryCount = webhook.deliveryCount + 1
end

-- Format Slack payload
function APIManager.formatSlackPayload(eventType, eventData)
    local color = "good"
    if eventType:find("ERROR") or eventType:find("VIOLATION") then
        color = "danger"
    elseif eventType:find("WARNING") or eventType:find("ALERT") then
        color = "warning"
    end
    
    return {
        attachments = {
            {
                color = color,
                title = eventType,
                text = eventData.description or "Event occurred",
                fields = {
                    {
                        title = "Timestamp",
                        value = os.date("%Y-%m-%d %H:%M:%S", os.time()),
                        short = true
                    },
                    {
                        title = "User",
                        value = eventData.user or "System",
                        short = true
                    }
                }
            }
        }
    }
end

-- Format Discord payload
function APIManager.formatDiscordPayload(eventType, eventData)
    local color = 65280 -- Green
    if eventType:find("ERROR") or eventType:find("VIOLATION") then
        color = 16711680 -- Red
    elseif eventType:find("WARNING") or eventType:find("ALERT") then
        color = 16776960 -- Yellow
    end
    
    return {
        embeds = {
            {
                title = eventType,
                description = eventData.description or "Event occurred",
                color = color,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                fields = {
                    {
                        name = "User",
                        value = eventData.user or "System",
                        inline = true
                    }
                }
            }
        }
    }
end

-- Integration management
function APIManager.configureIntegration(platformId, config)
    local integration = apiState.integrations[platformId]
    if not integration then
        return false, "Integration platform not found"
    end
    
    local platform = INTEGRATION_PLATFORMS[platformId:upper()]
    if not platform then
        return false, "Platform configuration not found"
    end
    
    -- Validate required fields
    for _, field in ipairs(platform.configFields) do
        if not config[field] then
            return false, "Missing required field: " .. field
        end
    end
    
    -- Update integration config (encrypt sensitive data)
    integration.config = APIManager.encryptIntegrationConfig(config)
    integration.enabled = true
    integration.status = "CONFIGURED"
    integration.lastModified = os.time()
    
    return true, "Integration configured successfully"
end

-- Encrypt integration config
function APIManager.encryptIntegrationConfig(config)
    local encrypted = {}
    
    for key, value in pairs(config) do
        if key:find("key") or key:find("secret") or key:find("token") then
            -- In production, use proper encryption
            encrypted[key] = "***ENCRYPTED***"
        else
            encrypted[key] = value
        end
    end
    
    return encrypted
end

-- Test integration
function APIManager.testIntegration(platformId)
    local integration = apiState.integrations[platformId]
    if not integration or not integration.enabled then
        return false, "Integration not configured or disabled"
    end
    
    -- Simulate test (in production, make actual API call)
    local success = math.random() > 0.1 -- 90% success rate
    
    integration.lastTest = os.time()
    integration.testResults = {
        success = success,
        timestamp = os.time(),
        latency = math.random(50, 200),
        response = success and "Connection successful" or "Connection failed"
    }
    
    integration.status = success and "ACTIVE" or "ERROR"
    
    return success, integration.testResults.response
end

-- Log API request
function APIManager.logAPIRequest(method, path, apiKey, status)
    local logEntry = {
        timestamp = os.time(),
        method = method,
        path = path,
        apiKey = apiKey and (apiKey:sub(1, 10) .. "...") or "none", -- Masked
        status = status,
        ip = "127.0.0.1" -- Placeholder
    }
    
    table.insert(apiState.requestLog, logEntry)
    
    -- Maintain log size
    if #apiState.requestLog > 1000 then
        table.remove(apiState.requestLog, 1)
    end
    
    -- Update server stats
    if apiState.server then
        apiState.server.requests_handled = apiState.server.requests_handled + 1
    end
end

-- Get API statistics
function APIManager.getAPIStatistics()
    local stats = {
        server = apiState.server,
        endpoints = #apiState.endpoints,
        webhooks = Utils.Table.count(apiState.webhooks),
        integrations = Utils.Table.count(apiState.integrations),
        apiKeys = Utils.Table.count(apiState.apiKeys),
        recentRequests = #apiState.requestLog
    }
    
    -- Calculate success rate
    local successCount = 0
    for _, request in ipairs(apiState.requestLog) do
        if request.status < 400 then
            successCount = successCount + 1
        end
    end
    
    stats.successRate = #apiState.requestLog > 0 and (successCount / #apiState.requestLog) or 0
    
    return stats
end

-- Get configured integrations
function APIManager.getIntegrations()
    local result = {}
    
    for id, integration in pairs(apiState.integrations) do
        table.insert(result, {
            id = id,
            platform = integration.platform,
            name = integration.name,
            type = integration.type,
            enabled = integration.enabled,
            status = integration.status,
            lastTest = integration.lastTest,
            supportedEvents = integration.events
        })
    end
    
    return result
end

-- Get API documentation
function APIManager.getAPIDocumentation()
    local docs = {
        version = "1.0",
        baseUrl = API_CONFIG.ENDPOINTS.BASE_URL,
        authentication = "API Key required in X-API-Key header",
        rateLimit = API_CONFIG.ENDPOINTS.RATE_LIMIT .. " requests per hour",
        endpoints = {}
    }
    
    for _, endpoint in ipairs(apiState.endpoints) do
        table.insert(docs.endpoints, {
            method = endpoint.method,
            path = endpoint.path,
            description = endpoint.description,
            permissions = endpoint.permissions
        })
    end
    
    return docs
end

-- Cleanup function
function APIManager.cleanup()
    apiState.initialized = false
    
    if apiState.server then
        apiState.server.running = false
    end
    
    print("[API_MANAGER] [INFO] API integration system cleanup completed")
end

return APIManager 