local Players = game:GetService("Players")
local player = Players.LocalPlayer

local shimmyDistance = 0.5 -- studs backward in shimmy
local shimmySpeed = 0.05 -- delay between shimmy steps (seconds)

local targetPlayer = nil -- current target to follow
local shimmyActive = false

-- Show controls UI when script loads
local function showControls()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShimmyControlsGui"
	screenGui.ResetOnSpawn = false

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0, 450, 0, 80)
	textLabel.Position = UDim2.new(0.5, -225, 0, 20)
	textLabel.BackgroundTransparency = 0.5
	textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = "Type a ! and your target's username to begin!\nType !stop to stop!"
	textLabel.TextWrapped = true
	textLabel.Parent = screenGui

	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Fade out and remove after 10 seconds
	task.delay(10, function()
		for i = 1, 20 do
			textLabel.TextTransparency = i * 0.05
			textLabel.BackgroundTransparency = 0.5 + i * 0.025
			task.wait(0.05)
		end
		screenGui:Destroy()
	end)
end

showControls()

-- Helper: Get torso (R6 or R15)
local function getTorso(character)
	if character:FindFirstChild("Torso") then
		return character.Torso -- R6
	elseif character:FindFirstChild("UpperTorso") then
		return character.UpperTorso -- R15
	end
	return nil
end

local function stopShimmy()
	shimmyActive = false
end

local function followAndShimmy(targetTorso, myHRP)
	shimmyActive = true
	
	while shimmyActive do
		if not targetTorso or not targetTorso.Parent then
			break
		end
		
		local backDir = targetTorso.CFrame.LookVector  -- FACE TOWARD their back

		local forwardPos = targetTorso.Position

		local lookDir = Vector3.new(backDir.X, 0, backDir.Z)
		if lookDir.Magnitude == 0 then
			lookDir = Vector3.new(0, 0, -1)
		else
			lookDir = lookDir.Unit
		end
		local lookCFrame = CFrame.new(forwardPos, forwardPos + lookDir)
		myHRP.CFrame = lookCFrame
		task.wait(shimmySpeed)

		local backPos = forwardPos - backDir * shimmyDistance -- move backward along backDir
		local backLookDir = Vector3.new(backDir.X, 0, backDir.Z)
		if backLookDir.Magnitude == 0 then
			backLookDir = Vector3.new(0, 0, -1)
		else
			backLookDir = backLookDir.Unit
		end
		local backCFrame = CFrame.new(backPos, backPos + backLookDir)
		myHRP.CFrame = backCFrame
		task.wait(shimmySpeed)
	end
end

-- Listen to chat input with ! prefix and partial name matching
player.Chatted:Connect(function(msg)
	msg = msg:lower():gsub("%s+", "") -- normalize message: lowercase, no spaces
	
	if msg == "!stop" then
		targetPlayer = nil
		stopShimmy()
	elseif msg:sub(1,1) == "!" and #msg > 1 then
		local partialName = msg:sub(2)
		local foundPlayer = nil
		
		for _, p in pairs(Players:GetPlayers()) do
			local pname = p.Name:lower():gsub("%s+", "")
			local dname = p.DisplayName:lower():gsub("%s+", "")
			if pname:sub(1, #partialName) == partialName or dname:sub(1, #partialName) == partialName then
				foundPlayer = p
				break
			end
		end
		
		if foundPlayer and foundPlayer ~= targetPlayer then
			targetPlayer = foundPlayer
			stopShimmy()
		end
	end
end)

-- Main loop to follow targetPlayer continuously
task.spawn(function()
	while true do
		task.wait(0.1)
		if targetPlayer and targetPlayer.Character and targetPlayer.Character.Parent then
			local theirTorso = getTorso(targetPlayer.Character)
			local myChar = player.Character
			if theirTorso and myChar and myChar:FindFirstChild("HumanoidRootPart") then
				followAndShimmy(theirTorso, myChar.HumanoidRootPart)
			end
		else
			task.wait(0.5)
		end
	end
end)
