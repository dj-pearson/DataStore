-- DataStore Manager Pro - Notification Manager
-- Manages notifications and status updates

local NotificationManager = {}
NotificationManager.__index = NotificationManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[NOTIFICATION_MANAGER] [%s] %s", level, message))
end

-- Create new Notification Manager instance
function NotificationManager.new(uiManager)
    local self = setmetatable({}, NotificationManager)
    
    self.uiManager = uiManager
    self.statusLabel = nil
    self.notificationContainer = nil
    self.activeNotifications = {}
    
    debugLog("NotificationManager created")
    return self
end

-- Set status label reference
function NotificationManager:setStatusLabel(statusLabel)
    self.statusLabel = statusLabel
end

-- Create notification container
function NotificationManager:createNotificationContainer(parent)
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, 300, 1, 0)
    container.Position = UDim2.new(1, -320, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    self.notificationContainer = container
    return container
end

-- Show notification
function NotificationManager:showNotification(message, type)
    type = type or "INFO"
    
    debugLog("Showing notification: " .. message .. " (" .. type .. ")")
    
    -- Update status bar if available
    if self.statusLabel then
        local icon = ""
        local color = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        
        if type == "SUCCESS" then
            icon = "✅"
            color = Constants.UI.THEME.COLORS.SUCCESS
        elseif type == "ERROR" then
            icon = "❌"
            color = Constants.UI.THEME.COLORS.ERROR
        elseif type == "WARNING" then
            icon = "⚠️"
            color = Constants.UI.THEME.COLORS.WARNING
        elseif type == "INFO" then
            icon = "ℹ️"
            color = Constants.UI.THEME.COLORS.INFO
        else
            icon = "📝"
        end
        
        self.statusLabel.Text = icon .. " " .. message
        self.statusLabel.TextColor3 = color
    end
    
    -- Create floating notification if container exists
    if self.notificationContainer then
        self:createFloatingNotification(message, type)
    end
end

-- Create floating notification
function NotificationManager:createFloatingNotification(message, type)
    local notificationId = tostring(os.time()) .. math.random(1000, 9999)
    
    -- Calculate position for new notification
    local yPosition = #self.activeNotifications * 70
    
    -- Create notification frame
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. notificationId
    notification.Size = UDim2.new(1, 0, 0, 60)
    notification.Position = UDim2.new(0, 0, 0, yPosition)
    notification.BackgroundColor3 = self:getNotificationColor(type)
    notification.BorderSizePixel = 0
    notification.Parent = self.notificationContainer
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    corner.Parent = notification
    
    -- Add subtle shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.8
    shadow.BorderSizePixel = 0
    shadow.ZIndex = notification.ZIndex - 1
    shadow.Parent = self.notificationContainer
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    shadowCorner.Parent = shadow
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0.5, -15)
    icon.BackgroundTransparency = 1
    icon.Text = self:getNotificationIcon(type)
    icon.Font = Constants.UI.THEME.FONTS.UI
    icon.TextSize = 18
    icon.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.TextYAlignment = Enum.TextYAlignment.Center
    icon.Parent = notification
    
    -- Message text
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -70, 1, -10)
    messageLabel.Position = UDim2.new(0, 50, 0, 5)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.Font = Constants.UI.THEME.FONTS.BODY
    messageLabel.TextSize = 12
    messageLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.Font = Constants.UI.THEME.FONTS.UI
    closeButton.TextSize = 14
    closeButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    closeButton.Parent = notification
    
    -- Store notification reference
    table.insert(self.activeNotifications, {
        id = notificationId,
        frame = notification,
        shadow = shadow,
        type = type
    })
    
    -- Animate in
    notification.Position = UDim2.new(1, 0, 0, yPosition)
    notification:TweenPosition(
        UDim2.new(0, 0, 0, yPosition),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.3,
        true
    )
    
    -- Auto-dismiss after delay
    local dismissDelay = self:getNotificationDuration(type)
    
    task.spawn(function()
        task.wait(dismissDelay)
        if notification.Parent then
            self:dismissNotification(notificationId)
        end
    end)
    
    -- Close button handler
    closeButton.MouseButton1Click:Connect(function()
        self:dismissNotification(notificationId)
    end)
    
    -- Hover effects
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundTransparency = 0.8
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundTransparency = 1
        closeButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    end)
    
    debugLog("Floating notification created: " .. notificationId)
