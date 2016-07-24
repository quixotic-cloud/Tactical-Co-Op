//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_AddActorToBuildingVis extends X2Action;

var Actor FocusActorToAdd;

//------------------------------------------------------------------------------------------------
simulated state Executing
{

Begin:

	if (`LEVEL.m_kBuildingVisManager != none && FocusActorToAdd != none)
		`LEVEL.m_kBuildingVisManager.AddFocusActorViaKismet(FocusActorToAdd);

	CompleteAction();
}

defaultproperties
{
}
