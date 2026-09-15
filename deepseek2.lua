-- // eclipse · examination
-- // ui · windui (beta) by footagesus
-- // built for examination only · 10165583746

-- // services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // supported places
local SUPPORTED = { [10165583746] = "Examination" }
if not SUPPORTED[game.PlaceId] then
    pcall(function() LP:Kick("This game is not supported.") end)
    return
end

-- // load windui
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- // shared
local Conns = {}
local S = {
    reduced = false,
    perfMode = false,
    notif = true,
    espRate = 0.08,
}

local function track(c)
    table.insert(Conns, c)
    return c
end

local function notify(t)
    if S.notif then WindUI:Notify(t) end
end

local function keyOk(name)
    if type(name) ~= "string" then return false end
    return pcall(function() return Enum.KeyCode[name] end)
end

-- // game settings bridge
local function csNode(path)
    local node = LP:FindFirstChild("ClientSettings")
    if not node then return nil end
    for _, seg in ipairs(path) do
        node = node:FindFirstChild(seg)
        if not node then return nil end
    end
    return node
end

local function csGet(path, attr, default)
    local node = csNode(path)
    if not node then return default end
    local v = node:GetAttribute(attr)
    if v == nil then return default end
    return v
end

local function csSet(path, attr, value)
    local node = csNode(path)
    if not node then return end
    pcall(function() node:SetAttribute(attr, value) end)
end

local function bindSync(toggle, path, attr, default)
    local node = csNode(path)
    if not node then return end
    local syncing = false
    track(node.AttributeChanged:Connect(function(changed)
        if changed ~= attr or syncing then return end
        local v = node:GetAttribute(attr)
        if v == nil then v = default end
        syncing = true
        pcall(function() toggle:Set(v) end)
        syncing = false
    end))
end

-- // movement state (defined early so character hookup never touches a nil)
local Move = {
    noclip = false,
    noclipConn = nil,
    speedOn = false,
    speed = 16,
    jumpOn = false,
    jump = 50,
}

