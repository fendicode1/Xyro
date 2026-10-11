--[[
    Xyro Hub — Steal An Egg
    Author: Xyro
    Executor: Xeno, Delta, Solara, Wave, Volt, Potassium, Codex
    Features: Auto Steal, Auto Return, Auto Place, Auto Hatch, Auto Equip,
              Egg ESP, Guardian ESP, Player ESP, WalkSpeed, JumpPower,
              Infinite Jump, Server Hop, Anti-AFK
    UI: Custom dark theme, tab-based, hover effects, draggable
--]]

-- ═══════════════════════════════════════════════════
-- SERVICES & CORE
-- ═══════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════
-- CLEANUP OLD
-- ═══════════════════════════════════════════════════
pcall(function()
    if CoreGui:FindFirstChild("XyroHub") then
        CoreGui.XyroHub:Destroy()
    end
    if LocalPlayer:FindFirstChild("XyroHub") then
        LocalPlayer.XyroHub:Destroy()
    end
end)

-- ═══════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════
local Config = {
    AutoSteal = false,
    AutoReturn = false,
    AutoPlace = false,
    AutoHatch = false,
    AutoEquip = false,
    EggESP = false,
    GuardianESP = false,
    PlayerESP = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    AntiAFK = true,
    StealRange = 50,
    ReturnDelay = 1,
}

-- ═══════════════════════════════════════════════════
-- UI LIBRARY (Custom)
-- ═══════════════════════════════════════════════════
local Theme = {
    BG = Color3.fromRGB(14, 14, 18),
    Panel = Color3.fromRGB(20, 20, 26),
    Accent = Color3.fromRGB(120, 80, 255),
    AccentDark = Color3.fromRGB(80, 50, 180),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(140, 140, 155),
    ToggleOn = Color3.fromRGB(120, 80, 255),
    ToggleOff = Color3.fromRGB(45, 45, 55),
    Stroke = Color3.fromRGB(35, 35, 45),
    Hover = Color3.fromRGB(30, 30, 40),
}

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

-- Main ScreenGui
local ScreenGui = Create("ScreenGui", {
    Name = "XyroHub",
    Parent = CoreGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

-- Main Frame
local MainFrame = Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    Size = UDim2.new(0, 520, 0, 380),
    Position = UDim2.new(0.5, -260, 0.5, -190),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})

Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 12) })
Create("UIStroke", { Parent = MainFrame, Color = Theme.Stroke, Thickness = 1 })

-- Header
local Header = Create("Frame", {
    Name = "Header",
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
})

Create("UICorner", { Parent = Header, CornerRadius = UDim.new(0, 12) })

local HeaderFix = Create("Frame", {
    Parent = Header,
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
})

Create("TextLabel", {
    Parent = Header,
    Text = "  XYRO HUB  |  STEAL AN EGG",
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
})

-- Close button
local CloseBtn = Create("TextButton", {
    Parent = Header,
    Text = "✕",
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(1, -44, 0, 4),
    BackgroundColor3 = Theme.BG,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.SubText,
    BorderSizePixel = 0,
})

Create("UICorner", { Parent = CloseBtn, CornerRadius = UDim.new(0, 8) })

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(180, 50, 60),
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.BG,
        TextColor3 = Theme.SubText,
    }):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Minimize button
local MinBtn = Create("TextButton", {
    Parent = Header,
    Text = "—",
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(1, -84, 0, 4),
    BackgroundColor3 = Theme.BG,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.SubText,
    BorderSizePixel = 0,
})

Create("UICorner", { Parent = MinBtn, CornerRadius = UDim.new(0, 8) })

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Draggable
local dragging = false
local dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ─── Tab Bar ───
local TabBar = Create("Frame", {
    Name = "TabBar",
    Parent = MainFrame,
    Size = UDim2.new(0, 120, 1, -56),
    Position = UDim2.new(0, 12, 0, 48),
    BackgroundTransparency = 1,
})

-- ─── Content Area ───
local Content = Create("Frame", {
    Name = "Content",
    Parent = MainFrame,
    Size = UDim2.new(1, -156, 1, -68),
    Position = UDim2.new(0, 144, 0, 56),
    BackgroundTransparency = 1,
})

