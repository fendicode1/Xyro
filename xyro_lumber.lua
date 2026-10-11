--[[
    Xyro Hub — Lumber Tycoon 2
    Author: Xyro
    For: He
    Executor: Xeno, Delta, Solara, Wave, Volt, Potassium, Codex, Vega
    Features: Auto Chop, Auto Collect, Auto Sell, ESP, Player, Teleport, Misc
    UI: Floating circular toggle button, draggable, tab-based dark theme
--]]

-- ═══════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════
pcall(function()
    if CoreGui:FindFirstChild("XyroHubLT2") then
        CoreGui.XyroHubLT2:Destroy()
    end
end)

-- ═══════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════
local Config = {
    AutoChop = false,
    ChopRange = 30,
    ChopSpeed = 0.1,
    AutoCollect = false,
    CollectRange = 100,
    AutoSell = false,
    SellRange = 500,
    TreeESP = false,
    PlayerESP = false,
    WoodESP = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    AntiAFK = true,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    Fullbright = false,
}

-- ═══════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════
local Theme = {
    BG = Color3.fromRGB(14, 14, 18),
    Panel = Color3.fromRGB(20, 20, 26),
    Accent = Color3.fromRGB(46, 204, 113),
    AccentDark = Color3.fromRGB(30, 140, 80),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(140, 140, 155),
    ToggleOn = Color3.fromRGB(46, 204, 113),
    ToggleOff = Color3.fromRGB(45, 45, 55),
    Stroke = Color3.fromRGB(35, 35, 45),
    Hover = Color3.fromRGB(30, 30, 40),
    Danger = Color3.fromRGB(220, 60, 70),
}

-- ═══════════════════════════════════════════════════
-- UTIL
-- ═══════════════════════════════════════════════════
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

local function GetChar()
    return LocalPlayer.Character
end

local function GetRoot()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════════════
local ScreenGui = Create("ScreenGui", {
    Name = "XyroHubLT2",
    Parent = CoreGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})

-- ═══════════════════════════════════════════════════
-- FLOATING CIRCULAR BUTTON
-- ═══════════════════════════════════════════════════
local FloatBtn = Create("TextButton", {
    Name = "FloatButton",
    Parent = ScreenGui,
    Size = UDim2.new(0, 52, 0, 52),
    Position = UDim2.new(1, -72, 1, -72),
    BackgroundColor3 = Theme.BG,
    Text = "",
    BorderSizePixel = 0,
    AutoButtonColor = false,
    ZIndex = 100,
    Active = true,
})

Create("UICorner", { Parent = FloatBtn, CornerRadius = UDim.new(1, 0) })
Create("UIStroke", { Parent = FloatBtn, Color = Theme.Accent, Thickness = 2 })

local GlowRing = Create("Frame", {
    Parent = FloatBtn,
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    ZIndex = 101,
    Active = false,
})
Create("UICorner", { Parent = GlowRing, CornerRadius = UDim.new(1, 0) })

local Icon = Create("TextLabel", {
    Parent = FloatBtn,
    Text = "X",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextColor3 = Theme.Accent,
    ZIndex = 102,
    Active = false,
})

-- Pulse animation
local pulseTween = TweenService:Create(GlowRing, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.4,
    Size = UDim2.new(1, -16, 1, -16),
    Position = UDim2.new(0, 8, 0, 8),
})
pulseTween:Play()

FloatBtn.MouseEnter:Connect(function()
    TweenService:Create(FloatBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Panel }):Play()
    TweenService:Create(Icon, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)
FloatBtn.MouseLeave:Connect(function()
    TweenService:Create(FloatBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.BG }):Play()
    TweenService:Create(Icon, TweenInfo.new(0.2), { TextColor3 = Theme.Accent }):Play()
end)

-- Float button drag
local btnDragging = false
local btnDragStart, btnStartPos

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragStart = input.Position
        btnStartPos = FloatBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnDragStart
        FloatBtn.Position = UDim2.new(
            btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X,
            btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
    end
end)

