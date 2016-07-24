//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsWriteDeathmatchClearGameStartedFlagDueToDisconnect.uc
//  AUTHOR:  Todd Smith  --  5/31/2012
//  PURPOSE: Clears the match started flag and records a win for the player 
//           due to other player disconnecting.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsWriteDeathmatchClearGameStartedFlagDueToDisconnect extends XComOnlineStatsWriteDeathmatch;

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
 *
 * @param PRI the replication info to process
 */
function UpdateFromPRI(XComPlayerReplicationInfo PRI)
{
	local XComMPTacticalPRI kOpponentsPRI;

	foreach PRI.DynamicActors(class'XComMPTacticalPRI', kOpponentsPRI)
	{
		if(kOpponentsPRI != PRI)
			break;
	}
	`assert(kOpponentsPRI != none);
	`log(self $ "::" $ GetFuncName() @ "BEFORE:" @ "\nOpponents PRI=" $ kOpponentsPRI.ToString() @ "\nMy PRI=" $ PRI.ToString(), true, 'XCom_Net');
	// NOTE: due to the way PS3 leaderboards work, we must write all the properties -tsmith 
	// clear the match started flag -tsmith 
	`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_bMatchStarted = false;
	PRI.m_bRankedDeathmatchLastMatchStarted = false;
	// NOTE: the player's number of wins prior to this match MUST be set and correct on the this PRI. -tsmith 
	PRI.m_iRankedDeathmatchMatchesWon++;
	UpdateStats(0, PRI.m_iRankedDeathmatchSkillRating, PRI.m_iRankedDeathmatchMatchesWon, PRI.m_iRankedDeathmatchMatchesLost, PRI.m_iRankedDeathmatchDisconnects);
	`log(self $ "::" $ GetFuncName() @ "AFTER:" @ "\nOpponents PRI=" $ kOpponentsPRI.ToString() @ "\nMy PRI=" $ PRI.ToString(), true, 'XCom_Net');
}

function UpdateFromGameState(XComGameState_Player Player)
{
	local MatchData Data;
	Player.GetMatchData(Data, 'Ranked');
	UpdateStats(0, Data.SkillRating, Data.MatchesWon, Data.MatchesLost, Data.Disconnects);
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
	Properties(4)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED,Data=(Type=SDT_Int32,Value1=-1))

	RatingId=PROPERTY_MP_DEATHMATCH_RANKED_RATING;
}