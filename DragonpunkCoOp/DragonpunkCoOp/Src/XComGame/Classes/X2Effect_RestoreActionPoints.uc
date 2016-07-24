//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_RestoreActionPoints.uc
//  AUTHOR:  Joshua Bouscher 24 Jun 2015
//  PURPOSE: Bring a unit's standard action points back to the normal amount.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_RestoreActionPoints extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit != none)
	{
		while (TargetUnit.NumActionPoints(class'X2CharacterTemplateManager'.default.StandardActionPoint) < class'X2CharacterTemplateManager'.default.StandardActionsPerTurn)
		{
			TargetUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
	}
}