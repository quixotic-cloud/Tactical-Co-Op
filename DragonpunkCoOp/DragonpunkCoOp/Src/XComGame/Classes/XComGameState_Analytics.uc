//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Analytics.uc
//  AUTHOR:  Scott Ramsay  --  4/1/2015
//  PURPOSE: State object that handles collection of all metrics at a "Game History level"
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Analytics extends XComGameState_BaseObject
	native(Core)
	config(GameData);

enum ChallengeModePointName
{
	CMPN_CompletedObjective,
	CMPN_KilledEnemy,
	CMPN_UninjuredSoldiers,
	CMPN_AliveSoldiers,
	CMPN_CiviliansSaved
};

const ANALYTICS_COMPLETED_GAMES = 'COMPLETED_GAMES';

const ANALYTICS_TURN_COUNT = 'TURN_COUNT';
const ANALYTICS_UNIT_MOVEMENT = 'ACC_UNIT_MOVEMENT';
const ANALYTICS_UNIT_COVER_COUNT = 'ACC_UNIT_COVER_COUNT';
const ANALYTICS_UNIT_COVER_TOTAL = 'ACC_UNIT_COVER_TOTAL';
const ANALYTICS_UNIT_KILLS = 'ACC_UNIT_KILLS';
const ANALYTICS_UNIT_DEALT_DAMAGE = 'ACC_UNIT_DEALT_DAMAGE';
const ANALYTICS_UNIT_TAKEN_DAMAGE = 'ACC_UNIT_TAKEN_DAMAGE';
const ANALYTICS_UNIT_SHOTS_TAKEN = 'ACC_UNIT_SHOTS_TAKEN';
const ANALYTICS_UNIT_SUCCESSFUL_SHOTS = 'ACC_UNIT_SUCCESS_SHOTS';
const ANALYTICS_UNIT_ABILITIES_RECIEVED = 'ACC_UNIT_ABILITIES_RECIEVED';
const ANALYTICS_UNIT_ATTACKS = 'ACC_UNIT_ATTACKS';
const ANALYTICS_UNIT_SUCCESSFUL_ATTACKS = 'ACC_UNIT_SUCCESSFUL_ATTACKS';
const ANALYTICS_UNIT_MISSIONS = 'ACC_UNIT_MISSIONS';
const ANALYTICS_UNIT_SERVICE_HOURS = 'ACC_UNIT_SERVICE_LENGTH';
const ANALYTICS_UNITS_HEALED_HOURS = 'ACC_UNIT_HEALING';
const ANALYTICS_SUCCESSFUL_HAYWIRES = 'SUCCESSFUL_HAYWIRES';

const ANALYTICS_RECORD_SHOT_PERCENTAGE = 'RECORD_SHOTS';
const ANALYTICS_RECORD_AVERAGE_DAMAGE = 'RECORD_AVERAGE_DAMAGE';
const ANALYTICS_RECORD_AVERAGE_KILLS = 'RECORD_AVERAGE_KILLS';
const ANALYTICS_RECORD_AVERAGE_COVER = 'RECORD_AVERAGE_COVER';

const ANALYTICS_MISSIONS_WON = 'BATTLES_WON';
const ANALYTICS_MISSIONS_LOST = 'BATTLES_LOST';
const ANALYTICS_UNITS_LOST = 'UNITS_LOST';
const ANALYTICS_FLAWLESS_MISSIONS = 'FLAWLESS_MISSIONS';
const ANALYTICS_GRENADE_KILL = 'KILLED_WITH_GRENADE';
const ANALYTICS_GRENADES_USED = 'GRENADES_USED';
const ANALYTICS_SABOTAGED_FACILITIES = 'NUM_SABOTAGED_FACILITIES';
const ANALYTICS_MISSION_TIMERS_REMAIN = 'REMAINING_TIMED_MISSION_TURNS';
const ANALYTICS_NUM_MISSION_TIMERS = 'NUM_TIMED_MISSIONS';

const ANALYTICS_NUM_ENGINEERS = 'NUM_ENGINEERS';
const ANALYTICS_NUM_SCIENTISTS = 'NUM_SCIENTISTS';

const ANALYTICS_DAYS_TO_MAGNETIC_WEAPONS = 'MAGNETIC_WEAPONS';
const ANALYTICS_DAYS_TO_PLATED_ARMOR = 'PLATED_ARMOR';
const ANALYTICS_DAYS_TO_BEAM_WEAPONS = 'BEAM_WEAPONS';
const ANALYTICS_DAYS_TO_POWERED_ARMOR = 'POWERED_ARMOR';
const ANALYTICS_DAYS_TO_ALIEN_ENCRYPTION = 'ALIEN_ENCRYPTION';

const ANALYTICS_OUTPOSTS_CONSTRUCTED = 'BUILT_OUTPOST';
const ANALYTICS_AVATAR_PROGRESS = 'AVATAR_PROGRESS';

const ANALYTICS_INTEL_GATHERED = 'INTEL_GATHERED';
const ANALYTICS_BLACKMARKET_INTEL = 'BLACKMARKET_INTEL';
const ANALYTICS_BLACKMARKET_SUPPLIES = 'BLACKMARKET_SUPPLIES';
const ANALYTICS_SUPPLY_DROP_SUPPLIES = 'SUPPLY_DROP_SUPPLIES';

const ANALYTICS_XCOM_VICTORY = 'XCOM_VICTORY';

const ANALYTICS_UNIT_ACTION = 'SAW_ACTION';
const ANALYTICS_HACK_REWARDS = 'HACK_REWARDS';

const ANALYTICS_DAYS_TO_COLONEL = 'FIRST_COLONEL_DAYS';
const ANALYTICS_PROMOTIONS_EARNED = 'PROMOTIONS_EARNED';
const ANALYTICS_NUM_COLONELS = 'NUM_COLONELS';
const ANALYTICS_NUM_PSIONICS = 'NUM_PSIONICS';
const ANALYTICS_NUM_MAGUSES = 'NUM_MAGUSES';

struct native ChallengeModeScoringTableEntry
{
	var name MissionType;
	var array<int> Points;
};

struct UnitAnalyticEntry
{
	var int ObjectID;
	var float Value;
};

struct native AnalyticEntry
{
	var name Key;
	var float Value;
};

var config array<ChallengeModeScoringTableEntry> ChallengeModeScoringTable;
var config int ChallengeModeEnemyBonusPerForceLevel;

var private native Map_Mirror AnalyticMap{ TMap<FName, double> };
var private native Map_Mirror TacticalAnalyticMap{ TMap<FName, double> };
var private native array<int> TacticalAnalyticUnits;

var private int CampaignDifficulty;

var bool SubmitToFiraxisLive;

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

protected native function AddValueImpl(name Metric, float Value);
protected native function SetValueImpl(name Metric, float Value);

native function string GetValueAsString(name metric, string Default = "0") const;
native function double GetValue(name metric) const;
native function float GetFloatValue(name metric) const; // Unrealscript has trouble converting from double to float.  This works around the compiler issue.
native function DumpValues() const;

protected native function AddTacticalValueImpl( name Metric, float Value );
protected native function AddTacticalTrackedUnit( int NewID );
protected native function ClearTacticalValues( );

native function string GetTacticalValueAsString( name metric, string Default = "0" ) const;
native function double GetTacticalValue( name metric ) const;
native function float GetTacticalFloatValue( name metric ) const; // Unrealscript has trouble converting from double to float.  This works around the compiler issue.
native function DumpTacticalValues( ) const;

native final iterator function IterateGlobalAnalytics( out AnalyticEntry outEntry, optional bool IncludeUnits = true );
native final iterator function IterateTacticalAnalytics( out AnalyticEntry outEntry, optional bool IncludeUnits = true );

