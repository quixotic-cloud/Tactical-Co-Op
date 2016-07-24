
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_AIGroup.uc    
//  AUTHOR:  Alex Cheng  --  12/10/2014
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AIGroup extends XComGameState_BaseObject
	dependson(XComAISpawnManager, XComGameState_AIUnitData)
	native(AI)
	config(AI);

// The Name of this encounter, used for determining when a specific group has been engaged/defeated
var Name EncounterID;

// How wide should this group's encounter band be?
var float MyEncounterZoneWidth;

// How deep should this group's encounter band be?
var float MyEncounterZoneDepth;

// The offset from the LOP for this group.
var float MyEncounterZoneOffsetFromLOP;

// The index of the encounter zone that this group should attempt to roam around within
var float MyEncounterZoneOffsetAlongLOP;

var array<StateObjectReference> m_arrMembers; // Current list of group members
var	array<TTile> m_arrGuardLocation;

var array<StateObjectReference> m_arrDisplaced; // Reference to unit that is not currently a member due to mind-control.
												// Keeping track of unit to be able to restore the unit if mind-control wears off.

var float InfluenceRange;

// Patrol group data. TODO- keep track of this here.
//var TTile kCurr; // Tile location of current node
//var TTile kLast; // Tile location of last node.
//var array<TTile> kLoc;

var bool bObjective; // Objective Guard?
var bool bPlotPath;

var bool bInterceptObjectiveLocation;
var bool bProcessedScamper; //TRUE if this AI group has scampered
var bool bPendingScamper;	//TRUE if this AI group has been told to scamper, but has not started to scamper yet ( can happen during group moves that reveal XCOM )

// the current destination that this group will attempt to be moving towards while in green alert
var Vector		CurrentTargetLocation;
var int			TurnCountForLastDestination;

struct native ai_group_stats
{
	var int m_iInitialMemberCount;
	var array<StateObjectReference> m_arrDead;		// Keeping track of units that have died.
};
var ai_group_stats m_kStats;


////////////////////////////////////////////////////////////////////////////////////////
// Reveal/Scamper data

// The alert data which instigated the reveal/scamper.
var EAlertCause DelayedScamperCause;

// The object Id of the unit who was the source of the alert data causing this reveal/scamper.
var int RevealInstigatorUnitObjectID;

// The Object IDs of all units that were concealed prior to this reveal, but had their concealment broken.
var array<int> PreviouslyConcealedUnitObjectIDs;

// The Object IDs of the revealed units who are surprised by the reveal.
var array<int> SurprisedScamperUnitIDs;

// If this group is mid-move, this is the step along the pre-calculated movement path at which the reveal will take place.
var int FinalVisibilityMovementStep;

// If this group is mid-move, this is the list of units within this group that still need to process some of their move before the group can reveal.
var array<int> WaitingOnUnitList;

// True while this group is in the process of performing a reveal/scamper.
var bool SubmittingScamperReflexGameState;

////////////////////////////////////////////////////////////////////////////////////////
// Ever Sighted

// Until true, this group has not been sighted by enemies, so the first sighting should show a camera look at.
var bool EverSightedByEnemy;

////////////////////////////////////////////////////////////////////////////////////////

var config float SURPRISED_SCAMPER_CHANCE;
var config float DESTINATION_REACHED_SIZE_SQ;
var config float MAX_TURNS_BETWEEN_DESTINATIONS;

////////////////////////////////////////////////////////////////////////////////////////
// Fallback behavior variables
var bool bHasCheckedForFallback;	// true if the decision to fallback or not has already been made.
var bool bFallingBack;				// true if Fallback is active. 
var bool bPlayedFallbackCallAnimation;		// Flag if the call animation has happened already.
var StateObjectReference FallbackGroup;		// Fallback group reference.  
var config array<Name> FallbackExclusionList; // List of unit types that are unable to fallback
var config float FallbackChance;			  // Chance to fallback, currently set to 50%.

