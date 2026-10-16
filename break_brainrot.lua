--[[
    ╔══════════════════════════════════════════╗
    ║    XYRO HUB — Break a Brainrot Egg!      ║
    ║         v1.0.0 | Keyless | Safe          ║
    ╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    Enabled = {
        AutoEgg = false,
        AutoPlace = false,
        AutoHatch = false,
        EquipBest = false,
    },
    SelectedZone = "Forest",
    Zones = { "Forest", "Desert", "Snow", "Jungle", "Volcano", "Ocean" },
    Remotes = {},
    Threads = {},
    Connections = {},
    AntiAFKEnabled = true,
}

-- ═══════════════════════════════════════════
-- UTIL
-- ═══════════════════════════════════════════
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Xyro Hub",
            Text = text or "",
            Duration = dur or 3,
        })
    end)
end

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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
-- ANTI-AFK (Built-in biar gak kena kick idle)
-- ═══════════════════════════════════════════
local function startAntiAFK()
    table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
        if State.AntiAFKEnabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end))
end

-- ═══════════════════════════════════════════
-- FEATURE LOGIC
-- ═══════════════════════════════════════════

local function startAutoEgg()
    table.insert(State.Threads, task.spawn(function()
        while State.Enabled.AutoEgg do
            pcall(function()
                local remote = findRemote("egg") or findRemote("collect") or findRemote("grab") or findRemote("break")
                if remote then
                    remote:FireServer(State.SelectedZone)
                else
                    -- Fallback: touch eggs di sekitar
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                                if (obj.Position - hrp.Position).Magnitude < 20 then
                                    firetouchinterest(hrp, obj, 0)
                                    firetouchinterest(hrp, obj, 1)
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.4)
        end
    end))
end

local function startAutoPlace()
    table.insert(State.Threads, task.spawn(function()
        while State.Enabled.AutoPlace do
            pcall(function()
                local remote = findRemote("place") or findRemote("drop")
                if remote then
                    remote:FireServer()
                end
            end)
            task.wait(1)
        end
    end))
end

local function startAutoHatch()
    table.insert(State.Threads, task.spawn(function()
        while State.Enabled.AutoHatch do
            pcall(function()
                local remote = findRemote("hatch") or findRemote("open") or findRemote("unbox")
                if remote then
                    remote:FireServer()
                end
            end)
            task.wait(1.5)
        end
    end))
end

local function startEquipBest()
    table.insert(State.Threads, task.spawn(function()
        while State.Enabled.EquipBest do
            pcall(function()
                local remote = findRemote("equipbest") or findRemote("equip") or findRemote("best")
                if remote then
                    remote:FireServer()
                end
            end)
            task.wait(3)
        end
    end))
end

-- ═══════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════

local COLORS = {
    Border = Color3.fromRGB(60, 120, 230),
    Background = Color3.fromRGB(20, 22, 30),
    RowBg = Color3.fromRGB(35, 38, 48),
    RowHover = Color3.fromRGB(45, 48, 58),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 190),
    Yellow = Color3.fromRGB(255, 220, 50),
    ToggleOff = Color3.fromRGB(60, 63, 75),
    ToggleOn = Color3.fromRGB(80, 200, 120),
    Accent = Color3.fromRGB(80, 180, 255),
}

