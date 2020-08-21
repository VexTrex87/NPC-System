local DIED_SOUNDS = {"Puncher", "Giant"}
local CollectionService = game:GetService("CollectionService")

-- // Functions \\ --

local function NewSound(Name, Char)
	-- Chooses a random sound and puts it into the HRP
	local Sounds = script[Name]:GetChildren()	
	local RandomSound = Sounds[math.random(#Sounds)]:Clone()
	RandomSound.Name = Name
	RandomSound.Parent = Char.HumanoidRootPart
end

local function AddSound(Char)
	
	-- Died sounds
	if table.find(DIED_SOUNDS, Char.Name) then
		NewSound("Died", Char)
	end
	
end

-- // Main \\ --

for _,Char in pairs(CollectionService:GetTagged("NPC")) do
	AddSound(Char)
end

CollectionService:GetInstanceAddedSignal("NPC"):Connect(AddSound)