// Config variables to determine when to disable fallback.
// Fallback is disabled at the start of the AI turn when either of the following conditions are filled:
//   1) XCom has caused the fallback-to-group to scamper, and no other groups can be set as an alternate fallback, or
//   2) the Unit is in range of the fallback group, as defined by the config value below, at which time the unit joins the group at green alert
var config int UnitInFallbackRangeMeters;  // Distance from fallback destination to be considered "In Fallback Area"
var int FallbackMaximumOverwatchCount;	// Any more overwatchers than this will prevent fallback from activating.
////////////////////////////////////////////////////////////////////////////////////////
const Z_TILE_RANGE = 3;
function OnUnitDeath( StateObjectReference DeadUnit, bool bIsAIUnit )
{
	if (bIsAIUnit)
	{
		if (m_arrMembers.Find('ObjectID', DeadUnit.ObjectID) != -1 && m_kStats.m_arrDead.Find('ObjectID', DeadUnit.ObjectID) == -1)
		{
			m_kStats.m_arrDead.AddItem(DeadUnit);
		}
	}
}

function bool GetLivingMembers(out array<int> arrMemberIDs)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Member;
	local StateObjectReference Ref;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if (Member != None && Member.IsAlive())
		{
			arrMemberIDs.AddItem(Ref.ObjectID);
		}
	}
	return arrMemberIDs.Length > 0;
}

function Vector GetGroupMidpoint(optional int HistoryIndex = -1)
{
	local TTile GroupMidpointTile;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	GetUnitMidpoint(GroupMidpointTile, HistoryIndex);
	return WorldData.GetPositionFromTileCoordinates(GroupMidpointTile);
}

// Get midpoint of all living members in this group.
function bool GetUnitMidpoint(out TTile Midpoint, optional int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Member;
	local StateObjectReference Ref;
	local TTile MinTile, MaxTile;
	local bool bInited;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID, , HistoryIndex));
		if( Member != None && Member.IsAlive() )
		{
			if( !bInited )
			{
				MinTile = Member.TileLocation;
				MaxTile = Member.TileLocation;
				bInited = true;
			}
			else
			{
				MinTile.X = Min(MinTile.X, Member.TileLocation.X);
				MinTile.Y = Min(MinTile.Y, Member.TileLocation.Y);
				MinTile.Z = Min(MinTile.Z, Member.TileLocation.Z);
				MaxTile.X = Max(MaxTile.X, Member.TileLocation.X);
				MaxTile.Y = Max(MaxTile.Y, Member.TileLocation.Y);
				MaxTile.Z = Max(MaxTile.Z, Member.TileLocation.Z);
			}
		}
	}
	if( bInited )
	{
		Midpoint.X = (MinTile.X + MaxTile.X)*0.5f;
		Midpoint.Y = (MinTile.Y + MaxTile.Y)*0.5f;
		Midpoint.Z = (MinTile.Z + MaxTile.Z)*0.5f;
		return true;
	}
	return false;
}

// Returns true if any living units are red or orange alert.
function bool IsEngaged() 
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_AIUnitData AIData;
	local StateObjectReference Ref, KnowledgeRef;
	local int AlertLevel, DataID;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if( Unit != None && Unit.IsAlive() )
		{
			AlertLevel = Unit.GetCurrentStat(eStat_AlertLevel);
			if (AlertLevel == `ALERT_LEVEL_RED)
			{
				return true;
			}
			if(AlertLevel == `ALERT_LEVEL_GREEN )
			{
				continue;
			}
			// Orange alert check.  
			DataID = Unit.GetAIUnitDataID();
			if( DataID > 0 )
			{
				AIData = XComGameState_AIUnitData(History.GetGameStateForObjectID(DataID));
				if( AIData.HasAbsoluteKnowledge(KnowledgeRef) )  
				{
					return true;
				}
			}
		}
	}
	return false;
}

