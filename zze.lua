-- LocalScript dans StarterGui

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables globales pour suivre l'état des fonctionnalités
local FLYING = false
local ESPenabled = false
local Noclipping = nil
local flyKeyDown, flyKeyUp
local ESPconnections = {}
local Clip = false

-- Variables pour FullBright et NoFog
local FullBrightEnabled = false
local NoFogEnabled = false
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd

-- Cache pour les singularités
local SingularityCache = {}
local RewoundCache = {}

-- Système de gestion des connexions pour éviter les memory leaks
local Connections = {
    Main = {},
    ESP = {},
    Fly = {},
    Noclip = {},
    Rewound = {},
    Character = {},
    Lighting = {}
}

local function CleanupConnections(connectionType)
    if Connections[connectionType] then
        for _, conn in pairs(Connections[connectionType]) do
            if conn then
                conn:Disconnect()
            end
        end
        Connections[connectionType] = {}
    end
end

local function AddConnection(connection, connectionType)
    if not Connections[connectionType] then
        Connections[connectionType] = {}
    end
    table.insert(Connections[connectionType], connection)
    return connection
end

-- Dictionnaire pour suivre les connexions de respawn
local CharacterAddedConnections = {}

-- Nouveau: Connexions pour surveiller les changements de Rewound
local RewoundChangedConnections = {}

-- Utility
local function new(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k=="Parent" then obj.Parent=v else obj[k]=v end
    end
    return obj
end

-- Fonction pour tout désactiver et nettoyer
local function CleanupEverything()
    -- Nettoyer toutes les connexions
    for connectionType, _ in pairs(Connections) do
        CleanupConnections(connectionType)
    end
    
    -- Désactiver le Fly
    if FLYING then
        NOFLY()
    end
    
    -- Désactiver le Noclip
    if Noclipping then 
        Noclipping:Disconnect() 
        Noclipping = nil 
        local char = player.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then 
                    p.CanCollide = true 
                end
            end
        end
    end
    
    -- Désactiver l'ESP
    if ESPenabled then
        ESPenabled = false
        for plr, conn in pairs(ESPconnections) do
            if conn then conn:Disconnect() end
        end
        ESPconnections = {}
        
        -- Nettoyer les connexions de respawn
        for plr, conn in pairs(CharacterAddedConnections) do
            if conn then conn:Disconnect() end
        end
        CharacterAddedConnections = {}
        
        local COREGUI = game:GetService("CoreGui")
        for _, item in pairs(COREGUI:GetChildren()) do
            if item.Name:find("_ESP") then
                item:Destroy()
            end
        end
    end
    
    -- Désactiver FullBright et NoFog (IMPORTANT: toujours exécuter même si pas activés)
    if FullBrightEnabled then
        Lighting.Brightness = originalBrightness
        Lighting.FogEnd = originalFogEnd
        Lighting.GlobalShadows = true
        FullBrightEnabled = false
    end
    
    if NoFogEnabled then
        Lighting.FogEnd = originalFogEnd
        NoFogEnabled = false
    end
    
    -- Nettoyer les connexions Rewound
    for plr, conn in pairs(RewoundChangedConnections) do
        if conn then conn:Disconnect() end
    end
    RewoundChangedConnections = {}
end

-- Colors
local Colors = {
    WindowBG = Color3.fromRGB(30,30,30),
    SectionBG = Color3.fromRGB(45,45,45),
    ButtonBG = Color3.fromRGB(70,70,70),
    ButtonHover = Color3.fromRGB(100,100,100),
    Text = Color3.fromRGB(255,255,255),
    CloseBtn = Color3.fromRGB(150,50,50),
    Success = Color3.fromRGB(50, 150, 50)
}

-- ScreenGui
local ScreenGui = new("ScreenGui",{Name="Singularity_Hub",Parent=playerGui,ResetOnSpawn=false})

-- Main Window
local Window = new("Frame",{
    Parent=ScreenGui,
    Position=UDim2.new(0.5,-320,0.5,-200),
    Size=UDim2.new(0,640,0,400),
    BackgroundColor3=Colors.WindowBG,
    BorderSizePixel=0
})
new("UICorner",{Parent=Window,CornerRadius=UDim.new(0,8)})

-- TopBar
local TopBar = new("Frame",{Parent=Window,Size=UDim2.new(1,0,0,36),BackgroundTransparency=1})
new("TextLabel",{Parent=TopBar,Text="⭐ Singularity Hub",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Colors.Text,BackgroundTransparency=1,Position=UDim2.new(0,10,0,5),Size=UDim2.new(0.6,0,1,-5),TextXAlignment=Enum.TextXAlignment.Left})

-- Bouton "-" pour cacher l'UI
local MinimizeBtn = new("TextButton",{Parent=TopBar,Text="-",Font=Enum.Font.Gotham,TextSize=20,Size=UDim2.new(0,32,0,28),Position=UDim2.new(1,-80,0,6),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text})
new("UICorner",{Parent=MinimizeBtn,CornerRadius=UDim.new(0,6)})
MinimizeBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- F4 pour réafficher
AddConnection(UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.F4 then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end), "Main")

