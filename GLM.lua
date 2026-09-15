--════════════════════════════════════════════════════════════════════════════
--  AURORA UI v1.0 — Premium single-script Roblox UI library
--
--  PUBLIC API
--    Library:CreateWindow(title, subtitle)                 -> Window
--    Window:CreateTab(name)                                -> Tab
--    Tab:CreateSection(name)                               -> Section
--    Tab/Section:CreateToggle({Name,Default,Flag,Callback})
--    Tab/Section:CreateButton({Name,Callback})
--    Tab/Section:CreateSlider({Name,Min,Max,Default,Increment,Suffix,Callback})
--    Tab/Section:CreateDropdown({Name,Options,Default,Multi,Placeholder,Callback})
--    Tab/Section:CreateTextbox({Name,Placeholder,Default,Callback})
--    Tab/Section:CreateKeybind({Name,Default,Callback})
--    Tab/Section:CreateColorPicker({Name,Default,Callback})
--    Tab/Section:CreateLabel({Text}) / CreateParagraph({Text})
--    Library:Notify(title, message, duration, "Success"|"Info"|"Warning"|"Error")
--    Library:ToggleVisibility() / Library:Shutdown() / Library:Save() / Library:Load()
--    Library:SetAccent(color) / Library.ApplyTheme(themeName)
--════════════════════════════════════════════════════════════════════════════

-- // SERVICES ------------------------------------------------------------------
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- // CONFIG (tweak the whole look here) ----------------------------------------
local Config = {
    WindowName     = "Aurora",
    WindowSubtitle = "premium interface  •  v1.0",
    WindowSize     = UDim2.fromScale(0.48, 0.58), -- scale-based => responsive
    MinWindowSize  = Vector2.new(470, 330),
    MaxWindowSize  = Vector2.new(860, 760),
    ToggleKey      = Enum.KeyCode.RightShift,
    Font           = Enum.Font.Gotham,
    FontBold       = Enum.Font.GothamBold,
    CornerRadius   = 10,
    ElementRadius  = 6,
    TabWidth       = 142,
    TabHeight      = 30,
    TabPadding     = 4,
    TitleHeight    = 46,
    ElementHeight  = 32,
    AnimationTime  = 0.25,
    Easing         = Enum.EasingStyle.Quint,
    EasingDirection= Enum.EasingDirection.Out,
    FolderName     = "Aurora",
    FileName       = "settings.json",
    SaveOnModify   = true,
}

-- // THEMES --------------------------------------------------------------------
local Themes = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 26),  Secondary = Color3.fromRGB(26, 26, 34),
        Element = Color3.fromRGB(34, 34, 44),     ElementHover = Color3.fromRGB(44, 44, 56),
        Stroke = Color3.fromRGB(60, 60, 76),      Text = Color3.fromRGB(240, 240, 248),
        TextDim = Color3.fromRGB(150, 150, 165),  ToggleOff = Color3.fromRGB(85, 85, 100),
        Accent = Color3.fromRGB(124, 111, 255),
    },
    Light = {
        Background = Color3.fromRGB(238, 238, 244), Secondary = Color3.fromRGB(228, 228, 236),
        Element = Color3.fromRGB(218, 218, 228),     ElementHover = Color3.fromRGB(206, 206, 218),
        Stroke = Color3.fromRGB(185, 185, 200),      Text = Color3.fromRGB(35, 35, 45),
        TextDim = Color3.fromRGB(110, 110, 125),     ToggleOff = Color3.fromRGB(168, 168, 180),
        Accent = Color3.fromRGB(124, 111, 255),
    },
    Midnight = {
        Background = Color3.fromRGB(12, 16, 32),  Secondary = Color3.fromRGB(16, 21, 40),
        Element = Color3.fromRGB(22, 28, 52),     ElementHover = Color3.fromRGB(28, 36, 66),
        Stroke = Color3.fromRGB(36, 46, 84),      Text = Color3.fromRGB(225, 232, 255),
        TextDim = Color3.fromRGB(130, 142, 180),  ToggleOff = Color3.fromRGB(52, 62, 100),
        Accent = Color3.fromRGB(80, 170, 255),
    },
    Ocean = {
        Background = Color3.fromRGB(10, 24, 28),  Secondary = Color3.fromRGB(13, 31, 36),
        Element = Color3.fromRGB(18, 41, 48),     ElementHover = Color3.fromRGB(24, 52, 60),
        Stroke = Color3.fromRGB(32, 66, 76),      Text = Color3.fromRGB(224, 245, 248),
        TextDim = Color3.fromRGB(128, 160, 168),  ToggleOff = Color3.fromRGB(48, 84, 92),
        Accent = Color3.fromRGB(38, 208, 186),
    },
    Bloodmoon = {
        Background = Color3.fromRGB(18, 12, 14),  Secondary = Color3.fromRGB(24, 15, 18),
        Element = Color3.fromRGB(34, 21, 25),     ElementHover = Color3.fromRGB(44, 28, 33),
        Stroke = Color3.fromRGB(62, 38, 44),      Text = Color3.fromRGB(248, 232, 234),
        TextDim = Color3.fromRGB(165, 130, 137),  ToggleOff = Color3.fromRGB(88, 58, 64),
        Accent = Color3.fromRGB(232, 62, 84),
    },
}

local CurrentThemeName = "Dark"
local Theme = Themes.Dark
local AccentOverride = nil

local function GetAccent()
    return AccentOverride or Theme.Accent
end

-- // CORE STATE ------------------------------------------------------------------
local Library      = {}
local Connections  = {}  -- global connections, disconnected on shutdown
local ThemeHooks   = {}  -- callbacks that restyle everything on theme change
local Keybinds     = {}  -- [Enum.KeyCode] = fn  (single shared dispatcher)
local Flags        = {}  -- Library.Flags["flag"]:Set(value) programmatic access
local RuntimeValues= {} -- values persisted to disk
local SavedData    = nil
local ListeningCount = 0
local ScreenGui    = nil
local SetFeature -- forward declaration (used by Shutdown, defined in FEATURES)
local FeatureList = {}

Library.Flags  = Flags
Library.Config = Config
Library.Themes = Themes

-- // UTILITIES -------------------------------------------------------------------
local function Track(conn)
    table.insert(Connections, conn)
    return conn
end

local function OnTheme(fn)
    table.insert(ThemeHooks, fn)
end

local function Create(className, props, children)
    local inst = Instance.new(className)
    local parent = nil
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then parent = v else inst[k] = v end
        end
    end
    if children then
        for _, child in ipairs(children) do child.Parent = inst end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Tween(obj, duration, props, style, direction)
    local t = TweenService:Create(obj,
        TweenInfo.new(duration or Config.AnimationTime, style or Config.Easing, direction or Config.EasingDirection), props)
    t:Play()
    return t
end

local function RGBtoHSV(c)
    local r, g, b = c.R, c.G, c.B
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    if max > 0 then s = d / max end
    if d > 0 then
        if max == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, s, v
end

local function GetViewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

-- // SETTINGS SAVE / LOAD (executor file I/O, safely wrapped) ----------------------
local SaveQueued = false

local function GetSavedValue(flag)
    if SavedData and typeof(SavedData.Values) == "table" then
        return SavedData.Values[flag]
    end
    return nil
end

local function QueueSave()
    if not Config.SaveOnModify or SaveQueued then return end
    SaveQueued = true
    task.delay(1, function()
        SaveQueued = false
        Library:Save()
    end)
end