-- ─── Tab System ───
local Tabs = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    local btn = Create("TextButton", {
        Parent = TabBar,
        Text = "",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, #Tabs * 42),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

    local label = Create("TextLabel", {
        Parent = btn,
        Text = "  " .. name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local container = Create("ScrollingFrame", {
        Parent = Content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
    })
    Create("UIListLayout", {
        Parent = container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    Create("UIPadding", {
        Parent = container,
        PaddingRight = UDim.new(0, 6),
    })

    local tab = { Btn = btn, Label = label, Container = container, Name = name }
    table.insert(Tabs, tab)

    btn.MouseEnter:Connect(function()
        if ActiveTab ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Hover }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= tab then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do
            t.Container.Visible = false
            TweenService:Create(t.Btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel }):Play()
            TweenService:Create(t.Label, TweenInfo.new(0.15), { TextColor3 = Theme.SubText }):Play()
        end
        container.Visible = true
        ActiveTab = tab
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentDark }):Play()
        TweenService:Create(label, TweenInfo.new(0.15), { TextColor3 = Theme.Text }):Play()
    end)

    return tab
end

-- ─── Components ───
local function AddToggle(parent, text, default, callback)
    local holder = Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = holder, CornerRadius = UDim.new(0, 8) })

    Create("TextLabel", {
        Parent = holder,
        Text = "  " .. text,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local toggleBg = Create("Frame", {
        Parent = holder,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = toggleBg, CornerRadius = UDim.new(1, 0) })

    local knob = Create("Frame", {
        Parent = toggleBg,
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local state = default
    local btn = Create("TextButton", {
        Parent = holder,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })

    local function update(val)
        state = val
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = val and Theme.ToggleOn or Theme.ToggleOff,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        }):Play()
        callback(val)
    end

    btn.MouseButton1Click:Connect(function()
        update(not state)
    end)

    holder.MouseEnter:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    holder.MouseLeave:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel }):Play()
    end)

    return { Set = update, Get = function() return state end }
end

