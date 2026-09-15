--[[
    ═══════════════════════════════════════════════════════════════
    AI OVERHAUL — WindUI Exploit Hub
    Built on WindUI (Beta) by Footagesus
    Docs: https://footagesus.github.io/WindUI-Docs/docs
    ═══════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════
-- LOAD WINDUI
-- ═══════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ═══════════════════════════════════════════════════════════════
-- GLOBAL STATE
-- ═══════════════════════════════════════════════════════════════
local State = {
    AimbotEnabled = false,
    AimKeyDown = false,
    AimMode = "Always", -- Always / Hold / Toggle
    Wallcheck = true,
    FOV = 120,
    Smoothness = 0.25,
    MaxDistance = 500,
    TargetPart = "Head",
    HitboxEnabled = false,
    HitboxSize = 6,
    HitboxVisual = false,
    HitboxTransparency = 0.7,
    ESPEnabled = false,
    ESPHighlight = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = 200,
    ESPColor = Color3.fromRGB(255, 60, 60),
    InfiniteStamina = false,
    InfiniteNVG = false,
    ReducedMotion = false,
    MobileMode = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
    NotificationsEnabled = true,
}

local Connections = {}
local ActiveHitboxes = {} -- [model] = Part

local function Track(conn)
    table.insert(Connections, conn)
    return conn
end

local function Notify(t)
    if State.NotificationsEnabled then
        WindUI:Notify(t)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "AI Overhaul",
    Icon = "crosshair",
    Author = "by PremiumDev",
    Folder = "AIOverhaul",
    Size = UDim2.fromOffset(520, 400),
    MinSize = Vector2.new(480, 340),
    MaxSize = Vector2.new(700, 520),
    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 170,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    OpenButton = {
        Title = "AI Overhaul",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#FF3B5C"),
            Color3.fromHex("#FF9A3C")
        ),
    },
    Topbar = {
        Height = 40,
        ButtonsType = "Mac",
    },
})

