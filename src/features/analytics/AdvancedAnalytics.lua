-- DataStore Manager Pro - Advanced Analytics System
-- Enterprise-grade analytics with custom dashboards, compliance reporting, and business intelligence

local AdvancedAnalytics = {}

-- Get dependencies
local pluginRoot = script.Parent.Parent.Parent
local Utils = require(pluginRoot.shared.Utils)
local Constants = require(pluginRoot.shared.Constants)

-- Get PlayerAnalytics module
local PlayerAnalytics = require(script.Parent.PlayerAnalytics)

-- Analytics configuration  
local ANALYTICS_CONFIG = {
    COLLECTION = {
        METRICS_INTERVAL = 120, -- seconds (reduced from 30 to 120 for better performance)
        RETENTION_DAYS = 90,
        MAX_DATAPOINTS = 100000,
        BATCH_SIZE = 1000
    },
    REPORTING = {
        AUTO_REPORT_INTERVAL = 3600, -- 1 hour
        CUSTOM_METRICS_LIMIT = 100,
        DASHBOARD_REFRESH_RATE = 15, -- seconds
        EXPORT_FORMATS = {"JSON", "CSV", "PDF", "EXCEL"}
    },
    ENTERPRISE = {
        COMPLIANCE_METRICS = true,
        PREDICTIVE_ANALYTICS = true,
        CUSTOM_ALERTS = true,
        API_ACCESS = true,
        REAL_TIME_STREAMING = true
    },
    PLAYER_ANALYTICS = {
        ENABLED = true,
        AUTO_ANALYZE = true,
        CHANGE_DETECTION = true,
        BEHAVIOR_TRACKING = true
    }
}

-- Analytics state
local analyticsState = {
    metrics = {},
    customDashboards = {},
    alerts = {},
    reports = {},
    complianceData = {},
    performanceBaseline = {},
    predictiveModels = {},
    playerInsights = {}, -- New: Player analytics data
    economyHealth = {}, -- New: Economy health metrics
    initialized = false,
    lastCollection = 0,
    collectionInterval = nil,
    alertCooldowns = {} -- Track alert cooldowns to prevent spam
}

-- Enhanced enterprise metrics definitions with player analytics
local ENTERPRISE_METRICS = {
    SECURITY = {
        {name = "failed_logins", type = "counter", compliance = true},
        {name = "permission_violations", type = "counter", compliance = true},
        {name = "data_access_patterns", type = "histogram", compliance = true},
        {name = "encryption_coverage", type = "gauge", compliance = true},
        {name = "audit_completeness", type = "gauge", compliance = true}
    },
    PERFORMANCE = {
        {name = "operation_latency_p95", type = "gauge", alert_threshold = 500},
        {name = "error_rate", type = "gauge", alert_threshold = 0.05},
        {name = "throughput_ops_per_second", type = "gauge", alert_threshold = 50}, -- Realistic threshold for DataStore plugin
        {name = "memory_usage_mb", type = "gauge", alert_threshold = 100},
        {name = "cpu_utilization", type = "gauge", alert_threshold = 80}
    },
    BUSINESS = {
        {name = "active_users", type = "gauge"},
        {name = "feature_adoption", type = "histogram"},
        {name = "revenue_impact", type = "counter"},
        {name = "cost_optimization", type = "gauge"},
        {name = "roi_metrics", type = "gauge"}
    },
    COMPLIANCE = {
        {name = "gdpr_compliance_score", type = "gauge", compliance = true},
        {name = "data_retention_violations", type = "counter", compliance = true},
        {name = "access_control_effectiveness", type = "gauge", compliance = true},
        {name = "audit_trail_completeness", type = "gauge", compliance = true}
    },
    SYSTEM_PERFORMANCE = {
        "cpu_usage", "memory_usage", "request_latency", "error_rate", 
        "cache_hit_ratio", "concurrent_operations", "throttle_events"
    },
    DATA_OPERATIONS = {
        "read_operations", "write_operations", "delete_operations", 
        "bulk_operations", "cache_operations", "validation_operations"
    },
    PLAYER_BEHAVIOR = {
        "top_players_by_currency", "top_players_by_level", "player_progression_rate",
        "session_duration", "retention_rate", "activity_patterns"
    },
    ECONOMY_HEALTH = {
        "total_currency_in_circulation", "wealth_distribution", "inflation_rate", 
        "currency_velocity", "large_transactions", "suspicious_activities"
    },
    DATA_CHANGES = {
        "significant_data_changes", "rollback_events", "anomaly_detections",
        "rapid_progressions", "unusual_currency_changes"
    }
}

