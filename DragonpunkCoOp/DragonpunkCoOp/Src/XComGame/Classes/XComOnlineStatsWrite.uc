//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsWrite.uc
//  AUTHOR:  Todd Smith  --  9/20/2011
//  PURPOSE: Base class for leaderboard writes.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsWrite extends OnlineStatsWrite
	abstract;

`include(XComOnlineConstants.uci);

/**
 * Copies the values from the PRI.
 *
 * @param PRI the replication info to process
 */
function UpdateFromPRI(XComPlayerReplicationInfo PRI);

function UpdateFromGameState(XComGameState_Player Player);

defaultproperties
{
	LeaderboardUpdateType=LUT_Force
}