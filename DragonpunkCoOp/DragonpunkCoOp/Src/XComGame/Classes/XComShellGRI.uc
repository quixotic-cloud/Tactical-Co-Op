//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComShellGRI.uc
//  AUTHOR:  Todd Smith  --  3/16/2011
//  PURPOSE: Game replication info for the shell
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComShellGRI extends XComTacticalGRI;

var EMPNetworkType              m_eMPNetworkType;
var EMPGameType                 m_eMPGameType;
var int	                        m_iMPMapPlotType;
var int                         m_iMPMapBiomeType;
var int                         m_iMPTurnTimeSeconds;
var int                         m_iMPMaxSquadCost;
var bool                        m_bMPIsRanked;
var bool                        m_bMPAutomatch;

function ResetToDefaults()
{
	m_eMPNetworkType = default.m_eMPNetworkType;
	m_eMPGameType = default.m_eMPGameType;
	m_iMPMapPlotType = default.m_iMPMapPlotType;
	m_iMPMapBiomeType = default.m_iMPMapBiomeType;
	m_iMPTurnTimeSeconds = default.m_iMPTurnTimeSeconds;
	m_iMPMaxSquadCost = default.m_iMPMaxSquadCost;
	m_bMPIsRanked = default.m_bMPIsRanked;
	m_bMPAutomatch = default.m_bMPAutomatch;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);
}

function SetMPMapPlotIndex(int iMapPlotType)
{
	m_iMPMapPlotType = iMapPlotType;
}

function SetMPMapBiomeIndex(int iMapBiomeType)
{
	m_iMPMapBiomeType = iMapBiomeType;
}

function int GetSquadCostMax()
{
	local int iMaxVal, iVal;
	foreach m_kMPData.m_arrMaxSquadCosts(iVal)
	{
		iMaxVal = Max(iMaxVal, iVal);
	}
	return iMaxVal;
}

function int GetTurnTimerMax()
{
	local int iMaxVal, iVal;
	foreach m_kMPData.m_arrTurnTimers(iVal)
	{
		iMaxVal = Max(iMaxVal, iVal);
	}
	return iMaxVal;
}

function int GetMPMapPlotIndex()
{
	local int iMaxVal, iMapIdx;
	for (iMapIdx = 0; iMapIdx < m_kMPData.m_arrMaps.Length; ++iMapIdx)
	{
		iMaxVal = Max(iMaxVal, m_kMPData.m_arrMaps[iMapIdx].m_iMapNameIndex);
	}
	return iMaxVal;
}

function int GetMPMapBiomeIndex()
{
	local int iMaxVal, iMapIdx;
	for (iMapIdx = 0; iMapIdx < m_kMPData.m_arrMaps.Length; ++iMapIdx)
	{
		iMaxVal = Max(iMaxVal, m_kMPData.m_arrMaps[iMapIdx].m_iMapNameIndex);
	}
	return iMaxVal;
}

defaultproperties
{
	m_eMPNetworkType=eMPNetworkType_Public
	m_eMPGameType=eMPGameType_Deathmatch
	m_iMPTurnTimeSeconds=120
	m_iMPMaxSquadCost=10000
}
