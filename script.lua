local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Configurações de Estado
local TargetPlayer = nil
local AimbotEnabled, FovEnabled, TeamCheckEnabled = false, false, false
local SilentAimEnabled = false 
local RandomBoneEnabled = false 
local AimSmoothness = 1 
local AimType = "Closest" 
local EspMaster = false
local TargetPart = "Head"
local FovRadius = 150 
local ScriptActive = true
local InfiniteJumpEnabled = false
local SpeedEnabled = false 
local WalkSpeedValue = 16 
local FlyEnabled = false 
local FlySpeed = 50 
local NoclipEnabled = false 
local ClickTpEnabled = false

-- Configurações de Hitbox
local HitboxEnabled = false
local HitboxSize = 2
local HitboxPart = "Head" -- "Head", "HumanoidRootPart", "All"
local ShowHitboxVisual = false
local HitboxTeamCheck = false

-- Estados dos Visuals
local ShowNames, ShowDistance, ShowChams, ShowBoxes = false, false, false, false

-- Configurações de Settings e Binds
local MainColor = Color3.fromRGB(0, 255, 255)
local PanicKey = Enum.KeyCode.F4
local SettingKeyBind = false 
local BindingFunction = nil 

local Binds = {
    Aimbot = Enum.KeyCode.Q,
    Esp = Enum.KeyCode.Return,
    SaveTP = Enum.KeyCode.V,
    TeleportTP = Enum.KeyCode.B,
    AutoTP = Enum.KeyCode.X,
    InfJump = Enum.KeyCode.Space,
    Fly = Enum.KeyCode.K,
    Noclip = Enum.KeyCode.N,
    ClickTPKey = Enum.KeyCode.LeftControl
}

-- Variáveis para Teleport
local SavedLocation = nil
local AutoTpEnabled = false

-- Círculo do FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = MainColor
FOVCircle.Visible = false
FOVCircle.Radius = FovRadius

-- Função de Notificação
local function Notify(titulo, estado)
    StarterGui:SetCore("SendNotification", {
        Title = "WHEN: " .. titulo,
        Text = estado,
        Duration = 2,
    })
end

-- Funções de Busca de Alvo
local function GetClosestToMouse()
    local target, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if not (TeamCheckEnabled and p.Team == LocalPlayer.Team) then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if onScreen and dist < closestDist and dist <= FovRadius then
                    target = p
                    closestDist = dist
                end
            end
        end
    end
    return target
end

local function GetLowestHealth()
    local target, lowestHP = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            if not (TeamCheckEnabled and p.Team == LocalPlayer.Team) then
                local hp = p.Character.Humanoid.Health
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if onScreen and hp < lowestHP and dist <= FovRadius then
                    target = p
                    lowestHP = hp
                end
            end
        end
    end
    return target
end

-- Função Arrastar
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- Interface Principal
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "WhenPanel_v2"
ScreenGui.ResetOnSpawn = false

-- [WATERMARK]
local WatermarkFrame = Instance.new("Frame", ScreenGui)
WatermarkFrame.Size = UDim2.new(0, 220, 0, 130) 
WatermarkFrame.Position = UDim2.new(0, 10, 0, 70)
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
WatermarkFrame.BackgroundTransparency = 0.3
WatermarkFrame.BorderSizePixel = 0
Instance.new("UICorner", WatermarkFrame).CornerRadius = UDim.new(0, 6)

local WatermarkText = Instance.new("TextLabel", WatermarkFrame)
WatermarkText.Size = UDim2.new(1, -10, 1, -10)
WatermarkText.Position = UDim2.new(0, 5, 0, 5)
WatermarkText.BackgroundTransparency = 1
WatermarkText.TextColor3 = Color3.new(1, 1, 1)
WatermarkText.Font = Enum.Font.GothamBold
WatermarkText.TextSize = 12
WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
WatermarkText.TextYAlignment = Enum.TextYAlignment.Top
WatermarkText.RichText = true

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 380, 0, 480)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MakeDraggable(MainFrame)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "WHEN PANEL v2 - FULL SETTINGS"
Title.TextColor3 = MainColor
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Instance.new("UICorner", Title)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 100, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -110, 1, -50)
TabContainer.Position = UDim2.new(0, 105, 0, 45)
TabContainer.BackgroundTransparency = 1

