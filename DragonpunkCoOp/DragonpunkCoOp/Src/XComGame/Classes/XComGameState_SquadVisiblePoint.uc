//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_SquadVisiblePoint.uc
//  AUTHOR:  David Burchanowski --  4/10/2014
//  PURPOSE: Game state object for a point on the map that triggers when a unit sees it.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_SquadVisiblePoint extends XComGameState_BaseObject 
	implements(X2GameRulesetVisibilityInterface)
	native(Core);

var private TTile TileLocation;
var private name RemoteEventToTrigger;

var private bool XComTriggers;  
var private bool AliensTrigger;  
var private bool CiviliansTrigger;
var private int MaxTriggerCount;

// this is cached so that we don't allocate a zillion of these check conditions, as this will be referenced many times each state building cycle.
var private transient X2Condition_Visibility CachedVisbilityCondition;

function SetInitialState(X2SquadVisiblePoint SquadVisiblePoint)
{
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	TileLocation = WorldData.GetTileCoordinatesFromPosition(SquadVisiblePoint.Location);
	RemoteEventToTrigger = SquadVisiblePoint.RemoteEventToTrigger;
	XComTriggers = SquadVisiblePoint.XComTriggers;
	AliensTrigger = SquadVisiblePoint.AliensTrigger;
	CiviliansTrigger = SquadVisiblePoint.CiviliansTrigger;
	MaxTriggerCount = SquadVisiblePoint.MaxTriggerCount;
	bRequiresVisibilityUpdate = true;
}

// checks for visiblity changes in the given game state and fires our event if needed
function CheckForVisibilityChanges(XComGameState NewGameState)
{
	local X2GameRulesetVisibilityManager VisibilityManager;
	local array<StateObjectReference> CurrentViewers;
	local array<StateObjectReference> PreviousViewers;
	local ETeam UnitTeam;
	local XComGameState_Unit UnitState;
	local StateObjectReference ObjectRef;
	local array<X2Condition> Conditions;

	// nothing to do if we are already past the activation limit
	if(MaxTriggerCount <= 0) return;

	VisibilityManager = `TACTICALRULES.VisibilityMgr;

	if(CachedVisbilityCondition == none)
	{
		CachedVisbilityCondition = new class'X2Condition_Visibility';
		CachedVisbilityCondition.bRequireGameplayVisible = true;
	}
	Conditions.AddItem(CachedVisbilityCondition);

	// get all previous and current viewers of this object
	VisibilityManager.GetAllViewersOfTarget(ObjectID, CurrentViewers, class'XComGameState_Unit', NewGameState.HistoryIndex, Conditions);
	VisibilityManager.GetAllViewersOfTarget(ObjectID, PreviousViewers, class'XComGameState_Unit', NewGameState.HistoryIndex - 1, Conditions);

	// find all "new" viewers. i.e., viewers that started viewing on this history frame, and 
	// fire off our event if needed
	foreach CurrentViewers(ObjectRef)
	{
		if(PreviousViewers.Find('ObjectID', ObjectRef.ObjectID) == INDEX_NONE)
		{
			UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ObjectRef.ObjectID));
			if (UnitState == none)
				continue;
	
			UnitTeam = UnitState.GetTeam();

			if((UnitTeam == eTeam_XCom && XComTriggers)
				|| (UnitTeam == eTeam_Alien && AliensTrigger)
				|| (UnitTeam == eTeam_Neutral && CiviliansTrigger))
			{
				`XCOMGRI.DoRemoteEvent(RemoteEventToTrigger);
				MaxTriggerCount--;

				// if we hit the activation limit, no need to continue checking
				if(MaxTriggerCount <= 0)
				{
					break;
				}
			}
		}
	}
}

// ----- X2GameRulesetVisibilityInterface -----
event float GetVisibilityRadius()
{
	return 0.0f;
}

event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo);

event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1)
{
	return false;
}

event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1)
{
	return false;
}

event int GetAssociatedPlayerID()
{
	return -1;
}

event bool ShouldTreatLowCoverAsHighCover( )
{
	return false;
}

native function NativeGetVisibilityLocation(out array<TTile> VisibilityTiles) const;
native function NativeGetKeystoneVisibilityLocation(out TTile VisibilityTile) const;

function GetVisibilityLocation(out array<TTile> VisibilityTiles)
{
	NativeGetVisibilityLocation(VisibilityTiles);
}

function GetKeystoneVisibilityLocation(out TTile VisibilityTile)
{
	NativeGetKeystoneVisibilityLocation(VisibilityTile);
}

event GetVisibilityExtents(out Box VisibilityExtents)
{
	local Vector HalfTileExtents;

	HalfTileExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;

	VisibilityExtents.Min = `XWORLD.GetPositionFromTileCoordinates( TileLocation ) - HalfTileExtents;
	VisibilityExtents.Max = `XWORLD.GetPositionFromTileCoordinates( TileLocation ) + HalfTileExtents;
	VisibilityExtents.IsValid = 1;
}

event SetVisibilityLocation(const out TTile VisibilityLocation);

event EForceVisibilitySetting ForceModelVisible()
{
	return eForceNone;
}
// ----- end X2GameRulesetVisibilityInterface -----

cpptext
{
	// ----- X2GameRulesetVisibilityInterface -----
	virtual UBOOL CanEverSee() const
	{
		return FALSE;
	}

	virtual UBOOL CanEverBeSeen() const
	{
		return TRUE;
	}
	// ----- end X2GameRulesetVisibilityInterface -----
};

defaultproperties
{
	MaxTriggerCount=1
}