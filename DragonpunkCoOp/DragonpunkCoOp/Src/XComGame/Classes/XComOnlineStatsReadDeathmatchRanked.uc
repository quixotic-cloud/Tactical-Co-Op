//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsReadDeathmatchRanked.uc
//  AUTHOR:  Todd Smith  --  9/20/2011
//  PURPOSE: Leaderboard read for ranked deathmatch 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsReadDeathmatchRanked extends XComOnlineStatsReadDeathmatch;

var bool    m_bWritePRIDataToLastMatchInfo;

/**
 * Copies the values to the PRI.
 *
 * @param PRI the replication info to process
 */
function UpdateToPRI(XComPlayerReplicationInfo PRI)
{
	local int iScore;
	local int iRank;
	local int iDisconnects;


	if(!GetIntStatValueForPlayer(PRI.UniqueId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON, PRI.m_iRankedDeathmatchMatchesWon))
	{
		`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "Stats not found for matches won", true, 'XCom_Online');
		PRI.m_iRankedDeathmatchMatchesWon = 0;
	}
	if(!GetIntStatValueForPlayer(PRI.UniqueId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST, PRI.m_iRankedDeathmatchMatchesLost))
	{
		`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "Stats not found for matches lost", true, 'XCom_Online');
		PRI.m_iRankedDeathmatchMatchesLost = 0;
	}
	iDisconnects = GetDisconnectsForPlayer(PRI.UniqueId);
	if(iDisconnects >= 0)
	{
		PRI.m_iRankedDeathmatchDisconnects = iDisconnects;
	}
	else
	{
		PRI.m_iRankedDeathmatchDisconnects = 0;
	}
	iScore = GetScoreForPlayer(PRI.UniqueId);
	if(iScore <= 0)
	{
		`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "Player score not found, setting to default value of " $ class'XComPlayerReplicationInfo'.default.m_iRankedDeathmatchSkillRating, true, 'XCom_Online');
		iScore = class'XComPlayerReplicationInfo'.default.m_iRankedDeathmatchSkillRating;
	}

	PRI.m_iRankedDeathmatchSkillRating = iScore;
	SetScoreForPlayer(PRI.UniqueId, PRI.m_iRankedDeathmatchSkillRating);

	iRank = GetRankForPlayer(PRI.UniqueId);
	if(iRank == 0)
	{
		`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "Player rank not found", true, 'XCom_Online');
	}
	else
	{
		PRI.m_iRankedDeathmatchRank = iRank;
	}

	PRI.m_bRankedDeathmatchLastMatchStarted = `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_bMatchStarted || (DidPlayerCompleteLastRankedmatch(PRI.UniqueId) > 0);

	if(m_bWritePRIDataToLastMatchInfo)
	{
		`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_bIsRanked = true;
		if(PRI.Owner != none && PlayerController(PRI.Owner).IsLocalPlayerController())
		{
			`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "is local player, writing stats to non-volatile memory" @ `ShowVar(DidPlayerCompleteLastRankedmatch(PRI.UniqueId)), true, 'XCom_Net');		
			if(`ONLINEEVENTMGR.ArePRIStatsNewerThanCachedVersion(PRI))
			{
				`ONLINEEVENTMGR.FillLastMatchPlayerInfoFromPRI(`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo, PRI);
			}
		}
		else
		{
			//`log(self $ "::" $ GetFuncName() @ PRI.PlayerName @ "is remote player, writing stats to non-volatile memory", true, 'XCom_Net');
			// WTF: TODO: we actually need to fill out the remote this info out when it gets replicated from the server, after the seamless travel -tsmith 
			//FillLastMatchPlayerInfoFromPRI(`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kRemotPlayerInfo, PRI);
		}
	}

	`log(self $ "::" $ GetFuncName() @ PRI.ToString(), true, 'XCom_Net');
}

simulated function FillLocalPRIFromLastMatchPlayerInfo(XComPlayerReplicationInfo kLocalPRI, const out TMPLastMatchInfo_Player kLastMatchLocalPlayerInfo)
{
	kLocalPRI.m_iRankedDeathmatchMatchesWon = kLastMatchLocalPlayerInfo.m_iWins;
	kLocalPRI.m_iRankedDeathmatchMatchesLost = kLastMatchLocalPlayerInfo.m_iLosses;
	kLocalPRI.m_iRankedDeathmatchDisconnects = kLastMatchLocalPlayerInfo.m_iDisconnects;
	kLocalPRI.m_iRankedDeathmatchSkillRating = kLastMatchLocalPlayerInfo.m_iSkillRating;
	kLocalPRI.m_iRankedDeathmatchRank = kLastMatchLocalPlayerInfo.m_iRank;
	kLocalPRI.m_bRankedDeathmatchLastMatchStarted = kLastMatchLocalPlayerInfo.m_bMatchStarted;
}

//function bool ArePRIStatsNewerThanCachedVersion(XComPlayerReplicationInfo PRI)
//{
//	local int iPRIStatsSum;
//	local int iCachedStatsSum;
//	local bool bResult;
//	local UniqueNetId kZeroID;

//	bResult = false;
//	`log(self $ "::" $ GetFuncName() @ PRI.ToString() @ "CachedStats=" $ `ONLINEEVENTMGR.TMPLastMatchInfo_Player_ToString(`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo), true, 'XCom_Online');
//	// only want to use cached stats for ourself or if the cache -tsmith 
//	if(PRI.UniqueId == `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_kUniqueID) 
//	{
//		// our stats are always increasing so newer stats will always sum to a larger value -tsmith 
//		iPRIStatsSum = PRI.m_iRankedDeathmatchMatchesWon + PRI.m_iRankedDeathmatchMatchesLost + PRI.m_iRankedDeathmatchDisconnects;
//		iCachedStatsSum = `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iWins + `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iLosses + `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iDisconnects;
//		`log(self $ "::" $  GetFuncName() @ `ShowVar(iPRIStatsSum) @ `ShowVar(iCachedStatsSum), true, 'XCom_Online');
//		bResult = iPRIStatsSum >= iCachedStatsSum;
//	}
//	else
//	{
//		// if the cached stats unique id is empty that means the game has just started running so the PRI stats will definitely be newer. -tsmith 
//		bResult = `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_kUniqueID  == kZeroId;
//	}