native function SingletonCopyForHistoryDiffDuplicate( XComGameState_BaseObject NewState );

private function name BuildUnitMetric( int UnitID, name Metric )
{
	return name("UNIT_"$UnitID$"_"$Metric);
}

static function name BuildEndGameMetric( name Metric )
{
	return name("ENDGAME_"$Metric);
}

private function MaybeAddFirstColonel( XComGameState_Analytics NewAnalytics, XComGameState_Unit NewColonel )
{
	local TDateTime GameStartDate, CurrentDate;
	local float TimeDiffHours;
	local int TimeToDays;

	if (GetFloatValue( ANALYTICS_DAYS_TO_COLONEL ) == 0.0f)
	{
		class'X2StrategyGameRulesetDataStructures'.static.SetTime( GameStartDate, 0, 0, 0,
		class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
		class'X2StrategyGameRulesetDataStructures'.default.START_DAY,
		class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );
		CurrentDate = `STRATEGYRULES.GameTime;

		TimeDiffHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours( CurrentDate, GameStartDate );

		TimeToDays = Round( TimeDiffHours / 24.0f );

		NewAnalytics.SetValue( ANALYTICS_DAYS_TO_COLONEL, TimeToDays );
	}
}

function string GetUnitValueAsString( name Metric, StateObjectReference UnitRef )
{
	`assert( UnitRef.ObjectID > 0 );

	return GetValueAsString( BuildUnitMetric( UnitRef.ObjectID, Metric ) );
}

function double GetUnitValue( name Metric, StateObjectReference UnitRef )
{
	`assert( UnitRef.ObjectID > 0 );

	return GetValue( BuildUnitMetric( UnitRef.ObjectID, Metric ) );
}

function float GetUnitFloatValue( name Metric, StateObjectReference UnitRef )
{
	`assert( UnitRef.ObjectID > 0 );

	return GetFloatValue( BuildUnitMetric( UnitRef.ObjectID, Metric ) );
}

function AddValue(name Metric, float Value, optional StateObjectReference UnitRef)
{
	local name UnitMetric;

	AddValueImpl(Metric, Value);

	// soldier specific tracking
	if (UnitRef.ObjectID > 0)
	{
		UnitMetric = BuildUnitMetric( UnitRef.ObjectID, Metric );
		AddValueImpl(UnitMetric, Value);
	}

	// send to server stats
	if (SubmitToFiraxisLive)
	{
		`FXSLIVE.StatAddValue( name(Metric$"_"$CampaignDifficulty), Value, eKVPSCOPE_USERANDGLOBAL);
	}
}


function SetValue(name Metric, float Value)
{
	SetValueImpl(Metric, Value);

	// send to server stats
	if (SubmitToFiraxisLive)
	{
		`FXSLIVE.StatSetValue(name(Metric$"_"$CampaignDifficulty), Value, eKVPSCOPE_USERANDGLOBAL);
	}
}

function AddTacticalValue( name Metric, int Value, optional StateObjectReference UnitRef )
{
	local name UnitMetric;

	AddTacticalValueImpl( Metric, Value );
	AddValueImpl( Metric, Value );
	
	// soldier specific tracking
	if (UnitRef.ObjectID > 0)
	{
		UnitMetric = BuildUnitMetric( UnitRef.ObjectID, Metric );
		AddTacticalValueImpl( UnitMetric, Value );
		AddTacticalTrackedUnit( UnitRef.ObjectID );

		AddValueImpl( UnitMetric, Value );
	}

	// send to server stats
	if (SubmitToFiraxisLive)
	{
		`FXSLIVE.StatAddValue( name(Metric$"_"$CampaignDifficulty), Value, eKVPSCOPE_USERANDGLOBAL );
	}
}

function UnitAnalyticEntry GetLargestTacticalAnalyticForMetric( name Metric )
{
	local UnitAnalyticEntry Entry;
	local int UnitID;
	local float Value;

	Entry.ObjectID = 0;
	Entry.Value = 0.0f;

	foreach TacticalAnalyticUnits( UnitID )
	{
		Value = GetTacticalFloatValue( BuildUnitMetric(UnitID, Metric) );

		if (Value > Entry.Value)
		{
			Entry.ObjectID = UnitID;
			Entry.Value = Value;
		}
	}

	return Entry;
}

static function CreateAnalytics(XComGameState StartState, int SelectedDifficulty)
{
	local XComGameState_Analytics AnalyticsObject;

	// create the analytics object
	AnalyticsObject = XComGameState_Analytics(StartState.CreateStateObject(class'XComGameState_Analytics'));
	AnalyticsObject.CampaignDifficulty = SelectedDifficulty;

	// add analytics object to the start state
	StartState.AddStateObject(AnalyticsObject);
}

function SubmitGameState(XComGameState NewGameState)
{
	if (`XANALYTICS.ShouldSubmitGameState())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

function AddTacticalGameStart()
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local float TurnCount, UnitKills, TotalShots, TotalHits, TotalDamage, TotalAttacks, CoverCount, CoverTotal;
	local float ShotPercent, AvgDamage, AvgKills, AvgCover, MissionLost;
	local float RecordShotPercent, RecordAvgDamage, RecordAvgKills, RecordAvgCover;
	local XGBattle_SP Battle;
	local array<XComGameState_Unit> MissionUnits;
	local XComGameState_Unit Unit;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Mission End" );

	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );
	MissionLost = GetTacticalFloatValue( ANALYTICS_MISSIONS_LOST );

	if ((TacticalAnalyticUnits.Length > 0) && (MissionLost == 0.0f))
	{
		TotalShots = GetTacticalFloatValue( ANALYTICS_UNIT_SHOTS_TAKEN );
		TotalHits = GetTacticalFloatValue( ANALYTICS_UNIT_SUCCESSFUL_SHOTS );
		if (TotalShots > 0)
			ShotPercent = TotalHits / TotalShots;

		TotalDamage = GetTacticalFloatValue( ANALYTICS_UNIT_DEALT_DAMAGE );
		TotalAttacks = GetTacticalFloatValue( ANALYTICS_UNIT_SUCCESSFUL_ATTACKS );
		if (TotalAttacks > 0)
			AvgDamage = TotalDamage / TotalAttacks;

		TurnCount = GetTacticalFloatValue( ANALYTICS_TURN_COUNT );
		UnitKills = GetTacticalFloatValue( ANALYTICS_UNIT_KILLS );
		if (TurnCount > 0)
			AvgKills = UnitKills / TurnCount;

		CoverCount = GetTacticalFloatValue( ANALYTICS_UNIT_COVER_COUNT );
		CoverTotal = GetTacticalFloatValue( ANALYTICS_UNIT_COVER_TOTAL );
		if (CoverCount > 0)
			AvgCover = CoverTotal / CoverCount;

		RecordShotPercent = GetFloatValue( ANALYTICS_RECORD_SHOT_PERCENTAGE );
		RecordAvgDamage = GetFloatValue( ANALYTICS_RECORD_AVERAGE_DAMAGE );
		RecordAvgKills = GetFloatValue( ANALYTICS_RECORD_AVERAGE_KILLS );
		RecordAvgCover = GetFloatValue( ANALYTICS_RECORD_AVERAGE_COVER );

		if (ShotPercent > RecordShotPercent)
			AnalyticsObject.SetValue( ANALYTICS_RECORD_SHOT_PERCENTAGE, ShotPercent );
		if (AvgDamage > RecordAvgDamage)
			AnalyticsObject.SetValue( ANALYTICS_RECORD_AVERAGE_DAMAGE, AvgDamage );
		if (AvgKills > RecordAvgKills)
			AnalyticsObject.SetValue( ANALYTICS_RECORD_AVERAGE_KILLS, AvgKills );
		if (AvgCover > RecordAvgCover)
			AnalyticsObject.SetValue( ANALYTICS_RECORD_AVERAGE_COVER, AvgCover );
	}
	AnalyticsObject.ClearTacticalValues( );

	Battle = XGBattle_SP( `BATTLE);
	Battle.GetHumanPlayer( ).GetOriginalUnits( MissionUnits, true );

	foreach MissionUnits( Unit )
	{
		if (GetUnitFloatValue( ANALYTICS_UNIT_ACTION, Unit.GetReference() ) == 0.0f)
		{
			AnalyticsObject.AddValue( ANALYTICS_UNIT_ACTION, 1, Unit.GetReference() );
		}
	}

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddTacticalGameEnd()
{
	local XComGameState_BattleData BattleData;
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local XComGameState_UITimer TimerState;
	local bool bMissionSuccess, bFlawless;
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> MissionUnits;
	local XGBattle_SP Battle;
	local StateObjectReference UnitRef;

	Battle = XGBattle_SP( `BATTLE);
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	bMissionSuccess = BattleData.bLocalPlayerWon && !BattleData.bMissionAborted;

	`ANALYTICSLOG("STAT_END_MISSION:"@bMissionSuccess);

	NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( CMPN_AliveSoldiers );

	AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));

	if (bMissionSuccess)
	{
		AnalyticsObject.AddValue(ANALYTICS_MISSIONS_WON, 1);

		if (BattleData.MapData.ActiveMission.sType == "Sabotage")
		{
			AnalyticsObject.AddValue( ANALYTICS_SABOTAGED_FACILITIES, 1 );
		}
	}
	else
	{
		AnalyticsObject.AddTacticalValue( ANALYTICS_MISSIONS_LOST, 1 );
	}

	Battle.GetHumanPlayer( ).GetOriginalUnits( MissionUnits, true );

	bFlawless = true;
	foreach MissionUnits( Unit )
	{
		UnitRef.ObjectID = Unit.ObjectID;

		AnalyticsObject.AddValue( ANALYTICS_UNIT_MISSIONS, 1, UnitRef );

		if (Unit.IsDead( ))
		{
			bFlawless = false;
			AnalyticsObject.AddValue( ANALYTICS_UNITS_LOST, 1 );
		}
		if (Unit.WasInjuredOnMission( ))
		{
			bFlawless = false;
		}
	}

	if (bFlawless)
	{
		AnalyticsObject.AddValue( ANALYTICS_FLAWLESS_MISSIONS, 1 );
	}

	TimerState = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_UITimer', true));
	if (TimerState != none)
	{
		while ((TimerState != none) && !TimerState.ShouldShow)
		{
			TimerState = XComGameState_UITimer(`XCOMHISTORY.GetPreviousGameStateForObject(TimerState));
		}

		if (TimerState != none)
		{
			AnalyticsObject.AddValue( ANALYTICS_NUM_MISSION_TIMERS, 1 );
			AnalyticsObject.AddValue( ANALYTICS_MISSION_TIMERS_REMAIN, TimerState.TimerValue );
		}
	}

	if (`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none)
	{
		AnalyticsObject.HandleChallengeModeEnd(NewGameState);
	}

	NewGameState.AddStateObject(AnalyticsObject);
	SubmitGameState(NewGameState);
}

function AddPlayerTurnEnd( )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Mission End" );

	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	AnalyticsObject.AddTacticalValue( ANALYTICS_TURN_COUNT, 1 );

	foreach History.IterateByClassType( class'XComGameState_Unit', Unit )
	{
		if ((Unit.GetTeam() == eTeam_XCom) && (!Unit.IsDead()) && Unit.GetMyTemplate().bCanTakeCover)
		{
			UnitRef.ObjectID = Unit.ObjectID;
			AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_COVER_COUNT, 1, UnitRef );
			AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_COVER_TOTAL, Unit.GetCoverTypeFromLocation( ), UnitRef );
		}
	}

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddSoldierTacticalToStrategy(XComGameState_Unit SourceUnit, XComGameState NewGameState)
{
	local XComGameState_Analytics AnalyticsObject;

	if (SourceUnit != none && SourceUnit.IsSoldier())
	{
		AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));

		if (SourceUnit.IsDead())
		{
			if (!SourceUnit.bBodyRecovered)
			{
				AnalyticsObject.AddValue('SOLDIERS_LEFT_BEHIND', 1);
			}
			else
			{
				AnalyticsObject.AddValue('NUMBER_OF_SOLDIERS_CARRIED_TO_EXTRACTION', 1);
			}
		}

		NewGameState.AddStateObject(AnalyticsObject);
	}
}


function AddWeaponKill(XComGameState_Unit SourceUnit, XComGameState_Ability Ability)
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	// we only care about player solders
	if (SourceUnit != none && SourceUnit.IsPlayerControlled() && SourceUnit.IsSoldier())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Weapon Kill");

		AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));
		AnalyticsObject.HandleWeaponKill(SourceUnit, Ability);

		NewGameState.AddStateObject(AnalyticsObject);
		SubmitGameState(NewGameState);
	}
}


function AddBreakDoor(XComGameState_Unit SourceUnit, XComGameStateContext_Ability AbilityContext)
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	// we only care about players kicking down doors taking names
	if (SourceUnit != none && SourceUnit.IsPlayerControlled())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Break Door");

		AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));
		AnalyticsObject.AddValue('DOORS_KICKED', 1);

		NewGameState.AddStateObject(AnalyticsObject);
		SubmitGameState(NewGameState);
	}
}


function AddBreakWindow(XComGameState_Unit SourceUnit, XComGameStateContext_Ability AbilityContext)
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	// we only care about players breaking windows
	if (SourceUnit != none && SourceUnit.IsPlayerControlled())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Break Window");

		AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));
		AnalyticsObject.AddValue('WINDOWS_JUMPED_THROUGH', 1);

		NewGameState.AddStateObject(AnalyticsObject);
		SubmitGameState(NewGameState);
	}
}

function AddUnitMoved( XComGameState_Unit MovedUnit )
{
	local XComGameState NewGameState, MovementGameState;
	local XComGameState_Analytics AnalyticsObject;
	local PathingResultData PathingData;
	local int TravelDistanceSq;
	local int x, dx, dy;
	local GameplayTileData Curr, Prev;
	local StateObjectReference UnitRef;

	if ((MovedUnit.GetTeam() != eTeam_XCom) || MovedUnit.GetMyTemplate().bIsCosmetic)
	{
		return;
	}

	UnitRef.ObjectID = MovedUnit.ObjectID;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Unit Moved" );

	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	TravelDistanceSq = 0;
	MovementGameState = MovedUnit.GetParentGameState( );
	PathingData = XComGameStateContext_Ability( MovementGameState.GetContext() ).ResultContext.PathResults[0];
	for (x = 1; x < PathingData.PathTileData.Length; ++x)
	{
		Prev = PathingData.PathTileData[x - 1];
		Curr = PathingData.PathTileData[x];

		dx = Prev.EventTile.X - Curr.EventTile.X;
		dy = Prev.EventTile.Y - Curr.EventTile.Y;
		TravelDistanceSq += dx*dx + dy*dy;
	}
	
	AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_MOVEMENT, TravelDistanceSq, UnitRef );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddKillMail(XComGameState_Unit SourceUnit, XComGameState_Unit KilledUnit)
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( CMPN_KilledEnemy );

	AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));
	AnalyticsObject.HandleKillMail(SourceUnit, KilledUnit, NewGameState);
	
	NewGameState.AddStateObject(AnalyticsObject);
	SubmitGameState(NewGameState);
}

function AddMissionObjectiveComplete()
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( CMPN_CompletedObjective );

	AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));
	AnalyticsObject.HandleMissionObjectiveComplete(NewGameState);

	NewGameState.AddStateObject(AnalyticsObject);
	SubmitGameState(NewGameState);
}

function AddCivilianRescued(XComGameState_Unit SourceUnit, XComGameState_Unit RescuedUnit)
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( CMPN_CiviliansSaved );

	AnalyticsObject = XComGameState_Analytics(NewGameState.CreateStateObject(class'XComGameState_Analytics', self.ObjectID));
	AnalyticsObject.HandleCivilianRescued(SourceUnit, RescuedUnit, NewGameState);

	NewGameState.AddStateObject(AnalyticsObject);
	SubmitGameState(NewGameState);
}

function AddUnitDamage( XComGameState_Unit Target, XComGameState_Unit Source, XComGameStateContext Context )
{
	local DamageResult DmgResult;
	local int DamageAmount;
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local StateObjectReference UnitRef;

	if ((Target.GetTeam() != eTeam_XCom) && (Source.GetTeam() != eTeam_XCom))
	{
		return; // no xcom units involved.  no tactical stats required
	}

	DamageAmount = 0;
	foreach Target.DamageResults( DmgResult )
	{
		if (DmgResult.Context == Context)
		{
			DamageAmount = DmgResult.DamageAmount;
			break;
		}
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Unit Damage" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	if (Target.GetTeam() == eTeam_XCom)
	{
		UnitRef.ObjectID = Target.ObjectID;
		AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_TAKEN_DAMAGE, DamageAmount, UnitRef );
	}

	if (Source.GetTeam() == eTeam_XCom)
	{
		UnitRef.ObjectID = Source.ObjectID;
		AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_DEALT_DAMAGE, DamageAmount, UnitRef );
	}

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddUnitTakenShot( XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState_Item Tool, 
							XComGameStateContext_Ability AbilityContext, XComGameState_Ability Ability )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local StateObjectReference UnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_InteractiveObject HackTarget;;

	if ((Shooter.GetTeam( ) != eTeam_XCom) && ((Target == none) || (Target.GetTeam( ) != eTeam_XCom)))
	{
		return; // no xcom units involved.  no tactical stats required
	}

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager( ).FindAbilityTemplate( AbilityContext.InputContext.AbilityTemplateName );

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Unit Taken Shot" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	if (Shooter.GetTeam() == eTeam_XCom)
	{
		if (AbilityTemplate.TargetEffectsDealDamage(Tool, Ability))
		{
			if ((AbilityTemplate.Name == 'StandardShot') || (AbilityTemplate.Name == 'PistolStandardShot'))
			{
				UnitRef.ObjectID = Shooter.ObjectID;
				AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_SHOTS_TAKEN, 1, UnitRef );

				if (!AbilityContext.IsResultContextMiss( ))
				{
					AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_SUCCESSFUL_SHOTS, 1, UnitRef );
				}
			}

			if (!AbilityContext.IsResultContextMiss( ))
			{
				AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_SUCCESSFUL_ATTACKS, 1, UnitRef );
			}

			AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_ATTACKS, 1, UnitRef );
		}

		if ( Tool != none && ((X2GrenadeTemplate( Tool.GetMyTemplate() ) != none) || (X2GrenadeTemplate( Tool.GetLoadedAmmoTemplate( Ability ) ) != none)))
		{
			AnalyticsObject.AddTacticalValue( ANALYTICS_GRENADES_USED, 1, UnitRef );

			AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_SUCCESSFUL_ATTACKS, 1, UnitRef );
			AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_ATTACKS, 1, UnitRef );
		}

		if ((AbilityTemplate.Name == 'FinalizeHaywire') && Target.bHasBeenHacked)
		{
			AnalyticsObject.AddTacticalValue( ANALYTICS_SUCCESSFUL_HAYWIRES, 1, UnitRef );

			if (Target.UserSelectedHackReward > 0)
			{
				AnalyticsObject.AddValue( ANALYTICS_HACK_REWARDS, 1 );
			}
		}
		else if ((AbilityTemplate.Name == 'FinalizeSKULLJACK') || (AbilityTemplate.Name == 'FinalizeSKULLMINE'))
		{
			if (Target.UserSelectedHackReward > 0)
			{
				AnalyticsObject.AddValue( ANALYTICS_HACK_REWARDS, 1 );
			}
		}
		else if ((AbilityTemplate.Name == 'FinalizeIntrusion') || (AbilityTemplate.Name == 'FinalizeHack'))
		{
			HackTarget = XComGameState_InteractiveObject( `XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.PrimaryTarget.ObjectID ) );
			if (HackTarget.bHasBeenHacked && HackTarget.UserSelectedHackReward > 0)
			{
				AnalyticsObject.AddValue( ANALYTICS_HACK_REWARDS, 1 );
			}
		}
	}

	if ((Target != none) && (Target.GetTeam() == eTeam_XCom) && (Shooter.GetTeam() != eTeam_XCom))
	{
		UnitRef.ObjectID = Target.ObjectID;
		AnalyticsObject.AddTacticalValue( ANALYTICS_UNIT_ABILITIES_RECIEVED, 1, UnitRef );
	}

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddUnitHealCompleted( XComGameState_Unit HealedUnit, int HoursHealed )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local StateObjectReference UnitRef;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Unit Healed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	UnitRef.ObjectID = HealedUnit.ObjectID;
	AnalyticsObject.AddValue( ANALYTICS_UNITS_HEALED_HOURS, HoursHealed, UnitRef );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddCrewAddition( XComGameState_Unit NewCrew )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Crew Added" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	if (NewCrew.IsAScientist())
	{
		AnalyticsObject.AddValue( ANALYTICS_NUM_SCIENTISTS, 1 );
	}
	else if (NewCrew.IsAnEngineer())
	{
		AnalyticsObject.AddValue( ANALYTICS_NUM_ENGINEERS, 1 );
	}
	else if (NewCrew.IsASoldier() && (NewCrew.GetRank() == 7) && (NewCrew.GetNumMissions() == 0))
	{
		if (NewCrew.IsPsiOperative())
		{
			AnalyticsObject.AddValue( ANALYTICS_NUM_MAGUSES, 1 );
		}
		else
		{
			AnalyticsObject.AddValue( ANALYTICS_NUM_COLONELS, 1 );

			MaybeAddFirstColonel( AnalyticsObject, NewCrew );
		}
	}

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddResearchCompletion( XComGameState_Tech CompletedTech )
{
	local TDateTime GameStartDate, CurrentDate;
	local name TechAnalytic;
	local float TimeDiffHours;
	local int TimeToDays;
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	switch (CompletedTech.GetMyTemplateName())
	{
		case 'MagnetizedWeapons': TechAnalytic = ANALYTICS_DAYS_TO_MAGNETIC_WEAPONS;
			break;

		case 'PlasmaRifle': TechAnalytic = ANALYTICS_DAYS_TO_BEAM_WEAPONS;
			break;

		case 'PlatedArmor': TechAnalytic = ANALYTICS_DAYS_TO_PLATED_ARMOR;
			break;

		case 'PoweredArmor': TechAnalytic = ANALYTICS_DAYS_TO_POWERED_ARMOR;
			break;

		case 'AlienEncryption': TechAnalytic = ANALYTICS_DAYS_TO_ALIEN_ENCRYPTION;
			break;

		default: // Don't care about when they got this tech
			return;
	}

	class'X2StrategyGameRulesetDataStructures'.static.SetTime( GameStartDate, 0, 0, 0,
																class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
																class'X2StrategyGameRulesetDataStructures'.default.START_DAY,
																class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );
	CurrentDate = `STRATEGYRULES.GameTime;

	TimeDiffHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours( CurrentDate, GameStartDate );

	TimeToDays = Round( TimeDiffHours / 24.0f );

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	AnalyticsObject.SetValue( TechAnalytic, TimeToDays );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddResistanceActivity( X2ResistanceActivityTemplate ActivityTemplate, int Delta )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local name Analytic;

	if (Delta < 0)
	{
		return; // don't care about backwards progress for the analytics tracking
	}

	switch( ActivityTemplate.Name )
	{
		case 'ResAct_OutpostsBuilt': Analytic = ANALYTICS_OUTPOSTS_CONSTRUCTED;
			break;

		case 'ResAct_AvatarProgress':  Analytic = ANALYTICS_AVATAR_PROGRESS;
			break;

		default: // Don't care about this activity
			return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	AnalyticsObject.AddValue( Analytic, Delta );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddResource( XComGameState_Item Resource, int Quantity )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local name Analytic;

	if (Quantity < 0)
	{
		return; // don't care about backwards progress for the analytics tracking
	}

	switch (Resource.GetMyTemplateName())
	{
		case 'Intel': Analytic = ANALYTICS_INTEL_GATHERED;
			break;

		default: // Don't care about this activity
			return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	AnalyticsObject.AddValue( Analytic, Quantity );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddBlackMarketPurchase( XComGameState_BlackMarket BlackMarket, XComGameState_Reward RewardState )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local int ItemIndex;
	local Commodity RewardCommodity;
	local StrategyCost ScaledCost;
	local ArtifactCost Cost;

	ItemIndex = BlackMarket.ForSaleItems.Find('RewardRef', RewardState.GetReference());
	RewardCommodity = BlackMarket.ForSaleItems[ItemIndex];
	ScaledCost = class'XComGameState_HeadquartersXCom'.static.GetScaledStrategyCost( RewardCommodity.Cost, RewardCommodity.CostScalars, RewardCommodity.DiscountPercent );

	foreach ScaledCost.ResourceCosts(Cost)
	{
		if (Cost.ItemTemplateName == 'Intel')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
			AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

			AnalyticsObject.AddValue( ANALYTICS_BLACKMARKET_INTEL, Cost.Quantity );

			NewGameState.AddStateObject( AnalyticsObject );
			SubmitGameState( NewGameState );

			break;
		}
	}
}

function AddBlackMarketSupplies( int Supplies )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	AnalyticsObject.AddValue( ANALYTICS_BLACKMARKET_SUPPLIES, Supplies );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddSupplyDropSupplies( int Supplies )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	AnalyticsObject.AddValue( ANALYTICS_SUPPLY_DROP_SUPPLIES, Supplies );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddXComVictory( )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;
	local TDateTime GameStartDate, CurrentDate;
	local float TimeDiffHours;
	local int TimeToDays;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Research Completed" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );


	class'X2StrategyGameRulesetDataStructures'.static.SetTime( GameStartDate, 0, 0, 0,
																	class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
																	class'X2StrategyGameRulesetDataStructures'.default.START_DAY,
																	class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );
	CurrentDate = `STRATEGYRULES.GameTime;

	TimeDiffHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours( CurrentDate, GameStartDate );

	TimeToDays = Round( TimeDiffHours / 24.0f );

	AnalyticsObject.AddValue( ANALYTICS_XCOM_VICTORY, TimeToDays );

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

function AddUnitPromotion( XComGameState_Unit PromotedUnit, XComGameState_Unit PrevState )
{
	local XComGameState NewGameState;
	local XComGameState_Analytics AnalyticsObject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Tactical Analytics Unit Promoted" );
	AnalyticsObject = XComGameState_Analytics( NewGameState.CreateStateObject( class'XComGameState_Analytics', self.ObjectID ) );

	if (PromotedUnit.IsPsiOperative())
	{
		if (PromotedUnit.GetRank() == 1)
		{
			AnalyticsObject.AddValue( ANALYTICS_NUM_PSIONICS, 1 );
		}
		else if ((PromotedUnit.GetRank() == 7) && (PrevState.GetRank() < 7))
		{
			AnalyticsObject.AddValue( ANALYTICS_NUM_MAGUSES, 1 );
		}
	}
	else
	{
		AnalyticsObject.AddValue( ANALYTICS_PROMOTIONS_EARNED, 1 );

		if (PromotedUnit.GetRank() == 7)
		{
			AnalyticsObject.AddValue( ANALYTICS_NUM_COLONELS, 1 );

			MaybeAddFirstColonel( AnalyticsObject, PromotedUnit );
		}
	}

	NewGameState.AddStateObject( AnalyticsObject );
	SubmitGameState( NewGameState );
}

protected function name GetAlienStatName( name TemplateName, bool WasKilled )
{
	local string StatString;

	switch (TemplateName)
	{
		case 'TutorialAdvTrooperM1':
		case 'AdvTrooperM1':		StatString = "ADVENT_TROOPER_MK1";
			break;

		case 'AdvTrooperM2':		StatString = "ADVENT_TROOPER_MK2";
			break;

		case 'AdvTrooperM3':		StatString = "ADVENT_TROOPER_MK3";
			break;

		case 'AdvCaptainM1':		StatString = "ADVENT_CAPTAIN_MK1";
			break;

		case 'AdvCaptainM2':		StatString = "ADVENT_CAPTAIN_MK2";
			break;

		case 'AdvCaptainM3':		StatString = "ADVENT_CAPTAIN_MK3";
			break;

		case 'AdvStunLancerM1':		StatString = "ADVENT_STUN_LANCER_MK1";
			break;

		case 'AdvStunLancerM2':		StatString = "ADVENT_STUN_LANCER_MK2";
			break;

		case 'AdvStunLancerM3':		StatString = "ADVENT_STUN_LANCER_MK3";
			break;

		case 'AdvShieldBearerM2':	StatString = "ADVENT_SHIELDBEARER_MK2";
			break;

		case 'AdvShieldBearerM3':	StatString = "ADVENT_SHIELDBEARER_MK3";
			break;

		case 'AdvPsiWitchM3':		StatString = "ADVENT_PSI_WITCH_MK3";
			break;

		case 'AdvMEC_M1':			StatString = "ADVENT_MEC_MK1";
			break;

		case 'AdvMEC_M2':			StatString = "ADVENT_MEC_MK2";
			break;

		case 'LostTowersTurretM1':
		case 'AdvShortTurretM3':
		case 'AdvShortTurretM2':
		case 'AdvShortTurretM1':
		case 'AdvShortTurret':
		case 'AdvTurretM3':
		case 'AdvTurretM2':
		case 'AdvTurretM1':			StatString = "ADVENT_TURRETS";
			break;

		case 'PrototypeSectopod':
		case 'Sectopod':			StatString = "SECTOPODS";
			break;

		case 'Sectoid':				StatString = "SECTOIDS";
			break;

		case 'Archon':				StatString = "ARCHONS";
			break;

		case 'ArchonKing':			StatString = "ARCHON_KING";
			break;

		case 'ViperNeonate':
		case 'Viper':				StatString = "VIPERS";
			break;

		case 'ViperKing':			StatString = "VIPER_KING";
			break;

		case 'Muton':				StatString = "MUTONS";
			break;

		case 'Berserker':			StatString = "MUTON_BERSERKERS";
			break;

		case 'BerserkerQueen':		StatString = "BERSERKER_QUEEN";
			break;

		case 'Cyberus':				StatString = "CYBERUS";
			break;

		case 'Gatekeeper':			StatString = "GATEKEEPERS";
			break;

		case 'ChryssalidCocoonHuman':
		case 'ChryssalidCocoon':
		case 'Chryssalid':			StatString = "CHRYSSALIDS";
			break;

		case 'Andromedon':			StatString = "ANDROMEDONS";
			break;

		case 'Faceless':			StatString = "FACELESS";
			break;

		case 'PsiZombieHuman':
		case 'PsiZombie':			StatString = "ZOMBIES";
			break;

		case 'AndromedonRobot':		StatString = "ANDROMEDON_ROBOT";
			break;

		case 'FeralMEC_M1':			
		case 'FeralMEC_M2':
		case 'FeralMEC_M3':			StatString = "FERAL_MEC";
			break;

		case 'Sectopod_Markov':		StatString = "MARKOV_SECTOPOD";
			break;

		default:					StatString = "UNKNOWN_ENEMY_TYPE";
			break;
	}

	if (WasKilled)
	{
		StatString = StatString $ "_KILLED";
	}
	else
	{
		StatString = "SOLDIERS_KILLED_BY_" $ StatString;
	}

	return name(StatString);
}

protected function PlayerKilledOther(XComGameState_Unit SourceUnit, XComGameState_Unit KilledUnit)
{
	local name TemplateName;
	local X2SoldierClassTemplate SoldierClass;
	local StateObjectReference UnitRef;
	local X2CharacterTemplate SourceTemplate;

	TemplateName = KilledUnit.GetMyTemplateName();
	UnitRef.ObjectID = SourceUnit.ObjectID;

	`ANALYTICSLOG("STAT_KILLED:"@TemplateName);

	AddTacticalValue(ANALYTICS_UNIT_KILLS, 1, UnitRef);

	if (KilledUnit.bKilledByExplosion)
	{
		AddValue('ENEMIES_KILLED_BY_EXPLOSIVE_WEAPON', 1, UnitRef);
	}

	if (KilledUnit.IsFlanked())
	{
		`ANALYTICSLOG("STAT_KILLED_FLANKED");
	
		AddValue('TOTAL_NUMBER_OF_KILLS_AGAINST_FLANKED_ENEMIES', 1, UnitRef);
	}

	`ANALYTICSLOG("STAT_KILLED_COVER:"@KilledUnit.GetCoverTypeFromLocation());
	switch (KilledUnit.GetCoverTypeFromLocation())
	{
		case CT_None:
			AddValue('TOTAL_NUMBER_OF_KILLS_AGAINST_ENEMIES_IN_NO_COVER', 1, UnitRef);
			break;

		case CT_MidLevel:
			AddValue('TOTAL_NUMBER_OF_KILLS_AGAINST_ENEMIES_IN_LOW_COVER', 1, UnitRef);
			break;

		case CT_Standing:
			AddValue('TOTAL_NUMBER_OF_KILLS_AGAINST_ENEMIES_IN_HIGH_COVER', 1, UnitRef);
			break;
	}

	AddValue( GetAlienStatName( TemplateName, true ), 1, UnitRef );

	// check source soldier class kills
	SourceTemplate = SourceUnit.GetMyTemplateManager().FindCharacterTemplate( SourceUnit.GetMyTemplateName() );
	SoldierClass = SourceUnit.GetSoldierClassTemplate();

	if (SoldierClass != None)
	{
		`ANALYTICSLOG("STAT_KILLED_BY:"@SoldierClass.DataName);

		switch (SoldierClass.DataName)
		{
			case 'Specialist':
				AddValue('TOTAL_SPECIALIST_KILLS', 1, UnitRef);
				break;

			case 'Grenadier':
				AddValue('TOTAL_GRENADIER_KILLS', 1, UnitRef);
				break;

			case 'Ranger':
				AddValue('TOTAL_RANGER_KILLS', 1, UnitRef);
				break;

			case 'Sharpshooter':
				AddValue('TOTAL_SHARPSHOOTER_KILLS', 1, UnitRef);
				break;

			case 'PsiOperative':
				AddValue('TOTAL_PSI_OPERATIVE_KILLS', 1, UnitRef);
				break;

			case 'Rookie':
				AddValue('TOTAL_ROOKIE_KILLS', 1, UnitRef);
				break;

			case 'CentralOfficer':
				AddValue( 'TOTAL_CENTRAL_KILLS', 1, UnitRef );
				break;

			case 'ChiefEngineer':
				AddValue( 'SHEN_KILLS', 1, UnitRef );
				break;

			case 'Spark':
				AddValue( 'SPARK_MEC_KILLS', 1, UnitRef );
				break;

			default:
				AddValue('TOTAL_UNKNOWN_SOLDIER_CLASS_KILLS', 1, UnitRef);
				break;
		}
	}
	else if (SourceTemplate.DataName == 'AdvPsiWitchM2')
	{
		AddValue('TOTAL_COMMANDER_KILLS', 1, UnitRef );
	}
	else if (SourceTemplate.bIsRobotic)
	{
		AddValue( 'TOTAL_HACKED_ROBOTIC_KILLS', 1, UnitRef );
	}
	else if (SourceTemplate.bIsAdvent)
	{
		AddValue( 'TOTAL_CONTROLLED_ADVENT_KILLS', 1, UnitRef );
	}
	else if (SourceTemplate.bIsAlien)
	{
		AddValue( 'TOTAL_CONTROLLED_ALIEN_KILLS', 1, UnitRef );
	}
	else
	{
		AddValue( 'TOTAL_UNKNOWN_KILLS', 1, UnitRef );
	}
}


