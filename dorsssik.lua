-- hollyscriptx mog everyone
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local ToggleRefs = {}
local guiCreated = false
local pendingNotifications = {}

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid(c)
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart(c)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function PlayBell()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://6518811702"
    s.Volume = 5
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local function Notify(title, text, duration)
    if guiCreated then
        Library:Notify({Title = title, Description = text, Duration = duration or 2})
    else
        table.insert(pendingNotifications, {title = title, text = text, duration = duration or 2})
    end
end

function Revive()
    local character = GetCharacter()
    local isDead = false
    
    if not character then
        isDead = true
    else
        local humanoid = GetHumanoid(character)
        if not humanoid or humanoid.Health <= 0 then
            isDead = true
        end
    end
    
    if not isDead then
        Notify("Revive", "You are already alive", 2)
        PlayBell()
        return
    end
    
    Notify("Revive", "Attempting to revive...", 2)
    
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if remote then
        local reviveRemote = remote:FindFirstChild("Revive") or remote:FindFirstChild("Respawn") or remote:FindFirstChild("RequestRespawn")
        if reviveRemote then
            pcall(function()
                reviveRemote:FireServer()
                Notify("Revive", "Revive requested", 2)
                PlayBell()
                return
            end)
        end
    end
    
    local bindable = ReplicatedStorage:FindFirstChild("Bindables")
    if bindable then
        local reviveBindable = bindable:FindFirstChild("Revive") or bindable:FindFirstChild("Respawn")
        if reviveBindable then
            pcall(function()
                reviveBindable:Fire()
                Notify("Revive", "Revive requested", 2)
                PlayBell()
                return
            end)
        end
    end
    
    Notify("Revive", "Waiting for respawn...", 2)
    PlayBell()
    
    local respawned = false
    local connection = LocalPlayer.CharacterAdded:Connect(function(newChar)
        respawned = true
        Notify("Revive", "You have been revived", 2)
        PlayBell()
        connection:Disconnect()
    end)
    
    task.delay(10, function()
        if not respawned then
            Notify("Revive", "Respawn timeout, trying force revive...", 2)
            pcall(function()
                LocalPlayer:LoadCharacter()
                Notify("Revive", "Force respawn initiated", 2)
                PlayBell()
            end)
            connection:Disconnect()
        end
    end)
end

local AntiBananaEnabled = false
local AntiBananaConnection = nil
local LastBanCheck = 0

function ToggleAntiBanana(enabled)
    AntiBananaEnabled = enabled
    if AntiBananaConnection then AntiBananaConnection:Disconnect() end
    
    if enabled then
        pcall(function()
            LocalPlayer.Kick = function() return end
            game.Kick = function() return end
        end)
        
        AntiBananaConnection = RunService.Heartbeat:Connect(function()
            if not AntiBananaEnabled then return end
            local now = tick()
            if now - LastBanCheck < 0.5 then return end
            LastBanCheck = now
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name and string.find(obj.Name:lower(), "ban") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
        Notify("Anti Banana", "Enabled", 2)
    else
        Notify("Anti Banana", "Disabled", 2)
    end
    PlayBell()
end

local FlyEnabled = false
local FlyBodyVelocity = nil
local FlyConnection = nil
local FlySpeed = 50

function ToggleFly(enabled)
    FlyEnabled = enabled
    if FlyConnection then FlyConnection:Disconnect() end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) end
    
    if enabled then
        local char = GetCharacter()
        if not char then return end
        local root = GetRootPart(char)
        if not root then return end
        
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        FlyBodyVelocity.Parent = root
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not FlyEnabled then return end
            local char = GetCharacter()
            if not char then return end
            local root = GetRootPart(char)
            if not root or not FlyBodyVelocity then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            
            local moveDir = Vector3.new(0, 0, 0)
            local lookVector = cam.CFrame.LookVector
            local rightVector = cam.CFrame.RightVector
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            if moveDir.Magnitude > 0 then
                FlyBodyVelocity.Velocity = moveDir.Unit * FlySpeed
            else
                FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        Notify("Flight", "Enabled", 2)
    else
        Notify("Flight", "Disabled", 2)
    end
    PlayBell()
end

function SetFlySpeed(speed) FlySpeed = speed end

local noclipEnabled = false
local noclipStepped = nil

function ToggleNoclip(enabled)
    noclipEnabled = enabled
    if noclipStepped then noclipStepped:Disconnect() end
    
    if enabled then
        noclipStepped = RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local char = GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        Notify("Noclip", "Enabled", 2)
    else
        local char = GetCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        Notify("Noclip", "Disabled", 2)
    end
    PlayBell()
end

local SpeedHackEnabled = false
local SpeedValue = 32
local SpeedHackLoop = nil

function ToggleSpeedHack(enabled)
    SpeedHackEnabled = enabled
    if enabled then
        if SpeedHackLoop then task.cancel(SpeedHackLoop) end
        SpeedHackLoop = task.spawn(function()
            while SpeedHackEnabled do
                local c = GetCharacter()
                if c then
                    local h = GetHumanoid(c)
                    if h and h.Health > 0 then h.WalkSpeed = SpeedValue end
                end
                task.wait(0.1)
            end
        end)
        Notify("Speed Hack", "Speed: " .. SpeedValue, 2)
    else
        if SpeedHackLoop then task.cancel(SpeedHackLoop); SpeedHackLoop = nil end
        local c = GetCharacter()
        if c then
            local h = GetHumanoid(c)
            if h then h.WalkSpeed = 16 end
        end
        Notify("Speed Hack", "Disabled", 2)
    end
    PlayBell()
