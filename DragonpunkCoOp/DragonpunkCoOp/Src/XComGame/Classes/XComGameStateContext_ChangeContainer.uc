//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_ChangeContainer.uc
//  AUTHOR:  David Burchanowski  --  11/21/2013
//  PURPOSE: Simple context for submitting game states that have arbitrary state changes in them.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_ChangeContainer extends XComGameStateContext;

var private XComGameState NewGameState;
var string ChangeInfo;  //Fill out with info to help with debug display

var Delegate<BuildVisualizationDelegate> BuildVisualizationFn; //Optional visualization function

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class isn't meant to be used with SubmitGameStateContext. Use plain vanilla SubmitGameState instead.
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	//if(!`REPLAY.bInReplay) //RAM - HACK! This delegate cannot work when performing a replay. An alternate means of operating this context's visualization should be found
	//{
		if(BuildVisualizationFn != None)
		{
			BuildVisualizationFn(AssociatedState, VisualizationTracks);
		}
	//}
}

static function XComGameStateContext_ChangeContainer CreateEmptyChangeContainer(optional string ChangeDescription)
{
	local XComGameStateContext_ChangeContainer container;
	container = XComGameStateContext_ChangeContainer(CreateXComGameStateContext());
	container.ChangeInfo = ChangeDescription;
	return container;
}

static function XComGameState CreateChangeState(optional string ChangeDescription, bool bSetVisualizationFence = false, float VisFenceTimeout=20.0f)
{
	local XComGameStateContext_ChangeContainer container;
	container = CreateEmptyChangeContainer(ChangeDescription);
	container.SetVisualizationFence(bSetVisualizationFence, VisFenceTimeout);
	return `XCOMHISTORY.CreateNewGameState(true, container);
}

static function XComGameState_Cheats_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameState_Cheats CheatState;
	local VisualizationTrack BuildTrack;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Cheats', CheatState)
	{
		BuildTrack.StateObject_NewState = CheatState;
		BuildTrack.StateObject_OldState = CheatState;
		class'X2Action_SyncVisualizer'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		OutVisualizationTracks.AddItem(BuildTrack);
		break;
	}
}

function string SummaryString()
{
	return ChangeInfo == "" ? "XComGameStateContext_ChangeContainer" : "CC" @ ChangeInfo;
}
