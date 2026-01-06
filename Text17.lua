--[[
AUTOFARM DE COINS RAW (FLOTANTE + ATRAVIESA PAREDES + RESPAWN + GODMODE)
- Botón ON/OFF
- Coin por coin, flotando suavemente
- Contador confiable
- GUI movible compatible con touch / mouse
- Chequeo rápido: 0.05s
- Rango de búsqueda: 200 studs
- Funciona aunque mueras o respawnees
- GodMode activo
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ===== Variables dinámicas del personaje =====
local char
local humanoidRootPart
local autofarming = false
local coinsCollected = 0
local collectedSet = {}
local speed = 20
local maxRange = 200
local noclipConn
local healthConn

-- Funciones para obtener Character y HumanoidRootPart actualizados
local function getCharacter()
	local c = player.Character
	if not c then
		c = player.CharacterAdded:Wait()
	end
	return c
end

local function getHumanoidRootPart()
	local c = getCharacter()
	return c:WaitForChild("HumanoidRootPart")
end

-- Inicializar
char = getCharacter()
humanoidRootPart = getHumanoidRootPart()

-- ===== Noclip para atravesar paredes =====
local function enableNoclip()
	noclipConn = RunService.Stepped:Connect(function()
		local c = char
		if c then
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
end

local function disableNoclip()
	if noclipConn then
		pcall(function() noclipConn:Disconnect() end)
		noclipConn = nil
	end
end

-- ===== GodMode =====
local function applyGodMode()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		if healthConn then healthConn:Disconnect() end
		healthConn = humanoid.HealthChanged:Connect(function()
			if autofarming and humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end
end

local function deactivateGodMode()
	if healthConn then
		healthConn:Disconnect()
		healthConn = nil
	end
end

-- ===== Helpers =====
local function isCoinPart(part)
	if not part or not part:IsA("BasePart") then return false end
	if part.Transparency >= 1 then return false end
	local n = part.Name:lower()
	return n:find("coin") or n:find("money") or n:find("cash")
end

local function findNearbyCoins()
	local list = {}
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if isCoinPart(inst) and not collectedSet[inst] then
			if (inst.Position - humanoidRootPart.Position).Magnitude <= maxRange then
				table.insert(list, inst)
			end
		elseif inst:IsA("Model") then
			for _, c in ipairs(inst:GetDescendants()) do
				if isCoinPart(c) and not collectedSet[c] then
					if (c.Position - humanoidRootPart.Position).Magnitude <= maxRange then
						table.insert(list, c)
					end
				end
			end
		end
	end
	return list
end

local function collectCoin(coin)
	if not coin or collectedSet[coin] then return end
	collectedSet[coin] = true
	coinsCollected += 1
	if countLabel then
		countLabel.Text = "Coins: "..coinsCollected
	end
	pcall(function()
		coin.Transparency = 1
		coin.CanCollide = false
		coin.Anchored = true
		if coin.Parent then coin:Destroy() end
	end)
end

-- ===== AutoFarm Fly FLOTANTE =====
local function moveToCoin(coin)
	if not coin or not coin.Parent then return end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5,1e5,1e5)
	bv.Velocity = Vector3.new(0,0,0)
	bv.Parent = humanoidRootPart

	while autofarming and coin.Parent and not collectedSet[coin] do
		local direction = (coin.Position - humanoidRootPart.Position)
		if direction.Magnitude < 2 then
			collectCoin(coin)
			break
		end
		bv.Velocity = direction.Unit * speed
		task.wait(0.05)
	end

	bv:Destroy()
end

local function startAutoFarmLoop()
	applyGodMode()
	enableNoclip()
	task.spawn(function()
		while autofarming do
			local coins = findNearbyCoins()
			if #coins == 0 then
				task.wait(0.05)
			else
				table.sort(coins, function(a,b)
					return (a.Position - humanoidRootPart.Position).Magnitude < (b.Position - humanoidRootPart.Position).Magnitude
				end)
				moveToCoin(coins[1])
			end
		end
	end)
end

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCoinGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 110)
frame.Position = UDim2.new(0.04, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -12, 0, 28)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(220,220,220)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Auto collect coins"

local countLabel = Instance.new("TextLabel", frame)
countLabel.Size = UDim2.new(1, -12, 0, 26)
countLabel.Position = UDim2.new(0,6,0,36)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(255,255,255)
countLabel.Font = Enum.Font.SourceSansBold
countLabel.TextSize = 16
countLabel.Text = "Coins: 0"

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -12, 0, 34)
btn.Position = UDim2.new(0,6,1,-44)
btn.Text = "AutoFarm"
btn.Font = Enum.Font.SourceSansBold
btn.TextScaled = true
btn.BackgroundColor3 = Color3.fromRGB(60,150,80)
btn.TextColor3 = Color3.fromRGB(255,255,255)

-- ===== Botón ON/OFF con noclip y godmode =====
btn.MouseButton1Click:Connect(function()
	if not autofarming then
		autofarming = true
		btn.Text = "AutoFarm: ON"
		startAutoFarmLoop()
	else
		autofarming = false
		btn.Text = "AutoFarm"
		disableNoclip()
		deactivateGodMode()
	end
end)

-- ===== GUI Movible =====
local dragging, dragInput, dragStart, startPos

local function updatePosition(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updatePosition(input)
	end
end)

-- ===== Detectar respawn =====
player.CharacterAdded:Connect(function(c)
	char = c
	humanoidRootPart = c:WaitForChild("HumanoidRootPart")
	if autofarming then
		enableNoclip()
		applyGodMode()
	end
end)
