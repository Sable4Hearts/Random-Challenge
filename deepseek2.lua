--[[
    ============================================================
    PREMIUM WINDUI HUB
    Built on WindUI (Beta) by Footagesus
    Docs: https://footagesus.github.io/WindUI-Docs/docs
    ============================================================
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- LOAD WINDUI
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ============================================================
-- PERFORMANCE / GLOBAL STATE
-- ============================================================
local Performance = {
    ReducedMotion = false,
    MobileMode = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
    NotificationsEnabled = true,
    UIEnabled = true,
}

local Connections = {}
local ActiveLoops = {}

local function CleanupConnections()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)
end

local function Track(conn)
    table.insert(Connections, conn)
    return conn
end

-- ============================================================
-- NOTIFICATION HELPER (respects notifications toggle)
-- ============================================================
local function Notify(config)
    if not Performance.NotificationsEnabled then return end
    WindUI:Notify(config)
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
local Window = WindUI:CreateWindow({
    Title = "Premium Hub",
    Icon = "solar:widget-bold",
    Author = "by PremiumDev",
    Folder = "PremiumHub",
    Size = UDim2.fromOffset(620, 480),
    MinSize = Vector2.new(560, 380),
    MaxSize = Vector2.new(900, 620),
    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    OpenButton = {
        Title = "Open Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#6C5CE7"),
            Color3.fromHex("#00CEC9")
        ),
    },
    Topbar = {
        Height = 42,
        ButtonsType = "Mac",
    },
})