end

-- Dismiss notification
function NotificationManager:dismissNotification(notificationId)
    for i, notif in ipairs(self.activeNotifications) do
        if notif.id == notificationId then
            -- Animate out
            notif.frame:TweenPosition(
                UDim2.new(1, 0, 0, notif.frame.Position.Y.Offset),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Back,
                0.2,
                true,
                function()
                    notif.frame:Destroy()
                    notif.shadow:Destroy()
                end
            )
            
            -- Remove from active list
            table.remove(self.activeNotifications, i)
            
            -- Reposition remaining notifications
            self:repositionNotifications()
            
            debugLog("Notification dismissed: " .. notificationId)
            break
        end
    end
end

-- Reposition notifications after dismissal
function NotificationManager:repositionNotifications()
    for i, notif in ipairs(self.activeNotifications) do
        local newYPosition = (i - 1) * 70
        notif.frame:TweenPosition(
            UDim2.new(0, 0, 0, newYPosition),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        notif.shadow:TweenPosition(
            UDim2.new(0, 2, 0, newYPosition + 2),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
    end
end

-- Get notification color based on type
function NotificationManager:getNotificationColor(type)
    if type == "SUCCESS" then
        return Constants.UI.THEME.COLORS.SUCCESS
    elseif type == "ERROR" then
        return Constants.UI.THEME.COLORS.ERROR
    elseif type == "WARNING" then
        return Constants.UI.THEME.COLORS.WARNING
    elseif type == "INFO" then
        return Constants.UI.THEME.COLORS.INFO
    else
        return Constants.UI.THEME.COLORS.PRIMARY
    end
end

-- Get notification icon based on type
function NotificationManager:getNotificationIcon(type)
    if type == "SUCCESS" then
        return "✅"
    elseif type == "ERROR" then
        return "❌"
    elseif type == "WARNING" then
        return "⚠️"
    elseif type == "INFO" then
        return "ℹ️"
    else
        return "📝"
    end
end

-- Get notification duration based on type
function NotificationManager:getNotificationDuration(type)
    if type == "SUCCESS" then
        return 3 -- 3 seconds
    elseif type == "ERROR" then
        return 8 -- 8 seconds for errors
    elseif type == "WARNING" then
        return 6 -- 6 seconds for warnings
    elseif type == "INFO" then
        return 4 -- 4 seconds for info
    else
        return 5 -- 5 seconds default
    end
end

-- Set status
function NotificationManager:setStatus(text, color)
    if self.statusLabel then
        self.statusLabel.Text = text
        if color then
            self.statusLabel.TextColor3 = color
        end
    end
    debugLog("Status updated: " .. text)
end

-- Clear all notifications
function NotificationManager:clearAllNotifications()
    for _, notif in ipairs(self.activeNotifications) do
        notif.frame:Destroy()
        notif.shadow:Destroy()
    end
    self.activeNotifications = {}
    debugLog("All notifications cleared")
end

-- Show loading notification
function NotificationManager:showLoadingNotification(message)
    self:showNotification("🔄 " .. message, "INFO")
end

-- Show success notification
function NotificationManager:showSuccessNotification(message)
    self:showNotification(message, "SUCCESS")
end

-- Show error notification
function NotificationManager:showErrorNotification(message)
    self:showNotification(message, "ERROR")
end

-- Show warning notification
function NotificationManager:showWarningNotification(message)
    self:showNotification(message, "WARNING")
end

return NotificationManager 