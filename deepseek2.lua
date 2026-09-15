-- // eclipse - examination
-- // only works in examination (10165583746)
-- // ui: windui by footagesus

-- // services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // game guard
if game.PlaceId ~= 10165583746 then
    pcall(function()
        LP:Kick("This game is not supported.")
    end)
    return
end

-- // load windui
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- // state
local S = {
    -- aimbot
    aimOn = false,
    aimActive = false,
    aimDown = false,
    aimMode = "Toggle",
    aimKeyName = "E",
    aimFOV = 140,
    aimSmooth = 0.22,
    aimDist = 600,
    aimPart = "Head",
    wallcheck = true,
    showFOV = true,

    -- hitbox
    hbOn = false,
    hbSize = 6,
    hbVisual = false,
    hbOpacity = 0.3,

    -- esp
    espOn = false,
    espHL = true,
    espName = true,
    espHP = true,
    espDist = 200,
    espColor = Color3.fromRGB(255, 70, 70),

    -- perks
    stamina = false,
    nvg = false,

    -- interface
    reduced = false,
    mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
    notif = true,
}

local Conns = {}
local Boxes = {}    -- [model] = Part
local Esps  = {}    -- [model] = {hl, bb, name, hp}

local function Track(c) table.insert(Conns, c) return c end

local function Toast(t)
    if S.notif then WindUI:Notify(t) end
end

-- // window
local Window = WindUI:CreateWindow({
    Title = "Eclipse - Examination",
    Icon = "solar:moon-stars-bold",
    Author = "Infinite",
    Folder = "EclipseExamination",
    Size = UDim2.fromOffset(490, 350),
    MinSize = Vector2.new(440, 300),
    MaxSize = Vector2.new(680, 480),
    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 148,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    OpenButton = {
        Title = "Eclipse",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(
            Color3.fromHex("#7C3AED"),
            Color3.fromHex("#22D3EE")
        ),
    },
    Topbar = { Height = 38, ButtonsType = "Mac" },
})

Window:Tag({
    Title = "v1.0",
    Icon = "zap",
    Color = Color3.fromHex("#18181b"),
    Border = true,
})

-- // ai helpers
local function GetAIs()
    local list = {}
    local folder = Workspace:FindFirstChild("Characters")
    if not folder then return list end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and m:FindFirstChild("AI") then
            local hum = m:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(list, m)
            end
        end
    end
    return list
end

local function TargetPart(model)
    if S.aimPart == "Hitbox" then
        local b = model:FindFirstChild("EclipseHitbox")
        if b then return b end
    end
    if S.aimPart == "HumanoidRootPart" then
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.RootPart then return hum.RootPart end
    end
    return model:FindFirstChild("Head")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

-- // hitbox — invisible box welded to head. head stays normal size
local function AddBox(model)
    if Boxes[model] then return end
    local head = model:FindFirstChild("Head")
    if not head then return end

    local box = Instance.new("Part")
    box.Name = "EclipseHitbox"
    box.Size = Vector3.new(S.hbSize, S.hbSize, S.hbSize)
    box.Transparency = S.hbVisual and (1 - S.hbOpacity) or 1
    box.CanCollide = false
    box.CanQuery = true
    box.CanTouch = false
    box.Massless = true
    box.Anchored = false
    box.Material = Enum.Material.ForceField
    box.Color = Color3.fromRGB(124, 58, 237)
    box.CFrame = head.CFrame

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = box
    weld.Parent = box

    box.Parent = model
    Boxes[model] = box
end

local function DelBox(model)
    local b = Boxes[model]
    if b then b:Destroy() Boxes[model] = nil end
end

local function RefreshBoxes()
    if S.hbOn then
        for _, m in ipairs(GetAIs()) do AddBox(m) end
    else
        for m in pairs(Boxes) do DelBox(m) end
    end
end

-- // esp
local function DelESP(model)
    local d = Esps[model]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
    Esps[model] = nil
