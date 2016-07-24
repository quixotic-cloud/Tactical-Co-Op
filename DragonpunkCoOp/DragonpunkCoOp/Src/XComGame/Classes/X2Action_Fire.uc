//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Fire extends X2Action;

//Cached info for performing the action
//*************************************
var protected XGWeapon            WeaponVisualizer;
//*************************************

//@TODO - rmcfall/jbouscher - base this on some logic provided by the ability, projectile speed, etc.
var private bool					bShooter;
var private bool					bWasHit;
var protected float					NotifyTargetTimer;
var protected bool					bUseAnimToSetNotifyTimer;
var protected X2VisualizerInterface	PrimaryTarget;
var protected XGUnit				TargetUnit;
var protected Vector                TargetLocation;
var public array<Vector>			allHitLocations;
var public Vector					ProjectileHitLocation;
var protected Vector				AimAtLocation;
var protected XComGameStateHistory  History;
var privatewrite int                PrimaryTargetID;
var privatewrite bool               bNotifyMultiTargetsAtOnce;

var private XComPresentationLayer PresentationLayer;
var private bool			 bComingFromEndMove;
var private bool			 bUseKillAnim;
var protected CustomAnimParams AnimParams;
var protected CustomAnimParams AdditiveAnimParams;
var private vector MoveEndDestination;
var private vector MoveEndDirection;
var private vector ToTarget;
var private array<X2UnifiedProjectile> ProjectileVolleys; //Tracks projectiles created during this fire action
var protected bool			 bHaltAimUpdates;
var protected array<name>    ShooterAdditiveAnims;

var XComGameStateContext_Ability AbilityContext;
var XComGameState VisualizeGameState;
var XComGameState_Unit SourceUnitState;
var XComGameState_Item SourceItemGameState;
var X2AbilityTemplate AbilityTemplate;
var XComPerkContent kPerkContent;
var bool bUpdatedMusicState;

var Actor FOWViewer;
var Actor SourceFOWViewer;
var bool AllowInterrupt;

