//-----------------------------------------------------------
// This is the base class for all movement related X2Actions. This class
// provides shared functionality that all movement actions should have, 
// such as interrupt / resume functionality that releases control and
// regains control of the camera.
//-----------------------------------------------------------
class X2Action_Move extends X2Action
	config(Animation);

//Cached info for performing the action
//************************************
//Since moves are interruptible, and frequently are interrupted, there are multiple contexts stored here.
var protected XComGameStateContext_Ability AbilityContext; //If the move was interrupted, this context points to the resume
var protected XComGameState		  LastInGameStateChain; //Some effects / systems need to know the last game state, so store it here

var protectedwrite int			  MovePathIndex;	//Index into the InputContext's MovementPaths array defining which path this move action is for
var protected int                 PathIndex;		//Index into the PathingInputData.MovementData array - defining string-pulled path points that define locations for the pawn to path through
var protected int                 PathTileIndex;	//Index into the PathingInputData.MovementTiles array - defining game play tiles that the unit will pass through / near
var protected bool				  bShouldUseWalkAnim; //Cached value determined by parse path
var protected bool				  bLocalUnit;
var protected int				  MovingUnitPlayerID;

var protected bool                bUpdateEffects;   //Indicates the unit has effects that need to be notified when the tile changes

var protected bool                NotifiedWindowBreak; // if animation doesn't provide a notify for a window break, allows us to break it at the end of the action
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameState_Unit MovingUnitState;
	local name EffectName;
	local XComGameState_Effect EffectState;

	super.Init(InTrack);

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);	
	LastInGameStateChain = AbilityContext.GetLastStateInInterruptChain();

	Ruleset = `TACTICALRULES;	
	MovingUnitState = XComGameState_Unit(InTrack.StateObject_NewState);
	MovingUnitPlayerID = MovingUnitState.ControllingPlayer.ObjectID;
	bLocalUnit = MovingUnitPlayerID == Ruleset.GetLocalClientPlayerObjectID();

	foreach class'X2AbilityTemplateManager'.default.EffectUpdatesOnMove(EffectName)
	{
		EffectState = MovingUnitState.GetUnitAffectedByEffectState(EffectName);
		if (EffectState != None)
		{
			bUpdateEffects = true;
			break;
		}
	}

	MovePathIndex = AbilityContext.GetMovePathIndex(Unit.ObjectID);
	PathTileIndex = FindPathTileIndex();

	if (PathIndex == -1) // some derived types (like climb ladder) set this directly
	{
		PathIndex = FindPathIndex();
	}

	//when the 1st move is directly into a thin wall, this is required to cause the phasing to happen Chang You Wong 2015-9-22
	UpdatePhasingEffect();
}

function SetShouldUseWalkAnim(bool bSetting)
{
	bShouldUseWalkAnim = bSetting;
}

function int FindPathTileIndex()
{
	local int Index;
	local TTile CurrTile;
	local Vector CurrPos;
	local float DistSqToCur;
	local float DistSqToBest;
	local int BestIndex;

	//This logic must use the ability context's tile list, as it is the canonical move. The one stored on the unit in CurrentMoveData is a potentially
	//truncated / shortened path since for AI moves the portions that are not visible to the player are removed
	DistSqToBest = 10000000.0f;
	for(Index = 0; Index < AbilityContext.InputContext.MovementPaths[MovePathIndex].MovementTiles.Length; ++Index)
	{
		CurrTile = AbilityContext.InputContext.MovementPaths[MovePathIndex].MovementTiles[Index];
		CurrPos = `XWORLD.GetPositionFromTileCoordinates(CurrTile);
		DistSqToCur = VSizeSq(CurrPos - Unit.Location);
		if(DistSqToCur < DistSqToBest)
		{
			DistSqToBest = DistSqToCur;
			BestIndex = Index;
		}
	}

	return BestIndex;
}

function bool CheckInterrupted()
{
	if (VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		if (VisualizationBlockContext.ResultContext.InterruptionStep <= PathTileIndex)
		{
			return true;
		}
	}

	//Unit.UnitSpeak(eCharSpeech_TargetSpotted);

	return false;
}

function bool IsTimedOut()
{
	return ExecutingTime >= TimeoutSeconds;
}