end

local function ClearESP()
    for m in pairs(Esps) do DelESP(m) end
end

local function AddESP(model)
    if not S.espOn or Esps[model] then return end
    local head = model:FindFirstChild("Head") or model.PrimaryPart
    if not head then return end

    local d = {}

    if S.espHL then
        local hl = Instance.new("Highlight")
        hl.Name = "EclipseHL"
        hl.Adornee = model
        hl.FillColor = S.espColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        d.hl = hl
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "EclipseBB"
    bb.Adornee = head
    bb.Size = UDim2.fromOffset(100, 36)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = S.espDist
    bb.Parent = model
    d.bb = bb

    if S.espName then
        local n = Instance.new("TextLabel")
        n.Size = UDim2.new(1, 0, 0.5, 0)
        n.BackgroundTransparency = 1
        n.TextColor3 = S.espColor
        n.TextStrokeTransparency = 0
        n.TextScaled = true
        n.Font = Enum.Font.GothamBold
        n.Text = model.Name
        n.Parent = bb
        d.name = n
    end

    if S.espHP then
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1, 0, 0.5, 0)
        h.Position = UDim2.new(0, 0, 0.5, 0)
        h.BackgroundTransparency = 1
        h.TextColor3 = Color3.fromRGB(255, 255, 255)
        h.TextStrokeTransparency = 0
        h.TextScaled = true
        h.Font = Enum.Font.Gotham
        h.Text = "100 / 100"
        h.Parent = bb
        d.hp = h
    end

    Esps[model] = d
end

local function RefreshESP()
    if not S.espOn then
        ClearESP()
        return
    end
    for _, m in ipairs(GetAIs()) do AddESP(m) end
end

-- // fov circle
local fovGui, fovCircle, fovStroke

local function EnsureFOV()
    if fovGui then return end
    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "EclipseFOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.Parent = LP:WaitForChild("PlayerGui")

    fovCircle = Instance.new("Frame")
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.Position = UDim2.fromScale(0.5, 0.5)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Visible = false
    fovCircle.Parent = fovGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovCircle

    fovStroke = Instance.new("UIStroke")
    fovStroke.Color = Color3.fromRGB(124, 58, 237)
    fovStroke.Thickness = 1.5
    fovStroke.Transparency = 0.4
    fovStroke.Parent = fovCircle
end

local function UpdateFOV()
    if not fovGui then return end
    fovCircle.Size = UDim2.fromOffset(S.aimFOV * 2, S.aimFOV * 2)
    fovCircle.Visible = S.aimOn and S.showFOV
end