end

function SetSpeedValue(v) SpeedValue = math.min(v, 100) end

local FullbrightEnabled = false
local FullbrightSettings = {}
local FullbrightConnection = nil

function ToggleFullbright(enabled)
    FullbrightEnabled = enabled
    if enabled then
        FullbrightSettings.Brightness = Lighting.Brightness
        FullbrightSettings.ClockTime = Lighting.ClockTime
        FullbrightSettings.FogEnd = Lighting.FogEnd
        FullbrightSettings.GlobalShadows = Lighting.GlobalShadows
        
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        
        if FullbrightConnection then FullbrightConnection:Disconnect() end
        FullbrightConnection = Lighting.Changed:Connect(function(property)
            if FullbrightEnabled then
                if property == "Brightness" then Lighting.Brightness = 2
                elseif property == "ClockTime" then Lighting.ClockTime = 14
                elseif property == "FogEnd" then Lighting.FogEnd = 100000
                elseif property == "GlobalShadows" then Lighting.GlobalShadows = false
                end
            end
        end)
        Notify("Fullbright", "Enabled", 2)
    else
        for property, value in pairs(FullbrightSettings) do
            pcall(function() Lighting[property] = value end)
        end
        if FullbrightConnection then FullbrightConnection:Disconnect() end
        Notify("Fullbright", "Disabled", 2)
    end
    PlayBell()
end

local AntiScreechEnabled = false
local AntiScreechConnection = nil

function ToggleAntiScreech(enabled)
    AntiScreechEnabled = enabled
    if AntiScreechConnection then AntiScreechConnection:Disconnect() end
    
    if enabled then
        local function RemoveScreech()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "Screech" then pcall(function() obj:Destroy() end) end
            end
        end
        RemoveScreech()
        AntiScreechConnection = RunService.Heartbeat:Connect(function()
            if AntiScreechEnabled then RemoveScreech() end
        end)
        Notify("Anti Screech", "Enabled", 2)
    else
        Notify("Anti Screech", "Disabled", 2)
    end
    PlayBell()
end

local AntiSlipEnabled = false
local AntiSlipConnection = nil

function ToggleAntiSlip(enabled)
    AntiSlipEnabled = enabled
    if AntiSlipConnection then AntiSlipConnection:Disconnect() end
    
    if enabled then
        AntiSlipConnection = RunService.Heartbeat:Connect(function()
            if not AntiSlipEnabled then return end
            local char = GetCharacter()
            if not char then return end
            local hum = GetHumanoid(char)
            if hum then hum.WalkSpeed = SpeedHackEnabled and SpeedValue or 16 end
        end)
        Notify("Anti Slip", "Enabled", 2)
    else
        Notify("Anti Slip", "Disabled", 2)
    end
    PlayBell()
end

local InstantPromptEnabled = false
local InstantPromptConnection = nil

function ToggleInstantPrompt(enabled)
    InstantPromptEnabled = enabled
    if InstantPromptConnection then InstantPromptConnection:Disconnect() end
    
    if enabled then
        local function SetPrompts()
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
            end
        end
        SetPrompts()
        InstantPromptConnection = Workspace.DescendantAdded:Connect(function(desc)
            if InstantPromptEnabled and desc:IsA("ProximityPrompt") then desc.HoldDuration = 0 end
        end)
        Notify("Instant Prompt", "Enabled", 2)
    else
        Notify("Instant Prompt", "Disabled", 2)
    end
    PlayBell()
end

local AutoOpenDrawers = false
local AutoOpenConnection = nil
local AlreadyOpened = {}

