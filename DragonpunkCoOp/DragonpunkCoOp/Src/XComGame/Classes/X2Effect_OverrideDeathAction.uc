class X2Effect_OverrideDeathAction extends X2Effect_Persistent;

var class<X2Action> DeathActionClass;

simulated function X2Action AddX2ActionsForVisualization_Death(out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	local X2Action AddAction;

	`assert(DeathActionClass != none);
	if( DeathActionClass != none && DeathActionClass.static.AllowOverrideActionDeath(BuildTrack, Context))
	{
		AddAction = class'X2Action'.static.CreateVisualizationActionClass( DeathActionClass, Context, BuildTrack.TrackActor );
		BuildTrack.TrackActions.AddItem( AddAction );
	}

	return AddAction;
}