function Library:Save()
    return pcall(function()
        if typeof(writefile) ~= "function" or typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then return end
        local payload = { Theme = CurrentThemeName, Values = {} }
        for k, v in pairs(RuntimeValues) do payload.Values[k] = v end
        if not isfolder(Config.FolderName) then makefolder(Config.FolderName) end
        writefile(Config.FolderName .. "/" .. Config.FileName, HttpService:JSONEncode(payload))
    end)
end

function Library:Load()
    pcall(function()
        if typeof(readfile) ~= "function" then return end
        SavedData = HttpService:JSONDecode(readfile(Config.FolderName .. "/" .. Config.FileName))
    end)
end

local function ApplyTheme(name)
    local t = Themes[name]
    if not t then return end
    CurrentThemeName = name
    Theme = t
    for _, fn in ipairs(ThemeHooks) do pcall(fn) end
    QueueSave()
end
Library.ApplyTheme = ApplyTheme

function Library:SetAccent(color)
    AccentOverride = color
    for _, fn in ipairs(ThemeHooks) do pcall(fn) end
    QueueSave()
end

-- // SHARED DRAG SYSTEM (one global connection for ALL drags, no per-frame loops) ---
local DragRegistry = {}

Track(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        for _, entry in ipairs(DragRegistry) do
            pcall(entry.Move, input.Position.X, input.Position.Y)
        end
    end
end))

Track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        table.clear(DragRegistry)
    end
end))

local function BindDrag(area, onStart, onMove)
    area.Active = true
    area.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if onStart then pcall(onStart, input.Position.X, input.Position.Y) end
            table.insert(DragRegistry, { Move = onMove })
        end
    end)
end

-- // SHARED KEYBIND DISPATCHER (one connection for ALL keybinds) --------------------
Track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or ListeningCount > 0 then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local fn = Keybinds[input.KeyCode]
        if fn then pcall(fn, input.KeyCode) end
    end
end))

-- // SCREENGUI INIT ------------------------------------------------------------------
function Library:Init()
    if ScreenGui then return end
    pcall(function()
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui.Name == "AuroraUI" then gui:Destroy() end
        end
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, gui in ipairs(pg:GetChildren()) do
                if gui.Name == "AuroraUI" then gui:Destroy() end
            end
        end
    end)
    ScreenGui = Create("ScreenGui", {
        Name = "AuroraUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    local placed = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not placed then
        local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
        if pg then ScreenGui.Parent = pg end
    end
end

-- // NOTIFICATIONS ----------------------------------------------------------------------
local NotifyStack, notifyOrder = nil, 0

function Library:Notify(title, message, duration, kind)
    Library:Init()
    if not ScreenGui then return end
    duration = duration or 4
    kind = kind or "Info"
    local kindColors = {
        Success = Color3.fromRGB(96, 220, 130),
        Info    = GetAccent(),
        Warning = Color3.fromRGB(250, 190, 80),
        Error   = Color3.fromRGB(240, 90, 90),
    }
    local kindColor = kindColors[kind] or kindColors.Info

    if not NotifyStack then
        NotifyStack = Create("Frame", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 18),
            Size = UDim2.fromOffset(270, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, ZIndex = 50, Parent = ScreenGui,
        })
        Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifyStack })
    end

    notifyOrder += 1
    local toast = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = notifyOrder, Parent = NotifyStack,
    })
    local card = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0,
        Position = UDim2.fromOffset(60, 0), ClipsDescendants = true, Parent = toast,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
    Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.4, Parent = card })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 12), Parent = card,
    })

    local stripe = Create("Frame", {
        BackgroundColor3 = kindColor, Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0, ZIndex = 2, Parent = card,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = stripe })
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, 0, 0, 16), Font = Config.FontBold, TextSize = 13,
        TextColor3 = kindColor, TextXAlignment = Enum.TextXAlignment.Left,
        Text = title or "Notification", Parent = card,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 26),
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, Font = Config.Font, TextSize = 12,
        TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Text = message or "", Parent = card,
    })
    local progress = Create("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = kindColor,
        BorderSizePixel = 0, ZIndex = 2, Parent = card,
    })

    local closed = false
    local function Close()
        if closed then return end
        closed = true
        local t = Tween(card, 0.3, { Position = UDim2.fromOffset(90, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function() toast:Destroy() end)
    end

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Close() end
    end)
    Tween(card, 0.4, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
    Tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(duration, Close)

    local frames = {}
    for _, child in ipairs(NotifyStack:GetChildren()) do
        if child:IsA("Frame") then table.insert(frames, child) end
    end
    table.sort(frames, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    if #frames > 6 then frames[1]:Destroy() end
end

-- // COMPONENTS -------------------------------------------------------------------------
local Components = {}

local function CreateBase(parent, height)
    return Create("Frame", {
        Size = UDim2.new(1, 0, 0, height or Config.ElementHeight),
        BackgroundTransparency = 1, Parent = parent,
    })
end

local function AddHover(btn)
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.15, { BackgroundColor3 = Theme.ElementHover }, Enum.EasingStyle.Quad)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, { BackgroundColor3 = Theme.Element }, Enum.EasingStyle.Quad)
    end)
end

-- // TOGGLE COMPONENT (animated knob + color transition) -----------------------------------
function Components.Toggle(parent, options)
    local state = false
    local flag = options.Flag or ("toggle_" .. tostring(options.Name))

    local frame = CreateBase(parent)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = btn })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.55, Parent = btn })
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -64, 1, 0), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = options.Name or "Toggle", Parent = btn,
    })
    local switch = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(36, 18), BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0, Parent = btn,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switch })
    local knob = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 9, 0.5, 0),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Parent = switch,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    local function Set(new, fire)
        state = new and true or false
        Tween(switch, 0.25, { BackgroundColor3 = state and GetAccent() or Theme.ToggleOff }, Enum.EasingStyle.Quad)
        Tween(knob, 0.3, { Position = state and UDim2.new(1, -9, 0.5, 0) or UDim2.new(0, 9, 0.5, 0) }, Enum.EasingStyle.Back)
        RuntimeValues[flag] = state
        QueueSave()
        if fire ~= false and options.Callback then pcall(options.Callback, state) end
    end

    btn.MouseButton1Click:Connect(function() Set(not state) end)
    AddHover(btn)

    OnTheme(function()
        btn.BackgroundColor3 = Theme.Element
        stroke.Color = Theme.Stroke
        label.TextColor3 = Theme.Text
        switch.BackgroundColor3 = state and GetAccent() or Theme.ToggleOff
    end)

    local initial = options.Default or false
    local saved = GetSavedValue(flag)
    if saved ~= nil then initial = saved and true or false end
    Set(initial, true)

    local obj = { Set = function(_, v) Set(v) end, Get = function() return state end }
    Flags[flag] = obj
    return obj
end

