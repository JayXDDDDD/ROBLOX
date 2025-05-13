-- UI Module
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local ui = {
    windowCount = 0,
    gui = nil,
}

-- Helper to create instances with a properties table
function ui.newInstance(class, props)
    local obj = Instance.new(class)
    for prop, value in pairs(props) do
        if prop ~= "Parent" then
            obj[prop] = value
        end
    end
    obj.Parent = props.Parent
    return obj
end

-- DRAGGER: makes a frame draggable by its header
ui.dragger = {}
function ui.dragger.bind(frame)
    frame.Active = true
    local mouse      = Players.LocalPlayer:GetMouse()
    local heartBeat  = RunService.Heartbeat
    local isDragging

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            local offset = Vector2.new(
                mouse.X - frame.AbsolutePosition.X,
                mouse.Y - frame.AbsolutePosition.Y
            )

            -- Move as long as mouse is down
            local conn
            conn = heartBeat:Connect(function()
                if isDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    local newX = mouse.X - offset.X + frame.Size.X.Offset * frame.AnchorPoint.X
                    local newY = mouse.Y - offset.Y + frame.Size.Y.Offset * frame.AnchorPoint.Y
                    frame:TweenPosition(
                        UDim2.new(0, newX, 0, newY),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quad,
                        0.1,
                        true
                    )
                else
                    isDragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)
end

-- RESIZER: keeps a content frame in sync with its parent’s height
ui.resizer = {}
function ui.resizer.bind(parentFrame, targetFrame)
    parentFrame:GetPropertyChangedSignal("AbsoluteSize")
        :Connect(function()
            local parentH = parentFrame.AbsoluteSize.Y
            local xScale, xOffset, yScale = targetFrame.Size.X.Scale, targetFrame.Size.X.Offset, targetFrame.Size.Y.Scale
            targetFrame.Size = UDim2.new(xScale, xOffset, yScale, parentH)
        end)
end

-- Default style settings
local defaults = {
    txtColor      = Color3.fromRGB(255,255,255),
    underline     = Color3.fromRGB(0,255,140),
    barColor      = Color3.fromRGB(40,40,40),
    bgColor       = Color3.fromRGB(30,30,30),
    boxColor      = Color3.fromRGB(50,50,50),
}

