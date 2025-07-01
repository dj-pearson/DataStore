-- DataStore Manager Pro - Player Analytics Module
-- Advanced player behavior analysis, data change detection, and game development insights

local PlayerAnalytics = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

local debugLog = Utils.debugLog

-- Player analytics configuration
local PLAYER_CONFIG = {
    ANALYSIS = {
        TOP_PLAYERS_COUNT = 50,
        CHANGE_THRESHOLD_PERCENTAGE = 50, -- Alert on 50%+ changes
        SUSPICIOUS_MULTIPLIER = 10, -- 10x normal change = suspicious
        MINIMUM_DATA_SIZE = 100, -- Minimum bytes to analyze
        ANOMALY_DETECTION_WINDOW = 24 -- Hours
    },
    TRACKING = {
        LEVEL_FIELDS = {"level", "xp", "experience", "rank", "prestige"},
        STATS_FIELDS = {"wins", "losses", "kills", "deaths", "score", "points"},
        TIME_FIELDS = {"lastLogin", "lastSeen", "playTime", "sessionTime", "joinTime"},
        GAME_DATA_FIELDS = {"level", "score", "progress", "achievements", "settings", "preferences"}
    },
    INSIGHTS = {
        RETENTION_PERIODS = {7, 30, 90}, -- Days
        PROGRESSION_MILESTONES = {1, 5, 10, 25, 50, 100},
        ECONOMY_HEALTH_INDICATORS = {"inflation", "distribution", "velocity", "retention"}
    }
}

-- Player analytics state
local playerState = {
    topPlayers = {
        byCurrency = {},
        byLevel = {},
        byActivity = {},
        byProgression = {}
    },
    dataChanges = {
        recent = {},
        suspicious = {},
        large = {},
        rollbacks = {}
    },
    behaviorInsights = {
        sessionPatterns = {},
        progressionRates = {},
        economyHealth = {},
        retentionMetrics = {}
    },
    playerProfiles = {}, -- Cache for analyzed players
    alerts = {},
    lastAnalysis = 0,
    initialized = false
}

-- Initialize Player Analytics
function PlayerAnalytics.initialize(dataStoreManager)
    if playerState.initialized then return true end
    
    debugLog("Initializing Player Analytics system...")
    
    -- Store DataStore manager reference for real data access
    playerState.dataStoreManager = dataStoreManager
    
    if dataStoreManager then
        debugLog("✅ Player Analytics connected to DataStore Manager for real data")
    else
        debugLog("⚠️ Player Analytics initialized without DataStore Manager - limited functionality", "WARN")
    end
    
    -- Initialize data structures
    playerState.topPlayers = {
        byCurrency = {},
        byLevel = {},
        byActivity = {},
        byProgression = {}
    }
    
    playerState.dataChanges = {
        recent = {},
        suspicious = {},
        large = {},
        rollbacks = {}
    }
    
    playerState.behaviorInsights = {
        sessionPatterns = {},
        progressionRates = {},
        economyHealth = {
            totalCurrency = 0,
            averageWealth = 0,
            wealthDistribution = {},
            inflationRate = 0
        },
        retentionMetrics = {}
    }
    
    playerState.alerts = {}
    playerState.playerProfiles = {}
    playerState.lastAnalysis = os.time()
    playerState.initialized = true
    
    debugLog("✅ Player Analytics system initialized successfully")
    return true
end

-- Analyze player data from a DataStore
function PlayerAnalytics.analyzePlayerData(dataStoreName, keyName, data, previousData)
    if not playerState.initialized then
        PlayerAnalytics.initialize()
    end
    
    if not data or type(data) ~= "table" then
        return
    end
    
    local currentTime = os.time()
    local playerId = PlayerAnalytics.extractPlayerId(keyName)
    
    if not playerId then
        return -- Not a player data key
    end
    
    -- Create or update player profile
    local profile = PlayerAnalytics.getOrCreatePlayerProfile(playerId, dataStoreName)
    profile.lastSeen = currentTime
    profile.dataStore = dataStoreName
    profile.keyName = keyName
    
    -- Analyze level/progression data
    local progressionAnalysis = PlayerAnalytics.analyzeProgression(data, previousData, profile)
    
    -- Analyze activity patterns
    local activityAnalysis = PlayerAnalytics.analyzeActivity(data, previousData, profile)
    
    -- Detect data changes and anomalies
    local changeAnalysis = PlayerAnalytics.analyzeDataChanges(data, previousData, profile)
    
    -- Update top players lists
    PlayerAnalytics.updateTopPlayers(playerId, profile, progressionAnalysis, activityAnalysis)
    
    -- Update behavior insights
    PlayerAnalytics.updateBehaviorInsights(progressionAnalysis, activityAnalysis)
    
    -- Generate alerts if needed
    PlayerAnalytics.generateAlerts(playerId, changeAnalysis, progressionAnalysis)
    
    debugLog("🔍 Analyzed player data for: " .. playerId .. " in " .. dataStoreName)