-- // target helpers
local function isAI(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return model:FindFirstChild("AI") ~= nil
end

local function humOf(model)
    return model:FindFirstChildOfClass("Humanoid")
end

local function collectPvE()
    local out = {}
    local folder = Workspace:FindFirstChild("Characters")
    if not folder then return out end
    for _, m in ipairs(folder:GetChildren()) do
        if isAI(m) then
            local hum = humOf(m)
            if hum and hum.Health > 0 then
                out[#out + 1] = { model = m, hum = hum }
            end
        end
    end
    return out
end

local friendCache = {}
task.spawn(function()
    local ok, pages = pcall(function() return LP:GetFriendsAsync() end)
    if not ok or not pages then return end
    while true do
        local ok2, items = pcall(function() return pages:GetCurrentPage() end)
        if not ok2 or type(items) ~= "table" then break end
        for _, item in ipairs(items) do
            friendCache[item.Id] = true
        end
        if pages.IsFinished then break end
        if not pcall(function() pages:AdvanceToNextPageAsync() end) then break end
    end
end)

local function collectPvP(teamCheck, ignoreFriends)
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local skip = false
            if teamCheck and p.Team ~= nil and p.Team == LP.Team then skip = true end
            if not skip and ignoreFriends and friendCache[p.UserId] then skip = true end
            if not skip then
                local char = p.Character
                local hum = char and humOf(char)
                if char and hum and hum.Health > 0 then
                    out[#out + 1] = { model = char, hum = hum, player = p }
                end
            end
        end
    end
    return out
end

local function partFor(model, kind, hum)
    if kind == "Hitbox" then
        local hb = model:FindFirstChild("Head")
        if hb then return hb end
    end
    if kind == "HumanoidRootPart" then
        return (hum and hum.RootPart) or model:FindFirstChild("HumanoidRootPart")
    end
    if kind == "Torso" then
        return model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
            or (hum and hum.RootPart)
    end
    return model:FindFirstChild("Head")
        or (hum and hum.RootPart)
        or model.PrimaryPart
end

local function screenDist(worldPos)
    local sp, on = Camera:WorldToViewportPoint(worldPos)
    if not on then return math.huge end
    local c = Camera.ViewportSize * 0.5
    local dx, dy = sp.X - c.X, sp.Y - c.Y
    return math.sqrt(dx * dx + dy * dy)
end

local function visible(from, to, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local hit = Workspace:Raycast(from, to - from, params)
    if not hit then return true end
    for _, inst in ipairs(ignore) do
        if typeof(inst) == "Instance" and hit.Instance:IsDescendantOf(inst) then
            return true
        end
    end
    return false
end

-- // fov ring
local FovGui, FovRing, FovStroke
local function ensureFov()
    if FovGui then return end
    FovGui = Instance.new("ScreenGui")
    FovGui.Name = "EclipseFov"
    FovGui.IgnoreGuiInset = true
    FovGui.ResetOnSpawn = false
    FovGui.Parent = LP:WaitForChild("PlayerGui")

    FovRing = Instance.new("Frame")
    FovRing.AnchorPoint = Vector2.new(0.5, 0.5)
    FovRing.Position = UDim2.fromScale(0.5, 0.5)
    FovRing.BackgroundTransparency = 1
    FovRing.Visible = false
    FovRing.Parent = FovGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = FovRing

    FovStroke = Instance.new("UIStroke")
    FovStroke.Color = Color3.fromRGB(124, 92, 255)
    FovStroke.Thickness = 1.5
    FovStroke.Transparency = 0.45
    FovStroke.Parent = FovRing
end

-- // aimbot
local Aim = {
    pve = {
        on = false, mode = "Toggle", key = "E", keyDown = false, toggled = false,
        part = "Head", fov = 130, smooth = 0.22, dist = 700,
        wall = true, showFov = true, deadzone = 0,
    },
    pvp = {
        on = false, mode = "Hold", key = "Q", keyDown = false, toggled = false,
        part = "Head", fov = 110, smooth = 0.28, dist = 450,
        wall = true, showFov = false, deadzone = 0,
        team = true, friends = true,
    },
}

local function aimActive(cfg)
    if not cfg.on then return false end
    if cfg.mode == "Always" then return true end
    if cfg.mode == "Hold" then return cfg.keyDown end
    return cfg.toggled
end

local function pickTarget(list, cfg)
    local camPos = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    local baseIgnore = { Camera, LP.Character, Workspace.Terrain }

    for _, entry in ipairs(list) do
        local part = partFor(entry.model, cfg.part, entry.hum)
        if part then
            local dist = (camPos - part.Position).Magnitude
            if dist <= cfg.dist then
                local sd = screenDist(part.Position)
                if sd <= cfg.fov and sd >= cfg.deadzone then
                    local clear = true
                    if cfg.wall then
                        local ignore = table.clone(baseIgnore)
                        ignore[#ignore + 1] = entry.model
                        clear = visible(camPos, part.Position, ignore)
                    end
                    if clear and sd < bestScore then
                        bestScore = sd
                        best = part
                    end
                end
            end
        end
    end
    return best
end

-- =========================================================
-- hitbox expander — uses your working head approach
-- resizes the actual Head so hits register, keeps default
-- head shape only changes size + transparency
-- =========================================================
local Hitboxes = {}

local function applyHitbox(model, size, transparency)
    if not model or not model.Parent then return end
    local head = model:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end

    local entry = Hitboxes[model]
    if not entry then
        entry = {
            head = head,
            saved = {
                size = head.Size,
                transparency = head.Transparency,
                cancollide = head.CanCollide,
            },
        }
        Hitboxes[model] = entry
    end

    pcall(function()
        head.Size = Vector3.new(size, size, size)
        head.CanCollide = false
        head.Transparency = transparency
    end)
end

local function removeHitbox(model)
    local entry = Hitboxes[model]
    if not entry then return end
    if entry.head and entry.head.Parent then
        pcall(function()
            entry.head.Size = entry.saved.size
            entry.head.Transparency = entry.saved.transparency
            entry.head.CanCollide = entry.saved.cancollide
        end)
    end
    Hitboxes[model] = nil
end

local function clearAllHitboxes()
    for m in pairs(Hitboxes) do removeHitbox(m) end
end

-- // esp — separate object tables per kind, distance culled
local Esp = {
    pve = {
        on = false, highlight = true, name = true, hp = true, dist = true,
        distMax = 250, color = Color3.fromRGB(255, 72, 72),
    },
    pvp = {
        on = false, highlight = true, name = true, hp = true, dist = true,
        distMax = 500, color = Color3.fromRGB(80, 200, 255),
        team = true, friends = true,
    },
}

local EspGui
local EspPvEObjects = {}
local EspPvPObjects = {}

local function ensureEspGui()
    if EspGui then return end
    EspGui = Instance.new("ScreenGui")
    EspGui.Name = "EclipseEsp"
    EspGui.IgnoreGuiInset = true
    EspGui.ResetOnSpawn = false
    EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    EspGui.Parent = LP:WaitForChild("PlayerGui")
end

local function clearOneEsp(tbl, model)
    local o = tbl[model]
    if not o then return end
    if o.hl then o.hl:Destroy() end
    if o.bb then o.bb:Destroy() end
    tbl[model] = nil
end

local function clearEspTable(tbl)
    for m in pairs(tbl) do clearOneEsp(tbl, m) end
end

local function makeEsp(tbl, model, cfg)
    if tbl[model] then return end
    local head = model:FindFirstChild("Head") or model.PrimaryPart
    if not head then return end

    local o = {}

    if cfg.highlight then
        local hl = Instance.new("Highlight")
        hl.Name = "EclipseHL"
        hl.Adornee = model
        hl.FillColor = cfg.color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        o.hl = hl
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "EclipseBB"
    bb.Adornee = head
    bb.Size = UDim2.fromOffset(140, 44)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = cfg.distMax
    bb.Parent = model
    o.bb = bb

    if cfg.name then
        local n = Instance.new("TextLabel")
        n.Name = "TagName"
        n.Size = UDim2.new(1, 0, 0.5, 0)
        n.BackgroundTransparency = 1
        n.TextColor3 = cfg.color
        n.TextStrokeTransparency = 0
        n.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        n.TextScaled = true
        n.Font = Enum.Font.GothamBold
        n.Text = model.Name
        n.Parent = bb
        o.name = n
    end

    if cfg.hp then
        local hp = Instance.new("TextLabel")
        hp.Name = "TagHp"
        hp.Size = UDim2.new(1, 0, 0.5, 0)
        hp.Position = UDim2.new(0, 0, 0.5, 0)
        hp.BackgroundTransparency = 1
        hp.TextColor3 = Color3.fromRGB(255, 255, 255)
        hp.TextStrokeTransparency = 0
        hp.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        hp.TextScaled = true
        hp.Font = Enum.Font.Gotham
        hp.Text = "100"
        hp.Parent = bb
        o.hp = hp
    end

    if cfg.dist then
        local d = Instance.new("TextLabel")
        d.Name = "TagDist"
        d.Size = UDim2.new(1, 0, 0, 14)
        d.Position = UDim2.new(0, 0, 1, 2)
        d.BackgroundTransparency = 1
        d.TextColor3 = Color3.fromRGB(210, 210, 210)
        d.TextStrokeTransparency = 0.4
        d.TextScaled = true
        d.Font = Enum.Font.Gotham
        d.Text = "0m"
        d.Parent = bb
        o.dist = d
    end

    tbl[model] = o
end

local function refreshEspKind(kind)
    local cfg = Esp[kind]
    local tbl = (kind == "pve") and EspPvEObjects or EspPvPObjects

    if not cfg.on then
        clearEspTable(tbl)
        return
    end

    local camPos = Camera.CFrame.Position
    local list = (kind == "pve") and collectPvE() or collectPvP(cfg.team, cfg.friends)
    local seen = {}

    for _, entry in ipairs(list) do
        local model = entry.model
        local head = model:FindFirstChild("Head") or model.PrimaryPart
        if head then
            local dist = (camPos - head.Position).Magnitude
            if dist <= cfg.distMax then
                seen[model] = true
                makeEsp(tbl, model, cfg)
                local o = tbl[model]
                if o then
                    if o.hl then
                        o.hl.FillColor = cfg.color
                        o.hl.Enabled = cfg.highlight
                    end
                    if o.bb then o.bb.MaxDistance = cfg.distMax end
                    if o.hp and entry.hum then
                        o.hp.Text = tostring(math.floor(entry.hum.Health))
                        o.hp.Visible = cfg.hp
                    end
                    if o.name then
                        o.name.TextColor3 = cfg.color
                        o.name.Text = entry.player and entry.player.DisplayName or model.Name
                        o.name.Visible = cfg.name
                    end
                    if o.dist then
                        o.dist.Text = tostring(math.floor(dist)) .. "m"
                        o.dist.Visible = cfg.dist
                    end
                end
            end
        end
    end

    for m in pairs(tbl) do
        if not seen[m] or not m.Parent then
            clearOneEsp(tbl, m)
        end
    end
end

-- // stamina
local Stamina = { on = false, module = nil, char = nil, bound = {} }

local function bindStamina(char)
    if Stamina.bound[char] then return end
    Stamina.bound[char] = true
    Stamina.char = char

    task.spawn(function()
        local handler
        for _ = 1, 40 do
            handler = char:FindFirstChild("ClientHandler")
                or char:FindFirstChild("Client")
                or char:FindFirstChild("ClientOLD")
            if handler then break end
            task.wait(0.1)
        end
        if not handler then return end

        local stateFolder = handler:WaitForChild("State", 5)
        if not stateFolder then return end

        local ok, mod = pcall(require, stateFolder)
        if not ok or type(mod) ~= "table" or not mod.stamina then return end
        if Stamina.char == char and Stamina.on then
            Stamina.module = mod
        end
    end)
end

local function unbindStamina(char)
    Stamina.bound[char] = nil
    if Stamina.char == char then
        Stamina.char = nil
        Stamina.module = nil
    end
end

-- // nvg
local Nvg = { on = false, bound = {} }

local function bindNvg(char)
    if Nvg.bound[char] then return end
    Nvg.bound[char] = true

    local flag = char:FindFirstChild("IsCloaker")
    if not flag then
        flag = Instance.new("BoolValue")
        flag.Name = "IsCloaker"
        flag.Parent = char
    end

    if Nvg.on then flag.Value = true end

    track(flag.Changed:Connect(function()
        if Nvg.on and flag.Value ~= true then
            flag.Value = true
        end
    end))

    track(char.ChildAdded:Connect(function(child)
        if Nvg.on and child.Name == "IsCloaker" and child:IsA("BoolValue") then
            child.Value = true
        end
    end))
end

-- // character hookup — nothing touches the character unless its own toggle is on
local function onCharacter(char)
    if Move.speedOn then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hum.WalkSpeed = Move.speed end
    end
    if Move.jumpOn then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = Move.jump
        end
    end
    if Move.noclip then
        -- loop already handles this, but re-flag for safety
        Move.noclip = true
    end
    if Stamina.on then bindStamina(char) end
    if Nvg.on then bindNvg(char) end
end

track(LP.CharacterAdded:Connect(onCharacter))
LP.CharacterRemoving:Connect(function()
    if LP.Character then unbindStamina(LP.Character) end
end)

-- // noclip loop (only runs when enabled)
local noclipConn = RunService.Stepped:Connect(function()
    if not Move.noclip then return end
    local char = LP.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then
            d.CanCollide = false
        end
    end
end)
track(noclipConn)

-- // ai watcher
local function onAIAdded(v)
    if not isAI(v) then return end
    task.wait(0.08)
    if not v.Parent then return end

    if HitboxPvE.on then
        applyHitbox(v, HitboxPvE.size, HitboxPvE.transparency)
    end

    v.AncestryChanged:Connect(function()
        if not v.Parent then
            removeHitbox(v)
            clearOneEsp(EspPvEObjects, v)
        end
    end)
end

local charsFolder = Workspace:WaitForChild("Characters", 10)
if charsFolder then
    for _, v in ipairs(charsFolder:GetChildren()) do
        task.spawn(onAIAdded, v)
    end
    track(charsFolder.ChildAdded:Connect(onAIAdded))
end

-- // player character hookups (hitbox reapply on respawn)
local function onPlayerChar(p, char)
    if p == LP then return end
    if HitboxPvP.on then
        applyHitbox(char, HitboxPvP.size, HitboxPvP.transparency)
    end
    char.AncestryChanged:Connect(function()
        if not char.Parent then
            removeHitbox(char)
            clearOneEsp(EspPvPObjects, char)
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        if p.Character then task.spawn(onPlayerChar, p, p.Character) end
        track(p.CharacterAdded:Connect(function(c) task.spawn(onPlayerChar, p, c) end))
    end
end

track(Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    track(p.CharacterAdded:Connect(function(c) task.spawn(onPlayerChar, p, c) end))
    if p.Character then task.spawn(onPlayerChar, p, p.Character) end
end))

-- // world state
local World = {
    timeOn = false,
    time = 14,
    fogOff = false,
    fogPrev = nil,
    ambientOn = false,
    ambient = Color3.fromRGB(70, 70, 80),
    ambientPrev = nil,
}

-- // input
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local name = input.KeyCode.Name
    if name == Aim.pve.key then
        if Aim.pve.mode == "Hold" then
            Aim.pve.keyDown = true
        elseif Aim.pve.mode == "Toggle" then
            Aim.pve.toggled = not Aim.pve.toggled
        end
    end
    if name == Aim.pvp.key then
        if Aim.pvp.mode == "Hold" then
            Aim.pvp.keyDown = true
        elseif Aim.pvp.mode == "Toggle" then
            Aim.pvp.toggled = not Aim.pvp.toggled
        end
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    local name = input.KeyCode.Name
    if name == Aim.pve.key then Aim.pve.keyDown = false end
    if name == Aim.pvp.key then Aim.pvp.keyDown = false end
end))

-- // main loop
local espAccum = 0
local staminaAccum = 0

track(RunService.RenderStepped:Connect(function(dt)
    -- pve aimbot
    if Aim.pve.on and aimActive(Aim.pve) then
        local list = collectPvE()
        local part = pickTarget(list, Aim.pve)
        if part then
            local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
            if S.reduced then
                Camera.CFrame = goal
            else
                local a = math.clamp(Aim.pve.smooth * dt * 60, 0, 1)
                Camera.CFrame = Camera.CFrame:Lerp(goal, a)
            end
        end
    end

    -- pvp aimbot
    if Aim.pvp.on and aimActive(Aim.pvp) then
        local list = collectPvP(Aim.pvp.team, Aim.pvp.friends)
        local part = pickTarget(list, Aim.pvp)
        if part then
            local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
            if S.reduced then
                Camera.CFrame = goal
            else
                local a = math.clamp(Aim.pvp.smooth * dt * 60, 0, 1)
                Camera.CFrame = Camera.CFrame:Lerp(goal, a)
            end
        end
    end

    -- esp
    if Esp.pve.on or Esp.pvp.on then
        espAccum = espAccum + dt
        if espAccum >= S.espRate then
            espAccum = 0
            if Esp.pve.on then refreshEspKind("pve") end
            if Esp.pvp.on then refreshEspKind("pvp") end
        end
    end

    -- infinite stamina
    if Stamina.on and Stamina.module then
        staminaAccum = staminaAccum + dt
        if staminaAccum >= 0.05 then
            staminaAccum = 0
            local st = Stamina.module.stamina
            if st then
                st.current = 200
                st.regenDelay = 0
                st.fullRegen = false
                st.active = false
                if st.exhausted ~= nil then
                    st.exhausted = false
                end
            end
        end
    end
end))

-- // world loop, slow and separate
local worldAccum = 0
track(RunService.Heartbeat:Connect(function(dt)
    if not (World.timeOn or World.fogOff or World.ambientOn) then return end
    worldAccum = worldAccum + dt
    if worldAccum < 0.4 then return end
    worldAccum = 0

    if World.timeOn then
        pcall(function() Lighting.ClockTime = World.time end)
    end
    if World.fogOff then
        pcall(function()
            Lighting.FogEnd = 1e6
            Lighting.FogStart = 1e6
        end)
    end
    if World.ambientOn then
        pcall(function() Lighting.Ambient = World.ambient end)
    end
end))

-- // window
local Window = WindUI:CreateWindow({
    Title = "Eclipse",
    Author = "by MNDEV",
    Icon = "moon-star",
    Folder = "EclipseMNDEV",
    Theme = "Midnight",

    Size = UDim2.fromOffset(80, 80),
    MinSize = Vector2.new(540, 390),
    MaxSize = Vector2.new(880, 600),

    AutoScale = false,
    NewElements = true,
    Resizable = true,
    Transparent = true,
    SideBarWidth = 190,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    ToggleKey = Enum.KeyCode.RightShift,

    Topbar = { Height = 48, ButtonsType = "Default" },

    OpenButton = {
        Title = "Eclipse",
        Icon = "moon-star",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(
            Color3.fromHex("#7C5CFF"),
            Color3.fromHex("#22D3EE")
        ),
    },

    User = { Enabled = false, Anonymous = false },
})

Window:Tag({
    Title = "v1.0",
    Icon = "github",
    Color = Color3.fromHex("#18181b"),
    Border = true,
})

notify({
    Title = "Eclipse loaded",
    Content = "Right Shift toggles the window.",
    Icon = "solar:check-circle-bold",
    Duration = 4,
})

-- =====================================================================
-- HOME
-- =====================================================================
Window:Section({ Title = "Home", Opened = true })

local CreditsTab = Window:Tab({ Title = "Credits", Icon = "book" })

local bannerSection = CreditsTab:Section({ Title = "About Eclipse", Opened = true })

bannerSection:Image({
    Image = "rbxassetid://95176729901641",
    AspectRatio = "16:9",
    Radius = 9,
})

bannerSection:Divider()

bannerSection:Paragraph({
    Title = "Eclipse",
    Desc = "A quiet little toolkit built for Examination. Nothing flashy, just things that work.",
})

bannerSection:Paragraph({
    Title = "Version 1.0",
    Desc = "First public build. Everything here is client side and reversible.",
})

local teamSection = CreditsTab:Section({ Title = "Team", Opened = true })

teamSection:Paragraph({
    Title = "MNDEV",
    Desc = "Lead developer. Wrote the whole thing.",
    Buttons = {
        {
            Icon = "youtube",
            Title = "Channel",
            Callback = function()
                local ok = pcall(function()
                    setclipboard("https://youtube.com/@infinitemndev?si=rpm1GtXg6T4L_qCs")
                end)
                notify({
                    Title = ok and "Copied" or "Copy failed",
                    Content = ok and "YouTube link is on your clipboard." or "Clipboard unavailable.",
                    Icon = "solar:link-bold",
                })
            end,
        },
    },
})

teamSection:Paragraph({
    Title = "Contributors",
    Desc = "Everyone who tested, broke things, and reported them back.",
})

local socialSection = CreditsTab:Section({ Title = "Socials", Opened = true })

socialSection:Button({
    Title = "YouTube",
    Desc = "Copy the channel link.",
    Icon = "youtube",
    Justify = "Between",
    Callback = function()
        local ok = pcall(function()
            setclipboard("https://youtube.com/@infinitemndev?si=rpm1GtXg6T4L_qCs")
        end)
        notify({
            Title = ok and "YouTube copied" or "Copy failed",
            Content = ok and "Paste it anywhere you like." or "Your executor blocked clipboard access.",
            Icon = "solar:link-bold",
        })
    end,
})

socialSection:Button({
    Title = "Discord",
    Desc = "Copy the server invite.",
    Icon = "message-circle",
    Justify = "Between",
    Callback = function()
        local ok = pcall(function()
            setclipboard("https://discord.gg/E4rWJVFqhA")
        end)
        notify({
            Title = ok and "Discord copied" or "Copy failed",
            Content = ok and "Invite is on your clipboard." or "Your executor blocked clipboard access.",
            Icon = "solar:link-bold",
        })
    end,
})

socialSection:Space({ Columns = 1 })

socialSection:Button({
    Title = "Copy both links",
    Desc = "Grabs the channel and the invite in one go.",
    Icon = "clipboard-copy",
    Callback = function()
        local ok = pcall(function()
            setclipboard(
                "YouTube: https://youtube.com/@infinitemndev?si=rpm1GtXg6T4L_qCs\n" ..
                "Discord: https://discord.gg/E4rWJVFqhA"
            )
        end)
        notify({
            Title = ok and "Copied" or "Copy failed",
            Content = ok and "Both links copied." or "Your executor blocked clipboard access.",
            Icon = "solar:clipboard-bold",
        })
    end,
})

local notesSection = CreditsTab:Section({ Title = "Notes", Opened = false })

notesSection:Paragraph({
    Title = "Reversibility",
    Desc = "Every toggle here undoes itself when you turn it off. Close the hub and your game goes back to normal.",
})

notesSection:Paragraph({
    Title = "Scope",
    Desc = "Eclipse only runs in Examination. If you load it somewhere else it will simply close.",
})

-- // settings
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "sliders-horizontal" })

local themeSection = SettingsTab:Section({ Title = "Appearance", Opened = true })

themeSection:Dropdown({
    Title = "Theme",
    Desc = "WindUI ships a handful of palettes. Pick whichever you like.",
    Values = { "Midnight", "Dark", "Light", "Aqua", "Rose" },
    Value = "Midnight",
    AllowNone = false,
    Callback = function(option)
        local ok = pcall(function() WindUI:SetTheme(option) end)
        notify({
            Title = ok and "Theme changed" or "Theme failed",
            Content = ok and ("Now using " .. tostring(option) .. ".") or "That theme is not available.",
            Icon = "solar:palette-bold",
        })
    end,
})

themeSection:Space({ Columns = 1 })

themeSection:Toggle({
    Title = "Reduced motion",
    Desc = "Snaps the aimbot instead of sliding it. Also shortens transitions.",
    Icon = "accessibility",
    Type = "Checkbox",
    Value = false,
    Callback = function(v) S.reduced = v end,
})

local perfSection = SettingsTab:Section({ Title = "Performance", Opened = true })

perfSection:Dropdown({
    Title = "ESP update rate",
    Desc = "How often tags refresh. Lower is lighter.",
    Values = { "Smooth (20/s)", "Balanced (12/s)", "Light (5/s)" },
    Value = "Balanced (12/s)",
    AllowNone = false,
    Callback = function(option)
        if option == "Smooth (20/s)" then
            S.espRate = 0.05
        elseif option == "Balanced (12/s)" then
            S.espRate = 0.08
        else
            S.espRate = 0.20
        end
    end,
})

perfSection:Space({ Columns = 1 })

perfSection:Toggle({
    Title = "Performance mode",
    Desc = "Drops ESP to 4 updates a second and disables highlight fills.",
    Icon = "gauge",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        S.perfMode = v
        if v then
            S.espRate = 0.25
        else
            S.espRate = 0.08
        end
    end,
})

local uiSection = SettingsTab:Section({ Title = "Interface", Opened = true })

uiSection:Keybind({
    Title = "Window key",
    Desc = "Opens and closes the hub.",
    Value = "RightShift",
    Callback = function(v)
        if keyOk(v) then
            pcall(function() Window:SetToggleKey(Enum.KeyCode[v]) end)
        end
    end,
})

uiSection:Space({ Columns = 1 })

uiSection:Toggle({
    Title = "Notifications",
    Desc = "Little popups whenever something changes.",
    Icon = "bell",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) S.notif = v end,
})

