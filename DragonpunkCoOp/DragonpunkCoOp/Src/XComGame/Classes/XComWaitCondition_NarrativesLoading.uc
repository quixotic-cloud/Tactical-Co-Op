/**
 * Wait for narratives to finish loading.
 */
class XComWaitCondition_NarrativesLoading extends SeqAct_XComWaitCondition;

/** @return true if the condition has been met */
event bool CheckCondition()
{
	local bool bResult;
	local UINarrativeMgr Manager;
	Manager = XComPlayerController(GetWorldInfo().GetALocalPlayerController()).Pres.m_kNarrativeUIMgr;
	bResult = ( Manager!=None && Manager.PendingPreloadConversations.Length == 0 );

	//  while we're waiting in the tutorial we can end up sitting on a black screen, this can take too long on consoles.
	//  turn load anim on if we're now waiting.
	if ((bResult && bNot) || (!bResult && !bNot))
	{
		XComPlayerController(GetWorldInfo().GetALocalPlayerController()).Pres.UILoadAnimation(true);
	}
	else
	{
		XComPlayerController(GetWorldInfo().GetALocalPlayerController()).Pres.UILoadAnimation(false);
	}
	return bResult;
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if (!bNot)
		return "no narratives preloading.";
	else
		return "narratives preloading.";
}

DefaultProperties
{
	ObjCategory="Tutorial"
	ObjName="Wait for Narratives Loading"
	
	VariableLinks.Empty
}