-- // BUTTON COMPONENT (ripple + hover) ------------------------------------------------------
function Components.Button(parent, options)
    local frame = CreateBase(parent)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Text = options.Name or "Button",
        Font = Config.Font, TextSize = 13, TextColor3 = Theme.Text,
        AutoButtonColor = false, ClipsDescendants = true, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = btn })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.55, Parent = btn })

    local function Ripple(x, y)
        local circle = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 2, Parent = btn,
        })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })
        local target = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.4
        local t = Tween(circle, 0.45, { Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
        t.Completed:Connect(function() circle:Destroy() end)
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Ripple(input.Position.X - btn.AbsolutePosition.X, input.Position.Y - btn.AbsolutePosition.Y)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if options.Callback then pcall(options.Callback) end
    end)
    AddHover(btn)

    OnTheme(function()
        btn.BackgroundColor3 = Theme.Element
        stroke.Color = Theme.Stroke
        btn.TextColor3 = Theme.Text
    end)

    return { Fire = function() if options.Callback then pcall(options.Callback) end end }
end

-- // SLIDER COMPONENT -----------------------------------------------------------------------
function Components.Slider(parent, options)
    local min, max = options.Min or 0, options.Max or 100
    local inc = options.Increment or 1
    local suffix = options.Suffix or ""
    local flag = options.Flag or ("slider_" .. tostring(options.Name))

    local frame = CreateBase(parent, 48)
    local nameLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -110, 0, 16), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = options.Name or "Slider", Parent = frame,
    })
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 5), Size = UDim2.fromOffset(90, 16),
        Font = Config.FontBold, TextSize = 12, TextColor3 = GetAccent(),
        TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
    })
    local track = Create("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.new(1, -20, 0, 6), BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
    local fill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = GetAccent(),
        BorderSizePixel = 0, Parent = track,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
    local knob = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 2, Parent = track,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
    local knobStroke = Create("UIStroke", { Color = GetAccent(), Thickness = 2, Parent = knob })

    local value = min
    local decimals = inc >= 1 and 0 or (inc >= 0.1 and 1 or 2)

    local function Set(newValue, fire)
        newValue = math.clamp(newValue, min, max)
        value = newValue
        local alpha = max > min and (value - min) / (max - min) or 0
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = string.format("%." .. decimals .. "f", value) .. suffix
        RuntimeValues[flag] = value
        QueueSave()
        if fire ~= false and options.Callback then pcall(options.Callback, value) end
    end

    local function FromX(x)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = min + (max - min) * alpha
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return math.clamp(v, min, max)
    end

    BindDrag(track, nil, function(x) Set(FromX(x)) end)
    BindDrag(knob, nil, function(x) Set(FromX(x)) end)

    OnTheme(function()
        nameLabel.TextColor3 = Theme.Text
        track.BackgroundColor3 = Theme.ToggleOff
        fill.BackgroundColor3 = GetAccent()
        valueLabel.TextColor3 = GetAccent()
        knobStroke.Color = GetAccent()
    end)

    local saved = GetSavedValue(flag)
    Set(typeof(saved) == "number" and saved or (options.Default or min), true)

    local obj = { Set = function(_, v) Set(v) end, Get = function() return value end }
    Flags[flag] = obj
    return obj
end

-- // DROPDOWN COMPONENT (single + multi + search) ------------------------------------------------
function Components.Dropdown(parent, options)
    local multi = options.Multi and true or false
    local optionList = {}
    for _, v in ipairs(options.Options or {}) do table.insert(optionList, tostring(v)) end
    local placeholder = options.Placeholder or (multi and "None selected" or "Select...")
    local flag = options.Flag or ("dropdown_" .. tostring(options.Name))
    local searchable = options.Searchable or #optionList >= 8

    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, Config.ElementHeight), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = parent,
    })
    local header = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, Config.ElementHeight), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = header })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.55, Parent = header })
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -150, 1, 0), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = options.Name or "Dropdown", Parent = header,
    })
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(120, Config.ElementHeight),
        Font = Config.Font, TextSize = 12, TextColor3 = Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
        Text = placeholder, Parent = header,
    })
    local chev = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
        Font = Config.Font, TextSize = 11, TextColor3 = Theme.TextDim,
        Text = "▼", Parent = header,
    })

    local list = Create("ScrollingFrame", {
        Position = UDim2.fromOffset(0, Config.ElementHeight + 2), Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0, ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Stroke,
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = list })
    local listStroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.45, Parent = list })
    Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = list,
    })

    local searchBox = nil
    if searchable then
        searchBox = Create("TextBox", {
            Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Secondary,
            BorderSizePixel = 0, Font = Config.Font, TextSize = 12,
            TextColor3 = Theme.Text, PlaceholderText = "Search...",
            PlaceholderColor3 = Theme.TextDim, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, LayoutOrder = 0, Parent = list,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = searchBox })
        Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = searchBox })
    end

    local open = false
    local selected = {}
    local currentSingle = nil
    local optionButtons = {}
    local visibleCount = #optionList
    local SetOpen -- forward declaration (referenced by option click closures)

    local function IsSelected(opt)
        if multi then
            for _, v in ipairs(selected) do if v == opt then return true end end
            return false
        end
        return currentSingle == opt
    end

    local function RefreshVisuals()
        for opt, obtn in pairs(optionButtons) do
            if IsSelected(opt) then
                obtn.BackgroundColor3 = GetAccent()
                obtn.BackgroundTransparency = 0.85
                obtn.TextColor3 = Theme.Text
                obtn.Text = (multi and "✓ " or "") .. opt
            else
                obtn.BackgroundTransparency = 1
                obtn.TextColor3 = Theme.TextDim
                obtn.Text = (multi and "    " or "") .. opt
            end
        end
    end

    local function ValueText()
        if multi then
            if #selected == 0 then return placeholder end
            return table.concat(selected, ", ")
        end
        return currentSingle or placeholder
    end

    local function FireCallback()
        RuntimeValues[flag] = multi and { table.unpack(selected) } or currentSingle
        QueueSave()
        if options.Callback then
            pcall(options.Callback, multi and { table.unpack(selected) } or currentSingle)
        end
    end

    local function Rebuild(filter)
        for _, obtn in pairs(optionButtons) do obtn:Destroy() end
        optionButtons = {}
        local count = 0
        for _, opt in ipairs(optionList) do
            if not filter or filter == "" or string.find(string.lower(opt), string.lower(filter), 1, true) then
                count += 1
                local obtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
                    BorderSizePixel = 0, AutoButtonColor = false, Font = Config.Font,
                    TextSize = 12, TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = opt, LayoutOrder = count, Parent = list,
                })
                obtn.MouseEnter:Connect(function()
                    if not IsSelected(opt) then
                        obtn.BackgroundColor3 = Theme.ElementHover
                        Tween(obtn, 0.12, { BackgroundTransparency = 0.6 }, Enum.EasingStyle.Quad)
                    end
                end)
                obtn.MouseLeave:Connect(function()
                    Tween(obtn, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
                end)
                obtn.MouseButton1Click:Connect(function()
                    if multi then
                        local idx = nil
                        for i, v in ipairs(selected) do
                            if v == opt then idx = i; break end
                        end
                        if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                        RefreshVisuals()
                        valueLabel.Text = ValueText()
                        FireCallback()
                    else
                        currentSingle = opt
                        RefreshVisuals()
                        valueLabel.Text = ValueText()
                        FireCallback()
                        SetOpen(false)
                    end
                end)
                optionButtons[opt] = obtn
            end
        end
        RefreshVisuals()
        return count
    end

    function SetOpen(state)
        open = state
        local searchH = searchBox and 28 or 0
        local targetH = state and math.clamp(visibleCount * 26 + searchH + 12, 0, 182) or 0
        Tween(list, Config.AnimationTime, { Size = UDim2.new(1, 0, 0, targetH) })
        Tween(chev, Config.AnimationTime, { Rotation = state and 180 or 0 })
        if state and searchBox then
            searchBox.Text = ""
            visibleCount = Rebuild("")
        end
    end

    header.MouseButton1Click:Connect(function() SetOpen(not open) end)
    AddHover(header)

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            visibleCount = Rebuild(searchBox.Text)
            if open then
                local targetH = math.clamp(visibleCount * 26 + 28 + 12, 0, 182)
                Tween(list, 0.2, { Size = UDim2.new(1, 0, 0, targetH) }, Enum.EasingStyle.Quad)
            end
        end)
    end

    -- restore saved / default value
    local saved = GetSavedValue(flag)
    if saved ~= nil then
        if multi and typeof(saved) == "table" then
            selected = {}
            for _, v in ipairs(saved) do
                for _, opt in ipairs(optionList) do
                    if opt == tostring(v) then table.insert(selected, opt) end
                end
            end
        elseif not multi and typeof(saved) == "string" then
            for _, opt in ipairs(optionList) do
                if opt == saved then currentSingle = opt end
            end
        end
    elseif options.Default ~= nil then
        if multi and typeof(options.Default) == "table" then
            for _, v in ipairs(options.Default) do table.insert(selected, tostring(v)) end
        else
            currentSingle = tostring(options.Default)
        end
    end

    visibleCount = Rebuild("")
    valueLabel.Text = ValueText()
    FireCallback()

    OnTheme(function()
        header.BackgroundColor3 = Theme.Element
        stroke.Color = Theme.Stroke
        label.TextColor3 = Theme.Text
        valueLabel.TextColor3 = Theme.TextDim
        chev.TextColor3 = Theme.TextDim
        list.BackgroundColor3 = Theme.Element
        listStroke.Color = Theme.Stroke
        list.ScrollBarImageColor3 = Theme.Stroke
        if searchBox then
            searchBox.BackgroundColor3 = Theme.Secondary
            searchBox.TextColor3 = Theme.Text
            searchBox.PlaceholderColor3 = Theme.TextDim
        end
        RefreshVisuals()
    end)

    local obj = {
        Set = function(_, value)
            if multi and typeof(value) == "table" then
                selected = {}
                for _, v in ipairs(value) do table.insert(selected, tostring(v)) end
            elseif typeof(value) == "string" then
                currentSingle = value
            end
            RefreshVisuals()
            valueLabel.Text = ValueText()
            FireCallback()
        end,
        Get = function() return multi and { table.unpack(selected) } or currentSingle end,
    }
    Flags[flag] = obj
    return obj
