//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveEnd extends X2Action_Move;

var vector              Destination;
var float               Distance;
var CustomAnimParams    AnimParams;
var vector				UnitGameStateLocation; //The final location of the unit. May or may not match Destination, depending on whether the final leg of the unit's movement is in the fog
var XComWorldData		World;
var bool                IgnoreDestinationMismatch; //If true, does not force pawn to end up at proper destination.
var bool                bNotifyEnvironmentDamage; // If false, do not notify the environmental damage actions. This is needed for some visualizations that handle it themselves.

function Init(const out VisualizationTrack InTrack)
{
	local int MovementDataLength;
	super.Init(InTrack);

	MovementDataLength = Unit.CurrentMoveData.MovementData.Length;
	if (PathIndex < MovementDataLength)
	{
		PathTileIndex = Unit.CurrentMoveData.MovementData[PathIndex].PathTileIndex;
	}
	else
	{
		PathTileIndex = Unit.CurrentMoveData.MovementData[MovementDataLength - 1].PathTileIndex;
	}

	World = `XWORLD;

	UnitGameStateLocation = World.GetPositionFromTileCoordinates(XComGameState_Unit(LastInGameStateChain.GetGameStateForObjectID(Unit.ObjectID)).TileLocation);
	UnitGameStateLocation += Unit.WorldSpaceOffset;

	//turning off phasing, super.init calls into X2Action_Move::init which causes phasing to be set on again when we land into a tile right after phasing. Chang You Wong 2015-9-22
	UnitPawn.SetPhasing( false );
}

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance)
{
	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;	
}

simulated function bool HasDoorsOpening()
{
	local XComInteractiveLevelActor kDoor;
	foreach DynamicActors(class'XComInteractiveLevelActor', kDoor)
	{
		if (kDoor.IsAnimating())
			return true;
	}
	return false;
}

event bool BlocksAbilityActivation()
{
	local XComGameState_Unit UnitState;

	// we only block if the move is interrupted in some way, or if this move is not actually the result of an ability ( certain types of AI move )
	AbilityContext = XComGameStateContext_Ability(StateChangeContext); // Possible we haven't been inited yet (init happens at action start)
	if (AbilityContext != none)
	{
		if(AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		{
			return true;
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		if(UnitState.GetTeam() == eTeam_Alien)
		{
			return true; // if the aliens are moving around, then we need to wait for them to finish
		}
	}

	return false;
}

simulated state Executing
{
	//If there are any environment damage actors still waiting for a message by now, send it to them now regardless of anything else
	function FinalNotifyEnvironmentDamage()
	{
		local XComGameState_EnvironmentDamage EnvironmentDamage;	
		local StateObjectReference DmgObjectRef;
		foreach StateChangeContext.AssociatedState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			if (EnvironmentDamage.DamageCause.ObjectID != Unit.ObjectID)
				continue;

			DmgObjectRef = EnvironmentDamage.GetReference();
			VisualizationMgr.SendInterTrackMessage( DmgObjectRef );			
		}
	}

	//If there are any environment damage actors still waiting for a message by now, send it to them now regardless of anything else
	function FinalNotifyBreakInteractiveObject()
	{
		local XComGameState_InteractiveObject BreakInteractiveObject;	
		local StateObjectReference DmgObjectRef;

		foreach StateChangeContext.AssociatedState.IterateByClassType(class'XComGameState_InteractiveObject', BreakInteractiveObject)
		{
			DmgObjectRef = BreakInteractiveObject.GetReference();
			VisualizationMgr.SendInterTrackMessage( DmgObjectRef );			
		}
	}

	function SetMovingUnitDiscState()
	{
		if( Unit != None && !Unit.IsMine() )
		{
			Unit.SetDiscState(eDS_Hidden); //Hide the enemy disc
		}
	}

	function XComCallOutSeenEnemies()
	{
		//local X2GameRulesetVisibilityInterface TargetInterface;
		local array<int> ChangedObjectIDs;	
		//local int ChangedID;

		class'X2TacticalVisibilityHelpers'.static.GetVisibilityMgr().GetVisibilityStatusChangedObjects(	AbilityContext.AssociatedState.HistoryIndex, ChangedObjectIDs );

		/*
		if( Unit.IsMine() )
		{
			foreach ChangedObjectIDs(ChangedID)
			{		
				TargetInterface = X2GameRulesetVisibilityInterface(TargetState);
				if( TargetInterface != none )
				{

				}
			}		
		}
		else
		{

		}*/
	}

Begin:
	// MHU - Ensures unit is level.
	UnitPawn.SetFocalPoint(UnitPawn.FocalPoint);

	// MILLER - Set the animation to Stop
	UnitPawn.Acceleration = vect(0,0,0);
	UnitPawn.vMoveDirection = vect(0,0,0);
	
	if( bNotifyEnvironmentDamage )
	{
		FinalNotifyEnvironmentDamage();
	}
	FinalNotifyBreakInteractiveObject();

	//Make sure we are at the proper location for cover queries
	//Ensure our destination matches where the game state thinks it should be.
	if (!IgnoreDestinationMismatch)
	{
		Destination.Z = Unit.GetDesiredZForLocation(Destination, World.IsPositionOnFloor(Destination));
		UnitGameStateLocation.Z = Unit.GetDesiredZForLocation(UnitGameStateLocation, World.IsPositionOnFloor(UnitGameStateLocation));
		if (VSizeSq(UnitGameStateLocation - Destination) > Square(48))
		{
			Destination = UnitGameStateLocation;
		}

		if (VSizeSq(Destination - UnitPawn.Location) > Square(48))
		{
			`Warn("XGAction_EndMove::Teleporting unit far from current location!");
			UnitPawn.SetLocation(Destination);
		}
	}

		
	//DrawDebugSphere(Destination, 10, 10, 255, 255, 255, true);
	//DrawDebugSphere(m_vDirectMoveDestination, 10, 10, 255, 0, 0, true);

	// ProcessNewPosition after we know that tiles are done rebuilding
	Unit.ProcessNewPosition( );

	UnitPawn.fFootIKTimeLeft = 1.0f;
	UnitPawn.EnableRMA(false, false);

	//Make sure RMA physics mode is off before we finish moving or else actor radius checks against the pawn will fail. An
	//example of this type of check is FindCollidingActors which is used by the targeting UI.
	UnitPawn.EnableRMAInteractPhysics(false);
	Unit.m_eFavorDir = eFavor_None;
	Unit.bNextMoveIsFollow = false;

	//Restore the pawn's normal gameplay visibility
	Unit.SetForceVisibility(eForceNone);

	Unit.m_bIsMoving = false;

	SetMovingUnitDiscState();

	UnitPawn.SetUpdateSkelWhenNotRendered(false);

	if( UnitPawn.m_bShouldTurnBeforeMoving || bShouldUseWalkAnim )
	{
		UnitPawn.RotationRate = class'XComUnitPawn'.default.RotationRate;
	}

	CompleteAction();
}

DefaultProperties
{
	IgnoreDestinationMismatch=false
	bNotifyEnvironmentDamage=true
}
