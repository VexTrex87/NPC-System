-- // Variables \\ --

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Settings = require(script.Settings)
local Target = workspace.Map.Target
local NPCs = {}

-- // Functions \\ --

	-- Helpers
local function NewThread(func,...)
	-- Helper function to create multiple threads
	
	local Thread = coroutine.wrap(func)
	Thread(...)	
end

local function Round(n)
	-- Helper function to round numbers
	return math.floor(n + 0.5)
end

local function Mag(PointA, PointB)	
	-- Helper function to get magnitude
	
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

local function CheckSight(NPC, Target)
	-- Uses rays to check if the target is in its direct line of sight
	
	local NewRay = Ray.new(NPC.Root.Position, (Target.Position - NPC.Root.Position).Unit * 40)
	local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(NewRay, {NPC.Char})
	
	if Hit then
		if Hit:IsDescendantOf(Target.Parent) and math.abs(Hit.Position.Y - NPC.Root.Position.Y) <= Settings.PovY then
			return true
		end
	end	
end

	-- AI
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

local function Attack(NPC, Char)
	-- Plays animation, sound, and deals damage to target
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Char.Humanoid:TakeDamage(math.random(Settings.MinDamage, Settings.MaxDamage))
end

local function AttackTarget(NPC)
	-- Plays animation, sound, and deals damage to target
	NPC.PunchAnim:Play()
	NPC.Root.Punch:Play()
	Target.Health.Value = Target.Health.Value - math.random(Settings.MinDamage, Settings.MaxDamage)
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
			
			-- Jumps if needed
			if Point.Action == Enum.PathWaypointAction.Jump then
				Hum.Jump = true
			end
								
			NewThread(function()
				wait(Settings.JumpDelay)
				if Round(Hum.WalkToPoint.Y) > Round(NPC.Root.Position.Y) then
					Hum.Jump = true
				end
			end)		
			
			-- Moves to point, restarts function if needed		
			Hum:MoveTo(Point.Position)
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				Hum.Jump = true
				Follow(NPC)
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

local function FindPoint(NPC)
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
	local Waypoints = Path:GetWaypoints()
	
	Path.Blocked:Connect(function()
		Hum:MoveTo(NPC.Root.Position)
	end)
	
	if Path.Status == Enum.PathStatus.Success then
		for i,Point in ipairs(Waypoints) do	
			
			-- Jumps if needed
			if Point.Action == Enum.PathWaypointAction.Jump then
				Hum.Jump = true
			end
								
			NewThread(function()
				wait(Settings.JumpDelay)
				if Round(Hum.WalkToPoint.Y) > Round(NPC.Root.Position.Y) then
				Hum.Jump = true
				end
			end)		
			
			-- Moves to point, restarts function if needed		
			Hum:MoveTo(Point.Position)		
			
			local Timeout = Hum.MoveToFinished:Wait()
			if not Timeout then
				FollowTarget(NPC)
				break
			end
			
			if NPC.Target then
				break
			end				
			
		end	
	else
		FollowTarget(NPC)
	end
end

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
	
	local Clone1, Clone2 = NPC.Char:Clone(), nil
	if math.random(2) == 1 then
		Clone2 = NPC.Char:Clone()
	end
	
	for Name, Val in pairs(Settings.Humanoid) do
		NPC.Hum[Name] = Val
	end
	
	-- Character died
	NPC.Hum.Died:Connect(function()
		table.remove(NPCs, table.find(NPCs, NPC))
		
		NPC.Root.Died.PlaybackSpeed = math.random(90, 110)/100
		NPC.Root.Died.PitchEffect.Octave = math.random(85, 105)/100
		NPC.Root.Died:Play()
		
		Ragdoll(NPC.Char)			
		wait(Settings.DespawnDelay)		
		NPC.Char:Destroy()
		
		wait(math.random(5, 20))
		
		Clone1.Parent = workspace.NPC
		if Clone2 then
			Clone2.Parent = workspace.NPC
		end
		
	end)	
	
	-- Health bar
	NPC.Hum.HealthChanged:Connect(function()			
		local Health = NPC.Hum.Health		
		if Health < 0 then
			Health = 0
		end
		
		local Perc = Health/NPC.Hum.MaxHealth

		NPC.Char.Head.Health.Frame.Frame:TweenSize(UDim2.new(Perc, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.5, true)
		if Perc >= 0.5 then
			NPC.Char.Head.Health.Frame.Frame.BackgroundColor3 = Settings.HealthBar.Yellow:lerp(Settings.HealthBar.Green, Perc)
		else
			NPC.Char.Head.Health.Frame.Frame.BackgroundColor3 = Settings.HealthBar.Red:lerp(Settings.HealthBar.Yellow, Perc)
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
	local CanTurn = true
	NPC.Root.Touched:Connect(function(Obj)
		if Obj.Parent ~= NPC.Char then
			if NPC.Target then
				local p = game.Players:FindFirstChild(Obj.Parent.Name)
				if NPC.Hum.Health ~= 0 and CanAttack and p then
					CanAttack = false
					Attack(NPC, p.Character)
					wait(Settings.AttackDelay)
					CanAttack = true
				end
			elseif Obj:FindFirstAncestor("Target") then
				if CanAttack then
					CanAttack = false
					AttackTarget(NPC)
					wait(Settings.AttackDelay)
					CanAttack = true
				end
			end		
		end
	end)	
	
	-- Punch Sounds
	local Sounds = script.PunchSounds:GetChildren()	
	local RandomSound = Sounds[math.random(1, #Sounds)]:Clone()
	RandomSound.Parent = NPC.Root
	RandomSound.Name = "Punch"
	
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

	-- Locate
NewThread(function()
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

for _,Char in pairs(CollectionService:GetTagged("Dummy")) do
	NewThread(Initiate, Char)
end

CollectionService:GetInstanceAddedSignal("Dummy"):Connect(function(Char)
	NewThread(Initiate, Char)
end)