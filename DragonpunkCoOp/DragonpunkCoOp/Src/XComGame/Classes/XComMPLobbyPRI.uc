//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMPLobbyPRI.uc
//  AUTHOR:  Todd Smith  --  3/24/2010
//  PURPOSE: Player Replication Info for the Lobby Players
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComMPLobbyPRI extends XComPlayerReplicationInfo;

var int                                     m_iTotalSquadCost;
var string                                  m_sSquadName;
var privatewrite bool                       m_bPlayerReady;
var privatewrite bool                       m_bPlayerLoaded;

simulated function string ToString()
{
	local string strRep;

	strRep = super.ToString();
	strRep $= "Team=" $ m_eTeam $ "TotalSquadCost=" $ m_iTotalSquadCost $ "PlayerReady=" $ m_bPlayerReady $ "PlayerLoaded=" $ m_bPlayerLoaded $ "SquadName=" $ m_sSquadName $"\n";

	return strRep;
}

simulated function int SumSquadCost(XComGameState_Player PlayerState, XComGameState LoadoutState)
{
	if (PlayerState != none)
	{
		m_iTotalSquadCost = PlayerState.CalcSquadPointValueFromGameState(LoadoutState);
	}
	return m_iTotalSquadCost;
}

simulated function SetPlayerReady(bool bPlayerReady)
{
	m_bPlayerReady = bPlayerReady;
}

simulated function SetPlayerLoaded(bool bPlayerLoaded)
{
	m_bPlayerLoaded = bPlayerLoaded;
}

simulated function SetPlayerLanguageSettings(string strPlayerLanguage, bool bSoldiersUseOwnLanguage)
{
}