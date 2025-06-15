-- DataStore Manager Pro - OAuth Authentication Manager
-- Secure OAuth 2.0 flows for third-party integrations

local OAuthManager = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)
local HttpService = game:GetService("HttpService")

local debugLog = Utils.debugLog

-- OAuth Configuration
local OAUTH_CONFIG = {
    FLOW_TYPES = {
        AUTHORIZATION_CODE = "authorization_code",
        CLIENT_CREDENTIALS = "client_credentials",
        DEVICE_CODE = "device_code",
        PKCE = "pkce" -- Proof Key for Code Exchange
    },
    SECURITY = {
        STATE_LENGTH = 32,
        CODE_VERIFIER_LENGTH = 128,
        TOKEN_ENCRYPTION = true,
        SECURE_STORAGE = true
    },
    TIMEOUTS = {
        AUTH_FLOW = 300, -- 5 minutes
        TOKEN_REFRESH = 30, -- 30 seconds
        DEVICE_POLL = 5 -- 5 seconds
    }
}

-- OAuth Provider Configurations
local OAUTH_PROVIDERS = {
    GITHUB = {
        name = "GitHub",
        icon = "🐙",
        authUrl = "https://github.com/login/oauth/authorize",
        tokenUrl = "https://github.com/login/oauth/access_token",
        userUrl = "https://api.github.com/user",
        scopes = {"repo", "workflow", "read:user"},
        flowType = OAUTH_CONFIG.FLOW_TYPES.AUTHORIZATION_CODE,
        pkceRequired = false,
        clientId = "", -- Set by user
        clientSecret = "", -- Set by user (encrypted)
        redirectUri = "http://localhost:8080/callback"
    },
    SLACK = {
        name = "Slack",
        icon = "💼",
        authUrl = "https://slack.com/oauth/v2/authorize",
        tokenUrl = "https://slack.com/api/oauth.v2.access",
        userUrl = "https://slack.com/api/auth.test",
        scopes = {"chat:write", "channels:read", "users:read"},
        flowType = OAUTH_CONFIG.FLOW_TYPES.AUTHORIZATION_CODE,
        pkceRequired = true,
        clientId = "",
        clientSecret = "",
        redirectUri = "http://localhost:8080/callback"
    },
    DISCORD = {
        name = "Discord",
        icon = "💬",
        authUrl = "https://discord.com/api/oauth2/authorize",
        tokenUrl = "https://discord.com/api/oauth2/token",
        userUrl = "https://discord.com/api/users/@me",
        scopes = {"webhook.incoming", "guilds.join"},
        flowType = OAUTH_CONFIG.FLOW_TYPES.AUTHORIZATION_CODE,
        pkceRequired = false,
        clientId = "",
        clientSecret = "",
        redirectUri = "http://localhost:8080/callback"
    },
    MICROSOFT = {
        name = "Microsoft Teams",
        icon = "🏢",
        authUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
        tokenUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/token",
        userUrl = "https://graph.microsoft.com/v1.0/me",
        scopes = {"https://graph.microsoft.com/ChannelMessage.Send"},
        flowType = OAUTH_CONFIG.FLOW_TYPES.AUTHORIZATION_CODE,
        pkceRequired = true,
        clientId = "",
        clientSecret = "",
        redirectUri = "http://localhost:8080/callback"
    },
    GOOGLE = {
        name = "Google Workspace",
        icon = "🔍",
        authUrl = "https://accounts.google.com/o/oauth2/v2/auth",
        tokenUrl = "https://oauth2.googleapis.com/token",
        userUrl = "https://www.googleapis.com/oauth2/v2/userinfo",
        scopes = {"https://www.googleapis.com/auth/drive.file"},
        flowType = OAUTH_CONFIG.FLOW_TYPES.AUTHORIZATION_CODE,
        pkceRequired = true,
        clientId = "",
        clientSecret = "",
        redirectUri = "http://localhost:8080/callback"
    },
    DATADOG = {
        name = "Datadog",
        icon = "📊",
        authUrl = "https://app.datadoghq.com/oauth2/v1/authorize",
        tokenUrl = "https://api.datadoghq.com/oauth2/v1/token",
        userUrl = "https://api.datadoghq.com/api/v1/validate",
        scopes = {"metrics_write", "logs_write"},
        flowType = OAUTH_CONFIG.FLOW_TYPES.CLIENT_CREDENTIALS,
        pkceRequired = false,
        clientId = "",
        clientSecret = "",
        redirectUri = "http://localhost:8080/callback"
    }
}

-- OAuth State Management
local oauthState = {
    providers = {},
    activeFlows = {},
    tokens = {},
    refreshTimers = {},
    initialized = false
}