var private array<XComPerkContent> Perks;
var private array<name> PerkAdditiveAnimNames;
var private int x;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_Ability AbilityState;	
	local XGUnit FiringUnit;	
	local XComPrecomputedPath Path;
	local XComGameState_Item WeaponItem;
	local X2WeaponTemplate WeaponTemplate;
	local Actor TargetVisualizer;
	local Vector TargetLoc;
	local string MissAnimString;
	local name MissAnimName;
	local int LastCharacter;
	local float DistanceForAttack;
	local XComGameState_Item Item;
	local XGWeapon AmmoWeapon;
	local XComWeapon Entity;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local name AdditiveAnim;

	super.Init(InTrack);

	PresentationLayer = `PRES;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	VisualizeGameState = AbilityContext.GetLastStateInInterruptChain();

	History = `XCOMHISTORY;

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	SourceItemGameState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	AbilityTemplate = AbilityState.GetMyTemplate();

	bComingFromEndMove = AbilityContext.InputContext.MovementPaths.Length > 0;
	if(bComingFromEndMove && AbilityContext.InputContext.MovementPaths[0].MovementData.Length > 0)
	{
		MoveEndDestination = AbilityContext.InputContext.MovementPaths[0].MovementData[AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1].Position;
	}
	else
	{
		MoveEndDestination = UnitPawn.Location;
	}

	MoveEndDirection = vector(UnitPawn.Rotation);

	bUseKillAnim = false;
	if (PrimaryTargetID == 0)
		PrimaryTargetID = AbilityContext.InputContext.PrimaryTarget.ObjectID;

	if( PrimaryTargetID > 0 )
	{
		TargetVisualizer = History.GetGameStateForObjectID( PrimaryTargetID ).GetVisualizer();		
		TargetUnit = XGUnit(TargetVisualizer);
		PrimaryTarget = X2VisualizerInterface(TargetVisualizer);
		bUseKillAnim = XComGameState_Unit(History.GetGameStateForObjectID(PrimaryTargetID)).IsDead();		
		TargetLoc = TargetVisualizer.Location;
	}

	if( AbilityContext.InputContext.TargetLocations.Length > 0 )
	{		
		TargetLocation = AbilityContext.InputContext.TargetLocations[0];
		TargetLoc = TargetLocation;
		AimAtLocation = TargetLocation;
	}

	MoveEndDirection = TargetLoc - MoveEndDestination;
	MoveEndDirection.Z = 0;
	if( MoveEndDirection.X == 0.0f && MoveEndDirection.Y == 0.0f )
	{
		MoveEndDirection = vector(UnitPawn.Rotation);
	}
	MoveEndDirection = Normal(MoveEndDirection);

	DistanceForAttack = VSize2D(MoveEndDestination - UnitPawn.Location);

	AnimParams.AnimName = AbilityState.GetFireAnimationName(UnitPawn, bComingFromEndMove, bUseKillAnim, MoveEndDirection, vector(UnitPawn.Rotation), PrimaryTargetID == SourceUnitState.ObjectID, DistanceForAttack);

	// Check for hit or miss. If miss, remove A, append MissA. Only orverwrite if can play.
	if( !class'XComGameStateContext_Ability'.static.IsHitResultHit(AbilityContext.ResultContext.HitResult) )
	{
		MissAnimString = string(AnimParams.AnimName);
		LastCharacter = Asc(Right(MissAnimString, 1));
		
		// Jwats: Only remove the A-Z if it is there, otherwise leave it the same
		if( LastCharacter >= 65 && LastCharacter <= 90 )
		{
			MissAnimString = Mid(MissAnimString, 0, (Len(MissAnimString) - 1));
		}
		
		MissAnimString $= "Miss";
		MissAnimName = name(MissAnimString);

		if( UnitPawn.GetAnimTreeController().CanPlayAnimation(MissAnimName) )
		{
			AnimParams.AnimName = MissAnimName;
		}
	}

	if (bComingFromEndMove)
	{
		AnimParams.HasDesiredEndingAtom = true;
		AnimParams.DesiredEndingAtom.Translation = MoveEndDestination;
		AnimParams.DesiredEndingAtom.Translation.Z = Unit.GetDesiredZForLocation(MoveEndDestination);
		AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(MoveEndDirection));
		AnimParams.DesiredEndingAtom.Scale = 1.0f;

		Unit.RestoreLocation = AnimParams.DesiredEndingAtom.Translation;
		Unit.RestoreHeading = vector(QuatToRotator(AnimParams.DesiredEndingAtom.Rotation));
	}


	if (SourceItemGameState != none)
		WeaponVisualizer = XGWeapon(SourceItemGameState.GetVisualizer());

	//Set the timeout based on our expected run time
	if( AbilityTemplate.TargetingMethod.static.GetProjectileTimingStyle() == class'X2TargetingMethod_Grenade'.default.ProjectileTimingStyle )
	{
		Path = `PRECOMPUTEDPATH;
		FiringUnit = XGUnit(History.GetVisualizer(AbilityState.OwnerStateObject.ObjectID));
		
		WeaponItem = AbilityState.GetSourceWeapon();
		WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());

		// grenade tosses hide the weapon
		if( AbilityTemplate.bHideWeaponDuringFire )
		{
			WeaponVisualizer.GetEntity( ).Mesh.SetHidden( false );						// unhide the grenade that was hidden after the last one fired
		}
		else if( AbilityTemplate.bHideAmmoWeaponDuringFire)
		{
			Item = XComGameState_Item( `XCOMHISTORY.GetGameStateForObjectID( AbilityState.SourceAmmo.ObjectID ) );
			AmmoWeapon = XGWeapon( Item.GetVisualizer( ) );
			Entity = XComWeapon( AmmoWeapon.m_kEntity );
			Entity.Mesh.SetHidden( true );
		}

		if( AbilityTemplate.bUseThrownGrenadeEffects )
		{
			// hackhackhack - we are assuming the underhand fire name here! --Ned
			if (Path.m_bIsUnderhandToss)
				AnimParams.AnimName = 'FF_GrenadeUnderhand';
		}

		Path.SetWeaponAndTargetLocation( WeaponVisualizer.GetEntity( ), FiringUnit.GetTeam( ), AbilityContext.InputContext.TargetLocations[ 0 ], WeaponTemplate.WeaponPrecomputedPathData );

		if (Path.iNumKeyframes <= 0) // just in case (but mostly because replays don't have a proper path computed)
		{
			Path.CalculateTrajectoryToTarget( WeaponTemplate.WeaponPrecomputedPathData );
			`assert( Path.iNumKeyframes > 0 );
		}

		Path.bUseOverrideTargetLocation = true;
		Path.UpdateTrajectory();
		Path.bUseOverrideTargetLocation = false; //Only need this for the above calculation
		NotifyTargetTimer = Path.GetEndTime() + 1.5f;
		bUseAnimToSetNotifyTimer = false;

		AimAtLocation = Path.ExtractInterpolatedKeyframe(0.3f).vLoc;
	}
	else if( AbilityTemplate.TargetingMethod.static.GetProjectileTimingStyle() == class'X2TargetingMethod_BlasterLauncher'.default.ProjectileTimingStyle )
	{
		Path = `PRECOMPUTEDPATH;
		FiringUnit = XGUnit(History.GetVisualizer(AbilityState.OwnerStateObject.ObjectID));
		
		WeaponItem = AbilityState.GetSourceWeapon();
		WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());

		Path.SetWeaponAndTargetLocation( WeaponVisualizer.GetEntity( ), FiringUnit.GetTeam( ), AbilityContext.InputContext.TargetLocations[ 0 ], WeaponTemplate.WeaponPrecomputedPathData );

		if (Path.iNumKeyframes <= 0) // just in case (but mostly because replays don't have a proper path computed)
		{
			Path.CalculateBlasterBombTrajectoryToTarget();
			`assert( Path.iNumKeyframes > 0 );
		}

		NotifyTargetTimer = Path.GetEndTime() + 1.5f;
		bUseAnimToSetNotifyTimer = false;

		AimAtLocation = Path.ExtractInterpolatedKeyframe(0.3f).vLoc;
	}
	else
	{
		//RAM - backwards compatibility support for old projectiles
		NotifyTargetTimer = UnitPawn.GetAnimTreeController().GetFirstCustomFireNotifyTime(AnimParams.AnimName);
		if( NotifyTargetTimer > 0.0f )
		{
			bUseAnimToSetNotifyTimer = true;
		}
	}

	foreach SourceUnitState.AppliedEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		AdditiveAnim = EffectState.GetX2Effect().ShooterAdditiveAnimOnFire(StateChangeContext, SourceUnitState, EffectState);
		if (AdditiveAnim != '')
			ShooterAdditiveAnims.AddItem(AdditiveAnim);
	}
}

function SetFireParameters(bool bHit, optional int OverrideTargetID, optional bool NotifyMultiTargetsAtOnce=true)
{
	bWasHit = bHit;
	PrimaryTargetID = OverrideTargetID;
	bNotifyMultiTargetsAtOnce = NotifyMultiTargetsAtOnce;
}

function HandleTrackMessage()
{
	if( AllowInterrupt )
	{
		//Currently we only receive a message when being counterattacked, indicating that we should stop right now and move to our hit react
		CompleteAction();
	}
}

function NotifyTargetsAbilityApplied()
{
	local int HistoryIndex;
	
	if( !bNotifiedTargets )
	{
		HistoryIndex = CurrentHistoryIndex;
		if( bComingFromEndMove )
		{
			HistoryIndex = -1;
		}
		DoNotifyTargetsAbilityAppliedWithMultipleHitLocations(VisualizeGameState, AbilityContext, HistoryIndex, ProjectileHitLocation, allHitLocations, PrimaryTargetID, bNotifyMultiTargetsAtOnce);

		if( Unit.CurrentPerkAction != None )
		{
			Unit.CurrentPerkAction.TriggerImpact();
		}
	}
}

function NotifyTargetsProjectileHit()
{
	local StateObjectReference Target;

	// Only send additional projectiles if we've already notfied the target.  The target will then decide how to deal with it.
	if( bNotifiedTargets )
	{
		if( PrimaryTargetID > 0 )
		{
			Target.ObjectID = PrimaryTargetID;
			VisualizationMgr.SendInterTrackMessage(Target, CurrentHistoryIndex);
		}
	}
}

//This method is called by the projectile system when it hits something
function ProjectileNotifyHit(bool bMainImpactNotify, Vector HitLocation)
{	
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_InteractiveObject InteractiveObject;
	local XComInteractiveLevelActor InteractiveLevelActor;
	local StateObjectReference Target;
	
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{		
		if(EnvironmentDamageEvent.HitLocation == HitLocation)
		{
			Target = EnvironmentDamageEvent.GetReference();
			VisualizationMgr.SendInterTrackMessage(Target, CurrentHistoryIndex);
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		InteractiveLevelActor = XComInteractiveLevelActor(History.GetVisualizer(InteractiveObject.ObjectID));
		if (VSize2D(InteractiveLevelActor.Location - HitLocation) < (class'XComWorldData'.const.WORLD_StepSize))
		{
			Target.ObjectID = InteractiveLevelActor.ObjectID;
			VisualizationMgr.SendInterTrackMessage(Target, CurrentHistoryIndex);
		}
	}

	if(bMainImpactNotify)
	{
		ProjectileHitLocation = HitLocation;
		NotifyTargetsAbilityApplied();
	}
	
	NotifyTargetsProjectileHit();
	
}

function MarkReactionFireDone()
{
	class'XComTacticalGRI'.static.GetReactionFireSequencer().MarkReactionFireInstanceDone(AbilityContext);
}

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
	ProjectileVolleys.AddItem(NewProjectile);

	if(!bUpdatedMusicState)	
	{
		`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();
		bUpdatedMusicState = true;
	}

	if(class'XComTacticalGRI'.static.GetReactionFireSequencer().IsReactionFire(AbilityContext))
	{
		SetTimer(0.5f, false, nameof(MarkReactionFireDone));
	}
}

