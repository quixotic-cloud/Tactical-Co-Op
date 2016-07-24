//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGPlayerNativeBase.uc
//  AUTHOR:  Todd Smith  --  2/3/2010
//  PURPOSE: Native base class for the XGPlayer
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XGPlayerNativeBase extends Actor
	native(Core);

struct native XGPlayer_TurnRepData
{
	var int                                             m_iTurn;
	var XGUnit                                          m_kActiveUnit;
	var bool                                            m_bActiveUnitNone;
};

var                              XComTacticalController m_kPlayerController;	// Controller if player controlled
var protected repnotify repretry XGPlayer_TurnRepData   m_kBeginTurnRepData;
var protected repnotify repretry XGPlayer_TurnRepData   m_kEndTurnRepData;
var protected bool                                      m_bClientCheckForEndTurn;

replication
{
	if( bNetOwner && bNetDirty && Role == ROLE_Authority )
		m_kPlayerController;

	if(bNetDirty && Role == ROLE_Authority)
		m_kBeginTurnRepData, m_kEndTurnRepData;
}

static final function string XGPlayer_TurnRepData_ToString(const out XGPlayer_TurnRepData kTurnRepData)
{
	local string strRep;
	strRep = "(m_iTurn=" $ kTurnRepData.m_iTurn;
	strRep $= ", m_kActiveUnit=" $ kTurnRepData.m_kActiveUnit;
	strRep $= ", m_bActiveUnitNone=" $ kTurnRepData.m_bActiveUnitNone;
	if(kTurnRepData.m_kActiveUnit != none)
	{
		strRep $= ", m_kActiveUnit.State=" $ kTurnRepData.m_kActiveUnit.GetStateName();
	}
	strRep $= ")";
	return strRep;
}

simulated event bool FromNativeCheckForEndTurn(XGUnitNativeBase kUnit)
{
	return CheckForEndTurn(XGUnit(kUnit));
}

simulated function bool CheckForEndTurn( XGUnit kUnit);

simulated native function bool IsEnemy(XGPlayerNativeBase kOtherPlayer);
simulated native function bool IsHumanPlayer();
simulated function XGUnit GetActiveUnit();

event XGSquadNativeBase GetNativeSquad();
event XGSquadNativeBase GetEnemySquad();
