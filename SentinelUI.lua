--[[
╔══════════════════════════════════════════════════════════════╗
║                     SENTINEL UI LIBRARY                      ║
║              Single-Script • No External Deps                ║
║         Features from ALL_SCRIPTS.txt fully wired           ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- // SERVICES
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local Workspace       = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- // THEME CONFIG
-- ============================================================
local Library = {}
Library.__index = Library

Library.Theme = {
    -- Base palette
    Background     = Color3.fromRGB(13,  13,  18),
    Surface        = Color3.fromRGB(20,  20,  28),
    SurfaceHigh    = Color3.fromRGB(28,  28,  40),
    SurfaceBorder  = Color3.fromRGB(40,  40,  58),

    -- Accent (swappable)
    Accent         = Color3.fromRGB(99,  102, 241),  -- Indigo
    AccentDim      = Color3.fromRGB(60,  63,  160),
    AccentGlow     = Color3.fromRGB(140, 143, 255),

    -- Text
    TextPrimary    = Color3.fromRGB(235, 235, 245),
    TextSecondary  = Color3.fromRGB(140, 140, 165),
    TextMuted      = Color3.fromRGB(80,  80,  105),

    -- Semantic
    Success        = Color3.fromRGB(52,  199, 89),
    Warning        = Color3.fromRGB(255, 159, 10),
    Error          = Color3.fromRGB(255, 59,  48),

    -- Toggle
    ToggleOff      = Color3.fromRGB(45,  45,  62),
    ToggleOn       = Color3.fromRGB(99,  102, 241),

    -- Misc
    CornerRadius   = UDim.new(0, 10),
    StrokeThick    = 1,
    AnimSpeed      = 0.18,
    AnimEase       = Enum.EasingStyle.Quint,
    Font           = Enum.Font.GothamBold,
    FontBody       = Enum.Font.Gotham,
}

Library.Themes = {
    Dark = {
        Background    = Color3.fromRGB(13,  13,  18),
        Surface       = Color3.fromRGB(20,  20,  28),
        SurfaceHigh   = Color3.fromRGB(28,  28,  40),
        SurfaceBorder = Color3.fromRGB(40,  40,  58),
        Accent        = Color3.fromRGB(99,  102, 241),
        AccentDim     = Color3.fromRGB(60,  63,  160),
        AccentGlow    = Color3.fromRGB(140, 143, 255),
    },
    Midnight = {
        Background    = Color3.fromRGB(6,   8,   24),
        Surface       = Color3.fromRGB(10,  12,  35),
        SurfaceHigh   = Color3.fromRGB(16,  20,  50),
        SurfaceBorder = Color3.fromRGB(30,  35,  80),
        Accent        = Color3.fromRGB(120, 80,  255),
        AccentDim     = Color3.fromRGB(70,  45,  180),
        AccentGlow    = Color3.fromRGB(170, 140, 255),
    },
    Ocean = {
        Background    = Color3.fromRGB(5,   18,  30),
        Surface       = Color3.fromRGB(8,   26,  44),
        SurfaceHigh   = Color3.fromRGB(12,  38,  60),
        SurfaceBorder = Color3.fromRGB(20,  60,  90),
        Accent        = Color3.fromRGB(0,   195, 210),
        AccentDim     = Color3.fromRGB(0,   120, 135),
        AccentGlow    = Color3.fromRGB(80,  230, 240),
    },
    Bloodmoon = {
        Background    = Color3.fromRGB(18,  5,   5),
        Surface       = Color3.fromRGB(28,  8,   8),
        SurfaceHigh   = Color3.fromRGB(40,  12,  12),
        SurfaceBorder = Color3.fromRGB(70,  18,  18),
        Accent        = Color3.fromRGB(220, 38,  38),
        AccentDim     = Color3.fromRGB(140, 20,  20),
        AccentGlow    = Color3.fromRGB(255, 90,  90),
    },
}

-- Window size defaults
Library.Config = {
    WindowWidth    = 580,
    WindowHeight   = 440,
    TabBarWidth    = 140,
    MinWidth       = 420,
    MinHeight      = 300,
    MaxWidth       = 900,
    MaxHeight      = 700,
    ToggleKey      = Enum.KeyCode.RightShift,
    SaveFile       = "sentinel_settings.json",
}

-- ============================================================
-- // UTILITY
-- ============================================================
local function tween(obj, props, dur, style, dir)
    dur   = dur   or Library.Theme.AnimSpeed
    style = style or Library.Theme.AnimEase
    dir   = dir   or Enum.EasingDirection.Out
    local info = TweenInfo.new(dur, style, dir)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Library.Theme.CornerRadius
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.Theme.SurfaceBorder
    s.Thickness = thick or Library.Theme.StrokeThick
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function makeShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.55
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = parent
    return shadow
end

local function newLabel(text, size, color, font, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size or 14
    l.TextColor3 = color or Library.Theme.TextPrimary
    l.Font = font or Library.Theme.FontBody
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, size and size + 4 or 18)
    if parent then l.Parent = parent end
    return l
end

-- ============================================================
-- // NOTIFICATION SYSTEM
-- ============================================================
local NotifHolder

local function initNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "SentinelNotifs"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    NotifHolder = Instance.new("Frame")
    NotifHolder.Name = "Holder"
    NotifHolder.BackgroundTransparency = 1
    NotifHolder.AnchorPoint = Vector2.new(1, 1)
    NotifHolder.Position = UDim2.new(1, -16, 1, -16)
    NotifHolder.Size = UDim2.new(0, 300, 1, 0)
    NotifHolder.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 8)
    layout.Parent = NotifHolder
end

function Library:Notify(opts)
    opts = opts or {}
    local title    = opts.Title   or "Sentinel"
    local msg      = opts.Message or ""
    local duration = opts.Duration or 4
    local variant  = opts.Type or "info"  -- "success" | "warning" | "error" | "info"
    local T = Library.Theme

    initNotifHolder()

    local accentColor = ({
        success = T.Success,
        warning = T.Warning,
        error   = T.Error,
        info    = T.Accent,
    })[variant] or T.Accent

    local frame = Instance.new("Frame")
    frame.Name = "Notif"
    frame.BackgroundColor3 = T.SurfaceHigh
    frame.Size = UDim2.new(1, 0, 0, 72)
    frame.BackgroundTransparency = 1
    frame.Parent = NotifHolder
    makeCorner(frame, UDim.new(0, 8))
    makeStroke(frame, T.SurfaceBorder)
    makeShadow(frame)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -16)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Position = UDim2.new(0, 8, 0.5, 0)
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel = 0
    bar.Parent = frame
    makeCorner(bar, UDim.new(0, 3))

    local titleLbl = newLabel(title, 14, T.TextPrimary, T.Font, frame)
    titleLbl.Position = UDim2.new(0, 20, 0, 14)
    titleLbl.Size = UDim2.new(1, -28, 0, 16)

    local msgLbl = newLabel(msg, 12, T.TextSecondary, T.FontBody, frame)
    msgLbl.Position = UDim2.new(0, 20, 0, 34)
    msgLbl.Size = UDim2.new(1, -28, 0, 26)
    msgLbl.TextWrapped = true

    -- Slide in
    frame.Position = UDim2.new(1, 320, 0, 0)
    tween(frame, {BackgroundTransparency = 0}, 0.2)
    tween(frame, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Back)

    task.delay(duration, function()
        tween(frame, {BackgroundTransparency = 1, Position = UDim2.new(1, 320, 0, 0)}, 0.24)
        task.wait(0.26)
        frame:Destroy()
    end)

    return frame