end

-- Extract player ID from key name
function PlayerAnalytics.extractPlayerId(keyName)
    -- Try common patterns: Player_123, player_123, 123456789, user_123, etc.
    local patterns = {
        "Player_(%d+)",
        "player_(%d+)", 
        "^(%d+)$",
        "user_(%d+)",
        "User_(%d+)",
        "p_(%d+)",
        "u_(%d+)"
    }
    
    for _, pattern in ipairs(patterns) do
        local id = keyName:match(pattern)
        if id then
            return id
        end
    end
    
    return nil
end

-- Get or create player profile
function PlayerAnalytics.getOrCreatePlayerProfile(playerId, dataStoreName)
    local profileKey = playerId .. "_" .. dataStoreName
    
    if not playerState.playerProfiles[profileKey] then
        playerState.playerProfiles[profileKey] = {
            playerId = playerId,
            dataStore = dataStoreName,
            firstSeen = os.time(),
            lastSeen = os.time(),
            currency = {},
            progression = {},
            activity = {},
            changeHistory = {},
            flags = {},
            totalSessions = 0,
            totalPlayTime = 0
        }
    end
    
    return playerState.playerProfiles[profileKey]
end

-- Analyze progression data
function PlayerAnalytics.analyzeProgression(data, previousData, profile)
    local analysis = {
        levels = {},
        experience = {},
        changes = {},
        flags = {}
    }
    
    for _, levelField in ipairs(PLAYER_CONFIG.TRACKING.LEVEL_FIELDS) do
        local currentValue = PlayerAnalytics.getNestedValue(data, levelField)
        local previousValue = previousData and PlayerAnalytics.getNestedValue(previousData, levelField)
        
        if currentValue and type(currentValue) == "number" then
            analysis.levels[levelField] = currentValue
            
            -- Track progression changes
            if previousValue and type(previousValue) == "number" then
                local change = currentValue - previousValue
                
                analysis.changes[levelField] = {
                    absolute = change,
                    previous = previousValue,
                    current = currentValue
                }
                
                -- Flag unusual progression
                if change > 10 then -- More than 10 levels at once
                    table.insert(analysis.flags, {
                        type = "rapid_progression",
                        field = levelField,
                        change = change,
                        severity = change > 50 and "critical" or "warning"
                    })
                end
            end
            
            -- Update profile
            profile.progression[levelField] = currentValue
        end
    end
    
    return analysis
end

-- Analyze activity patterns
function PlayerAnalytics.analyzeActivity(data, previousData, profile)
    local analysis = {
        sessionData = {},
        timePlayed = 0,
        lastActivity = 0,
        changes = {},
        flags = {}
    }
    
    for _, timeField in ipairs(PLAYER_CONFIG.TRACKING.TIME_FIELDS) do
        local currentValue = PlayerAnalytics.getNestedValue(data, timeField)
        
        if currentValue and type(currentValue) == "number" then
            analysis.sessionData[timeField] = currentValue
            
            if timeField:find("last") or timeField:find("Last") then
                analysis.lastActivity = math.max(analysis.lastActivity, currentValue)
            end
            
            if timeField:find("time") or timeField:find("Time") then
                analysis.timePlayed = analysis.timePlayed + currentValue
            end
            
            -- Update profile
            profile.activity[timeField] = currentValue
        end
    end
    
    return analysis
end

