//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_RemoveActorFromBuildingVis extends X2Action;

var Actor FocusActorToRemove;

//------------------------------------------------------------------------------------------------
simulated state Executing
{

Begin:

	if (`LEVEL.m_kBuildingVisManager != none && FocusActorToRemove != none)
		`LEVEL.m_kBuildingVisManager.RemoveFocusActorViaKismet(FocusActorToRemove);

	CompleteAction();
}

defaultproperties
{
}
