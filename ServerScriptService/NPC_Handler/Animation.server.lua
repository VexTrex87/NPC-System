-- // Settings \\ --

local DISABLED_STATES = {"FallingDown", "RunningNoPhysics", "Climbing", "Ragdoll", "GettingUp", "Flying", "Seated", "Swimming", "PlatformStanding"}
local NPC_TAG = "NPC"

-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")
local NewThread = require(game.ServerScriptService.NewThread)

-- // Functions \\ --

local function Animate(Char)
	local Hum = Char.Humanoid
	local Anims = {}
	
	-- Disables unnecessary states for more performance
	for _,State in pairs(DISABLED_STATES) do
		Hum:SetStateEnabled(Enum.HumanoidStateType[State], false)
	end
	
	-- Loads & runs random default animations
	for _,Anim in pairs(script:GetChildren()) do
		Anims[Anim.Name] = Hum:LoadAnimation(Anim[math.random(1, #Anim:GetChildren())])
	end
	
	-- Events for default animations to run
	Hum.Running:Connect(function(Speed)
		if Speed ~= 0 then
			Anims.Idle:Stop()
			Anims.Run:Play()
		else
			Anims.Run:Stop()
			Anims.Idle:Play()
		end
	end)
	
	Hum.Jumping:Connect(function(Entering)
		if Entering then
			Anims.Jump:Play()
		else
			Anims.Jump:Stop()
		end
	end)
	
	Hum.FreeFalling:Connect(function(Entering)
		if Entering then
			Anims.FreeFall:Play()
		else
			Anims.FreeFall:Stop()
		end
	end)	
	
end

-- // Main \\ --

for _,Char in pairs(CollectionService:GetTagged(NPC_TAG)) do
	NewThread(Animate, Char)
end

CollectionService:GetInstanceAddedSignal(NPC_TAG):Connect(function(Char)
	NewThread(Animate, Char)
end)