--[[ 
Standalone Evade and Kick System (FollowUp)
Client-side only, draggable UI, hold-to-spam with G
Stylish animated UI with pop toggle, uniform drag, glow effect, and responsive buttons
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variables
local EvadeKickEnabled = false
local EvadeKickBind = Enum.KeyCode.G
local EvadeKickRemote = nil
local OriginalEvadeFire = nil
local Spamming = false

-- Trouver RemoteEvent FollowUp
local function FindEvadeKickRemote()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj.Name == "FollowUp" and obj:IsA("RemoteEvent") then
            return obj
        end
    end
    warn("RemoteEvent 'FollowUp' non trouvé")
    return nil
end

-- Hook pour bypass conditions
local function HookEvadeKickRemote()
    EvadeKickRemote = FindEvadeKickRemote()
    if not EvadeKickRemote then return false end

    OriginalEvadeFire = EvadeKickRemote.FireServer
    EvadeKickRemote.FireServer = function(self, ...)
        local args = {...}
        if type(args[1]) ~= "table" then
            args[1] = {
                Action = "FollowUp",
                Cooldown = 0,
                canUse = true,
                requiresDive = false,
                divePerformed = true,
                isValid = true,
                type = "EvadeKick",
                skillType = "FollowUp",
                forceActivate = true
            }
        end
        return OriginalEvadeFire(self, args[1])
    end
    return true
end

-- Spam de l'attaque
local function PerformEvadeKick()
    if not EvadeKickRemote or not EvadeKickEnabled then return end
    Spamming = true
    while Spamming do
        pcall(function()
            EvadeKickRemote:FireServer({
                Action = "FollowUp",
                Cooldown = 0,
                canUse = true,
                requiresDive = false,
                divePerformed = true,
                isValid = true,
                valid = true,
                type = "EvadeKick",
                skillType = "FollowUp",
                forceActivate = true
            })
        end)
        task.wait(0.1)
    end
end

local function StopEvadeKick()
    Spamming = false
end

-- Input handler
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == EvadeKickBind and EvadeKickEnabled then
        PerformEvadeKick()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == EvadeKickBind then
        StopEvadeKick()
    end
end)

-- === Stylish Animated UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EvadeKickUI_Stylish"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
local OriginalSize = UDim2.new(0, 280, 0, 120)
Frame.Size = OriginalSize
Frame.Position = UDim2.new(0.5, -140, 0.5, -60)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 16)
FrameCorner.Parent = Frame

-- Border using UIStroke
local FrameStroke = Instance.new("UIStroke")
FrameStroke.Parent = Frame
FrameStroke.Thickness = 3
FrameStroke.Color = Color3.fromRGB(50, 50, 60)
FrameStroke.Transparency = 0.3
FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Gradient effect
local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new(Color3.fromRGB(50, 150, 255), Color3.fromRGB(80, 200, 255))
UIGradient.Rotation = 45
UIGradient.Parent = Frame

-- Glow effect
local Glow = Instance.new("UIStroke")
Glow.Parent = Frame
Glow.Thickness = 4
Glow.Color = Color3.fromRGB(0, 200, 255)
Glow.Transparency = 0.6
Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Glow.LineJoinMode = Enum.LineJoinMode.Round

-- Animate glow
RunService.RenderStepped:Connect(function()
    Glow.Transparency = 0.4 + 0.2 * math.sin(tick()*5)
end)

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleBtn.Size = UDim2.new(0, 240, 0, 50)
ToggleBtn.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centré
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Text = "Evade Kick: OFF (G)"
ToggleBtn.Parent = Frame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtn

-- Close Button (toujours collée au coin supérieur droit)
local CloseBtn = Instance.new("TextButton")
CloseBtn.AnchorPoint = Vector2.new(1, 0) -- ancrée au coin
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, 0, 0, 0) -- coin exact
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = Frame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 18)
CloseCorner.Parent = CloseBtn

-- Update Toggle UI with pop animation
local function UpdateToggleUI()
    local keyName = tostring(EvadeKickBind):gsub("Enum.KeyCode.", "")
    if EvadeKickEnabled then
        ToggleBtn.Text = "Evade Kick: ON (" .. keyName .. ")"
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(50,220,50),
            Size = UDim2.new(0, 250, 0, 55)
        }):Play()
        task.wait(0.1)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 240, 0, 50)}):Play()
    else
        ToggleBtn.Text = "Evade Kick: OFF (" .. keyName .. ")"
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(40,40,45),
            Size = UDim2.new(0, 250, 0, 55)
        }):Play()
        task.wait(0.1)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 240, 0, 50)}):Play()
    end
end

-- Hover effects
ToggleBtn.MouseEnter:Connect(function()
    TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70,70,80)}):Play()
end)
ToggleBtn.MouseLeave:Connect(UpdateToggleUI)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255,70,70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200,50,50)}):Play()
end)

-- Drag animation (gonflement)
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(Frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, 140)
        }):Play()
    end
end)

Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(Frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = OriginalSize}):Play()
    end
end)

-- Toggle action
ToggleBtn.MouseButton1Click:Connect(function()
    EvadeKickEnabled = not EvadeKickEnabled
    if EvadeKickEnabled then
        if not HookEvadeKickRemote() then
            EvadeKickEnabled = false
            ToggleBtn.Text = "Evade Kick: ERROR"
            TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(180,50,50)}):Play()
            return
        end
    else
        if EvadeKickRemote and OriginalEvadeFire then
            EvadeKickRemote.FireServer = OriginalEvadeFire
        end
        StopEvadeKick()
    end
    UpdateToggleUI()
end)

-- Close action
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -140, 1, 200)}):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
end)

warn("Standalone Evade and Kick system loaded! Stylish UI with pop toggle, uniform drag, responsive buttons, glow, and close button locked to corner ready.")
