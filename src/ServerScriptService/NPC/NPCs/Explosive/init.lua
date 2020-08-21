local Explosive = {}

local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local NpcModule = require(script.Parent.Parent.Helper)
local Settings = require(script.Settings)
local Core = require(game.ServerScriptService.Core)
local Explode = require(script.Explode)

local Target = workspace.Map.Target
local NPCs = {}

-- AI: Players

function Explosive.InitiateExplode(NPC)
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

function Explosive.Attack(NPC)
	if NPC.Target and Core.Mag(NPC.Root, NPC.Target) < Settings.AttackDist then
		NPC.Hum:MoveTo(NPC.Root.Position)		
		Explosive.InitiateExplode(NPC)
	end	
end

function Explosive.Follow(NPC)
	
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
			
			NpcModule.Jump(NPC, Point, Settings)		
			NpcModule.CheckFront(NPC, Settings)			
			Hum:MoveTo(Point.Position)
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Explosive.Follow(NPC)
				break
			end

			if NPC and NPC.Root and NPC.Target and NpcModule.CheckSight(NPC, NPC.Target, Settings) then
				repeat
					Explosive.Attack(NPC)
					NpcModule.CheckFront(NPC, Settings)
					Hum:MoveTo(CurrentTarget.Position)
					wait(Settings.UpdateDelay)
				until not NPC.Target or not NPC.Root or CurrentTarget ~= NPC.Target or not NpcModule.CheckSight(NPC, NPC.Target, Settings) or Hum.Health == 0 or NPC.Target.Parent.Humanoid.Health == 0
				break
			end			
			
			if not NPC.Target then
				break
			elseif Core.Mag(NPC.Target, Waypoints[#Waypoints]) > Settings.TimeoutDist or CurrentTarget ~= NPC.Target then
				Explosive.Follow(NPC)
				break
			end				
			
		end	
	else
		Explosive.Follow(NPC)
	end
end

	-- AI: Main
function Explosive.Initiate(TempChar)
	
	-- Creates table, ragdoll; sets properties, network
	local NPC = NpcModule.CreateTable(TempChar, NPCs, {
		ExplodeAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Explode),
	})
	
	NpcModule.SetProperties(NPC.Hum, Settings)
	NpcModule.SetNet(NPC)	
	NpcModule.CreateRagdoll(NPC.Char, Settings)
	
	-- Died
	NPC.Hum.Died:Connect(function()			
		table.remove(NPCs, table.find(NPCs, NPC))
		Debris:AddItem(NPC.Char, Settings.DespawnDelay)		
		Explosive.InitiateExplode(NPC)	
	end)	
	
	-- Health Bar
	NPC.Hum.HealthChanged:Connect(function(Health)
		NpcModule.UpdateHealthBar(Health, NPC, Settings)
	end)
	
	-- Main
	while wait(Settings.UpdateDelay) do
		if NPC.Hum.Health == 0 then
			break
		elseif NPC.Target then
			Explosive.Follow(NPC)
		else
			wait(1)			
		end
	end
	
end

Core.NewThread(NpcModule.Locate, NPCs, Settings)

return Explosive