protected function OtherKilledPlayer(XComGameState_Unit SourceUnit, XComGameState_Unit KilledUnit)
{
	local name TemplateName;
	local X2SoldierClassTemplate SoldierClass;
	local int TimeDiffHours;
	local StateObjectReference UnitRef;

	TemplateName = SourceUnit.GetMyTemplateName();

	UnitRef.ObjectID = KilledUnit.ObjectID;

	`ANALYTICSLOG("STAT_KILLBY:"@TemplateName);

	AddValue('SOLDIERS_KILLED_TOTAL', 1);

	TimeDiffHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours( KilledUnit.m_KIADate, KilledUnit.m_RecruitDate );
	AddValue(ANALYTICS_UNIT_SERVICE_HOURS, TimeDiffHours, UnitRef );

	if (SourceUnit != none)
	{
		if (!SourceUnit.IsASoldier())
		{
			AddValue( GetAlienStatName( TemplateName, false ), 1, UnitRef );
		}
		else
		{
			AddValue( 'SOLDIERS_KILLED_BY_CONTROLLED_FRIENDLY', 1, UnitRef );
		}
	}
	else
	{
		AddValue( 'SOLDIERS_KILLED_BY_ENVIRONMENT', 1, UnitRef );
	}

	// check killed soldier rank
	switch (KilledUnit.GetRank())
	{
		case 0: AddValue('ROOKIES_KILLED', 1); break;
		case 1: AddValue('SQUADDIES_KILLED', 1); break;
		case 2: AddValue('CORPORALS_KILLED', 1); break;
		case 3: AddValue('SERGEANTS_KILLED', 1); break;
		case 4: AddValue('LIEUTENANTS_KILLED', 1); break;
		case 5: AddValue('CAPTAINS_KILLED', 1); break;
		case 6: AddValue('MAJORS_KILLED', 1); break;
		case 7: AddValue('COLONELS_KILLED', 1); break;
		case 8: AddValue('BRIGADIER_KILLED', 1); break;

		default: AddValue('UNKNOWN_RANK_KILLED', 1);
			break;
	}

	// check killed soldier class
	SoldierClass = KilledUnit.GetSoldierClassTemplate();

	if (SoldierClass != None)
	{
		`ANALYTICSLOG("STAT_KILLBY_BY:"@SoldierClass.DataName);

		switch (SoldierClass.DataName)
		{
			case 'Specialist':
				AddValue('SPECIALISTS_KILLED', 1);
				break;

			case 'Grenadier':
				AddValue('GRENADIERS_KILLED', 1);
				break;

			case 'Ranger':
				AddValue('RANGERS_KILLED', 1);
				break;

			case 'Sharpshooter':
				AddValue('SHARPSHOOTERS_KILLED', 1);
				break;

			case 'PsiOperative':
				AddValue('PSI_OPERATIVES_KILLED', 1);
				break;

			case 'Rookie':
				AddValue('ROOKIE_SOLIDER_KILLED', 1);
				break;

			case 'CentralOfficer':
				AddValue( 'CENTRALS_KILLED', 1, UnitRef );
				break;

			case 'ChiefEngineer':
				AddValue( 'SHEN_KILLED', 1, UnitRef );
				break;

			case 'Spark':
				AddValue( 'SPARK_MEC_KILLED', 1, UnitRef );
				break;

			default:
				AddValue( 'UNKNOWN_SOLDIER_CLASS_KILLED', 1);
				break;
		}
	}
}