end

-- ============================================================
-- // SETTINGS PERSISTENCE
-- ============================================================
local SavedSettings = {}

local function saveSettings()
    pcall(function()
        if writefile then
            writefile(Library.Config.SaveFile, HttpService:JSONEncode(SavedSettings))
        end
    end)
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(Library.Config.SaveFile) then
            local raw = readfile(Library.Config.SaveFile)
            SavedSettings = HttpService:JSONDecode(raw) or {}
        end
    end)
end

loadSettings()

-- ============================================================
-- // WINDOW CREATION
-- ============================================================
function Library:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "Sentinel"
    local subtitle = opts.Subtitle or "v1.0"
    local T        = Library.Theme
    local C        = Library.Config

    -- Root ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "SentinelUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 10
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main window frame
    local win = Instance.new("Frame")
    win.Name = "Window"
    win.Size = UDim2.new(0, C.WindowWidth, 0, C.WindowHeight)
    win.Position = UDim2.new(0.5, -C.WindowWidth/2, 0.5, -C.WindowHeight/2)
    win.BackgroundColor3 = T.Background
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = sg
    makeCorner(win, UDim.new(0, 12))
    makeStroke(win, T.SurfaceBorder, 1)
    makeShadow(win)

    -- Backdrop gradient for depth
    local grad = Instance.new("UIGradient")
    grad.Rotation = 125
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(25, 25, 38)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(13, 13, 18)),
    })
    grad.Parent = win

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 48)
    topBar.BackgroundColor3 = T.Surface
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 3
    topBar.Parent = win

    local topGrad = Instance.new("UIGradient")
    topGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30)),
    })
    topGrad.Parent = topBar

    -- Accent line under top bar
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 1)
    accentLine.Position = UDim2.new(0, 0, 1, -1)
    accentLine.BackgroundColor3 = T.Accent
    accentLine.BorderSizePixel = 0
    accentLine.BackgroundTransparency = 0.5
    accentLine.Parent = topBar

    -- Logo dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 16, 0.5, -4)
    dot.BackgroundColor3 = T.Accent
    dot.BorderSizePixel = 0
    dot.Parent = topBar
    makeCorner(dot, UDim.new(1, 0))

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 32, 0, 8)
    titleLbl.Size = UDim2.new(0, 200, 0, 18)
    titleLbl.Text = title
    titleLbl.TextColor3 = T.TextPrimary
    titleLbl.Font = T.Font
    titleLbl.TextSize = 15
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = topBar

    local subtitleLbl = Instance.new("TextLabel")
    subtitleLbl.BackgroundTransparency = 1
    subtitleLbl.Position = UDim2.new(0, 32, 0, 28)
    subtitleLbl.Size = UDim2.new(0, 200, 0, 13)
    subtitleLbl.Text = subtitle
    subtitleLbl.TextColor3 = T.TextMuted
    subtitleLbl.Font = T.FontBody
    subtitleLbl.TextSize = 11
    subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLbl.Parent = topBar

    -- Close button
    local function makeTopBtn(icon, xOffset, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.Position = UDim2.new(1, xOffset, 0.5, -14)
        btn.BackgroundColor3 = T.SurfaceHigh
        btn.Text = icon
        btn.TextColor3 = color or T.TextSecondary
        btn.Font = T.Font
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = topBar
        makeCorner(btn, UDim.new(0, 6))
        btn.MouseEnter:Connect(function()
            tween(btn, {BackgroundColor3 = color or T.Accent}, 0.12)
            tween(btn, {TextColor3 = T.TextPrimary}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, {BackgroundColor3 = T.SurfaceHigh}, 0.12)
            tween(btn, {TextColor3 = color or T.TextSecondary}, 0.12)
        end)
        return btn
    end

    local closeBtn = makeTopBtn("✕", -12, T.Error)
    local minBtn   = makeTopBtn("−", -48, T.Warning)

    local minimized = false
    local originalSize = win.Size

    closeBtn.MouseButton1Click:Connect(function()
        tween(win, {Size = UDim2.new(0, C.WindowWidth, 0, 0), BackgroundTransparency = 1}, 0.2)
        task.wait(0.22)
        sg:Destroy()
    end)

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(win, {Size = UDim2.new(0, C.WindowWidth, 0, 48)}, 0.22, Enum.EasingStyle.Quint)
        else
            tween(win, {Size = originalSize}, 0.22, Enum.EasingStyle.Back)
        end
    end)

    -- Drag logic
    local dragStart, startPos, dragging
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = win.Position
        end
    end)
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize

        local newX = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - C.WindowWidth)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - 48)
        win.Position = UDim2.new(0, newX, 0, newY)
    end)

    -- Resize handle
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, -2, 1, -2)
    resizeHandle.BackgroundColor3 = T.SurfaceBorder
    resizeHandle.Text = "⌟"
    resizeHandle.TextColor3 = T.TextMuted
    resizeHandle.TextSize = 12
    resizeHandle.Font = T.FontBody
    resizeHandle.BorderSizePixel = 0
    resizeHandle.AutoButtonColor = false
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = win
    makeCorner(resizeHandle, UDim.new(0, 4))

    local resizing, resizeStart, resizeWinStart
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing       = true
            resizeStart    = input.Position
            resizeWinStart = win.AbsoluteSize
        end
    end)
    resizeHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - resizeStart
        local newW  = math.clamp(resizeWinStart.X + delta.X, C.MinWidth, C.MaxWidth)
        local newH  = math.clamp(resizeWinStart.Y + delta.Y, C.MinHeight, C.MaxHeight)
        win.Size = UDim2.new(0, newW, 0, newH)
        originalSize = win.Size
    end)

    -- Toggle key
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == (opts.ToggleKey or C.ToggleKey) then
            win.Visible = not win.Visible
        end
    end)

    -- Sidebar (tab bar)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.Size = UDim2.new(0, C.TabBarWidth, 1, -48)
    sidebar.BackgroundColor3 = T.Surface
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
    sidebar.Parent = win

    local sideGrad = Instance.new("UIGradient")
    sideGrad.Rotation = 90
    sideGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 26)),
    })
    sideGrad.Parent = sidebar

    -- Sidebar divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0, 1, 1, 0)
    divider.Position = UDim2.new(1, -1, 0, 0)
    divider.BackgroundColor3 = T.SurfaceBorder
    divider.BorderSizePixel = 0
    divider.Parent = sidebar

    local tabList = Instance.new("Frame")
    tabList.Name = "TabList"
    tabList.Size = UDim2.new(1, 0, 1, -12)
    tabList.Position = UDim2.new(0, 0, 0, 12)
    tabList.BackgroundTransparency = 1
    tabList.Parent = sidebar
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabList
    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 8)
    tabPad.PaddingRight = UDim.new(0, 8)
    tabPad.Parent = tabList

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.new(0, C.TabBarWidth, 0, 48)
    content.Size = UDim2.new(1, -C.TabBarWidth, 1, -48)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = win

    -- Open animation
    win.Size = UDim2.new(0, C.WindowWidth, 0, 0)
    win.BackgroundTransparency = 1
    tween(win, {Size = UDim2.new(0, C.WindowWidth, 0, C.WindowHeight), BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Back)

    -- -------------------------------------------------------
    -- Window object returned to caller
    -- -------------------------------------------------------
    local Window = {}
    Window._tabs    = {}
    Window._active  = nil
    Window._sg      = sg
    Window._win     = win

    function Window:ApplyTheme(themeName)
        local th = Library.Themes[themeName]
        if not th then return end
        for k, v in pairs(th) do
            Library.Theme[k] = v
        end
        Library:Notify({Title = "Theme Applied", Message = themeName, Type = "info", Duration = 2})
    end

    function Window:CreateTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Name or "Tab"
        local tabIcon = tabOpts.Icon or "●"
        local T = Library.Theme

        -- Tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name  = tabName
        tabBtn.Size  = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = T.Surface
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text  = ""
        tabBtn.AutoButtonColor = false
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabList
        makeCorner(tabBtn, UDim.new(0, 8))

        -- Active indicator bar
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0.6, 0)
        indicator.AnchorPoint = Vector2.new(0, 0.5)
        indicator.Position = UDim2.new(0, 0, 0.5, 0)
        indicator.BackgroundColor3 = T.Accent
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = 1
        indicator.Parent = tabBtn
        makeCorner(indicator, UDim.new(0, 3))

        local iconLbl = Instance.new("TextLabel")
        iconLbl.BackgroundTransparency = 1
        iconLbl.Position = UDim2.new(0, 10, 0, 0)
        iconLbl.Size = UDim2.new(0, 20, 1, 0)
        iconLbl.Text = tabIcon
        iconLbl.TextColor3 = T.TextMuted
        iconLbl.Font = T.FontBody
        iconLbl.TextSize = 14
        iconLbl.Parent = tabBtn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position = UDim2.new(0, 34, 0, 0)
        nameLbl.Size = UDim2.new(1, -38, 1, 0)
        nameLbl.Text = tabName
        nameLbl.TextColor3 = T.TextMuted
        nameLbl.Font = T.FontBody
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = tabBtn

        -- Tab page (scroll frame for content)
        local page = Instance.new("ScrollingFrame")
        page.Name  = tabName .. "Page"
        page.Size  = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = T.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 10)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page
        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingLeft  = UDim.new(0, 14)
        pagePad.PaddingRight = UDim.new(0, 14)
        pagePad.PaddingTop   = UDim.new(0, 12)
        pagePad.PaddingBottom = UDim.new(0, 12)
        pagePad.Parent = page

        local function activate()
            -- Deactivate all tabs
            for _, t in ipairs(Window._tabs) do
                t._page.Visible = false
                tween(t._indicator, {BackgroundTransparency = 1}, 0.15)
                tween(t._icon, {TextColor3 = T.TextMuted}, 0.15)
                tween(t._name, {TextColor3 = T.TextMuted}, 0.15)
                tween(t._btn, {BackgroundTransparency = 1}, 0.15)
            end
            -- Activate this tab
            page.Visible = true
            tween(indicator, {BackgroundTransparency = 0}, 0.18)
            tween(iconLbl, {TextColor3 = T.AccentGlow}, 0.18)
            tween(nameLbl, {TextColor3 = T.TextPrimary}, 0.18)
            tween(tabBtn, {BackgroundTransparency = 0.88}, 0.18)
            Window._active = tabName
        end

        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if Window._active ~= tabName then
                tween(tabBtn, {BackgroundTransparency = 0.94}, 0.12)
                tween(nameLbl, {TextColor3 = T.TextSecondary}, 0.12)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active ~= tabName then
                tween(tabBtn, {BackgroundTransparency = 1}, 0.12)
                tween(nameLbl, {TextColor3 = T.TextMuted}, 0.12)
            end
        end)

        local tabEntry = {
            _btn       = tabBtn,
            _indicator = indicator,
            _icon      = iconLbl,
            _name      = nameLbl,
            _page      = page,
        }
        table.insert(Window._tabs, tabEntry)

        -- Auto-select first tab
        if #Window._tabs == 1 then
            activate()
        end

        -- -------------------------------------------------------
        -- Tab object
        -- -------------------------------------------------------
        local Tab = {}

        function Tab:CreateSection(secOpts)
            secOpts = secOpts or {}
            local secName = secOpts.Name or "Section"
            local T = Library.Theme

            local section = Instance.new("Frame")
            section.Name = secName
            section.BackgroundColor3 = T.SurfaceHigh
            section.Size = UDim2.new(1, 0, 0, 0)
            section.AutomaticSize = Enum.AutomaticSize.Y
            section.BorderSizePixel = 0
            section.Parent = page
            makeCorner(section, UDim.new(0, 8))
            makeStroke(section, T.SurfaceBorder)

            -- Section header
            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 34)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.AutoButtonColor = false
            header.BorderSizePixel = 0
            header.Parent = section

            local headerLbl = newLabel("  " .. secName, 13, T.TextSecondary, T.Font, header)
            headerLbl.Size = UDim2.new(1, -30, 1, 0)
            headerLbl.Position = UDim2.new(0, 0, 0, 0)

            local chevron = Instance.new("TextLabel")
            chevron.BackgroundTransparency = 1
            chevron.AnchorPoint = Vector2.new(1, 0.5)
            chevron.Position = UDim2.new(1, -10, 0.5, 0)
            chevron.Size = UDim2.new(0, 16, 0, 16)
            chevron.Text = "▾"
            chevron.TextColor3 = T.TextMuted
            chevron.Font = T.FontBody
            chevron.TextSize = 12
            chevron.Parent = header

            local divLine = Instance.new("Frame")
            divLine.Size = UDim2.new(1, -20, 0, 1)
            divLine.Position = UDim2.new(0, 10, 0, 33)
            divLine.BackgroundColor3 = T.SurfaceBorder
            divLine.BorderSizePixel = 0
            divLine.Parent = section

            local body = Instance.new("Frame")
            body.Name = "Body"
            body.BackgroundTransparency = 1
            body.Position = UDim2.new(0, 0, 0, 34)
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.ClipsDescendants = true
            body.Parent = section

            local bodyLayout = Instance.new("UIListLayout")
            bodyLayout.Padding = UDim.new(0, 8)
            bodyLayout.Parent = body
            local bodyPad = Instance.new("UIPadding")
            bodyPad.PaddingLeft   = UDim.new(0, 12)
            bodyPad.PaddingRight  = UDim.new(0, 12)
            bodyPad.PaddingTop    = UDim.new(0, 8)
            bodyPad.PaddingBottom = UDim.new(0, 10)
            bodyPad.Parent = body

            local collapsed = false
            local bodyHeight = 0

            local function updateBodyHeight()
                task.wait()
                bodyHeight = body.AbsoluteSize.Y
            end

            header.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                if collapsed then
                    updateBodyHeight()
                    tween(body, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    tween(divLine, {BackgroundTransparency = 1}, 0.2)
                    tween(chevron, {Rotation = -90, TextColor3 = T.TextMuted}, 0.2)
                else
                    body.AutomaticSize = Enum.AutomaticSize.Y
                    tween(divLine, {BackgroundTransparency = 0}, 0.2)
                    tween(chevron, {Rotation = 0, TextColor3 = T.TextMuted}, 0.2)
                end
            end)

            -- -------------------------------------------------------
            -- Section object
            -- -------------------------------------------------------
            local Section = {}

            -- TOGGLE
            function Section:CreateToggle(togOpts)
                togOpts = togOpts or {}
                local togName     = togOpts.Name or "Toggle"
                local togDefault  = togOpts.Default or false
                local togCallback = togOpts.Callback or function() end
                local saveKey     = togOpts.SaveKey

                if saveKey and SavedSettings[saveKey] ~= nil then
                    togDefault = SavedSettings[saveKey]
                end

                local state = togDefault
                local T     = Library.Theme

                local row = Instance.new("Frame")
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 34)
                row.Parent = body
                makeCorner(row, UDim.new(0, 6))

                local lbl = newLabel(togName, 13, T.TextPrimary, T.FontBody, row)
                lbl.Size = UDim2.new(1, -58, 1, 0)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                -- Toggle track
                local track = Instance.new("Frame")
                track.AnchorPoint = Vector2.new(1, 0.5)
                track.Position = UDim2.new(1, 0, 0.5, 0)
                track.Size = UDim2.new(0, 44, 0, 22)
                track.BackgroundColor3 = state and T.ToggleOn or T.ToggleOff
                track.BorderSizePixel = 0
                track.Parent = row
                makeCorner(track, UDim.new(1, 0))
                makeStroke(track, T.SurfaceBorder)

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 16, 0, 16)
                knob.AnchorPoint = Vector2.new(0, 0.5)
                knob.Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.Parent = track
                makeCorner(knob, UDim.new(1, 0))

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.ZIndex = 5
                btn.Parent = row

                local function setState(newState, silent)
                    state = newState
                    tween(track, {BackgroundColor3 = state and T.ToggleOn or T.ToggleOff}, 0.18)
                    tween(knob, {
                        Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                    }, 0.18, Enum.EasingStyle.Back)
                    if not silent then
                        pcall(togCallback, state)
                        if saveKey then
                            SavedSettings[saveKey] = state
                            saveSettings()
                        end
                    end
                end

                btn.MouseButton1Click:Connect(function() setState(not state) end)
                btn.MouseEnter:Connect(function()
                    tween(row, {BackgroundTransparency = 0.92}, 0.1)
                    tween(row, {BackgroundColor3 = T.SurfaceHigh}, 0.1)
                end)
                btn.MouseLeave:Connect(function()
                    tween(row, {BackgroundTransparency = 1}, 0.1)
                end)

                -- Fire initial callback
                if togDefault then
                    task.defer(function() pcall(togCallback, togDefault) end)
                end

                local Toggle = {}
                function Toggle:Set(v) setState(v, false) end
                function Toggle:Get() return state end
                return Toggle
            end

            -- BUTTON
            function Section:CreateButton(btnOpts)
                btnOpts = btnOpts or {}
                local btnName     = btnOpts.Name or "Button"
                local btnCallback = btnOpts.Callback or function() end
                local T = Library.Theme

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 34)
                btn.BackgroundColor3 = T.SurfaceHigh
                btn.Text = btnName
                btn.TextColor3 = T.TextPrimary
                btn.Font = T.FontBody
                btn.TextSize = 13
                btn.AutoButtonColor = false
                btn.BorderSizePixel = 0
                btn.Parent = body
                makeCorner(btn, UDim.new(0, 6))
                makeStroke(btn, T.SurfaceBorder)

                btn.MouseEnter:Connect(function()
                    tween(btn, {BackgroundColor3 = T.AccentDim}, 0.12)
                    tween(btn, {TextColor3 = T.AccentGlow}, 0.12)
                end)
                btn.MouseLeave:Connect(function()
                    tween(btn, {BackgroundColor3 = T.SurfaceHigh}, 0.12)
                    tween(btn, {TextColor3 = T.TextPrimary}, 0.12)
                end)
                btn.MouseButton1Down:Connect(function()
                    tween(btn, {BackgroundColor3 = T.Accent, Size = UDim2.new(1, -4, 0, 32)}, 0.08)
                end)
                btn.MouseButton1Up:Connect(function()
                    tween(btn, {BackgroundColor3 = T.AccentDim, Size = UDim2.new(1, 0, 0, 34)}, 0.12, Enum.EasingStyle.Back)
                    pcall(btnCallback)
                end)

                return btn
            end

            -- SLIDER
            function Section:CreateSlider(slOpts)
                slOpts = slOpts or {}
                local slName     = slOpts.Name     or "Slider"
                local slMin      = slOpts.Min      or 0
                local slMax      = slOpts.Max      or 100
                local slDefault  = slOpts.Default  or slMin
                local slStep     = slOpts.Step     or 1
                local slCallback = slOpts.Callback or function() end
                local saveKey    = slOpts.SaveKey
                local T = Library.Theme

                if saveKey and SavedSettings[saveKey] ~= nil then
                    slDefault = SavedSettings[saveKey]
                end

                local value = slDefault

                local container = Instance.new("Frame")
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(1, 0, 0, 46)
                container.Parent = body

                local lbl = newLabel(slName, 13, T.TextPrimary, T.FontBody, container)
                lbl.Size = UDim2.new(0.7, 0, 0, 18)

                local valLbl = Instance.new("TextLabel")
                valLbl.BackgroundTransparency = 1
                valLbl.AnchorPoint = Vector2.new(1, 0)
                valLbl.Position = UDim2.new(1, 0, 0, 0)
                valLbl.Size = UDim2.new(0.3, 0, 0, 18)
                valLbl.Text = tostring(value)
                valLbl.TextColor3 = T.Accent
                valLbl.Font = T.Font
                valLbl.TextSize = 13
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Parent = container

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 26)
                track.BackgroundColor3 = T.SurfaceBorder
                track.BorderSizePixel = 0
                track.Parent = container
                makeCorner(track, UDim.new(1, 0))

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((value - slMin) / (slMax - slMin), 0, 1, 0)
                fill.BackgroundColor3 = T.Accent
                fill.BorderSizePixel = 0
                fill.Parent = track
                makeCorner(fill, UDim.new(1, 0))

                local handle = Instance.new("Frame")
                handle.Size = UDim2.new(0, 14, 0, 14)
                handle.AnchorPoint = Vector2.new(0.5, 0.5)
                handle.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
                handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                handle.BorderSizePixel = 0
                handle.ZIndex = 3
                handle.Parent = track
                makeCorner(handle, UDim.new(1, 0))

                local inputBtn = Instance.new("TextButton")
                inputBtn.Size = UDim2.new(1, 0, 1, 0)
                inputBtn.BackgroundTransparency = 1
                inputBtn.Text = ""
                inputBtn.ZIndex = 5
                inputBtn.Parent = track

                local draggingSlider = false

                local function updateSlider(inputPos)
                    local rel = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local raw = slMin + (slMax - slMin) * rel
                    local stepped = math.round(raw / slStep) * slStep
                    value = math.clamp(stepped, slMin, slMax)
                    local pct = (value - slMin) / (slMax - slMin)
                    tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.06)
                    tween(handle, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.06)
                    valLbl.Text = tostring(value)
                    pcall(slCallback, value)
                    if saveKey then SavedSettings[saveKey] = value; saveSettings() end
                end

                inputBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        updateSlider(input.Position)
                    end
                end)
                inputBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input.Position)
                    end
                end)

                local Slider = {}
                function Slider:Set(v)
                    value = math.clamp(v, slMin, slMax)
                    local pct = (value - slMin) / (slMax - slMin)
                    tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.12)
                    tween(handle, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.12)
                    valLbl.Text = tostring(value)
                end
                function Slider:Get() return value end
                return Slider
            end

            -- DROPDOWN
            function Section:CreateDropdown(ddOpts)
                ddOpts = ddOpts or {}
                local ddName     = ddOpts.Name     or "Dropdown"
                local ddOptions  = ddOpts.Options  or {}
                local ddDefault  = ddOpts.Default
                local ddCallback = ddOpts.Callback or function() end
                local T = Library.Theme

                local selected = ddDefault

                local container = Instance.new("Frame")
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(1, 0, 0, 52)
                container.ClipsDescendants = false
                container.ZIndex = 5
                container.Parent = body

                newLabel(ddName, 13, T.TextPrimary, T.FontBody, container)

                local ddBtn = Instance.new("TextButton")
                ddBtn.Size = UDim2.new(1, 0, 0, 30)
                ddBtn.Position = UDim2.new(0, 0, 0, 20)
                ddBtn.BackgroundColor3 = T.Surface
                ddBtn.Text = selected or "Select..."
                ddBtn.TextColor3 = selected and T.TextPrimary or T.TextMuted
                ddBtn.Font = T.FontBody
                ddBtn.TextSize = 13
                ddBtn.AutoButtonColor = false
                ddBtn.BorderSizePixel = 0
                ddBtn.ZIndex = 6
                ddBtn.Parent = container
                makeCorner(ddBtn, UDim.new(0, 6))
                makeStroke(ddBtn, T.SurfaceBorder)

                local chevron = Instance.new("TextLabel")
                chevron.BackgroundTransparency = 1
                chevron.AnchorPoint = Vector2.new(1, 0.5)
                chevron.Position = UDim2.new(1, -8, 0.5, 0)
                chevron.Size = UDim2.new(0, 16, 0, 16)
                chevron.Text = "▾"
                chevron.TextColor3 = T.TextMuted
                chevron.Font = T.FontBody
                chevron.TextSize = 12
                chevron.ZIndex = 7
                chevron.Parent = ddBtn

                local dropFrame = Instance.new("Frame")
                dropFrame.BackgroundColor3 = T.Surface
                dropFrame.BorderSizePixel = 0
                dropFrame.Position = UDim2.new(0, 0, 1, 4)
                dropFrame.Size = UDim2.new(1, 0, 0, 0)
                dropFrame.ClipsDescendants = true
                dropFrame.ZIndex = 20
                dropFrame.Visible = false
                dropFrame.Parent = ddBtn
                makeCorner(dropFrame, UDim.new(0, 6))
                makeStroke(dropFrame, T.SurfaceBorder)

                local dropLayout = Instance.new("UIListLayout")
                dropLayout.Padding = UDim.new(0, 2)
                dropLayout.Parent = dropFrame
                local dropPad = Instance.new("UIPadding")
                dropPad.PaddingTop    = UDim.new(0, 4)
                dropPad.PaddingBottom = UDim.new(0, 4)
                dropPad.PaddingLeft   = UDim.new(0, 4)
                dropPad.PaddingRight  = UDim.new(0, 4)
                dropPad.Parent = dropFrame

                local open = false
                local targetH = 0

                local function populate()
                    for _, child in ipairs(dropFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, opt in ipairs(ddOptions) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 28)
                        optBtn.BackgroundColor3 = T.SurfaceHigh
                        optBtn.Text = opt
                        optBtn.TextColor3 = opt == selected and T.AccentGlow or T.TextSecondary
                        optBtn.Font = T.FontBody
                        optBtn.TextSize = 13
                        optBtn.AutoButtonColor = false
                        optBtn.BorderSizePixel = 0
                        optBtn.ZIndex = 21
                        optBtn.Parent = dropFrame
                        makeCorner(optBtn, UDim.new(0, 4))

                        optBtn.MouseEnter:Connect(function()
                            tween(optBtn, {BackgroundColor3 = T.AccentDim, TextColor3 = T.TextPrimary}, 0.1)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            tween(optBtn, {
                                BackgroundColor3 = T.SurfaceHigh,
                                TextColor3 = opt == selected and T.AccentGlow or T.TextSecondary,
                            }, 0.1)
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            ddBtn.Text = opt
                            ddBtn.TextColor3 = T.TextPrimary
                            open = false
                            tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                            tween(chevron, {Rotation = 0}, 0.15)
                            task.wait(0.16)
                            dropFrame.Visible = false
                            pcall(ddCallback, opt)
                        end)
                    end
                    targetH = math.min(#ddOptions * 30 + 10, 180)
                end

                populate()

                ddBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        dropFrame.Visible = true
                        tween(dropFrame, {Size = UDim2.new(1, 0, 0, targetH)}, 0.18, Enum.EasingStyle.Back)
                        tween(chevron, {Rotation = 180}, 0.15)
                    else
                        tween(dropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                        tween(chevron, {Rotation = 0}, 0.15)
                        task.wait(0.16)
                        dropFrame.Visible = false
                    end
                end)

                local DD = {}
                function DD:Get()    return selected end
                function DD:Set(v)
                    selected = v
                    ddBtn.Text = v
                    ddBtn.TextColor3 = T.TextPrimary
                end
                function DD:SetOptions(opts)
                    ddOptions = opts
                    populate()
                end
                return DD
            end

            -- TEXTBOX
            function Section:CreateTextbox(tbOpts)
                tbOpts = tbOpts or {}
                local tbName        = tbOpts.Name        or "Input"
                local tbPlaceholder = tbOpts.Placeholder or "Enter text..."
                local tbCallback    = tbOpts.Callback    or function() end
                local T = Library.Theme

                local container = Instance.new("Frame")
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(1, 0, 0, 52)
                container.Parent = body

                newLabel(tbName, 13, T.TextPrimary, T.FontBody, container)

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, 0, 0, 30)
                box.Position = UDim2.new(0, 0, 0, 20)
                box.BackgroundColor3 = T.Surface
                box.Text = ""
                box.PlaceholderText = tbPlaceholder
                box.PlaceholderColor3 = T.TextMuted
                box.TextColor3 = T.TextPrimary
                box.Font = T.FontBody
                box.TextSize = 13
                box.ClearTextOnFocus = false
                box.BorderSizePixel = 0
                box.Parent = container
                makeCorner(box, UDim.new(0, 6))
                makeStroke(box, T.SurfaceBorder)

                local stroke = makeStroke(box, T.SurfaceBorder)

                box.Focused:Connect(function()
                    tween(stroke, {Color = T.Accent}, 0.15)
                end)
                box.FocusLost:Connect(function()
                    tween(stroke, {Color = T.SurfaceBorder}, 0.15)
                    pcall(tbCallback, box.Text)
                end)

                local TB = {}
                function TB:Get() return box.Text end
                function TB:Set(v) box.Text = v end
                return TB
            end

            -- KEYBIND
            function Section:CreateKeybind(kbOpts)
                kbOpts = kbOpts or {}
                local kbName     = kbOpts.Name     or "Keybind"
                local kbDefault  = kbOpts.Default  or Enum.KeyCode.Unknown
                local kbCallback = kbOpts.Callback or function() end
                local T = Library.Theme

                local bound   = kbDefault
                local waiting = false

                local row = Instance.new("Frame")
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 34)
                row.Parent = body

                local lbl = newLabel(kbName, 13, T.TextPrimary, T.FontBody, row)
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.TextYAlignment = Enum.TextYAlignment.Center

                local kbBtn = Instance.new("TextButton")
                kbBtn.AnchorPoint = Vector2.new(1, 0.5)
                kbBtn.Position = UDim2.new(1, 0, 0.5, 0)
                kbBtn.Size = UDim2.new(0, 100, 0, 26)
                kbBtn.BackgroundColor3 = T.Surface
                kbBtn.Text = bound.Name
                kbBtn.TextColor3 = T.Accent
                kbBtn.Font = T.Font
                kbBtn.TextSize = 12
                kbBtn.AutoButtonColor = false
                kbBtn.BorderSizePixel = 0
                kbBtn.Parent = row
                makeCorner(kbBtn, UDim.new(0, 6))
                makeStroke(kbBtn, T.SurfaceBorder)

                kbBtn.MouseButton1Click:Connect(function()
                    waiting = true
                    kbBtn.Text = "..."
                    tween(kbBtn, {BackgroundColor3 = T.AccentDim}, 0.12)
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if not waiting then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    waiting = false
                    bound = input.KeyCode
                    kbBtn.Text = bound.Name
                    tween(kbBtn, {BackgroundColor3 = T.Surface}, 0.12)
                    pcall(kbCallback, bound)
                end)

                local KB = {}
                function KB:Get() return bound end
                function KB:Set(key) bound = key; kbBtn.Text = key.Name end
                return KB
            end

            -- LABEL
            function Section:CreateLabel(text, color)
                local lbl = newLabel(text or "", 12, color or Library.Theme.TextMuted, Library.Theme.FontBody, body)
                lbl.Size = UDim2.new(1, 0, 0, 18)
                lbl.TextWrapped = true
                return lbl
            end

            return Section
        end -- CreateSection

        return Tab
    end -- CreateTab

    return Window