local function buildGUI()
    local screenGui = create("ScreenGui", {
        Name = "XyroBreakBrainrotEgg",
        ResetOnSpawn = false,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
    })

    -- Main card
    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 300, 0, 380),
        Position = UDim2.new(0, 60, 0, 100),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        Parent = screenGui,
    })
    addCorner(main, 12)
    addStroke(main, COLORS.Border, 2)

    -- Title (2 baris)
    create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 24),
        Position = UDim2.new(0, 16, 0, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = COLORS.Yellow,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "BREAK A BRAINROT",
        Parent = main,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 20),
        Position = UDim2.new(0, 16, 0, 34),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = COLORS.Yellow,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "EGG!",
        Parent = main,
    })

    -- Minimize button
    local minBtn = create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -38, 0, 12),
        BackgroundColor3 = COLORS.RowBg,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = COLORS.Text,
        Text = "—",
        AutoButtonColor = false,
        Parent = main,
    })
    addCorner(minBtn, 6)

    -- Content container
    local content = create("Frame", {
        Size = UDim2.new(1, -32, 1, -90),
        Position = UDim2.new(0, 16, 0, 66),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = content,
    })

    -- ═══════════════════════════════════════════
    -- ZONE DROPDOWN
    -- ═══════════════════════════════════════════
    local zoneRow = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = COLORS.RowBg,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "  Select Zone: " .. State.SelectedZone .. "          ▼",
        AutoButtonColor = false,
        Parent = content,
    })
    addCorner(zoneRow, 8)

    local zoneList = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = COLORS.RowBg,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        Parent = content,
    })
    addCorner(zoneList, 8)

    local listLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = zoneList,
    })

    local listOpen = false
    local zoneButtons = {}

    for i, zone in ipairs(State.Zones) do
        local zb = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = COLORS.RowBg,
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = COLORS.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "  " .. zone,
            AutoButtonColor = false,
            Parent = zoneList,
        })
        table.insert(zoneButtons, zb)

        zb.MouseEnter:Connect(function()
            zb.BackgroundColor3 = COLORS.RowHover
        end)
        zb.MouseLeave:Connect(function()
            zb.BackgroundColor3 = COLORS.RowBg
        end)

        zb.MouseButton1Click:Connect(function()
            State.SelectedZone = zone
            zoneRow.Text = "  Select Zone: " .. zone .. "          ▼"
            listOpen = false
            TweenService:Create(zoneList, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.2, function()
                zoneList.Visible = false
            end)
        end)
    end

    zoneRow.MouseButton1Click:Connect(function()
        listOpen = not listOpen
        if listOpen then
            zoneList.Visible = true
            TweenService:Create(zoneList, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, #State.Zones * 28)
            }):Play()
        else
            TweenService:Create(zoneList, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.2, function()
                zoneList.Visible = false
            end)
        end
    end)

    -- ═══════════════════════════════════════════
    -- TOGGLE ROWS
    -- ═══════════════════════════════════════════
    local toggles = {}

    local function makeToggleRow(name, key, callback)
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = COLORS.RowBg,
            BorderSizePixel = 0,
            Parent = content,
        })
        addCorner(row, 8)

        create("TextLabel", {
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = COLORS.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = name,
            Parent = row,
        })

        local toggle = create("TextButton", {
            Size = UDim2.new(0, 26, 0, 26),
            Position = UDim2.new(1, -38, 0.5, -13),
            BackgroundColor3 = COLORS.ToggleOff,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = row,
        })
        addCorner(toggle, 6)

        local check = create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = COLORS.Text,
            Text = "",
            Parent = toggle,
        })

        toggles[key] = { button = toggle, check = check }

        toggle.MouseButton1Click:Connect(function()
            State.Enabled[key] = not State.Enabled[key]
            local state = State.Enabled[key]

            TweenService:Create(toggle, TweenInfo.new(0.15), {
                BackgroundColor3 = state and COLORS.ToggleOn or COLORS.ToggleOff
            }):Play()
            check.Text = state and "✓" or ""

            if callback then callback(state) end
        end)
    end

    makeToggleRow("Auto Egg", "AutoEgg", function(v)
        if v then startAutoEgg() end
    end)

    makeToggleRow("Auto Place", "AutoPlace", function(v)
        if v then startAutoPlace() end
    end)

    makeToggleRow("Auto Hatch", "AutoHatch", function(v)
        if v then startAutoHatch() end
    end)

    makeToggleRow("Equip Best", "EquipBest", function(v)
        if v then startEquipBest() end
    end)

    -- ═══════════════════════════════════════════
    -- FOOTER — Xyro Hub
    -- ═══════════════════════════════════════════
    create("TextLabel", {
        Name = "Footer",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Color3.fromRGB(80, 200, 255),
        Text = "Xyro Hub",
        Parent = main,
    })

    -- ═══════════════════════════════════════════
    -- MINIMIZE
    -- ═══════════════════════════════════════════
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetSize = minimized and UDim2.new(0, 300, 0, 60) or UDim2.new(0, 300, 0, 380)
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Size = targetSize
        }):Play()

        content.Visible = not minimized
        main.Footer.Visible = not minimized
    end)

    return screenGui
end

-- ═══════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════
local function init()
    State.Remotes = scanRemotes()
    print("[Xyro Hub] Found " .. tostring(#State.Remotes) .. " remotes")

    buildGUI()
    startAntiAFK()
    notify("Xyro Hub", "Loaded for Break a Brainrot Egg!", 4)
end

init()