function ToggleAutoOpenDrawers(enabled)
    AutoOpenDrawers = enabled
    
    if AutoOpenConnection then
        AutoOpenConnection:Disconnect()
        AutoOpenConnection = nil
    end
    
    if enabled then
        AlreadyOpened = {}
        
        AutoOpenConnection = RunService.Heartbeat:Connect(function()
            if not AutoOpenDrawers then return end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    local name = obj.Name:lower()
                    local isDrawer = (string.find(name, "drawer") or 
                                     string.find(name, "nightstand") or 
                                     string.find(name, "cabinet") or 
                                     string.find(name, "chest") or
                                     string.find(name, "table") or
                                     string.find(name, "desk")) and
                                     not string.find(name, "closet") and 
                                     not string.find(name, "wardrobe") and
                                     not string.find(name, "locker") and
                                     not string.find(name, "door")
                    
                    if isDrawer and not AlreadyOpened[obj] then
                        local prompt = obj:FindFirstChild("ProximityPrompt") or obj:FindFirstChildWhichIsA("ProximityPrompt")
                        
                        if not prompt then
                            for _, child in pairs(obj:GetChildren()) do
                                if child:IsA("ProximityPrompt") then
                                    prompt = child
                                    break
                                end
                            end
                        end
                        
                        if prompt then
                            local character = GetCharacter()
                            if character then
                                local rootPart = GetRootPart(character)
                                if rootPart then
                                    local promptPart = prompt.Parent
                                    local partPos = nil
                                    
                                    if promptPart and promptPart:IsA("BasePart") then
                                        partPos = promptPart.Position
                                    elseif promptPart then
                                        for _, p in pairs(promptPart:GetDescendants()) do
                                            if p:IsA("BasePart") then
                                                partPos = p.Position
                                                break
                                            end
                                        end
                                    end
                                    
                                    if partPos then
                                        local distance = (rootPart.Position - partPos).Magnitude
                                        if distance < 8 then
                                            pcall(function()
                                                if fireproximityprompt then
                                                    fireproximityprompt(prompt)
                                                elseif syn and syn.proximityprompt then
                                                    syn.proximityprompt(prompt)
                                                else
                                                    local oldDuration = prompt.HoldDuration
                                                    prompt.HoldDuration = 0
                                                    prompt:InputHoldBegin()
                                                    task.wait(0.05)
                                                    prompt:InputHoldEnd()
                                                    prompt.HoldDuration = oldDuration
                                                end
                                                AlreadyOpened[obj] = true
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            for obj in pairs(AlreadyOpened) do
                if not obj.Parent then
                    AlreadyOpened[obj] = nil
                end
            end
        end)
        
        Notify("Auto Open Drawers", "Enabled", 2)
    else
        AlreadyOpened = {}
        Notify("Auto Open Drawers", "Disabled", 2)
    end
    PlayBell()
end

local DoorsESP = {
    Enabled = false,
    Connection = nil,
    Objects = {}
}

function ToggleDoorsESP(enabled)
    DoorsESP.Enabled = enabled
    if DoorsESP.Connection then DoorsESP.Connection:Disconnect() end
    
    for _, data in pairs(DoorsESP.Objects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    DoorsESP.Objects = {}
    
    if not enabled then
        Notify("Doors ESP", "Disabled", 2)
        PlayBell()
        return
    end
    
    DoorsESP.Connection = RunService.RenderStepped:Connect(function()
        if not DoorsESP.Enabled then return end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Door" then
                local rootPart = obj:FindFirstChildWhichIsA("BasePart")
                if rootPart and not DoorsESP.Objects[obj] then
                    local h = Instance.new("Highlight")
                    h.FillTransparency = 0.4
                    h.OutlineTransparency = 0.1
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillColor = Color3.fromRGB(0, 255, 0)
                    h.OutlineColor = Color3.fromRGB(0, 255, 0)
                    h.Parent = CoreGui
                    h.Adornee = obj
                    
                    local b = Instance.new("BillboardGui")
                    b.Size = UDim2.new(0, 60, 0, 20)
                    b.StudsOffset = Vector3.new(0, 2, 0)
                    b.AlwaysOnTop = true
                    b.Parent = CoreGui
                    b.Adornee = rootPart
                    
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundTransparency = 1
                    l.Text = "DOOR"
                    l.TextColor3 = Color3.fromRGB(0, 255, 0)
                    l.TextScaled = true
                    l.Font = Enum.Font.GothamBold
                    l.Parent = b
                    
                    DoorsESP.Objects[obj] = {Highlight = h, Billboard = b}
                end
                if DoorsESP.Objects[obj] then
                    DoorsESP.Objects[obj].Highlight.Enabled = true
                    DoorsESP.Objects[obj].Billboard.Enabled = true
                end
            end
        end
    end)
    
    Notify("Doors ESP", "Enabled", 2)
    PlayBell()
end

local ClosetESP = {
    Enabled = false,
    Connection = nil,
    Objects = {}
}

function ToggleClosetESP(enabled)
    ClosetESP.Enabled = enabled
    if ClosetESP.Connection then ClosetESP.Connection:Disconnect() end
    
    for _, data in pairs(ClosetESP.Objects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    ClosetESP.Objects = {}
    
    if not enabled then
        Notify("Closet ESP", "Disabled", 2)
        PlayBell()
        return
    end
    
    ClosetESP.Connection = RunService.RenderStepped:Connect(function()
        if not ClosetESP.Enabled then return end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:lower() == "closet" or obj.Name:lower() == "wardrobe") then
                local rootPart = obj:FindFirstChildWhichIsA("BasePart")
                if rootPart and not ClosetESP.Objects[obj] then
                    local h = Instance.new("Highlight")
                    h.FillTransparency = 0.4
                    h.OutlineTransparency = 0.1
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillColor = Color3.fromRGB(150, 0, 255)
                    h.OutlineColor = Color3.fromRGB(150, 0, 255)
                    h.Parent = CoreGui
                    h.Adornee = obj
                    
                    local b = Instance.new("BillboardGui")
                    b.Size = UDim2.new(0, 60, 0, 20)
                    b.StudsOffset = Vector3.new(0, 2, 0)
                    b.AlwaysOnTop = true
                    b.Parent = CoreGui
                    b.Adornee = rootPart
                    
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundTransparency = 1
                    l.Text = "CLOSET"
                    l.TextColor3 = Color3.fromRGB(150, 0, 255)
                    l.TextScaled = true
                    l.Font = Enum.Font.GothamBold
                    l.Parent = b
                    
                    ClosetESP.Objects[obj] = {Highlight = h, Billboard = b}
                end
                if ClosetESP.Objects[obj] then
                    ClosetESP.Objects[obj].Highlight.Enabled = true
                    ClosetESP.Objects[obj].Billboard.Enabled = true
                end
            end
        end
    end)
    
    Notify("Closet ESP", "Enabled", 2)
    PlayBell()
end

local ItemsESP = {
    Enabled = false,
    Connection = nil,
    Objects = {}
}

function ToggleItemsESP(enabled)
    ItemsESP.Enabled = enabled
    if ItemsESP.Connection then ItemsESP.Connection:Disconnect() end
    
    for _, data in pairs(ItemsESP.Objects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    ItemsESP.Objects = {}
    
    if not enabled then
        Notify("Items ESP", "Disabled", 2)
        PlayBell()
        return
    end
    
    ItemsESP.Connection = RunService.RenderStepped:Connect(function()
        if not ItemsESP.Enabled then return end
        
        for _, item in pairs(Workspace:GetDescendants()) do
            if item:IsA("Model") and not ItemsESP.Objects[item] then
                local name = item.Name
                local itemType = nil
                
                if string.find(name, "Key") then itemType = "KEY"
                elseif string.find(name, "Coin") then itemType = "COIN"
                elseif string.find(name, "Gold") then itemType = "COIN"
                elseif string.find(name, "Lockpick") then itemType = "LOCKPICK"
                elseif string.find(name, "Vitamin") then itemType = "VITAMINS"
                elseif string.find(name, "Bandage") then itemType = "BANDAGE"
                elseif string.find(name, "Flashlight") then itemType = "FLASHLIGHT"
                elseif string.find(name, "Battery") then itemType = "BATTERY"
                elseif string.find(name, "Crucifix") then itemType = "CRUCIFIX"
                elseif string.find(name, "Lighter") then itemType = "LIGHTER"
                end
                
                if itemType then
                    local root = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                    if root then
                        local h = Instance.new("Highlight")
                        h.FillTransparency = 0.3
                        h.OutlineTransparency = 0
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillColor = Color3.fromRGB(0, 200, 255)
                        h.OutlineColor = Color3.fromRGB(0, 200, 255)
                        h.Parent = CoreGui
                        h.Adornee = item
                        
                        local b = Instance.new("BillboardGui")
                        b.Size = UDim2.new(0, 50, 0, 20)
                        b.StudsOffset = Vector3.new(0, 1, 0)
                        b.AlwaysOnTop = true
                        b.Parent = CoreGui
                        b.Adornee = root
                        
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 1, 0)
                        l.BackgroundTransparency = 1
                        l.Text = itemType
                        l.TextColor3 = Color3.fromRGB(0, 200, 255)
                        l.TextScaled = true
                        l.Font = Enum.Font.GothamBold
                        l.Parent = b
                        
                        ItemsESP.Objects[item] = {Highlight = h, Billboard = b}
                    end
                end
            end
        end
        
        for item, data in pairs(ItemsESP.Objects) do
            if not item.Parent then
                data.Highlight.Enabled = false
                data.Billboard.Enabled = false
                ItemsESP.Objects[item] = nil
            end
        end
    end)
    
    Notify("Items ESP", "Enabled", 2)
    PlayBell()
end

local BooksESP = {
    Enabled = false,
    Connection = nil,
    Objects = {}
}

function ToggleBooksESP(enabled)
    BooksESP.Enabled = enabled
    if BooksESP.Connection then BooksESP.Connection:Disconnect() end
    
    for _, data in pairs(BooksESP.Objects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    BooksESP.Objects = {}
    
    if not enabled then
        Notify("Books ESP", "Disabled", 2)
        PlayBell()
        return
    end
    
    BooksESP.Connection = RunService.RenderStepped:Connect(function()
        if not BooksESP.Enabled then return end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Book" then
                if not BooksESP.Objects[obj] then
                    local h = Instance.new("Highlight")
                    h.FillTransparency = 0.3
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillColor = Color3.fromRGB(255, 150, 0)
                    h.OutlineColor = Color3.fromRGB(255, 150, 0)
                    h.Parent = CoreGui
                    h.Adornee = obj
                    
                    local b = Instance.new("BillboardGui")
                    b.Size = UDim2.new(0, 50, 0, 20)
                    b.StudsOffset = Vector3.new(0, 1, 0)
                    b.AlwaysOnTop = true
                    b.Parent = CoreGui
                    b.Adornee = obj
                    
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundTransparency = 1
                    l.Text = "BOOK"
                    l.TextColor3 = Color3.fromRGB(255, 150, 0)
                    l.TextScaled = true
                    l.Font = Enum.Font.GothamBold
                    l.Parent = b
                    
                    BooksESP.Objects[obj] = {Highlight = h, Billboard = b}
                end
                if BooksESP.Objects[obj] then
                    BooksESP.Objects[obj].Highlight.Enabled = true
                    BooksESP.Objects[obj].Billboard.Enabled = true
                end
            end
        end
    end)
    
    Notify("Books ESP", "Enabled", 2)
    PlayBell()
end

local EntitiesESP = {
    Enabled = false,
    Connection = nil,
    ESPObjects = {},
    UpdateCooldown = 0,
    LastUpdate = 0
}

local EntityDetectNames = {
    "Rush", "Ambush", "Seek", "Figure", "Screech", "Hide", "Jack",
    "Eyes", "Dupe", "Glitch", "Void", "A-60", "A-90", "A-120"
}

local function GetEntityColor(name)
    local colors = {
        Rush = Color3.fromRGB(255, 0, 0),
        Ambush = Color3.fromRGB(200, 0, 0),
        Seek = Color3.fromRGB(255, 50, 0),
        Figure = Color3.fromRGB(150, 0, 200),
        Screech = Color3.fromRGB(0, 255, 0),
        Hide = Color3.fromRGB(100, 50, 0),
        Jack = Color3.fromRGB(255, 200, 0),
        Eyes = Color3.fromRGB(0, 200, 255),
        Dupe = Color3.fromRGB(255, 100, 0),
        Glitch = Color3.fromRGB(0, 255, 255),
        Void = Color3.fromRGB(100, 0, 100),
        ["A-60"] = Color3.fromRGB(255, 0, 100),
        ["A-90"] = Color3.fromRGB(255, 0, 150),
        ["A-120"] = Color3.fromRGB(255, 0, 200)
    }
    return colors[name] or Color3.fromRGB(255, 255, 255)
end

function ToggleEntitiesESP(enabled)
    EntitiesESP.Enabled = enabled
    
    if EntitiesESP.Connection then
        EntitiesESP.Connection:Disconnect()
        EntitiesESP.Connection = nil
    end
    
    for _, obj in pairs(EntitiesESP.ESPObjects) do
        pcall(function() 
            if obj.Highlight then obj.Highlight:Destroy() end
            if obj.Billboard then obj.Billboard:Destroy() end
        end)
    end
    EntitiesESP.ESPObjects = {}
    
    if not enabled then
        Notify("Entities ESP", "Disabled", 2)
        PlayBell()
        return
    end
    
    EntitiesESP.Connection = RunService.Heartbeat:Connect(function()
        if not EntitiesESP.Enabled then return end
        
        local currentTime = tick()
        if currentTime - EntitiesESP.LastUpdate < 0.15 then return end
        EntitiesESP.LastUpdate = currentTime
        
        local foundEntities = {}
        
        for _, entity in pairs(Workspace:GetDescendants()) do
            if entity:IsA("Model") then
                local entityName = entity.Name
                for _, detectName in ipairs(EntityDetectNames) do
                    if string.find(entityName, detectName) then
                        foundEntities[entity] = detectName
                        break
                    end
                end
            end
        end
        
        for entity, name in pairs(foundEntities) do
            local rootPart = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChildWhichIsA("BasePart")
            if rootPart then
                if not EntitiesESP.ESPObjects[entity] then
                    local highlight = Instance.new("Highlight")
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0.1
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillColor = GetEntityColor(name)
                    highlight.OutlineColor = GetEntityColor(name)
                    highlight.Parent = CoreGui
                    
                    local bill = Instance.new("BillboardGui")
                    bill.Size = UDim2.new(0, 120, 0, 30)
                    bill.StudsOffset = Vector3.new(0, 3, 0)
                    bill.AlwaysOnTop = true
                    bill.Parent = CoreGui
                    bill.Adornee = rootPart
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = name
                    label.TextColor3 = GetEntityColor(name)
                    label.TextScaled = true
                    label.Font = Enum.Font.GothamBold
                    label.TextStrokeTransparency = 0
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.Parent = bill
                    
                    EntitiesESP.ESPObjects[entity] = {
                        Highlight = highlight,
                        Billboard = bill,
                        Name = name
                    }
                end
                
                local data = EntitiesESP.ESPObjects[entity]
                data.Highlight.Adornee = entity
                data.Highlight.Enabled = true
                data.Billboard.Enabled = true
            end
        end
        
        for entity, data in pairs(EntitiesESP.ESPObjects) do
            if not foundEntities[entity] then
                pcall(function()
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                end)
            end
        end
    end)
    
    Notify("Entities ESP", "Enabled", 2)
    PlayBell()
end

local EntitiesTracers = {
    Enabled = false,
    Connection = nil,
    Lines = {},
    LastUpdate = 0
}

function ToggleEntitiesTracers(enabled)
    EntitiesTracers.Enabled = enabled
    
    if EntitiesTracers.Connection then
        EntitiesTracers.Connection:Disconnect()
        EntitiesTracers.Connection = nil
    end
    
    for _, line in pairs(EntitiesTracers.Lines) do
        pcall(function() line:Destroy() end)
    end
    EntitiesTracers.Lines = {}
    
    if not enabled then
        Notify("Entities Tracers", "Disabled", 2)
        PlayBell()
        return
    end
    
    EntitiesTracers.Connection = RunService.Heartbeat:Connect(function()
        if not EntitiesTracers.Enabled then return end
        
        local character = GetCharacter()
        if not character then 
            for _, line in pairs(EntitiesTracers.Lines) do
                pcall(function() line:Destroy() end)
            end
            EntitiesTracers.Lines = {}
            return 
        end
        
        local rootPart = GetRootPart(character)
        if not rootPart then return end
        
        local currentCamera = workspace.CurrentCamera
        if not currentCamera then return end
        
        for _, line in pairs(EntitiesTracers.Lines) do
            pcall(function() line:Destroy() end)
        end
        EntitiesTracers.Lines = {}
        
        local currentTime = tick()
        if currentTime - EntitiesTracers.LastUpdate < 0.1 then return end
        EntitiesTracers.LastUpdate = currentTime
        
        local rootPos = rootPart.Position
        
        for _, entity in pairs(Workspace:GetDescendants()) do
            if entity:IsA("Model") then
                local entityName = entity.Name
                local detected = false
                local detectedName = nil
                for _, detectName in ipairs(EntityDetectNames) do
                    if string.find(entityName, detectName) then
                        detected = true
                        detectedName = detectName
                        break
                    end
                end
                
                if detected then
                    local rootPartEntity = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChildWhichIsA("BasePart")
                    if rootPartEntity and rootPartEntity.Position then
                        local entityPos = rootPartEntity.Position
                        local distance = (rootPos - entityPos).Magnitude
                        
                        if distance < 250 then
                            local vector, onScreen = currentCamera:WorldToViewportPoint(entityPos)
                            local vector2, onScreen2 = currentCamera:WorldToViewportPoint(rootPos)
                            
                            if onScreen and onScreen2 then
                                local line = Drawing.new("Line")
                                line.From = Vector2.new(vector2.X, vector2.Y)
                                line.To = Vector2.new(vector.X, vector.Y)
                                line.Thickness = 2
                                local color = GetEntityColor(detectedName)
                                line.Color = Color3.new(color.R, color.G, color.B)
                                line.Transparency = 0.5
                                line.Visible = true
                                table.insert(EntitiesTracers.Lines, line)
                            end
                        end
                    end
                end
            end
        end
    end)
    
    Notify("Entities Tracers", "Enabled", 2)
    PlayBell()
end

local NotifyEntitiesEnabled = false
local NotifyEntitiesConnection = nil
local LastNotified = {}

function ToggleNotifyEntities(enabled)
    NotifyEntitiesEnabled = enabled
    
    if NotifyEntitiesConnection then
        NotifyEntitiesConnection:Disconnect()
        NotifyEntitiesConnection = nil
    end
    
    if not enabled then
        Notify("Notify Entities", "Disabled", 2)
        PlayBell()
        return
    end
    
    LastNotified = {}
    
    NotifyEntitiesConnection = RunService.Heartbeat:Connect(function()
        if not NotifyEntitiesEnabled then return end
        
        local character = GetCharacter()
        if not character then return end
        local rootPart = GetRootPart(character)
        if not rootPart then return end
        local currentPos = rootPart.Position
        
        for _, entity in pairs(Workspace:GetDescendants()) do
            if entity:IsA("Model") then
                local entityName = entity.Name
                local detectedName = nil
                for _, detectName in ipairs(EntityDetectNames) do
                    if string.find(entityName, detectName) then
                        detectedName = detectName
                        break
                    end
                end
                
                if detectedName then
                    local rootPartEntity = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChildWhichIsA("BasePart")
                    if rootPartEntity then
                        local distance = (currentPos - rootPartEntity.Position).Magnitude
                        local key = detectedName
                        local currentTime = tick()
                        
                        if distance < 500 then
                            if not LastNotified[key] or (currentTime - LastNotified[key] > 8) then
                                LastNotified[key] = currentTime
                                Notify(detectedName, "Distance: " .. math.floor(distance) .. " studs", 3)
                                PlayBell()
                            end
                        end
                    end
                end
            end
        end
    end)
    
    Notify("Notify Entities", "Enabled", 2)
    PlayBell()
end

local Window = Library:CreateWindow({
    Title = "HollyScriptX",
    Icon = "star",
    Footer = "discord.gg/PufsSPGK2x | Doors (by @t3e6)",
    Center = true,
    Resizable = true,
    AutoShow = true,
    ShowCustomCursor = false,
    ToggleKeybind = Enum.KeyCode.Z,
    CornerRadius = 99999999
})

Library:SetDPIScale(85)
guiCreated = true

local CombatTab = Window:AddTab("Combat", "sword")
local ESPTab = Window:AddTab("ESP", "eye")
local MovementTab = Window:AddTab("Movement", "move-diagonal-2")
local WorldTab = Window:AddTab("World", "warehouse")
local SettingsTab = Window:AddTab("Settings", "settings")

local CombatGroup = CombatTab:AddLeftGroupbox("Combat", "shield")

ToggleRefs.AntiBanana = CombatGroup:AddToggle("AntiBanana", {
    Text = "Anti Banana", 
    Default = false, 
    Callback = ToggleAntiBanana,
    Tooltip = "Deleted bananas objects"
})

ToggleRefs.AntiScreech = CombatGroup:AddToggle("AntiScreech", {
    Text = "Anti Screech", 
    Default = false, 
    Callback = ToggleAntiScreech,
    Tooltip = "Automatically removes Screech entities"
})

ToggleRefs.AntiSlip = CombatGroup:AddToggle("AntiSlip", {
    Text = "Anti Slip", 
    Default = false, 
    Callback = ToggleAntiSlip,
    Tooltip = "Prevents slipping on slippery surfaces"
})

CombatGroup:AddButton({
    Text = "Use Revive", 
    Callback = function() Revive() end,
    Tooltip = "Attempts to revive you when dead"
})

local DoorsGroup = ESPTab:AddLeftGroupbox("ESP", "eye")

ToggleRefs.DoorsESP = DoorsGroup:AddToggle("DoorsESP", {
    Text = "Doors ESP", 
    Default = false, 
    Callback = ToggleDoorsESP,
    Tooltip = "Highlights all doors in green"
})

ToggleRefs.ClosetESP = DoorsGroup:AddToggle("ClosetESP", {
    Text = "Closet ESP", 
    Default = false, 
    Callback = ToggleClosetESP,
    Tooltip = "Highlights closets and wardrobes in purple"
})

ToggleRefs.ItemsESP = DoorsGroup:AddToggle("ItemsESP", {
    Text = "Items ESP", 
    Default = false, 
    Callback = ToggleItemsESP,
    Tooltip = "Highlights items like keys, coins, lockpicks, etc."
})

ToggleRefs.BooksESP = DoorsGroup:AddToggle("BooksESP", {
    Text = "Books ESP", 
    Default = false, 
    Callback = ToggleBooksESP,
    Tooltip = "Highlights books in orange"
})

local EntitiesESPGroup = ESPTab:AddLeftGroupbox("Entities", "eye")

ToggleRefs.EntitiesESP = EntitiesESPGroup:AddToggle("EntitiesESP", {
    Text = "Entities ESP",
    Default = false,
    Callback = ToggleEntitiesESP,
    Tooltip = "Highlights all entities with colored outlines based on type"
})

ToggleRefs.EntitiesTracers = EntitiesESPGroup:AddToggle("EntitiesTracers", {
    Text = "Entities Tracers",
    Default = false,
    Callback = ToggleEntitiesTracers,
    Tooltip = "Draws lines from you to nearby entities"
})

ToggleRefs.NotifyEntities = EntitiesESPGroup:AddToggle("NotifyEntities", {
    Text = "Notify Entities",
    Default = false,
    Callback = ToggleNotifyEntities,
    Tooltip = "Shows notifications when entities are nearby"
})

local MovementGroup = MovementTab:AddLeftGroupbox("Movement", "component")

ToggleRefs.SpeedHack = MovementGroup:AddToggle("SpeedHack", {
    Text = "Speed Hack", 
    Default = false, 
    Callback = ToggleSpeedHack,
    Tooltip = "Increases your walking speed"
})

MovementGroup:AddSlider("SpeedValue", {
    Text = "Speed Value", 
    Default = 32, 
    Min = 16, 
    Max = 100, 
    Callback = SetSpeedValue,
    Tooltip = "Sets the walking speed value (16-100)"
})

ToggleRefs.Noclip = MovementGroup:AddToggle("Noclip", {
    Text = "Noclip", 
    Default = false, 
    Callback = ToggleNoclip,
    Tooltip = "Allows you to walk through walls"
})

ToggleRefs.Noclip:AddKeyPicker("NoclipBind", {
    Default = "V", 
    Mode = "Toggle", 
    Text = "Noclip Keybind", 
    Callback = function(v) ToggleNoclip(v) end,
    Tooltip = "Keybind to toggle noclip"
})

ToggleRefs.Flight = MovementGroup:AddToggle("Flight", {
    Text = "Flight", 
    Default = false, 
    Callback = ToggleFly,
    Tooltip = "Allows you to fly around the map"
})

ToggleRefs.Flight:AddKeyPicker("FlightBind", {
    Default = "F", 
    Mode = "Toggle", 
    Text = "Flight Keybind", 
    Callback = function(v) ToggleFly(v) end,
    Tooltip = "Keybind to toggle flight"
})

MovementGroup:AddSlider("FlySpeed", {
    Text = "Flight Speed", 
    Default = 50, 
    Min = 20, 
    Max = 200, 
    Callback = SetFlySpeed,
    Tooltip = "Sets the flight speed (20-200)"
})

local VisualGroup = WorldTab:AddLeftGroupbox("Visuals", "sun")

ToggleRefs.Fullbright = VisualGroup:AddToggle("Fullbright", {
    Text = "Fullbright", 
    Default = false, 
    Callback = ToggleFullbright,
    Tooltip = "Makes the world fully bright, no darkness"
})

local InteractionGroup = WorldTab:AddRightGroupbox("Interaction", "hand")

ToggleRefs.AutoOpenDrawers = InteractionGroup:AddToggle("AutoOpenDrawers", {
    Text = "Auto Open Drawers", 
    Default = false, 
    Callback = ToggleAutoOpenDrawers,
    Tooltip = "Automatically opens drawers when nearby"
})

ToggleRefs.InstantPrompt = InteractionGroup:AddToggle("InstantPrompt", {
    Text = "Instant Prompt", 
    Default = false, 
    Callback = ToggleInstantPrompt,
    Tooltip = "Makes proximity prompts activate instantly with no hold duration"
})

local MenuBox = SettingsTab:AddLeftGroupbox("Menu", "menu")
local InfoBox = SettingsTab:AddRightGroupbox("Info", "info")

local customCursorEnabled = false
local customCursorGui = nil
local cursorRotationConnection = nil

local function CreateCustomCursor()

    if customCursorGui then
        pcall(function() customCursorGui:Destroy() end)
        customCursorGui = nil
    end
    
    local player = Players.LocalPlayer
    local mouse = player:GetMouse()
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "HollyScriptX_Cursor"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 40, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    local crosshairH = Instance.new("Frame")
    crosshairH.Size = UDim2.new(0, 24, 0, 3)
    crosshairH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshairH.BorderSizePixel = 1
    crosshairH.BorderColor3 = Color3.fromRGB(0, 0, 0)
    crosshairH.Position = UDim2.new(0.5, -12, 0.5, -1.5)
    crosshairH.Parent = container
    
    local crosshairV = Instance.new("Frame")
    crosshairV.Size = UDim2.new(0, 3, 0, 24)
    crosshairV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshairV.BorderColor3 = Color3.fromRGB(0, 0, 0)
    crosshairV.Position = UDim2.new(0.5, -1.5, 0.5, -12)
    crosshairV.Parent = container
    
    local crosshairD1 = Instance.new("Frame")
    crosshairD1.Size = UDim2.new(0, 16, 0, 2)
    crosshairD1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshairD1.BorderSizePixel = 1
    crosshairD1.BorderColor3 = Color3.fromRGB(0, 0, 0)
    crosshairD1.Position = UDim2.new(0.5, -8, 0.5, -1)
    crosshairD1.Rotation = 45
    crosshairD1.Parent = container
    
    local crosshairD2 = Instance.new("Frame")
    crosshairD2.Size = UDim2.new(0, 16, 0, 2)
    crosshairD2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshairD2.BorderSizePixel = 1
    crosshairD2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    crosshairD2.Position = UDim2.new(0.5, -8, 0.5, -1)
    crosshairD2.Rotation = -45
    crosshairD2.Parent = container
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 100, 0, 18)
    text.BackgroundTransparency = 1
    text.Text = "HollyScriptX"
    text.TextColor3 = Color3.fromRGB(200, 200, 200)
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextStrokeTransparency = 0
    text.TextSize = 12
    text.Font = Enum.Font.GothamBold
    text.TextXAlignment = Enum.TextXAlignment.Center
    text.Parent = gui
    
    local rotationSpeed = 150
    

    if cursorRotationConnection then
        cursorRotationConnection:Disconnect()
        cursorRotationConnection = nil
    end
    
    cursorRotationConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if not customCursorEnabled then 
            return 
        end
        if not customCursorGui or not customCursorGui.Parent then

            if cursorRotationConnection then
                cursorRotationConnection:Disconnect()
                cursorRotationConnection = nil
            end
            return
        end
        container.Rotation = container.Rotation + rotationSpeed * deltaTime
        
        local x = mouse.X
        local y = mouse.Y
        container.Position = UDim2.new(0, x - 20, 0, y - 20)
        text.Position = UDim2.new(0, x - 50, 0, y - -20)
    end)
    
    customCursorGui = gui
end

local function DestroyCustomCursor()
    if cursorRotationConnection then
        cursorRotationConnection:Disconnect()
        cursorRotationConnection = nil
    end

    if customCursorGui then
        pcall(function() 
            customCursorGui:Destroy() 
        end)
        customCursorGui = nil
    end
end

MenuBox:AddToggle("KeybindMenuOpen", {
    Text = "Open Keybind Menu",
    Tooltip = "Shows Library Keybinds menu",
    Default = Library.KeybindFrame.Visible,
    Callback = function(State)
        Library.KeybindFrame.Visible = State
    end
})

local cursorToggle = MenuBox:AddToggle("Wcursor", {
    Text = "Custom Cursor",
    Default = true,
    Tooltip = "Shows Custom Script Cursor",
    Callback = function(enabled)
        customCursorEnabled = enabled
        if enabled then
            CreateCustomCursor()
        else
            DestroyCustomCursor()
        end
        MainModule.PlayBell()
    end
})


task.spawn(function()
    task.wait(0.5)
    customCursorEnabled = true
    if cursorToggle then
        cursorToggle:SetValue(true)
    end
    CreateCustomCursor()
end)

MenuBox:AddDropdown("NotificationSide", {
    Callback = function(Value) Library:SetNotifySide(Value) end, 
    Text = "Notification Side", 
    Default = "Right", 
    Values = {"Left", "Right"},
    Tooltip = "Choose which side notifications appear on"
})

MenuBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    NoUI = true, 
    Default = "Z", 
    Text = "Menu Keybind",
    Tooltip = "Keybind to open/close the menu"
})