function float GetMaxMobility()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Member;
	local StateObjectReference Ref;
	local float MaxMobility;

	History = `XCOMHISTORY;
	foreach m_arrMembers(Ref)
	{
		Member = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if( Member != None && Member.IsAlive() )
		{
			MaxMobility = Max(MaxMobility, Member.GetCurrentStat(eStat_Mobility));
		}
	}
	return MaxMobility;
}

// Determine if this AI Group should currently be moving towards an intercept location
function bool ShouldMoveToIntercept(out Vector TargetInterceptLocation, XComGameState NewGameState, XComGameState_AIPlayerData PlayerData)
{
	local XComGameState_BattleData BattleData;
	local Vector CurrentGroupLocation;
	local EncounterZone MyEncounterZone;
	local XComAISpawnManager SpawnManager;
	local XComTacticalMissionManager MissionManager;
	local MissionSchedule ActiveMissionSchedule;
	local array<Vector> EncounterCorners;
	local int CornerIndex;
	local XComGameState_AIGroup NewGroupState;
	local XComGameStateHistory History;
	local Vector CurrentXComLocation;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if( XComSquadMidpointPassedGroup() )
	{
		if( !GetNearestEnemyLocation(GetGroupMidpoint(), TargetInterceptLocation) )
		{
			// If for some reason the nearest enemy can't be found, send these units to the objective.
			TargetInterceptLocation = BattleData.MapData.ObjectiveLocation;
		}
		return true;
	}

	// This flag is turned on if XCom is unengaged, and the SeqAct_CompleteMissionObjective has fired, and this is the closest group -or cheatmgr setting bAllPodsConvergeOnMissionComplete is on.
	if( bInterceptObjectiveLocation )
	{
		TargetInterceptLocation = BattleData.MapData.ObjectiveLocation;
		return true;
	}

	// TODO: otherwise, try to patrol around within the current encounter zone
	CurrentGroupLocation = GetGroupMidpoint();

	if( PlayerData.StatsData.TurnCount - TurnCountForLastDestination > MAX_TURNS_BETWEEN_DESTINATIONS || 
	   VSizeSq(CurrentGroupLocation - CurrentTargetLocation) < DESTINATION_REACHED_SIZE_SQ )
	{
		// choose new target location
		SpawnManager = `SPAWNMGR;
		MissionManager = `TACTICALMISSIONMGR;
		MissionManager.GetActiveMissionSchedule(ActiveMissionSchedule);
		CurrentXComLocation = SpawnManager.GetCurrentXComLocation();
		MyEncounterZone = SpawnManager.BuildEncounterZone(
			BattleData.MapData.ObjectiveLocation,
			CurrentXComLocation,
			MyEncounterZoneDepth,
			MyEncounterZoneWidth,
			MyEncounterZoneOffsetFromLOP,
			MyEncounterZoneOffsetAlongLOP);

		EncounterCorners[0] = SpawnManager.CastVector(MyEncounterZone.Origin);
		EncounterCorners[0].Z = CurrentGroupLocation.Z;
		EncounterCorners[1] = EncounterCorners[0] + SpawnManager.CastVector(MyEncounterZone.SideA);
		EncounterCorners[2] = EncounterCorners[1] + SpawnManager.CastVector(MyEncounterZone.SideB);
		EncounterCorners[3] = EncounterCorners[0] + SpawnManager.CastVector(MyEncounterZone.SideB);

		for( CornerIndex = EncounterCorners.Length - 1; CornerIndex >= 0; --CornerIndex )
		{
			if( VSizeSq(CurrentGroupLocation - EncounterCorners[CornerIndex]) < DESTINATION_REACHED_SIZE_SQ )
			{
				EncounterCorners.Remove(CornerIndex, 1);
			}
		}

		if( EncounterCorners.Length > 0 )
		{
			TargetInterceptLocation = EncounterCorners[`SYNC_RAND_STATIC(EncounterCorners.Length)];

			NewGroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', ObjectID));
			NewGameState.AddStateObject(NewGroupState);
			NewGroupState.CurrentTargetLocation = TargetInterceptLocation;
			NewGroupState.TurnCountForLastDestination = PlayerData.StatsData.TurnCount;

			return true;
		}
	}

	return false;
}

// Return true if XCom units have passed our group location.
function bool XComSquadMidpointPassedGroup()
{
	local vector GroupLocationToEnemy;
	local vector GroupLocationToEnemyStart;
	local vector GroupLocation;
	local vector GroupLocationOnAxis;

	local TwoVectors CurrentLineOfPlay;
	local XGAIPlayer AIPlayer;

	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	AIPlayer.m_kNav.UpdateCurrentLineOfPlay(CurrentLineOfPlay);
	GroupLocation = GetGroupMidpoint();
	GroupLocationOnAxis = AIPlayer.m_kNav.GetNearestPointOnAxisOfPlay(GroupLocation);

	GroupLocationToEnemy = CurrentLineOfPlay.v1 - GroupLocationOnAxis;
	GroupLocationToEnemyStart = AIPlayer.m_kNav.m_kAxisOfPlay.v1 - GroupLocationOnAxis;

	if( GroupLocationToEnemyStart dot GroupLocationToEnemy < 0 )
	{
		return true;
	}
	return false;
}

