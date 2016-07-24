//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyBlazingPinionsTargetToWorld extends X2Effect_Persistent config(GameData);

var config string BlazingPinionsParticleSystemFill_Name;

var string OverrideParticleSystemFill_Name;

private function DoTargetFX(XComGameState_Effect TargetEffect, out VisualizationTrack BuildTrack, XComGameStateContext Context, name EffectApplyResult, bool bStopEffect)
{
	local X2Action_PlayEffect EffectAction;
	local int i;

	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	// The first value in the InputContext.TargetLocations is the desired landing posiiton
	// The targets start at index 1
	if( TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 1 )
	{
		for( i = 1; i < TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations.Length; ++i )
		{
			EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
			EffectAction.EffectName = default.BlazingPinionsParticleSystemFill_Name;
			if( OverrideParticleSystemFill_Name != "" )
			{
				EffectAction.EffectName = OverrideParticleSystemFill_Name;
			}
			EffectAction.bStopEffect = bStopEffect;
			EffectAction.EffectLocation = TargetEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[i];
		}
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Effect TargetEffect;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', TargetEffect)
	{
		if( TargetEffect.GetX2Effect() == self )
		{
			break;
		}
	}

	if( TargetEffect == none )
	{
		`RedScreen("Could not find Blazing Pinions World Target effect. Author: dslonneger Contact: @gameplay");
		return;
	}

	DoTargetFX(TargetEffect, BuildTrack, VisualizeGameState.GetContext(), EffectApplyResult, false);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	DoTargetFX(RemovedEffect, BuildTrack, VisualizeGameState.GetContext(), EffectApplyResult, true);
}

defaultproperties
{
	EffectName="ApplyBlazingPinionsTargetToWorld"
	OverrideParticleSystemFill_Name=""
}