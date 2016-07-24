class X2Effect_SensorSweepTarget extends X2Effect_Persistent;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	//@TODO this should add some kind of pfx to the target until the effect is removed
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "Ping!", '', eColor_Bad);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	//@TODO remove the pfx
}

DefaultProperties
{
	EffectName="SensorSweepTarget"
	DuplicateResponse=eDupe_Refresh
}