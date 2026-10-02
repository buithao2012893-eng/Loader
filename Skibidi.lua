-- ==========================================
-- SKIBIDI TOILET - AUTO CARRY EGG VỀ BASE
-- ==========================================

local Config = {
    BasePosition = Vector3.new(0, 0, 0),    -- ⚠️ MÀY ĐIỀN TỌA ĐỘ BASE VÀO ĐÂY
    FlySpeed = 200,                          -- Tốc độ bay (studs/giây)
    StepDistance = 100,                      -- Bay từng đoạn bao xa
    AutoThrow = true,                        -- Tự thả trứng khi tới base
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Hàm kiểm tra đang cầm trứng không
local function IsHoldingEgg()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and obj.Name:lower():find("egg") then
            return true, obj
        end
    end
    return false
end

-- Hàm kiểm tra trứng cướp (không phải của mình)
local function IsStolenEgg(tool)
    -- ⚠️ Mày cần chỉnh hàm này cho đúng game
    -- Cách 1: Dựa vào tên
    -- return tool.Name:lower():find("stolen") or tool.Name:lower():find("cướp")

    -- Cách 2: Dựa vào attribute
    -- return tool:GetAttribute("IsStolen") == true

    -- Cách 3: Tạm thời coi tất cả là trứng cướp
    return true
end

-- Hàm bay tới vị trí
local function FlyTo(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Tạo BodyVelocity + BodyGyro
    local bv = hrp:FindFirstChild("SkibidiBV") or Instance.new("BodyVelocity")
    bv.Name = "SkibidiBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Parent = hrp

    local bg = hrp:FindFirstChild("SkibidiBG") or Instance.new("BodyGyro")
    bg.Name = "SkibidiBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.Parent = hrp

    hum.PlatformStand = true

    -- Bay từng đoạn
    local current = hrp.Position
    while (current - targetPos).Magnitude > 5 do
        local dir = (targetPos - current).Unit
        bv.Velocity = dir * Config.FlySpeed
        bg.CFrame = CFrame.new(current, targetPos)
        task.wait(0.1)
        current = hrp.Position
        -- Kiểm tra mất trứng giữa đường
        local holding = IsHoldingEgg()
        if not holding then
            hum.PlatformStand = false
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            return false
        end
    end

    -- Đến base → thả trứng
    if Config.AutoThrow then
        local holding, tool = IsHoldingEgg()
        if holding and tool then
            tool.Parent = workspace
        end
    end

    hum.PlatformStand = false
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    return true
end

-- Nút UI chính
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkibidiUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainBtn = Instance.new("TextButton")
MainBtn.Size = UDim2.new(0, 150, 0, 50)
MainBtn.Position = UDim2.new(0, 20, 0.5, -25)
MainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainBtn.Text = "💀 MENU"
MainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MainBtn.Font = Enum.Font.GothamBold
MainBtn.TextSize = 16
MainBtn.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainBtn

-- Nút Skibidi (ẩn lúc đầu)
local SkibidiBtn = Instance.new("TextButton")
SkibidiBtn.Size = UDim2.new(0, 150, 0, 50)
SkibidiBtn.Position = UDim2.new(0, 20, 0.5, 30)
SkibidiBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
SkibidiBtn.Text = "🚽 SKIBIDI TOILET"
SkibidiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkibidiBtn.Font = Enum.Font.GothamBold
SkibidiBtn.TextSize = 14
SkibidiBtn.Visible = false
SkibidiBtn.Parent = ScreenGui

local SkibidiCorner = Instance.new("UICorner")
SkibidiCorner.CornerRadius = UDim.new(0, 10)
SkibidiCorner.Parent = SkibidiBtn

-- Toggle menu
local menuOpen = false
MainBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    SkibidiBtn.Visible = menuOpen
    MainBtn.Text = menuOpen and "💀 CLOSE" or "💀 MENU"
end)

-- Xử lý nút Skibidi
local running = false
SkibidiBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true

    task.spawn(function()
        while running do
            local holding, tool = IsHoldingEgg()
            if holding and IsStolenEgg(tool) then
                -- Đang cầm trứng cướp → bay về base
                FlyTo(Config.BasePosition)
            end
            task.wait(0.1)
        end
        running = false
    end)
end)

print("[SKIBIDI] Loaded - @tpmodz")
