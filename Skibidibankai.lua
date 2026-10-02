-- ==========================================
-- STEAL AN EGG V7 - CÓ MENU MOBILE
-- Author: @tpmodz
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    AutoSteal = true,
    ESP = true,
    SpeedHack = true,
    SpeedValue = 120,
    FlyHack = false,
    FlySpeed = 80,
    GodMode = true,
    TeleportToEggs = true,
    TeleportDelay = 0.2,
}

local function Notify(t, x, d)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=x, Duration=d or 3})
    end)
end

local function GetChar(p)
    p = p or LocalPlayer
    return p.Character or p.CharacterAdded:Wait()
end
local function GetHum(p)
    local c = GetChar(p); return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetRoot(p)
    local c = GetChar(p); return c and c:FindFirstChild("HumanoidRootPart")
end

-- ========== GODMODE ==========
local function ApplyGodMode()
    local char, hum = GetChar(), GetHum()
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
    hum.Died:Connect(function()
        if Config.GodMode then
            task.wait(0.1)
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.Health = math.huge; h.MaxHealth = math.huge end
            end
        end
    end)
end

if Config.GodMode then ApplyGodMode() end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Config.GodMode then ApplyGodMode() end
end)
task.spawn(function()
    while task.wait(0.5) do
        if Config.GodMode then
            local hum = GetHum()
            if hum and (hum.Health < hum.MaxHealth or hum.Health <= 0) then
                hum.MaxHealth = math.huge; hum.Health = math.huge
            end
        end
    end
end)

-- ========== FLY ==========
local FlyConn = nil
local flyKeys = {}

local function EnableFly()
    if FlyConn then return end
    local hrp, hum = GetRoot(), GetHum()
    if not hrp or not hum then return end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"; bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.zero; bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBG"; bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4; bg.CFrame = hrp.CFrame; bg.Parent = hrp

    hum.PlatformStand = true

    UserInputService.InputBegan:Connect(function(i,g)
        if not g then flyKeys[i.KeyCode] = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        flyKeys[i.KeyCode] = false
    end)

    FlyConn = RunService.RenderStepped:Connect(function()
        if not Config.FlyHack then return end
        local hrp2 = GetRoot()
        if not hrp2 then return end
        local bv2 = hrp2:FindFirstChild("FlyBV")
        local bg2 = hrp2:FindFirstChild("FlyBG")
        if not bv2 or not bg2 then return end
        local move = Vector3.zero
        if flyKeys[Enum.KeyCode.W] then move += Camera.CFrame.LookVector end
        if flyKeys[Enum.KeyCode.S] then move -= Camera.CFrame.LookVector end
        if flyKeys[Enum.KeyCode.A] then move -= Camera.CFrame.RightVector end
        if flyKeys[Enum.KeyCode.D] then move += Camera.CFrame.RightVector end
        if flyKeys[Enum.KeyCode.Space] then move += Vector3.new(0,1,0) end
        if flyKeys[Enum.KeyCode.LeftControl] then move -= Vector3.new(0,1,0) end
        bv2.Velocity = move * Config.FlySpeed
        bg2.CFrame = Camera.CFrame
    end)
end

local function DisableFly()
    Config.FlyHack = false
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    local hrp = GetRoot()
    if hrp then
        local bv = hrp:FindFirstChild("FlyBV"); if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("FlyBG"); if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

-- ========== SPEED ==========
local function ApplySpeed()
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = Config.SpeedValue
        hum.JumpPower = 100
        hum.UseJumpPower = true
    end
end
if Config.SpeedHack then
    ApplySpeed()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); if Config.SpeedHack then ApplySpeed() end
    end)
end

-- ========== AUTO STEAL ==========
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
    elseif obj:IsA("BasePart") then return obj.Position end
end
local function TeleportTo(pos)
    local hrp = GetRoot()
    if hrp and pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0)) end
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
            if Config.TeleportToEggs then TeleportTo(GetPos(closest)) end
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

-- ========== ESP ==========
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
end

-- ========== ANTI AFK ==========
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ==========================================
-- MENU NÚT BẤM TRÊN MÀN HÌNH
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "DevilsMenu"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Nút mở/đóng menu
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(0, 60, 0, 60)
Toggle.Position = UDim2.new(0, 20, 0.5, -30)
Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Toggle.Text = "💀"
Toggle.TextSize = 30
Toggle.TextColor3 = Color3.fromRGB(255,255,255)
Toggle.Parent = gui

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(1, 0)
TCorner.Parent = Toggle

