//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPData_Common.uc
//  AUTHOR:  Todd Smith  --  7/8/2015
//  PURPOSE: common static data that is used by many systems. game, ui, etc.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPData_Common extends Object
	dependson(X2TacticalGameRulesetDataStructures);

// enum hacks to get around unreal scripts shittyness that doesnt allow constants in one file to be used in static array declarations in another file.
// so we can use EnumName.EnumCount for the array size and then eEnumName_MAX for looping and such. -tsmith 
enum EMPNumUnitsPerSquad
{
	eMPNumUnitsPerSquad_0,
	eMPNumUnitsPerSquad_1,
	eMPNumUnitsPerSquad_2,
	eMPNumUnitsPerSquad_3,
	eMPNumUnitsPerSquad_4,
	eMPNumUnitsPerSquad_5,
};

enum EMPNumHumanPlayers
{
	eMPNumHumanPlayers_0,
	eMPNumHumanPlayers_1,
};

enum EMPGameType
{
	eMPGameType_Deathmatch,
	eMPGameType_Assault,
	eMPGameType_VirtualCheng
};

enum EMPNetworkType
{
	eMPNetworkType_Public,
	eMPNetworkType_Private,
	eMPNetworkType_LAN
};

struct TMPGameSettings
{
	var int                                 m_iMPTurnTimeSeconds;
	var int                                 m_iMPMaxSquadCost;
	var EMPGameType                         m_eMPGameType;
	var EMPNetworkType                      m_eMPNetworkType;
	var bool                                m_bMPIsRanked;
	var int                                 m_iMPMapPlotType;
	var int                                 m_iMPMapBiomeType;
	var name                                m_nmMPMapName;
	var bool                                m_bMPAutomatch;

	structdefaultproperties
	{
		m_iMPTurnTimeSeconds = -1;
		m_iMPMaxSquadCost = -1;
		m_eMPGameType = eMPGameType_Deathmatch;
		m_eMPNetworkType = eMPNetworkType_LAN;
		m_bMPIsRanked = false;
		m_bMPAutomatch = false;
		m_iMPMapPlotType = -2;
		m_iMPMapBiomeType = -2;
	}
};

struct TMPLobbyInfo
{
	var TMPGameSettings m_kGameSettings;
	var bool            m_bLocalPlayerReady;
	var bool            m_bRemotePlayerReady;
};

// These two values should the same as XComOnlineGameSearch
const ANY_VALUE = -2;
const INFINITE_VALUE = -1;


static function GiveSoldierAbilities(XComGameState_Unit Unit, array<name> AbilityNames)
{
	local name AbilityName;
	local SCATProgression Progress;
	local array<SCATProgression> arrProgressions;
	local array<SoldierClassAbilityType> AbilityTree;
	local int i, j;

	foreach AbilityNames(AbilityName)
	{
		for(i = 0; i < Unit.GetSoldierClassTemplate().GetMaxConfiguredRank(); i++)
		{
			AbilityTree = Unit.GetSoldierClassTemplate().GetAbilityTree(i);
			for(j = 0; j < AbilityTree.Length; j++)
			{
				if(AbilityTree[j].AbilityName == AbilityName)
				{
					Progress.iRank = i;
					Progress.iBranch = j;
					arrProgressions.AddItem(Progress);
					break;
				}
			}
		}
	}

	Unit.SetSoldierProgression(arrProgressions);
}

defaultproperties
{
}