-- Bouton "X" pour fermer tout
local CloseBtn = new("TextButton",{Parent=TopBar,Text="X",Font=Enum.Font.Gotham,TextSize=16,Size=UDim2.new(0,32,0,28),Position=UDim2.new(1,-40,0,6),BackgroundColor3=Colors.CloseBtn,TextColor3=Colors.Text})
new("UICorner",{Parent=CloseBtn,CornerRadius=UDim.new(0,6)})
CloseBtn.MouseButton1Click:Connect(function()
    CleanupEverything()
    ScreenGui:Destroy()
end)

-- Left Category List
local CategoryWidth = 120
local CategoryList = new("Frame",{
    Parent=Window,
    BackgroundTransparency=1,
    Position=UDim2.new(0,10,0,46),
    Size=UDim2.new(0,CategoryWidth,1,-56)
})

local CategoryButtons = {}
local function createCategory(name)
    local btn = new("TextButton",{
        Parent=CategoryList,
        Text=name,
        Font=Enum.Font.GothamBold,
        TextSize=16,
        TextColor3=Colors.Text,
        BackgroundColor3=Colors.ButtonBG,
        Size=UDim2.new(1,0,0,36)
    })
    new("UICorner",{Parent=btn,CornerRadius=UDim.new(0,6)})
    btn.MouseEnter:Connect(function() 
        if btn.BackgroundColor3 ~= Colors.ButtonHover then
            btn.BackgroundColor3=Colors.ButtonHover 
        end
    end)
    btn.MouseLeave:Connect(function() 
        if btn.BackgroundColor3 ~= Colors.ButtonBG then
            btn.BackgroundColor3=Colors.ButtonBG 
        end
    end)
    return btn
end

local Sections = {}
local SectionWidth = Window.Size.X.Offset - CategoryWidth - 30
local SectionHeight = Window.Size.Y.Offset - 56
local function createSection(name)
    local sec = new("Frame",{Parent=Window,Position=UDim2.new(0,CategoryWidth+20,0,46),Size=UDim2.new(0,SectionWidth,0,SectionHeight),BackgroundColor3=Colors.SectionBG})
    new("UICorner",{Parent=sec,CornerRadius=UDim.new(0,8)})
    sec.Visible = false
    return sec
end

-- Sections
Sections["🏠 Home"] = createSection("Home")
Sections["🎲 Misc"] = createSection("Misc")
Sections["📚 Archived"] = createSection("Archived")
Sections["⚙️ Settings"] = createSection("Settings")

-- Create Category Buttons
local catNames = {"🏠 Home","🎲 Misc","📚 Archived","⚙️ Settings"}
for i,name in ipairs(catNames) do
    local btn = createCategory(name)
    btn.Position = UDim2.new(0,0,0,(i-1)*46)
    btn.MouseButton1Click:Connect(function()
        for _,sec in pairs(Sections) do sec.Visible=false end
        Sections[name].Visible = true
    end)
    CategoryButtons[name] = btn
end
Sections["🏠 Home"].Visible = true

-- === Système de vol corrigé (sans tremblement) ===
local iyflyspeed = 1
local QEfly = true

local function getRoot(char) 
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
end