end -- CreateWindow

-- ============================================================
-- // FEATURE ENGINE — from ALL_SCRIPTS.txt
-- Optimized, event-driven, fully togglable
-- ============================================================

-- Shared RunService connection pool to avoid redundant Heartbeats
local SharedHeartbeat = {
    _callbacks = {},
    _connection = nil,
}

function SharedHeartbeat:Add(key, fn)
    self._callbacks[key] = fn
    if not self._connection then
        self._connection = RunService.Heartbeat:Connect(function(dt)
            for _, cb in pairs(self._callbacks) do
                pcall(cb, dt)
            end
        end)
    end
end

function SharedHeartbeat:Remove(key)
    self._callbacks[key] = nil
    if not next(self._callbacks) then
        if self._connection then
            self._connection:Disconnect()
            self._connection = nil
        end
    end
end

-- -------------------------------------------------------
-- FEATURE: Infinite Stamina
-- -------------------------------------------------------
local InfiniteStamina = {}
InfiniteStamina._active = false

function InfiniteStamina:Setup(char)
    if not char then return end

    local clientHandler = char:FindFirstChild("ClientHandler")
        or char:FindFirstChild("Client")
        or char:FindFirstChild("ClientOLD")
    if not clientHandler then return end

    local ok, State = pcall(require, clientHandler:FindFirstChild("State"))
    if not ok or not State then return end

    SharedHeartbeat:Add("InfiniteStamina", function()
        if not InfiniteStamina._active then return end
        if State and State.stamina then
            State.stamina.current     = 200
            State.stamina.regenDelay  = 0
            State.stamina.fullRegen   = false
            State.stamina.active      = false
            if State.stamina.exhausted ~= nil then
                State.stamina.exhausted = false
            end
        end
    end)
