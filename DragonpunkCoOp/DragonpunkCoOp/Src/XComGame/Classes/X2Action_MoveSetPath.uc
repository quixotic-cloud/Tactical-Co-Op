//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveSetPath extends X2Action;

var array<PathPoint> MovementData;
var XComGameStateContext_Ability AbilityContext;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
	
	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
}

simulated state Executing
{
Begin:
	AbilityContext.InputContext.MovementPaths[0].MovementData = MovementData; //In the situations where this action is used - overwrite the first path

	CompleteAction();
}


DefaultProperties
{
}
