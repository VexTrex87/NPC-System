local Giant = {}

local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local NpcModule = require(script.Parent.Parent.Helper)
local Settings = require(script.Settings)
local Core = require(game.ServerScriptService.Core)

local Target = workspace.Map.Target
local NPCs = {}

-- AI: Players

function Giant.Attack(NPC)
	if NPC.Target and Core.Mag(NPC.Root, NPC.Target) < Settings.AttackDist and math.random(Settings.Throwing.Chance) == 1 then		
		
		-- Defaults
		local LeftHand = NPC.Char.LeftHand
		local TargetChar = NPC.Target.Parent
		local PreviousCollisionGroupId = NPC.Target.CollisionGroupId
		
		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.Velocity = NPC.Root.CFrame.LookVector * Settings.Throwing.xVelocity + Vector3.new(0, Settings.Throwing.yVelocity, 0)
		
		NpcModule.SetCollisions(TargetChar, Settings.Throwing.CarriedCollisionGroupId)	
		
		-- Start
		NPC.PickUpAnim:Play(0.1, 1, 0.8)		
		wait(NPC.PickUpAnim.Length / 0.8 / 2)
		TargetChar.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall, true)
		NPC.Root.PickUp:Play()
		NPC.Target.CFrame = LeftHand.CFrame * Settings.Throwing.PosOffset * Settings.Throwing.RotOffset
		
		local Weld = Instance.new("WeldConstraint")
		Weld.Part0 = LeftHand
		Weld.Part1 = NPC.Target
		Weld.Parent = LeftHand
		
		-- Physics
		NPC.ThrowAnim:Play(NPC.PickUpAnim.Length / 0.8 / 2, 2)	
		NPC.ThrowAnim:GetMarkerReachedSignal("Throw"):Wait()	
		NPC.Root.Throw:Play()
		Weld:Destroy()	

		BodyVelocity.Parent = NPC.Target
		NpcModule.StartRagdoll(NPC.Target.Parent, Settings)
		wait(Settings.Throwing.InAirDur)
		BodyVelocity:Destroy()
		
		NpcModule.SetCollisions(TargetChar, PreviousCollisionGroupId)	
		wait(0.5)			
		NpcModule.StopRagdoll(TargetChar, Settings)
		
	elseif NPC.Target and Core.Mag(NPC.Root, NPC.Target) < Settings.AttackDist then
		NPC.PunchAnim:Play()
		NPC.Root.Punch:Play()
		NPC.Target.Parent.Humanoid:TakeDamage(math.random(Settings.MinDamage, Settings.MaxDamage))
		wait(Settings.AttackDelay)
	end	
end

function Giant.Follow(NPC)
	
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
				Giant.Follow(NPC)
				break
			end

			if NPC and NPC.Root and NPC.Target and NpcModule.CheckSight(NPC, NPC.Target, Settings) then
				repeat
					Giant.Attack(NPC)
					NpcModule.CheckFront(NPC, Settings)
					Hum:MoveTo(CurrentTarget.Position)
					wait(Settings.UpdateDelay)
				until not NPC.Target or not NPC.Root or CurrentTarget ~= NPC.Target or not NpcModule.CheckSight(NPC, NPC.Target, Settings) or Hum.Health == 0 or NPC.Target.Parent.Humanoid.Health == 0
				break
			end			
			
			if not NPC.Target then
				break
			elseif Core.Mag(NPC.Target, Waypoints[#Waypoints]) > Settings.TimeoutDist or CurrentTarget ~= NPC.Target then
				Giant.Follow(NPC)
				break
			end				
			
		end	
	else
		Giant.Follow(NPC)
	end
end

-- AI: Non-Humanoid Target

function Giant.AttackTarget(NPC)
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Target.Health.Value = Target.Health.Value - math.random(Settings.MinDamage, Settings.MaxDamage)
end

function Giant.FollowTarget(NPC)
	
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
				Giant.FollowTarget(NPC)
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
		Giant.FollowTarget(NPC)
	end
end

	-- AI: Main

function Giant.CheckToAttack(Obj, NPC)
	if Obj.Parent ~= NPC.Char and Obj:FindFirstAncestor("Target") and NPC.CanAttack then
		NPC.CanAttack = false
		Giant.AttackTarget(NPC)
		wait(Settings.AttackDelay)
		NPC.CanAttack = true
	end				
end	

function Giant.Initiate(TempChar)
	
	-- Creates table, ragdoll, sounds; sets properties, network ownership, collisions
	local NPC = NpcModule.CreateTable(TempChar, NPCs, {
		CanAttack = true,
		PunchAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Punch),
		PickUpAnim = TempChar.Humanoid:LoadAnimation(script.Animations.PickUp),
		CarryAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Carry),
		ThrowAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Throw)			
	})
	
	NpcModule.SetProperties(NPC.Hum, Settings)
	NpcModule.SetNet(NPC)	
	NpcModule.CreateRagdoll(NPC.Char, Settings)
	NpcModule.GiveAllSounds(script.Sounds, NPC.Root)	
	NpcModule.SetCollisions(TempChar, Settings.CollisionGroupId)	
	
	-- Died
	NPC.Hum.Died:Connect(function()
		table.remove(NPCs, table.find(NPCs, NPC))		
		NpcModule.StartRagdoll(NPC.Char, Settings)
		Debris:AddItem(NPC.Char, Settings.DespawnDelay)		
	end)	
	
	-- Health bar
	NPC.Hum.HealthChanged:Connect(function(Health)
		NpcModule.UpdateHealthBar(Health, NPC, Settings)
	end)	
	
	-- Attack listener
	NPC.Char.LeftHand.Touched:Connect(function(Obj)
		Giant.CheckToAttack(Obj, NPC)
	end)	
	
	NPC.Char.RightHand.Touched:Connect(function(Obj)
		Giant.CheckToAttack(Obj, NPC)
	end)	
	
	-- Main
	while wait(Settings.UpdateDelay) do
		if NPC.Hum.Health == 0 then
			break
		elseif NPC.Target then
			Giant.Follow(NPC)
		else
			Giant.FollowTarget(NPC)
		end
	end
	
end

Core.NewThread(NpcModule.Locate, NPCs, Settings)

return Giant