local Mouse = game.Players.LocalPlayer:GetMouse()
local PreviousFrame

Mouse.Move:Connect(function()	
	local Target = Mouse.Target
	
	if Target and Target.Parent ~= PreviousFrame and PreviousFrame then
		PreviousFrame.Visible = false
	end
	
	if Target and Target.Parent.Parent == workspace.NPC then	
		PreviousFrame = Target.Parent.Head.Health.Frame
		PreviousFrame.Visible = true
	end	
end)