-- ═══════════════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════════════
local MainFrame = Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    Size = UDim2.new(0, 540, 0, 400),
    Position = UDim2.new(0.5, -270, 0.5, -200),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 50,
})

Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 12) })
Create("UIStroke", { Parent = MainFrame, Color = Theme.Stroke, Thickness = 1 })

local Header = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    ZIndex = 51,
})
Create("UICorner", { Parent = Header, CornerRadius = UDim.new(0, 12) })
Create("Frame", { Parent = Header, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ZIndex = 51 })

Create("TextLabel", {
    Parent = Header,
    Text = "  XYRO HUB  |  LUMBER TYCOON 2",
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 52,
})

local CloseBtn = Create("TextButton", {
    Parent = Header,
    Text = "✕",
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(1, -44, 0, 6),
    BackgroundColor3 = Theme.BG,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.SubText,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    ZIndex = 52,
})
Create("UICorner", { Parent = CloseBtn, CornerRadius = UDim.new(0, 8) })
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Danger, TextColor3 = Color3.fromRGB(255,255,255) }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.BG, TextColor3 = Theme.SubText }):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Main frame drag
local frameDragging = false
local frameDragStart, frameStartPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        frameDragging = true
        frameDragStart = input.Position
        frameStartPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if frameDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - frameDragStart
        MainFrame.Position = UDim2.new(
            frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        frameDragging = false
    end
end)

-- ═══════════════════════════════════════════════════
-- TAB SYSTEM
-- ═══════════════════════════════════════════════════
local TabBar = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(0, 130, 1, -60),
    Position = UDim2.new(0, 12, 0, 52),
    BackgroundTransparency = 1,
    ZIndex = 51,
})

local Content = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, -166, 1, -72),
    Position = UDim2.new(0, 154, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 51,
})

local Tabs = {}
local ActiveTab = nil