end

function InfiniteStamina:Enable()
    self._active = true
    local char = LocalPlayer.Character
    if char then self:Setup(char) end
    self._charConn = self._charConn or LocalPlayer.CharacterAdded:Connect(function(c)
        if self._active then self:Setup(c) end
    end)
end

function InfiniteStamina:Disable()
    self._active = false
    SharedHeartbeat:Remove("InfiniteStamina")
end

-- -------------------------------------------------------
-- FEATURE: Infinite NVG (IsCloaker value lock)
-- -------------------------------------------------------
local InfiniteNVG = {}
InfiniteNVG._active = false
InfiniteNVG._charConn = nil
InfiniteNVG._cleanups = {}

function InfiniteNVG:_setupChar(char)
    -- Clean up previous connections
    for _, conn in ipairs(self._cleanups) do pcall(function() conn:Disconnect() end) end
    self._cleanups = {}

    local function lockCloaker(c)
        local ic = c:FindFirstChild("IsCloaker")
        if not ic then
            ic = Instance.new("BoolValue")
            ic.Name = "IsCloaker"
            ic.Parent = c
        end
        ic.Value = true

        local conn1 = ic.Changed:Connect(function()
            if InfiniteNVG._active and ic.Value ~= true then
                ic.Value = true
            end
        end)

        local conn2 = c.ChildAdded:Connect(function(child)
            if InfiniteNVG._active
            and child.Name == "IsCloaker"
            and child:IsA("BoolValue") then
                child.Value = true
            end
        end)

        table.insert(self._cleanups, conn1)
        table.insert(self._cleanups, conn2)
    end

    lockCloaker(char)
