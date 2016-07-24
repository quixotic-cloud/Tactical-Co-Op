//-----------------------------------------------------------
// Defines static helper methods for constructing visualizer sequences
//-----------------------------------------------------------
class X2VisualizerHelpers extends Object 
	config(Animation);

var bool bShouldUseWalkAnim; //Used in ParsePath to indicate whether the pawns should walk or run when moving along the path
var PathingInputData InputData;
var PathingResultData ResultData;
var int TilesInFog; //The goal for moves that end or start in the fog is for only the visible part of the path to exist / be shown to the player.

function Cleanup()
{
	local PathingInputData EmptyInputData;
	local PathingResultData EmptyResultData;

	//Clear data in these structures, as they may contain references we want to ditch
	InputData = EmptyInputData;
	ResultData = EmptyResultData;
}

//OutVisualizationTracks is used for special circumstances where the movement action adds other visualizers to the
//tracks via an end of move ability. Could end of move actions be refactored to be less crazy?! Probably.
static function ParsePath(const out XComGameStateContext_Ability AbilityContext, 
						  out VisualizationTrack BuildTrack, 
						  out array<VisualizationTrack> OutVisualizationTracks,
						  optional bool InShouldSkipStop = false)
{
	local XGUnit Unit;
	local int Index;
	local int TileIndex;
	local int MovementPathIndex; //Index in the MovementPaths array - supporting multiple paths for a single ability context
	local Vector Point;
	local Vector NextPoint;
	local Vector NewDirection;
	local float DistanceBetweenPoints;
	local ETraversalType LastTraversalType;	
	local X2VisualizerHelpers VisualizerHelper;			
	local int LocalPlayerID;	
	local XComGameState_Unit UnitState;			
	local XComGameStateContext_Ability LastInterruptedMoveContext;	
	local XComGameState_Unit InterruptedUnitState;
	local X2Action_CameraFrameAbility FrameAbilityAction;
	local X2Action_CameraFollowUnit CameraFollowAction;		
	local int UpdateFirstTile;
	local int UpdateLength;
	local PathPoint TempPoint;
	local TTile TempTile;
	local bool bCivilianMove;
	
	local int NumPathTiles;
	local bool bMoveVisible;	
	local int LastVisibleTileIndex;		
	local XComGameStateHistory History;
	local int LastAddedTileIndex;
	local float MoveSpeedModifier;
	
	Unit = XGUnit( BuildTrack.StateObject_NewState.GetVisualizer() );
	VisualizerHelper = `XCOMVISUALIZATIONMGR.VisualizerHelpers;

	if(Unit != none)
	{
		History = `XCOMHISTORY;

		bCivilianMove = Unit.GetTeam() == eTeam_Neutral;
		MovementPathIndex = AbilityContext.GetMovePathIndex(Unit.ObjectID);		
		NewDirection = Vector(Unit.GetPawn().Rotation);		
		LastTraversalType = eTraversal_None;
		DistanceBetweenPoints = 0.0f;

		UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
		LocalPlayerID = `TACTICALRULES.GetLocalClientPlayerObjectID();

		UpdateFirstTile = 0;
		UpdateLength = AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles.Length;
		
		if( AbilityContext.InputContext.MovementPaths.Length == 1 )
		{
			MoveSpeedModifier = UnitState.GetMyTemplate().SoloMoveSpeedModifier;
		}
		else
		{
			MoveSpeedModifier = 1.0f;
		}

		// gremlin flies much faster in zip mode
		if( UnitState.GetMyTemplate().bIsCosmetic && `XPROFILESETTINGS.Data.bEnableZipMode )
		{
			MoveSpeedModifier *= class'X2TacticalGameRuleset'.default.ZipModeTrivialAnimSpeed;
		}


		//Truncate the path if the unit did not make it to their destination but is still alive. In this situation the unit should still play
		//move end animation and generally behave as if that is what they meant to do. For other cases such as where the unit dies, the death
		//action takes care of animations at the end of the interrupted move...
		NumPathTiles = AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles.Length;		
		if(UnitState.IsAlive() && !UnitState.IsBleedingOut() && !UnitState.GetMyTemplate().bIsCosmetic &&
		   UnitState.TileLocation != AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles[NumPathTiles - 1])
		{
			LastInterruptedMoveContext = XComGameStateContext_Ability(AbilityContext.GetLastStateInInterruptChain().GetContext());
			if(LastInterruptedMoveContext != none)
			{	
				//See if the unit is still alive at the end of the event chain that this interrupt was a part of. If the unit died, then we don't want to truncate the path
				InterruptedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, AbilityContext.GetLastStateInEventChain().HistoryIndex));
				if(InterruptedUnitState.IsAlive())
				{
					//Truncate the movement tiles if there was an interruption. If this was a group move, use the movement path index to offset
					UpdateLength = LastInterruptedMoveContext.ResultContext.InterruptionStep + 1;
					UpdateLength = Max(UpdateLength, 1); //Make sure we don't reduce the length to 0
				}
			}
		}

		//Truncate the front of the path for any part of it not visible to a local viewer. Only do this calculation for AIs and non local players
		if(UnitState.ControllingPlayer.ObjectID != LocalPlayerID && 
		   UnitState.ReflexActionState != eReflexActionState_AIScamper) //Never truncate the scamper path, as a FOW viewer will reveal the movement area artificially
		{	
			NumPathTiles = AbilityContext.ResultContext.PathResults[MovementPathIndex].PathTileData.Length;
			bMoveVisible = UnitState.ControllingPlayer.ObjectID == LocalPlayerID; //If this is the local player, the moves are always visible
			for(TileIndex = 0; TileIndex < NumPathTiles; ++TileIndex)
			{
				if(AbilityContext.ResultContext.PathResults[MovementPathIndex].PathTileData[TileIndex].NumLocalViewers > 0)
				{
					LastVisibleTileIndex = TileIndex;

					if(!bMoveVisible)
					{
						UpdateFirstTile = TileIndex;
					}
					bMoveVisible = true;
				}
			}
		}
		else
		{			
			LastVisibleTileIndex = UpdateLength - 1;
			bMoveVisible = true;
		}
		
		UpdateLength = Min(UpdateLength, LastVisibleTileIndex + class'X2VisualizerHelpers'.default.TilesInFog + 1);//+1 because this is a length
		UpdateFirstTile = Max(0, UpdateFirstTile - class'X2VisualizerHelpers'.default.TilesInFog);
		
		//Make adjustments to the path if we have a new starting tile or a new ending tile. This is only necessary if at least some part of the path is visible
		if(bMoveVisible && (UpdateFirstTile > 0 || UpdateLength < AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles.Length))
		{
			VisualizerHelper.InputData = AbilityContext.InputContext.MovementPaths[MovementPathIndex];

			//Zero out the arrays as we will be rebuilding these
			VisualizerHelper.InputData.MovementTiles.Length = 0;
			VisualizerHelper.InputData.MovementData.Length = 0;

			//Enforce some limits on the tile removal
			if(UpdateFirstTile == UpdateLength)
			{
				UpdateFirstTile = 0; 
			}

			//Build the new tile array		
			for(TileIndex = 0; TileIndex < NumPathTiles; ++TileIndex)
			{			
				if(TileIndex >= UpdateFirstTile && TileIndex < UpdateLength)
				{
					TempTile = AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles[TileIndex];
					LastAddedTileIndex = TileIndex;
					//`SHAPEMGR.DrawTile(TempTile, 0, 155, 0, 0.9f);
					VisualizerHelper.InputData.MovementTiles.AddItem(TempTile);
				}
				else
				{
				//	`SHAPEMGR.DrawTile(TempTile, 100, 100, 100, 0.9f);
				}
			}
			// Fix for red screen where only one movement tile is in the list.
			if( VisualizerHelper.InputData.MovementTiles.Length == 1 )
			{ 
				// Ensure at least 2 tiles are in here.
				if( LastAddedTileIndex > 0)
				{
					// Insert previous tile in list.
					TempTile = AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles[LastAddedTileIndex - 1];
					VisualizerHelper.InputData.MovementTiles.InsertItem(0, TempTile);
				}
				else if( LastAddedTileIndex < AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles.Length - 1 )
				{
					// Add next tile in list.
					TempTile = AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles[LastAddedTileIndex + 1];
					VisualizerHelper.InputData.MovementTiles.AddItem(TempTile);
				}
				else
				{
					`RedScreenOnce("Error - only one movement tile in path? @acheng");
				}
			}

			//Convert path tiles in the path points
			class'X2PathSolver'.static.GetPathPointsFromPath(UnitState, VisualizerHelper.InputData.MovementTiles, VisualizerHelper.InputData.MovementData);

			//Run string pulling on the path points
			class'XComPath'.static.PerformStringPulling(Unit, VisualizerHelper.InputData.MovementData, VisualizerHelper.InputData.WaypointTiles);			
			
			//Fill out the result data for the path
			class'X2TacticalVisibilityHelpers'.static.FillPathTileData(VisualizerHelper.InputData.MovingUnitRef.ObjectID, VisualizerHelper.InputData.MovementTiles, VisualizerHelper.ResultData.PathTileData);

		}
		else
		{
// 			for(TileIndex = 0; TileIndex < NumPathTiles; ++TileIndex)
// 			{
// 				TempTile = AbilityContext.InputContext.MovementPaths[MovementPathIndex].MovementTiles[TileIndex];
// 				`SHAPEMGR.DrawTile(TempTile, 0, 155, 0, 0.9f);
// 				VisualizerHelper.InputData.MovementTiles.AddItem(TempTile);				
// 			}

			VisualizerHelper.InputData = AbilityContext.InputContext.MovementPaths[MovementPathIndex];
			VisualizerHelper.ResultData = AbilityContext.ResultContext.PathResults[MovementPathIndex];
		}

		//When determining whether to walk or not we use the first state / initial state of the unit when it was moving. The context passed in here will be the *last* state
		//which is appropriate for the rest of the move.
		VisualizerHelper.bShouldUseWalkAnim = Unit.ShouldUseWalkAnim(AbilityContext.GetFirstStateInInterruptChain());
		if((Unit.GetPawn().m_bShouldTurnBeforeMoving || VisualizerHelper.bShouldUseWalkAnim) && VisualizerHelper.InputData.MovementData.Length > 1)// Rotate before BeginMove if needed
		{			
			TempPoint = VisualizerHelper.InputData.MovementData[1];
			VisualizerHelper.AddTrackAction_TurnTorwards(TempPoint.Position, AbilityContext, BuildTrack);
		}	

		if(!bMoveVisible && VisualizerHelper.InputData.MovementData.Length > 1 && UnitState.ForceModelVisible() != eForceVisible)
		{
			TempPoint = VisualizerHelper.InputData.MovementData[0];
			//This unit was not seen at any point during its move, teleport to keep turn times down
			VisualizerHelper.AddTrackAction_Teleport(LastTraversalType, TempPoint.Position, VisualizerHelper.InputData.MovementData[VisualizerHelper.InputData.MovementData.Length - 1].Position, NewDirection, 0, 0, AbilityContext, BuildTrack);
		}
		else
		{			
			if (!bCivilianMove && //Per Jake, never have the camera follow civilian moves
				MovementPathIndex == 0 &&  //For group moves, follow the first mover
				UnitState.ReflexActionState != eReflexActionState_AIScamper && //The scamper action sequence has its own camera
				!Unit.bNextMoveIsFollow && //A unit following another will not get a follow cam
				bMoveVisible) //A unit that isn't visible to the local player shouldn't frame
			{
				// Movement is unique in that we spawn our own frame ability camera
				if(class'X2Camera_FollowMovingUnit'.default.UseFollowUnitCamera)
				{
					// more like old school EU
					for (Index = 0; Index < BuildTrack.TrackActions.Length && CameraFollowAction == none; Index++)
					{
						CameraFollowAction = X2Action_CameraFollowUnit(BuildTrack.TrackActions[Index]);
					}
					if(CameraFollowAction == none)
					{
						CameraFollowAction = X2Action_CameraFollowUnit(class'X2Action_CameraFollowUnit'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
					}
					CameraFollowAction.AbilityToFrame = AbilityContext;
					CameraFollowAction.ParsePathSetParameters(VisualizerHelper.InputData, VisualizerHelper.ResultData);
				}
				else
				{
					// full move framing camera
					FrameAbilityAction = X2Action_CameraFrameAbility(class'X2Action_CameraFrameAbility'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
					FrameAbilityAction.AbilityToFrame = AbilityContext;
				}
			}

			VisualizerHelper.AddTrackAction_BeginMove(AbilityContext, BuildTrack, MoveSpeedModifier);
			VisualizerHelper.AddTrackActions_MoveOverPath(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, 0, VisualizerHelper.InputData.MovementData, AbilityContext, BuildTrack, InShouldSkipStop,, MoveSpeedModifier);

			// MHU - Set the total path length distance into the pawn.
			Unit.GetPawn().m_fTotalDistanceAlongPath = DistanceBetweenPoints;

			VisualizerHelper.AddTrackAction_EndMove(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
		}		
	}	
}

//Path Support
//*************************************************************************************************************
//*************************************************************************************************************
//*************************************************************************************************************
private function AddTrackActions_MoveOverPath(out ETraversalType LastTraversalType, out Vector Point, out Vector NextPoint, out Vector NewDirection, out float DistanceBetweenPoints, int Index, out array<PathPoint> Path,
											const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack, optional bool ShouldSkipStop = false, optional float StopShortOfEndDistance = 0.0f, 
											optional float MoveSpeedModifier = 1.0f)
{
	local XGUnit Unit;
	local Vector LastPoint;
	local XComCoverPoint CoverPoint;		
	local X2VisualizerHelpers VisualizerHelper;		
	local bool ShouldSkipStopThisAction;

	Unit = XGUnit( BuildTrack.StateObject_NewState.GetVisualizer() );
	VisualizerHelper = `XCOMVISUALIZATIONMGR.VisualizerHelpers;

	LastPoint=Unit.Location;
	for(Index = 0; Index < VisualizerHelper.InputData.MovementData.Length; Index++)
	{
		Point = VisualizerHelper.InputData.MovementData[Index].Position;
		if(Index + 1 < VisualizerHelper.InputData.MovementData.Length)
		{
			NextPoint = VisualizerHelper.InputData.MovementData[Index + 1].Position;
			// MILLER - Compute the direction we should end up facing
			//          at the end of this action
			if(Index + 2 < VisualizerHelper.InputData.MovementData.Length)
			{
				NewDirection = VisualizerHelper.InputData.MovementData[Index + 2].Position - NextPoint;
			}
			else
			{
				NewDirection = NextPoint - Point;
			}

			// if we are going up/down make sure we maintain our current facing (so we dont spin around)
			if( VisualizerHelper.InputData.MovementData[Index].Traversal != eTraversal_Flying)
			{
				NewDirection.Z = 0;
			}

			NewDirection = Normal(NewDirection);
		}
		else
		{
			//If the move location is in a tile with cover, make sure the destination is at the cover point
			if( `XWORLD.GetCoverPoint(Point, CoverPoint) && Unit.CanUseCover() )
			{
				Point = CoverPoint.ShieldLocation;
			}

			NextPoint = Point;
			NewDirection = Point-LastPoint;
			NewDirection.Z = 0;
			NewDirection = Normal(NewDirection);
		}
		LastPoint=Point;

		
		DistanceBetweenPoints += VSize(Point - NextPoint);

		if(Index == VisualizerHelper.InputData.MovementData.Length - 2)
			DistanceBetweenPoints -= StopShortOfEndDistance;

		// only skip the stop on the last movement action. +2 because the very last node is for the end move action
		ShouldSkipStopThisAction = ShouldSkipStop && ((Index + 2) >= VisualizerHelper.InputData.MovementData.Length);
			
		// MILLER - Grab the traversal type and queue up an action.  If it's the first
		//          action in the path, we let it interrupt the current action.  Otherwise,
		//          it doesn't interrupt.
		switch (VisualizerHelper.InputData.MovementData[Index].Traversal)
		{
			case eTraversal_None:
				`Log("Invalid path");
				break;
			case eTraversal_Normal:
			case eTraversal_Ramp:
				if((Index + 1) < VisualizerHelper.InputData.MovementData.Length)
				{
					VisualizerHelper.AddTrackAction_Normal(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack, ShouldSkipStopThisAction, MoveSpeedModifier);
				}
				break;
			case eTraversal_Flying:
				VisualizerHelper.AddTrackAction_Flying(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack, ShouldSkipStopThisAction, MoveSpeedModifier);
				break;
			case eTraversal_Launch:
				VisualizerHelper.AddTrackAction_Flying(eTraversal_None, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack, ShouldSkipStopThisAction, MoveSpeedModifier);
				break;
			case eTraversal_Land:
				VisualizerHelper.AddTrackAction_Normal(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack, ShouldSkipStopThisAction, MoveSpeedModifier);
				break;
			case eTraversal_ClimbOver:
				VisualizerHelper.AddTrackAction_ClimbOver(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_BreakWindow:
				VisualizerHelper.AddTrackAction_BreakWindow(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_KickDoor:
				VisualizerHelper.AddTrackAction_KickDoor(LastTraversalType, Path, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_ClimbOnto:
				VisualizerHelper.AddTrackAction_ClimbOnto(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_ClimbLadder:
				VisualizerHelper.AddTrackAction_ClimbLadder(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_DropDown:
				VisualizerHelper.AddTrackAction_DropDown(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_Grapple:
				VisualizerHelper.AddTrackAction_Grapple(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_Landing:
				VisualizerHelper.AddTrackAction_Normal(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack, ShouldSkipStopThisAction, MoveSpeedModifier);
				break;
			case eTraversal_JumpUp:
				VisualizerHelper.AddTrackAction_JumpUp(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_WallClimb:
				VisualizerHelper.AddTrackAction_ClimbWall(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			case eTraversal_Unreachable:
				break;
			case eTraversal_Teleport:
				VisualizerHelper.AddTrackAction_VisibleTeleport(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
			default:
				VisualizerHelper.AddTrackAction_Teleport(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
				break;
		}

		LastTraversalType = VisualizerHelper.InputData.MovementData[Index].Traversal;
	}
}

private function AddTrackAction_BeginMove(const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack, optional float MoveSpeedModifier = 1.0f)
{
	local X2Action_MoveBegin NewAction;

	NewAction = X2Action_MoveBegin(class'X2Action_MoveBegin'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(InputData, ResultData);
}

private function AddTrackAction_EndMove(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index, 
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveEnd NewAction;

	NewAction = X2Action_MoveEnd(class'X2Action_MoveEnd'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints);
}

private function AddTrackAction_TurnTorwards(const out vector TurnTowardsLocation, const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action NewAction;

	NewAction = class'X2Action_MoveTurn'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);	
	X2Action_MoveTurn(NewAction).ParsePathSetParameters(TurnTowardsLocation);
	
}

private function AddTrackAction_Normal(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index, 
									   const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack, optional bool ShouldSkipStop,
									   optional float MoveSpeedModifier = 1.0f)
{
	local X2Action_MoveDirect NewAction;
	local X2Action_MoveDirect PrevMoveDirectAction;
	local Vector CurrentDirection;

	CurrentDirection = NextPoint - Point;
	CurrentDirection.Z = 0.0f;
	CurrentDirection = Normal(CurrentDirection);
	if( LastTraversalType == eTraversal_Normal || LastTraversalType == eTraversal_Flying )
	{			
		//Normal traversals are consolidated together by simply updating the parameters of an existing move direct
		PrevMoveDirectAction = X2Action_MoveDirect(BuildTrack.TrackActions[BuildTrack.TrackActions.Length - 1]);
		if( NextPoint != PrevMoveDirectAction.Destination ) //Don't let the system create a traversal that doesn't go anywhere!
		{
			PrevMoveDirectAction.ParsePathSetParameters(NextPoint, DistanceBetweenPoints, CurrentDirection, NewDirection, ShouldSkipStop, MoveSpeedModifier);
		}
	}
	else
	{			
		NewAction = X2Action_MoveDirect(class'X2Action_MoveDirect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
		NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
		NewAction.ParsePathSetParameters(NextPoint, DistanceBetweenPoints, CurrentDirection, NewDirection, ShouldSkipStop, MoveSpeedModifier);
	}
}

private function AddTrackAction_Flying(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index, 
									   const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack, optional bool ShouldSkipStop = false,
									   optional float MoveSpeedModifier = 1.0f)
{
	local X2Action_MoveDirect NewAction;
	local X2Action_MoveDirect PrevMoveFlyingAction;
	local Vector CurrentDirection;

	// flying moves are concatenated together if possible
	CurrentDirection = Normal(NextPoint - Point);

	if(LastTraversalType == eTraversal_Flying || LastTraversalType == eTraversal_Launch )
	{	
		PrevMoveFlyingAction = X2Action_MoveDirect(BuildTrack.TrackActions[BuildTrack.TrackActions.Length - 1]);
		PrevMoveFlyingAction.ParsePathSetParameters(NextPoint, DistanceBetweenPoints, CurrentDirection, NewDirection, ShouldSkipStop, MoveSpeedModifier);
		PrevMoveFlyingAction.SetFlying();
	}
	else
	{
		NewAction = X2Action_MoveDirect(class'X2Action_MoveDirect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
		NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
		NewAction.ParsePathSetParameters(NextPoint, DistanceBetweenPoints, CurrentDirection, NewDirection, ShouldSkipStop, MoveSpeedModifier);
		PrevMoveFlyingAction.SetFlying();
	}
}

private function AddTrackAction_ClimbOver(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index, 
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveClimbOver NewAction;

	NewAction = X2Action_MoveClimbOver(class'X2Action_MoveClimbOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints);	
}

private function AddTrackAction_BreakWindow(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MovePlayAnimation NewAction;

	NewAction = X2Action_MovePlayAnimation(class'X2Action_MovePlayAnimation'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints, 'MV_WindowBreakThroughA');

	`XEVENTMGR.TriggerEvent('BreakWindow', AbilityContext, BuildTrack.StateObject_NewState);
}

private function AddTrackAction_KickDoor(ETraversalType LastTraversalType, const out array<PathPoint> Path, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
										 const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack, bool bUseWalkAnim = false)
{
	local X2Action_MovePlayAnimation NewAction;
	local Actor Door;
	local XComInteractiveLevelActor InteractiveDoor;

	local X2Action_MoveTurn TurnAnimation;
	local X2Action_PlayAnimation PlayAnimation;
	local X2Action_SendInterTrackMessage MessageAction;
	local X2Action_Delay DelayAction;

	class'WorldInfo'.static.GetWorldInfo().FindActorByIdentifier(InputData.MovementData[Index].ActorId, Door);
	InteractiveDoor = XComInteractiveLevelActor(Door);

	if ((InteractiveDoor == none || InteractiveDoor.IsInState('_Pristine')))
	{	
		if (InteractiveDoor.HasDestroyAnim())
		{
			NewAction = X2Action_MovePlayAnimation(class'X2Action_MovePlayAnimation'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
			NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints, 'MV_DoorOpenBreakA');
		}
		else
		{
			//Start the door opening animation.
			MessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			MessageAction.SendTrackMessageToRef = `XCOMHISTORY.GetGameStateForObjectID(InteractiveDoor.ObjectID).GetReference();

			//Turn towards the door
			TurnAnimation = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			TurnAnimation.m_vFacePoint = NextPoint;

			//Play idle animation while door opens
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			PlayAnimation.Params.AnimName = 'NO_IdleGunDwnA';
			PlayAnimation.bFinishAnimationWait = false;

			//Wait for the door to open
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			DelayAction.Duration = 0.2f;

			//Run into room
			NewAction = X2Action_MovePlayAnimation(class'X2Action_MovePlayAnimation'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
			NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints, 'MV_RunFwd_StartA');
		}

		`XEVENTMGR.TriggerEvent('BreakDoor', AbilityContext, BuildTrack.StateObject_NewState);
	}
	else
	{
		//If the door is already broken, but somehow there is a kick door traversal, we fall through here and treat it as a normal traversal
		AddTrackAction_Normal(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
	}
}

private function AddTrackAction_ClimbOnto(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveClimbOnto NewAction;
	local vector ModifiedDestination;

	ModifiedDestination = NextPoint;
	ModifiedDestination.Z -= 4.0f;

	NewAction = X2Action_MoveClimbOnto(class'X2Action_MoveClimbOnto'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, ModifiedDestination, DistanceBetweenPoints);	
}

private function AddTrackAction_Landing(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
										const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack, bool bUseWalkAnim = false, optional float MoveSpeedModifier = 1.0f)
{
	
}

private function AddTrackAction_DropDown(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveDropDown NewAction;

	NewAction = X2Action_MoveDropDown(class'X2Action_MoveDropDown'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints);	
}

private function AddTrackAction_Grapple(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	AddTrackAction_Teleport(LastTraversalType, Point, NextPoint, NewDirection, DistanceBetweenPoints, Index, AbilityContext, BuildTrack);
}

private function AddTrackAction_ClimbLadder(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveClimbLadder NewAction;

	NewAction = X2Action_MoveClimbLadder(class'X2Action_MoveClimbLadder'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints, NewDirection);
}


private function AddTrackAction_JumpUp(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveJumpUp NewAction;

	NewAction = X2Action_MoveJumpUp(class'X2Action_MoveJumpUp'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints);	
}


private function AddTrackAction_ClimbWall(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
									const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveClimbWall NewAction;

	NewAction = X2Action_MoveClimbWall(class'X2Action_MoveClimbWall'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, Point, DistanceBetweenPoints);	
}

private function AddTrackAction_Teleport(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
															   const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveTeleport NewAction;

	NewAction = X2Action_MoveTeleport(class'X2Action_MoveTeleport'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints, InputData, ResultData);	
}

private function AddTrackAction_VisibleTeleport(ETraversalType LastTraversalType, Vector Point, Vector NextPoint, Vector NewDirection, float DistanceBetweenPoints, int Index,
												const out XComGameStateContext_Ability AbilityContext, out VisualizationTrack BuildTrack)
{
	local X2Action_MoveVisibleTeleport NewAction;

	NewAction = X2Action_MoveVisibleTeleport(class'X2Action_MoveVisibleTeleport'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));	
	NewAction.SetShouldUseWalkAnim(bShouldUseWalkAnim);
	NewAction.ParsePathSetParameters(Index, NextPoint, DistanceBetweenPoints);
}
//*************************************************************************************************************

defaultproperties
{
	TilesInFog = 2
}