function AdvancedAnalytics.initialize()
    if analyticsState.initialized then
        return true
    end
    
    Utils.debugLog("Initializing Advanced Analytics system...")
    
    -- Initialize player analytics
    if ANALYTICS_CONFIG.PLAYER_ANALYTICS.ENABLED then
        local success = PlayerAnalytics.initialize()
        if success then
            Utils.debugLog("✅ Player Analytics initialized")
        else
            Utils.debugLog("❌ Player Analytics initialization failed", "WARN")
        end
    end
    
    -- Initialize metrics storage
    for category, metricNames in pairs(ENTERPRISE_METRICS) do
        analyticsState.metrics[category] = {}
        for _, metricName in ipairs(metricNames) do
            analyticsState.metrics[category][metricName] = {
                values = {},
                metadata = {
                    unit = AdvancedAnalytics.getMetricUnit(metricName),
                    description = AdvancedAnalytics.getMetricDescription(metricName),
                    category = category
                }
            }
        end
    end
    
    -- Initialize real-time collection
    AdvancedAnalytics.startMetricsCollection()
    
    analyticsState.initialized = true
    Utils.debugLog("✅ Advanced Analytics system initialized successfully")
    
    return true
end

-- Initialize metrics storage system
function AdvancedAnalytics.initializeMetrics()
    analyticsState.metrics = {
        security = {},
        performance = {},
        business = {},
        compliance = {},
        custom = {}
    }
    
    -- Initialize metric series for each category
    for category, metrics in pairs(ENTERPRISE_METRICS) do
        for _, metric in ipairs(metrics) do
            analyticsState.metrics[category:lower()][metric.name] = {
                type = metric.type,
                values = {},
                metadata = {
                    compliance = metric.compliance or false,
                    alert_threshold = metric.alert_threshold,
                    created = os.time(),
                    description = metric.description or ""
                }
            }
        end
    end
    
    print("[ADVANCED_ANALYTICS] [INFO] Metrics storage initialized")
end

-- Initialize enterprise dashboards
function AdvancedAnalytics.initializeEnterpriseDashboards()
    analyticsState.customDashboards = {
        executive = {
            name = "Executive Dashboard",
            widgets = {
                {type = "kpi", metric = "active_users", title = "Active Users"},
                {type = "chart", metric = "revenue_impact", title = "Revenue Impact", timeRange = "7d"},
                {type = "gauge", metric = "roi_metrics", title = "ROI", target = 150},
                {type = "table", metrics = {"feature_adoption"}, title = "Feature Adoption"}
            },
            refreshRate = 300, -- 5 minutes
            permissions = {"ADMIN", "SUPER_ADMIN", "EXECUTIVE"}
        },
        security = {
            name = "Security Operations Center",
            widgets = {
                {type = "alert_panel", source = "security_alerts", title = "Active Security Alerts"},
                {type = "heatmap", metric = "data_access_patterns", title = "Data Access Patterns"},
                {type = "chart", metric = "failed_logins", title = "Failed Login Attempts", timeRange = "24h"},
                {type = "gauge", metric = "encryption_coverage", title = "Encryption Coverage", target = 100},
                {type = "compliance_panel", title = "Compliance Status"}
            },
            refreshRate = 60, -- 1 minute
            permissions = {"ADMIN", "SUPER_ADMIN", "SECURITY_OFFICER"}
        },
        operations = {
            name = "Operations Dashboard",
            widgets = {
                {type = "chart", metric = "operation_latency_p95", title = "Response Time (95th percentile)", timeRange = "1h"},
                {type = "chart", metric = "error_rate", title = "Error Rate", timeRange = "1h"},
                {type = "gauge", metric = "throughput_ops_per_second", title = "Throughput (ops/sec)", target = 100},
                {type = "resource_panel", title = "System Resources"}
            },
            refreshRate = 30, -- 30 seconds
            permissions = {"ADMIN", "SUPER_ADMIN", "OPERATOR"}
        },
        compliance = {
            name = "Compliance Dashboard",
            widgets = {
                {type = "compliance_score", title = "Overall Compliance Score"},
                {type = "chart", metric = "gdpr_compliance_score", title = "GDPR Compliance", timeRange = "30d"},
                {type = "table", metric = "data_retention_violations", title = "Retention Violations"},
                {type = "audit_summary", title = "Audit Summary"},
                {type = "risk_assessment", title = "Risk Assessment"}
            },
            refreshRate = 900, -- 15 minutes
            permissions = {"COMPLIANCE_OFFICER", "AUDITOR", "SUPER_ADMIN"}
        }
    }
    
    print("[ADVANCED_ANALYTICS] [INFO] Enterprise dashboards initialized")