-- Système de vol corrigé sans tremblement
function sFLY()
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid")
    end
    
    local root = getRoot(character)
    if not root then
        warn("Impossible de trouver HumanoidRootPart")
        return
    end
    
    -- Nettoyer les anciennes connexions
    if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
    if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
    
    FLYING = true
    humanoid.PlatformStand = true
    
    -- Créer les contrôles de physique avec des paramètres optimisés
    local bg = Instance.new("BodyGyro", root)
    bg.P = 90000
    bg.MaxTorque = Vector3.new(90000, 90000, 90000)
    bg.D = 1000  -- Ajout d'un amortissement pour réduire les tremblements
    bg.CFrame = root.CFrame
    
    local bv = Instance.new("BodyVelocity", root)
    bv.Velocity = Vector3.new(0, 0.1, 0)  -- Petite vitesse initiale pour éviter le blocage
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    
    local control = {f = 0, b = 0, l = 0, r = 0, q = 0, e = 0}
    local lastcontrol = {f = 0, b = 0, l = 0, r = 0, q = 0, e = 0}
    
    -- Connexions pour les touches
    flyKeyDown = AddConnection(UserInputService.InputBegan:Connect(function(input)
        if not FLYING then return end
        
        if input.KeyCode == Enum.KeyCode.W then
            control.f = iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.S then
            control.b = -iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.A then
            control.l = -iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.D then
            control.r = iyflyspeed
        elseif input.KeyCode == Enum.KeyCode.E and QEfly then
            control.q = iyflyspeed * 2
        elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
            control.e = -iyflyspeed * 2
        end
    end), "Fly")
    
    flyKeyUp = AddConnection(UserInputService.InputEnded:Connect(function(input)
        if not FLYING then return end
        
        if input.KeyCode == Enum.KeyCode.W then
            control.f = 0
        elseif input.KeyCode == Enum.KeyCode.S then
            control.b = 0
        elseif input.KeyCode == Enum.KeyCode.A then
            control.l = 0
        elseif input.KeyCode == Enum.KeyCode.D then
            control.r = 0
        elseif input.KeyCode == Enum.KeyCode.E then
            control.q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then
            control.e = 0
        end
    end), "Fly")
    
    -- Boucle de vol principale avec interpolation pour éviter les tremblements
    local flyLoop = AddConnection(RunService.Heartbeat:Connect(function()
        if not FLYING or not root or not root.Parent then
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            return
        end
        
        local cam = workspace.CurrentCamera
        if not cam then return end
        
        -- Calcul de la vitesse basé sur les contrôles
        local speed = 50
        local moveVector = Vector3.new(control.l + control.r, control.q + control.e, control.f + control.b)
        
        if moveVector.Magnitude > 0 then
            -- Conversion des inputs en direction relative à la caméra
            local cameraCF = cam.CFrame
            local moveDirection = (cameraCF.LookVector * moveVector.Z) + 
                                (cameraCF.RightVector * moveVector.X) +
                                (Vector3.new(0, 1, 0) * moveVector.Y)
            
            -- Normalisation et application de la vitesse
            moveDirection = moveDirection.Unit * speed * iyflyspeed  -- Utilisation de iyflyspeed ici
            
            -- Application en douceur de la vélocité
            bv.Velocity = moveDirection
            
            -- Mise à jour de la rotation en douceur
            local targetCFrame = CFrame.new(root.Position, root.Position + cameraCF.LookVector)
            bg.CFrame = targetCFrame
            
            lastcontrol = {
                f = control.f, b = control.b, 
                l = control.l, r = control.r, 
                q = control.q, e = control.e
            }
        else
            -- Arrêt en douceur
            bv.Velocity = Vector3.new(0, 0, 0)
        end
    end), "Fly")
end

function NOFLY()
    FLYING = false
    
    if flyKeyDown then 
        flyKeyDown:Disconnect() 
        flyKeyDown = nil 
    end
    if flyKeyUp then 
        flyKeyUp:Disconnect() 
        flyKeyUp = nil 
    end
    
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then 
            humanoid.PlatformStand = false 
        end
        
        local root = getRoot(char)
        if root then
            for _, child in pairs(root:GetChildren()) do
                if child:IsA("BodyGyro") or child:IsA("BodyVelocity") then
                    child:Destroy()
                end
            end
        end
    end
    
    CleanupConnections("Fly")
end

-- === Fonctions pour FullBright et NoFog ===
local function toggleFullBright()
    FullBrightEnabled = not FullBrightEnabled
    
    if FullBrightEnabled then
        originalBrightness = Lighting.Brightness
        originalFogEnd = Lighting.FogEnd  -- Sauvegarder aussi FogEnd pour FullBright
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        
        -- Détruire aussi les atmosphères pour FullBright
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
    else
        Lighting.Brightness = originalBrightness
        Lighting.FogEnd = originalFogEnd
        Lighting.GlobalShadows = true
    end
    
    return FullBrightEnabled
end

local function toggleNoFog()
    NoFogEnabled = not NoFogEnabled
    
    if NoFogEnabled then
        originalFogEnd = Lighting.FogEnd
        Lighting.FogEnd = 100000
        
        -- Détruire toutes les atmosphères comme dans votre exemple
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
    else
        Lighting.FogEnd = originalFogEnd
    end
    
    return NoFogEnabled
end