function bool GetNearestEnemyLocation(vector TargetLocation, out vector ClosestLocation)
{
	local float fDistSq, fClosest;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int ClosestID;
	local vector UnitLocation;
	local XComWorldData World;
	World = `XWORLD;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom && !UnitState.bRemovedFromPlay && UnitState.IsAlive() && !UnitState.IsBleedingOut() )
		{
			UnitLocation = World.GetPositionFromTileCoordinates(UnitState.TileLocation);
			fDistSq = VSizeSq(UnitLocation - TargetLocation);

			if( ClosestID <= 0 || fDistSq < fClosest )
			{
				ClosestID = UnitState.ObjectID;
				fClosest = fDistSq;
				ClosestLocation = UnitLocation;
			}
		}
	}

	if( ClosestID > 0 )
	{
		return true;
	}
	return false;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function GatherBrokenConcealmentUnits()
{
	local XComGameStateHistory History;
	local int EventChainStartHistoryIndex;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	PreviouslyConcealedUnitObjectIDs.Length = 0;
	EventChainStartHistoryIndex = History.GetEventChainStartIndex();

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( !UnitState.IsConcealed() && UnitState.WasConcealed(EventChainStartHistoryIndex) )
		{
			PreviouslyConcealedUnitObjectIDs.AddItem(UnitState.ObjectID);
		}
	}
}

function bool IsWaitingOnUnitForReveal(XComGameState_Unit JustMovedUnitState)
{
	return WaitingOnUnitList.Find(JustMovedUnitState.ObjectID) != INDEX_NONE;
}

function StopWaitingOnUnitForReveal(XComGameState_Unit JustMovedUnitState)
{
	WaitingOnUnitList.RemoveItem(JustMovedUnitState.ObjectID);

	// just removed the last impediment to performing the reveal
	if( WaitingOnUnitList.Length == 0 )
	{
		ProcessReflexMoveActivate();
	}
}

function InitiateReflexMoveActivate(XComGameState_Unit TargetUnitState, EAlertCause eCause)
{
	DelayedScamperCause = eCause;
	RevealInstigatorUnitObjectID = TargetUnitState.ObjectID;
	GatherBrokenConcealmentUnits();

	ProcessReflexMoveActivate();
}

private function bool CanScamper(XComGameState_Unit UnitStateObject)
{
	return UnitStateObject.IsAlive() &&
		(!UnitStateObject.IsIncapacitated()) &&
		UnitStateObject.bTriggerRevealAI &&
		!UnitStateObject.IsPanicked() &&
		!UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.PanickedName) &&
		!UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.BurrowedName) &&
	    (`CHEATMGR == None || !`CHEATMGR.bAbortScampers);
}

function ApplyAlertAbilityToGroup(EAlertCause eCause)
{
	local StateObjectReference Ref;
	local XComGameState_Unit UnitStateObject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach m_arrMembers(Ref)
	{
		UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));

		UnitStateObject.ApplyAlertAbilityForNewAlertData(eCause);
	}
}

function ProcessReflexMoveActivate()
{
	local XComGameStateHistory History;
	local int Index, NumScamperers, NumSurprised;
	local XComGameState_Unit UnitStateObject, TargetStateObject, NewUnitState;
	local XComGameState_AIGroup NewGroupState;
	local StateObjectReference Ref;
	local XGAIPlayer AIPlayer;
	local XComGameState NewGameState;
	local array<StateObjectReference> Scamperers;
	local float SurprisedChance;
	local bool bUnitIsSurprised;

	History = `XCOMHISTORY;

	if( !bProcessedScamper ) // Only allow scamper once.
	{
		//First, collect a list of scampering units. Due to cheats and other mechanics this list could be empty, in which case we should just skip the following logic
		foreach m_arrMembers(Ref)
		{
			UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
			if(CanScamper(UnitStateObject))
			{	
				Scamperers.AddItem(Ref);
			}
		}

		NumScamperers = Scamperers.Length;
		if( NumScamperers > 0 )
		{
			//////////////////////////////////////////////////////////////
			// Kick off the BT scamper actions

			//Find the AI player data object
			AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
			`assert(AIPlayer != none);
			TargetStateObject = XComGameState_Unit(History.GetGameStateForObjectID(RevealInstigatorUnitObjectID));

			// Give the units their scamper action points
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Scamper Action Points");
			foreach Scamperers(Ref)
			{
				NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Ref.ObjectID));
				if( NewUnitState.IsAbleToAct() )
				{
					NewUnitState.ActionPoints.Length = 0;
					NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint); //Give the AI one free action point to use.
					NewGameState.AddStateObject(NewUnitState);

					if (NewUnitState.GetMyTemplate().OnRevealEventFn != none)
					{
						NewUnitState.GetMyTemplate().OnRevealEventFn(NewUnitState);
					}
				}
				else
				{
					NewGameState.PurgeGameStateForObjectID(NewUnitState.ObjectID);
				}
			}

			NewGroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', ObjectID));
			NewGameState.AddStateObject(NewGroupState);
			NewGroupState.bProcessedScamper = true;
			NewGroupState.bPendingScamper = true;

			if(NewGameState.GetNumGameStateObjects() > 0)
			{
				// Now that we are kicking off a scamper Behavior Tree (latent), we need to handle the scamper clean-up on
				// an event listener that waits until after the scampering behavior decisions are made.
				for( Index = 0; Index < NumScamperers; ++Index )
				{
					UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Scamperers[Index].ObjectID));

					// choose which scampering units should be surprised
					// randomly choose half to be surprised
					if(PreviouslyConcealedUnitObjectIDs.Length > 0)
					{
						if( UnitStateObject.IsGroupLeader() )
						{
							bUnitIsSurprised = false;
						}
						else
						{
							NumSurprised = NewGroupState.SurprisedScamperUnitIDs.Length;
							SurprisedChance = (float(NumScamperers) * SURPRISED_SCAMPER_CHANCE - NumSurprised) / float(NumScamperers - Index);
							bUnitIsSurprised = `SYNC_FRAND() <= SurprisedChance;
						}

						if(bUnitIsSurprised)
						{
							NewGroupState.SurprisedScamperUnitIDs.AddItem(Scamperers[Index].ObjectID);
						}
					}

					AIPlayer.QueueScamperBehavior(UnitStateObject, TargetStateObject, bUnitIsSurprised, Index == 0);
				}

				`TACTICALRULES.SubmitGameState(NewGameState);
				`BEHAVIORTREEMGR.TryUpdateBTQueue();
			}
			else
			{
				History.CleanupPendingGameState(NewGameState);
			}
		}
	}
}