-- // aimbot helpers
local function ScreenDist(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return math.huge end
    local c = Camera.ViewportSize / 2
    local dx, dy = sp.X - c.X, sp.Y - c.Y
    return math.sqrt(dx * dx + dy * dy)
end

local function LOS(from, to, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore or { Camera, LP.Character }
    params.IgnoreWater = true
    local hit = Workspace:Raycast(from, to - from, params)
    return hit == nil
end

local function BestTarget()
    local best, score = nil, math.huge
    for _, m in ipairs(GetAIs()) do
        local part = TargetPart(m)
        if part then
            local dist = (Camera.CFrame.Position - part.Position).Magnitude
            if dist <= S.aimDist then
                local sd = ScreenDist(part.Position)
                if sd <= S.aimFOV then
                    if not S.wallcheck or LOS(Camera.CFrame.Position, part.Position,
                        { Camera, LP.Character, m }) then
                        if sd < score then
                            score = sd
                            best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

-- // ai watcher (event driven, no polling)
local function OnAI(v)
    if not v:IsA("Model") or not v:FindFirstChild("AI") then return end
    task.wait(0.1)
    if not v.Parent then return end
    if S.hbOn then AddBox(v) end
    if S.espOn then AddESP(v) end
    v.AncestryChanged:Connect(function()
        if not v.Parent then
            DelBox(v)
            DelESP(v)
        end
    end)
end

local charsFolder = Workspace:WaitForChild("Characters", 10)
if charsFolder then
    for _, v in ipairs(charsFolder:GetChildren()) do
        task.spawn(OnAI, v)
    end
    Track(charsFolder.ChildAdded:Connect(OnAI))
end

-- // character setup (stamina + nvg)
local function SetupChar(char)
    -- nvg via IsCloaker flag
    local flag = char:FindFirstChild("IsCloaker")
    if not flag then
        flag = Instance.new("BoolValue")
        flag.Name = "IsCloaker"
        flag.Parent = char
    end
    if S.nvg then flag.Value = true end
    Track(flag.Changed:Connect(function()
        if S.nvg and not flag.Value then flag.Value = true end
    end))

    -- stamina via ClientHandler.State
    task.spawn(function()
        local handler
        for _ = 1, 50 do
            handler = char:FindFirstChild("ClientHandler")
                or char:FindFirstChild("Client")
                or char:FindFirstChild("ClientOLD")
            if handler then break end
            task.wait(0.1)
        end
        if not handler then return end

        local ok, State = pcall(require, handler:WaitForChild("State", 4))
        if not ok or not State or not State.stamina then return end

        Track(RunService.Heartbeat:Connect(function()
            if not S.stamina then return end
            State.stamina.current = 200
            State.stamina.regenDelay = 0
            State.stamina.fullRegen = false
            State.stamina.active = false
            if State.stamina.exhausted ~= nil then
                State.stamina.exhausted = false
            end
        end))
    end)
end

if LP.Character then task.spawn(SetupChar, LP.Character) end
Track(LP.CharacterAdded:Connect(function(c) task.spawn(SetupChar, c) end))

-- // single main loop (aimbot + throttled esp)
local espAccum = 0
Track(RunService.Heartbeat:Connect(function(dt)
    -- aimbot
    if S.aimOn then
        local should = (S.aimMode == "Always")
            or (S.aimMode == "Hold" and S.aimDown)
            or (S.aimMode == "Toggle" and S.aimActive)
        if should then
            local t = BestTarget()
            if t then
                local goal = CFrame.lookAt(Camera.CFrame.Position, t.Position)
                if S.reduced then
                    Camera.CFrame = goal
                else
                    local a = math.clamp(S.aimSmooth * dt * 60, 0, 1)
                    Camera.CFrame = Camera.CFrame:Lerp(goal, a)
                end
            end
        end
    end

    -- esp hp refresh (throttled to ~8hz)
    if S.espOn then
        espAccum = espAccum + dt
        if espAccum >= 0.12 then
            espAccum = 0
            for m, d in pairs(Esps) do
                if not m.Parent then
                    DelESP(m)
                elseif d.hp then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum then
                        d.hp.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                    end
                end
            end
        end
    end
end))

-- // aim key
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode[S.aimKeyName or "E"] then
        if S.aimMode == "Hold" then
            S.aimDown = true
        elseif S.aimMode == "Toggle" then
            S.aimActive = not S.aimActive
        end
    end
end))

Track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode[S.aimKeyName or "E"] then
        S.aimDown = false
    end
end))

-- // sidebar
Window:Section({ Title = "Combat", Opened = true })
local AimTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })
local HBTab  = Window:Tab({ Title = "Hitbox", Icon = "box" })

Window:Section({ Title = "Visuals", Opened = true })
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })

Window:Section({ Title = "Player", Opened = true })
local PerkTab = Window:Tab({ Title = "Perks", Icon = "star" })

Window:Section({ Title = "Interface", Opened = true })
local UITab = Window:Tab({ Title = "Interface", Icon = "settings" })

-- // aimbot tab
local aimCtl = AimTab:Section({ Title = "Controls", Opened = true })