-- === Fonctions pour détecter la singularité ===
local function getPlayerSingularity(plr)
    if SingularityCache[plr] ~= nil then
        return SingularityCache[plr]
    end
    
    if plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Singularity") then
        local val = plr.Data.Singularity
        if val:IsA("StringValue") then
            SingularityCache[plr] = val.Value ~= "" and val.Value or "No Value"
        elseif val:IsA("BoolValue") then
            SingularityCache[plr] = val.Value and "Yes" or "No"
        elseif val:IsA("IntValue") or val:IsA("NumberValue") then
            SingularityCache[plr] = tostring(val.Value)
        else
            SingularityCache[plr] = "Present"
        end
    else
        SingularityCache[plr] = nil
    end
    
    return SingularityCache[plr]
end

local function hasSingularity(plr)
    local singularity = getPlayerSingularity(plr)
    return singularity and singularity ~= "No Value" and singularity ~= "No"
end

-- === Fonctions pour détecter Rewound ===
local function getPlayerRewoundCount(plr)
    if RewoundCache[plr] ~= nil then
        return RewoundCache[plr]
    end
    
    local count = 0
    local backpack = plr:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item.Name == "Rewound Time" then
                count += 1
            end
        end
    end
    
    RewoundCache[plr] = count
    return count
end

-- === Fonction pour surveiller les changements de Rewound ===
local function monitorRewoundChanges(plr)
    if RewoundChangedConnections[plr] then
        RewoundChangedConnections[plr]:Disconnect()
    end
    
    local backpack = plr:FindFirstChild("Backpack")
    if backpack then
        -- Surveiller l'ajout/suppression d'items dans le backpack
        RewoundChangedConnections[plr] = backpack.ChildAdded:Connect(function(child)
            if child.Name == "Rewound Time" then
                -- Invalider le cache et mettre à jour l'affichage
                RewoundCache[plr] = nil
                if RewoundFrame.Visible then
                    updateRewoundList()
                end
            end
        end)
        
        RewoundChangedConnections[plr] = backpack.ChildRemoved:Connect(function(child)
            if child.Name == "Rewound Time" then
                -- Invalider le cache et mettre à jour l'affichage
                RewoundCache[plr] = nil
                if RewoundFrame.Visible then
                    updateRewoundList()
                end
            end
        end)
    end
end

-- === ESP optimisé avec détection de respawn ===
local function createESP(plr)
    if plr.Name==player.Name then return end
    if ESPconnections[plr] then 
        ESPconnections[plr]:Disconnect()
        ESPconnections[plr] = nil
    end
    
    local COREGUI = game:GetService("CoreGui")
    
    -- Supprimer l'ancien ESP s'il existe
    local oldESP = COREGUI:FindFirstChild(plr.Name.."_ESP")
    if oldESP then oldESP:Destroy() end
    
    local ESPholder = Instance.new("Folder", COREGUI)
    ESPholder.Name = plr.Name.."_ESP"
    
    local function setup()
        pcall(function()
            -- Attendre que le personnage soit disponible
            if not plr.Character then
                plr.CharacterAdded:Wait()
                task.wait(0.5) -- Petit délai après le respawn
            end
            
            if not getRoot(plr.Character) then
                repeat task.wait(0.5) until getRoot(plr.Character)
            end
            
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                repeat task.wait(0.5) until plr.Character:FindFirstChildOfClass("Humanoid")
            end
            
            local head = plr.Character:FindFirstChild("Head")
            if not head then return end
            
            local BG = Instance.new("BillboardGui", ESPholder)
            BG.Adornee = head
            BG.Size = UDim2.new(0, 100, 0, 50)
            BG.StudsOffset = Vector3.new(0, 2, 0)
            BG.AlwaysOnTop = true
            
            local TL = Instance.new("TextLabel", BG)
            TL.BackgroundTransparency = 1
            TL.Size = UDim2.new(1, 0, 1, 0)
            TL.Font = Enum.Font.SourceSansBold
            TL.TextSize = 14
            TL.TextColor3 = Color3.new(1, 1, 1)
            TL.TextStrokeTransparency = 0
            TL.TextYAlignment = Enum.TextYAlignment.Center
            
            -- Vérifier si le joueur a une singularité
            local hasSingularityValue = hasSingularity(plr)
            local starPrefix = hasSingularityValue and "⭐ " or ""
            
            local lastUpdate = 0
            local updateInterval = 0.2 -- Mise à jour toutes les 0.2 secondes pour améliorer les performances
            
            ESPconnections[plr] = AddConnection(RunService.Heartbeat:Connect(function()
                if not plr.Character or not plr.Character.Parent or not getRoot(plr.Character) or not player.Character or not getRoot(player.Character) then 
                    if ESPconnections[plr] then 
                        ESPconnections[plr]:Disconnect() 
                        ESPconnections[plr] = nil
                    end
                    return 
                end
                
                -- Vérifier si le personnage a changé (respawn)
                if BG.Parent ~= ESPholder or not BG.Adornee or BG.Adornee.Parent ~= plr.Character then
                    if ESPconnections[plr] then 
                        ESPconnections[plr]:Disconnect() 
                        ESPconnections[plr] = nil
                    end
                    createESP(plr) -- Recréer l'ESP
                    return
                end
                
                -- Limiter la fréquence de mise à jour
                local now = tick()
                if now - lastUpdate < updateInterval then return end
                lastUpdate = now
                
                local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then return end
                
                local dist = math.floor((getRoot(player.Character).Position - getRoot(plr.Character).Position).Magnitude)
                local hp = humanoid.Health
                local hpColor
                
                if hp > 100 then 
                    hpColor = Color3.fromRGB(0, 255, 0)
                elseif hp > 25 then 
                    hpColor = Color3.fromRGB(255, 165, 0)
                else 
                    hpColor = Color3.fromRGB(255, 0, 0)
                end
                
                -- Mettre à jour le texte avec l'étoile si le joueur a une singularité
                TL.Text = starPrefix .. plr.Name .. " ["..dist.." stud]\n"..math.floor(hp).."/"..humanoid.MaxHealth
                TL.TextColor3 = hpColor
            end), "ESP")
        end)
    end
    
    task.spawn(setup)
