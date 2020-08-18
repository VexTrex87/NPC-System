script.Calm:Play()

while wait(1) do
	local PreviousTime = os.clock()
	local Pinged = game.ReplicatedStorage.Ping:InvokeServer()
	
	if Pinged then		
		local CurrentTime = os.clock()		
		local FPS = math.floor(workspace:GetRealPhysicsFPS())
		local Ping = math.floor((CurrentTime - PreviousTime) * 100)
		local Count = #workspace.NPC:GetChildren()
		
		script.Parent.TextColor3 = Color3.fromRGB(255, 255, 255)		
		script.Parent.Text = "FPS: " .. FPS .. "     PING: " .. Ping .. " ms     COUNT: " .. Count	
	else
		script.Parent.TextColor3 = Color3.fromRGB(255, 0, 0)
	end	
end