//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameReplicationInfo.uc
//  AUTHOR:  Todd Smith  --  9/28/2009
//  PURPOSE: Our base game replication info class
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComGameReplicationInfo extends GameReplicationInfo
	dependson(XGGameData)	
	native(Core);

var     /*repnotify*/   XGTacticalGameCore          m_kGameCore;    
var                 XComMPData                  m_kMPData;
var bool                                        m_bOnReceivedGameClassGetNewMPINI;

var class<XComSoundManager> SoundManagerClassToSpawn;
var XComSoundManager SoundManager;

var class<XComGroupedSoundManager> GroupedSoundManagerClassToSpawn;
var XComGroupedSoundManager FlameSoundManager;
var XComGroupedSoundManager AcidSoundManager;
var XComGroupedSoundManager PoisonSoundManager;

var XComAutosaveMgr m_kAutosaveMgr;

//=======================================================================================
//X-Com 2 Refactoring
//
var() XComReplayMgr ReplayMgr;
var() XComGameStateVisualizationMgr VisualizationMgr;

//Support the dropship transition map
var() bool bDropshipLaunch;
//=======================================================================================

enum ESingleAnim
{
	eAnim_None,
	eAnim_Running2NoCoverStart,
	eAnim_Running2CoverLeftStart,
	eAnim_Running2CoverRightStart,
	eAnim_Running2CoverRightHighStop,
	eAnim_Running2CoverLeftHighStop,
	eAnim_Running2CoverLeftLowStop,
	eAnim_Running2CoverRightLowStop,
	eAnim_FlightUp_Start,
	eAnim_FlightUp_Stop,
	eAnim_FlightDown_Start,
	eAnim_FlightDown_Stop,
	eAnim_FlightToggledOn,
	eAnim_FlightToggledOff,
	eAnim_ClimbThruWindow,
	eAnim_BreakWall,
	eAnim_KickDoor,
	eAnim_CallOthers,
	eAnim_SignalEnemyTarget,

	eAnim_ClimbUpGetOnLadder,
	eAnim_ClimbUpLadder,
	eAnim_ClimbUpDrain,
	eAnim_ClimbUpGetOffLadder,
	eAnim_ClimbUpGetOffLadderDropDown,
	eAnim_ClimbDownGetOnLadder,
	eAnim_ClimbDownGetOnLadderClimbOver,
	eAnim_ClimbDownLadder,
	eAnim_ClimbDownDrain,
	eAnim_ClimbDownGetOffLadder,

	eAnim_ClimbUpStart,
	eAnim_ClimbUpLoop,
	eAnim_ClimbUpStop,
	eAnim_ClimbUpStopDropDown,

	eAnim_ChryssalidBirthVomit,

	eAnim_ShotDroneHack,
	eAnim_ShotRepairSHIV,
	eAnim_BullRushStart,

	eAnim_DroneRepair,
	eAnim_ShotOverload,
	eAnim_HotPotatoPickup,
	eAnim_UnderhandGrenade,

	eAnim_UpAlienLiftStart,
	eAnim_UpAlienLiftLoop,
	eAnim_UpAlienLiftStop,
	eAnim_DownAlienLiftStart,
	eAnim_DownAlienLiftLoop,
	eAnim_DownAlienLiftStop,

	eAnim_ArcThrowerStunned,

	eAnim_ZombiePuke,

	eAnim_MutonBloodCall,
	eAnim_MEC_ElectroPulse,
	eAnim_MEC_RestorativeMist,

	eAnim_Strangle,
};

var array<name> AnimMapping;

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated event PostBeginPlay()
{	
	Super.PostBeginPlay();

	SoundManager = Spawn(SoundManagerClassToSpawn, self);
	SoundManager.Init();

	FlameSoundManager = Spawn(GroupedSoundManagerClassToSpawn, self);
	FlameSoundManager.Init(eGroupedSoundType_Fire);

	AcidSoundManager = Spawn(GroupedSoundManagerClassToSpawn, self);
	AcidSoundManager.Init(eGroupedSoundType_Acid);

	PoisonSoundManager = Spawn(GroupedSoundManagerClassToSpawn, self);
	PoisonSoundManager.Init(eGroupedSoundType_Poison);


	m_kAutosaveMgr = Spawn(class'XComAutosaveMgr', self);
	m_kAutosaveMgr.Init();

	`MAPS.PreloadTransitionLevels();
		
	bDropshipLaunch = WorldInfo.GetMapName(false) == `MAPS.GetTransitionMap(); //Set this flag to let additional start up code know that we are in the transition map
}