end

local function removeESP(plr)
    if ESPconnections[plr] then
        ESPconnections[plr]:Disconnect()
        ESPconnections[plr] = nil
    end
    
    if CharacterAddedConnections[plr] then
        CharacterAddedConnections[plr]:Disconnect()
        CharacterAddedConnections[plr] = nil
    end
    
    local COREGUI = game:GetService("CoreGui")
    local folder = COREGUI:FindFirstChild(plr.Name.."_ESP")
    if folder then folder:Destroy() end
end

local function toggleESP()
    ESPenabled = not ESPenabled
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=player then
            if ESPenabled then 
                createESP(plr)
                
                -- Ajouter un écouteur pour détecter les respawns
                if not CharacterAddedConnections[plr] then
                    CharacterAddedConnections[plr] = plr.CharacterAdded:Connect(function()
                        if ESPenabled then
                            task.wait(1) -- Petit délai après le respawn
                            createESP(plr)
                        end
                    end)
                end
            else 
                removeESP(plr)
            end
        end
    end
end

AddConnection(Players.PlayerAdded:Connect(function(plr)
    if ESPenabled then 
        createESP(plr)
        
        -- Ajouter un écouteur pour détecter les respawns
        CharacterAddedConnections[plr] = plr.CharacterAdded:Connect(function()
            if ESPenabled then
                task.wait(1) -- Petit délai après le respawn
                createESP(plr)
            end
        end)
    end
    
    -- Surveiller les changements de Rewound pour les nouveaux joueurs
    monitorRewoundChanges(plr)
end), "Main")

AddConnection(Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    SingularityCache[plr] = nil
    RewoundCache[plr] = nil
    
    -- Nettoyer les connexions Rewound
    if RewoundChangedConnections[plr] then
        RewoundChangedConnections[plr]:Disconnect()
        RewoundChangedConnections[plr] = nil
    end
end), "Main")

-- === Sections ===
local HomeSection=Sections["🏠 Home"]
local MiscSection=Sections["🎲 Misc"]
local ArchivedSection=Sections["📚 Archived"]
local SettingsSection=Sections["⚙️ Settings"]

-- Fly Button
local FlyBtn=new("TextButton",{Parent=HomeSection,Text="Fly",Size=UDim2.new(0,200,0,36),Position=UDim2.new(0,20,0,20),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text,Font=Enum.Font.Gotham,TextSize=14})
new("UICorner",{Parent=FlyBtn,CornerRadius=UDim.new(0,6)})
FlyBtn.MouseButton1Click:Connect(function()
    if FLYING then 
        NOFLY() 
        FlyBtn.Text = "Fly"
        FlyBtn.BackgroundColor3 = Colors.ButtonBG
    else 
        sFLY() 
        FlyBtn.Text = "Fly (ON)"
        FlyBtn.BackgroundColor3 = Colors.Success
    end
end)