uiSection:Space({ Columns = 2 })

uiSection:Button({
    Title = "Reset everything",
    Desc = "Turns off every feature and restores defaults.",
    Icon = "rotate-ccw",
    Justify = "Between",
    Callback = function()
        for _, fn in ipairs(ResetQueue) do pcall(fn) end
        notify({
            Title = "Reset",
            Content = "All features are back to default.",
            Icon = "solar:refresh-bold",
        })
    end,
})

-- =====================================================================
-- MOVEMENT
-- =====================================================================
Window:Section({ Title = "Movement", Opened = true })

local PlayerTab = Window:Tab({ Title = "Player", Icon = "person-standing" })

local noclipSection = PlayerTab:Section({ Title = "Collision", Opened = true })

noclipSection:Toggle({
    Title = "Noclip",
    Desc = "Walk through anything. Turns itself back on after each respawn.",
    Icon = "ghost",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Move.noclip = v
        if not v then
            local char = LP.Character
            if char then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BasePart") then
                        pcall(function() d.CanCollide = true end)
                    end
                end
            end
        end
    end,
})

local speedSection = PlayerTab:Section({ Title = "Speed", Opened = true })

local speedInput
speedInput = speedSection:Input({
    Title = "WalkSpeed",
    Desc = "Any number between 8 and 250.",
    Value = "16",
    InputIcon = "hash",
    Placeholder = "16",
    Callback = function(text)
        local n = tonumber(text)
        if not n then return end
        n = math.clamp(n, 8, 250)
        Move.speed = n
        if Move.speedOn then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = n end
        end
    end,
})