function EndVolleyConstants( AnimNotify_EndVolleyConstants Notify )
{
	local int Index;

	for (Index = 0; Index < ProjectileVolleys.Length; ++Index)
	{
		if (ProjectileVolleys[Index] != none)
		{
			ProjectileVolleys[Index].EndConstantProjectileEffects();
		}
	}
}

// Called by the animation system to place an impact decal in the world
function NotifyApplyDecal(XComAnimNotify_TriggerDecal Notify)
{
	local vector StartLocation, EndLocation;
	local XComWorldData World;
	local int i;
	
	World = `XWORLD;

	for( i = 0; i < AbilityContext.InputContext.TargetLocations.Length; ++i )
	{
		StartLocation = AbilityContext.InputContext.TargetLocations[i];
		StartLocation.Z += 0.5f;    // Offset by a bit to make sure we have an acutal travel direction
		EndLocation = AbilityContext.InputContext.TargetLocations[i];
		EndLocation.Z = World.GetFloorZForPosition(EndLocation, false) - 0.5f;  // Offset by a bit to make sure we have an acutal travel direction

		Unit.AddDecalProjectile(StartLocation, EndLocation, AbilityContext);
	}
}

function bool IsTimedOut()
{
	return ExecutingTime >= TimeoutSeconds;
}

function CompleteAction()
{
	EndVolleyConstants( none ); //end everything just to be safe and not leak projectiles that are just hanging around, executing and doing nothing

	if(class'XComTacticalGRI'.static.GetReactionFireSequencer().IsReactionFire(AbilityContext))
	{
		class'XComTacticalGRI'.static.GetReactionFireSequencer().PopReactionFire(AbilityContext);		
	}

	if( !bNotifiedTargets && IsTimedOut() )
	{
		NotifyTargetsAbilityApplied();
	}

	`assert(Unit.CurrentFireAction == self);
	Unit.CurrentFireAction = none;

	// Do this last, because if two X2Action_Fire actions are played back to back, the next Fire will
	// immediately set Unit.CurrentFireAction to itself, which, if this came sooner, might mess up
	// the above code.  mdomowicz 2015_10_23
	super.CompleteAction();
}