local Pages = {
    Combat = Instance.new("ScrollingFrame", TabContainer),
    Hitbox = Instance.new("ScrollingFrame", TabContainer),
    Visuals = Instance.new("ScrollingFrame", TabContainer),
    Teleport = Instance.new("ScrollingFrame", TabContainer),
    Movement = Instance.new("ScrollingFrame", TabContainer), 
    Players = Instance.new("ScrollingFrame", TabContainer),
    Settings = Instance.new("ScrollingFrame", TabContainer)
}

for name, page in pairs(Pages) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = (name == "Combat")
    page.CanvasSize = UDim2.new(0, 0, 2.0, 0)
    page.ScrollBarThickness = 0
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
end

local function CreateTabBtn(txt, y, targetPage)
    local b = Instance.new("TextButton", Sidebar)
    b.Size = UDim2.new(1, -10, 0, 35)
    b.Position = UDim2.new(0, 5, 0, y)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        targetPage.Visible = true
    end)
end

CreateTabBtn("COMBAT", 10, Pages.Combat)
CreateTabBtn("HITBOX", 50, Pages.Hitbox)
CreateTabBtn("VISUALS", 90, Pages.Visuals)
CreateTabBtn("TELEPORT", 130, Pages.Teleport)
CreateTabBtn("MOVEMENT", 170, Pages.Movement) 
CreateTabBtn("PLAYERS", 210, Pages.Players)
CreateTabBtn("SETTINGS", 250, Pages.Settings)

local function CreateToggle(txt, parent, callback)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.95, 0, 0, 32)
    b.Text = txt .. ": OFF"
    b.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    local active = false
    
    local function update(state, silent)
        active = state
        b.BackgroundColor3 = active and Color3.fromRGB(20, 150, 80) or Color3.fromRGB(60, 20, 20)
        b.Text = txt .. (active and ": ON" or ": OFF")
        callback(active)
        if not silent then
            Notify(txt, active and "Ativado com sucesso!" or "Desativado com sucesso!")
        end
    end

    b.MouseButton1Click:Connect(function()
        update(not active)
    end)
    return {update = update}
end

local function CreateBtn(txt, parent, callback)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.95, 0, 0, 32)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() callback(b) end)
    return b
end

-- Botão "W" Flutuante
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0, 10)
OpenBtn.Text = "W"
OpenBtn.BackgroundColor3 = MainColor
OpenBtn.TextColor3 = Color3.fromRGB(20,20,25)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 25
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
MakeDraggable(OpenBtn)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- [ABA HITBOX]
CreateToggle("Hitbox Expander", Pages.Hitbox, function(v) HitboxEnabled = v end)
CreateToggle("Show Hitbox", Pages.Hitbox, function(v) ShowHitboxVisual = v end)
CreateToggle("Hitbox Team Check", Pages.Hitbox, function(v) HitboxTeamCheck = v end)

