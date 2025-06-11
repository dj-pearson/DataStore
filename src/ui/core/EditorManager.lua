-- DataStore Manager Pro - Editor Manager
-- Manages data editing functionality and editor interfaces

local EditorManager = {}
EditorManager.__index = EditorManager

-- Import dependencies
local Constants = require(script.Parent.Parent.Parent.shared.Constants)

local function debugLog(message, level)
    level = level or "INFO"
    print(string.format("[EDITOR_MANAGER] [%s] %s", level, message))
end

-- Create new Editor Manager instance
function EditorManager.new(uiManager)
    local self = setmetatable({}, EditorManager)
    
    self.uiManager = uiManager
    self.activeEditor = nil
    self.editorModal = nil
    
    debugLog("EditorManager created")
    return self
end

-- Open data editor
function EditorManager:openDataEditor(mode, keyName, dataInfo)
    debugLog("Opening data editor: " .. mode .. " for key: " .. (keyName or "new"))
    
    -- Create modal backdrop
    local modal = Instance.new("Frame")
    modal.Name = "EditorModal"
    modal.Size = UDim2.new(1, 0, 1, 0)
    modal.Position = UDim2.new(0, 0, 0, 0)
    modal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    modal.BackgroundTransparency = 0.5
    modal.BorderSizePixel = 0
    modal.ZIndex = 100
    modal.Parent = self.uiManager.layoutManager:getMainFrame()
    
    self.editorModal = modal
    
    -- Create editor interface
    self:createDataEditorInterface(modal, mode, keyName, dataInfo)
    
    -- Click outside to close
    modal.MouseButton1Click:Connect(function()
        self:closeDataEditor()
    end)
end

-- Create data editor interface
function EditorManager:createDataEditorInterface(modal, mode, keyName, dataInfo)
    -- Editor window
    local editorWindow = Instance.new("Frame")
    editorWindow.Name = "EditorWindow"
    editorWindow.Size = UDim2.new(0, 800, 0, 600)
    editorWindow.Position = UDim2.new(0.5, -400, 0.5, -300)
    editorWindow.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_PRIMARY
    editorWindow.BorderSizePixel = 1
    editorWindow.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_PRIMARY
    editorWindow.ZIndex = 101
    editorWindow.Parent = modal
    
    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    windowCorner.Parent = editorWindow
    
    -- Prevent click-through
    editorWindow.MouseButton1Click:Connect(function()
        -- Do nothing to prevent propagation
    end)
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    header.BorderSizePixel = 0
    header.Parent = editorWindow
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    headerCorner.Parent = header
    
    -- Header title
    local titleText = ""
    if mode == "edit" then
        titleText = "✏️ Edit Key: " .. keyName
    elseif mode == "create" then
        titleText = "📝 Create New Key"
    elseif mode == "view" then
        titleText = "👁️ View Key: " .. keyName
    end
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, -60, 1, 0)
    headerTitle.Position = UDim2.new(0, Constants.UI.THEME.SPACING.MEDIUM, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = titleText
    headerTitle.Font = Constants.UI.THEME.FONTS.HEADING
    headerTitle.TextSize = 16
    headerTitle.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.TextYAlignment = Enum.TextYAlignment.Center
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0.5, -15)
    closeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.ERROR
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.Font = Constants.UI.THEME.FONTS.UI
    closeButton.TextSize = 16
    closeButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:closeDataEditor()
    end)
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -110)
    contentArea.Position = UDim2.new(0, 0, 0, 50)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = editorWindow
    
    -- Form fields
    if mode == "create" or mode == "edit" then
        self:createEditForm(contentArea, mode, keyName, dataInfo)
    else
        self:createViewForm(contentArea, keyName, dataInfo)
    end
    
    -- Footer with action buttons
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 60)
    footer.Position = UDim2.new(0, 0, 1, -60)
    footer.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_SECONDARY
    footer.BorderSizePixel = 0
    footer.Parent = editorWindow
    
    local footerCorner = Instance.new("UICorner")
    footerCorner.CornerRadius = UDim.new(0, Constants.UI.THEME.SIZES.BORDER_RADIUS)
    footerCorner.Parent = footer
    
    self:createActionButtons(footer, mode, keyName, dataInfo)
    
    self.activeEditor = {
        modal = modal,
        window = editorWindow,
        mode = mode,
        keyName = keyName,
        dataInfo = dataInfo
    }
end