-- Slider moderne avec plage 1-5
local SliderFrame = new("Frame",{
    Parent=HomeSection,
    Position=UDim2.new(0,20,0,70),
    Size=UDim2.new(0,200,0,24),
    BackgroundColor3=Colors.SectionBG
})
new("UICorner",{Parent=SliderFrame,CornerRadius=UDim.new(0,12)})
local sliderStroke = Instance.new("UIStroke")
sliderStroke.Parent = SliderFrame
sliderStroke.Color = Colors.ButtonHover
sliderStroke.Thickness = 2
local SliderFill = new("Frame",{
    Parent=SliderFrame,
    Position=UDim2.new(0,0,0,0),
    Size=UDim2.new((iyflyspeed-1)/4,1,0,0),
    BackgroundColor3=Colors.ButtonHover
})
new("UICorner",{Parent=SliderFill,CornerRadius=UDim.new(0,12)})
local SliderLabel = new("TextLabel",{
    Parent=HomeSection,
    Text="Speed: "..iyflyspeed,
    Font=Enum.Font.Gotham,
    TextSize=14,
    TextColor3=Colors.Text,
    BackgroundTransparency=1,
    Position=UDim2.new(0,20,0,100),
    Size=UDim2.new(0,200,0,20)
})
local function updateSlider(value)
    iyflyspeed = math.clamp(value,1,5)
    SliderFill.Size = UDim2.new((iyflyspeed-1)/4,0,1,0)
    SliderLabel.Text = "Speed: "..string.format("%.1f", iyflyspeed)
end
SliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function move(input2)
            local relative = math.clamp((input2.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
            updateSlider(relative * 4 + 1)
        end
        move(input)
        local conn
        conn = UserInputService.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement then
                move(input2)
            end
        end)
        local ended
        ended = UserInputService.InputEnded:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                conn:Disconnect()
                ended:Disconnect()
            end
        end)
    end
end)

-- Noclip Button
local NoclipBtn=new("TextButton",{Parent=HomeSection,Text="Noclip",Size=UDim2.new(0,200,0,36),Position=UDim2.new(0,240,0,20),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text,Font=Enum.Font.Gotham,TextSize=14})
new("UICorner",{Parent=NoclipBtn,CornerRadius=UDim.new(0,6)})
NoclipBtn.MouseButton1Click:Connect(function()
    if not Noclipping then
        Noclipping=RunService.Stepped:Connect(function()
            if not Clip and player.Character then
                for _,p in pairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide==true then 
                        p.CanCollide=false 
                    end
                end
            end
        end)
        Clip=false
        NoclipBtn.Text = "Noclip (ON)"
        NoclipBtn.BackgroundColor3 = Colors.Success
    else
        if Noclipping then Noclipping:Disconnect() Noclipping=nil end
        Clip=true
        NoclipBtn.Text = "Noclip"
        NoclipBtn.BackgroundColor3 = Colors.ButtonBG
    end
end)

-- Misc Section Buttons
local ESPBtn=new("TextButton",{Parent=MiscSection,Text="ESP",Size=UDim2.new(0,200,0,36),Position=UDim2.new(0,20,0,20),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text,Font=Enum.Font.Gotham,TextSize=14})
new("UICorner",{Parent=ESPBtn,CornerRadius=UDim.new(0,6)})
ESPBtn.MouseButton1Click:Connect(function()
    toggleESP()
    if ESPenabled then
        ESPBtn.Text = "ESP (ON)"
        ESPBtn.BackgroundColor3 = Colors.Success
    else
        ESPBtn.Text = "ESP"
        ESPBtn.BackgroundColor3 = Colors.ButtonBG
    end
end)

local GotoBox=new("TextBox",{Parent=MiscSection,Text="",PlaceholderText="Player name...",Size=UDim2.new(0,200,0,36),Position=UDim2.new(0,240,0,20),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text,Font=Enum.Font.Gotham,TextSize=14})
new("UICorner",{Parent=GotoBox,CornerRadius=UDim.new(0,6)})
GotoBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and GotoBox.Text~="" then
        local targetName = GotoBox.Text
        for _,plr in pairs(Players:GetPlayers()) do
            if plr.Name:lower():find(targetName:lower()) then
                if plr.Character and player.Character then
                    local root = getRoot(player.Character)
                    local targetRoot = getRoot(plr.Character)
                    if root and targetRoot then
                        root.CFrame = targetRoot.CFrame + Vector3.new(0,3,0)
                    end
                end
                break
            end
        end
        GotoBox.Text = ""
    end
end)

