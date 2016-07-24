
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_AIPlayerData.uc    
//  AUTHOR:  Alex Cheng  --  1/27/2014
//  PURPOSE: XComGameState_AIPlayerData, container for persistent data needed by the AI player.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AIPlayerData extends XComGameState_BaseObject
	native(AI)
	dependson(XComAISpawnManager, XComGameState_AIUnitData)
	config(AI);

struct native AIPlayerStats
{
	var bool bAITakenDamage;  // Tracked for Reinforcement triggers.
	var bool bAIDeath;		// Tracked for Reinforcement triggers.
	var bool bEnemyDamaged;	// Tracked for Reinforcement triggers.

	var array<int> TakenDamageUnitIDs; // Keeping track of units that have taken damage since last turn.  Reset in OnEndTurn
	var array<int> TakenFireUnitIDs;   // Keeping track of units that have been unsuccessfully attacked since last turn. Reset in OnEndTurn

	var int NumEngagedAI;				// Number of active AI currently in combat (In Red or Orange alert)
	var int ConsecutiveInactiveTurns;	// Reset to 0 when an AI is alerted. Increments at turn start if NumEngagedAI == 0.  Or, maybe it should be 
	var int TurnCount;

	var int FallbackCount;				// Number of times a unit in this mission has fallen back.
};

var int m_iPlayerObjectID; // Is this necessary? why not use this objects ObjectID?

var AIPlayerStats StatsData;
var int m_iLastEndTurnHistoryIndex;
var int m_iYellCooldown;
var int m_iCivilianYellCooldown;
var StateObjectReference PriorityTarget; // Either reference to a Unit or Interactive Object.

var array<StateObjectReference> GroupList, PatrolGroupList;
//var private native Map_Mirror       UnitToGroupMap{TMap<INT, INT>};        //  maps unit id to a group id.
// Using two arrays instead of a map mirror due to serialization issues.
var private array<int> UnitIndexToGroupList;
var private array<int> UnitIndexList;

var bool bDownThrottlingActive, bUpThrottlingActive; // Flags to indicate if throttling is active.
var config int DownThrottleUnitCount;    // Num units engaged to trigger down-throttling.
var config int UpThrottleTurnCount;      // Num turns to pass before triggering up-throttling.
var config float DownThrottleGroupRange; // Groups in this range (meters) that are not engaged in battle are steered away, when Down-Throttling is active.
var TwoVectors CurrentLineOfPlay;		 //  v1 = xcom midpoint, v2 = objective location.
var string ThrottleDebugText;			 // Debugging use only.  On-screen info text while AIDebugFightManager command is active.

var config array<int> MaxEngagedEnemies; // Number of enemies that can attack the player, per difficulty level. -1 = Unlimited attacks.

var bool bConvergedToObjective;
struct native KismetPostedJob
{
	var Name	JobName;
	var int		PriorityValue;  // Corresponds to position in Job queue to insert this job.  Default=0, this job is placed first.
	var int		TargetID;

	structcpptext
	{
		FKismetPostedJob()
		{
			appMemzero(this, sizeof(FKismetPostedJob));
		}

		FKismetPostedJob(EEventParm)
		{
			appMemzero(this, sizeof(FKismetPostedJob));
		}

		FORCEINLINE UBOOL operator==(const FKismetPostedJob &Other) const
		{
			return JobName == Other.JobName && TargetID == Other.TargetID;
		}
	}
};

var array<KismetPostedJob> KismetJobs;	// List of jobs posted by Kismet. (Moved here from JobMgr for save/load.)
var config int RetreatCap; // Max number of units that can fall back to the objective area (or nearest guard group).  -1 == no limit.
var transient StateObjectReference EngagedUnitRef; // Only pertinent when there is one active AI unit, for fallback.

native function InitGroupLookup();
native function int GetGroupObjectIDFromUnit( StateObjectReference kUnitRef );
native function AddUnitToGroupLookup( StateObjectReference kGroupRef, StateObjectReference kUnitRef );
native function RemoveFromGroupLookup(StateObjectReference kUnitRef);

function Init(int AIPlayerObjectID, XComGameState NewGameState)
{
	UpdateData(AIPlayerObjectID);
	InitGroupLookup();
	UpdateGroupData(NewGameState);
}

function OnBeginTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnBeginTacticalPlay();

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'OnMissionObjectiveComplete', OnObjectiveComplete, ELD_OnStateSubmitted, , ThisObj);
}

function OnEndTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay();

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.UnRegisterFromEvent(ThisObj, 'OnMissionObjectiveComplete');
}

