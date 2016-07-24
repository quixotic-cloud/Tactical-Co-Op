//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMPTacticalPRI.uc
//  AUTHOR:  Todd Smith  --  4/19/2011
//  PURPOSE: PlayerReplicationInfo for the MPTacticalGame
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComMPTacticalPRI extends XComPlayerReplicationInfo;

var TMPUnitLoadoutReplicationInfo           m_arrUnitLoadouts[EMPNumUnitsPerSquad.EnumCount];
var int                                     m_iTotalSquadCost;
var bool                                    m_bWinner;
var bool                                    m_bDisconnected;
var string                                  m_strLanguage;

struct TMatchEndReplicationInfo
{
	var bool    m_bWinner;
	var bool    m_bRanked;
	var int     m_iRankedMatchesWon;
	var int     m_iRankedMatchesLost;
	var int     m_iNewRankedSkillRating;
	var int     m_iOldOpponentsRankedSkillRating;
};

var repnotify TMatchEndReplicationInfo      m_kWonMatchReplicationInfo;
var repnotify TMatchEndReplicationInfo      m_kLostMatchReplicationInfo;

struct TRankedDeathmatchMatchStartedReplicationInfo
{
	var int                                     m_iRankedDeathmatchMatchesWon;
	var int                                     m_iRankedDeathmatchMatchesLost;
	var int                                     m_iRankedDeathmatchDisconnects;
	var int                                     m_iRankedDeathmatchSkillRating;
	var int                                     m_iRankedDeathmatchRank;
	var bool                                    m_bRankedDeathmatchLastMatchStarted;
	var bool                                    m_bRankedDeathmatchReplicationInfoFlipFlop;
};

var repnotify TRankedDeathmatchMatchStartedReplicationInfo  m_kRankedDeathmatchMatchStartedReplicationInfo;
var privatewrite bool                                       m_bRankedDeathmatchMatchStartedReplicationInfoReceived;

replication
{
	if(bNetDirty && Role == ROLE_Authority)
		m_arrUnitLoadouts, m_iTotalSquadCost, m_kWonMatchReplicationInfo, m_kLostMatchReplicationInfo, m_strLanguage;

	if(bNetOwner && bNetDirty && Role == ROLE_Authority)
		m_kRankedDeathmatchMatchStartedReplicationInfo;
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'm_kWonMatchReplicationInfo')
	{
		UnpackMatchEndReplicationInfo(m_kWonMatchReplicationInfo);
		`assert(m_bWinner);
		WonMatch(m_kWonMatchReplicationInfo.m_bRanked, m_kWonMatchReplicationInfo.m_iOldOpponentsRankedSkillRating);
	}
	else if(VarName == 'm_kLostMatchReplicationInfo')
	{
		UnpackMatchEndReplicationInfo(m_kLostMatchReplicationInfo);
		`assert(!m_bWinner);
		LostMatch(m_kLostMatchReplicationInfo.m_bRanked, m_kLostMatchReplicationInfo.m_iOldOpponentsRankedSkillRating);
	}
	else if(VarName == 'm_kRankedDeathmatchMatchStartedReplicationInfo' && !m_bRankedDeathmatchMatchStartedReplicationInfoReceived)
	{
		m_iRankedDeathmatchMatchesWon = m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchMatchesWon;
		m_iRankedDeathmatchMatchesLost = m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchMatchesLost;
		m_iRankedDeathmatchDisconnects = m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchDisconnects;
		m_iRankedDeathmatchSkillRating = m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchSkillRating;
		m_iRankedDeathmatchRank = m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchRank;
		m_bRankedDeathmatchLastMatchStarted = m_kRankedDeathmatchMatchStartedReplicationInfo.m_bRankedDeathmatchLastMatchStarted;
		m_bRankedDeathmatchMatchStartedReplicationInfoReceived = true;
		if(Owner != none)
		{
			XComMPTacticalController(Owner).PlayerReplicationInfo = self;
		}

		`log(self $ "::" $ GetFuncName() @ `ShowVar(VarName), true, 'XCom_Net');
	}

	super.ReplicatedEvent(VarName);
}

simulated function UnpackMatchEndReplicationInfo(const out TMatchEndReplicationInfo kMatchEndRepInfo)
{
	m_bWinner = kMatchEndRepInfo.m_bWinner;
	m_iRankedDeathmatchMatchesWon = kMatchEndRepInfo.m_iRankedMatchesWon;
	m_iRankedDeathmatchMatchesLost = kMatchEndRepInfo.m_iRankedMatchesLost;
	m_iRankedDeathmatchSkillRating = kMatchEndRepInfo.m_iNewRankedSkillRating;
}

