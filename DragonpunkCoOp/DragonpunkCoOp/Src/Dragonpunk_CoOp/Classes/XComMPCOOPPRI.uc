//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComMPCOOPPRI
//  AUTHOR:  Elad Dvash
//  PURPOSE: Player Replication Class for the Co-Op game. Not really in use but left in JIC
//---------------------------------------------------------------------------------------
                           
Class XComMPCOOPPRI extends XComPlayerReplicationInfo;

var privatewrite bool                       m_bPlayerReady;
var privatewrite bool                       m_bPlayerLoaded;

simulated function string ToString()
{
	local string strRep;

	strRep = super.ToString();
	strRep $= "Team=" $ m_eTeam $ "PlayerReady=" $ m_bPlayerReady $ "PlayerLoaded=" $ m_bPlayerLoaded $"\n";

	return strRep;
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