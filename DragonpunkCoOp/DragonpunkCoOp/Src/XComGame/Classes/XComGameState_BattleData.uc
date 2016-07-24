//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Player.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: This object represents the instance data for a tactical battle of X-Com.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_BattleData extends XComGameState_BaseObject 
	dependson(XComParcelManager, XComPlotCoverParcelManager) 
	native(Core)
	config(GameData);

enum PlotSelectionEnum
{
	ePlotSelection_Random,
	ePlotSelection_Type,
	ePlotSelection_Specify
};

struct native DirectTransferInformation_UnitStats
{
	var StateObjectReference UnitStateRef;
	var float                HP; // amount of HP this unit had before the transfer
	var int                  ArmorShred; // amount armor that was shredded on this unit before the transfer
	var int					 LowestHP; // for injuries, needs to be tracked across all parts of a mission
	var int					 HighestHP; // for injuries, needs to be tracked across all parts of a mission

	structcpptext
	{
		FDirectTransferInformation_UnitStats()
		{
			appMemzero(this, sizeof(FDirectTransferInformation_UnitStats));
		}
		FDirectTransferInformation_UnitStats(EEventParm)
		{
			appMemzero(this, sizeof(FDirectTransferInformation_UnitStats));
		}
	}
};

// This structure (and it's substructures) are intended to pass extra information along when doing a
// direct mission->mission tactical transfer. Since many gamestates are destroyed permanently when
// leaving a tactical mission, there will be various values that should be manually tracked at
// the end of each mission, such as transferred unit stats and aliens killed
struct native DirectTransferInformation
{
	var bool IsDirectMissionTransfer; // true if this battle data is being transferred over from another mission directly
	var array<DirectTransferInformation_UnitStats> TransferredUnitStats;

	// to allow us to correctly talley the number of units killed/seen at the end of the mission,
	// keep track of what has happened in the previous parts of the mission. Ideally we'd be keeping
	// all of the state information for these units along for the ride as well, but I don't think we have the
	// time to ensure that I don't accidentally break something doing that. So for now (DLC3), doing it the
	// safe way
	var int AliensSeen;
	var int AliensKilled;

	structcpptext
	{
		FDirectTransferInformation()
		{
			appMemzero(this, sizeof(FDirectTransferInformation));
		}
		FDirectTransferInformation(EEventParm)
		{
			appMemzero(this, sizeof(FDirectTransferInformation));
		}
	}
};

//RAM - copied from XGBattleDesc
//------------STRATEGY GAME DATA -----------------------------------------------
// ------- Please no touchie ---------------------------------------------------
var() string						m_strLocation;          // The city and country where this mission is taking place
var() string						m_strOpName;            // Operation name
var() string						m_strObjective;         // Squad objective
var() string						m_strDesc;              // Type of mission string
var() string						m_strTime;              // Time of Day string
var() int							m_iMissionID;           // Mission ID in the strategy layer
var() int							m_iMissionType;         // CHENG - eMission_TerrorSite
var() EShipType						m_eUFOType;
var() EContinent					m_eContinent;
var() ETOD							m_eTimeOfDay;
var() bool							m_bOvermindEnabled;
var() bool							m_bIsFirstMission;      // Is this the player's very first mission?
var() bool							m_bIsTutorial;          // Is this the tutorial
var() bool							m_bDisableSoldierChatter; // Disable Soldier Chatter
var() bool							m_bIsIronman;           // Is the player in Ironman mode?
var() bool							m_bScripted;            // Is this mission the scripted first mission?
var() float							m_fMatchDuration;
var() array<int>					m_arrSecondWave;
var() int							m_iPlayCount;
var() bool							m_bSilenceNewbieMoments;
var() bool							bIsTacticalQuickLaunch; //Flag set to true if this is a tactical battle that was started via TQL
var() TDateTime						LocalTime;			    //The local time at the mission site

//RAM - these are legacy from EU/EW
var() string						m_strMapCommand;        // Name of map

//Used by the tactical quick launch process to pick a map
var PlotSelectionEnum               PlotSelectionType;
var string                          PlotType;

// A list of unit state objects being treated as "rewards" for the mission
var() array<StateObjectReference>   RewardUnits;

// A list of the original units that the reward unit proxies were created from.
// Not for use in tactical, it simply maintains the links to the reward proxies so that
// we can sync them up after the mission.
var() array<StateObjectReference>   RewardUnitOriginals;

//Saved data describing the layout of the level
var() PlotDefinition				PlotData; //Backwards compatibility
var() StoredMapData					MapData;

