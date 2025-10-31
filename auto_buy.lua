local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local PROMPT_ACTIVATION_DURATION = 2.0 
local POSITION_TOLERANCE = 5          
local FORWARD_OFFSET = 15             
local TARGET_NAMES = {
    "Secret Lucky Block",
    "Admin Lucky Block",
    "Spooky Lucky Block",
    "Los Lucky Blocks",
    "Taco Lucky Block"
}

local isScriptActive = false
local mainLoopThread = nil
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")


if not humanoid or not rootPart then
    warn("Humanoid или HumanoidRootPart не найдены! Скрипт прекращает работу.")
    return
end

print("Скрипт запущен. Начинаю поиск цели: " .. table.concat(TARGET_NAMES, ", ") .. "...")

local function getTargetCFrameAndPosition(item)
    if not item then return nil, nil end
    local targetPosition = nil
    local targetCFrame = nil
    
    local targetRoot = item:FindFirstChild("HumanoidRootPart")
    local primaryPart = item:IsA("Model") and item.PrimaryPart

    if targetRoot then
        targetPosition = targetRoot.Position
        targetCFrame = targetRoot.CFrame
    elseif primaryPart then
        targetPosition = primaryPart.Position
        targetCFrame = primaryPart.CFrame
    elseif item:IsA("BasePart") then
        targetPosition = item.Position
        targetCFrame = item.CFrame
    end
    return targetCFrame, targetPosition
end

local function findAndActivatePrompt(targetPosition)
    if not targetPosition then return nil end

    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") then
            for _, part in ipairs(model:GetChildren()) do
                if part:IsA("BasePart") then
                    
                    local distance = (part.Position - targetPosition).Magnitude
                    
                    if distance <= POSITION_TOLERANCE then
                        
                        local promptAttachment = part:FindFirstChild("PromptAttachment")
                        if promptAttachment then
                            
                            local prompt = promptAttachment:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                return prompt
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end


local function mainLogicLoop()
    while true do
        if isScriptActive then
            
            local foundTarget = nil
            for _, name in ipairs(TARGET_NAMES) do
                local target = workspace.RenderedMovingAnimals:FindFirstChild(name)
                if target then
                    foundTarget = target
                    print("Предмет '" .. name .. "' найден.")
                    break
                end
            end
            
            if foundTarget then
                local targetCFrame, originalPosition = getTargetCFrameAndPosition(foundTarget)

                if originalPosition and targetCFrame then
				local lookVector = targetCFrame.LookVector
                    local offsetVector = lookVector * FORWARD_OFFSET
                    local finalMoveToPosition = originalPosition + offsetVector
                    
                    local promptToActivate = findAndActivatePrompt(originalPosition)

                    if promptToActivate then
                        print("Иду к '" .. foundTarget.Name .. "' со смещением на " .. FORWARD_OFFSET .. " студсов вперед...")
                        
                        if not isScriptActive then continue end
                        humanoid:MoveTo(finalMoveToPosition)
                        humanoid.MoveToFinished:Wait()
                        
                        if not isScriptActive then continue end
                        
                        local currentDistance = (rootPart.Position - finalMoveToPosition).Magnitude
                        if currentDistance <= POSITION_TOLERANCE * 2 then 
                            
                            print("Активирую ProximityPrompt на " .. PROMPT_ACTIVATION_DURATION .. " секунды.")
                            promptToActivate:InputHoldBegin()
                            task.wait(PROMPT_ACTIVATION_DURATION)
                            promptToActivate:InputHoldEnd()
                            
                            print("Покупка завершена.")
                        else
                            print("Не удалось подойти достаточно близко к целевой точке.")
                        end
                    else
                        print("⚠️ Найден '" .. foundTarget.Name .. "', но не удалось найти соответствующий ProximityPrompt.")
                    end
                else
                    print("Найден '" .. foundTarget.Name .. "', но не могу определить его позицию/ориентацию.")
                end
            else
                print("Целевые предметы не найдены...")
            end
            
            task.wait(1) 
            
        else
            task.wait(0.5) 
        end
    end
end

mainLoopThread = task.spawn(mainLogicLoop)

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) 

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutomatedBuyerGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 80)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -40) 
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true 

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -10, 1, -10)
toggleButton.Position = UDim2.new(0, 5, 0, 5)
toggleButton.Text = "🔴 ВЫКЛ. КОД"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 20
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0) 
toggleButton.Parent = mainFrame

local function toggleScriptState()
    isScriptActive = not isScriptActive
    
    if isScriptActive then
        toggleButton.Text = "🟢 ВКЛ. КОД"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        print(">> Автоматический покупатель: ВКЛЮЧЕН.")
    else
        toggleButton.Text = "🔴 ВЫКЛ. КОД"
        toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        humanoid:MoveTo(rootPart.Position) 
        print(">> Автоматический покупатель: ВЫКЛЮЧЕН.")
    end
end

toggleButton.MouseButton1Click:Connect(toggleScriptState)
toggleScriptState()

local isDragging = false
local dragStart = Vector2.new(0, 0)
local startPos = UDim2.new(0, 0, 0, 0)

local function onInputBegan(input, gameProcessed)
    -- Не перетаскиваем, если нажали на кнопку, или если ввод обработан игрой (например, чат)
    if toggleButton:IsA("TextButton") and input.Target == toggleButton then return end
    if gameProcessed then return end 

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Target == mainFrame or mainFrame:IsAncestorOf(input.Target) then
            isDragging = true
            
            dragStart = UserInputService:GetMouseLocation()
           
            startPos = mainFrame.Position 
            
            mainFrame.ZIndex = 100 -- Делаем меню самым верхним
            
            return Enum.ContextActionResult.Sink
        end
    end
end

local function onInputChanged(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMousePosition = UserInputService:GetMouseLocation()
        local delta = currentMousePosition - dragStart
        
        local newXOffset = startPos.X.Offset + delta.X
        local newYOffset = startPos.Y.Offset + delta.Y

        mainFrame.Position = UDim2.new(startPos.X.Scale, newXOffset, startPos.Y.Scale, newYOffset)
    end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        mainFrame.ZIndex = 1 -- Возвращаем ZIndex
    end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputChanged:Connect(onInputChanged)
UserInputService.InputEnded:Connect(onInputEnded)
