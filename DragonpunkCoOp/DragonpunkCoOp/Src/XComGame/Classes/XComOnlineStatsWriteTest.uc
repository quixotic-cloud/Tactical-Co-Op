//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsWriteTest.uc
//  AUTHOR:  Todd Smith  --  12/7/2011
//  PURPOSE: Stats class file ONLY used for development testing
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsWriteTest extends XComOnlineStatsWrite;

simulated function InitOnlineStatsWriteTest(int iTestInt, int iTestRating)
{
	SetIntStat(PROPERTY_TEST_INT, iTestInt);
	SetIntStat(PROPERTY_TEST_RATING, iTestRating);
}

defaultproperties
{
	// The leaderboards the properties are written to
	ViewIds=(STATS_VIEW_TEST)

	// These are the stats we are collecting
	Properties(0)=(PropertyId=PROPERTY_TEST_INT,Data=(Type=SDT_Int32,Value1=0))
	Properties(1)=(PropertyId=PROPERTY_TEST_RATING,Data=(Type=SDT_Int32,Value1=0))

	RatingId=PROPERTY_TEST_RATING
}
