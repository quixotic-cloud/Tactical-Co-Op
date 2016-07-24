//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_CallReinforcements.uc
//  AUTHOR:  Alex Cheng  --  3/7/2014
//  PURPOSE: Call Reinforcements get kicked off
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_CallReinforcements extends X2Effect;
var AkEvent m_kAudioEvent;
// Update info within the XComGameState_AIPlayerData
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	// no longer using this action
	`RedScreen("X2Effect_CallReinforcements called - we no longer expect to be using this effect");
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
	class'X2Action_CallReinforcements'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
}

function int GetArrivalTime()
{
	//Design Doc says this can be modified depending on objective type..  i.e. Final mission lower.
	return `GAMECORE.AI_REINFORCEMENTS_DEFAULT_ARRIVAL_TIME; // Default arrival time.  
}

defaultproperties
{
	m_kAudioEvent=AkEvent'SoundTacticalUI.TacticalUI_UnitFlagWarning'
}