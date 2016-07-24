//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_RedAlert.uc
//  AUTHOR:  Ryan McFall  --  1/13/2014
//  PURPOSE: Defines the abilities that form the concealment / alertness mechanics in 
//  X-Com 2. Presently these abilities are only available to the AI.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_RedAlert extends X2Effect_Persistent;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{	
	local XComGameState_Unit kTargetUnitState;
	//local StateObjectReference PlayerRef;

	kTargetUnitState = XComGameState_Unit(kNewTargetState);
	if( kTargetUnitState != none )
	{
		kTargetUnitState.SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_RED);
		UpdateAIPlayerOfRedAlert(NewGameState);

		ApplyStatChangeToSubSystems(kTargetUnitState.GetReference(), eStat_AlertLevel, 2, NewGameState);
		`LogAI("ALERTEFFECTS: X2Effect_RedAlert::OnEffectAdded- Set Alert Level Stat 2. Unit#"$kTargetUnitState.ObjectID);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

// Update AI Player data if necessary.  Reset ConsecutiveInactiveTurns when an AI becomes active.
function UpdateAIPlayerOfRedAlert(XComGameState NewGameState)
{
	local XComGameState_AIPlayerData AIState;
	local XGAIPlayer AIPlayer;
	local int AIDataID;

	// Get the AIPlayerData gamestate to check if we need to update it.
	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( AIPlayer != None )
	{
		AIDataID = AIPlayer.m_iDataID;
		if( AIDataID > 0 )
		{
			AIState = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIDataID));
			if( AIState.StatsData.ConsecutiveInactiveTurns > 0 ) // Only need reset this value if it has not already been reset.
			{
				// Reset the AIPlayerData's ConsecutiveInactiveTurns to zero.
				AIState = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', AIDataID));
				AIState.StatsData.ConsecutiveInactiveTurns = 0;  
				NewGameState.AddStateObject(AIState);
			}
		}
	}
}

// Returns true if the associated XComGameSate_Effect should be removed
simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit TargetUnitState;

	if (!FullTurnComplete(kNewEffectState))
		return true;

	//Decrement the turns remaining if no enemies are visible, otherwise we stay at the same alert level and reset our turns remaining
	TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( TargetUnitState != none )
	{
		// Tick down as long as no living enemies are visible.
		if (TargetUnitState.GetNumVisibleEnemyUnits(true,true) == 0 || TargetUnitState.IsDead())
		{		
			kNewEffectState.iTurnsRemaining = 0;		
			bInfiniteDuration = false; // Disable this effect.
			NewGameState.RemoveStateObject(kNewEffectState.ObjectID);// Remove effect.
		}
		else
		{
			kNewEffectState.iTurnsRemaining = 1;
		}
	}

	return (bInfiniteDuration || kNewEffectState.iTurnsRemaining > 0);
}

// Removed this function since it causes a conflict with another game state being modified, can't call SubmitGameStateContext here.
//simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
//{
//	local XComGameState_Unit TargetUnitState;
//	local XComGameState_Ability ViewerAbility;
//	local XComGameStateContext_Ability AlertContext;
//	local XComGameStateHistory History;
//	local int AbilityIndex;
//
//	TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
//	if( TargetUnitState != none && TargetUnitState.IsAlive() )// Don't bother updating stats and AI data when dead.
//	{
//		History = `XCOMHISTORY;
//		// Kick off yellow alert when dropping down from red alert state.
//		for( AbilityIndex = 0; AbilityIndex < TargetUnitState.Abilities.Length; ++AbilityIndex )
//		{
//			ViewerAbility = XComGameState_Ability(History.GetGameStateForObjectID(TargetUnitState.Abilities[AbilityIndex].ObjectID));
//			if( ViewerAbility.GetMyTemplateName() == 'YellowAlert' )
//			{
//				AlertContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(ViewerAbility, TargetUnitState.ObjectID);
//				`XCOMGAME.GameRuleset.SubmitGameStateContext(AlertContext);
//				break;
//			}
//		}
//	}
//}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	if(UnitState != None && UnitState.IsTurret())
	{
		class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
}