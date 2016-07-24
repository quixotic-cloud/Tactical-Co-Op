/**
 * A directed tactical experience (DTE) is intended to control
 * the events of a tactical mission for tutorials and demos.
 * If an actor of type XComDirectedTacticalExperience is placed
 * in the world and enabled it will be activated when the map
 * is loaded and its PlaybackScript will guide how the level proceeds.
 * 
 * DTEs use Kismet is a novel way. They treat Kismet SubSequences like states. 
 * This can be used to break what would be a complex Kismet sequence into
 * a series of manageable pieces.  The DTE Actor will disable all DTE SubSequences
 * that are not the currently playing sequence. This allows event listeners to
 * be scoped. DTE SubSequences are SubSequences off of the game sequence that
 * have no input links. They should start with an event listener for the
 * SeqEvent_BeginSubSequence event and end with a SeqAct_EndSubSequence action.
 * 
 * DO NOT USE IN MULTIPLAYER
 */
class XComDirectedTacticalExperience extends Actor
	native(Level)
	placeable;

/** 
 * Determines if this DTE is enabled. Do not set from outside this
 * class when in game. Use EnableDTE() and DisableDTE() instead.
 */
var() bool bEnabled;

/////////////////////////////////////////////////////////////////////
// Playback Script Variables
/////////////////////////////////////////////////////////////////////

/**
 * Each element in this array represents the name of a sub sequence in
 * Kismet. These sequences will be played in order to direct the tactical
 * game. The sequences may be thought of as states in Kismet.
 */
var() array<string> PlaybackScript;

/** The index into the PlaybackScript of the current sequence */
var int CurrentSequence;

/////////////////////////////////////////////////////////////////////
// For the DTE attached to the TacticalGRI, there will be
// additional code that I didn't want to place everywhere
// throughout the game codebase.
/////////////////////////////////////////////////////////////////////

var private transient int       m_iInvalidClicks;
var private transient XGUnit    m_kClickedUnit;
var private transient int       m_iInvalidTurn;
var private transient Vector    m_vCameraLookAt;

var bool m_bAllowFiring;
var bool m_bAliensDealDamage;
var int m_iNextSequenceOverride;
var bool m_bLoadedFromSaveEnabled;

var array<int>                  m_arrButtonsBlocked;      

var private bool                m_bDisplayedOffscreenMessage;
var private transient float     m_fTickTime;
var private transient XGUnit    m_kPrevActiveUnit;

/////////////////////////////////////////////////////////////////////
// Enable / Disable
/////////////////////////////////////////////////////////////////////

// Note:
// A DTE may be enabled and disabled over the coarse of a tactical mission.
// Since each DTE represents a linear sequence of events, non-linear missions
// may be accomplished by disabling and enabling DTEs. This functionality is
// exposed to Kismet.
//
// See SeqAct_SetActiveDirectedExperience and SeqAct_DisableDirectedExperience
//

/** Enables this DTE and begins running the PlaybackScript */
function EnableDTE()
{
	if (!IsInState('Enabled'))
	{
		bEnabled = true;
		GotoState('Enabled');
	}
}

/** Disables this DTE and halts the PlaybackScript */
function DisableDTE()
{
	if (!IsInState('Disabled'))
	{
		bEnabled = false;
		GotoState('Disabled');
	}
}

event PostBeginPlay()
{
	if (bEnabled)
		InitialState = 'Enabled';
	else
		InitialState = 'Disabled';
}

/////////////////////////////////////////////////////////////////////
// Kismet Sequence Manipulation
/////////////////////////////////////////////////////////////////////

/**
 * Disables all DTE Sequences.
 * A DTE Sequence is defined as a sub sequence directly
 * under the game sequence which has no input links.
 */
native function DisableAllDTESequences();

/** Finds a sub sequence off of the main game sequence */
native function Sequence FindSubSequence(String SubSequenceName);

/** Activates a sub sequence off of the main game sequence and calls the begin sequence event */
native function ActivateSubSequence(String SubSequenceName);

/** Disables a sub sequence off of the main game sequence */
native function DeactivateSubSequence(String SubSequenceName);

/////////////////////////////////////////////////////////////////////
// Playback Script Handling
/////////////////////////////////////////////////////////////////////

