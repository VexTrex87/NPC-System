local Puncher = {}

local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local NpcModule = require(script.Parent.Parent.Helper)
local Settings = require(script.Settings)
local Core = require(game.ServerScriptService.Core)

local Target = workspace.Map.Target
local NPCs = {}

-- AI: Players

function Puncher.Attack(NPC, Char)
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Char.Humanoid:TakeDamage(math.random(Settings.MinDamage, Settings.MaxDamage))
end

function Puncher.Follow(NPC)
	
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
			NpcModule.CheckFront(NPC,Settings)			
			Hum:MoveTo(Point.Position)
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Puncher.Follow(NPC)
				break
			end

			if NPC and NPC.Root and NPC.Target and NpcModule.CheckSight(NPC, NPC.Target, Settings) then
				repeat
					NpcModule.CheckFront(NPC, Settings)
					Hum:MoveTo(CurrentTarget.Position)
					wait(Settings.UpdateDelay)
				until not NPC.Target or not NPC.Root or CurrentTarget ~= NPC.Target or not NpcModule.CheckSight(NPC, NPC.Target, Settings) or Hum.Health == 0 or NPC.Target.Parent.Humanoid.Health == 0
				break
			end			
			
			if not NPC.Target then
				break
			elseif Core.Mag(NPC.Target, Waypoints[#Waypoints]) > Settings.TimeoutDist or CurrentTarget ~= NPC.Target then
				Puncher.Follow(NPC)
				break
			end				
			
		end	
	else
		Puncher.Follow(NPC)
	end
end

-- AI: Non-Humanoid Target

function Puncher.AttackTarget(NPC)
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Target.Health.Value = Target.Health.Value - math.random(Settings.MinDamage, Settings.MaxDamage)
end

function Puncher.FollowTarget(NPC)
	
	if not NPC or not NPC.Root then
		return
	end
	
	local Path = PathfindingService:CreatePath()  
	Path:ComputeAsync(NPC.Root.Position, NpcModule.FindPoint(NPC, workspace.Map.Points))
	local Hum = NPC.Hum
	
	local PathBlocked
	PathBlocked = Path.Blocked:Connect(function()
		Hum:MoveTo(NPC.Root.Position)
	end)
	
	if Path.Status == Enum.PathStatus.Success then
		for i,Point in ipairs(Path:GetWaypoints()) do	
			
			NpcModule.Jump(NPC, Point, Settings)
			Hum:MoveTo(Point.Position)		
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				PathBlocked:Disconnect()
				Puncher.FollowTarget(NPC)
				break
			end			
			
			if NPC and NPC.Root and NpcModule.CheckSight(NPC, Target.Center, Settings, Settings.TargetLineOfSightDist) then
				NPC.Root.CFrame = CFrame.new(NPC.Root.Position, Target.Center.Position)
			end					
			
			if NPC.Target then
				PathBlocked:Disconnect()
				break
			end				
			
			PathBlocked:Disconnect()
		end	
	else
		PathBlocked:Disconnect()
		Puncher.FollowTarget(NPC)
	end
end

-- AI: Main

function Puncher.CheckToAttack(Obj, NPC)
	if Obj.Parent ~= NPC.Char and NPC.Target then
		local p = game.Players:FindFirstChild(Obj.Parent.Name)
		if NPC.Hum.Health ~= 0 and NPC.CanAttack and p then
			NPC.CanAttack = false
			Puncher.Attack(NPC, p.Character)
			wait(Settings.AttackDelay)
			NPC.CanAttack = true
		end
	elseif Obj.Parent ~= NPC.Char and Obj:FindFirstAncestor("Target") then
		if NPC.CanAttack then
			NPC.CanAttack = false
			Puncher.AttackTarget(NPC)
			wait(Settings.AttackDelay)
			NPC.CanAttack = true
		end
	end		
end	

function Puncher.Initiate(TempChar)
	
	-- Create table, ragdoll; sets properties, network
	local NPC = NpcModule.CreateTable(TempChar, NPCs, {
		PunchAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Punch),
		CanAttack = true,
	})
	
	NpcModule.SetProperties(NPC.Hum, Settings)
	NpcModule.SetNet(NPC)	
	NpcModule.CreateRagdoll(NPC.Char, Settings)
	NpcModule.GiveAllSounds(script.Sounds, NPC.Root)
	
	NPC.Hum.Died:Connect(function()		
		table.remove(NPCs, table.find(NPCs, NPC))	
		NPC.Root.Died:Play()		
		NpcModule.StartRagdoll(NPC.Char, Settings)
		Debris:AddItem(NPC.Char, Settings.DespawnDelay)		
	end)	
	
	-- Health bar
	NPC.Hum.HealthChanged:Connect(function(Health)
		NpcModule.UpdateHealthBar(Health, NPC, Settings)
	end)
	
	-- Attacking listener
	NPC.Char.LeftHand.Touched:Connect(function(Obj)
		Puncher.CheckToAttack(Obj, NPC)
	end)	
	
	NPC.Char.RightHand.Touched:Connect(function(Obj)
		Puncher.CheckToAttack(Obj, NPC)
	end)		
	
	-- Main
	while wait(Settings.UpdateDelay) do
		if NPC.Hum.Health == 0 then
			break
		elseif NPC.Target then
			Puncher.Follow(NPC)
		else
			Puncher.FollowTarget(NPC)
		end
	end
	
end

Core.NewThread(NpcModule.Locate, NPCs, Settings)

return Puncher