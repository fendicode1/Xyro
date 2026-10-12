--[[
    ╔══════════════════════════════════════════╗
    ║           XYRO HUB — Lift Rock For Eggs  ║
    ║           v1.0.0 | Keyless               ║
    ║           Toggle GUI + Unload            ║
    ╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════
-- METADATA
-- ═══════════════════════════════════════════
local HUB = {
    Name = "Xyro Hub",
    Version = "1.0.0",
    Game = "Lift Rock For Eggs",
    Keybind = Enum.KeyCode.RightShift,
    AccentColor = Color3.fromRGB(255, 90, 40), -- orange, sesuai theme game
}

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    Loaded = false,
    GUI = nil,
    Connections = {},
    Threads = {},
    Config = {
        -- Farm
        AutoLift = false,
        AutoGrabEgg = false,
        AutoReturnBase = false,
        AutoHatch = false,
        AutoPlacePet = false,
        AutoEquipBest = false,

        -- Train
        AutoTreadmill = false,
        AutoBenchPress = false,
        AutoRebirth = false,

        -- Upgrade
        AutoUpgradeGym = false,
        AutoUpgradePlot = false,

        -- Visual
        EggESP = false,
        Fullbright = false,
        NoClip = false,

        -- Player
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,

        -- Misc
        AntiAFK = true,
        AntiGuard = false,
    },
    Remotes = {},
    Eggs = {},
}

-- ═══════════════════════════════════════════
-- UTIL
-- ═══════════════════════════════════════════
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or HUB.Name,
            Text = text or "",
            Duration = duration or 4,
        })
    end)
end

local function log(...)
    print("[Xyro Hub LRE]", ...)
end

local function create(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 60, 70)
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

-- ═══════════════════════════════════════════
-- REMOTE SCANNER
-- ═══════════════════════════════════════════
local function scanRemotes()
    local found = {}
    local function scan(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                found[obj.Name:lower()] = obj
            end
        end
    end
    pcall(scan, ReplicatedStorage)
    pcall(scan, workspace)
    return found
end

local function findRemote(pattern)
    for name, remote in pairs(State.Remotes) do
        if name:find(pattern) then return remote end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- GAME OBJECT SCANNER
-- ═══════════════════════════════════════════
local function findEggs()
    local eggs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("egg") and not name:find("gui") then
                table.insert(eggs, obj)
            end
        end
    end
    return eggs
end

local function findPlot()
    -- Cari plot player (biasanya ada "Your farm" di atasnya)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("plot") or name:find("farm") or name:find("base") then
                return obj
            end
        end
    end
    return nil
end

local function findTrack()
    -- Cari lifting track
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("track") or name:find("lift") or name:find("lane") then
                return obj
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
-- CONFIG SAVE/LOAD
-- ═══════════════════════════════════════════
local CONFIG_FILE = "xyro_lre_config.json"

local function saveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(State.Config))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k, v in pairs(data) do State.Config[k] = v end
        end
    end)
end

-- ═══════════════════════════════════════════
-- FEATURE FUNCTIONS
-- ═══════════════════════════════════════════

-- Anti AFK
local function startAntiAFK()
    table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end))
end

-- WalkSpeed / JumpPower
local function setWalkSpeed(speed)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speed end
    end
end

local function setJumpPower(power)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = power end
    end
end

-- Fullbright
local function toggleFullbright(enabled)
    if enabled then
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end

-- Noclip
local function startNoclip()
    local thread = task.spawn(function()
        while State.Config.NoClip do
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
            task.wait(0.1)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Infinite Jump
local function startInfiniteJump()
    table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
        if State.Config.InfiniteJump then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState("Jumping") end
            end
        end
    end))
end

