-- ==========================================
-- STEAL AN EGG - ULTIMATE V7 (ANTI-RESET)
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
    TeleportDelay = 0.1,
    NotifyOnSteal = true,
    AntiReset = true,      -- BẬT CHỐNG TELE VỀ
    GrabRadius = 30,       -- Bán kính giữ trứng
    HoldEgg = true,        -- Giữ trứng không cho rớt
}

-- ============ NOTIFY ============
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3,
        })
    end)
end

Notify("💀 DEVILS WILL RISE 💀", "V7 Anti-Reset Loaded - @tpmodz", 5)

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

local function IsEgg(obj)
    local n = string.lower(obj.Name)
    return (obj:IsA("BasePart") or obj:IsA("Model"))
        and (n:find("egg") or n:find("trung"))
end

-- ==========================================
-- GODMODE (BẤT TỬ)
-- ==========================================
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
        if Config.GodMode then
            hum.Health = math.huge
        end
    end)

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

if Config.GodMode then
    ApplyGodMode()
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Config.GodMode then ApplyGodMode() end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.GodMode then
            local hum = GetHum()
            if hum and (hum.Health < hum.MaxHealth or hum.Health <= 0) then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
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
    local hrp = GetRoot()
    local hum = GetHum()
    if not hrp or not hum then return end

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
-- 🥚 ANTI-RESET TRỨNG (PHẦN MỚI)
-- ==========================================

-- Lấy trứng từ Workspace
local function GetEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsEgg(obj) then
            table.insert(eggs, obj)
        end
    end
    return eggs
end

-- Lấy vị trí trứng (BasePart hoặc Model)
local function GetPos(obj)
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return p and p.Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
end

-- Lấy BasePart chính của trứng
local function GetEggPart(obj)
    if obj:IsA("BasePart") then
        return obj
    elseif obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
end

-- 🎯 HÀM CHỐNG TELE VỀ
local function FreezeEgg(obj)
    local part = GetEggPart(obj)
    if not part then return end

    -- 1. Chiếm network ownership
    pcall(function()
        part:SetNetworkOwner(LocalPlayer)
    end)

    -- 2. Neo cứng tại chỗ (chống server tele về)
    pcall(function()
        part.Anchored = true
    end)

    -- 3. Thêm BodyPosition giữ vị trí
    if not part:FindFirstChild("AntiReset_BP") then
        local bp = Instance.new("BodyPosition")
        bp.Name = "AntiReset_BP"
        bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bp.P = 1e6
        bp.D = 100
        bp.Position = part.Position
        bp.Parent = part
    end

    -- 4. Thêm BodyGyro chống xoay
    if not part:FindFirstChild("AntiReset_BG") then
        local bg = Instance.new("BodyGyro")
        bg.Name = "AntiReset_BG"
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P = 1e6
        bg.D = 100
        bg.Parent = part
    end

    -- 5. Xóa mọi weld/constraint từ server
    for _, c in ipairs(part:GetChildren()) do
        if c:IsA("WeldConstraint") or c:IsA("ManualWeld") or c:IsA("Weld") then
            pcall(function() c:Destroy() end)
        end
    end

    -- 6. Báo về vị trí cũ nếu bị dịch chuyển
    if not part:FindFirstChild("AntiReset_Heartbeat") then
        local hb = Instance.new("BindableEvent")
        hb.Name = "AntiReset_Heartbeat"
        hb.Parent = part
        local savedPos = part.Position
        hb.Event:Connect(function()
            if Config.AntiReset then
                if (part.Position - savedPos).Magnitude > 5 then
                    part.CFrame = CFrame.new(savedPos)
                end
            end
        end)
    end
end

-- 🎯 HÀM GỠ FREEZE
local function UnfreezeEgg(obj)
    local part = GetEggPart(obj)
    if not part then return end
    pcall(function() part.Anchored = false end)
    for _, name in ipairs({"AntiReset_BP", "AntiReset_BG", "AntiReset_Heartbeat"}) do
        local c = part:FindFirstChild(name)
        if c then c:Destroy() end
    end
end

-- 🎯 AUTO STEAL + ANTI-RESET LOOP
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
            -- Teleport đến trứng
            if Config.TeleportToEggs then
                local p = GetPos(closest)
                if p then
                    hrp.CFrame = CFrame.new(p + Vector3.new(0, 3, 0))
                end
            end

            -- Giữ trứng khỏi tele về
            if Config.AntiReset then
                FreezeEgg(closest)
            end

            -- Gọi remote để claim
            pcall(function()
                for _, name in ipairs({"StealEgg", "Steal", "CollectEgg", "Pickup", "ClaimEgg", "GrabEgg"}) do
                    local remote = ReplicatedStorage:FindFirstChild(name)
                    if not remote then
                        remote = ReplicatedStorage:FindFirstChild(name, true)
                    end
                    if remote and remote:IsA("RemoteEvent") then
                        remote:FireServer(closest)
                    elseif remote and remote:IsA("RemoteFunction") then
                        pcall(function() remote:InvokeServer(closest) end)
                    end
                end
            end)

            if Config.NotifyOnSteal then
                Notify("🥚 STEAL", closest.Name, 1)
            end
        end
    end
end)

-- 🎯 LOOP GIỮ TRỨNG GẦN MÌNH (KHÔNG TELE VỀ)
task.spawn(function()
    while task.wait(0.1) do
        if not Config.AntiReset then continue end

        local hrp = GetRoot()
        if not hrp then continue end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if IsEgg(obj) then
                local p = GetPos(obj)
                if p and (p - hrp.Position).Magnitude < Config.GrabRadius then
                    FreezeEgg(obj)
                end
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
                if IsEgg(obj) and not obj:FindFirstChild("EggESP_Label") then
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
    elseif k == Enum.KeyCode.R then
        Config.AntiReset = not Config.AntiReset
        Notify("🔒 ANTI-RESET", Config.AntiReset and "ON" or "OFF", 2)
    end
end)

Notify("💀 READY", "F=Fly | G=God | T=TP | E=ESP | H=Steal | R=AntiReset", 6)
print("[DEVILS WILL RISE] Steal An Egg V7 Anti-Reset - @tpmodz")