Window:Tag({
    Title = "v2.0",
    Icon = "zap",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

-- Get all AI characters (models in workspace.Characters with an "AI" child)
local function GetAICharacters()
    local out = {}
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return out end
    for _, v in ipairs(chars:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("AI") then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(out, v)
            end
        end
    end
    return out
end

-- Screen-space distance from crosshair (for FOV check)
local function GetScreenDist(worldPos)
    local screenPos, onScreen = Camera:WorldToScreenPoint(worldPos)
    if not onScreen then return math.huge end
    local center = Camera.ViewportSize / 2
    return (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
end

-- Wallcheck: is there clear line of sight from camera to target?
local function HasLineOfSight(fromPos, toPos, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or { Camera, LocalPlayer.Character, Workspace.Terrain }
    params.IgnoreWater = true
    local dir = (toPos - fromPos)
    local result = Workspace:Raycast(fromPos, dir, params)
    if not result then return true end
    -- If the hit instance is part of the target, LOS is clear
    return false, result
end

-- Get the target part for an AI character
local function GetTargetPart(model)
    if State.TargetPart == "Hitbox" then
        local hb = model:FindFirstChild("HitboxExpander")
        if hb then return hb end
    end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    return model:FindFirstChild("Head") or model.PrimaryPart
end

-- ═══════════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════════════════════════
local FOVCircle
local function CreateFOVCircle()
    if FOVCircle then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "AIFOV"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.BackgroundTransparency = 1
    circle.Size = UDim2.fromOffset(State.FOV * 2, State.FOV * 2)
    circle.Position = UDim2.fromScale(0.5, 0.5)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = circle

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    FOVCircle = { gui = gui, circle = circle, stroke = stroke }
end

local function UpdateFOVCircle()
    if not FOVCircle then return end
    FOVCircle.circle.Size = UDim2.fromOffset(State.FOV * 2, State.FOV * 2)
    FOVCircle.circle.Visible = State.AimbotEnabled
end

local function DestroyFOVCircle()
    if FOVCircle then
        FOVCircle.gui:Destroy()
        FOVCircle = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- HITBOX EXPANDER (ILLUSION — invisible box, head stays normal)
-- ═══════════════════════════════════════════════════════════════
local function ApplyHitbox(model)
    if not model or not model.Parent then return end
    if ActiveHitboxes[model] then return end

    local head = model:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end

    -- Create invisible box welded to head
    local box = Instance.new("Part")
    box.Name = "HitboxExpander"
    box.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
    box.Transparency = State.HitboxVisual and (1 - State.HitboxTransparency) or 1
    box.CanCollide = false
    box.CanQuery = true
    box.CanTouch = false
    box.Massless = true
    box.Anchored = false
    box.Material = Enum.Material.ForceField
    box.Color = Color3.fromRGB(255, 80, 80)
    box.CFrame = head.CFrame

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = box
    weld.Parent = box

    box.Parent = model
    ActiveHitboxes[model] = box
end

local function RemoveHitbox(model)
    local box = ActiveHitboxes[model]
    if box then
        box:Destroy()
        ActiveHitboxes[model] = nil
    end
end

local function RefreshAllHitboxes()
    if State.HitboxEnabled then
        for _, model in ipairs(GetAICharacters()) do
            ApplyHitbox(model)
        end
    else
        for model in pairs(ActiveHitboxes) do
            RemoveHitbox(model)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ESP FOR AI
-- ═══════════════════════════════════════════════════════════════
local ESPObjects = {} -- [model] = {highlight, billboard, nameLabel, healthLabel}

local function ClearESP(model)
    local data = ESPObjects[model]
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    ESPObjects[model] = nil
end

local function ClearAllESP()
    for model in pairs(ESPObjects) do
        ClearESP(model)
    end
end

local function ApplyESP(model)
    if not model or not model.Parent then return end
    if not State.ESPEnabled then return end
    if ESPObjects[model] then return end

    local head = model:FindFirstChild("Head") or model.PrimaryPart
    if not head then return end

    local data = {}

    if State.ESPHighlight then
        local hl = Instance.new("Highlight")
        hl.Name = "AIOverhaul_HL"
        hl.Adornee = model
        hl.FillColor = State.ESPColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        data.highlight = hl
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "AIOverhaul_BB"
    bb.Adornee = head
    bb.Size = UDim2.fromOffset(100, 40)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = State.ESPDistance
    bb.Parent = model
    data.billboard = bb

    if State.ESPName then
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = State.ESPColor
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Text = model.Name
        nameLabel.Parent = bb
        data.nameLabel = nameLabel
    end

    if State.ESPHealth then
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "Health"
        healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        healthLabel.TextStrokeTransparency = 0
        healthLabel.TextScaled = true
        healthLabel.Font = Enum.Font.SourceSans
        healthLabel.Text = "100 / 100"
        healthLabel.Parent = bb
        data.healthLabel = healthLabel
    end

    ESPObjects[model] = data
end

local function RefreshAllESP()
    if not State.ESPEnabled then
        ClearAllESP()
        return
    end
    for _, model in ipairs(GetAICharacters()) do
        ApplyESP(model)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INFINITE STAMINA
-- ═══════════════════════════════════════════════════════════════
local function SetupInfiniteStamina(char)
    local handler = char:WaitForChild("ClientHandler", 5)
        or char:WaitForChild("Client", 5)
        or char:WaitForChild("ClientOLD", 5)
    if not handler then return end
    local ok, StateMod = pcall(require, handler:WaitForChild("State", 5))
    if not ok or not StateMod or not StateMod.stamina then return end

    local conn = RunService.Heartbeat:Connect(function()
        if not State.InfiniteStamina then return end
        StateMod.stamina.current = 200
        StateMod.stamina.regenDelay = 0
        StateMod.stamina.fullRegen = false
        StateMod.stamina.active = false
        if StateMod.stamina.exhausted ~= nil then
            StateMod.stamina.exhausted = false
        end
    end)
    Track(conn)
end

-- ═══════════════════════════════════════════════════════════════
-- INFINITE NVG
-- ═══════════════════════════════════════════════════════════════
local function SetupInfiniteNVG(char)
    local flag = char:FindFirstChild("IsCloaker")
    if not flag then
        flag = Instance.new("BoolValue")
        flag.Name = "IsCloaker"
        flag.Parent = char
    end
    flag.Value = true

    Track(flag.Changed:Connect(function()
        if State.InfiniteNVG and flag.Value ~= true then
            flag.Value = true
        end
    end))

    Track(char.ChildAdded:Connect(function(child)
        if State.InfiniteNVG and child.Name == "IsCloaker" and child:IsA("BoolValue") then
            child.Value = true
        end
    end))
end

-- ═══════════════════════════════════════════════════════════════
-- AIMBOT CORE
-- ═══════════════════════════════════════════════════════════════

-- Returns the best target for the aimbot, or nil
local function FindBestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local best, bestScore = nil, math.huge

    for _, model in ipairs(GetAICharacters()) do
        local part = GetTargetPart(model)
        if part then
            -- Distance check
            local dist = (Camera.CFrame.Position - part.Position).Magnitude
            if dist <= State.MaxDistance then
                -- FOV check (screen-space)
                local screenDist = GetScreenDist(part.Position)
                if screenDist <= State.FOV then
                    -- Wallcheck
                    if not State.Wallcheck or HasLineOfSight(Camera.CFrame.Position, part.Position, { Camera, LocalPlayer.Character, model, Workspace.Terrain }) then
                        -- Score: prefer closest to crosshair
                        if screenDist < bestScore then
                            bestScore = screenDist
                            best = part
                        end
                    end
                end
            end
        end
    end

    return best
end

-- Heartbeat aimbot update
local function AimbotLoop(dt)
    if not State.AimbotEnabled then return end
    if State.AimMode == "Hold" and not State.AimKeyDown then return end

    local targetPart = FindBestTarget()
    if not targetPart then return end

    local cam = Workspace.CurrentCamera
    local targetCF = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)

    if State.ReducedMotion then
        cam.CFrame = targetCF
    else
        local alpha = math.clamp(State.Smoothness * dt * 60, 0, 1)
        cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- THROTTLED UPDATE LOOP (single connection for ESP health + cleanup)
-- ═══════════════════════════════════════════════════════════════
local updateAccum = 0
local UPDATE_INTERVAL = 0.12 -- seconds (throttled, not per-frame)

local function ThrottledUpdate(dt)
    updateAccum = updateAccum + dt
    if updateAccum < UPDATE_INTERVAL then return end
    updateAccum = 0

    -- ESP health text + distance culling
    if State.ESPEnabled then
        for model, data in pairs(ESPObjects) do
            if not model.Parent then
                ClearESP(model)
            else
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and data.healthLabel then
                    data.healthLabel.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                end
                if data.billboard then
                    data.billboard.MaxDistance = State.ESPDistance
                end
            end
        end
    end

    -- Hitbox cleanup for dead/removed models
    if State.HitboxEnabled then
        for model, box in pairs(ActiveHitboxes) do
            if not model.Parent or not box.Parent then
                if box then box:Destroy() end
                ActiveHitboxes[model] = nil
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SINGLE MAIN LOOP
-- ═══════════════════════════════════════════════════════════════
local mainConn = RunService.Heartbeat:Connect(function(dt)
    AimbotLoop(dt)
    ThrottledUpdate(dt)
end)
Track(mainConn)

-- ═══════════════════════════════════════════════════════════════
-- AI WATCHER (event-driven, no polling)
-- ═══════════════════════════════════════════════════════════════
local function WatchAI(v)
    if not v:IsA("Model") or not v:FindFirstChild("AI") then return end
    task.wait(0.05)
    if not v.Parent then return end

    if State.ESPEnabled then ApplyESP(v) end
    if State.HitboxEnabled then ApplyHitbox(v) end

    v.AncestryChanged:Connect(function()
        if not v.Parent then
            ClearESP(v)
            RemoveHitbox(v)
        end
    end)
end

local charFolder = Workspace:WaitForChild("Characters", 5)
if charFolder then
    for _, v in ipairs(charFolder:GetChildren()) do
        WatchAI(v)
    end
    Track(charFolder.ChildAdded:Connect(WatchAI))
end

-- ═══════════════════════════════════════════════════════════════
-- CHARACTER HOOKS (stamina + NVG)
-- ═══════════════════════════════════════════════════════════════
local function OnCharacter(char)
    SetupInfiniteStamina(char)
    SetupInfiniteNVG(char)
end

if LocalPlayer.Character then OnCharacter(LocalPlayer.Character) end
Track(LocalPlayer.CharacterAdded:Connect(OnCharacter))

-- ═══════════════════════════════════════════════════════════════
-- UI — SECTIONS
-- ═══════════════════════════════════════════════════════════════

-- ══════ COMBAT ══════
local CombatSection = Window:Section({ Title = "Combat" })

local AimbotTab = CombatSection:Tab({
    Title = "Aimbot",
    Icon = "crosshair",
    IconColor = Color3.fromHex("#FF3B5C"),
    IconShape = "Square",
})

-- Aim activation
local AimSection = AimbotTab:Section({ Title = "Activation", Opened = true })

AimSection:Toggle({
    Title = "Enable Aimbot",
    Desc = "Aims at nearest AI target",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Flag = "AimbotEnabled",
    Callback = function(state)
        State.AimbotEnabled = state
        CreateFOVCircle()
        UpdateFOVCircle()
        Notify({
            Title = state and "Aimbot ON" or "Aimbot OFF",
            Content = state and "Targeting AI..." or "Aimbot disabled.",
            Icon = "crosshair",
        })
    end,
})

AimSection:Space({ Columns = 1 })

local aimModeDropdown = AimSection:Dropdown({
    Title = "Activation Mode",
    Desc = "How the aimbot engages",
    Icon = "mouse-pointer",
    Values = { "Always", "Hold", "Toggle" },
    Default = "Always",
    Flag = "AimMode",
    Callback = function(v)
        State.AimMode = v
        if v == "Always" then
            State.AimbotEnabled = true
        end
        UpdateFOVCircle()
    end,
})

AimSection:Space({ Columns = 1 })

local aimKeybind = AimSection:Keybind({
    Title = "Aim Key (Hold/Toggle)",
    Desc = "Key to activate aimbot in Hold/Toggle mode",
    Icon = "keyboard",
    Value = "E",
    Flag = "AimKey",
})

AimSection:Space({ Columns = 1 })

-- FOV / smoothness
local TargetSection = AimbotTab:Section({ Title = "Targeting", Opened = true })

TargetSection:Slider({
    Title = "FOV",
    Desc = "Field of view for target detection",
    Icon = "circle-dot",
    Min = 20,
    Max = 600,
    Default = 120,
    Step = 5,
    Suffix = "px",
    Flag = "AimbotFOV",
    Callback = function(v)
        State.FOV = v
        UpdateFOVCircle()
    end,
})

TargetSection:Space({ Columns = 1 })

TargetSection:Slider({
    Title = "Smoothness",
    Desc = "Higher = smoother aim",
    Icon = "activity",
    Min = 0.02,
    Max = 1,
    Default = 0.25,
    Step = 0.02,
    Flag = "AimbotSmooth",
    Callback = function(v) State.Smoothness = v end,
})

TargetSection:Space({ Columns = 1 })

TargetSection:Slider({
    Title = "Max Distance",
    Desc = "Max targeting range (studs)",
    Icon = "ruler",
    Min = 50,
    Max = 2000,
    Default = 500,
    Step = 50,
    Suffix = " studs",
    Flag = "AimbotDistance",
    Callback = function(v) State.MaxDistance = v end,
})

TargetSection:Space({ Columns = 1 })

local targetPartDropdown = TargetSection:Dropdown({
    Title = "Target Part",
    Desc = "Which part to aim at",
    Icon = "target",
    Values = { "Head", "Hitbox", "RootPart" },
    Default = "Head",
    Flag = "TargetPart",
    Callback = function(v) State.TargetPart = v end,
})

TargetSection:Space({ Columns = 1 })

TargetSection:Toggle({
    Title = "Wallcheck",
    Desc = "Only aim when line of sight is clear",
    Icon = "eye-off",
    Type = "Checkbox",
    Value = true,
    Flag = "Wallcheck",
    Callback = function(v) State.Wallcheck = v end,
})

-- ══════ HITBOX ══════
local HitboxTab = CombatSection:Tab({
    Title = "Hitbox",
    Icon = "box",
    IconColor = Color3.fromHex("#FF9A3C"),
    IconShape = "Square",
})

local HitboxSection = HitboxTab:Section({ Title = "Hitbox Expander", Opened = true })

HitboxSection:Toggle({
    Title = "Enable Hitbox Expander",
    Desc = "Invisible box around AI head (model stays normal)",
    Icon = "box",
    Type = "Checkbox",
    Value = false,
    Flag = "HitboxEnabled",
    Callback = function(state)
        State.HitboxEnabled = state
        RefreshAllHitboxes()
        Notify({
            Title = state and "Hitbox ON" or "Hitbox OFF",
            Content = state and "Expanded hitboxes applied." or "Hitboxes removed.",
            Icon = "box",
        })
    end,
})

HitboxSection:Space({ Columns = 1 })

HitboxSection:Slider({
    Title = "Hitbox Size",
    Desc = "Size of the invisible box (studs)",
    Icon = "maximize",
    Min = 2,
    Max = 20,
    Default = 6,
    Step = 0.5,
    Suffix = " studs",
    Flag = "HitboxSize",
    Callback = function(v)
        State.HitboxSize = v
        for _, box in pairs(ActiveHitboxes) do
            box.Size = Vector3.new(v, v, v)
        end
    end,
})

HitboxSection:Space({ Columns = 1 })

HitboxSection:Toggle({
    Title = "Visualize Hitbox",
    Desc = "Shows the box (semi-transparent)",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Flag = "HitboxVisual",
    Callback = function(v)
        State.HitboxVisual = v
        for _, box in pairs(ActiveHitboxes) do
            box.Transparency = v and (1 - State.HitboxTransparency) or 1
        end
    end,
})

HitboxSection:Space({ Columns = 1 })

HitboxSection:Slider({
    Title = "Box Opacity",
    Desc = "Transparency of visual box",
    Icon = "droplet",
    Min = 0,
    Max = 1,
    Default = 0.3,
    Step = 0.05,
    Flag = "HitboxOpacity",
    Callback = function(v)
        State.HitboxTransparency = 1 - v
        if State.HitboxVisual then
            for _, box in pairs(ActiveHitboxes) do
                box.Transparency = 1 - v
            end
        end
    end,
})

-- ══════ VISUALS ══════
local VisualsSection = Window:Section({ Title = "Visuals" })

local ESPTab = VisualsSection:Tab({
    Title = "AI ESP",
    Icon = "eye",
    IconColor = Color3.fromHex("#00CEC9"),
    IconShape = "Square",
})

local ESPMain = ESPTab:Section({ Title = "ESP Elements", Opened = true })

ESPMain:Toggle({
    Title = "Enable AI ESP",
    Desc = "Highlight and label all AI",
    Icon = "scan",
    Type = "Checkbox",
    Value = false,
    Flag = "ESPEnabled",
    Callback = function(state)
        State.ESPEnabled = state
        RefreshAllESP()
        Notify({
            Title = state and "ESP ON" or "ESP OFF",
            Content = state and "AI ESP enabled." or "AI ESP disabled.",
            Icon = "eye",
        })
    end,
})

ESPMain:Space({ Columns = 2 })

ESPMain:Toggle({
    Title = "Highlight",
    Desc = "Colored outline through walls",
    Icon = "square",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPHighlight",
    Callback = function(v)
        State.ESPHighlight = v
        RefreshAllESP()
    end,
})

ESPMain:Toggle({
    Title = "Name Tag",
    Desc = "Show AI name above head",
    Icon = "user",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPName",
    Callback = function(v)
        State.ESPName = v
        RefreshAllESP()
    end,
})

ESPMain:Space({ Columns = 1 })

ESPMain:Toggle({
    Title = "Health Bar",
    Desc = "Show health text above head",
    Icon = "heart",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPHealth",
    Callback = function(v)
        State.ESPHealth = v
        RefreshAllESP()
    end,
})

-- ESP settings
local ESPSettings = ESPTab:Section({ Title = "ESP Settings", Opened = false })

ESPSettings:Slider({
    Title = "ESP Distance",
    Desc = "Max render distance",
    Icon = "ruler",
    Min = 50,
    Max = 1000,
    Default = 200,
    Step = 50,
    Suffix = " studs",
    Flag = "ESPDistance",
    Callback = function(v)
        State.ESPDistance = v
        for _, data in pairs(ESPObjects) do
            if data.billboard then data.billboard.MaxDistance = v end
        end
    end,
})

ESPSettings:Space({ Columns = 1 })

ESPSettings:Colorpicker({
    Title = "ESP Color",
    Desc = "Highlight and text color",
    Default = Color3.fromRGB(255, 60, 60),
    Transparency = 0,
    Flag = "ESPColor",
    Callback = function(c)
        State.ESPColor = c
        for _, data in pairs(ESPObjects) do
            if data.highlight then data.highlight.FillColor = c end
            if data.nameLabel then data.nameLabel.TextColor3 = c end
        end
    end,
})

-- ══════ PLAYER ══════
local PlayerSection = Window:Section({ Title = "Player" })

local PerksTab = PlayerSection:Tab({
    Title = "Perks",
    Icon = "star",
    IconColor = Color3.fromHex("#A29BFE"),
    IconShape = "Square",
})

local StaminaSection = PerksTab:Section({ Title = "Stamina", Opened = true })

StaminaSection:Toggle({
    Title = "Infinite Stamina",
    Desc = "Never exhaust (game-specific perk)",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Flag = "InfiniteStamina",
    Callback = function(v)
        State.InfiniteStamina = v
        Notify({
            Title = v and "Infinite Stamina ON" or "Infinite Stamina OFF",
            Content = v and "Stamina will stay maxed." or "Stamina reverted to normal.",
            Icon = "zap",
        })
    end,
})

PerksTab:Space({ Columns = 1 })

local NVGSection = PerksTab:Section({ Title = "NVG", Opened = true })

NVGSection:Toggle({
    Title = "Infinite NVG",
    Desc = "Permanent night vision (game-specific perk)",
    Icon = "moon",
    Type = "Checkbox",
    Value = false,
    Flag = "InfiniteNVG",
    Callback = function(v)
        State.InfiniteNVG = v
        if LocalPlayer.Character then
            SetupInfiniteNVG(LocalPlayer.Character)
        end
        Notify({
            Title = v and "Infinite NVG ON" or "Infinite NVG OFF",
            Content = v and "NVG always active." or "NVG reverted.",
            Icon = "moon",
        })
    end,
})

-- ══════ SETTINGS ══════
local SettingsSection = Window:Section({ Title = "Settings" })

local ConfigTab = SettingsSection:Tab({
    Title = "Config",
    Icon = "settings",
    IconColor = Color3.fromHex("#74B9FF"),
    IconShape = "Square",
})

local KeySection = ConfigTab:Section({ Title = "Keybinds", Opened = true })

KeySection:Keybind({
    Title = "UI Toggle Key",
    Desc = "Open/close this hub",
    Icon = "keyboard",
    Value = "RightShift",
    Flag = "UIToggleKey",
    Callback = function(key)
        pcall(function()
            Window:SetToggleKey(Enum.KeyCode[key])
        end)
    end,
})

ConfigTab:Space({ Columns = 1 })

local PerfSection = ConfigTab:Section({ Title = "Performance", Opened = false })

PerfSection:Toggle({
    Title = "Reduced Motion",
    Desc = "Disable aim smoothing (snap instead)",
    Icon = "accessibility",
    Type = "Checkbox",
    Value = false,
    Flag = "ReducedMotion",
    Callback = function(v) State.ReducedMotion = v end,
})

PerfSection:Space({ Columns = 1 })

PerfSection:Toggle({
    Title = "Disable Notifications",
    Desc = "Hide all popups",
    Icon = "bell-off",
    Type = "Checkbox",
    Value = false,
    Flag = "DisableNotifications",
    Callback = function(v)
        State.NotificationsEnabled = not v
    end,
})

ConfigTab:Space({ Columns = 1 })

ConfigTab:Toggle({
    Title = "Mobile-Friendly Mode",
    Desc = "Larger UI for touch screens",
    Icon = "smartphone",
    Type = "Checkbox",
    Value = State.MobileMode,
    Flag = "MobileMode",
    Callback = function(v)
        State.MobileMode = v
        pcall(function()
            Window:SetUIScale(v and 1.15 or 1)
        end)
    end,
})

ConfigTab:Space({ Columns = 1 })

ConfigTab:Button({
    Title = "Unload Hub",
    Desc = "Remove UI and disable all features",
    Icon = "trash-2",
    Color = Color3.fromHex("#FF3B5C"),
    Callback = function()
        WindUI:Popup({
            Title = "Unload AI Overhaul?",
            Icon = "alert-triangle",
            Content = "All features will be disabled and the UI removed.",
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
                        -- Cleanup
                        for _, conn in ipairs(Connections) do
                            pcall(function() conn:Disconnect() end)
                        end
                        table.clear(Connections)
                        ClearAllESP()
                        for model in pairs(ActiveHitboxes) do
                            RemoveHitbox(model)
                        end
                        DestroyFOVCircle()
                        Window:Destroy()
                    end,
                },
            },
        })
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- AIM KEYBIND HANDLER
-- ═══════════════════════════════════════════════════════════════
Track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if State.AimMode == "Hold" and input.KeyCode == Enum.KeyCode.E then
        State.AimKeyDown = true
    elseif State.AimMode == "Toggle" and input.KeyCode == Enum.KeyCode.E then
        State.AimbotEnabled = not State.AimbotEnabled
        Notify({
            Title = State.AimbotEnabled and "Aimbot ON" or "Aimbot OFF",
            Icon = "crosshair",
        })
    end
end))

Track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        State.AimKeyDown = false
    end
end))

-- ═══════════════════════════════════════════════════════════════
-- MOBILE SCALE
-- ═══════════════════════════════════════════════════════════════
if State.MobileMode then
    pcall(function() Window:SetUIScale(1.15) end)
end

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP ON SCRIPT DESTROY
-- ═══════════════════════════════════════════════════════════════
script.Destroying:Connect(function()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)
    ClearAllESP()
    for model in pairs(ActiveHitboxes) do
        RemoveHitbox(model)
    end
    DestroyFOVCircle()
end)

-- ═══════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════
Notify({
    Title = "AI Overhaul Loaded",
    Content = "Press RightShift to open. Aimbot targets AI only.",
    Icon = "check-circle",
    Duration = 5,
})