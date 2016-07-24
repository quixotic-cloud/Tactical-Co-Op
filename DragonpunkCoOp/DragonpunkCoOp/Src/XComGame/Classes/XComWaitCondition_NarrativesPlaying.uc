/**
 * Wait for narratives to finish playing.
 */
class XComWaitCondition_NarrativesPlaying extends SeqAct_XComWaitCondition;

/** @return true if the condition has been met */
event bool CheckCondition()
{
	local UINarrativeMgr Manager;
	Manager = XComPlayerController(GetWorldInfo().GetALocalPlayerController()).Pres.m_kNarrativeUIMgr;
	return( Manager.m_arrConversations.Length == 0 && !Manager.bActivelyPlayingConversation && Manager.PendingConversations.Length == 0 );
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if (!bNot)
		return "no narratives in queue.";
	else
		return "narratives in queue.";
}

DefaultProperties
{
	ObjCategory="Tutorial"
	ObjName="Wait for Narratives"
	
	VariableLinks.Empty
}