speedSection:Space({ Columns = 1 })

speedSection:Toggle({
    Title = "Apply WalkSpeed",
    Desc = "Reapplies the value above, including after respawn.",
    Icon = "wind",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Move.speedOn = v
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and Move.speed or 16 end
    end,
})

speedSection:Space({ Columns = 1 })

speedSection:Input({
    Title = "JumpPower",
    Desc = "Anything from 50 to 250.",
    Value = "50",
    InputIcon = "hash",
    Placeholder = "50",
    Callback = function(text)
        local n = tonumber(text)
        if not n then return end
        n = math.clamp(n, 50, 250)
        Move.jump = n
        if Move.jumpOn then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = n
            end
        end
    end,
})

speedSection:Space({ Columns = 1 })

speedSection:Toggle({
    Title = "Apply JumpPower",
    Desc = "Locks the value above in place.",
    Icon = "arrow-up-circle",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Move.jumpOn = v
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if v then
                hum.UseJumpPower = true
                hum.JumpPower = Move.jump
            else
                hum.JumpPower = 50
            end
        end
    end,
})

speedSection:Space({ Columns = 2 })

speedSection:Button({
    Title = "Reset movement",
    Desc = "Puts WalkSpeed and JumpPower back to normal.",
    Icon = "undo-2",
    Justify = "Between",
    Callback = function()
        Move.speedOn = false
        Move.jumpOn = false
        Move.speed = 16
        Move.jump = 50
        pcall(function() speedInput:Set("16") end)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        notify({
            Title = "Movement reset",
            Content = "Back to default speed and jump.",
            Icon = "solar:refresh-bold",
        })
    end,
})

local staminaSection = PlayerTab:Section({ Title = "Stamina", Opened = true })

staminaSection:Toggle({
    Title = "Infinite stamina",
    Desc = "Stamina stays pinned at full. Sprinting and sliding never drain it.",
    Icon = "battery-full",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Stamina.on = v
        if v then
            if LP.Character then bindStamina(LP.Character) end
        else
            Stamina.module = nil
        end
        notify({
            Title = v and "Stamina locked" or "Stamina normal",
            Icon = "solar:battery-bold",
        })
    end,
})

-- // local player
local LocalPlayerTab = Window:Tab({ Title = "Local Player", Icon = "monitor-cog" })

local nvgSection = LocalPlayerTab:Section({ Title = "Night Vision", Opened = true })

nvgSection:Toggle({
    Title = "Infinite NVG",
    Desc = "Keeps the night vision flag on at all times.",
    Icon = "moon",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Nvg.on = v
        if v then
            if LP.Character then bindNvg(LP.Character) end
        elseif LP.Character then
            local flag = LP.Character:FindFirstChild("IsCloaker")
            if flag then
                pcall(function() flag.Value = false end)
            end
        end
        notify({
            Title = v and "NVG forced on" or "NVG released",
            Icon = "solar:moon-bold",
        })
    end,
})

