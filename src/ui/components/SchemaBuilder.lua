local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local UI = Framework.UI
local Button = UI.Button
local TextInput = UI.TextInput
local SelectInput = UI.SelectInput
local Checkbox = UI.Checkbox
local TreeView = UI.TreeView
local DragSource = UI.DragSource
local DropTarget = UI.DropTarget

local SchemaBuilder = Roact.PureComponent:extend("SchemaBuilder")

function SchemaBuilder:init()
    self.state = {
        schemaName = "",
        schemaVersion = "1.0.0",
        selectedNode = nil,
        schemaTree = {
            type = "object",
            properties = {}
        }
    }

    self.onSchemaNameChange = function(newName)
        self:setState({
            schemaName = newName
        })
    end

    self.onSchemaVersionChange = function(newVersion)
        self:setState({
            schemaVersion = newVersion
        })
    end

    self.onNodeSelect = function(node)
        self:setState({
            selectedNode = node
        })
    end

    self.onAddProperty = function(parentPath)
        local newProperty = {
            name = "newProperty",
            type = "string",
            required = false
        }
        
        self:updateSchemaTree(function(tree)
            local parent = self:getNodeByPath(tree, parentPath)
            if parent then
                parent.properties = parent.properties or {}
                parent.properties[newProperty.name] = {
                    type = newProperty.type,
                    required = newProperty.required
                }
            end
            return tree
        end)
    end

    self.onRemoveProperty = function(path)
        self:updateSchemaTree(function(tree)
            local parentPath = self:getParentPath(path)
            local propertyName = self:getLastPathSegment(path)
            local parent = self:getNodeByPath(tree, parentPath)
            if parent and parent.properties then
                parent.properties[propertyName] = nil
            end
            return tree
        end)
    end

    self.onPropertyChange = function(path, field, value)
        self:updateSchemaTree(function(tree)
            local node = self:getNodeByPath(tree, path)
            if node then
                node[field] = value
            end
            return tree
        end)
    end

    self.onSaveSchema = function()
        local schema = self.state.schemaTree
        self.props.onSaveSchema(self.state.schemaName, schema, self.state.schemaVersion)
    end
end

function SchemaBuilder:getNodeByPath(tree, path)
    if not path or path == "" then
        return tree
    end

    local segments = string.split(path, ".")
    local current = tree

    for _, segment in ipairs(segments) do
        if current.properties and current.properties[segment] then
            current = current.properties[segment]
        else
            return nil
        end
    end

    return current
end

function SchemaBuilder:getParentPath(path)
    local segments = string.split(path, ".")
    table.remove(segments)
    return table.concat(segments, ".")
end

function SchemaBuilder:getLastPathSegment(path)
    local segments = string.split(path, ".")
    return segments[#segments]
end

function SchemaBuilder:updateSchemaTree(updateFn)
    self:setState(function(state)
        return {
            schemaTree = updateFn(state.schemaTree)
        }
    end)
end

function SchemaBuilder:renderPropertyEditor(node, path)
    if not node then return nil end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundTransparency = 1,
        LayoutOrder = 2
    }, {
        Layout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),

        TypeSelector = Roact.createElement(SelectInput, {
            Label = "Type",
            Options = {
                {Text = "String", Value = "string"},
                {Text = "Number", Value = "number"},
                {Text = "Boolean", Value = "boolean"},
                {Text = "Object", Value = "object"},
                {Text = "Array", Value = "array"}
            },
            SelectedValue = node.type,
            OnChanged = function(value)
                self.onPropertyChange(path, "type", value)
            end
        }),

        RequiredCheckbox = Roact.createElement(Checkbox, {
            Label = "Required",
            Checked = node.required,
            OnChanged = function(value)
                self.onPropertyChange(path, "required", value)
            end
        }),

        DescriptionInput = Roact.createElement(TextInput, {
            Label = "Description",
            Text = node.description or "",
            OnChanged = function(value)
                self.onPropertyChange(path, "description", value)
            end
        }),

        Constraints = self:renderConstraints(node, path)
    })