end

-- // TEXTBOX COMPONENT ------------------------------------------------------------------------
function Components.Textbox(parent, options)
    local flag = options.Flag or ("textbox_" .. tostring(options.Name))

    local frame = CreateBase(parent, 34)
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -180, 1, 0), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = options.Name or "Input", Parent = frame,
    })
    local box = Create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.new(0.42, 0, 0, 26), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Font = Config.Font, TextSize = 12,
        TextColor3 = Theme.Text, PlaceholderText = options.Placeholder or "Type here...",
        PlaceholderColor3 = Theme.TextDim, Text = options.Default or "",
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = options.ClearOnFocus or false,
        Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = box })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.55, Parent = box })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })

    local saved = GetSavedValue(flag)
    if typeof(saved) == "string" then box.Text = saved end

    box.Focused:Connect(function()
        Tween(stroke, 0.2, { Color = GetAccent(), Transparency = 0 }, Enum.EasingStyle.Quad)
    end)
    box.FocusLost:Connect(function(enterPressed)
        Tween(stroke, 0.2, { Color = Theme.Stroke, Transparency = 0.55 }, Enum.EasingStyle.Quad)
        RuntimeValues[flag] = box.Text
        QueueSave()
        if options.Callback then pcall(options.Callback, box.Text, enterPressed) end
    end)

    OnTheme(function()
        label.TextColor3 = Theme.Text
        box.BackgroundColor3 = Theme.Element
        box.TextColor3 = Theme.Text
        box.PlaceholderColor3 = Theme.TextDim
        stroke.Color = Theme.Stroke
    end)

    local obj = { Set = function(_, text) box.Text = tostring(text) end, Get = function() return box.Text end }
    Flags[flag] = obj
    return obj
end

-- // KEYBIND COMPONENT --------------------------------------------------------------------------
function Components.Keybind(parent, options)
    local flag = options.Flag or ("keybind_" .. tostring(options.Name))
    local currentKey = options.Default or Enum.KeyCode.Unknown
    local listening = false

    local frame = CreateBase(parent)
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -130, 1, 0), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = options.Name or "Keybind", Parent = frame,
    })
    local btn = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(96, 22), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Font = Config.FontBold, TextSize = 11,
        TextColor3 = Theme.TextDim, Text = "None", AutoButtonColor = false, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = btn })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.55, Parent = btn })

    local dispatch = function()
        if options.Callback then pcall(options.Callback, currentKey) end
    end

    local function SetKey(key)
        if currentKey ~= Enum.KeyCode.Unknown and Keybinds[currentKey] == dispatch then
            Keybinds[currentKey] = nil
        end
        currentKey = key
        if key ~= Enum.KeyCode.Unknown then Keybinds[key] = dispatch end
        btn.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
        RuntimeValues[flag] = key.Name
        QueueSave()
    end

    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        ListeningCount += 1
        btn.Text = "press a key..."
        Tween(btn, 0.2, { TextColor3 = GetAccent() }, Enum.EasingStyle.Quad)
        local conn
        conn = Track(UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                listening = false
                ListeningCount -= 1
                Tween(btn, 0.2, { TextColor3 = Theme.TextDim }, Enum.EasingStyle.Quad)
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    SetKey(input.KeyCode)
                else
                    btn.Text = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name
                end
            end
        end))
    end)

    AddHover(btn)

    local saved = GetSavedValue(flag)
    if typeof(saved) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[saved] end)
        if ok and key and key ~= Enum.KeyCode.Unknown then currentKey = key end
    end
    btn.Text = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name
    if currentKey ~= Enum.KeyCode.Unknown then Keybinds[currentKey] = dispatch end
    RuntimeValues[flag] = currentKey.Name

    OnTheme(function()
        btn.BackgroundColor3 = Theme.Element
        stroke.Color = Theme.Stroke
        label.TextColor3 = Theme.Text
        if not listening then btn.TextColor3 = Theme.TextDim end
    end)

    local obj = { Set = function(_, key) SetKey(key) end, Get = function() return currentKey end }
    Flags[flag] = obj
    return obj
end