local visualsLocal = LocalPlayerTab:Section({ Title = "Local Visuals", Opened = true })

visualsLocal:Toggle({
    Title = "Crosshair",
    Desc = "Show or hide the game's own crosshair.",
    Icon = "crosshair",
    Type = "Checkbox",
    Value = csGet({ "Misc" }, "CrosshairEnabled", true),
    Callback = function(v) csSet({ "Misc" }, "CrosshairEnabled", v) end,
})

visualsLocal:Space({ Columns = 1 })

visualsLocal:Toggle({
    Title = "Hitmarkers",
    Desc = "Hit sounds and the little tick marks.",
    Icon = "target",
    Type = "Checkbox",
    Value = csGet({ "Misc" }, "HitmarkerEnabled", true),
    Callback = function(v) csSet({ "Misc" }, "HitmarkerEnabled", v) end,
})

visualsLocal:Space({ Columns = 2 })

visualsLocal:Toggle({
    Title = "HUD",
    Desc = "Toggles the entire in game interface.",
    Icon = "layout-dashboard",
    Type = "Checkbox",
    Value = csGet({ "Misc" }, "UIEnabled", true),
    Callback = function(v) csSet({ "Misc" }, "UIEnabled", v) end,
})

-- =====================================================================
-- COMBAT (PvE)
-- =====================================================================
Window:Section({ Title = "Combat (PvE)", Opened = true })

local AimbotPvETab = Window:Tab({ Title = "Aimbot", Icon = "target" })

local pveMain = AimbotPvETab:Section({ Title = "Activation", Opened = true })

pveMain:Toggle({
    Title = "Enable",
    Desc = "Tracks the closest AI in your field of view.",
    Icon = "crosshair",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Aim.pve.on = v
        Aim.pve.toggled = false
        ensureFov()
        if FovRing then FovRing.Visible = v and Aim.pve.showFov end
        notify({
            Title = v and "PvE aimbot on" or "PvE aimbot off",
            Icon = "solar:target-bold",
        })
    end,
})

pveMain:Space({ Columns = 1 })

pveMain:Dropdown({
    Title = "Activation mode",
    Desc = "Always tracks. Hold only while the key is down. Toggle flips with the key.",
    Values = { "Always", "Hold", "Toggle" },
    Value = "Toggle",
    AllowNone = false,
    Callback = function(option)
        Aim.pve.mode = option
        Aim.pve.toggled = false
    end,
})

pveMain:Space({ Columns = 1 })

pveMain:Keybind({
    Title = "Activation key",
    Desc = "Ignored while the mode is set to Always.",
    Value = "E",
    Callback = function(v)
        if keyOk(v) then Aim.pve.key = v end
    end,
})

local pveTarget = AimbotPvETab:Section({ Title = "Targeting", Opened = true })

pveTarget:Dropdown({
    Title = "Target part",
    Desc = "Where the crosshair lands.",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Value = "Head",
    AllowNone = false,
    Callback = function(option) Aim.pve.part = option end,
})

pveTarget:Space({ Columns = 1 })

pveTarget:Slider({
    Title = "Field of view",
    Desc = "Screen radius in pixels.",
    Step = 5,
    Value = { Min = 20, Max = 600, Default = 130 },
    Callback = function(v)
        Aim.pve.fov = v
        if FovRing then FovRing.Size = UDim2.fromOffset(v * 2, v * 2) end
    end,
})

pveTarget:Space({ Columns = 1 })

pveTarget:Slider({
    Title = "Smoothness",
    Desc = "Higher glides slower. Lower snaps harder.",
    Step = 0.02,
    Value = { Min = 0.02, Max = 1, Default = 0.22 },
    Callback = function(v) Aim.pve.smooth = v end,
})

pveTarget:Space({ Columns = 1 })

pveTarget:Slider({
    Title = "Max distance",
    Desc = "Studs.",
    Step = 25,
    Value = { Min = 50, Max = 2000, Default = 700 },
    Callback = function(v) Aim.pve.dist = v end,
})

pveTarget:Space({ Columns = 1 })

pveTarget:Slider({
    Title = "Deadzone",
    Desc = "Skips targets closer to the centre than this.",
    Step = 2,
    Value = { Min = 0, Max = 60, Default = 0 },
    Callback = function(v) Aim.pve.deadzone = v end,
})

local pveChecks = AimbotPvETab:Section({ Title = "Checks", Opened = true })

pveChecks:Toggle({
    Title = "Wall check",
    Desc = "Skips AI standing behind something solid.",
    Icon = "eye-off",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Aim.pve.wall = v end,
})

pveChecks:Space({ Columns = 1 })

pveChecks:Toggle({
    Title = "Show FOV ring",
    Desc = "Draws the detection radius on screen.",
    Icon = "circle-dashed",
    Type = "Checkbox",
    Value = true,
    Callback = function(v)
        Aim.pve.showFov = v
        if FovRing then FovRing.Visible = Aim.pve.on and v end
    end,
})

pveChecks:Space({ Columns = 2 })

pveChecks:Button({
    Title = "Reset PvE aimbot",
    Desc = "Back to factory defaults.",
    Icon = "rotate-ccw",
    Justify = "Between",
    Callback = function()
        Aim.pve.on = false
        Aim.pve.mode = "Toggle"
        Aim.pve.part = "Head"
        Aim.pve.fov = 130
        Aim.pve.smooth = 0.22
        Aim.pve.dist = 700
        Aim.pve.wall = true
        Aim.pve.deadzone = 0
        if FovRing then FovRing.Visible = false end
        notify({ Title = "PvE aimbot reset", Icon = "solar:refresh-bold" })
    end,
})

-- // hitbox pve
local HitboxPvETab = Window:Tab({ Title = "Hitbox Expander", Icon = "box" })

HitboxPvE = { on = false, size = 4, transparency = 0.5 }

local pveHitboxMain = HitboxPvETab:Section({ Title = "Expander", Opened = true })

pveHitboxMain:Toggle({
    Title = "Enable",
    Desc = "Grows the AI head so shots land on it. Head keeps its shape, just bigger.",
    Icon = "box",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        HitboxPvE.on = v
        if v then
            for _, entry in ipairs(collectPvE()) do
                applyHitbox(entry.model, HitboxPvE.size, HitboxPvE.transparency)
            end
        else
            for model in pairs(Hitboxes) do
                if isAI(model) then removeHitbox(model) end
            end
        end
        notify({
            Title = v and "PvE hitbox on" or "PvE hitbox off",
            Icon = "solar:box-bold",
        })
    end,
})

pveHitboxMain:Space({ Columns = 1 })

pveHitboxMain:Slider({
    Title = "Head size",
    Desc = "Studs. The head grows in every direction from this value.",
    Step = 0.5,
    Value = { Min = 2, Max = 24, Default = 4 },
    Callback = function(v)
        HitboxPvE.size = v
        for model, entry in pairs(Hitboxes) do
            if isAI(model) then
                pcall(function()
                    entry.head.Size = Vector3.new(v, v, v)
                end)
            end
        end
    end,
})

pveHitboxMain:Space({ Columns = 1 })

pveHitboxMain:Slider({
    Title = "Transparency",
    Desc = "0 is fully visible, 1 is invisible. If a value does not register, try 0.5 again.",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        HitboxPvE.transparency = v
        for model, entry in pairs(Hitboxes) do
            if isAI(model) then
                pcall(function() entry.head.Transparency = v end)
            end
        end
    end,
})

-- // local combat
local LocalCombatTab = Window:Tab({ Title = "Local Combat", Icon = "laptop" })

local automationSection = LocalCombatTab:Section({ Title = "Automation", Opened = true })

automationSection:Paragraph({
    Title = "These are the game's own settings",
    Desc = "Eclipse just flips the same switches the in game menu uses, so they behave exactly like they normally would.",
})

