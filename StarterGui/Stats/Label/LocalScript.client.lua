-- // Settings \\ --

local UPDATE_DELAY = 1
local SUCCESS_COLOR = Color3.fromRGB(255, 255, 255)
local ERROR_COLOR = Color3.fromRGB(255, 0, 0)

-- // Variables \\ --

local PingRemote = game.ReplicatedStorage.Ping
local ThreadValue = game.ReplicatedStorage.Threads

-- // Main \\ --

script.Calm:Play()

while wait(UPDATE_DELAY) do
	local PreviousTime = os.clock()
	local Pinged = PingRemote:InvokeServer()
	
	if Pinged then		
		local CurrentTime = os.clock()	
	
		local FPS = math.floor(workspace:GetRealPhysicsFPS())
		local Ping = math.floor((CurrentTime - PreviousTime) * 100)
		local Count = #workspace.NPC:GetChildren()
		local Threads = ThreadValue.Value
		
		local Parts = 0		
		for _,Part in pairs(workspace:GetDescendants()) do
			if Part:IsA("BasePart") then
				Parts = Parts + 1
			end
		end		
		
		script.Parent.TextColor3 = SUCCESS_COLOR	
		script.Parent.Text = "FPS: " .. FPS .. "   PING: " .. Ping .. " ms   NPC's: " .. Count .. "   PARTS: " .. Parts	 .. "   OTHER THREADS: " .. Threads		
	else
		script.Parent.TextColor3 = ERROR_COLOR
	end	
end