//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ChryssalidBurrowedAttack extends X2Effect_Persistent;

var private int NumActions;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_AIGroup GroupState;
	local XComGameState_Unit TargetUnitState;
	
	local XComWorldData WorldData;
	local Vector OurVectorLocation;
	local Vector ResultVectorLocation;
	local TTile TargetFinalTile, OurTile, resultTile;
	local bool bIsSpaceOccupiedAlready;
	local StateObjectReference TargetObjectReference;

	WorldData = `XWORLD;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	// This happens while it is not the unit's turn, so it should have no action points
	// The unit must Unburrow and the Unburrow ability grants two action points
	UnitState.ActionPoints.Length = 0;
	UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);
	UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);

	UnitState.bTriggerRevealAI = false;

	NewGameState.AddStateObject(UnitState);

	// Mark group as scampered.
	GroupState = UnitState.GetGroupMembership();
	if( GroupState != none )
	{
		// No AI in MP
		GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
		GroupState.bProcessedScamper = true;
		NewGameState.AddStateObject(GroupState);
	}

	`assert(ApplyEffectParameters.AbilityInputContext.MultiTargets.Length == 1); // Since the ability does a self target, the moved unit is now stored in the first multitarget index
	TargetObjectReference = ApplyEffectParameters.AbilityInputContext.MultiTargets[0];
	TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetObjectReference.ObjectID));
	XGUnit(UnitState.GetVisualizer()).m_kBehavior.PriorityTarget = TargetObjectReference; // Unit the Chryssalid will attack

	if (TargetUnitState != none)
	{
		//if the target's final tile and our tile are the same, we need to move to a different Tile.
		TargetFinalTile = TargetUnitState.TileLocation;
		OurTile = UnitState.TileLocation;

		bIsSpaceOccupiedAlready = (TargetFinalTile == OurTile);
		if (bIsSpaceOccupiedAlready)
		{
			OurVectorLocation = WorldData.GetPositionFromTileCoordinates(OurTile);
			ResultVectorLocation = WorldData.FindClosestValidLocation(OurVectorLocation, false, false, false);
			resultTile = WorldData.GetTileCoordinatesFromPosition(ResultVectorLocation);
			UnitState.SetVisibilityLocation(resultTile);
		}
	}

	// Kick off panic behavior tree.
	// Delayed behavior tree kick-off.  Points must be added and game state submitted before the behavior tree can 
	// update, since it requires the ability cache to be refreshed with the new action points.
	UnitState.AutoRunBehaviorTree('ChryssalidBurrowedAttack', NumActions, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true);
}

defaultproperties
{
	NumActions=3
}