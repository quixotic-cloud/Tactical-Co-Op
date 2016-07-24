//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_PlaceEvacZone extends X2Action
	config(GameCore);

var private const config float LookAtEvacZoneDuration; // in seconds

var private XComGameState_EvacZone EvacZoneState;
var private X2Camera_LookAtLocationTimed LookAtCamera;

var XComGameStateContext_Ability AbilityContext;
var XGUnit UnitWhoPlacedEvacFlare;


function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	EvacZoneState = XComGameState_EvacZone(InTrack.StateObject_NewState);

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	if (AbilityContext != None)
	{
		UnitWhoPlacedEvacFlare = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer());
	}
}

simulated state Executing
{
	function vector GetZoneLocation()
	{
		local XComWorldData WorldData;
		local vector ZoneLocation;
		
		WorldData = `XWORLD;
		if(!WorldData.GetFloorPositionForTile(EvacZoneState.CenterLocation, ZoneLocation))
		{
			ZoneLocation = WorldData.GetPositionFromTileCoordinates(EvacZoneState.CenterLocation);
		}

		return ZoneLocation;
	}

Begin:
	if( !bNewUnitSelected )
	{
		LookAtCamera = new class'X2Camera_LookAtLocationTimed';
		LookAtCamera.LookAtDuration = LookAtEvacZoneDuration;
		LookAtCamera.UseTether = false;
		LookAtCamera.LookAtLocation = GetZoneLocation();

		`CAMERASTACK.AddCamera(LookAtCamera);
		while( LookAtCamera != None && !LookAtCamera.HasArrived && LookAtCamera.IsLookAtValid() )
		{
			Sleep(0.0f);
		}
	}

	// syncing will create the evac zone
	PlayAKEvent(AkEvent'SoundTacticalUI.TacticalUI_DropZonePlacement');
	EvacZoneState.FindOrCreateVisualizer();
	EvacZoneState.SyncVisualizer();


	// MissionAbortRequest is the same as EVACRequest.  However, there are way more VO lines 
	// associated with EVACrequest, so we skew the selection accordingly.  mdomowicz 2015_07_27
	if (`SYNC_RAND(100)<10)
		UnitWhoPlacedEvacFlare.UnitSpeak('MissionAbortRequest');
	else
		UnitWhoPlacedEvacFlare.UnitSpeak('EVACrequest');


	while( LookAtCamera != None && !LookAtCamera.HasTimerExpired )
	{
		Sleep(0.0f);
	}

	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( LookAtCamera != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
		LookAtCamera = None;
	}
}

