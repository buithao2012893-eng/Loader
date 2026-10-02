-- ==========================================
-- DEVILS HUB V7 - USER CONTROLLED
-- Author: @tpmodz
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- CONFIG - TẤT CẢ OFF, USER TỰ BẬT
-- ==========================================
local Config = {
    AutoSteal = false,
    AutoCollect = false,
    ESP = false,
    SpeedHack = false,
    SpeedValue = 120,
    FlyHack = false,
    FlySpeed = 100,
    GodMode = false,
    TeleportToEggs = false,
    TeleportDelay = 0.2,
}

-- ==========================================
-- UI (giống hệt V7 cũ)
-- ==========================================
-- ... copy nguyên đoạn UI từ script V7 cũ vào đây ...

-- ==========================================
-- HELPERS
-- ==========================================
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
-- GODMODE
-- ==========================================
local function ApplyGodMode()
    if not Config.GodMode then return end
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
end

-- Loop check godmode - chỉ chạy khi user bật
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

-- ==========================================
-- FLY
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
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    local hrp = GetRoot()
    if hrp then
        local bv = hrp:FindFirstChild("FlyBV"); if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("FlyBG"); if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

-- Loop theo dõi fly state
task.spawn(function()
    while task.wait(0.3) do
        if Config.FlyHack and not FlyConnection then
            EnableFly()
        elseif not Config.FlyHack and FlyConnection then
            DisableFly()
        end
    end
end)

-- ==========================================
-- SPEED HACK - chỉ chạy khi user bật
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if Config.SpeedHack then
            local hum = GetHum()
            if hum then
                hum.WalkSpeed = Config.SpeedValue
                hum.JumpPower = 100
                hum.UseJumpPower = true
            end
        else
            -- user tắt -> reset về bình thường
            local hum = GetHum()
            if hum and hum.WalkSpeed ~= 16 then
                hum.WalkSpeed = 16
            end
        end
    end
end)

-- ==========================================
-- AUTO STEAL - chỉ chạy khi user bật
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
                local hrp2 = GetRoot()
                if hrp2 then hrp2.CFrame = CFrame.new(GetPos(closest) + Vector3.new(0, 5, 0)) end
            end
            pcall(function()
                local remote = ReplicatedStorage:FindFirstChild("StealEgg")
                    or ReplicatedStorage:FindFirstChild("Steal")
                    or ReplicatedStorage:FindFirstChild("CollectEgg")
                    or ReplicatedStorage:FindFirstChild("Pickup")
                if remote and remote:IsA("RemoteEvent") then remote:FireServer(closest) end
                if remote and remote:IsA("RemoteFunction") then remote:InvokeServer(closest) end
            end)
        end
    end
end)

-- ==========================================
-- ESP - chỉ chạy khi user bật
-- ==========================================
task.spawn(function()
    while task.wait(2) do
        if not Config.ESP then
            -- tắt ESP -> xóa hết label
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local e = obj:FindFirstChild("EggESP_Label")
                if e then e:Destroy() end
            end
            continue
        end
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

-- ==========================================
-- ANTI AFK
-- ==========================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

print("[DEVILS HUB V7] Loaded - @tpmodz - All features OFF by default")
