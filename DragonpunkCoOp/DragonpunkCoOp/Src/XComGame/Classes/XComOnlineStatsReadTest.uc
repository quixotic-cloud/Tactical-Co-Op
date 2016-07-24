//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsReadTest.uc
//  AUTHOR:  Todd Smith  --  12/7/2011
//  PURPOSE: Stats read class ONLY used for development testing
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsReadTest extends XComOnlineStatsRead;

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
	local string strRep;
	local int iTestInt;
	local int iScore;
	local int iRank;

	strRep = self @ "Player=" $ strPlayerName;
	strRep @= self @ "PlayerUniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerId);
	if(!GetIntStatValueForPlayer(PlayerId, STATS_COLUMN_TEST_TEST_INT, iTestInt))
	{
		`warn(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Stats not found for TEST_INT");
	}
	iScore = GetScoreForPlayer(PlayerId);
	if(iScore == 0)
	{
		`warn(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Player score not found");
		iScore = -1;
	}
	iRank = GetRankForPlayer(PlayerId);
	if(iRank == 0)
	{
		`warn(self $ "::" $ GetFuncName() @ `ShowVar(strPlayerName) @ "Player rank not found");
		iRank = -1;
	}

	strRep @= self @ strPlayerName @ "TestInt=" $ iTestInt $ ", Score=" $ iScore $ ", Rank=" $ iRank;

	return strRep;
}

defaultproperties
{
	// the leaderboard we are reading from -tsmith 
	ViewId=STATS_VIEW_TEST

	// the stats we read -tsmith 
	ColumnIds(0)=STATS_COLUMN_TEST_TEST_INT

	// The metadata for the columns
	ColumnMappings(0)=(Id=STATS_COLUMN_TEST_TEST_INT,Name="TestInt")
}
