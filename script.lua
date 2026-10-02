-- ==========================================
-- STEAL AN EGG - ULTIMATE V6 (FLY + GODMODE)
-- Author: Người Đẹp Trai (@tpmodz)
-- Channel: @tpmodz
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============ CONFIG ============
local Config = {
    AutoSteal = true,
    AutoCollect = true,
    ESP = true,
    SpeedHack = true,
    SpeedValue = 120,
    FlyHack = false,
    FlySpeed = 80,
    GodMode = true,
    TeleportToEggs = true,
    TeleportDelay = 0.2,
    NotifyOnSteal = true,
}

-- ============ NOTIFY ============
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3,
        })
    end)
end

Notify("💀 DEVILS WILL RISE 💀", "V6 Loaded - @tpmodz", 5)

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

-- ==========================================
-- GODMODE (BẤT TỬ)
-- ==========================================
local function ApplyGodMode()
    local char = GetChar()
    local hum = GetHum()
    if not char or not hum then return end

    -- Bật MaxHealth vô hạn
    hum.MaxHealth = math.huge
    hum.Health = math.huge

    -- Vô hiệu hóa damage qua Humanoid
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    -- Bảo vệ bằng ForceField
    if not char:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end

    -- Chặn mọi sát thương qua thuộc tính Health
    local conn
    conn = hum.HealthChanged:Connect(function(h)
        if Config.GodMode then
            hum.Health = math.huge
        end
    end)

    -- Chặn death event
    hum.Died:Connect(function()
        if Config.GodMode then
            task.wait(0.1)
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    h.Health = math.huge
                    h.MaxHealth = math.huge
                end
            end
        end
    end)
end

-- Áp dụng godmode mỗi khi respawn
local function SetupGodMode()
    if Config.GodMode then
        ApplyGodMode()
    end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config.GodMode then
            ApplyGodMode()
        end
    end)
end

SetupGodMode()

-- Loop giữ bất tử
task.spawn(function()
    while task.wait(0.5) do
        if Config.GodMode then
            local hum = GetHum()
            if hum then
                if hum.Health < hum.MaxHealth or hum.Health <= 0 then
                    hum.MaxHealth = math.huge
                    hum.Health = math.huge
                end
            end
        end
    end
end)

-- ==========================================
-- FLY HACK
-- ==========================================
local FlyConnection = nil

local function EnableFly()
    if FlyConnection then return end

    local char = GetChar()
    local hrp = GetRoot()
    local hum = GetHum()
    if not hrp or not hum then return end

    -- Tạo BodyVelocity + BodyGyro
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    hum.PlatformStand = true

    local keys = {}
    UserInputService.InputBegan:Connect(function(i, g)
        if not g then keys[i.KeyCode] = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        keys[i.KeyCode] = false
    end)

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Config.FlyHack then return end
        local hrp2 = GetRoot()
        if not hrp2 then return end
        local bv2 = hrp2:FindFirstChild("FlyBV")
        local bg2 = hrp2:FindFirstChild("FlyBG")
        if not bv2 or not bg2 then return end

        local move = Vector3.zero
        if keys[Enum.KeyCode.W] then move += Camera.CFrame.LookVector end
        if keys[Enum.KeyCode.S] then move -= Camera.CFrame.LookVector end
        if keys[Enum.KeyCode.A] then move -= Camera.CFrame.RightVector end
        if keys[Enum.KeyCode.D] then move += Camera.CFrame.RightVector end
        if keys[Enum.KeyCode.Space] then move += Vector3.new(0, 1, 0) end
        if keys[Enum.KeyCode.LeftControl] then move -= Vector3.new(0, 1, 0) end

        bv2.Velocity = move * Config.FlySpeed
        bg2.CFrame = Camera.CFrame
    end)
end

local function DisableFly()
    Config.FlyHack = false
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    local hrp = GetRoot()
    if hrp then
        local bv = hrp:FindFirstChild("FlyBV"); if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("FlyBG"); if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

local function ToggleFly()
    Config.FlyHack = not Config.FlyHack
    if Config.FlyHack then
        EnableFly()
        Notify("✈️ FLY", "ON", 2)
    else
        DisableFly()
        Notify("✈️ FLY", "OFF", 2)
    end
end

-- Nếu bật sẵn từ config
if Config.FlyHack then
    EnableFly()
end

-- ==========================================
-- SPEED HACK
-- ==========================================
if Config.SpeedHack then
    local function ApplySpeed()
        local hum = GetHum()
        if hum then
            hum.WalkSpeed = Config.SpeedValue
            hum.JumpPower = 100
            hum.UseJumpPower = true
        end
    end
    ApplySpeed()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        ApplySpeed()
    end)
end

-- ==========================================
-- AUTO STEAL EGG
-- ==========================================
local function GetEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if (obj:IsA("BasePart") or obj:IsA("Model"))
            and (n:find("egg") or n:find("trung")) then
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

local function TeleportTo(pos)
    local hrp = GetRoot()
    if hrp and pos then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end
end

task.spawn(function()
    while task.wait(Config.TeleportDelay) do
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
                TeleportTo(GetPos(closest))
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

            if Config.NotifyOnSteal then
                Notify("🥚 STEAL", closest.Name, 1)
            end
        end
    end
end)

-- ==========================================
-- ESP TRỨNG
-- ==========================================
if Config.ESP then
    task.spawn(function()
        while task.wait(2) do
            if not Config.ESP then continue end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local n = string.lower(obj.Name)
                if (obj:IsA("BasePart") or obj:IsA("Model"))
                    and (n:find("egg") or n:find("trung"))
                    and not obj:FindFirstChild("EggESP_Label") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "EggESP_Label"
                    bb.Size = UDim2.new(0, 200, 0, 50)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.Parent = obj

                    local lb = Instance.new("TextLabel")
                    lb.Size = UDim2.new(1, 0, 1, 0)
                    lb.BackgroundTransparency = 1
                    lb.Text = "🥚 " .. obj.Name
                    lb.TextColor3 = Color3.fromRGB(0, 255, 0)
                    lb.TextStrokeTransparency = 0
                    lb.TextScaled = true
                    lb.Parent = bb
                end
            end
        end
    end)
end

-- ==========================================
-- ANTI AFK
-- ==========================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ==========================================
-- PHÍM TẮT
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local k = input.KeyCode

    if k == Enum.KeyCode.F then
        ToggleFly()
    elseif k == Enum.KeyCode.G then
        Config.GodMode = not Config.GodMode
        if Config.GodMode then
            ApplyGodMode()
            Notify("🛡️ GODMODE", "ON", 2)
        else
            Notify("🛡️ GODMODE", "OFF", 2)
        end
    elseif k == Enum.KeyCode.T then
        Config.TeleportToEggs = not Config.TeleportToEggs
        Notify("📍 TELEPORT", Config.TeleportToEggs and "ON" or "OFF", 2)
    elseif k == Enum.KeyCode.E then
        Config.ESP = not Config.ESP
        Notify("👁️ ESP", Config.ESP and "ON" or "OFF", 2)
    elseif k == Enum.KeyCode.H then
        Config.AutoSteal = not Config.AutoSteal
        Notify("🥚 AUTO STEAL", Config.AutoSteal and "ON" or "OFF", 2)
    end
end)

Notify("💀 READY", "F=Fly | G=God | T=TP | E=ESP | H=Steal", 6)
print("[DEVILS WILL RISE] Steal An Egg Ultimate V6 - @tpmodz")