automationSection:Space({ Columns = 1 })

local autoBashToggle = automationSection:Toggle({
    Title = "Auto bash",
    Desc = "Swings automatically at anything close in front of you.",
    Icon = "swords",
    Type = "Checkbox",
    Value = csGet({ "Mobile" }, "AutoBashEnabled", false),
    Callback = function(v) csSet({ "Mobile" }, "AutoBashEnabled", v) end,
})
bindSync(autoBashToggle, { "Mobile" }, "AutoBashEnabled", false)

automationSection:Space({ Columns = 1 })

local autoFireToggle = automationSection:Toggle({
    Title = "Auto fire on target",
    Desc = "Fires when something hostile sits under the centre reticle.",
    Icon = "flame",
    Type = "Checkbox",
    Value = csGet({ "Mobile" }, "AutoFireOnTargetEnabled", false),
    Callback = function(v) csSet({ "Mobile" }, "AutoFireOnTargetEnabled", v) end,
})
bindSync(autoFireToggle, { "Mobile" }, "AutoFireOnTargetEnabled", false)

automationSection:Space({ Columns = 2 })

local aimAssistToggle = automationSection:Toggle({
    Title = "Aim assist",
    Desc = "Nudges the reticle toward whatever you are already looking at.",
    Icon = "magnet",
    Type = "Checkbox",
    Value = csGet({ "Mobile" }, "AimAssistEnabled", false),
    Callback = function(v) csSet({ "Mobile" }, "AimAssistEnabled", v) end,
})
bindSync(aimAssistToggle, { "Mobile" }, "AimAssistEnabled", false)

local autoAimToggle = automationSection:Toggle({
    Title = "Auto aim on fire",
    Desc = "Enters ADS the moment you press fire.",
    Icon = "focus",
    Type = "Checkbox",
    Value = csGet({ "Mobile" }, "AutoAimOnFireEnabled", false),
    Callback = function(v) csSet({ "Mobile" }, "AutoAimOnFireEnabled", v) end,
})
bindSync(autoAimToggle, { "Mobile" }, "AutoAimOnFireEnabled", false)

local assistSection = LocalCombatTab:Section({ Title = "Assist Tuning", Opened = false })

assistSection:Slider({
    Title = "Assist strength",
    Desc = "How hard shots bend toward the target.",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = csGet({ "Mobile" }, "AimAssistStrength", 100) },
    Callback = function(v) csSet({ "Mobile" }, "AimAssistStrength", v) end,
})

assistSection:Space({ Columns = 1 })

assistSection:Slider({
    Title = "Assist window",
    Desc = "How far off centre a target can be before assist kicks in, in degrees.",
    Step = 1,
    Value = { Min = 2, Max = 15, Default = csGet({ "Mobile" }, "AimAssistFOVDegrees", 8) },
    Callback = function(v) csSet({ "Mobile" }, "AimAssistFOVDegrees", v) end,
})

assistSection:Space({ Columns = 1 })

assistSection:Toggle({
    Title = "Toggle aim",
    Desc = "Aim stays on after a tap instead of while holding.",
    Icon = "mouse-pointer-click",
    Type = "Checkbox",
    Value = csGet({ "Game" }, "ToggleAimEnabled", false),
    Callback = function(v) csSet({ "Game" }, "ToggleAimEnabled", v) end,
})

local feedbackSection = LocalCombatTab:Section({ Title = "Camera & Feedback", Opened = false })

feedbackSection:Toggle({
    Title = "Camera shake",
    Desc = "The little kick you get from firing and impacts.",
    Icon = "vibrate",
    Type = "Checkbox",
    Value = csGet({ "Game" }, "CameraShakeEnabled", true),
    Callback = function(v) csSet({ "Game" }, "CameraShakeEnabled", v) end,
})

feedbackSection:Space({ Columns = 1 })

feedbackSection:Toggle({
    Title = "ADS zoom",
    Desc = "FOV narrows while you aim.",
    Icon = "zoom-in",
    Type = "Checkbox",
    Value = csGet({ "Game" }, "ADSZoomingEnabled", true),
    Callback = function(v) csSet({ "Game" }, "ADSZoomingEnabled", v) end,
})

feedbackSection:Space({ Columns = 2 })

feedbackSection:Toggle({
    Title = "Execution camera",
    Desc = "The cinematic angle on executions.",
    Icon = "video",
    Type = "Checkbox",
    Value = csGet({ "Game" }, "RenderNewExecutionCamera", true),
    Callback = function(v) csSet({ "Game" }, "RenderNewExecutionCamera", v) end,
})

local audioSection = LocalCombatTab:Section({ Title = "Audio", Opened = false })

audioSection:Slider({
    Title = "Gunshots",
    Desc = "Volume for weapon fire.",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = csGet({ "Sounds" }, "GunShots", 100) },
    Callback = function(v) csSet({ "Sounds" }, "GunShots", v) end,
})

audioSection:Space({ Columns = 1 })

audioSection:Slider({
    Title = "Footsteps",
    Desc = "Volume for movement.",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = csGet({ "Sounds" }, "Footsteps", 100) },
    Callback = function(v) csSet({ "Sounds" }, "Footsteps", v) end,
})

audioSection:Space({ Columns = 1 })

audioSection:Slider({
    Title = "Voice lines",
    Desc = "Volume for character barks.",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = csGet({ "Sounds" }, "Voicelines", 100) },
    Callback = function(v) csSet({ "Sounds" }, "Voicelines", v) end,
})

audioSection:Space({ Columns = 1 })

audioSection:Slider({
    Title = "Music",
    Desc = "Volume for the soundtrack.",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = csGet({ "Sounds" }, "Music", 100) },
    Callback = function(v) csSet({ "Sounds" }, "Music", v) end,
})

audioSection:Space({ Columns = 1 })

audioSection:Toggle({
    Title = "Tinnitus ringing",
    Desc = "The ringing noise after explosions.",
    Icon = "ear",
    Type = "Checkbox",
    Value = csGet({}, "TinnitusEnabled", true),
    Callback = function(v) csSet({}, "TinnitusEnabled", v) end,
})

audioSection:Space({ Columns = 1 })

audioSection:Toggle({
    Title = "Low health theme",
    Desc = "Music that creeps in when you are nearly down.",
    Icon = "heart-pulse",
    Type = "Checkbox",
    Value = csGet({ "Sounds" }, "LowHPMusicEnabled", true),
    Callback = function(v) csSet({ "Sounds" }, "LowHPMusicEnabled", v) end,
})

local graphicsSection = LocalCombatTab:Section({ Title = "Graphics", Opened = false })

graphicsSection:Toggle({
    Title = "Shadows",
    Desc = "Turning this off is the single biggest win on a weak machine.",
    Icon = "cloud-sun",
    Type = "Checkbox",
    Value = csGet({ "Graphics" }, "CastShadowsEnabled", true),
    Callback = function(v) csSet({ "Graphics" }, "CastShadowsEnabled", v) end,
})

graphicsSection:Space({ Columns = 1 })

graphicsSection:Toggle({
    Title = "Textures",
    Desc = "Surface detail on world geometry.",
    Icon = "image",
    Type = "Checkbox",
    Value = csGet({ "Graphics" }, "TexturesEnabled", true),
    Callback = function(v) csSet({ "Graphics" }, "TexturesEnabled", v) end,
})

graphicsSection:Space({ Columns = 2 })

graphicsSection:Toggle({
    Title = "Materials",
    Desc = "PBR materials. Off makes everything flat and cheap.",
    Icon = "layers",
    Type = "Checkbox",
    Value = csGet({ "Graphics" }, "MaterialsEnabled", true),
    Callback = function(v) csSet({ "Graphics" }, "MaterialsEnabled", v) end,
})

graphicsSection:Toggle({
    Title = "VFX",
    Desc = "Particles, trails and beams.",
    Icon = "sparkles",
    Type = "Checkbox",
    Value = csGet({ "Graphics" }, "VFXEnabled", true),
    Callback = function(v) csSet({ "Graphics" }, "VFXEnabled", v) end,
})

