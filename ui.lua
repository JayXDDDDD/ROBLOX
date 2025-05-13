local UI = {
	WindowCount = 0,
	Defaults = {
		TxtColor = Color3.fromRGB(255, 255, 255),
		Underline = Color3.fromRGB(0, 255, 140),
		BarColor = Color3.fromRGB(40, 40, 40),
		BgColor = Color3.fromRGB(30, 30, 30),
		BoxColor = Color3.fromRGB(50, 50, 50)
	}
}

local Dragger = {}
local Resizer = {}

do -- Input handlers
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Mouse = game.Players.LocalPlayer:GetMouse()

	local function UpdateFramePosition(frame, input)
		local dragStart = input.Position
		local startPos = frame.Position
		local connection
		
		connection = RunService.Heartbeat:Connect(function()
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				local delta = dragStart - Vector2.new(Mouse.X, Mouse.Y)
				frame.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset - delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset - delta.Y
				)
			else
				connection:Disconnect()
			end
		end)
	end

	function Dragger.New(frame)
		frame.Active = true
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				UpdateFramePosition(frame, input)
			end
		end)
	end

	function Resizer.New(parent, child)
		parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, parent.AbsoluteSize.Y)
		end)
	end
end

function UI:Create(class, properties)
	local instance = Instance.new(class)
	for prop, value in pairs(properties) do
		if prop ~= "Parent" then
			instance[prop] = value
		end
	end
	instance.Parent = properties.Parent
	return instance
end

function UI:CreateWindow(options)
	assert(options.Text, "Window must have a name")
	local config = setmetatype(options, {__index = UI.Defaults})
	
	self.WindowCount += 1
	self.Gui = self.Gui or self:Create("ScreenGui", {
		Name = "UI_"..tostring(os.time()),
		Parent = game.CoreGui
	})
	
	local window = {
		Count = 0,
		Toggles = {},
		Closed = false,
		Elements = {}
	}
	
	window.Frame = self:Create("Frame", {
		Name = options.Text,
		Parent = self.Gui,
		Size = UDim2.new(0, 190, 0, 30),
		Position = UDim2.new(0, 15 + (200 * (self.WindowCount - 1)), 0, 15),
		BackgroundColor3 = config.BarColor,
		BorderSizePixel = 0
	})
	
	window.Background = self:Create("Frame", {
		Name = "Background",
		Parent = window.Frame,
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = config.BgColor,
		ClipsDescendants = true
	})
	
	window.Container = self:Create("Frame", {
		Name = "Container",
		Parent = window.Background,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1
	})
	
	window.Layout = self:Create("UIListLayout", {
		Parent = window.Container,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	})
	
	window.Padding = self:Create("UIPadding", {
		Parent = window.Container,
		PaddingLeft = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5)
	})
	
	self:Create("Frame", {
		Parent = window.Frame,
		Name = "Underline",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = config.Underline
	})
	
	local toggleButton = self:Create("TextButton", {
		Parent = window.Frame,
		Text = "-",
		Size = UDim2.new(0, 25, 1, 0),
		Position = UDim2.new(1, -25, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = config.TxtColor
	})
	
	toggleButton.MouseButton1Click:Connect(function()
		window.Closed = not window.Closed
		toggleButton.Text = window.Closed and "+" or "-"
		window.Background:TweenSize(
			window.Closed and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, window.Container.AbsoluteSize.Y + 10),
			Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.5
		)
	end)
	
	self:Create("TextLabel", {
		Parent = window.Frame,
		Text = options.Text,
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = config.TxtColor,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	Dragger.New(window.Frame)
	Resizer.New(window.Background, window.Container)
	
	function window:AddToggle(text, callback)
		self.Count += 1
		local toggle = self:CreateElement("TextLabel", {
			Text = text,
			Size = UDim2.new(1, -10, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Left
		})
		
		local stateButton = self:Create("TextButton", {
			Parent = toggle,
			Text = "OFF",
			Size = UDim2.new(0, 25, 1, 0),
			Position = UDim2.new(1, -25, 0, 0),
			TextColor3 = Color3.fromRGB(255, 25, 25)
		})
		
		stateButton.MouseButton1Click:Connect(function()
			self.Toggles[text] = not self.Toggles[text]
			stateButton.Text = self.Toggles[text] and "ON" or "OFF"
			stateButton.TextColor3 = self.Toggles[text] and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 25, 25)
			if callback then callback(self.Toggles[text]) end
		end)
		
		return stateButton
	end
	
	function window:AddButton(text, callback)
		self.Count += 1
		local button = self:CreateElement("TextButton", {
			Text = text,
			BackgroundColor3 = Color3.fromRGB(65, 65, 65),
			Size = UDim2.new(1, -10, 0, 25)
		})
		
		button.MouseButton1Click:Connect(function()
			if callback then callback() end
		end)
		
		return button
	end
	
	function window:CreateElement(type, props)
		props.Parent = props.Parent or window.Container
		props.LayoutOrder = self.Count
		props.BackgroundTransparency = props.BackgroundTransparency or 0.75
		props.TextColor3 = props.TextColor3 or UI.Defaults.TxtColor
		props.BorderSizePixel = 0
		return self:Create(type, props)
	end
	
	return window
end

return UI
