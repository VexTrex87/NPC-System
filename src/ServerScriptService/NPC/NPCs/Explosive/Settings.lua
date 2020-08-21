local Settings = {	
	
	UpdateDelay = 0.1,	
	JumpDelay = 1,
	DespawnDelay = 3,
	
	DetectionDist = 50,
	PovX = 0.4,
	PovY = 5,
	TimeoutDist = 20,
	LineOfSightDist = 40,
	PovIgnore = {},
	
	SpacingDist = 3,
	WalkSpeed = 8,
	AttemptSpacingDuration = 5,
	
	AttackDist = 15,
	
	Humanoid = {
		["WalkSpeed"] = 12
	},
	
	ExplosionInfo = {
		ExplosionModel = game.ServerStorage.Effects.Explosion,				
		Parent = workspace.Debris,
		Position = Vector3.new(0, 0, 0),
		ShakeDist = 20,
		Size = 200,	
		Duration = 1,
		FadeDuration = 0.8,
		DespawnDelay = 0.5,
		
		MaxDamage = 200,	
		BlastRadius = 15,	
		DestroyJointRadiusPercent = 0,
		BlastPressure = 500000,
		ExplosionType = Enum.ExplosionType.NoCraters,
		
		NewExplosion = nil,	
		NPC = nil,			
		
		ExplodeTweenInfo = {
			EasingStyle = Enum.EasingStyle.Exponential,
			EasingDirection = Enum.EasingDirection.Out,
		},
		
		FadeTweenInfo = {
			EasingStyle = Enum.EasingStyle.Exponential,
			EasingDirection = Enum.EasingDirection.In,
		}		
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