simulated function PackMatchEndReplicationInfo(out TMatchEndReplicationInfo kMatchEndRepInfo, bool bRanked, int iOldOpponentsRankedSkillRating)
{
	kMatchEndRepInfo.m_bWinner = m_bWinner;
	kMatchEndRepInfo.m_bRanked = bRanked;
	kMatchEndRepInfo.m_iRankedMatchesWon = m_iRankedDeathmatchMatchesWon;
	kMatchEndRepInfo.m_iRankedMatchesLost = m_iRankedDeathmatchMatchesLost;
	kMatchEndRepInfo.m_iNewRankedSkillRating = m_iRankedDeathmatchSkillRating;
	kMatchEndRepInfo.m_iOldOpponentsRankedSkillRating = iOldOpponentsRankedSkillRating;
}

simulated function WonMatch(bool bRankedMatch, int iOldLosersRankedSkillRating)
{
	if(Role == ROLE_Authority)
	{
		m_bWinner = true;
		if(bRankedMatch)
		{
			m_iRankedDeathmatchMatchesWon++;
			//m_iRankedDeathmatchSkillRating = class'XComOnlineStatsUtils'.static.CalculateSkillRatingForPlayer(m_iRankedDeathmatchSkillRating, iOldLosersRankedSkillRating, true);
		}

		PackMatchEndReplicationInfo(m_kWonMatchReplicationInfo, bRankedMatch, iOldLosersRankedSkillRating);
	}

	if(GetALocalPlayerController().PlayerReplicationInfo == self)
	{
		// no achievement given if a disconnect occured. -tsmith 
		`log(self $ "::" $ GetFuncName() @ 
			`ShowVar(XComMPTacticalController(GetALocalPlayerController()).m_bConnectionFailedDuringGame) @ 
			`ShowVar(`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay), true, 'XCom_Online');

		if(!XComMPTacticalController(GetALocalPlayerController()).m_bConnectionFailedDuringGame && !`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay)
		{
			`log(self $ "::" $ GetFuncName() @ "Unlocking the MeetNewPeople achievement", true, 'XCom_Online');
			ScriptTrace();
			`ONLINEEVENTMGR.UnlockAchievement(AT_WinMultiplayerMatch); // Win an online match! 
		}
	}
	if (XComMPTacticalController(Owner) != none)
	{
		XComMPTacticalController(Owner).m_XGPlayer.GotoState('GameOver');
	}
}

simulated function LostMatch(bool bRankedMatch, int iOldWinnersRankedSkillRating)
{
	if(Role == ROLE_Authority)
	{
		m_bWinner = false;
		if(bRankedMatch)
		{
			m_iRankedDeathmatchMatchesLost++;
			//m_iRankedDeathmatchSkillRating = class'XComOnlineStatsUtils'.static.CalculateSkillRatingForPlayer(m_iRankedDeathmatchSkillRating, iOldWinnersRankedSkillRating, false);
		}

		PackMatchEndReplicationInfo(m_kLostMatchReplicationInfo, bRankedMatch, iOldWinnersRankedSkillRating);
	}

	if (XComMPTacticalController(Owner) != none)
	{
		XComMPTacticalController(Owner).m_XGPlayer.GotoState('GameOver');
	}
}

/* epic ===============================================
* ::ClientInitialize
*
* Called by Controller when its PlayerReplicationInfo is initially replicated.
* Now that
*
* =====================================================
*/
simulated function ClientInitialize(Controller C)
{
	super.ClientInitialize(C);
}

simulated function string ToString()
{
	local string strRep;
	
	strRep = super.ToString();
	strRep @= "RankedDeathmatchMatchStartedReplicationInfo:\n";
	strRep @= "     RankedDeathmatchMatchesWon=" $ m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchMatchesWon $ "\n";
	strRep @= "     RankedDeathmatchMatchesLost=" $ m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchMatchesLost $ "\n";
	strRep @= "     RankedDeathmatchDisconnects=" $ m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchDisconnects $ "\n";
	strRep @= "     RankedDeathmatchSkillRating=" $ m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchSkillRating $ "\n";
	strRep @= "     RankedDeathmatchRank=" $ m_kRankedDeathmatchMatchStartedReplicationInfo.m_iRankedDeathmatchRank $ "\n";
	strRep @= "     RankedDeathmatchLastMatchStarted=" $ m_kRankedDeathmatchMatchStartedReplicationInfo.m_bRankedDeathmatchLastMatchStarted $ "\n";
	strRep @= "     RankedDeathmatchReplicationInfoReceived=" $ m_bRankedDeathmatchMatchStartedReplicationInfoReceived $ "\n";
	strRep @= "     m_strLanguage=" $ m_strLanguage;

	return strRep;
}