graphicsSection:Space({ Columns = 1 })

graphicsSection:Toggle({
    Title = "Prop clutter",
    Desc = "Hides decorative props. Collision stays, so nothing breaks.",
    Icon = "boxes",
    Type = "Checkbox",
    Value = csGet({ "Graphics" }, "PropsEnabled", true),
    Callback = function(v) csSet({ "Graphics" }, "PropsEnabled", v) end,
})

graphicsSection:Space({ Columns = 1 })

graphicsSection:Slider({
    Title = "Colour correction",
    Desc = "How strong the tint over the world is.",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = csGet({ "Graphics" }, "ColorCorrectionIntensity", 100) },
    Callback = function(v) csSet({ "Graphics" }, "ColorCorrectionIntensity", v) end,
})

-- =====================================================================
-- VISUALS (PvE)
-- =====================================================================
Window:Section({ Title = "Visuals (PvE)", Opened = true })

local EspPvETab = Window:Tab({ Title = "ESP", Icon = "eye" })

local pveEspMain = EspPvETab:Section({ Title = "AI Tags", Opened = true })

pveEspMain:Toggle({
    Title = "Enable",
    Desc = "Highlights every AI in the map with a tag above their head.",
    Icon = "scan",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Esp.pve.on = v
        ensureEspGui()
        refreshEspKind("pve")
        notify({
            Title = v and "PvE ESP on" or "PvE ESP off",
            Icon = "solar:eye-bold",
        })
    end,
})

pveEspMain:Space({ Columns = 2 })

pveEspMain:Toggle({
    Title = "Highlight",
    Desc = "Soft coloured outline you can see through walls.",
    Icon = "square",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pve.highlight = v end,
})

pveEspMain:Toggle({
    Title = "Name",
    Desc = "Shows the AI name.",
    Icon = "user",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pve.name = v end,
})

pveEspMain:Space({ Columns = 2 })

pveEspMain:Toggle({
    Title = "Health",
    Desc = "Live health above the tag.",
    Icon = "heart",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pve.hp = v end,
})

pveEspMain:Toggle({
    Title = "Distance",
    Desc = "How far away they are, in metres.",
    Icon = "ruler",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pve.dist = v end,
})

local pveEspStyle = EspPvETab:Section({ Title = "Style", Opened = false })

pveEspStyle:Slider({
    Title = "Render distance",
    Desc = "Tags disappear past this range.",
    Step = 25,
    Value = { Min = 50, Max = 1500, Default = 250 },
    Callback = function(v) Esp.pve.distMax = v end,
})

pveEspStyle:Space({ Columns = 1 })

pveEspStyle:Colorpicker({
    Title = "Tag colour",
    Desc = "Used for the highlight and the name.",
    Default = Color3.fromRGB(255, 72, 72),
    Transparency = 0,
    Callback = function(c) Esp.pve.color = c end,
})

-- =====================================================================
-- COMBAT (PvP)
-- =====================================================================
Window:Section({ Title = "Combat (PvP)", Opened = true })

local AimbotPvPTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })

local pvpMain = AimbotPvPTab:Section({ Title = "Activation", Opened = true })

pvpMain:Toggle({
    Title = "Enable",
    Desc = "Tracks the closest player in your field of view.",
    Icon = "crosshair",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Aim.pvp.on = v
        Aim.pvp.toggled = false
        notify({
            Title = v and "PvP aimbot on" or "PvP aimbot off",
            Icon = "solar:crosshair-bold",
        })
    end,
})

pvpMain:Space({ Columns = 1 })

pvpMain:Dropdown({
    Title = "Activation mode",
    Desc = "Same idea as the PvE tab.",
    Values = { "Always", "Hold", "Toggle" },
    Value = "Hold",
    AllowNone = false,
    Callback = function(option)
        Aim.pvp.mode = option
        Aim.pvp.toggled = false
    end,
})

pvpMain:Space({ Columns = 1 })

pvpMain:Keybind({
    Title = "Activation key",
    Desc = "Default is Q so it stays clear of the PvE key.",
    Value = "Q",
    Callback = function(v)
        if keyOk(v) then Aim.pvp.key = v end
    end,
})

local pvpTarget = AimbotPvPTab:Section({ Title = "Targeting", Opened = true })

pvpTarget:Dropdown({
    Title = "Target part",
    Desc = "Where the crosshair lands.",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Value = "Head",
    AllowNone = false,
    Callback = function(option) Aim.pvp.part = option end,
})

pvpTarget:Space({ Columns = 1 })

pvpTarget:Slider({
    Title = "Field of view",
    Desc = "Screen radius in pixels.",
    Step = 5,
    Value = { Min = 20, Max = 600, Default = 110 },
    Callback = function(v) Aim.pvp.fov = v end,
})

pvpTarget:Space({ Columns = 1 })

pvpTarget:Slider({
    Title = "Smoothness",
    Desc = "Higher glides slower. Lower snaps harder.",
    Step = 0.02,
    Value = { Min = 0.02, Max = 1, Default = 0.28 },
    Callback = function(v) Aim.pvp.smooth = v end,
})

pvpTarget:Space({ Columns = 1 })

pvpTarget:Slider({
    Title = "Max distance",
    Desc = "Studs.",
    Step = 25,
    Value = { Min = 50, Max = 2000, Default = 450 },
    Callback = function(v) Aim.pvp.dist = v end,
})

pvpTarget:Space({ Columns = 1 })

pvpTarget:Slider({
    Title = "Deadzone",
    Desc = "Ignores targets closer to the centre than this.",
    Step = 2,
    Value = { Min = 0, Max = 60, Default = 0 },
    Callback = function(v) Aim.pvp.deadzone = v end,
})

local pvpChecks = AimbotPvPTab:Section({ Title = "Checks", Opened = true })

pvpChecks:Toggle({
    Title = "Wall check",
    Desc = "Skips players standing behind something solid.",
    Icon = "eye-off",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Aim.pvp.wall = v end,
})

pvpChecks:Space({ Columns = 1 })

pvpChecks:Toggle({
    Title = "Skip teammates",
    Desc = "Never locks onto someone on your own team.",
    Icon = "users",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Aim.pvp.team = v end,
})

pvpChecks:Space({ Columns = 2 })

pvpChecks:Toggle({
    Title = "Skip friends",
    Desc = "Your Roblox friends are ignored.",
    Icon = "user-check",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Aim.pvp.friends = v end,
})

pvpChecks:Button({
    Title = "Reset PvP aimbot",
    Desc = "Back to factory defaults.",
    Icon = "rotate-ccw",
    Justify = "Between",
    Callback = function()
        Aim.pvp.on = false
        Aim.pvp.mode = "Hold"
        Aim.pvp.part = "Head"
        Aim.pvp.fov = 110
        Aim.pvp.smooth = 0.28
        Aim.pvp.dist = 450
        Aim.pvp.wall = true
        Aim.pvp.team = true
        Aim.pvp.friends = true
        notify({ Title = "PvP aimbot reset", Icon = "solar:refresh-bold" })
    end,
})

-- // hitbox pvp
local HitboxPvPTab = Window:Tab({ Title = "Hitbox Expander", Icon = "package-open" })

HitboxPvP = { on = false, size = 4, transparency = 0.5, team = true }

local pvpHitboxMain = HitboxPvPTab:Section({ Title = "Expander", Opened = true })

pvpHitboxMain:Toggle({
    Title = "Enable",
    Desc = "Same trick as the PvE tab, but applied to players.",
    Icon = "package-open",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        HitboxPvP.on = v
        if v then
            for _, entry in ipairs(collectPvP(HitboxPvP.team, false)) do
                applyHitbox(entry.model, HitboxPvP.size, HitboxPvP.transparency)
            end
        else
            for model in pairs(Hitboxes) do
                if not isAI(model) then removeHitbox(model) end
            end
        end
        notify({
            Title = v and "PvP hitbox on" or "PvP hitbox off",
            Icon = "solar:package-bold",
        })
    end,
})