aimCtl:Toggle({
    Title = "Enable Aimbot",
    Desc = "Locks onto the closest AI in range.",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Flag = "AimbotEnabled",
    Callback = function(v)
        S.aimOn = v
        S.aimActive = false
        EnsureFOV()
        UpdateFOV()
        Toast({ Title = v and "Aimbot on" or "Aimbot off", Icon = "crosshair" })
    end,
})

aimCtl:Space({ Columns = 1 })

aimCtl:Dropdown({
    Title = "Activation",
    Desc = "How the aimbot engages.",
    Icon = "mouse-pointer",
    Values = { "Always", "Hold", "Toggle" },
    Default = "Toggle",
    Flag = "AimbotMode",
    Callback = function(v)
        S.aimMode = v
        S.aimActive = false
    end,
})

aimCtl:Space({ Columns = 1 })

aimCtl:Keybind({
    Title = "Aim Key",
    Desc = "Used in Hold/Toggle modes. Ignored when Always.",
    Icon = "keyboard",
    Value = "E",
    Flag = "AimbotKey",
    Callback = function(v) S.aimKeyName = v end,
})

local aimTgt = AimTab:Section({ Title = "Targeting", Opened = true })

aimTgt:Dropdown({
    Title = "Target Part",
    Desc = "Which bone to aim at.",
    Icon = "target",
    Values = { "Head", "Hitbox", "HumanoidRootPart" },
    Default = "Head",
    Flag = "AimbotPart",
    Callback = function(v) S.aimPart = v end,
})

aimTgt:Space({ Columns = 1 })

aimTgt:Slider({
    Title = "FOV",
    Desc = "Screen-space radius for detection.",
    Icon = "circle-dot",
    Min = 20,
    Max = 600,
    Default = 140,
    Step = 5,
    Suffix = "px",
    Flag = "AimbotFOV",
    Callback = function(v)
        S.aimFOV = v
        UpdateFOV()
    end,
})

aimTgt:Space({ Columns = 1 })

aimTgt:Slider({
    Title = "Smoothness",
    Desc = "Lower = snappier. Higher = smoother.",
    Icon = "activity",
    Min = 0.02,
    Max = 1,
    Default = 0.22,
    Step = 0.02,
    Flag = "AimbotSmooth",
    Callback = function(v) S.aimSmooth = v end,
})

aimTgt:Space({ Columns = 1 })

aimTgt:Slider({
    Title = "Max Distance",
    Desc = "Studs.",
    Icon = "ruler",
    Min = 50,
    Max = 2000,
    Default = 600,
    Step = 50,
    Suffix = " studs",
    Flag = "AimbotDist",
    Callback = function(v) S.aimDist = v end,
})

aimTgt:Space({ Columns = 1 })

aimTgt:Toggle({
    Title = "Wallcheck",
    Desc = "Skip targets behind cover.",
    Icon = "eye-off",
    Type = "Checkbox",
    Value = true,
    Flag = "AimbotWall",
    Callback = function(v) S.wallcheck = v end,
})

aimTgt:Space({ Columns = 1 })

aimTgt:Toggle({
    Title = "Show FOV Circle",
    Desc = "Draws the detection radius on screen.",
    Icon = "circle",
    Type = "Checkbox",
    Value = true,
    Flag = "AimbotShowFOV",
    Callback = function(v)
        S.showFOV = v
        UpdateFOV()
    end,
})

-- // hitbox tab
local hbSec = HBTab:Section({ Title = "Expander", Opened = true })

hbSec:Toggle({
    Title = "Enable Hitbox",
    Desc = "Invisible box welded to the AI head. The head itself stays untouched.",
    Icon = "box",
    Type = "Checkbox",
    Value = false,
    Flag = "HitboxEnabled",
    Callback = function(v)
        S.hbOn = v
        RefreshBoxes()
        Toast({ Title = v and "Hitbox on" or "Hitbox off", Icon = "box" })
    end,
})

hbSec:Space({ Columns = 1 })

