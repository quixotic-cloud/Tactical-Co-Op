class XComWaitCondition_WaitForGlamCam extends SeqAct_XComWaitCondition;

event bool CheckCondition()
{
	//`LOG( "WaitForGlamCam:  m_bGlamCamBusy = " @`BATTLE.m_kGlamMgr.m_bGlamBusy,, 'Tutorial' );
	// Wait for the camera to get to its final location.
	return false; // !`BATTLE.m_kGlamMgr.m_bGlamBusy;
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if (!bNot)
		return "Glam Cam Finishes.";
	else
		return "Glam Cam Starts.";
}

defaultproperties
{
	ObjCategory="Wait Conditions"
	ObjName="Wait For Glam Cam"
}