-- Analyze data changes and detect anomalies
function PlayerAnalytics.analyzeDataChanges(data, previousData, profile)
    local analysis = {
        totalChanges = 0,
        significantChanges = {},
        anomalies = {},
        flags = {}
    }
    
    if not previousData then
        return analysis
    end
    
    -- Deep compare data structures
    local changes = PlayerAnalytics.deepCompare(data, previousData)
    analysis.totalChanges = #changes
    
    for _, change in ipairs(changes) do
        -- Check if this is a significant change
        if PlayerAnalytics.isSignificantChange(change) then
            table.insert(analysis.significantChanges, change)
        end
        
        -- Check for anomalies
        if PlayerAnalytics.isAnomalousChange(change, profile) then
            table.insert(analysis.anomalies, change)
            table.insert(analysis.flags, {
                type = "data_anomaly",
                field = change.field,
                change = change,
                severity = "warning"
            })
        end
    end
    
    return analysis
end

-- Update top players lists
function PlayerAnalytics.updateTopPlayers(playerId, profile, progressionAnalysis, activityAnalysis)
    -- Update level leaderboards
    for levelField, level in pairs(progressionAnalysis.levels) do
        if not playerState.topPlayers.byLevel[levelField] then
            playerState.topPlayers.byLevel[levelField] = {}
        end
        
        PlayerAnalytics.updateLeaderboard(
            playerState.topPlayers.byLevel[levelField],
            playerId,
            level,
            PLAYER_CONFIG.ANALYSIS.TOP_PLAYERS_COUNT
        )
    end
    
    -- Update activity leaderboards
    if activityAnalysis.timePlayed > 0 then
        PlayerAnalytics.updateLeaderboard(
            playerState.topPlayers.byActivity,
            playerId,
            activityAnalysis.timePlayed,
            PLAYER_CONFIG.ANALYSIS.TOP_PLAYERS_COUNT
        )
    end
end

-- Update leaderboard
function PlayerAnalytics.updateLeaderboard(leaderboard, playerId, value, maxSize)
    -- Remove existing entry for this player
    for i = #leaderboard, 1, -1 do
        if leaderboard[i].playerId == playerId then
            table.remove(leaderboard, i)
            break
        end
    end
    
    -- Add new entry
    table.insert(leaderboard, {
        playerId = playerId,
        value = value,
        timestamp = os.time()
    })
    
    -- Sort by value (descending)
    table.sort(leaderboard, function(a, b) return a.value > b.value end)
    
    -- Trim to max size
    while #leaderboard > maxSize do
        table.remove(leaderboard)
    end
end

-- Generate comprehensive player analytics report
function PlayerAnalytics.generateReport()
    if not playerState.initialized then
        PlayerAnalytics.initialize()
    end
    
    local report = {
        summary = PlayerAnalytics.generateSummary(),
        topPlayers = PlayerAnalytics.generateTopPlayersReport(),
        dataChanges = PlayerAnalytics.generateDataChangesReport(),
        behaviorInsights = PlayerAnalytics.generateBehaviorInsightsReport(),
        alerts = PlayerAnalytics.generateAlertsReport(),
        economyHealth = PlayerAnalytics.generateEconomyHealthReport(),
        recommendations = PlayerAnalytics.generateRecommendations(),
        generatedAt = os.time()
    }
    
    return report
end

-- Generate summary statistics
function PlayerAnalytics.generateSummary()
    local totalPlayers = 0
    for _ in pairs(playerState.playerProfiles) do
        totalPlayers = totalPlayers + 1
    end
    
    local totalAlerts = #playerState.alerts
    local recentChanges = 0
    local currentTime = os.time()
    
    for _, change in ipairs(playerState.dataChanges.recent) do
        if currentTime - change.timestamp < 3600 then -- Last hour
            recentChanges = recentChanges + 1
        end
    end
    
    return {
        totalPlayersAnalyzed = totalPlayers,
        activeAlerts = totalAlerts,
        recentDataChanges = recentChanges,
        suspiciousActivities = #playerState.dataChanges.suspicious,
        lastAnalysisTime = playerState.lastAnalysis
    }
end

-- Generate top players report
function PlayerAnalytics.generateTopPlayersReport()
    return {
        levels = playerState.topPlayers.byLevel,
        activity = playerState.topPlayers.byActivity,
        progression = playerState.topPlayers.byProgression
    }
end

-- Generate data changes report
function PlayerAnalytics.generateDataChangesReport()
    return {
        recent = playerState.dataChanges.recent,
        suspicious = playerState.dataChanges.suspicious,
        large = playerState.dataChanges.large,
        rollbacks = playerState.dataChanges.rollbacks
    }
end