-- Nouveaux boutons dans Misc
local FullBrightBtn=new("TextButton",{Parent=MiscSection,Text="FullBright",Size=UDim2.new(0,200,0,36),Position=UDim2.new(0,20,0,70),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text,Font=Enum.Font.Gotham,TextSize=14})
new("UICorner",{Parent=FullBrightBtn,CornerRadius=UDim.new(0,6)})
FullBrightBtn.MouseButton1Click:Connect(function()
    local enabled = toggleFullBright()
    if enabled then
        FullBrightBtn.Text = "FullBright (ON)"
        FullBrightBtn.BackgroundColor3 = Colors.Success
    else
        FullBrightBtn.Text = "FullBright"
        FullBrightBtn.BackgroundColor3 = Colors.ButtonBG
    end
end)

local NoFogBtn=new("TextButton",{Parent=MiscSection,Text="NoFog",Size=UDim2.new(0,200,0,36),Position=UDim2.new(0,240,0,70),BackgroundColor3=Colors.ButtonBG,TextColor3=Colors.Text,Font=Enum.Font.Gotham,TextSize=14})
new("UICorner",{Parent=NoFogBtn,CornerRadius=UDim.new(0,6)})
NoFogBtn.MouseButton1Click:Connect(function()
    local enabled = toggleNoFog()
    if enabled then
        NoFogBtn.Text = "NoFog (ON)"
        NoFogBtn.BackgroundColor3 = Colors.Success
    else
        NoFogBtn.Text = "NoFog"
        NoFogBtn.BackgroundColor3 = Colors.ButtonBG
    end
end)

-- ===========================
-- Archived Section Buttons
-- ===========================

local spacing = 10

-- Singularity List
local SingularityBtn = new("TextButton", {
    Parent = ArchivedSection,
    Text = "Singularity List",
    Size = UDim2.new(0, 200, 0, 36),
    Position = UDim2.new(0,20,0,20),
    BackgroundColor3 = Colors.ButtonBG,
    TextColor3 = Colors.Text,
    Font = Enum.Font.Gotham,
    TextSize = 14
})
new("UICorner", {Parent = SingularityBtn, CornerRadius = UDim.new(0, 6)})

-- Traveller TP
local TravellerBtn = new("TextButton",{
    Parent = ArchivedSection,
    Text = "Traveller TP",
    Size = SingularityBtn.Size,
    Position = UDim2.new(0,20,0,20 + 36 + spacing),
    BackgroundColor3 = Colors.ButtonBG,
    TextColor3 = Colors.Text,
    Font = Enum.Font.Gotham,
    TextSize = 14
})
new("UICorner",{Parent=TravellerBtn,CornerRadius=UDim.new(0,6)})
TravellerBtn.MouseButton1Click:Connect(function()
    local npc = workspace.NPCS:FindFirstChild("Traveling Pawner")
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
    end
end)

-- Singularity List Frame
local SingularityListFrame = new("ScrollingFrame", {
    Parent = Window,
    Size = UDim2.new(0, 300, 0, 250),
    Position = UDim2.new(1, 10, 0, 46),
    BackgroundColor3 = Colors.SectionBG,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Visible = false,
    BorderSizePixel = 0
})
new("UICorner", {Parent = SingularityListFrame, CornerRadius = UDim.new(0, 8)})