hbSec:Slider({
    Title = "Box Size",
    Desc = "Studs. Hits register on the whole box.",
    Icon = "maximize",
    Min = 2,
    Max = 20,
    Default = 6,
    Step = 0.5,
    Suffix = " studs",
    Flag = "HitboxSize",
    Callback = function(v)
        S.hbSize = v
        for _, b in pairs(Boxes) do
            b.Size = Vector3.new(v, v, v)
        end
    end,
})

hbSec:Space({ Columns = 1 })

hbSec:Toggle({
    Title = "Show Box",
    Desc = "Reveals the invisible hitbox as a translucent shell.",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Flag = "HitboxShow",
    Callback = function(v)
        S.hbVisual = v
        for _, b in pairs(Boxes) do
            b.Transparency = v and (1 - S.hbOpacity) or 1
        end
    end,
})

hbSec:Space({ Columns = 1 })

hbSec:Slider({
    Title = "Box Opacity",
    Desc = "Only matters when Show Box is on.",
    Icon = "droplet",
    Min = 0,
    Max = 1,
    Default = 0.3,
    Step = 0.05,
    Flag = "HitboxOpacity",
    Callback = function(v)
        S.hbOpacity = v
        if S.hbVisual then
            for _, b in pairs(Boxes) do
                b.Transparency = 1 - v
            end
        end
    end,
})

-- // esp tab
local espSec = ESPTab:Section({ Title = "AI ESP", Opened = true })

espSec:Toggle({
    Title = "Enable ESP",
    Desc = "Highlights and labels every AI in the map.",
    Icon = "scan",
    Type = "Checkbox",
    Value = false,
    Flag = "ESPEnabled",
    Callback = function(v)
        S.espOn = v
        RefreshESP()
        Toast({ Title = v and "ESP on" or "ESP off", Icon = "eye" })
    end,
})

espSec:Space({ Columns = 2 })

espSec:Toggle({
    Title = "Highlight",
    Desc = "Outline through walls.",
    Icon = "square",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPHL",
    Callback = function(v) S.espHL = v RefreshESP() end,
})

espSec:Toggle({
    Title = "Name",
    Desc = "AI name above head.",
    Icon = "user",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPName",
    Callback = function(v) S.espName = v RefreshESP() end,
})

espSec:Space({ Columns = 1 })

espSec:Toggle({
    Title = "Health",
    Desc = "Live HP text.",
    Icon = "heart",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPHP",
    Callback = function(v) S.espHP = v RefreshESP() end,
})

local espCfg = ESPTab:Section({ Title = "Style", Opened = false })

espCfg:Slider({
    Title = "Max Distance",
    Desc = "Hide tags beyond this range.",
    Icon = "ruler",
    Min = 50,
    Max = 1000,
    Default = 200,
    Step = 50,
    Suffix = " studs",
    Flag = "ESPDist",
    Callback = function(v)
        S.espDist = v
        for _, d in pairs(Esps) do
            if d.bb then d.bb.MaxDistance = v end
        end
    end,
})

espCfg:Space({ Columns = 1 })

espCfg:Colorpicker({
    Title = "Highlight Color",
    Desc = "Also tints the name text.",
    Default = Color3.fromRGB(255, 70, 70),
    Transparency = 0,
    Flag = "ESPColor",
    Callback = function(c)
        S.espColor = c
        for _, d in pairs(Esps) do
            if d.hl then d.hl.FillColor = c end
            if d.name then d.name.TextColor3 = c end
        end
    end,
})

-- // perks tab
local perkSec = PerkTab:Section({ Title = "Self", Opened = true })

perkSec:Toggle({
    Title = "Infinite Stamina",
    Desc = "Stamina stays maxed.",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Flag = "InfiniteStamina",
    Callback = function(v)
        S.stamina = v
        Toast({ Title = v and "Stamina locked" or "Stamina normal", Icon = "zap" })
    end,
})

perkSec:Space({ Columns = 1 })