function OnScamperBegin()
{
	local XComGameStateHistory History;
	local XComGameStateContext_RevealAI ScamperContext;
	local StateObjectReference Ref;
	local XComGameState_Unit UnitStateObject;
	local X2GameRuleset Ruleset;
	local array<int> ScamperList;
	local XComGameState_Unit GroupLeaderUnitState;
	local XComGameState_AIGroup AIGroupState;


	History = `XCOMHISTORY;
	Ruleset = `XCOMGAME.GameRuleset;

	//////////////////////////////////////////////////////////////
	// Reveal Begin
	foreach m_arrMembers(Ref)
	{
		UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
		if( CanScamper(UnitStateObject) )
		{
			ScamperList.AddItem(Ref.ObjectID);
		}
	}

	// Prevent a red screen by only submitting this game state if we have units that are scampering.
	if(ScamperList.Length > 0 )
	{
		ScamperContext = XComGameStateContext_RevealAI(class'XComGameStateContext_RevealAI'.static.CreateXComGameStateContext());
		ScamperContext.RevealAIEvent = eRevealAIEvent_Begin;
		ScamperContext.CausedRevealUnit_ObjectID = RevealInstigatorUnitObjectID;
		ScamperContext.ConcealmentBrokenUnits = PreviouslyConcealedUnitObjectIDs;
		ScamperContext.SurprisedScamperUnitIDs = SurprisedScamperUnitIDs;

		//Mark this game state as a visualization fence (ie. we need to see whatever triggered the scamper fully before the scamper happens)
		ScamperContext.SetVisualizationFence(true);
		ScamperContext.RevealedUnitObjectIDs = ScamperList;


		// determine if this is the first ever sighting of this type of enemy
		GroupLeaderUnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_arrMembers[0].ObjectID));
		
		AIGroupState = GroupLeaderUnitState.GetGroupMembership();

		if (AIGroupState != None && !AIGroupState.EverSightedByEnemy)
		{
			ScamperContext.bDoSoldierVO = true;
		}

		Ruleset.SubmitGameStateContext(ScamperContext);
	}
}