function EventListenerReturn OnObjectiveComplete(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_AIGroup Group;
	local XComGameState_AIPlayerData PlayerData;
	local StateObjectReference GroupRef;
	local XComGameState NewGameState;
	BattleData = XComGameState_BattleData(EventData);
	if( !bConvergedToObjective && BattleData.AllStrategyObjectivesCompleted() )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
		// Kick off heat-seek on nearest (or all) groups.
		if( `CHEATMGR != None && `CHEATMGR.bAllPodsConvergeOnMissionComplete )
		{
			foreach GroupList(GroupRef)
			{
				Group = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', GroupRef.ObjectID));
				Group.bInterceptObjectiveLocation = true;
				NewGameState.AddStateObject(Group);
			}
		}
		else
		{
			// Set nearest group to heat seek only if XCom is not already engaged.
			GroupRef = GetNearestGroup(BattleData.MapData.ObjectiveLocation);
			if(GroupRef.ObjectID > 0)
			{
				Group = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(GroupRef.ObjectID));
				if( Group != None && !Group.IsEngaged() )
				{
					Group = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', GroupRef.ObjectID));
					Group.bInterceptObjectiveLocation = true;
					NewGameState.AddStateObject(Group);
				}
			}
		}
		PlayerData = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', ObjectID));
		PlayerData.bConvergedToObjective = true;
		NewGameState.AddStateObject(PlayerData);
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

// Return nearest (living) group to location.  Skip turrets or groups that cannot move.
function StateObjectReference GetNearestGroup(vector TargetLocation)
{
	local XComGameState_AIGroup Group;
	local StateObjectReference GroupRef;
	local StateObjectReference ClosestGroup;
	local XComGameStateHistory History;
	local float fDistSq, fClosest;

	History = `XCOMHISTORY;
	foreach GroupList(GroupRef)
	{
		Group = XComGameState_AIGroup(History.GetGameStateForObjectID(GroupRef.ObjectID));
		if( Group.GetMaxMobility() > 0 ) // Check unit can move (and implicitly check is alive)
		{
			fDistSq = VSizeSq(Group.GetGroupMidpoint() - TargetLocation);
			if( ClosestGroup.ObjectID == 0 || fDistSq < fClosest )
			{
				ClosestGroup = GroupRef;
				fClosest = fDistSq;
			}
		}
	}
	return ClosestGroup;
}

function SetPriorityTarget( StateObjectReference kTarget )
{
	PriorityTarget = kTarget;
}

function bool HasPriorityTargetLocation(optional out TTile TargetTile)
{
	local XComGameState_BaseObject TargetObj;
	local XComGameState_Unit TargetUnit;
	local XComGameState_InteractiveObject TargetInteract;
	TargetObj = `XCOMHISTORY.GetGameStateForObjectID(PriorityTarget.ObjectID);
	if( TargetObj != None )
	{
		TargetUnit = XComGameState_Unit(TargetObj);
		if( TargetUnit != None )
		{
			TargetTile = TargetUnit.TileLocation;
			return true;
		}
		else
		{
			TargetInteract = XComGameState_InteractiveObject(TargetObj);
			if( TargetInteract != None )
			{
				TargetTile = TargetInteract.TileLocation;
				return true;
			}
		}
	}
	return false;
}

function bool HasEnemyVIP(optional out XComGameState_Unit VIP_out)
{
	local ObjectiveSpawnInfo SpawnInfo;
	local Name VIPTemplateName;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComTacticalMissionManager TacticalMissionMgr;
	History = `XCOMHISTORY;
	TacticalMissionMgr = `TacticalMissionMgr;
	SpawnInfo = TacticalMissionMgr.GetObjectiveSpawnInfoByType(TacticalMissionMgr.ActiveMission.sType);
	if( SpawnInfo.DefaultVIPTemplate != '' )
	{
		VIPTemplateName = SpawnInfo.DefaultVIPTemplate;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.GetTeam() != eTeam_Alien && UnitState.GetMyTemplateName() == VIPTemplateName )
			{
				VIP_out = UnitState;
				break;
			}
		}
	}
	return (VIP_out != None);
}

function bool HasPriorityTargetUnit( optional out XComGameState_Unit kPriorityUnit_out )
{
	kPriorityUnit_out = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(PriorityTarget.ObjectID));
	return (kPriorityUnit_out != None);
}

