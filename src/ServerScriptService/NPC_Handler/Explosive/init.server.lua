-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local NpcModule = require(script.Parent.NPC)
local Settings = require(script.Settings)
local Core = require(game.ServerScriptService.Core)
local Explode = require(script.Explode)

local Target = workspace.Map.Target
local NPCs = {}

-- // Functions \\ --

-- AI: Players

local function InitiateExplode(NPC)
	NPC.ExplodeAnim:Play()
		
	local Con
	Con = NPC.ExplodeAnim:GetMarkerReachedSignal("StartExplosion"):Connect(function()
		Explode.Start({
			["Position"] = NPC.Root.Position,
			["NPC"] = NPC.Char
		})
		Con:Disconnect()
	end)
		
	NPC.ExplodeAnim.Stopped:Wait()		
end

local function Attack(NPC)
	if NPC.Target and Core.Mag(NPC.Root, NPC.Target) < Settings.AttackDist then
		NPC.Hum:MoveTo(NPC.Root.Position)		
		InitiateExplode(NPC)
	end	
end

local function Follow(NPC)
	
	if not NPC or not NPC.Root or not NPC.Target then
		return
	end
	
	local Path = PathfindingService:CreatePath()  
	Path:ComputeAsync(NPC.Root.Position, NPC.Target.Position)
	local Waypoints = Path:GetWaypoints()
	local CurrentTarget = NPC.Target
	local Hum = NPC.Hum
	
	if Path.Status == Enum.PathStatus.Success then
		for i,Point in ipairs(Waypoints) do	
			
			-- Jumps if needed, moves to point, restarts function if needed		
			NpcModule.Jump(NPC, Point, Settings)		
			NpcModule.CheckFront(NPC, Settings)			
			Hum:MoveTo(Point.Position)
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Follow(NPC)
				break
			end

			if NPC and NPC.Root and NPC.Target and NpcModule.CheckSight(NPC, NPC.Target, Settings) then
				repeat
					Attack(NPC)
					NpcModule.CheckFront(NPC, Settings)
					Hum:MoveTo(CurrentTarget.Position)
					wait(Settings.UpdateDelay)
				until not NPC.Target or not NPC.Root or CurrentTarget ~= NPC.Target or not NpcModule.CheckSight(NPC, NPC.Target, Settings) or Hum.Health == 0 or NPC.Target.Parent.Humanoid.Health == 0
				break
			end			
			
			if not NPC.Target then
				break
			elseif Core.Mag(NPC.Target, Waypoints[#Waypoints]) > Settings.TimeoutDist or CurrentTarget ~= NPC.Target then
				Follow(NPC)
				break
			end				
			
		end	
	else
		Follow(NPC)
	end
end

	-- AI: Main
local function Initiate(TempChar)
	
	-- Local table for NPC's
	local NPC = {
		Char = TempChar,
		Root = TempChar.HumanoidRootPart,
		Hum = TempChar.Humanoid,
		Target = nil,
		ExplodeAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Explode),
		CurrentTarget = nil
	}		
	table.insert(NPCs, NPC)
	
	-- Sets default properties labeled in settings
	for Name, Val in pairs(Settings.Humanoid) do
		NPC.Hum[Name] = Val
	end
	
	------------------------------------
	------------------------------------
	local Clone = NPC.Char:Clone()
	------------------------------------
	------------------------------------	
	
	-- Character died: Removes NPC from table, plays death sound, ragdoll, and destroys
	NPC.Hum.Died:Connect(function()
		
		------------------------------------
		------------------------------------
		Clone.Parent = workspace.NPC
		------------------------------------
		------------------------------------			
		
		table.remove(NPCs, table.find(NPCs, NPC))		
		InitiateExplode(NPC)		
		wait(Settings.DespawnDelay)		
		NPC.Char:Destroy()
	end)	
	
	NPC.Hum.HealthChanged:Connect(function(Health)
		NpcModule.UpdateHealthBar(Health, NPC, Settings)
	end)
	
	NpcModule.SetNet(NPC)	
	NpcModule.CreateRagdoll(NPC.Char, Settings)
		
	-- Main
	while wait(Settings.UpdateDelay) do
		if NPC.Hum.Health == 0 then
			break
		elseif NPC.Target then
			Follow(NPC)
		else
			wait(1)			
		end
	end
	
end

Core.NewThread(NpcModule.Locate, NPCs, Settings)

-- // Defaults \\ --

for _,Char in pairs(CollectionService:GetTagged(script.Name)) do
	Core.NewThread(Initiate, Char)
end

CollectionService:GetInstanceAddedSignal(script.Name):Connect(function(Char)
	Core.NewThread(Initiate, Char)
end)