-- Egg ESP
local espObjects = {}
local function toggleEggESP(enabled)
    for _, obj in ipairs(espObjects) do pcall(function() obj:Destroy() end) end
    espObjects = {}

    if not enabled then return end

    local eggs = findEggs()
    for _, egg in ipairs(eggs) do
        local part = egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart")
        if part then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = HUB.AccentColor
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.Parent = egg
            table.insert(espObjects, highlight)

            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, 120, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 4, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = part

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = HUB.AccentColor
            label.TextStrokeTransparency = 0
            label.Text = egg.Name
            label.Parent = billboard

            table.insert(espObjects, billboard)
        end
    end
    notify(HUB.Name, "Egg ESP: " .. tostring(enabled) .. " (" .. tostring(#eggs) .. " eggs)", 3)
end

-- Auto Lift
local function startAutoLift()
    local thread = task.spawn(function()
        while State.Config.AutoLift do
            pcall(function()
                local remote = findRemote("lift") or findRemote("push") or findRemote("track")
                if remote then remote:FireServer() end
            end)
            task.wait(0.5)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Grab Egg
local function startAutoGrabEgg()
    local thread = task.spawn(function()
        while State.Config.AutoGrabEgg do
            pcall(function()
                local remote = findRemote("grab") or findRemote("pickup") or findRemote("egg")
                if remote then
                    local eggs = findEggs()
                    if #eggs > 0 then
                        remote:FireServer(eggs[1])
                    end
                end
            end)
            task.wait(1)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Return Base
local function startAutoReturnBase()
    local thread = task.spawn(function()
        while State.Config.AutoReturnBase do
            pcall(function()
                local char = LocalPlayer.Character
                local plot = findPlot()
                if char and plot then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local plotPart = plot:IsA("BasePart") and plot or plot:FindFirstChildWhichIsA("BasePart")
                        if plotPart then
                            hum:MoveTo(plotPart.Position)
                        end
                    end
                end
            end)
            task.wait(2)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Hatch
local function startAutoHatch()
    local thread = task.spawn(function()
        while State.Config.AutoHatch do
            pcall(function()
                local remote = findRemote("hatch")
                if remote then remote:FireServer() end
            end)
            task.wait(1)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Place Pet
local function startAutoPlacePet()
    local thread = task.spawn(function()
        while State.Config.AutoPlacePet do
            pcall(function()
                local remote = findRemote("place") or findRemote("equip")
                if remote then remote:FireServer() end
            end)
            task.wait(1)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Equip Best
local function startAutoEquipBest()
    local thread = task.spawn(function()
        while State.Config.AutoEquipBest do
            pcall(function()
                local remote = findRemote("equipbest") or findRemote("best") or findRemote("equip")
                if remote then remote:FireServer() end
            end)
            task.wait(2)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Treadmill (Speed training)
local function startAutoTreadmill()
    local thread = task.spawn(function()
        while State.Config.AutoTreadmill do
            pcall(function()
                -- Teleport ke treadmill di plot
                local plot = findPlot()
                if plot then
                    for _, obj in ipairs(plot:GetDescendants()) do
                        if obj:IsA("BasePart") and obj.Name:lower():find("treadmill") then
                            local char = LocalPlayer.Character
                            if char then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                                end
                            end
                        end
                    end
                end
                -- Fire remote kalau ada
                local remote = findRemote("treadmill") or findRemote("train") or findRemote("speed")
                if remote then remote:FireServer() end
            end)
            task.wait(1)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Bench Press (Strength training)
local function startAutoBenchPress()
    local thread = task.spawn(function()
        while State.Config.AutoBenchPress do
            pcall(function()
                local plot = findPlot()
                if plot then
                    for _, obj in ipairs(plot:GetDescendants()) do
                        if obj:IsA("BasePart") and (obj.Name:lower():find("bench") or obj.Name:lower():find("weight")) then
                            local char = LocalPlayer.Character
                            if char then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                                end
                            end
                        end
                    end
                end
                local remote = findRemote("bench") or findRemote("strength") or findRemote("train")
                if remote then remote:FireServer() end
            end)
            task.wait(1)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Rebirth
local function startAutoRebirth()
    local thread = task.spawn(function()
        while State.Config.AutoRebirth do
            pcall(function()
                local remote = findRemote("rebirth")
                if remote then remote:FireServer() end
            end)
            task.wait(5)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Auto Upgrade
local function startAutoUpgradeGym()
    local thread = task.spawn(function()
        while State.Config.AutoUpgradeGym do
            pcall(function()
                local remote = findRemote("upgrade") or findRemote("gym")
                if remote then remote:FireServer() end
            end)
            task.wait(3)
        end
    end)
    table.insert(State.Threads, thread)
end

local function startAutoUpgradePlot()
    local thread = task.spawn(function()
        while State.Config.AutoUpgradePlot do
            pcall(function()
                local remote = findRemote("plot") or findRemote("upgrade")
                if remote then remote:FireServer() end
            end)
            task.wait(3)
        end
    end)
    table.insert(State.Threads, thread)
end

-- Anti Guard (teleport ke base kalau ada guard dekat)
local function startAntiGuard()
    local thread = task.spawn(function()
        while State.Config.AntiGuard do
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name:lower():find("chicken") or obj.Name:lower():find("guard") or obj.Name:lower():find("llama")) then
                                local guardPart = obj:FindFirstChildWhichIsA("BasePart")
                                if guardPart and (guardPart.Position - hrp.Position).Magnitude < 30 then
                                    -- Teleport ke plot
                                    local plot = findPlot()
                                    if plot then
                                        local plotPart = plot:IsA("BasePart") and plot or plot:FindFirstChildWhichIsA("BasePart")
                                        if plotPart then
                                            hrp.CFrame = plotPart.CFrame + Vector3.new(0, 5, 0)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
    table.insert(State.Threads, thread)
end

-- ═══════════════════════════════════════════
-- GUI FRAMEWORK
-- ═══════════════════════════════════════════
local function buildGUI()
    local screenGui = create("ScreenGui", {
        Name = "XyroHubLRE",
        ResetOnSpawn = false,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
    })
    State.GUI = screenGui

    -- Main frame
    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 540, 0, 420),
        Position = UDim2.new(0.5, -270, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(18, 15, 12),
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        Parent = screenGui,
    })
    addCorner(main, 10)
    addStroke(main, HUB.AccentColor, 1)

    -- Title bar
    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(24, 20, 16),
        BorderSizePixel = 0,
        Parent = main,
    })
    addCorner(titleBar, 10)

    local titleMask = create("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 1, -22),
        BackgroundColor3 = Color3.fromRGB(24, 20, 16),
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    local logo = create("TextLabel", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 10, 0.5, -16),
        BackgroundColor3 = HUB.AccentColor,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "X",
        Parent = titleBar,
    })
    addCorner(logo, 8)

    create("TextLabel", {
        Size = UDim2.new(0, 250, 0, 22),
        Position = UDim2.new(0, 50, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(245, 240, 235),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = HUB.Name,
        Parent = titleBar,
    })

    create("TextLabel", {
        Size = UDim2.new(0, 250, 0, 14),
        Position = UDim2.new(0, 50, 0, 23),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(140, 130, 120),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "v" .. HUB.Version .. " | " .. HUB.Game,
        Parent = titleBar,
    })

    local minBtn = create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -100, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(45, 40, 35),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(220, 215, 210),
        Text = "—",
        Parent = titleBar,
    })
    addCorner(minBtn, 6)

    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(220, 60, 60),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "X",
        Parent = titleBar,
    })
    addCorner(closeBtn, 6)

    -- Tab bar
    local tabBar = create("Frame", {
        Size = UDim2.new(0, 130, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(22, 18, 14),
        BorderSizePixel = 0,
        Parent = main,
    })

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabBar,
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tabBar,
    })

    local content = create("Frame", {
        Size = UDim2.new(1, -130, 1, -44),
        Position = UDim2.new(0, 130, 0, 44),
        BackgroundColor3 = Color3.fromRGB(18, 15, 12),
        BorderSizePixel = 0,
        Parent = main,
    })

    -- Tab system
    local tabButtons = {}
    local tabPages = {}

    local function createTab(name)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.fromRGB(30, 25, 20),
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(180, 170, 160),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "  " .. name,
            Parent = tabBar,
        })
        addCorner(btn, 6)

        local page = create("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = HUB.AccentColor,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = content,
        })

        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = page,
        })

        tabButtons[name] = btn
        tabPages[name] = page

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
                b.TextColor3 = Color3.fromRGB(180, 170, 160)
            end
            for _, p in pairs(tabPages) do p.Visible = false end

            btn.BackgroundColor3 = HUB.AccentColor
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            page.Visible = true
        end)

        return page
    end

    -- Widgets
    local function section(parent, text)
        return create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = HUB.AccentColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.upper(text),
            Parent = parent,
        })
    end

    local function toggle(parent, name, default, callback)
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(26, 22, 18),
            BorderSizePixel = 0,
            Parent = parent,
        })
        addCorner(frame, 6)

        create("TextLabel", {
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(225, 220, 215),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = name,
            Parent = frame,
        })

        local tg = create("TextButton", {
            Size = UDim2.new(0, 40, 0, 20),
            Position = UDim2.new(1, -52, 0.5, -10),
            BackgroundColor3 = default and HUB.AccentColor or Color3.fromRGB(55, 48, 42),
            BorderSizePixel = 0,
            Text = "",
            Parent = frame,
        })
        addCorner(tg, 10)

        local knob = create("Frame", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = tg,
        })
        addCorner(knob, 8)

        local state = default
        tg.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(tg, TweenInfo.new(0.2), {
                BackgroundColor3 = state and HUB.AccentColor or Color3.fromRGB(55, 48, 42)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }):Play()
            if callback then callback(state) end
            saveConfig()
        end)

        return frame
    end

    local function slider(parent, name, min, max, default, callback)
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = Color3.fromRGB(26, 22, 18),
            BorderSizePixel = 0,
            Parent = parent,
        })
        addCorner(frame, 6)

        create("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 16),
            Position = UDim2.new(0, 12, 0, 4),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(225, 220, 215),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = name,
            Parent = frame,
        })

        local valLabel = create("TextLabel", {
            Size = UDim2.new(0.4, -12, 0, 16),
            Position = UDim2.new(0.6, 0, 0, 4),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = HUB.AccentColor,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = tostring(default),
            Parent = frame,
        })

        local bar = create("Frame", {
            Size = UDim2.new(1, -24, 0, 6),
            Position = UDim2.new(0, 12, 0, 30),
            BackgroundColor3 = Color3.fromRGB(50, 44, 38),
            BorderSizePixel = 0,
            Parent = frame,
        })
        addCorner(bar, 3)

        local fill = create("Frame", {
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = HUB.AccentColor,
            BorderSizePixel = 0,
            Parent = bar,
        })
        addCorner(fill, 3)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLabel.Text = tostring(val)
            if callback then callback(val) end
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)

        table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end))

        table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                saveConfig()
            end
        end))

        return frame
    end

    local function button(parent, name, color, callback)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = color or HUB.AccentColor,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = name,
            Parent = parent,
        })
        addCorner(btn, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- FARM TAB
    local farmPage = createTab("Farm")
    section(farmPage, "Lifting")
    toggle(farmPage, "Auto Lift Track", State.Config.AutoLift, function(v)
        State.Config.AutoLift = v
        if v then startAutoLift() end
    end)
    toggle(farmPage, "Auto Grab Egg", State.Config.AutoGrabEgg, function(v)
        State.Config.AutoGrabEgg = v
        if v then startAutoGrabEgg() end
    end)
    toggle(farmPage, "Auto Return Base", State.Config.AutoReturnBase, function(v)
        State.Config.AutoReturnBase = v
        if v then startAutoReturnBase() end
    end)
    section(farmPage, "Egg & Pet")
    toggle(farmPage, "Auto Hatch", State.Config.AutoHatch, function(v)
        State.Config.AutoHatch = v
        if v then startAutoHatch() end
    end)
    toggle(farmPage, "Auto Place Pet", State.Config.AutoPlacePet, function(v)
        State.Config.AutoPlacePet = v
        if v then startAutoPlacePet() end
    end)
    toggle(farmPage, "Auto Equip Best", State.Config.AutoEquipBest, function(v)
        State.Config.AutoEquipBest = v
        if v then startAutoEquipBest() end
    end)
    section(farmPage, "Progression")
    toggle(farmPage, "Auto Rebirth", State.Config.AutoRebirth, function(v)
        State.Config.AutoRebirth = v
        if v then startAutoRebirth() end
    end)

    -- TRAIN TAB
    local trainPage = createTab("Train")
    section(trainPage, "Gym")
    toggle(trainPage, "Auto Treadmill (Speed)", State.Config.AutoTreadmill, function(v)
        State.Config.AutoTreadmill = v
        if v then startAutoTreadmill() end
    end)
    toggle(trainPage, "Auto Bench Press (Strength)", State.Config.AutoBenchPress, function(v)
        State.Config.AutoBenchPress = v
        if v then startAutoBenchPress() end
    end)
    section(trainPage, "Upgrade")
    toggle(trainPage, "Auto Upgrade Gym", State.Config.AutoUpgradeGym, function(v)
        State.Config.AutoUpgradeGym = v
        if v then startAutoUpgradeGym() end
    end)
    toggle(trainPage, "Auto Upgrade Plot", State.Config.AutoUpgradePlot, function(v)
        State.Config.AutoUpgradePlot = v
        if v then startAutoUpgradePlot() end
    end)

    -- VISUAL TAB
    local visualPage = createTab("Visual")
    section(visualPage, "ESP")
    toggle(visualPage, "Egg ESP", State.Config.EggESP, function(v)
        State.Config.EggESP = v
        toggleEggESP(v)
    end)
    section(visualPage, "Lighting")
    toggle(visualPage, "Fullbright", State.Config.Fullbright, function(v)
        State.Config.Fullbright = v
        toggleFullbright(v)
    end)

    -- PLAYER TAB
    local playerPage = createTab("Player")
    section(playerPage, "Movement")
    slider(playerPage, "WalkSpeed", 16, 200, State.Config.WalkSpeed, function(v)
        State.Config.WalkSpeed = v
        setWalkSpeed(v)
    end)
    slider(playerPage, "JumpPower", 50, 200, State.Config.JumpPower, function(v)
        State.Config.JumpPower = v
        setJumpPower(v)
    end)
    toggle(playerPage, "Noclip", State.Config.NoClip, function(v)
        State.Config.NoClip = v
        if v then startNoclip() end
    end)
    toggle(playerPage, "Infinite Jump", State.Config.InfiniteJump, function(v)
        State.Config.InfiniteJump = v
    end)
    section(playerPage, "Protection")
    toggle(playerPage, "Anti Guard", State.Config.AntiGuard, function(v)
        State.Config.AntiGuard = v
        if v then startAntiGuard() end
    end)

    -- MISC TAB
    local miscPage = createTab("Misc")
    section(miscPage, "Game")
    toggle(miscPage, "Anti AFK", State.Config.AntiAFK, function(v)
        State.Config.AntiAFK = v
    end)
    button(miscPage, "Rejoin Server", Color3.fromRGB(100, 180, 100), function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
    section(miscPage, "Hub")
    button(miscPage, "Save Config", Color3.fromRGB(80, 140, 200), function()
        saveConfig()
        notify(HUB.Name, "Config saved", 2)
    end)
    button(miscPage, "Reset Config", Color3.fromRGB(200, 140, 80), function()
        if delfile then pcall(delfile, CONFIG_FILE) end
        notify(HUB.Name, "Config reset — rejoin to apply", 3)
    end)
    button(miscPage, "Unload Hub", Color3.fromRGB(220, 60, 60), function()
        unload()
    end)

    -- Default tab
    tabButtons["Farm"].BackgroundColor3 = HUB.AccentColor
    tabButtons["Farm"].TextColor3 = Color3.fromRGB(255, 255, 255)
    tabPages["Farm"].Visible = true

    -- Minimize / Close
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local target = minimized and UDim2.new(0, 540, 0, 44) or UDim2.new(0, 540, 0, 420)
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = target }):Play()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
        notify(HUB.Name, "GUI hidden — press " .. HUB.Keybind.Name .. " to reopen", 3)
    end)

    return screenGui