local hbPartBtn = CreateBtn("Target: " .. HitboxPart, Pages.Hitbox, function(btn)
    local parts = {"Head", "HumanoidRootPart", "All"}
    local i = table.find(parts, HitboxPart) or 1
    HitboxPart = parts[(i % #parts) + 1]
    btn.Text = "Target: " .. HitboxPart
    Notify("Hitbox Target", "Alterado para: " .. HitboxPart)
end)

local HBControl = Instance.new("Frame", Pages.Hitbox)
HBControl.Size = UDim2.new(0.95, 0, 0, 40)
HBControl.BackgroundTransparency = 1
local HBLabel = Instance.new("TextLabel", HBControl)
HBLabel.Size = UDim2.new(0.6, 0, 1, 0)
HBLabel.Text = "Size: " .. HitboxSize
HBLabel.TextColor3 = Color3.new(1,1,1)
HBLabel.BackgroundTransparency = 1
HBLabel.Font = Enum.Font.GothamBold
HBLabel.TextSize = 14
HBLabel.TextXAlignment = Enum.TextXAlignment.Left

local HBMinus = Instance.new("TextButton", HBControl)
HBMinus.Size = UDim2.new(0.15, 0, 0.8, 0)
HBMinus.Position = UDim2.new(0.65, 0, 0.1, 0)
HBMinus.Text = "[-]"
HBMinus.BackgroundColor3 = Color3.fromRGB(45,45,50)
HBMinus.TextColor3 = MainColor
Instance.new("UICorner", HBMinus)

local HBPlus = Instance.new("TextButton", HBControl)
HBPlus.Size = UDim2.new(0.15, 0, 0.8, 0)
HBPlus.Position = UDim2.new(0.82, 0, 0.1, 0)
HBPlus.Text = "[+]"
HBPlus.BackgroundColor3 = Color3.fromRGB(45,45,50)
HBPlus.TextColor3 = MainColor
Instance.new("UICorner", HBPlus)

HBPlus.MouseButton1Click:Connect(function()
    HitboxSize = math.min(50, HitboxSize + 1)
    HBLabel.Text = "Size: " .. HitboxSize
end)
HBMinus.MouseButton1Click:Connect(function()
    HitboxSize = math.max(2, HitboxSize - 1)
    HBLabel.Text = "Size: " .. HitboxSize
end)

-- [ABA TELEPORT]
CreateBtn("Teleport To Player", Pages.Teleport, function()
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = TargetPlayer.Character.HumanoidRootPart.CFrame
        Notify("Teleport", "Teleportado para " .. TargetPlayer.Name)
    else
        Notify("Aviso", "Selecione um player na aba Players!")
    end
end)

CreateBtn("Save TP Location", Pages.Teleport, function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        SavedLocation = LocalPlayer.Character.HumanoidRootPart.CFrame
        Notify("Teleport", "Localização salva!")
    end
end)

CreateBtn("Teleport to SaveTP", Pages.Teleport, function()
    if SavedLocation then
        LocalPlayer.Character.HumanoidRootPart.CFrame = SavedLocation
        Notify("Teleport", "Retornando ao ponto salvo!")
    else
        Notify("Erro", "Nenhum ponto salvo!")
    end
end)

local autoTpToggle = CreateToggle("Auto Teleport", Pages.Teleport, function(v)
    if v and not SavedLocation then
        Notify("Erro", "Salve um local primeiro!")
        AutoTpEnabled = false
    else
        AutoTpEnabled = v
    end
end)

local clickTpToggleUI = CreateToggle("Click To Teleport", Pages.Teleport, function(v)
    ClickTpEnabled = v
end)

-- [ABA MOVEMENT] 
local infJumpToggleUI = CreateToggle("Infinite Jump", Pages.Movement, function(v) 
    InfiniteJumpEnabled = v 
end)

local flyToggleUI = CreateToggle("Fly Hack", Pages.Movement, function(v)
    FlyEnabled = v
end)

local noclipToggleUI = CreateToggle("Noclip", Pages.Movement, function(v) 
    NoclipEnabled = v
end)

local speedToggleUI = CreateToggle("Speed Hack", Pages.Movement, function(v) 
    SpeedEnabled = v 
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

local SpeedControlFrame = Instance.new("Frame", Pages.Movement)
SpeedControlFrame.Size = UDim2.new(0.95, 0, 0, 40)
SpeedControlFrame.BackgroundTransparency = 1

local SpeedLabel = Instance.new("TextLabel", SpeedControlFrame)
SpeedLabel.Size = UDim2.new(0.6, 0, 1, 0)
SpeedLabel.Text = "Speed: " .. WalkSpeedValue
SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 14
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinusBtn = Instance.new("TextButton", SpeedControlFrame)
MinusBtn.Size = UDim2.new(0.15, 0, 0.8, 0)
MinusBtn.Position = UDim2.new(0.65, 0, 0.1, 0)
MinusBtn.Text = "[-]"
MinusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
MinusBtn.TextColor3 = MainColor
Instance.new("UICorner", MinusBtn)

local PlusBtn = Instance.new("TextButton", SpeedControlFrame)
PlusBtn.Size = UDim2.new(0.15, 0, 0.8, 0)
PlusBtn.Position = UDim2.new(0.82, 0, 0.1, 0)
PlusBtn.Text = "[+]"
PlusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
PlusBtn.TextColor3 = MainColor
Instance.new("UICorner", PlusBtn)

PlusBtn.MouseButton1Click:Connect(function()
    if WalkSpeedValue < 1000 then
        WalkSpeedValue = WalkSpeedValue + 10
        SpeedLabel.Text = "Speed: " .. WalkSpeedValue
    end
end)

MinusBtn.MouseButton1Click:Connect(function()
    if WalkSpeedValue > 16 then
        WalkSpeedValue = WalkSpeedValue - 10
        if WalkSpeedValue < 16 then WalkSpeedValue = 16 end
        SpeedLabel.Text = "Speed: " .. WalkSpeedValue
    end
end)

-- [ABA COMBAT]
local aimbotToggle = CreateToggle("Aimbot", Pages.Combat, function(v) AimbotEnabled = v end)
CreateToggle("Silent Aim", Pages.Combat, function(v) SilentAimEnabled = v end)
CreateToggle("Random Bone", Pages.Combat, function(v) RandomBoneEnabled = v end)
CreateToggle("Show FOV", Pages.Combat, function(v) FovEnabled = v FOVCircle.Visible = v end)

local typeBtn = CreateBtn("Aim Type: " .. AimType, Pages.Combat, function(btn)
    local modes = {"Closest", "Lowest Health", "Selected"}
    local i = table.find(modes, AimType) or 1
    AimType = modes[(i % #modes) + 1]
    btn.Text = "Aim Type: " .. AimType
    Notify("Aim Type", "Alterado para: " .. AimType)
end)

local SmoothControl = Instance.new("Frame", Pages.Combat)
SmoothControl.Size = UDim2.new(0.95, 0, 0, 40)
SmoothControl.BackgroundTransparency = 1
local SLabel = Instance.new("TextLabel", SmoothControl)
SLabel.Size = UDim2.new(0.5, 0, 1, 0)
SLabel.Text = "Smooth: " .. AimSmoothness
SLabel.TextColor3 = Color3.new(1,1,1)
SLabel.BackgroundTransparency = 1
SLabel.Font = Enum.Font.GothamBold
SLabel.TextSize = 12

local SMinus = Instance.new("TextButton", SmoothControl)
SMinus.Size = UDim2.new(0.2, 0, 0.8, 0)
SMinus.Position = UDim2.new(0.55, 0, 0.1, 0)
SMinus.Text = "-"
SMinus.BackgroundColor3 = Color3.fromRGB(45,45,50)
SMinus.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", SMinus)

local SPlus = Instance.new("TextButton", SmoothControl)
SPlus.Size = UDim2.new(0.2, 0, 0.8, 0)
SPlus.Position = UDim2.new(0.78, 0, 0.1, 0)
SPlus.Text = "+"
SPlus.BackgroundColor3 = Color3.fromRGB(45,45,50)
SPlus.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", SPlus)

SPlus.MouseButton1Click:Connect(function() AimSmoothness = math.min(10, AimSmoothness + 0.5) SLabel.Text = "Smooth: " .. AimSmoothness Notify("Smooth", "Valor: " .. AimSmoothness) end)
SMinus.MouseButton1Click:Connect(function() AimSmoothness = math.max(1, AimSmoothness - 0.5) SLabel.Text = "Smooth: " .. AimSmoothness Notify("Smooth", "Valor: " .. AimSmoothness) end)

-- [ABA VISUALS]
local espMasterToggle = CreateToggle("ESP Master", Pages.Visuals, function(v) EspMaster = v end)
CreateToggle("Names", Pages.Visuals, function(v) ShowNames = v end)
CreateToggle("Distance", Pages.Visuals, function(v) ShowDistance = v end)
CreateToggle("Chams", Pages.Visuals, function(v) ShowChams = v end)
CreateToggle("Boxes", Pages.Visuals, function(v) ShowBoxes = v end)
CreateToggle("Team Check", Pages.Visuals, function(v) TeamCheckEnabled = v end)

-- [ABA PLAYERS]
local PList = Instance.new("Frame", Pages.Players)
PList.Size = UDim2.new(0.95, 0, 0, 200)
PList.BackgroundTransparency = 1
Instance.new("UIListLayout", PList)
local function UpdateList()
    for _, c in pairs(PList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local b = Instance.new("TextButton", PList)
            b.Size = UDim2.new(1, 0, 0, 25)
            b.Text = p.Name
            b.BackgroundColor3 = Color3.fromRGB(30,30,30)
            b.TextColor3 = Color3.new(1,1,1)
            b.MouseButton1Click:Connect(function() TargetPlayer = p Notify("Target", "Selecionado: " .. p.Name) end)
        end
    end
end
Players.PlayerAdded:Connect(UpdateList)
Players.PlayerRemoving:Connect(UpdateList)
UpdateList()

-- [ABA SETTINGS]
local colorIdx = 1
CreateBtn("Change Theme Color", Pages.Settings, function()
    local Colors = {Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 0), Color3.fromRGB(170, 0, 255)}
    colorIdx = (colorIdx % #Colors) + 1
    MainColor = Colors[colorIdx]
    Title.TextColor3 = MainColor
    OpenBtn.BackgroundColor3 = MainColor
    FOVCircle.Color = MainColor
    Notify("Tema", "Cor alterada!")
end)

local function CreateBindBtn(label, key)
    local b = Instance.new("TextButton", Pages.Settings)
    b.Size = UDim2.new(0.95, 0, 0, 32)
    b.Text = label .. ": " .. Binds[key].Name
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    b.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        SettingKeyBind = true
        BindingFunction = key
        b.Text = "Press any key..."
    end)
    return b
end

local bindBtns = {
    Aimbot = CreateBindBtn("Aimbot Key", "Aimbot"),
    Esp = CreateBindBtn("ESP Master Key", "Esp"),
    SaveTP = CreateBindBtn("Save TP Key", "SaveTP"),
    TeleportTP = CreateBindBtn("TP to Save Key", "TeleportTP"),
    AutoTP = CreateBindBtn("Auto TP Key", "AutoTP"),
    InfJump = CreateBindBtn("Inf Jump Key", "InfJump"),
    Fly = CreateBindBtn("Fly Key", "Fly"),
    Noclip = CreateBindBtn("Noclip Key", "Noclip"),
    ClickTPBind = CreateBindBtn("ClickTP Modifier", "ClickTPKey")
}

-- Teclas de Pânico e Binds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if SettingKeyBind and input.UserInputType == Enum.UserInputType.Keyboard then
        Binds[BindingFunction] = input.KeyCode
        local label = (BindingFunction == "Aimbot" and "Aimbot Key: " or BindingFunction == "Esp" and "ESP Master Key: " or BindingFunction == "SaveTP" and "Save TP Key: " or BindingFunction == "TeleportTP" and "TP to Save Key: " or BindingFunction == "InfJump" and "Inf Jump Key: " or BindingFunction == "Fly" and "Fly Key: " or BindingFunction == "Noclip" and "Noclip Key: " or BindingFunction == "ClickTPKey" and "ClickTP Modifier: " or "Auto TP Key: ")
        bindBtns[BindingFunction].Text = label .. input.KeyCode.Name
        SettingKeyBind = false
        BindingFunction = nil
        Notify("Settings", "Tecla configurada!")
        return
    end

    if ClickTpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Binds.ClickTPKey) then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.p) + Vector3.new(0, 3, 0)
            Notify("Click TP", "Teleportado!")
        end
    end

    if not gameProcessed then
        if input.KeyCode == PanicKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
            FOVCircle.Visible = (ScreenGui.Enabled and FovEnabled)
            
            -- PANIC RESET: Desativa hacks de movimento e visuais pesados
            if not ScreenGui.Enabled then
                FlyEnabled = false flyToggleUI.update(false, true)
                SpeedEnabled = false speedToggleUI.update(false, true)
                InfiniteJumpEnabled = false infJumpToggleUI.update(false, true)
                NoclipEnabled = false noclipToggleUI.update(false, true)
                HitboxEnabled = false -- Hitbox também reseta por segurança
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.WalkSpeed = 16
                end
            end
            Notify("Panic", ScreenGui.Enabled and "Painel Visível" or "Limpando tudo...")
        elseif input.KeyCode == Enum.KeyCode.F8 then
            ScriptActive = false
            FOVCircle:Remove()
            ScreenGui:Destroy()
        elseif input.KeyCode == Binds.Fly then 
            FlyEnabled = not FlyEnabled
            flyToggleUI.update(FlyEnabled)
        elseif input.KeyCode == Binds.Noclip then 
            NoclipEnabled = not NoclipEnabled
            noclipToggleUI.update(NoclipEnabled)
        elseif input.KeyCode == Binds.Aimbot then
            AimbotEnabled = not AimbotEnabled
            aimbotToggle.update(AimbotEnabled)
        elseif input.KeyCode == Binds.Esp then
            EspMaster = not EspMaster
            espMasterToggle.update(EspMaster)
        elseif input.KeyCode == Binds.SaveTP then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                SavedLocation = LocalPlayer.Character.HumanoidRootPart.CFrame
                Notify("Teleport", "Localização salva!")
            end
        elseif input.KeyCode == Binds.TeleportTP then
            if SavedLocation then LocalPlayer.Character.HumanoidRootPart.CFrame = SavedLocation end
        elseif input.KeyCode == Binds.AutoTP then
            AutoTpEnabled = not AutoTpEnabled
            autoTpToggle.update(AutoTpEnabled)
        end
    end
end)

-- Limpeza de Visuals
local function ClearVisuals(char)
    if char:FindFirstChild("Highlight") then char.Highlight:Destroy() end
    if char:FindFirstChild("ESPTag") then char.ESPTag:Destroy() end
    if char:FindFirstChild("Box") then char.Box:Destroy() end
end

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    if not ScriptActive then return end
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")

    -- Hitbox Expander Logic (CORRIGIDA)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pChar = p.Character
            local isTeammate = (p.Team == LocalPlayer.Team and p.Team ~= nil)
            
            if HitboxEnabled and not (HitboxTeamCheck and isTeammate) then
                local function resize(partName)
                    local part = pChar:FindFirstChild(partName)
                    -- O segredo está em desativar colisão E garantir que a parte não seja Massless: false
                    if part and part:IsA("BasePart") then
                        part.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        part.Transparency = ShowHitboxVisual and 0.6 or (partName == "HumanoidRootPart" and 1 or 0)
                        part.CanCollide = false
                        part.CanTouch = true -- Mantém o toque para o tiro registrar
                        part.Massless = true -- Evita que o peso da parte gigante trave o boneco
                    end
                end

                if HitboxPart == "Head" then
                    resize("Head")
                elseif HitboxPart == "HumanoidRootPart" then
                    resize("HumanoidRootPart")
                elseif HitboxPart == "All" then
                    for _, v in pairs(pChar:GetChildren()) do
                        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                            v.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                            v.Transparency = ShowHitboxVisual and 0.6 or 0
                            v.CanCollide = false
                            v.Massless = true
                        end
                    end
                end
            else
                -- Reset (Importante voltar ao normal)
                if pChar:FindFirstChild("Head") then 
                    pChar.Head.Size = Vector3.new(1.2, 1.2, 1.2) -- Tamanho padrão aproximado
                    pChar.Head.CanCollide = true
                    pChar.Head.Massless = false
                end
                -- Adicione o reset para outras partes se usar o modo "All"
            end
        end
    end

    -- Fly Hack
    if FlyEnabled then
        hum.PlatformStand = true
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
        root.Velocity = moveDir * FlySpeed
    else
        if hum and hum.PlatformStand then hum.PlatformStand = false end
    end

    -- Noclip / Speed / Jump
    local isAnyoneNear = false
    for _, otherP in pairs(Players:GetPlayers()) do
        if otherP ~= LocalPlayer and otherP.Character and otherP.Character:FindFirstChild("HumanoidRootPart") then
            if (root.Position - otherP.Character.HumanoidRootPart.Position).Magnitude < 25 then
                isAnyoneNear = true
                break
            end
        end
    end

    if NoclipEnabled and not isAnyoneNear then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if InfiniteJumpEnabled and UserInputService:IsKeyDown(Binds.InfJump) and not FlyEnabled then
        root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
    end
    if SpeedEnabled and not FlyEnabled and hum then
        hum.WalkSpeed = WalkSpeedValue
    end

    -- Watermark
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    WatermarkText.Text = string.format(
        "<font color='#%02X%02X%02X'><b>WHEN PANEL v2</b></font>\nFPS: %d | Ping: %dms\nHitbox: %d (%s)",
        MainColor.R * 255, MainColor.G * 255, MainColor.B * 255,
        fps, ping, HitboxSize, HitboxPart
    )

    -- Auto Teleport
    if AutoTpEnabled and SavedLocation and root then
        local currentPos = root.Position
        local savedPos = SavedLocation.Position
        if (Vector2.new(currentPos.X, currentPos.Z) - Vector2.new(savedPos.X, savedPos.Z)).Magnitude > 0.1 then 
            root.CFrame = CFrame.new(savedPos.X, currentPos.Y, savedPos.Z) * SavedLocation.Rotation
        end
    end

    -- COMBAT LOGIC
    if AimbotEnabled or SilentAimEnabled then
        local target = nil
        if AimType == "Closest" then target = GetClosestToMouse()
        elseif AimType == "Lowest Health" then target = GetLowestHealth()
        elseif AimType == "Selected" then target = TargetPlayer end

        if target and target.Character then
            local bone = TargetPart
            if RandomBoneEnabled then bone = (math.random(1, 10) > 5) and "Head" or "HumanoidRootPart" end
            if target.Character:FindFirstChild(bone) then
                local tPos = target.Character[bone].Position
                if AimbotEnabled then
                    local camPos = Camera.CFrame.Position
                    local newCF = CFrame.new(camPos, tPos)
                    Camera.CFrame = Camera.CFrame:Lerp(newCF, 1 / AimSmoothness)
                end
            end
        end
    end

    -- ESP LOGIC
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pChar = p.Character
            if not EspMaster or not ScreenGui.Enabled or (TeamCheckEnabled and p.Team == LocalPlayer.Team) then 
                ClearVisuals(pChar)
            else
                local t = pChar:FindFirstChild("ESPTag")
                if ShowNames or ShowDistance then
                    if not t then
                        t = Instance.new("BillboardGui", pChar)
                        t.Name = "ESPTag"
                        t.Size = UDim2.new(0, 200, 0, 50)
                        t.AlwaysOnTop = true
                        t.Adornee = pChar:FindFirstChild("Head")
                        t.ExtentsOffset = Vector3.new(0, 3, 0)
                        local l = Instance.new("TextLabel", t)
                        l.Name = "Label"
                        l.Size = UDim2.new(1,0,1,0)
                        l.TextColor3 = Color3.new(1,1,1)
                        l.BackgroundTransparency = 1
                        l.Font = Enum.Font.GothamBold
                        l.TextSize = 14
                        l.TextStrokeTransparency = 0
                    end
                    local d = math.floor((root.Position - pChar.HumanoidRootPart.Position).Magnitude)
                    t.Label.Text = (ShowNames and p.Name or "") .. (ShowDistance and " [" .. d .. "m]" or "")
                elseif t then t:Destroy() end
                
                if ShowChams then
                    if not pChar:FindFirstChild("Highlight") then Instance.new("Highlight", pChar).FillColor = Color3.new(1,0,0) end
                elseif pChar:FindFirstChild("Highlight") then pChar.Highlight:Destroy() end

                if ShowBoxes then
                    if not pChar:FindFirstChild("Box") then
                        local b = Instance.new("SelectionBox", pChar)
                        b.Name = "Box"
                        b.Adornee = pChar
                        b.Color3 = Color3.new(1,0,0)
                    end
                elseif pChar:FindFirstChild("Box") then pChar.Box:Destroy() end
            end
        end
    end
end)