-- // COLOR PICKER COMPONENT (full HSV picker) -----------------------------------------------------
function Components.ColorPicker(parent, options)
    local flag = options.Flag or ("color_" .. tostring(options.Name))
    local defaultColor = options.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = RGBtoHSV(defaultColor)

    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, Config.ElementHeight), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = parent,
    })
    local header = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, Config.ElementHeight), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = header })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.55, Parent = header })
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -70, 1, 0), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = options.Name or "Color", Parent = header,
    })
    local chev = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
        Font = Config.Font, TextSize = 11, TextColor3 = Theme.TextDim,
        Text = "▼", Parent = header,
    })
    local swatch = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.fromOffset(18, 14), BackgroundColor3 = defaultColor,
        BorderSizePixel = 0, Parent = header,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = swatch })

    local panel = Create("Frame", {
        Position = UDim2.fromOffset(0, Config.ElementHeight + 2), Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = frame,
    })
    local svBox = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0, ClipsDescendants = true, Parent = panel,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.ElementRadius), Parent = svBox })
    local whiteOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Parent = svBox,
    })
    Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = whiteOverlay })
    local blackOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0, Parent = svBox,
    })
    Create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = blackOverlay })
    local cursor = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = svBox,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cursor })
    Create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = cursor })

    local hueBar = Create("Frame", {
        Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 14),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        ClipsDescendants = true, Parent = panel,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueBar })
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hueBar,
    })
    local hueCursor = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(8, 18), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 3, Parent = hueBar,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueCursor })
    Create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = hueCursor })

    local hexLabel = Create("TextLabel", {
        Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1, Font = Config.Font, TextSize = 11,
        TextColor3 = Theme.TextDim, Text = "", Parent = panel,
    })

    local open = false
    local color = defaultColor

    local function Apply(fire)
        color = Color3.fromHSV(h, s, v)
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        swatch.BackgroundColor3 = color
        hexLabel.Text = string.format("RGB  %d, %d, %d",
            math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
        RuntimeValues[flag] = { color.R, color.G, color.B }
        QueueSave()
        if fire ~= false and options.Callback then pcall(options.Callback, color) end
    end

    BindDrag(svBox, nil, function(x, y)
        s = math.clamp((x - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
        Apply()
    end)
    BindDrag(hueBar, nil, function(x)
        h = math.clamp((x - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        Apply()
    end)

    header.MouseButton1Click:Connect(function()
        open = not open
        Tween(panel, Config.AnimationTime, { Size = UDim2.new(1, 0, 0, open and 156 or 0) })
        Tween(chev, Config.AnimationTime, { Rotation = open and 180 or 0 })
    end)
    AddHover(header)

    OnTheme(function()
        header.BackgroundColor3 = Theme.Element
        stroke.Color = Theme.Stroke
        label.TextColor3 = Theme.Text
        hexLabel.TextColor3 = Theme.TextDim
    end)

    local saved = GetSavedValue(flag)
    if typeof(saved) == "table" and #saved == 3 then
        h, s, v = RGBtoHSV(Color3.new(saved[1], saved[2], saved[3]))
    end
    Apply(true)

    local obj = { Set = function(_, c) h, s, v = RGBtoHSV(c); Apply(true) end, Get = function() return color end }
    Flags[flag] = obj
    return obj
end

-- // LABEL / PARAGRAPH COMPONENTS -----------------------------------------------------------------
function Components.Label(parent, options)
    local frame = CreateBase(parent, 20)
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0), Font = Config.Font, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Text = options.Text or options.Name or "Label", Parent = frame,
    })
    OnTheme(function() label.TextColor3 = Theme.Text end)
    return { Set = function(_, t) label.Text = t end }
end

function Components.Paragraph(parent, options)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = parent,
    })
    local label = Create("TextLabel", {
        Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Font = Config.Font, TextSize = 12, TextColor3 = Theme.TextDim,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Text = options.Text or options.Name or "",
        Parent = frame,
    })
    OnTheme(function() label.TextColor3 = Theme.TextDim end)
    return { Set = function(_, t) label.Text = t end }
end

-- // ELEMENT HOST MIXIN (tabs + sections expose every component) ------------------------------------
local function AttachHost(host, container)
    function host:CreateToggle(options)      return Components.Toggle(container, options) end
    function host:CreateButton(options)      return Components.Button(container, options) end
    function host:CreateSlider(options)      return Components.Slider(container, options) end
    function host:CreateDropdown(options)    return Components.Dropdown(container, options) end
    function host:CreateTextbox(options)     return Components.Textbox(container, options) end
    function host:CreateKeybind(options)     return Components.Keybind(container, options) end
    function host:CreateColorPicker(options) return Components.ColorPicker(container, options) end
    function host:CreateLabel(options)       return Components.Label(container, options) end
    function host:CreateParagraph(options)   return Components.Paragraph(container, options) end
    return host
end

-- // SECTION COMPONENT (collapsible groupbox) --------------------------------------------------------
local function CreateSection(parent, name)
    local Section = {}
    local expanded = true
    local contentHeight = 0

    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
    local stroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.45, Parent = frame })

    local header = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Parent = frame,
    })
    local title = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -40, 1, 0), Font = Config.FontBold, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = name or "Section", Parent = header,
    })
    local arrow = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
        Font = Config.Font, TextSize = 12, TextColor3 = Theme.TextDim,
        Text = "▼", Parent = header,
    })

    local content = Create("Frame", {
        Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, Parent = frame,
    })
    local layout = Create("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content,
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentHeight = layout.AbsoluteContentSize.Y
        content.Size = UDim2.new(1, 0, 0, contentHeight)
        if expanded then frame.Size = UDim2.new(1, 0, 0, 36 + contentHeight + 8) end
    end)

    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        Tween(arrow, 0.3, { Rotation = expanded and 0 or -90 })
        Tween(frame, 0.35, { Size = UDim2.new(1, 0, 0, expanded and (36 + contentHeight + 8) or 36) })
    end)

    OnTheme(function()
        frame.BackgroundColor3 = Theme.Secondary
        stroke.Color = Theme.Stroke
        title.TextColor3 = Theme.Text
        arrow.TextColor3 = Theme.TextDim
    end)

    AttachHost(Section, content)
    return Section
end

