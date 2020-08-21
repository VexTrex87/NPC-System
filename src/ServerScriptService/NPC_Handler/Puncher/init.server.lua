-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local NpcModule = require(script.Parent.NPC)
local Settings = require(script.Settings)
local Core = require(game.ServerScriptService.Core)

local Target = workspace.Map.Target
local NPCs = {}

-- // Functions \\ --

	-- AI: Players
local function Attack(NPC, Char)
	-- Plays animation, sound, and deals damage to target
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Char.Humanoid:TakeDamage(math.random(Settings.MinDamage, Settings.MaxDamage))
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
			NpcModule.CheckFront(NPC,Settings)			
			Hum:MoveTo(Point.Position)
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Follow(NPC)
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
		PunchAnim = TempChar.Humanoid:LoadAnimation(script.Animations.Punch),
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
		
		NPC.Root.Died.PlaybackSpeed = math.random(Settings.Sounds.DeathSpeed_Min*100, Settings.Sounds.DeathSpeed_Max*100)/100
		NPC.Root.Died.PitchEffect.Octave = math.random(Settings.Sounds.DeathPitch_Min*100, Settings.Sounds.DeathPitch_Max*100)/100
		NPC.Root.Died:Play()
		
		NpcModule.StartRagdoll(NPC.Char, Settings)			
		wait(Settings.DespawnDelay)		
		NPC.Char:Destroy()
	end)	
		
	NPC.Hum.HealthChanged:Connect(function(Health)
		NpcModule.UpdateHealthBar(Health, NPC, Settings)
	end)
	
	NpcModule.SetNet(NPC)	
	NpcModule.CreateRagdoll(NPC.Char, Settings)
	
	-- Attacking event listener
	local CanAttack = true	
	local function CheckToAttack(Obj)
		if Obj.Parent ~= NPC.Char and NPC.Target then
			local p = game.Players:FindFirstChild(Obj.Parent.Name)
			if NPC.Hum.Health ~= 0 and CanAttack and p then
				CanAttack = false
				Attack(NPC, p.Character)
				wait(Settings.AttackDelay)
				CanAttack = true
			end
		elseif Obj.Parent ~= NPC.Char and Obj:FindFirstAncestor("Target") then
			if CanAttack then
				CanAttack = false
				AttackTarget(NPC)
				wait(Settings.AttackDelay)
				CanAttack = true
			end
		end			
	end
	
	NPC.Char.LeftHand.Touched:Connect(CheckToAttack)	
	NPC.Char.RightHand.Touched:Connect(CheckToAttack)
	
	-- Punch Sounds
	local Sounds = script.PunchSounds:GetChildren()	
	local RandomSound = Sounds[math.random(#Sounds)]:Clone()
	RandomSound.Name = "Punch"
	RandomSound.Parent = NPC.Root
	
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