//Temporary variable for save load of the parcel system. Eventually we need to replace this with a parcel state object.
var() int							iLevelSeed;
var() int							iFirstStartTurnSeed;    // Specified Seed for whenever the map is done loading and the first turn is about to be taken.
var() bool							bUseFirstStartTurnSeed; // If set, will set the engine's random seed with the specified iFirstStartTurnSeed after the map has been loaded or generated.

//From profile/shell
var() int							m_iSubObjective;
var() name 							m_nQuestItem;
var() int							m_iLayer;
var() privatewrite int				m_iForceLevel;
var() privatewrite int				m_iAlertLevel;
var() privatewrite int				m_iPopularSupport;
var() privatewrite int				m_iMaxPopularSupport;

// The tactical gameplay events affecting Alert/Popular support levels
var() array<Name>					AlertEventIDs;
var() array<Name>					PopularSupportEventIDs;

var() StateObjectReference			CivilianPlayerRef;

var() bool							bRainIfPossible;	// Rain if the map supports rain
//------------------------------------------------------------------------------
//------------END STRATEGY GAME DATA -------------------------------------------

var() bool							bIntendedForReloadLevel; //variable that gets checked so that we know if we want to create a new game, or load one instead when restarting a match
var() DirectTransferInformation     DirectTransferInfo; // data used to facilitate direct mission->mission transfer carryover

//These variables deal with controlling the flow of the Unit Actions turn phase
var() array<StateObjectReference>   PlayerTurnOrder;	 //Indicates the order in which the players take the unit actions phase of their turn
var() private array<name>           AllowedAbilities;	 //Some abilities must be enabled by kismet. That is tracked here.
var() private array<name>           DisallowedAbilities; //Some abilities can be disabled by kismet. That is tracked here.
var() private array<name>           HighlightedObjectiveAbilities; //Abilities which have been flagged by kismet to show with a green background
var() bool                          bMissionAborted;	 //If Abort Mission ability is used, this will be set true.
var() bool                          bLocalPlayerWon;     //Set true during BuildTacticalGameEndGameState if the victorious player is XCom / Local Player
var() StateObjectReference          VictoriousPlayer;    //Set to the player who won the match

// The bucket of loot that will be awarded to the XCom player if they successfully complete all tactical mission objectives on this mission.
var() array<Name>					AutoLootBucket;

// The bucket of loot that was carried out of the mission by XCom soldiers.
var() array<Name>					CarriedOutLootBucket;


// The list of all unique once-per-mission hack rewards that have already been acquired this mission.
var() array<Name>					UniqueHackRewardsAcquired;

// The list of the tactical hack rewards that are available to be acquired this mission.
var() array<Name>					TacticalHackRewards;

// The list of the strategy hack rewards that are available to be acquired this mission.
var() array<Name>					StrategyHackRewards;

// True if a tactical hack has already been completed for this battle.
var() bool							bTacticalHackCompleted;

// Great Mission and tough mission bool for after action and reward recap VO
var() bool bGreatMission;
var() bool bToughMission;

var() int iMaxSquadCost;
var() int iTurnTimeSeconds;
var() bool bMultiplayer;
var() bool bRanked;
var() bool bAutomatch;
var() string strMapType;

var string BizAnalyticsMissionID;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

final function ResetObjectiveCompletionStatus()
{
	local int ObjectiveIndex;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted = false;
	}
}

