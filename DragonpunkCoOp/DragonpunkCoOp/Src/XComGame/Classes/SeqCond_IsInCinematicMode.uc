//-----------------------------------------------------------
//Returns whether in cinematic mode
//-----------------------------------------------------------
class SeqCond_IsInCinematicMode extends SequenceCondition;

event Activated()
{
	local XComTacticalController kTacticalController;
	local PlayerController kController;
	local bool bInMode;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		if (kTacticalController != none)
		{
			kController = kTacticalController.GetALocalPlayerController();
		}
	}
	
	if (kController != none)
	{
		bInMode = kController.bCinematicMode;
		if (bInMode)
		{
			OutputLinks[0].bHasImpulse = TRUE;
			OutputLinks[1].bHasImpulse = FALSE;
		}
		else
		{
			OutputLinks[0].bHasImpulse = FALSE;
			OutputLinks[1].bHasImpulse = TRUE;
		}
	}
}

defaultproperties
{
	ObjName="In Cinematic Mode"

	bAutoActivateOutputLinks=false

	OutputLinks(0)=(LinkDesc="True")
	OutputLinks(1)=(LinkDesc="False")
	//VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Players")
}