simulated state Executing
{
	simulated function BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);

		Unit.CurrentFireAction = self;
	}

	simulated event Tick( float fDeltaT )
	{	
		NotifyTargetTimer -= fDeltaT;		

		if( bUseAnimToSetNotifyTimer && !bNotifiedTargets && NotifyTargetTimer < 0.0f )
		{
			NotifyTargetsAbilityApplied();
		}

		UpdateAim(fDeltaT);
	}

	simulated function UpdateAim(float DT)
	{
		if (PrimaryTargetID == SourceUnitState.ObjectID) //We can't aim at ourselves, or IK will explode
			return;

		if(class'XComTacticalGRI'.static.GetReactionFireSequencer().FiringAtMovingTarget())
		{
			//Use a special aiming location if we are part of a reaction fire sequence
			UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
		}		
		else if(!bNotifiedTargets && !bHaltAimUpdates && !UnitPawn.ProjectileOverwriteAim ) //Projectile overwrites the normal aim upon firing, as projectile have the ability to miss Chang You Wong 2015-23-6
		{
			if((PrimaryTarget != none) && AbilityContext.ResultContext.HitResult != eHit_Miss)
			{
				UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
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
			}
		}
	}

	function SetTargetUnitDiscState()
	{
		if( TargetUnit != None && TargetUnit.IsMine() )
		{
			TargetUnit.SetDiscState(eDS_Hidden);
		}

		if( Unit != None )
		{
			Unit.SetDiscState(eDS_Hidden);
		}
	}

	function HideFOW()
	{
		FOWViewer = `XWORLD.CreateFOWViewer(XGUnit(PrimaryTarget).GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);

		XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();

		SourceFOWViewer = `XWORLD.CreateFOWViewer(Unit.GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);
		Unit.SetForceVisibility(eForceVisible);
		Unit.GetPawn().UpdatePawnVisibility();
	}