final function CompleteObjective(Name ObjectiveName)
{
	local int ObjectiveIndex;
	local Object ThisObj;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].ObjectiveName == ObjectiveName )
		{
			MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted = true;
		}
	}
	ThisObj = self;
	`XEVENTMGR.TriggerEvent('OnMissionObjectiveComplete', ThisObj, ThisObj);
}

final function bool AllTacticalObjectivesCompleted()
{
	local int ObjectiveIndex;
	local bool AnyTacticalObjectives;

	AnyTacticalObjectives = false;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsTacticalObjective )
		{
			if( !MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
			{
				return false;
			}

			AnyTacticalObjectives = true;
		}
	}

	return AnyTacticalObjectives;
}

final function bool AllStrategyObjectivesCompleted()
{
	local int ObjectiveIndex;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsStrategyObjective && !MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
		{
			return false;
		}
	}

	return true;
}

final function bool OneStrategyObjectiveCompleted()
{
	local int ObjectiveIndex;

	for(ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex)
	{
		if(MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsStrategyObjective && MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted)
		{
			return true;
		}
	}

	return false;
}

final function bool AllTriadObjectivesCompleted()
{
	local int ObjectiveIndex;

	for( ObjectiveIndex = 0; ObjectiveIndex < MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bIsTriadObjective && !MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
		{
			return false;
		}
	}

	return true;
}


function SetForceLevel(int NewForceLevel)
{
	m_iForceLevel = NewForceLevel;
}

function SetAlertLevel(int NewAlertLevel)
{
	m_iAlertLevel = NewAlertLevel;
}

function SetPopularSupport( int NewPopVal )
{
	m_iPopularSupport = NewPopVal;
}

function int GetPopularSupport()
{
	return m_iPopularSupport;
}

function SetMaxPopularSupport( int NewMaxPopVal )
{
	m_iMaxPopularSupport = NewMaxPopVal;
}

function int GetMaxPopularSupport()
{
	return m_iMaxPopularSupport;
}

native function int GetForceLevel();
native function int GetAlertLevel();

native function bool AlertLevelThresholdReached(int Threshold);
native function bool AlertLevelSupportsPCPCheckpoints();
native function bool AlertLevelSupportsPCPTurrets();
native function bool AlertLevelSupportsAlienSpawnAdvantage();

native function bool AreCiviliansAlienTargets();
native function bool AreCiviliansAlwaysVisible();
native function bool CiviliansAreHostile();

static function bool SetGlobalAbilityEnabled(name AbilityName, bool Enabled, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2AbilityTemplateManager AbilityMan;
	local XComGameState_BattleData BattleData;
	local X2TacticalGameRuleset Rules; 
	local bool SubmitState;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	if(AbilityMan.FindAbilityTemplate(AbilityName) == none)
	{
		return false;
	}
		
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (BattleData == none)
	{
		`RedScreen(GetFuncName() @ "activated for" @ AbilityName @ "but no BattleData state object exists.");
		return false;
	}

	if (Enabled)
	{
		if(BattleData.AllowedAbilities.Find(AbilityName) == INDEX_NONE || BattleData.DisallowedAbilities.Find(AbilityName) != INDEX_NONE)
		{
			if(NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
				SubmitState = true;
			}
			BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(BattleData.Class, BattleData.ObjectID));
			BattleData.AllowedAbilities.AddItem(AbilityName);
			BattleData.DisallowedAbilities.RemoveItem(AbilityName);
			NewGameState.AddStateObject(BattleData);
		}
	}	
	else
	{
		if(BattleData.AllowedAbilities.Find(AbilityName) != INDEX_NONE || BattleData.DisallowedAbilities.Find(AbilityName) == INDEX_NONE)
		{
			if(NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
				SubmitState = true;
			}
			BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(BattleData.Class, BattleData.ObjectID));
			BattleData.AllowedAbilities.RemoveItem(AbilityName);
			BattleData.DisallowedAbilities.AddItem(AbilityName);
			NewGameState.AddStateObject(BattleData);
		}
	}

	if(SubmitState)
	{
		Rules = `TACTICALRULES;
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Failed to submit state from" @ GetFuncName());
			return false;
		}
	}

	return true;
}

static function bool HighlightObjectiveAbility(name AbilityName, bool Enabled, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2AbilityTemplateManager AbilityMan;
	local XComGameState_BattleData BattleData;
	local X2TacticalGameRuleset Rules; 
	local bool SubmitState;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	if(AbilityMan.FindAbilityTemplate(AbilityName) == none)
	{
		return false;
	}
		
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (BattleData == none)
	{
		`RedScreen(GetFuncName() @ "activated for" @ AbilityName @ "but no BattleData state object exists.");
		return false;
	}

	if (Enabled && BattleData.HighlightedObjectiveAbilities.Find(AbilityName) == INDEX_NONE)
	{
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
			SubmitState = true;
		}
		BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(BattleData.Class, BattleData.ObjectID));
		BattleData.HighlightedObjectiveAbilities.AddItem(AbilityName);
		NewGameState.AddStateObject(BattleData);
	}	
	else if(!Enabled && BattleData.HighlightedObjectiveAbilities.Find(AbilityName) != INDEX_NONE)
	{
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ AbilityName);
			SubmitState = true;
		}
		BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(BattleData.Class, BattleData.ObjectID));
		BattleData.HighlightedObjectiveAbilities.RemoveItem(AbilityName);
		NewGameState.AddStateObject(BattleData);
	}

	if(SubmitState)
	{
		Rules = `TACTICALRULES;
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Failed to submit state from" @ GetFuncName());
			return false;
		}
	}

	return true;
}

function bool IsAbilityGloballyDisabled(name AbilityName)
{
	local X2AbilityTemplate Template;

	Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
	if(Template != none)
	{
		if (Template.bAllowedByDefault)
		{
			return DisallowedAbilities.Find(AbilityName) != INDEX_NONE;
		}
		else
		{
			return AllowedAbilities.Find(AbilityName) == INDEX_NONE;
		}
		
	}

	return false;
}

function bool IsAbilityObjectiveHighlighted(name AbilityName)
{
	return HighlightedObjectiveAbilities.Find(AbilityName) != INDEX_NONE;
}

// Hooks for tracking gameplay events affecting strategy layer alert level & pop support

function AddAlertEvent(Name EventID, XComGameState NewGameState=None)
{
	local XComGameState_BattleData NewBattleData;
	local bool NewGameStateMustBeSubmitted;

	NewGameStateMustBeSubmitted = false;
	if( NewGameState == None )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ EventID);
		NewGameStateMustBeSubmitted = true;
	}

	NewBattleData = XComGameState_BattleData(NewGameState.CreateStateObject(Class, ObjectID));
	NewBattleData.AlertEventIDs.AddItem(EventID);
	NewGameState.AddStateObject(NewBattleData);

	if( NewGameStateMustBeSubmitted )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function AddPopularSupportEvent(Name EventID, XComGameState NewGameState=None)
{
	local XComGameState_BattleData NewBattleData;
	local bool NewGameStateMustBeSubmitted;

	NewGameStateMustBeSubmitted = false;
	if( NewGameState == None )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(GetFuncName() @ "for" @ EventID);
		NewGameStateMustBeSubmitted = true;
	}

	NewBattleData = XComGameState_BattleData(NewGameState.CreateStateObject(Class, ObjectID));
	NewBattleData.PopularSupportEventIDs.AddItem(EventID);
	NewGameState.AddStateObject(NewBattleData);

	if( NewGameStateMustBeSubmitted )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}


function OnBeginTacticalPlay()
{
	super.OnBeginTacticalPlay();
}

function int GetAlertLevelBonus()
{
	local int TotalBonus, i;

	TotalBonus = 0;

	for( i = 0; i < AlertEventIDs.length; ++i )
	{
		TotalBonus += class'X2ExperienceConfig'.static.GetAlertLevelBonusForEvent(AlertEventIDs[i]);
	}

	return TotalBonus;
}

function int GetPopularSupportBonus()
{
	local int TotalBonus, i;

	TotalBonus = 0;

	for( i = 0; i < PopularSupportEventIDs.length; ++i )
	{
		TotalBonus += class'X2ExperienceConfig'.static.GetPopularSupportBonusForEvent(PopularSupportEventIDs[i]);
	}

	return TotalBonus;
}


function AwardTacticalGameEndBonuses(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local Name MissionResultEventID;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	if(bLocalPlayerWon)
	{
		MissionResultEventID = MissionState.GetMissionSuccessEventID();
	}
	else
	{
		MissionResultEventID = MissionState.GetMissionFailureEventID();
	}

	AddPopularSupportEvent(MissionResultEventID, NewGameState);
	AddAlertEvent(MissionResultEventID, NewGameState);
}

function SetVictoriousPlayer(XComGameState_Player Winner, bool bWinnerIsLocal)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;

	if(bWinnerIsLocal)
	{
		History = `XCOMHISTORY;
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(m_iMissionID));

		if(MissionState != none)
		{
			MissionSource = MissionState.GetMissionSource();

			if(MissionSource.WasMissionSuccessfulFn != none)
			{
				bLocalPlayerWon = MissionSource.WasMissionSuccessfulFn(self);
			}
			else
			{
				bLocalPlayerWon = true;
			}
		}
		else
		{
			bLocalPlayerWon = true;
		}	
	}
	else
	{
		bLocalPlayerWon = false;
	}
	
	VictoriousPlayer = Winner.GetReference();
}

function bool IsMultiplayer()
{	
	return bMultiplayer;
}

function SetPostMissionGrade()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local int idx, NumWounded, NumDead, NumSquad;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NumWounded = 0;
	NumDead = 0;
	NumSquad = 0;
	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if(UnitState != none)
		{
			NumSquad++;
			if(UnitState.IsDead())
			{
				NumDead++;
			}
			else if(UnitState.IsInjured())
			{
				NumWounded++;
			}
		}
	}

	bGreatMission = false;
	bToughMission = false;
	if(bLocalPlayerWon && NumDead == 0 && NumWounded <= 1)
	{
		bGreatMission = true;
	}
	else if(NumDead > (NumSquad / 2))
	{
		bToughMission = true;
	}
}

static function bool TacticalHackCompleted()
{
	local XComGameState_BattleData BattleData;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	return BattleData != None && BattleData.bTacticalHackCompleted;
}

DefaultProperties
{	
	m_iLayer=-1 // no layer by default
	m_iForceLevel=1
	m_iAlertLevel=1
}
