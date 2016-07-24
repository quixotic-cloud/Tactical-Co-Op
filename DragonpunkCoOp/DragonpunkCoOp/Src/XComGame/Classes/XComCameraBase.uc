class XComCameraBase extends Camera
	native
	abstract;

var protectedwrite X2CameraStack CameraStack;

simulated function PostProcessInput()
{
}

// jboswell: This is the state the camera starts in when spawned, which happens in 4 ways:
// * When going from Strategy -> Tactical, 
//      * TransitioningToTactical: When the transition map (dropship) is loaded, a new camera is spawned in the old XComHeadquartersController
//      * BootstrappingTactical: When the Tactical map is brought up for play (before the battle/gameplay is ready to go)
// * When going from Tactical -> Strategy, 
//      * TransitioningToStrategy: When the transition map (dropship) is loaded, a new camera is spawned in the old XComTacticalController
//      * BootstrappingStrategy: When the Strategy map is brought up for play
auto simulated state Initing
{
Begin:
	if( WorldInfo.NetMode == NM_Client )
	{
		//If we are a client in an MP game, we may need to wait for the GRI to come down...
		while( WorldInfo.GRI == none )
		{
			Sleep(0.01);
		}
	}

	if (WorldInfo.GRI.IsA('XComTacticalGRI'))
	{
		if(WorldInfo.GetMapName() == `MAPS.GetTransitionMap())
			GotoState('TransitioningToTactical');
		else
			GotoState('BootstrappingTactical');
	}
	else
	{
		if(WorldInfo.GetMapName() == `MAPS.GetTransitionMap())
			GotoState('TransitioningToStrategy');
		else
			GotoState('BootstrappingStrategy');
	}
}

