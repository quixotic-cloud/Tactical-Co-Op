//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ChryssalidCocoonDeathAction extends X2Action_PlayAnimation;

static function bool AllowOverrideActionDeath(const out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	return true;
}

simulated state Executing
{
Begin:
	CompleteAction();
}