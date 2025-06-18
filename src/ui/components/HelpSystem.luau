-- DataStore Manager Pro - Interactive Help System
-- Provides comprehensive documentation, tutorials, and context-sensitive help

local HelpSystem = {}
HelpSystem.__index = HelpSystem

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)
local Utils = require(script.Parent.Parent.Parent.shared.Utils)
local ThemeManager = require(script.Parent.Parent.core.ThemeManager)
local LayoutManager = require(script.Parent.Parent.core.LayoutManager)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[HELP_SYSTEM] [%s] %s", level, message))
end

-- Help content database
local HELP_CONTENT = {
    overview = {
        title = "DataStore Manager Pro Overview",
        category = "Getting Started",
        content = {
            "Welcome to DataStore Manager Pro - the ultimate enterprise solution for managing Roblox DataStores!",
            "",
            "🎯 **Key Features:**",
            "• Real-time DataStore management with live data",
            "• Advanced analytics and player insights",
            "• Team collaboration with role-based permissions",
            "• Intelligent search and bulk operations",
            "• Performance monitoring and optimization",
            "• Modern glassmorphism UI with accessibility",
            "",
            "🚀 **Getting Started:**",
            "1. Connect to your DataStore using the connection panel",
            "2. Explore your data using the Data Explorer",
            "3. Set up team collaboration in the Team tab",
            "4. Configure preferences in Settings",
            "",
            "💡 **Pro Tips:**",
            "• Use Ctrl+F for quick search across all data",
            "• Enable real-time monitoring for production insights",
            "• Set up backup schedules for data protection"
        },
        tags = {"overview", "getting-started", "introduction"},
        difficulty = "beginner",
        estimatedTime = "5 minutes"
    },
    
    dataExplorer = {
        title = "Data Explorer Guide",
        category = "Core Features",
        content = {
            "The Data Explorer is your primary interface for browsing and managing DataStore data.",
            "",
            "🔍 **Navigation:**",
            "• Left panel: DataStore list with real-time status",
            "• Center panel: Key-value browser with search",
            "• Right panel: Data inspector with JSON viewer",
            "",
            "✨ **Features:**",
            "• **Live Data**: All data is fetched directly from Roblox DataStores",
            "• **Smart Search**: Find keys, values, or patterns instantly",
            "• **Batch Operations**: Select multiple keys for bulk actions",
            "• **Data Validation**: Real-time schema validation",
            "• **History Tracking**: View all changes with timestamps",
            "",
            "🛠️ **Operations:**",
            "• **Create**: Add new key-value pairs",
            "• **Read**: View data with syntax highlighting",
            "• **Update**: Edit values with validation",
            "• **Delete**: Safe deletion with confirmation",
            "",
            "⚡ **Keyboard Shortcuts:**",
            "• Ctrl+N: Create new entry",
            "• Ctrl+E: Edit selected entry",
            "• Ctrl+D: Delete selected entry",
            "• Ctrl+F: Focus search box",
            "• F5: Refresh current view"
        },
        tags = {"data-explorer", "navigation", "crud", "shortcuts"},
        difficulty = "beginner",
        estimatedTime = "10 minutes"
    },
    
    teamCollaboration = {
        title = "Team Collaboration Setup",
        category = "Advanced Features",
        content = {
            "Enable real-time collaboration with your development team using Studio integration.",
            "",
            "👥 **Team Management:**",
            "• **Real Users**: Integrates with actual Roblox Studio users",
            "• **Role-Based Access**: Admin, Editor, Viewer permissions",
            "• **Live Presence**: See who's online and what they're working on",
            "• **Activity Feed**: Track all team member actions",
            "",
            "🔐 **Permission Levels:**",
            "",
            "**Admin (Full Access):**",
            "• Manage team members and permissions",
            "• Access all DataStores and operations",
            "• Configure plugin settings and preferences",
            "• View audit logs and analytics",
            "",
            "**Editor (Data Management):**",
            "• Read and write DataStore data",
            "• Use search and bulk operations",
            "• View analytics and monitoring",
            "• Cannot manage team or settings",
            "",
            "**Viewer (Read-Only):**",
            "• View DataStore data and structure",
            "• Access analytics and reports",
            "• Cannot modify data or settings",
            "",
            "🚀 **Getting Started:**",
            "1. Open the Team tab in the main interface",
            "2. Click 'Invite Team Member' to add users",
            "3. Set appropriate permission levels",
            "4. Share the workspace ID with team members",
            "",
            "💡 **Best Practices:**",
            "• Use Admin role sparingly for security",
            "• Regularly review team member access",
            "• Monitor activity logs for suspicious behavior",
            "• Set up notifications for critical changes"
        },
        tags = {"team", "collaboration", "permissions", "security"},
        difficulty = "intermediate",
        estimatedTime = "15 minutes"
    },
    
    analytics = {
        title = "Advanced Analytics Guide",
        category = "Analytics",
        content = {
            "Gain deep insights into your game's data patterns and player behavior.",
            "",
            "📊 **Analytics Dashboard:**",
            "• **Real-time Metrics**: Live player activity and data changes",
            "• **Historical Trends**: Track data growth and usage patterns",
            "• **Player Insights**: Understand player behavior and progression",
            "• **Performance Metrics**: Monitor DataStore operation efficiency",
            "",
            "🎯 **Key Metrics:**",
            "",
            "**Data Health:**",
            "• Total keys and data size",
            "• Growth rate and trends",
            "• Data quality scores",
            "• Schema compliance",
            "",
            "**Player Analytics:**",
            "• Active player count",
            "• Session duration patterns",
            "• Progression tracking",
            "• Retention analysis",
            "",
            "**Performance Monitoring:**",
            "• Request latency and throughput",
            "• Error rates and types",
            "• Cache hit rates",
            "• Resource utilization",
            "",
            "🔍 **Advanced Features:**",
            "• **Anomaly Detection**: Automatic identification of unusual patterns",
            "• **Predictive Analytics**: Forecast future trends and capacity needs",
            "• **Custom Dashboards**: Create personalized analytics views",
            "• **Export Reports**: Generate PDF/CSV reports for stakeholders",
            "",
            "⚙️ **Configuration:**",
            "1. Enable analytics in Settings > Analytics",
            "2. Configure data collection preferences",
            "3. Set up alert thresholds",
            "4. Choose dashboard layout and metrics"
        },
        tags = {"analytics", "metrics", "monitoring", "insights"},
        difficulty = "intermediate",
        estimatedTime = "20 minutes"
    },
    
    performance = {
        title = "Performance Optimization",
        category = "Advanced Features",
        content = {
            "Maximize your DataStore performance with intelligent monitoring and optimization.",
            "",
            "⚡ **Performance Dashboard:**",
            "• **Real-time Monitoring**: Live performance metrics with 2-second refresh",
            "• **Automatic Optimization**: AI-driven performance tuning",
            "• **Alert System**: Proactive issue detection and notifications",
            "• **Historical Analysis**: Performance trends and pattern recognition",
            "",
            "🎯 **Key Performance Indicators:**",
            "",
            "**Response Time:**",
            "• Target: <200ms average response time",
            "• Automatic optimization when >500ms detected",
            "• Latency tracking for all operations",
            "",
            "**Cache Efficiency:**",
            "• Target: >80% cache hit rate",
            "• Intelligent cache sizing and eviction",
            "• Smart preloading based on access patterns",
            "",
            "**Error Rates:**",
            "• Target: <2% error rate",
            "• Adaptive throttling based on error patterns",
            "• Automatic retry with exponential backoff",
            "",
            "**Throughput:**",
            "• Operations per second tracking",
            "• Batch processing optimization",
            "• Request prioritization system",
            "",
            "🤖 **Automatic Optimizations:**",
            "",
            "**Cache Management:**",
            "• Dynamic cache size adjustment",
            "• LRU/LFU eviction strategy switching",
            "• Access pattern analysis and preloading",
            "",
            "**Request Optimization:**",
            "• Adaptive throttling based on error rates",
            "• Request batching and prioritization",
            "• Connection pooling and reuse",
            "",
            "**Memory Management:**",
            "• Automatic cleanup of expired data",
            "• Memory usage monitoring and optimization",
            "• Garbage collection tuning",
            "",
            "📈 **Performance Recommendations:**",
            "The system provides AI-driven recommendations such as:",
            "• 'Increase cache size to improve hit rate'",
            "• 'Enable request batching for better throughput'",
            "• 'Consider data archiving for old entries'",
            "",
            "⚙️ **Configuration:**",
            "1. Access Performance tab in main interface",
            "2. Review current metrics and alerts",
            "3. Configure optimization settings",
            "4. Set up custom alert thresholds",
            "5. Enable automatic optimization features"
        },
        tags = {"performance", "optimization", "monitoring", "caching"},
        difficulty = "advanced",
        estimatedTime = "25 minutes"
    },
    
    troubleshooting = {
        title = "Troubleshooting Guide",
        category = "Support",
        content = {
            "Common issues and their solutions for DataStore Manager Pro.",
            "",
            "🔧 **Connection Issues:**",
            "",
            "**Problem**: Cannot connect to DataStore",
            "**Solutions**:",
            "• Verify API key is valid and has DataStore permissions",
            "• Check internet connection and firewall settings",
            "• Ensure Universe ID is correct",
            "• Try refreshing the connection",
            "",
            "**Problem**: Slow data loading",
            "**Solutions**:",
            "• Enable performance optimization in settings",
            "• Check DataStore request budget",
            "• Reduce concurrent operations",
            "• Clear cache and reload",
            "",
            "🚫 **Permission Errors:**",
            "",
            "**Problem**: Access denied errors",
            "**Solutions**:",
            "• Verify user has appropriate permissions",
            "• Check team role assignments",
            "• Ensure API key has required scopes",
            "• Contact team admin for access",
            "",
            "📊 **Data Issues:**",
            "",
            "**Problem**: Data not updating",
            "**Solutions**:",
            "• Check if data is cached (look for cache indicator)",
            "• Force refresh with F5 or refresh button",
            "• Verify write permissions",
            "• Check for data validation errors",
            "",
            "**Problem**: Search not working",
            "**Solutions**:",
            "• Ensure search index is built (may take time for large datasets)",
            "• Try different search terms or patterns",
            "• Check search filters and options",
            "• Rebuild search index in settings",
            "",
            "⚡ **Performance Issues:**",
            "",
            "**Problem**: Plugin running slowly",
            "**Solutions**:",
            "• Enable low power mode in preferences",
            "• Disable animations and visual effects",
            "• Reduce cache size if memory is limited",
            "• Close unused tabs and features",
            "",
            "🆘 **Getting Help:**",
            "",
            "If you're still experiencing issues:",
            "1. Check the plugin logs for error messages",
            "2. Try restarting Roblox Studio",
            "3. Report the issue with reproduction steps",
            "4. Include your Studio version and plugin version",
            "",
            "📞 **Support Channels:**",
            "• In-plugin help system (you're here!)",
            "• Community forums and documentation",
            "• Direct support for enterprise users",
            "• GitHub issues for bug reports"
        },
        tags = {"troubleshooting", "issues", "support", "help"},
        difficulty = "beginner",
        estimatedTime = "15 minutes"
    }
}