-- Create edit form
function EditorManager:createEditForm(parent, mode, keyName, dataInfo)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "EditForm"
    scrollFrame.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE * 2, 1, -Constants.UI.THEME.SPACING.MEDIUM * 2)
    scrollFrame.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, Constants.UI.THEME.SPACING.MEDIUM)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
    scrollFrame.Parent = parent
    
    local yOffset = 0
    
    -- Key name field
    local keyNameLabel = Instance.new("TextLabel")
    keyNameLabel.Size = UDim2.new(1, 0, 0, 25)
    keyNameLabel.Position = UDim2.new(0, 0, 0, yOffset)
    keyNameLabel.BackgroundTransparency = 1
    keyNameLabel.Text = "Key Name:"
    keyNameLabel.Font = Constants.UI.THEME.FONTS.UI
    keyNameLabel.TextSize = 14
    keyNameLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    keyNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyNameLabel.Parent = scrollFrame
    
    yOffset = yOffset + 30
    
    local keyNameInput = Instance.new("TextBox")
    keyNameInput.Name = "KeyNameInput"
    keyNameInput.Size = UDim2.new(1, 0, 0, 35)
    keyNameInput.Position = UDim2.new(0, 0, 0, yOffset)
    keyNameInput.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    keyNameInput.BorderSizePixel = 1
    keyNameInput.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    keyNameInput.Text = keyName or ""
    keyNameInput.Font = Constants.UI.THEME.FONTS.BODY
    keyNameInput.TextSize = 13
    keyNameInput.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    keyNameInput.TextXAlignment = Enum.TextXAlignment.Left
    keyNameInput.PlaceholderText = "Enter key name..."
    keyNameInput.Parent = scrollFrame
    
    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 4)
    keyInputCorner.Parent = keyNameInput
    
    yOffset = yOffset + 50
    
    -- Data type selector
    local dataTypeLabel = Instance.new("TextLabel")
    dataTypeLabel.Size = UDim2.new(1, 0, 0, 25)
    dataTypeLabel.Position = UDim2.new(0, 0, 0, yOffset)
    dataTypeLabel.BackgroundTransparency = 1
    dataTypeLabel.Text = "Data Type:"
    dataTypeLabel.Font = Constants.UI.THEME.FONTS.UI
    dataTypeLabel.TextSize = 14
    dataTypeLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    dataTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
    dataTypeLabel.Parent = scrollFrame
    
    yOffset = yOffset + 30
    
    -- Data type buttons
    local dataTypes = {"JSON", "String", "Number", "Boolean"}
    local selectedDataType = "JSON"
    
    for i, dataType in ipairs(dataTypes) do
        local typeButton = Instance.new("TextButton")
        typeButton.Name = dataType .. "Button"
        typeButton.Size = UDim2.new(0.23, -5, 0, 30)
        typeButton.Position = UDim2.new((i-1) * 0.25, 0, 0, yOffset)
        typeButton.BackgroundColor3 = dataType == selectedDataType and Constants.UI.THEME.COLORS.PRIMARY or Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
        typeButton.BorderSizePixel = 1
        typeButton.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        typeButton.Text = dataType
        typeButton.Font = Constants.UI.THEME.FONTS.UI
        typeButton.TextSize = 12
        typeButton.TextColor3 = dataType == selectedDataType and Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY or Constants.UI.THEME.COLORS.TEXT_PRIMARY
        typeButton.Parent = scrollFrame
        
        local typeCorner = Instance.new("UICorner")
        typeCorner.CornerRadius = UDim.new(0, 4)
        typeCorner.Parent = typeButton
        
        typeButton.MouseButton1Click:Connect(function()
            -- Update selection
            for _, child in ipairs(scrollFrame:GetChildren()) do
                if child.Name:match("Button$") then
                    local isSelected = child.Name == dataType .. "Button"
                    child.BackgroundColor3 = isSelected and Constants.UI.THEME.COLORS.PRIMARY or Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
                    child.TextColor3 = isSelected and Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY or Constants.UI.THEME.COLORS.TEXT_PRIMARY
                end
            end
            selectedDataType = dataType
        end)
    end
    
    yOffset = yOffset + 50
    
    -- Data content field
    local dataContentLabel = Instance.new("TextLabel")
    dataContentLabel.Size = UDim2.new(1, 0, 0, 25)
    dataContentLabel.Position = UDim2.new(0, 0, 0, yOffset)
    dataContentLabel.BackgroundTransparency = 1
    dataContentLabel.Text = "Data Content:"
    dataContentLabel.Font = Constants.UI.THEME.FONTS.UI
    dataContentLabel.TextSize = 14
    dataContentLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    dataContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    dataContentLabel.Parent = scrollFrame
    
    yOffset = yOffset + 30
    
    local dataContentInput = Instance.new("TextBox")
    dataContentInput.Name = "DataContentInput"
    dataContentInput.Size = UDim2.new(1, 0, 0, 250)
    dataContentInput.Position = UDim2.new(0, 0, 0, yOffset)
    dataContentInput.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    dataContentInput.BorderSizePixel = 1
    dataContentInput.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    dataContentInput.Text = dataInfo and self:formatDataForEditing(dataInfo.data) or ""
    dataContentInput.Font = Enum.Font.Code
    dataContentInput.TextSize = 12
    dataContentInput.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    dataContentInput.TextXAlignment = Enum.TextXAlignment.Left
    dataContentInput.TextYAlignment = Enum.TextYAlignment.Top
    dataContentInput.TextWrapped = true
    dataContentInput.MultiLine = true
    dataContentInput.ClearTextOnFocus = false
    dataContentInput.PlaceholderText = "Enter data content..."
    dataContentInput.Parent = scrollFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 4)
    contentCorner.Parent = dataContentInput
    
    -- Update canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 260)