-- Generate behavior insights report
function PlayerAnalytics.generateBehaviorInsightsReport()
    return playerState.behaviorInsights
end

-- Generate alerts report
function PlayerAnalytics.generateAlertsReport()
    return playerState.alerts
end

-- Generate economy health report
function PlayerAnalytics.generateEconomyHealthReport()
    local economyHealth = playerState.behaviorInsights.economyHealth
    
    -- Calculate additional metrics
    local wealthGini = PlayerAnalytics.calculateWealthDistribution()
    local inflationRate = PlayerAnalytics.calculateInflationRate()
    
    return {
        totalCurrency = economyHealth.totalCurrency,
        averageWealth = economyHealth.averageWealth,
        wealthDistribution = economyHealth.wealthDistribution,
        giniCoefficient = wealthGini,
        inflationRate = inflationRate,
        economyHealth = PlayerAnalytics.assessEconomyHealth(wealthGini, inflationRate)
    }
end

-- Generate recommendations
function PlayerAnalytics.generateRecommendations()
    local recommendations = {}
    
    -- Check for economy issues
    local gini = PlayerAnalytics.calculateWealthDistribution()
    if gini > 0.8 then
        table.insert(recommendations, {
            type = "economy",
            priority = "high",
            title = "High Wealth Inequality Detected",
            description = "Consider implementing wealth redistribution mechanics or progressive taxation.",
            action = "Review currency distribution and implement balancing measures."
        })
    end
    
    -- Check for suspicious activity
    if #playerState.dataChanges.suspicious > 10 then
        table.insert(recommendations, {
            type = "security",
            priority = "critical",
            title = "Multiple Suspicious Activities Detected",
            description = "Unusual data changes detected across multiple players.",
            action = "Review security measures and investigate potential exploits."
        })
    end
    
    -- Check for retention issues
    local inactivePlayers = PlayerAnalytics.countInactivePlayers(7) -- 7 days
    if inactivePlayers > 0.3 then -- More than 30% inactive
        table.insert(recommendations, {
            type = "retention",
            priority = "medium",
            title = "High Player Inactivity",
            description = "Over 30% of players haven't been active in the last week.",
            action = "Consider implementing re-engagement campaigns or feature improvements."
        })
    end
    
    return recommendations
end

-- Helper functions
function PlayerAnalytics.getNestedValue(data, field)
    if not data or type(data) ~= "table" then return nil end
    
    -- Try direct access first
    if data[field] then return data[field] end
    
    -- Try case-insensitive search
    for key, value in pairs(data) do
        if type(key) == "string" and key:lower() == field:lower() then
            return value
        end
    end
    
    return nil
end

function PlayerAnalytics.deepCompare(data1, data2, path)
    path = path or ""
    local changes = {}
    
    if type(data1) ~= type(data2) then
        table.insert(changes, {
            field = path,
            type = "type_change",
            old = data2,
            new = data1
        })
        return changes
    end
    
    if type(data1) == "table" then
        -- Check all keys in data1
        for key, value in pairs(data1) do
            local newPath = path == "" and tostring(key) or (path .. "." .. tostring(key))
            local subChanges = PlayerAnalytics.deepCompare(value, data2[key], newPath)
            for _, change in ipairs(subChanges) do
                table.insert(changes, change)
            end
        end
        
        -- Check for removed keys
        for key, value in pairs(data2) do
            if data1[key] == nil then
                local newPath = path == "" and tostring(key) or (path .. "." .. tostring(key))
                table.insert(changes, {
                    field = newPath,
                    type = "removed",
                    old = value,
                    new = nil
                })
            end
        end
    else
        if data1 ~= data2 then
            table.insert(changes, {
                field = path,
                type = "value_change",
                old = data2,
                new = data1
            })
        end
    end
    
    return changes
end

function PlayerAnalytics.isSignificantChange(change)
    if change.type == "value_change" and type(change.old) == "number" and type(change.new) == "number" then
        local percentChange = change.old > 0 and math.abs((change.new - change.old) / change.old * 100) or 0
        return percentChange > PLAYER_CONFIG.ANALYSIS.CHANGE_THRESHOLD_PERCENTAGE
    end
    return change.type == "type_change" or change.type == "removed"
end

