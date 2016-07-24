//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveBegin extends X2Action_Move
	config(Animation);

var private transient float         RunStartDistanceAvailable;  // Distance of normal traversals in a somewhat straight path
var private bool                    bAllowInterrupt;
var private CustomAnimParams        AnimParams;
var private Rotator                 RotatorBetween;
var private float                   AngleBetween;
var private Rotator                 MoveDirectionRotator;
var private vector                  RunStartDestination;	
var private float					DefaultGroupFollowDelay;
var private float					RunStartRequiredDistance;
var private float					AnimationRateModifier;

//Path data set from ParsePath. These are set into the unit and then referenced for the rest of the path
var private PathingInputData		CurrentMoveData;
var private PathingResultData		CurrentMoveResultData;
var config float					TurnAngleThreshold;
var X2Camera_RushCam RushCam;

function Init(const out VisualizationTrack InTrack)
{	
	local array<PathPoint> MovementData;

	super.Init(InTrack); 
		
	PathIndex = 0;
	PathTileIndex = 0;

	Unit.CurrentMoveData = CurrentMoveData;
	Unit.CurrentMoveResultData = CurrentMoveResultData;

	//@TOOD - rmcfall - this is somewhat of a HACK to get around the weird way that units move around. Look up AXComLocomotionUnitPawn::physWalking for details.	
	MovementData = Unit.CurrentMoveData.MovementData;
	Unit.VisualizerUsePath.SetPathPointsDirect(MovementData);
	UnitPawn.m_fDistanceMovedAlongPath = 0.0f;

	// Don't do this when in tutorial/demo mode, ok for replay mode only I suppose
	if (XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay && !XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
 	{
		if (!XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID)).ControllingPlayerIsAI())
		{
			XComTacticalController(GetALocalPlayerController()).Visualizer_SelectUnit(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID)));
		}
 	}

	RunStartRequiredDistance = UnitPawn.fRunStartDistance + (class'XComWorldData'.const.World_StepSize / 2.0f);

	bAllowInterrupt = false;

	if( Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch )
	{
		// Since we want to make sure we end up in flying after finishing RMA_interact
		UnitPawn.m_kLastPhysicsState.m_ePhysics = PHYS_Flying;
	}
}

function ParsePathSetParameters(const out PathingInputData InputData, const out PathingResultData ResultData, float MoveSpeedModifier = 1.0f)
{
	CurrentMoveData = InputData;
	CurrentMoveResultData = ResultData;
	AnimationRateModifier = MoveSpeedModifier;
}

function float GetStraightNormalDistance()
{
	local float StraightDistance;
	local int NumPathPoints;
	local int ScanPoint;
	local vector SegmentMovement;
	local vector PreviousSegmentMovement;

	StraightDistance = 0.0f;
	
	NumPathPoints = Unit.CurrentMoveData.MovementData.Length;
	for( ScanPoint = 0; ScanPoint < NumPathPoints - 1; ++ScanPoint )
	{
		
		SegmentMovement = Unit.CurrentMoveData.MovementData[ScanPoint + 1].Position - Unit.CurrentMoveData.MovementData[ScanPoint].Position;

		// break if this segment isn't along the straight(ish) path of our previous segment
		if( ScanPoint != 0 )
		{
			AngleBetween = abs(Normalize(Rotator(PreviousSegmentMovement) - Rotator(SegmentMovement)).Yaw) * UnrRotToDeg;
			if( AngleBetween > TurnAngleThreshold )
			{
				break;
			}
		}

		// Add our current segment
		StraightDistance += VSize2D(SegmentMovement);

		// Stop if our next traversal isn't a normal traversal
		if( Unit.CurrentMoveData.MovementData[ScanPoint + 1].Traversal != eTraversal_Normal && 
		   Unit.CurrentMoveData.MovementData[ScanPoint + 1].Traversal != eTraversal_Flying &&
		   Unit.CurrentMoveData.MovementData[ScanPoint + 1].Traversal != eTraversal_Launch &&
		   Unit.CurrentMoveData.MovementData[ScanPoint + 1].Traversal != eTraversal_Ramp &&
		   Unit.CurrentMoveData.MovementData[ScanPoint + 1].Traversal != eTraversal_Land &&
		   Unit.CurrentMoveData.MovementData[ScanPoint + 1].Traversal != eTraversal_Landing )
		{
			break;
		}

		PreviousSegmentMovement = SegmentMovement;
	}

	return StraightDistance;
}

