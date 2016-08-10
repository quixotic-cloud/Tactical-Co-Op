// This is an Unreal Script
                           
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