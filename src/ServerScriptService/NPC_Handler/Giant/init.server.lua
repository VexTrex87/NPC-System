-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local Settings = require(script.Settings)
local Core = require(5584659207)

local Target = workspace.Map.Target
local NPCs = {}

-- // Functions \\ --

	-- Helpers

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

local function CheckFront(NPC)
	local MyRay = Ray.new(NPC.Root.Position, NPC.Root.CFrame.lookVector * Settings.SpacingDist)
	local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(MyRay, {NPC.Char})
	
	if Hit and Hit:IsDescendantOf(workspace.NPC) and Core.Mag(NPC.Root, Pos) < Settings.SpacingDist and Core.Round(Hit.Velocity.Magnitude) > 0 then		
		local PreviousSpeed = NPC.Hum.WalkSpeed		
		NPC.Hum.WalkSpeed = Settings.WalkSpeed
		
		for x = 0, Settings.AttemptSpacingDuration, Settings.UpdateDelay do
			wait(Settings.UpdateDelay)			
			if not Hit or Core.Mag(NPC.Root, Pos) < Settings.SpacingDist or Core.Round(Hit.Velocity.Magnitude) > 0 then
				NPC.Hum.WalkSpeed = PreviousSpeed
				break
			end
		end				
	end	
end

-- AI: Helper

local function StartRagdoll(Char)			
	for _,desc in pairs(Char:GetDescendants()) do
		if (desc:IsA("Motor6D") and desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint") and Settings.JointConfiguration[desc.Name]) then
			desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint").Enabled = true
			desc.Enabled = false
		end
	end	
end

local function StopRagdoll(Char)			
	for _,desc in pairs(Char:GetDescendants()) do
		if (desc:IsA("Motor6D") and desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint") and Settings.JointConfiguration[desc.Name]) then
			desc.Enabled = true
			desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint").Enabled = false
		end
	end	
end


local function CreateRagdoll(Char)
	-- Replaces all Motor6D's with BallSocketsConstraints
	
	--Char.HumanoidRootPart.Anchored = true
	--Char.HumanoidRootPart.CanCollide = false
	--Char.HumanoidRootPart:BreakJoints()
			
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
				Joint.Enabled = false
				--desc:Destroy()
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
								
	Core.NewThread(function()
		wait(Settings.JumpDelay)
		if Core.Round(Hum.WalkToPoint.Y) > Core.Round(NPC.Root.Position.Y) then
			Hum.Jump = true
		end
	end)	
end

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
		StartRagdoll(NPC.Target.Parent)
		wait(Settings.Throwing.InAirDur)
		BodyVelocity:Destroy()
				
		for _,Part in pairs(Core.Get(NPC.Target.Parent, "BasePart")) do
			Part.CollisionGroupId = PreviousCollisionGroupId
		end	
		
		local Char = NPC.Target.Parent
		
		wait(0.5)		
		
		StopRagdoll(Char)
		
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
			Jump(NPC, Point)		
			CheckFront(NPC)			
			Hum:MoveTo(Point.Position)
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Follow(NPC)
				break
			end

			if NPC and NPC.Root and NPC.Target and CheckSight(NPC, NPC.Target) then
				repeat
					Attack(NPC)
					CheckFront(NPC)
					Hum:MoveTo(CurrentTarget.Position)
					wait(Settings.UpdateDelay)
				until not NPC.Target or not NPC.Root or CurrentTarget ~= NPC.Target or not CheckSight(NPC, NPC.Target) or Hum.Health == 0 or NPC.Target.Parent.Humanoid.Health == 0
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
				PathBlocked:Disconnect()
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
		StartRagdoll(NPC.Char)			
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
	
	-- Attack listener
	local CanAttack = true
	local function CheckToAttack(Obj, NPC)
		if Obj.Parent ~= NPC.Char and Obj:FindFirstAncestor("Target") and CanAttack then
			CanAttack = false
			AttackTarget(NPC)
			wait(Settings.AttackDelay)
			CanAttack = true
		end			
	end
	
	NPC.Char.LeftHand.Touched:Connect(function(Obj)
		CheckToAttack(Obj, NPC)
	end)
	
	NPC.Char.RightHand.Touched:Connect(function(Obj)
		CheckToAttack(Obj, NPC)
	end)	
	
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
	
	CreateRagdoll(NPC.Char)
	
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

Core.NewThread(function() -- Locate
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
						local CurrentDist = Core.Mag(Root, NPC.Root)
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
				local TempDist = Core.Mag(NPC.Root, v)
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
	Core.NewThread(Initiate, Char)
end

CollectionService:GetInstanceAddedSignal(script.Name):Connect(function(Char)
	Core.NewThread(Initiate, Char)
end)