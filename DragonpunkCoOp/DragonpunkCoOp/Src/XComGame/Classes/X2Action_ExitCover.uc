//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ExitCover extends X2Action DependsOn(XGUnitNativeBase, XComAnimNodeBlendDynamic)
	config(Animation);

//Cached data from the history frame
//*************************************
var Actor                   PrimaryTarget;
var Vector                  TargetLocation;
var XGWeapon                UseWeapon;
var XComGameState_Ability   AbilityState;
//*************************************

var XComGameStateContext_Ability AbilityContext;
var XComGameState VisualizeGameState;

var X2Camera_FrameAbility FramingCamera;
var X2ReactionFireSequencer ReactionFireSequencer;

var bool bIsForSuppression;
var bool bSkipExitCoverVisualization;
var bool bUsePreviousGameState;
var private int  StepOutVisibilityHistoryIndex;

//Variables used during the Executing state
//********************************************
var private int                                 UseCoverDirectionIndex; //Set within GetExitCoverType
var private UnitPeekSide                        UsePeekSide;            //Set within GetExitCoverType
var private int									RequiresLean;			//Set to 1 if the unit has to use the 'lean' anims to make this shot
var private bool								bStepoutHasFloor;
var private int                                 bCanSeeFromDefault;
var private AnimNodeSequence                    FinishAnimNodeSequence; //Stores the sequence we are waiting on in FinishAnim, if any
var privatewrite XComDestructibleActor			WindowToBreak; //If it is determined we should bash something before exiting cover, this is the object to bash
var private bool                                bAllowInterrupt;
var privatewrite CustomAnimParams               AnimParams;
var private BoneAtom							DesiredStartingAtom;
var private TTile								StepOutTile;
var private Vector								StepOutLocation;
var private bool								bIsEndMoveAbility;
var private bool								bHaltAimUpdates;
var private Vector								TowardsTarget;
var private int									BreakWindowTouchEventIndex;
var private bool								bHasResume;
var Vector										AimAtLocation;
//********************************************

var config float CrossFadeTime;

enum AnimNodeConfiguration
{
	eConfig_Unequip,
	eConfig_ExitCover
};