end

function SchemaBuilder:renderConstraints(node, path)
    local constraints = {}
    local layoutOrder = 1

    if node.type == "string" then
        constraints.MinLength = Roact.createElement(TextInput, {
            Label = "Min Length",
            Text = tostring(node.minLength or ""),
            OnChanged = function(value)
                self.onPropertyChange(path, "minLength", tonumber(value))
            end,
            LayoutOrder = layoutOrder
        })
        layoutOrder = layoutOrder + 1

        constraints.MaxLength = Roact.createElement(TextInput, {
            Label = "Max Length",
            Text = tostring(node.maxLength or ""),
            OnChanged = function(value)
                self.onPropertyChange(path, "maxLength", tonumber(value))
            end,
            LayoutOrder = layoutOrder
        })
        layoutOrder = layoutOrder + 1

        constraints.Pattern = Roact.createElement(TextInput, {
            Label = "Pattern",
            Text = node.pattern or "",
            OnChanged = function(value)
                self.onPropertyChange(path, "pattern", value)
            end,
            LayoutOrder = layoutOrder
        })
    elseif node.type == "number" then
        constraints.Min = Roact.createElement(TextInput, {
            Label = "Min",
            Text = tostring(node.min or ""),
            OnChanged = function(value)
                self.onPropertyChange(path, "min", tonumber(value))
            end,
            LayoutOrder = layoutOrder
        })
        layoutOrder = layoutOrder + 1

        constraints.Max = Roact.createElement(TextInput, {
            Label = "Max",
            Text = tostring(node.max or ""),
            OnChanged = function(value)
                self.onPropertyChange(path, "max", tonumber(value))
            end,
            LayoutOrder = layoutOrder
        })
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundTransparency = 1,
        LayoutOrder = 4
    }, {
        Layout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        Constraints = constraints
    })
end

function SchemaBuilder:renderTreeView()
    local function renderNode(node, path)
        local children = {}
        
        if node.properties then
            for name, property in pairs(node.properties) do
                local childPath = path == "" and name or path .. "." .. name
                children[name] = renderNode(property, childPath)
            end
        end

        return {
            Text = path == "" and "Root" or name,
            Children = children,
            OnClick = function()
                self.onNodeSelect(path)
            end
        }
    end

    return Roact.createElement(TreeView, {
        Size = UDim2.new(0.3, 0, 1, 0),
        Tree = renderNode(self.state.schemaTree, ""),
        OnNodeSelect = self.onNodeSelect
    })
end

function SchemaBuilder:render()
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    }, {
        Layout = Roact.createElement("UIGridLayout", {
            CellSize = UDim2.new(1, 0, 1, 0),
            CellPadding = UDim2.new(0, 10, 0, 10)
        }),

        Header = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, {
            Layout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10)
            }),

            NameInput = Roact.createElement(TextInput, {
                Label = "Schema Name",
                Text = self.state.schemaName,
                OnChanged = self.onSchemaNameChange,
                Size = UDim2.new(0.3, 0, 1, 0)
            }),

            VersionInput = Roact.createElement(TextInput, {
                Label = "Version",
                Text = self.state.schemaVersion,
                OnChanged = self.onSchemaVersionChange,
                Size = UDim2.new(0.2, 0, 1, 0)
            }),

            SaveButton = Roact.createElement(Button, {
                Text = "Save Schema",
                OnClick = self.onSaveSchema,
                Size = UDim2.new(0.1, 0, 1, 0)
            })
        }),

        Content = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, -50),
            BackgroundTransparency = 1,
            LayoutOrder = 2
        }, {
            Layout = Roact.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10)
            }),

            TreeView = self:renderTreeView(),

            PropertyEditor = self:renderPropertyEditor(
                self.state.selectedNode and self:getNodeByPath(self.state.schemaTree, self.state.selectedNode),
                self.state.selectedNode
            )
        })
    })
end

return withContext({
    Theme = ContextServices.Theme,
    Localization = ContextServices.Localization
})(SchemaBuilder) 