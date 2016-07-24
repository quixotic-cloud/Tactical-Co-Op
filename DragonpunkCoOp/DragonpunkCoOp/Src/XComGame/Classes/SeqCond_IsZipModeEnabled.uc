//-----------------------------------------------------------
//Returns whether in Zip mode
//-----------------------------------------------------------
class SeqCond_IsZipModeEnabled extends SequenceCondition;

event Activated()
{
	if( `XPROFILESETTINGS.Data.bEnableZipMode )
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

defaultproperties
{
	ObjName = "Zip Mode Enabled"

	bAutoActivateOutputLinks = false
	bCanBeUsedForGameplaySequence = true
	bConvertedForReplaySystem = true

	OutputLinks(0)=(LinkDesc="True")
	OutputLinks(1)=(LinkDesc="False")
	//VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Players")
}
