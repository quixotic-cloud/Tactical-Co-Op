//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_PlayWorldNarrative extends X2Action;

var private X2WorldNarrativeActor WorldNarrativeActor;
var XGUnit SpeakingUnit;

var private bool WaitingForCompletion;
var private X2Camera_LookAtActor LookAtCamera;

simulated private function OnFinishedNarrative();

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_WorldNarrativeActor WorldNarrativeActorState;
	local XComGameState_Unit SpeakingUnitState;

	super.Init(InTrack);

	WorldNarrativeActor = X2WorldNarrativeActor(InTrack.StateObject_NewState.GetVisualizer());

	WorldNarrativeActorState = XComGameState_WorldNarrativeActor(InTrack.StateObject_NewState);
	SpeakingUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(WorldNarrativeActorState.UnitThatSawMeRef.ObjectID));
	SpeakingUnit = XGUnit(SpeakingUnitState.GetVisualizer());
}

event bool BlocksAbilityActivation()
{
	return false;
}

event HandleNewUnitSelection()
{
	if( LookAtCamera != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
		LookAtCamera = None;
	}
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated private function OnFinishedNarrative()
	{
		WaitingForCompletion = false;
	}

Begin:
	if( !ShouldPlayZipMode() )
	{
		if( !bNewUnitSelected )
		{
			LookAtCamera = new class'X2Camera_LookAtActor';
			LookAtCamera.ActorToFollow = WorldNarrativeActor;
			LookAtCamera.UseTether = false;
			`CAMERASTACK.AddCamera(LookAtCamera);

			while( LookAtCamera != None && !LookAtCamera.HasArrived && LookAtCamera.IsLookAtValid() )
			{
				Sleep(0.1f);
			}
		}

		if( WorldNarrativeActor.NarrativeMoment.eType == eNarrMoment_VoiceOnlySoldierVO )
		{
			if( SpeakingUnit != none )
				SpeakingUnit.UnitSpeak(WorldNarrativeActor.NarrativeMoment.SoldierVO);
		}
		else
		{
			if( WorldNarrativeActor.NarrativeMoment != none )
			{
				`PRES().UINarrative(WorldNarrativeActor.NarrativeMoment, , OnFinishedNarrative);

				WaitingForCompletion = true;
				while( WaitingForCompletion )
				{
					Sleep(0.1);
				}
			}
			else
			{
				`RedScreen("X2Action_PlayWorldNarrative - NarrativeMoment is none:" @ WorldNarrativeActor);
			}
		}
	}

	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();

	// remove this here so that we are guaranteed to remove it, even if the action times out
	if( LookAtCamera != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
		LookAtCamera = None;
	}
}

defaultproperties
{
	TimeoutSeconds=30
}