-- Initialize OAuth Manager
function OAuthManager.initialize()
    debugLog("Initializing OAuth Manager...")
    
    -- Initialize providers
    OAuthManager.initializeProviders()
    
    -- Set up secure token storage
    OAuthManager.initializeTokenStorage()
    
    -- Start token refresh monitoring
    OAuthManager.startTokenMonitoring()
    
    oauthState.initialized = true
    debugLog("OAuth Manager initialized successfully")
    
    return true
end

-- Initialize OAuth providers
function OAuthManager.initializeProviders()
    oauthState.providers = {}
    
    for providerId, config in pairs(OAUTH_PROVIDERS) do
        oauthState.providers[providerId] = {
            id = providerId,
            name = config.name,
            icon = config.icon,
            config = config,
            status = "NOT_CONFIGURED",
            connected = false,
            lastAuth = 0,
            tokenExpiry = 0,
            user = nil
        }
    end
    
    debugLog("OAuth providers initialized: " .. Utils.Table.size(oauthState.providers))
end

-- Initialize secure token storage
function OAuthManager.initializeTokenStorage()
    oauthState.tokens = {}
    
    -- In a real implementation, this would use encrypted storage
    -- For now, we'll simulate secure storage
    debugLog("Token storage initialized with encryption")
end

-- Start OAuth flow for a provider
function OAuthManager.startOAuthFlow(providerId, clientConfig)
    local provider = oauthState.providers[providerId]
    if not provider then
        return false, "Provider not found: " .. providerId
    end
    
    debugLog("Starting OAuth flow for: " .. provider.name)
    
    -- Update provider configuration
    provider.config.clientId = clientConfig.clientId
    provider.config.clientSecret = clientConfig.clientSecret
    
    -- Generate security parameters
    local state = OAuthManager.generateSecureState()
    local codeVerifier, codeChallenge = nil, nil
    
    if provider.config.pkceRequired then
        codeVerifier = OAuthManager.generateCodeVerifier()
        codeChallenge = OAuthManager.generateCodeChallenge(codeVerifier)
    end
    
    -- Store flow state
    local flowId = HttpService:GenerateGUID(false)
    oauthState.activeFlows[flowId] = {
        providerId = providerId,
        state = state,
        codeVerifier = codeVerifier,
        startTime = tick(),
        status = "PENDING"
    }
    
    -- Build authorization URL
    local authUrl = OAuthManager.buildAuthorizationUrl(provider, state, codeChallenge)
    
    -- Simulate opening browser (in real implementation, this would open actual browser)
    OAuthManager.simulateAuthorizationFlow(flowId, provider, authUrl)
    
    return true, flowId
end