-- Tutorial sequences
local TUTORIALS = {
    quickStart = {
        title = "Quick Start Tutorial",
        description = "Get up and running with DataStore Manager Pro in 5 minutes",
        steps = {
            {
                title = "Welcome to DataStore Manager Pro",
                content = "This tutorial will guide you through the basic features of the plugin.",
                action = "highlight",
                target = "main-interface"
            },
            {
                title = "Connect to Your DataStore",
                content = "First, let's connect to your DataStore. Click the connection panel.",
                action = "highlight",
                target = "connection-panel"
            },
            {
                title = "Explore Your Data",
                content = "Use the Data Explorer to browse your DataStore contents.",
                action = "highlight",
                target = "data-explorer"
            },
            {
                title = "Try the Search Feature",
                content = "Use Ctrl+F or click the search box to find specific data.",
                action = "highlight",
                target = "search-box"
            },
            {
                title = "Check Out Analytics",
                content = "View insights about your data and player behavior.",
                action = "highlight",
                target = "analytics-tab"
            },
            {
                title = "Customize Your Experience",
                content = "Access Settings to personalize the plugin to your needs.",
                action = "highlight",
                target = "settings-tab"
            }
        }
    },
    
    teamSetup = {
        title = "Team Collaboration Setup",
        description = "Learn how to set up team collaboration with role-based permissions",
        steps = {
            {
                title = "Team Collaboration Overview",
                content = "Set up real-time collaboration with your development team.",
                action = "navigate",
                target = "team-tab"
            },
            {
                title = "Invite Team Members",
                content = "Click 'Invite Team Member' to add users to your workspace.",
                action = "highlight",
                target = "invite-button"
            },
            {
                title = "Set Permissions",
                content = "Choose appropriate permission levels: Admin, Editor, or Viewer.",
                action = "highlight",
                target = "permissions-panel"
            },
            {
                title = "Monitor Activity",
                content = "Track team member actions in the activity feed.",
                action = "highlight",
                target = "activity-feed"
            }
        }
    }
}

