//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsWriteDeathmatchClearAllStats.uc
//  AUTHOR:  Todd Smith  --  6/4/2012
//  PURPOSE: Debug only class, used to clear all Deathmatch ranked stats.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsWriteDeathmatchClearAllStats extends XComOnlineStatsWrite;

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