event bool BlocksAbilityActivation()
{
	// only X2Action_MoveEnd needs to determine this
	return false;
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{	
	local AnimNotify_BreakWindow BreakWindowNotify;

	super.OnAnimNotify(ReceiveNotify);

	BreakWindowNotify = AnimNotify_BreakWindow(ReceiveNotify);
	if( BreakWindowNotify != none && !NotifiedWindowBreak )
	{
		NotifyEnvironmentDamage(PathTileIndex, true);
		NotifiedWindowBreak = true;
	}
}

//If bForce is true, this method will send a notify to the nearest environment damage object if none meet the distance criteria
function NotifyEnvironmentDamage(int PreviousPathTileIndex, bool bFragileOnly = true, bool bCheckForDestructibleObject = false)
{
	local float DestroyTileDistance;
	local Vector HitLocation;
	local Vector TileLocation;
	local XComGameState_EnvironmentDamage EnvironmentDamage;		
	local StateObjectReference DmgObjectRef;		
	local XComWorldData WorldData;
	local TTile PathTile;
	local int Index;		

	WorldData = `XWORLD;
			
	//If the unit jumped more than one tile index, make sure it is caught
	for(Index = PreviousPathTileIndex; Index <= PathTileIndex; ++Index)
	{
		if (bCheckForDestructibleObject)
		{
			//Only trigger nearby environment damage if the traversal to the next tile has a destructible object
			if (AbilityContext.InputContext.MovementPaths[MovePathIndex].Destructibles.Length == 0 || 
				AbilityContext.InputContext.MovementPaths[MovePathIndex].Destructibles.Find(Index + 1) == INDEX_NONE)
			{
				continue;
			}
		}

		foreach LastInGameStateChain.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			if (EnvironmentDamage.DamageCause.ObjectID != Unit.ObjectID)
				continue;

			HitLocation = WorldData.GetPositionFromTileCoordinates(EnvironmentDamage.HitLocationTile);			
			PathTile = AbilityContext.InputContext.MovementPaths[MovePathIndex].MovementTiles[Index];
			TileLocation = WorldData.GetPositionFromTileCoordinates(PathTile);
			
			DestroyTileDistance = VSize(HitLocation - TileLocation);
			if(DestroyTileDistance < (class'XComWorldData'.const.WORLD_StepSize * 1.5f) &&
			   ((!bFragileOnly && !EnvironmentDamage.bAffectFragileOnly) || (bFragileOnly && EnvironmentDamage.bAffectFragileOnly)))
			{
				DmgObjectRef = EnvironmentDamage.GetReference();
				VisualizationMgr.SendInterTrackMessage(DmgObjectRef);			
			}
		}
	}
}

//This method is used to handle wall smashing movement
private function UpdateDestruction()
{
	local int PreviousPathTileIndex;

	PreviousPathTileIndex = PathTileIndex;
	if(UpdatePathTileIndex())
	{
		UpdatePathIndex();
		UpdatePhasingEffect();
		NotifyEnvironmentDamage(PreviousPathTileIndex, false);
	}
}

function UpdatePhasingEffect()
{
	local PathPoint CurrPoint, NextPoint;

	if((PathIndex + 1) >= Unit.CurrentMoveData.MovementData.Length) // >= to handle the empty path case (such as a full teleport on a hidden unit)
	{
		if(UnitPawn.m_bIsPhasing)
		{
			UnitPawn.SetPhasing(false);
		}
		return;
	}

	CurrPoint = Unit.CurrentMoveData.MovementData[PathIndex];
	NextPoint = Unit.CurrentMoveData.MovementData[PathIndex + 1];

	if((NextPoint.PathTileIndex == (PathTileIndex + 1)) && (NextPoint.Phasing))
	{
		UnitPawn.SetPhasing(true);
	}
	else if((PathIndex > 0) && !CurrPoint.Phasing && Unit.CurrentMoveData.MovementData[PathIndex - 1].Phasing)
	{
		UnitPawn.SetPhasing(false);
	}
}

private function bool UpdatePathTileIndex()
{	
	local int Index;		
	//local TTile EventTile;
	local bool bStartVisible;
	local bool bEndVisible;
	local X2Action FollowUnitAction;

	Index = FindPathTileIndex();
	if(PathTileIndex != Index)
	{
		PathTileIndex = Index;

		//This functionality manipulates the visibility of units based on distance from the start and end of their path if those start or end
		//points are in the fog
		if(Unit.ForceVisibility == eForceVisible && !bLocalUnit)
		{
			bStartVisible = Unit.CurrentMoveResultData.PathTileData[0].NumLocalViewers > 0;
			bEndVisible = Unit.CurrentMoveResultData.PathTileData[Unit.CurrentMoveResultData.PathTileData.Length - 1].NumLocalViewers > 0;
			
			//Don't do any processing if the unit starts and ends visible. Perform special handling if the unit begins or ends its move not visible
			
			if(!bStartVisible && PathTileIndex >= class'X2VisualizerHelpers'.default.TilesInFog - 1)
			{
				//If we didn't start out visible, make us visible when we are one tile in from the edge of the fog
				//`SHAPEMGR.DrawTile(EventTile, 0, 255, 0);
				Unit.SetForceVisibility(eForceVisible);
			}

			if(!bEndVisible && PathTileIndex >= (Unit.CurrentMoveResultData.PathTileData.Length - 2))
			{
				`XCOMVISUALIZATIONMGR.TrackHasActionOfType(Track, class'X2Action_CameraFollowUnit', FollowUnitAction);
				if (FollowUnitAction != none)
				{					
					`CAMERASTACK.RemoveCamera(X2Action_CameraFollowUnit(FollowUnitAction).FollowCamera);
				}
				//If we didn't end visible, make us not visible when we are one tile in the edge of the fog
				//`SHAPEMGR.DrawTile(EventTile, 255, 0, 0);
				Unit.SetForceVisibility(eForceNotVisible);
			}
		}

		return true;
	}

	return false;
}

