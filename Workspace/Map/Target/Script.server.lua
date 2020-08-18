-- // Settings \\ --

local GREEN = Color3.fromRGB(0, 255, 0)
local YELLOW = Color3.fromRGB(255, 255, 0)
local RED = Color3.fromRGB(255, 0, 0)

-- // Variables \\ --

local Target = script.Parent
local Health = Target.Health
local MaxHealth = Target.MaxHealth
local Frame = Target.Pad.Health

-- // Defaults \\ --

Frame.Enabled = true
Frame.Label.Text = Health.Value .. "/" .. MaxHealth.Value

-- // Events \\ --

Health.Changed:Connect(function(Val)		
	if Val < 0 then
		script.DefeatSound:Play()
		Val = 0
	end
		
	local Perc = Val/MaxHealth.Value
	
	if Perc == 1 then
		Frame.Bar.Fill:TweenSize(UDim2.new(Perc, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.5, true)
	else
		Frame.Bar.Fill.Size = UDim2.new(Perc, 0, 1, 0)
	end

	if Perc >= 0.5 then
		Frame.Bar.Fill.BackgroundColor3 = YELLOW:lerp(GREEN, Perc)
	else
		Frame.Bar.Fill.BackgroundColor3 = RED:lerp(YELLOW, Perc)
	end	
	
	Frame.Label.Text = Val .. "/" .. MaxHealth.Value
	
	if Val == 0 then
		Health.Value = MaxHealth.Value
	end
	
	wait(5)
	script.DefeatSound:Pause()
	
end)	