end

-- Create view form
function EditorManager:createViewForm(parent, keyName, dataInfo)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ViewForm"
    scrollFrame.Size = UDim2.new(1, -Constants.UI.THEME.SPACING.LARGE * 2, 1, -Constants.UI.THEME.SPACING.MEDIUM * 2)
    scrollFrame.Position = UDim2.new(0, Constants.UI.THEME.SPACING.LARGE, 0, Constants.UI.THEME.SPACING.MEDIUM)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    scrollFrame.Parent = parent
    
    local yOffset = 0
    
    -- Key info
    local keyInfoLabel = Instance.new("TextLabel")
    keyInfoLabel.Size = UDim2.new(1, 0, 0, 30)
    keyInfoLabel.Position = UDim2.new(0, 0, 0, yOffset)
    keyInfoLabel.BackgroundTransparency = 1
    keyInfoLabel.Text = "Key: " .. keyName
    keyInfoLabel.Font = Constants.UI.THEME.FONTS.HEADING
    keyInfoLabel.TextSize = 16
    keyInfoLabel.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    keyInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyInfoLabel.Parent = scrollFrame
    
    yOffset = yOffset + 40
    
    -- Data display
    local dataDisplay = Instance.new("TextBox")
    dataDisplay.Size = UDim2.new(1, 0, 0, 300)
    dataDisplay.Position = UDim2.new(0, 0, 0, yOffset)
    dataDisplay.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
    dataDisplay.BorderSizePixel = 1
    dataDisplay.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
    dataDisplay.Text = dataInfo and self:formatDataForEditing(dataInfo.data) or ""
    dataDisplay.Font = Enum.Font.Code
    dataDisplay.TextSize = 12
    dataDisplay.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
    dataDisplay.TextXAlignment = Enum.TextXAlignment.Left
    dataDisplay.TextYAlignment = Enum.TextYAlignment.Top
    dataDisplay.TextWrapped = true
    dataDisplay.MultiLine = true
    dataDisplay.TextEditable = false
    dataDisplay.Parent = scrollFrame
    
    local displayCorner = Instance.new("UICorner")
    displayCorner.CornerRadius = UDim.new(0, 4)
    displayCorner.Parent = dataDisplay
end