// After Scamper behavior trees have finished running, clean up all the scamper vars.
function OnScamperComplete()
{
	local XComGameStateContext_RevealAI ScamperContext;
	local XGAIPlayer AIPlayer;
	local StateObjectReference Ref;
	local XComGameStateContext_RevealAI AIRevealContext;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability AbilityContext;
	local Array<int> SourceObjects;
	local bool PreventSimultaneousVisualization;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	//Find the AI player data object, and mark the reflex action state done.
	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());

	ScamperContext = XComGameStateContext_RevealAI(class'XComGameStateContext_RevealAI'.static.CreateXComGameStateContext());
	ScamperContext.RevealAIEvent = eRevealAIEvent_End; // prevent from reflexing again.
	foreach m_arrMembers(Ref)
	{
		ScamperContext.RevealedUnitObjectIDs.AddItem(Ref.ObjectID);
	}
	ScamperContext.CausedRevealUnit_ObjectID = RevealInstigatorUnitObjectID;

	`XCOMGAME.GameRuleset.SubmitGameStateContext(ScamperContext);

	PreventSimultaneousVisualization = false;
	foreach History.IterateContextsByClassType(class'XComGameStateContext', Context)
	{
		AIRevealContext = XComGameStateContext_RevealAI(Context);
		if( AIRevealContext != None && AIRevealContext.RevealAIEvent == eRevealAIEvent_Begin )
		{
			break;
		}

		AbilityContext = XComGameStateContext_Ability(Context);
		if( AbilityContext != None && AbilityContext.InputContext.AbilityTemplateName != 'StandardMove' )
		{
			if( SourceObjects.Find(AbilityContext.InputContext.SourceObject.ObjectID) != INDEX_NONE )
			{
				PreventSimultaneousVisualization = true;
				break;
			}

			SourceObjects.AddItem(AbilityContext.InputContext.SourceObject.ObjectID);
		}
	}

	if( PreventSimultaneousVisualization )
	{
		foreach History.IterateContextsByClassType(class'XComGameStateContext', Context)
		{
			AIRevealContext = XComGameStateContext_RevealAI(Context);
			if( AIRevealContext != None && AIRevealContext.RevealAIEvent == eRevealAIEvent_Begin )
			{
				break;
			}

			Context.SetVisualizationStartIndex(-1);
		}
	}
	

	ClearScamperData();
	AIPlayer.ClearWaitForScamper();
}

function ClearScamperData()
{
	local XComGameState_AIGroup NewGroupState;
	local XComGameState NewGameState;

	// Mark the end of the reveal/scamper process
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIRevealComplete [" $ ObjectID $ "]");
	NewGroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', ObjectID));
	NewGameState.AddStateObject(NewGroupState);

	NewGroupState.DelayedScamperCause = eAC_None;
	NewGroupState.RevealInstigatorUnitObjectID = INDEX_NONE;
	NewGroupState.FinalVisibilityMovementStep = INDEX_NONE;
	NewGroupState.WaitingOnUnitList.Length = 0;
	NewGroupState.PreviouslyConcealedUnitObjectIDs.Length = 0;
	NewGroupState.SurprisedScamperUnitIDs.Length = 0;
	NewGroupState.SubmittingScamperReflexGameState = false;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function bool IsFallingBack(optional out vector Destination)
{
	if( bFallingBack )
	{
		Destination = GetFallBackDestination();
		return true;
	}
	return false;
}

function vector GetFallBackDestination()
{
	local XComGameState_AIGroup GroupState;
	local vector Destination;
	GroupState = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(FallbackGroup.ObjectID));
	Destination = GroupState.GetGroupMidpoint();
	return Destination;
}

function bool ShouldDoFallbackYell()
{
	return !bPlayedFallbackCallAnimation;
}

// Update while fallback is active.  Disable fallback once XCom reaches the area.
function UpdateFallBack()
{
	local array<int> LivingUnits;
	local XComGameState_Unit UnitState;
	local bool bDisableFallback;
	local StateObjectReference AlternateGroup, TransferUnitRef;

	if( bFallingBack )
	{
		GetLivingMembers(LivingUnits);
		if( LivingUnits.Length > 0 )
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LivingUnits[0]));
			if( IsXComVisibleToFallbackArea() )
			{
				// Option A - Pick another group to fallback to, if any.
				if( HasRetreatLocation(XGUnit(UnitState.GetVisualizer()), AlternateGroup) )
				{
					`LogAI("FALLBACK- Changing fallback-to-group since original group has already scampered.");
					SetFallbackStatus(true, AlternateGroup);
					return;
				}
				else
				{
					`LogAI("FALLBACK- Disabling fallback due to XCom soldiers in the fallback zone.");
					bDisableFallback = true;
				}
			}

			// Disable fallback if this unit is already in the fallback area, and XCom is already within range.
			if( IsUnitInFallbackArea(UnitState) )
			{
				bDisableFallback = true;
				TransferUnitRef = UnitState.GetReference();
			}
		}
		else
		{
			`LogAI("FALLBACK- Disabling fallback due to no living units in group remaining.");
			bDisableFallback = true;
		}
		if( bDisableFallback )
		{
			SetFallbackStatus(false, FallbackGroup, TransferUnitRef);
		}
	}
}

