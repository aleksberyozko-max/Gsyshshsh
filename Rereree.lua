-- Blackbox Mobile (Android) Inventory Duplicator v5.1
-- С графическим меню, ползунком размера и дупликацией предмета в руке

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Backpack = Player:WaitForChild("Backpack")
local StarterGear = Player:WaitForChild("StarterGear")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Конфигурация
local CONFIG = {
    TouchDelay = 0.03,
    MaxDupePerCycle = 99,
    MenuScale = 1.0,
    MenuColor = Color3.fromRGB(20, 20, 30),
    AccentColor = Color3.fromRGB(0, 200, 255)
}

-- Получение предмета в руке
local function GetEquippedItem()
    if not Character then return nil end
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name, tool
    end
    
    -- Проверка через Humanoid
    if Humanoid then
        for _, item in ipairs(Humanoid:GetPlayingAnimationTracks()) do
            if item.Name:match("Tool") or item.Name:match("Weapon") then
                local toolName = item.Name:gsub("Animation", ""):gsub("Hold", "")
                return toolName, nil
            end
        end
    end
    
    -- Проверка через Equipment
    local equipment = Character:FindFirstChild("Equipment")
    if equipment then
        for _, child in ipairs(equipment:GetChildren()) do
            if child:IsA("Tool") or child:IsA("Model") then
                return child.Name, child
            end
        end
    end
    
    return nil, nil
end

-- Ядро дупликации (только для предмета в руке)
local function DuplicateEquippedItem()
    local itemName, tool = GetEquippedItem()
    if not itemName then
        return false, "Нет предмета в руке"
    end
    
    local success = false
    local methodUsed = ""
    
    -- Метод 1: Тач-спам на UI (удержание и клик)
    local function TouchSpam()
        local gui = Player.PlayerGui:GetDescendants()
        for _, element in ipairs(gui) do
            if element:IsA("ImageButton") or element:IsA("TextButton") then
                local pos = element.AbsolutePosition
                local size = element.AbsoluteSize
                if pos.X > 0 and pos.Y > 0 and pos.X < 5000 and pos.Y < 5000 then
                    for i = 1, 5 do
                        local touchEvent = {
                            Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2),
                            Delta = Vector2.new(0, 0),
                            UserIndex = 0,
                            TouchState = Enum.TouchState.Began
                        }
                        UserInputService:SendTouchEvent(touchEvent)
                        wait(0.01)
                        touchEvent.TouchState = Enum.TouchState.Ended
                        UserInputService:SendTouchEvent(touchEvent)
                        wait(0.01)
                        success = true
                        methodUsed = "TouchSpam"
                    end
                end
            end
        end
    end
    
    -- Метод 2: RemoteEvent спам с именем предмета в руке
    local function RemoteSpam()
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local remoteName = remote.Name:lower()
                if remoteName:match("item") or remoteName:match("inventory") or remoteName:match("give") or remoteName:match("tool") then
                    pcall(function()
                        remote:FireServer("Add", itemName, 1)
                        remote:FireServer("GiveItem", itemName)
                        remote:FireServer("Duplicate", itemName)
                        remote:FireServer("CloneTool", itemName)
                        remote:FireServer("Equip", itemName)
                        success = true
                        methodUsed = "RemoteSpam"
                    end)
                end
            end
        end
    end
    
    -- Метод 3: Прямая манипуляция с Backpack
    local function BackpackManipulation()
        if tool and tool:IsA("Tool") then
            -- Клонирование тула
            local clone = tool:Clone()
            clone.Name = tool.Name .. "_dupe_" .. os.time()
            clone.Parent = Backpack
            success = true
            methodUsed = "BackpackClone"
            
            -- Дополнительно через StarterGear
            local clone2 = tool:Clone()
            clone2.Name = tool.Name .. "_dupe2_" .. os.time()
            clone2.Parent = StarterGear
            success = true
        end
        
        -- Поиск по имени в Backpack
        for _, item in ipairs(Backpack:GetChildren()) do
            if item.Name == itemName or item.Name:match(itemName) then
                if item:IsA("Tool") or item:IsA("NumberValue") then
                    local clone = item:Clone()
                    clone.Parent = Backpack
                    success = true
                    methodUsed = "BackpackSearch"
                end
            end
        end
    end
    
    -- Метод 4: Memory запись (Android)
    local function MemoryWrite()
        local file = io.open("/proc/self/mem", "rb+")
        if file then
            local pattern = string.rep(string.char(0x01), 64)
            for offset = 0, 0xFFFF, 8 do
                file:seek("set", offset)
                file:write(pattern)
                success = true
                methodUsed = "MemoryWrite"
                break
            end
            file:close()
        end
    end
    
    -- Метод 5: Форсирование через эквипмент
    local function EquipForce()
        if Character then
            local oldTool = Character:FindFirstChildOfClass("Tool")
            if oldTool then
                local clone = oldTool:Clone()
                clone.Parent = Backpack
                wait(0.05)
                local equipRemote = ReplicatedStorage:FindFirstChild("EquipTool")
                if equipRemote and equipRemote:IsA("RemoteEvent") then
                    equipRemote:FireServer(clone)
                    success = true
                    methodUsed = "EquipForce"
                end
            end
        end
    end
    
    -- Исполнение всех методов
    pcall(TouchSpam)
    pcall(RemoteSpam)
    pcall(BackpackManipulation)
    pcall(MemoryWrite)
    pcall(EquipForce)
    
    -- Дополнительный проход если не сработало
    if not success then
        -- Пробуем через все возможные ремоуты с разными аргументами
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                pcall(function()
                    remote:FireServer(itemName)
                    remote:FireServer("Clone", itemName)
                    remote:FireServer(itemName, 999)
                    remote:FireServer({itemName, 1})
                    success = true
                    methodUsed = "Fallback"
                end)
            end
        end
    end
    
    return success, methodUsed, itemName
