//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsWriteDeathmatchRankedGameStartedFlag.uc
//  AUTHOR:  Todd Smith  --  5/26/2012
//  PURPOSE:    Writes the game start flag to the online stats service.
//              Flag is cleared at the end of the match. 
//              Used to detect disconnects: if the player has the flag set next time
//              they start a match then a disconnect will be recorded.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsWriteDeathmatchRankedGameStartedFlag extends XComOnlineStatsWriteDeathmatch;

function UpdateStats(int MatchStarted, int SkillRating, int MatchesWon, int MatchesLost, int Disconnects)
{
	SetIntStat(PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_WON, MatchesWon);
	SetIntStat(PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_LOST, MatchesLost);
	SetIntStat(PROPERTY_MP_DEATHMATCH_RANKED_DISCONNECTS, Disconnects);
	SetIntStat(PROPERTY_MP_DEATHMATCH_RANKED_RATING, SkillRating);
	SetIntStat(PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED, MatchStarted);
}

/**
 * Copies the values from the PRI.
 * NOTE: this must be called after the PRI has been filled out with a StatsReadDeathmatchRanked.
 *
 * @param PRI the replication info to process
 */
function UpdateFromPRI(XComPlayerReplicationInfo PRI)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(PRI.Owner) @ `ShowVar(PlayerController(PRI.Owner).IsLocalPlayerController()), true, 'XCom_Online');

	// NOTE: due to the way PS3 leaderboards work, we must write all the properties -tsmith 
	UpdateStats(1, PRI.m_iRankedDeathmatchSkillRating, PRI.m_iRankedDeathmatchMatchesWon, PRI.m_iRankedDeathmatchMatchesLost, PRI.m_iRankedDeathmatchDisconnects);

	if(PRI.Owner != none && PlayerController(PRI.Owner).IsLocalPlayerController())
	{
		`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "is local player, writing stats to non-volatile memory", true, 'XCom_Online');
		`ONLINEEVENTMGR.FillLastMatchPlayerInfoFromPRI(`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo, PRI);
	}
}

function UpdateFromGameState(XComGameState_Player Player)
{
	local MatchData Data;
	Player.GetMatchData(Data, 'Ranked');
	UpdateStats(1, Data.SkillRating, Data.MatchesWon, Data.MatchesLost, Data.Disconnects);
}

defaultproperties
{
	// The leaderboards the properties are written to
	ViewIds=(STATS_VIEW_DEATHMATCHALLTIMERANKED)

	// These are the stats we are collecting
	// NOTE: due to the way PS3 leaderboards work, we must write all the properties -tsmith 
	Properties(0)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_WON,Data=(Type=SDT_Int32,Value1=-1))
	Properties(1)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_LOST,Data=(Type=SDT_Int32,Value1=-1))
	Properties(2)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_DISCONNECTS,Data=(Type=SDT_Int32,Value1=-1))
	Properties(3)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_RATING,Data=(Type=SDT_Int32,Value1=-1))
	Properties(4)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED,Data=(Type=SDT_Int32,Value1=1))

	RatingId=PROPERTY_MP_DEATHMATCH_RANKED_RATING;
}