-- CREATE WINDOW
function ui:CreateWindow(opts)
    assert(opts.text, "Window must have a title")
    opts = setmetatable(opts or {}, { __index = defaults })
    self.windowCount = self.windowCount + 1

    -- Ensure a single ScreenGui parent
    if not self.gui then
        self.gui = self:newInstance("ScreenGui", {
            Name   = "UI_"..tostring(math.random(1e8,1e9)),
            Parent = game.CoreGui,
        })
    end

    -- Main window frame
    local window = {
        toggles = {},
        isClosed = false,
        count = 0,
    }

    local header = self:newInstance("Frame", {
        Name              = opts.text,
        Parent            = self.gui,
        Active            = true,
        BackgroundColor3  = opts.barColor,
        Size              = UDim2.new(0, 190, 0, 30),
        Position          = UDim2.new(0, 15 + 200*(self.windowCount-1), 0, 15),
        BorderSizePixel   = 0,
    })

    -- Title label
    self:newInstance("TextLabel", {
        Parent           = header,
        Size             = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text             = opts.text,
        TextColor3       = opts.txtColor,
        TextSize         = 17,
        Font             = Enum.Font.SourceSansSemibold,
        Name             = "Title",
    })

    -- Toggle button (collapse/expand)
    local toggleBtn = self:newInstance("TextButton", {
        Parent           = header,
        Name             = "Toggle",
        Size             = UDim2.new(0,25,1,0),
        Position         = UDim2.new(1,-25,0,0),
        BackgroundTransparency = 1,
        Text             = "-",
        TextSize         = 17,
        Font             = Enum.Font.SourceSans,
        TextColor3       = opts.txtColor,
    })

    -- Underline
    self:newInstance("Frame", {
        Parent           = header,
        Size             = UDim2.new(1,0,0,1),
        Position         = UDim2.new(0,0,1,-1),
        BackgroundColor3 = opts.underline,
        BorderSizePixel  = 0,
    })

    -- Background & container
    local background = self:newInstance("Frame", {
        Parent           = header,
        Name             = "Background",
        BackgroundColor3 = opts.bgColor,
        Position         = UDim2.new(0,0,1,0),
        Size             = UDim2.new(1,0,0,25),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })

    local container = self:newInstance("Frame", {
        Parent           = background,
        Name             = "Container",
        BackgroundColor3 = opts.bgColor,
        Size             = UDim2.new(1,0,1,0),
        BorderSizePixel  = 0,
    })

    -- Layout & padding
    self:newInstance("UIListLayout", { Parent = container, SortOrder = Enum.SortOrder.LayoutOrder })
    self:newInstance("UIPadding", {
        Parent     = container,
        PaddingLeft = UDim.new(0,10),
        PaddingTop  = UDim.new(0,5),
    })

    -- Enable dragging & resizing
    ui.dragger.bind(header)
    ui.resizer.bind(background, container)

    -- Utility to recalc container height
    local function recalcHeight()
        local totalY = 0
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                totalY = totalY + child.AbsoluteSize.Y
            end
        end
        return UDim2.new(1, 0, 0, totalY + 10)
    end

    function window:resize(animate, sizeOverride)
        local targetSize = sizeOverride or recalcHeight()
        if animate then
            background:TweenSize(targetSize, Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.5, true)
        else
            background.Size = targetSize
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        window.isClosed = not window.isClosed
        toggleBtn.Text = window.isClosed and "+" or "-"
        window:resize(true, window.isClosed and UDim2.new(1,0,0,0) or nil)
    end)

    ---- Public API: AddToggle, AddButton, AddLabel, etc. ----

    function window:AddToggle(labelText, callback)
        self.count = self.count + 1
        callback = callback or function() end

        local row = Instance.new("Frame", container)
        row.Size = UDim2.new(1,0,0,20)
        row.BackgroundTransparency = 1
        row.LayoutOrder = self.count

        local label = self:newInstance("TextLabel", {
            Parent = row,
            Text   = labelText,
            Size   = UDim2.new(1,-40,1,0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3     = opts.txtColor,
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            TextSize = 16,
        })

        local btn = self:newInstance("TextButton", {
            Parent = row,
            Text   = "OFF",
            Size   = UDim2.new(0,40,1,0),
            Position = UDim2.new(1,-40,0,0),
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSansSemibold,
            TextSize = 16,
            TextColor3 = Color3.fromRGB(255,25,25),
        })

        btn.MouseButton1Click:Connect(function()
            self.toggles[labelText] = not self.toggles[labelText]
            btn.Text = self.toggles[labelText] and "ON" or "OFF"
            btn.TextColor3 = self.toggles[labelText]
                and Color3.fromRGB(0,255,140)
                or Color3.fromRGB(255,25,25)
            callback(self.toggles[labelText])
            window:resize()
        end)

        window:resize()
        return btn
    end

    function window:AddButton(text, callback)
        self.count = self.count + 1
        callback = callback or function() end

        local btn = self:newInstance("TextButton", {
            Parent = container,
            Text   = text,
            Size   = UDim2.new(1,-20,0,25),
            LayoutOrder = self.count,
            BackgroundColor3 = Color3.fromRGB(65,65,65),
            BorderSizePixel = 0,
            TextColor3 = opts.txtColor,
            Font = Enum.Font.SourceSans,
            TextSize = 16,
        })

        btn.MouseButton1Click:Connect(function()
            callback()
            window:resize()
        end)

        window:resize()
        return btn
    end

    function window:AddLabel(text)
        self.count = self.count + 1
        local label = self:newInstance("TextLabel", {
            Parent = container,
            Text   = text,
            Size   = UDim2.new(1,-20,0,20),
            LayoutOrder = self.count,
            BackgroundTransparency = 1,
            TextColor3 = opts.txtColor,
            Font = Enum.Font.SourceSans,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        window:resize()
        return label
    end

    -- (Similarly, you can add AddBox, AddDestroy, AddDropdown, etc. following the above patterns.)

    return window
end

return ui
