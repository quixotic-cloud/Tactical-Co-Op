//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Effect_Panicked.uc    
//  AUTHOR:  Alex Cheng  --  2/12/2015
//  PURPOSE: Panic Effects - Remove control from player and run Panic behavior tree.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Panicked extends X2Effect_ModifyStats;

var array<StatChange>	m_aStatChanges;

simulated function AddPersistentStatChange(ECharStatType StatType, float StatAmount, optional EStatModOp InModOp=MODOP_Addition )
{
	local StatChange NewChange;
	
	NewChange.StatType = StatType;
	NewChange.StatAmount = StatAmount;
	NewChange.ModOp = InModOp;

	m_aStatChanges.AddItem(NewChange);
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	// If our effect is set to expire this turn, don't modify the action points
	if (EffectState.iTurnsRemaining == 1 && WatchRule == eGameRule_PlayerTurnBegin)
		return;

	// Disable player control while panic is in effect.
	ActionPoints.Length = 0;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local Name PanicBehaviorTree;
	local bool bCivilian;
	local int Point;
	
	UnitState = XComGameState_Unit(kNewTargetState);
	if (m_aStatChanges.Length > 0)
	{
		NewEffectState.StatChanges = m_aStatChanges;

		//  Civilian panic does not modify stats and does not need to call the parent functions (which will result in a RedScreen for having no stats!)
		super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	}

	// Add two standard action points for panicking actions.	
	bCivilian = UnitState.GetTeam() == eTeam_Neutral;
	if( !bCivilian )
	{
		for( Point = 0; Point < 2; ++Point )
		{
			if( Point < UnitState.ActionPoints.Length )
			{
				if( UnitState.ActionPoints[Point] != class'X2CharacterTemplateManager'.default.StandardActionPoint )
				{
					UnitState.ActionPoints[Point] = class'X2CharacterTemplateManager'.default.StandardActionPoint;
				}
			}
			else
			{
				UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			}
		}
	}
	else
	{
		// Force civilians into red alert.
		if( UnitState.GetCurrentStat(eStat_AlertLevel) != `ALERT_LEVEL_RED )
		{
			UnitState.SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_RED);
		}
	}
	UnitState.bPanicked = true;

	if( !bCivilian )
	{
		// Kick off panic behavior tree.
		PanicBehaviorTree = Name(UnitState.GetMyTemplate().strPanicBT);

		// Delayed behavior tree kick-off.  Points must be added and game state submitted before the behavior tree can 
		// update, since it requires the ability cache to be refreshed with the new action points.
		UnitState.AutoRunBehaviorTree(PanicBehaviorTree, 2, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true);
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	// This cleared flag is set through the AIBehavior after the behavior tree runs in OnEffectAdded.
	UnitState.bPanicked = false;
	NewGameState.AddStateObject(UnitState);
}

DefaultProperties
{
	bIsImpairingMomentarily=true
	DamageTypes.Add("Mental");
	DamageTypes.Add("Panic");
}