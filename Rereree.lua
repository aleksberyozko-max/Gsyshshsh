-- 🌱 Aggressive Weight Changer | Grow a Garden 2
-- Удобно для телефона + авто-поиск

local player = game.Players.LocalPlayer
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 450)
frame.Position = UDim2.new(0.5, -170, 0.5, -225)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,50)
title.Text = "🌱 Weight Increaser"
title.TextColor3 = Color3.fromRGB(0, 255, 120)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.95,0,0,200)
scroll.Position = UDim2.new(0.025,0,0,60)
scroll.BackgroundColor3 = Color3.fromRGB(25,25,25)
scroll.ScrollBarThickness = 8
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 6)

local weightBox = Instance.new("TextBox")
weightBox.Size = UDim2.new(0.9,0,0,55)
weightBox.Position = UDim2.new(0.05,0,0,280)
weightBox.PlaceholderText = "Новый вес (рекомендую 1e7 или 99999999)"
weightBox.Text = "10000000"
weightBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
weightBox.TextColor3 = Color3.new(1,1,1)
weightBox.TextScaled = true
weightBox.Parent = frame
Instance.new("UICorner", weightBox).CornerRadius = UDim.new(0, 12)

local applyAll = Instance.new("TextButton")
applyAll.Size = UDim2.new(0.9,0,0,60)
applyAll.Position = UDim2.new(0.05,0,0,350)
applyAll.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
applyAll.Text = "🚀 Увеличить вес ВСЕМ фруктам"
applyAll.TextScaled = true
applyAll.Font = Enum.Font.GothamBold
applyAll.Parent = frame
Instance.new("UICorner", applyAll).CornerRadius = UDim.new(0, 12)

-- Перетаскивание пальцем
local dragging = false
frame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging then
        local pos = game:GetService("UserInputService"):GetMouseLocation()
        frame.Position = UDim2.new(0, pos.X - 170, 0, pos.Y - 225)
    end
end)

frame.InputEnded:Connect(function() dragging = false end)

local selectedFruits = {}

local function findMyFruits()
    for _, v in ipairs(scroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj.Name:find("Fruit") or obj.Name:find("Plant") or obj:FindFirstChild("Weight") or obj:FindFirstChild("weight")) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,-10,0,50)
            btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
            btn.Text = obj.Name .. " (вес: " .. (obj:FindFirstChild("Weight") and obj.Weight.Value or "?") .. ")"
            btn.TextScaled = true
            btn.Parent = scroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            
            btn.MouseButton1Click:Connect(function()
                if table.find(selectedFruits, obj) then
                    table.remove(selectedFruits, table.find(selectedFruits, obj))
                    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
                else
                    table.insert(selectedFruits, obj)
                    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                end
            end)
        end
    end
end

applyAll.MouseButton1Click:Connect(function()
    local newWeight = tonumber(weightBox.Text) or 10000000
    
    -- Применяем ко всем выбранным + всем найденным
    for _, fruit in ipairs(selectedFruits) do
        pcall(function()
            if fruit:FindFirstChild("Weight") then
                fruit.Weight.Value = newWeight
            elseif fruit:FindFirstChild("weight") then
                fruit.weight.Value = newWeight
            else
                local w = Instance.new("NumberValue", fruit)
                w.Name = "Weight"
                w.Value = newWeight
            end
        end)
    end
    
    -- Агрессивно ко всем растениям
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:FindFirstChild("Weight") then
                obj.Weight.Value = newWeight
            end
        end)
    end
    
    game.StarterGui:SetCore("SendNotification", {Title="Success", Text="Вес увеличен до " .. newWeight, Duration=5})
end)

-- Кнопка обновления
local refresh = Instance.new("TextButton")
refresh.Size = UDim2.new(0.9,0,0,40)
refresh.Position = UDim2.new(0.05,0,0,410)
refresh.BackgroundColor3 = Color3.fromRGB(50,50,50)
refresh.Text = "🔄 Обновить список"
refresh.TextScaled = true
refresh.Parent = frame
Instance.new("UICorner", refresh).CornerRadius = UDim.new(0, 10)

refresh.MouseButton1Click:Connect(findMyFruits)

findMyFruits()

print("🌱 Weight Increaser загружен! Выбирай фрукты и применяй вес.")
