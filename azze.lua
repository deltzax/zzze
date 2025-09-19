--[[ 
Standalone Evade and Kick System (FollowUp + Pounce)
Client-side only, draggable UI, hold-to-spam with G/T
Stylish animated UI with pop toggle, uniform drag, glow effect, responsive buttons, and fixed X
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variables
local EvadeKickEnabled = false
local PounceEnabled = false
local EvadeKickBind = Enum.KeyCode.G
local PounceBind = Enum.KeyCode.T
local EvadeKickRemote = nil
local PounceRemote = nil
local OriginalEvadeFire = nil
local OriginalPounceFire = nil
local Spamming = false

-- Find RemoteEvent
local function FindRemote(name)
    for _, obj in ipairs(game:GetDescendants()) do
        if obj.Name == name and obj:IsA("RemoteEvent") then
            return obj
        end
    end
    return nil
end

-- Hook Remote
local function HookRemote(remote)
    if not remote then return false end
    local originalFire = remote.FireServer
    remote.FireServer = function(self, args)
        if type(args) ~= "table" then
            args = {
                Action = remote.Name,
                Cooldown = 0,
                canUse = true,
                requiresDive = false,
                divePerformed = true,
                isValid = true,
                type = remote.Name,
                skillType = remote.Name,
                forceActivate = true
            }
        end
        return originalFire(self, args)
    end
    return true, originalFire
end

-- Spam action
local function PerformAction(remote)
    if not remote then return end
    Spamming = true
    while Spamming do
        pcall(function()
            remote:FireServer({
                Action = remote.Name,
                Cooldown = 0,
                canUse = true,
                requiresDive = false,
                divePerformed = true,
                isValid = true,
                valid = true,
                type = remote.Name,
                skillType = remote.Name,
                forceActivate = true
            })
        end)
        task.wait(0.1)
    end
end

local function StopAction()
    Spamming = false
end

-- Input handlers
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == EvadeKickBind and EvadeKickEnabled then
        PerformAction(EvadeKickRemote)
    elseif input.KeyCode == PounceBind and PounceEnabled then
        PerformAction(PounceRemote)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == EvadeKickBind or input.KeyCode == PounceBind then
        StopAction()
    end
end)

-- === UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EvadeKickUI_Stylish"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
local OriginalSize = UDim2.new(0, 280, 0, 180)
Frame.Size = OriginalSize
Frame.Position = UDim2.new(0.5, -140, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 16)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Parent = Frame
FrameStroke.Thickness = 3
FrameStroke.Color = Color3.fromRGB(50, 50, 60)
FrameStroke.Transparency = 0.3

local Glow = Instance.new("UIStroke")
Glow.Parent = Frame
Glow.Thickness = 4
Glow.Color = Color3.fromRGB(0, 200, 255)
Glow.Transparency = 0.6
Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Glow.LineJoinMode = Enum.LineJoinMode.Round

RunService.RenderStepped:Connect(function()
    Glow.Transparency = 0.4 + 0.2 * math.sin(tick()*5)
end)

-- Buttons
local ToggleBtnEvade = Instance.new("TextButton")
ToggleBtnEvade.Size = UDim2.new(0, 240, 0, 50)
ToggleBtnEvade.Position = UDim2.new(0, 20, 0, 35)
ToggleBtnEvade.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtnEvade.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtnEvade.Font = Enum.Font.GothamBold
ToggleBtnEvade.TextSize = 16
ToggleBtnEvade.Text = "Evade Kick: OFF (G)"
ToggleBtnEvade.Parent = Frame
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtnEvade

local ToggleBtnPounce = Instance.new("TextButton")
ToggleBtnPounce.Size = UDim2.new(0, 240, 0, 50)
ToggleBtnPounce.Position = UDim2.new(0, 20, 0, 100)
ToggleBtnPounce.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtnPounce.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtnPounce.Font = Enum.Font.GothamBold
ToggleBtnPounce.TextSize = 16
ToggleBtnPounce.Text = "Pounce: OFF (T)"
ToggleBtnPounce.Parent = Frame
local ToggleCorner2 = Instance.new("UICorner")
ToggleCorner2.CornerRadius = UDim.new(0, 12)
ToggleCorner2.Parent = ToggleBtnPounce

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -46, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = Frame
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 18)
CloseCorner.Parent = CloseBtn

-- Update UI
local function UpdateToggle(button, state, key, name)
    if state then
        button.Text = name..": ON ("..key..")"
        button.BackgroundColor3 = Color3.fromRGB(50,220,50)
    else
        button.Text = name..": OFF ("..key..")"
        button.BackgroundColor3 = Color3.fromRGB(40,40,45)
    end
end

-- Hover effects
ToggleBtnEvade.MouseEnter:Connect(function() TweenService:Create(ToggleBtnEvade, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70,70,80)}):Play() end)
ToggleBtnEvade.MouseLeave:Connect(function() UpdateToggle(ToggleBtnEvade, EvadeKickEnabled, "G", "Evade Kick") end)
ToggleBtnPounce.MouseEnter:Connect(function() TweenService:Create(ToggleBtnPounce, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70,70,80)}):Play() end)
ToggleBtnPounce.MouseLeave:Connect(function() UpdateToggle(ToggleBtnPounce, PounceEnabled, "T", "Pounce") end)
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255,70,70)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200,50,50)}):Play() end)

-- Button clicks
ToggleBtnEvade.MouseButton1Click:Connect(function()
    EvadeKickEnabled = not EvadeKickEnabled
    if EvadeKickEnabled then
        EvadeKickRemote = FindRemote("FollowUp")
        local ok, orig = HookRemote(EvadeKickRemote)
        OriginalEvadeFire = orig
        if not ok then
            EvadeKickEnabled = false
            ToggleBtnEvade.Text = "Evade Kick: ERROR"
            ToggleBtnEvade.BackgroundColor3 = Color3.fromRGB(180,50,50)
            return
        end
    else
        StopAction()
    end
    UpdateToggle(ToggleBtnEvade, EvadeKickEnabled, "G", "Evade Kick")
end)

ToggleBtnPounce.MouseButton1Click:Connect(function()
    PounceEnabled = not PounceEnabled
    if PounceEnabled then
        PounceRemote = FindRemote("Pounce")
        local ok, orig = HookRemote(PounceRemote)
        OriginalPounceFire = orig
        if not ok then
            PounceEnabled = false
            ToggleBtnPounce.Text = "Pounce: ERROR"
            ToggleBtnPounce.BackgroundColor3 = Color3.fromRGB(180,50,50)
            return
        end
    else
        StopAction()
    end
    UpdateToggle(ToggleBtnPounce, PounceEnabled, "T", "Pounce")
end)

-- Drag animation
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(Frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 200)}):Play()
    end
end)
Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(Frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = OriginalSize}):Play()
    end
end)

-- Close button
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5,-140,1,200)}):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
end)

warn("Standalone Evade Kick & Pounce system loaded! UI ready, buttons functional, X fixed.")
