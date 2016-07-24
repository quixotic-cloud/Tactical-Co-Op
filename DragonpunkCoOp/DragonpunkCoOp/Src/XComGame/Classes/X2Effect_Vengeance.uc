//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Vengeance.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    5/29/2015
//  PURPOSE: Stat boost effect that calculates bonuses based on the source unit's rank.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_Vengeance extends X2Effect_ModifyStats config(GameData_SoldierSkills);

var config int STAT_BASE_CHANCE, STAT_PER_RANK_CHANCE;
var config int AIM_BASE, AIM_INCREASE;
var config int CRIT_BASE, CRIT_INCREASE;
var config int WILL_BASE, WILL_INCREASE;
var config int MOBILITY_BASE, MOBILITY_INCREASE;
var config int NO_RANK_INCREASES;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnit;

	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SourceUnit != none);

	CalculateVengeanceStats(SourceUnit, XComGameState_Unit(kNewTargetState), NewEffectState);
	
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated protected function CalculateVengeanceStats(XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState)
{
	local int DeadRank, RankDiff, StatChance, RandRoll;
	local StatChange Vengeance;

	DeadRank = SourceUnit.GetRank();
	if (DeadRank > default.NO_RANK_INCREASES)
		RankDiff = DeadRank - default.NO_RANK_INCREASES;
	
	StatChance = default.STAT_BASE_CHANCE + DeadRank * default.STAT_PER_RANK_CHANCE;

	//  Roll for Aim
	RandRoll = `SYNC_RAND(100);
	if (RandRoll < StatChance)
	{
		Vengeance.StatType = eStat_Offense;
		Vengeance.StatAmount = default.AIM_BASE + RankDiff * default.AIM_INCREASE;
		EffectState.StatChanges.AddItem(Vengeance);
	}
	//  Roll for Crit
	RandRoll = `SYNC_RAND(100);
	if (RandRoll < StatChance)
	{
		Vengeance.StatType = eStat_CritChance;
		Vengeance.StatAmount = default.CRIT_BASE + RankDiff * default.CRIT_INCREASE;
		EffectState.StatChanges.AddItem(Vengeance);
	}
	//  Roll for Will
	RandRoll = `SYNC_RAND(100);
	if (RandRoll < StatChance)
	{
		Vengeance.StatType = eStat_Will;
		Vengeance.StatAmount = default.WILL_BASE + RankDiff * default.WILL_INCREASE;
		EffectState.StatChanges.AddItem(Vengeance);
	}
	//  Roll for Mobility
	RandRoll = `SYNC_RAND(100);
	if (RandRoll < StatChance)
	{
		Vengeance.StatType = eStat_Mobility;
		Vengeance.StatAmount = default.MOBILITY_BASE + RankDiff * default.MOBILITY_INCREASE;
		EffectState.StatChanges.AddItem(Vengeance);
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	//  Only relevant if we successfully rolled any stat changes
	return EffectGameState.StatChanges.Length > 0;
}

DefaultProperties
{
	EffectName = "Vengeance"
	DuplicateResponse = eDupe_Ignore
}