pvpHitboxMain:Space({ Columns = 1 })

pvpHitboxMain:Slider({
    Title = "Head size",
    Desc = "Studs.",
    Step = 0.5,
    Value = { Min = 2, Max = 24, Default = 4 },
    Callback = function(v)
        HitboxPvP.size = v
        for model, entry in pairs(Hitboxes) do
            if not isAI(model) then
                pcall(function() entry.head.Size = Vector3.new(v, v, v) end)
            end
        end
    end,
})

pvpHitboxMain:Space({ Columns = 1 })

pvpHitboxMain:Slider({
    Title = "Transparency",
    Desc = "0 is visible, 1 is invisible.",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        HitboxPvP.transparency = v
        for model, entry in pairs(Hitboxes) do
            if not isAI(model) then
                pcall(function() entry.head.Transparency = v end)
            end
        end
    end,
})

pvpHitboxMain:Space({ Columns = 1 })

pvpHitboxMain:Toggle({
    Title = "Skip teammates",
    Desc = "Leaves anyone on your team alone.",
    Icon = "users",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) HitboxPvP.team = v end,
})

-- =====================================================================
-- VISUALS (PvP)
-- =====================================================================
Window:Section({ Title = "Visuals (PvP)", Opened = true })

local EspPvPTab = Window:Tab({ Title = "ESP", Icon = "eye-dashed" })

local pvpEspMain = EspPvPTab:Section({ Title = "Player Tags", Opened = true })

pvpEspMain:Toggle({
    Title = "Enable",
    Desc = "Tags every other player in the server.",
    Icon = "scan",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        Esp.pvp.on = v
        ensureEspGui()
        refreshEspKind("pvp")
        notify({
            Title = v and "PvP ESP on" or "PvP ESP off",
            Icon = "solar:eye-bold",
        })
    end,
})

pvpEspMain:Space({ Columns = 2 })

pvpEspMain:Toggle({
    Title = "Highlight",
    Desc = "Soft outline through walls. Turn off if you notice slowdown.",
    Icon = "square",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pvp.highlight = v end,
})

pvpEspMain:Toggle({
    Title = "Name",
    Desc = "Display name instead of username.",
    Icon = "user",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pvp.name = v end,
})

pvpEspMain:Space({ Columns = 2 })

pvpEspMain:Toggle({
    Title = "Health",
    Desc = "Live health above the tag.",
    Icon = "heart",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pvp.hp = v end,
})

pvpEspMain:Toggle({
    Title = "Distance",
    Desc = "Range in metres.",
    Icon = "ruler",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pvp.dist = v end,
})

pvpEspMain:Space({ Columns = 1 })

pvpEspMain:Toggle({
    Title = "Skip teammates",
    Desc = "Hides anyone on your own team.",
    Icon = "users",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pvp.team = v end,
})

pvpEspMain:Space({ Columns = 1 })

pvpEspMain:Toggle({
    Title = "Skip friends",
    Desc = "Hides your Roblox friends.",
    Icon = "user-check",
    Type = "Checkbox",
    Value = true,
    Callback = function(v) Esp.pvp.friends = v end,
})

local pvpEspStyle = EspPvPTab:Section({ Title = "Style", Opened = false })

pvpEspStyle:Slider({
    Title = "Render distance",
    Desc = "Tags disappear past this range.",
    Step = 25,
    Value = { Min = 50, Max = 2000, Default = 500 },
    Callback = function(v) Esp.pvp.distMax = v end,
})

pvpEspStyle:Space({ Columns = 1 })

pvpEspStyle:Colorpicker({
    Title = "Tag colour",
    Desc = "Used for the highlight and the name.",
    Default = Color3.fromRGB(80, 200, 255),
    Transparency = 0,
    Callback = function(c) Esp.pvp.color = c end,
})

-- =====================================================================
-- UTILITY
-- =====================================================================
Window:Section({ Title = "Utility", Opened = true })

local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })

local worldSection = WorldTab:Section({ Title = "Environment", Opened = true })

worldSection:Input({
    Title = "Time of day",
    Desc = "Anything from 0 to 24. Decimals work.",
    Value = "14",
    InputIcon = "clock",
    Placeholder = "14",
    Callback = function(text)
        local n = tonumber(text)
        if not n then return end
        World.time = math.clamp(n, 0, 24)
        if World.timeOn then
            pcall(function() Lighting.ClockTime = World.time end)
        end
    end,
})

worldSection:Space({ Columns = 1 })

worldSection:Toggle({
    Title = "Lock time",
    Desc = "Holds the clock at the value above instead of letting it drift.",
    Icon = "clock",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        World.timeOn = v
        if v then
            pcall(function() Lighting.ClockTime = World.time end)
        end
    end,
})

worldSection:Space({ Columns = 1 })

worldSection:Toggle({
    Title = "Clear fog",
    Desc = "Pushes the fog range out so you can see across the map.",
    Icon = "cloud-off",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        World.fogOff = v
        if v then
            World.fogPrev = { Lighting.FogStart, Lighting.FogEnd }
            pcall(function()
                Lighting.FogStart = 1e6
                Lighting.FogEnd = 1e6
            end)
        elseif World.fogPrev then
            pcall(function()
                Lighting.FogStart = World.fogPrev[1]
                Lighting.FogEnd = World.fogPrev[2]
            end)
        end
    end,
})

local minimapSection = WorldTab:Section({ Title = "Minimap", Opened = true })

minimapSection:Toggle({
    Title = "Minimap",
    Desc = "The radar in the corner.",
    Icon = "map",
    Type = "Checkbox",
    Value = csGet({ "Game" }, "MinimapEnabled", true),
    Callback = function(v) csSet({ "Game" }, "MinimapEnabled", v) end,
})

minimapSection:Space({ Columns = 1 })

minimapSection:Toggle({
    Title = "Lock rotation",
    Desc = "Keeps north pointing up.",
    Icon = "compass",
    Type = "Checkbox",
    Value = csGet({ "Game" }, "MinimapRotationLocked", false),
    Callback = function(v) csSet({ "Game" }, "MinimapRotationLocked", v) end,
})

minimapSection:Space({ Columns = 2 })

minimapSection:Slider({
    Title = "Radar size",
    Desc = "Scales the minimap only. Zoom and detection are unaffected.",
    Step = 5,
    Value = { Min = 60, Max = 120, Default = csGet({ "Game" }, "MinimapScalePercent", 100) },
    Callback = function(v) csSet({ "Game" }, "MinimapScalePercent", v) end,
})

-- =====================================================================
-- RESET QUEUE
-- =====================================================================
ResetQueue = {
    function()
        Aim.pve.on = false
        Aim.pvp.on = false
        Aim.pve.toggled = false
        Aim.pvp.toggled = false
        if FovRing then FovRing.Visible = false end
    end,
    function()
        HitboxPvE.on = false
        HitboxPvP.on = false
        clearAllHitboxes()
    end,
    function()
        Esp.pve.on = false
        Esp.pvp.on = false
        clearEspTable(EspPvEObjects)
        clearEspTable(EspPvPObjects)
    end,
    function()
        Nvg.on = false
    end,
    function()
        Stamina.on = false
        Stamina.module = nil
    end,
    function()
        Move.noclip = false
        Move.speedOn = false
        Move.jumpOn = false
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    pcall(function() d.CanCollide = true end)
                end
            end
        end
    end,
    function()
        World.timeOn = false
        World.fogOff = false
        World.ambientOn = false
        if World.fogPrev then
            pcall(function()
                Lighting.FogStart = World.fogPrev[1]
                Lighting.FogEnd = World.fogPrev[2]
            end)
        end
    end,
}

-- =====================================================================
-- CLEANUP
-- =====================================================================
local function cleanup()
    for _, c in ipairs(Conns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Conns)

    clearAllHitboxes()
    clearEspTable(EspPvEObjects)
    clearEspTable(EspPvPObjects)

    if FovGui then FovGui:Destroy() FovGui = nil end
    if EspGui then EspGui:Destroy() EspGui = nil end
end

script.Destroying:Connect(cleanup)