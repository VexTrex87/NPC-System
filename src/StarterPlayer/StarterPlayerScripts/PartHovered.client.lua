local UPDATE_DELAY = 0.5
local Mouse = game.Players.LocalPlayer:GetMouse()
local PreviousFrame

while wait(UPDATE_DELAY) do
	local Target = Mouse.Target
	
	if Target and Target.Parent ~= PreviousFrame and PreviousFrame then
		PreviousFrame.Visible = false
	end
	
	if Target and Target.Parent.Parent == workspace.NPC then	
		PreviousFrame = Target.Parent.Head.Health.Frame
		PreviousFrame.Visible = true
	end	
end