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

-- UI Configuration - Modern Professional Theme
Constants.UI = {
    THEME = {
        COLORS = {
            -- Modern dark theme inspired by professional tools
            PRIMARY = Color3.fromRGB(88, 101, 242),        -- Discord/Modern blue
            SECONDARY = Color3.fromRGB(114, 137, 218),     -- Lighter blue accent
            SUCCESS = Color3.fromRGB(87, 242, 135),        -- Modern green
            WARNING = Color3.fromRGB(254, 231, 92),        -- Warm yellow
            ERROR = Color3.fromRGB(237, 66, 69),           -- Clean red
            
            -- Background layers (darkest to lightest)
            BACKGROUND_PRIMARY = Color3.fromRGB(32, 34, 37),   -- Main background
            BACKGROUND_SECONDARY = Color3.fromRGB(40, 43, 48), -- Cards/panels
            BACKGROUND_TERTIARY = Color3.fromRGB(47, 49, 54),  -- Elevated elements
            
            -- Sidebar theme
            SIDEBAR_BACKGROUND = Color3.fromRGB(25, 28, 31),   -- Dark sidebar
            SIDEBAR_ITEM_HOVER = Color3.fromRGB(88, 101, 242), -- Hover state
            SIDEBAR_ITEM_ACTIVE = Color3.fromRGB(114, 137, 218), -- Active item
            
            -- Text hierarchy
            TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),      -- Primary text
            TEXT_SECONDARY = Color3.fromRGB(185, 187, 190),    -- Secondary text
            TEXT_MUTED = Color3.fromRGB(142, 146, 151),        -- Muted text
            TEXT_DISABLED = Color3.fromRGB(96, 101, 108),      -- Disabled text
            TEXT_INVERSE = Color3.fromRGB(0, 0, 0),            -- Text on light backgrounds
            
            -- Interactive elements
            BUTTON_PRIMARY = Color3.fromRGB(88, 101, 242),     -- Primary buttons
            BUTTON_SECONDARY = Color3.fromRGB(79, 84, 92),     -- Secondary buttons
            BUTTON_DANGER = Color3.fromRGB(237, 66, 69),       -- Danger buttons
            BUTTON_HOVER = Color3.fromRGB(71, 82, 196),        -- Button hover
            BUTTON_DISABLED = Color3.fromRGB(54, 57, 62),      -- Disabled buttons
            
            -- Borders and dividers
            BORDER_PRIMARY = Color3.fromRGB(79, 84, 92),       -- Main borders
            BORDER_SECONDARY = Color3.fromRGB(67, 70, 75),     -- Subtle borders
            DIVIDER = Color3.fromRGB(47, 49, 54),              -- Section dividers
            
            -- Input fields
            INPUT_BACKGROUND = Color3.fromRGB(40, 43, 48),     -- Input background
            CODE_BACKGROUND = Color3.fromRGB(32, 34, 37),      -- Code editor background
            
            -- Data visualization
            JSON_STRING = Color3.fromRGB(152, 195, 121),       -- JSON string values
            JSON_NUMBER = Color3.fromRGB(209, 154, 102),       -- JSON numbers
            JSON_BOOLEAN = Color3.fromRGB(86, 182, 194),       -- JSON booleans
            JSON_NULL = Color3.fromRGB(224, 108, 117),         -- JSON null
            JSON_KEY = Color3.fromRGB(198, 120, 221),          -- JSON keys
            CODE_NORMAL = Color3.fromRGB(171, 178, 191),       -- Normal code text
            
            -- Status indicators
            STATUS_ONLINE = Color3.fromRGB(87, 242, 135),      -- Online/connected
            STATUS_OFFLINE = Color3.fromRGB(116, 127, 141),    -- Offline/disconnected
            STATUS_LOADING = Color3.fromRGB(114, 137, 218),    -- Loading state
        },
        FONTS = {
            HEADING = Enum.Font.GothamBold,        -- Modern headings
            SUBHEADING = Enum.Font.GothamMedium,   -- Subheadings
            BODY = Enum.Font.Gotham,               -- Body text
            CODE = Enum.Font.RobotoMono,           -- Code/JSON display
            UI = Enum.Font.GothamMedium,           -- UI elements
            ICON = Enum.Font.GothamMedium          -- Icon labels
        },
        SPACING = {
            TINY = 4,     -- 4px
            SMALL = 8,    -- 8px
            MEDIUM = 12,  -- 12px
            LARGE = 16,   -- 16px
            XLARGE = 24,  -- 24px
            XXLARGE = 32, -- 32px
            HUGE = 48     -- 48px
        },
        SIZES = {
            -- Text sizes
            TEXT_TINY = 10,
            TEXT_SMALL = 11,
            TEXT_MEDIUM = 13,
            TEXT_LARGE = 16,
            TEXT_XLARGE = 20,
            
            -- Icons
            ICON_TINY = 12,
            ICON_SMALL = 16,
            ICON_MEDIUM = 20,
            ICON_LARGE = 24,
            ICON_XLARGE = 32,
            
            -- Components
            BUTTON_HEIGHT = 36,        -- Comfortable button height
            INPUT_HEIGHT = 40,         -- Input field height
            CARD_MIN_HEIGHT = 80,      -- Minimum card height
            SIDEBAR_WIDTH = 200,       -- Sidebar width
            TOOLBAR_HEIGHT = 48,       -- Toolbar height
            STATUSBAR_HEIGHT = 24,     -- Status bar height
            
            -- Layout
            PANEL_PADDING = 16,        -- Panel padding
            CARD_PADDING = 20,         -- Card internal padding
            BORDER_RADIUS = 6,         -- Border radius for cards
            BORDER_WIDTH = 1           -- Border width
        },
        ANIMATIONS = {
            DURATION_FAST = 0.15,      -- Quick transitions
            DURATION_NORMAL = 0.25,    -- Normal transitions
            DURATION_SLOW = 0.4,       -- Slow transitions
            EASING = Enum.EasingStyle.Quart,
            DIRECTION = Enum.EasingDirection.Out
        }
    },
    WINDOW = {
        DEFAULT_WIDTH = 1400,      -- Wider for modern layouts
        DEFAULT_HEIGHT = 900,      -- Taller for better content
        MIN_WIDTH = 800,           -- Minimum usable width
        MIN_HEIGHT = 500           -- Minimum usable height
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