simulated state Executing
{
	function SetMovingUnitDiscState()
	{
		if( Unit != None )
		{
			if( Unit.IsMine() )
			{
				// remove the unit ring while he is running
				Unit.SetDiscState(eDS_Hidden);
			}
			else
			{
				Unit.SetDiscState(eDS_Red); //Set the enemy disc state to red when moving		
			}
		}
	}

	function AddRushCam()
	{
		local XComGameState_Unit UnitState;
		local XComGameStateHistory History;

		// no rush cams if the user has fancy cameras turned off
		if(!`Battle.ProfileSettingsGlamCam())
		{
			return;
		}

		// only do a rush cam if the unit is dashing
		if(Unit.CurrentMoveData.CostIncreases.Length == 0)
		{
			return;
		}
		
		// only do a rush cam if this is the human player on the local machine
		if(!bLocalUnit)
		{
			return;
		}

		// no rush cams if they have been disabled by a cheat
		if(class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableRushCams)
		{
			return;
		}

		History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID,, AbilityContext.AssociatedState.HistoryIndex));
			if(UnitState == none) continue; // unit didn't exist at this point in the past

			if (Unit.ObjectID == UnitState.ObjectID) // this is the moving unit
			{
				// don't do a rush cam if the unit is panicking 
				if(UnitState.IsPanicked())
				{
					return;
				}

				if(!UnitState.GetMyTemplate().bAllowRushCam)
				{
					return;
				}
			}
			else if(MovingUnitPlayerID == UnitState.ControllingPlayer.ObjectID // this is another unit on the moving unit's team
					&& !UnitState.GetMyTemplate().bIsCosmetic
					&& UnitState.NumActionPoints() > 0) 
			{
				// don't do a rush cam if this isn't the last move of the player's turn.
				// (this check ensures all other non-cosmetic units are out of moves)
				return;
			}
		}			

		RushCam = new class'X2Camera_RushCam';
		RushCam.AbilityToFollow = AbilityContext;
		`CAMERASTACK.AddCamera(RushCam);
	}

Begin:
	//If this unit is set to follow another unit, insert a delay into the beginning of the move
	if (Unit.bNextMoveIsFollow)
	{
		sleep(UnitPawn.FollowDelay * GetDelayModifier());
	}
	else
	{
		sleep(DefaultGroupFollowDelay * float(MovePathIndex) * GetDelayModifier()); //If we are part of a group, add an increasing delay based on which group index we are
	}

	while( Unit.IdleStateMachine.IsEvaluatingStance() )
	{
		sleep(0.0f);
	}

	//If a move has a tracking camera, make the model visible for the duration of the move	
	UnitPawn.SetUpdateSkelWhenNotRendered(true);//even if the unit is not visible, update the skeleton so it can animate

	SetMovingUnitDiscState();

	if( !bNewUnitSelected )
	{
		AddRushCam();
	}

	if (Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Normal || Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch)
	{	
		if(Unit.CurrentMoveData.MovementData.Length == 1)
		{
			`RedScreen("Movement data only has 1 entry. Bummer. Unit #"@Unit.ObjectID@"UnitType="$XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID)).GetMyTemplateName()@"-JBouscher ");
		}
		
		RunStartDistanceAvailable = GetStraightNormalDistance(); 

		if( RunStartDistanceAvailable >= RunStartRequiredDistance
			|| Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch) // always play the move start when launching into the air
		{
			UnitPawn.vMoveDirection = Normal(Unit.CurrentMoveData.MovementData[1].Position - UnitPawn.Location);
			UnitPawn.vMoveDestination = Unit.CurrentMoveData.MovementData[1].Position;

			if(!bShouldUseWalkAnim) //For determining whether to walk we want to know the state as of the beginning of the move
			{
				RunStartDestination = Unit.VisualizerUsePath.FindPointOnPath(UnitPawn.fRunStartDistance);

				// if we are transitioning to flying, bump the fixup up to match the flight path
				// otherwise snap the unit to the ground
				if( Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch )
				{
					if( UnitPawn.CollisionComponent != None )
					{
						RunStartDestination.Z += UnitPawn.CollisionComponent.Bounds.BoxExtent.Z;
					}

					MoveDirectionRotator = UnitPawn.GetFlyingDesiredRotation();
				}
				else
				{
					RunStartDestination.Z = Unit.GetDesiredZForLocation(RunStartDestination);
					MoveDirectionRotator = Rotator(RunStartDestination - UnitPawn.Location);
					MoveDirectionRotator = Normalize(MoveDirectionRotator);
				}

				RotatorBetween = Normalize(MoveDirectionRotator - UnitPawn.Rotation);
				AngleBetween = RotatorBetween.Yaw * UnrRotToDeg;

				if (AngleBetween > 120.0f)
				{
					AnimParams.AnimName = 'MV_RunBackRight_Start';
				}
				else if (AngleBetween > 45.0f)
				{
					AnimParams.AnimName = 'MV_RunRight_Start';
				}
				else if (AngleBetween < -120.0f)
				{
					AnimParams.AnimName = 'MV_RunBackLeft_Start';
				}
				else if (AngleBetween < -45.0f)
				{
					AnimParams.AnimName = 'MV_RunLeft_Start';
				}
				else // AngleBetween >= -45 && AngleBetween <= 45
				{
					AnimParams.AnimName = 'MV_RunFwd_Start';
				}

				UnitPawn.EnableRMA(true, true);
				UnitPawn.EnableRMAInteractPhysics(true);
				
				AnimParams.PlayRate = GetMoveAnimationSpeed();
				AnimParams.HasDesiredEndingAtom = true;
				AnimParams.DesiredEndingAtom.Translation = RunStartDestination;
				AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(MoveDirectionRotator);
				AnimParams.DesiredEndingAtom.Scale = 1.0f;
				AnimParams.PlayRate = AnimationRateModifier;

				FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
				UnitPawn.m_fDistanceMovedAlongPath += UnitPawn.fRunStartDistance;
				UnitPawn.EnableRMAInteractPhysics(false);
			}
		}
		else
		{
			// At least make sure you are facing the correct direction
			MoveDirectionRotator = Normalize(Rotator(Unit.CurrentMoveData.MovementData[1].Position - Unit.CurrentMoveData.MovementData[0].Position));
			RotatorBetween = Normalize(MoveDirectionRotator - UnitPawn.Rotation);
			AngleBetween = abs(RotatorBetween.Yaw * UnrRotToDeg);

			if( AngleBetween > TurnAngleThreshold ) // Only Turn if we are far off from our desired facing
			{
				FinishAnim(UnitPawn.StartTurning(Unit.CurrentMoveData.MovementData[1].Position));
			}
		}
	}

	UnitPawn.UpdateAnimations();

	//At the point we force the pawn to be visible. AI paths that come out of the fog are updated so that portions of the path in the fog are removed.
	Unit.SetForceVisibility(eForceVisible);
	UnitPawn.UpdatePawnVisibility();

	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( RushCam != None )
	{
		`CAMERASTACK.RemoveCamera(RushCam);
		RushCam = None;
	}
}


DefaultProperties
{
	DefaultGroupFollowDelay = 0.75f
}
