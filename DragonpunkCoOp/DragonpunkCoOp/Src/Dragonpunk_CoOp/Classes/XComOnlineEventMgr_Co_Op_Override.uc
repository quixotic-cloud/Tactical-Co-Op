// This is an Unreal Script
                           
class XComOnlineEventMgr_Co_Op_Override extends XComOnlineEventMgr;

static function bool IsInvitedToCoOp()
{
	local XComOnlineGameSettings lastestInviteSettings;

	lastestInviteSettings=XComOnlineGameSettings(`ONLINEEVENTMGR.m_tAcceptedGameInviteResults[`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.Length-1].GameSettings);
	return(lastestInviteSettings.GetMaxSquadCost()>=2147483647 && lastestInviteSettings.GetTurnTimeSeconds()==3600);
}

static function AddItemToAcceptedInvites(OnlineGameSearchResult InviteResult)
{
	`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.AddItem(InviteResult);
}

static function OnlineGameSearchResult GetLatestInvite()
{
	return `ONLINEEVENTMGR.m_tAcceptedGameInviteResults[`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.Length-1];
}
