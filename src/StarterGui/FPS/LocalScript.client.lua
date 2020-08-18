script.Calm:Play()

while wait(1) do
	script.Parent.FPS.Text = "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())
	script.Parent.Count.Text = "NPC's: " .. #workspace.NPC:GetChildren()
end