-- Create new Help System
function HelpSystem.new(services)
    local self = setmetatable({}, HelpSystem)
    
    self.services = services or {}
    self.isVisible = false
    self.currentTopic = "overview"
    self.currentTutorial = nil
    self.tutorialStep = 1
    self.searchQuery = ""
    self.searchResults = {}
    
    -- UI elements
    self.gui = nil
    self.contentPanel = nil
    self.navigationPanel = nil
    self.searchBox = nil
    
    debugLog("Help System created")
    return self
end

-- Initialize the help system
function HelpSystem:initialize(parent)
    self:createHelpUI(parent)
    self:loadHelpContent()
    debugLog("Help System initialized")
end

-- Create the main help UI
function HelpSystem:createHelpUI(parent)
    -- Main help container
    self.gui = Instance.new("Frame")
    self.gui.Name = "HelpSystem"
    self.gui.Size = UDim2.new(1, 0, 1, 0)
    self.gui.Position = UDim2.new(0, 0, 0, 0)
    self.gui.BackgroundTransparency = 1
    self.gui.Visible = false
    self.gui.Parent = parent
    
    -- Help layout
    local helpLayout = Instance.new("Frame")
    helpLayout.Name = "HelpLayout"
    helpLayout.Size = UDim2.new(1, 0, 1, 0)
    helpLayout.BackgroundTransparency = 1
    helpLayout.Parent = self.gui
    
    -- Create navigation sidebar
    self:createNavigationPanel(helpLayout)
    
    -- Create main content area
    self:createContentPanel(helpLayout)
    
    -- Create search functionality
    self:createSearchSystem()
