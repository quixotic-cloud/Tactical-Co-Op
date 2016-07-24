//---------------------------------------------------------------------------------------
//  FILE:    X2AchievementData.uc
//  AUTHOR:  Aaron Smith -- 8/14/2015
//  PURPOSE: Game state for tracking achievements whose conditions have to be
//           met in the same game, which needs to be preserved during save / load.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_AchievementData extends XComGameState_BaseObject 
	native(Core);
	
// Stored for achievement: AT_TripleKill	
struct native UnitKills
{	var int		UnitId;
	var int		NumKills;
};
var array<UnitKills> arrKillsPerUnitThisTurn;

// Stored for achievement: AT_Ambush
var array<int> arrUnitsKilledThisTurn;
var array<int> arrRevealedUnitsThisTurn;	

// Stored for achievement: AT_RecoverCodexBrain
var bool bKilledACyberusThisMission;

