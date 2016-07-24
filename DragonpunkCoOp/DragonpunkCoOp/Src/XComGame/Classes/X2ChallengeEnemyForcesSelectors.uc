//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeEnemyForcesSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeEnemyForcesSelectors extends X2ChallengeElement;

struct ScheduleBreakdown
{
	var array<PrePlacedEncounterPair> WeakSpawns;
	var array<PrePlacedEncounterPair> StandardSpawns;
	var array<PrePlacedEncounterPair> BossSpawns;
};

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateStandardScheduleSelector( ) );
	Templates.AddItem( CreateRoboSquadSelector( ) );

	return Templates;
}

static function X2ChallengeEnemyForces CreateStandardScheduleSelector( )
{
	local X2ChallengeEnemyForces	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeEnemyForces', Template, 'ChallengeStandardSchedule');

	Template.SelectEnemyForcesFn = StandardScheduleSelector;

	return Template;
}

static function StandardScheduleSelector( X2ChallengeEnemyForces Selector, XComGameState_MissionSite MissionSite, XComGameState_BattleData BattleData, XComGameState StartState )
{
	MissionSite.CacheSelectedMissionData( BattleData.GetForceLevel(), BattleData.GetAlertLevel() );
}

static function X2ChallengeEnemyForces CreateRoboSquadSelector( )
{
	local X2ChallengeEnemyForces	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeEnemyForces', Template, 'ChallengeRoboSquad');

	Template.SelectEnemyForcesFn = RoboSquadSelector;

	return Template;
}

static function RoboSquadSelector( X2ChallengeEnemyForces Selector, XComGameState_MissionSite MissionSite, XComGameState_BattleData BattleData, XComGameState StartState )
{
	local X2SelectedEncounterData NewEncounter, EmptyEncounter;
	local ScheduleBreakdown Breakdown;
	local PrePlacedEncounterPair Encounter;
	local int SpawnCount;

	MissionSite.SelectedMissionData.ForceLevel = BattleData.GetForceLevel( );
	MissionSite.SelectedMissionData.AlertLevel = BattleData.GetAlertLevel( );

	Breakdown = GetAScheduleBreakdownForMission( MissionSite );

	MissionSite.SelectedMissionData.SelectedMissionScheduleName = 'ChallengeRoboSquad';

	EmptyEncounter.EncounterSpawnInfo.Team = eTeam_Alien;
	EmptyEncounter.EncounterSpawnInfo.SkipSoldierVO = true;

	SpawnCount = 1;

	foreach Breakdown.StandardSpawns( Encounter )
	{
		NewEncounter = EmptyEncounter;

		NewEncounter.EncounterSpawnInfo.EncounterZoneDepth = Encounter.EncounterZoneDepthOverride;
		NewEncounter.EncounterSpawnInfo.EncounterZoneWidth = Encounter.EncounterZoneWidth;
		NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetFromLOP = Encounter.EncounterZoneOffsetFromLOP;
		NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetAlongLOP = Encounter.EncounterZoneOffsetAlongLOP;
		NewEncounter.EncounterSpawnInfo.SpawnLocationActorTag = Encounter.SpawnLocationActorTag;

		if (SpawnCount % 2 == 0)
		{
			NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M2' );
			NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );
			NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );
		}
		else
		{
			NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );
			NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );
			NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );
		}

		NewEncounter.SelectedEncounterName = name( "Robo" $ SpawnCount++ );

		MissionSite.SelectedMissionData.SelectedEncounters.AddItem( NewEncounter );
	}

	foreach Breakdown.BossSpawns( Encounter )
	{
		NewEncounter = EmptyEncounter;

		NewEncounter.EncounterSpawnInfo.EncounterZoneDepth = Encounter.EncounterZoneDepthOverride;
		NewEncounter.EncounterSpawnInfo.EncounterZoneWidth = Encounter.EncounterZoneWidth;
		NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetFromLOP = Encounter.EncounterZoneOffsetFromLOP;
		NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetAlongLOP = Encounter.EncounterZoneOffsetAlongLOP;
		NewEncounter.EncounterSpawnInfo.SpawnLocationActorTag = Encounter.SpawnLocationActorTag;

		NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'Sectopod' );
		NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M2' );
		NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M2' );

		NewEncounter.SelectedEncounterName = name( "Robo" $ SpawnCount++ );

		MissionSite.SelectedMissionData.SelectedEncounters.AddItem( NewEncounter );
	}

	foreach Breakdown.WeakSpawns( Encounter )
	{
		NewEncounter = EmptyEncounter;

		NewEncounter.EncounterSpawnInfo.EncounterZoneDepth = Encounter.EncounterZoneDepthOverride;
		NewEncounter.EncounterSpawnInfo.EncounterZoneWidth = Encounter.EncounterZoneWidth;
		NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetFromLOP = Encounter.EncounterZoneOffsetFromLOP;
		NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetAlongLOP = Encounter.EncounterZoneOffsetAlongLOP;
		NewEncounter.EncounterSpawnInfo.SpawnLocationActorTag = Encounter.SpawnLocationActorTag;

		NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );
		NewEncounter.EncounterSpawnInfo.SelectedCharacterTemplateNames.AddItem( 'AdvMEC_M1' );

		NewEncounter.SelectedEncounterName = name( "Robo" $ SpawnCount++ );

		MissionSite.SelectedMissionData.SelectedEncounters.AddItem( NewEncounter );
	}
}

static function ScheduleBreakdown GetAScheduleBreakdownForMission( XComGameState_MissionSite MissionSite )
{
	local XComTacticalMissionManager TacticalMissionManager;
	local name ScheduleName;
	local MissionSchedule SelectedMissionSchedule;
	local PrePlacedEncounterPair Encounter;
	local string EncounterID;
	local ScheduleBreakdown Breakdown;
	local ConfigurableEncounter ConfigEncounter;

	TacticalMissionManager = `TACTICALMISSIONMGR;

	ScheduleName = TacticalMissionManager.ChooseMissionSchedule( MissionSite );
	TacticalMissionManager.GetMissionSchedule( ScheduleName, SelectedMissionSchedule );

	foreach SelectedMissionSchedule.PrePlacedEncounters( Encounter )
	{
		TacticalMissionManager.GetConfigurableEncounter( Encounter.EncounterID, ConfigEncounter );
		if (ConfigEncounter.TeamToSpawnInto != eTeam_Alien)
		{
			continue;
		}

		if (Encounter.EncounterZoneDepthOverride < 0)
		{
			Encounter.EncounterZoneDepthOverride = SelectedMissionSchedule.EncounterZonePatrolDepth;
		}

		EncounterID = string( Encounter.EncounterID );
		if (InStr( EncounterID, "_BOSS" ) != -1)
		{
			Breakdown.BossSpawns.AddItem( Encounter );
		}
		else if (InStr( EncounterID, "_Standard" ) != -1)
		{
			Breakdown.StandardSpawns.AddItem( Encounter );
		}
		else if (InStr( EncounterID, "_Weak" ) != -1)
		{
			Breakdown.WeakSpawns.AddItem( Encounter );
		}
	}

	return Breakdown;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}