end

function InfiniteNVG:Enable()
    self._active = true
    local char = LocalPlayer.Character
    if char then self:_setupChar(char) end
    self._charConn = self._charConn or LocalPlayer.CharacterAdded:Connect(function(c)
        if self._active then self:_setupChar(c) end
    end)
end

function InfiniteNVG:Disable()
    self._active = false
    for _, conn in ipairs(self._cleanups) do pcall(function() conn:Disconnect() end) end
    self._cleanups = {}
    -- Remove the IsCloaker value so NVG actually turns off
    local char = LocalPlayer.Character
    if char then
        local ic = char:FindFirstChild("IsCloaker")
        if ic then ic:Destroy() end
    end
end

-- -------------------------------------------------------
-- FEATURE: AI Highlight ESP
-- -------------------------------------------------------
local AIESP = {}
AIESP._active     = false
AIESP._childConn  = nil
AIESP._highlights = {}  -- track created instances for cleanup

local function clearAIHighlights()
    for _, v in pairs(AIESP._highlights) do
        pcall(function()
            for _, child in ipairs(v:GetChildren()) do
                if child:IsA("Highlight") or child:IsA("BillboardGui") then
                    child:Destroy()
                end
            end
        end)
    end
    AIESP._highlights = {}
end

local function applyAIHighlight(v)
    if not AIESP._active then return end
    if not v or not v.Parent then return end
    if not v:FindFirstChild("AI") then return end
    if v:FindFirstChildOfClass("Highlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "AI_Highlight"
    highlight.Adornee = v
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 1
    highlight.Parent = v

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AI_HealthUI"
    billboard.Adornee = v
    billboard.Size = UDim2.new(0, 100, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 150
    billboard.Parent = v

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboard
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold

    AIESP._highlights[v] = v

    -- Health update loop — event-driven via stepped task instead of busy-wait
    task.spawn(function()
        local humanoid = v:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        while v and v.Parent and humanoid and AIESP._active do
            if humanoid.Health <= 0 then
                pcall(function() highlight:Destroy() billboard:Destroy() end)
                AIESP._highlights[v] = nil
                break
            end
            textLabel.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
            task.wait(0.2)
        end
    end)
end

function AIESP:Enable()
    self._active = true
    local chars = Workspace:FindFirstChild("Characters")
    if chars then
        for _, v in ipairs(chars:GetChildren()) do
            applyAIHighlight(v)
        end
        self._childConn = chars.ChildAdded:Connect(function(v)
            task.wait(0.1)
            applyAIHighlight(v)
        end)
    end
end

function AIESP:Disable()
    self._active = false
    if self._childConn then
        self._childConn:Disconnect()
        self._childConn = nil
    end
    clearAIHighlights()
end

-- -------------------------------------------------------
-- FEATURE: Hitbox Expander (AI NPCs only, Head → 4x4x4)
-- -------------------------------------------------------
local HitboxExpander = {}
HitboxExpander._active       = false
HitboxExpander._descConn     = nil
HitboxExpander._modifiedParts = {}  -- {part = originalSize}

local function isPlayerChar(model)
    if not model or not model:IsA("Model") then return false end
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function hasHumanoid(model)
    if not model or not model:IsA("Model") then return false end
    return model:FindFirstChildWhichIsA("Humanoid") ~= nil
end

local function expandPart(part)
    if not part or not part:IsA("BasePart") then return end
    if part.Name ~= "Head" then return end
    local model = part.Parent
    if not (hasHumanoid(model) and not isPlayerChar(model)) then return end
    if HitboxExpander._modifiedParts[part] then return end

    local origSize = part.Size
    pcall(function()
        part.Size       = Vector3.new(4, 4, 4)
        part.CanCollide = false
        part.Transparency = 0.5
    end)
    HitboxExpander._modifiedParts[part] = origSize
end

local function restorePart(part, origSize)
    pcall(function()
        if part and part.Parent then
            part.Size         = origSize
            part.CanCollide   = true
            part.Transparency = 0
        end
    end)
end

function HitboxExpander:Enable()
    self._active = true
    for _, desc in ipairs(Workspace:GetDescendants()) do
        expandPart(desc)
    end
    self._descConn = Workspace.DescendantAdded:Connect(function(desc)
        if HitboxExpander._active then expandPart(desc) end
    end)
end

function HitboxExpander:Disable()
    self._active = false
    if self._descConn then
        self._descConn:Disconnect()
        self._descConn = nil
    end
    for part, origSize in pairs(self._modifiedParts) do
        restorePart(part, origSize)
    end
    self._modifiedParts = {}
end

-- ============================================================
-- // MAIN UI BUILD
-- ============================================================
local win = Library:CreateWindow({
    Title    = "Sentinel",
    Subtitle = "ShadowHawk Edition  •  v2.0",
})

-- -------------------------------------------------------
-- TAB: Visuals
-- -------------------------------------------------------
local visualsTab = win:CreateTab({Name = "Visuals", Icon = "◈"})

local espSection = visualsTab:CreateSection({Name = "ESP"})

espSection:CreateToggle({
    Name     = "AI Highlight ESP",
    Default  = false,
    SaveKey  = "ai_esp",
    Callback = function(state)
        if state then
            AIESP:Enable()
        else
            AIESP:Disable()
        end
        Library:Notify({
            Title   = "AI ESP",
            Message = state and "Highlights enabled." or "Highlights disabled.",
            Type    = state and "success" or "info",
            Duration = 2,
        })
    end,
})

-- -------------------------------------------------------
-- TAB: Combat
-- -------------------------------------------------------
local combatTab = win:CreateTab({Name = "Combat", Icon = "⚔"})

local hitboxSection = combatTab:CreateSection({Name = "Hitbox"})

hitboxSection:CreateToggle({
    Name     = "Hitbox Expander",
    Default  = false,
    SaveKey  = "hitbox_expand",
    Callback = function(state)
        if state then
            HitboxExpander:Enable()
        else
            HitboxExpander:Disable()
        end
        Library:Notify({
            Title   = "Hitbox Expander",
            Message = state and "AI heads expanded to 4x4x4." or "Hitboxes restored.",
            Type    = state and "warning" or "info",
            Duration = 2,
        })
    end,
})

-- -------------------------------------------------------
-- TAB: Movement
-- -------------------------------------------------------
local movementTab = win:CreateTab({Name = "Movement", Icon = "⚡"})

local staminaSection = movementTab:CreateSection({Name = "Stamina"})

staminaSection:CreateToggle({
    Name     = "Infinite Stamina",
    Default  = false,
    SaveKey  = "inf_stamina",
    Callback = function(state)
        if state then
            InfiniteStamina:Enable()
        else
            InfiniteStamina:Disable()
        end
        Library:Notify({
            Title   = "Stamina",
            Message = state and "Infinite stamina active." or "Stamina restored.",
            Type    = state and "success" or "info",
            Duration = 2,
        })
    end,
})

-- -------------------------------------------------------
-- TAB: Misc
-- -------------------------------------------------------
local miscTab = win:CreateTab({Name = "Misc", Icon = "◉"})

local nvgSection = miscTab:CreateSection({Name = "Vision"})

nvgSection:CreateToggle({
    Name     = "Infinite NVG",
    Default  = false,
    SaveKey  = "inf_nvg",
    Callback = function(state)
        if state then
            InfiniteNVG:Enable()
        else
            InfiniteNVG:Disable()
        end
        Library:Notify({
            Title   = "Night Vision",
            Message = state and "NVG locked on." or "NVG released.",
            Type    = state and "success" or "info",
            Duration = 2,
        })
    end,
})

local themeSection = miscTab:CreateSection({Name = "Appearance"})

themeSection:CreateDropdown({
    Name     = "Theme",
    Options  = {"Dark", "Midnight", "Ocean", "Bloodmoon"},
    Default  = "Dark",
    Callback = function(chosen)
        win:ApplyTheme(chosen)
    end,
})

themeSection:CreateSlider({
    Name     = "UI Opacity",
    Min      = 20,
    Max      = 100,
    Default  = 100,
    Step     = 5,
    SaveKey  = "ui_opacity",
    Callback = function(val)
        -- Applies to the main window background transparency
        -- (inverse: 100 = fully visible = 0 transparency)
        local t = 1 - (val / 100)
        if win._win then
            win._win.BackgroundTransparency = t
        end
    end,
})

local settingsSection = miscTab:CreateSection({Name = "Hotkeys"})

settingsSection:CreateKeybind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightShift,
    Callback = function(key)
        Library.Config.ToggleKey = key
        Library:Notify({
            Title   = "Hotkey Updated",
            Message = "UI toggle: " .. key.Name,
            Type    = "info",
            Duration = 2,
        })
    end,
})

