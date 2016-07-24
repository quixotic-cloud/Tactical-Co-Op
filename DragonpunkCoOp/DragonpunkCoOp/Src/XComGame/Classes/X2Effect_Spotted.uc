//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Spotted.uc
//  AUTHOR:  Alex Cheng --  6/23/2014
//  PURPOSE: Spotted flag on units
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Spotted extends X2Effect;
var bool m_bBecomeUnspotted;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{	
	local XComGameState_Unit kTargetUnitState;

	kTargetUnitState = XComGameState_Unit(kNewTargetState);
	if( kTargetUnitState != none )
	{
		kTargetUnitState.m_bSpotted = !m_bBecomeUnspotted;	
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action AddedAction;
	if( BuildTrack.StateObject_NewState.IsA('XComGameState_Unit') )
	{
		AddedAction = class'X2Action_SpottedUnit'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		X2Action_SpottedUnit(AddedAction).SetSpottedParameter( m_bBecomeUnspotted );
	}
}

static function X2Effect_Spotted CreateUnspottedEffect()
{
	local X2Effect_Spotted     UnspottedEffect;

	UnspottedEffect = new class'X2Effect_Spotted';
	UnspottedEffect.m_bBecomeUnspotted = true;

	return UnspottedEffect;
}


defaultproperties
{
	m_bBecomeUnspotted=false
}