function bool HasPriorityTargetObject( optional out XComGameState_InteractiveObject kPriorityObject_out )
{
	kPriorityObject_out = XComGameState_InteractiveObject(`XCOMHISTORY.GetGameStateForObjectID(PriorityTarget.ObjectID));
	return (kPriorityObject_out != None);
}

function UpdateData(int iPlayerID)
{
	m_iPlayerObjectID  = iPlayerID;
}

function UpdateGroupData(XComGameState NewGameState)
{
	local XComGameState_AIGroup GroupState;
	local StateObjectReference kMemberRef;
	local int iGroupCount, iUnitCount;
	local XComGameStateHistory History;

	GroupList.Length = 0;
	PatrolGroupList.Length = 0;

	// Iterate to find all group states, and rebuild the member-to-group-lookup tables.
	// Start with groups updated in the NewGameState.
	foreach NewGameState.IterateByClassType(class'XComGameState_AIGroup', GroupState)
	{
		GroupList.AddItem(GroupState.GetReference());
		foreach GroupState.m_arrMembers(kMemberRef)
		{
			AddUnitToGroupLookup(GroupState.GetReference(), kMemberRef);
			++iUnitCount;
		}
		++iGroupCount;
	}
	`LogAI("UpdateGroupData::Added "$iUnitCount@"units to "$iGroupCount@"groups from NewGameState.");

	History = `XCOMHISTORY;
	iGroupCount = 0;
	iUnitCount = 0;
	// Iterate through the rest of the groups, skipping groups that were already updated via NewGameState.
	foreach History.IterateByClassType(class'XComGameState_AIGroup', GroupState)
	{
		if (GroupList.Find('ObjectID', GroupState.ObjectID) == INDEX_NONE) // Only add groups that weren't added from the NewGameState.
		{
			GroupList.AddItem(GroupState.GetReference());
			foreach GroupState.m_arrMembers(kMemberRef)
			{
				AddUnitToGroupLookup(GroupState.GetReference(), kMemberRef);
				++iUnitCount;
			}
			++iGroupCount;
		}
	}
	`LogAI("UpdateGroupData::Added "$iUnitCount@"units to "$iGroupCount@"groups from History.");
}

// Update group data based on mind control.
function UpdateForMindControlledUnit(XComGameState NewGameState, XComGameState_Unit MindControlledUnit, StateObjectReference InstigatorRef)
{
	local XComGameState_AIGroup GroupState;
	local int iGroupID;
	// Check team on newly-mind-controlled unit.
	if (MindControlledUnit.GetTeam() == eTeam_Alien)
	{
		// Add to instigator's group.
		if (InstigatorRef.ObjectID > 0)
		{
			iGroupID = GetGroupObjectIDFromUnit(InstigatorRef);
			GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', iGroupID));
			GroupState.m_arrMembers.AddItem(MindControlledUnit.GetReference());
			if (iGroupID <= 0)
			{
				`LogAI("Failed to find group for alien instigator of mind-control!  Adding both instigator and mind-controlled unit to new group!");
				GroupState.m_arrMembers.AddItem(InstigatorRef);
			}

			NewGameState.AddStateObject(GroupState);
			UpdateGroupData(NewGameState);
		}
		else
		{
			`LogAI("Failed to update mind-controlled unit - Team==Alien, no valid instigator found.");
		}
	}
	else if (MindControlledUnit.GetTeam() == eTeam_XCom)
	{ 
		// Remove unit from any existing group.  Add to displaced array.
		if (!RemoveFromCurrentGroup(MindControlledUnit.GetReference(), NewGameState, true))
		{
			`LogAI("Failed to update mind-controlled unit - Team==XCom, no associated group found.");
		}
	}
	else
	{
		`LogAI("Failed to update mind-controlled unit#"$MindControlledUnit.ObjectID$"- Team=="$MindControlledUnit.GetTeam());
	}
}

// Update group data and lookup tables after a previously-mind-controlled unit is no longer mind-controlled 
// and is restored to the original player.
function UpdateForMindControlRemoval(XComGameState NewGameState, XComGameState_Unit MindControlledUnit)
{
	local XComGameState_AIGroup GroupState;
	local int iGroupID, iIndex;
	local XComGameStateHistory History;
	// Check team on previously-mind-controlled unit.
	if (MindControlledUnit.GetTeam() == eTeam_Alien) // Restore unit to former group.
	{
		iIndex = INDEX_NONE;
		History = `XCOMHISTORY;
		// Search through the 'displaced' arrays of all existing groups to find the group this alien used to belong to.
		foreach History.IterateByClassType(class'XComGameState_AIGroup', GroupState)
		{
			iIndex = GroupState.m_arrDisplaced.Find('ObjectID', MindControlledUnit.ObjectID);
			if (iIndex != INDEX_NONE)
			{
				iGroupID = GroupState.ObjectID;
				break;
			}
		}
		
		// Restore unit to his former group.  
		GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', iGroupID));
		GroupState.m_arrMembers.AddItem(MindControlledUnit.GetReference());
		if (iIndex != INDEX_NONE)
		{
			GroupState.m_arrDisplaced.Remove(iIndex, 1);
		}
		NewGameState.AddStateObject(GroupState);
		UpdateGroupData(NewGameState);
	}
	else if (MindControlledUnit.GetTeam() == eTeam_XCom)
	{
		// Remove soldier from group.
		RemoveFromCurrentGroup(MindControlledUnit.GetReference(), NewGameState);
	}
}

function bool RemoveFromCurrentGroup(StateObjectReference UnitRef, XComGameState NewGameState, bool bAddToDisplaced=false)
{
	local XComGameState_AIGroup GroupState;
	local int iGroupID;

	iGroupID = GetGroupObjectIDFromUnit(UnitRef);
	if( iGroupID > 0 )
	{
		GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', iGroupID));
		GroupState.m_arrMembers.RemoveItem(UnitRef);
		if( bAddToDisplaced && GroupState.m_arrDisplaced.Find('ObjectID', UnitRef.ObjectID) == INDEX_NONE )
		{
			GroupState.m_arrDisplaced.AddItem(UnitRef);
		}
		NewGameState.AddStateObject(GroupState);
		UpdateGroupData(NewGameState);
		RemoveFromGroupLookup(UnitRef);
		return true;
	}
	return false;
}

function bool TransferUnitToGroup(StateObjectReference GroupRef, StateObjectReference UnitRef, XComGameState NewGameState)
{
	local XComGameState_AIGroup GroupState;
	if (RemoveFromCurrentGroup(UnitRef, NewGameState))
	{
		GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', GroupRef.ObjectID));
		if( GroupState != None )
		{
			GroupState.m_arrMembers.AddItem(UnitRef);
			NewGameState.AddStateObject(GroupState);
			UpdateGroupData(NewGameState);
			return true;
		}
	}
	return false;
}

function UpdateYellCooldowns()
{
	if( m_iYellCooldown > 0 )
	{
		m_iYellCooldown--;
		`LogAI("Updating Yell- Ticking down COOLdown to "$m_iYellCooldown);
	}
	if( m_iCivilianYellCooldown > 0 )
	{
		m_iCivilianYellCooldown--;
		`LogAI("Updating CivilianYell- Ticking down COOLdown to "$m_iCivilianYellCooldown);
	}
}

// TODO - put these into an ini file.
function int GetYellCooldownDuration()
{
	local int iDiff, iTurns;
	iDiff = `DIFFICULTYSETTING; // Currently this defaults to 0 since it is not hooked up.
	switch (iDiff)
	{
	case eDifficulty_Easy:
		iTurns = 4;
		break;
	case eDifficulty_Normal:
		iTurns = 3;
		break;
	case eDifficulty_Hard:
		iTurns = 3;
		break;
	case eDifficulty_Classic:
		iTurns = 2;
		break;
	}
	return iTurns;
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//--  FIGHT MANAGER FUNCTIONS ---
//------------------------------------------------------------------------------------------------
function ShowFightManagerDebugInfo(Canvas kCanvas)
{
	local vector2d ViewportSize;
	local Engine                Engine;
	local int iX, iY;
	local LinearColor kDebugColor;
	Engine = class'Engine'.static.GetEngine();
	Engine.GameViewport.GetViewportSize(ViewportSize);

	iX = ViewportSize.X - 384;
	iY = ViewportSize.Y - 150;

	kCanvas.SetDrawColor(255, 255, 255);
	kCanvas.SetPos(iX, iY);
	iY += 15;
	kCanvas.DrawText(`ShowVar(StatsData.NumEngagedAI));
	kCanvas.SetPos(iX, iY);
	iY += 15;
	kCanvas.DrawText("Down Throttling:"@bDownThrottlingActive ? "On":"Off. Enabled at"@DownThrottleUnitCount@"Units.");
	kCanvas.SetPos(iX, iY);
	iY += 15;
	kCanvas.DrawText(`ShowVar(StatsData.ConsecutiveInactiveTurns));
	kCanvas.SetPos(iX, iY);
	iY += 15;
	kCanvas.DrawText("Up Throttling:"@(bUpThrottlingActive ? "On":"Off. Enabled after"@UpThrottleTurnCount@"turns."));
	if( Len(ThrottleDebugText) > 0 )
	{
		kCanvas.SetPos(iX, iY);
		iY += 15;
		kCanvas.DrawText("Throttling Debug:"@ThrottleDebugText);
	}

	kDebugColor = MakeLinearColor(1, 1, 0, 1);
	`BATTLE.DrawDebugLine(CurrentLineOfPlay.v1, CurrentLineOfPlay.v2, kDebugColor.R * 255, kDebugColor.G * 255, kDebugColor.B * 255, false);
}
function XComGameState_Player GetPlayerState(eTeam Team)
{
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	PlayerState = none;
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.GetTeam() == Team)
		{
			break;
		}
	}

	return PlayerState;
}
//------------------------------------------------------------------------------------------------
// UpdateFightMgrStats is called at the start of each Alien turn.  
// Checks conditions for enabling throttling.  
//   If DownThrottling is activated, then 
//		1) Reinforcement calling is disabled
//		2) Only absolute knowledge alerts are added (except throttling alerts below)
//		3) Alerts added to steer green & yellow groups away from the battle.
//   If UpThrottling is activated, then: An alert is added to steer the 
//    closest group toward the current line of play.
function UpdateFightMgrStats( XComGameState NewGameState )
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XGAIBehavior Behavior;
	local XGAIPlayer AIPlayer;
	local XComGameState_Player XComPlayerState;
	local XComGameState_AIGroup UnitGroup;

	bDownThrottlingActive = false;
	bUpThrottlingActive = false;
	ThrottleDebugText = "";
	if( `CHEATMGR != None && `CHEATMGR.bDisableFightManager )
	{
		ThrottleDebugText = "Fight Manager Disabled by CheatMgr.";
		return;
	}

	++StatsData.TurnCount;

	// Reset and recalculate the number of engaged AI units.
	StatsData.NumEngagedAI = 0;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.IsAbleToAct() && UnitState.GetTeam() == eTeam_Alien )
		{
			// Skip units in fallback.  (They are no longer in active combat.)
			UnitGroup = UnitState.GetGroupMembership();
			if( UnitGroup.IsFallingBack() )
			{
				continue;
			}

			// Count all red or orange-alert units that have been revealed.
			if( !UnitState.IsUnrevealedAI() )
			{
				if( UnitState.GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED )
				{
					++StatsData.NumEngagedAI;
					EngagedUnitRef = UnitState.GetReference();
				}
				else
				{
					Behavior = XGUnit(UnitState.GetVisualizer()).m_kBehavior;
					if( Behavior.IsOrangeAlert() )
					{
						++StatsData.NumEngagedAI;
						EngagedUnitRef = UnitState.GetReference();
					}
				}
			}
		}
	}

	XComPlayerState = GetPlayerState(eTeam_XCom);
	// Check if DownThrottling should be active.
	if( StatsData.NumEngagedAI > 0 )
	{
		StatsData.ConsecutiveInactiveTurns = 0;
		if( StatsData.NumEngagedAI >= DownThrottleUnitCount )
		{
			bDownThrottlingActive = true;
		}
	}
	else if( !XComPlayerState.bSquadIsConcealed )
	{
		StatsData.ConsecutiveInactiveTurns++;
	}

	// Check if UpThrottling should be active.
	if( StatsData.ConsecutiveInactiveTurns > UpThrottleTurnCount )
	{
		bUpThrottlingActive = true;
	}

	// Override with cheat manager commands, for testing.
	if( `CHEATMGR != None )
	{
		if( `CHEATMGR.bFightMgrForceUpThrottle )
		{
			ThrottleDebugText = "UpThrottle set by CheatMgr.";
			bDownThrottlingActive = false;
			bUpThrottlingActive = true;
		}
		else if( `CHEATMGR.bFightMgrForceDownThrottle )
		{
			ThrottleDebugText = "DownThrottle set by CheatMgr.";
			bDownThrottlingActive = true;
			bUpThrottlingActive = false;
		}
	}

	// Update current line of play.
	AIPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	AIPlayer.m_kNav.UpdateCurrentLineOfPlay( CurrentLineOfPlay );

	// Error checking.  At most one of these should be true.
	if( bDownThrottlingActive && bUpThrottlingActive )
	{
		`RedScreen("Error- AI Fight Manager - Down-Throttling is active AND Up-Throttling is active!");
	}

	// Set up alerts if any throttling is necessary.
	UpdateThrottleAlerts(NewGameState);
}
//------------------------------------------------------------------------------------------------
// This function sets up new alerts as needed for any throttling that is active.
function UpdateThrottleAlerts(XComGameState NewGameState)
{
	local array<StateObjectReference> GroupsInRange;
	local StateObjectReference GroupRef;
	local XComGameState_AIGroup Group;
	local XComGameStateHistory History;
	local vector AlertLocation;
	local array<int> AlertAddedToGroupID;

	History = `XCOMHISTORY;

	// Add Down Throttling away-from-action alerts
	if( bDownThrottlingActive )
	{
		// Select groups in green/yellow alert within range of the player.
		CollectNonEngagedGroupsNearPlayer(GroupsInRange);
		ThrottleDebugText @= "\nDT:Found"@GroupsInRange.Length@"groups in player range.";

		foreach GroupsInRange(GroupRef)
		{
			Group = XComGameState_AIGroup(History.GetGameStateForObjectID(GroupRef.ObjectID));

			// Find a point away from the player and away from the current line of play.
			SelectAwayLocation(Group, AlertLocation);

			// Generate an alert beacon to steer each unit in this group away from the player.
			SetThrottlingBeaconForGroup(Group, AlertLocation, NewGameState);
			AlertAddedToGroupID.AddItem(Group.ObjectID);
		}
	}
	// Add Up-Throttling alert to steer the nearest group to the middle of the current line of play.
	else if( bUpThrottlingActive )
	{
		// Get Midpoint of current line of play.
		AlertLocation = (CurrentLineOfPlay.v1 + CurrentLineOfPlay.v2) * 0.5f;
		AlertLocation = `TACTICALGRI.GetClosestValidLocation(AlertLocation, None);
		// Take nearest group to midpoint.
		Group = FindClosestGroup(AlertLocation);
		if( Group.ObjectID > 0 )
		{
			SetThrottlingBeaconForGroup(Group, AlertLocation, NewGameState);
			AlertAddedToGroupID.AddItem(Group.ObjectID);
		}
		else
		{
			`LogAI("Warning - No groups found from XComGameState_AIPlayerData::FindClosestGroup()!");
			ThrottleDebugText = "No AI Groups found!";
		}
	}

	// pull groups toward their interception locations, if necessary
	foreach History.IterateByClassType(class'XComGameState_AIGroup', Group)
	{
		if( AlertAddedToGroupID.Find(Group.ObjectID) == INDEX_NONE // Don't attempt to set a throttling beacon for a group twice.
		   && Group.ShouldMoveToIntercept(AlertLocation, NewGameState, self) ) // Duplicates will fail and purge the alert and not receive any at all.
		{
			SetThrottlingBeaconForGroup(Group, AlertLocation, NewGameState);
		}
	}
}
//------------------------------------------------------------------------------------------------
function SetThrottlingBeaconForGroup(XComGameState_AIGroup Group, vector AlertLocation, XComGameState NewGameState)
{
	local AlertAbilityInfo AlertInfo;
	local XComGameState_Unit Unit;
	local XComGameState_AIUnitData AIData;
	local StateObjectReference UnitRef;
	local int AIUnitDataID;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	AlertInfo.AlertTileLocation = `XWORLD.GetTileCoordinatesFromPosition(AlertLocation);
	AlertInfo.AlertRadius = 1000;
	AlertInfo.AlertUnitSourceID = 0;
	AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex();
	foreach Group.m_arrMembers(UnitRef)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		AIUnitDataID = Unit.GetAIUnitDataID();
		if( Unit.IsAlive() && AIUnitDataID > 0 )
		{
			AIData = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', AIUnitDataID));
			if( AIData.AddAlertData(UnitRef.ObjectID, eAC_ThrottlingBeacon, AlertInfo, NewGameState) )
			{
				NewGameState.AddStateObject(AIData);
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(AIData.ObjectID);
			}
		}
	}
}
//------------------------------------------------------------------------------------------------
// Gather all groups within range of the player that are not in red alert or orange alert
function CollectNonEngagedGroupsNearPlayer(out array<StateObjectReference> GroupsInRange)
{
	local XComGameState_AIGroup	Group;
	local float DistSq, RangeDistanceSq;
	local XComGameStateHistory History;
	local TTile GroupLoc;

	History = `XCOMHISTORY;
	RangeDistanceSq = Square(`METERSTOUNITS(DownThrottleGroupRange));
	foreach History.IterateByClassType(class'XComGameState_AIGroup', Group)
	{
		if( Group.GetUnitMidpoint(GroupLoc) ) // Failure means group is already dead.
		{
			if( !Group.IsEngaged() )
			{
				GetClosestEnemyUnitDistance(GroupLoc, DistSq);
				if( DistSq < RangeDistanceSq )
				{
					GroupsInRange.AddItem(Group.GetReference());
				}
			}
		}
	}
}
//------------------------------------------------------------------------------------------------
// Find distance to closest living XCom unit.
function GetClosestEnemyUnitDistance(TTile ToTile, out float ClosestDistSq)
{
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local vector UnitLocation;
	local float DistSq;
	local int ClosestUnitID;
	local vector Point;
	local XComWorldData World;

	World = `XWORLD;
	History = `XCOMHISTORY;
	Point = World.GetPositionFromTileCoordinates(ToTile);
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.IsAlive() && Unit.GetTeam() == eTeam_XCom )
		{
			UnitLocation = World.GetPositionFromTileCoordinates(Unit.TileLocation);
			DistSq = VSizeSq(UnitLocation - Point);
			if( ClosestUnitID == 0 || DistSq < ClosestDistSq )
			{
				ClosestUnitID = Unit.ObjectID;
				ClosestDistSq = DistSq;
			}
		}
	}
}
//------------------------------------------------------------------------------------------------
// Find a point out of view of the player, using the current Line of Play and using the group location.
function SelectAwayLocation(XComGameState_AIGroup Group, out vector AwayLocation)
{
	local vector GroupLoc, ClosestPointOnCLOP; // CLOP = Current Line Of Play
	local vector AwayDirection, ClopDir, Up;
	local TTile GroupTile;
	local float Mobility;

	Group.GetUnitMidpoint(GroupTile);
	GroupLoc = `XWORLD.GetPositionFromTileCoordinates(GroupTile);
	ClosestPointOnCLOP = class'XGAIPlayerNavigator'.static.GetClosestPointAlongLineToTestPoint(CurrentLineOfPlay.v1, CurrentLineOfPlay.v2, GroupLoc);

	// Use the direction from the closest point on the CLOP to the current GroupLoc.
	AwayDirection = GroupLoc - ClosestPointOnCLOP;
	// Drop the Z value and get the unit vector direction along the XY plane.
	AwayDirection.Z = 0;

	// Handle delinquent case - Group location is centered directly on the CLOP. Take a perpendicular direction away from the CLOP.
	if( VSizeSq(AwayDirection) < Square(`METERSTOUNITS(1)) ) // Within a meter of the line.
	{
		ClopDir = CurrentLineOfPlay.v1 - CurrentLineOfPlay.v2;
		ClopDir.Z = 0;
		ClopDir = Normal(ClopDir);
		Up = vect(0, 0, 1);
		AwayDirection = ClopDir Cross Up;
	}

	Mobility = `METERSTOUNITS(Group.GetMaxMobility()) * 2;
	
	AwayDirection = Normal(AwayDirection);
	AwayDirection *= Mobility;
	AwayLocation = GroupLoc + AwayDirection;
	AwayLocation = `TACTICALGRI.GetClosestValidLocation(AwayLocation, None);
	`LogAI("SelectAwayLocation - Group at ("$GroupLoc$") - AwayLocation=("$AwayLocation$").");
}


//------------------------------------------------------------------------------------------------
// Find closest living group to the given point.
function XComGameState_AIGroup FindClosestGroup(vector Point)
{
	local XComGameState_AIGroup	Group, ClosestGroup;
	local float DistSq, ClosestDistSq;
	local XComGameStateHistory History;
	local TTile GroupTile;
	local XComWorldData World;
	local vector GroupCenter;
	World = `XWORLD;

	History = `XCOMHISTORY;
	ClosestDistSq = -1;
	foreach History.IterateByClassType(class'XComGameState_AIGroup', Group)
	{
		Group.GetUnitMidpoint(GroupTile);
		GroupCenter = World.GetPositionFromTileCoordinates(GroupTile);
		DistSq = VSizeSq(GroupCenter - Point);
		if( ClosestGroup == None || DistSq < ClosestDistSq)
		{
			ClosestGroup = Group;
			ClosestDistSq = DistSq;
		}
	}
	return ClosestGroup;
}
//------------------------------------------------------------------------------------------------
//-- END FIGHT MGR FUNCTIONS --
//------------------------------------------------------------------------------------------------

/// <summary>
/// Given the ID of a unit, find out whether it is part of a patrol group and fill an out
/// array with the member of the group ( will include QueryUnitObjectID ). Returns TRUE
/// if a patrol group was found for the given ObjectID, FALSE otherwise.
/// bOnlyWaitingToMove = true means we are only getting the group members from a patrol that
/// are in the WaitingToMove array, specifically used to simulate simultaneous squad-movement.
///  (Units actually get processed one-by-one, but when the first unit is alerted, we want the other units
/// in the group that haven't yet moved to carry on as if they are all still in green alert, until they 
/// see the other unit getting alerted.)
/// </summary>
function bool GetGroupMembersFromUnitObjectID(int QueryUnitObjectID, out array<int> OutGroupMemberObjectIDs, bool bOnlyWaitingToMove=false)
{
	local bool bFoundGroup;
	local XComGameState_AIGroup kGroup;
	local int iID;
	local XGAIPatrolGroup kPatrol;
	local StateObjectReference kUnitRef, kMemberRef;
	local XGAIPlayer kAIPlayer;

	bFoundGroup = false;
	kUnitRef.ObjectID = QueryUnitObjectID;
	iID = GetGroupObjectIDFromUnit(kUnitRef);
	if (iID > 0)
	{
		kGroup = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(iID));
		if (kGroup != None)
		{
			bFoundGroup = true;
			OutGroupMemberObjectIDs.Length = 0;
			if (bOnlyWaitingToMove)
			{
				kAIPlayer = XGAIPlayer(`XCOMHISTORY.GetVisualizer(m_iPlayerObjectID));
				if (kAIPlayer.m_kNav.IsPatrol(QueryUnitObjectID, kPatrol))
				{
					kPatrol.HasUnitsWaitingToMove(OutGroupMemberObjectIDs);
				}
				return true;
			}
			foreach kGroup.m_arrMembers(kMemberRef)
			{
				OutGroupMemberObjectIDs.AddItem(kMemberRef.ObjectID);
			}
		}
	}	
	return bFoundGroup;
}

function OnTakeDamage( int iUnitID, bool bIsAIUnit )
{
	if (StatsData.TakenDamageUnitIDs.Find(iUnitID) == -1)
	{
		if (bIsAIUnit)
		{
			StatsData.bAITakenDamage = true;
		}
		else
		{
			StatsData.bEnemyDamaged = true;
		}
		StatsData.TakenDamageUnitIDs.AddItem(iUnitID);
	}
}

function OnTakeFire( int iUnitID )
{
	if (StatsData.TakenFireUnitIDs.Find(iUnitID) == -1)
	{
		StatsData.TakenFireUnitIDs.AddItem(iUnitID);
	}
}

function OnUnitDeath( int iUnitID, bool bIsAIUnit )
{
	if (bIsAIUnit)
	{
		StatsData.bAIDeath = true;
	}
}

function ResetTurnStats()
{
	// These are kept to determine if the AI had a bad turn, for Reinforcement triggers.
	StatsData.bAITakenDamage = false;
	StatsData.bAIDeath = false;
	StatsData.bEnemyDamaged = false;
}

function CreateNewAIUnitGameStateIfNeeded(int UnitID, XComGameState NewGameState)
{
	local int AIDataID;
	local XComGameState_AIUnitData AIUnitData;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitID));
	AIDataID = UnitState.GetAIUnitDataID();
	if( AIDataID == INDEX_NONE )
	{
		AIUnitData = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData'));
		AIUnitData.Init(UnitState.ObjectID);
		NewGameState.AddStateObject(AIUnitData);
	}
}

function AddKismetJob(Name JobName, int Priority=0, int TargetID=0)
{
	local KismetPostedJob Job;
	local int ExistingJobIndex;
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData NewAIPlayerDataState;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Kismet Job");
	NewAIPlayerDataState = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', ObjectID));

	Job.JobName = JobName;
	Job.PriorityValue = Priority;
	Job.TargetID = TargetID;

	// Ensure only one job per target id.  Remove any existing job(s) with this id.
	if( TargetID > 0 )
	{
		ExistingJobIndex = NewAIPlayerDataState.KismetJobs.Find('TargetID', TargetID);
		while( ExistingJobIndex != INDEX_NONE )
		{
			NewAIPlayerDataState.KismetJobs.Remove(ExistingJobIndex, 1);
			ExistingJobIndex = NewAIPlayerDataState.KismetJobs.Find('TargetID', TargetID);
		}

		CreateNewAIUnitGameStateIfNeeded(TargetID, NewGameState);
	}
	NewAIPlayerDataState.KismetJobs.AddItem(Job);
	NewGameState.AddStateObject(NewAIPlayerDataState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`AIJOBMGR.bJobListDirty = true;
}

function RevokeKismetJob(Name JobName, int Count=-1, int TargetID=0)
{
	local int NumRemoved;
	local int RemoveIndex;
	local KismetPostedJob Job;
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData NewAIPlayerDataState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Revoke Kismet Job");
	NewAIPlayerDataState = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', ObjectID));

	// Special handling for revoking all jobs specific to a TargetID.
	if( TargetID != 0 && JobName == '' )
	{
		for( RemoveIndex = NewAIPlayerDataState.KismetJobs.Length - 1; RemoveIndex >= 0; --RemoveIndex )
		{
			if( TargetID == NewAIPlayerDataState.KismetJobs[RemoveIndex].TargetID )
			{
				NewAIPlayerDataState.KismetJobs.Remove(RemoveIndex, 1);
			}
		}
	}
	else
	{
		if( Count < 0 )	// Remove all by default.
		{
			Job.JobName = JobName;
			Job.TargetID = TargetID;
			NewAIPlayerDataState.KismetJobs.RemoveItem(Job);
		}
		else
		{
			for( NumRemoved = 0; NumRemoved < Count; ++NumRemoved )
			{
				RemoveIndex = NewAIPlayerDataState.KismetJobs.Find('JobName', JobName);
				if( RemoveIndex == INDEX_NONE )
				{
					break;
				}
				NewAIPlayerDataState.KismetJobs.Remove(RemoveIndex, 1);
			}
		}
	}
	NewGameState.AddStateObject(NewAIPlayerDataState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`AIJOBMGR.bJobListDirty = true;
}

function RevokeAllKismetJobs()
{
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData NewAIPlayerDataState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Revoke All Kismet Job");
	NewAIPlayerDataState = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', ObjectID));
	NewAIPlayerDataState.KismetJobs.Length = 0;
	NewGameState.AddStateObject(NewAIPlayerDataState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`AIJOBMGR.bJobListDirty = true;
}


defaultproperties
{
}