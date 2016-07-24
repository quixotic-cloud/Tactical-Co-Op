//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_AreaDamage.uc
//  AUTHOR:  Ryan McFall, David Burchanowski  --  3/5/2014
//  PURPOSE: This context is used with damage events that require their own game state
//           object. IE. Kismet driven damage.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_AreaDamage extends XComGameStateContext
	native(Core);

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class isn't meant to be used with SubmitGameStateContext. Use plain vanilla SubmitGameState + manually building the game state instead. 
	// ContextBuildVisualization IS STILL USED to create the necessary tracks to show damage occurring
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;
	local VisualizationTrack EmptyTrack;
	local XComGameState_EnvironmentDamage DamageEventStateObject;
	local XComGameState_Unit UnitObject;
	local XComGameState_WorldEffectTileData TileDataStateObject;
	local X2Effect ApplyEffect;
	local X2Action_WaitForDestructibleActorActionTrigger WaitForTriggerAction;
	local X2Action_WaitForWorldDamage WaitForWorldDamageAction;
	local X2Action_Delay DelayAction;
	local int FirstDamageSource;
	local bool bCausedByDestructible;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameStateContext VisualizingWithContext;
	local bool bShouldWaitForWorldDamage;

	History = `XCOMHISTORY;

	//Look up the context we're visualizing with - if it's an ability context, we should wait for it.
	if (DesiredVisualizationBlockIndex != -1)
	{
		VisualizingWithContext = History.GetGameStateFromHistory(DesiredVisualizationBlockIndex).GetContext();
		if (XComGameStateContext_Ability(VisualizingWithContext) != None)
			bShouldWaitForWorldDamage = true;
	}

	// add visualization of environment damage
	foreach AssociatedState.IterateByClassType(class'XComGameState_EnvironmentDamage', DamageEventStateObject)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = DamageEventStateObject;
		BuildTrack.StateObject_NewState = DamageEventStateObject;

		if (FirstDamageSource == 0)
		{
			FirstDamageSource = DamageEventStateObject.DamageSource.ObjectID;
			bCausedByDestructible = XComDestructibleActor(History.GetVisualizer(FirstDamageSource)) != None;
		}

		if(bCausedByDestructible)
		{
			WaitForTriggerAction = X2Action_WaitForDestructibleActorActionTrigger(class'X2Action_WaitForDestructibleActorActionTrigger'.static.AddToVisualizationTrack(BuildTrack, self));
			WaitForTriggerAction.SetTriggerParameters(class'XComDestructibleActor_Action_RadialDamage', FirstDamageSource);
		}
		else if (bShouldWaitForWorldDamage)
		{
			WaitForWorldDamageAction = X2Action_WaitForWorldDamage(class'X2Action_WaitForWorldDamage'.static.AddToVisualizationTrack(BuildTrack, self));
			WaitForWorldDamageAction.bIgnoreIfPriorWaitFound = true;
		}

		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, self);
		VisualizationTracks.AddItem(BuildTrack);	
	}

	// add visualization of all damaged units
	foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitObject)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitObject.ObjectID,, AssociatedState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = UnitObject;
		BuildTrack.TrackActor = UnitObject.GetVisualizer();

		if(bCausedByDestructible)
		{
			WaitForTriggerAction = X2Action_WaitForDestructibleActorActionTrigger(class'X2Action_WaitForDestructibleActorActionTrigger'.static.AddToVisualizationTrack(BuildTrack, self));
			WaitForTriggerAction.SetTriggerParameters(class'XComDestructibleActor_Action_RadialDamage', FirstDamageSource);

			//Add a delay in so that they appear caught in the explosion
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, self));
			DelayAction.Duration = 0.5f;
		}
		else if (bShouldWaitForWorldDamage)
		{
			WaitForWorldDamageAction = X2Action_WaitForWorldDamage(class'X2Action_WaitForWorldDamage'.static.AddToVisualizationTrack(BuildTrack, self));
			WaitForWorldDamageAction.bIgnoreIfPriorWaitFound = true;
		}
		
		class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, self);

		//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
		TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
		if (TargetVisualizerInterface != none)
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, BuildTrack);

		VisualizationTracks.AddItem(BuildTrack);	
	}
	
	foreach AssociatedState.IterateByClassType(class'XComGameState_WorldEffectTileData', TileDataStateObject)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = TileDataStateObject;
		BuildTrack.StateObject_NewState = TileDataStateObject;

		if( TileDataStateObject.StoredTileData.Length > 0 )
		{
			//Assume that effect names are the same for each tile
			ApplyEffect = X2Effect(class'Engine'.static.FindClassDefaultObject(string(TileDataStateObject.StoredTileData[0].Data.EffectName)));
			if( ApplyEffect != none )
			{
				if(bCausedByDestructible)
				{
					WaitForTriggerAction = X2Action_WaitForDestructibleActorActionTrigger(class'X2Action_WaitForDestructibleActorActionTrigger'.static.AddToVisualizationTrack(BuildTrack, self));
					WaitForTriggerAction.SetTriggerParameters(class'XComDestructibleActor_Action_RadialDamage', FirstDamageSource);
				}
				else if (bShouldWaitForWorldDamage)
				{
					WaitForWorldDamageAction = X2Action_WaitForWorldDamage(class'X2Action_WaitForWorldDamage'.static.AddToVisualizationTrack(BuildTrack, self));
					WaitForWorldDamageAction.bIgnoreIfPriorWaitFound = true;
				}

				ApplyEffect.AddX2ActionsForVisualization(AssociatedState, BuildTrack, 'AA_Success');
			}
			else
			{
				`redscreen("UpdateWorldEffects context failed to build visualization, could not resolve class from name:"@TileDataStateObject.StoredTileData[0].Data.EffectName@"!");
			}

			VisualizationTracks.AddItem(BuildTrack);
		}
	}

	AddVisualizationFromFutureGameStates(AssociatedState, VisualizationTracks, VisTrackInsertedInfoArray);
}

function string SummaryString()
{
	return "XComGameStateContext_AreaDamage";
}