-- DataStore Manager Pro - Data Health Auditor
-- Scans all DataStores for orphaned keys, unused DataStores, and anomalies

local DataHealthAuditor = {}

-- Utility function to check for outliers (simple z-score or threshold)
local function isOutlier(value, mean, stddev, threshold)
    if not mean or not stddev or stddev == 0 then return false end
    return math.abs((value - mean) / stddev) > (threshold or 3)
end

-- Main audit function
function DataHealthAuditor.runAudit(services)
    local report = {
        summary = {
            totalDataStores = 0,
            totalKeys = 0,
            orphanedKeys = 0,
            unusedDataStores = 0,
            anomalies = 0,
            lastAudit = os.time(),
        },
        details = {
            orphanedKeys = {},
            unusedDataStores = {},
            anomalies = {},
        },
        suggestions = {}
    }

    local dataStoreManager = services and (services.DataStoreManager or services["core.data.DataStoreManager"])
    if not dataStoreManager or not dataStoreManager.getDataStoreNames or not dataStoreManager.getKeys then
        report.suggestions = {"DataStoreManager service not available or missing methods."}
        return report
    end

    local dataStores = dataStoreManager:getDataStoreNames() or {}
    report.summary.totalDataStores = #dataStores

    for _, dsName in ipairs(dataStores) do
        local keys = dataStoreManager:getKeys(dsName) or {}
        if #keys == 0 then
            table.insert(report.details.unusedDataStores, {dataStore = dsName, lastUsed = "Unknown"})
            report.summary.unusedDataStores = report.summary.unusedDataStores + 1
        end
        for _, key in ipairs(keys) do
            report.summary.totalKeys = report.summary.totalKeys + 1
            -- Orphaned key check (example: key with no matching user/entity)
            if tostring(key):match("orphaned") then
                table.insert(report.details.orphanedKeys, {dataStore = dsName, key = key, reason = "No matching entity"})
                report.summary.orphanedKeys = report.summary.orphanedKeys + 1
            end
            -- Anomaly check (example: negative values, outliers)
            local data = dataStoreManager.getDataInfo and dataStoreManager:getDataInfo(dsName, key) or nil
            if data and type(data) == "table" then
                for field, value in pairs(data) do
                    if type(value) == "number" and value < 0 then
                        table.insert(report.details.anomalies, {dataStore = dsName, key = key, type = "NegativeValue", field = field, value = value})
                        report.summary.anomalies = report.summary.anomalies + 1
                    end
                    -- Outlier detection (placeholder: flag values > 1e6)
                    if type(value) == "number" and math.abs(value) > 1e6 then
                        table.insert(report.details.anomalies, {dataStore = dsName, key = key, type = "Outlier", field = field, value = value})
                        report.summary.anomalies = report.summary.anomalies + 1
                    end
                end
            end
        end
    end

    -- Suggestions
    if report.summary.orphanedKeys > 0 then
        table.insert(report.suggestions, "Delete " .. report.summary.orphanedKeys .. " orphaned keys")
    end
    if report.summary.unusedDataStores > 0 then
        table.insert(report.suggestions, "Archive " .. report.summary.unusedDataStores .. " unused DataStores")
    end
    if report.summary.anomalies > 0 then
        table.insert(report.suggestions, "Review " .. report.summary.anomalies .. " anomalies")
    end
    if #report.suggestions == 0 then
        table.insert(report.suggestions, "No issues detected. Data health is good!")
    end

    return report
end

return DataHealthAuditor 