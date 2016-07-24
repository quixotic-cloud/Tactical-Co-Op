//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIGroup.uc    
//  AUTHOR:  Alex Cheng  --  11/6/2013
//  PURPOSE: XGAIGroup:   Basic group definition, base of guard and patrol groups.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGAIGroup extends Actor
	native(AI);

var   array<XGUnit> m_arrMember;
var	  array<int> m_arrUnitIDs;
var	  array<TTile> m_arrGuardLocation;

var   XGAIPlayer m_kPlayer;
var	  array<int> m_arrLastAlertLevel;

var array<XComBuildingVolume> m_arrBuildings; // Keep track of building volumes around us.
var TTile m_AlertTile;
var vector m_vAlertDirection;
var float InfluenceRange;
var bool bDetailedDebugging;
var int NumUnitsForPodTalking;

var bool bStartedUnrevealed;

//------------------------------------------------------------------------------------------------

event InitializePostSpawn()
{
	m_kPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
	RefreshMembers();
	if( m_arrUnitIDs.Length <= 1 )
	{
		// Units that start out with one are exempt from the fallback check.
		SetFallbackStatus(false);
	}
}

function BaseInit(array<int> arrObjIDs)
{
	m_arrUnitIDs = arrObjIDs;
	InitializePostSpawn();
}
//------------------------------------------------------------------------------------------------
function RefreshMembers()
{
	local XGUnit kUnit;
	local int iObjID;
	local XComGameState_Unit kUnitState;
	m_arrMember.Length = 0;
	foreach m_arrUnitIDs(iObjID)
	{
		kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjID));	
		kUnit = XGUnit(kUnitState.GetVisualizer());
		if (kUnit != None && kUnitState.IsAlive())
		{
			m_arrMember.AddItem(kUnit);
		}
	}
}
//------------------------------------------------------------------------------------------------
// Prevent other group members from blocking the leader from moving in green alert.
function UnblockMemberTiles()
{
	local int iObjID;
	local XComGameState_Unit kUnitState;
	local XComWorldData World;
	World = `XWORLD;
	foreach m_arrUnitIDs(iObjID)
	{
		kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjID));
		if( kUnitState.IsAlive() )
		{
			World.ClearTileBlockedByUnitFlag(kUnitState);
		}
	}
}

//------------------------------------------------------------------------------------------------
// Undo the unblock.
function BlockMemberTiles()
{
	local int iObjID;
	local XComGameState_Unit kUnitState;
	local XComWorldData World;
	World = `XWORLD;
	foreach m_arrUnitIDs(iObjID)
	{
			kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjID));
			if( kUnitState.IsAlive() )
			{
				World.SetTileBlockedByUnitFlag(kUnitState);
			}
		}
}


//------------------------------------------------------------------------------------------------
function UpdatePodIdles()
{
	local XGUnit CurrentUnit;
	local int ScanUnit;
	local Vector TurnVector;
	local XComUnitPawn CurrentUnitPawn;
	local XGUnit PodTalker;
	local bool bFacesAwayFromPod;
	local Vector FaceTarget;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	NumUnitsForPodTalking = 0;
	for( ScanUnit = 0; ScanUnit < m_arrMember.Length; ++ScanUnit )
	{
		CurrentUnit = m_arrMember[ScanUnit];
		bFacesAwayFromPod = CurrentUnit.GetVisualizedGameState().GetMyTemplate().bFacesAwayFromPod;
		if( !bFacesAwayFromPod )
		{
			NumUnitsForPodTalking++;
			if( PodTalker == None )
			{
				PodTalker = CurrentUnit;
			}
		}
	}

	// If all the characters are not talkable just select one for facing to work
	if( PodTalker == None && m_arrMember.Length != 0 )
	{
		PodTalker = m_arrMember[0];
	}

	if( PodTalker != None )
	{
		PodTalker.IdleStateMachine.TalkerHasSomeoneToTalkTo = (NumUnitsForPodTalking > 1);
	}

	if( m_arrMember.Length > 1 )
	{
		for( ScanUnit = 0; ScanUnit < m_arrMember.Length; ++ScanUnit )
		{
			CurrentUnit = m_arrMember[ScanUnit];

			CurrentUnit.IdleStateMachine.SetPodTalker(PodTalker);
			CurrentUnit.IdleStateMachine.FacePod(FaceTarget, self);

			TurnVector = FaceTarget - WorldData.GetPositionFromTileCoordinates(CurrentUnit.GetVisualizedGameState().TileLocation);
			
			TurnVector.Z = 0;
			TurnVector = Normal(TurnVector);

			CurrentUnitPawn = CurrentUnit.GetPawn();
			CurrentUnitPawn.SetRotation(Rotator(TurnVector));
		}
	}
}

