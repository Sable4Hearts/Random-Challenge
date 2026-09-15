--=====================================================================
--  AuraUI  ·  Single-file premium Roblox UI library
--  Author: AuraUI  |  No external dependencies
--  Drop into a LocalScript / ModuleScript and call Library:CreateWindow()
--=====================================================================

--=====================================================================
-- // SERVICES
--=====================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--=====================================================================
-- // CONFIG  (change these to restyle the whole library)
--=====================================================================
local Config = {
	Title          = "Aura",
	Subtitle       = "v1.0  ·  premium suite",

	WindowSize     = Vector2.new(660, 440),
	MinWindowSize  = Vector2.new(520, 340),
	MaxWindowSize  = Vector2.new(1280, 820),
	Resizable      = true,

	ToggleKey      = Enum.KeyCode.RightShift,

	Font           = Enum.Font.GothamMedium,
	FontBold       = Enum.Font.GothamBold,

	CornerRadius   = UDim.new(0, 10),
	ElementCorner  = UDim.new(0, 6),
	ElementHeight  = 32,
	RowPadding     = 6,

	AnimationSpeed = 0.18,
	EasingStyle    = Enum.EasingStyle.Quint,
	EasingDir      = Enum.EasingDirection.Out,

	ThemeName      = "Midnight",
	SaveSettings   = true,
	SettingsFile   = "AuraUI_Settings.json",
}

--=====================================================================
-- // THEMES
--=====================================================================
local Themes = {
	Midnight = {
		Accent       = Color3.fromRGB(99, 102, 241),
		Window       = Color3.fromRGB(18, 18, 24),
		Topbar       = Color3.fromRGB(24, 24, 32),
		Sidebar      = Color3.fromRGB(15, 15, 20),
		Section      = Color3.fromRGB(24, 24, 32),
		Element      = Color3.fromRGB(33, 33, 43),
		ElementHover = Color3.fromRGB(44, 44, 58),
		Text         = Color3.fromRGB(240, 240, 248),
		SubText      = Color3.fromRGB(150, 150, 168),
		Outline      = Color3.fromRGB(48, 48, 62),
		Off          = Color3.fromRGB(58, 58, 74),
	},
	Dark = {
		Accent       = Color3.fromRGB(0, 170, 255),
		Window       = Color3.fromRGB(26, 26, 26),
		Topbar       = Color3.fromRGB(32, 32, 32),
		Sidebar      = Color3.fromRGB(20, 20, 20),
		Section      = Color3.fromRGB(33, 33, 33),
		Element      = Color3.fromRGB(42, 42, 42),
		ElementHover = Color3.fromRGB(52, 52, 52),
		Text         = Color3.fromRGB(238, 238, 238),
		SubText      = Color3.fromRGB(150, 150, 150),
		Outline      = Color3.fromRGB(55, 55, 55),
		Off          = Color3.fromRGB(70, 70, 70),
	},
	Light = {
		Accent       = Color3.fromRGB(0, 122, 255),
		Window       = Color3.fromRGB(244, 245, 248),
		Topbar       = Color3.fromRGB(255, 255, 255),
		Sidebar      = Color3.fromRGB(235, 236, 240),
		Section      = Color3.fromRGB(255, 255, 255),
		Element      = Color3.fromRGB(240, 241, 245),
		ElementHover = Color3.fromRGB(228, 230, 236),
		Text         = Color3.fromRGB(24, 24, 30),
		SubText      = Color3.fromRGB(110, 112, 124),
		Outline      = Color3.fromRGB(214, 216, 224),
		Off          = Color3.fromRGB(200, 202, 210),
	},
	Ocean = {
		Accent       = Color3.fromRGB(0, 200, 190),
		Window       = Color3.fromRGB(12, 26, 34),
		Topbar       = Color3.fromRGB(16, 34, 44),
		Sidebar      = Color3.fromRGB(10, 22, 30),
		Section      = Color3.fromRGB(17, 36, 47),
		Element      = Color3.fromRGB(23, 48, 62),
		ElementHover = Color3.fromRGB(30, 62, 80),
		Text         = Color3.fromRGB(226, 248, 250),
		SubText      = Color3.fromRGB(130, 175, 186),
		Outline      = Color3.fromRGB(32, 66, 84),
		Off          = Color3.fromRGB(40, 72, 88),
	},
	Bloodmoon = {
		Accent       = Color3.fromRGB(220, 40, 60),
		Window       = Color3.fromRGB(22, 14, 16),
		Topbar       = Color3.fromRGB(30, 18, 21),
		Sidebar      = Color3.fromRGB(18, 11, 13),
		Section      = Color3.fromRGB(30, 19, 22),
		Element      = Color3.fromRGB(42, 26, 30),
		ElementHover = Color3.fromRGB(56, 34, 40),
		Text         = Color3.fromRGB(248, 232, 235),
		SubText      = Color3.fromRGB(180, 140, 148),
		Outline      = Color3.fromRGB(62, 36, 42),
		Off          = Color3.fromRGB(70, 44, 50),
	},
}

--=====================================================================
-- // LIBRARY CORE
--=====================================================================
local Library = {}
Library.__index = Library
Library.Theme     = Themes[Config.ThemeName]
Library.Flags     = {}        -- flag -> current value
Library.Options   = {}        -- flag -> setter function
Library._bindings = {}        -- {i = instance, p = property, r = themeRole}
Library._callbacks = {}       -- functions called on theme change
Library.Windows   = {}

--=====================================================================
-- // UTILITIES
--=====================================================================
local function new(class, props)
	local inst = Instance.new(class)
	local parent = props and props.Parent
	if props then
		for k, v in next, props do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function tw(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time or Config.AnimationSpeed, style or Config.EasingStyle, dir or Config.EasingDir),
		props
	)
	t:Play()
	return t
end

local function bind(instance, prop, role)
	instance[prop] = Library.Theme[role]
	table.insert(Library._bindings, { i = instance, p = prop, r = role })
	return instance
end

local function round(n, step)
	if not step or step <= 0 then return n end
	return math.floor(n / step + 0.5) * step
end

local function parentGui(gui)
	local ok = false
	if gethui then ok = pcall(function() gui.Parent = gethui() end) end
	if not ok or not gui.Parent then
		ok = pcall(function() gui.Parent = CoreGui end)
	end
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

--=====================================================================
-- // SETTINGS PERSISTENCE
--=====================================================================
Library.LoadedFlags = {}
local LoadedTheme, LoadedKey

local function serialise(v)
	if typeof(v) == "Color3" then
		return { __t = "Color3", v:ToHex() }
	elseif typeof(v) == "EnumItem" then
		return { __t = "Enum", e = tostring(v.EnumType), n = v.Name }
	end
	return v
end

local function deserialise(v)
	if type(v) == "table" and v.__t == "Color3" then
		return Color3.fromHex(v.v)
	elseif type(v) == "table" and v.__t == "Enum" then
		local ok, enum = pcall(function() return Enum[v.e] end)
		if ok and enum then
			local ok2, item = pcall(function() return enum[v.n] end)
			if ok2 then return item end
		end
	end
	return v
end

local function saveSettings()
	if not Config.SaveSettings then return end
	if not writefile then return end
	local data = { Flags = {}, Theme = Config.ThemeName, ToggleKey = Config.ToggleKey.Name }
	for k, v in pairs(Library.Flags) do
		data.Flags[k] = serialise(v)
	end
	pcall(function()
		writefile(Config.SettingsFile, HttpService:JSONEncode(data))
	end)
end

local saveQueued = false
local function queueSave()
	if saveQueued then return end
	saveQueued = true
	task.delay(1, function()
		saveQueued = false
		saveSettings()
	end)
end

local function loadSettings()
	if not Config.SaveSettings then return end
	if not (isfile and readfile) then return end
	local ok, content = pcall(function()
		if isfile(Config.SettingsFile) then return readfile(Config.SettingsFile) end
	end)
	if not ok or not content then return end
	local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
	if not ok2 or type(data) ~= "table" then return end
	if data.Theme and Themes[data.Theme] then
		Config.ThemeName = data.Theme
		Library.Theme = Themes[data.Theme]
	end
	if data.ToggleKey then
		local ok3, key = pcall(function() return Enum.KeyCode[data.ToggleKey] end)
		if ok3 and key then Config.ToggleKey = key end
	end
	if type(data.Flags) == "table" then
		for k, v in pairs(data.Flags) do
			Library.LoadedFlags[k] = deserialise(v)
		end
	end
