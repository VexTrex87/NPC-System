local CollectionService = game:GetService("CollectionService")
local Core = require(game.ServerScriptService.Core)
local NPCs = script.NPCs
local Modules = {}

local function RequireModule(Script, Char)
	Modules[Script.Name].Initiate(Char)
end

for _,Script in pairs(NPCs:GetChildren()) do
	
	Modules[Script.Name] = require(Script)
	
	for _,Char in pairs(CollectionService:GetTagged(Script.Name)) do		
		Core.NewThread(RequireModule, Script, Char)
	end
	
	CollectionService:GetInstanceAddedSignal(Script.Name):Connect(function(Char)
		Core.NewThread(RequireModule, Script, Char)
	end)
	
end