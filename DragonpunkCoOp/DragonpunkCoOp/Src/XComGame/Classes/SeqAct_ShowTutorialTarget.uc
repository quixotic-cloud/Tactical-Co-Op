class SeqAct_ShowTutorialTarget extends SequenceAction
	implements(X2KismetSeqOpVisualizer);


event Activated()
{
}

function ModifyKismetGameState(out XComGameState GameState)
{
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;
	local VisualizationTrack BuildTrack;

	if(`TUTORIAL != none)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
		{
			break;
		}

		BuildTrack.StateObject_OldState = KismetStateObject;
		BuildTrack.StateObject_NewState = KismetStateObject;

		class'X2Action_ShowTutorialTarget'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext());
	
		VisualizationTracks.AddItem(BuildTrack);
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 3;
}

defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="Show Tutorial Target"
	bAutoActivateOutputLinks=true
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
}