simulated function StartMatch()
{
	WorldInfo.MyKismetVariableMgr.RebuildVariableMap(); //Streaming levels can include kismet, so rebuild the map here
	WorldInfo.MyKismetVariableMgr.RebuildClassMap();
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'm_kGameCore' && m_kGameCore != none && !m_kGameCore.m_bInitialized)
	{
		m_kGameCore.Init();
		if(m_kMPData != none && !m_kMPData.m_bInitialized)
		{
			m_kMPData.Init();
		}
	}

	super.ReplicatedEvent(VarName);
}

/** Called when the GameClass property is set (at startup for the server, after the variable has been replicated on clients) */
simulated function ReceivedGameClass()
{
	super.ReceivedGameClass();

	if(m_kGameCore == none)
	{
		m_kGameCore = Spawn(class'XGTacticalGameCore', self);
		m_kGameCore.Init();
	}

	if( ReplayMgr == none )
	{
		if( `ONLINEEVENTMGR.bTutorial )
		{
			ReplayMgr = Spawn(class'XComTutorialMgr', self);
			XComTutorialMgr(ReplayMgr).bDemoMode = `ONLINEEVENTMGR.bDemoMode;
			`ONLINEEVENTMGR.bTutorial = false;
		}
		else
		{
			ReplayMgr = Spawn(class'XComReplayMgr', self);
		}
	}
	
	if( VisualizationMgr == none )
	{
		VisualizationMgr = `XCOMGAME.spawn(class'XComGameStateVisualizationMgr', `XCOMGAME);
	}
}

simulated function DoRemoteEvent(name evt, optional bool bRunOnClient)
{
	local PlayerController Controller;

	Controller = GetALocalPlayerController();
	if (Controller != none)
	{
		Controller.RemoteEvent(evt, bRunOnClient);
	}
}

simulated function XComSoundManager GetSoundManager()
{
	return SoundManager;
}

simulated function XComGroupedSoundManager GetAcidSoundManager()
{
	return AcidSoundManager;
}

simulated function XComGroupedSoundManager GetFlameSoundManager()
{
	return FlameSoundManager;
}

simulated function XComGroupedSoundManager GetPoisonSoundManager()
{
	return PoisonSoundManager;
}

simulated function XComAutosaveMgr GetAutosaveMgr()
{
	return m_kAutosaveMgr;
}

defaultproperties
{
	SoundManagerClassToSpawn = class'XComStrategySoundManager'
	GroupedSoundManagerClassToSpawn = class'XComGroupedSoundManager'

	SoundManager = none

	AnimMapping(eAnim_Running2NoCoverStart)=MV_RunFwd_StopStandA
	AnimMapping(eAnim_Running2CoverLeftStart)=HL_Run2CoverA
	AnimMapping(eAnim_Running2CoverRightStart)=HR_Run2CoverA
	AnimMapping(eAnim_Running2CoverRightHighStop)=HR_Run2CoverA
	AnimMapping(eAnim_Running2CoverLeftHighStop)=HL_Run2CoverA
	AnimMapping(eAnim_Running2CoverLeftLowStop)=LL_Run2CoverA
	AnimMapping(eAnim_Running2CoverRightLowStop)=LR_Run2CoverA
	AnimMapping(eAnim_FlightUp_Start)=AC_NO_JetUpAir_StartA
	AnimMapping(eAnim_FlightUp_Stop)=AC_NO_JetUpAir_StopA
	AnimMapping(eAnim_FlightDown_Start)=AC_NO_JetDownAir_StartA
	AnimMapping(eAnim_FlightDown_Stop)=AC_NO_JetDownAir_StopA
	AnimMapping(eAnim_FlightToggledOn)=AC_NO_JetUpGround_StartA
	AnimMapping(eAnim_FlightToggledOff)=AC_NO_JetDownGround_StopA
	AnimMapping(eAnim_ClimbThruWindow)=MV_WindowBreakThroughA
	AnimMapping(eAnim_BreakWall)=AC_NO_BullRushA
	AnimMapping(eAnim_KickDoor)=MV_DoorOpenBreakA
	AnimMapping(eAnim_CallOthers)=HL_CallReinforcementsA
	AnimMapping(eAnim_SignalEnemyTarget)=HL_CallReinforcementsA
	
	AnimMapping(eAnim_ClimbUpGetOnLadder)=MV_ClimbLadderUp_StartA
	AnimMapping(eAnim_ClimbUpLadder)=MV_ClimbLadderUp_LoopA
	AnimMapping(eAnim_ClimbUpDrain)=MV_ClimbPipeUp_LoopA
	AnimMapping(eAnim_ClimbUpGetOffLadder)=MV_ClimbLadderUp_StopA
	AnimMapping(eAnim_ClimbUpGetOffLadderDropDown)=MV_ClimbLadderUp_StopA
	AnimMapping(eAnim_ClimbDownGetOnLadder)=MV_ClimbLadderDwn_StartA
	AnimMapping(eAnim_ClimbDownGetOnLadderClimbOver)=MV_ClimbLadderDwn_StartA
	AnimMapping(eAnim_ClimbDownLadder)=MV_ClimbLadderDwn_LoopA
	AnimMapping(eAnim_ClimbDownDrain)=MV_ClimbPipeDwn_LoopA
	AnimMapping(eAnim_ClimbDownGetOffLadder)=MV_ClimbLadderDwn_StopA
	
	AnimMapping(eAnim_ChryssalidBirthVomit)=HL_DeathA

	AnimMapping(eAnim_ShotDroneHack)=FF_FireA
	AnimMapping(eAnim_ShotRepairSHIV)=FF_FireA
	AnimMapping(eAnim_BullRushStart)=AC_NO_BullRushStartA
	AnimMapping(eAnim_DroneRepair)=AC_NO_HealA

	AnimMapping(eAnim_ShotOverload)=FF_FireA

	AnimMapping(eAnim_ClimbUpStart)=AC_NO_ClimbWallUp_StartA
	AnimMapping(eAnim_ClimbUpLoop)=MV_ClimbWallUp_LoopA
	AnimMapping(eAnim_ClimbUpStop)=AC_NO_ClimbWallUp_StopA
	AnimMapping(eAnim_ClimbUpStopDropDown)=AC_NO_ClimbWallUp_StopB

	AnimMapping(eAnim_HotPotatoPickup)=AC_NO_HotPotatoA
	AnimMapping(eAnim_UnderhandGrenade)=FF_GrenadeLauncherA

	AnimMapping(eAnim_UpAlienLiftStart)=AC_NO_ClimbAlienLiftUp_StartA
	AnimMapping(eAnim_UpAlienLiftLoop)=MV_ClimbAlienLiftUp_LoopA
	AnimMapping(eAnim_UpAlienLiftStop)=AC_NO_ClimbAlienLiftUp_StopA
	AnimMapping(eAnim_DownAlienLiftStart)=AC_NO_ClimbAlienLiftDown_StartA
	AnimMapping(eAnim_DownAlienLiftLoop)=MV_ClimbAlienLiftDown_LoopA
	AnimMapping(eAnim_DownAlienLiftStop)=AC_NO_ClimbAlienLiftDown_StopA


	AnimMapping(eAnim_ArcThrowerStunned)=AC_NO_DeathCollapseA
	AnimMapping(eAnim_ZombiePuke)=AC_NO_PukeA

	AnimMapping(eAnim_MutonBloodCall)=AC_NO_BloodCallA
	AnimMapping(eAnim_MEC_ElectroPulse)=AC_NO_ElectroPulse
	AnimMapping(eAnim_MEC_RestorativeMist)=AC_NO_RestorativeMist

	AnimMapping(eAnim_Strangle)=AC_NO_Strangle_StartA

	m_bOnReceivedGameClassGetNewMPINI=true;
}
