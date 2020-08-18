-- // Variables \\ --

	-- Services
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

	-- Modules
local Settings = require(script.Settings)
local NewThread = require(game.ServerScriptService.NewThread)

	-- Instances
local Target = workspace.Map.Target

	-- Script
local NPCs = {}

-- // Functions \\ --

	-- Helpers
local function Round(n)
	return math.floor(n + 0.5)
end

local function Mag(PointA, PointB)	
	-- Helper function to get magnitude of two instances and/or positions
	
	if typeof(PointA) ~= Vector3 then 
		PointA = PointA.Position 
	end
	
	if typeof(PointB) ~= Vector3 then 
		PointB = PointB.Position 
	end
	
	return (PointA - PointB).Magnitude 
end

local function CheckPov(NPC, Target)
	-- Uses dot product to check if the target is within its perspective
	
	local NpcToChar = (NPC.Char.Head.Position - Target.Parent.Head.Position).Unit
	local NpcLook = NPC.Char.Head.CFrame.LookVector
	local DotProduct = NpcToChar:Dot(NpcLook)
	
	if DotProduct >= Settings.PovX then
		return true
	end

end

local function CheckSight(NPC, Target, Dist)
	-- Uses rays to check if the target is in its direct line of sight
	
	local PovIgnore = Settings.PovIgnore
	table.insert(PovIgnore, NPC.Char)
	
	if not Dist then
		Dist = Settings.LineOfSightDist
	end
	
	local NewRay = Ray.new(NPC.Root.Position, (Target.Position - NPC.Root.Position).Unit * Dist)
	local Hit = workspace:FindPartOnRayWithIgnoreList(NewRay, PovIgnore)
	
	if Hit then
		if Hit:IsDescendantOf(Target.Parent) and math.abs(Hit.Position.Y - NPC.Root.Position.Y) <= Settings.PovY then
			return true
		end
	end	

end

	-- AI: Helper
local function Ragdoll(Char)
	-- Replaces all Motor6D's with BallSocketsConstraints
	
	Char.HumanoidRootPart.Anchored = true
	Char.HumanoidRootPart.CanCollide = false
	Char.HumanoidRootPart:BreakJoints()
			
	for _,desc in pairs(Char:GetDescendants()) do
		if (desc:IsA("Motor6D") and Settings.JointConfiguration[desc.Name]) then
			local Joint = Instance.new(Settings.JointConfiguration[desc.Name][1] .. "Constraint")
			local Attachment0 = desc.Parent:FindFirstChild(desc.Name .. "Attachment") or desc.Parent:FindFirstChild(desc.Name .. "RigAttachment")
			local Attachment1 = desc.Part0:FindFirstChild(desc.Name .. "Attachment") or desc.Part0:FindFirstChild(desc.Name .. "RigAttachment")
					
			if (Settings.JointConfiguration[desc.Name].Properties) then
				for property,value in pairs(Settings.JointConfiguration[desc.Name].Properties) do
					Joint[property] = value
				end
			end
					
			if (Attachment0 and Attachment1) then
				Joint.Attachment0 = Attachment0
				Joint.Attachment1 = Attachment1
				Joint.Parent = desc.Parent
				desc:Destroy()
			end
		elseif (desc:IsA("Attachment")) then
			desc.Axis = Vector3.new(0, 1, 0)
			desc.SecondaryAxis = Vector3.new(0, 0, 1)
			desc.Rotation = Vector3.new(0, 0, 0)
		end
	end	
end

local function Jump(NPC, Point)
	-- Jumps if the point requires a jump or the move to position is higher than the NPC's position
	
	local Hum = NPC.Hum
	
	if Point.Action == Enum.PathWaypointAction.Jump then
		Hum.Jump = true
	end
								
	NewThread(function()
		wait(Settings.JumpDelay)
		if Round(Hum.WalkToPoint.Y) > Round(NPC.Root.Position.Y) then
			Hum.Jump = true
		end
	end)	
