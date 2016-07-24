//---------------------------------------------------------------------------------------
//  FILE:    X2Ability.uc
//  AUTHOR:  Ryan McFall  --  11/11/2013
//  PURPOSE: Interface for adding new abilities to X-Com 2. Extend this class and then
//           implement CreateAbilityTemplates to produce one or more ability templates
//           defining new abilities.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability extends X2DataSet
	config(GameCore)
	native(Core)
	dependson(XComGameStateContext_Ability);

// Maximum angle at which a missed shot will angle its projectile visuals
var private const config float MaxProjectileMissOffset_Standard; // Maximum distance from the shoot at location for misses, in meters (1.0f = 64 unreal units)
var private const config float MaxProjectileMissOffset_Close;	 // Maximum distance from the shoot at location for misses at close range ( < 2 tiles ), in meters (1.0f = 64 unreal units)
var private const config float MinProjectileMissOffset;			 // Minimum distance from the target that a miss trajectory should take - safeguard against misses that don't visually miss
var private const config float MaxProjectileHalfAngle;			 // Controls the arc where misses can happen

//---------------------------------------------------------------------------------------
//      Careful, these objects should NEVER be modified - only constructed by default.
//      They can be freely used by any ability template, but NEVER modified by them.
var protected X2AbilityToHitCalc_DeadEye    DeadEye;
var protected X2AbilityToHitCalc_StandardAim SimpleStandardAim;
var protected X2Condition_UnitProperty      LivingShooterProperty;
var protected X2Condition_UnitProperty      LivingHostileTargetProperty, LivingHostileUnitOnlyProperty, LivingTargetUnitOnlyProperty, LivingTargetOnlyProperty, LivingHostileUnitDisallowMindControlProperty;
var protected X2AbilityTrigger_PlayerInput  PlayerInputTrigger;
var protected X2AbilityTrigger_UnitPostBeginPlay UnitPostBeginPlayTrigger;
var protected X2AbilityTarget_Self          SelfTarget;
var protected X2AbilityTarget_Single        SimpleSingleTarget;
var protected X2AbilityTarget_Single        SimpleSingleMeleeTarget;
var protected X2AbilityTarget_Single        SingleTargetWithSelf;
var protected X2Condition_Visibility        GameplayVisibilityCondition;
var protected X2Condition_Visibility        MeleeVisibilityCondition;
var protected X2AbilityCost_ActionPoints    FreeActionCost;
var protected X2Effect_ApplyWeaponDamage    WeaponUpgradeMissDamage;
//---------------------------------------------------------------------------------------

//General ability values
//---------------------------------------------------------------------------------------
var name CounterattackDodgeEffectName;
var int CounterattackDodgeUnitValue;
//---------------------------------------------------------------------------------------

//This method generates a miss location that attempts avoid hitting other units, obstacles near to the shooter, etc.
native static function Vector FindOptimalMissLocation(XComGameStateContext AbilityContext, bool bDebug);
native static function Vector GetTargetShootAtLocation(XComGameStateContext_Ability AbilityContext);
static function UpdateTargetLocationsFromContext(XComGameStateContext_Ability AbilityContext)
{
	local XComGameStateHistory History;
	local XComLevelActor LevelActor;
	local XComGameState_Ability ShootAbilityState;
	local X2AbilityTemplate AbilityTemplate;	
	local X2VisualizerInterface PrimaryTargetVisualizer;
	local vector MissLocation;
	local int TargetIndex;
	local vector TargetShootAtLocation;

	History = `XCOMHISTORY;

	ShootAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = ShootAbilityState.GetMyTemplate();

	// Generate a list of locations in the world to effect	
	if(AbilityTemplate.AbilityTargetEffects.Length > 0 && AbilityContext.InputContext.PrimaryTarget.ObjectID != 0)
	{
		PrimaryTargetVisualizer = X2VisualizerInterface(History.GetVisualizer(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if(PrimaryTargetVisualizer != none)
		{
			//Always have a target location that matches the primary target
			TargetShootAtLocation = GetTargetShootAtLocation(AbilityContext);
			AbilityContext.InputContext.TargetLocations.AddItem(TargetShootAtLocation);

			//Here we set projectile hit locations. These locations MUST represent the stopping point of the projectile or else 
			//severe issues will result in the projectile system.
			if(AbilityContext.IsResultContextMiss() || AbilityTemplate.bIsASuppressionEffect)
			{
				if(`CHEATMGR != none && `CHEATMGR.ForceMissedProjectileHitActorTag != "")
				{
					foreach `BATTLE.AllActors(class'XComLevelActor', LevelActor)
					{
						if(string(LevelActor.Tag) == `CHEATMGR.ForceMissedProjectileHitActorTag)
						{
							MissLocation = LevelActor.Location;
							AbilityContext.ResultContext.ProjectileHitLocations.AddItem(MissLocation);
							break;
						}
					}
				}
				if (`CHEATMGR != none && `CHEATMGR.UseForceMissedProjectileHitTile)
				{
					if (!`XWORLD.GetFloorPositionForTile( `CHEATMGR.ForceMissedProjectileHitTile, MissLocation ))
					{
						MissLocation = `XWORLD.GetPositionFromTileCoordinates( `CHEATMGR.ForceMissedProjectileHitTile );
					}

					AbilityContext.ResultContext.ProjectileHitLocations.AddItem( MissLocation );
				}
				else
				{
					if(AbilityTemplate.IsMelee() == false)
					{
						AbilityContext.ResultContext.ProjectileHitLocations.AddItem(FindOptimalMissLocation(AbilityContext, false));

						if(AbilityTemplate.bIsASuppressionEffect) // Add a bunch of target locations for suppression
						{
							for(TargetIndex = 0; TargetIndex < 5; ++TargetIndex)
							{
								AbilityContext.ResultContext.ProjectileHitLocations.AddItem(FindOptimalMissLocation(AbilityContext, false));
							}
						}
					}
				}
			}
			else
			{
				AbilityContext.ResultContext.ProjectileHitLocations.AddItem(AbilityContext.InputContext.TargetLocations[0]);
			}
		}		
	}
	else if(AbilityContext.InputContext.TargetLocations.Length > 0)
	{
		//This indicates an ability that was free-aimed. Copy the target location into the projectile hit locations for this type of ability.
		AbilityContext.ResultContext.ProjectileHitLocations.AddItem(AbilityContext.InputContext.TargetLocations[0]);
	}
}

//This function will analyze a game state and generate damage events based on the touch event list
static function GenerateDamageEvents(XComGameState NewGameState, XComGameStateContext_Ability AbilityContext)
{
	local XComGameStateHistory History;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Item SourceItemStateObject;
	local X2WeaponTemplate WeaponTemplate;
	local XComInteractiveLevelActor InteractActor;
	local XComGameState_InteractiveObject InteractiveObject;
	local name SocketName;
	local Vector SocketLocation;
	local float AbilityRadius;
	local int Index;

	local int PhysicalImpulseAmount;
	local name DamageTypeTemplateName;
	
	//If this damage effect has an associated position, it does world damage
	if(AbilityContext.ResultContext.ProjectileHitLocations.Length > 0)
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
		if(SourceItemStateObject != None)
		{
			WeaponTemplate = X2WeaponTemplate(SourceItemStateObject.GetMyTemplate());
		}
			
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));		

		if((SourceStateObject != none && AbilityStateObject != none) && (SourceItemStateObject != none))
		{
			AbilityRadius = AbilityStateObject.GetAbilityRadius();

			if(WeaponTemplate != none)
			{
				PhysicalImpulseAmount = WeaponTemplate.iPhysicsImpulse;
				DamageTypeTemplateName = WeaponTemplate.DamageTypeTemplateName;
			}
			else
			{
				PhysicalImpulseAmount = 0;
				DamageTypeTemplateName = 'Explosion';
			}

			//The touch list includes a start and end point. Do not apply travelling damage to these points
			for(Index = 1; Index < AbilityContext.InputContext.ProjectileEvents.Length; ++Index)
			{
				if(AbilityContext.InputContext.ProjectileEvents[Index].bEntry)
				{
					DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage'));
					DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Ability:GenerateProjectileTouchEvents";
					DamageEvent.DamageTypeTemplateName = DamageTypeTemplateName;
					DamageEvent.HitLocation = AbilityContext.InputContext.ProjectileEvents[Index].HitLocation;
					DamageEvent.Momentum = (AbilityRadius == 0.0f) ? -AbilityContext.InputContext.ProjectileEvents[Index].HitNormal : vect(0, 0, 0);
					DamageEvent.PhysImpulse = PhysicalImpulseAmount;
					DamageEvent.DamageRadius = 16.0f;					
					DamageEvent.DamageCause = SourceStateObject.GetReference();
					DamageEvent.DamageSource = DamageEvent.DamageCause;
					DamageEvent.bRadialDamage = AbilityRadius > 0;

					if ( XComTileFracLevelActor(AbilityContext.InputContext.ProjectileEvents[Index].TraceInfo.HitComponent.Owner) != none )
					{
						DamageEvent.DamageAmount = 20;
						DamageEvent.bAffectFragileOnly = false;
						DamageEvent.DamageDirection = AbilityContext.InputContext.ProjectileTouchEnd - AbilityContext.InputContext.ProjectileTouchStart;
					}
					else
					{
						DamageEvent.DamageAmount = 1;
						DamageEvent.bAffectFragileOnly = true;
					}

					NewGameState.AddStateObject(DamageEvent);

					InteractActor = XComInteractiveLevelActor(AbilityContext.InputContext.ProjectileEvents[Index].TraceInfo.HitComponent.Owner);
					if (InteractActor != none && InteractActor.IsDoor() && InteractActor.GetInteractionCount() % 2 == 0 && WeaponTemplate.Name != 'Flamethrower' )
					{
						//Special handling for doors. They are knocked open by projectiles ( if the projectiles don't destroy them first )
						InteractiveObject = XComGameState_InteractiveObject(InteractActor.GetState(NewGameState));
						InteractActor.GetClosestSocket(AbilityContext.InputContext.ProjectileEvents[Index].HitLocation, SocketName, SocketLocation);
						InteractiveObject.Interacted(SourceStateObject, NewGameState, SocketName);
					}

					//`SHAPEMGR.DrawSphere(DamageEvent.HitLocation, vect(10, 10, 10), MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f), true);
				}
			}
			
		}
	}
}