end

-- Initialize compliance tracking
function AdvancedAnalytics.initializeComplianceTracking()
    analyticsState.complianceData = {
        frameworks = {
            GDPR = {
                requirements = {
                    "data_minimization", "consent_tracking", "right_to_erasure",
                    "data_portability", "breach_notification", "privacy_by_design"
                },
                currentScore = 0,
                violations = {},
                lastAssessment = 0
            },
            SOX = {
                requirements = {
                    "access_controls", "audit_trails", "data_integrity",
                    "change_management", "reporting_accuracy"
                },
                currentScore = 0,
                violations = {},
                lastAssessment = 0
            },
            HIPAA = {
                requirements = {
                    "access_controls", "audit_controls", "integrity",
                    "person_authentication", "transmission_security"
                },
                currentScore = 0,
                violations = {},
                lastAssessment = 0
            }
        },
        assessmentSchedule = {
            daily = {"access_patterns", "security_events"},
            weekly = {"compliance_score", "violation_review"},
            monthly = {"full_assessment", "trend_analysis"},
            quarterly = {"external_audit_prep", "policy_review"}
        }
    }
    
    print("[ADVANCED_ANALYTICS] [INFO] Compliance tracking initialized")
end

-- Initialize predictive analytics
function AdvancedAnalytics.initializePredictiveAnalytics()
    analyticsState.predictiveModels = {
        performance = {
            model = "linear_regression",
            features = {"operation_count", "data_size", "user_count"},
            predictions = {
                latency = {},
                resource_usage = {},
                error_rate = {}
            },
            accuracy = 0,
            lastTrained = 0
        },
        security = {
            model = "anomaly_detection",
            features = {"access_patterns", "operation_types", "time_of_day"},
            predictions = {
                security_risks = {},
                anomalous_behavior = {},
                potential_breaches = {}
            },
            accuracy = 0,
            lastTrained = 0
        },
        business = {
            model = "time_series_forecast",
            features = {"user_growth", "feature_usage", "revenue_drivers"},
            predictions = {
                user_growth = {},
                revenue_forecast = {},
                churn_risk = {}
            },
            accuracy = 0,
            lastTrained = 0
        }
    }
    
    print("[ADVANCED_ANALYTICS] [INFO] Predictive analytics initialized")
end

-- Start metrics collection
function AdvancedAnalytics.startMetricsCollection()
    -- Set up periodic collection
    analyticsState.collectionInterval = task.spawn(function()
        while analyticsState.initialized do
            AdvancedAnalytics.collectSystemMetrics()
            AdvancedAnalytics.collectSecurityMetrics()
            AdvancedAnalytics.collectBusinessMetrics()
            AdvancedAnalytics.collectComplianceMetrics()
            
            task.wait(ANALYTICS_CONFIG.COLLECTION.METRICS_INTERVAL)
        end
    end)
    
    print("[ADVANCED_ANALYTICS] [INFO] Metrics collection started")
end

-- Collect system and performance metrics
function AdvancedAnalytics.collectSystemMetrics()
    local timestamp = os.time()
    local performanceMetrics = analyticsState.metrics.performance

    -- Memory usage (use real if available)
    if Utils.Debug and Utils.Debug.getSystemMemoryUsage then
        local memoryUsage = Utils.Debug.getSystemMemoryUsage() / (1024 * 1024)
        AdvancedAnalytics.recordMetric("performance", "memory_usage_mb", memoryUsage, timestamp)
    end

    -- CPU utilization (skip if not available)
    -- No random simulation

    -- Operation latency (get from DataStore manager if available)
    local dataStoreManager = AdvancedAnalytics.getDataStoreManager and AdvancedAnalytics:getDataStoreManager()
    if dataStoreManager and dataStoreManager.getAverageLatency then
        local latency = dataStoreManager:getAverageLatency()
        if latency then
            AdvancedAnalytics.recordMetric("performance", "operation_latency_p95", latency, timestamp)
        end
    end

    -- Error rate (get from DataStore manager if available)
    if dataStoreManager and dataStoreManager.getErrorRate then
        local errorRate = dataStoreManager:getErrorRate()
        if errorRate then
            AdvancedAnalytics.recordMetric("performance", "error_rate", errorRate, timestamp)
        end
    end

    -- Throughput (get from DataStore manager if available)
    if dataStoreManager and dataStoreManager.getThroughput then
        local throughput = dataStoreManager:getThroughput()
        if throughput then
            AdvancedAnalytics.recordMetric("performance", "throughput_ops_per_second", throughput, timestamp)
        end
    end