// Return val : Path index has changed.
function bool UpdatePathIndex()
{
	local int NextIndex;

	// Only need to update until we hit the last tile.
	if(PathIndex < Unit.CurrentMoveData.MovementData.Length - 1)
	{
		NextIndex = PathIndex + 1;
		while (Unit.CurrentMoveData.MovementData[NextIndex].PathTileIndex == -1)
		{
			++NextIndex;
		}

		if(Unit.CurrentMoveData.MovementData[NextIndex].PathTileIndex == PathTileIndex)
		{
			PathIndex = NextIndex;
			return true;
		}
	}
	return false;
}

function int FindPathIndex()
{
	local int Index, LastValid;

	Index = 0;

	while (Index < Unit.CurrentMoveData.MovementData.Length)
	{
		if (Unit.CurrentMoveData.MovementData[Index].PathTileIndex == -1)
		{
			++Index;
			continue; // skip the path smoothing entries
		}

		if (Unit.CurrentMoveData.MovementData[Index].PathTileIndex > PathTileIndex)
		{
			return LastValid; // return the last valid index
		}

		LastValid = Index; // keep track of the last non-negative move data index
		++Index;
	}

	return LastValid;
}

function OnUnitChangedTile(const out TTile NewTileLocation)
{
	UpdateDestruction();

	if (bUpdateEffects)
	{
		UpdateEffectsForChangedTile(NewTileLocation);	
	}

	if(!NotifiedWindowBreak)
	{
		// make sure we break any windows we've moved through, no matter how we moved through them
		NotifyEnvironmentDamage(PathTileIndex, true, true);
	}
}

function UpdateEffectsForChangedTile(const out TTile NewTileLocation)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Effect EffectState;
	local name EffectName;
	local X2Effect_Persistent EffectTemplate;

	UnitState = XComGameState_Unit(Track.StateObject_NewState);
	foreach class'X2AbilityTemplateManager'.default.EffectUpdatesOnMove(EffectName)
	{
		EffectState = UnitState.GetUnitAffectedByEffectState(EffectName);
		if (EffectState != None)
		{
			EffectTemplate = EffectState.GetX2Effect();
			if (EffectTemplate != None)
			{
				EffectTemplate.OnUnitChangedTile(NewTileLocation, EffectState, UnitState);
			}
		}
	}
}

defaultproperties
{
	TimeoutSeconds = 10.0
	PathIndex = -1;
}