//Used by charging melee attacks to perform a move and an attack.
static function XComGameState TypicalMoveEndAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	// finalize the movement portion of the ability
	class'X2Ability_DefaultAbilitySet'.static.MoveAbility_FillOutGameState(NewGameState, false); //Do not apply costs at this time.

	// build the "fire" animation for the slash
	TypicalAbility_FillOutGameState(NewGameState); //Costs applied here.

	return NewGameState;
}

//Used by charging melee attacks - needed to handle the case where no movement occurs first, which isn't handled by MoveAbility_BuildInterruptGameState.
static function XComGameState TypicalMoveEndAbility_BuildInterruptGameState(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local int MovingUnitIndex, NumMovementTiles;

	AbilityContext = XComGameStateContext_Ability(Context);
	`assert(AbilityContext != None);

	if (AbilityContext.InputContext.MovementPaths.Length == 0) //No movement - use the trivial case in TypicalAbility_BuildInterruptGameState
	{
		return TypicalAbility_BuildInterruptGameState(Context, InterruptStep, InterruptionStatus);
	}
	else //Movement - MoveAbility_BuildInterruptGameState can handle
	{
		NewGameState = class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildInterruptGameState(Context, InterruptStep, InterruptionStatus);
		if (NewGameState == none && InterruptionStatus == eInterruptionStatus_Interrupt)
		{
			//  all movement has processed interruption, now allow the ability to be interrupted for the attack
			for(MovingUnitIndex = 0; MovingUnitIndex < AbilityContext.InputContext.MovementPaths.Length; ++MovingUnitIndex)
			{
				NumMovementTiles = Max(NumMovementTiles, AbilityContext.InputContext.MovementPaths[MovingUnitIndex].MovementTiles.Length);
			}
			//  only interrupt when movement is completed, and not again afterward
			if(InterruptStep == (NumMovementTiles - 1))			
			{
				NewGameState = `XCOMHISTORY.CreateNewGameState(true, AbilityContext);
				AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
				//  setup game state as though movement is fully completed so that the unit state's location is up to date
				class'X2Ability_DefaultAbilitySet'.static.MoveAbility_FillOutGameState(NewGameState, false); //Do not apply costs at this time.
				AbilityContext.SetInterruptionStatus(InterruptionStatus);
				AbilityContext.ResultContext.InterruptionStep = InterruptStep;
			}
		}
		return NewGameState;
	}
}

static function XComGameState TypicalAbility_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);

	TypicalAbility_FillOutGameState(NewGameState);

	return NewGameState;
}