Begin:
	if (XGUnit(PrimaryTarget).GetTeam() == eTeam_Neutral)
	{
		HideFOW();

		// Sleep long enough for the fog to be revealed
		Sleep(1.0f * GetDelayModifier());
	}

	
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	class'XComPerkContent'.static.GetAssociatedPerks(Perks, UnitPawn, AbilityContext.InputContext.AbilityTemplateName);
	for( x = 0; x < Perks.Length; ++x )
	{
		kPerkContent = Perks[x];

		if( (kPerkContent.IsInState('ActionActive') || kPerkContent.IsInState('DurationAction')) &&
			kPerkContent.CasterActivationAnim.PlayAnimation &&
			kPerkContent.CasterActivationAnim.AdditiveAnim )
		{
			PerkAdditiveAnimNames.AddItem(class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.CasterActivationAnim));
		}
	}

	for( x =0; x < PerkAdditiveAnimNames.Length; ++x )
	{
		AdditiveAnimParams.AnimName = PerkAdditiveAnimNames[x];
		UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AdditiveAnimParams);
	}
	for (x = 0; x < ShooterAdditiveAnims.Length; ++x)
	{
		AdditiveAnimParams.AnimName = ShooterAdditiveAnims[x];
		UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AdditiveAnimParams);
	}

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	for( x =0; x < PerkAdditiveAnimNames.Length; ++x )
	{
		AdditiveAnimParams.AnimName = PerkAdditiveAnimNames[x];
		UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AdditiveAnimParams);
	}
	for (x = 0; x < ShooterAdditiveAnims.Length; ++x)
	{
		AdditiveAnimParams.AnimName = ShooterAdditiveAnims[x];
		UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AdditiveAnimParams);
	}

	// Taking a shot causes overwatch to be removed
	PresentationLayer.m_kUnitFlagManager.RealizeOverwatch(Unit.ObjectID, History.GetCurrentHistoryIndex());

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	SetTargetUnitDiscState();

	if( FOWViewer != none )
	{
		`XWORLD.DestroyFOWViewer(FOWViewer);

		if( XGUnit(PrimaryTarget).IsAlive() )
		{
			XGUnit(PrimaryTarget).SetForceVisibility(eForceNone);
			XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
		}
	}

	if( SourceFOWViewer != none )
	{
		`XWORLD.DestroyFOWViewer(SourceFOWViewer);

		Unit.SetForceVisibility(eForceNone);
		Unit.GetPawn().UpdatePawnVisibility();
	}

	CompleteAction();
	//reset to false, only during firing would the projectile be able to overwrite aim
	UnitPawn.ProjectileOverwriteAim = false;
}

event bool BlocksAbilityActivation()
{
	return true;
}

DefaultProperties
{
	NotifyTargetTimer = 0.75;
	TimeoutSeconds = 10.0f; //Should eventually be an estimate of how long we will run
	bNotifyMultiTargetsAtOnce = true
	bCauseTimeDilationWhenInterrupting = true
	AllowInterrupt = true
}
