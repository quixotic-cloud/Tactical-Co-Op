//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsRead.uc
//  AUTHOR:  Todd Smith  --  9/20/2011
//  PURPOSE: Base class for leaderboard reads
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsRead extends OnlineStatsRead
	abstract;

`include(XComOnlineConstants.uci);

/**
 * Copies the values to the PRI.
 *
 * @param PRI the replication info to process
 */
function UpdateToPRI(XComPlayerReplicationInfo PRI);

/**
 * Returns a string representation of the stats for the given player
 *
 * @param strPlayerName the name of the player
 * @param PlayerId the unique id of the player to look up
 *
 * @return a string representation of the stats for the given player
 */
function string ToString_ForPlayer(string strPlayerName, UniqueNetId PlayerId);