end

-- Create navigation panel
function HelpSystem:createNavigationPanel(parent)
    self.navigationPanel = ThemeManager.createProfessionalCard({
        name = "NavigationPanel",
        size = UDim2.new(0, 280, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        background = "secondary",
        cornerRadius = 0
    })
    self.navigationPanel.Parent = parent
    
    -- Navigation header
    local navHeader = Instance.new("TextLabel")
    navHeader.Name = "NavigationHeader"
    navHeader.Size = UDim2.new(1, -20, 0, 40)
    navHeader.Position = UDim2.new(0, 10, 0, 10)
    navHeader.Text = "📚 Help & Documentation"
    navHeader.Font = Constants.UI.THEME.FONTS.UI
    navHeader.TextSize = 18
    navHeader.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    navHeader.BackgroundTransparency = 1
    navHeader.TextXAlignment = Enum.TextXAlignment.Left
    navHeader.Parent = self.navigationPanel
    
    -- Search box
    local searchContainer, searchField = ThemeManager.createModernInput({
        name = "HelpSearch",
        placeholder = "Search help topics...",
        size = UDim2.new(1, -20, 0, 36),
        position = UDim2.new(0, 10, 0, 60)
    })
    searchContainer.Parent = self.navigationPanel
    self.searchBox = searchField
    
    -- Search functionality
    searchField:GetPropertyChangedSignal("Text"):Connect(function()
        self:performSearch(searchField.Text)
    end)
    
    -- Navigation categories
    local categoriesContainer = Instance.new("ScrollingFrame")
    categoriesContainer.Name = "CategoriesContainer"
    categoriesContainer.Size = UDim2.new(1, 0, 1, -110)
    categoriesContainer.Position = UDim2.new(0, 0, 0, 110)
    categoriesContainer.BackgroundTransparency = 1
    categoriesContainer.ScrollBarThickness = 6
    categoriesContainer.Parent = self.navigationPanel
    
    -- Categories content
    local categoriesContent = Instance.new("Frame")
    categoriesContent.Name = "CategoriesContent"
    categoriesContent.Size = UDim2.new(1, 0, 0, 0)
    categoriesContent.BackgroundTransparency = 1
    categoriesContent.Parent = categoriesContainer
    
    -- Auto-sizing layout
    local categoriesLayout = Instance.new("UIListLayout")
    categoriesLayout.FillDirection = Enum.FillDirection.Vertical
    categoriesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    categoriesLayout.Padding = UDim.new(0, 4)
    categoriesLayout.Parent = categoriesContent
    
    -- Update canvas size
    categoriesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        categoriesContainer.CanvasSize = UDim2.new(0, 0, 0, categoriesLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Create category sections
    self:createCategoryNavigation(categoriesContent)
end

-- Create category navigation
function HelpSystem:createCategoryNavigation(parent)
    local categories = {}
    
    -- Group help content by category
    for topicId, topic in pairs(HELP_CONTENT) do
        local category = topic.category
        if not categories[category] then
            categories[category] = {}
        end
        table.insert(categories[category], {id = topicId, topic = topic})
    end
    
    -- Create category sections
    for categoryName, topics in pairs(categories) do
        local categorySection = Instance.new("Frame")
        categorySection.Name = categoryName .. "Section"
        categorySection.Size = UDim2.new(1, -20, 0, 40 + (#topics * 32))
        categorySection.BackgroundTransparency = 1
        categorySection.Parent = parent
        
        -- Category header
        local categoryHeader = Instance.new("TextLabel")
        categoryHeader.Name = "CategoryHeader"
        categoryHeader.Size = UDim2.new(1, 0, 0, 30)
        categoryHeader.Position = UDim2.new(0, 0, 0, 0)
        categoryHeader.Text = categoryName
        categoryHeader.Font = Constants.UI.THEME.FONTS.UI
        categoryHeader.TextSize = 14
        categoryHeader.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
        categoryHeader.BackgroundTransparency = 1
        categoryHeader.TextXAlignment = Enum.TextXAlignment.Left
        categoryHeader.Parent = categorySection
        
        -- Topic buttons
        for i, topicData in ipairs(topics) do
            local topicButton = ThemeManager.createProfessionalButton({
                name = topicData.id .. "Button",
                text = topicData.topic.title,
                size = UDim2.new(1, 0, 0, 28),
                position = UDim2.new(0, 0, 0, 30 + ((i-1) * 32)),
                background = "tertiary",
                textColor = "primary"
            })
            topicButton.Parent = categorySection
            
            -- Add click handler
            topicButton.MouseButton1Click:Connect(function()
                self:showTopic(topicData.id)
            end)
        end
    end
    
    -- Add tutorials section
    self:createTutorialsNavigation(parent)
end

-- Create tutorials navigation
function HelpSystem:createTutorialsNavigation(parent)
    local tutorialsSection = Instance.new("Frame")
    tutorialsSection.Name = "TutorialsSection"
    tutorialsSection.Size = UDim2.new(1, -20, 0, 40 + (Utils.tableLength(TUTORIALS) * 32))
    tutorialsSection.BackgroundTransparency = 1
    tutorialsSection.Parent = parent
    
    -- Tutorials header
    local tutorialsHeader = Instance.new("TextLabel")
    tutorialsHeader.Name = "TutorialsHeader"
    tutorialsHeader.Size = UDim2.new(1, 0, 0, 30)
    tutorialsHeader.Position = UDim2.new(0, 0, 0, 0)
    tutorialsHeader.Text = "Interactive Tutorials"
    tutorialsHeader.Font = Constants.UI.THEME.FONTS.UI
    tutorialsHeader.TextSize = 14
    tutorialsHeader.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    tutorialsHeader.BackgroundTransparency = 1
    tutorialsHeader.TextXAlignment = Enum.TextXAlignment.Left
    tutorialsHeader.Parent = tutorialsSection
    
    -- Tutorial buttons
    local i = 1
    for tutorialId, tutorial in pairs(TUTORIALS) do
        local tutorialButton = ThemeManager.createProfessionalButton({
            name = tutorialId .. "TutorialButton",
            text = "▶️ " .. tutorial.title,
            size = UDim2.new(1, 0, 0, 28),
            position = UDim2.new(0, 0, 0, 30 + ((i-1) * 32)),
            background = "accent",
            textColor = "primary"
        })
        tutorialButton.Parent = tutorialsSection
        
        -- Add click handler
        tutorialButton.MouseButton1Click:Connect(function()
            self:startTutorial(tutorialId)
        end)
        
        i = i + 1
    end
end

-- Create content panel
function HelpSystem:createContentPanel(parent)
    self.contentPanel = Instance.new("Frame")
    self.contentPanel.Name = "ContentPanel"
    self.contentPanel.Size = UDim2.new(1, -300, 1, 0)
    self.contentPanel.Position = UDim2.new(0, 300, 0, 0)
    self.contentPanel.BackgroundTransparency = 1
    self.contentPanel.Parent = parent
    
    -- Content background
    local contentBg = ThemeManager.createProfessionalCard({
        name = "ContentBackground",
        size = UDim2.new(1, -20, 1, -20),
        position = UDim2.new(0, 10, 0, 10),
        background = "primary",
        cornerRadius = 12
    })
    contentBg.Parent = self.contentPanel
    
    -- Scrolling content area
    local scrollingContent = Instance.new("ScrollingFrame")
    scrollingContent.Name = "ScrollingContent"
    scrollingContent.Size = UDim2.new(1, -40, 1, -40)
    scrollingContent.Position = UDim2.new(0, 20, 0, 20)
    scrollingContent.BackgroundTransparency = 1
    scrollingContent.ScrollBarThickness = 8
    scrollingContent.Parent = contentBg
    
    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = scrollingContent
    
    -- Content layout
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    contentLayout.Padding = UDim.new(0, 16)
    contentLayout.Parent = contentContainer
    
    -- Update canvas size
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollingContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40)
    end)
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.Parent = contentContainer
    
    self.contentContainer = contentContainer
end

-- Load help content
function HelpSystem:loadHelpContent()
    self:showTopic(self.currentTopic)
end

-- Show specific help topic
function HelpSystem:showTopic(topicId)
    local topic = HELP_CONTENT[topicId]
    if not topic then
        debugLog("Topic not found: " .. topicId, "WARN")
        return
    end
    
    self.currentTopic = topicId
    
    -- Clear existing content
    for _, child in ipairs(self.contentContainer:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Topic header
    local headerCard = ThemeManager.createGlassmorphismCard({
        name = "TopicHeader",
        size = UDim2.new(1, 0, 0, 120),
        cornerRadius = 12
    })
    headerCard.Parent = self.contentContainer
    
    -- Topic title
    local title = Instance.new("TextLabel")
    title.Name = "TopicTitle"
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.Text = topic.title
    title.Font = Constants.UI.THEME.FONTS.UI
    title.TextSize = 24
    title.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerCard
    
    -- Topic metadata
    local metadata = Instance.new("TextLabel")
    metadata.Name = "TopicMetadata"
    metadata.Size = UDim2.new(1, -40, 0, 20)
    metadata.Position = UDim2.new(0, 20, 0, 65)
    metadata.Text = string.format("📂 %s • 🎯 %s • ⏱️ %s", 
        topic.category, 
        topic.difficulty:gsub("^%l", string.upper), 
        topic.estimatedTime)
    metadata.Font = Constants.UI.THEME.FONTS.UI
    metadata.TextSize = 12
    metadata.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    metadata.BackgroundTransparency = 1
    metadata.TextXAlignment = Enum.TextXAlignment.Left
    metadata.Parent = headerCard
    
    -- Topic tags
    local tagsText = "🏷️ " .. table.concat(topic.tags, ", ")
    local tags = Instance.new("TextLabel")
    tags.Name = "TopicTags"
    tags.Size = UDim2.new(1, -40, 0, 20)
    tags.Position = UDim2.new(0, 20, 0, 90)
    tags.Text = tagsText
    tags.Font = Constants.UI.THEME.FONTS.UI
    tags.TextSize = 11
    tags.TextColor3 = ThemeManager.getCurrentTheme().text.muted
    tags.BackgroundTransparency = 1
    tags.TextXAlignment = Enum.TextXAlignment.Left
    tags.Parent = headerCard
    
    -- Topic content
    local contentCard = ThemeManager.createProfessionalCard({
        name = "TopicContent",
        size = UDim2.new(1, 0, 0, 0), -- Will be auto-sized
        background = "secondary",
        cornerRadius = 8
    })
    contentCard.Parent = self.contentContainer
    
    -- Content text
    local contentText = table.concat(topic.content, "\n")
    local content = Instance.new("TextLabel")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 0, 0)
    content.Position = UDim2.new(0, 20, 0, 20)
    content.Text = contentText
    content.Font = Constants.UI.THEME.FONTS.UI
    content.TextSize = 14
    content.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    content.BackgroundTransparency = 1
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Parent = contentCard
    
    -- Auto-size content card
    content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        contentCard.Size = UDim2.new(1, 0, 0, content.AbsoluteSize.Y + 40)
    end)
    
    debugLog("Showed help topic: " .. topicId)
end

-- Perform search
function HelpSystem:performSearch(query)
    self.searchQuery = query:lower()
    self.searchResults = {}
    
    if query == "" then
        return
    end
    
    -- Search through help content
    for topicId, topic in pairs(HELP_CONTENT) do
        local score = 0
        
        -- Check title
        if topic.title:lower():find(self.searchQuery) then
            score = score + 10
        end
        
        -- Check content
        local contentText = table.concat(topic.content, " "):lower()
        if contentText:find(self.searchQuery) then
            score = score + 5
        end
        
        -- Check tags
        for _, tag in ipairs(topic.tags) do
            if tag:lower():find(self.searchQuery) then
                score = score + 3
            end
        end
        
        -- Check category
        if topic.category:lower():find(self.searchQuery) then
            score = score + 2
        end
        
        if score > 0 then
            table.insert(self.searchResults, {
                topicId = topicId,
                topic = topic,
                score = score
            })
        end
    end
    
    -- Sort by relevance score
    table.sort(self.searchResults, function(a, b)
        return a.score > b.score
    end)
    
    -- Show search results
    if #self.searchResults > 0 then
        self:showSearchResults()
    end
    
    debugLog("Search performed: " .. query .. " (" .. #self.searchResults .. " results)")
end

-- Show search results
function HelpSystem:showSearchResults()
    -- Clear existing content
    for _, child in ipairs(self.contentContainer:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Search results header
    local resultsHeader = Instance.new("TextLabel")
    resultsHeader.Name = "SearchResultsHeader"
    resultsHeader.Size = UDim2.new(1, 0, 0, 40)
    resultsHeader.Text = string.format("🔍 Search Results for '%s' (%d found)", 
        self.searchQuery, #self.searchResults)
    resultsHeader.Font = Constants.UI.THEME.FONTS.UI
    resultsHeader.TextSize = 20
    resultsHeader.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    resultsHeader.BackgroundTransparency = 1
    resultsHeader.TextXAlignment = Enum.TextXAlignment.Left
    resultsHeader.Parent = self.contentContainer
    
    -- Search results
    for i, result in ipairs(self.searchResults) do
        local resultCard = ThemeManager.createProfessionalCard({
            name = "SearchResult" .. i,
            size = UDim2.new(1, 0, 0, 100),
            background = "secondary",
            cornerRadius = 8
        })
        resultCard.Parent = self.contentContainer
        
        -- Result title
        local resultTitle = Instance.new("TextLabel")
        resultTitle.Name = "ResultTitle"
        resultTitle.Size = UDim2.new(1, -40, 0, 24)
        resultTitle.Position = UDim2.new(0, 20, 0, 15)
        resultTitle.Text = result.topic.title
        resultTitle.Font = Constants.UI.THEME.FONTS.UI
        resultTitle.TextSize = 16
        resultTitle.TextColor3 = ThemeManager.getCurrentTheme().text.primary
        resultTitle.BackgroundTransparency = 1
        resultTitle.TextXAlignment = Enum.TextXAlignment.Left
        resultTitle.Parent = resultCard
        
        -- Result snippet
        local snippet = table.concat(result.topic.content, " "):sub(1, 120) .. "..."
        local resultSnippet = Instance.new("TextLabel")
        resultSnippet.Name = "ResultSnippet"
        resultSnippet.Size = UDim2.new(1, -40, 0, 40)
        resultSnippet.Position = UDim2.new(0, 20, 0, 40)
        resultSnippet.Text = snippet
        resultSnippet.Font = Constants.UI.THEME.FONTS.UI
        resultSnippet.TextSize = 12
        resultSnippet.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
        resultSnippet.BackgroundTransparency = 1
        resultSnippet.TextXAlignment = Enum.TextXAlignment.Left
        resultSnippet.TextYAlignment = Enum.TextYAlignment.Top
        resultSnippet.TextWrapped = true
        resultSnippet.Parent = resultCard
        
        -- Click to view
        local viewButton = ThemeManager.createProfessionalButton({
            name = "ViewButton",
            text = "View Topic",
            size = UDim2.new(0, 100, 0, 24),
            position = UDim2.new(1, -120, 1, -35),
            background = "accent",
            textColor = "primary"
        })
        viewButton.Parent = resultCard
        
        -- Add click handler
        viewButton.MouseButton1Click:Connect(function()
            self:showTopic(result.topicId)
        end)
        
        -- Add hover effect
        ThemeManager.addHoverEffects(resultCard, "scale")
    end
end

-- Start tutorial
function HelpSystem:startTutorial(tutorialId)
    local tutorial = TUTORIALS[tutorialId]
    if not tutorial then
        debugLog("Tutorial not found: " .. tutorialId, "WARN")
        return
    end
    
    self.currentTutorial = tutorialId
    self.tutorialStep = 1
    
    -- Show tutorial overlay
    self:showTutorialStep()
    
    debugLog("Started tutorial: " .. tutorialId)
end

-- Show tutorial step
function HelpSystem:showTutorialStep()
    local tutorial = TUTORIALS[self.currentTutorial]
    local step = tutorial.steps[self.tutorialStep]
    
    if not step then
        self:completeTutorial()
        return
    end
    
    -- Create tutorial overlay
    local tutorialOverlay = Instance.new("Frame")
    tutorialOverlay.Name = "TutorialOverlay"
    tutorialOverlay.Size = UDim2.new(1, 0, 1, 0)
    tutorialOverlay.Position = UDim2.new(0, 0, 0, 0)
    tutorialOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tutorialOverlay.BackgroundTransparency = 0.7
    tutorialOverlay.ZIndex = 1000
    tutorialOverlay.Parent = self.gui.Parent
    
    -- Tutorial step card
    local stepCard = ThemeManager.createGlassmorphismCard({
        name = "TutorialStep",
        size = UDim2.new(0, 400, 0, 200),
        position = UDim2.new(0.5, -200, 0.5, -100),
        cornerRadius = 16
    })
    stepCard.ZIndex = 1001
    stepCard.Parent = tutorialOverlay
    
    -- Step title
    local stepTitle = Instance.new("TextLabel")
    stepTitle.Name = "StepTitle"
    stepTitle.Size = UDim2.new(1, -40, 0, 30)
    stepTitle.Position = UDim2.new(0, 20, 0, 20)
    stepTitle.Text = step.title
    stepTitle.Font = Constants.UI.THEME.FONTS.UI
    stepTitle.TextSize = 18
    stepTitle.TextColor3 = ThemeManager.getCurrentTheme().text.primary
    stepTitle.BackgroundTransparency = 1
    stepTitle.TextXAlignment = Enum.TextXAlignment.Left
    stepTitle.ZIndex = 1002
    stepTitle.Parent = stepCard
    
    -- Step content
    local stepContent = Instance.new("TextLabel")
    stepContent.Name = "StepContent"
    stepContent.Size = UDim2.new(1, -40, 0, 80)
    stepContent.Position = UDim2.new(0, 20, 0, 60)
    stepContent.Text = step.content
    stepContent.Font = Constants.UI.THEME.FONTS.UI
    stepContent.TextSize = 14
    stepContent.TextColor3 = ThemeManager.getCurrentTheme().text.secondary
    stepContent.BackgroundTransparency = 1
    stepContent.TextXAlignment = Enum.TextXAlignment.Left
    stepContent.TextYAlignment = Enum.TextYAlignment.Top
    stepContent.TextWrapped = true
    stepContent.ZIndex = 1002
    stepContent.Parent = stepCard
    
    -- Navigation buttons
    local nextButton = ThemeManager.createProfessionalButton({
        name = "NextButton",
        text = "Next",
        size = UDim2.new(0, 80, 0, 32),
        position = UDim2.new(1, -100, 1, -45),
        background = "accent",
        textColor = "primary"
    })
    nextButton.ZIndex = 1002
    nextButton.Parent = stepCard
    
    nextButton.MouseButton1Click:Connect(function()
        tutorialOverlay:Destroy()
        self.tutorialStep = self.tutorialStep + 1
        self:showTutorialStep()
    end)
    
    -- Skip tutorial button
    local skipButton = ThemeManager.createProfessionalButton({
        name = "SkipButton",
        text = "Skip",
        size = UDim2.new(0, 80, 0, 32),
        position = UDim2.new(1, -190, 1, -45),
        background = "secondary",
        textColor = "primary"
    })
    skipButton.ZIndex = 1002
    skipButton.Parent = stepCard
    
    skipButton.MouseButton1Click:Connect(function()
        tutorialOverlay:Destroy()
        self:completeTutorial()
    end)
    
    -- Close on overlay click
    tutorialOverlay.MouseButton1Click:Connect(function()
        tutorialOverlay:Destroy()
        self:completeTutorial()
    end)
    
    -- Prevent card clicks from closing
    stepCard.MouseButton1Click:Connect(function() end)
    
    -- Show with animation
    if ThemeManager.areAnimationsEnabled() then
        ThemeManager.fadeIn(tutorialOverlay, 0.3)
        ThemeManager.slideIn(stepCard, "bottom", 0.4)
    end
end

-- Complete tutorial
function HelpSystem:completeTutorial()
    self.currentTutorial = nil
    self.tutorialStep = 1
    
    -- Show completion notification
    ThemeManager.createModernNotification({
        title = "Tutorial Complete!",
        message = "You've completed the tutorial. Happy data managing!",
        icon = "🎉",
        type = "success",
        duration = 5
    }).Parent = self.gui.Parent
    
    debugLog("Tutorial completed")
end

-- Create search system
function HelpSystem:createSearchSystem()
    -- Search is already integrated into the navigation panel
    debugLog("Search system initialized")
end

-- Show help system
function HelpSystem:show()
    if self.gui then
        self.gui.Visible = true
        self.isVisible = true
        
        -- Show with animation
        if ThemeManager.areAnimationsEnabled() then
            ThemeManager.fadeIn(self.gui, 0.3)
        end
        
        debugLog("Help system shown")
    end
end

-- Hide help system
function HelpSystem:hide()
    if self.gui then
        self.gui.Visible = false
        self.isVisible = false
        debugLog("Help system hidden")
    end
end

-- Toggle help system
function HelpSystem:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- Show context-sensitive help
function HelpSystem:showContextHelp(context)
    -- Map contexts to help topics
    local contextMap = {
        ["data-explorer"] = "dataExplorer",
        ["team-collaboration"] = "teamCollaboration",
        ["analytics"] = "analytics",
        ["performance"] = "performance",
        ["settings"] = "overview"
    }
    
    local topicId = contextMap[context] or "overview"
    
    self:show()
    self:showTopic(topicId)
    
    debugLog("Showed context help for: " .. context)
end

-- Get help statistics
function HelpSystem:getStatistics()
    return {
        totalTopics = Utils.tableLength(HELP_CONTENT),
        totalTutorials = Utils.tableLength(TUTORIALS),
        currentTopic = self.currentTopic,
        searchResults = #self.searchResults,
        isVisible = self.isVisible
    }
end

-- Cleanup
function HelpSystem:cleanup()
    self:hide()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
    debugLog("Help system cleanup complete")
end

return HelpSystem 