perkSec:Toggle({
    Title = "Infinite NVG",
    Desc = "IsCloaker flag forced on.",
    Icon = "moon",
    Type = "Checkbox",
    Value = false,
    Flag = "InfiniteNVG",
    Callback = function(v)
        S.nvg = v
        if v and LP.Character then
            local f = LP.Character:FindFirstChild("IsCloaker")
            if f then f.Value = true end
        end
        Toast({ Title = v and "NVG forced on" or "NVG normal", Icon = "moon" })
    end,
})

-- // interface tab
local uiGen = UITab:Section({ Title = "General", Opened = true })

uiGen:Keybind({
    Title = "UI Toggle",
    Desc = "Key to open/close the window.",
    Icon = "keyboard",
    Value = "RightShift",
    Flag = "UIToggle",
    Callback = function(v)
        pcall(function()
            Window:SetToggleKey(Enum.KeyCode[v])
        end)
    end,
})

uiGen:Space({ Columns = 1 })

uiGen:Dropdown({
    Title = "Theme",
    Desc = "WindUI theme.",
    Icon = "palette",
    Values = { "Dark", "Light", "Midnight", "Aqua", "Rose" },
    Default = "Dark",
    Flag = "UITheme",
    Callback = function(v)
        pcall(function() WindUI:SetTheme(v) end)
    end,
})

uiGen:Space({ Columns = 1 })

uiGen:Toggle({
    Title = "Reduced Motion",
    Desc = "Snap aim instead of smoothing. Helps on weak hardware.",
    Icon = "accessibility",
    Type = "Checkbox",
    Value = false,
    Flag = "UIReduced",
    Callback = function(v) S.reduced = v end,
})

uiGen:Space({ Columns = 1 })

uiGen:Toggle({
    Title = "Silent Mode",
    Desc = "Hide all notifications.",
    Icon = "bell-off",
    Type = "Checkbox",
    Value = false,
    Flag = "UISilent",
    Callback = function(v) S.notif = not v end,
})

uiGen:Space({ Columns = 1 })

uiGen:Toggle({
    Title = "Mobile Mode",
    Desc = "Bigger UI for touch screens.",
    Icon = "smartphone",
    Type = "Checkbox",
    Value = S.mobile,
    Flag = "UIMobile",
    Callback = function(v)
        S.mobile = v
        pcall(function() Window:SetUIScale(v and 1.15 or 1) end)
    end,
})

UITab:Space({ Columns = 2 })

UITab:Button({
    Title = "Unload Hub",
    Desc = "Removes the UI and stops every feature.",
    Icon = "trash-2",
    Color = Color3.fromHex("#EF4444"),
    Callback = function()
        WindUI:Popup({
            Title = "Unload Eclipse?",
            Icon = "alert-triangle",
            Content = "Every feature will stop and the window will close.",
            Buttons = {
                {
                    Title = "Cancel",
                    Icon = "x",
                    Callback = function() end,
                },
                {
                    Title = "Unload",
                    Icon = "trash-2",
                    Primary = true,
                    Callback = function()
                        for _, c in ipairs(Conns) do
                            pcall(function() c:Disconnect() end)
                        end
                        table.clear(Conns)
                        ClearESP()
                        for m in pairs(Boxes) do DelBox(m) end
                        if fovGui then fovGui:Destroy() end
                        Window:Destroy()
                    end,
                },
            },
        })
    end,
})

-- // mobile scale on load
if S.mobile then
    pcall(function() Window:SetUIScale(1.15) end)
end

-- // cleanup on destroy
script.Destroying:Connect(function()
    for _, c in ipairs(Conns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Conns)
    ClearESP()
    for m in pairs(Boxes) do DelBox(m) end
    if fovGui then fovGui:Destroy() end
end)

-- // hello
Toast({
    Title = "Eclipse loaded",
    Content = "Press RightShift to toggle. Examination only.",
    Icon = "solar:check-circle-bold",
    Duration = 5,
})