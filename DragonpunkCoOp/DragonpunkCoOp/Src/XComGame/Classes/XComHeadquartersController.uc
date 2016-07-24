//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHeadquartersController extends XComPlayerController
	native(Core);

var bool                                m_bAffectsHUD;
var bool                                m_bInCinematicMode;

/* SetPause()
 Try to pause game; returns success indicator.
 Replicated to server in network games.
 */
function bool SetPause( bool bPause, optional delegate<CanUnpause> CanUnpauseDelegate=CanUnpause, optional bool bFromLossOfFocus)
{
	local bool bResult;
	
	bResult = super.SetPause(bPause, CanUnpauseDelegate, bFromLossOfFocus);

	if( XComHQPresentationLayer(Pres).Get3DMovie() != none )
	{
		XComHQPresentationLayer(Pres).Get3DMovie().SetPause(bPause);
	}

	return bResult;
}

function SetCinematicMode( bool bInCinematicMode, bool bHidePlayer, bool bAffectsHUD, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsButtons, optional bool bDoClientRPC = true, optional bool bOverrideUserMusic = false )
{
	super.SetCinematicMode( bInCinematicMode, bHidePlayer, bAffectsHUD, bAffectsMovement, bAffectsTurning, bAffectsButtons, bDoClientRPC, bOverrideUserMusic );

	CinematicModeToggled(bInCinematicMode, bAffectsMovement, bAffectsTurning, bAffectsHUD);
}

simulated function CinematicModeToggled(bool bInCinematicMode, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsHUD)
{
	m_bInCinematicMode = bInCinematicMode;
	m_bAffectsHUD = bAffectsHUD;

	if (bInCinematicMode)
	{
		if( PlayerCamera != none )
			PlayerCamera.ClearAllCameraShakes();

		if (bAffectsHUD)
		{
			Pres.HideUIForCinematics();
			
			//ConsoleCommand( "SetPPVignette "@string(!bInCinematicMode));
		}
		if( PlayerCamera != none )
			PlayerCamera.PushState('CinematicView');

		PushState( 'CinematicMode' );
	}
	else
	{
		if (bAffectsHUD)
		{
			Pres.ShowUIForCinematics();
			//ConsoleCommand( "SetPPVignette "@string(!bInCinematicMode));
		}

		if( PlayerCamera != none && PlayerCamera.IsInState('CinematicView',true) )
		{
			while( PlayerCamera.IsInState('CinematicView', true) )
				PlayerCamera.PopState();

			XComBaseCamera(PlayerCamera).bHasOldCameraState = false; //Force an instant transition
			PlayerCamera.ResetConstrainAspectRatio();
		}

		PopState();
	}
}

simulated function SetInputState( name nStateName )
{
	XComHeadquartersInput( PlayerInput ).GotoState( nStateName );
}

state CinematicMode
{
	event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);
	}
/*
	// don't show menu in cenematic mode - the button skips the cinematic
	exec function ShowMenu();

	// dont playe selection sound
	exec function PlayUnitSelectSound();*/
}

/** Start as PhysicsSpectator by default */
auto state PlayerWaiting
{

Begin:
	PlayerReplicationInfo.bOnlySpectator = false;
	WorldInfo.Game.bRestartLevel = false;
	WorldInfo.Game.RestartPlayer( Self );
	WorldInfo.Game.bRestartLevel = true;
	SetCameraMode('ThirdPerson');
}

state MissionControl
{
ignores SeePlayer, HearNoise, Bump;

	event BeginState( name p )
	{
		//XComHeadquartersCamera(PlayerCamera).StartMissionControlView();
		Pawn.SetPhysics(PHYS_None);
		//XComHQPresentationLayer(Pres).UIShowMissionControlMenu();
	}

	function PlayerMove(float DeltaTime)
	{
		if( XComHQPresentationLayer(Pres) == none || 
			XComHQPresentationLayer(Pres).CAMIsBusy() )
			return;

		// Update rotation.
		UpdateRotation( DeltaTime );

		if (Pawn != none)
		{
			if ( Role < ROLE_Authority ) // then save this move and replicate it
				ReplicateMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
			else
				ProcessMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		}
	}
}

state StrategyShell
{
ignores SeePlayer, HearNoise, Bump;

	event BeginState( name p )
	{
		XComHeadquartersCamera(PlayerCamera).StartStrategyShellView();
		Pawn.SetPhysics(PHYS_None);
	}

	function PlayerMove(float DeltaTime)
	{
	}
}

state Headquarters
{
ignores SeePlayer, HearNoise, Bump;

	event BeginState( name p )
	{
		XComHeadquartersCamera(PlayerCamera).StartHeadquartersView();
		Pawn.SetPhysics(PHYS_Flying);
	}

	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		Pawn.Acceleration = PlayerInput.aLookUp*(X*vect(1,1,0)) + PlayerInput.aTurn*(Y*vect(1,1,0));
		Pawn.Acceleration = Pawn.AccelRate * Normal(Pawn.Acceleration);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
	}
}



/**
 * Looks at the current game state and uses that to set the
 * rich presence strings
 *
 * Licensees (that's us!) should override this in their player controller derived class
 */
reliable client function ClientSetOnlineStatus()
{
	`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_InGameSP);
}

simulated function bool IsInCinematicMode()
{
	return m_bInCinematicMode;
}
simulated function bool ShouldBlockPauseMenu()
{
	return m_bInCinematicMode && m_bAffectsHUD;
}
simulated function bool IsStartingGame()
{
	return `GAME.IsInState('StartingGame');
}

defaultproperties
{
	CameraClass=class'XComHeadquartersCamera'
	InputClass=class'XComHeadquartersInput'
	CheatClass=class'XComHeadquartersCheatManager'
	PresentationLayerClass=class'XComHQPresentationLayer'
}