function PlayerAnalytics.isAnomalousChange(change, profile)
    if change.type == "value_change" and type(change.old) == "number" and type(change.new) == "number" then
        local absoluteChange = math.abs(change.new - change.old)
        
        -- Check against historical data for this player
        local history = profile.changeHistory[change.field] or {}
        if #history > 0 then
            local avgChange = 0
            for _, historicalChange in ipairs(history) do
                avgChange = avgChange + math.abs(historicalChange)
            end
            avgChange = avgChange / #history
            
            return absoluteChange > (avgChange * PLAYER_CONFIG.ANALYSIS.SUSPICIOUS_MULTIPLIER)
        end
    end
    return false
end

function PlayerAnalytics.calculateWealthDistribution()
    local wealthValues = {}
    
    for _, profile in pairs(playerState.playerProfiles) do
        local totalWealth = 0
        for _, amount in pairs(profile.currency) do
            totalWealth = totalWealth + amount
        end
        if totalWealth > 0 then
            table.insert(wealthValues, totalWealth)
        end
    end
    
    if #wealthValues < 2 then return 0 end
    
    table.sort(wealthValues)
    
    -- Calculate Gini coefficient (simplified)
    local sum = 0
    local sumOfRanks = 0
    for i, wealth in ipairs(wealthValues) do
        sum = sum + wealth
        sumOfRanks = sumOfRanks + (i * wealth)
    end
    
    local n = #wealthValues
    local mean = sum / n
    
    if mean == 0 then return 0 end
    
    local gini = (2 * sumOfRanks) / (n * sum) - (n + 1) / n
    return math.max(0, math.min(1, gini))
end

function PlayerAnalytics.calculateInflationRate()
    -- Simplified inflation calculation based on average wealth growth
    local currentTime = os.time()
    local dayAgo = currentTime - 86400
    
    local currentWealth = 0
    local pastWealth = 0
    local currentCount = 0
    local pastCount = 0
    
    for _, profile in pairs(playerState.playerProfiles) do
        local totalWealth = 0
        for _, amount in pairs(profile.currency) do
            totalWealth = totalWealth + amount
        end
        
        if profile.lastSeen >= dayAgo then
            currentWealth = currentWealth + totalWealth
            currentCount = currentCount + 1
        end
        
        -- This is simplified - in reality you'd need historical wealth data
        pastWealth = pastWealth + (totalWealth * 0.95) -- Assume 5% growth
        pastCount = pastCount + 1
    end
    
    if pastCount == 0 or pastWealth == 0 then return 0 end
    
    local currentAvg = currentCount > 0 and (currentWealth / currentCount) or 0
    local pastAvg = pastWealth / pastCount
    
    return pastAvg > 0 and ((currentAvg - pastAvg) / pastAvg * 100) or 0
end

function PlayerAnalytics.assessEconomyHealth(giniCoefficient, inflationRate)
    local health = "healthy"
    
    if giniCoefficient > 0.8 then
        health = "inequality_high"
    elseif inflationRate > 20 then
        health = "inflation_high"
    elseif inflationRate < -20 then
        health = "deflation_high"
    end
    
    return health
end

function PlayerAnalytics.countInactivePlayers(days)
    local cutoffTime = os.time() - (days * 86400)
    local totalPlayers = 0
    local inactivePlayers = 0
    
    for _, profile in pairs(playerState.playerProfiles) do
        totalPlayers = totalPlayers + 1
        if profile.lastSeen < cutoffTime then
            inactivePlayers = inactivePlayers + 1
        end
    end
    
    return totalPlayers > 0 and (inactivePlayers / totalPlayers) or 0
end

-- Update behavior insights
function PlayerAnalytics.updateBehaviorInsights(progressionAnalysis, activityAnalysis)
    local insights = playerState.behaviorInsights
    
    -- Update economy health
    insights.economyHealth.totalCurrency = insights.economyHealth.totalCurrency + progressionAnalysis.experience
    
    -- Update other insights (simplified)
    -- In a real implementation, you'd have more sophisticated analysis here
end

