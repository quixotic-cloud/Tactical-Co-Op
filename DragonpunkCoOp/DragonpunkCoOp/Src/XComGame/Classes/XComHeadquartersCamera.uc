//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHeadquartersCamera extends XComBaseCamera
	config(Camera);

// current ViewDistance multiplier
var transient float						CurrentZoom;

var name RoomTransitioningToFromEarthView;

var rotator m_kEarthViewRotation;

var bool bHasFocusQueued;
var Vector2D QueuedEarthFocusLoc;   // When we transition to Earth view, we'll look at this location if its been Queued
var float fQueuedInterpTime;

var privatewrite name PreviousRoom;
var private name QueuedBaseRoom;
var private float fQueuedBaseRoomInterpTime;

var name CurrentRoom;
var float fEarthTransitionInterp;

var bool bTransitionFromSideViewToEarthView;

const FREECAM_MIN_X = -2300; // right
const FREECAM_MAX_X = 600; // left
const FREECAM_MAX_Z = 1400; // up
const FREECAM_MIN_Z = 800; // down

delegate EnteringRoomView();
delegate EnteringGeoscapeView();
delegate EnteringFacilityView();

function InitializeFor(PlayerController PC)
{
	super.InitializeFor( PC );

	CurrentZoom = 1.0f;
}

function bool IsMoving()
{
	return AnimTime < TotalAnimTime;
}

function SetZoom( float Amount )
{
	Amount = FMax( Amount, 0.01f );
	CurrentZoom = Amount;
}

function ResetZoom()
{
	CurrentZoom = 1.0f;
}

