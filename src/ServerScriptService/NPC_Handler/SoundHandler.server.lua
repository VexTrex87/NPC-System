-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")

-- // Functions \\ --

local function NewSound(Name, Root)
	-- Chooses a random sound and puts it into the HRP
	local Sounds = script[Name]:GetChildren()	
	local RandomSound = Sounds[math.random(1, #Sounds)]:Clone()
	RandomSound.Parent = Root
	RandomSound.Name = Name
end

local function AddSound(Char)
	local Root = Char.HumanoidRootPart
	NewSound("Died", Root)
end

-- // Main \\ --

for _,Char in pairs(CollectionService:GetTagged("NPC")) do
	AddSound(Char)
end

CollectionService:GetInstanceAddedSignal("NPC"):Connect(function(Char)
	AddSound(Char)
end)