protected function HandleKillMail(XComGameState_Unit SourceUnit, XComGameState_Unit KilledUnit, XComGameState NewGameState)
{
	local StateObjectReference UnitRef;

	// player kills something
	if (SourceUnit != None && SourceUnit.IsPlayerControlled())
	{
		// Friendly fire
		if (KilledUnit.IsSoldier() && KilledUnit.IsPlayerControlled())
		{
			UnitRef.ObjectID = SourceUnit.ObjectID;
			AddValue('FRIENDLY_FIRE_DEATHS', 1, UnitRef);
		}
		else
		{
			PlayerKilledOther(SourceUnit, KilledUnit);
			if ((KilledUnit.GetTeam() == eTeam_Alien) && (`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none))
			{
				HandleChallengeModeEnemyKill(SourceUnit, NewGameState);
			}
		}
	}
	else
	if (KilledUnit.IsSoldier())
	{
		// player unit was killed
		OtherKilledPlayer(SourceUnit, KilledUnit);
	}
}


protected function HandleWeaponKill(XComGameState_Unit SourceUnit, XComGameState_Ability Ability)
{
	local XComGameState_Item Item;
	local XComGameStateHistory History;
	local name TemplateName;
	local StateObjectReference UnitRef;

	History = `XCOMHISTORY;
	Item = XComGameState_Item(History.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID));
	TemplateName = Item.GetMyTemplateName();
	UnitRef.ObjectID = SourceUnit.ObjectID;

	switch (TemplateName)
	{
		case 'AssaultRifle_CV':
		case 'AssaultRifle_MG':
		case 'AssaultRifle_BM':
			AddValue('KILLS_WITH_RIFLES', 1, UnitRef);
			break;

		case 'Pistol_CV':
		case 'Pistol_MG':
		case 'Pistol_BM':
			AddValue('KILLS_WITH_PISTOLS', 1, UnitRef);
			break;

		case 'Shotgun_CV':
		case 'Shotgun_MG':
		case 'Shotgun_BM':
			AddValue('KILLS_WITH_SHOTGUNS', 1, UnitRef);

		case 'Cannon_CV':
		case 'Cannon_MG':
		case 'Cannon_BM':
			AddValue('KILLS_WITH_CANNON', 1, UnitRef);
			break;

		case 'RocketLauncher':
			AddValue('KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef);
			AddValue('KILLS_WITH_ROCKET_LAUNCHER', 1, UnitRef);
			break;

		case 'ShredderGun':
			AddValue('KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef);
			AddValue('KILLS_WITH_SHREDDER_GUN', 1, UnitRef);
			break;

		case 'Flamethrower':
			AddValue('KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef);
			AddValue('KILLS_WITH_FLAMETHROWER', 1, UnitRef);
			break;

		case 'FlamethrowerMk2':
			AddValue( 'KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef );
			AddValue( 'KILLS_WITH_HELLFIRE', 1, UnitRef );
			break;

		case 'BlasterLauncher':
			AddValue('KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef);
			AddValue('KILLS_WITH_BLASTER_LAUNCHER', 1, UnitRef);
			break;

		case 'PlasmaBlaster':
			AddValue('KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef);
			AddValue('KILLS_WITH_PLASMA_BLASTER', 1, UnitRef);
			break;

		case 'ShredstormCannon':
			AddValue('KILLS_WITH_HEAVY_WEAPONS', 1, UnitRef);
			AddValue('KILLS_WITH_SHREDSTORM_CANNON', 1, UnitRef);
			break;

		case 'Gremlin_CV':
		case 'Gremlin_MG':
		case 'Gremlin_BM':
		case 'Gremlin_Shen':
			AddValue('KILLS_WITH_GREMLIN', 1, UnitRef);
			break;

		case 'PsiAmp_CV':
		case 'PsiAmp_MG':
		case 'PsiAmp_BM':
			AddValue('KILLS_WITH_PSIONIC_ABILITIES', 1, UnitRef);
			break;

		case 'SniperRifle_CV':
		case 'SniperRifle_MG':
		case 'SniperRifle_BM':
			AddValue('KILLS_WITH_SNIPER_RIFLES', 1, UnitRef);
			break;

		case 'Sword_CV':
		case 'Sword_MG':
		case 'Sword_BM':
			AddValue('KILLS_WITH_SWORDS', 1, UnitRef);
			break;

		case 'AlienHunterRifle_CV':
		case 'AlienHunterRifle_MG':
		case 'AlienHunterRifle_BM':
			AddValue('KILLS_WITH_HUNTER_RIFLES', 1, UnitRef);
			break;

		case 'AlienHunterPistol_CV':
		case 'AlienHunterPistol_MG':
		case 'AlienHunterPistol_BM':
			AddValue('KILLS_WITH_HUNTER_PISTOLS', 1, UnitRef);
			break;

		case 'AlienHunterAxe_CV':
		case 'AlienHunterAxe_MG':
		case 'AlienHunterAxe_BM':
		case 'AlienHunterAxeThrown_CV':
		case 'AlienHunterAxeThrown_MG':
		case 'AlienHunterAxeThrown_BM':
			AddValue('KILLS_WITH_HUNTER_AXES', 1, UnitRef);
			break;

		case 'HeavyAlienArmor':
		case 'HeavyAlienArmorMk2':
			AddValue('KILLS_WITH_ALIEN_ARMOR', 1, UnitRef);
			break;

		case 'SparkRifle_CV':
		case 'SparkRifle_MG':
		case 'SparkRifle_BM':
			AddValue('KILLS_WITH_SPARK_RIFLE', 1, UnitRef);
			break;

		case 'SparkBit_CV':
		case 'SparkBit_MG':
		case 'SparkBit_BM':
			AddValue('KILLS_WITH_SPARK_BIT', 1, UnitRef);
			break;

		default:
			if ((X2GrenadeTemplate( Item.GetMyTemplate( ) ) != none) || (X2GrenadeTemplate( Item.GetLoadedAmmoTemplate( Ability ) ) != none))
			{
				AddValue( ANALYTICS_GRENADE_KILL, 1, UnitRef );
			}
			else
			{
				// Some of the SPARK abilities deal damage without using an item
				TemplateName = Ability.GetMyTemplateName();
				switch (TemplateName)
				{
					case 'Strike':	AddValue( 'KILLS_WITH_SPARK_STRIKE', 1, UnitRef );
						break;

					case 'Nova': AddValue( 'KILLS_WITH_SPARK_NOVA', 1, UnitRef );
						break;

					case 'SparkDeathExplosion': AddValue( 'KILLS_WITH_SPARK_DEATH_EXPLOSION', 1, UnitRef );
						break;

					default:
						AddValue( 'KILLS_WITH_UNKNOWN_WEAPONS', 1, UnitRef );
						break;
				}
			}
			break;
	}
}

protected function HandleMissionObjectiveComplete(XComGameState NewGameState)
{
	local int Points;
	local int PlayerIndex;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Player ControllingPlayer;
	local XComGameStateContext_ChallengeScore ChallengeContext;

	History = `XCOMHISTORY;

	if (History.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) == none)
	{
		return;
	}

	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	for (PlayerIndex = 0; PlayerIndex < BattleData.PlayerTurnOrder.Length; ++PlayerIndex)
	{
		ControllingPlayer = XComGameState_Player( History.GetGameStateForObjectID( BattleData.PlayerTurnOrder[ PlayerIndex ].ObjectID ) );
		if (!ControllingPlayer.IsAIPlayer( ))
		{
			break;
		}
	}

	ChallengeContext = XComGameStateContext_ChallengeScore( NewGameState.GetContext( ) );
	ChallengeContext.CategoryPointValue = GetChallengeModePoints( CMPN_CompletedObjective );

	Points = ChallengeContext.CategoryPointValue - ((ControllingPlayer.PlayerTurnCount - 1) * 1000);
	Points = Max( 0, Points );

	AddValue( 'CM_OBJECTIVE_COMPLETE_SCORE', Points );
	AddValue( 'CM_TOTAL_SCORE', Points );
	ChallengeContext.AddedPoints = Points;

	`XEVENTMGR.TriggerEvent( 'ChallengeModeScoreChange', , , NewGameState );
	`log("--->Challenge Mode Objective Complete Points:" @ Points);
}

protected function HandleCivilianRescued(XComGameState_Unit SourceUnit, XComGameState_Unit RescuedUnit, XComGameState NewGameState)
{
	local int Points;
	local int PlayerIndex;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Player ControllingPlayer;
	local XComGameStateContext_ChallengeScore ChallengeContext;
	local float AwardPercentage;

	History = `XCOMHISTORY;

	if (History.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) == none)
	{
		return;
	}

	if (SourceUnit != none)
	{
		ControllingPlayer = XComGameState_Player( History.GetGameStateForObjectID( SourceUnit.ControllingPlayer.ObjectID ) );
	}
	else
	{
		BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
		for (PlayerIndex = 0; PlayerIndex < BattleData.PlayerTurnOrder.Length; ++PlayerIndex)
		{
			ControllingPlayer = XComGameState_Player( History.GetGameStateForObjectID( BattleData.PlayerTurnOrder[ PlayerIndex ].ObjectID ) );
			if (!ControllingPlayer.IsAIPlayer( ))
			{
				break;
			}
		}
	}

	ChallengeContext = XComGameStateContext_ChallengeScore( NewGameState.GetContext( ) );

	ChallengeContext.CategoryPointValue = GetChallengeModePoints( CMPN_CiviliansSaved );
	AwardPercentage = (1.0 - ((ControllingPlayer.PlayerTurnCount - 1) * 0.1f)); // reduce by 10% every turn beyond the 1st

	Points = ChallengeContext.CategoryPointValue * AwardPercentage;
	Points = Max( 0, Points );

	AddValue( 'CM_CIVILIANS_RESCUED_SCORE', Points );
	AddValue( 'CM_TOTAL_SCORE', Points );
	ChallengeContext.AddedPoints = Points;

	`XEVENTMGR.TriggerEvent( 'ChallengeModeScoreChange', , , NewGameState );
}

private function HandleChallengeModeEnemyKill(XComGameState_Unit SourceUnit, XComGameState NewGameState)
{
	local int Points;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Player ControllingPlayer;
	local XComGameStateContext_ChallengeScore ChallengeContext;
	local float AwardPercentage;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ControllingPlayer = XComGameState_Player( History.GetGameStateForObjectID( SourceUnit.ControllingPlayer.ObjectID ) );

	ChallengeContext = XComGameStateContext_ChallengeScore( NewGameState.GetContext( ) );

	ChallengeContext.CategoryPointValue = GetChallengeModePoints( CMPN_KilledEnemy ) + (ChallengeModeEnemyBonusPerForceLevel * BattleData.m_iForceLevel);
	AwardPercentage = (1.0 - ((ControllingPlayer.PlayerTurnCount - 1) * 0.1f)); // reduce by 10% every turn beyond the 1st

	Points = ChallengeContext.CategoryPointValue * AwardPercentage;
	Points = Max( 0, Points );

	AddValue('CM_ENEMY_KILL_SCORE', Points);
	AddValue( 'CM_TOTAL_SCORE', Points );
	ChallengeContext.AddedPoints = Points;

	`XEVENTMGR.TriggerEvent( 'ChallengeModeScoreChange', , , NewGameState );
	`log("--->Challenge Mode Kill Points:" @ Points);
}

private function HandleChallengeModeEnd(XComGameState NewGameState)
{
	local int Points, TotalPoints;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int Uninjured, Alive;

	Uninjured = GetChallengeModePoints(CMPN_UninjuredSoldiers);
	Alive = GetChallengeModePoints(CMPN_AliveSoldiers);

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		Points = 0;
		if (UnitState.GetTeam() == eTeam_XCom && UnitState.IsASoldier())
		{
			if (!UnitState.IsInjured())
			{
				Points = Uninjured;
				AddValue('CM_UNINJURED_SOLDIERS_SCORE', Points);
			}
			else if (UnitState.IsAlive())
			{
				Points = Alive;
				AddValue('CM_ALIVE_SOLDIERS_SCORE', Points);
			}
			TotalPoints += Points;
		}
	}

	AddValue( 'CM_TOTAL_SCORE', TotalPoints );
	XComGameStateContext_ChallengeScore( NewGameState.GetContext( ) ).AddedPoints = TotalPoints;
	XComGameStateContext_ChallengeScore( NewGameState.GetContext( ) ).CategoryPointValue = Max( Uninjured, Alive );

	`XEVENTMGR.TriggerEvent( 'ChallengeModeScoreChange', , , NewGameState );
}

function ChallengeModeScoringTableEntry GetChallengePointsTable( )
{
	local ChallengeModeScoringTableEntry ScoreEntry;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local Name MissionType;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	MissionType = name( BattleData.MapData.ActiveMission.sType );

	foreach ChallengeModeScoringTable( ScoreEntry )
	{
		if (ScoreEntry.MissionType == MissionType)
		{
			return ScoreEntry;
		}
	}

	ScoreEntry.MissionType = MissionType;
	ScoreEntry.Points[ CMPN_CompletedObjective ] = 0;
	ScoreEntry.Points[ CMPN_KilledEnemy ] = 0;
	ScoreEntry.Points[ CMPN_UninjuredSoldiers ] = 0;
	ScoreEntry.Points[ CMPN_AliveSoldiers ] = 0;
	ScoreEntry.Points[ CMPN_CiviliansSaved ] = 0;

	return ScoreEntry;
}

private function int GetChallengeModePoints(ChallengeModePointName PointName)
{
	local ChallengeModeScoringTableEntry ScoreEntry;

	ScoreEntry = GetChallengePointsTable( );

	return ScoreEntry.Points[ PointName ];
}


cpptext
{
	virtual void Serialize(FArchive& Ar);
}

DefaultProperties
{
	CampaignDifficulty=-1
	bSingletonStateType=true
	SubmitToFiraxisLive=true
}