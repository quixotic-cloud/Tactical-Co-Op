//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_TickEffect.uc
//  AUTHOR:  Joshua Bouscher -- 6/17/2014
//  PURPOSE: Used by XComGameState_Effect whenever an effect is ticked. Used purely for
//           visualization purposes.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_TickEffect extends XComGameStateContext;

var StateObjectReference TickedEffect;
var() array<name> arrTickSuccess;   // Stores result of ApplyEffect for each ApplyOnTick effect

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class is not used to build a game state, see XComGameState_Effect for use
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local VisualizationTrack BuildTrack, SourceBuildTrack;	
	local XComGameStateHistory History;
	local X2VisualizerInterface VisualizerInterface;
	local XComGameState_Effect EffectState;
	local XComGameState_BaseObject EffectTarget;
	local X2Effect_Persistent EffectTemplate;
	local X2Effect TickingEffect;
	local int i;

	History = `XCOMHISTORY;
	
	EffectState = XComGameState_Effect(AssociatedState.GetGameStateForObjectID(TickedEffect.ObjectID));
	`assert(EffectState != none);
	EffectTarget = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);
	
	if (EffectTarget != none)
	{
		BuildTrack.TrackActor = History.GetVisualizer(EffectTarget.ObjectID);
		VisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
		if (BuildTrack.TrackActor != none)
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
			if (BuildTrack.StateObject_NewState == none)
				BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
			else if (BuildTrack.StateObject_OldState == none)
				BuildTrack.StateObject_OldState = BuildTrack.StateObject_NewState;

			if (VisualizerInterface != none)
				VisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, BuildTrack);

			EffectTemplate = EffectState.GetX2Effect();

			if (!EffectState.bRemoved)
			{
				EffectTemplate.AddX2ActionsForVisualization_Tick(AssociatedState, BuildTrack, INDEX_NONE, EffectState);
			}

			for (i = 0; i < EffectTemplate.ApplyOnTick.Length; ++i)
			{
				TickingEffect = EffectTemplate.ApplyOnTick[i];
				TickingEffect.AddX2ActionsForVisualization_Tick(AssociatedState, BuildTrack, i, EffectState);
			}

			if (EffectState.bRemoved)
			{
				EffectTemplate.AddX2ActionsForVisualization_Removed(AssociatedState, BuildTrack, 'AA_Success', EffectState);

				// When the effect gets removed, the source of the effect may also need to update visuals
				SourceBuildTrack.TrackActor = History.GetVisualizer(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
				if (SourceBuildTrack.TrackActor != none)
				{
					History.GetCurrentAndPreviousGameStatesForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID, SourceBuildTrack.StateObject_OldState, SourceBuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
					if (SourceBuildTrack.StateObject_NewState == none)
						SourceBuildTrack.StateObject_NewState = SourceBuildTrack.StateObject_OldState;
					else if (SourceBuildTrack.StateObject_OldState == none)
						SourceBuildTrack.StateObject_OldState = SourceBuildTrack.StateObject_NewState;

					EffectTemplate.AddX2ActionsForVisualization_RemovedSource(AssociatedState, SourceBuildTrack, 'AA_Success', EffectState);
					if (SourceBuildTrack.TrackActions.Length > 0)
					{
						VisualizationTracks.AddItem(SourceBuildTrack);
					}
				}
			}
		}
	}
	if (BuildTrack.TrackActions.Length > 0)
	{
		VisualizationTracks.AddItem(BuildTrack);
	}
}

function string SummaryString()
{
	return "XComGameStateContext_TickEffect";
}

static function XComGameStateContext_TickEffect CreateTickContext(XComGameState_Effect EffectState)
{
	local XComGameStateContext_TickEffect container;
	container = XComGameStateContext_TickEffect(CreateXComGameStateContext());
	container.TickedEffect = EffectState.GetReference();
	container.SetVisualizationFence(true, 5);
	return container;
}