-- // WINDOW CREATION (drag, resize, minimize, close, tabs, animated indicator) ------------------------
function Library:CreateWindow(title, subtitle)
    Library:Init()
    local Window = { Tabs = {}, Selected = nil }
    Library.Window = Window

    -- responsive initial size derived from viewport scale, clamped to min/max
    local vp = GetViewport()
    local w = math.clamp(math.floor(vp.X * Config.WindowSize.X.Scale + 0.5),
        math.min(Config.MinWindowSize.X, vp.X), math.min(Config.MaxWindowSize.X, vp.X))
    local h = math.clamp(math.floor(vp.Y * Config.WindowSize.Y.Scale + 0.5),
        math.min(Config.MinWindowSize.Y, vp.Y), math.min(Config.MaxWindowSize.Y, vp.Y))

    local Holder = Create("Frame", {
        Name = "AuroraHolder", BackgroundTransparency = 1, ZIndex = 1,
        Position = UDim2.fromOffset(math.floor((vp.X - w) / 2), math.floor((vp.Y - h) / 2)),
        Size = UDim2.fromOffset(w, h), Parent = ScreenGui,
    })

    local RootCG = Create("CanvasGroup", {
        Name = "Root", BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), Parent = Holder,
    })

    local Shadow = Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
        ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
        Size = UDim2.new(1, 60, 1, 60), Position = UDim2.new(0, -30, 0, -30), Parent = RootCG,
    })

    local Main = Create("Frame", {
        Name = "Main", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = RootCG,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, Config.CornerRadius), Parent = Main })
    local mainStroke = Create("UIStroke", { Color = Theme.Stroke, Transparency = 0.35, Parent = Main })
    Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(235, 235, 240)),
        Parent = Main,
    })

    -- title bar
    local TitleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, Config.TitleHeight), BackgroundTransparency = 1, Parent = Main,
    })
    local logo = Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(8, 8), BackgroundColor3 = GetAccent(),
        BorderSizePixel = 0, Parent = TitleBar,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = logo })
    local titleL = Create("TextLabel", {
        Position = UDim2.fromOffset(30, 6), Size = UDim2.new(1, -140, 0, 18),
        BackgroundTransparency = 1, Font = Config.FontBold, TextSize = 15,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = title or Config.WindowName, Parent = TitleBar,
    })
    local subL = Create("TextLabel", {
        Position = UDim2.fromOffset(30, 25), Size = UDim2.new(1, -140, 0, 13),
        BackgroundTransparency = 1, Font = Config.Font, TextSize = 11,
        TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = subtitle or Config.WindowSubtitle, Parent = TitleBar,
    })
    local divider = Create("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = TitleBar,
    })

    local function TitleBtn(offset, glyph, isClose)
        local b = Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offset, 0.5, 0),
            Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1,
            BackgroundColor3 = isClose and Color3.fromRGB(220, 70, 80) or Theme.ElementHover,
            Text = glyph, Font = Config.FontBold, TextSize = 14,
            TextColor3 = Theme.TextDim, AutoButtonColor = false, Parent = TitleBar,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
        b.MouseEnter:Connect(function()
            Tween(b, 0.15, { BackgroundTransparency = 0.15, TextColor3 = isClose and Color3.new(1, 1, 1) or Theme.Text })
        end)
        b.MouseLeave:Connect(function()
            Tween(b, 0.15, { BackgroundTransparency = 1, TextColor3 = Theme.TextDim })
        end)
        return b
    end
    local minBtn = TitleBtn(-38, "–", false)
    local closeBtn = TitleBtn(-8, "✕", true)

    -- sidebar (tabs)
    local Sidebar = Create("Frame", {
        Position = UDim2.new(0, 0, 0, Config.TitleHeight),
        Size = UDim2.new(0, Config.TabWidth, 1, -Config.TitleHeight),
        BackgroundTransparency = 1, Parent = Main,
    })
    local ButtonHolder = Create("Frame", {
        Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12),
        BackgroundTransparency = 1, Parent = Sidebar,
    })
    Create("UIListLayout", { Padding = UDim.new(0, Config.TabPadding), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ButtonHolder })
    local Indicator = Create("Frame", {
        Size = UDim2.new(1, -12, 0, Config.TabHeight), BackgroundColor3 = GetAccent(),
        BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = Sidebar,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Indicator })
    local indBar = Create("Frame", {
        Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = GetAccent(),
        BorderSizePixel = 0, Parent = Indicator,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = indBar })
    local sideDivider = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, Config.TitleHeight),
        Size = UDim2.new(0, 1, 1, -Config.TitleHeight), BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = Main,
    })

    -- content area
    local ContentHolder = Create("Frame", {
        Position = UDim2.new(0, Config.TabWidth, 0, Config.TitleHeight),
        Size = UDim2.new(1, -Config.TabWidth, 1, -Config.TitleHeight),
        BackgroundTransparency = 1, Parent = Main,
    })

    -- resize grip (bottom-right, min/max clamped)
    local Grip = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
        Text = "◢", Font = Config.Font, TextSize = 12, TextColor3 = Theme.TextDim,
        AutoButtonColor = false, ZIndex = 5, Parent = Main,
    })
    Grip.MouseEnter:Connect(function() Tween(Grip, 0.15, { TextColor3 = GetAccent() }) end)
    Grip.MouseLeave:Connect(function() Tween(Grip, 0.15, { TextColor3 = Theme.TextDim }) end)

    local minimized, restoreSize = false, nil

    BindDrag(Grip, nil, function(x, y)
        if minimized then return end
        local origin = Holder.AbsolutePosition
        local vpNow = GetViewport()
        local minW = math.min(Config.MinWindowSize.X, vpNow.X)
        local minH = math.min(Config.MinWindowSize.Y, vpNow.Y)
        local nw = math.clamp(x - origin.X, minW, math.min(Config.MaxWindowSize.X, vpNow.X - origin.X))
        local nh = math.clamp(y - origin.Y, minH, math.min(Config.MaxWindowSize.Y, vpNow.Y - origin.Y))
        Holder.Size = UDim2.fromOffset(nw, nh)
    end)

    local function SetMinimized(state)
        if minimized == state then return end
        minimized = state
        Grip.Visible = not state
        if state then
            restoreSize = Holder.Size
            Tween(Holder, 0.4, { Size = UDim2.fromOffset(Holder.AbsoluteSize.X, Config.TitleHeight + 2) })
        elseif restoreSize then
            Tween(Holder, 0.4, { Size = restoreSize }, Enum.EasingStyle.Back)
        end
    end
    minBtn.MouseButton1Click:Connect(function() SetMinimized(not minimized) end)

    closeBtn.MouseButton1Click:Connect(function()
        local t = Tween(RootCG, 0.25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function() Library:Shutdown() end)
    end)

    -- drag-to-move (clamped so the window can never be dragged fully off-screen)
    local dragOffset = Vector2.zero
    BindDrag(TitleBar, function(x, y)
        dragOffset = Vector2.new(x, y) - Holder.AbsolutePosition
    end, function(x, y)
        local vpNow = GetViewport()
        local size = Holder.AbsoluteSize
        local nx = math.clamp(x - dragOffset.X, -size.X + 90, math.max(0, vpNow.X - 90))
        local ny = math.clamp(y - dragOffset.Y, 0, math.max(0, vpNow.Y - 40))
        Holder.Position = UDim2.fromOffset(nx, ny)
    end)

    -- keep window on-screen when the viewport changes
    if workspace.CurrentCamera then
        Track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local vpNow = GetViewport()
            local pos, size = Holder.AbsolutePosition, Holder.AbsoluteSize
            Holder.Position = UDim2.fromOffset(
                math.clamp(pos.X, -size.X + 90, math.max(0, vpNow.X - 90)),
                math.clamp(pos.Y, 0, math.max(0, vpNow.Y - 40)))
        end))
    end

    -- visibility toggle
    local visible = true
    function Window:SetVisible(state)
        if visible == state then return end
        visible = state
        if state then
            Holder.Visible = true
            Tween(RootCG, 0.25, { GroupTransparency = 0 })
        else
            local t = Tween(RootCG, 0.25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            t.Completed:Connect(function() if not visible then Holder.Visible = false end end)
        end
    end
    function Window:Toggle() Window:SetVisible(not visible) end
    function Library:ToggleVisibility() if Library.Window then Library.Window:Toggle() end end

    -- tab creation
    function Window:CreateTab(name)
        local Tab = { Window = self, Index = #self.Tabs + 1 }
        table.insert(self.Tabs, Tab)

        local btn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, Config.TabHeight), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, LayoutOrder = Tab.Index, Parent = ButtonHolder,
        })
        local btnLabel = Create("TextLabel", {
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -16, 1, 0),
            BackgroundTransparency = 1, Font = Config.Font, TextSize = 13,
            TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = name, Parent = btn,
        })
        btn.MouseEnter:Connect(function()
            if self.Selected ~= Tab then Tween(btnLabel, 0.15, { TextColor3 = Theme.Text }) end
        end)
        btn.MouseLeave:Connect(function()
            if self.Selected ~= Tab then Tween(btnLabel, 0.15, { TextColor3 = Theme.TextDim }) end
        end)
        btn.MouseButton1Click:Connect(function() self:SelectTab(Tab) end)

        local page = Create("CanvasGroup", {
            Visible = false, Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, GroupTransparency = 1, Parent = ContentHolder,
        })
        local scroll = Create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Stroke,
            ScrollingDirection = Enum.ScrollingDirection.Y, Parent = page,
        })
        Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = scroll,
        })

        Tab.Page, Tab.Button, Tab.ButtonLabel = page, btn, btnLabel
        AttachHost(Tab, scroll)
        function Tab:CreateSection(n) return CreateSection(scroll, n) end
        OnTheme(function()
            if self.Selected ~= Tab then btnLabel.TextColor3 = Theme.TextDim end
            scroll.ScrollBarImageColor3 = Theme.Stroke
        end)
        return Tab
    end

    function Window:SelectTab(tab)
        if self.Selected == tab then return end
        local prev = self.Selected
        self.Selected = tab
        if prev then
            prev.Page.Visible = false
            Tween(prev.ButtonLabel, 0.2, { TextColor3 = Theme.TextDim })
        end
        tab.Page.Visible = true
        tab.Page.GroupTransparency = 1
        Tween(tab.Page, 0.22, { GroupTransparency = 0 })
        Tween(tab.ButtonLabel, 0.2, { TextColor3 = Theme.Text })
        local target = UDim2.fromOffset(6, 6 + (tab.Index - 1) * (Config.TabHeight + Config.TabPadding))
        if prev then
            Tween(self.Indicator, Config.AnimationTime, { Position = target })
        else
            self.Indicator.Position = target
        end
    end

    OnTheme(function()
        Main.BackgroundColor3 = Theme.Background
        mainStroke.Color = Theme.Stroke
        divider.BackgroundColor3 = Theme.Stroke
        sideDivider.BackgroundColor3 = Theme.Stroke
        titleL.TextColor3 = Theme.Text
        subL.TextColor3 = Theme.TextDim
        logo.BackgroundColor3 = GetAccent()
        Indicator.BackgroundColor3 = GetAccent()
        indBar.BackgroundColor3 = GetAccent()
    end)

    -- opening animation
    RootCG.GroupTransparency = 1
    Holder.Position = Holder.Position - UDim2.fromOffset(0, 14)
    Tween(RootCG, 0.35, { GroupTransparency = 0 })
    Tween(Holder, 0.45, { Position = Holder.Position + UDim2.fromOffset(0, 14) }, Enum.EasingStyle.Quint)

    return Window
