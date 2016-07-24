//---------------------------------------------------------------------------------------
// DEPRECATED - HERE FOR SAVED GAME BACKWARDS COMPATIBILITY                    
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_AdventTroopTransport extends XComGameStateContext_ReinforcementSpawner;


function UpdatePlayerStateOnSpawn(XComGameState_AIPlayerData AIPlayerDataState, XComGameState NewGameState)
{
	
}

function XComGameState ContextBuildGameState()
{
	//DEPRECATED - HERE FOR SAVED GAME BACKWARDS COMPATIBILITY
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{	
	
}

function string SummaryString()
{
	return "XComGameStateContext_AdventTroopTransport";
}