//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_BattleDataMP.uc
//  AUTHOR:  Timothy Talley  --  08/06/2015
//  PURPOSE: Contains instance configuration information for a Multiplayer Battle
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_BattleDataMP extends XComGameState_BattleData
	native(Core);


// Contains configuration settings for hosting this game online.
var OnlineGameSettings              GameSettings;

var string BizAnalyticsSessionID;

/////////////////////////////////////////////////////////////////////////////////////////
// cpptext

cpptext
{
public: 
	void Serialize(FArchive& Ar);
};

defaultproperties
{
}