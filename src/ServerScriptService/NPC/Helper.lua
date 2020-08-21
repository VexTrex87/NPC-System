local CollectionService = game:GetService("CollectionService")
local Core = require(game.ServerScriptService.Core)
local NpcModule = {}

-- Locating

function NpcModule.CheckPov(NPC, Target, Settings)
	-- Uses dot product to check if the target is within its perspective
	
	local NpcToChar = (NPC.Char.Head.Position - Target.Parent.Head.Position).Unit
	local NpcLook = NPC.Char.Head.CFrame.LookVector
	local DotProduct = NpcToChar:Dot(NpcLook)
	
	if DotProduct >= Settings.PovX then
		return true
	end

end

function NpcModule.CheckSight(NPC, Target, Settings, Dist)
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

function NpcModule.CheckFront(NPC, Settings)
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

function NpcModule.FindPoint(NPC, Points)
	-- Finds the point in the map with the least amount of NPC's at it
	
	local NewTarget
	local LeastPopulatedPoint = math.huge
	
	if NPC.CurrentTarget then
		NPC.CurrentTarget.Count.Value = NPC.CurrentTarget.Count.Value - 1
	end
		
	for _,Point in pairs(Points:GetChildren()) do
		if Point.Count.Value < LeastPopulatedPoint then
			LeastPopulatedPoint = Point.Count.Value
			NewTarget = Point
		end
	end
	
	NPC.CurrentTarget = NewTarget
	NewTarget.Count.Value = NewTarget.Count.Value + 1	
	
	return NewTarget.Position
end

function NpcModule.Locate(NPCs, Settings)
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
				if NpcModule.CheckPov(NPC, v, Settings) then
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
end

-- NPC

function NpcModule.Jump(NPC, Point, Settings)
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

-- Initiate

function NpcModule.GiveAllSounds(Folder, Target)
	for _,Sound in pairs(Folder:GetChildren()) do
		Sound:Clone().Parent = Target
	end	
end

function NpcModule.SetCollisions(Char, ID)
	for _,Part in pairs(Char:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CollisionGroupId = ID
		end
	end	
end

function NpcModule.UpdateHealthBar(Health, NPC, Settings)
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
end	

function NpcModule.SetNet(NPC)
	for _,Part in pairs(NPC.Char:GetDescendants()) do
		if Part:IsA("BasePart") and Part:CanSetNetworkOwnership() then
			Part:SetNetworkOwner(nil)
		end
	end	
end

function NpcModule.SetProperties(Hum, Settings)
	for Name, Val in pairs(Settings.Humanoid) do
		Hum[Name] = Val
	end	
end

function NpcModule.CreateTable(TempChar, Target, OptionalTbl)
	local NPC = {
		Char = TempChar,
		Root = TempChar.HumanoidRootPart,
		Hum = TempChar.Humanoid,
		Target = nil,
		CurrentTarget = nil
	}		
	
	for i,v in pairs(OptionalTbl) do
		NPC[i] = v
	end
	
	table.insert(Target, NPC)
	return NPC
end

-- Ragdoll

function NpcModule.StartRagdoll(Char, Settings)			
	for _,desc in pairs(Char:GetDescendants()) do
		if (desc:IsA("Motor6D") and desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint") and Settings.JointConfiguration[desc.Name]) then
			desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint").Enabled = true
			desc.Enabled = false
		end
	end	
end

function NpcModule.StopRagdoll(Char, Settings)			
	for _,desc in pairs(Char:GetDescendants()) do
		if (desc:IsA("Motor6D") and desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint") and Settings.JointConfiguration[desc.Name]) then
			desc.Enabled = true
			desc.Parent:FindFirstChildWhichIsA("BallSocketConstraint").Enabled = false
		end
	end	
end

function NpcModule.CreateRagdoll(Char, Settings)
			
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

return NpcModule