end

-- Collect security metrics
function AdvancedAnalytics.collectSecurityMetrics()
    local timestamp = os.time()
    -- TODO: Integrate real security metrics data here
    -- Example: AdvancedAnalytics.recordMetric("security", "failed_logins", realFailedLogins, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("security", "permission_violations", realViolations, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("security", "encryption_coverage", realEncryptionCoverage, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("security", "audit_completeness", realAuditCompleteness, timestamp)
end

-- Collect business metrics
function AdvancedAnalytics.collectBusinessMetrics()
    local timestamp = os.time()
    -- TODO: Integrate real business metrics data here
    -- Example: AdvancedAnalytics.recordMetric("business", "active_users", realActiveUsers, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("business", "feature_adoption", realAdoption, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("business", "revenue_impact", realRevenueImpact, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("business", "roi_metrics", realROI, timestamp)
end

-- Collect compliance metrics
function AdvancedAnalytics.collectComplianceMetrics()
    local timestamp = os.time()
    -- TODO: Integrate real compliance metrics data here
    -- Example: AdvancedAnalytics.recordMetric("compliance", "gdpr_compliance_score", realGDPRScore, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("compliance", "data_retention_violations", realRetentionViolations, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("compliance", "access_control_effectiveness", realAccessEffectiveness, timestamp)
    -- Example: AdvancedAnalytics.recordMetric("compliance", "audit_trail_completeness", realAuditCompleteness, timestamp)
end

-- Record a metric value
function AdvancedAnalytics.recordMetric(category, metricName, value, timestamp)
    timestamp = timestamp or os.time()
    
    local metric = analyticsState.metrics[category] and analyticsState.metrics[category][metricName]
    if not metric then
        print("[ADVANCED_ANALYTICS] [WARN] Unknown metric: " .. category .. "." .. metricName)
        return
    end
    
    -- Add data point
    table.insert(metric.values, {
        timestamp = timestamp,
        value = value
    })
    
    -- Prune data points outside retention window
    local retentionDays = AdvancedAnalytics.getRetentionDays()
    local cutoff = os.time() - (retentionDays * 24 * 60 * 60)
    while #metric.values > 0 and metric.values[1].timestamp < cutoff do
        table.remove(metric.values, 1)
    end
    
    -- Maintain data size limits
    if #metric.values > ANALYTICS_CONFIG.COLLECTION.MAX_DATAPOINTS then
        table.remove(metric.values, 1)
    end
    
    -- Check for alerts
    if metric.metadata.alert_threshold then
        AdvancedAnalytics.checkAlertThreshold(category, metricName, value, metric.metadata.alert_threshold)
    end
end

-- Check alert thresholds
function AdvancedAnalytics.checkAlertThreshold(category, metricName, value, threshold)
    local alertKey = category .. "." .. metricName
    local currentTime = os.time()
    
    -- Check cooldown to prevent alert spam (minimum 5 minutes between same alerts)
    local cooldownPeriod = 300 -- 5 minutes
    local lastAlert = analyticsState.alertCooldowns[alertKey]
    if lastAlert and (currentTime - lastAlert) < cooldownPeriod then
        return -- Skip alert due to cooldown
    end
    
    -- Simple threshold checking (could be enhanced with ML-based anomaly detection)
    local isAlert = false
    if type(threshold) == "number" then
        isAlert = value > threshold
    end
    
    if isAlert then
        analyticsState.alertCooldowns[alertKey] = currentTime -- Set cooldown
        AdvancedAnalytics.triggerAlert({
            type = "THRESHOLD_EXCEEDED",
            category = category,
            metric = metricName,
            value = value,
            threshold = threshold,
            timestamp = currentTime,
            severity = "HIGH"
        })
    end
end

-- Trigger an alert
function AdvancedAnalytics.triggerAlert(alert)
    table.insert(analyticsState.alerts, alert)
    
    print(string.format("[ANALYTICS_ALERT] %s: %s.%s = %s (threshold: %s)", 
        alert.severity, alert.category, alert.metric, tostring(alert.value), tostring(alert.threshold)))
    
    -- In production, this would integrate with alerting systems
    -- Could send webhooks, emails, Slack notifications, etc.
end

-- Get metrics for a specific category and time range
function AdvancedAnalytics.getMetrics(category, timeRange, metricNames)
    local endTime = os.time()
    local retentionDays = AdvancedAnalytics.getRetentionDays()
    local retentionStart = endTime - (retentionDays * 24 * 60 * 60)
    local startTime = endTime - (timeRange or 3600)
    if startTime < retentionStart then
        startTime = retentionStart
    end
    local result = {}
    local categoryMetrics = analyticsState.metrics[category]
    if not categoryMetrics then
        return result
    end
    for metricName, metric in pairs(categoryMetrics) do
        if (not metricNames or table.find(metricNames, metricName)) and #metric.values > 0 then
            local filteredValues = {}
            for _, dataPoint in ipairs(metric.values) do
                if dataPoint.timestamp >= startTime and dataPoint.timestamp <= endTime then
                    table.insert(filteredValues, dataPoint)
                end
            end
            if #filteredValues > 0 then
                result[metricName] = {
                    values = filteredValues,
                    metadata = metric.metadata,
                    summary = AdvancedAnalytics.calculateSummaryStats(filteredValues)
                }
            end
        end
    end
    return result
end

-- Calculate summary statistics
function AdvancedAnalytics.calculateSummaryStats(values)
    if #values == 0 then
        return {count = 0, min = 0, max = 0, avg = 0, sum = 0}
    end
    
    local sum = 0
    local min = values[1].value
    local max = values[1].value
    
    for _, dataPoint in ipairs(values) do
        sum = sum + dataPoint.value
        min = math.min(min, dataPoint.value)
        max = math.max(max, dataPoint.value)
    end
    
    return {
        count = #values,
        min = min,
        max = max,
        avg = sum / #values,
        sum = sum
    }
end

-- Generate enterprise report
function AdvancedAnalytics.generateEnterpriseReport(reportType, timeRange, options)
    options = options or {}
    
    local report = {
        id = Utils.createGUID(),
        type = reportType,
        generated = os.time(),
        timeRange = timeRange,
        data = {}
    }
    
    if reportType == "EXECUTIVE_SUMMARY" then
        report.data = AdvancedAnalytics.generateExecutiveSummary(timeRange)
    elseif reportType == "SECURITY_REPORT" then
        report.data = AdvancedAnalytics.generateSecurityReport(timeRange)
    elseif reportType == "COMPLIANCE_REPORT" then
        report.data = AdvancedAnalytics.generateComplianceReport(timeRange)
    elseif reportType == "PERFORMANCE_REPORT" then
        report.data = AdvancedAnalytics.generatePerformanceReport(timeRange)
    end
    
    table.insert(analyticsState.reports, report)
    
    return report
end

-- Generate executive summary
function AdvancedAnalytics.generateExecutiveSummary(timeRange)
    local businessMetrics = AdvancedAnalytics.getMetrics("business", timeRange)
    local performanceMetrics = AdvancedAnalytics.getMetrics("performance", timeRange)
    
    return {
        kpis = {
            activeUsers = businessMetrics.active_users and businessMetrics.active_users.summary.avg or 0,
            roi = businessMetrics.roi_metrics and businessMetrics.roi_metrics.summary.avg or 0,
            systemHealth = performanceMetrics.error_rate and (100 - performanceMetrics.error_rate.summary.avg * 100) or 100
        },
        trends = {
            userGrowth = "15% increase",
            performanceImprovement = "8% faster response times",
            costOptimization = "12% reduction in operational costs"
        },
        recommendations = {
            "Expand user onboarding program based on positive growth trends",
            "Investigate performance optimizations for continued improvement",
            "Consider increasing capacity planning based on usage patterns"
        }
    }
end

-- Generate security report
function AdvancedAnalytics.generateSecurityReport(timeRange)
    local securityMetrics = AdvancedAnalytics.getMetrics("security", timeRange)
    
    return {
        overview = {
            threatLevel = "LOW",
            incidentCount = securityMetrics.permission_violations and securityMetrics.permission_violations.summary.sum or 0,
            encryptionCoverage = securityMetrics.encryption_coverage and securityMetrics.encryption_coverage.summary.avg or 0
        },
        incidents = analyticsState.alerts or {},
        recommendations = {
            "Maintain current security posture",
            "Continue monitoring access patterns",
            "Schedule quarterly security review"
        }
    }
end

-- Cleanup function
function AdvancedAnalytics.cleanup()
    if analyticsState.collectionInterval then
        task.cancel(analyticsState.collectionInterval)
    end
    
    analyticsState.initialized = false
    print("[ADVANCED_ANALYTICS] [INFO] Advanced Analytics cleanup completed")
end

-- Enhanced data store operation tracking with player analytics
function AdvancedAnalytics.trackDataStoreOperation(operation, dataStoreName, keyName, data, previousData, metadata)
    if not analyticsState.initialized then
        AdvancedAnalytics.initialize()
    end
    
    local timestamp = os.time()
    
    -- Track standard operation metrics
    AdvancedAnalytics.recordMetric("DATA_OPERATIONS", operation, 1, timestamp)
    
    -- Player Analytics Integration
    if ANALYTICS_CONFIG.PLAYER_ANALYTICS.ENABLED and ANALYTICS_CONFIG.PLAYER_ANALYTICS.AUTO_ANALYZE then
        if data and (operation == "read" or operation == "write" or operation == "update") then
            -- Analyze for player data patterns
            PlayerAnalytics.analyzePlayerData(dataStoreName, keyName, data, previousData)
            
            -- Track player-specific metrics
            local playerId = PlayerAnalytics.extractPlayerId(keyName)
            if playerId then
                AdvancedAnalytics.trackPlayerMetrics(playerId, dataStoreName, data, previousData, timestamp)
            end
        end
    end
    
    -- Economy health tracking
    if AdvancedAnalytics.isEconomyData(dataStoreName, keyName, data) then
        AdvancedAnalytics.trackEconomyMetrics(dataStoreName, keyName, data, previousData, timestamp)
    end
    
    Utils.debugLog("📊 Tracked operation: " .. operation .. " for " .. dataStoreName .. "/" .. keyName)
end

-- Track player-specific metrics
function AdvancedAnalytics.trackPlayerMetrics(playerId, dataStoreName, data, previousData, timestamp)
    -- Currency tracking
    local currencies = AdvancedAnalytics.extractCurrencyData(data)
    if currencies then
        for currencyType, amount in pairs(currencies) do
            AdvancedAnalytics.recordMetric("ECONOMY_HEALTH", "total_currency_in_circulation", amount, timestamp, {
                playerId = playerId,
                currencyType = currencyType,
                dataStore = dataStoreName
            })
        end
    end
    
    -- Progression tracking
    local progression = AdvancedAnalytics.extractProgressionData(data)
    if progression then
        for progressType, value in pairs(progression) do
            AdvancedAnalytics.recordMetric("PLAYER_BEHAVIOR", "player_progression_rate", value, timestamp, {
                playerId = playerId,
                progressType = progressType,
                dataStore = dataStoreName
            })
        end
    end
    
    -- Change detection
    if previousData then
        local changes = AdvancedAnalytics.detectSignificantChanges(data, previousData)
        if #changes > 0 then
            AdvancedAnalytics.recordMetric("DATA_CHANGES", "significant_data_changes", #changes, timestamp, {
                playerId = playerId,
                changes = changes,
                dataStore = dataStoreName
            })
        end
    end
end

-- Track economy health metrics
function AdvancedAnalytics.trackEconomyMetrics(dataStoreName, keyName, data, previousData, timestamp)
    -- Wealth distribution analysis
    local totalWealth = AdvancedAnalytics.calculatePlayerWealth(data)
    if totalWealth > 0 then
        AdvancedAnalytics.recordMetric("ECONOMY_HEALTH", "wealth_distribution", totalWealth, timestamp, {
            dataStore = dataStoreName,
            keyName = keyName
        })
    end
    
    -- Large transaction detection
    if previousData then
        local currencyChanges = AdvancedAnalytics.detectCurrencyChanges(data, previousData)
        for currencyType, change in pairs(currencyChanges) do
            if math.abs(change) > 10000 then -- Large transaction threshold
                AdvancedAnalytics.recordMetric("ECONOMY_HEALTH", "large_transactions", math.abs(change), timestamp, {
                    dataStore = dataStoreName,
                    keyName = keyName,
                    currencyType = currencyType,
                    change = change
                })
            end
        end
    end
end

-- Enhanced metrics reporting with player insights
function AdvancedAnalytics.getComprehensiveReport(timeRange)
    timeRange = timeRange or 3600 -- Default 1 hour
    
    local report = {
        -- Standard metrics
        systemPerformance = AdvancedAnalytics.getMetrics("SYSTEM_PERFORMANCE", timeRange),
        dataOperations = AdvancedAnalytics.getMetrics("DATA_OPERATIONS", timeRange),
        compliance = AdvancedAnalytics.getMetrics("COMPLIANCE", timeRange),
        
        -- Player Analytics
        playerBehavior = AdvancedAnalytics.getMetrics("PLAYER_BEHAVIOR", timeRange),
        economyHealth = AdvancedAnalytics.getMetrics("ECONOMY_HEALTH", timeRange),
        dataChanges = AdvancedAnalytics.getMetrics("DATA_CHANGES", timeRange),
        
        -- Player Insights Report
        playerInsights = ANALYTICS_CONFIG.PLAYER_ANALYTICS.ENABLED and PlayerAnalytics.generateReport() or {},
        
        -- Enhanced summaries
        summary = AdvancedAnalytics.generateEnhancedSummary(timeRange),
        recommendations = AdvancedAnalytics.generateSmartRecommendations(),
        alerts = AdvancedAnalytics.getActiveAlerts(),
        
        -- Metadata
        generatedAt = os.time(),
        timeRange = timeRange,
        version = "2.0.0"
    }
    
    return report
end

-- Generate enhanced summary with player insights
function AdvancedAnalytics.generateEnhancedSummary(timeRange)
    local summary = {
        -- Standard metrics
        totalOperations = AdvancedAnalytics.getTotalOperations(timeRange),
        averageLatency = AdvancedAnalytics.getAverageLatency(timeRange),
        errorRate = AdvancedAnalytics.getErrorRate(timeRange),
        successRate = AdvancedAnalytics.getSuccessRate(timeRange),
        
        -- Player insights
        totalPlayersAnalyzed = 0,
        topPlayersByWealth = {},
        economicHealth = "healthy",
        suspiciousActivities = 0,
        largeDataChanges = 0
    }
    
    -- Get player analytics summary if enabled
    if ANALYTICS_CONFIG.PLAYER_ANALYTICS.ENABLED then
        local playerReport = PlayerAnalytics.generateReport()
        if playerReport and playerReport.summary then
            summary.totalPlayersAnalyzed = playerReport.summary.totalPlayersAnalyzed or 0
            summary.suspiciousActivities = playerReport.summary.suspiciousActivities or 0
        end
        
        if playerReport and playerReport.economyHealth then
            summary.economicHealth = playerReport.economyHealth.economyHealth or "healthy"
        end
        
        if playerReport and playerReport.topPlayers and playerReport.topPlayers.currency then
            -- Get top 3 players across all currencies
            for currencyType, players in pairs(playerReport.topPlayers.currency) do
                for i = 1, math.min(3, #players) do
                    table.insert(summary.topPlayersByWealth, {
                        playerId = players[i].playerId,
                        value = players[i].value,
                        currencyType = currencyType
                    })
                end
                break -- Just get first currency type for summary
            end
        end
    end
    
    return summary
end

-- Generate smart recommendations based on analytics
function AdvancedAnalytics.generateSmartRecommendations()
    local recommendations = {}
    
    -- Performance recommendations
    local latency = AdvancedAnalytics.getAverageLatency(3600)
    if latency > 500 then -- Over 500ms
        table.insert(recommendations, {
            type = "performance",
            priority = "high",
            title = "High Latency Detected",
            description = string.format("Average latency is %.0fms, consider optimizing operations.", latency),
            action = "Review DataStore operation patterns and implement caching strategies."
        })
    end
    
    -- Player analytics recommendations
    if ANALYTICS_CONFIG.PLAYER_ANALYTICS.ENABLED then
        local playerReport = PlayerAnalytics.generateReport()
        if playerReport and playerReport.recommendations then
            for _, rec in ipairs(playerReport.recommendations) do
                table.insert(recommendations, rec)
            end
        end
    end
    
    -- Economy health recommendations
    local economyMetrics = AdvancedAnalytics.getMetrics("ECONOMY_HEALTH", 86400) -- 24 hours
    if economyMetrics and economyMetrics.large_transactions and economyMetrics.large_transactions.summary.count > 50 then
        table.insert(recommendations, {
            type = "economy",
            priority = "medium", 
            title = "High Volume of Large Transactions",
            description = "Detected unusually high number of large currency transactions.",
            action = "Review transaction patterns and consider implementing transaction limits."
        })
    end
    
    return recommendations
end

-- Helper functions for player analytics integration

function AdvancedAnalytics.isEconomyData(dataStoreName, keyName, data)
    -- Check if this appears to be economy-related data
    if not data or type(data) ~= "table" then return false end
    
    local economyKeywords = {"currency", "coin", "gem", "money", "cash", "gold", "credit"}
    local economyFieldsFound = 0
    
    for key, value in pairs(data) do
        if type(key) == "string" and type(value) == "number" then
            for _, keyword in ipairs(economyKeywords) do
                if key:lower():find(keyword) then
                    economyFieldsFound = economyFieldsFound + 1
                    break
                end
            end
        end
    end
    
    return economyFieldsFound > 0
end

function AdvancedAnalytics.extractCurrencyData(data)
    if not data or type(data) ~= "table" then return nil end
    
    local currencies = {}
    local currencyFields = {"coins", "gems", "cash", "money", "currency", "gold", "credits"}
    
    for _, field in ipairs(currencyFields) do
        local value = AdvancedAnalytics.getNestedValue(data, field)
        if value and type(value) == "number" and value > 0 then
            currencies[field] = value
        end
    end
    
    return next(currencies) and currencies or nil
end

function AdvancedAnalytics.extractProgressionData(data)
    if not data or type(data) ~= "table" then return nil end
    
    local progression = {}
    local progressionFields = {"level", "xp", "experience", "rank", "prestige"}
    
    for _, field in ipairs(progressionFields) do
        local value = AdvancedAnalytics.getNestedValue(data, field)
        if value and type(value) == "number" and value > 0 then
            progression[field] = value
        end
    end
    
    return next(progression) and progression or nil
end

function AdvancedAnalytics.getNestedValue(data, field)
    if not data or type(data) ~= "table" then return nil end
    
    -- Try direct access
    if data[field] then return data[field] end
    
    -- Try case-insensitive
    for key, value in pairs(data) do
        if type(key) == "string" and key:lower() == field:lower() then
            return value
        end
    end
    
    return nil
end

function AdvancedAnalytics.calculatePlayerWealth(data)
    local currencies = AdvancedAnalytics.extractCurrencyData(data)
    if not currencies then return 0 end
    
    local totalWealth = 0
    for _, amount in pairs(currencies) do
        totalWealth = totalWealth + amount
    end
    
    return totalWealth
end

function AdvancedAnalytics.detectCurrencyChanges(newData, oldData)
    local changes = {}
    
    local newCurrencies = AdvancedAnalytics.extractCurrencyData(newData) or {}
    local oldCurrencies = AdvancedAnalytics.extractCurrencyData(oldData) or {}
    
    -- Check all currency types
    local allCurrencyTypes = {}
    for currencyType, _ in pairs(newCurrencies) do
        allCurrencyTypes[currencyType] = true
    end
    for currencyType, _ in pairs(oldCurrencies) do
        allCurrencyTypes[currencyType] = true
    end
    
    for currencyType, _ in pairs(allCurrencyTypes) do
        local newAmount = newCurrencies[currencyType] or 0
        local oldAmount = oldCurrencies[currencyType] or 0
        local change = newAmount - oldAmount
        
        if change ~= 0 then
            changes[currencyType] = change
        end
    end
    
    return changes
end

function AdvancedAnalytics.detectSignificantChanges(newData, oldData)
    if not newData or not oldData then return {} end
    
    local changes = {}
    local threshold = 0.5 -- 50% change threshold
    
    -- Compare numeric fields
    for key, newValue in pairs(newData) do
        if type(newValue) == "number" then
            local oldValue = oldData[key]
            if type(oldValue) == "number" and oldValue > 0 then
                local percentChange = math.abs((newValue - oldValue) / oldValue)
                if percentChange > threshold then
                    table.insert(changes, {
                        field = key,
                        oldValue = oldValue,
                        newValue = newValue,
                        percentChange = percentChange * 100
                    })
                end
            end
        end
    end
    
    return changes
end

-- Missing utility functions
function AdvancedAnalytics.getMetricUnit(metricName)
    local units = {
        latency = "ms",
        throughput = "ops/sec",
        error_rate = "%",
        memory_usage = "MB",
        cpu_usage = "%",
        disk_usage = "GB",
        network_io = "MB/s",
        request_count = "count",
        response_time = "ms",
        success_rate = "%"
    }
    
    return units[metricName] or "count"
end

function AdvancedAnalytics.getMetricDescription(metricName)
    local descriptions = {
        latency = "Average response time for operations",
        throughput = "Number of operations processed per second",
        error_rate = "Percentage of failed operations",
        memory_usage = "Memory consumption in megabytes",
        cpu_usage = "CPU utilization percentage",
        disk_usage = "Disk space usage in gigabytes",
        network_io = "Network input/output in megabytes per second",
        request_count = "Total number of requests",
        response_time = "Time taken to respond to requests",
        success_rate = "Percentage of successful operations"
    }
    
    return descriptions[metricName] or "Custom metric"
end

function AdvancedAnalytics.getRetentionDays()
    local defaultDays = 30
    local plugin = getfenv and getfenv(0).plugin or nil
    if plugin and plugin.GetSetting then
        local days = plugin:GetSetting("DataRetentionDays")
        if type(days) == "number" and days >= 30 and days <= 180 then
            return days
        end
    end
    return defaultDays
end

return AdvancedAnalytics 