local function CreateTab(name)
    local btn = Create("TextButton", {
        Parent = TabBar,
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, #Tabs * 42),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 52,
    })
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

    local lbl = Create("TextLabel", {
        Parent = btn,
        Text = "  " .. name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 53,
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
        ZIndex = 52,
    })
    Create("UIListLayout", { Parent = container, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    Create("UIPadding", { Parent = container, PaddingRight = UDim.new(0, 6) })

    local tab = { Btn = btn, Label = lbl, Container = container, Name = name }
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
        TweenService:Create(lbl, TweenInfo.new(0.15), { TextColor3 = Theme.Text }):Play()
    end)

    return tab
end

-- ═══════════════════════════════════════════════════
-- COMPONENTS
-- ═══════════════════════════════════════════════════
local function AddToggle(parent, text, default, callback)
    local holder = Create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 53,
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
        ZIndex = 54,
    })

    local toggleBg = Create("Frame", {
        Parent = holder,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
        ZIndex = 54,
    })
    Create("UICorner", { Parent = toggleBg, CornerRadius = UDim.new(1, 0) })

    local knob = Create("Frame", {
        Parent = toggleBg,
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 55,
    })
    Create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local state = default
    local btn = Create("TextButton", {
        Parent = holder,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 56,
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
        ZIndex = 53,
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
        ZIndex = 54,
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
        ZIndex = 54,
    })

    local barBg = Create("Frame", {
        Parent = holder,
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 1, -18),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        ZIndex = 54,
    })
    Create("UICorner", { Parent = barBg, CornerRadius = UDim.new(1, 0) })

    local fill = Create("Frame", {
        Parent = barBg,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 55,
    })
    Create("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

    local knob = Create("Frame", {
        Parent = barBg,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 56,
    })
    Create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local sliderBtn = Create("TextButton", {
        Parent = holder,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 57,
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return { Set = function(v)
        valueLabel.Text = tostring(v)
        local rel = (v - min) / (max - min)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
    end }
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
        ZIndex = 53,
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
    return Create("TextLabel", {
        Parent = parent,
        Text = "  " .. text,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = color or Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 53,
    })
end

-- ═══════════════════════════════════════════════════
-- BUILD TABS
-- ═══════════════════════════════════════════════════
local FarmTab = CreateTab("Farm")
local ESPTab = CreateTab("ESP")
local PlayerTab = CreateTab("Player")
local TeleportTab = CreateTab("Teleport")
local MiscTab = CreateTab("Misc")

if Tabs[1] then
    Tabs[1].Container.Visible = true
    ActiveTab = Tabs[1]
    TweenService:Create(Tabs[1].Btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentDark }):Play()
    TweenService:Create(Tabs[1].Label, TweenInfo.new(0.15), { TextColor3 = Theme.Text }):Play()
end

-- ─── FARM ───
AddToggle(FarmTab.Container, "Auto Chop Tree", false, function(v) Config.AutoChop = v end)
AddSlider(FarmTab.Container, "Chop Range", 10, 100, 30, function(v) Config.ChopRange = v end)
AddSlider(FarmTab.Container, "Chop Speed", 0.05, 1, 0.1, function(v) Config.ChopSpeed = v end)

AddToggle(FarmTab.Container, "Auto Collect Wood", false, function(v) Config.AutoCollect = v end)
AddSlider(FarmTab.Container, "Collect Range", 20, 300, 100, function(v) Config.CollectRange = v end)

AddToggle(FarmTab.Container, "Auto Sell Wood", false, function(v) Config.AutoSell = v end)
AddSlider(FarmTab.Container, "Sell Range", 100, 2000, 500, function(v) Config.SellRange = v end)

AddLabel(FarmTab.Container, "─── Status ───", Theme.Accent)
local StatusLabel = AddLabel(FarmTab.Container, "Idle", Theme.SubText)

-- ─── ESP ───
AddToggle(ESPTab.Container, "Tree ESP", false, function(v)
    Config.TreeESP = v
    if not v then ClearESP("Tree") end
end)
AddToggle(ESPTab.Container, "Player ESP", false, function(v)
    Config.PlayerESP = v
    if not v then ClearESP("Player") end
end)
AddToggle(ESPTab.Container, "Wood ESP", false, function(v)
    Config.WoodESP = v
    if not v then ClearESP("Wood") end
end)
AddButton(ESPTab.Container, "Clear All ESP", function()
    ClearESP("Tree")
    ClearESP("Player")
    ClearESP("Wood")
end)

-- ─── PLAYER ───
AddSlider(PlayerTab.Container, "WalkSpeed", 16, 300, 16, function(v)
    Config.WalkSpeed = v
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = v end
end)
AddSlider(PlayerTab.Container, "JumpPower", 50, 300, 50, function(v)
    Config.JumpPower = v
    local hum = GetHumanoid()
    if hum then
        hum.JumpPower = v
        hum.UseJumpPower = true
    end
end)
AddToggle(PlayerTab.Container, "Infinite Jump", false, function(v) Config.InfiniteJump = v end)
AddToggle(PlayerTab.Container, "Anti-AFK", true, function(v) Config.AntiAFK = v end)
AddToggle(PlayerTab.Container, "Fly", false, function(v) Config.Fly = v end)
AddSlider(PlayerTab.Container, "Fly Speed", 20, 200, 50, function(v) Config.FlySpeed = v end)
AddToggle(PlayerTab.Container, "Noclip", false, function(v) Config.Noclip = v end)
AddToggle(PlayerTab.Container, "Fullbright", false, function(v)
    Config.Fullbright = v
    if v then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
    end
end)

-- ─── TELEPORT ───
AddButton(TeleportTab.Container, "Teleport to Spawn", function()
    local root = GetRoot()
    if root then root.CFrame = CFrame.new(0, 10, 0) end
end)
AddButton(TeleportTab.Container, "Teleport to Sawmill", function()
    local sawmill = GetSawmillPosition()
    if sawmill then
        local root = GetRoot()
        if root then root.CFrame = CFrame.new(sawmill + Vector3.new(0, 5, 0)) end
    end
end)
AddButton(TeleportTab.Container, "Teleport to Shop", function()
    local shop = GetShopPosition()
    if shop then
        local root = GetRoot()
        if root then root.CFrame = CFrame.new(shop + Vector3.new(0, 5, 0)) end
    end
end)

AddLabel(TeleportTab.Container, "─── Players ───", Theme.Accent)
local playerListFrame = Create("Frame", {
    Parent = TeleportTab.Container,
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundTransparency = 1,
})
Create("UIListLayout", { Parent = playerListFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })

local function RefreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            AddButton(playerListFrame, plr.Name, function()
                local target = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                local root = GetRoot()
                if target and root then
                    root.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                end
            end)
        end
    end
end

Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    RefreshPlayerList()
end)

-- ─── MISC ───
AddButton(MiscTab.Container, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
AddButton(MiscTab.Container, "Server Hop", function()
    local servers = {}
    pcall(function()
        local req = http_request or request or (syn and syn.request)
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
    end
end)

AddLabel(MiscTab.Container, "─── Info ───", Theme.Accent)
AddLabel(MiscTab.Container, "Xyro Hub | Lumber Tycoon 2", Theme.SubText)
AddLabel(MiscTab.Container, "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"), Theme.SubText)

-- Toggle on float button click
FloatBtn.MouseButton1Click:Connect(function()
    if btnDragging then return end
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        task.wait(0.05)
        RefreshPlayerList()
    end
end)

-- ═══════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════
local ESPObjects = {}

function ClearESP(typeFilter)
    for instance, obj in pairs(ESPObjects) do
        if typeFilter then
            if obj.Type == typeFilter then
                pcall(function() obj.Highlight:Destroy() end)
                pcall(function() obj.Billboard:Destroy() end)
                ESPObjects[instance] = nil
            end
        else
            pcall(function() obj.Highlight:Destroy() end)
            pcall(function() obj.Billboard:Destroy() end)
        end
    end
    if not typeFilter then ESPObjects = {} end
end

local function CreateESP(instance, color, label, type)
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
        Size = UDim2.new(0, 120, 0, 20),
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        Name = "XyroESP",
    })
    Create("TextLabel", {
        Parent = billboard,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = color,
        TextStrokeTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    })
    ESPObjects[instance] = { Highlight = highlight, Billboard = billboard, Type = type }
