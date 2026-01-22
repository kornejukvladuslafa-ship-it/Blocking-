local BLOCK_DURATION = 2.0
local ARM_ANIMATION_DURATION = 0.2
local MAX_BLOCK_USES = 20
local DEATH_ANIM_DURATION = 5.0
local NUMBERS_DELAY = 0.5
local NUMBERS_DISPLAY_TIME = 3.0
local NUMBERS_3D_OFFSET_BEHIND_PLAYER = 2.0
local NUMBERS_TEXT = "99999999999999999999"
local NUMBERS_FONT_SIZE = 100
local NUMBERS_TEXT_COLOR = Color3.new(1, 1, 1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local lastPlayerHealth = -1
local scriptEnabled = false

local currentBlockUses = MAX_BLOCK_USES
local blockActive = false
local blockStartTime = 0
local blockTween = nil

local deathAnimationActive = false
local deathAnimStartTime = 0

local originalTakeDamage = nil
local characterConnection = nil

local mainScreenGui = Instance.new("ScreenGui")
mainScreenGui.Name = "BlockScriptGui"
mainScreenGui.Parent = PlayerGui

local numbersBillboard = Instance.new("BillboardGui")
numbersBillboard.Name = "BlockNumbers"
numbersBillboard.Size = UDim2.new(5, 0, 1, 0)
numbersBillboard.ExtentsOffset = Vector3.new(0, 0, 0)
numbersBillboard.AlwaysOnTop = true
numbersBillboard.LightInfluence = 0
local numbersBillboard = Instance.new("BillboardGui")
numbersBillboard.Name = "BlockNumbers"
numbersBillboard.Size = UDim2.new(5, 0, 1, 0)
numbersBillboard.ExtentsOffset = Vector3.new(0, 0, 0)
numbersBillboard.AlwaysOnTop = true
numbersBillboard.LightInfluence = 0
numbersBillboard.StudsOffset = Vector3.new(0, 1, 0)
numbersBillboard.Visible = false
numbersBillboard.Parent = LocalPlayer.Character or workspace
numbersBillboard.StudsOffset = Vector3.new(0, 1, 0)
numbersBillboard.Visible = false
numbersBillboard.Parent = LocalPlayer.Character or workspace
numbersBillboard.StudsOffset = Vector3.new(0, 1, 0)
numbersBillboard.Visible = false
numbersBillboard.Parent = LocalPlayer.Character or workspace

local numbersText = Instance.new("TextLabel")
numbersText.Name = "NumbersText"
numbersText.Text = NUMBERS_TEXT
numbersText.TextColor3 = NUMBERS_TEXT_COLOR
numbersText.TextSize = NUMBERS_FONT_SIZE
numbersText.BackgroundTransparency = 1
numbersText.Size = UDim2.new(1, 0, 1, 0)
numbersText.Font = Enum.Font.SourceSansBold
numbersText.Parent = numbersBillboard

local menuFrame = Instance.new("Frame")
menuFrame.Name = "BlockMenu"
menuFrame.Size = UDim2.new(0.2, 0, 0.15, 0)
menuFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
menuFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = true
menuFrame.Parent = mainScreenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "Блок Руками"
titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = menuFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Text = "Включить Блок Руками"
toggleButton.Size = UDim2.new(0.9, 0, 0.3, 0)
toggleButton.Position = UDim2.new(0.05, 0, 0.35, 0)
toggleButton.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.SourceSans
toggleButton.Parent = menuFrame

local blocksCounterLabel = Instance.new("TextLabel")
blocksCounterLabel.Text = "Блоков: " .. currentBlockUses
blocksCounterLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
blocksCounterLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
blocksCounterLabel.BackgroundTransparency = 1
blocksCounterLabel.TextColor3 = Color3.new(1, 1, 1)
blocksCounterLabel.TextSize = 14
blocksCounterLabel.Font = Enum.Font.SourceSans
blocksCounterLabel.Parent = menuFrame

function hookHumanoidTakeDamage()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and not originalTakeDamage then
        originalTakeDamage = humanoid.TakeDamage

        humanoid.TakeDamage = function(self, damage)
            if blockActive then
            else
                return originalTakeDamage(self, damage)
            end
        end
        print("[BlockScript] Humanoid:TakeDamage() успешно перехвачен.")
    elseif not humanoid then
        print("[BlockScript] Ошибка: Humanoid не найден для перехвата TakeDamage.")
    end
end

function unhookHumanoidTakeDamage()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and originalTakeDamage then
        humanoid.TakeDamage = originalTakeDamage
        originalTakeDamage = nil
        print("[BlockScript] Humanoid:TakeDamage() перехват отменен.")
    end
end

function activateArmBlock()
    local character = LocalPlayer.Character
    if not character then return end

    local rightArm = character:FindFirstChild("Right Arm")
    local leftArm = character:FindFirstChild("Left Arm")
    local upperTorso = character:FindFirstChild("UpperTorso")

    if rightArm and leftArm and upperTorso and TweenService then
        blockActive = true
        blockStartTime = os.clock()
        print("[BlockScript] Блок руками активирован! Осталось блоков: " .. currentBlockUses)

        local rightMotor = upperTorso:FindFirstChild("RightShoulder")
        local leftMotor = upperTorso:FindFirstChild("LeftShoulder")
        if rightMotor then rightMotor.Enabled = false end
        if leftMotor then leftMotor.Enabled = false end

        local tweenInfo = TweenInfo.new(ARM_ANIMATION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local targetCFrameRight = upperTorso.CFrame * CFrame.new(0.5, -0.5, -0.5) * CFrame.Angles(math.rad(-90), math.rad(-45), math.rad(45))
        local targetCFrameLeft = upperTorso.CFrame * CFrame.new(-0.5, -0.5, -0.5) * CFrame.Angles(math.rad(-90), math.rad(45), math.rad(-45))

        blockTween = TweenService:Create(rightArm, tweenInfo, {CFrame = targetCFrameRight})
        blockTween:Play()
        TweenService:Create(leftArm, tweenInfo, {CFrame = targetCFrameLeft}):Play()
    else
        print("[BlockScript] Ошибка: Не удалось найти части тела или TweenService для блока.")
    end
end

function deactivateArmBlock()
    blockActive = false
    print("[BlockScript] Блок руками завершен.")

    local character = LocalPlayer.Character
    if not character then return end

    local rightArm = character:FindFirstChild("Right Arm")
    local leftArm = character:FindFirstChild("Left Arm")
    local upperTorso = character:FindFirstChild("UpperTorso")

    if rightArm and leftArm and upperTorso then
        local rightMotor = upperTorso:FindFirstChild("RightShoulder")
        local leftMotor = upperTorso:FindFirstChild("LeftShoulder")
        if rightMotor then rightMotor.Enabled = true end
        if leftMotor then leftMotor.Enabled = true end
    end
end

function startDeathAnimation()
    deathAnimationActive = true
    deathAnimStartTime = os.clock()
    numbersBillboard.Visible = false
    print("[BlockScript] Блоки исчерпаны! Запускаю анимацию смерти...")
end

function updateGuiBlocksCounter()
    blocksCounterLabel.Text = "Блоков: " .. currentBlockUses
end

local function onCharacterAdded(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        numbersBillboard.Adornee = humanoidRootPart
    else
        numbersBillboard.Adornee = character
    end

    if scriptEnabled then
        hookHumanoidTakeDamage()
    end
end

characterConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end

RunService.RenderStepped:Connect(function()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

    if not scriptEnabled then
        numbersBillboard.Visible = false
        if blockActive then deactivateArmBlock() end
        blockActive = false
        deathAnimationActive = false
        return
    end

    if humanoid then
        local currentHealth = humanoid.Health

        if lastPlayerHealth ~= -1 and currentHealth < lastPlayerHealth then
            if not blockActive then
                if currentBlockUses > 0 then
                    currentBlockUses = currentBlockUses - 1
                    activateArmBlock()
                    updateGuiBlocksCounter()
                else
                    if not deathAnimationActive then
                        startDeathAnimation()
                    end
                end
            end
        end
        lastPlayerHealth = currentHealth
    end

    if blockActive then
        local elapsedTime = os.clock() - blockStartTime
        if elapsedTime >= BLOCK_DURATION then
            deactivateArmBlock()
            print("[BlockScript] Блок завершен.")
        end
    end

    if deathAnimationActive then
        local elapsedTime = os.clock() - deathAnimStartTime

        if elapsedTime >= DEATH_ANIM_DURATION then
            deathAnimationActive = false
            numbersBillboard.Visible = false
            print("[BlockScript] Анимация смерти завершена.")
            return
        end

        if elapsedTime >= NUMBERS_DELAY and elapsedTime < NUMBERS_DELAY + NUMBERS_DISPLAY_TIME then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local rootPart = character.HumanoidRootPart
                numbersBillboard.Adornee = rootPart
                local lookVector = rootPart.CFrame.LookVector
                numbersBillboard.StudsOffset = -lookVector * NUMBERS_3D_OFFSET_BEHIND_PLAYER + Vector3.new(0, 1, 0)
                numbersBillboard.Visible = true

                local textAlpha = math.min(1, (elapsedTime - NUMBERS_DELAY) / (NUMBERS_DISPLAY_TIME * 0.2))
                if elapsedTime > NUMBERS_DELAY + NUMBERS_DISPLAY_TIME * 0.7 then
                     textAlpha = textAlpha * (1 - ((elapsedTime - (NUMBERS_DELAY + NUMBERS_DISPLAY_TIME * 0.7)) / (NUMBERS_DISPLAY_TIME * 0.3)))
                end
                numbersText.TextTransparency = math.min(1, math.max(0, 1 - textAlpha))
            end
        else
            numbersBillboard.Visible = false
        end
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    scriptEnabled = not scriptEnabled
    if scriptEnabled then
        toggleButton.Text = "Выключить Блок Руками"
        toggleButton.BackgroundColor3 = Color3.new(0.5, 0.2, 0.2)
        
        currentBlockUses = MAX_BLOCK_USES
        lastPlayerHealth = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.Health or -1
        updateGuiBlocksCounter()
        
        hookHumanoidTakeDamage()
        print("[BlockScript] Скрипт включен!")
    else
        toggleButton.Text = "Включить Блок Руками"
        toggleButton.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
        
        unhookHumanoidTakeDamage()
        
        if blockActive then deactivateArmBlock() end
        blockActive = false
        deathAnimationActive = false
        numbersBillboard.Visible = false
        print("[BlockScript] Скрипт выключен.")
    end
end)

game:GetService("Debris"):AddItem(mainScreenGui, 0)
if characterConnection then characterConnection:Disconnect() end
unhookHumanoidTakeDamage()
print("[BlockScript] Скрипт 'Блок Руками' готов к работе. Используйте GUI для управления.")
