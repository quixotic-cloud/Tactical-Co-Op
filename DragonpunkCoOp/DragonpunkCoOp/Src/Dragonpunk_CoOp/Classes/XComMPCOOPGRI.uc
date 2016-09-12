//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComMPCOOPGRI
//  AUTHOR:  Elad Dvash
//  PURPOSE: Game Replication Class for the Co-Op game
//---------------------------------------------------------------------------------------
                           
Class XComMPCOOPGRI extends XComTacticalGRI;

var XComGameState_BattleData m_BattleData;
var bool m_bCallStartMatch;


auto state PendingSetup
{
	simulated function StartMatch()
	{
		super.StartMatch();
	}

Begin:
	while(!`BATTLE.IsInitializationComplete())
	{
		sleep(0.1f);
	}
	if (m_bCallStartMatch)
	{
		global.StartMatch();
	}
	GotoState('FinishedSetup');
}

simulated state FinishedSetup
{
}

simulated function StartMatch()
{
	super.StartMatch();
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function InitBattle()
{
	super.InitBattle();
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function ReceivedGameClass()
{
	ReplayMgr = Spawn(class'XComCoOpReplayMgr', self);

	super.ReceivedGameClass();

	if(m_kMPData == none)
	{
		m_kMPData = new class'XComMPData';
		m_kMPData.Init(); 
	}
}

defaultproperties
{
	m_kPlayerClass = class'XGPlayer';
	m_bCallStartMatch=true;
}

