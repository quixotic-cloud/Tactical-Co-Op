//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ProximityMine.uc
//  AUTHOR:  Joshua Bouscher  --  3/24/2015
//  PURPOSE: This effect will persist on a unit that uses a proximity mine.
//           It is in charge of detecting enemy movement within the appropriate
//           range and issuing the corresponding detonation ability.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ProximityMine extends X2Effect_Persistent config(GameData);

var config string PersistentParticles;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'ObjectMoved', EffectGameState.ProximityMine_ObjectMoved, ELD_OnStateSubmitted);
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', EffectGameState.ProximityMine_AbilityActivated, ELD_OnStateSubmitted);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Effect MineEffect, EffectState;
	local X2Action_PlayEffect EffectAction;
	local X2Action_StartStopSound SoundAction;

	if (EffectApplyResult != 'AA_Success' || BuildTrack.TrackActor == none)
		return;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect() == self)
		{
			MineEffect = EffectState;
			break;
		}
	}
	`assert(MineEffect != none);

	//For multiplayer: don't visualize mines on the enemy team.
	if (MineEffect.GetSourceUnitAtTimeOfApplication().ControllingPlayer.ObjectID != `TACTICALRULES.GetLocalClientPlayerObjectID())
		return;

	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	EffectAction.EffectName = default.PersistentParticles;
	EffectAction.EffectLocation = MineEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAction.Sound = new class'SoundCue';
	SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Item_Proximity_Mine_Active_Ping';
	SoundAction.iAssociatedGameStateObjectId = MineEffect.ObjectID;
	SoundAction.bStartPersistentSound = true;
	SoundAction.bIsPositional = true;
	SoundAction.vWorldPosition = MineEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local XComGameState_Effect MineEffect, EffectState;
	local X2Action_PlayEffect EffectAction;
	local X2Action_StartStopSound SoundAction;

	if (EffectApplyResult != 'AA_Success' || BuildTrack.TrackActor == none)
		return;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect() == self)
		{
			MineEffect = EffectState;
			break;
		}
	}
	`assert(MineEffect != none);

	//For multiplayer: don't visualize mines on the enemy team.
	if (MineEffect.GetSourceUnitAtTimeOfApplication().ControllingPlayer.ObjectID != `TACTICALRULES.GetLocalClientPlayerObjectID())
		return;

	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	EffectAction.EffectName = default.PersistentParticles;
	EffectAction.EffectLocation = MineEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	EffectAction.bStopEffect = true;

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAction.Sound = new class'SoundCue';
	SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Stop_Proximity_Mine_Active_Ping';
	SoundAction.iAssociatedGameStateObjectId = MineEffect.ObjectID;
	SoundAction.bIsPositional = true;
	SoundAction.bStopPersistentSound = true;
}

DefaultProperties
{
	EffectName="ProximityMine"
	DuplicateResponse = eDupe_Allow;
	bCanBeRedirected = false;
}