function Init(const out VisualizationTrack InTrack)
{
	local XComPrecomputedPath Path;
	local XComGameState_Item WeaponState;
	local X2WeaponTemplate WeaponTemplate;

	super.Init(InTrack);

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	bIsEndMoveAbility = AbilityContext.InputContext.MovementPaths.Length > 0;
	VisualizeGameState = AbilityContext.GetLastStateInInterruptChain();

	Unit.CurrentExitAction = self;

	if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
	{
		// Need target to be set regardless of hit or miss so we can set disc states on target - cotoole
		PrimaryTarget = `XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.PrimaryTarget.ObjectID ).GetVisualizer();
		TargetLocation = X2VisualizerInterface(PrimaryTarget).GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
	}
	else if( AbilityContext.InputContext.TargetLocations.Length > 0 )
	{
		TargetLocation = AbilityContext.InputContext.TargetLocations[0];
	}

	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 && UseWeapon == None )
	{
		WeaponState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
		UseWeapon = XGWeapon(WeaponState.GetVisualizer());
	}	

	bAllowInterrupt = false;

	ReactionFireSequencer = class'XComTacticalGRI'.static.GetReactionFireSequencer();

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if( AbilityState.GetMyTemplate().TargetingMethod == class'X2TargetingMethod_Grenade' && UseWeapon != None && WeaponState != None )
	{
		Path = `PRECOMPUTEDPATH;

		WeaponTemplate = X2WeaponTemplate(WeaponState.GetMyTemplate());
		Path.SetWeaponAndTargetLocation(UseWeapon.GetEntity(), Unit.GetTeam(), AbilityContext.InputContext.TargetLocations[0], WeaponTemplate.WeaponPrecomputedPathData);

		if( Path.iNumKeyframes <= 0 ) // just in case (but mostly because replays don't have a proper path computed)
		{
			Path.CalculateTrajectoryToTarget(WeaponTemplate.WeaponPrecomputedPathData);
			`assert( Path.iNumKeyframes > 0 );
		}

		Path.bUseOverrideTargetLocation = true;
		Path.UpdateTrajectory();
		Path.bUseOverrideTargetLocation = false; //Only need this for the above calculation

		AimAtLocation = Path.ExtractInterpolatedKeyframe(0.3f).vLoc;
	}
	else if( AbilityState.GetMyTemplate().TargetingMethod == class'X2TargetingMethod_BlasterLauncher' && UseWeapon != None && WeaponState != None )
	{
		Path = `PRECOMPUTEDPATH;
		WeaponTemplate = X2WeaponTemplate(WeaponState.GetMyTemplate());

		Path.SetWeaponAndTargetLocation(UseWeapon.GetEntity(), Unit.GetTeam(), AbilityContext.InputContext.TargetLocations[0], WeaponTemplate.WeaponPrecomputedPathData);

		if( Path.iNumKeyframes <= 0 ) // just in case (but mostly because replays don't have a proper path computed)
		{
			Path.CalculateBlasterBombTrajectoryToTarget();
			`assert( Path.iNumKeyframes > 0 );
		}

		AimAtLocation = Path.ExtractInterpolatedKeyframe(0.3f).vLoc;
	}
	else
	{
		AimAtLocation = TargetLocation;
	}
}

function bool CheckInterrupted()
{
	return bAllowInterrupt;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	super.ResumeFromInterrupt(HistoryIndex);

	if(bAllowInterrupt)
	{
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		bAllowInterrupt = false;
		CompleteAction();
	}
}

function ForceImmediateTimeout()
{
	//No immediate timeout when setting up suppression.
	if (!bIsForSuppression)
	{
		super.ForceImmediateTimeout();
	}
}

function CompleteAction()
{
	super.CompleteAction();

	Unit.CurrentExitAction = none;
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{	
	local AnimNotify_BreakWindow BreakWindowNotify;

	super.OnAnimNotify(ReceiveNotify);

	BreakWindowNotify = AnimNotify_BreakWindow(ReceiveNotify);
	if (BreakWindowNotify != none)
	{		
		BreakWindow();
	}
}

function BreakWindow()
{
	local XComGameState_InteractiveObject InteractiveObject;
	local XComInteractiveLevelActor InteractiveActor;
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local StateObjectReference Target;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		if (VSize(EnvironmentDamageEvent.HitLocation - AbilityContext.InputContext.ProjectileEvents[BreakWindowTouchEventIndex].HitLocation) < (class'XComWorldData'.const.WORLD_StepSize))
		{
			Target = EnvironmentDamageEvent.GetReference();
			VisualizationMgr.SendInterTrackMessage(Target);
			break;
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		InteractiveActor = XComInteractiveLevelActor(`XCOMHISTORY.GetVisualizer(InteractiveObject.ObjectID));
		if (VSize2D(InteractiveActor.Location - AbilityContext.InputContext.ProjectileEvents[BreakWindowTouchEventIndex].HitLocation) < (class'XComWorldData'.const.WORLD_StepSize))
		{
			Target.ObjectID = InteractiveActor.ObjectID;
			VisualizationMgr.SendInterTrackMessage(Target);
			break;
		}
	}
}

function TTile GetTileFiringFrom()
{
	local TTile RetVal;
	local XComWorldData WorldData;
	local bool bSteppingOut;
	local int OutCoverIndex;
	local UnitPeekSide OutPeekSide;
	local int OutRequiresLean;
	local int bOutCanSeeFromDefault;
	local Vector FireFromLocation;

	WorldData = `XWORLD;

	StepOutVisibilityHistoryIndex = -1;

	if( bUsePreviousGameState )
	{
		StepOutVisibilityHistoryIndex = CurrentHistoryIndex - 1;
	}
	
	bSteppingOut = Unit.GetStepOutCoverInfo(PrimaryTarget, TargetLocation, OutCoverIndex, OutPeekSide, OutRequiresLean, bOutCanSeeFromDefault, StepOutVisibilityHistoryIndex);
	FireFromLocation = Unit.GetExitCoverPosition(OutCoverIndex, OutPeekSide, bSteppingOut);
	if( !WorldData.GetFloorTileForPosition(FireFromLocation, RetVal) )
	{
		RetVal = WorldData.GetTileCoordinatesFromPosition(FireFromLocation);
	}

	return RetVal;
}


function array<TTile> GetTilesInLineOfFire()
{
	local TTile StartTile;
	local TTile EndTile;
	local XComWorldData WorldData;
	local VoxelRaytraceCheckResult CheckResult;

	WorldData = `XWORLD;

	StartTile = GetTileFiringFrom();
	EndTile = WorldData.GetTileCoordinatesFromPosition(TargetLocation);

	CheckResult.bRecordAllTiles = true;
	CheckResult.bTraceToMapEdge = true;
	WorldData.VoxelRaytrace_Tiles(StartTile, EndTile, CheckResult);

	return CheckResult.TraceTiles;
}

function LineOfFireFriendlyUnitCrouch()
{
	local XComGameState_Unit MyUnitState;
	local XComGameState_Unit TestUnitState;
	local XGUnit TestUnitVisualizer;
	local XComGameStateHistory History;
	local array<TTile> TilesToTest;
	local int scan;
	local XComWorldData WorldData;
	local StateObjectReference UnitRef;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	MyUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID));

	TilesToTest = GetTilesInLineOfFire();
	for( scan = 0; scan < TilesToTest.Length; ++scan )
	{
		UnitRef = WorldData.GetUnitOnTile(TilesToTest[scan]);
		if( UnitRef.ObjectID != 0 )
		{
			TestUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if( TestUnitState.IsAlive() && !TestUnitState.bRemovedFromPlay && TestUnitState.IsFriendlyUnit(MyUnitState) )
			{
				TestUnitVisualizer = XGUnit(TestUnitState.GetVisualizer());
				//If the unit isn't doing anything, play a crouch
				if( TestUnitVisualizer.GetNumVisualizerTracks() == 0 )
				{
					TestUnitVisualizer.IdleStateMachine.PerformCrouch();
				}
			}
		}
	}
}

