//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ScanningProtocol.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ScanningProtocol extends X2Effect_Persistent;

var float LookAtDuration;

function EffectAddedCallback(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local X2EventManager EventMan;
	local XComGameState_Unit UnitState;

	EventMan = `XEVENTMGR;
	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);      //  will be useless for units without unburrow, just add it blindly
		EventMan.TriggerEvent(class'X2Ability_Chryssalid'.default.UnburrowTriggerEventName, kNewTargetState, kNewTargetState, NewGameState);
		EventMan.TriggerEvent(class'X2Ability_Faceless'.default.ChangeFormTriggerEventName, kNewTargetState, kNewTargetState, NewGameState);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_UpdateScanningProtocolOutline OutlineAction;
	local X2Action_PlaySoundAndFlyOver FlyOver;
	local X2AbilityTemplate AbilityTemplate;

	if (EffectApplyResult == 'AA_Success' && XComGameState_Unit(BuildTrack.StateObject_NewState) != none)
	{
		OutlineAction = X2Action_UpdateScanningProtocolOutline(class'X2Action_UpdateScanningProtocolOutline'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		OutlineAction.bEnableOutline = true;

		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(XComGameStateContext_Ability(VisualizeGameState.GetContext()).InputContext.AbilityTemplateName);
		FlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		FlyOver.SetSoundAndFlyOverParameters(none, AbilityTemplate.LocFlyOverText, '', eColor_Bad, AbilityTemplate.IconImage, default.LookAtDuration, true);
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	if (XComGameState_Unit(BuildTrack.StateObject_NewState) != none)
	{
		class'X2Action_UpdateScanningProtocolOutline'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationTrack BuildTrack )
{
	local X2Action_UpdateScanningProtocolOutline OutlineAction;

	OutlineAction = X2Action_UpdateScanningProtocolOutline( class'X2Action_UpdateScanningProtocolOutline'.static.AddToVisualizationTrack( BuildTrack, VisualizeGameState.GetContext( ) ) );
	OutlineAction.bEnableOutline = true;
}

DefaultProperties
{
	EffectName="ScanningProtocol"
	DuplicateResponse=eDupe_Ignore
	EffectAddedFn=EffectAddedCallback
	LookAtDuration=1.0f
}