class SeqAct_XComCameraLookAt extends SequenceAction
	implements(X2KismetSeqOpVisualizer)
	native;

var() Actor TargetActor;
var XComGameState_Unit TargetUnit;
var XComGameState_InteractiveObject TargetInteractiveObject;
var vector TargetLocation;
var() float LookAtDuration;
var() bool UseTether;
var() bool SnapToFloor;

// Stores the camera action used by this SeqAct.
var X2Action_CameraLookAt CameraAction;

cpptext
{
#if WITH_EDITOR
	virtual FString GetDisplayTitle() const;
#endif
}

event Activated()
{
	// Check to make sure if this action is being called again, we have removed the previous camera from the stack. Otherwise it will be lost.
	if (LookAtDuration < 0.0 && CameraAction != none)
	{
		`RedScreen("SeqAct_XComCameraLookAt action is being called with an indefinite duration for a second time without the first camera being stopped. ");
	}

	CameraAction = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2Action_CameraLookAt');
}

function ModifyKismetGameState(out XComGameState GameState)
{
	// always fence this. The camera lookat action will immediately return and unblock if
	// not block is requested
	GameState.GetContext().SetVisualizationFence(true, LookAtDuration + 10);
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;

	History = `XComHistory;
	foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	if(CameraAction == none)
	{
		CameraAction = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2Action_CameraLookAt');
	}

	BuildTrack.TrackActor = `BATTLE;

	class'X2Action_CameraLookAt'.static.AddActionToVisualizationTrack(CameraAction, BuildTrack, GameState.GetContext());

	CameraAction.LookAtActor = TargetActor;
	CameraAction.LookAtLocation = TargetLocation;
	if( TargetUnit != None )
	{
		CameraAction.LookAtObject = TargetUnit;
	}
	else
	{
		CameraAction.LookAtObject = TargetInteractiveObject;
	}
	CameraAction.LookAtDuration = Max(LookAtDuration, 0.0);

	if (OutputLinks[2].Links.Length > 0 && LookAtDuration < 0.0)
	{
		`RedScreen("SeqAct_XComCameraLookAt action is waiting for completion but is set to an indifinite duration.");
	}

	CameraAction.UseTether = UseTether;
	CameraAction.BlockUntilActorOnScreen = OutputLinks[1].Links.Length > 0;
	CameraAction.BlockUntilFinished = OutputLinks[2].Links.Length > 0;

	// when looking at a game object, obey the camera floor snapping. Otherwise, assume the LDs
	// know what they are doing when they provide and absolute position via actor or location
	CameraAction.SnapToFloor = SnapToFloor;
	
	VisualizationTracks.AddItem(BuildTrack);
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 4;
}

defaultproperties
{
	ObjCategory="Camera"
	ObjName="Game Camera - Focus on Actor"
	bAutoActivateOutputLinks=true
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	LookAtDuration=2
	UseTether=false;
	SnapToFloor=true

	OutputLinks(0)=(LinkDesc="Out")
	OutputLinks(1)=(LinkDesc="Arrived")
	OutputLinks(2)=(LinkDesc="Completed")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Target Game Unit",PropertyName=TargetUnit)
	VariableLinks(2)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="Target Interactive Object",PropertyName=TargetInteractiveObject)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Target Location",PropertyName=TargetLocation)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Bool',LinkDesc="Snap To Floor",PropertyName=SnapToFloor)
	VariableLinks(5)=(ExpectedType = class'SeqVar_Object', LinkDesc = "Out Camera", PropertyName = CameraAction, bWriteable = true)
}