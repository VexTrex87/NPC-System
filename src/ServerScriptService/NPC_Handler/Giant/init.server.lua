-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local NpcModule = require(script.Parent.NPC)
local Settings = require(script.Settings)
local Core = require(game.ServerScriptService.Core)

local Target = workspace.Map.Target
local NPCs = {}

-- // Functions \\ --

	-- AI: Players
local function Attack(NPC)
	if NPC.Target and Core.Mag(NPC.Root, NPC.Target) < Settings.AttackDist and math.random(Settings.Throwing.Chance) == 1 then		
		
		local LeftHand = NPC.Char.LeftHand
		
		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.Velocity = NPC.Root.CFrame.LookVector * Settings.Throwing.xVelocity + Vector3.new(0, Settings.Throwing.yVelocity, 0)
		
		local PreviousCollisionGroupId = NPC.Target.CollisionGroupId
		for _,Part in pairs(Core.Get(NPC.Target.Parent, "BasePart")) do
			Part.CollisionGroupId = Settings.Throwing.CarriedCollisionGroupId
		end		
		
		NPC.PickUpAnim:Play(0.1, 1, 0.8)		
		wait(NPC.PickUpAnim.Length / 0.8 / 2)
		
		NPC.Target.Parent.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall, true)
		NPC.Root.PickUp:Play()
		NPC.Target.CFrame = LeftHand.CFrame * Settings.Throwing.PosOffset * Settings.Throwing.RotOffset
		
		local Weld = Instance.new("WeldConstraint")
		Weld.Part0 = LeftHand
		Weld.Part1 = NPC.Target
		Weld.Parent = LeftHand
		
		NPC.ThrowAnim:Play(NPC.PickUpAnim.Length / 0.8 / 2, 2)	
		NPC.ThrowAnim:GetMarkerReachedSignal("Throw"):Wait()	
		NPC.Root.Throw:Play()
		Weld:Destroy()	

		BodyVelocity.Parent = NPC.Target
		NpcModule.StartRagdoll(NPC.Target.Parent, Settings)
		wait(Settings.Throwing.InAirDur)
		BodyVelocity:Destroy()
				
		for _,Part in pairs(Core.Get(NPC.Target.Parent, "BasePart")) do
			Part.CollisionGroupId = PreviousCollisionGroupId
		end	
		
		local Char = NPC.Target.Parent
		
		wait(0.5)		
		
		NpcModule.StopRagdoll(Char, Settings)
		
	elseif NPC.Target and Core.Mag(NPC.Root, NPC.Target) < Settings.AttackDist then
		NPC.PunchAnim:Play()
		NPC.Root.Punch:Play()
		NPC.Target.Parent.Humanoid:TakeDamage(math.random(Settings.MinDamage, Settings.MaxDamage))
		wait(Settings.AttackDelay)
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

	-- AI: Non-Humanoid Target
local function AttackTarget(NPC)
	-- Plays animation, sound, and deals damage to target
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Target.Health.Value = Target.Health.Value - math.random(Settings.MinDamage, Settings.MaxDamage)
end

local function FollowTarget(NPC)
	
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
			
			-- Jumps if needed, moves to point, restarts function if doesn't reach point in 8 sec (default humanoid timeout)
			NpcModule.Jump(NPC, Point, Settings)
			Hum:MoveTo(Point.Position)		
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				PathBlocked:Disconnect()
				FollowTarget(NPC)
				break
			end			
			
			-- If the NPC is close to the non-humanoid target, it will look at it
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
		FollowTarget(NPC)
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
		CurrentTarget = nil,
		
		PunchAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Punch),
		PickUpAnim = TempChar.Humanoid:LoadAnimation(script.Animations.PickUp),
		CarryAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Carry),
		ThrowAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Throw)				
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
		NpcModule.StartRagdoll(NPC.Char, Settings)			
		wait(Settings.DespawnDelay)		
		NPC.Char:Destroy()
	end)	
	
	NPC.Hum.HealthChanged:Connect(function(Health)
		NpcModule.UpdateHealthBar(Health, NPC, Settings)
	end)
	
	NpcModule.SetNet(NPC)	
	NpcModule.CreateRagdoll(NPC.Char, Settings)
	
	-- Attack listener
	local CanAttack = true
	local function CheckToAttack(Obj)
		if Obj.Parent ~= NPC.Char and Obj:FindFirstAncestor("Target") and CanAttack then
			CanAttack = false
			AttackTarget(NPC)
			wait(Settings.AttackDelay)
			CanAttack = true
		end			
	end
	
	NPC.Char.LeftHand.Touched:Connect(CheckToAttack)	
	NPC.Char.RightHand.Touched:Connect(CheckToAttack)
	
	-- Punch sounds
	local Sounds = script.PunchSounds:GetChildren()	
	local RandomSound = Sounds[math.random(#Sounds)]:Clone()
	RandomSound.Name = "Punch"
	RandomSound.Parent = NPC.Root		
	
	-- Throwing sounds
	
	for _,Sound in pairs(script.Sounds:GetChildren()) do
		Sound:Clone().Parent = NPC.Root
	end
	
	-- Set collisions
	for _,Part in pairs(TempChar:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CollisionGroupId = Settings.CollisionGroupId
		end
	end
		
	-- Main
	while wait(Settings.UpdateDelay) do
		if NPC.Hum.Health == 0 then
			break
		elseif NPC.Target then
			Follow(NPC)
		else
			FollowTarget(NPC)
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