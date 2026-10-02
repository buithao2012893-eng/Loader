-- ==========================================
-- SKIBIDI TOILET V3 - SET BASE + AUTO CARRY
-- Author: @tpmodz
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============ CONFIG ============
local Config = {
    FlySpeed = 250,
    AutoThrow = true,
}

-- ============ BIẾN LƯU BASE ============
local SavedBase = nil  -- Lưu Vector3 sau khi bấm SET BASE

-- ============ HÀM HỖ TRỢ ============
local function GetChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetRoot()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3,
        })
    end)
end

-- Kiểm tra đang cầm trứng không
local function IsHoldingEgg()
    local char = LocalPlayer.Character
    if not char then return false, nil end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            local n = string.lower(obj.Name)
            if n:find("egg") or n:find("trung") then
                return true, obj
            end
        end
    end
    return false, nil
end

-- ============ BAY TỚI BASE ============
local function FlyToBase()
    if not SavedBase then
        Notify("❌ CHƯA SET BASE", "Bấm nút SET BASE trước", 3)
        return false
    end

    local hrp = GetRoot()
    local hum = GetHum()
    if not hrp or not hum then return false end

    -- Tạo BodyVelocity + BodyGyro
    local bv = Instance.new("BodyVelocity")
    bv.Name = "SkibidiBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "SkibidiBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    hum.PlatformStand = true

    -- Bay cho tới khi tới base
    local target = SavedBase
    local maxTime = 15  -- Tối đa 15 giây, tránh treo
    local t = 0

    while t < maxTime do
        local holding = IsHoldingEgg()
        if not holding then
            -- Mất trứng giữa đường → dừng
            break
        end

        local current = hrp.Position
        local dist = (target - current).Magnitude

        if dist < 5 then
            -- Đã tới base
            break
        end

        local dir = (target - current).Unit
        bv.Velocity = dir * Config.FlySpeed
        bg.CFrame = CFrame.new(current, target)

        task.wait(0.05)
        t = t + 0.05
    end

    -- Dừng bay
    bv:Destroy()
    bg:Destroy()
    hum.PlatformStand = false

    -- Thả trứng nếu có
    if Config.AutoThrow then
        local holding, tool = IsHoldingEgg()
        if holding and tool then
            -- Thả bằng cách đổi parent về Backpack
            pcall(function()
                tool.Parent = LocalPlayer.Backpack
            end)
        end
    end

    Notify("🏠 VỀ BASE", "Đã về tới base", 2)
    return true
end

-- ============ UI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkibidiUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Nút MENU
local MainBtn = Instance.new("TextButton")
MainBtn.Size = UDim2.new(0, 160, 0, 50)
MainBtn.Position = UDim2.new(0, 20, 0.5, -60)
MainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainBtn.Text = "💀 MENU"
MainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MainBtn.Font = Enum.Font.GothamBold
MainBtn.TextSize = 16
MainBtn.Parent = ScreenGui

local MC1 = Instance.new("UICorner"); MC1.CornerRadius = UDim.new(0, 10); MC1.Parent = MainBtn

-- Nút SET BASE (ẩn lúc đầu)
local SetBaseBtn = Instance.new("TextButton")
SetBaseBtn.Size = UDim2.new(0, 160, 0, 50)
SetBaseBtn.Position = UDim2.new(0, 20, 0.5, 0)
SetBaseBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
SetBaseBtn.Text = "📍 SET BASE"
SetBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetBaseBtn.Font = Enum.Font.GothamBold
SetBaseBtn.TextSize = 14
SetBaseBtn.Visible = false
SetBaseBtn.Parent = ScreenGui

local MC2 = Instance.new("UICorner"); MC2.CornerRadius = UDim.new(0, 10); MC2.Parent = SetBaseBtn

-- Nút SKIBIDI (ẩn lúc đầu)
local SkibidiBtn = Instance.new("TextButton")
SkibidiBtn.Size = UDim2.new(0, 160, 0, 50)
SkibidiBtn.Position = UDim2.new(0, 20, 0.5, 60)
SkibidiBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
SkibidiBtn.Text = "🚽 SKIBIDI TOILET"
SkibidiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkibidiBtn.Font = Enum.Font.GothamBold
SkibidiBtn.TextSize = 14
SkibidiBtn.Visible = false
SkibidiBtn.Parent = ScreenGui

local MC3 = Instance.new("UICorner"); MC3.CornerRadius = UDim.new(0, 10); MC3.Parent = SkibidiBtn

-- Toggle menu
local menuOpen = false
MainBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    SetBaseBtn.Visible = menuOpen
    SkibidiBtn.Visible = menuOpen
    MainBtn.Text = menuOpen and "💀 CLOSE" or "💀 MENU"
end)

-- Xử lý SET BASE
SetBaseBtn.MouseButton1Click:Connect(function()
    local hrp = GetRoot()
    if hrp then
        SavedBase = hrp.Position
        SetBaseBtn.Text = "📍 BASE ĐÃ LƯU"
        SetBaseBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        Notify("📍 ĐÃ LƯU BASE", string.format("X: %.1f, Y: %.1f, Z: %.1f", SavedBase.X, SavedBase.Y, SavedBase.Z), 4)
        print("[SKIBIDI] Base saved: " .. tostring(SavedBase))
        task.wait(2)
        SetBaseBtn.Text = "📍 SET BASE"
        SetBaseBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    end
end)

-- Xử lý SKIBIDI
local running = false
SkibidiBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    SkibidiBtn.Text = "🚽 ĐANG BAY..."
    SkibidiBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)

    task.spawn(function()
        local holding, tool = IsHoldingEgg()
        if holding then
            FlyToBase()
        else
            Notify("❌ KHÔNG CẦM TRỨNG", "Cầm trứng cướp trước", 3)
        end
        running = false
        SkibidiBtn.Text = "🚽 SKIBIDI TOILET"
        SkibidiBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
    end)
end)

Notify("💀 SKIBIDI V3 LOADED", "@tpmodz", 5)
print("[SKIBIDI] Script loaded - @tpmodz")