settingsSection:CreateButton({
    Name     = "Save Settings",
    Callback = function()
        saveSettings()
        Library:Notify({
            Title   = "Settings Saved",
            Message = "All toggle states persisted.",
            Type    = "success",
            Duration = 2,
        })
    end,
})

-- Opening notification
Library:Notify({
    Title   = "Sentinel Loaded",
    Message = "ShadowHawk Edition  •  RShift to toggle",
    Type    = "info",
    Duration = 4,
})

--[[
════════════════════════════════════════════════════════════
  PUBLIC API REFERENCE
════════════════════════════════════════════════════════════

  Library:CreateWindow(opts) → Window
    opts.Title, opts.Subtitle, opts.ToggleKey

  Window:CreateTab(opts) → Tab
    opts.Name, opts.Icon

  Tab:CreateSection(opts) → Section
    opts.Name

  Section:CreateToggle(opts) → Toggle
    opts.Name, opts.Default, opts.SaveKey, opts.Callback(bool)
    Toggle:Set(bool), Toggle:Get() → bool

  Section:CreateButton(opts) → TextButton
    opts.Name, opts.Callback()

  Section:CreateSlider(opts) → Slider
    opts.Name, opts.Min, opts.Max, opts.Default, opts.Step
    opts.SaveKey, opts.Callback(number)
    Slider:Set(number), Slider:Get() → number

  Section:CreateDropdown(opts) → Dropdown
    opts.Name, opts.Options {string}, opts.Default, opts.Callback(string)
    DD:Get() → string, DD:Set(string), DD:SetOptions({string})

  Section:CreateTextbox(opts) → Textbox
    opts.Name, opts.Placeholder, opts.Callback(string)
    TB:Get() → string, TB:Set(string)

  Section:CreateKeybind(opts) → Keybind
    opts.Name, opts.Default (KeyCode), opts.Callback(KeyCode)
    KB:Get() → KeyCode, KB:Set(KeyCode)

  Section:CreateLabel(text, color) → TextLabel

  Library:Notify(opts)
    opts.Title, opts.Message, opts.Type ("success"|"warning"|"error"|"info")
    opts.Duration (seconds)

  Window:ApplyTheme(name)
    name: "Dark" | "Midnight" | "Ocean" | "Bloodmoon"

════════════════════════════════════════════════════════════
  FEATURES WIRED FROM ALL_SCRIPTS.txt
════════════════════════════════════════════════════════════

  [VISUALS tab → ESP section]
  • AI Highlight ESP
    Original: Highlight + BillboardGui on AI-tagged models
    Optimized: single ChildAdded listener, health loop via task.wait
                (not RunService), full cleanup on disable

  [COMBAT tab → Hitbox section]
  • Hitbox Expander
    Original: DescendantAdded + Name change watcher
    Optimized: original sizes stored for restore, single DescendantAdded
                connection, full restore on disable, isPlayerChar guard

  [MOVEMENT tab → Stamina section]
  • Infinite Stamina
    Original: RunService.Heartbeat, re-attaches on CharacterAdded
    Optimized: routed through SharedHeartbeat pool (single connection
                shared with all Heartbeat features), CharacterAdded
                wired once, guard flag on Disable

  [MISC tab → Vision section]
  • Infinite NVG (IsCloaker lock)
    Original: BoolValue lock + Changed/ChildAdded listeners
    Optimized: connections tracked in _cleanups table, all disconnected
                and IsCloaker destroyed on Disable (true off-state)

════════════════════════════════════════════════════════════
]]