MenuBox:AddButton({
    Text = "Unload Script", 
    Callback = function()
        ToggleItemsESP(false) ToggleBooksESP(false) ToggleDoorsESP(false) ToggleClosetESP(false)
        ToggleSpeedHack(false) ToggleNoclip(false) ToggleFly(false)
        ToggleAntiScreech(false) ToggleAntiSlip(false) ToggleAntiBanana(false)
        ToggleFullbright(false) ToggleAutoOpenDrawers(false) ToggleInstantPrompt(false)
        Library:Unload()
    end,
    Tooltip = "Unloads the script and removes all features"
})

local executorName = "Unknown"
if identifyexecutor and type(identifyexecutor) == "function" then executorName = identifyexecutor() end

InfoBox:AddLabel("Executor: " .. executorName)
InfoBox:AddDivider()
InfoBox:AddLabel("if you found any bug dm me:")
InfoBox:AddLabel("@t3e6 (in discord)")
InfoBox:AddLabel("Discord.gg/PufsSPGK2x")
InfoBox:AddButton({
    Text = "Copy Discord Tag", 
    Callback = function()
        if setclipboard then setclipboard("t3e6") Library:Notify("Copied", "Discord Tag Copied!", 2) PlayBell() end
    end,
    Tooltip = "Copies discord tag @t3e6 to clipboard"
})

Library.ToggleKeybind = Library.Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("HollyScriptX")
SaveManager:SetFolder("HollyScriptX")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()

Library.Scheme.BackgroundColor = Color3.fromRGB(0, 0, 0)
Library.Scheme.MainColor = Color3.fromRGB(25, 25, 25)
Library.Scheme.AccentColor = Color3.fromRGB(115, 210, 193)
Library.Scheme.OutlineColor = Color3.fromRGB(41, 40, 40)
Library.Scheme.FontColor = Color3.fromRGB(255, 255, 255)
Library.Scheme.Font = Font.fromEnum(Enum.Font.Gotham)
Library:UpdateColorsUsingRegistry()
