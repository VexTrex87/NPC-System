local NpcModule = require(script.Parent.Parent.Parent.Helper)
local Settings = require(script.Parent.Settings)

function Carry(NPC)
	
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
	
end

return Carry