function bool IsUnitInFallbackArea(XComGameState_Unit Unit)
{
	local vector UnitLocation;
	UnitLocation = `XWORLD.GetPositionFromTileCoordinates(Unit.TileLocation);

	return IsInFallbackArea(UnitLocation);
}

function bool IsInFallbackArea( vector UnitLocation )
{
	local vector FallbackLocation;
	FallbackLocation = GetFallBackDestination();
	if( VSizeSq(UnitLocation - FallbackLocation) < Square(`METERSTOUNITS(UnitInFallbackRangeMeters) ))
	{
		return true;
	}
	return false;
}

// Once the target group has scampered, fallback should be disabled, or transferred to another group.
function bool IsXComVisibleToFallbackArea()
{
	local XComGameState_AIGroup TargetGroup;
	TargetGroup = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(FallbackGroup.ObjectID));
	return (TargetGroup != None && TargetGroup.bProcessedScamper);
}

// Update game state
function SetFallbackStatus(bool bFallback, optional StateObjectReference FallbackRef, optional StateObjectReference TransferUnitRef)
{
	local XComGameState_AIGroup NewGroupState, TargetGroup;
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData NewAIPlayerData;
	local XGAIPlayer AIPlayer;
	local XComGameStateHistory History;
	local XComGameState_Unit NewUnitState, LeaderState;
	local float LeaderAlert;

	if( bFallback == bFallingBack && bHasCheckedForFallback && FallbackGroup == FallbackRef && TransferUnitRef.ObjectID <= 0)
	{
		// No change, early exit.
		return;
	}

	History = `XCOMHISTORY;

	NewGameState = History.GetStartState(); // Fallback can be disabled when this group is spawned if it is a singleton.
	if( NewGameState == none )
	{
		// Create a new gamestate to update the fallback variables.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set Fallback Status");
	}

	NewGroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', ObjectID));
	NewGroupState.bHasCheckedForFallback = true;
	NewGroupState.bFallingBack = bFallback;
	NewGroupState.FallbackGroup = FallbackRef;
	NewGameState.AddStateObject(NewGroupState);

	if( bFallback )
	{
		// Add to fallback count in AIPlayerData.  
		AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
		NewAIPlayerData = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', AIPlayer.GetAIDataID()));
		NewAIPlayerData.StatsData.FallbackCount++;
		NewGameState.AddStateObject(NewAIPlayerData);
	}
	
	if( TransferUnitRef.ObjectID > 0 ) // If this ref exists, we want to transfer the unit to the fallback-to group.
	{
		`Assert(bFallback == false && FallbackRef.ObjectID > 0); // Cannot be set to fallback and have a transfer unit.

		// We also want to make some changes to the unit to make him more ready to join the group.
		NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', TransferUnitRef.ObjectID));
		// Unit needs to have the same unrevealed pod status.
		NewUnitState.bTriggerRevealAI = true;
		TargetGroup = XComGameState_AIGroup(History.GetGameStateForObjectID(FallbackRef.ObjectID));
		LeaderState = XComGameState_Unit(History.GetGameStateForObjectID(TargetGroup.m_arrMembers[0].ObjectID));
		LeaderAlert = LeaderState.GetCurrentStat(eStat_AlertLevel);
		// Unit needs to have the same alert level as the rest of the pod.
		if( NewUnitState.GetCurrentStat(eStat_AlertLevel) != LeaderAlert )
		{
			NewUnitState.SetCurrentStat(eStat_AlertLevel, LeaderAlert);
		}
		NewGameState.AddStateObject(NewUnitState);

		// Now to transfer the unit out of its old group and into its new group.
		AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
		NewAIPlayerData = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', AIPlayer.GetAIDataID()));
		if( !NewAIPlayerData.TransferUnitToGroup(FallbackRef, TransferUnitRef, NewGameState) )
		{ 
			`RedScreen("Error in transferring fallback unit to new group. @acheng");
		}
		NewGameState.AddStateObject(NewAIPlayerData);
	}

	if( NewGameState != History.GetStartState() )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	// If a unit was transferred, update group listings in visualizers after the gamestates are updated.
	if( TransferUnitRef.ObjectID > 0 && AIPlayer != None && TargetGroup != None)
	{
		if( TargetGroup.m_arrMembers.Length > 0 )
		{
			AIPlayer.m_kNav.TransferUnitToGroup(TargetGroup.m_arrMembers[0].ObjectID, TransferUnitRef.ObjectID);
		}
		else
		{
			`RedScreen("TransferUnitGroup On Fallback failure - Target group has no units? @acheng");
		}
	}
}