-- Generate alerts
function PlayerAnalytics.generateAlerts(playerId, changeAnalysis, progressionAnalysis)
    local currentTime = os.time()
    
    -- Progression alerts
    for _, flag in ipairs(progressionAnalysis.flags) do
        if flag.severity == "critical" then
            table.insert(playerState.alerts, {
                type = "progression_alert", 
                playerId = playerId,
                message = string.format("Player %s: %s of %d in %s", 
                    playerId, flag.type, flag.change, flag.field),
                severity = flag.severity,
                timestamp = currentTime,
                data = flag
            })
        end
    end
    
    -- Data anomaly alerts
    for _, flag in ipairs(changeAnalysis.flags) do
        table.insert(playerState.alerts, {
            type = "anomaly_alert",
            playerId = playerId,
            message = string.format("Player %s: Data anomaly detected in %s", 
                playerId, flag.field),
            severity = flag.severity,
            timestamp = currentTime,
            data = flag
        })
    end
    
    -- Cleanup old alerts (keep last 100)
    while #playerState.alerts > 100 do
        table.remove(playerState.alerts, 1)
    end
end

-- Scan real DataStores for player data analysis
function PlayerAnalytics.scanRealDataStores()
    local dataStoreManager = playerState.dataStoreManager
    if not dataStoreManager or not playerState.initialized then
        debugLog("❌ Cannot scan DataStores - no DataStore manager available", "WARN")
        return false
    end
    
    debugLog("🔍 Scanning real DataStores for player analytics...")
    
    local dataStoreNames = dataStoreManager:getDataStoreNames()
    if not dataStoreNames or #dataStoreNames == 0 then
        debugLog("No DataStores found to analyze")
        return false
    end
    
    local totalPlayersFound = 0
    local analysisResults = {
        dataStoresScanned = #dataStoreNames,
        playersAnalyzed = 0,
        levelsAnalyzed = 0,
        suspiciousActivities = 0
    }
    
    for _, dsName in ipairs(dataStoreNames) do
        debugLog("Analyzing DataStore: " .. dsName)
        
        -- Get keys from this DataStore
        local keys = dataStoreManager:getKeys(dsName, "global", 100) -- Limit for performance
        if keys and #keys > 0 then
            for _, key in ipairs(keys) do
                -- Check if this looks like player data
                local playerId = PlayerAnalytics.extractPlayerId(key)
                if playerId then
                    totalPlayersFound = totalPlayersFound + 1
                    analysisResults.playersAnalyzed = analysisResults.playersAnalyzed + 1
                    
                    -- Get the actual player data
                    local data = dataStoreManager:getData(dsName, key, "global")
                    if data and type(data) == "table" then
                        -- Analyze this player's data
                        PlayerAnalytics.analyzePlayerData(dsName, key, data)
                        
                        -- Count analyzed fields
                        for _, levelField in ipairs(PLAYER_CONFIG.TRACKING.LEVEL_FIELDS) do
                            if data[levelField] and type(data[levelField]) == "number" then
                                analysisResults.levelsAnalyzed = analysisResults.levelsAnalyzed + 1
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Count suspicious activities
    analysisResults.suspiciousActivities = #playerState.dataChanges.suspicious
    
    debugLog("✅ DataStore scan complete:")
    debugLog("  - DataStores scanned: " .. analysisResults.dataStoresScanned)
    debugLog("  - Players analyzed: " .. analysisResults.playersAnalyzed)
    debugLog("  - Level fields analyzed: " .. analysisResults.levelsAnalyzed)
    debugLog("  - Suspicious activities: " .. analysisResults.suspiciousActivities)
    
    return analysisResults
end

-- Get real-time player insights
function PlayerAnalytics.getRealTimeInsights()
    if not playerState.initialized then
        PlayerAnalytics.initialize()
    end
    
    -- Trigger a fresh scan of DataStores
    local scanResults = PlayerAnalytics.scanRealDataStores()
    
    return {
        scanResults = scanResults,
        topPlayers = playerState.topPlayers,
        economyHealth = playerState.behaviorInsights.economyHealth,
        recentChanges = playerState.dataChanges.recent,
        suspiciousActivities = playerState.dataChanges.suspicious,
        alerts = playerState.alerts,
        lastUpdated = os.time()
    }
end

-- Replace with safe game progress tracking
function PlayerAnalytics.analyzeGameProgress(data)
    local analysis = {
        progressMetrics = {},
        achievementData = {},
        settingsData = {}
    }
    
    -- Analyze safe game progression data only
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(value) == "number" and key:match("level") then
                analysis.progressMetrics.level = value
            elseif type(value) == "number" and key:match("score") then
                analysis.progressMetrics.score = value
            end
        end
    end
    
    return analysis
end

return PlayerAnalytics 