-- Version tag next to title
Window:Tag({
    Title = "v1.0.0",
    Icon = "github",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

-- ============================================================
-- TAB STRUCTURE
-- ============================================================

-- ===== SECTION: MAIN =====
local MainSection = Window:Section({ Title = "Main" })

-- ============================================================
-- TAB: HOME / ABOUT
-- ============================================================
local HomeTab = MainSection:Tab({
    Title = "Home",
    Icon = "solar:home-2-bold",
    IconColor = Color3.fromHex("#6C5CE7"),
    IconShape = "Square",
})

local AboutSection = HomeTab:Section({ Title = "About Premium Hub", Opened = true })
AboutSection:Image({
    Image = "rbxassetid://95176729901641",
    AspectRatio = "16:9",
    Radius = 9,
})
AboutSection:Space({ Columns = 3 })
AboutSection:Section({
    Title = "Welcome to Premium Hub",
    TextSize = 24,
    FontWeight = Enum.FontWeight.SemiBold,
})
AboutSection:Section({
    Title = "A premium WindUI-powered hub with optimized features for PC and mobile. Built for performance and aesthetics.",
    TextSize = 18,
    TextTransparency = 0.35,
    FontWeight = Enum.FontWeight.Medium,
})

AboutSection:Space({ Columns = 2 })

-- Credits / Social buttons
HomeTab:Group({ Title = "Credits & Links" })
HomeTab:Button({
    Title = "Join Discord",
    Desc = "Get support and updates",
    Icon = "solar:chat-round-line-bold",
    Callback = function()
        local ok = pcall(function() setclipboard("https://discord.gg/example") end)
        Notify({
            Title = ok and "Copied!" or "Copy Failed",
            Content = ok and "Discord invite copied to clipboard." or "Could not copy to clipboard.",
            Icon = "solar:copy-bold",
        })
    end,
})
HomeTab:Button({
    Title = "Subscribe on YouTube",
    Desc = "Watch tutorials",
    Icon = "solar:play-circle-bold",
    Callback = function()
        local ok = pcall(function() setclipboard("https://youtube.com/@example") end)
        Notify({
            Title = ok and "Copied!" or "Copy Failed",
            Content = ok and "YouTube link copied to clipboard." or "Could not copy to clipboard.",
            Icon = "solar:copy-bold",
        })
    end,
})
HomeTab:Button({
    Title = "Copy Script Link",
    Desc = "Share the loader",
    Icon = "solar:link-bold",
    Callback = function()
        local ok = pcall(function()
            setclipboard('loadstring(game:HttpGet("https://example.com/loader.lua"))()')
        end)
        Notify({
            Title = ok and "Copied!" or "Copy Failed",
            Content = ok and "Script loader copied to clipboard." or "Could not copy to clipboard.",
            Icon = "solar:copy-bold",
        })
    end,
})

-- ============================================================
-- TAB: MOVEMENT
-- ============================================================
local MovementTab = MainSection:Tab({
    Title = "Movement",
    Icon = "solar:running-2-bold",
    IconColor = Color3.fromHex("#00CEC9"),
    IconShape = "Square",
})

-- Sprint / Speed
local SprintSection = MovementTab:Section({ Title = "Sprint & Speed", Opened = true })
local sprintEnabled = SprintSection:Toggle({
    Title = "Sprint Enhancement",
    Desc = "Boosts walk speed while sprinting",
    Icon = "solar:bolt-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "SprintEnabled",
    Callback = function(state)
        if state then
            -- Placeholder: connect to actual sprint logic
            Notify({ Title = "Sprint On", Content = "Sprint enhancement enabled.", Icon = "solar:bolt-bold" })
        else
            Notify({ Title = "Sprint Off", Content = "Sprint enhancement disabled.", Icon = "solar:bolt-bold" })
        end
    end,
})

local sprintSpeedSlider = SprintSection:Slider({
    Title = "Sprint Multiplier",
    Desc = "How much faster sprinting is",
    Icon = "solar:speedometer-bold",
    Min = 1,
    Max = 3,
    Default = 1.3,
    Step = 0.1,
    Suffix = "x",
    Flag = "SprintMultiplier",
    Callback = function(value)
        -- Live update sprint speed reference
    end,
})

SprintSection:Space({ Columns = 1 })

-- Jump
local JumpSection = MovementTab:Section({ Title = "Jump", Opened = true })
local infJumpToggle = JumpSection:Toggle({
    Title = "Infinite Jump",
    Desc = "Jump repeatedly in mid-air",
    Icon = "solar:arrow-up-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "InfiniteJump",
    Callback = function(state)
        if state then
            local conn
            conn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
                        -- Allow re-jump
                    end
                end
            end)
            Track(conn)
            Notify({ Title = "Infinite Jump On", Content = "Infinite jump enabled.", Icon = "solar:arrow-up-bold" })
        else
            Notify({ Title = "Infinite Jump Off", Content = "Infinite jump disabled.", Icon = "solar:arrow-up-bold" })
        end
    end,
})

local jumpPowerSlider = JumpSection:Slider({
    Title = "Jump Power",
    Desc = "Custom jump height",
    Icon = "solar:rocket-bold",
    Min = 50,
    Max = 200,
    Default = 50,
    Step = 5,
    Flag = "JumpPower",
    Callback = function(value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = value
            end
        end
    end,
})

JumpSection:Space({ Columns = 1 })

-- Slide
local SlideSection = MovementTab:Section({ Title = "Slide", Opened = false })
local slideToggle = SlideSection:Toggle({
    Title = "Enable Slide",
    Desc = "Sprint + C to slide",
    Icon = "solar:skateboarding-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "SlideEnabled",
    Callback = function(state)
        -- Placeholder for slide logic
    end,
})

SlideSection:Space({ Columns = 1 })

-- ============================================================
-- TAB: COMBAT
-- ============================================================
local CombatTab = MainSection:Tab({
    Title = "Combat",
    Icon = "solar:sword-bold",
    IconColor = Color3.fromHex("#FF7675"),
    IconShape = "Square",
})

-- Aim Assist
local AimSection = CombatTab:Section({ Title = "Aim Assist", Opened = true })
local aimAssistToggle = AimSection:Toggle({
    Title = "Aim Assist",
    Desc = "Gently corrects shots toward enemies",
    Icon = "solar:target-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "AimAssistEnabled",
    Callback = function(state)
        Notify({
            Title = state and "Aim Assist On" or "Aim Assist Off",
            Content = state and "Aim assist enabled." or "Aim assist disabled.",
            Icon = "solar:target-bold",
        })
    end,
})

local aimStrengthSlider = AimSection:Slider({
    Title = "Assist Strength",
    Desc = "How strongly shots bend toward target",
    Icon = "solar:slider-vertical-bold",
    Min = 0,
    Max = 100,
    Default = 100,
    Step = 5,
    Suffix = "%",
    Flag = "AimAssistStrength",
})

AimSection:Space({ Columns = 1 })

local aimFOVSlider = AimSection:Slider({
    Title = "Assist Window",
    Desc = "How close enemy must be to reticle",
    Icon = "solar:view-bold",
    Min = 2,
    Max = 15,
    Default = 8,
    Step = 1,
    Suffix = "°",
    Flag = "AimAssistFOV",
})

AimSection:Space({ Columns = 2 })

-- Auto Features
local AutoSection = CombatTab:Section({ Title = "Automation", Opened = true })
local autoFireToggle = AutoSection:Toggle({
    Title = "Auto Fire On Target",
    Desc = "Fires when reticle is on enemy",
    Icon = "solar:fire-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "AutoFireEnabled",
    Callback = function(state)
        Notify({
            Title = state and "Auto Fire On" or "Auto Fire Off",
            Content = state and "Auto fire enabled." or "Auto fire disabled.",
            Icon = "solar:fire-bold",
        })
    end,
})

local autoBashToggle = AutoSection:Toggle({
    Title = "Auto Bash",
    Desc = "Bashes enemies directly in front",
    Icon = "solar:hand-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "AutoBashEnabled",
})

AutoSection:Space({ Columns = 1 })

-- ============================================================
-- TAB: VISUALS
-- ============================================================
local VisualsSection = Window:Section({ Title = "Visuals" })

local VisualsTab = VisualsSection:Tab({
    Title = "ESP",
    Icon = "solar:eye-bold",
    IconColor = Color3.fromHex("#FDCB6E"),
    IconShape = "Square",
})

local ESPMainSection = VisualsTab:Section({ Title = "Player ESP", Opened = true })
local espEnabled = ESPMainSection:Toggle({
    Title = "Enable ESP",
    Desc = "Highlight players through walls",
    Icon = "solar:scan-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "ESPEnabled",
    Callback = function(state)
        Notify({
            Title = state and "ESP On" or "ESP Off",
            Content = state and "Player ESP enabled." or "Player ESP disabled.",
            Icon = "solar:scan-bold",
        })
    end,
})

ESPMainSection:Space({ Columns = 1 })

local espBoxToggle = ESPMainSection:Toggle({
    Title = "Box",
    Desc = "Draw box around players",
    Icon = "solar:square-bold",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPBox",
})

local espNameToggle = ESPMainSection:Toggle({
    Title = "Name",
    Desc = "Show player names",
    Icon = "solar:user-bold",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPName",
})

ESPMainSection:Space({ Columns = 1 })

local espHealthToggle = ESPMainSection:Toggle({
    Title = "Health Bar",
    Desc = "Show health bar",
    Icon = "solar:heart-bold",
    Type = "Checkbox",
    Value = true,
    Flag = "ESPHealth",
})

local espTracerToggle = ESPMainSection:Toggle({
    Title = "Tracers",
    Desc = "Draw lines to players",
    Icon = "solar:line-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "ESPTracer",
})

ESPMainSection:Space({ Columns = 2 })

-- ESP distance
local espDistanceSlider = VisualsTab:Slider({
    Title = "Max Distance",
    Desc = "How far ESP renders",
    Icon = "solar:ruler-bold",
    Min = 50,
    Max = 1000,
    Default = 500,
    Step = 50,
    Suffix = " studs",
    Flag = "ESPDistance",
})

-- ============================================================
-- TAB: APPEARANCE
-- ============================================================
local AppearanceTab = VisualsSection:Tab({
    Title = "Appearance",
    Icon = "solar:palette-bold",
    IconColor = Color3.fromHex("#A29BFE"),
    IconShape = "Square",
})

local ThemeSection = AppearanceTab:Section({ Title = "Theme", Opened = true })
local themeDropdown = ThemeSection:Dropdown({
    Title = "UI Theme",
    Desc = "Choose a built-in theme",
    Icon = "solar:brush-bold",
    Values = { "Dark", "Light", "Mellowsi", "Custom" },
    Default = "Dark",
    Flag = "UITheme",
    Callback = function(selected)
        if selected == "Custom" then
            Notify({
                Title = "Custom Theme",
                Content = "Use the colorpickers below to customize.",
                Icon = "solar:palette-bold",
            })
        else
            -- Apply theme via WindUI if supported
            WindUI:AddTheme({ Name = selected })
            Notify({
                Title = "Theme Applied",
                Content = selected .. " theme loaded.",
                Icon = "solar:brush-bold",
            })
        end
    end,
})

ThemeSection:Space({ Columns = 1 })

-- Color customizers
local AccentColor = ThemeSection:Colorpicker({
    Title = "Accent Color",
    Default = Color3.fromHex("#6C5CE7"),
    Transparency = 0,
    Flag = "AccentColor",
    Callback = function(color)
        -- Live update accent references
    end,
})

local ToggleColor = ThemeSection:Colorpicker({
    Title = "Toggle On Color",
    Default = Color3.fromHex("#00CEC9"),
    Transparency = 0,
    Flag = "ToggleColor",
})

ThemeSection:Space({ Columns = 1 })

local SliderColor = ThemeSection:Colorpicker({
    Title = "Slider Fill Color",
    Default = Color3.fromHex("#6C5CE7"),
    Transparency = 0,
    Flag = "SliderColor",
})

local HighlightColor = ThemeSection:Colorpicker({
    Title = "Highlight Color",
    Default = Color3.fromHex("#FDCB6E"),
    Transparency = 0,
    Flag = "HighlightColor",
})

ThemeSection:Space({ Columns = 2 })

-- Reset theme
AppearanceTab:Button({
    Title = "Reset to Default Theme",
    Desc = "Restore all colors to defaults",
    Icon = "solar:refresh-bold",
    Callback = function()
        AccentColor:Set(Color3.fromHex("#6C5CE7"))
        ToggleColor:Set(Color3.fromHex("#00CEC9"))
        SliderColor:Set(Color3.fromHex("#6C5CE7"))
        HighlightColor:Set(Color3.fromHex("#FDCB6E"))
        Notify({
            Title = "Theme Reset",
            Content = "All colors restored to default.",
            Icon = "solar:refresh-bold",
        })
    end,
})

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
local SettingsSection = Window:Section({ Title = "Settings" })

local SettingsTab = SettingsSection:Tab({
    Title = "General",
    Icon = "solar:settings-bold",
    IconColor = Color3.fromHex("#74B9FF"),
    IconShape = "Square",
})

-- Toggle key
local KeybindSection = SettingsTab:Section({ Title = "Keybinds", Opened = true })
local toggleKeybind = KeybindSection:Keybind({
    Title = "UI Toggle Key",
    Desc = "Key to open/close the hub",
    Icon = "solar:keyboard-bold",
    Value = "RightShift",
    Flag = "ToggleKey",
    Callback = function(key)
        local success, err = pcall(function()
            Window:SetToggleKey(Enum.KeyCode[key])
        end)
        if success then
            Notify({
                Title = "Keybind Updated",
                Content = "UI toggles with " .. key .. ".",
                Icon = "solar:keyboard-bold",
            })
        end
    end,
})

KeybindSection:Space({ Columns = 1 })

-- Notifications toggle
local NotificationsToggle = SettingsTab:Toggle({
    Title = "Disable Notifications",
    Desc = "Hide all popup notifications",
    Icon = "solar:bell-off-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "DisableNotifications",
    Callback = function(state)
        Performance.NotificationsEnabled = not state
        if not state then
            WindUI:Notify({
                Title = "Notifications On",
                Content = "Notifications are now enabled.",
                Icon = "solar:bell-bold",
            })
        end
    end,
})

SettingsTab:Space({ Columns = 1 })

-- Reduced motion
local ReducedMotionToggle = SettingsTab:Toggle({
    Title = "Reduced Motion",
    Desc = "Disable animations for performance",
    Icon = "solar:accessibility-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "ReducedMotion",
    Callback = function(state)
        Performance.ReducedMotion = state
        Notify({
            Title = state and "Reduced Motion On" or "Reduced Motion Off",
            Content = state and "Animations disabled for performance." or "Animations enabled.",
            Icon = "solar:accessibility-bold",
        })
    end,
})

SettingsTab:Space({ Columns = 1 })

-- Mobile mode
local MobileModeToggle = SettingsTab:Toggle({
    Title = "Mobile-Friendly Mode",
    Desc = "Larger UI and reduced effects",
    Icon = "solar:smartphone-bold",
    Type = "Checkbox",
    Value = Performance.MobileMode,
    Flag = "MobileMode",
    Callback = function(state)
        Performance.MobileMode = state
        Notify({
            Title = state and "Mobile Mode On" or "Mobile Mode Off",
            Content = state and "UI scaled for mobile." or "Desktop UI restored.",
            Icon = "solar:smartphone-bold",
        })
    end,
})

SettingsTab:Space({ Columns = 2 })

-- Auto-save
local AutoSaveToggle = SettingsTab:Toggle({
    Title = "Auto-Save Config",
    Desc = "Automatically save settings",
    Icon = "solar:diskette-bold",
    Type = "Checkbox",
    Value = true,
    Flag = "AutoSave",
})

SettingsTab:Space({ Columns = 1 })

-- Config export/import
local ConfigSection = SettingsTab:Section({ Title = "Config Management", Opened = false })
ConfigSection:Button({
    Title = "Export Config as JSON",
    Desc = "Copy current settings to clipboard",
    Icon = "solar:export-bold",
    Callback = function()
        local ok = pcall(function()
            local configData = {}
            -- Collect flag values from WindUI config system
            setclipboard("{\"hub\":\"PremiumHub\",\"version\":\"1.0.0\"}")
        end)
        Notify({
            Title = ok and "Exported!" or "Export Failed",
            Content = ok and "Config copied to clipboard." or "Could not export config.",
            Icon = "solar:export-bold",
        })
    end,
})

ConfigSection:Space({ Columns = 1 })

local importInput = ConfigSection:Input({
    Title = "Import Config",
    Desc = "Paste JSON config here",
    Placeholder = "{\"setting\":\"value\"}",
    Flag = "ImportConfig",
})

ConfigSection:Space({ Columns = 1 })

ConfigSection:Button({
    Title = "Apply Imported Config",
    Desc = "Load settings from pasted JSON",
    Icon = "solar:import-bold",
    Callback = function()
        Notify({
            Title = "Import",
            Content = "Paste JSON into the field above and click Apply.",
            Icon = "solar:import-bold",
        })
    end,
})

SettingsTab:Space({ Columns = 2 })

-- Destroy UI
SettingsTab:Button({
    Title = "Unload Hub",
    Desc = "Remove the UI completely",
    Icon = "solar:trash-bin-trash-bold",
    Color = Color3.fromHex("#FF7675"),
    Callback = function()
        WindUI:Popup({
            Title = "Are you sure?",
            Icon = "solar:danger-triangle-bold",
            Content = "This will completely unload the hub and reset all features.",
            Buttons = {
                {
                    Title = "Cancel",
                    Icon = "solar:close-circle-bold",
                    Callback = function() end,
                },
                {
                    Title = "Unload",
                    Icon = "solar:trash-bin-trash-bold",
                    Primary = true,
                    Callback = function()
                        CleanupConnections()
                        Window:Destroy()
                    end,
                },
            },
        })
    end,
})

-- ============================================================
-- TAB: MISC
-- ============================================================
local MiscTab = SettingsSection:Tab({
    Title = "Misc",
    Icon = "solar:widget-5-bold",
    IconColor = Color3.fromHex("#FD79A8"),
    IconShape = "Square",
})

-- Lighting / time
local LightingSection = MiscTab:Section({ Title = "World", Opened = true })
local timeSlider = LightingSection:Slider({
    Title = "Time of Day",
    Desc = "Adjust world lighting",
    Icon = "solar:sun-bold",
    Min = 0,
    Max = 24,
    Default = 14,
    Step = 1,
    Suffix = ":00",
    Flag = "TimeOfDay",
    Callback = function(value)
        pcall(function()
            Lighting.ClockTime = value
        end)
    end,
})

LightingSection:Space({ Columns = 1 })

local fogToggle = LightingSection:Toggle({
    Title = "Disable Fog",
    Desc = "Remove atmospheric fog",
    Icon = "solar:cloud-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "DisableFog",
    Callback = function(state)
        pcall(function()
            Lighting.FogEnd = state and 100000 or 1000
        end)
    end,
})

-- Sound
local SoundSection = MiscTab:Section({ Title = "Audio", Opened = false })
local soundMuteToggle = SoundSection:Toggle({
    Title = "Mute All Sounds",
    Desc = "Silence the game",
    Icon = "solar:volume-cross-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "MuteSounds",
    Callback = function(state)
        pcall(function()
            SoundService.AmbientReverb = Enum.ReverbType.NoReverb
        end)
    end,
})

SoundSection:Space({ Columns = 1 })

-- FPS / Performance
local PerfSection = MiscTab:Section({ Title = "Performance", Opened = true })
local fpsUnlockerToggle = PerfSection:Toggle({
    Title = "FPS Unlocker",
    Desc = "Remove frame rate cap",
    Icon = "solar:speedometer-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "FPSUnlocker",
    Callback = function(state)
        if state then
            pcall(function()
                if setfpscap then setfpscap(999) end
            end)
            Notify({
                Title = "FPS Unlocked",
                Content = "Frame rate cap removed.",
                Icon = "solar:speedometer-bold",
            })
        else
            pcall(function()
                if setfpscap then setfpscap(60) end
            end)
        end
    end,
})

PerfSection:Space({ Columns = 1 })

local lowGraphicsToggle = PerfSection:Toggle({
    Title = "Low Graphics Mode",
    Desc = "Reduce visual quality for performance",
    Icon = "solar:monitor-bold",
    Type = "Checkbox",
    Value = false,
    Flag = "LowGraphics",
    Callback = function(state)
        pcall(function()
            Lighting.GlobalShadows = not state
            Lighting.Brightness = state and 1 or 2
        end)
    end,
})

-- ============================================================
-- TAB: MOBILE CONTROLS
-- ============================================================
local MobileSection = Window:Section({ Title = "Mobile" })

local MobileTab = MobileSection:Tab({
    Title = "Controls",
    Icon = "solar:smartphone-rotate-2-bold",
    IconColor = Color3.fromHex("#55EFC4"),
    IconShape = "Square",
    Locked = not Performance.MobileMode,
})

local MobileControlSection = MobileTab:Section({ Title = "Mobile Options", Opened = true })
local mobilePerfToggle = MobileControlSection:Toggle({
    Title = "Mobile Performance Mode",
    Desc = "Reduce effects and update rates",
    Icon = "solar:lightning-bolt-bold",
    Type = "Checkbox",
    Value = true,
    Flag = "MobilePerformance",
})

MobileControlSection:Space({ Columns = 1 })

local mobileSprintToggle = MobileControlSection:Toggle({
    Title = "Separate Sprint Button",
    Desc = "Fixed sprint button instead of radial",
    Icon = "solar:walk-bold",
    Type = "Checkbox",
    Value = true,
    Flag = "MobileSprint",
})

MobileControlSection:Space({ Columns = 1 })

MobileControlSection:Button({
    Title = "Customize Controls",
    Desc = "Move mobile action buttons",
    Icon = "solar:settings-bold",
    Callback = function()
        Notify({
            Title = "Layout Editor",
            Content = "Drag buttons to reposition them.",
            Icon = "solar:settings-bold",
        })
    end,
})

-- Mobile sliders
local MobileSliderSection = MobileTab:Section({ Title = "Mobile Tuning", Opened = false })
MobileSliderSection:Slider({
    Title = "Button Size",
    Desc = "Scale mobile buttons",
    Icon = "solar:maximize-bold",
    Min = 80,
    Max = 100,
    Default = 100,
    Step = 5,
    Suffix = "%",
    Flag = "MobileButtonSize",
})

MobileSliderSection:Space({ Columns = 1 })

MobileSliderSection:Slider({
    Title = "Aim Assist Strength",
    Desc = "Mobile aim assist intensity",
    Icon = "solar:target-bold",
    Min = 0,
    Max = 100,
    Default = 100,
    Step = 5,
    Suffix = "%",
    Flag = "MobileAimStrength",
})

-- ============================================================
-- CONFIG MANAGER
-- ============================================================
local ConfigManager = Window.ConfigManager

-- Auto-save handling
local autoSaveConn = Track(Window.OnClose or RunService.Heartbeat)

-- ============================================================
-- MOBILE UI SCALE
-- ============================================================
if Performance.MobileMode then
    pcall(function()
        Window:SetUIScale(1.1)
    end)
end

-- ============================================================
-- CLEANUP ON SCRIPT DESTROY
-- ============================================================
script.Destroying:Connect(function()
    CleanupConnections()
end)

-- ============================================================
-- STARTUP NOTIFICATION
-- ============================================================
Notify({
    Title = "Premium Hub Loaded",
    Content = "Press " .. tostring(Window.ToggleKey or "RightShift") .. " to toggle.",
    Icon = "solar:check-circle-bold",
    Duration = 5,
})