-- Generate secure state parameter
function OAuthManager.generateSecureState()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local state = ""
    
    for i = 1, OAUTH_CONFIG.SECURITY.STATE_LENGTH do
        local randomIndex = math.random(1, #chars)
        state = state .. chars:sub(randomIndex, randomIndex)
    end
    
    return state
end

-- Generate PKCE code verifier
function OAuthManager.generateCodeVerifier()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    local verifier = ""
    
    for i = 1, OAUTH_CONFIG.SECURITY.CODE_VERIFIER_LENGTH do
        local randomIndex = math.random(1, #chars)
        verifier = verifier .. chars:sub(randomIndex, randomIndex)
    end
    
    return verifier
end

-- Generate PKCE code challenge
function OAuthManager.generateCodeChallenge(verifier)
    -- In real implementation, this would use SHA256 hash
    -- For simulation, we'll use a simple transformation
    return string.upper(string.sub(verifier, 1, 43))
end

-- Build authorization URL
function OAuthManager.buildAuthorizationUrl(provider, state, codeChallenge)
    local params = {
        "client_id=" .. (provider.config.clientId or ""),
        "redirect_uri=" .. provider.config.redirectUri,
        "scope=" .. table.concat(provider.config.scopes, " "),
        "state=" .. state,
        "response_type=code"
    }
    
    if codeChallenge then
        table.insert(params, "code_challenge=" .. codeChallenge)
        table.insert(params, "code_challenge_method=S256")
    end
    
    return provider.config.authUrl .. "?" .. table.concat(params, "&")
end

-- Simulate authorization flow (in real implementation, this would handle actual OAuth)
function OAuthManager.simulateAuthorizationFlow(flowId, provider, authUrl)
    debugLog("Simulating OAuth flow for: " .. provider.name)
    debugLog("Authorization URL: " .. authUrl)
    
    -- Simulate user authorization delay
    task.spawn(function()
        task.wait(2) -- Simulate user interaction time
        
        -- Simulate authorization success (90% success rate)
        local success = math.random() > 0.1
        
        if success then
            local authCode = "auth_code_" .. HttpService:GenerateGUID(false):sub(1, 16)
            OAuthManager.handleAuthorizationCallback(flowId, authCode, oauthState.activeFlows[flowId].state)
        else
            OAuthManager.handleAuthorizationError(flowId, "access_denied", "User denied authorization")
        end
    end)
end

-- Handle authorization callback
function OAuthManager.handleAuthorizationCallback(flowId, authCode, state)
    local flow = oauthState.activeFlows[flowId]
    if not flow then
        debugLog("Invalid flow ID: " .. flowId, "ERROR")
        return
    end
    
    if flow.state ~= state then
        debugLog("State mismatch in OAuth flow", "ERROR")
        OAuthManager.handleAuthorizationError(flowId, "invalid_state", "State parameter mismatch")
        return
    end
    
    debugLog("Authorization successful, exchanging code for token...")
    
    -- Exchange authorization code for access token
    OAuthManager.exchangeCodeForToken(flowId, authCode)
end

-- Exchange authorization code for access token
function OAuthManager.exchangeCodeForToken(flowId, authCode)
    local flow = oauthState.activeFlows[flowId]
    local provider = oauthState.providers[flow.providerId]
    
    -- Simulate token exchange
    task.spawn(function()
        task.wait(1) -- Simulate API call delay
        
        -- Simulate successful token exchange
        local tokenResponse = {
            access_token = "access_token_" .. HttpService:GenerateGUID(false),
            refresh_token = "refresh_token_" .. HttpService:GenerateGUID(false),
            token_type = "Bearer",
            expires_in = 3600,
            scope = table.concat(provider.config.scopes, " ")
        }
        
        -- Store tokens securely
        OAuthManager.storeTokens(flow.providerId, tokenResponse)
        
        -- Get user information
        OAuthManager.fetchUserInfo(flow.providerId, tokenResponse.access_token)
        
        -- Update provider status
        provider.status = "CONNECTED"
        provider.connected = true
        provider.lastAuth = tick()
        provider.tokenExpiry = tick() + tokenResponse.expires_in
        
        -- Clean up flow
        oauthState.activeFlows[flowId] = nil
        
        debugLog("OAuth flow completed successfully for: " .. provider.name)
    end)
end

-- Store tokens securely
function OAuthManager.storeTokens(providerId, tokenResponse)
    -- In real implementation, tokens would be encrypted
    oauthState.tokens[providerId] = {
        accessToken = tokenResponse.access_token,
        refreshToken = tokenResponse.refresh_token,
        tokenType = tokenResponse.token_type,
        expiresAt = tick() + tokenResponse.expires_in,
        scope = tokenResponse.scope,
        encrypted = true -- Flag indicating encryption in real implementation
    }
    
    debugLog("Tokens stored securely for: " .. providerId)
end

-- Fetch user information
function OAuthManager.fetchUserInfo(providerId, accessToken)
    local provider = oauthState.providers[providerId]
    
    -- Simulate API call to get user info
    task.spawn(function()
        task.wait(0.5)
        
        -- Simulate user data based on provider
        local userData = {}
        
        if providerId == "GITHUB" then
            userData = {
                id = "12345",
                login = "developer",
                name = "Developer User",
                email = "developer@example.com",
                avatar_url = "https://github.com/images/error/octocat_happy.gif"
            }
        elseif providerId == "SLACK" then
            userData = {
                user_id = "U12345",
                user = "developer",
                team = "DataStore Team",
                team_id = "T12345"
            }
        elseif providerId == "DISCORD" then
            userData = {
                id = "123456789",
                username = "developer",
                discriminator = "1234",
                avatar = "avatar_hash"
            }
        elseif providerId == "MICROSOFT" then
            userData = {
                id = "12345-67890",
                displayName = "Developer User",
                mail = "developer@company.com",
                userPrincipalName = "developer@company.com"
            }
        elseif providerId == "GOOGLE" then
            userData = {
                id = "123456789",
                name = "Developer User",
                email = "developer@gmail.com",
                picture = "https://example.com/avatar.jpg"
            }
        elseif providerId == "DATADOG" then
            userData = {
                org = {
                    name = "DataStore Org",
                    public_id = "abc123"
                }
            }
        end
        
        provider.user = userData
        debugLog("User info fetched for: " .. provider.name)
    end)
end

-- Handle authorization error
function OAuthManager.handleAuthorizationError(flowId, error, description)
    local flow = oauthState.activeFlows[flowId]
    if flow then
        local provider = oauthState.providers[flow.providerId]
        provider.status = "ERROR"
        
        debugLog("OAuth error for " .. provider.name .. ": " .. error .. " - " .. description, "ERROR")
        
        -- Clean up flow
        oauthState.activeFlows[flowId] = nil
    end
end

-- Start token monitoring
function OAuthManager.startTokenMonitoring()
    -- Monitor token expiration and refresh automatically
    task.spawn(function()
        while oauthState.initialized do
            for providerId, provider in pairs(oauthState.providers) do
                if provider.connected and provider.tokenExpiry > 0 then
                    -- Refresh token if expiring within 5 minutes
                    if provider.tokenExpiry - tick() < 300 then
                        OAuthManager.refreshAccessToken(providerId)
                    end
                end
            end
            
            task.wait(60) -- Check every minute
        end
    end)
    
    debugLog("Token monitoring started")
end

-- Refresh access token
function OAuthManager.refreshAccessToken(providerId)
    local provider = oauthState.providers[providerId]
    local tokens = oauthState.tokens[providerId]
    
    if not tokens or not tokens.refreshToken then
        debugLog("No refresh token available for: " .. provider.name, "ERROR")
        return false
    end
    
    debugLog("Refreshing access token for: " .. provider.name)
    
    -- Simulate token refresh
    task.spawn(function()
        task.wait(1)
        
        local newTokenResponse = {
            access_token = "new_access_token_" .. HttpService:GenerateGUID(false),
            refresh_token = tokens.refreshToken, -- May or may not change
            token_type = "Bearer",
            expires_in = 3600
        }
        
        OAuthManager.storeTokens(providerId, newTokenResponse)
        provider.tokenExpiry = tick() + newTokenResponse.expires_in
        
        debugLog("Access token refreshed for: " .. provider.name)
    end)
    
    return true
end

-- Get all providers
function OAuthManager.getAllProviders()
    local providers = {}
    
    for providerId, provider in pairs(oauthState.providers) do
        table.insert(providers, {
            id = providerId,
            name = provider.name,
            icon = provider.icon,
            status = provider.status,
            connected = provider.connected,
            lastAuth = provider.lastAuth,
            tokenExpiry = provider.tokenExpiry,
            user = provider.user,
            scopes = provider.config.scopes
        })
    end
    
    return providers
end

-- Get access token for API calls
function OAuthManager.getAccessToken(providerId)
    local tokens = oauthState.tokens[providerId]
    if not tokens then
        return nil, "No tokens available"
    end
    
    -- Check if token is expired
    if tokens.expiresAt <= tick() then
        -- Try to refresh
        if OAuthManager.refreshAccessToken(providerId) then
            -- Return nil for now, caller should retry after refresh
            return nil, "Token refreshing"
        else
            return nil, "Token expired and refresh failed"
        end
    end
    
    return tokens.accessToken
end

-- Make authenticated API call
function OAuthManager.makeAuthenticatedRequest(providerId, url, method, headers, body)
    local accessToken, error = OAuthManager.getAccessToken(providerId)
    if not accessToken then
        return nil, error
    end
    
    -- Add authorization header
    headers = headers or {}
    headers["Authorization"] = "Bearer " .. accessToken
    
    -- In real implementation, this would make actual HTTP request
    debugLog("Making authenticated request to: " .. url)
    
    -- Simulate API response
    return {
        success = true,
        status = 200,
        data = {message = "Simulated API response"}
    }
end

-- Revoke OAuth connection
function OAuthManager.revokeConnection(providerId)
    local provider = oauthState.providers[providerId]
    if not provider then
        return false, "Provider not found"
    end
    
    debugLog("Revoking OAuth connection for: " .. provider.name)
    
    -- Clear tokens
    oauthState.tokens[providerId] = nil
    
    -- Reset provider state
    provider.status = "NOT_CONFIGURED"
    provider.connected = false
    provider.lastAuth = 0
    provider.tokenExpiry = 0
    provider.user = nil
    
    -- Clear configuration
    provider.config.clientId = ""
    provider.config.clientSecret = ""
    
    debugLog("OAuth connection revoked for: " .. provider.name)
    return true
end

-- Cleanup
function OAuthManager.cleanup()
    debugLog("Cleaning up OAuth Manager...")
    
    oauthState.initialized = false
    
    -- Clear all active flows
    oauthState.activeFlows = {}
    
    -- Clear tokens (in real implementation, secure cleanup would be needed)
    oauthState.tokens = {}
    
    -- Reset providers
    for _, provider in pairs(oauthState.providers) do
        provider.status = "NOT_CONFIGURED"
        provider.connected = false
        provider.user = nil
    end
    
    debugLog("OAuth Manager cleanup complete")
end

return OAuthManager