end

loadSettings()

--=====================================================================
-- // THEME API
--=====================================================================
function Library:SetTheme(name)
	local t = Themes[name]
	if not t then return end
	Config.ThemeName = name
	self.Theme = t
	for i = #self._bindings, 1, -1 do
		local b = self._bindings[i]
		if b.i and b.i.Parent then
			pcall(function() b.i[b.p] = t[b.r] end)
		else
			table.remove(self._bindings, i)
		end
	end
	for _, cb in ipairs(self._callbacks) do
		pcall(cb, t)
	end
	queueSave()
end

function Library:SetAccent(color)
	Themes[Config.ThemeName].Accent = color
	self:SetTheme(Config.ThemeName)
end

function Library:GetThemeList()
	local list = {}
	for name in pairs(Themes) do table.insert(list, name) end
	table.sort(list)
	return list
end

--=====================================================================
-- // FLAG API
--=====================================================================
function Library:SetFlag(flag, value)
	self.Flags[flag] = value
	local setter = self.Options[flag]
	if setter then pcall(setter, value) end
	queueSave()
end

function Library:GetFlag(flag)
	return self.Flags[flag]
end

--=====================================================================
-- // NOTIFICATIONS
--=====================================================================
local NotifyGui = new("ScreenGui", {
	Name = "AuraUI_Notifications",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10000,
})
parentGui(NotifyGui)

