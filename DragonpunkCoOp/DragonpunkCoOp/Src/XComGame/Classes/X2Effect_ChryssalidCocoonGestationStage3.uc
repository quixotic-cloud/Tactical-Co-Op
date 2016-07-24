class X2Effect_ChryssalidCocoonGestationStage3 extends X2Effect_Persistent
	config(GameCore);

var config string COCOONSTAGETHREEPARTICLE_NAME;
var config name COCOONSTAGETHREESOCKET_NAME;
var config name COCOONSTAGETHREESOCKETSARRAY_NAME;

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlayEffect PlayEffectAction;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);

	PlayEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTrack( BuildTrack, VisualizeGameState.GetContext() ) );

	PlayEffectAction.AttachToUnit = true;
	PlayEffectAction.EffectName = default.COCOONSTAGETHREEPARTICLE_NAME;
	PlayEffectAction.AttachToSocketName = default.COCOONSTAGETHREESOCKET_NAME;
	PlayEffectAction.AttachToSocketsArrayName = default.COCOONSTAGETHREESOCKETSARRAY_NAME;
	PlayEffectAction.bStopEffect = true;
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
	local X2Action_PlayEffect PlayEffectAction;

	super.AddX2ActionsForVisualization_Sync(VisualizeGameState, BuildTrack);

	PlayEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTrack( BuildTrack, VisualizeGameState.GetContext( ) ) );

	PlayEffectAction.AttachToUnit = true;
	PlayEffectAction.EffectName = default.COCOONSTAGETHREEPARTICLE_NAME;
	PlayEffectAction.AttachToSocketName = default.COCOONSTAGETHREESOCKET_NAME;
	PlayEffectAction.AttachToSocketsArrayName = default.COCOONSTAGETHREESOCKETSARRAY_NAME;
}

defaultproperties
{
	EffectName="GestationEffect_Stage3"
}