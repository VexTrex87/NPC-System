local Settings = {
	LeftHip = {"BallSocket"};
	RightHip = {"BallSocket"};
	Waist = {"BallSocket"};
	LeftShoulder = {"BallSocket"};
	RightShoulder = {"BallSocket"};
	LeftElbow = {"BallSocket"};
	RightElbow = {"BallSocket"};
	Neck = {"BallSocket"};
		
	LeftAnkle = {
		"Hinge";
		Properties = {
			LimitsEnabled = true;
			UpperAngle = 15;
			LowerAngle = -45;
		};
	};
		
	RightAnkle = {
		"Hinge";
		Properties = {
			LimitsEnabled = true;
			UpperAngle = 15;
			LowerAngle = -45;
		};
	};
		
	LeftKnee = {
		"Hinge";
		Properties = {
			LimitsEnabled = true;
			UpperAngle = 0;
			LowerAngle = -75;
		};
	};
		
	RightKnee = {
		"Hinge";
		Properties = {
			LimitsEnabled = true;
			UpperAngle = 0;
			LowerAngle = -75;
		};
	};		
		
	LeftWrist = {
		"Hinge";
		Properties = {
			LimitsEnabled = true;
			UpperAngle = 0;
			LowerAngle = 0;
		};
	};
		
	RightWrist = {
		"Hinge";
		Properties = {
			LimitsEnabled = true;
			UpperAngle = 0;
			LowerAngle = 0;
		};
	};	
}

local Char = script.Parent
for _,desc in pairs(Char:GetDescendants()) do
	if (desc:IsA("Motor6D") and Settings[desc.Name]) then
		local Joint = Instance.new(Settings[desc.Name][1] .. "Constraint")
		local Attachment0 = desc.Parent:FindFirstChild(desc.Name .. "Attachment") or desc.Parent:FindFirstChild(desc.Name .. "RigAttachment")
		local Attachment1 = desc.Part0:FindFirstChild(desc.Name .. "Attachment") or desc.Part0:FindFirstChild(desc.Name .. "RigAttachment")
					
		if (Settings[desc.Name].Properties) then
			for property,value in pairs(Settings[desc.Name].Properties) do
				Joint[property] = value
			end
		end
					
		if (Attachment0 and Attachment1) then
			Joint.Attachment0 = Attachment0
			Joint.Attachment1 = Attachment1
			Joint.Parent = desc.Parent
			Joint.Enabled = false
		end
	elseif (desc:IsA("Attachment")) then
		desc.Axis = Vector3.new(0, 1, 0)
		desc.SecondaryAxis = Vector3.new(0, 0, 1)
		desc.Rotation = Vector3.new(0, 0, 0)
	end
end	