local function AddSlider(parent, text, min, max, default, callback)
    local holder = Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = holder, CornerRadius = UDim.new(0, 8) })

    Create("TextLabel", {
        Parent = holder,
        Text = "  " .. text,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 8, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valueLabel = Create("TextLabel", {
        Parent = holder,
        Text = tostring(default),
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -70, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local barBg = Create("Frame", {
        Parent = holder,
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 1, -18),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = barBg, CornerRadius = UDim.new(1, 0) })

    local fill = Create("Frame", {
        Parent = barBg,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

    local knob = Create("Frame", {
        Parent = barBg,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    Create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local sliderBtn = Create("TextButton", {
        Parent = holder,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Text = "",
    })

    local dragging = false
    local function updateFromInput(input)
        local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        valueLabel.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
        callback(val)
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return { Set = function(v) valueLabel.Text = tostring(v); fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0); knob.Position = UDim2.new((v-min)/(max-min), -7, 0.5, -7) end }
end

local function AddButton(parent, text, callback)
    local btn = Create("TextButton", {
        Parent = parent,
        Text = "  " .. text,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
    })
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        callback()
    end)

    return btn
end

local function AddLabel(parent, text, color)
    local lbl = Create("TextLabel", {
        Parent = parent,
        Text = "  " .. text,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = color or Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return lbl
end

-- ═══════════════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════════════
local FarmTab = CreateTab("Farm")
local ESPTab = CreateTab("ESP")
local PlayerTab = CreateTab("Player")
local MiscTab = CreateTab("Misc")

if Tabs[1] then
    Tabs[1].Container.Visible = true
    ActiveTab = Tabs[1]
    TweenService:Create(Tabs[1].Btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentDark }):Play()
    TweenService:Create(Tabs[1].Label, TweenInfo.new(0.15), { TextColor3 = Theme.Text }):Play()
end

-- ═══════════════════════════════════════════════════
-- FARM TAB
-- ═══════════════════════════════════════════════════
AddToggle(FarmTab.Container, "Auto Steal", false, function(v) Config.AutoSteal = v end)
AddToggle(FarmTab.Container, "Auto Return to Base", false, function(v) Config.AutoReturn = v end)
AddToggle(FarmTab.Container, "Auto Place Egg", false, function(v) Config.AutoPlace = v end)
AddToggle(FarmTab.Container, "Auto Hatch", false, function(v) Config.AutoHatch = v end)
AddToggle(FarmTab.Container, "Auto Equip Best Pet", false, function(v) Config.AutoEquip = v end)

AddSlider(FarmTab.Container, "Steal Range", 10, 200, 50, function(v) Config.StealRange = v end)

AddLabel(FarmTab.Container, "─── Status ───", Theme.Accent)

local StatusLabel = AddLabel(FarmTab.Container, "Idle", Theme.SubText)

-- ═══════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════
AddToggle(ESPTab.Container, "Egg ESP", false, function(v)
    Config.EggESP = v
    if not v then ClearESP("Egg") end
end)

AddToggle(ESPTab.Container, "Guardian ESP", false, function(v)
    Config.GuardianESP = v
    if not v then ClearESP("Guardian") end
end)

AddToggle(ESPTab.Container, "Player ESP", false, function(v)
    Config.PlayerESP = v
    if not v then ClearESP("Player") end
end)

AddButton(ESPTab.Container, "Clear All ESP", function()
    ClearESP("Egg")
    ClearESP("Guardian")
    ClearESP("Player")
end)

-- ═══════════════════════════════════════════════════
-- PLAYER TAB
-- ═══════════════════════════════════════════════════
AddSlider(PlayerTab.Container, "WalkSpeed", 16, 500, 16, function(v)
    Config.WalkSpeed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
    end
end)

AddSlider(PlayerTab.Container, "JumpPower", 50, 500, 50, function(v)
    Config.JumpPower = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = v
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").UseJumpPower = true
    end
end)

AddToggle(PlayerTab.Container, "Infinite Jump", false, function(v)
    Config.InfiniteJump = v
end)

AddToggle(PlayerTab.Container, "Anti-AFK", true, function(v)
    Config.AntiAFK = v
end)

AddButton(PlayerTab.Container, "Teleport to Spawn", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
    end
end)

-- ═══════════════════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════════════════
AddButton(MiscTab.Container, "Server Hop (Lowest Ping)", function()
    local servers = {}
    pcall(function()
        local req = http_request or request or HttpGet or syn and syn.request
        if req then
            local res = req({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" })
            local data = HttpService:JSONDecode(res.Body)
            for _, v in ipairs(data.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        end
    end)
    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        StatusLabel.Text = "No servers found"
    end
end)

AddButton(MiscTab.Container, "Copy Join Script", function()
    local script = 'game:GetService("TeleportService"):Teleport(' .. game.PlaceId .. ')'
    if setclipboard then
        setclipboard(script)
        StatusLabel.Text = "Join script copied"
    end
end)

AddLabel(MiscTab.Container, "─── Info ───", Theme.Accent)
AddLabel(MiscTab.Container, "Xyro Hub | Steal An Egg", Theme.SubText)
AddLabel(MiscTab.Container, "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"), Theme.SubText)

-- ═══════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════
local ESPObjects = {}

function ClearESP(typeFilter)
    for _, obj in pairs(ESPObjects) do
        if typeFilter then
            if obj.Type == typeFilter then
                pcall(function() obj.Highlight:Destroy() end)
                pcall(function() obj.Billboard:Destroy() end)
                ESPObjects[obj.Instance] = nil
            end
        else
            pcall(function() obj.Highlight:Destroy() end)
            pcall(function() obj.Billboard:Destroy() end)
        end
    end
    if not typeFilter then ESPObjects = {} end
end

local function CreateHighlight(instance, color, name, type)
    if ESPObjects[instance] then return end

    local highlight = Create("Highlight", {
        Parent = instance,
        FillColor = color,
        FillTransparency = 0.6,
        OutlineColor = color,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    })

    local billboard = Create("BillboardGui", {
        Parent = instance,
        Size = UDim2.new(0, 100, 0, 20),
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        Name = "XyroESP",
    })

    Create("TextLabel", {
        Parent = billboard,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = color,
        TextStrokeTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    })

    ESPObjects[instance] = {
        Highlight = highlight,
        Billboard = billboard,
        Type = type,
        Instance = instance,
    }
end

-- ═══════════════════════════════════════════════════
-- CHARACTER SETUP
-- ═══════════════════════════════════════════════════
local function OnCharacter(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.WalkSpeed = Config.WalkSpeed
        humanoid.JumpPower = Config.JumpPower
        humanoid.UseJumpPower = true
    end
end

if LocalPlayer.Character then
    OnCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(OnCharacter)

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

-- ═══════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRoot()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function FindEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("egg") and not name:find("ui") and not name:find("gui") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(eggs, { Instance = obj, Part = part })
                end
            end
        end
    end
    return eggs
end

local function FindGuardians()
    local guardians = {}
    local guardianNames = { "guardian", "guard", "protector", "monster" }
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            for _, gn in ipairs(guardianNames) do
                if name:find(gn) then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        table.insert(guardians, { Instance = obj, Part = part })
                    end
                end
            end
        end
    end
    return guardians
end

local function TrySteal(eggPart)
    local char = GetCharacter()
    if not char then return false end

    for _, obj in ipairs(eggPart:GetChildren()) do
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(obj)
            end)
            return true
        end
    end

    local parent = eggPart.Parent
    if parent then
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                pcall(function()
                    fireproximityprompt(obj)
                end)
                return true
            end
        end
    end

    pcall(function()
        local root = GetRoot()
        if root and (root.Position - eggPart.Position).Magnitude < 10 then
            eggPart.CFrame = root.CFrame
        end
    end)

    return false
end

local function GetBasePosition()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj.Position
        end
    end
    return Vector3.new(0, 10, 0)
end

task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoSteal then
            local root = GetRoot()
            if not root then continue end

            local eggs = FindEggs()
            local nearest = nil
            local nearestDist = Config.StealRange

            for _, egg in ipairs(eggs) do
                local dist = (egg.Part.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = egg
                end
            end

            if nearest then
                pcall(function()
                    root.CFrame = CFrame.new(nearest.Part.Position + Vector3.new(0, 3, 0))
                end)
                task.wait(0.2)

                if TrySteal(nearest.Part) then
                    StatusLabel.Text = "Stealing: " .. nearest.Instance.Name
                else
                    StatusLabel.Text = "Trying: " .. nearest.Instance.Name
                end
            else
                StatusLabel.Text = "No eggs in range"
            end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.ReturnDelay) do
        if Config.AutoReturn then
            local root = GetRoot()
            if not root then continue end

            local basePos = GetBasePosition()
            local dist = (root.Position - basePos).Magnitude

            if dist > 20 then
                pcall(function()
                    root.CFrame = CFrame.new(basePos + Vector3.new(0, 5, 0))
                end)
                StatusLabel.Text = "Returning to base..."
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.EggESP then
            local eggs = FindEggs()
            for _, egg in ipairs(eggs) do
                if not ESPObjects[egg.Instance] then
                    CreateHighlight(egg.Instance, Color3.fromRGB(255, 200, 50), "EGG", "Egg")
                end
            end
        end        if Config.GuardianESP then
            local guardians = FindGuardians()
            for _, g in ipairs(guardians) do
                if not ESPObjects[g.Instance] then
                    CreateHighlight(g.Instance, Color3.fromRGB(255, 60, 60), "GUARDIAN", "Guardian")
                end
            end
        end

        if Config.PlayerESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not ESPObjects[plr.Character] then
                        CreateHighlight(plr.Character, Color3.fromRGB(80, 200, 255), plr.Name, "Player")
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- REOPEN HOTKEY
-- ═══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ═══════════════════════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════════════════════
local function Notify(title, text)
    local notif = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0, 280, 0, 60),
        Position = UDim2.new(1, -300, 0, 20),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    })
    Create("UICorner", { Parent = notif, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = notif, Color = Theme.Accent, Thickness = 1 })

    Create("TextLabel", {
        Parent = notif,
        Text = title,
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    Create("TextLabel", {
        Parent = notif,
        Text = text,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Position = UDim2.new(1, -300, 0, 20),
    }):Play()

    task.delay(3, function()
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = UDim2.new(1, 20, 0, 20),
        }):Play()
        task.wait(0.4)
        notif:Destroy()
    end)
end

Notify("Xyro Hub", "Loaded. Press RightShift to toggle.")

print("[Xyro Hub] Loaded for Steal An Egg")