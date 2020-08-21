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
	
	MinDamage = 10,
	MaxDamage = 15,
	AttackDelay = 2,
	
	Humanoid = {
		["WalkSpeed"] = 12
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
