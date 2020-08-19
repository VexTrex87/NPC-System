-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")

-- // Functions \\ --

local function NewSound(Name, Root)
	-- Chooses a random sound and puts it into the HRP
	local Sounds = script[Name]:GetChildren()	
	local RandomSound = Sounds[math.random(#Sounds)]:Clone()
	RandomSound.Name = Name
	RandomSound.Parent = Root
end

local function AddSound(Char)
	local Root = Char.HumanoidRootPart
	if table.find({"Dummy"}, Char.Name) then
		NewSound("Died", Root)
	end
end

-- // Main \\ --

for _,Char in pairs(CollectionService:GetTagged("NPC")) do
	AddSound(Char)
end

CollectionService:GetInstanceAddedSignal("NPC"):Connect(function(Char)
	AddSound(Char)
end)