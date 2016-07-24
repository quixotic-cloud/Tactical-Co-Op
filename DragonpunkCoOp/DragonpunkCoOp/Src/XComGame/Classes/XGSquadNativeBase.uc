//
// native base class
// Author - Mustafa Thamer, 3/19/09
// Copyright 2009 Firaxis Games
// FIRAXIS SOURCE CODE
//

class XGSquadNativeBase extends Actor
	native(Unit);

const MaxUnitCount = 128;

var protected repnotify XGUnit			m_arrPermanentMembers[MaxUnitCount];
var protected repnotify int 			m_iNumPermanentUnits;		// for MP
var protected int 			            m_iNumCloseUnits;           // Number of units currently in "close encounters"
var protected string			        m_strName;
var protected string			        m_strMotto;
var protected color				        m_clrColors;
var public XGPlayer			            m_kPlayer;
var protected int                       m_iCloseCombatInit; // Keeps track of units who still had time prior to CC.
var protected repnotify XGUnit			m_arrUnits[MaxUnitCount];
var protected repnotify int 			m_iNumUnits;		        // for MP
var private int                         m_iLeader;

simulated event int GetNumMembers()
{
	return m_iNumUnits;
}

simulated event XGUnit GetMemberAt( int iIndex )
{
	return m_arrUnits[iIndex];
}

native simulated function int GetNumDead();
native simulated function int GetNumDeadOrCriticallyWounded();
native simulated function int GetNumAliveAndWell();
native simulated function int GetNumOnMap();
native simulated function bool SquadCanSeeEnemy(XGUnit kEnemy);
native simulated function bool SquadHasStarOfTerra(bool PowerA);

simulated native function XGUnit GetSquadLeader();
native function SetSquadLeader( int iNewLeaderIndex );

replication
{
	if( bNetDirty && Role == ROLE_Authority )
		m_arrUnits, m_arrPermanentMembers, m_iNumUnits, m_iNumPermanentUnits, m_iNumCloseUnits, m_strName,
		m_strMotto, m_clrColors, m_kPlayer, m_iCloseCombatInit, m_iLeader;
}