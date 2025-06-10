-- DataStore Manager Pro - Type Definitions
-- Centralized type definitions for better code organization

local Types = {}

-- Plugin Types
export type PluginInfo = {
    name: string,
    version: string,
    id: string,
    author: string,
    description: string?
}

export type ServiceDefinition = {
    initialize: (() -> boolean)?,
    cleanup: (() -> ())?,
    [string]: any
}

-- DataStore Types
export type DataStoreInfo = {
    name: string,
    scope: string?,
    keyCount: number?,
    totalSize: number?,
    lastAccessed: number?
}

export type DataStoreKey = {
    name: string,
    value: any,
    metadata: {[string]: any}?,
    userIds: {number}?,
    version: string?,
    createdTime: number?,
    updatedTime: number?
}

export type DataStoreOperation = {
    type: "READ" | "WRITE" | "DELETE" | "LIST",
    store: string,
    key: string?,
    timestamp: number,
    attempts: number,
    success: boolean?,
    result: any?,
    error: string?,
    latency: number?,
    dataSize: number?
}

export type DataStoreCache = {
    [string]: {
        store: DataStore,
        created: number,
        lastAccessed: number
    }
}

-- Performance Types
export type PerformanceMetrics = {
    totalOperations: number,
    successRate: number,
    averageLatency: number,
    operationTypes: {[string]: number},
    recentErrors: {DataStoreOperation},
    memoryUsage: number,
    loadTime: number
}

export type BenchmarkResult = {
    name: string,
    iterations: number,
    totalTime: number,
    averageTime: number,
    memoryDelta: number
}

-- UI Types
export type ThemeColors = {
    primary: Color3,
    success: Color3,
    warning: Color3,
    error: Color3,
    background: Color3,
    surface: Color3,
    text: Color3,
    textSecondary: Color3,
    border: Color3,
    accent: Color3
}

export type ComponentStyle = {
    size: UDim2?,
    position: UDim2?,
    color: Color3?,
    textColor: Color3?,
    borderColor: Color3?,
    font: Enum.Font?,
    textSize: number?
}

export type UIComponent = {
    element: GuiObject,
    update: ((any) -> ())?,
    destroy: (() -> ())?,
    setVisible: ((boolean) -> ())?,
    setEnabled: ((boolean) -> ())?
}

export type TreeNode = {
    name: string,
    children: {TreeNode}?,
    data: any?,
    expanded: boolean?,
    level: number,
    parent: TreeNode?
}

-- Error Types
export type ErrorInfo = {
    code: string,
    message: string,
    context: {[string]: any},
    timestamp: number,
    stack: string
}

export type ValidationResult = {
    isValid: boolean,
    errors: {string}?,
    warnings: {string}?
}

-- License Types
export type LicenseInfo = {
    tier: number,
    isValid: boolean,
    expiresAt: number?,
    features: {string},
    userId: number?,
    userName: string?
}

export type FeatureDefinition = {
    tier: number,
    enabled: boolean,
    description: string?
}

-- Schema Types
export type SchemaField = {
    name: string,
    type: "string" | "number" | "boolean" | "table" | "array" | "any",
    required: boolean?,
    default: any?,
    validation: ((any) -> ValidationResult)?,
    description: string?
}

export type Schema = {
    name: string,
    version: string,
    fields: {SchemaField},
    strict: boolean?, -- Whether to allow additional fields
    description: string?
}

-- Analytics Types
export type AnalyticsEvent = {
    type: string,
    data: {[string]: any},
    timestamp: number,
    userId: string?,
    sessionId: string
}

export type UsageStatistics = {
    totalUsers: number,
    activeUsers: number,
    featuresUsed: {[string]: number},
    errorRate: number,
    averageSessionTime: number,
    retentionRate: number
}

-- Configuration Types
export type PluginConfig = {
    theme: string,
    autoSave: boolean,
    performanceTracking: boolean,
    debugMode: boolean,
    maxCacheSize: number,
    defaultTimeout: number,
    customSettings: {[string]: any}
}

-- Search and Filter Types
export type SearchFilter = {
    query: string?,
    type: "contains" | "exact" | "regex" | "starts_with" | "ends_with",
    caseSensitive: boolean?,
    fields: {string}? -- Which fields to search in
}

export type SortOptions = {
    field: string,
    direction: "asc" | "desc",
    type: "string" | "number" | "date"
}

-- Bulk Operations Types
export type BulkOperation = {
    type: "create" | "update" | "delete",
    items: {{key: string, value: any?}},
    options: {
        batchSize: number?,
        delay: number?,
        onProgress: ((number, number) -> ())?,
        onError: ((string, any) -> ())?
    }
}

export type BulkOperationResult = {
    success: boolean,
    totalItems: number,
    processedItems: number,
    successfulItems: number,
    failedItems: number,
    errors: {ErrorInfo},
    duration: number
}

-- Export and Import Types
export type ExportFormat = "json" | "csv" | "xml" | "lua"

export type ExportOptions = {
    format: ExportFormat,
    includeMetadata: boolean?,
    compress: boolean?,
    maxFileSize: number?,
    filename: string?
}

export type ImportResult = {
    success: boolean,
    importedCount: number,
    skippedCount: number,
    errorCount: number,
    errors: {ErrorInfo},
    warnings: {string}?
}

-- API Types (for Enterprise features)
export type APIEndpoint = {
    path: string,
    method: "GET" | "POST" | "PUT" | "DELETE",
    handler: (any) -> any,
    authentication: boolean?,
    rateLimit: number?
}

export type APIResponse = {
    success: boolean,
    data: any?,
    error: string?,
    code: number
}

-- Team Collaboration Types (Enterprise)
export type TeamMember = {
    userId: number,
    userName: string,
    role: "owner" | "admin" | "editor" | "viewer",
    permissions: {string},
    joinedAt: number
}

export type CollaborationSession = {
    id: string,
    creator: TeamMember,
    participants: {TeamMember},
    dataStore: string,
    createdAt: number,
    lastActivity: number
}

return Types 