end

-- ═══════════════════════════════════════════
-- UNLOAD
-- ═══════════════════════════════════════════
function unload()
    log("Unloading...")
    for _, thread in ipairs(State.Threads) do
        pcall(function() task.cancel(thread) end)
    end
    State.Threads = {}
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    toggleEggESP(false)
    for k in pairs(State.Config) do
        if type(State.Config[k]) == "boolean" then State.Config[k] = false end
    end
    if State.GUI then
        State.GUI:Destroy()
        State.GUI = nil
    end
    State.Loaded = false
    notify(HUB.Name, "Hub unloaded", 3)
end

-- ═══════════════════════════════════════════
-- KEYBIND
-- ═══════════════════════════════════════════
local function setupKeybind()
    table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == HUB.Keybind and State.GUI then
            State.GUI.Enabled = not State.GUI.Enabled
        end
    end))
end

-- ═══════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════
local function init()
    log("Loading " .. HUB.Name .. " v" .. HUB.Version .. "...")

    loadConfig()
    State.Remotes = scanRemotes()
    log("Found " .. tostring(#State.Remotes) .. " remotes")

    local eggs = findEggs()
    log("Found " .. tostring(#eggs) .. " eggs in workspace")

    buildGUI()
    setupKeybind()

    if State.Config.AntiAFK then startAntiAFK() end

    State.Loaded = true
    notify(HUB.Name, "Loaded! Press " .. HUB.Keybind.Name .. " to toggle GUI", 5)
    log("Ready.")
end

init()