end

-- ═══════════════════════════════════════════════════
-- CHARACTER SETUP
-- ═══════════════════════════════════════════════════
local function OnCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.WalkSpeed = Config.WalkSpeed
        hum.JumpPower = Config.JumpPower
        hum.UseJumpPower = true
    end
end

if LocalPlayer.Character then OnCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(OnCharacter)

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ═══════════════════════════════════════════════════
-- GAME HELPERS
-- ═══════════════════════════════════════════════════
local function FindTrees()
    local trees = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("tree") or n:find("wood") or n:find("log") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(trees, { Instance = obj, Part = part })
                end
            end
        end
    end
    return trees
end

local function FindWoodParts()
    local wood = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("wood") or n:find("plank") or n:find("log") or n:find("lumber") then
                table.insert(wood, obj)
            end
        end
    end
    return wood
end

local function GetSawmillPosition()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("sawmill") or n:find("mill") or n:find("saw") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then return part.Position end
            end
        end
    end
    return nil
end

local function GetShopPosition()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("shop") or n:find("store") or n:find("market") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then return part.Position end
            end
        end
    end
    return nil
end

local function TryChop(targetPart)
    local char = GetChar()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    pcall(function()
        tool:Activate()
    end)

    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            pcall(function()
                child:FireServer()
            end)
        end
    end

    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            pcall(function()
                child:FireServer(targetPart)
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════
-- AUTO CHOP
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(Config.ChopSpeed) do
        if Config.AutoChop then
            local root = GetRoot()
            if not root then continue end

            local trees = FindTrees()
            local nearest = nil
            local nearestDist = Config.ChopRange

            for _, t in ipairs(trees) do
                local dist = (t.Part.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = t
                end
            end

            if nearest then
                pcall(function()
                    root.CFrame = CFrame.new(nearest.Part.Position + Vector3.new(0, 4, 0))
                end)
                task.wait(0.05)
                TryChop(nearest.Part)
                StatusLabel.Text = "Chopping: " .. nearest.Instance.Name
            else
                StatusLabel.Text = "No trees in range"
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- AUTO COLLECT WOOD
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoCollect then
            local root = GetRoot()
            if not root then continue end
            local wood = FindWoodParts()
            for _, w in ipairs(wood) do
                if w ~= root and w.Parent ~= GetChar() then
                    local dist = (w.Position - root.Position).Magnitude
                    if dist < Config.CollectRange then
                        pcall(function()
                            w.CFrame = root.CFrame
                        end)
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- AUTO SELL
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1) do
        if Config.AutoSell then
            local root = GetRoot()
            if not root then continue end
            local sawmill = GetSawmillPosition()
            if sawmill then
                local dist = (root.Position - sawmill).Magnitude
                if dist > 20 then
                    pcall(function()
                        root.CFrame = CFrame.new(sawmill + Vector3.new(0, 5, 0))
                    end)
                    StatusLabel.Text = "Selling at sawmill..."
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════════════
local flyBodyVel
local flyBodyGyro
local flyConnection

local function StartFly()
    local char = GetChar()
    local root = GetRoot()
    if not char or not root then return end
    local hum = GetHumanoid()
    if hum then hum.PlatformStand = true end

    flyBodyVel = Create("BodyVelocity", { Parent = root, MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.new(0, 0, 0), P = 1250 })
    flyBodyGyro = Create("BodyGyro", { Parent = root, MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 1250, CFrame = root.CFrame })

    flyConnection = RunService.RenderStepped:Connect(function()
        if not Config.Fly then return end
        local cam = Camera.CFrame
        local move = Vector3.new(0, 0, 0)
        local r = GetRoot()
        if not r then return end

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0, -1, 0) end

        if move.Magnitude > 0 then
            flyBodyVel.Velocity = move.Unit * Config.FlySpeed
        else
            flyBodyVel.Velocity = Vector3.new(0, 0, 0)
        end
        flyBodyGyro.CFrame = cam
    end)
