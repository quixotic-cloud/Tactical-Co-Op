//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsWriteDeathmatchRanked.uc
//  AUTHOR:  Todd Smith  --  9/20/2011
//  PURPOSE: Leaderboard write for ranked deathmatch
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsWriteDeathmatchRanked extends XComOnlineStatsWriteDeathmatch;


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
	local XComMPTacticalGRI kGRI;
	local XComMPTacticalPRI kPRI;

	kGRI = XComMPTacticalGRI(PRI.WorldInfo.GRI);
	`assert(kGRI != none);
	kPRI = XComMPTacticalPRI(PRI);
	`assert(kPRI != none);

	`log(self $ "::" $ GetFuncName() @ `ShowVar(kGRI.m_kWinningPRI) @ `ShowVar(kPRI) @ kPRI.ToString(), true, 'XCom_Online');
	if(kGRI.m_kWinningPRI != none)
	{
		if(kGRI.m_kWinningPRI == kPRI)
		{
			`log(self $ "::" $ GetFuncName() @ "Writing" @ kPRI.PlayerName @ "as the WINNER", true, 'XCom_Online');
		}
		else
		{
			`log(self $ "::" $ GetFuncName() @ "Writing" @ kPRI.PlayerName @ "as the LOSER", true, 'XCom_Online');
		}
	}
	// match has finished so clear the game started flag. -tsmith 
	kPRI.m_bRankedDeathmatchLastMatchStarted = false;

	UpdateStats(0, PRI.m_iRankedDeathmatchSkillRating, PRI.m_iRankedDeathmatchMatchesWon, PRI.m_iRankedDeathmatchMatchesLost, PRI.m_iRankedDeathmatchDisconnects);

	if(PRI.Owner != none && PlayerController(PRI.Owner).IsLocalPlayerController())
	{
		`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "is local player, writing stats to non-volatile memory", true, 'XCom_Net');		
		`ONLINEEVENTMGR.FillLastMatchPlayerInfoFromPRI(`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo, PRI);
	}
}

function UpdateFromGameState(XComGameState_Player Player)
{
	local MatchData Data;
	Player.GetMatchData(Data, 'Ranked');
	UpdateStats(0, Data.SkillRating, Data.MatchesWon, Data.MatchesLost, Data.Disconnects);
}

defaultproperties
{
	ViewIds=(STATS_VIEW_DEATHMATCHALLTIMERANKED)

	// These are the stats we are collecting
	Properties(0)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_WON,Data=(Type=SDT_Int32,Value1=0))
	Properties(1)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_LOST,Data=(Type=SDT_Int32,Value1=0))
	Properties(2)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_DISCONNECTS,Data=(Type=SDT_Int32,Value1=0))
	Properties(3)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_RATING,Data=(Type=SDT_Int32,Value1=0))
	Properties(4)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED,Data=(Type=SDT_Int32,Value1=0))

	RatingId=PROPERTY_MP_DEATHMATCH_RANKED_RATING;
}