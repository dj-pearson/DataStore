-- DataStore Manager Pro - Shared Constants
-- Centralized configuration values for easy maintenance

local Constants = {}

-- Plugin Information
Constants.PLUGIN = {
    NAME = "DataStore Manager Pro",
    VERSION = "1.0.0",
    ID = "DataStoreManagerPro",
    AUTHOR = "YourStudioName"
}

-- DataStore Configuration
Constants.DATASTORE = {
    MAX_RETRIES = 3,
    RETRY_DELAY_BASE = 0.5,
    CACHE_TIMEOUT = 300, -- 5 minutes
    MAX_DATA_SIZE = 4000000, -- 4MB Roblox limit
    REQUEST_BUDGET_LIMIT = 100,
    REQUEST_COOLDOWN = 6 -- seconds
}

-- Performance Thresholds
Constants.PERFORMANCE = {
    MAX_LOAD_TIME = 500, -- milliseconds
    MAX_MEMORY_USAGE = 100 * 1024 * 1024, -- 100MB
    MAX_UI_RESPONSE_TIME = 100, -- milliseconds
    TARGET_LOAD_TIME = 300,
    TARGET_MEMORY_USAGE = 50 * 1024 * 1024 -- 50MB
}

-- UI Configuration
Constants.UI = {
    THEME = {
        COLORS = {
            PRIMARY = Color3.fromRGB(0, 162, 255),
            SUCCESS = Color3.fromRGB(0, 200, 100),
            WARNING = Color3.fromRGB(255, 193, 7),
            ERROR = Color3.fromRGB(220, 53, 69),
            BACKGROUND = Color3.fromRGB(46, 46, 46),
            SURFACE = Color3.fromRGB(56, 56, 56),
            TEXT = Color3.fromRGB(255, 255, 255),
            TEXT_SECONDARY = Color3.fromRGB(180, 180, 180),
            BORDER = Color3.fromRGB(80, 80, 80),
            ACCENT = Color3.fromRGB(120, 120, 120)
        },
        FONTS = {
            HEADING = Enum.Font.SourceSansBold,
            BODY = Enum.Font.SourceSans,
            CODE = Enum.Font.Code,
            ICON = Enum.Font.SourceSans
        },
        SPACING = {
            TINY = 2,
            SMALL = 4,
            MEDIUM = 8,
            LARGE = 16,
            XLARGE = 24
        },
        SIZES = {
            ICON_SMALL = 16,
            ICON_MEDIUM = 24,
            ICON_LARGE = 32,
            BUTTON_HEIGHT = 32,
            TOOLBAR_HEIGHT = 40,
            STATUSBAR_HEIGHT = 28
        }
    },
    WINDOW = {
        DEFAULT_WIDTH = 1200,
        DEFAULT_HEIGHT = 800,
        MIN_WIDTH = 600,
        MIN_HEIGHT = 400
    }
}

-- Logging Configuration
Constants.LOGGING = {
    LEVELS = {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
        FATAL = 5
    },
    MAX_LOG_ENTRIES = 1000,
    LOG_FILE_MAX_SIZE = 10 * 1024 * 1024, -- 10MB
    DEFAULT_LEVEL = 2 -- INFO
}

-- License Management
Constants.LICENSE = {
    TIERS = {
        BASIC = 1,
        PROFESSIONAL = 2,
        ENTERPRISE = 3
    },
    VALIDATION_TIMEOUT = 30, -- seconds
    OFFLINE_GRACE_PERIOD = 7 * 24 * 60 * 60, -- 7 days in seconds
    CHECK_INTERVAL = 24 * 60 * 60 -- 24 hours in seconds
}

-- Feature Flags
Constants.FEATURES = {
    DATA_EXPLORER = {
        tier = Constants.LICENSE.TIERS.BASIC,
        enabled = true
    },
    DATA_EDITING = {
        tier = Constants.LICENSE.TIERS.BASIC,
        enabled = true
    },
    SCHEMA_VALIDATION = {
        tier = Constants.LICENSE.TIERS.PROFESSIONAL,
        enabled = true
    },
    PERFORMANCE_MONITORING = {
        tier = Constants.LICENSE.TIERS.PROFESSIONAL,
        enabled = true
    },
    BULK_OPERATIONS = {
        tier = Constants.LICENSE.TIERS.PROFESSIONAL,
        enabled = true
    },
    ADVANCED_ANALYTICS = {
        tier = Constants.LICENSE.TIERS.ENTERPRISE,
        enabled = true
    },
    API_ACCESS = {
        tier = Constants.LICENSE.TIERS.ENTERPRISE,
        enabled = false -- Coming soon
    },
    TEAM_FEATURES = {
        tier = Constants.LICENSE.TIERS.ENTERPRISE,
        enabled = false -- Coming soon
    }
}

-- Error Codes
Constants.ERRORS = {
    -- DataStore Errors
    DATASTORE_NOT_FOUND = "DS001",
    DATASTORE_ACCESS_DENIED = "DS002",
    DATASTORE_QUOTA_EXCEEDED = "DS003",
    DATASTORE_DATA_TOO_LARGE = "DS004",
    DATASTORE_KEY_NOT_FOUND = "DS005",
    
    -- UI Errors
    UI_COMPONENT_FAILED = "UI001",
    UI_THEME_LOAD_FAILED = "UI002",
    UI_WINDOW_CREATE_FAILED = "UI003",
    
    -- License Errors
    LICENSE_INVALID = "LIC001",
    LICENSE_EXPIRED = "LIC002",
    LICENSE_VALIDATION_FAILED = "LIC003",
    
    -- General Errors
    INITIALIZATION_FAILED = "GEN001",
    SERVICE_UNAVAILABLE = "GEN002",
    CONFIGURATION_ERROR = "GEN003"
}

-- Development flags
Constants.DEBUG = {
    ENABLED = false, -- Set to true for development
    VERBOSE_LOGGING = false,
    MOCK_LICENSE = false,
    PERFORMANCE_TRACKING = true
}

return Constants 