simulated state Executing
{
	//This is used to determine whether the unit is facing the right direction when utilizing the turn node to face a target
	function bool UnitFacingMatchesDesiredDirection()
	{
		local vector CurrentFacing;
		local vector DesiredFacing;
		local float Dot;

		CurrentFacing = Vector(Unit.Rotation);
		DesiredFacing = Normal(TargetLocation - UnitPawn.Location);

		Dot = NoZDot(CurrentFacing, DesiredFacing);

		return Dot > 0.7f; //~45 degrees of tolerance
	}

	simulated event Tick( float DeltaT )
	{
		if(!bHaltAimUpdates)
		{
			if(PrimaryTarget != none)
			{
				UnitPawn.TargetLoc = X2VisualizerInterface(PrimaryTarget).GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
				AimAtLocation = UnitPawn.TargetLoc;
			}
			else
			{
				UnitPawn.TargetLoc = AimAtLocation;
			}

			//If we are very close to the target, just update our aim with a more distance target once and then stop
			if(VSize(UnitPawn.TargetLoc - UnitPawn.Location) < (class'XComWorldData'.const.WORLD_StepSize * 2.0f))
			{
				bHaltAimUpdates = true;
				UnitPawn.TargetLoc = UnitPawn.TargetLoc + (Normal(UnitPawn.TargetLoc - UnitPawn.Location) * 400.0f);
				AimAtLocation = UnitPawn.TargetLoc;
			}
		}
	}

	function HideFOW()
	{
		local XGPlayer AIPlayer;
		local vector RevealLocation;
		local Actor FOWViewer;
		local XGBattle_SP Battle;

		Battle = XGBattle_SP(`BATTLE);

		AIPlayer = Battle.GetAIPlayer();
		RevealLocation = UnitPawn.Location;
		RevealLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;
		FOWViewer = `XWORLD.CreateFOWViewer(RevealLocation, 3); //3 meters
		
		AIPlayer.SetFOWViewer(FOWViewer);
	}

	function SetTargetUnitDiscState()
	{
		local XGUnit TargetUnit;

		TargetUnit = XGUnit(PrimaryTarget);
		if( TargetUnit != None && TargetUnit.IsMine() )
		{
			if( Unit.IsMine() )
			{
				TargetUnit.SetDiscState(eDS_Good); //If the shooter is mine, make it the good kind of disc
			}
			else
			{
				TargetUnit.SetDiscState(eDS_AttackTarget); //If the shooter is not mine, set the disc state to indicate we're under attack
				Unit.SetDiscState(eDS_Red); //Set the enemy disc state to red
			}
		}
	}

	function CreateFramingCamera()
	{
		local X2AbilityTemplateManager AbilityTemplateManager;
		local X2AbilityTemplate AbilityTemplate;

		// check if this ability even wants a framing camera
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		`assert(AbilityTemplate != none);

		if(AbilityContext.ShouldFrameAbility())
		{
			FramingCamera = new class'X2Camera_FrameAbility';
			FramingCamera.AbilityToFrame = AbilityContext;
			`CAMERASTACK.AddCamera(FramingCamera);
		}
	}

	function bool ShouldBreakWindowBeforeFiring()
	{
		local int Index;
		local ProjectileTouchEvent TouchEvent;
		local XComPhysicalMaterialProperty PhysMaterial;
		local XComInteractiveLevelActor InteractActor;
		local XComDestructibleActor DestructibleActor;

		BreakWindowTouchEventIndex = -1;
		for (Index = 0; Index < AbilityContext.InputContext.ProjectileEvents.Length && BreakWindowTouchEventIndex < 0; ++Index)
		{
			TouchEvent = AbilityContext.InputContext.ProjectileEvents[Index];			
			if (TouchEvent.bEntry == true &&
				TouchEvent.TravelDistance > 0.0f && 
				TouchEvent.TravelDistance < class'XComWorldData'.const.WORLD_StepSize &&
				(TouchEvent.TraceInfo.PhysMaterial != none || TouchEvent.TraceInfo.HitComponent != none))
			{
				//Next, check to see whether the LDs have flagged this as a window
				if (BreakWindowTouchEventIndex < 0)
				{
					DestructibleActor = XComDestructibleActor(TouchEvent.TraceInfo.HitComponent.Owner);
					if (DestructibleActor != None && DestructibleActor.VisibilityBlockingData.bIsWindow && 
						(DestructibleActor.GetStateName() == '_Pristine' || DestructibleActor.GetStateName() == '_DamageStarted'))
					{
						BreakWindowTouchEventIndex = Index;
					}
				}
				
				//Last, check whether this is a transparent door
				if (BreakWindowTouchEventIndex < 0)
				{
					InteractActor = XComInteractiveLevelActor(TouchEvent.TraceInfo.HitComponent.Owner);
					if( InteractActor != None && InteractActor.IsDoor() && InteractActor.GetInteractionCount() % 2 == 0 
						&& (InteractActor.GetStateName() == '_Pristine' || InteractActor.GetStateName() == '_DamageStarted'))
					{
						BreakWindowTouchEventIndex = Index;
					}
				}

				//Failsafe: see if the material is glass
				if (BreakWindowTouchEventIndex < 0 && TouchEvent.TraceInfo.PhysMaterial != none)
				{
					PhysMaterial = XComPhysicalMaterialProperty(TouchEvent.TraceInfo.PhysMaterial.GetPhysicalMaterialProperty(class'XComPhysicalMaterialProperty'));
					if (PhysMaterial != None && PhysMaterial.MaterialType == MaterialType_Glass)
					{
						// If it is a door make sure we only break closed doors.
						InteractActor = XComInteractiveLevelActor(TouchEvent.TraceInfo.HitComponent.Owner);
						if (InteractActor == None || !InteractActor.IsDoor() || InteractActor.GetInteractionCount() % 2 == 0)
						{
							BreakWindowTouchEventIndex = Index;
						}
					}
				}
			}
		}

		return BreakWindowTouchEventIndex > -1;
	}

	function ManualStartLeanAim(AnimNodeSequence Sequence)
	{
		local XComAnimNotify_Aim AimNotify;

		AimNotify = new class'XComAnimNotify_Aim';
		AimNotify.Enable = true;
		AimNotify.ProfileName = 'RiflePeekFwd';
		AimNotify.BlendTime = 0.4f;
		AimNotify.ManualTrigger(UnitPawn, Sequence);
	}

	function bool ShouldWaitForFramingCamera()
	{
		local X2AbilityTemplate Template;

		if(!Unit.GetVisualizedGameState().IsPlayerControlled())
		{
			// non-humans always wait
			return true;
		}

		Template = AbilityState.GetMyTemplate();
		if( Template.TargetingMethod != None && Template.TargetingMethod.static.ShouldWaitForFramingCamera())
		{
			// if human targeted, check if the targeting method requires us to wait
			return true;
		}

		return false;
	}

Begin:

	//`log("X2Action_ExitCover::Begin -"@UnitPawn@Unit.ObjectID, , 'XCom_Filtered');

	if( !bSkipExitCoverVisualization )
	{
		HideFOW();

		SetTargetUnitDiscState();

		if( !bNewUnitSelected )
		{
			CreateFramingCamera();
		}
	}

	//Check whether this is reaction fire, and update the sequencer if so
	if(ReactionFireSequencer.IsReactionFire(AbilityContext))
	{
		ReactionFireSequencer.PushReactionFire(self);		

		//This odd bit of code handles situations where Unit is taking multiple shots in a reaction fire sequence, and verifies that any
		//previous X2Actions in other active blocks that contain this unit have completed before we move on. If we don't wait, we will 
		//potentially conflict with this actions and cause animation hangs.
		while(VisualizationMgr.GetCurrentTrackActionForVisualizer(Unit) != self)
		{
			Sleep(0.0f);
		}
	}

	if( !bSkipExitCoverVisualization )
	{
		UnitPawn.EnableLeftHandIK(true);

		// in some cases, such as OTS targeting, we don't want or need to wait for the framing camera to arrive before continuing.
		// if that is the case, skip the wait and just move on
		if( ShouldWaitForFramingCamera() )
		{
			// wait for the framing camera to finish framing the ability before continuing
			while( FramingCamera != none && !FramingCamera.HasArrived() )
			{
				Sleep(0.0);
			}

			// to make the action sequence flow properly, we do the midpoint camera here,
			// but it should have the same delay as a standalone frame action
			if( AbilityContext.ShouldFrameAbility() && !bNewUnitSelected )
			{
				Sleep(class'X2Action_CameraFrameAbility'.default.FrameDuration * GetDelayModifier());
			}
		}

		LineOfFireFriendlyUnitCrouch();

		//First, we make sure the character is in the proper cover state before they fire. This may not always be the case, eg. we are overwatching in a left peek
		//position ( closest enemy is in that direction ) and an enemy moves into view of our right peek position. In this situation, we would need to switch sides
		//before proceeding with the exit cover + firing actions.
		//****************
		if( bIsEndMoveAbility == false )
		{
			Unit.IdleStateMachine.CheckForStanceUpdate();
			while( Unit.IdleStateMachine.IsEvaluatingStance() ) //Wait for any pending stance update to complete
			{
				Sleep(0.0f);
			}

			//****************

			//A unit's idle state machine must be dormant during firing, or else the idle state machine will fight the firing process for control over the unit's anim nodes. At best
			//this will dirupt the animations/firing process, at worst it will lead to a permanent hang.
			if( !Unit.IdleStateMachine.IsDormant() )
			{
				Unit.IdleStateMachine.GoDormant();
			}

			//@TODO - jbouscher/rmcfall/jwatson - is left hand IK still applied? If so, is it still controlled this way or is it part of the animation controller?
			UnitPawn.EnableLeftHandIK(true);

			//Based on the unit's current cover state, this sets UseCoverDirectionIndex and UsePeekSide to determine which exit cover animation to use. This function also
			//sets our cached anim tree nodes

			StepOutVisibilityHistoryIndex = -1;

			if( bUsePreviousGameState )
			{
				StepOutVisibilityHistoryIndex = CurrentHistoryIndex - 1;
			}

			Unit.bShouldStepOut = Unit.GetStepOutCoverInfo(PrimaryTarget, TargetLocation, UseCoverDirectionIndex, UsePeekSide, RequiresLean, bCanSeeFromDefault, StepOutVisibilityHistoryIndex);

			//Save our location so that it can be reset later in EnterCover if not already stepped out
			Unit.RestoreLocation = UnitPawn.Location;
			Unit.RestoreHeading = vector(UnitPawn.Rotation);			
		}
		// Set our weapon to get the correct animations
		// RAM - this should no longer be necessary. The character's animsets should be fixed based on their current inventory items
		UnitPawn.SetCurrentWeapon(XComWeapon(UseWeapon.m_kEntity));
		UnitPawn.UpdateAnimations();

		if( bIsEndMoveAbility == false )
		{
			//Determine if we need to break out windows / bash open doors to make our shot, and then perform the door/window break. This is done before
			//anything else, as the animations were designed to be done from the starting tile
			//****************
			if( ShouldBreakWindowBeforeFiring() )
			{
				if( Unit.CanUseCover() )
				{
					AnimParams = default.AnimParams;
					AnimParams.PlayRate = GetNonCriticalAnimationSpeed();
					switch( Unit.m_eCoverState )
					{
					case eCS_LowLeft:
						AnimParams.AnimName = 'LL_WindowBreak';
						break;
					case eCS_HighLeft:
						AnimParams.AnimName = 'HL_WindowBreak';
						break;
					case eCS_LowRight:
						AnimParams.AnimName = 'LR_WindowBreak';
						break;
					case eCS_HighRight:
						AnimParams.AnimName = 'HR_WindowBreak';
						break;
					case eCS_None:
						AnimParams.AnimName = 'NO_WindowBreak';
						break;
					}
					FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
				}
				else
				{
					BreakWindow();
				}
			}
			//****************

			UnitPawn.EnableRMAInteractPhysics(true);
			UnitPawn.EnableRMA(true, true);

			if( Unit.bShouldStepOut && Unit.m_eCoverState != eCS_None )
			{
				AnimParams = default.AnimParams;
				AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

				switch( Unit.m_eCoverState )
				{
				case eCS_LowLeft:
				case eCS_HighLeft:
					AnimParams.AnimName = 'HL_StepOut';
					break;
				case eCS_LowRight:
				case eCS_HighRight:
					AnimParams.AnimName = 'HR_StepOut';
					break;
				}

				// First find the tile we'll be stepping into
				DesiredStartingAtom.Translation = UnitPawn.Location;
				DesiredStartingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
				DesiredStartingAtom.Scale = 1.0f;
				UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(AnimParams, DesiredStartingAtom);

				// Find the tile location we are stepping to			
				StepOutLocation = AnimParams.DesiredEndingAtom.Translation;
				if( `XWORLD.GetFloorTileForPosition(AnimParams.DesiredEndingAtom.Translation, StepOutTile, false) )
				{
					StepOutLocation.Z = Unit.GetDesiredZForLocation(StepOutLocation);
					bStepoutHasFloor = true;
				}
				else
				{
					StepOutLocation.Z = Unit.GetDesiredZForLocation(StepOutLocation, false);
					bStepoutHasFloor = false;
				}

				if( RequiresLean == 1 )
				{
					//Turn off all IK, the unit may be clipping into railings to make this shot
					UnitPawn.bSkipIK = true;
					UnitPawn.EnableFootIK(false);

					//Step out a little further if there is floor, otherwise don't step outside our tile
					if( bStepoutHasFloor )
					{
						AnimParams.DesiredEndingAtom.Translation = UnitPawn.Location + (Normal(StepOutLocation - UnitPawn.Location) * VSize(StepOutLocation - UnitPawn.Location) * 0.70f);
					}
					else
					{
						UnitPawn.bNoZAcceleration = true; //Don't allow falling if there is no floor where we are going
						AnimParams.DesiredEndingAtom.Translation = UnitPawn.Location + (Normal(StepOutLocation - UnitPawn.Location) * VSize(StepOutLocation - UnitPawn.Location) * 0.5f);
					}
				}
				else
				{
					AnimParams.DesiredEndingAtom.Translation = StepOutLocation;
				}

				// Now Determine our facing based on our ending location and the target
				TowardsTarget = TargetLocation - AnimParams.DesiredEndingAtom.Translation;
				TowardsTarget.Z = 0;
				TowardsTarget = Normal(TowardsTarget);
				AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(TowardsTarget));

				FinishAnimNodeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				Unit.bSteppingOutOfCover = true;

			}

			if( Unit.bShouldStepOut == false )
			{
				AnimParams = default.AnimParams;
				AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

				AnimParams.HasDesiredEndingAtom = true;
				AnimParams.DesiredEndingAtom.Scale = 1.0f;
				AnimParams.DesiredEndingAtom.Translation = UnitPawn.Location;
				TowardsTarget = TargetLocation - UnitPawn.Location;
				TowardsTarget.Z = 0;
				TowardsTarget = Normal(TowardsTarget);
				AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(TowardsTarget));
				switch( Unit.m_eCoverState )
				{
				case eCS_LowLeft:
				case eCS_LowRight:
					AnimParams.AnimName = 'LL_FireStart';
					break;
				case eCS_HighLeft:
				case eCS_HighRight:
					AnimParams.AnimName = 'HL_FireStart';
					break;
				case eCS_None:
					AnimParams.AnimName = 'NO_FireStart';
					break;
				}

				if( UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
				{
					FinishAnimNodeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				}
				else
				{
					if( UseWeapon != None && XComWeapon(UseWeapon.m_kEntity) != None && XComWeapon(UseWeapon.m_kEntity).WeaponAimProfileType != WAP_Unarmed )
					{
						UnitPawn.UpdateAimProfile();
						UnitPawn.SetAiming(true, 0.5f, 'AimOrigin', false);
					}
				}
			}

			//If we need to animate out of cover or switch to our new weapon, finish the anim here. In the case of exiting cover while switching weapons, this animsequence
			//equips the new weapon and finishes the RMA step out of cover animation. In the case of a simple step out, this animsequence just gets out of cover
			//****************
			if( FinishAnimNodeSequence != None )
			{
				FinishAnim(FinishAnimNodeSequence, false, CrossFadeTime);
			}
			//****************
		}
	}

	//If we are reaction fire, wait for the sequencer to give its blessing
	if(ReactionFireSequencer.IsReactionFire(AbilityContext))
	{
		while(!ReactionFireSequencer.AttemptStartReactionFire(self))
		{
			sleep(0.0f);
		}		
	}

	//If the ability which generated this exit cover was interrupted, then process that here
	if( !bSkipExitCoverVisualization && VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt )
	{		
		//We don't want anyone messing up our step out / fire sequence. ( ie. flinches, get hit anims, etc. ). But we only care if there is a resume. If there is no
		//resume it means we died or otherwise cannot finish this action.
		if(VisualizationBlockContext.GetResumeState() != none)
		{
			UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false); 
		}		
		else
		{
			if (Unit.TargetingCamera != None)
				`CAMERASTACK.RemoveCamera(Unit.TargetingCamera);
		}
		bAllowInterrupt = true;
	}
	else
	{
		CompleteAction();
	}
}

event HandleNewUnitSelection()
{
	if( FramingCamera != None )
	{
		`CAMERASTACK.RemoveCamera(FramingCamera);
		FramingCamera = None;
	}
}


DefaultProperties
{	
}