// This is a debug "free-look" mode, where the camera is flying around
simulated state DebugView
{
	simulated function DisplayDebugMsg()
	{		
	}
	simulated event BeginState(name PreviousStateName)
	{
		//SetTimer(1.2f,true);
	}

	simulated event EndState(name NextState)
	{
		if (`BATTLE != None && `BATTLE.IsCameraMoving( XComTacticalController(Owner) ) )
		{
			// MHU - Bugfix, ensure this is disabled whenever DebugView is enabled, otherwise
			//       could result in an input lock state.
			`BATTLE.CameraMoveComplete( XComTacticalController(Owner) );
		}
	}

	event Timer()
	{
		//DisplayDebugMsg();
	}

	simulated protected function UpdateCameraView( float DeltaTime, out TPOV out_POV )
	{
		out_POV = CameraCache.POV;
	}

	protected function UpdateWorldInfoDOF(float DeltaTime)
	{

	}

	function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
	{
		if( CameraStack != None )
		{
			CameraStack.UpdateCameras(DeltaTime); // update the cameras even while in debug mode so that they keep doing their thing and not holding up gameplay
		}

		OutVT.POV = CameraCache.POV;
	}

	simulated function PostProcessInput()
	{
		local XComTacticalController XCTC;
		local vector X, Y, Z;
		local float fMoveSpeedMultipier;
		local float fRotationUnitsPerSecond;

		XCTC = XComTacticalController(Owner);

		if(XCTC == none || !XCTC.bLockDebugCamera) {

			GetAxes(CameraCache.POV.Rotation,X,Y,Z);

			fRotationUnitsPerSecond = 250;

			// NOTE: anything from PlayerInput is a relative delta from the last frame

			fMoveSpeedMultipier = 1.0f;

			// if pressing SHIFT, speed us up (we're abusing bRun here to mean the opposite of what it normally does)
			if (PCOwner.bRun != 0)
				fMoveSpeedMultipier = 6.0f;

			fMoveSpeedMultipier += 6.0 * PCOwner.PlayerInput.aRightAnalogTrigger; // speedup up to 600%
			fMoveSpeedMultipier *= 1.0 - (0.8 * PCOwner.PlayerInput.aLeftAnalogTrigger); // slow up to 80%

			CameraCache.POV.Rotation.Yaw += (PCOwner.PlayerInput.aTurn * fRotationUnitsPerSecond);
			CameraCache.POV.Rotation.Pitch += (PCOwner.PlayerInput.aLookUp * fRotationUnitsPerSecond);

			CameraCache.POV.Location += (PCOwner.PlayerInput.aBaseY*X + PCOwner.PlayerInput.aStrafe*Y + PCOwner.PlayerInput.aUp*vect(0,0,0.1) ) * (fMoveSpeedMultipier * 0.005);
		}
		else {
			CameraCache.POV = XCTC.vDebugStaticPOV;
		}
	}

begin:
	DisplayDebugMsg();
}

//simulated event BeginState(name PreviousStateName)
//{
//	super.BeginState(PreviousStateName);

//	`log("XComCamera: entering" @ GetStateName() @ "from" @ PreviousStateName);
//}

simulated state InTransitionBetweenGames
{
	simulated event EndState(name NextStateName)
	{
		RestorePostProcessing();
	}

	simulated function DumpPostProcessState()
	{
		local LocalPlayer LP;
		local PostProcessChain PPChain;
		local int ChainIdx;

		LP = LocalPlayer(PCOwner.Player);
		if (LP != none)
		{
			for (ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
			{
				PPChain = LP.PlayerPostProcessChains[ChainIdx];

				PPChain.DumpEffectState();
			}
		}
	}

	simulated function DisablePostProcessing()
	{
		local LocalPlayer LP;
		local PostProcessChain PPChain;
		local int ChainIdx, EffectIdx;

		LP = LocalPlayer(PCOwner.Player);
		if (LP != none)
		{
			for (ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
			{
				PPChain = LP.PlayerPostProcessChains[ChainIdx];
				if (PPChain != none)
				{
					if (!PPChain.HasSavedEffectState())
						PPChain.SaveEffectState();

					for (EffectIdx = 0; EffectIdx < PPChain.Effects.Length; ++EffectIdx)
					{
						if (PPChain.Effects[EffectIdx] != none)
							PPChain.Effects[EffectIdx].bShowInGame = false;
					}
				}
			}
		}
	}

	simulated function RestorePostProcessing()
	{
		local LocalPlayer LP;
		local PostProcessChain PPChain;
		local int ChainIdx;

		// Restore the state of post processing
		LP = LocalPlayer(PCOwner.Player);
		if (LP != none)
		{
			for (ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
			{
				PPChain = LP.PlayerPostProcessChains[ChainIdx];
				if (PPChain.HasSavedEffectState())
					PPChain.RestoreEffectState();
			}
		}
	}

	simulated function EnablePostProcessEffect(name EffectName, bool bEnable)
	{
		XComPlayerController(PCOwner).Pres.EnablePostProcessEffect(EffectName, bEnable);
	}
}

// This state will happen when the camera has been spawned into the transition level
// when going from tactical -> strategy
simulated state TransitioningToStrategy extends InTransitionBetweenGames
{
	simulated function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
	{
		local bool bInitComplete;
		
		super.UpdateViewTarget(OutVT, DeltaTime);

		bInitComplete = WorldInfo.bContinueToSeamlessTravelDestination;

		// Disable FOW in the dropship until we are loaded
		// NOTE: This is not done in BeginState() because it needs to be done repeatedly
		// as the PPChain swaps a few times during loading/initing -- jboswell
		if (!bInitComplete)
		{
			EnablePostProcessEffect('XComFOWEffect', false); // Disable FOW
			EnablePostProcessEffect('ConcealmentMode', false); // Disable Concealment
		}
	}

Begin:
	EnablePostProcessEffect('XComFOWEffect', false);
}

simulated state TransitioningToTactical extends InTransitionBetweenGames
{
	simulated function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
	{
		super.UpdateViewTarget(OutVT, DeltaTime);

		EnablePostProcessEffect('Vignette', false);
		EnablePostProcessEffect('ComputerScreenBlur', false); // HQ Computer Screen blur
		EnablePostProcessEffect('XComFOWEffect', false); // Disable FOW
		EnablePostProcessEffect('ConcealmentMode', false); // Disable Concealment
	}
}

simulated state BootstrappingStrategy extends InTransitionBetweenGames
{
	simulated function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
	{
		super.UpdateViewTarget(OutVT, DeltaTime);

		// Disable PostProcessing except for black screen until after we are loaded
		// NOTE: This is not done in BeginState() because it needs to be done repeatedly
		// as the PPChain swaps a few times during loading/initing -- jboswell
		//DisablePostProcessing();
		//EnablePostProcessEffect('BlackScreen', true);
	}
Begin:
	PCOwner.ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
}

// This state will happen during the first few frames after a tactical level starts,
//  before the battle is initialized and the cinematic starts -- jboswell
simulated state BootstrappingTactical extends InTransitionBetweenGames
{
	simulated function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
	{
		local bool bInitComplete;
		
		super.UpdateViewTarget(OutVT, DeltaTime);

		if( WorldInfo.NetMode == NM_Client )
		{
			bInitComplete = `BATTLE.IsInitializationComplete();
		}
		//else
		//{
		//	bInitComplete = (`BATTLE != none && (`BATTLE.IsInState('LevelCinematicIntro') || `BATTLE.IsInState('Running')));
		//}

		// Disable PostProcessing except for black screen until after we are loaded
		// NOTE: This is not done in BeginState() because it needs to be done repeatedly
		// as the PPChain swaps a few times during loading/initing -- jboswell
		//DisablePostProcessing();
		
		if (bInitComplete)
		{
			StartTactical();
		}
	}

Begin:
	//Only fade the camera if the level is an actual tactical mission, and we seamless travelled here
	if (`XWORLD != none && `XWORLD.NumX > 0 && class'XComMapManager'.default.bUseSeamlessTravelToTactical)
	{
		`log("FADING CAMERA OUT");
		if(XComShellPresentationLayer(XComPlayerController(Owner).Pres) == none && !class'XComEngine'.static.IsAnyMoviePlaying())
		{
			class'Engine'.Static.GetAudioDevice().TransientMasterVolume = 0;
		}
			

		PCOwner.ClientSetCameraFade(true, MakeColor(0,0,0), vect2d(0,1), 0.0);
	}
}

function StartTactical()
{
	// This may be called multiple times, only bother to do something the first time	
	`log("XComCamera: StartTactical", , 'XComCameraMgr');

	if (IsInState('BootstrappingTactical'))
	{
		GotoState('');
		//GotoState('CursorView');
	}

	class'Engine'.Static.GetAudioDevice().TransientMasterVolume = 1.0f;
}

simulated state CinematicView
{
	simulated function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
	{
		local CameraActor	CamActor;

		if( CameraStack != None )
		{
			CameraStack.UpdateCameras(DeltaTime); // update the cameras even while in cinematic mode, as the cameras are independent of the view position
		}

		// Viewing through a camera actor.
		CamActor = CameraActor(OutVT.Target);
		if( CamActor != none)
		{
			CamActor.GetCameraView(DeltaTime, OutVT.POV);

			// Grab aspect ratio from the CameraActor.
			bConstrainAspectRatio	= bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
			OutVT.AspectRatio		= CamActor.AspectRatio;

			// See if the CameraActor wants to override the PostProcess settings used.
			// NOTE: bCamOverridePostProcess is deprecated, if you want to use it,
			// we'll need another way to determine this -- jboswell
			//if (CamActor.bCamOverridePostProcess)
			CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
			CamPostProcessSettings = CamActor.CamOverridePostProcess;
		}

		super.UpdateViewTarget( OutVT, DeltaTime );
	}

	simulated event BeginState( name PrevStateName )
	{
		local CameraActor CamActor;
		CamActor = CameraActor(ViewTarget.Target);
		if( CamActor != none )
		{
			//AimTime = 0;
			//AimStartPOV = CameraCache.POV;
			//CamActor.GetCameraView(0, AimEndPOV);
			//PushState('ViewTransition');  commented this out for now.  may implement toggle for cut/blend of cinematic mode -cdoyle
		}
	}

	simulated event EndState( name n )
	{
		ResetConstrainAspectRatio();
	}

	simulated event PoppedState()
	{
		super.PoppedState();
	}
}

defaultproperties
{

}