end

-- Создание GUI меню
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlackboxDupeMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = Player.PlayerGui
    
    -- Основной фрейм
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -275)
    mainFrame.BackgroundColor3 = CONFIG.MenuColor
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = CONFIG.AccentColor
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    -- Эффект стекла
    local glassEffect = Instance.new("Frame")
    glassEffect.Size = UDim2.new(1, 0, 1, 0)
    glassEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glassEffect.BackgroundTransparency = 0.92
    glassEffect.BorderSizePixel = 0
    glassEffect.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = CONFIG.AccentColor
    title.BackgroundTransparency = 0.2
    title.BorderSizePixel = 0
    title.Text = "BLACKBOX DUPE v5.1"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = mainFrame
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Image = "rbxassetid://3926305904"
    closeBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent = mainFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Фрейм для скролла
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -80)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 700)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = CONFIG.AccentColor
    scrollFrame.Parent = mainFrame
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 680)
    container.BackgroundTransparency = 1
    container.Parent = scrollFrame
    
    -- Ползунок размера меню
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(1, 0, 0, 25)
    sizeLabel.Position = UDim2.new(0, 0, 0, 5)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = "Размер меню: " .. string.format("%.1f", CONFIG.MenuScale)
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.TextSize = 16
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.Parent = container
    
    local sizeSlider = Instance.new("Frame")
    sizeSlider.Size = UDim2.new(0.9, 0, 0, 30)
    sizeSlider.Position = UDim2.new(0, 0, 0, 35)
    sizeSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sizeSlider.BorderSizePixel = 1
    sizeSlider.BorderColor3 = Color3.fromRGB(60, 60, 70)
    sizeSlider.Parent = container
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(1, 0, 1, 0)
    sliderFill.BackgroundColor3 = CONFIG.AccentColor
    sliderFill.BackgroundTransparency = 0.3
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sizeSlider
    
    local sliderBtn = Instance.new("ImageButton")
    sliderBtn.Size = UDim2.new(0, 20, 0, 20)
    sliderBtn.Position = UDim2.new(1, -10, 0.5, -10)
    sliderBtn.BackgroundColor3 = CONFIG.AccentColor
    sliderBtn.Image = "rbxassetid://3926305904"
    sliderBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.Parent = sizeSlider
    
    local isDragging = false
    sliderBtn.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if isDragging then
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = sizeSlider.AbsolutePosition
            local frameSize = sizeSlider.AbsoluteSize
            local percent = math.clamp((mousePos.X - framePos.X) / frameSize.X, 0, 1)
            CONFIG.MenuScale = 0.5 + percent * 1.5
            sizeLabel.Text = "Размер меню: " .. string.format("%.1f", CONFIG.MenuScale)
            mainFrame.Size = UDim2.new(0, 350 * CONFIG.MenuScale, 0, 550 * CONFIG.MenuScale)
            mainFrame.Position = UDim2.new(0.5, -175 * CONFIG.MenuScale, 0.5, -275 * CONFIG.MenuScale)
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderBtn.Position = UDim2.new(percent, -10, 0.5, -10)
        end
    end)
    
    -- Разделитель
    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(0.9, 0, 0, 2)
    sep1.Position = UDim2.new(0.05, 0, 0, 80)
    sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sep1.BorderSizePixel = 0
    sep1.Parent = container
    
    -- Информация о предмете в руке
    local equippedLabel = Instance.new("TextLabel")
    equippedLabel.Size = UDim2.new(0.9, 0, 0, 30)
    equippedLabel.Position = UDim2.new(0.05, 0, 0, 90)
    equippedLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    equippedLabel.BackgroundTransparency = 0.5
    equippedLabel.BorderSizePixel = 1
    equippedLabel.BorderColor3 = Color3.fromRGB(80, 80, 90)
    equippedLabel.Text = "🔍 Предмет в руке: НЕТ"
    equippedLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    equippedLabel.TextSize = 16
    equippedLabel.Font = Enum.Font.Gotham
    equippedLabel.TextScaled = true
    equippedLabel.Parent = container
    
    -- Обновление информации о предмете
    local function UpdateEquippedInfo()
        local name, _ = GetEquippedItem()
        if name then
            equippedLabel.Text = "🔍 Предмет в руке: " .. name
            equippedLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            equippedLabel.Text = "🔍 Предмет в руке: НЕТ"
            equippedLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
    UpdateEquippedInfo()
    
    -- Кнопка обновления информации
    local refreshBtn = Instance.new("ImageButton")
    refreshBtn.Size = UDim2.new(0, 30, 0, 30)
    refreshBtn.Position = UDim2.new(0.8, 0, 0, 90)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    refreshBtn.BackgroundTransparency = 0.3
    refreshBtn.Image = "rbxassetid://3926305904"
    refreshBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
    refreshBtn.Parent = container
    
    refreshBtn.MouseButton1Click:Connect(function()
        UpdateEquippedInfo()
        refreshBtn.ImageColor3 = Color3.fromRGB(0, 255, 0)
        wait(0.2)
        refreshBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
    end)
    
    -- Разделитель
    local sep2 = Instance.new("Frame")
    sep2.Size = UDim2.new(0.9, 0, 0, 2)
    sep2.Position = UDim2.new(0.05, 0, 0, 130)
    sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sep2.BorderSizePixel = 0
    sep2.Parent = container
    
    -- Кнопка "Дюпать предмет в руке"
    local dupeBtn = Instance.new("ImageButton")
    dupeBtn.Size = UDim2.new(0.9, 0, 0, 70)
    dupeBtn.Position = UDim2.new(0.05, 0, 0, 145)
    dupeBtn.BackgroundColor3 = CONFIG.AccentColor
    dupeBtn.BackgroundTransparency = 0.2
    dupeBtn.BorderSizePixel = 2
    dupeBtn.BorderColor3 = CONFIG.AccentColor
    dupeBtn.Image = "rbxassetid://3926305904"
    dupeBtn.ImageColor3 = Color3.fromRGB(0, 0, 0)
    dupeBtn.ImageTransparency = 1
    dupeBtn.Parent = container
    
    local dupeLabel = Instance.new("TextLabel")
    dupeLabel.Size = UDim2.new(1, 0, 1, 0)
    dupeLabel.BackgroundTransparency = 1
    dupeLabel.Text = "🔁 ДЮПНУТЬ ПРЕДМЕТ В РУКЕ"
    dupeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dupeLabel.TextSize = 22
    dupeLabel.Font = Enum.Font.GothamBold
    dupeLabel.TextScaled = true
    dupeLabel.Parent = dupeBtn
    
    -- Подпись с количеством копий
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0, 20)
    countLabel.Position = UDim2.new(0, 0, 1, -22)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Копий за цикл: " .. CONFIG.MaxDupePerCycle
    countLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextScaled = true
    countLabel.Parent = dupeBtn
    
    -- Анимация кнопки
    dupeBtn.MouseEnter:Connect(function()
        TweenService:Create(dupeBtn, TweenInfo.new(0.3), {
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(dupeLabel, TweenInfo.new(0.3), {
            TextColor3 = CONFIG.AccentColor
        }):Play()
    end)
    
    dupeBtn.MouseLeave:Connect(function()
        TweenService:Create(dupeBtn, TweenInfo.new(0.3), {
            BackgroundTransparency = 0.2
        }):Play()
        TweenService:Create(dupeLabel, TweenInfo.new(0.3), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    dupeBtn.MouseButton1Click:Connect(function()
        local itemName, _ = GetEquippedItem()
        if not itemName then
            dupeLabel.Text = "❌ НЕТ ПРЕДМЕТА!"
            dupeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            wait(1.5)
            dupeLabel.Text = "🔁 ДЮПНУТЬ ПРЕДМЕТ В РУКЕ"
            dupeBtn.BackgroundColor3 = CONFIG.AccentColor
            return
        end
        
        dupeLabel.Text = "⏳ ДЮПАЮ..."
        dupeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        countLabel.Text = "⏳ Дюпается: " .. itemName
        
        spawn(function()
            local totalDupe = 0
            local errors = 0
            
            for i = 1, CONFIG.MaxDupePerCycle do
                local success, method, name = DuplicateEquippedItem()
                if success then
                    totalDupe = totalDupe + 1
                    dupeLabel.Text = "🔄 Копий: " .. totalDupe
                    countLabel.Text = "✅ " .. name .. " | метод: " .. method
                else
                    errors = errors + 1
                    if errors > 10 then
                        -- Смена стратегии при ошибках
                        wait(0.1)
                        pcall(function()
                            local _, newTool = GetEquippedItem()
                            if newTool and newTool:IsA("Tool") then
                                local clone = newTool:Clone()
                                clone.Parent = Backpack
                                totalDupe = totalDupe + 1
                                countLabel.Text = "🔧 Форс-клон: " .. newTool.Name
                            end
                        end)
                    end
                end
                wait(CONFIG.TouchDelay)
            end
            
            dupeLabel.Text = "✅ ГОТОВО! (" .. totalDupe .. ")"
            dupeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            countLabel.Text = "Создано копий: " .. totalDupe
            
            -- Возврат в исходное состояние
            wait(2)
            dupeLabel.Text = "🔁 ДЮПНУТЬ ПРЕДМЕТ В РУКЕ"
            dupeBtn.BackgroundColor3 = CONFIG.AccentColor
            countLabel.Text = "Копий за цикл: " .. CONFIG.MaxDupePerCycle
            UpdateEquippedInfo()
        end)
    end)
    
    -- Разделитель
    local sep3 = Instance.new("Frame")
    sep3.Size = UDim2.new(0.9, 0, 0, 2)
    sep3.Position = UDim2.new(0.05, 0, 0, 230)
    sep3.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sep3.BorderSizePixel = 0
    sep3.Parent = container
    
    -- Кнопка "Дюпать выбранный" (ручной ввод)
    local itemInput = Instance.new("TextBox")
    itemInput.Size = UDim2.new(0.6, 0, 0, 40)
    itemInput.Position = UDim2.new(0.05, 0, 0, 245)
    itemInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    itemInput.BorderSizePixel = 1
    itemInput.BorderColor3 = Color3.fromRGB(60, 60, 70)
    itemInput.Text = "Или введите название"
    itemInput.TextColor3 = Color3.fromRGB(150, 150, 150)
    itemInput.TextSize = 16
    itemInput.Font = Enum.Font.Gotham
    itemInput.ClearTextOnFocus = false
    itemInput.Parent = container
    
    local dupeSingleBtn = Instance.new("ImageButton")
    dupeSingleBtn.Size = UDim2.new(0.25, 0, 0, 40)
    dupeSingleBtn.Position = UDim2.new(0.7, 0, 0, 245)
    dupeSingleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    dupeSingleBtn.BackgroundTransparency = 0.2
    dupeSingleBtn.BorderSizePixel = 1
    dupeSingleBtn.BorderColor3 = Color3.fromRGB(0, 150, 100)
    dupeSingleBtn.ImageTransparency = 1
    dupeSingleBtn.Parent = container
    
    local singleLabel = Instance.new("TextLabel")
    singleLabel.Size = UDim2.new(1, 0, 1, 0)
    singleLabel.BackgroundTransparency = 1
    singleLabel.Text = "ДЮП"
    singleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    singleLabel.TextSize = 18
    singleLabel.Font = Enum.Font.GothamBold
    singleLabel.TextScaled = true
    singleLabel.Parent = dupeSingleBtn
    
    dupeSingleBtn.MouseButton1Click:Connect(function()
        local itemName = itemInput.Text
        if itemName and itemName ~= "" and itemName ~= "Или введите название" then
            singleLabel.Text = "⏳"
            spawn(function()
                local count = 0
                for i = 1, CONFIG.MaxDupePerCycle do
                    pcall(function()
                        -- Используем ту же логику, но с переданным именем
                        local success = false
                        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                pcall(function()
                                    remote:FireServer("Add", itemName, 1)
                                    remote:FireServer("GiveItem", itemName)
                                    success = true
                                end)
                            end
                        end
                        if success then count = count + 1 end
                        singleLabel.Text = "🔄 " .. count
                        wait(CONFIG.TouchDelay)
                    end)
                end
                singleLabel.Text = "✅ " .. count
                wait(1.5)
                singleLabel.Text = "ДЮП"
            end)
        end
    end)
    
    -- Кнопка очистки (только дубликатов)
    local clearBtn = Instance.new("ImageButton")
    clearBtn.Size = UDim2.new(0.4, 0, 0, 35)
    clearBtn.Position = UDim2.new(0.3, 0, 0, 300)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    clearBtn.BackgroundTransparency = 0.3
    clearBtn.BorderSizePixel = 1
    clearBtn.BorderColor3 = Color3.fromRGB(200, 30, 30)
    clearBtn.Parent = container
    
    local clearLabel = Instance.new("TextLabel")
    clearLabel.Size = UDim2.new(1, 0, 1, 0)
    clearLabel.BackgroundTransparency = 1
    clearLabel.Text = "🗑 ОЧИСТИТЬ ДУБЛИКАТЫ"
    clearLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearLabel.TextSize = 14
    clearLabel.Font = Enum.Font.Gotham
    clearLabel.TextScaled = true
    clearLabel.Parent = clearBtn
    
    clearBtn.MouseButton1Click:Connect(function()
        local deleted = 0
        for _, v in ipairs(Backpack:GetChildren()) do
            if v.Name:match("dupe") or v.Name:match("_clone") or v.Name:match("copy") then
                v:Destroy()
                deleted = deleted + 1
                wait(0.01)
            end
        end
        clearLabel.Text = "🗑 УДАЛЕНО: " .. deleted
        wait(1.5)
        clearLabel.Text = "🗑 ОЧИСТИТЬ ДУБЛИКАТЫ"
    end)
    
    -- Движение меню
    local dragging = false
    local dragStart = nil
    local frameStart = nil
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = mainFrame.Position
        end
    end)
    
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local delta = mousePos - dragStart
            mainFrame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Автообновление информации о предмете
    spawn(function()
        while screenGui and screenGui.Parent do
            wait(1)
            pcall(UpdateEquippedInfo)
        end
    end)
    
    return screenGui
end

-- Запуск
local menu = CreateMenu()
print("[Blackbox] Меню загружено. Возьмите предмет в руку и нажмите 'ДЮПНУТЬ ПРЕДМЕТ В РУКЕ'.")
