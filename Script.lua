-- ==========================================
-- STEAL AN EGG - MENU UI V7
-- Author: Người Đẹp Trai (@tpmodz)
-- UI: Rayfield
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============ CONFIG ============
local Config = {
    AutoSteal = false,
    AutoCollect = false,
    ESP = false,
    SpeedHack = false,
    SpeedValue = 120,
    FlyHack = false,
    FlySpeed = 80,
    GodMode = false,
    TeleportToEggs = true,
}

-- ============ HELPERS ============
local function GetChar(plr)
    plr = plr or LocalPlayer
    return plr.Character or plr.CharacterAdded:Wait()
end
local function GetHum(plr)
    local c = GetChar(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetRoot(plr)
    local c = GetChar(plr)
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============ GODMODE ============
local function ApplyGodMode()
    local char = GetChar()
    local hum = GetHum()
    if not char or not hum then return end
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    if not char:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end
    hum.HealthChanged:Connect(function()
        if Config.GodMode then hum.Health = math.huge end
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        if Config.GodMode then
            local hum = GetHum()
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
        end
    end
end)

-- ============ FLY ============
local FlyConn = nil
local function EnableFly()
    if FlyConn then return end
    local hrp = GetRoot()
    local hum = GetHum()
    if not hrp or not hum then return end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBG"
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    hum.PlatformStand = true

    local keys = {}
    UserInputService.InputBegan:Connect(function(i,g) if not g then keys[i.KeyCode]=true end end)
    UserInputService.InputEnded:Connect(function(i) keys[i.KeyCode]=false end)

    FlyConn = RunService.RenderStepped:Connect(function()
        if not Config.FlyHack then return end
        local h = GetRoot()
        if not h then return end
        local bv2 = h:FindFirstChild("FlyBV")
        local bg2 = h:FindFirstChild("FlyBG")
        if not bv2 or not bg2 then return end
        local move = Vector3.zero
        if keys[Enum.KeyCode.W] then move += Camera.CFrame.LookVector end
        if keys[Enum.KeyCode.S] then move -= Camera.CFrame.LookVector end
        if keys[Enum.KeyCode.A] then move -= Camera.CFrame.RightVector end
        if keys[Enum.KeyCode.D] then move += Camera.CFrame.RightVector end
        if keys[Enum.KeyCode.Space] then move += Vector3.new(0,1,0) end
        if keys[Enum.KeyCode.LeftControl] then move -= Vector3.new(0,1,0) end
        bv2.Velocity = move * Config.FlySpeed
        bg2.CFrame = Camera.CFrame
    end)
end

local function DisableFly()
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    local hrp = GetRoot()
    if hrp then
        local bv = hrp:FindFirstChild("FlyBV"); if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("FlyBG"); if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

-- ============ AUTO STEAL ============
local function GetEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if (obj:IsA("BasePart") or obj:IsA("Model")) and (n:find("egg") or n:find("trung")) then
            table.insert(eggs, obj)
        end
    end
    return eggs
end
local function GetPos(obj)
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return p and p.Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
end

task.spawn(function()
    while task.wait(0.2) do
        if not Config.AutoSteal then continue end
        local hrp = GetRoot()
        if not hrp then continue end
        local eggs = GetEggs()
        local closest, cd = nil, math.huge
        for _, egg in ipairs(eggs) do
            local p = GetPos(egg)
            if p then
                local d = (p - hrp.Position).Magnitude
                if d < cd then closest, cd = egg, d end
            end
        end
        if closest and cd < 500 then
            if Config.TeleportToEggs then
                hrp.CFrame = CFrame.new(GetPos(closest) + Vector3.new(0,5,0))
            end
            pcall(function()
                local remote = ReplicatedStorage:FindFirstChild("StealEgg")
                    or ReplicatedStorage:FindFirstChild("Steal")
                    or ReplicatedStorage:FindFirstChild("CollectEgg")
                    or ReplicatedStorage:FindFirstChild("Pickup")
                if remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(closest)
                elseif remote and remote:IsA("RemoteFunction") then
                    remote:InvokeServer(closest)
                end
            end)
        end
    end
end)

-- ============ ESP ============
task.spawn(function()
    while task.wait(2) do
        if not Config.ESP then continue end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if (obj:IsA("BasePart") or obj:IsA("Model")) and (n:find("egg") or n:find("trung"))
                and not obj:FindFirstChild("EggESP_Label") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "EggESP_Label"
                bb.Size = UDim2.new(0,200,0,50)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0,3,0)
                bb.Parent = obj
                local lb = Instance.new("TextLabel")
                lb.Size = UDim2.new(1,0,1,0)
                lb.BackgroundTransparency = 1
                lb.Text = "🥚 " .. obj.Name
                lb.TextColor3 = Color3.fromRGB(0,255,0)
                lb.TextStrokeTransparency = 0
                lb.TextScaled = true
                lb.Parent = bb
            end
        end
    end
end)

-- ============ ANTI AFK ============
LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- ==========================================
-- MENU UI (RAYFIELD)
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "💀 DEVILS WILL RISE",
    LoadingTitle = "Đang load menu...",
    LoadingSubtitle = "by @tpmodz",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DevilsHub",
        FileName = "StealEggV7"
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ============ TAB FARM ============
local FarmTab = Window:CreateTab("Farm", 4483362458)

FarmTab:CreateToggle({
    Name = "Auto Steal Egg",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v)
        Config.AutoSteal = v
    end,
})

FarmTab:CreateToggle({
    Name = "Teleport đến trứng",
    CurrentValue = true,
    Flag = "TPEggs",
    Callback = function(v)
        Config.TeleportToEggs = v
    end,
})

FarmTab:CreateToggle({
    Name = "ESP Trứng",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        Config.ESP = v
        if not v then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local e = obj:FindFirstChild("EggESP_Label")
                if e then e:Destroy() end
            end
        end
    end,
})

-- ============ TAB PLAYER ============
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateToggle({
    Name = "Godmode (Bất tử)",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        Config.GodMode = v
        if v then ApplyGodMode() end
    end,
})

PlayerTab:CreateToggle({
    Name = "Fly Hack",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        Config.FlyHack = v
        if v then EnableFly() else DisableFly() end
    end,
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 10,
    Suffix = "studs/s",
    CurrentValue = 80,
    Flag = "FlySpeed",
    Callback = function(v)
        Config.FlySpeed = v
    end,
})

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "Speed",
    Callback = function(v)
        Config.SpeedHack = v
        local hum = GetHum()
        if hum then
            hum.WalkSpeed = v and Config.SpeedValue or 16
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 500},
    Increment = 4,
    Suffix = "studs",
    CurrentValue = 120,
    Flag = "SpeedValue",
    Callback = function(v)
        Config.SpeedValue = v
        if Config.SpeedHack then
            local hum = GetHum()
            if hum then hum.WalkSpeed = v end
        end
    end,
})

-- ============ TAB MISC ============
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateButton({
    Name = "Teleport về Spawn",
    Callback = function()
        local hrp = GetRoot()
        if hrp then
            hrp.CFrame = CFrame.new(0, 100, 0)
        end
    end,
})

MiscTab:CreateButton({
    Name = "Đóng Menu",
    Callback = function()
        Rayfield:Destroy()
    end,
})

Rayfield:Notify({
    Title = "💀 DEVILS WILL RISE",
    Content = "Menu đã load - by @tpmodz",
    Duration = 5,
})

print("[DEVILS WILL RISE] Menu V7 - @tpmodz")