end

-- // SHUTDOWN (full cleanup: features off, connections dead, GUI destroyed) ---------------------------
function Library:Shutdown()
    for _, f in ipairs(FeatureList) do
        if f.Enabled then SetFeature(f, false) end
    end
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)
    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end
end

-- // FEATURE FRAMEWORK (optimized rewrites of ALL SCRIPTS.txt features) -------------------------------
local function NewFeature(name)
    local f = { Name = name, Enabled = false, Conns = {} }
    function f:Track(conn) self.Conns[conn] = true; return conn end
    function f:DisconnectAll()
        for conn in pairs(self.Conns) do pcall(function() conn:Disconnect() end) end
        table.clear(self.Conns)
    end
    table.insert(FeatureList, f)
    return f
end

SetFeature = function(f, state)
    if f.Enabled == state then return end
    f.Enabled = state
    local ok, err
    if state then ok, err = pcall(f.Enable) else ok, err = pcall(f.Disable) end
    if not ok then
        warn("[Aurora] " .. f.Name .. " error: " .. tostring(err))
        Library:Notify(f.Name, "An error occurred — check the console", 4, "Error")
    end
end

-- // FEATURE: Infinite Stamina (Player tab) ------------------------------------------------------------
local Stamina = NewFeature("Infinite Stamina")
function Stamina.Enable()
    local function setup(char)
        task.spawn(function()
            local handler = char:WaitForChild("ClientHandler", 10) or char:WaitForChild("Client", 10) or char:WaitForChild("ClientOLD", 10)
            if not handler or not Stamina.Enabled then return end
            local ok, State = pcall(require, handler:WaitForChild("State", 10))
            if not ok or typeof(State) ~= "table" or not Stamina.Enabled then return end
            Stamina:Track(RunService.Heartbeat:Connect(function()
                local st = State.stamina
                if st then
                    st.current = 200
                    st.regenDelay = 0
                    st.fullRegen = false
                    st.active = false
                    if st.exhausted ~= nil then st.exhausted = false end
                end
            end))
        end)
    end
    Stamina:Track(LocalPlayer.CharacterAdded:Connect(setup))
    if LocalPlayer.Character then setup(LocalPlayer.Character) end
end
function Stamina.Disable()
    Stamina:DisconnectAll() -- heartbeat + CharacterAdded fully disconnected
end

-- // FEATURE: Infinite NVG / Cloaker lock (Visuals tab) ---------------------------------------------------
local NVG = NewFeature("Infinite NVG")
NVG.Created = {}
function NVG.Enable()
    local function setup(char)
        local isCloaker = char:FindFirstChild("IsCloaker")
        if not isCloaker then
            isCloaker = Instance.new("BoolValue")
            isCloaker.Name = "IsCloaker"
            isCloaker.Value = true
            isCloaker.Parent = char
            table.insert(NVG.Created, isCloaker)
        else
            isCloaker.Value = true
        end
        NVG:Track(isCloaker.Changed:Connect(function(v)
            if v ~= true and NVG.Enabled then isCloaker.Value = true end
        end))
        NVG:Track(char.ChildAdded:Connect(function(child)
            if child.Name == "IsCloaker" and child:IsA("BoolValue") then
                child.Value = true
            end
        end))
    end
    NVG:Track(LocalPlayer.CharacterAdded:Connect(setup))
    if LocalPlayer.Character then setup(LocalPlayer.Character) end
end
function NVG.Disable()
    NVG:DisconnectAll()
    for _, v in ipairs(NVG.Created) do
        pcall(function() v:Destroy() end) -- remove only the BoolValues we created
    end
    table.clear(NVG.Created)
end

-- // FEATURE: AI Highlight + Health ESP (Visuals tab) -------------------------------------------------------
local ESP = NewFeature("AI Highlight")
ESP.Tracked = {}
ESP.MaxDistance = 150

local function espHighlight(v)
    if ESP.Tracked[v] then return end
    local humanoid = v:FindFirstChildOfClass("Humanoid")

    local highlight = Instance.new("Highlight")
    highlight.Name = "AI_Highlight"
    highlight.Adornee = v
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 1
    highlight.Parent = v

    local billboard, textLabel = nil, nil
    if humanoid then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "AI_HealthUI"
        billboard.Adornee = v
        billboard.Size = UDim2.new(0, 100, 0, 25)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = ESP.MaxDistance
        billboard.Parent = v

        textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billboard
    end

    local entry = { Highlight = highlight, Billboard = billboard, Conns = {} }
    local function cleanup()
        if ESP.Tracked[v] ~= entry then return end
        ESP.Tracked[v] = nil
        for c in pairs(entry.Conns) do pcall(function() c:Disconnect() end) end
        pcall(function() highlight:Destroy() end)
        pcall(function() if billboard then billboard:Destroy() end end)
    end

    if humanoid then
        -- OPTIMIZATION: event-driven health updates instead of a 0.2s polling loop
        local function refresh()
            if humanoid.Health <= 0 then
                cleanup()
                return
            end
            textLabel.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
        end
        entry.Conns[humanoid:GetPropertyChangedSignal("Health"):Connect(refresh)] = true
        entry.Conns[humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(refresh)] = true
        refresh()
    end
    entry.Conns[v.Destroying:Connect(cleanup)] = true
    ESP.Tracked[v] = entry
end

local function espStart(folder)
    -- clear leftovers from any previous execution
    for _, v in ipairs(folder:GetChildren()) do
        for _, child in ipairs(v:GetChildren()) do
            if child:IsA("Highlight") or child:IsA("BillboardGui") then child:Destroy() end
        end
    end
    for _, v in ipairs(folder:GetChildren()) do
        if v:FindFirstChild("AI") then espHighlight(v) end
    end
    -- OPTIMIZATION: event-driven spawn detection instead of task.wait(0.1) polling
    ESP:Track(folder.ChildAdded:Connect(function(v)
        task.spawn(function()
            if v:WaitForChild("AI", 10) and ESP.Enabled then espHighlight(v) end
        end)
    end))
end

