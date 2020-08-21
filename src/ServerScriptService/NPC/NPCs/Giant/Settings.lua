local Settings = {	
	
	UpdateDelay = 0.1,	
	JumpDelay = 1,
	DespawnDelay = 3,
	
	DetectionDist = 50,
	PovX = 0.4,
	PovY = 5,
	TimeoutDist = 20,
	LineOfSightDist = 40,
	TargetLineOfSightDist = 10,
	PovIgnore = {},
	
	SpacingDist = 3,
	WalkSpeed = 8,
	AttemptSpacingDuration = 5,
	
	MinDamage = 60,
	MaxDamage = 80,
	AttackDelay = 3,
	AttackDist = 3,
	
	CollisionGroupId = 1,
	
	Throwing = {
		xVelocity = 100,
		yVelocity = 50,
		InAirDur = 0.3,
		
		Chance = 1, -- 1 to n chance of throwing			
		CarriedCollisionGroupId = 2,
		PosOffset = CFrame.new(0, -0.7, 1),
		RotOffset = CFrame.fromEulerAnglesXYZ(math.rad(90), 0, math.rad(180))		
	},
	
	Humanoid = {
		["Health"] = 300,
		["WalkSpeed"] = 8,
		["HipHeight"] = 2.8
	},
	
	HealthBar = {
		Red = Color3.fromRGB(255, 0, 0),
		Yellow = Color3.fromRGB(255, 255, 0),
		Green = Color3.fromRGB(0, 255, 0)
	},
	
	JointConfiguration = {		
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
	
}

return Settings