end

local function StopFly()
    if flyConnection then flyConnection:Disconnect() end
    if flyBodyVel then flyBodyVel:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    local hum = GetHumanoid()
    if hum then hum.PlatformStand = false end
end

task.spawn(function()
    while task.wait(0.2) do
        if Config.Fly and not flyBodyVel then
            StartFly()
        elseif not Config.Fly and flyBodyVel then
            StopFly()
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = GetChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- ESP LOOP
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1) do
        if Config.TreeESP then
            local trees = FindTrees()
            for _, t in ipairs(trees) do
                if not ESPObjects[t.Instance] then
                    CreateESP(t.Instance, Color3.fromRGB(80, 200, 80), t.Instance.Name, "Tree")
                end
            end
        end

        if Config.PlayerESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not ESPObjects[plr.Character] then
                        CreateESP(plr.Character, Color3.fromRGB(80, 200, 255), plr.Name, "Player")
                    end
                end
            end
        end

        if Config.WoodESP then
            local wood = FindWoodParts()
            for _, w in ipairs(wood) do
                if not ESPObjects[w] then
                    CreateESP(w, Color3.fromRGB(255, 200, 50), w.Name, "Wood")
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- HOTKEY
-- ═══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            task.wait(0.05)
            RefreshPlayerList()
        end
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
        ZIndex = 200,
    })
    Create("UICorner", { Parent = notif, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = notif, Color = Theme.Accent, Thickness = 1 })

    Create("TextLabel", {
        Parent = notif, Text = title,
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
    })
    Create("TextLabel", {
        Parent = notif, Text = text,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
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

Notify("Xyro Hub", "Lumber Tycoon 2 loaded. Click floating X button.")

print("[Xyro Hub] Lumber Tycoon 2 — Loaded")