local SingularityTitle = new("TextLabel", {
    Parent = SingularityListFrame,
    Text = "SINGULARITY LIST",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Colors.Text,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(1, -20, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Center
})

local function updateSingularityList()
    for _, child in ipairs(SingularityListFrame:GetChildren()) do
        if child ~= SingularityTitle and child:IsA("Frame") then
            child:Destroy()
        end
    end

    local players = Players:GetPlayers()
    local yOffset = 40
    local hasSingularityCount = 0

    for _, plr in ipairs(players) do
        local singularity = getPlayerSingularity(plr)
        local bgColor
        if singularity and singularity ~= "No Value" then
            bgColor = Colors.Success
            hasSingularityCount += 1
        else
            bgColor = Color3.fromRGB(100,100,100)
        end
        
        local playerFrame = new("Frame", {
            Parent = SingularityListFrame,
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, yOffset),
            BackgroundColor3 = bgColor,
            BackgroundTransparency = 0.3
        })
        new("UICorner", {Parent = playerFrame, CornerRadius = UDim.new(0, 4)})

        new("TextLabel", {
            Parent = playerFrame,
            Text = (singularity and singularity ~= "No Value" and "⭐ " or "") .. plr.Name,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Colors.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        new("TextLabel", {
            Parent = playerFrame,
            Text = singularity or "No Value",
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = (singularity == nil or singularity == "No Value") and Color3.fromRGB(255, 0, 0) or Colors.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right
        })
        yOffset = yOffset + 30
    end
    SingularityListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    SingularityTitle.Text = "SINGULARITY - " .. hasSingularityCount .. "/" .. #players
end

SingularityBtn.MouseButton1Click:Connect(function()
    SingularityListFrame.Visible = not SingularityListFrame.Visible
    if SingularityListFrame.Visible then
        updateSingularityList()
    end
end)

-- ===========================
-- Rewound Button
-- ===========================

local RewoundBtn = new("TextButton", {
    Parent = ArchivedSection,
    Text = "Rewound List",
    Size = SingularityBtn.Size,
    Position = UDim2.new(0, 240, 0, 20), -- droite de SingularityBtn
    BackgroundColor3 = Colors.ButtonBG,
    TextColor3 = Colors.Text,
    Font = Enum.Font.Gotham,
    TextSize = 14
})
new("UICorner", {Parent = RewoundBtn, CornerRadius = UDim.new(0, 6)})

local RewoundFrame = new("ScrollingFrame", {
    Parent = Window,
    Size = UDim2.new(0, 300, 0, 250),
    Position = UDim2.new(1, 10, 0, 46),
    BackgroundColor3 = Colors.SectionBG,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Visible = false,
    BorderSizePixel = 0
})
new("UICorner", {Parent = RewoundFrame, CornerRadius = UDim.new(0, 8)})

local RewoundTitle = new("TextLabel", {
    Parent = RewoundFrame,
    Text = "REWOUND LIST",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Colors.Text,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(1, -20, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Center
})

local function updateRewoundList()
    for _, child in ipairs(RewoundFrame:GetChildren()) do
        if child ~= RewoundTitle and child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local yOffset = 40
    local players = Players:GetPlayers()
    local hasRewoundCount = 0
    
    for _, plr in ipairs(players) do
        local count = getPlayerRewoundCount(plr)
        if count > 0 then
            hasRewoundCount += 1
        end
        
        local playerFrame = new("Frame", {
            Parent = RewoundFrame,
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, yOffset),
            BackgroundColor3 = count > 0 and Colors.Success or Color3.fromRGB(100,100,100),
            BackgroundTransparency = 0.3
        })
        new("UICorner", {Parent = playerFrame, CornerRadius = UDim.new(0,4)})
        
        new("TextLabel", {
            Parent = playerFrame,
            Text = plr.Name,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Colors.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        new("TextLabel", {
            Parent = playerFrame,
            Text = tostring(count),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Colors.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right
        })
        yOffset = yOffset + 30
    end
    RewoundFrame.CanvasSize = UDim2.new(0,0,0,yOffset)
    RewoundTitle.Text = "REWOUND - " .. hasRewoundCount .. "/" .. #players
end

RewoundBtn.MouseButton1Click:Connect(function()
    RewoundFrame.Visible = not RewoundFrame.Visible
    if RewoundFrame.Visible then
        updateRewoundList()
    end
end)

-- Drag Window
local dragging=false
local dragStart,startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true
        dragStart=input.Position
        startPos=Window.Position
        input.Changed:Connect(function() 
            if input.UserInputState==Enum.UserInputState.End then 
                dragging=false 
            end 
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=input.Position-dragStart
        Window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

-- Initialiser la surveillance des changements de Rewound pour tous les joueurs existants
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= player then
        monitorRewoundChanges(plr)
    end
end

-- Mise à jour périodique des caches pour améliorer les performances
task.spawn(function()
    while task.wait(2) do  -- Mise à jour plus fréquente (2 secondes)
        -- Mettre à jour la liste Rewound si elle est visible
        if RewoundFrame.Visible then
            -- Invalider le cache pour forcer une re-vérification
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player then
                    RewoundCache[plr] = nil
                end
            end
            updateRewoundList()
        end
        
        -- Mettre à jour la liste Singularity si elle est visible
        if SingularityListFrame.Visible then
            updateSingularityList()
        end
        
        if ESPenabled then
            -- Mettre à jour le cache des singularités
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player then
                    local oldValue = SingularityCache[plr]
                    SingularityCache[plr] = nil  -- Invalider le cache
                    local newValue = getPlayerSingularity(plr)
                    
                    -- Si la valeur a changé et que l'ESP est activé, mettre à jour l'affichage
                    if oldValue ~= newValue and ESPconnections[plr] then
                        removeESP(plr)
                        createESP(plr)
                    end
                end
            end
        end
    end
end)