-- Create action buttons
function EditorManager:createActionButtons(footer, mode, keyName, dataInfo)
    if mode == "view" then
        -- Close button only for view mode
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 100, 0, 35)
        closeButton.Position = UDim2.new(1, -120, 0.5, -17)
        closeButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
        closeButton.BorderSizePixel = 1
        closeButton.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        closeButton.Text = "Close"
        closeButton.Font = Constants.UI.THEME.FONTS.UI
        closeButton.TextSize = 13
        closeButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        closeButton.Parent = footer
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 4)
        closeCorner.Parent = closeButton
        
        closeButton.MouseButton1Click:Connect(function()
            self:closeDataEditor()
        end)
    else
        -- Save and Cancel buttons for edit/create mode
        local cancelButton = Instance.new("TextButton")
        cancelButton.Size = UDim2.new(0, 100, 0, 35)
        cancelButton.Position = UDim2.new(1, -230, 0.5, -17)
        cancelButton.BackgroundColor3 = Constants.UI.THEME.COLORS.BACKGROUND_TERTIARY
        cancelButton.BorderSizePixel = 1
        cancelButton.BorderColor3 = Constants.UI.THEME.COLORS.BORDER_SECONDARY
        cancelButton.Text = "Cancel"
        cancelButton.Font = Constants.UI.THEME.FONTS.UI
        cancelButton.TextSize = 13
        cancelButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_PRIMARY
        cancelButton.Parent = footer
        
        local cancelCorner = Instance.new("UICorner")
        cancelCorner.CornerRadius = UDim.new(0, 4)
        cancelCorner.Parent = cancelButton
        
        local saveButton = Instance.new("TextButton")
        saveButton.Size = UDim2.new(0, 100, 0, 35)
        saveButton.Position = UDim2.new(1, -120, 0.5, -17)
        saveButton.BackgroundColor3 = Constants.UI.THEME.COLORS.SUCCESS
        saveButton.BorderSizePixel = 0
        saveButton.Text = mode == "create" and "Create" or "Save"
        saveButton.Font = Constants.UI.THEME.FONTS.UI
        saveButton.TextSize = 13
        saveButton.TextColor3 = Constants.UI.THEME.COLORS.TEXT_ON_PRIMARY
        saveButton.Parent = footer
        
        local saveCorner = Instance.new("UICorner")
        saveCorner.CornerRadius = UDim.new(0, 4)
        saveCorner.Parent = saveButton
        
        -- Button handlers
        cancelButton.MouseButton1Click:Connect(function()
            self:closeDataEditor()
        end)
        
        saveButton.MouseButton1Click:Connect(function()
            self:saveEditorData()
        end)
    end
end

-- Format data for editing
function EditorManager:formatDataForEditing(data)
    if type(data) == "table" then
        -- Simple JSON formatting
        local function formatValue(value, indent)
            indent = indent or 0
            local indentStr = string.rep("  ", indent)
            
            if type(value) == "table" then
                if #value > 0 then
                    -- Array
                    local lines = {"["}
                    for i, v in ipairs(value) do
                        local formattedValue = formatValue(v, indent + 1)
                        lines[#lines + 1] = "  " .. indentStr .. formattedValue .. (i == #value and "" or ",")
                    end
                    lines[#lines + 1] = indentStr .. "]"
                    return table.concat(lines, "\n")
                else
                    -- Object
                    local lines = {"{"}
                    local keys = {}
                    for k in pairs(value) do
                        table.insert(keys, k)
                    end
                    table.sort(keys)
                    
                    for i, k in ipairs(keys) do
                        local formattedValue = formatValue(value[k], indent + 1)
                        lines[#lines + 1] = "  " .. indentStr .. '"' .. k .. '": ' .. formattedValue .. (i == #keys and "" or ",")
                    end
                    lines[#lines + 1] = indentStr .. "}"
                    return table.concat(lines, "\n")
                end
            elseif type(value) == "string" then
                return '"' .. value .. '"'
            else
                return tostring(value)
            end
        end
        
        return formatValue(data)
    else
        return tostring(data)
    end
end

-- Save editor data
function EditorManager:saveEditorData()
    if not self.activeEditor then
        return
    end
    
    debugLog("Saving editor data...")
    
    if self.uiManager.notificationManager then
        self.uiManager.notificationManager:showNotification("💾 Data saved successfully!", "SUCCESS")
    end
    
    self:closeDataEditor()
end

-- Close data editor
function EditorManager:closeDataEditor()
    if self.editorModal then
        self.editorModal:Destroy()
        self.editorModal = nil
    end
    
    self.activeEditor = nil
    debugLog("Data editor closed")
end

-- Edit selected key
function EditorManager:editSelectedKey()
    debugLog("Edit selected key requested")
    if self.uiManager.dataExplorerManager and self.uiManager.dataExplorerManager.selectedKey then
        self:openDataEditor("edit", self.uiManager.dataExplorerManager.selectedKey, {data = {}})
    else
        if self.uiManager.notificationManager then
            self.uiManager.notificationManager:showNotification("❌ Please select a key first!", "ERROR")
        end
    end
end

-- Create new key
function EditorManager:createNewKey()
    debugLog("Create new key requested")
    self:openDataEditor("create", nil, nil)
end

-- Delete selected key
function EditorManager:deleteSelectedKey()
    debugLog("Delete selected key requested")
    if self.uiManager.dataExplorerManager and self.uiManager.dataExplorerManager.selectedKey then
        if self.uiManager.notificationManager then
            self.uiManager.notificationManager:showNotification("🗑️ Key deleted: " .. self.uiManager.dataExplorerManager.selectedKey, "SUCCESS")
        end
    else
        if self.uiManager.notificationManager then
            self.uiManager.notificationManager:showNotification("❌ Please select a key first!", "ERROR")
        end
    end
end

return EditorManager 