protected function OnCameraInterpolationComplete()
{
	super.OnCameraInterpolationComplete();

	if (IsInState('EarthView'))
	{
		LastCameraStateOrientation.Focus = `EARTH.GetWorldViewLocation();
		OldCameraStateOrientation.Focus = LastCameraStateOrientation.Focus;
	}
	else if (IsInState('BaseViewTransition'))
	{
		StartRoomView(QueuedBaseRoom, fQueuedBaseRoomInterpTime);
	}

	PreviousRoom = QueuedBaseRoom;
	fQueuedBaseRoomInterpTime = 0;
	QueuedBaseRoom = '';
}


protected function GetCameraStateView( XComCameraState CamState, float DeltaTime, out CameraStateOrientation NewOrientation )
{
	// start with an fov of 90, the views can override if they want to
	NewOrientation.FOV = 90.0f;

	super.GetCameraStateView( CamState, DeltaTime, NewOrientation );

	NewOrientation.ViewDistance *= CurrentZoom;
}

function GetViewDistance( out float ViewDistance )
{
	local CameraStateOrientation NewOrientation;
	GetCameraStateView( CameraState, 0.0f, NewOrientation );

	NewOrientation.ViewDistance *= CurrentZoom;
	ViewDistance = NewOrientation.ViewDistance;
}

function SetRelativeViewDistance( float fRelativeDist )
{
	local CameraStateOrientation NewOrientation;

	GetCameraStateView( CameraState, 0.0, NewOrientation );
	NewOrientation.ViewDistance += fRelativeDist;
	
	XComCamState_HQ_FreeMovement(CameraState).SetViewDistance( NewOrientation.ViewDistance );
}

function SetViewDistance( float fDist )
{
	local CameraStateOrientation NewOrientation;

	GetCameraStateView( CameraState, 0.0, NewOrientation );
	NewOrientation.ViewDistance = fDist;
	
	XComCamState_HQ_FreeMovement(CameraState).SetViewDistance( NewOrientation.ViewDistance );

	LookRelative(vect(0, 0, 0), CurrentZoom);
}
function StartStrategyShellView()
{
	XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',0.0f)).InitRoomView( PCOwner, 'Shell' );
	TriggerKismetEvent('Shell');
	GotoState( 'BaseView' );
}


function StartHeadquartersView()
{
	XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',0.0f)).InitRoomView( PCOwner, 'Base' );
	TriggerKismetEvent('Base');
}

function StartRoomView( name RoomName, float InterpTime )
{
	local CameraStateOrientation CurrentOrientation;
	local CameraActor cameraActor;

	if (IsInState('EarthView') || IsInState('EarthViewFocusingOnLocation'))
	{
		/*RoomTransitioningToFromEarthView = RoomName;
		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, 'MissionControl' );
		TriggerKismetEvent(RoomName);
		if (InterpTime > 0)
			fEarthTransitionInterp = 1.0f;
		else fEarthTransitionInterp = 0;
		GotoState('EarthViewReverseTransition');*/

		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
				
		`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true); // Refresh Avenger visibility states when leaving the Geoscape

		TriggerKismetEvent(RoomName);
		GotoState( 'BaseRoomView' );
	}
	else if (RoomName == 'MissionControl')
	{
		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
		TriggerKismetEvent(RoomName);
		if (InterpTime > 0)
			fEarthTransitionInterp = 1.0f;
		else fEarthTransitionInterp = 0;		
	}
	else if(RoomName == 'FreeMovement')
	{
		//Only switch to free movement if we are not in a cinematic view at the moment ( cinematic mode should be toggled off first, and the matinees stopped )
		if( XComCamState_HQ_FreeMovement(CameraState) == none && !IsInState('CinematicView'))
		{
			//Grab the current view...
			GetCameraStateView( CameraState, 0.0, CurrentOrientation );
			ResetZoom();

			//...and init the free movement at the current view's focus . 
			XComCamState_HQ_FreeMovement(SetCameraState(class'XComCamState_HQ_FreeMovement',0.0f)).Init( PCOwner, CurrentOrientation.Focus, CurrentOrientation.ViewDistance );
			//TriggerKismetEvent('FreeMovement'); //TODO: will we need this? 
			GotoState( 'FreeMovementView' );
		}
	}
	else if(RoomName == 'Expansion')
	{
		if( WorldInfo.IsConsoleBuild() )
		{
			foreach AllActors(class'CameraActor', cameraActor)
			{
				if( cameraActor.Tag == 'Expansion')
				{
					cameraActor.SetLocation(vect(3290, 3000, -2500));
				}
			}
		}

		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
		TriggerKismetEvent(RoomName);
		GotoState( 'BaseRoomView' );
	}
	else
	{

		XComCamState_HQ_BaseRoomView(SetCameraState(class'XComCamState_HQ_BaseRoomView',InterpTime)).InitRoomView( PCOwner, RoomName );
		TriggerKismetEvent(RoomName);
		GotoState( 'BaseRoomView' );

		// if going to ant farm view or...
		// if going into the armory and not in squad select sequence then we still want ambient musings to trigger
		if (RoomName == 'Base' ||
		   (RoomName == 'UIDisplayCam_Armory' && !`SCREENSTACK.HasInstanceOf(class'UISquadSelect')))
		{
			if (EnteringRoomView != none)
			{
				EnteringRoomView();
			}
		}
		else
		{
			// going into a specific room
			if (EnteringFacilityView != none)
			{
				EnteringFacilityView();
			}
		}
	}
}

function StartRoomViewNamed( name RoomName, float fInterpTime, optional bool bSkipBaseViewTransition )
{
	local XComCamState_HQ_BaseRoomView RoomView;
	RoomView = XComCamState_HQ_BaseRoomView(CameraState);

	if(fInterpTime > 0)
	{
		// No need to interpolate to the same room - prevents camera jerking
		if(RoomName == PreviousRoom)
		{
			return;
		}

		if (!bSkipBaseViewTransition && RoomView != none && RoomView.CamName == 'Base' && AnimTime < TotalAnimTime)
		{
			QueuedBaseRoom = RoomName;
			fQueuedBaseRoomInterpTime = fInterpTime;
			GotoState('BaseViewTransition');
			return;
		}
	}
	else
	{
		// if we get an instant camera change then drop any queued change
		QueuedBaseRoom = '';
		fQueuedBaseRoomInterpTime = 0;
	}

	if(RoomName == 'MissionControl')
	{
		RoomName = 'Base';
	}

	if(RoomName == 'Base' && fInterpTime > 0)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("AntFarm_Camera_Zoom_Out");
	}

	// cache the previous room to prevent animation reset to the same camera location
	PreviousRoom = RoomName;

	StartRoomView( RoomName, fInterpTime );
}

function TriggerKismetEvent(name RoomName)
{
	local int i;
	local SeqEvent_OnStrategyRoomEntered RoomEnteredEvent;
	local SeqEvent_OnStrategyRoomExited RoomExitedEvent;
	local array<SequenceObject> Events;

	if( WorldInfo.GetGameSequence() != None )
	{
		WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_OnStrategyRoomExited', TRUE, Events);
		for (i = 0; i < Events.Length; i++)
		{
			RoomExitedEvent = SeqEvent_OnStrategyRoomExited(Events[i]);
			if( RoomExitedEvent != None )
			{
				RoomExitedEvent.RoomName = CurrentRoom;

				RoomExitedEvent.CheckActivate(WorldInfo, None);
			}
		}

		CurrentRoom = RoomName; // This will be the next room to be left

		WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_OnStrategyRoomEntered', TRUE, Events);
		for (i = 0; i < Events.Length; i++)
		{
			RoomEnteredEvent = SeqEvent_OnStrategyRoomEntered(Events[i]);
			if( RoomEnteredEvent != None )
			{
				RoomEnteredEvent.RoomName = RoomName;

				RoomEnteredEvent.CheckActivate(WorldInfo, None);
			}
		}
	}
}

function FocusOnFacility(name RoomName)
{
	local vector FacilityLocation;
	local XComHQ_RoomLocation RoomLoc;

	foreach AllActors(class'XComHQ_RoomLocation', RoomLoc)
	{
		if (RoomLoc.RoomName == RoomName)
		{
			FacilityLocation = RoomLoc.Location;
			break;
		}
	}

	StartRoomView('FreeMovement', 2.0);
	XComCamState_HQ_FreeMovement(CameraState).SetTargetFocus(FacilityLocation);
	//SetZoom(0.3f);
}

state BaseView
{
}

state BaseViewTransition
{
}

state BaseRoomView
{
	event BeginState(Name PreviousStateName)
	{
		if (CurrentRoom == 'Base' && PreviousStateName == 'EarthView')
		{
			`AUTOSAVEMGR.DoAutosave();
		}
	}

	event EndState(Name NextStateName)
	{
		if (CurrentRoom == 'UIDisplayCam_CIC' && NextStateName == 'EarthView')
		{
			if (EnteringGeoscapeView != none)
			{
				EnteringGeoscapeView();
			}

			if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M3_WelcomeToHQ') != eObjectiveState_InProgress)
			{
				`AUTOSAVEMGR.DoAutosave();
			}
		}
	}
}


function LookRelative( Vector vRelativeLoc, optional float fZoomPercent = 1.0f ); 
state FreeMovementView
{	
	event BeginState(Name PreviousStateName)
	{
		if (CurrentRoom == 'Base')
		{
			if (EnteringRoomView != none)
			{
				EnteringRoomView();
			}
		}
	}

	function LookRelative( Vector vRelativeLoc, optional float fZoomPercent = 1.0f )
	{
		local CameraStateOrientation CurrentOrientation, NewOrientation;
		local bool bFreeCam;
		local float fViewDistScalar;

		GetCameraStateView( CameraState, 0.0, CurrentOrientation );
		NewOrientation = CurrentOrientation;
		NewOrientation.Focus.X += vRelativeLoc.X;
		NewOrientation.Focus.Y += vRelativeLoc.Y;
		NewOrientation.Focus.Z += vRelativeLoc.Z; 


		bFreeCam = false;
		if (XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager) != none) 
			bFreeCam = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager).bFreeCam;

		fViewDistScalar = GetViewDistanceScalar();

		if (!bFreeCam)
		{
			if (NewOrientation.Focus.X > GetFreeCamMax_X(fViewDistScalar))
				NewOrientation.Focus.X = GetFreeCamMax_X(fViewDistScalar);
			else if (NewOrientation.Focus.X < GetFreeCamMin_X(fViewDistScalar))
				NewOrientation.Focus.X = GetFreeCamMin_X(fViewDistScalar);
			if (NewOrientation.Focus.Z > GetFreeCamMax_Z(fViewDistScalar))
				NewOrientation.Focus.Z = GetFreeCamMax_Z(fViewDistScalar);
			else if (NewOrientation.Focus.Z < GetFreeCamMin_Z(fViewDistScalar))
				NewOrientation.Focus.Z = GetFreeCamMin_Z(fViewDistScalar);
		}
		
		SetZoom( fZoomPercent );
		XComCamState_HQ_FreeMovement(CameraState).LookAt( NewOrientation.Focus );
		`Log("HQ cam look at " $ NewOrientation.Focus,,'XComCameramgr');
	}
}

function ForceEarthViewImmediately(bool TransitionFromSideView)
{
	bTransitionFromSideViewToEarthView = TransitionFromSideView;
	GotoState('EarthView');
}

function NewEarthView(float fInterpTime)
{
	XComCamState_Earth(SetCameraState(class'XComCamState_Earth', fInterpTime)).Init(PCOwner, self);
}

state EarthView
{
	event BeginState(Name PreviousStateName)
	{
		NewEarthView(0);

		if (EnteringGeoscapeView != none)
		{
			EnteringGeoscapeView();
		}

		XComInputBase(PCOwner.PlayerInput).m_bSteamControllerInGeoscapeView = true;
	}

	event EndState(Name NextStateName)
	{
		XComInputBase(PCOwner.PlayerInput).m_bSteamControllerInGeoscapeView = false;
	}


Begin:
	if( bTransitionFromSideViewToEarthView )
	{
		bTransitionFromSideViewToEarthView = false;

		// Wait for the geoscape to become fully visible
		while( !`MAPS.IsStreamingComplete() )
		{
			Sleep(0.1f);
		}

		// kick off the post-geoscape-fully-loaded events
		`XCOMGRI.DoRemoteEvent('CIN_PostGeoscapeLoaded');
	}
}



simulated state BootstrappingStrategy
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		StartRoomView('MissionControl', 0.0f);
		StartRoomView('FreeMovement', 0.5f);
	}
}

function float GetViewDistanceScalar()
{
	local float fViewDist;

	`HQPRES.GetCamera().GetViewDistance(fViewDist);

	return 1.0f - fViewDist / (class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - class'XComCamState_HQ_BaseView'.default.m_fPCDefaultMinViewDistance);
}

function float GetFreeCamMax_X(float fViewDistScalar)
{
	return FREECAM_MAX_X + (FREECAM_MAX_X - FREECAM_MIN_X)*fViewDistScalar;
}

function float GetFreeCamMin_X(float fViewDistScalar)
{
	return FREECAM_MIN_X - (FREECAM_MAX_X - FREECAM_MIN_X)*fViewDistScalar;
}

function float GetFreeCamMax_Z(float fViewDistScalar)
{
	return FREECAM_MAX_Z + (FREECAM_MAX_Z - FREECAM_MIN_Z)*fViewDistScalar;
}

function float GetFreeCamMin_Z(float fViewDistScalar)
{
	return FREECAM_MIN_Z - (FREECAM_MAX_Z - FREECAM_MIN_Z)*fViewDistScalar;
}

DefaultProperties
{
	DefaultFOV=30.0f
	CurrentRoom=none
}