local NotifyHolder = new("Frame", {
	Parent = NotifyGui,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -18),
	Size = UDim2.fromOffset(300, 500),
	BackgroundTransparency = 1,
})
new("UIListLayout", {
	Parent = NotifyHolder,
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local NotifyColors = {
	Success = Color3.fromRGB(56, 200, 120),
	Warning = Color3.fromRGB(240, 180, 60),
	Error   = Color3.fromRGB(235, 70, 80),
	Info    = nil, -- falls back to accent
}

function Library:Notify(o)
	if type(o) == "string" then o = { Text = o } end
	o = o or {}
	local kind   = o.Type or "Info"
	local accent = NotifyColors[kind] or self.Theme.Accent
	local dur    = o.Duration or 4

	local toast = new("CanvasGroup", {
		Parent = NotifyHolder,
		Size = UDim2.new(1, 0, 0, o.Text and 62 or 48),
		BackgroundColor3 = self.Theme.Section,
		BackgroundTransparency = 0,
		GroupTransparency = 1,
		LayoutOrder = math.floor(os.clock() * 1000),
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toast })
	new("UIStroke", { Color = self.Theme.Outline, Thickness = 1, Parent = toast })

	local bar = new("Frame", {
		Parent = toast,
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.new(0, 8, 0, 7),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

	local titleLbl = new("TextLabel", {
		Parent = toast,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 8),
		Size = UDim2.new(1, -32, 0, 16),
		Font = Config.FontBold,
		Text = o.Title or kind,
		TextColor3 = accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	if o.Text then
		new("TextLabel", {
			Parent = toast,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 26),
			Size = UDim2.new(1, -32, 0, 28),
			Font = Config.Font,
			Text = o.Text,
			TextColor3 = self.Theme.Text,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end

	local scale = new("UIScale", { Scale = 0.85, Parent = toast })

	tw(toast, 0.25, { GroupTransparency = 0 })
	tw(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

	local closing = false
	local function dismiss()
		if closing then return end
		closing = true
		tw(toast, 0.2, { GroupTransparency = 1 })
		tw(scale, 0.2, { Scale = 0.9 })
		task.delay(0.22, function()
			if toast then toast:Destroy() end
		end)
	end

	task.delay(dur, dismiss)
	toast.InputBegan = nil

	local click = new("TextButton", {
		Parent = toast,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 5,
	})
	click.MouseButton1Click:Connect(dismiss)

	return { Dismiss = dismiss }
end

--=====================================================================
-- // COMPONENT: SECTION
--=====================================================================
local Section = {}
Section.__index = Section

local function makeCollapsible(section, clip, content, arrow)
	local open = true
	section.Toggle = function(force)
		local target = force
		if target == nil then target = not open end
		open = target
		tw(arrow, 0.2, { Rotation = open and 0 or -90 })

		if open then
			clip.Visible = true
			clip.AutomaticSize = Enum.AutomaticSize.None
			clip.Size = UDim2.new(1, 0, 0, 0)
			task.defer(function()
				local h = content.AbsoluteSize.Y
				tw(clip, 0.22, { Size = UDim2.new(1, 0, 0, h) })
				task.delay(0.22, function()
					if open then
						clip.AutomaticSize = Enum.AutomaticSize.Y
						clip.Size = UDim2.new(1, 0, 0, 0)
					end
				end)
			end)
		else
			clip.AutomaticSize = Enum.AutomaticSize.None
			clip.Size = UDim2.new(1, 0, 0, content.AbsoluteSize.Y)
			tw(clip, 0.22, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.22, function()
				if not open then clip.Visible = false end
			end)
		end
	end
end

local function createSection(self, name, collapsed)
	local section = setmetatable({ Elements = {} }, Section)

	local holder = new("Frame", {
		Parent = self.Page,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Section,
		BorderSizePixel = 0,
		ClipsDescendants = false,
	})
	bind(holder, "BackgroundColor3", "Section")
	new("UICorner", { CornerRadius = Config.ElementCorner, Parent = holder })
	new("UIListLayout", {
		Parent = holder,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local header = new("TextButton", {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 1,
	})

	new("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Font = Config.FontBold,
		Text = name,
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local arrow = new("TextLabel", {
		Parent = header,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Font = Config.FontBold,
		Text = "▾",
		TextColor3 = Library.Theme.SubText,
		TextSize = 14,
		Rotation = 0,
	})

	local clip = new("Frame", {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 2,
	})

	local content = new("Frame", {
		Parent = clip,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	new("UIListLayout", {
		Parent = content,
		Padding = UDim.new(0, Config.RowPadding),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	new("UIPadding", {
		Parent = content,
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	section.Holder  = holder
	section.Content = content
	section.Name    = name

	makeCollapsible(section, clip, content, arrow)
	header.MouseButton1Click:Connect(function() section.Toggle() end)
	header.MouseEnter:Connect(function() tw(arrow, 0.15, { TextColor3 = Library.Theme.Accent }) end)
	header.MouseLeave:Connect(function() tw(arrow, 0.15, { TextColor3 = Library.Theme.SubText }) end)

	if collapsed then section.Toggle(false) end
	return section
end

--=====================================================================
-- // COMPONENT BUILDERS (attached to Section)
--=====================================================================

-- // ELEMENT ROW HELPER -----------------------------------------------
local function elementRow(parent, height)
	local row = new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, height or Config.ElementHeight),
		BackgroundColor3 = Library.Theme.Element,
		BorderSizePixel = 0,
	})
	bind(row, "BackgroundColor3", "Element")
	new("UICorner", { CornerRadius = Config.ElementCorner, Parent = row })
	return row
end

local function rowHover(row, click)
	click.MouseEnter:Connect(function()
		tw(row, 0.12, { BackgroundColor3 = Library.Theme.ElementHover })
	end)
	click.MouseLeave:Connect(function()
		tw(row, 0.12, { BackgroundColor3 = Library.Theme.Element })
	end)
end

-- // TOGGLE -----------------------------------------------------------
function Section:CreateToggle(o)
	o = o or {}
	local flag     = o.Flag or o.Name or "Toggle"
	local callback = o.Callback

	local row = elementRow(self.Content)
	local label = new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Font = Config.Font,
		Text = o.Name or "Toggle",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	bind(label, "TextColor3", "Text")

	local switch = new("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = Library.Theme.Off,
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switch })

	local knob = new("Frame", {
		Parent = switch,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local click = new("TextButton", {
		Parent = row,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	rowHover(row, click)

	local toggle = { Value = false, Flag = flag }

	local function apply(value, silent)
		toggle.Value = value
		Library.Flags[flag] = value
		if value then
			tw(switch, 0.18, { BackgroundColor3 = Library.Theme.Accent })
			tw(knob, 0.18, { Position = UDim2.fromOffset(20, 2) }, Enum.EasingStyle.Back)
		else
			tw(switch, 0.18, { BackgroundColor3 = Library.Theme.Off })
			tw(knob, 0.18, { Position = UDim2.fromOffset(2, 2) }, Enum.EasingStyle.Back)
		end
		if not silent then queueSave() end
	end

	function toggle:Set(value)
		value = not not value
		if toggle.Value == value then return end
		apply(value)
		if callback then
			task.spawn(function()
				pcall(callback, value)
			end)
		end
	end

	local initial = o.Default or false
	if Library.LoadedFlags[flag] ~= nil then initial = Library.LoadedFlags[flag] end

	apply(initial, true)
	Library.Flags[flag] = initial
	Library.Options[flag] = function(v) toggle:Set(v) end

	-- keep colours in sync when the theme changes
	table.insert(Library._callbacks, function(t)
		if toggle.Value then
			switch.BackgroundColor3 = t.Accent
		else
			switch.BackgroundColor3 = t.Off
		end
	end)

	click.MouseButton1Click:Connect(function()
		toggle:Set(not toggle.Value)
	end)

	if callback and initial then
		task.spawn(function() pcall(callback, initial) end)
	end

	return toggle
end

-- // BUTTON -----------------------------------------------------------
function Section:CreateButton(o)
	o = o or {}
	local row = elementRow(self.Content)

	local label = new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Config.FontBold,
		Text = o.Name or "Button",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
	})
	bind(label, "TextColor3", "Text")

	local click = new("TextButton", {
		Parent = row,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	rowHover(row, click)

	local button = { Enabled = true }

	click.MouseButton1Click:Connect(function()
		if not button.Enabled then return end
		tw(row, 0.08, { BackgroundColor3 = Library.Theme.Accent })
		task.delay(0.12, function()
			tw(row, 0.2, { BackgroundColor3 = Library.Theme.Element })
		end)
		if o.Callback then
			task.spawn(function() pcall(o.Callback) end)
		end
	end)

	function button:SetEnabled(v)
		button.Enabled = v
		label.TextColor3 = v and Library.Theme.Text or Library.Theme.SubText
	end

	return button
end

-- // LABEL ------------------------------------------------------------
function Section:CreateLabel(o)
	o = o or {}
	local lbl = new("TextLabel", {
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, o.Height or 20),
		BackgroundTransparency = 1,
		Font = o.Bold and Config.FontBold or Config.Font,
		Text = o.Text or "Label",
		TextColor3 = Library.Theme.Text,
		TextSize = o.Size or 13,
		TextXAlignment = o.Align or Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	bind(lbl, "TextColor3", "Text")
	return lbl
end

function Section:CreateParagraph(o)
	o = o or {}
	local wrap = new("Frame", {
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Element,
		BorderSizePixel = 0,
	})
	bind(wrap, "BackgroundColor3", "Element")
	new("UICorner", { CornerRadius = Config.ElementCorner, Parent = wrap })

	local lbl = new("TextLabel", {
		Parent = wrap,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Config.Font,
		Text = o.Text or "Paragraph text.",
		TextColor3 = Library.Theme.SubText,
		TextSize = o.Size or 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	bind(lbl, "TextColor3", "SubText")
	return lbl
end

-- // SLIDER -----------------------------------------------------------
function Section:CreateSlider(o)
	o = o or {}
	local flag     = o.Flag or o.Name or "Slider"
	local min      = o.Min or 0
	local max      = o.Max or 100
	local step     = o.Step or 1
	local callback = o.Callback

	local row = new("Frame", {
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Library.Theme.Element,
		BorderSizePixel = 0,
	})
	bind(row, "BackgroundColor3", "Element")
	new("UICorner", { CornerRadius = Config.ElementCorner, Parent = row })

	local label = new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -70, 0, 16),
		Font = Config.Font,
		Text = o.Name or "Slider",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	bind(label, "TextColor3", "Text")

	local valueLbl = new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(60, 16),
		Font = Config.FontBold,
		Text = "0",
		TextColor3 = Library.Theme.Accent,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	table.insert(Library._callbacks, function(t) valueLbl.TextColor3 = t.Accent end)

	local track = new("Frame", {
		Parent = row,
		Position = UDim2.new(0, 10, 0, 30),
		Size = UDim2.new(1, -20, 0, 6),
		BackgroundColor3 = Library.Theme.Off,
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = new("Frame", {
		Parent = track,
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Library.Theme.Accent,
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	table.insert(Library._callbacks, function(t) fill.BackgroundColor3 = t.Accent end)

	local knob = new("Frame", {
		Parent = track,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local hitbox = new("TextButton", {
		Parent = row,
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})

	local slider = { Value = 0, Flag = flag }

	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local value = round(min + (max - min) * rel, step)
		value = math.clamp(value, min, max)
		slider:Set(value)
	end

	function slider:Set(value, silent)
		value = math.clamp(round(value, step), min, max)
		slider.Value = value
		local rel = (max - min > 0) and (value - min) / (max - min) or 0
		tw(fill, 0.1, { Size = UDim2.fromScale(rel, 1) })
		tw(knob, 0.1, { Position = UDim2.new(rel, 0, 0.5, 0) })
		valueLbl.Text = tostring(value)
		Library.Flags[flag] = value
		if not silent then
			queueSave()
			if callback then task.spawn(function() pcall(callback, value) end) end
		end
	end

	local initial = o.Default or min
	if Library.LoadedFlags[flag] ~= nil then initial = Library.LoadedFlags[flag] end
	slider:Set(initial, true)
	Library.Flags[flag] = initial
	Library.Options[flag] = function(v) slider:Set(v) end

	local dragging = false
	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	if callback and initial ~= (o.Default or min) then
		task.spawn(function() pcall(callback, initial) end)
	end
	return slider
end

-- // TEXTBOX ----------------------------------------------------------
function Section:CreateTextBox(o)
	o = o or {}
	local flag = o.Flag or o.Name or "TextBox"

	local row = elementRow(self.Content)
	local label = new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.45, -10, 1, 0),
		Font = Config.Font,
		Text = o.Name or "Input",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	bind(label, "TextColor3", "Text")

	local boxWrap = new("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.5, 0, 1, -8),
		BackgroundColor3 = Library.Theme.Window,
		BorderSizePixel = 0,
	})
	bind(boxWrap, "BackgroundColor3", "Window")
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = boxWrap })
	local stroke = new("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = boxWrap })
	bind(stroke, "Color", "Outline")

	local box = new("TextBox", {
		Parent = boxWrap,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Font = Config.Font,
		PlaceholderText = o.Placeholder or "Type here...",
		PlaceholderColor3 = Library.Theme.SubText,
		Text = o.Default or "",
		TextColor3 = Library.Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})
	bind(box, "TextColor3", "Text")

	box.Focused:Connect(function()
		tw(stroke, 0.15, { Color = Library.Theme.Accent, Thickness = 1.5 })
	end)
	box.FocusLost:Connect(function(enter)
		tw(stroke, 0.15, { Color = Library.Theme.Outline, Thickness = 1 })
		Library.Flags[flag] = box.Text
		queueSave()
		if o.Callback then task.spawn(function() pcall(o.Callback, box.Text, enter) end) end
	end)

	if Library.LoadedFlags[flag] then box.Text = Library.LoadedFlags[flag] end
	Library.Flags[flag] = box.Text
	Library.Options[flag] = function(v) box.Text = tostring(v) end
	return box
end

-- // DROPDOWN ---------------------------------------------------------
function Section:CreateDropdown(o)
	o = o or {}
	local flag     = o.Flag or o.Name or "Dropdown"
	local multi    = o.Multi or false
	local options  = o.Options or {}
	local callback = o.Callback
	local searchable = o.Searchable ~= false and #options > 6

	local CLOSED_H = Config.ElementHeight
	local MAX_LIST = 150

	local container = new("Frame", {
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, CLOSED_H),
		BackgroundColor3 = Library.Theme.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	bind(container, "BackgroundColor3", "Element")
	new("UICorner", { CornerRadius = Config.ElementCorner, Parent = container })

	local label = new("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.45, -10, 0, CLOSED_H),
		Font = Config.Font,
		Text = o.Name or "Dropdown",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	bind(label, "TextColor3", "Text")

	local valueLbl = new("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		Size = UDim2.new(0.45, 0, 0, CLOSED_H),
		Font = Config.Font,
		Text = "None",
		TextColor3 = Library.Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	bind(valueLbl, "TextColor3", "SubText")

	local arrow = new("TextLabel", {
		Parent = container,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.fromOffset(12, CLOSED_H),
		BackgroundTransparency = 1,
		Font = Config.FontBold,
		Text = "▾",
		TextColor3 = Library.Theme.SubText,
		TextSize = 13,
	})
	bind(arrow, "TextColor3", "SubText")

	local header = new("TextButton", {
		Parent = container,
		Size = UDim2.new(1, 0, 0, CLOSED_H),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	header.MouseEnter:Connect(function()
		tw(container, 0.12, { BackgroundColor3 = Library.Theme.ElementHover })
	end)
	header.MouseLeave:Connect(function()
		tw(container, 0.12, { BackgroundColor3 = Library.Theme.Element })
	end)

	-- list area
	local listY = CLOSED_H + 4
	local list = new("ScrollingFrame", {
		Parent = container,
		Position = UDim2.fromOffset(8, listY),
		Size = UDim2.new(1, -16, 0, MAX_LIST),
		BackgroundColor3 = Library.Theme.Window,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Library.Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 4,
	})
	bind(list, "BackgroundColor3", "Window")
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = list })
	new("UIListLayout", {
		Parent = list,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	new("UIPadding", {
		Parent = list,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	})

	local searchBox
	if searchable then
		searchBox = new("TextBox", {
			Parent = container,
			Position = UDim2.fromOffset(8, listY),
			Size = UDim2.new(1, -16, 0, 24),
			BackgroundColor3 = Library.Theme.Window,
			BorderSizePixel = 0,
			Font = Config.Font,
			PlaceholderText = "Search...",
			PlaceholderColor3 = Library.Theme.SubText,
			Text = "",
			TextColor3 = Library.Theme.Text,
			TextSize = 12,
			Visible = false,
			ClearTextOnFocus = false,
			ZIndex = 5,
		})
		bind(searchBox, "BackgroundColor3", "Window")
		bind(searchBox, "TextColor3", "Text")
		new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = searchBox })
		list.Position = UDim2.fromOffset(8, listY + 28)
		list.Size = UDim2.new(1, -16, 0, MAX_LIST - 28)
	end

	local dropdown = {
		Value = multi and {} or nil,
		Flag = flag,
		Open = false,
		Options = options,
		Buttons = {},
	}

	local function updateDisplay()
		if multi then
			local vals = dropdown.Value
			if #vals == 0 then
				valueLbl.Text = "None"
			elseif #vals <= 2 then
				valueLbl.Text = table.concat(vals, ", ")
			else
				valueLbl.Text = string.format("%d selected", #vals)
			end
			Library.Flags[flag] = vals
		else
			valueLbl.Text = dropdown.Value or "None"
			Library.Flags[flag] = dropdown.Value
		end
	end

	local function refresh()
		for _, b in ipairs(dropdown.Buttons) do
			local selected
			if multi then
				selected = table.find(dropdown.Value, b.Value) ~= nil
			else
				selected = dropdown.Value == b.Value
			end
			b.Frame.BackgroundColor3 = selected and Library.Theme.Accent or Library.Theme.Element
			b.Label.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Library.Theme.Text
		end
	end

	local function buildList(filter)
		for _, b in ipairs(dropdown.Buttons) do b.Frame:Destroy() end
		table.clear(dropdown.Buttons)
		filter = filter and filter:lower() or ""

		for _, opt in ipairs(options) do
			if filter == "" or string.find(opt:lower(), filter, 1, true) then
				local btnFrame = new("Frame", {
					Parent = list,
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundColor3 = Library.Theme.Element,
					BorderSizePixel = 0,
				})
				new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btnFrame })

				local btnLabel = new("TextLabel", {
					Parent = btnFrame,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(8, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Font = Config.Font,
					Text = opt,
					TextColor3 = Library.Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})

				local btn = new("TextButton", {
					Parent = btnFrame,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
				})

				btn.MouseEnter:Connect(function()
					if not (multi and table.find(dropdown.Value, opt)) and dropdown.Value ~= opt then
						tw(btnFrame, 0.1, { BackgroundColor3 = Library.Theme.ElementHover })
					end
				end)
				btn.MouseLeave:Connect(function()
					if not (multi and table.find(dropdown.Value, opt)) and dropdown.Value ~= opt then
						tw(btnFrame, 0.1, { BackgroundColor3 = Library.Theme.Element })
					end
				end)

				btn.MouseButton1Click:Connect(function()
					if multi then
						local idx = table.find(dropdown.Value, opt)
						if idx then
							table.remove(dropdown.Value, idx)
						else
							table.insert(dropdown.Value, opt)
						end
					else
						dropdown.Value = opt
						dropdown:Toggle(false)
					end
					updateDisplay()
					refresh()
					queueSave()
					if callback then
						task.spawn(function()
							pcall(callback, multi and table.clone(dropdown.Value) or dropdown.Value)
						end)
					end
				end)

				table.insert(dropdown.Buttons, { Frame = btnFrame, Label = btnLabel, Value = opt })
			end
		end
		refresh()
	end

	function dropdown:Toggle(force)
		local target = force
		if target == nil then target = not dropdown.Open end
		dropdown.Open = target
		tw(arrow, 0.2, { Rotation = target and 180 or 0 })

		if target then
			if searchBox then
				searchBox.Visible = true
				searchBox.Text = ""
			end
			list.Visible = true
			list.CanvasPosition = Vector2.new(0, 0)
			buildList("")
			tw(container, 0.2, { Size = UDim2.new(1, 0, 0, listY + MAX_LIST + 8) })
			if searchBox then
				task.defer(function() searchBox:CaptureFocus() end)
			end
		else
			tw(container, 0.2, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
			task.delay(0.2, function()
				if not dropdown.Open then
					list.Visible = false
					if searchBox then searchBox.Visible = false end
				end
			end)
		end
	end

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			buildList(searchBox.Text)
		end)
	end

	header.MouseButton1Click:Connect(function() dropdown:Toggle() end)

	-- apply saved / default value
	local default = o.Default
	if Library.LoadedFlags[flag] ~= nil then default = Library.LoadedFlags[flag] end
	if multi then
		dropdown.Value = type(default) == "table" and default or {}
	else
		dropdown.Value = default or options[1]
	end
	updateDisplay()
	Library.Flags[flag] = dropdown.Value
	Library.Options[flag] = function(v)
		dropdown.Value = v
		updateDisplay()
		refresh()
	end

	function dropdown:Set(v)
		dropdown.Value = v
		updateDisplay()
		refresh()
		queueSave()
		if callback then task.spawn(function() pcall(callback, v) end) end
	end

	return dropdown
end

-- // KEYBIND ----------------------------------------------------------
function Section:CreateKeybind(o)
	o = o or {}
	local flag     = o.Flag or o.Name or "Keybind"
	local callback = o.Callback

	local row = elementRow(self.Content)
	local label = new("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.5, -10, 1, 0),
		Font = Config.Font,
		Text = o.Name or "Keybind",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	bind(label, "TextColor3", "Text")

	local keyBtn = new("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.4, 0, 1, -8),
		BackgroundColor3 = Library.Theme.Window,
		Font = Config.FontBold,
		Text = (o.Default or Enum.KeyCode.E).Name,
		TextColor3 = Library.Theme.Text,
		TextSize = 12,
		AutoButtonColor = false,
	})
	bind(keyBtn, "BackgroundColor3", "Window")
	bind(keyBtn, "TextColor3", "Text")
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = keyBtn })
	local stroke = new("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = keyBtn })
	bind(stroke, "Color", "Outline")

	local keybind = { Value = o.Default or Enum.KeyCode.E, Flag = flag, Listening = false }

	local function setKey(key, silent)
		keybind.Value = key
		keyBtn.Text = key and key.Name or "None"
		Library.Flags[flag] = key
		if not silent then
			queueSave()
			if callback then task.spawn(function() pcall(callback, key) end) end
		end
	end

	keyBtn.MouseButton1Click:Connect(function()
		if keybind.Listening then return end
		keybind.Listening = true
		keyBtn.Text = "..."
		tw(stroke, 0.15, { Color = Library.Theme.Accent, Thickness = 1.5 })

		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				conn:Disconnect()
				keybind.Listening = false
				tw(stroke, 0.15, { Color = Library.Theme.Outline, Thickness = 1 })
				if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
					setKey(nil)
				else
					setKey(input.KeyCode)
				end
			end
		end)
	end)

	if Library.LoadedFlags[flag] ~= nil then
		local ok, key = pcall(function() return Enum.KeyCode[Library.LoadedFlags[flag]] end)
		if ok and key then keybind.Value = key end
	end
	setKey(keybind.Value, true)
	Library.Flags[flag] = keybind.Value and keybind.Value.Name or "None"
	Library.Options[flag] = function(v)
		local ok, key = pcall(function() return Enum.KeyCode[v] end)
		if ok then setKey(key, true) end
	end

	return keybind
end

-- // COLOR PICKER -----------------------------------------------------
function Section:CreateColorPicker(o)
	o = o or {}
	local flag     = o.Flag or o.Name or "Color"
	local callback = o.Callback

	local CLOSED_H = Config.ElementHeight
	local PAD_H = 110
	local OPEN_H = CLOSED_H + PAD_H + 74

	local container = new("Frame", {
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, CLOSED_H),
		BackgroundColor3 = Library.Theme.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	bind(container, "BackgroundColor3", "Element")
	new("UICorner", { CornerRadius = Config.ElementCorner, Parent = container })

	local label = new("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -60, 0, CLOSED_H),
		Font = Config.Font,
		Text = o.Name or "Color",
		TextColor3 = Library.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	bind(label, "TextColor3", "Text")

	local preview = new("Frame", {
		Parent = container,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(44, 18),
		BackgroundColor3 = o.Default or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })
	new("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = preview })

	local header = new("TextButton", {
		Parent = container,
		Size = UDim2.new(1, 0, 0, CLOSED_H),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	header.MouseEnter:Connect(function()
		tw(container, 0.12, { BackgroundColor3 = Library.Theme.ElementHover })
	end)
	header.MouseLeave:Connect(function()
		tw(container, 0.12, { BackgroundColor3 = Library.Theme.Element })
	end)

	-- SV pad
	local pad = new("Frame", {
		Parent = container,
		Position = UDim2.fromOffset(10, CLOSED_H + 6),
		Size = UDim2.new(1, -20, 0, PAD_H),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 4,
		Visible = false,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = pad })

	local whiteOverlay = new("Frame", {
		Parent = pad,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = whiteOverlay })
	local satGradient = new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = whiteOverlay,
	})

	local blackOverlay = new("Frame", {
		Parent = pad,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = blackOverlay })
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = blackOverlay,
	})

	local cross = new("Frame", {
		Parent = pad,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cross })
	new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = cross })

	-- Hue slider
	local hueBar = new("Frame", {
		Parent = container,
		Position = UDim2.fromOffset(10, CLOSED_H + PAD_H + 14),
		Size = UDim2.new(1, -20, 0, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 4,
		Visible = false,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueBar })
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueBar,
	})

	local hueKnob = new("Frame", {
		Parent = hueBar,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueKnob })
	new("UIStroke", { Color = Color3.fromRGB(20, 20, 20), Thickness = 1, Parent = hueKnob })

	-- Hex input
	local hexBox = new("TextBox", {
		Parent = container,
		Position = UDim2.fromOffset(10, CLOSED_H + PAD_H + 32),
		Size = UDim2.new(1, -20, 0, 26),
		BackgroundColor3 = Library.Theme.Window,
		BorderSizePixel = 0,
		Font = Config.Font,
		Text = "#FFFFFF",
		TextColor3 = Library.Theme.Text,
		TextSize = 12,
		ZIndex = 4,
		Visible = false,
		ClearTextOnFocus = false,
	})
	bind(hexBox, "BackgroundColor3", "Window")
	bind(hexBox, "TextColor3", "Text")
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = hexBox })

	local picker = { Value = o.Default or Color3.fromRGB(255, 255, 255), Flag = flag, Open = false }
	local h, s, v = picker.Value:ToHSV()

	local function render()
		local color = Color3.fromHSV(h, s, v)
		picker.Value = color
		preview.BackgroundColor3 = color
		pad.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		cross.Position = UDim2.fromScale(s, 1 - v)
		hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
		hexBox.Text = "#" .. color:ToHex()
		Library.Flags[flag] = color
	end

	local function commit()
		queueSave()
		if callback then task.spawn(function() pcall(callback, picker.Value) end) end
	end

	function picker:Set(color, silent)
		h, s, v = color:ToHSV()
		render()
		if not silent then commit() end
	end

	-- pad interaction
	local padDragging = false
	local function padFromInput(pos)
		local relX = math.clamp((pos.X - pad.AbsolutePosition.X) / pad.AbsoluteSize.X, 0, 1)
		local relY = math.clamp((pos.Y - pad.AbsolutePosition.Y) / pad.AbsoluteSize.Y, 0, 1)
		s, v = relX, 1 - relY
		render()
	end

	local padBtn = new("TextButton", {
		Parent = pad,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	})
	padBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			padDragging = true
			padFromInput(input.Position)
		end
	end)

	-- hue interaction
	local hueDragging = false
	local function hueFromInput(pos)
		h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
		render()
	end

	local hueBtn = new("TextButton", {
		Parent = hueBar,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	})
	hueBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = true
			hueFromInput(input.Position)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if padDragging then padFromInput(input.Position) end
		if hueDragging then hueFromInput(input.Position) end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if padDragging or hueDragging then commit() end
			padDragging = false
			hueDragging = false
		end
	end)

	hexBox.FocusLost:Connect(function()
		local ok, color = pcall(Color3.fromHex, hexBox.Text)
		if ok then
			picker:Set(color)
		else
			hexBox.Text = "#" .. picker.Value:ToHex()
		end
	end)

	function picker:Toggle(force)
		local target = force
		if target == nil then target = not picker.Open end
		picker.Open = target
		if target then
			pad.Visible = true
			hueBar.Visible = true
			hexBox.Visible = true
			tw(container, 0.22, { Size = UDim2.new(1, 0, 0, OPEN_H) })
		else
			tw(container, 0.22, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
			task.delay(0.22, function()
				if not picker.Open then
					pad.Visible = false
					hueBar.Visible = false
					hexBox.Visible = false
				end
			end)
		end
	end

	header.MouseButton1Click:Connect(function() picker:Toggle() end)

	if Library.LoadedFlags[flag] ~= nil then
		local val = Library.LoadedFlags[flag]
		if typeof(val) == "Color3" then picker.Value = val end
	end
	h, s, v = picker.Value:ToHSV()
	render()
	Library.Flags[flag] = picker.Value
	Library.Options[flag] = function(c) picker:Set(c, true) end

	return picker
end

--=====================================================================
-- // WINDOW
--=====================================================================
local Window = {}
Window.__index = Window

local function makeDraggable(window, dragArea, main, shadow)
	local dragging, dragInput, dragStart, startPos

	local function clampAndSet(newX, newY)
		local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
		local size = main.AbsoluteSize
		newX = math.clamp(newX, -(size.X - 80), vp.X - 80)
		newY = math.clamp(newY, 0, vp.Y - 40)
		main.Position = UDim2.fromOffset(newX, newY)
		shadow.Position = UDim2.fromOffset(newX - 4, newY - 4)
	end

	dragArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragArea.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			clampAndSet(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		end
	end)
end

function Library:CreateWindow(o)
	o = o or {}
	local window = setmetatable({}, Window)
	window.Tabs = {}
	window.Flags = Library.Flags
	window.ActiveTab = nil

	local title    = o.Title or Config.Title
	local subtitle = o.Subtitle or Config.Subtitle

	local W, H = Config.WindowSize.X, Config.WindowSize.Y
	local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local px = math.floor((vp.X - W) / 2)
	local py = math.floor((vp.Y - H) / 2)

	-- GUI ------------------------------------------------------------
	local gui = new("ScreenGui", {
		Name = "AuraUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
	})
	parentGui(gui)

	-- Shadow ---------------------------------------------------------
	local shadow = new("Frame", {
		Parent = gui,
		Position = UDim2.fromOffset(px - 4, py - 4),
		Size = UDim2.fromOffset(W + 8, H + 8),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = shadow })

	-- Main -----------------------------------------------------------
	local main = new("Frame", {
		Name = "Main",
		Parent = gui,
		Position = UDim2.fromOffset(px, py),
		Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = Library.Theme.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	})
	bind(main, "BackgroundColor3", "Window")
	new("UICorner", { CornerRadius = Config.CornerRadius, Parent = main })
	local mainStroke = new("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = main })
	bind(mainStroke, "Color", "Outline")

	-- Topbar ---------------------------------------------------------
	local topbar = new("Frame", {
		Name = "Topbar",
		Parent = main,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Library.Theme.Topbar,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	bind(topbar, "BackgroundColor3", "Topbar")

	new("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 7),
		Size = UDim2.new(0.6, 0, 0, 16),
		Font = Config.FontBold,
		Text = title,
		TextColor3 = Library.Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local subLbl = new("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 23),
		Size = UDim2.new(0.6, 0, 0, 14),
		Font = Config.Font,
		Text = subtitle,
		TextColor3 = Library.Theme.SubText,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	bind(subLbl, "TextColor3", "SubText")

	local accentLine = new("Frame", {
		Parent = topbar,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	})
	table.insert(Library._callbacks, function(t) accentLine.BackgroundColor3 = t.Accent end)

	-- Window buttons
	local function topButton(text, order)
		local btn = new("TextButton", {
			Parent = topbar,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10 - (order * 30), 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 1,
			Font = Config.FontBold,
			Text = text,
			TextColor3 = Library.Theme.SubText,
			TextSize = 15,
			AutoButtonColor = false,
			ZIndex = 4,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = btn })
		btn.MouseEnter:Connect(function()
			tw(btn, 0.12, { BackgroundTransparency = 0.15 })
			tw(btn, 0.12, { TextColor3 = Library.Theme.Text })
		end)
		btn.MouseLeave:Connect(function()
			tw(btn, 0.12, { BackgroundTransparency = 1 })
			tw(btn, 0.12, { TextColor3 = Library.Theme.SubText })
		end)
		return btn
	end

	local closeBtn = topButton("✕", 0)
	closeBtn.MouseButton1Click:Connect(function()
		tw(main, 0.18, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.4 })
		window.Visible = false
		task.delay(0.19, function()
			main.Visible = false
			shadow.Visible = false
			main.Size = UDim2.fromOffset(W, window.Minimized and 42 or H)
			tw(main, 0.2, { BackgroundTransparency = 0 })
		end)
	end)
	closeBtn.MouseEnter:Connect(function()
		tw(closeBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(220, 60, 70) })
	end)
	closeBtn.MouseLeave:Connect(function()
		tw(closeBtn, 0.12, { BackgroundColor3 = Library.Theme.Element })
	end)

	local minBtn = topButton("—", 1)
	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		window.Minimized = minimized
		if minimized then
			sidebar.Visible = false
			contentHolder.Visible = false
			if resizeHandle then resizeHandle.Visible = false end
			tw(main, 0.22, { Size = UDim2.fromOffset(main.AbsoluteSize.X, 42) })
			tw(shadow, 0.22, { Size = UDim2.fromOffset(main.AbsoluteSize.X + 8, 50) })
		else
			tw(main, 0.22, { Size = UDim2.fromOffset(main.AbsoluteSize.X, H) })
			tw(shadow, 0.22, { Size = UDim2.fromOffset(main.AbsoluteSize.X + 8, H + 8) })
			task.delay(0.1, function()
				sidebar.Visible = true
				contentHolder.Visible = true
				if resizeHandle then resizeHandle.Visible = true end
			end)
		end
	end)

	-- Sidebar --------------------------------------------------------
	local sidebar = new("Frame", {
		Name = "Sidebar",
		Parent = main,
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(0, 158, 1, -42),
		BackgroundColor3 = Library.Theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	bind(sidebar, "BackgroundColor3", "Sidebar")

	local sideLine = new("Frame", {
		Parent = sidebar,
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Library.Theme.Outline,
		BorderSizePixel = 0,
	})
	bind(sideLine, "BackgroundColor3", "Outline")

	local tabScroll = new("ScrollingFrame", {
		Parent = sidebar,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Library.Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
	})
	new("UIListLayout", {
		Parent = tabScroll,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	new("UIPadding", {
		Parent = tabScroll,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	-- Content --------------------------------------------------------
	local contentHolder = new("Frame", {
		Name = "Content",
		Parent = main,
		Position = UDim2.fromOffset(158, 42),
		Size = UDim2.new(1, -158, 1, -42),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 3,
	})

	-- Resize handle --------------------------------------------------
	local resizeHandle
	if Config.Resizable then
		resizeHandle = new("TextButton", {
			Parent = main,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -3, 1, -3),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Text = "◢",
			Font = Config.FontBold,
			TextColor3 = Library.Theme.SubText,
			TextSize = 11,
			AutoButtonColor = false,
			ZIndex = 5,
		})
		bind(resizeHandle, "TextColor3", "SubText")

		local resizing = false
		local rsStart, rsSize

		resizeHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				rsStart = input.Position
				rsSize = main.AbsoluteSize
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not resizing then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - rsStart
				local nw = math.clamp(rsSize.X + delta.X, Config.MinWindowSize.X, Config.MaxWindowSize.X)
				local nh = math.clamp(rsSize.Y + delta.Y, Config.MinWindowSize.Y, Config.MaxWindowSize.Y)
				main.Size = UDim2.fromOffset(nw, nh)
				shadow.Size = UDim2.fromOffset(nw + 8, nh + 8)
			end
		end)
	end

	-- Dragging -------------------------------------------------------
	makeDraggable(window, topbar, main, shadow)

	-- Window state ---------------------------------------------------
	window.Gui     = gui
	window.Main    = main
	window.Shadow  = shadow
	window.Visible = true
	window.Minimized = false

	function window:SetVisible(state)
		self.Visible = state
		if state then
			main.Visible = true
			shadow.Visible = true
			main.Size = UDim2.fromOffset(main.AbsoluteSize.X, 0)
			tw(main, 0.2, { Size = UDim2.fromOffset(main.AbsoluteSize.X, minimized and 42 or H) })
			tw(shadow, 0.2, { Size = UDim2.fromOffset(main.AbsoluteSize.X + 8, (minimized and 42 or H) + 8) })
			tw(main, 0.2, { BackgroundTransparency = 0 })
		else
			tw(main, 0.15, { Size = UDim2.new(0, main.AbsoluteSize.X, 0, main.AbsoluteSize.Y), BackgroundTransparency = 0.5 })
			task.delay(0.16, function()
				main.Visible = false
				shadow.Visible = false
				main.BackgroundTransparency = 0
				main.Size = UDim2.fromOffset(main.AbsoluteSize.X, minimized and 42 or H)
			end)
		end
	end

	function window:Toggle()
		self:SetVisible(not self.Visible)
	end

	function window:Destroy()
		UserInputService.InputBegan:Connect(function() end) -- noop guard
		gui:Destroy()
		for i = #Library._bindings, 1, -1 do
			local b = Library._bindings[i]
			if not b.i or not b.i.Parent then table.remove(Library._bindings, i) end
		end
	end

	-- // TAB ---------------------------------------------------------
	function window:CreateTab(tabName)
		local tab = { Name = tabName, Elements = {}, Active = false }

		-- sidebar button
		local tabBtn = new("TextButton", {
			Parent = tabScroll,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 1,
			Font = Config.Font,
			Text = "",
			AutoButtonColor = false,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabBtn })

		local indicator = new("Frame", {
			Parent = tabBtn,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 3, 0, 18),
			BackgroundColor3 = Library.Theme.Accent,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })
		table.insert(Library._callbacks, function(t)
			indicator.BackgroundColor3 = t.Accent
		end)

		local tabLabel = new("TextLabel", {
			Parent = tabBtn,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -18, 1, 0),
			Font = Config.Font,
			Text = tabName,
			TextColor3 = Library.Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		-- page
		local page = new("ScrollingFrame", {
			Parent = contentHolder,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Position = UDim2.new(0, 12, 0, 0),
		})
		new("UIListLayout", {
			Parent = page,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		new("UIPadding", {
			Parent = page,
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 12),
		})

		tab.Button = tabBtn
		tab.Label  = tabLabel
		tab.Page   = page
		tab.Indicator = indicator

		function tab:Select()
			if window.ActiveTab == tab then return end
			if window.ActiveTab then
				local prev = window.ActiveTab
				prev.Active = false
				prev.Page.Visible = false
				tw(prev.Indicator, 0.18, { BackgroundTransparency = 1 })
				tw(prev.Label, 0.18, { TextColor3 = Library.Theme.SubText })
				tw(prev.Button, 0.18, { BackgroundTransparency = 1 })
			end

			window.ActiveTab = tab
			tab.Active = true
			page.Visible = true
			page.Position = UDim2.new(0, 20, 0, 0)
			tw(page, 0.22, { Position = UDim2.new(0, 12, 0, 0) })
			tw(indicator, 0.18, { BackgroundTransparency = 0 })
			tw(tabLabel, 0.18, { TextColor3 = Library.Theme.Text })
			tw(tabBtn, 0.18, { BackgroundTransparency = 0.75 })
		end

		tabBtn.MouseEnter:Connect(function()
			if not tab.Active then
				tw(tabBtn, 0.14, { BackgroundTransparency = 0.85 })
				tw(tabLabel, 0.14, { TextColor3 = Library.Theme.Text })
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if not tab.Active then
				tw(tabBtn, 0.14, { BackgroundTransparency = 1 })
				tw(tabLabel, 0.14, { TextColor3 = Library.Theme.SubText })
			end
		end)
		tabBtn.MouseButton1Click:Connect(function() tab:Select() end)

		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then tab:Select() end

		-- // SECTION
		function tab:CreateSection(sectionName, collapsed)
			return createSection(tab, sectionName, collapsed)
		end

		return tab
	end

	table.insert(Library.Windows, window)
	return window
end

--=====================================================================
-- // GLOBAL TOGGLE KEYBIND
--=====================================================================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Config.ToggleKey then
		local w = Library.Windows[1]
		if w then w:Toggle() end
	end
end)

--=====================================================================
-- // FEATURES  (ported + optimized from ALL SCRIPTS.txt)
--=====================================================================

--// SHARED HEARTBEAT SCHEDULER ---------------------------------------
-- Replaces multiple RunService.Heartbeat connections with a single one.
local Scheduler = { Tasks = {}, Connection = nil }
function Scheduler:Add(fn)
	table.insert(self.Tasks, fn)
	if not self.Connection then
		self.Connection = RunService.Heartbeat:Connect(function(dt)
			for i = #self.Tasks, 1, -1 do
				local ok = pcall(self.Tasks[i], dt)
				if not ok then table.remove(self.Tasks, i) end
			end
		end)
	end
end
function Scheduler:Remove(fn)
	local i = table.find(self.Tasks, fn)
	if i then table.remove(self.Tasks, i) end
end
function Scheduler:Clear()
	table.clear(self.Tasks)
end

--// FEATURE 1 : INFINITE STAMINA -------------------------------------
local InfiniteStamina = {
	Connections = {},
	Task        = nil,
	State       = nil,
	Active      = false,
}
function InfiniteStamina:BindCharacter(char)
	task.spawn(function()
		local handler = char:WaitForChild("ClientHandler", 10)
			or char:WaitForChild("Client", 10)
			or char:WaitForChild("ClientOLD", 10)
		if not handler or not self.Active then return end

		local stateModule = handler:WaitForChild("State", 10)
		if not stateModule then return end

		local ok, State = pcall(require, stateModule)
		if not ok or type(State) ~= "table" then return end
		self.State = State

		if self.Task then Scheduler:Remove(self.Task) end

		-- Single lightweight update task, no per-character Heartbeat connection.
		self.Task = function()
			local stamina = State.stamina
			if not stamina then return end
			stamina.current    = 200
			stamina.regenDelay = 0
			stamina.fullRegen  = false
			stamina.active     = false
			if stamina.exhausted ~= nil then
				stamina.exhausted = false
			end
		end
		Scheduler:Add(self.Task)
	end)
end
function InfiniteStamina:Start()
	if self.Active then return end
	self.Active = true
	local char = LocalPlayer.Character
	if char then self:BindCharacter(char) end
	table.insert(self.Connections, LocalPlayer.CharacterAdded:Connect(function(c)
		self:BindCharacter(c)
	end))
end
function InfiniteStamina:Stop()
	self.Active = false
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	table.clear(self.Connections)
	if self.Task then
		Scheduler:Remove(self.Task)
		self.Task = nil
	end
	self.State = nil
end

--// FEATURE 2 : INFINITE NVG (IsCloaker) -----------------------------
local InfiniteNVG = {
	Connections = {},
	Active      = false,
	Created     = {},   -- flags we created ourselves (for clean removal)
}
local function applyCloaker(self, char)
	local flag = char:FindFirstChild("IsCloaker")
	if not flag then
		flag = Instance.new("BoolValue")
		flag.Name = "IsCloaker"
		flag.Parent = char
		self.Created[flag] = true
	end
	if not flag:IsA("BoolValue") then return nil end
	flag.Value = true
	return flag
end
function InfiniteNVG:BindCharacter(char)
	local flag = applyCloaker(self, char)
	if not flag then return end

	table.insert(self.Connections, flag.Changed:Connect(function()
		if self.Active and flag.Value ~= true then
			flag.Value = true
		end
	end))

	table.insert(self.Connections, char.ChildAdded:Connect(function(child)
		if self.Active and child.Name == "IsCloaker" and child:IsA("BoolValue") then
			child.Value = true
		end
	end))
end
function InfiniteNVG:Start()
	if self.Active then return end
	self.Active = true
	local char = LocalPlayer.Character
	if char then self:BindCharacter(char) end
	table.insert(self.Connections, LocalPlayer.CharacterAdded:Connect(function(c)
		self:BindCharacter(c)
	end))
end
function InfiniteNVG:Stop()
	self.Active = false
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	table.clear(self.Connections)

	local char = LocalPlayer.Character
	if char then
		local flag = char:FindFirstChild("IsCloaker")
		if flag and flag:IsA("BoolValue") then
			if self.Created[flag] then
				flag:Destroy()
			else
				flag.Value = false
			end
		end
	end
	table.clear(self.Created)
end

--// FEATURE 3 : AI HIGHLIGHT / ESP -----------------------------------
local AIHighlight = {
	Connections = {},
	Tracked     = {},   -- [model] = {highlight=, billboard=, thread=}
	Active      = false,
	Accent      = Color3.fromRGB(255, 0, 0),
}

local function clearHighlight(entry)
	if not entry then return end
	if entry.Highlight then entry.Highlight:Destroy() end
	if entry.Billboard then entry.Billboard:Destroy() end
end

function AIHighlight:Add(model)
	if self.Tracked[model] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "AI_Highlight"
	highlight.Adornee = model
	highlight.FillColor = self.Accent
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 1
	highlight.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "AI_HealthUI"
	billboard.Adornee = model
	billboard.Size = UDim2.new(0, 100, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.Parent = model

	local textLabel = Instance.new("TextLabel")
	textLabel.Parent = billboard
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = self.Accent
	textLabel.TextStrokeTransparency = 0
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Text = ""

	local entry = { Highlight = highlight, Billboard = billboard, Label = textLabel }
	self.Tracked[model] = entry

	-- event-driven health updater (no more polling when dead)
	entry.Thread = task.spawn(function()
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		while self.Active and self.Tracked[model] and model.Parent do
			if not humanoid or humanoid.Parent ~= model then
				humanoid = model:FindFirstChildOfClass("Humanoid")
			end
			if humanoid then
				textLabel.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
				if humanoid.Health <= 0 then break end
			end
			task.wait(0.2)
		end
		if self.Tracked[model] then
			clearHighlight(self.Tracked[model])
			self.Tracked[model] = nil
		end
	end)
end

function AIHighlight:Remove(model)
	local entry = self.Tracked[model]
	if entry then
		clearHighlight(entry)
		self.Tracked[model] = nil
	end
end

function AIHighlight:Start()
	if self.Active then return end
	self.Active = true

	local characters = workspace:WaitForChild("Characters", 10)
	if not characters then
		self.Active = false
		return
	end
	self.Characters = characters

	for _, v in ipairs(characters:GetChildren()) do
		if v:FindFirstChild("AI") then self:Add(v) end
	end

	table.insert(self.Connections, characters.ChildAdded:Connect(function(v)
		task.wait(0.1)
		if self.Active and v:FindFirstChild("AI") then
			self:Add(v)
		end
	end))

	table.insert(self.Connections, characters.ChildRemoved:Connect(function(v)
		self:Remove(v)
	end))
end

function AIHighlight:Stop()
	self.Active = false
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	table.clear(self.Connections)
	for model in pairs(self.Tracked) do
		self:Remove(model)
	end
	table.clear(self.Tracked)
end

--// FEATURE 4 : AI HEAD HITBOX ---------------------------------------
local Hitbox = {
	Connections = {},
	Modified    = {},   -- [part] = {Size=, Transparency=, CanCollide=}
	Active      = false,
	Size        = Vector3.new(4, 4, 4),
	Transparency = 0.5,
}

local function isPlayerCharacter(model)
	if not model or not model:IsA("Model") then return false end
	return Players:GetPlayerFromCharacter(model) ~= nil
end

local function isHumanoidModel(model)
	if not model or not model:IsA("Model") then return false end
	return model:FindFirstChildWhichIsA("Humanoid") ~= nil
end

function Hitbox:ApplyToPart(part)
	if not self.Active then return end
	if not part or not part:IsA("BasePart") then return end
	if part.Name ~= "Head" then return end

	local model = part.Parent
	if not isHumanoidModel(model) or isPlayerCharacter(model) then return end

	-- cache originals so we can perfectly restore on disable
	if not self.Modified[part] then
		self.Modified[part] = {
			Size = part.Size,
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
		}
	end

	pcall(function()
		part.Size = self.Size
		part.CanCollide = false
		part.Transparency = self.Transparency
	end)
end

function Hitbox:Restore(part)
	local orig = self.Modified[part]
	if not orig then return end
	pcall(function()
		part.Size = orig.Size
		part.Transparency = orig.Transparency
		part.CanCollide = orig.CanCollide
	end)
	self.Modified[part] = nil
end

function Hitbox:Start()
	if self.Active then return end
	self.Active = true

	for _, desc in ipairs(workspace:GetDescendants()) do
		self:ApplyToPart(desc)
		if desc:IsA("BasePart") then
			table.insert(self.Connections, desc:GetPropertyChangedSignal("Name"):Connect(function()
				self:ApplyToPart(desc)
			end))
		end
	end

	table.insert(self.Connections, workspace.DescendantAdded:Connect(function(desc)
		self:ApplyToPart(desc)
		if desc:IsA("BasePart") then
			table.insert(self.Connections, desc:GetPropertyChangedSignal("Name"):Connect(function()
				self:ApplyToPart(desc)
			end))
		end
	end))
end

function Hitbox:Stop()
	self.Active = false
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	table.clear(self.Connections)
	for part in pairs(self.Modified) do
		self:Restore(part)
	end
	table.clear(self.Modified)
end

--=====================================================================
-- // BOOTSTRAP  ·  build the menu and wire the feature toggles
--=====================================================================
local Window = Library:CreateWindow({
	Title    = Config.Title,
	Subtitle = Config.Subtitle,
})

-- ---------------------------------------------------------------
-- TAB: Player
-- ---------------------------------------------------------------
local playerTab = Window:CreateTab("Player")

local perksSection = playerTab:CreateSection("Perks")

perksSection:CreateToggle({
	Name = "Infinite Stamina",
	Flag = "InfiniteStamina",
	Default = false,
	Callback = function(state)
		if state then
			InfiniteStamina:Start()
			Library:Notify({ Title = "Perks", Text = "Infinite Stamina enabled.", Type = "Success", Duration = 3 })
		else
			InfiniteStamina:Stop()
			Library:Notify({ Title = "Perks", Text = "Infinite Stamina disabled.", Type = "Warning", Duration = 3 })
		end
	end,
})

perksSection:CreateToggle({
	Name = "Infinite NVG",
	Flag = "InfiniteNVG",
	Default = false,
	Callback = function(state)
		if state then
			InfiniteNVG:Start()
			Library:Notify({ Title = "Perks", Text = "Infinite NVG enabled.", Type = "Success", Duration = 3 })
		else
			InfiniteNVG:Stop()
			Library:Notify({ Title = "Perks", Text = "Infinite NVG disabled.", Type = "Warning", Duration = 3 })
		end
	end,
})

-- ---------------------------------------------------------------
-- TAB: Visuals
-- ---------------------------------------------------------------
local visualsTab = Window:CreateTab("Visuals")

local espSection = visualsTab:CreateSection("Enemy ESP")

espSection:CreateToggle({
	Name = "AI Highlight",
	Flag = "AIHighlight",
	Default = false,
	Callback = function(state)
		if state then
			AIHighlight:Start()
			Library:Notify({ Title = "Visuals", Text = "AI Highlight enabled.", Type = "Success", Duration = 3 })
		else
			AIHighlight:Stop()
			Library:Notify({ Title = "Visuals", Text = "AI Highlight disabled.", Type = "Warning", Duration = 3 })
		end
	end,
})

local hitboxSection = visualsTab:CreateSection("Hitbox")

hitboxSection:CreateToggle({
	Name = "AI Head Hitbox",
	Flag = "AIHitbox",
	Default = false,
	Callback = function(state)
		if state then
			Hitbox:Start()
			Library:Notify({ Title = "Hitbox", Text = "AI Head Hitbox enabled.", Type = "Success", Duration = 3 })
		else
			Hitbox:Stop()
			Library:Notify({ Title = "Hitbox", Text = "AI Head Hitbox disabled.", Type = "Warning", Duration = 3 })
		end
	end,
})

hitboxSection:CreateSlider({
	Name = "Head Size",
	Flag = "HitboxSize",
	Min = 2, Max = 10, Step = 0.5, Default = 4,
	Callback = function(v)
		Hitbox.Size = Vector3.new(v, v, v)
		if Hitbox.Active then
			for part in pairs(Hitbox.Modified) do
				pcall(function()
					part.Size = Hitbox.Size
				end)
			end
		end
	end,
})

hitboxSection:CreateSlider({
	Name = "Head Transparency",
	Flag = "HitboxTransparency",
	Min = 0, Max = 1, Step = 0.05, Default = 0.5,
	Callback = function(v)
		Hitbox.Transparency = v
		if Hitbox.Active then
			for part in pairs(Hitbox.Modified) do
				pcall(function()
					part.Transparency = v
				end)
			end
		end
	end,
})

-- ---------------------------------------------------------------
-- TAB: Settings
-- ---------------------------------------------------------------
local settingsTab = Window:CreateTab("Settings")

local themeSection = settingsTab:CreateSection("Appearance")

themeSection:CreateDropdown({
	Name = "Theme",
	Flag = "Theme",
	Options = Library:GetThemeList(),
	Default = Config.ThemeName,
	Searchable = false,
	Callback = function(value)
		Library:SetTheme(value)
	end,
})

themeSection:CreateColorPicker({
	Name = "Accent Color",
	Flag = "AccentColor",
	Default = Library.Theme.Accent,
	Callback = function(color)
		Library:SetAccent(color)
	end,
})

local keySection = settingsTab:CreateSection("Controls")

keySection:CreateKeybind({
	Name = "Menu Toggle Key",
	Flag = "MenuKey",
	Default = Config.ToggleKey,
	Callback = function(key)
		if key then
			Config.ToggleKey = key
			Library:Notify({ Title = "Controls", Text = "Menu key set to " .. key.Name, Type = "Info", Duration = 3 })
		end
	end,
})

local miscSection = settingsTab:CreateSection("Misc")

miscSection:CreateButton({
	Name = "Reset All Settings",
	Callback = function()
		Library.Flags = {}
		Library.LoadedFlags = {}
		if writefile then pcall(function() writefile(Config.SettingsFile, "{}") end) end
		Library:Notify({ Title = "Settings", Text = "Saved settings cleared. Rejoin to fully reset.", Type = "Warning", Duration = 4 })
	end,
})

miscSection:CreateButton({
	Name = "Unload UI",
	Callback = function()
		InfiniteStamina:Stop()
		InfiniteNVG:Stop()
		AIHighlight:Stop()
		Hitbox:Stop()
		Library.Windows[1]:Destroy()
		NotifyGui:Destroy()
		Library:Notify({ Title = "AuraUI", Text = "Unloaded.", Type = "Info", Duration = 2 })
	end,
})

-- ---------------------------------------------------------------
-- Welcome notification
-- ---------------------------------------------------------------
task.delay(0.4, function()
	Library:Notify({
		Title = "AuraUI",
		Text = string.format("Loaded. Press %s to toggle the menu.", Config.ToggleKey.Name),
		Type = "Success",
		Duration = 5,
	})
end)

return Library