end

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
			Jump(NPC, Point)					
			Hum:MoveTo(Point.Position)
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Follow(NPC)
				break
			end

			if NPC and NPC.Root and NPC.Target and CheckSight(NPC, NPC.Target) then
				repeat
					Hum:MoveTo(CurrentTarget.Position)
					wait(Settings.UpdateDelay)
				until not NPC.Target or not NPC.Root or CurrentTarget ~= NPC.Target or not CheckSight(NPC, NPC.Target) or Hum.Health == 0 or NPC.Target.Parent.Humanoid.Health == 0
				break
			end			
			
			if not NPC.Target then
				break
			elseif Mag(NPC.Target, Waypoints[#Waypoints]) > Settings.TimeoutDist or CurrentTarget ~= NPC.Target then
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

local function FindPoint(NPC)
	-- Finds the point in the map with the least amount of NPC's at it
	
	local NewTarget
	local LeastPopulatedPoint = math.huge
	
	if NPC.CurrentTarget then
		NPC.CurrentTarget.Count.Value = NPC.CurrentTarget.Count.Value - 1
	end
		
	for _,Point in pairs(workspace.Map.Points:GetChildren()) do
		if Point.Count.Value < LeastPopulatedPoint then
			LeastPopulatedPoint = Point.Count.Value
			NewTarget = Point
		end
	end
	
	NPC.CurrentTarget = NewTarget
	NewTarget.Count.Value = NewTarget.Count.Value + 1	
	
	return NewTarget.Position
end

local function FollowTarget(NPC)
	
	if not NPC or not NPC.Root then
		return
	end
	
	local Path = PathfindingService:CreatePath()  
	Path:ComputeAsync(NPC.Root.Position, FindPoint(NPC))
	local Hum = NPC.Hum
	
	local PathBlocked
	PathBlocked = Path.Blocked:Connect(function()
		Hum:MoveTo(NPC.Root.Position)
	end)
	
	if Path.Status == Enum.PathStatus.Success then
		for i,Point in ipairs(Path:GetWaypoints()) do	
			
			-- Jumps if needed, moves to point, restarts function if doesn't reach point in 8 sec (default humanoid timeout)
			Jump(NPC, Point)
			Hum:MoveTo(Point.Position)		
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				PathBlocked:Disconect()
				FollowTarget(NPC)
				break
			end			
			
			-- If the NPC is close to the non-humanoid target, it will look at it
			if NPC and NPC.Root and CheckSight(NPC, Target.Center, Settings.TargetLineOfSightDist) then
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
	
	-- Character died: Removes NPC from table, plays death sound, ragdoll, and destroys
	NPC.Hum.Died:Connect(function()
		table.remove(NPCs, table.find(NPCs, NPC))
		
		NPC.Root.Died.PlaybackSpeed = math.random(Settings.Sounds.DeathSpeed_Min*100, Settings.Sounds.DeathSpeed_Max*100)/100
		NPC.Root.Died.PitchEffect.Octave = math.random(Settings.Sounds.DeathPitch_Min*100, Settings.Sounds.DeathPitch_Max*100)/100
		NPC.Root.Died:Play()
		
		Ragdoll(NPC.Char)			
		wait(Settings.DespawnDelay)		
		NPC.Char:Destroy()
	end)	
	
	-- Health bar
	NPC.Hum.HealthChanged:Connect(function()			
		local Health = NPC.Hum.Health		
		if Health < 0 then
			Health = 0
		end
		
		local Perc = Health/NPC.Hum.MaxHealth
		local Frame = NPC.Char.Head.Health.Frame
		
		Frame.Size = UDim2.new(Perc, 0, 1, 0)
		if Perc >= 0.5 then
			Frame.Frame.BackgroundColor3 = Settings.HealthBar.Yellow:lerp(Settings.HealthBar.Green, Perc)
		else
			Frame.Frame.BackgroundColor3 = Settings.HealthBar.Red:lerp(Settings.HealthBar.Yellow, Perc)
		end
	end)	

	-- Ensures sever has 100% control over the NPC to ensure minimum client control
	for _,Part in pairs(NPC.Char:GetDescendants()) do
		if Part:IsA("BasePart") and Part:CanSetNetworkOwnership() then
			Part:SetNetworkOwner(nil)
		end
	end	
	
	-- Attacking event listener
	local CanAttack = true
	
	local function CheckToAttack(Obj, NPC)
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
	
	NPC.Char.LeftHand.Touched:Connect(function(Obj)
		CheckToAttack(Obj, NPC)
	end)
	
	NPC.Char.RightHand.Touched:Connect(function(Obj)
		CheckToAttack(Obj, NPC)
	end)
	
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

NewThread(function() -- Locate
	while wait(Settings.UpdateDelay) do		
		for _,NPC in pairs(NPCs) do		
			
			local Dist = Settings.DetectionDist
			local Target, Pot, See = nil, {}, {}
			
			-- Adds potential players as targets if within range
			for _,p in pairs(game.Players:GetPlayers()) do
				local Char = p.Character
				if Char then
					local Root = Char:FindFirstChild("HumanoidRootPart")
					if Root then
						local CurrentDist = Mag(Root, NPC.Root)
						if Char.Humanoid.Health > 0 and CurrentDist < Dist then
							table.insert(Pot, Root)
						end
					end
				end
			end				
			
			-- Prioritizes those in its perspective
			for _,v in ipairs(Pot) do
				if CheckPov(NPC, v) then
					table.insert(See, v) 
				elseif #See == 0 then
					Target = v
				end
			end
			
			-- Prioritizes those closest to it
			for i,v in ipairs(See) do
				local TempDist = Mag(NPC.Root, v)
				if TempDist < Dist then
					Dist = TempDist
					Target = v
				end
			end
			
			NPC.Target = Target				
		end				
	end
end)

-- // Defaults \\ --

for _,Char in pairs(CollectionService:GetTagged(script.Name)) do
	NewThread(Initiate, Char)
end

CollectionService:GetInstanceAddedSignal(script.Name):Connect(function(Char)
	NewThread(Initiate, Char)
end)