//	return bResult;
//}
/**
 * Returns the number of ranked matches won for a given player
 *
 * @param PlayerId the unique id of the player to look up
 * 
 * @return the number of ranked matches won of the given player.
 */
function int GetRankedMatchesWonForPlayer(UniqueNetId PlayerId)
{
	local int iValue;
	iValue = -1;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON, iValue))
	{
		`log(self $ "::" $ GetFuncName() @ "Player:" @ class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerId) @ "Stats not found for matches won, returning -1", true, 'XCom_Online');
	}
	return iValue;
}

/**
 * Returns the number of ranked matches lost for a given player
 *
 * @param PlayerId the unique id of the player to look up
 * 
 * @return the number of ranked matches lost of the given player.
 */
function int GetRankedMatchesLostForPlayer(UniqueNetId PlayerId)
{
	local int iValue;
	iValue = -1;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST, iValue))
	{
		`log(self $ "::" $ GetFuncName() @ "Player:" @ class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerId) @ "Stats not found for matches lost, returning -1", true, 'XCom_Online');
	}
	return iValue;
}

/**
 * Returns the number of disconnects for a given player
 *
 * @param PlayerId the unique id of the player to look up
 * 
 * @return the number of disconnects of the given player.
 */
function int GetDisconnectsForPlayer(UniqueNetId PlayerId)
{
	local int iValue;
	iValue = -1;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_DISCONNECTED, iValue))
	{
		`log(self $ "::" $ GetFuncName() @ "Player:" @ class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerId) @ "Stats not found for matches disconnected, returning -1", true, 'XCom_Online');
	}
	return iValue;
}

/**
 * Returns whether or not the player completed the last ranked match
 * If not then the player disconnected and should be marked as such
 * in the leaderboards/stats.
 *
 * @param PlayerId the unique id of the player to look up
 * 
 * @return -1, stat could not be read. 
 *          0, player completed the last match.
 *          1, player did not complete the last match.
 */
function int DidPlayerCompleteLastRankedmatch(UniqueNetId PlayerId)
{
	local int iValue;
	iValue = -1;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCH_STARTED, iValue))
	{
		`log(self $ "::" $ GetFuncName() @ "Player:" @ class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerId) @ "Stats not found for last match completed, returning -1", true, 'XCom_Online');
	}
	return iValue;
}

/**
 * Returns a string representation of the stats for the given player
 *
 * @param strPlayerName the name of the player
 * @param PlayerId the unique id of the player to look up
 *
 * @return a string representation of the stats for the given player
 */
function string ToString_ForPlayer(string strPlayerName, UniqueNetId PlayerId)
{
	local int iMatchesWon;
	local int iMatchesLost;
	local int iMatchesDisconnected;
	local int iLastMatchStarted;
	local int iScore;
	local int iRank;
	local string strRep;

	strRep = self @ "PlayerName=" $ strPlayerName;
	strRep @= self @ "PlayerUniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerId);
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON, iMatchesWon))
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Stats not found for matches won", true, 'XCom_Online');
	}
	strRep @= "MatchesWon=" $ iMatchesWon;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST, iMatchesLost))
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Stats not found for matches lost", true, 'XCom_Online');
	}
	strRep @= "MatchesLost=" $ iMatchesLost;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_DISCONNECTED, iMatchesDisconnected))
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Stats not found for matches disconnected", true, 'XCom_Online');
	}
	strRep @= "MatchesDisconnected=" $ iMatchesDisconnected;
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCH_STARTED, iLastMatchStarted))
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Stats not found for last match completed", true, 'XCom_Online');
	}
	strRep @= "LastMatchStarted=" $ iLastMatchStarted;

	iScore = GetScoreForPlayer(PlayerId);
	strRep @= "Score=" $ iScore;

	iRank = GetRankForPlayer(PlayerId);
	strRep @= "Rank=" $ iRank;

	return strRep;
}

defaultproperties
{
	// the leaderboard we are reading from -tsmith 
	ViewId=STATS_VIEW_DEATHMATCHALLTIMERANKED

	// the stats we read -tsmith 
	ColumnIds(0)=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON
	ColumnIds(1)=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST
	ColumnIds(2)=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_DISCONNECTED
	ColumnIds(3)=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCH_STARTED

	// The metadata for the columns
	ColumnMappings(0)=(Id=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON,Name="MatchesWon")
	ColumnMappings(1)=(Id=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST,Name="MatchesLost")
	ColumnMappings(2)=(Id=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_DISCONNECTED,Name="MatchesDisconnected")
	ColumnMappings(3)=(Id=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCH_STARTED,Name="MatchStarted")
}
