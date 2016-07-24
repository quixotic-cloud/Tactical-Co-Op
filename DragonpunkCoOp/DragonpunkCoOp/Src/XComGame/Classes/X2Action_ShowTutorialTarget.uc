class X2Action_ShowTutorialTarget extends X2Action;

simulated state Executing
{
	function ShowTargets()
	{
		local XComTutorialMgr TutorialManager;

		TutorialManager = `TUTORIAL;
		
		TutorialManager.SetMoveMarkers();
		TutorialManager.SetTargetLocationMarkers();
	}

Begin:
	ShowTargets();	

	CompleteAction();
}