/** Ends the current sequence and moves to the next one. */
function bool MoveToNextSequence()
{
	if (m_bLoadedFromSaveEnabled)
	{
		m_bLoadedFromSaveEnabled = false;
		return true;
	}

	if( CurrentSequence < PlaybackScript.Length )
	{
		if( CurrentSequence >= 0 )
		{
			DeactivateSubSequence(PlaybackScript[CurrentSequence]);
		}

		if( m_iNextSequenceOverride != -1 )
		{
			CurrentSequence = m_iNextSequenceOverride;
			m_iNextSequenceOverride = -1;
		}
		else
		{
			CurrentSequence++;
		}
	
		if (CurrentSequence >= PlaybackScript.Length)
		{
			// We've reached the end of this directed experience.
			// Disable and reset.
			DisableDTE();
			return false;
		}
		else
		{
			if (InStr(PlaybackScript[CurrentSequence], "AlienC", false, true) != INDEX_NONE)
			{
				`log("This is bad");
			}
			ActivateSubSequence(PlaybackScript[CurrentSequence]);
		}
		return true;
	}
	return false;
}

/** Ensures that this DTE is properly disabled */
private function OnDisabled()
{
	local XComTacticalGRI TacticalGRI;

	// Unregister this with the tactical GRI
	TacticalGRI = `TACTICALGRI;
	if (TacticalGRI != none && TacticalGRI.DirectedExperience == self)
		TacticalGRI.DirectedExperience = none;

	bEnabled = false;
	if( CurrentSequence >= 0 && CurrentSequence < PlaybackScript.Length )
	{
		DeactivateSubSequence(PlaybackScript[CurrentSequence]);
	}
}

state Enabled
{
	event BeginState(name PreviousStateName)
	{
		local XComTacticalGRI TacticalGRI;

		if( bEnabled )
		{
			// Register this with the tactical GRI
			TacticalGRI = `TACTICALGRI;
			if (TacticalGRI == none)
			{
				`log("ERROR: Tactical GRI not found",,'XComDTE');
				bEnabled = false;
				GotoState('Disabled');
			}
			else if (TacticalGRI.DirectedExperience != none && TacticalGRI.DirectedExperience != self)
			{
				`log("ERROR: Multiple DTEs Enabled!",,'XComDTE');
				bEnabled = false;
				GotoState('Disabled');
			}
			else
			{
				//bEnabled = true;
				TacticalGRI.DirectedExperience = self;
				if (CurrentSequence == -1)
					MoveToNextSequence();
			}
		}
	}

	event EndState(name NextStateName)
	{
		if( NextStateName == 'Disabled' )
		{
			OnDisabled();
		}
	}

	simulated function Tick( float fDeltaTime )
	{
		local vector2D vScreenLocation;
		local XGUnit kActiveUnit;
		local XGPlayer kActivePlayer;

		// If we already displayed the messages, do nothing.
		if( m_bDisplayedOffscreenMessage )
		{
			return;
		}

		if( !WorldInfo.IsConsoleBuild() )
		{
			kActivePlayer = XGBattle_SP(`BATTLE).GetHumanPlayer();
			kActiveUnit = kActivePlayer.GetActiveUnit();

			// Reset timer if selected unit changed
			if( kActiveUnit != m_kPrevActiveUnit )
			{
				m_kPrevActiveUnit = kActiveUnit;
				m_fTickTime = 0;
			}
			// Reset timer of we are in cinematic mode.
			else if( kActivePlayer.GetALocalPlayerController().bCinematicMode )
			{
				m_fTickTime = 0;
			}
			// Reset timer if we are playing a movie
			else if( `XENGINE.IsAnyMoviePlaying() )
			{
				m_fTickTime = 0;
			}
			// Reset timer if the current unit is onscreen.
			else if( kActiveUnit != none  && class'UIUtilities'.static.IsOnscreen( kActiveUnit.Location, vScreenLocation ) )
			{
				m_fTickTime = 0;
			}
		}
	}
}

state Disabled
{
	event BeginState(name PreviousStateName)
	{
		OnDisabled();
	}
}

state CameraLookAt
{
Begin:
	/*
     `CAMERAMGR.ClearKismetLookAts(true);
     while (`CAMERAMGR.WaitForCamera())
		Sleep(0);
	//`CAMERAMGR.AddLookAt(m_vCameraLookAt, `BATTLE.PRES().GetCamera().m_kLookAtView.GetZoom() * 0.4f);
	while (`CAMERAMGR.WaitForCamera())
		Sleep(0);
	// Keep it here for 1 second
	Sleep(2.0f);
	`CAMERAMGR.RemoveLookAt(m_vCameraLookAt);
	while (`CAMERAMGR.WaitForCamera())
		Sleep(0);
	*/
	PopState();
}

/////////////////////////////////////////////////////////////////////
// For the enabled DTE, there are some additional functions that
// are needed for the full experience that I didn't want all over
// the code.  - DMW
/////////////////////////////////////////////////////////////////////

public function InvalidMovement( XGUnit ActiveUnit )
{
}

public function SetFiringIsAllowed( bool bAllowed )
{
	m_bAllowFiring = bAllowed;
}

public function SetAliensDealDamage( bool damage )
{
	m_bAliensDealDamage = damage;
}

/////////////////////////////////////////////////////////////////////
// Default Properties
/////////////////////////////////////////////////////////////////////

simulated function BlockButton( int cmd )
{
	if( m_arrButtonsBlocked.Find(cmd) == -1 )
	{
		m_arrButtonsBlocked.AddItem(cmd);
	}
}

simulated function Unblockbutton( int cmd )
{
	m_arrButtonsBlocked.RemoveItem(cmd);
}

simulated function UnblockAllButtons()
{
	m_arrButtonsBlocked.Length = 0;
}

simulated function bool ButtonIsBlocked( int cmd )
{
	return( m_arrButtonsBlocked.Find(cmd) != -1 );
}

simulated function bool ShowShotHUD()
{
	return( !ButtonIsBlocked( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER ) );
}

simulated function bool AllowSwapWeapons()
{
	return( !ButtonIsBlocked( class'UIUtilities_Input'.const.FXS_BUTTON_X ) );
}

simulated function bool AllowCameraSpin()
{
	return( !ButtonIsBlocked( class'UIUtilities_Input'.const.FXS_DPAD_LEFT ) );
}

simulated function bool AllowElevationChange()
{
	return( !ButtonIsBlocked( class'UIUtilities_Input'.const.FXS_DPAD_UP ) );
}

simulated function bool AllowOverwatch()
{
	return( !ButtonIsBlocked( class'UIUtilities_Input'.const.FXS_BUTTON_Y ) );
}

/////////////////////////////////////////////////////////////////////
// Default Properties
/////////////////////////////////////////////////////////////////////

DefaultProperties
{
	bEnabled=true
	CurrentSequence=-1

	m_iInvalidClicks = 0
	m_iInvalidTurn = 0
	m_kClickedUnit = none
	m_iNextSequenceOverride = -1

	m_bAllowFiring = true;
	m_bAliensDealDamage = true;
	m_bDisplayedOffscreenMessage = false;
}
