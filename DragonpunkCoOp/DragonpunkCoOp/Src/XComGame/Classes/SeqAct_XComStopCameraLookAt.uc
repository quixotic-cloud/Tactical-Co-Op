class SeqAct_XComStopCameraLookAt extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var X2Action_CameraLookAt CameraActionToStop;

event Activated()
{
}

function ModifyKismetGameState(out XComGameState GameState)
{
	// always fence this. The camera lookat action will immediately return and unblock if
	// not block is requested
	GameState.GetContext().SetVisualizationFence(true, 0);
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_CameraRemove CameraRemoveAction;
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;

	History = `XComHistory;
	foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	CameraRemoveAction = X2Action_CameraRemove(class'X2Action_CameraRemove'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
	CameraRemoveAction.CameraActionToRemove = CameraActionToStop;

	CameraActionToStop = none;

	VisualizationTracks.AddItem(BuildTrack);
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory="Camera"
	ObjName="Game Camera - Stop Camera"
	bAutoActivateOutputLinks=true
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="CameraToStop",PropertyName=CameraActionToStop,bWriteable=true)
}