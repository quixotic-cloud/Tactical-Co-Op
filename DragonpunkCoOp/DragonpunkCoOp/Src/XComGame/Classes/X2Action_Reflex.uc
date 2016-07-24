class X2Action_Reflex extends X2Action;

var localized string FlyoverText;
var string PostProcessName;

//FOW reveal properties
var float RevealFOWRadius;  //A radius in units for how much FOW should be revealed
var Actor FOWViewer;        //The world data uses 'viewers' to show / hide FOW. This actor tracks the temp viewer

var private X2Camera_ReflexActionReveal ReflexCam;

function bool CheckInterrupted()
{
	return false;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	`assert(false);
}

simulated state Executing
{
	function UpdateUnitVisuals()
	{		
		local XComGameState_Unit UnitState;		
		local XGUnit Visualizer;

		//Iterate all the unit states that are part of the reflex action state. If they are not the
		//reflexing unit, they are enemy units that must be shown to the player. These vis states will
		//be cleaned up / reset by the visibility observer in subsequent frames
		foreach StateChangeContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			Visualizer = XGUnit(UnitState.GetVisualizer());

			if( UnitState.ObjectID != Unit.ObjectID )
			{
				Visualizer.SetVisibleToTeams(eTeam_All);
			}

			Visualizer.IdleStateMachine.CheckForStanceUpdateOnIdle();
		}
	}

	function RequestReflexCamera()
	{			
		ReflexCam = new class'X2Camera_ReflexActionReveal';
		ReflexCam.ReflexActionToShow = self;
		`CAMERASTACK.AddCamera(ReflexCam);
	}

	function RequestReturnToUnitCamera()
	{	
		local X2Camera_LookAtActorTimed LookAtCam;

		LookAtCam = new class'X2Camera_LookAtActorTimed';
		LookAtCam.ActorToFollow = Unit;
		LookAtCam.LookAtDuration = 0; // pop as soon as we arrive at the unit
		`CAMERASTACK.AddCamera(LookAtCam);
	}


	function HideFOW()
	{
		local XGUnit LookAtUnit;		
		local vector RevealLocation;

		LookAtUnit = Unit;
		if( LookAtUnit != none )
		{	
			RevealLocation = LookAtUnit.Location;
			RevealLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;
			FOWViewer = `XWORLD.CreateFOWViewer(RevealLocation, RevealFOWRadius);
		}
	}

	function RestoreFOW()
	{
		if( FOWViewer != None )
		{
			`XWORLD.DestroyFOWViewer(FOWViewer);
		}
	}

Begin:

	Unit.UnitSpeak('TargetSpotted');

	Unit.SetTimeDilation(1.0f);

	UpdateUnitVisuals();
	
	HideFOW();

	EnablePostProcessEffect(name(PostProcessName), true);

	`PRES.UIShowReflexOverlay();

	RequestReflexCamera();

	while(!ReflexCam.HasTimerExpired)
	{
		Sleep(0.0);
	}

	RequestReturnToUnitCamera();

	`PRES.GetWorldMessenger().Message(default.FlyoverText, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Good, , , Unit.m_eTeamVisibilityFlags, , , , class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');

	RestoreFOW();

	CompleteAction();
}

DefaultProperties
{	
	PostProcessName = "ReflexAction"
	RevealFOWRadius = 384.0; //4 tiles
	bCauseTimeDilationWhenInterrupting = true
}
