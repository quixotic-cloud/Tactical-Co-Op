// This is an Unreal Script
                           
class XComOnlineEventMgr_Co_Op_Override extends XComOnlineEventMgr;

static function bool IsInvitedToCoOp()
{
	local XComOnlineGameSettings lastestInviteSettings;

	lastestInviteSettings=XComOnlineGameSettings(`ONLINEEVENTMGR.m_tAcceptedGameInviteResults[`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.Length-1].GameSettings);
	return(lastestInviteSettings.GetMaxSquadCost()>=5000000 && lastestInviteSettings.GetTurnTimeSeconds()>=3000);
}

static function AddItemToAcceptedInvites(OnlineGameSearchResult InviteResult)
{
	`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.AddItem(InviteResult);
}

static function OnlineGameSearchResult GetLatestInvite()
{
	return `ONLINEEVENTMGR.m_tAcceptedGameInviteResults[`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.Length-1];
}
