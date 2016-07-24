//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsUtils.uc
//  AUTHOR:  Todd Smith  --  11/2/2011
//  PURPOSE: Script class for utilites and data relating to stats . i.e. the ranking algorithm
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsUtils extends XComOnlineStatsUtilsNativeBase;

`include(XComOnlineConstants.uci)

/** Mappings of views and properties to column ID. currently only needed by Steam */
var array<ViewPropertyToColumnId> StatsViewPropertyToColumnIdMap;

/** Mappings of views to leaderboard name. currently only needed by Steam */
var array<ViewIdToLeaderboardName> ViewIdToLeaderboardNameMap;

defaultproperties
{
	StatsViewPropertyToColumnIdMap(0)=(ViewId=STATS_VIEW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_WON, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON);          
	StatsViewPropertyToColumnIdMap(1)=(ViewId=STATS_VIEW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_LOST, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST);
	StatsViewPropertyToColumnIdMap(2)=(ViewId=STATS_VIEW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_DISCONNECTS, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_DISCONNECTED);
	StatsViewPropertyToColumnIdMap(3)=(ViewId=STATS_VIEW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCH_STARTED);
	StatsViewPropertyToColumnIdMap(4)=(ViewId=STATS_VIEW_TEST, PropertyId=PROPERTY_TEST_INT, ColumnId=STATS_COLUMN_TEST_TEST_INT);
	StatsViewPropertyToColumnIdMap(5)=(ViewId=STATS_VIEW_EW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_WON, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_WON);          
	StatsViewPropertyToColumnIdMap(6)=(ViewId=STATS_VIEW_EW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_LOST, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_LOST);
	StatsViewPropertyToColumnIdMap(7)=(ViewId=STATS_VIEW_EW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_DISCONNECTS, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCHES_DISCONNECTED);
	StatsViewPropertyToColumnIdMap(8)=(ViewId=STATS_VIEW_EW_DEATHMATCHALLTIMERANKED, PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED, ColumnId=STATS_COLUMN_DEATHMATCHALLTIMERANKED_MATCH_STARTED);

	ViewIdToLeaderboardNameMap(0)=(ViewId=STATS_VIEW_TEST,LeaderboardName="STATS_VIEW_TEST")
	ViewIdToLeaderboardNameMap(1)=(ViewId=STATS_VIEW_DEATHMATCHALLTIMERANKED,LeaderboardName="STATS_VIEW_DEATHMATCHALLTIMERANKED")
	ViewIdToLeaderboardNameMap(2)=(ViewId=STATS_VIEW_EW_DEATHMATCHALLTIMERANKED,LeaderboardName="STATS_VIEW_EW_DEATHMATCHALLTIMERANKED")
}