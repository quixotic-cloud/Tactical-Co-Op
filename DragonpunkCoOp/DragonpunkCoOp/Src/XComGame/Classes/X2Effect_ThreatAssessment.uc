//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ThreatAssessment.uc
//  AUTHOR:  Joshua Bouscher  --  6/25/2015
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ThreatAssessment extends X2Effect_CoveringFire;

var name ImmediateActionPoint;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit != none && ImmediateActionPoint != '')
	{
		TargetUnit.ReserveActionPoints.AddItem(ImmediateActionPoint);
	}
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
}