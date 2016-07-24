//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComPlayerReplicationInfo.uc
//  AUTHOR:  Todd Smith  --  9/21/2011
//  PURPOSE: Base class for our player replication infos.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComPlayerReplicationInfo extends PlayerReplicationInfo;

var int                                     m_iRankedDeathmatchMatchesWon;
var int                                     m_iRankedDeathmatchMatchesLost;
var int                                     m_iRankedDeathmatchDisconnects;
var int                                     m_iRankedDeathmatchSkillRating;
var int                                     m_iRankedDeathmatchRank;
/** flag signaling if the previous match started but did not finish, if set then this player gets # of disconnects incrmemented */
var bool                                    m_bRankedDeathmatchLastMatchStarted;

replication
{
	if(bNetDirty && Role == ROLE_Authority)
		m_iRankedDeathmatchMatchesWon, m_iRankedDeathmatchMatchesLost, m_iRankedDeathmatchDisconnects, m_iRankedDeathmatchSkillRating, m_iRankedDeathmatchRank, m_bRankedDeathmatchLastMatchStarted;
}

simulated function string ToString()
{
	local string strRep;

	strRep = "" $ self $ "\n";
	strRep @= "Player=" $ PlayerName $ "\n";
	strRep @= "RankedDeathmatchMatchesWon=" $ m_iRankedDeathmatchMatchesWon $ "\n";
	strRep @= "RankedDeathmatchMatchesLost=" $ m_iRankedDeathmatchMatchesLost $ "\n";
	strRep @= "RankedDeathmatchDisconnects=" $ m_iRankedDeathmatchDisconnects $ "\n";
	strRep @= "RankedDeathmatchSkillRating=" $ m_iRankedDeathmatchSkillRating $ "\n";
	strRep @= "RankedDeathmatchRank=" $ m_iRankedDeathmatchRank $ "\n";
	strRep @= "RankedDeathmatchLastMatchStarted=" $ m_bRankedDeathmatchLastMatchStarted $ "\n";

	return strRep;
}

defaultproperties
{
	m_iRankedDeathmatchSkillRating=1200
}