// this function exists outside of TypicalAbility_BuildGameState so that you can do typical ability state 
// modifications to an existing game state. Useful for building compound game states 
// (such as adding an attack to the end of a move)
static function TypicalAbility_FillOutGameState(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability ShootAbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameStateContext_Ability AbilityContext;
	local int TargetIndex;	

	local XComGameState_BaseObject AffectedTargetObject_OriginalState;	
	local XComGameState_BaseObject AffectedTargetObject_NewState;
	local XComGameState_BaseObject SourceObject_OriginalState;
	local XComGameState_BaseObject SourceObject_NewState;
	local XComGameState_Item       SourceWeapon, SourceWeapon_NewState;
	local X2AmmoTemplate           AmmoTemplate;
	local X2GrenadeTemplate        GrenadeTemplate;
	local X2WeaponTemplate         WeaponTemplate;
	local EffectResults            MultiTargetEffectResults, EmptyResults;
	local EffectTemplateLookupType MultiTargetLookupType;

	History = `XCOMHISTORY;	

	//Build the new game state frame, and unit state object for the acting unit
	`assert(NewGameState != none);
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	ShootAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));	
	AbilityTemplate = ShootAbilityState.GetMyTemplate();
	SourceObject_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);	
	SourceWeapon = ShootAbilityState.GetSourceWeapon();
	ShootAbilityState = XComGameState_Ability(NewGameState.CreateStateObject(ShootAbilityState.Class, ShootAbilityState.ObjectID));
	NewGameState.AddStateObject(ShootAbilityState);

	//Any changes to the shooter / source object are made to this game state
	SourceObject_NewState = NewGameState.CreateStateObject(SourceObject_OriginalState.Class, AbilityContext.InputContext.SourceObject.ObjectID);
	NewGameState.AddStateObject(SourceObject_NewState);

	if (SourceWeapon != none)
	{
		SourceWeapon_NewState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', SourceWeapon.ObjectID));
		NewGameState.AddStateObject(SourceWeapon_NewState);
	}

	if (AbilityTemplate.bRecordValidTiles && AbilityContext.InputContext.TargetLocations.Length > 0)
	{
		AbilityTemplate.AbilityMultiTargetStyle.GetValidTilesForLocation(ShootAbilityState, AbilityContext.InputContext.TargetLocations[0], AbilityContext.ResultContext.RelevantEffectTiles);
	}

	//If there is a target location, generate a list of projectile events to use if a projectile is requested
	if(AbilityContext.InputContext.ProjectileEvents.Length > 0)
	{
		GenerateDamageEvents(NewGameState, AbilityContext);
	}

	//  Apply effects to shooter
	if (AbilityTemplate.AbilityShooterEffects.Length > 0)
	{
		AffectedTargetObject_OriginalState = SourceObject_OriginalState;
		AffectedTargetObject_NewState = SourceObject_NewState;				
			
		ApplyEffectsToTarget(
			AbilityContext, 
			AffectedTargetObject_OriginalState, 
			SourceObject_OriginalState, 
			ShootAbilityState, 
			AffectedTargetObject_NewState, 
			NewGameState, 
			AbilityContext.ResultContext.HitResult,
			AbilityContext.ResultContext.ArmorMitigation,
			AbilityContext.ResultContext.StatContestResult,
			AbilityTemplate.AbilityShooterEffects, 
			AbilityContext.ResultContext.ShooterEffectResults, 
			AbilityTemplate.DataName, 
			TELT_AbilityShooterEffects);
			
		NewGameState.AddStateObject(AffectedTargetObject_NewState);
	}

	//  Apply effects to primary target
	if (AbilityContext.InputContext.PrimaryTarget.ObjectID != 0)
	{
		AffectedTargetObject_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference);
		AffectedTargetObject_NewState = NewGameState.CreateStateObject(AffectedTargetObject_OriginalState.Class, AbilityContext.InputContext.PrimaryTarget.ObjectID);
		
		if (AbilityTemplate.AbilityTargetEffects.Length > 0)
		{
			if (ApplyEffectsToTarget(
				AbilityContext, 
				AffectedTargetObject_OriginalState, 
				SourceObject_OriginalState, 
				ShootAbilityState, 
				AffectedTargetObject_NewState, 
				NewGameState, 
				AbilityContext.ResultContext.HitResult,
				AbilityContext.ResultContext.ArmorMitigation,
				AbilityContext.ResultContext.StatContestResult,
				AbilityTemplate.AbilityTargetEffects, 
				AbilityContext.ResultContext.TargetEffectResults, 
				AbilityTemplate.DataName, 
				TELT_AbilityTargetEffects))

			{
				if (AbilityTemplate.bAllowAmmoEffects && SourceWeapon_NewState != none && SourceWeapon_NewState.HasLoadedAmmo())
				{
					AmmoTemplate = X2AmmoTemplate(SourceWeapon_NewState.GetLoadedAmmoTemplate(ShootAbilityState));
					if (AmmoTemplate != none && AmmoTemplate.TargetEffects.Length > 0)
					{
						ApplyEffectsToTarget(
							AbilityContext, 
							AffectedTargetObject_OriginalState, 
							SourceObject_OriginalState, 
							ShootAbilityState, 
							AffectedTargetObject_NewState, 
							NewGameState, 
							AbilityContext.ResultContext.HitResult,
							AbilityContext.ResultContext.ArmorMitigation,
							AbilityContext.ResultContext.StatContestResult,
							AmmoTemplate.TargetEffects, 
							AbilityContext.ResultContext.TargetEffectResults, 
							AmmoTemplate.DataName,  //Use the ammo template for TELT_AmmoTargetEffects
							TELT_AmmoTargetEffects);
					}
				}
				if (AbilityTemplate.bAllowBonusWeaponEffects && SourceWeapon_NewState != none)
				{
					WeaponTemplate = X2WeaponTemplate(SourceWeapon_NewState.GetMyTemplate());
					if (WeaponTemplate != none && WeaponTemplate.BonusWeaponEffects.Length > 0)
					{
						ApplyEffectsToTarget(
							AbilityContext,
							AffectedTargetObject_OriginalState, 
							SourceObject_OriginalState, 
							ShootAbilityState, 
							AffectedTargetObject_NewState, 
							NewGameState, 
							AbilityContext.ResultContext.HitResult,
							AbilityContext.ResultContext.ArmorMitigation,
							AbilityContext.ResultContext.StatContestResult,
							WeaponTemplate.BonusWeaponEffects, 
							AbilityContext.ResultContext.TargetEffectResults, 
							WeaponTemplate.DataName,
							TELT_WeaponEffects);
					}
				}
			}
		}
			
		NewGameState.AddStateObject(AffectedTargetObject_NewState);

		if (AbilityTemplate.Hostility == eHostility_Offensive && AffectedTargetObject_NewState.CanEarnXp() && XComGameState_Unit(AffectedTargetObject_NewState).IsEnemyUnit(XComGameState_Unit(SourceObject_NewState)))
		{
			`TRIGGERXP('XpGetShotAt', AffectedTargetObject_NewState.GetReference(), SourceObject_NewState.GetReference(), NewGameState);
		}
	}

	if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(ShootAbilityState));
		MultiTargetLookupType = TELT_LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
		MultiTargetLookupType = TELT_ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetLookupType = TELT_AbilityMultiTargetEffects;
	}

	//  Apply effects to multi targets
	if( (AbilityTemplate.AbilityMultiTargetEffects.Length > 0 || GrenadeTemplate != none) && AbilityContext.InputContext.MultiTargets.Length > 0)
	{		
		for( TargetIndex = 0; TargetIndex < AbilityContext.InputContext.MultiTargets.Length; ++TargetIndex )
		{
			AffectedTargetObject_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.MultiTargets[TargetIndex].ObjectID, eReturnType_Reference);
			AffectedTargetObject_NewState = NewGameState.CreateStateObject(AffectedTargetObject_OriginalState.Class, AbilityContext.InputContext.MultiTargets[TargetIndex].ObjectID);
			
			MultiTargetEffectResults = EmptyResults;        //  clear struct for use - cannot pass dynamic array element as out parameter
			if (ApplyEffectsToTarget(
				AbilityContext, 
				AffectedTargetObject_OriginalState, 
				SourceObject_OriginalState, 
				ShootAbilityState, 
				AffectedTargetObject_NewState, 
				NewGameState, 
				AbilityContext.ResultContext.MultiTargetHitResults[TargetIndex],
				AbilityContext.ResultContext.MultiTargetArmorMitigation[TargetIndex],
				AbilityContext.ResultContext.MultiTargetStatContestResult[TargetIndex],
				AbilityTemplate.bUseLaunchedGrenadeEffects ? GrenadeTemplate.LaunchedGrenadeEffects : (AbilityTemplate.bUseThrownGrenadeEffects ? GrenadeTemplate.ThrownGrenadeEffects : AbilityTemplate.AbilityMultiTargetEffects), 
				MultiTargetEffectResults, 
				GrenadeTemplate == none ? AbilityTemplate.DataName : GrenadeTemplate.DataName, 
				MultiTargetLookupType ,
				AbilityContext.ResultContext.MultiTargetEffectsOverrides[TargetIndex]))
			{
				AbilityContext.ResultContext.MultiTargetEffectResults[TargetIndex] = MultiTargetEffectResults;  //  copy results into dynamic array
			}
							
			NewGameState.AddStateObject(AffectedTargetObject_NewState);
		}
	}
	
	//Give all effects a chance to make world modifications ( ie. add new state objects independent of targeting )
	ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, AbilityTemplate.AbilityShooterEffects, AbilityTemplate.DataName, TELT_AbilityShooterEffects);
	ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, AbilityTemplate.AbilityTargetEffects, AbilityTemplate.DataName, TELT_AbilityTargetEffects);	
	if (GrenadeTemplate != none)
	{
		if (AbilityTemplate.bUseLaunchedGrenadeEffects)
		{
			ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, GrenadeTemplate.LaunchedGrenadeEffects, GrenadeTemplate.DataName, TELT_LaunchedGrenadeEffects);
		}
		else if (AbilityTemplate.bUseThrownGrenadeEffects)
		{
			ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, GrenadeTemplate.ThrownGrenadeEffects, GrenadeTemplate.DataName, TELT_ThrownGrenadeEffects);
		}
	}
	else
	{
		ApplyEffectsToWorld(AbilityContext, SourceObject_OriginalState, ShootAbilityState, NewGameState, AbilityTemplate.AbilityMultiTargetEffects, AbilityTemplate.DataName, TELT_AbilityMultiTargetEffects);
	}

	//Apply the cost of the ability
	AbilityTemplate.ApplyCost(AbilityContext, ShootAbilityState, SourceObject_NewState, SourceWeapon_NewState, NewGameState);
}

static function ApplyEffectsToWorld(XComGameStateContext_Ability AbilityContext,
											  XComGameState_BaseObject kSource, 
											  XComGameState_Ability kSourceAbility, 											  
											  XComGameState NewGameState,
											  array<X2Effect> Effects,
											  Name SourceTemplateName,
											  EffectTemplateLookupType EffectLookupType)
{
	local EffectAppliedData ApplyData;
	local int EffectIndex;
	local StateObjectReference NoWeapon;
	local XComGameState_Unit SourceUnit;
	local StateObjectReference DefaultPlayerStateObjectRef;
	local bool bHit, bMiss;
	
	bHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(AbilityContext.ResultContext.HitResult);
	bMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(AbilityContext.ResultContext.HitResult);
	//  Check to see if this was a multi target.
	`assert(bHit || bMiss);     //  Better be one or the other!

	ApplyData.AbilityInputContext = AbilityContext.InputContext;
	ApplyData.AbilityResultContext = AbilityContext.ResultContext;
	ApplyData.AbilityStateObjectRef = kSourceAbility.GetReference();
	ApplyData.SourceStateObjectRef = kSource.GetReference();	
	ApplyData.ItemStateObjectRef = kSourceAbility.GetSourceWeapon() == none ? NoWeapon : kSourceAbility.GetSourceWeapon().GetReference();	
	ApplyData.EffectRef.SourceTemplateName = SourceTemplateName;
	ApplyData.EffectRef.LookupType = EffectLookupType;

	DefaultPlayerStateObjectRef = `TACTICALRULES.GetCachedUnitActionPlayerRef();
	for (EffectIndex = 0; EffectIndex < Effects.Length; ++EffectIndex)
	{
		// Only Apply the effect if the result meets the effect's world application criteria.
		if ( (Effects[EffectIndex].bApplyToWorldOnHit && bHit) ||
			 (Effects[EffectIndex].bApplyToWorldOnMiss && bMiss) )
		{
			ApplyData.PlayerStateObjectRef = DefaultPlayerStateObjectRef;

			if (Effects[EffectIndex].bUseSourcePlayerState)
			{
				// If the source unit's controlling player needs to be saved in
				// ApplyData.PlayerStateObjectRef
				SourceUnit = XComGameState_Unit(kSource);
			
				if (SourceUnit != none)
				{
					ApplyData.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
				}
			}

			ApplyData.EffectRef.TemplateEffectLookupArrayIndex = EffectIndex;
			Effects[EffectIndex].ApplyEffectToWorld(ApplyData, NewGameState);
		}
	}
}

static function bool ApplyEffectsToTarget( XComGameStateContext_Ability AbilityContext,
												XComGameState_BaseObject kOriginalTarget, 
												XComGameState_BaseObject kSource, 
												XComGameState_Ability kSourceAbility, 
												XComGameState_BaseObject kNewTargetState,
												XComGameState NewGameState,
												EAbilityHitResult Result,
												ArmorMitigationResults ArmorMitigated,
												int StatContestResult,
												array<X2Effect> Effects,
												out EffectResults EffectResults,
												Name SourceTemplateName,
												EffectTemplateLookupType EffectLookupType,
												optional OverriddenEffectsByType TargetEffectsOverrides)
{
	local XComGameState_Unit UnitState, SourceUnit, RedirectUnit;
	local EffectAppliedData ApplyData, RedirectData;
	local int EffectIndex;
	local StateObjectReference NoWeapon;
	local bool bHit, bMiss, bRedirected;
	local StateObjectReference DefaultPlayerStateObjectRef;
	local name AffectingRedirectorName, OverrideRedirectResult;
	local XComGameState_Effect RedirectorEffectState;
	local EffectRedirect Redirection, EmptyRedirection;

	UnitState = XComGameState_Unit(kNewTargetState);
	SourceUnit = XComGameState_Unit(kSource);

	`XEVENTMGR.TriggerEvent('UnitAttacked', UnitState, UnitState, NewGameState);

	bHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(Result);
	bMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(Result);
	//  Check to see if this was a multi target.
	`assert(bHit || bMiss);     //  Better be one or the other!

	ApplyData.AbilityInputContext = AbilityContext.InputContext;
	ApplyData.AbilityResultContext = AbilityContext.ResultContext;
	ApplyData.AbilityResultContext.HitResult = Result;                      //  fixes result with multi target result so that effects don't have to dig into the multi target info
	ApplyData.AbilityResultContext.ArmorMitigation = ArmorMitigated;        //  as above
	ApplyData.AbilityResultContext.StatContestResult = StatContestResult;   //  as above
	ApplyData.AbilityResultContext.TargetEffectsOverrides = TargetEffectsOverrides;   //  as above
	ApplyData.AbilityStateObjectRef = kSourceAbility.GetReference();
	ApplyData.SourceStateObjectRef = kSource.GetReference();
	ApplyData.TargetStateObjectRef = kOriginalTarget.GetReference();	
	ApplyData.ItemStateObjectRef = kSourceAbility.GetSourceWeapon() == none ? NoWeapon : kSourceAbility.GetSourceWeapon().GetReference();	
	ApplyData.EffectRef.SourceTemplateName = SourceTemplateName;
	ApplyData.EffectRef.LookupType = EffectLookupType;

	DefaultPlayerStateObjectRef = UnitState == none ? `TACTICALRULES.GetCachedUnitActionPlayerRef() : UnitState.ControllingPlayer;
	for (EffectIndex = 0; EffectIndex < Effects.Length; ++EffectIndex)
	{
		ApplyData.PlayerStateObjectRef = DefaultPlayerStateObjectRef;

		EffectResults.Effects.AddItem( Effects[ EffectIndex ] );

		// Only Apply the effect if the result meets the effect's application criteria.
		if ( (Effects[EffectIndex].bApplyOnHit && bHit) ||
			 (Effects[EffectIndex].bApplyOnMiss && bMiss))
		{	
			if (Effects[EffectIndex].bUseSourcePlayerState)
			{
				// If the source unit's controlling player needs to be saved in
				// ApplyData.PlayerStateObjectRef							
				if (SourceUnit != none)
				{
					ApplyData.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
				}
			}
			ApplyData.EffectRef.TemplateEffectLookupArrayIndex = EffectIndex;

			//  Check for a redirect
			bRedirected = false;
			foreach class'X2AbilityTemplateManager'.default.AffectingEffectRedirectors(AffectingRedirectorName)
			{
				RedirectorEffectState = UnitState.GetUnitAffectedByEffectState(AffectingRedirectorName);
				if (RedirectorEffectState != None)
				{
					Redirection = EmptyRedirection;
					Redirection.OriginalTargetRef = kOriginalTarget.GetReference();
					OverrideRedirectResult = 'AA_Success';        //  assume the redirected effect will apply normally
					if (RedirectorEffectState.GetX2Effect().EffectShouldRedirect(AbilityContext, kSourceAbility, RedirectorEffectState, Effects[EffectIndex], SourceUnit, UnitState, Redirection.RedirectedToTargetRef, Redirection.RedirectReason, OverrideRedirectResult))
					{
						RedirectUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(Redirection.RedirectedToTargetRef.ObjectID));
						if (RedirectUnit == None)
						{
							RedirectUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Redirection.RedirectedToTargetRef.ObjectID));
							if (RedirectUnit == None)
							{
								`RedScreen("Attempted effect redirection wanted to redirect to unit ID" @ Redirection.RedirectedToTargetRef.ObjectID @ "but no such unit was found. @gameplay @jbouscher");
								break;
							}
							RedirectUnit = XComGameState_Unit(NewGameState.CreateStateObject(RedirectUnit.Class, RedirectUnit.ObjectID));
							NewGameState.AddStateObject(RedirectUnit);
						}
						bRedirected = true;
						break;
					}
				}
			}
			
			if (bRedirected)
			{
				EffectResults.ApplyResults.AddItem(Redirection.RedirectReason);
				
				RedirectData = ApplyData;
				RedirectData.TargetStateObjectRef = Redirection.RedirectedToTargetRef;
				Redirection.RedirectResults.Effects.AddItem(Effects[EffectIndex]);
				Redirection.RedirectResults.TemplateRefs.AddItem(ApplyData.EffectRef);
				if (OverrideRedirectResult == 'AA_Success')
					Redirection.RedirectResults.ApplyResults.AddItem(Effects[EffectIndex].ApplyEffect(RedirectData, RedirectUnit, NewGameState));
				else
					Redirection.RedirectResults.ApplyResults.AddItem(OverrideRedirectResult);
				AbilityContext.ResultContext.EffectRedirects.AddItem(Redirection);
			}
			else
			{				
				EffectResults.ApplyResults.AddItem(Effects[EffectIndex].ApplyEffect(ApplyData, kNewTargetState, NewGameState));
			}
		}
		else
		{
			EffectResults.ApplyResults.AddItem( 'AA_HitResultFailure' );
		}

		EffectResults.TemplateRefs.AddItem(ApplyData.EffectRef);
	}
	return true;
}

static function ActivationFlyOver_PostBuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability Context;
	local X2AbilityTemplate            AbilityTemplate;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int ShooterID;
	local int TrackIndex;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
	ShooterID = Context.InputContext.SourceObject.ObjectID;

	for (TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; TrackIndex++)
	{
		if (OutVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == ShooterID)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.CreateVisualizationAction(Context));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFriendlyName, '', eColor_Good, AbilityTemplate.IconImage);
			OutVisualizationTracks[TrackIndex].TrackActions.AddItem(SoundAndFlyOver);
		}
	}
}

function TypicalAbility_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{		
	local X2AbilityTemplate             AbilityTemplate;
	local XComGameStateContext_Ability  Context, InterruptContext;
	local AbilityInputContext           AbilityContext;
	local StateObjectReference          ShootingUnitRef;	
	local X2Action                      AddedAction;
	local XComGameState_BaseObject      TargetStateObject;//Container for state objects within VisualizeGameState	
	local XComGameState_Item            SourceWeapon;
	local X2GrenadeTemplate             GrenadeTemplate;
	local X2AmmoTemplate                AmmoTemplate;
	local X2WeaponTemplate              WeaponTemplate;
	local array<X2Effect>               MultiTargetEffects;
	local bool							bSourceIsAlsoTarget;
	local bool							bMultiSourceIsAlsoTarget;
	
	local Actor                     TargetVisualizer, ShooterVisualizer;
	local X2VisualizerInterface     TargetVisualizerInterface, ShooterVisualizerInterface;
	local int                       EffectIndex, TargetIndex;
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local VisualizationTrack        SourceTrack, InterruptTrack;
	local int						TrackIndex;
	local bool						bAlreadyAdded, bInterruptTrackAlreadyAdded;
	local XComGameStateHistory      History;
	local X2Action_MoveTurn         MoveTurnAction;

	local XComGameStateContext_Ability CounterAttackContext;
	local X2AbilityTemplate			CounterattackTemplate;
	local array<VisualizationTrack> OutCounterattackVisualizationTracks;
	local int						ActionIndex;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local name         ApplyResult;

	local XComGameState_InteractiveObject InteractiveObject;
	local XComGameState_Ability     AbilityState;
	local XComGameState InterruptState;
	local X2Action_SendInterTrackMessage InterruptMsg;
	local X2Action FoundAction;
	local X2Action_WaitForAbilityEffect WaitAction;
	local bool bInterruptPath;

	local X2Action_ExitCover ExitCoverAction;
	local X2Action_Delay MoveDelay;
			
	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.AbilityRef.ObjectID));
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.AbilityTemplateName);
	ShootingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter, part I. We split this into two parts since
	//in some situations the shooter can also be a target
	//****************************************************************************************
	ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);
	ShooterVisualizerInterface = X2VisualizerInterface(ShooterVisualizer);

	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	if (SourceTrack.StateObject_NewState == none)
		SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;
	SourceTrack.TrackActor = ShooterVisualizer;

	SourceTrack.AbilityName = AbilityTemplate.DataName;

	SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.ItemObject.ObjectID));
	if (SourceWeapon != None)
	{
		WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
		AmmoTemplate = X2AmmoTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState));
	}
	if(AbilityTemplate.bShowPostActivation)
	{
		//Show the text flyover at the end of the visualization after the camera pans back
		Context.PostBuildVisualizationFn.AddItem(ActivationFlyOver_PostBuildVisualization);
	}
	if (AbilityTemplate.bShowActivation || AbilityTemplate.ActivationSpeech != '')
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(SourceTrack, Context));

		if (SourceWeapon != None)
		{
			GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
		}

		if (GrenadeTemplate != none)
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", GrenadeTemplate.OnThrowBarkSoundCue, eColor_Good);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.bShowActivation ? AbilityTemplate.LocFriendlyName : "", AbilityTemplate.ActivationSpeech, eColor_Good, AbilityTemplate.bShowActivation ? AbilityTemplate.IconImage : "");
		}
	}

	if( Context.IsResultContextMiss() && AbilityTemplate.SourceMissSpeech != '' )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceMissSpeech, eColor_Bad);
	}
	else if( Context.IsResultContextHit() && AbilityTemplate.SourceHitSpeech != '' )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceHitSpeech, eColor_Good);
	}

	if( !AbilityTemplate.bSkipFireAction || Context.InputContext.MovementPaths.Length > 0 )
	{
		ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTrack(SourceTrack, Context));
		ExitCoverAction.bSkipExitCoverVisualization = AbilityTemplate.bSkipExitCoverWhenFiring;

		// if this ability has a built in move, do it right before we do the fire action
		if(Context.InputContext.MovementPaths.Length > 0)
		{
			if (Context.InterruptionStatus == eInterruptionStatus_Resume)
			{				
				//  Look for the interrupting state and fill in its visualization
			    InterruptState = Context.GetFirstStateInInterruptChain();
				if (InterruptState != None)
				{
					while (InterruptState != None)
					{
						InterruptContext = XComGameStateContext_Ability(InterruptState.GetContext());
						if (InterruptContext != none && InterruptContext.InterruptionStatus == eInterruptionStatus_None)
						{
							if (InterruptContext.InputContext.PrimaryTarget.ObjectID == ShootingUnitRef.ObjectID)
								break;
						}
						InterruptState = InterruptState.GetContext().GetNextStateInEventChain();
						InterruptContext = None;
					}
					if (InterruptContext != None)
					{				
						CounterattackTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(InterruptContext.InputContext.AbilityTemplateName);
						if ((Context.ResultContext.HitResult != eHit_CounterAttack) && CounterattackTemplate.IsMelee())        //  an interrupt during the move should be fine, only need special handling for end of move interruption prior to the attack
						{
							bInterruptPath = true;
							class'X2VisualizerHelpers'.static.ParsePath(Context, SourceTrack, OutVisualizationTracks, false);
							CounterattackTemplate.BuildVisualizationFn(InterruptState, OutCounterattackVisualizationTracks);
				
							InterruptMsg = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(SourceTrack, Context));
							InterruptMsg.SendTrackMessageToRef = InterruptContext.InputContext.SourceObject;

							for (TrackIndex = 0; TrackIndex < OutCounterattackVisualizationTracks.Length; ++TrackIndex)
							{
								if(OutCounterattackVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == SourceTrack.StateObject_OldState.ObjectID)
								{
									for(ActionIndex = 0; ActionIndex < OutCounterattackVisualizationTracks[TrackIndex].TrackActions.Length; ++ActionIndex)
									{
										SourceTrack.TrackActions.AddItem(OutCounterattackVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
									}
								}
								else
								{
									if (OutCounterattackVisualizationTracks[TrackIndex].StateObject_NewState.ObjectID == InterruptContext.InputContext.SourceObject.ObjectID &&
										InterruptTrack == EmptyTrack)
									{
										InterruptTrack = OutCounterattackVisualizationTracks[TrackIndex];

										if(`XCOMVISUALIZATIONMGR.TrackHasActionOfType(OutCounterattackVisualizationTracks[TrackIndex], class'X2Action_EnterCover', FoundAction))
										{
											X2Action_EnterCover(FoundAction).bInstantEnterCover = true;
										}

										AddedAction = class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_WaitForAbilityEffect', InterruptContext, InterruptTrack.TrackActor);
										OutCounterattackVisualizationTracks[TrackIndex].TrackActions.InsertItem(0, AddedAction);
										WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(InterruptTrack, InterruptContext));
										WaitAction.bWaitingForActionMessage = true;
									}

									OutVisualizationTracks.AddItem(OutCounterattackVisualizationTracks[TrackIndex]);
								}
							}
							OutCounterattackVisualizationTracks.Length = 0;
							`XCOMVISUALIZATIONMGR.SkipVisualization(InterruptState.HistoryIndex);

							class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(SourceTrack, Context);
						}
					}
				}
			}
			if (!bInterruptPath)
			{
				// note that we skip the stop animation since we'll be doing our own stop with the end of move attack
				class'X2VisualizerHelpers'.static.ParsePath(Context, SourceTrack, OutVisualizationTracks, AbilityTemplate.bSkipMoveStop);

				//  add paths for other units moving with us (e.g. gremlins moving with a move+attack ability)
				if (Context.InputContext.MovementPaths.Length > 1)
				{
					for (TrackIndex = 1; TrackIndex < Context.InputContext.MovementPaths.Length; ++TrackIndex)
					{
						BuildTrack = EmptyTrack;
						BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
						BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
						MoveDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, Context));
						MoveDelay.Duration = class'X2Ability_DefaultAbilitySet'.default.TypicalMoveDelay;
						class'X2VisualizerHelpers'.static.ParsePath(Context, BuildTrack, OutVisualizationTracks, AbilityTemplate.bSkipMoveStop);						
						OutVisualizationTracks.AddItem(BuildTrack);
					}
				}
			}

			if( !AbilityTemplate.bSkipFireAction )
			{
				// add our fire action
				AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTrack(SourceTrack, Context);
			}
			
			if (!bInterruptPath)
			{
				// swap the fire action for the end move action, so that we trigger it just before the end. This sequences any moving fire action
				// correctly so that it blends nicely before the move end.
				for (TrackIndex = 0; TrackIndex < SourceTrack.TrackActions.Length; ++TrackIndex)
				{
					if (X2Action_MoveEnd(SourceTrack.TrackActions[TrackIndex]) != none)
					{
						break;
					}
				}
				if(TrackIndex >= SourceTrack.TrackActions.Length)
				{
					`Redscreen("X2Action_MoveEnd not found when building Typical Ability path. @gameplay @dburchanowski @jbouscher");
				}
				else
				{
					SourceTrack.TrackActions[TrackIndex + 1] = SourceTrack.TrackActions[TrackIndex];
					SourceTrack.TrackActions[TrackIndex] = AddedAction;
				}
			}
			else
			{
				//  prompt the target to play their hit reacts after the attack
				InterruptMsg = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(SourceTrack, Context));
				InterruptMsg.SendTrackMessageToRef = InterruptContext.InputContext.SourceObject;
			}
		}
		else if( !AbilityTemplate.bSkipFireAction )
		{
			// no move, just add the fire action
			AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTrack(SourceTrack, Context);
		}

		if( !AbilityTemplate.bSkipFireAction )
		{
			if( AbilityTemplate.AbilityToHitCalc != None )
			{
				X2Action_Fire(AddedAction).SetFireParameters(Context.IsResultContextHit());
			}

			//Process a potential counter attack from the target here
			if( Context.ResultContext.HitResult == eHit_CounterAttack )
			{
				CounterAttackContext = class'X2Ability'.static.FindCounterAttackGameState(Context, XComGameState_Unit(SourceTrack.StateObject_OldState));
				if( CounterAttackContext != none )
				{
					//Entering this code block means that we were the target of a counter attack to our original attack. Here, we look forward in the history
					//and append the necessary visualization tracks so that the counter attack can happen visually as part of our original attack.

					//Get the ability template for the counter attack against us
					CounterattackTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(CounterAttackContext.InputContext.AbilityTemplateName);
					CounterattackTemplate.BuildVisualizationFn(CounterAttackContext.AssociatedState, OutCounterattackVisualizationTracks);

					//Take the visualization actions from the counter attack game state ( where we are the target )
					for( TrackIndex = 0; TrackIndex < OutCounterattackVisualizationTracks.Length; ++TrackIndex )
					{
						if( OutCounterattackVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == SourceTrack.StateObject_OldState.ObjectID )
						{
							for( ActionIndex = 0; ActionIndex < OutCounterattackVisualizationTracks[TrackIndex].TrackActions.Length; ++ActionIndex )
							{
								//Don't include waits
								if( !OutCounterattackVisualizationTracks[TrackIndex].TrackActions[ActionIndex].IsA('X2Action_WaitForAbilityEffect') )
								{
									SourceTrack.TrackActions.AddItem(OutCounterattackVisualizationTracks[TrackIndex].TrackActions[ActionIndex]);
								}
							}
							break;
						}
					}

					//Notify the visualization mgr that the counter attack visualization is taken care of, so it can be skipped
					`XCOMVISUALIZATIONMGR.SkipVisualization(CounterAttackContext.AssociatedState.HistoryIndex);
				}
			}
		}
	}

	//If there are effects added to the shooter, add the visualizer actions for them
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, SourceTrack, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));		
	}
	//****************************************************************************************

	//Configure the visualization track for the target(s). This functionality uses the context primarily
	//since the game state may not include state objects for misses.
	//****************************************************************************************	
	bSourceIsAlsoTarget = AbilityContext.PrimaryTarget.ObjectID == AbilityContext.SourceObject.ObjectID; //The shooter is the primary target
	if (AbilityTemplate.AbilityTargetEffects.Length > 0 &&			//There are effects to apply
		AbilityContext.PrimaryTarget.ObjectID > 0)				//There is a primary target
	{
		TargetVisualizer = History.GetVisualizer(AbilityContext.PrimaryTarget.ObjectID);
		TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

		if( bSourceIsAlsoTarget )
		{
			BuildTrack = SourceTrack;
		}
		else
		{
			BuildTrack = InterruptTrack;        //  interrupt track will either be empty or filled out correctly
		}

		BuildTrack.TrackActor = TargetVisualizer;

		TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
		if( TargetStateObject != none )
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.PrimaryTarget.ObjectID, 
															   BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState,
															   eReturnType_Reference,
															   VisualizeGameState.HistoryIndex);
			`assert(BuildTrack.StateObject_NewState == TargetStateObject);
		}
		else
		{
			//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
			//and show no change.
			BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
			BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
		}

		// if this is a melee attack, make sure the target is facing the location he will be melee'd from
		if(!AbilityTemplate.bSkipFireAction 
			&& !bSourceIsAlsoTarget 
			&& AbilityContext.MovementPaths.Length > 0
			&& AbilityContext.MovementPaths[0].MovementData.Length > 0
			&& XGUnit(TargetVisualizer) != none)
		{
			MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTrack(BuildTrack, Context));
			MoveTurnAction.m_vFacePoint = AbilityContext.MovementPaths[0].MovementData[AbilityContext.MovementPaths[0].MovementData.Length - 1].Position;
			MoveTurnAction.m_vFacePoint.Z = TargetVisualizerInterface.GetTargetingFocusLocation().Z;
			MoveTurnAction.UpdateAimTarget = true;
		}

		//Make the target wait until signaled by the shooter that the projectiles are hitting
		if (!AbilityTemplate.bSkipFireAction && !bSourceIsAlsoTarget)
		{
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);
		}
		
		//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
		//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
		//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);

			// Target effect visualization
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, ApplyResult);

			// Source effect visualization
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
		}

		//the following is used to handle Rupture flyover text
		if (XComGameState_Unit(BuildTrack.StateObject_OldState).GetRupturedValue() == 0 &&
			XComGameState_Unit(BuildTrack.StateObject_NewState).GetRupturedValue() > 0)
		{
			//this is the frame that we realized we've been ruptured!
			class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildTrack);
		}

		if (AbilityTemplate.bAllowAmmoEffects && AmmoTemplate != None)
		{
			for (EffectIndex = 0; EffectIndex < AmmoTemplate.TargetEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindTargetEffectApplyResult(AmmoTemplate.TargetEffects[EffectIndex]);
				AmmoTemplate.TargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, ApplyResult);
				AmmoTemplate.TargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
			}
		}
		if (AbilityTemplate.bAllowBonusWeaponEffects && WeaponTemplate != none)
		{
			for (EffectIndex = 0; EffectIndex < WeaponTemplate.BonusWeaponEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindTargetEffectApplyResult(WeaponTemplate.BonusWeaponEffects[EffectIndex]);
				WeaponTemplate.BonusWeaponEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, ApplyResult);
				WeaponTemplate.BonusWeaponEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
			}
		}

		if (Context.IsResultContextMiss() && (AbilityTemplate.LocMissMessage != "" || AbilityTemplate.TargetMissSpeech != ''))
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, AbilityTemplate.TargetMissSpeech, eColor_Bad);
		}
		else if( Context.IsResultContextHit() && (AbilityTemplate.LocHitMessage != "" || AbilityTemplate.TargetHitSpeech != '') )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocHitMessage, AbilityTemplate.TargetHitSpeech, eColor_Good);
		}

		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
		}

		if (!bSourceIsAlsoTarget && BuildTrack.TrackActions.Length > 0)
		{
			OutVisualizationTracks.AddItem(BuildTrack);
		}

		if( bSourceIsAlsoTarget )
		{
			SourceTrack = BuildTrack;
		}
	}

	if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState)).LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetMyTemplate()).ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
	}

	//  Apply effects to multi targets
	if( MultiTargetEffects.Length > 0 && AbilityContext.MultiTargets.Length > 0)
	{
		for( TargetIndex = 0; TargetIndex < AbilityContext.MultiTargets.Length; ++TargetIndex )
		{	
			bMultiSourceIsAlsoTarget = false;
			if( AbilityContext.MultiTargets[TargetIndex].ObjectID == AbilityContext.SourceObject.ObjectID )
			{
				bMultiSourceIsAlsoTarget = true;
				bSourceIsAlsoTarget = bMultiSourceIsAlsoTarget;				
			}

			//Some abilities add the same target multiple times into the targets list - see if this is the case and avoid adding redundant tracks
			bAlreadyAdded = false;
			bInterruptTrackAlreadyAdded = false;
			for( TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; ++TrackIndex )
			{
				if( OutVisualizationTracks[TrackIndex].StateObject_NewState.ObjectID == AbilityContext.MultiTargets[TargetIndex].ObjectID )
				{
					if( (InterruptTrack != EmptyTrack) &&
						(AbilityContext.MultiTargets[TargetIndex].ObjectID == InterruptTrack.StateObject_NewState.ObjectID) &&
						!bInterruptTrackAlreadyAdded )
					{
						// This target may already be in the track due to the fact that it was an interrupting (counterattack)
						// Make sure the MultiTarget effects are applied then.
						// WHEN WE HAVE MORE TIME TO FIX, THIS SHOULD PROBABLY CHECK A LIST AGAINST WHAT HAS BEEN PUT IN BY THE LOOP.
						// THESE TRACKS COULD BE IN THERE FOR OTHER REASONS BESIDES THIS MULTITARGET LOOP.
						bInterruptTrackAlreadyAdded = true;
					}
					else
					{
						bAlreadyAdded = true;
					}
				}
			}

			if( !bAlreadyAdded )
			{
				TargetVisualizer = History.GetVisualizer(AbilityContext.MultiTargets[TargetIndex].ObjectID);
				TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

				if( bMultiSourceIsAlsoTarget )
				{
					BuildTrack = SourceTrack;
				}
				else
				{
					BuildTrack = EmptyTrack;
				}
				BuildTrack.TrackActor = TargetVisualizer;

				TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
				if( TargetStateObject != none )
				{
					History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID, 
																	   BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState,
																	   eReturnType_Reference,
																	   VisualizeGameState.HistoryIndex);
					`assert(BuildTrack.StateObject_NewState == TargetStateObject);
				}			
				else
				{
					//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
					//and show no change.
					BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
					BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
				}

				//Make the target wait until signaled by the shooter that the projectiles are hitting
				if (!AbilityTemplate.bSkipFireAction && !bMultiSourceIsAlsoTarget)
				{
					WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));

					if( bInterruptTrackAlreadyAdded &&
						(AbilityContext.MultiTargets[TargetIndex].ObjectID == InterruptTrack.StateObject_NewState.ObjectID) )
					{
						// This is the interrupting track and this wait needs to stop since the interruption would put an earlier
						// wait in.
						// AGAIN, WHEN WE HAVE MORE TIME TO FIX, THIS SHOULD PROBABLY BE MOVED TO THE WAIT ACTION
						// MAKING SURE ANY WAIT IN THE TRACK STOPS.
						WaitAction.bWaitingForActionMessage = true;
					}
				}
		
				//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
				//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
				//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
				for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
				{
					ApplyResult = Context.FindMultiTargetEffectApplyResult(MultiTargetEffects[EffectIndex], TargetIndex);

					// Target effect visualization
					MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, ApplyResult);

					// Source effect visualization
					MultiTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
				}			

				//the following is used to handle Rupture flyover text
				if (XComGameState_Unit(BuildTrack.StateObject_OldState).GetRupturedValue() == 0 &&
					XComGameState_Unit(BuildTrack.StateObject_NewState).GetRupturedValue() > 0)
				{
					//this is the frame that we realized we've been ruptured!
					class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildTrack);
				}

				if( TargetVisualizerInterface != none )
				{
					//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
					TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
				}

				if( !bMultiSourceIsAlsoTarget && BuildTrack.TrackActions.Length > 0 )
				{
					OutVisualizationTracks.AddItem(BuildTrack);
				}

				if( bMultiSourceIsAlsoTarget )
				{
					SourceTrack = BuildTrack;
				}
			}
		}
	}
	//****************************************************************************************

	//Finish adding the shooter's track
	//****************************************************************************************
	if( !bSourceIsAlsoTarget && ShooterVisualizerInterface != none)
	{
		ShooterVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, SourceTrack);				
	}	

	if (!AbilityTemplate.bSkipFireAction)
	{
		if (!AbilityTemplate.bSkipExitCoverWhenFiring)
		{
			class'X2Action_EnterCover'.static.AddToVisualizationTrack(SourceTrack, Context);
		}
	}	

	OutVisualizationTracks.AddItem(SourceTrack);

	//  Handle redirect visualization
	TypicalAbility_AddEffectRedirects(VisualizeGameState, OutVisualizationTracks, SourceTrack);

	//****************************************************************************************

	//Configure the visualization tracks for the environment
	//****************************************************************************************
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.TrackActor = none;
		BuildTrack.StateObject_NewState = EnvironmentDamageEvent;
		BuildTrack.StateObject_OldState = EnvironmentDamageEvent;

		//Wait until signaled by the shooter that the projectiles are hitting
		if (!AbilityTemplate.bSkipFireAction)
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');		
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
		}

		for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
		{
			MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');	
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.TrackActor = none;
		BuildTrack.StateObject_NewState = WorldDataUpdate;
		BuildTrack.StateObject_OldState = WorldDataUpdate;

		//Wait until signaled by the shooter that the projectiles are hitting
		if (!AbilityTemplate.bSkipFireAction)
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');		
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
		}

		for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
		{
			MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');	
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************

	//Process any interactions with interactive objects
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		// Add any doors that need to listen for notification
		if (InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim()) //Is this a closed door?
		{
			BuildTrack = EmptyTrack;
			//Don't necessarily have a previous state, so just use the one we know about
			BuildTrack.StateObject_OldState = InteractiveObject;
			BuildTrack.StateObject_NewState = InteractiveObject;
			BuildTrack.TrackActor = History.GetVisualizer(InteractiveObject.ObjectID);

			if (!AbilityTemplate.bSkipFireAction)
				class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

			class'X2Action_BreakInteractActor'.static.AddToVisualizationTrack(BuildTrack, Context);

			OutVisualizationTracks.AddItem(BuildTrack);
		}
	}
}

function TypicalAbility_AddEffectRedirects(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks, out VisualizationTrack SourceTrack)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local Actor                     TargetVisualizer;
	local X2VisualizerInterface     TargetVisualizerInterface;
	local VisualizationTrack    BuildTrack, EmptyTrack;
	local XComGameState_BaseObject  TargetStateObject;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local name ApplyResult;
	local X2AbilityTemplate AbilityTemplate;
	local int RedirectIndex, TrackIndex, EffectIndex;
	local array<int> RedirectTargets;
	local string RedirectText;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (Context.ResultContext.EffectRedirects.Length == 0)
		return;

	History = `XCOMHISTORY;
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

    for (RedirectIndex = 0; RedirectIndex < Context.ResultContext.EffectRedirects.Length; ++RedirectIndex)
	{
		//  Look for an existing track for the redirect target
		for (TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; ++TrackIndex)
		{
			if (OutVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID)
			{
				BuildTrack = OutVisualizationTracks[TrackIndex];
				break;
			}
		}
		if (TrackIndex == OutVisualizationTracks.Length)
		{
			//  need to make a new track
			BuildTrack = EmptyTrack;
			TargetVisualizer = History.GetVisualizer(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID);
			TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);
			BuildTrack.TrackActor = TargetVisualizer;
			TargetStateObject = VisualizeGameState.GetGameStateForObjectID(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID);
			if( TargetStateObject != none )
			{
				History.GetCurrentAndPreviousGameStatesForObjectID(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID, 
																	BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState,
																	eReturnType_Reference,
																	VisualizeGameState.HistoryIndex);
				`assert(BuildTrack.StateObject_NewState == TargetStateObject);
			}			
			else
			{
				//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
				//and show no change.
				BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID);
				BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
			}
		}

		//Make the target wait until signaled by the shooter that the projectiles are hitting
		if (!AbilityTemplate.bSkipFireAction)
		{
			X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
		}

		//  add the redirect effects
		for (EffectIndex = 0; EffectIndex < Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.Effects.Length; ++EffectIndex)
		{
			ApplyResult = Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.ApplyResults[EffectIndex];

			// Target effect visualization
			Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.Effects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, ApplyResult);

			// Source effect visualization
			Context.ResultContext.EffectRedirects[RedirectIndex].RedirectResults.Effects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceTrack, ApplyResult);
		}

		//  Do other typical visualization if this track wasn't created before
		if (TrackIndex == OutVisualizationTracks.Length)
		{
			//the following is used to handle Rupture flyover text
			if (XComGameState_Unit(BuildTrack.StateObject_OldState).GetRupturedValue() == 0 &&
				XComGameState_Unit(BuildTrack.StateObject_NewState).GetRupturedValue() > 0)
			{
				//this is the frame that we realized we've been ruptured!
				class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildTrack);
			}

			if( TargetVisualizerInterface != none )
			{
				//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
				TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
			}

			OutVisualizationTracks.AddItem(BuildTrack);
		}
		else
		{
			//  update the track in the array
			OutVisualizationTracks[TrackIndex] = BuildTrack;
		}

		//  only visualize a flyover once for any given target
		if (RedirectTargets.Find(Context.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID) != INDEX_NONE)
			continue;
		RedirectTargets.AddItem(Context.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID);

		//  Look for an existing track for the original target - this should be guaranteed to exist
		RedirectText = class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(Context.ResultContext.EffectRedirects[RedirectIndex].RedirectReason);
		if (RedirectText != "")
		{
			for (TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; ++TrackIndex)
			{
				if (OutVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == Context.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID)
				{
					BuildTrack = OutVisualizationTracks[TrackIndex];
					SoundAndFlyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
					SoundAndFlyover.SetSoundAndFlyOverParameters(none, RedirectText, '', eColor_Good);
					OutVisualizationTracks[TrackIndex] = BuildTrack;
					break;
				}
			}
		}
	}
}

function OverwatchShot_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local X2AbilityTemplate					AbilityTemplate;
	local Actor								ShooterVisualizer;
	local XComGameStateContext_Ability		Context;
	local XComGameStateVisualizationMgr		VisManager;
	local array<VisualizationTrackModInfo>	InfoArray;
	local VisualizationTrackModInfo			CurrentInfo;
	local XComGameState_Unit				TargetUnitState;
	local XComGameState_AIGroup				AIGroup;
	local X2Action_EnterCover				EnterCoverAction;
	local int								InfoIndex, ActionIndex;
	local bool								bModifiedTrack;
	local array<VisualizationTrack>			LocalVisualizationTracks;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
	ShooterVisualizer = `XCOMHISTORY.GetVisualizer(Context.InputContext.SourceObject.ObjectID);

	VisManager = `XCOMVISUALIZATIONMGR;

	//Find pending visualization blocks where the TrackActor is performing OverwatchShot
	VisManager.GetVisModInfoForTrackActor(AbilityTemplate.DataName, ShooterVisualizer, InfoArray);
	if (InfoArray.Length > 0)
	{
		//Iterate backwards to find the latest instance
		for (InfoIndex = InfoArray.Length - 1; InfoIndex >= 0 && !bModifiedTrack; --InfoIndex)
		{
			CurrentInfo = InfoArray[InfoIndex];
			TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CurrentInfo.Context.InputContext.PrimaryTarget.ObjectID));
			AIGroup = TargetUnitState.GetGroupMembership();
			//Modify the exiting visualization block if the TrackActor is firing at an enemy in the same UI group as the current target.
			if (AIGroup.m_arrMembers.Find('ObjectID', Context.InputContext.PrimaryTarget.ObjectID) != INDEX_NONE)
			{
				VisManager.GetTrackActions(CurrentInfo.BlockIndex, LocalVisualizationTracks);
				//Look for the EnterCover action of the previous OverwatchShot
				for (ActionIndex = LocalVisualizationTracks[CurrentInfo.TrackIndex].TrackActions.Length - 1; ActionIndex >= 0; --ActionIndex)
				{
					EnterCoverAction = X2Action_EnterCover(LocalVisualizationTracks[CurrentInfo.TrackIndex].TrackActions[ActionIndex]);
					if (EnterCoverAction != none)
					{
						//Set this new action to trigger after the previous overwatch
						Context.SetVisualizationStartIndex(EnterCoverAction.CurrentHistoryIndex);
						//Remove the EnterCover action. The last OverwatchShot will return the soldier to cover.
						VisManager.RemovePendingTrackAction(CurrentInfo.BlockIndex, CurrentInfo.TrackIndex, ActionIndex);
						bModifiedTrack = true;
						break;
					}
				}
			}
		}
	}
	//Continue building the OverwatchShot visualization as normal.
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
}

static function XComGameStateContext_Ability FindCounterAttackGameState(XComGameStateContext_Ability InitiatingAbilityContext, XComGameState_Unit OriginalAttacker)
{
	local int Index;
	local XComGameStateContext_Ability IterateAbility;
	local XComGameStateHistory History;
	
	//Check if we are the original shooter in a counter attack sequence, meaning that we are now being attacked. The
	//target of a counter attack just plays a different flinch/reaction anim
	if (InitiatingAbilityContext.InputContext.SourceObject.ObjectID == OriginalAttacker.ObjectID)
	{
		History = `XCOMHISTORY;
		//In this situation we need to update ability context so that it is from the counter attack game state
		for (Index = InitiatingAbilityContext.AssociatedState.HistoryIndex; Index < History.GetNumGameStates(); ++Index)
		{
			//The counter attack ability context will have its targets / sources reversed
			IterateAbility = XComGameStateContext_Ability(History.GetGameStateFromHistory(Index).GetContext());
			if (IterateAbility != none &&
				IterateAbility.InputContext.PrimaryTarget.ObjectID == OriginalAttacker.ObjectID &&
				InitiatingAbilityContext.InputContext.PrimaryTarget.ObjectID == IterateAbility.InputContext.SourceObject.ObjectID)
			{
				break;
			}
		}
	}

	return IterateAbility;
}

native static function bool MoveAbility_StepCausesDestruction(XComGameState_Unit MovingUnitState, const out AbilityInputContext InputContext, int PathIndex, int ToStep);
native static function MoveAbility_AddTileStateObjects(XComGameState NewGameState, XComGameState_Unit MovingUnitState, const out AbilityInputContext InputContext, int PathIndex, int ToStep);
native static function MoveAbility_AddNewlySeenUnitStateObjects(XComGameState NewGameState, XComGameState_Unit MovingUnitState, const out AbilityInputContext InputContext, int PathIndex);

static function XComGameState TypicalAbility_BuildInterruptGameState(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus)
{
	//  This "typical" interruption game state allows the ability to be interrupted with no game state changes.
	//  Upon resume from the interrupt, the ability will attempt to build a new game state like normal.

	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;

	AbilityContext = XComGameStateContext_Ability(Context);
	if (AbilityContext != none)
	{
		if (InterruptionStatus == eInterruptionStatus_Resume)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
			NewGameState = AbilityState.GetMyTemplate().BuildNewGameStateFn(Context);
			AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
			AbilityContext.SetInterruptionStatus(InterruptionStatus);
			AbilityContext.ResultContext.InterruptionStep = InterruptStep;
		}		
		else if (InterruptStep == 0)
		{
			NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);
			AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
			AbilityContext.SetInterruptionStatus(InterruptionStatus);
			AbilityContext.ResultContext.InterruptionStep = InterruptStep;
		}				
	}
	return NewGameState;
}

static function X2AbilityTemplate PurePassive(name TemplateName, optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard", optional bool bCrossClassEligible=false, optional Name AbilitySourceName='eAbilitySource_Perk', optional bool bDisplayInUI=true)
{
	local X2AbilityTemplate             Template;
	local X2Effect_Persistent           PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = TemplateIconImage;
	Template.AbilitySourceName = AbilitySourceName;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	//  This is a dummy effect so that an icon shows up in the UI.
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, true, false);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, TemplateIconImage, bDisplayInUI,, Template.AbilitySourceName);
	Template.AddTargetEffect(PersistentEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!

	Template.bCrossClassEligible = bCrossClassEligible;

	return Template;
}

DefaultProperties
{
	Begin Object Class=X2AbilityToHitCalc_DeadEye Name=DefaultDeadEye
	End Object
	DeadEye = DefaultDeadEye;

	Begin Object Class=X2AbilityToHitCalc_StandardAim Name=DefaultSimpleStandardAim
	End Object
	SimpleStandardAim = DefaultSimpleStandardAim;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingShooterProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=true
	End Object
	LivingShooterProperty = DefaultLivingShooterProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileTargetProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=true
	End Object
	LivingHostileTargetProperty = DefaultLivingHostileTargetProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileUnitOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=true
		FailOnNonUnits=true
	End Object
	LivingHostileUnitOnlyProperty = DefaultLivingHostileUnitOnlyProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileUnitDisallowMindControlProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=false
		FailOnNonUnits=true
	End Object
	LivingHostileUnitDisallowMindControlProperty = DefaultLivingHostileUnitDisallowMindControlProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingTargetUnitOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=false
		FailOnNonUnits=true
	End Object
	LivingTargetUnitOnlyProperty = DefaultLivingTargetUnitOnlyProperty;

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingTargetOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=false
	End Object
	LivingTargetOnlyProperty = DefaultLivingTargetOnlyProperty;

	Begin Object Class=X2AbilityTrigger_PlayerInput Name=DefaultPlayerInputTrigger
	End Object
	PlayerInputTrigger = DefaultPlayerInputTrigger;

	Begin Object Class=X2AbilityTrigger_UnitPostBeginPlay Name=DefaultUnitPostBeginPlayTrigger
	End Object
	UnitPostBeginPlayTrigger = DefaultUnitPostBeginPlayTrigger;

	Begin Object Class=X2AbilityTarget_Self Name=DefaultSelfTarget
	End Object
	SelfTarget = DefaultSelfTarget;

	Begin Object Class=X2AbilityTarget_Single Name=DefaultSimpleSingleTarget
		bAllowDestructibleObjects=true
	End Object
	SimpleSingleTarget = DefaultSimpleSingleTarget;

	Begin Object Class=X2AbilityTarget_Single Name=DefaultSimpleSingleMeleeTarget
		bAllowDestructibleObjects=true
		OnlyIncludeTargetsInsideWeaponRange=true
	End Object
	SimpleSingleMeleeTarget = DefaultSimpleSingleMeleeTarget;

	Begin Object Class=X2AbilityTarget_Single Name=DefaultSingleTargetWithSelf
		bIncludeSelf=true
	End Object
	SingleTargetWithSelf = DefaultSingleTargetWithSelf;

	Begin Object Class=X2Condition_Visibility Name=DefaultGameplayVisibilityCondition
		bRequireGameplayVisible=true
		bRequireBasicVisibility=true
	End Object
	GameplayVisibilityCondition = DefaultGameplayVisibilityCondition;

	Begin Object Class=X2Condition_Visibility Name=DefaultMeleeVisibilityCondition
		bRequireGameplayVisible=true
		bVisibleToAnyAlly=true
	End Object
	MeleeVisibilityCondition = DefaultMeleeVisibilityCondition;

	Begin Object Class=X2AbilityCost_ActionPoints Name=DefaultFreeActionCost
		iNumPoints=1
		bFreeCost=true
	End Object
	FreeActionCost = DefaultFreeActionCost;

	Begin Object Class=X2Effect_ApplyWeaponDamage Name=DefaultWeaponUpgradeMissDamage
		bApplyOnHit=false
		bApplyOnMiss=true
		bIgnoreBaseDamage=true
		DamageTag="Miss"
		bAllowWeaponUpgrade=true
		bAllowFreeKill=false
	End Object
	WeaponUpgradeMissDamage = DefaultWeaponUpgradeMissDamage;

	CounterattackDodgeEffectName = "CounterattackDodgeEffect"
	CounterattackDodgeUnitValue = 1
}