// Do a fallback check.  Check if the last living unit qualifies and roll the dice.
function CheckForFallback()
{
	local array<int> LivingUnitIDs;
	local bool bShouldFallback;
	local float Roll;
	local StateObjectReference FallbackGroupRef;
	GetLivingMembers(LivingUnitIDs);

	if( LivingUnitIDs.Length != 1 )
	{
		`RedScreen("Error - XComGameState_AIGroup::CheckForFallback living unit length does not equal 1.  @acheng");
	}
	else
	{
		if( IsUnitEligibleForFallback(LivingUnitIDs[0], FallbackGroupRef) )
		{
			Roll = `SYNC_FRAND_STATIC();
			bShouldFallback =  Roll < FallbackChance;
			`LogAI("FALLBACK CHECK for unit"@LivingUnitIDs[0]@"- Rolled"@Roll@"on fallback check..." @(bShouldFallback ? "Passed, falling back." : "Failed.Not falling back."));
		}
		else
		{
			`LogAI("FALLBACK CHECK for unit"@LivingUnitIDs[0]@"- Failed in check IsUnitEligibleForFallback.");
		}
	}

	SetFallbackStatus(bShouldFallback, FallbackGroupRef);
}

function bool HasRetreatLocation(XGUnit RetreatUnit, optional out StateObjectReference RetreatGroupRef)
{
	local XGAIPlayer AIPlayer;
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	return AIPlayer.HasRetreatLocation(RetreatUnit, RetreatGroupRef);
}

function bool HasHitRetreatCap()
{
	local XGAIPlayer AIPlayer;
	local XComGameState_AIPlayerData AIData;
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIPlayer.GetAIDataID()));
	if( AIData.RetreatCap < 0 ) // Unlimited retreating when retreat cap is negative.
	{
		return false;
	}
	return AIData.StatsData.FallbackCount >= AIData.RetreatCap;
}

function bool IsUnitEligibleForFallback(int UnitID, optional out StateObjectReference RetreatGroupRef)
{
	local XComGameState_Unit UnitState;
	local array<StateObjectReference> Overwatchers;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));

	if( !HasRetreatLocation(XGUnit(UnitState.GetVisualizer()), RetreatGroupRef) )
	{
		return false;
	}

	`LogAI("Found fallback group for unit"@UnitID@"at  group ID#"$RetreatGroupRef.ObjectID);

	if( UnitState != None )
	{
		if( FallbackExclusionList.Find(UnitState.GetMyTemplateName()) != INDEX_NONE )
		{
			`LogAI("Fallback failure: Ineligible for unit type: "$UnitState.GetMyTemplateName());
			return false;
		}
	}

	// Check if the number of overwatchers prevents fallback.
	class'X2TacticalVisibilityHelpers'.static.GetOverwatchingEnemiesOfTarget(UnitID, Overwatchers);
	if( Overwatchers.Length > FallbackMaximumOverwatchCount )
	{
		`LogAI("Fallback failure: Exceeded maximum overwatch count. Overwatcher count ="@Overwatchers.Length);
		return false;
	}

	// Check if under suppression.  
	if( UnitState.IsUnitAffectedByEffectName(class'X2Effect_Suppression'.default.EffectName) )
	{
		`LogAI("Fallback failure: Unit is being suppressed.");
		return false;
	}

	// Retreat cap - total number of retreats in this mission has reached the retreat cap (specified in AIPlayerData).
	if( HasHitRetreatCap() )
	{
		`LogAI("Fallback failure: Reached retreat cap!");
		return false;
	}

	return true;
}


defaultproperties
{
	RevealInstigatorUnitObjectID = -1
	FinalVisibilityMovementStep = -1
	TurnCountForLastDestination = -100
	FallbackMaximumOverwatchCount = 1;
}