function ESP.Enable()
    local folder = workspace:FindFirstChild("Characters")
    if not folder then
        task.delay(3, function()
            if not ESP.Enabled then return end
            local retry = workspace:FindFirstChild("Characters")
            if retry then
                espStart(retry)
            else
                Library:Notify("AI Highlight", "workspace.Characters not found in this game", 4, "Warning")
                if Flags["feat_esp"] then Flags["feat_esp"]:Set(false) end
            end
        end)
        return
    end
    espStart(folder)
end
function ESP.Disable()
    ESP:DisconnectAll()
    for _, entry in pairs(ESP.Tracked) do
        for c in pairs(entry.Conns) do pcall(function() c:Disconnect() end) end
        if entry.Highlight then pcall(function() entry.Highlight:Destroy() end) end
        if entry.Billboard then pcall(function() entry.Billboard:Destroy() end) end
    end
    table.clear(ESP.Tracked)
end

-- // FEATURE: Hitbox Extender (Combat tab) ------------------------------------------------------------------
local Hitbox = NewFeature("Hitbox Extender")
Hitbox.TargetSize = 4
Hitbox.OriginalSizes = setmetatable({}, { __mode = "k" }) -- weak keys: no leaks from destroyed parts
Hitbox.NameConns = setmetatable({}, { __mode = "k" })

local function hitboxApply(part)
    if not (part and part:IsA("BasePart")) or part.Name ~= "Head" then return end
    local model = part.Parent
    if not (model and model:IsA("Model")) then return end
    if not model:FindFirstChildWhichIsA("Humanoid") then return end
    if Players:GetPlayerFromCharacter(model) then return end
    if Hitbox.OriginalSizes[part] == nil then
        Hitbox.OriginalSizes[part] = part.Size
    end
    pcall(function()
        local s = Hitbox.TargetSize
        part.Size = Vector3.new(s, s, s)
        part.CanCollide = false
        part.Transparency = 0.5
    end)
end

function Hitbox.Enable()
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") then
            hitboxApply(desc)
            Hitbox.NameConns[desc] = desc:GetPropertyChangedSignal("Name"):Connect(function()
                hitboxApply(desc)
            end)
        end
    end
    Hitbox:Track(workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            hitboxApply(desc)
            Hitbox.NameConns[desc] = desc:GetPropertyChangedSignal("Name"):Connect(function()
                hitboxApply(desc)
            end)
        end
    end))
end
function Hitbox.Disable()
    Hitbox:DisconnectAll()
    for part, conn in pairs(Hitbox.NameConns) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Hitbox.NameConns)
    for part, size in pairs(Hitbox.OriginalSizes) do
        pcall(function()
            if part and part.Parent then
                part.Size = size
                part.CanCollide = true
                part.Transparency = 0
            end
        end)
    end
    table.clear(Hitbox.OriginalSizes)
end

-- // BOOTSTRAP: BUILD THE UI + WIRE EVERY FEATURE --------------------------------------------------------------
Library:Load()
if SavedData and typeof(SavedData.Theme) == "string" and Themes[SavedData.Theme] then
    ApplyTheme(SavedData.Theme)
end

local Window = Library:CreateWindow(Config.WindowName, Config.WindowSubtitle)

-- PLAYER TAB
local playerTab = Window:CreateTab("Player")
local stamSec = playerTab:CreateSection("Stamina")
stamSec:CreateToggle({
    Name = "Infinite Stamina",
    Flag = "feat_stamina",
    Default = false,
    Callback = function(v) SetFeature(Stamina, v) end,
})
stamSec:CreateParagraph({
    Text = "Locks your character's ClientHandler stamina state at 200 with instant regen. Re-applies automatically on respawn.",
})

-- VISUALS TAB
local visTab = Window:CreateTab("Visuals")
local espSec = visTab:CreateSection("AI ESP")
espSec:CreateToggle({
    Name = "AI Highlight + Health ESP",
    Flag = "feat_esp",
    Default = false,
    Callback = function(v) SetFeature(ESP, v) end,
})
espSec:CreateSlider({
    Name = "ESP Max Distance",
    Flag = "esp_distance",
    Min = 25, Max = 1000, Default = 150, Increment = 25, Suffix = " studs",
    Callback = function(v)
        ESP.MaxDistance = v
        for _, entry in pairs(ESP.Tracked) do
            if entry.Billboard then entry.Billboard.MaxDistance = v end
        end
    end,
})
local nvgSec = visTab:CreateSection("Night Vision")
nvgSec:CreateToggle({
    Name = "Infinite NVG (Cloaker)",
    Flag = "feat_nvg",
    Default = false,
    Callback = function(v) SetFeature(NVG, v) end,
})
nvgSec:CreateParagraph({
    Text = "Forces the IsCloaker BoolValue on your character to true and re-locks it whenever the game tries to change it.",
})

-- COMBAT TAB
local combatTab = Window:CreateTab("Combat")
local hbSec = combatTab:CreateSection("Hitbox")
hbSec:CreateToggle({
    Name = "Hitbox Extender",
    Flag = "feat_hitbox",
    Default = false,
    Callback = function(v) SetFeature(Hitbox, v) end,
})
hbSec:CreateSlider({
    Name = "Hitbox Size",
    Flag = "hitbox_size",
    Min = 1, Max = 10, Default = 4, Increment = 0.5, Suffix = "x",
    Callback = function(v)
        Hitbox.TargetSize = v
        local size = Vector3.new(v, v, v)
        for part in pairs(Hitbox.OriginalSizes) do
            pcall(function() part.Size = size end)
        end
    end,
})
hbSec:CreateParagraph({
    Text = "Enlarges the Head hitbox of every non-player humanoid model, sets it non-collidable and semi-transparent. Original sizes are restored when disabled.",
})

-- SETTINGS TAB
local settingsTab = Window:CreateTab("Settings")
local appearanceSec = settingsTab:CreateSection("Appearance")
local themeNames = {}
for k in pairs(Themes) do table.insert(themeNames, k) end
table.sort(themeNames)
appearanceSec:CreateDropdown({
    Name = "Theme",
    Flag = "ui_theme",
    Options = themeNames,
    Default = "Dark",
    Callback = function(v) ApplyTheme(v) end,
})
appearanceSec:CreateColorPicker({
    Name = "Accent Color",
    Flag = "ui_accent",
    Default = GetAccent(),
    Callback = function(c) Library:SetAccent(c) end,
})
appearanceSec:CreateButton({
    Name = "Reset Accent Color",
    Callback = function()
        if Flags["ui_accent"] then Flags["ui_accent"]:Set(Themes[CurrentThemeName].Accent) end
    end,
})

local interfaceSec = settingsTab:CreateSection("Interface")
interfaceSec:CreateKeybind({
    Name = "Toggle UI Visibility",
    Flag = "ui_togglekey",
    Default = Config.ToggleKey,
    Callback = function() Window:Toggle() end,
})
interfaceSec:CreateButton({
    Name = "Save Settings",
    Callback = function()
        Library:Save()
        Library:Notify("Aurora", "Settings saved to disk", 3, "Success")
    end,
})
interfaceSec:CreateButton({
    Name = "Unload / Destroy UI",
    Callback = function()
        Library:Notify("Aurora", "Unloading...", 2, "Info")
        task.delay(0.2, function() Library:Shutdown() end)
    end,
})
settingsTab:CreateParagraph({
    Text = "Aurora UI v1.0 — all toggle states, slider values, theme and accent persist between sessions via executor file I/O when available. Press your Toggle UI keybind (default RightShift) to show/hide.",
})

Window:SelectTab(Window.Tabs[1])
Library:Notify("Aurora", "Loaded — press RightShift to toggle the UI", 4, "Success")