//------------------------------------------------------------------------------------------------
function vector GetCenterFloorPointInVolume( Volume kVolume )
{
	local vector vCenter;
	vCenter = kVolume.BrushComponent.Bounds.Origin;
	vCenter = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vCenter, None, false, false, true);
	vCenter.Z = `XWORLD.GetFloorZForPosition(vCenter);
	return vCenter;
}

//------------------------------------------------------------------------------------------------
function InitTurn()
{
	local XComGameState_Unit UnitState;
	RefreshMembers();
	UpdateFallbackStatus();
	if( m_arrMember.Length > 0 && m_arrMember[0].GetTeam() == eTeam_Alien )
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrUnitIDs[0]));
		bStartedUnrevealed = UnitState.bTriggerRevealAI;
	}
}

//------------------------------------------------------------------------------------------------
function bool CheckForVisibleTargets( int ObjID, out vector vTargetLoc )
{
	local array<StateObjectReference> arrVisibleEnemies;
	local StateObjectReference kEnemyRef;
	local XComGameState_Unit UnitGameState;
	local XComGameStateHistory History;
	local vector vLoc, vUnitLoc;
	local float fDist, fClosest;

	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(ObjID, arrVisibleEnemies, class'X2TacticalVisibilityHelpers'.default.LivingLOSVisibleFilter);
	if (arrVisibleEnemies.Length > 0)
	{
		History = `XCOMHISTORY;
		UnitGameState = XComGameState_Unit(History.GetGameStateForObjectID(ObjID));
		vUnitLoc = `XWORLD.GetPositionFromTileCoordinates(UnitGameState.TileLocation);
		fClosest = Square(`METERSTOUNITS(128));
		// Take closest to this unit location.
		foreach arrVisibleEnemies(kEnemyRef)
		{
			UnitGameState = XComGameState_Unit(History.GetGameStateForObjectID(kEnemyRef.ObjectID));
			vLoc = `XWORLD.GetPositionFromTileCoordinates(UnitGameState.TileLocation);
			fDist = VSizeSq(vLoc-vUnitLoc);
			if (fDist < fClosest)
			{
				fClosest = fDist;
				vTargetLoc = vLoc;
			}
		}
		return true;
	}
	return false;
}

function UpdateLastAlertLevel()
{
	local XComGameState_Unit kUnitState;
	local int iObjID;
	m_arrLastAlertLevel.Length = 0;
	foreach m_arrUnitIDs(iObjID)
	{
		kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjID));	
		m_arrLastAlertLevel.AddItem(kUnitState.GetCurrentStat(eStat_AlertLevel));
	}
}

function int GetLastAlertLevel( int UnitID )
{
	local int iIndex;
	iIndex = m_arrUnitIDs.Find(UnitID);
	if (iIndex == -1)
	{
		`Warn("Error XGAIGroup::GetLastAlertLevel- passed in invalid UnitID. Returning -1.");
		return -1;
	}
	if (m_arrLastAlertLevel.Length != m_arrUnitIDs.Length)
	{
		UpdateLastAlertLevel();
	}
	if (m_arrLastAlertLevel.Length != m_arrUnitIDs.Length)
	{
		`Warn("Error XGAIGroup::GetLastAlertLevel- Unable to update last alert levels! Returning -1.");
		return -1;
	}

	return m_arrLastAlertLevel[iIndex];
}
//------------------------------------------------------------------------------------------------
function OnEndTurn()
{
	UpdateLastAlertLevel();
}
//------------------------------------------------------------------------------------------------
function vector GetNextDestination( XGUnit kUnit );

//------------------------------------------------------------------------------------------------
// Overridden in patrol groups.
function bool HasUnitsWaitingToMove( out array<int> arrObjIDs )
{
	return false;
}
//------------------------------------------------------------------------------------------------

simulated function DrawDebugLabel(Canvas kCanvas)
{	
	local XGUnit Unit;

	// don't draw debug info for this group at all if displaying detailed debugging and this is not the specific target
	if (`CHEATMGR != None && `CHEATMGR.DebugSpawnIndex >= 0 && !bDetailedDebugging)
	{
		return;
	}

	foreach m_arrMember(Unit)
	{
		Unit.DrawSpawningDebug(kCanvas, bDetailedDebugging);
	}
}

function int GetGroupPointTotal()
{
	local int ObjID, TotalPoints;
	local XComGameState_Unit UnitState;

	TotalPoints = 0;

	foreach m_arrUnitIDs(ObjID)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjID));
		TotalPoints += UnitState.GetXpKillscore();
	}

	return TotalPoints;
}

function XComGameState_AIGroup GetGroupState()
{
	local XComGameState_AIGroup GroupState;
	local int ObjID;
	local XComGameState_Unit UnitState;

	foreach m_arrUnitIDs(ObjID)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjID));
		GroupState = UnitState.GetGroupMembership();
		if( GroupState != None )
			break;
	}
	return GroupState;
}

// Run fallback check if we only have one unit remaining in our group (and haven't already run the check).
function UpdateFallbackStatus()
{
	local XComGameState_AIGroup GroupState;
	GroupState = GetGroupState();
	if( GroupState.IsFallingBack() )
	{ 
		// Update while Fallback is active.  Must be disabled when XCom gets there.
		GroupState.UpdateFallBack();
	}
}

// Update - Fallback is checked only when there is one engaged unit left.
function CheckForFallback()
{
	local array<int> LivingMemberIDs;
	local XComGameState_AIGroup GroupState;
	GroupState = GetGroupState();
	if( !GroupState.bHasCheckedForFallback )
	{
		if( GroupState.GetLivingMembers(LivingMemberIDs) )
		{
			if( LivingMemberIDs.Length == 1 )
			{
				GroupState.CheckForFallback();
			}
		}
		else
		{
			// No units left to fallback.
			SetFallbackStatus(false);
		}
	}
}

function SetFallbackStatus(bool bFallback, optional StateObjectReference FallbackGroupRef)
{
	local XComGameState_AIGroup GroupState;
	GroupState = GetGroupState();
	GroupState.SetFallbackStatus(bFallback, FallbackGroupRef);
}

cpptext
{
	// Add a unit to this group
	virtual void AddUnitToGroup(UXComGameState_Unit& NewUnit);

	// Given the current state of this group, find the location at which a new member of the specified 
	// CharacterTemplate type should be spawned.
	FVector FindSpawnLocationForCharacter(const UX2CharacterTemplate& ChracterTemplate) const;
};

defaultproperties
{
}