local TStroke = Instance.new("UIStroke")
TStroke.Color = Color3.fromRGB(200, 50, 50)
TStroke.Thickness = 2
TStroke.Parent = Toggle

-- Khung menu
local Menu = Instance.new("Frame")
Menu.Size = UDim2.new(0, 220, 0, 380)
Menu.Position = UDim2.new(0, 90, 0.5, -190)
Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Menu.Visible = false
Menu.Parent = gui

local MCorner = Instance.new("UICorner")
MCorner.CornerRadius = UDim.new(0, 10)
MCorner.Parent = Menu

local MStroke = Instance.new("UIStroke")
MStroke.Color = Color3.fromRGB(200, 50, 50)
MStroke.Thickness = 2
MStroke.Parent = Menu

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.Text = "💀 DEVILS MENU"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Menu

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Hàm tạo nút
local function MakeBtn(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = Menu

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local statusGod = MakeBtn("🛡️ Godmode: ON", 50, Color3.fromRGB(76,175,92), function(self)
    Config.GodMode = not Config.GodMode
    if Config.GodMode then ApplyGodMode() end
    self.Text = "🛡️ Godmode: " .. (Config.GodMode and "ON" or "OFF")
    self.BackgroundColor3 = Config.GodMode and Color3.fromRGB(76,175,92) or Color3.fromRGB(120,50,50)
end)

local statusFly = MakeBtn("✈️ Fly: OFF", 100, Color3.fromRGB(120,50,50), function(self)
    Config.FlyHack = not Config.FlyHack
    if Config.FlyHack then EnableFly() else DisableFly() end
    self.Text = "✈️ Fly: " .. (Config.FlyHack and "ON" or "OFF")
    self.BackgroundColor3 = Config.FlyHack and Color3.fromRGB(76,175,92) or Color3.fromRGB(120,50,50)
end)

local statusSteal = MakeBtn("🥚 Auto Steal: ON", 150, Color3.fromRGB(76,175,92), function(self)
    Config.AutoSteal = not Config.AutoSteal
    self.Text = "🥚 Auto Steal: " .. (Config.AutoSteal and "ON" or "OFF")
    self.BackgroundColor3 = Config.AutoSteal and Color3.fromRGB(76,175,92) or Color3.fromRGB(120,50,50)
end)

local statusTP = MakeBtn("📍 Teleport Egg: ON", 200, Color3.fromRGB(76,175,92), function(self)
    Config.TeleportToEggs = not Config.TeleportToEggs
    self.Text = "📍 Teleport Egg: " .. (Config.TeleportToEggs and "ON" or "OFF")
    self.BackgroundColor3 = Config.TeleportToEggs and Color3.fromRGB(76,175,92) or Color3.fromRGB(120,50,50)
end)

local statusESP = MakeBtn("👁️ ESP Trứng: ON", 250, Color3.fromRGB(76,175,92), function(self)
    Config.ESP = not Config.ESP
    self.Text = "👁️ ESP Trứng: " .. (Config.ESP and "ON" or "OFF")
    self.BackgroundColor3 = Config.ESP and Color3.fromRGB(76,175,92) or Color3.fromRGB(120,50,50)
end)

local statusSpeed = MakeBtn("⚡ Speed: 120", 300, Color3.fromRGB(76,175,92), function(self)
    Config.SpeedHack = not Config.SpeedHack
    if Config.SpeedHack then
        Config.SpeedValue = 120
        ApplySpeed()
        self.Text = "⚡ Speed: 120"
        self.BackgroundColor3 = Color3.fromRGB(76,175,92)
    else
        Config.SpeedValue = 16
        ApplySpeed()
        self.Text = "⚡ Speed: OFF"
        self.BackgroundColor3 = Color3.fromRGB(120,50,50)
    end
end)

local closeBtn = MakeBtn("❌ Đóng Menu", 350 - 45, Color3.fromRGB(200,50,50), function()
    Menu.Visible = false
end)

-- Xử lý kéo thả menu
local dragging = false
local dragStart, startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Menu.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Menu.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Nút 💀 mở/đóng menu
Toggle.MouseButton1Click:Connect(function()
    Menu.Visible = not Menu.Visible
end)

Notify("💀 DEVILS MENU", "Menu đã load - bấm nút 💀", 5)
print("[DEVILS WILL RISE] V7 Mobile Menu - @tpmodz")
