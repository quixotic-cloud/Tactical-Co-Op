//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineStatsUtilsNativeBase.uc
//  AUTHOR:  Todd Smith  --  12/6/2011
//  PURPOSE: Native base clase for utilites and data relating to stats . i.e. the ranking algorithm
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineStatsUtilsNativeBase extends Object
	abstract
	native(Online);

struct native MatchData
{
	var name            MatchType;
	var int				Rank;
	var int             MatchesPlayed;
	var int				MatchesWon;
	var int				MatchesLost;
	var int             MatchesTied;
	var int				Disconnects;
	var int				SkillRating;
	var bool			LastMatchStarted;
};

enum MatchResultType
{
	EOMRT_None,
	EOMRT_Loss,
	EOMRT_Tie,
	EOMRT_Win,
	EOMRT_AbandonedLoss,
	EOMRT_AbandonedWin
};

/**
 * Calculates the new rating of the player based on current rating, opponents rating, and win/loss
 * 
 * @param PlayerData The current rating information of the player.
 * @param OpponentData The opponent player's rating information.
 * @param PlayersMatchResult Did the player win / lose / draw?
 * 
 * @return the new rating of the player.
 */
native static function int CalculateSkillRatingForPlayer(MatchData PlayerData, MatchData OpponentData, MatchResultType PlayersMatchResult);