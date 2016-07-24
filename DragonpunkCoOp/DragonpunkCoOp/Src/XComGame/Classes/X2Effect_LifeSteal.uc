//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_LifeSteal extends X2Effect;

var float LifeAmountMultiplier;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Ability Ability;
	local XComGameState_Unit TargetUnit, OldTargetUnit, SourceUnit;
	local int SourceObjectID;
	local XComGameStateHistory History;
	local int LifeAmount;

	History = `XCOMHISTORY;

	Ability = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if( Ability == none )
	{
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	}

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if( (Ability != none) && (TargetUnit != none) )
	{
		SourceObjectID = ApplyEffectParameters.SourceStateObjectRef.ObjectID;
		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(SourceObjectID));
		OldTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));
		
		if( (SourceUnit != none) && (OldTargetUnit != none) )
		{
			LifeAmount = (OldTargetUnit.GetCurrentStat(eStat_HP) - TargetUnit.GetCurrentStat(eStat_HP));
			LifeAmount = LifeAmount * LifeAmountMultiplier;

			SourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', SourceObjectID));
			SourceUnit.ModifyCurrentStat(eStat_HP, LifeAmount);
			NewGameState.AddStateObject(SourceUnit);
		}
	}
}

simulated function AddX2ActionsForVisualizationSource(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int Healed;

	if (EffectApplyResult != 'AA_Success')
		return;

	// Grab the current and previous gatekeeper unit and check if it has been healed
	OldUnit = XComGameState_Unit(BuildTrack.StateObject_OldState);
	NewUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);

	Healed = NewUnit.GetCurrentStat(eStat_HP) - OldUnit.GetCurrentStat(eStat_HP);
	
	if( Healed > 0 )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "+" $ Healed, '', eColor_Good);
	}
}