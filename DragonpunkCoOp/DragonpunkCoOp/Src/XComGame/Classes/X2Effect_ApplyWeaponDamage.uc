//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplyWeaponDamage.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyWeaponDamage extends X2Effect config(GameCore);

var bool    bExplosiveDamage;
var bool    bIgnoreBaseDamage;
var name    DamageTag;
var bool    bAlwaysKillsCivilians;
var bool    bApplyWorldEffectsForEachTargetLocation;
var bool	bAllowFreeKill;
var bool    bAllowWeaponUpgrade;
var bool    bBypassShields;
var bool    bIgnoreArmor;

// These values are extra amount an ability may add or apply directly
var WeaponDamageValue EffectDamageValue;
var int EnvironmentalDamageAmount;

var config float GRAZE_DMG_MULT;
var config array<name> HideVisualizationOfResults;

struct ApplyDamageInfo
{
	var WeaponDamageValue BaseDamageValue;
	var WeaponDamageValue ExtraDamageValue;
	var WeaponDamageValue BonusEffectDamageValue;
	var WeaponDamageValue AmmoDamageValue;
	var WeaponDamageValue UpgradeDamageValue;
	var bool bDoesDamageIgnoreShields;
};

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Item SourceWeapon, StateObjectReference TargetRef) { return EffectDamageValue; }

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local Damageable kNewTargetDamageableState;
	local int iDamage, iMitigated, NewRupture, NewShred, TotalToKill; 
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item SourceWeapon;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<Name> AppliedDamageTypes;
	local int bAmmoBypassesShields;
	local bool bDoesDamageIgnoreShields;

	kNewTargetDamageableState = Damageable(kNewTargetState);
	if( kNewTargetDamageableState != none )
	{
		AppliedDamageTypes = DamageTypes;
		iDamage = CalculateDamageAmount(ApplyEffectParameters, iMitigated, NewRupture, NewShred, AppliedDamageTypes, bAmmoBypassesShields, NewGameState);
		bDoesDamageIgnoreShields = (bAmmoBypassesShields > 0) || bBypassShields;

		if ((iDamage == 0) && (iMitigated == 0) && (NewRupture == 0) && (NewShred == 0))
		{
			// No damage is being dealt
			return;
		}

		if (bAllowFreeKill)
		{
			//  check to see if the damage ought to kill them and if not, roll for a free kill
			TargetUnit = XComGameState_Unit(kNewTargetState);
			if (TargetUnit != none)
			{
				TotalToKill = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
				if (TotalToKill > iDamage)
				{
					SourceWeapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
					if (SourceWeapon != none)
					{
						WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
						foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
						{
							if (WeaponUpgradeTemplate.FreeKillFn != none && WeaponUpgradeTemplate.FreeKillFn(WeaponUpgradeTemplate, TargetUnit))
							{
								TargetUnit.TakeEffectDamage(self, TotalToKill, 0, NewShred, ApplyEffectParameters, NewGameState, false, false, true, AppliedDamageTypes);
								if (TargetUnit.IsAlive())
								{
									`RedScreen("Somehow free kill upgrade failed to kill the target! -jbouscher @gameplay");
								}
								else
								{
									TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1].bFreeKill = true;
								}
								return;
							}
						}
					}
				}
			}
		}
		
		if (NewRupture > 0)
		{
			kNewTargetDamageableState.AddRupturedValue(NewRupture);
		}

		kNewTargetDamageableState.TakeEffectDamage(self, iDamage, iMitigated, NewShred, ApplyEffectParameters, NewGameState, false, true, bDoesDamageIgnoreShields, AppliedDamageTypes);
	}
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Item SourceItemStateObject;
	local X2WeaponTemplate WeaponTemplate;
	local float AbilityRadius;
	local vector DamageDirection;
	local vector SourceUnitPosition;
	local XComGameStateContext_Ability AbilityContext;
	local int DamageAmount;
	local int PhysicalImpulseAmount;
	local name DamageTypeTemplateName;
	local XGUnit SourceUnit;
	local int OutCoverIndex;
	local UnitPeekSide OutPeekSide;
	local int OutRequiresLean;
	local int bOutCanSeeFromDefault;
	local X2AbilityTemplate AbilityTemplate;	
	local XComGameState_Item LoadedAmmo, SourceAmmo;	
	local Vector HitLocation;	
	local int i, HitLocationCount, HitLocationIndex;
	local array<vector> HitLocationsArray;
	local bool bLinearDamage;
	local X2AbilityMultiTargetStyle TargetStyle;

	//If this damage effect has an associated position, it does world damage
	if( ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 || ApplyEffectParameters.AbilityResultContext.ProjectileHitLocations.Length > 0 )
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));	
		if (SourceItemStateObject != None)
			WeaponTemplate = X2WeaponTemplate(SourceItemStateObject.GetMyTemplate());
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

		if( (SourceStateObject != none && AbilityStateObject != none) && (SourceItemStateObject != none || EnvironmentalDamageAmount > 0) )
		{	
			AbilityTemplate = AbilityStateObject.GetMyTemplate();
			if( AbilityTemplate != None )
			{
				TargetStyle = AbilityTemplate.AbilityMultiTargetStyle;

				if( TargetStyle != none && TargetStyle.IsA('X2AbilityMultiTarget_Line') )
				{
					bLinearDamage = true;
				}
			}
			AbilityRadius = AbilityStateObject.GetAbilityRadius();

			//Here, we want to use the target location as the input for the direction info since a miss location might possibly want a different step out
			SourceUnit = XGUnit(History.GetVisualizer(SourceStateObject.ObjectID));
			SourceUnit.GetDirectionInfoForPosition(ApplyEffectParameters.AbilityInputContext.TargetLocations[0], OutCoverIndex, OutPeekSide, bOutCanSeeFromDefault, OutRequiresLean);
			SourceUnitPosition = SourceUnit.GetExitCoverPosition(OutCoverIndex, OutPeekSide);	
			SourceUnitPosition.Z += 8.0f;
			
			DamageAmount = EnvironmentalDamageAmount;
			if ((SourceItemStateObject != none) && !bIgnoreBaseDamage)
			{
				SourceAmmo = AbilityStateObject.GetSourceAmmo();
				if (SourceAmmo != none)
				{
					DamageAmount += SourceAmmo.GetItemEnvironmentDamage();
				}
				else if(SourceItemStateObject.HasLoadedAmmo())
				{
					LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(SourceItemStateObject.LoadedAmmo.ObjectID));
					if(LoadedAmmo != None)
					{	
						DamageAmount += LoadedAmmo.GetItemEnvironmentDamage();
					}
				}
				
				DamageAmount += SourceItemStateObject.GetItemEnvironmentDamage();				
			}

			if (WeaponTemplate != none)
			{
				PhysicalImpulseAmount = WeaponTemplate.iPhysicsImpulse;
				DamageTypeTemplateName = WeaponTemplate.DamageTypeTemplateName;
			}
			else
			{
				PhysicalImpulseAmount = 0;

				if( EffectDamageValue.DamageType != '' )
				{
					// If the damage effect's damage type is filled out, use that
					DamageTypeTemplateName = EffectDamageValue.DamageType;
				}
				else if( DamageTypes.Length > 0 )
				{
					// If there is at least one DamageType, use the first one (may want to change
					// in the future to make a more intelligent decision)
					DamageTypeTemplateName = DamageTypes[0];
				}
				else
				{
					// Default to explosive
					DamageTypeTemplateName = 'Explosion';
				}
			}
			
			if( ( bLinearDamage || AbilityRadius > 0.0f || AbilityContext.ResultContext.HitResult == eHit_Miss) && DamageAmount > 0 )
			{
				// Loop here over projectiles if needed. If not single hit and use the first index.
				if(ApplyEffectParameters.AbilityResultContext.ProjectileHitLocations.Length > 0)
				{
					HitLocationsArray = ApplyEffectParameters.AbilityResultContext.ProjectileHitLocations;
				}
				else
				{
					HitLocationsArray = ApplyEffectParameters.AbilityInputContext.TargetLocations;
				}

				HitLocationCount = 1;
				if( bApplyWorldEffectsForEachTargetLocation )
				{
					HitLocationCount = HitLocationsArray.Length;
				}

				for( HitLocationIndex = 0; HitLocationIndex < HitLocationCount; ++HitLocationIndex )
				{
					HitLocation = HitLocationsArray[HitLocationIndex];

					DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage'));	
					DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_ApplyWeaponDamage:ApplyEffectToWorld";
					DamageEvent.DamageAmount = DamageAmount;
					DamageEvent.DamageTypeTemplateName = DamageTypeTemplateName;
					DamageEvent.HitLocation = HitLocation;
					DamageEvent.Momentum = (AbilityRadius == 0.0f) ? DamageDirection : vect(0,0,0);
					DamageEvent.PhysImpulse = PhysicalImpulseAmount;

					if( bLinearDamage )
					{
						TargetStyle.GetValidTilesForLocation(AbilityStateObject, DamageEvent.HitLocation, DamageEvent.DamageTiles);
					}
					else if (AbilityRadius > 0.0f)
					{
						DamageEvent.DamageRadius = AbilityRadius;
					}
					else
					{					
						DamageEvent.DamageTiles.AddItem(`XWORLD.GetTileCoordinatesFromPosition(DamageEvent.HitLocation));
					}

					if( X2AbilityMultiTarget_Cone(TargetStyle) != none )
					{
						DamageEvent.bAffectFragileOnly = AbilityTemplate.bFragileDamageOnly;
						DamageEvent.CosmeticConeEndDiameter = X2AbilityMultiTarget_Cone(TargetStyle).GetConeEndDiameter(AbilityStateObject);
						DamageEvent.CosmeticConeLength = X2AbilityMultiTarget_Cone(TargetStyle).GetConeLength(AbilityStateObject);
						DamageEvent.CosmeticConeLocation = SourceUnitPosition;
						DamageEvent.CosmeticDamageShape = SHAPE_CONE;

						if (AbilityTemplate.bCheckCollision)
						{
							for (i = 0; i < AbilityContext.InputContext.VisibleTargetedTiles.Length; i++)
							{
								DamageEvent.DamageTiles.AddItem( AbilityContext.InputContext.VisibleTargetedTiles[i] );
							}

							for (i = 0; i < AbilityContext.InputContext.VisibleNeighborTiles.Length; i++)
							{
								DamageEvent.DamageTiles.AddItem( AbilityContext.InputContext.VisibleNeighborTiles[i] );
							}
						}
					}

					DamageEvent.DamageCause = SourceStateObject.GetReference();
					DamageEvent.DamageSource = DamageEvent.DamageCause;
					DamageEvent.bRadialDamage = AbilityRadius > 0;
					NewGameState.AddStateObject(DamageEvent);
				}
			}
		}
	}
}

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_Item SourceWeapon, LoadedAmmo;
	local WeaponDamageValue UpgradeTemplateBonusDamage, BaseDamageValue, ExtraDamageValue, AmmoDamageValue, BonusEffectDamageValue, UpgradeDamageValue;
	local X2Condition ConditionIter;
	local name AvailableCode;
	local X2AmmoTemplate AmmoTemplate;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local int EffectDmg;
	local EffectAppliedData TestEffectParams;
	local name DamageType;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<Name> AppliedDamageTypes;
	local bool bDoesDamageIgnoreShields;

	MinDamagePreview = UpgradeTemplateBonusDamage;
	MaxDamagePreview = UpgradeTemplateBonusDamage;
	bDoesDamageIgnoreShields = bBypassShields;

	if (!bApplyOnHit)
		return;

	History = `XCOMHISTORY;

	if (AbilityState.SourceAmmo.ObjectID > 0)
		SourceWeapon = AbilityState.GetSourceAmmo();
	else
		SourceWeapon = AbilityState.GetSourceWeapon();

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));

	if (TargetUnit != None)
	{
		foreach TargetConditions(ConditionIter)
		{
			AvailableCode = ConditionIter.AbilityMeetsCondition(AbilityState, TargetUnit);
			if (AvailableCode != 'AA_Success')
				return;
			AvailableCode = ConditionIter.MeetsCondition(TargetUnit);
			if (AvailableCode != 'AA_Success')
				return;
			AvailableCode = ConditionIter.MeetsConditionWithSource(TargetUnit, SourceUnit);
			if (AvailableCode != 'AA_Success')
				return;
		}
		foreach DamageTypes(DamageType)
		{
			if (TargetUnit.IsImmuneToDamage(DamageType))
				return;
		}
	}
	
	if (bAlwaysKillsCivilians && TargetUnit != None && TargetUnit.GetTeam() == eTeam_Neutral)
	{
		MinDamagePreview.Damage = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
		MaxDamagePreview = MinDamagePreview;
		return;
	}
	if (SourceWeapon != None)
	{
		if (!bIgnoreBaseDamage)
		{
			SourceWeapon.GetBaseWeaponDamageValue(TargetUnit, BaseDamageValue);
			ModifyDamageValue(BaseDamageValue, TargetUnit, AppliedDamageTypes);
		}
		if (DamageTag != '')
		{
			SourceWeapon.GetWeaponDamageValue(TargetUnit, DamageTag, ExtraDamageValue);
			ModifyDamageValue(ExtraDamageValue, TargetUnit, AppliedDamageTypes);
		}
		if (SourceWeapon.HasLoadedAmmo() && !bIgnoreBaseDamage)
		{
			LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(SourceWeapon.LoadedAmmo.ObjectID));
			AmmoTemplate = X2AmmoTemplate(LoadedAmmo.GetMyTemplate()); 
			if (AmmoTemplate != None)
			{
				AmmoTemplate.GetTotalDamageModifier(LoadedAmmo, SourceUnit, TargetUnit, AmmoDamageValue);
				bDoesDamageIgnoreShields = AmmoTemplate.bBypassShields || bDoesDamageIgnoreShields;
			}
			else
				LoadedAmmo.GetBaseWeaponDamageValue(TargetUnit, AmmoDamageValue);
			ModifyDamageValue(AmmoDamageValue, TargetUnit, AppliedDamageTypes);
		}
		if (bAllowWeaponUpgrade)
		{
			WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
			foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
			{
				if (WeaponUpgradeTemplate.BonusDamage.Tag == DamageTag)
				{
					UpgradeTemplateBonusDamage = WeaponUpgradeTemplate.BonusDamage;

					ModifyDamageValue(UpgradeTemplateBonusDamage, TargetUnit, AppliedDamageTypes);

					UpgradeDamageValue.Damage += UpgradeTemplateBonusDamage.Damage;
					UpgradeDamageValue.Spread += UpgradeTemplateBonusDamage.Spread;
					UpgradeDamageValue.Crit += UpgradeTemplateBonusDamage.Crit;
					UpgradeDamageValue.Pierce += UpgradeTemplateBonusDamage.Pierce;
					UpgradeDamageValue.Rupture += UpgradeTemplateBonusDamage.Rupture;
					UpgradeDamageValue.Shred += UpgradeTemplateBonusDamage.Shred;
					//  ignores PlusOne as there is no good way to add them up
				}
			}
		}
	}
	BonusEffectDamageValue = GetBonusEffectDamageValue(AbilityState, SourceWeapon, TargetRef);
	ModifyDamageValue(BonusEffectDamageValue, TargetUnit, AppliedDamageTypes);

	MinDamagePreview.Damage = BaseDamageValue.Damage + ExtraDamageValue.Damage + AmmoDamageValue.Damage + BonusEffectDamageValue.Damage + UpgradeDamageValue.Damage -
							  BaseDamageValue.Spread - ExtraDamageValue.Spread - AmmoDamageValue.Spread - BonusEffectDamageValue.Spread - UpgradeDamageValue.Spread;

	MaxDamagePreview.Damage = BaseDamageValue.Damage + ExtraDamageValue.Damage + AmmoDamageValue.Damage + BonusEffectDamageValue.Damage + UpgradeDamageValue.Damage +
							  BaseDamageValue.Spread + ExtraDamageValue.Spread + AmmoDamageValue.Spread + BonusEffectDamageValue.Spread + UpgradeDamageValue.Spread;

	MinDamagePreview.Pierce = BaseDamageValue.Pierce + ExtraDamageValue.Pierce + AmmoDamageValue.Pierce + BonusEffectDamageValue.Pierce + UpgradeDamageValue.Pierce;
	MaxDamagePreview.Pierce = MinDamagePreview.Pierce;
	
	MinDamagePreview.Shred = BaseDamageValue.Shred + ExtraDamageValue.Shred + AmmoDamageValue.Shred + BonusEffectDamageValue.Shred + UpgradeDamageValue.Shred;
	MaxDamagePreview.Shred = MinDamagePreview.Shred;

	MinDamagePreview.Rupture = BaseDamageValue.Rupture + ExtraDamageValue.Rupture + AmmoDamageValue.Rupture + BonusEffectDamageValue.Rupture + UpgradeDamageValue.Rupture;
	MaxDamagePreview.Rupture = MinDamagePreview.Rupture;

	if (BaseDamageValue.PlusOne > 0)
		MaxDamagePreview.Damage++;
	if (ExtraDamageValue.PlusOne > 0)
		MaxDamagePreview.Damage++;
	if (AmmoDamageValue.PlusOne > 0)
		MaxDamagePreview.Damage++;
	if (BonusEffectDamageValue.PlusOne > 0)
		MaxDamagePreview.Damage++;

	TestEffectParams.AbilityInputContext.AbilityRef = AbilityState.GetReference();
	TestEffectParams.AbilityInputContext.AbilityTemplateName = AbilityState.GetMyTemplateName();
	TestEffectParams.ItemStateObjectRef = AbilityState.SourceWeapon;
	TestEffectParams.AbilityStateObjectRef = AbilityState.GetReference();
	TestEffectParams.SourceStateObjectRef = SourceUnit.GetReference();
	TestEffectParams.PlayerStateObjectRef = SourceUnit.ControllingPlayer;
	TestEffectParams.TargetStateObjectRef = TargetRef;

	foreach SourceUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();

		EffectDmg = EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, MinDamagePreview.Damage);
		MinDamagePreview.Damage += EffectDmg;
		EffectDmg = EffectTemplate.GetAttackingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, MaxDamagePreview.Damage);
		MaxDamagePreview.Damage += EffectDmg;

		EffectDmg = EffectTemplate.GetExtraArmorPiercing(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams);
		MinDamagePreview.Pierce += EffectDmg;
		MaxDamagePreview.Pierce += EffectDmg;

		EffectDmg = EffectTemplate.GetExtraShredValue(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams);
		MinDamagePreview.Shred += EffectDmg;
		MaxDamagePreview.Shred += EffectDmg;
	}

	if (TargetUnit != none)
	{
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			EffectDmg = EffectTemplate.GetDefendingDamageModifier(EffectState, SourceUnit, Damageable(TargetUnit), AbilityState, TestEffectParams, MaxDamagePreview.Damage, self);
			MinDamagePreview.Damage += EffectDmg;
			MaxDamagePreview.Damage += EffectDmg;
		}
	}
	if (!bDoesDamageIgnoreShields)
		AllowsShield += MaxDamagePreview.Damage;
}

// Cannot pass bools as out params, so use an int. Zero is false, non-zero is true.
simulated function int CalculateDamageAmount(const out EffectAppliedData ApplyEffectParameters, out int ArmorMitigation, out int NewRupture, out int NewShred, out array<Name> AppliedDamageTypes, out int bAmmoIgnoresShields, optional XComGameState NewGameState)
{
	local int TotalDamage, WeaponDamage, DamageSpread, ArmorPiercing, EffectDmg, CritDamage;

	local XComGameStateHistory History;
	local XComGameState_Unit kSourceUnit;
	local Damageable kTarget;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item kSourceItem, LoadedAmmo;
	local XComGameState_Ability kAbility;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local WeaponDamageValue BaseDamageValue, ExtraDamageValue, BonusEffectDamageValue, AmmoDamageValue, UpgradeTemplateBonusDamage, UpgradeDamageValue;
	local X2AmmoTemplate AmmoTemplate;
	local int RuptureCap, RuptureAmount, OriginalMitigation;
	local int EnvironmentDamage;
	local XComDestructibleActor kDestructibleActorTarget;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;

	ArmorMitigation = 0;
	NewRupture = 0;
	NewShred = 0;
	EnvironmentDamage = 0;
	bAmmoIgnoresShields = 0;    // FALSE

	//Cheats can force the damage to a specific value
	if (`CHEATMGR != none && `CHEATMGR.NextShotDamageRigged )
	{
		`CHEATMGR.NextShotDamageRigged = false;
		return `CHEATMGR.NextShotDamage;
	}

	History = `XCOMHISTORY;
	kSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));	
	kTarget = Damageable(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	kDestructibleActorTarget = XComDestructibleActor(History.GetVisualizer(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	kAbility = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if (kAbility.SourceAmmo.ObjectID > 0)
		kSourceItem = XComGameState_Item(History.GetGameStateForObjectID(kAbility.SourceAmmo.ObjectID));		
	else
		kSourceItem = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));		

	if( bAlwaysKillsCivilians )
	{
		TargetUnit = XComGameState_Unit(kTarget);

		if( (TargetUnit != none) && (TargetUnit.GetTeam() == eTeam_Neutral) )
		{
			// Return the amount of health the civlian has so that it will be euthanized
			return TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
		}
	}

	`log("===" $ GetFuncName() $ "===", true, 'XCom_HitRolls');

	if (kSourceItem != none)
	{
		`log("Attacker ID:" @ kSourceUnit.ObjectID @ "With Item ID:" @ kSourceItem.ObjectID @ "Target ID:" @ ApplyEffectParameters.TargetStateObjectRef.ObjectID, true, 'XCom_HitRolls');
		if (!bIgnoreBaseDamage)
		{
			kSourceItem.GetBaseWeaponDamageValue(XComGameState_BaseObject(kTarget), BaseDamageValue);
			EnvironmentDamage += kSourceItem.GetItemEnvironmentDamage();

			ModifyDamageValue(BaseDamageValue, kTarget, AppliedDamageTypes);
		}
		if (DamageTag != '')
		{
			kSourceItem.GetWeaponDamageValue(XComGameState_BaseObject(kTarget), DamageTag, ExtraDamageValue);

			ModifyDamageValue(ExtraDamageValue, kTarget, AppliedDamageTypes);
		}
		if (kSourceItem.HasLoadedAmmo() && !bIgnoreBaseDamage)
		{
			LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(kSourceItem.LoadedAmmo.ObjectID));
			AmmoTemplate = X2AmmoTemplate(LoadedAmmo.GetMyTemplate());
			if (AmmoTemplate != none)
			{
				AmmoTemplate.GetTotalDamageModifier(LoadedAmmo, kSourceUnit, XComGameState_BaseObject(kTarget), AmmoDamageValue);
				if (AmmoTemplate.bBypassShields)
				{
					bAmmoIgnoresShields = 1;  // TRUE
				}
			}
			else
			{
				LoadedAmmo.GetBaseWeaponDamageValue(XComGameState_BaseObject(kTarget), AmmoDamageValue);
				EnvironmentDamage += LoadedAmmo.GetItemEnvironmentDamage();
			}

			ModifyDamageValue(AmmoDamageValue, kTarget, AppliedDamageTypes);
		}
		if (bAllowWeaponUpgrade)
		{
			WeaponUpgradeTemplates = kSourceItem.GetMyWeaponUpgradeTemplates();
			foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
			{
				if (WeaponUpgradeTemplate.BonusDamage.Tag == DamageTag)
				{
					UpgradeTemplateBonusDamage = WeaponUpgradeTemplate.BonusDamage;

					ModifyDamageValue(UpgradeTemplateBonusDamage, kTarget, AppliedDamageTypes);

					UpgradeDamageValue.Damage += UpgradeTemplateBonusDamage.Damage;
					UpgradeDamageValue.Spread += UpgradeTemplateBonusDamage.Spread;
					UpgradeDamageValue.Crit += UpgradeTemplateBonusDamage.Crit;
					UpgradeDamageValue.Pierce += UpgradeTemplateBonusDamage.Pierce;
					UpgradeDamageValue.Rupture += UpgradeTemplateBonusDamage.Rupture;
					UpgradeDamageValue.Shred += UpgradeTemplateBonusDamage.Shred;
					//  ignores PlusOne as there is no good way to add them up
				}
			}
		}
	}

	// non targeted objects take the environmental damage amount
	if( kDestructibleActorTarget != None && !kDestructibleActorTarget.IsTargetable() )
	{
		return EnvironmentDamage;
	}

	BonusEffectDamageValue = GetBonusEffectDamageValue(kAbility, kSourceItem, ApplyEffectParameters.TargetStateObjectRef);

	ModifyDamageValue(BonusEffectDamageValue, kTarget, AppliedDamageTypes);

	WeaponDamage = BaseDamageValue.Damage + ExtraDamageValue.Damage + BonusEffectDamageValue.Damage + AmmoDamageValue.Damage + UpgradeDamageValue.Damage;
	DamageSpread = BaseDamageValue.Spread + ExtraDamageValue.Spread + BonusEffectDamageValue.Spread + AmmoDamageValue.Spread + UpgradeDamageValue.Spread;
	CritDamage = BaseDamageValue.Crit + ExtraDamageValue.Crit + BonusEffectDamageValue.Crit + AmmoDamageValue.Crit + UpgradeDamageValue.Crit;
	ArmorPiercing = BaseDamageValue.Pierce + ExtraDamageValue.Pierce + BonusEffectDamageValue.Pierce + AmmoDamageValue.Pierce + UpgradeDamageValue.Pierce;
	NewRupture = BaseDamageValue.Rupture + ExtraDamageValue.Rupture + BonusEffectDamageValue.Rupture + AmmoDamageValue.Rupture + UpgradeDamageValue.Rupture;
	NewShred = BaseDamageValue.Shred + ExtraDamageValue.Shred + BonusEffectDamageValue.Shred + AmmoDamageValue.Shred + UpgradeDamageValue.Shred;
	RuptureCap = WeaponDamage;

	`log(`ShowVar(bIgnoreBaseDamage) @ `ShowVar(DamageTag), true, 'XCom_HitRolls');
	`log("Weapon damage:" @ WeaponDamage @ "Potential spread:" @ DamageSpread, true, 'XCom_HitRolls');

	if (DamageSpread > 0)
	{
		WeaponDamage += DamageSpread;                          //  set to max damage based on spread
		WeaponDamage -= `SYNC_RAND(DamageSpread * 2 + 1);      //  multiply spread by 2 to get full range off base damage, add 1 as rand returns 0:x-1, not 0:x
	}
	`log("Damage with spread:" @ WeaponDamage, true, 'XCom_HitRolls');
	if (PlusOneDamage(BaseDamageValue.PlusOne))
	{
		WeaponDamage++;
		`log("Rolled for PlusOne off BaseDamage, succeeded. Damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}
	if (PlusOneDamage(ExtraDamageValue.PlusOne))
	{
		WeaponDamage++;
		`log("Rolled for PlusOne off ExtraDamage, succeeded. Damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}
	if (PlusOneDamage(BonusEffectDamageValue.PlusOne))
	{
		WeaponDamage++;
		`log("Rolled for PlusOne off BonusEffectDamage, succeeded. Damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}
	if (PlusOneDamage(AmmoDamageValue.PlusOne))
	{
		WeaponDamage++;
		`log("Rolled for PlusOne off AmmoDamage, succeeded. Damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}

	if (ApplyEffectParameters.AbilityResultContext.HitResult == eHit_Crit)
	{
		WeaponDamage += CritDamage;
		`log("CRIT! Adjusted damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}
	else if (ApplyEffectParameters.AbilityResultContext.HitResult == eHit_Graze)
	{
		WeaponDamage *= GRAZE_DMG_MULT;
		`log("GRAZE! Adjusted damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}

	RuptureAmount = min(kTarget.GetRupturedValue() + NewRupture, RuptureCap);
	if (RuptureAmount != 0)
	{
		WeaponDamage += RuptureAmount;
		`log("Target is ruptured, increases damage by" @ RuptureAmount $", new damage:" @ WeaponDamage, true, 'XCom_HitRolls');
	}

	if( kSourceUnit != none)
	{
		//  Allow attacker effects to modify damage output before applying final bonuses and reductions
		foreach kSourceUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			EffectDmg = EffectTemplate.GetAttackingDamageModifier(EffectState, kSourceUnit, kTarget, kAbility, ApplyEffectParameters, WeaponDamage, NewGameState);
			if (EffectDmg != 0)
			{
				WeaponDamage += EffectDmg;
				`log("Attacker effect" @ EffectTemplate.EffectName @ "adjusting damage by" @ EffectDmg $ ", new damage:" @ WeaponDamage, true, 'XCom_HitRolls');				
			}
			EffectDmg = EffectTemplate.GetExtraArmorPiercing(EffectState, kSourceUnit, kTarget, kAbility, ApplyEffectParameters);
			if (EffectDmg != 0)
			{
				ArmorPiercing += EffectDmg;
				`log("Attacker effect" @ EffectTemplate.EffectName @ "adjusting armor piercing by" @ EffectDmg $ ", new pierce:" @ ArmorPiercing, true, 'XCom_HitRolls');				
			}
			EffectDmg = EffectTemplate.GetExtraShredValue(EffectState, kSourceUnit, kTarget, kAbility, ApplyEffectParameters);
			if (EffectDmg != 0)
			{
				NewShred += EffectDmg;
				`log("Attacker effect" @ EffectTemplate.EffectName @ "adjust new shred value by" @ EffectDmg $ ", new shred:" @ NewShred, true, 'XCom_HitRolls');
			}
		}

		//  If this is a unit, apply any effects that modify damage
		TargetUnit = XComGameState_Unit(kTarget);
		if (TargetUnit != none)
		{
			foreach TargetUnit.AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				EffectTemplate = EffectState.GetX2Effect();
				EffectDmg = EffectTemplate.GetDefendingDamageModifier(EffectState, kSourceUnit, kTarget, kAbility, ApplyEffectParameters, WeaponDamage, self);
				if (EffectDmg != 0)
				{
					WeaponDamage += EffectDmg;
					`log("Defender effect" @ EffectTemplate.EffectName @ "adjusting damage by" @ EffectDmg $ ", new damage:" @ WeaponDamage, true, 'XCom_HitRolls');				
				}
			}
		}

		if (kTarget != none && !bIgnoreArmor)
		{
			ArmorMitigation = kTarget.GetArmorMitigation(ApplyEffectParameters.AbilityResultContext.ArmorMitigation);
			if (ArmorMitigation != 0)
			{				
				OriginalMitigation = ArmorMitigation;
				ArmorPiercing += kSourceUnit.GetCurrentStat(eStat_ArmorPiercing);				
				`log("Armor mitigation! Target armor mitigation value:" @ ArmorMitigation @ "Attacker armor piercing value:" @ ArmorPiercing, true, 'XCom_HitRolls');
				ArmorMitigation -= ArmorPiercing;				
				if (ArmorMitigation < 0)
					ArmorMitigation = 0;
				if (ArmorMitigation >= WeaponDamage)
					ArmorMitigation = WeaponDamage - 1;
				if (ArmorMitigation < 0)    //  WeaponDamage could have been 0
					ArmorMitigation = 0;    
				`log("  Final mitigation value:" @ ArmorMitigation, true, 'XCom_HitRolls');
			}
		}
	}
	//Shred can only shred as much as the maximum armor mitigation
	NewShred = Min(NewShred, OriginalMitigation);

	TotalDamage = WeaponDamage - ArmorMitigation;

	if ((WeaponDamage > 0 && TotalDamage < 0) || (WeaponDamage < 0 && TotalDamage > 0))
	{
		// Do not allow the damage reduction to invert the damage amount (i.e. heal instead of hurt, or vice-versa).
		TotalDamage = 0;
	}
	`log("Total Damage:" @ TotalDamage, true, 'XCom_HitRolls');
	`log("Shred from this attack:" @ NewShred, NewShred > 0, 'XCom_HitRolls');

	// Set the effect's damage
	return TotalDamage;
}

simulated function ModifyDamageValue(out WeaponDamageValue DamageValue, Damageable Target, out array<Name> AppliedDamageTypes)
{
	local WeaponDamageValue EmptyDamageValue;

	if( Target != None )
	{
		if( Target.IsImmuneToDamage(DamageValue.DamageType) )
		{
			`log("Target is immune to damage type" @ DamageValue.DamageType $ "!", true, 'XCom_HitRolls');
			DamageValue = EmptyDamageValue;
		}
		else if( AppliedDamageTypes.Find(DamageValue.DamageType) == INDEX_NONE )
		{
			AppliedDamageTypes.AddItem(DamageValue.DamageType);
		}
	}
}

simulated function bool PlusOneDamage(int Chance)
{
	return `SYNC_RAND(100) < Chance;
}

simulated function bool IsExplosiveDamage() 
{ 
	return bExplosiveDamage; 
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_ApplyWeaponDamageToUnit UnitAction;	
	local X2Action_PlaySoundAndFlyOver FlyOverAction;
	local XComGameState_Unit UnitState;
	
	local name EffectName;
	local int x, OverwatchExclusion;
	local bool bRemovedEffect;
	
	if( BuildTrack.StateObject_NewState.IsA('XComGameState_Unit') )
	{		
		if (default.HideVisualizationOfResults.Find(EffectApplyResult) != INDEX_NONE)
			return;

		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		UnitAction.OriginatingEffect = self;

		if (EffectApplyResult == 'AA_Success')
		{
			UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
			if (XComGameState_Unit(BuildTrack.StateObject_OldState).NumAllReserveActionPoints() > 0 && UnitState.NumAllReserveActionPoints() == 0)
			{
				FlyOverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
				bRemovedEffect = false;
				for (x = 0; x < UnitState.AppliedEffects.Length; ++x)
				{
					EffectName = UnitState.AppliedEffectNames[x];

					if (EffectName == class'X2Effect_Suppression'.default.EffectName)
					{
						FlyOverAction.SetSoundAndFlyOverParameters(none, class'XLocalizedData'.default.SuppressionRemovedMsg, '', eColor_Bad);
						bRemovedEffect = true;
					}
				}

				if (!bRemovedEffect)
				{
					FlyOverAction.SetSoundAndFlyOverParameters(none, class'XLocalizedData'.default.OverwatchRemovedMsg, '', eColor_Bad);
				}
			}
		}
		else
		{
			OverwatchExclusion = class'X2Ability_DefaultAbilitySet'.default.OverwatchExcludeReasons.Find(EffectApplyResult);
			if (OverwatchExclusion != INDEX_NONE)
			{
				FlyOverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
				FlyOverAction.SetSoundAndFlyOverParameters(none, class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(EffectApplyResult), '', eColor_Bad);
			}
			else
			{
				super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);
			}
		}
	}
	else if( BuildTrack.StateObject_NewState.IsA('XComGameState_EnvironmentDamage')
			|| BuildTrack.StateObject_NewState.IsA('XComGameState_Destructible') )
	{
		if(EffectApplyResult == 'AA_Success')
		{
			//All non-unit damage is routed through XComGameState_EnvironmentDamage state objects, which represent an environmental damage event 
			class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		}
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_Delay DelayAction;
	local Actor UnitVisualizer;
	local X2Action_ApplyWeaponDamageToUnit UnitAction;
	local XComGameStateContext_TickEffect TickContext;
	local XComGameState_Effect TickedEffect;

	if( BuildTrack.StateObject_NewState.IsA('XComGameState_Unit') )
	{
		//  cosmetic units should not take damage
		if (XComGameState_Unit(BuildTrack.StateObject_NewState).GetMyTemplate().bIsCosmetic)
			return;

		UnitVisualizer = XComGameState_Unit(BuildTrack.StateObject_NewState).GetVisualizer();
		LookAtAction = X2Action_CameraLookAt( class'X2Action_CameraLookAt'.static.CreateVisualizationAction( VisualizeGameState.GetContext(), BuildTrack.TrackActor ));
		LookAtAction.LookAtActor = UnitVisualizer;
		LookAtAction.BlockUntilActorOnScreen = true;
		LookAtAction.UseTether = false;
		LookAtAction.LookAtDuration = 2.0f;
		LookAtAction.DesiredCameraPriority = eCameraPriority_GameActions;
		BuildTrack.TrackActions.InsertItem(0, LookAtAction);

		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		UnitAction.TickIndex = TickIndex;

		UnitAction.OriginatingEffect = self;

		//The "ancestor effect" for the weapon damage action should be the ticking effect that caused us.
		//This is needed to correctly identify the damage event to use.
		TickContext = XComGameStateContext_TickEffect(VisualizeGameState.GetContext());
		if (TickContext != None && TickContext.TickedEffect.ObjectID != 0)
		{
			TickedEffect = XComGameState_Effect(VisualizeGameState.GetGameStateForObjectID(TickContext.TickedEffect.ObjectID));
			if (TickedEffect != None)
				UnitAction.AncestorEffect = TickedEffect.GetX2Effect();
		}

		// the camera action is not longer blocking (but will hang out for a short duration), so add a delay function to 
		// prevent further visualization from occuring
		DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		DelayAction.Duration = LookAtAction.LookAtDuration;
	}
	else if( BuildTrack.StateObject_NewState.IsA('XComGameState_EnvironmentDamage')
			|| BuildTrack.StateObject_NewState.IsA('XComGameState_Destructible') )
	{
			//All non-unit damage is routed through XComGameState_EnvironmentDamage state objects, which represent an environmental damage event 
			class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
}

function GetEffectDamageTypes(XComGameState GameState, EffectAppliedData EffectData, out array<name> EffectDamageTypes)
{
	local XComGameState_Item SourceWeapon;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local XComGameState_Unit SourceUnit, TargetUnit;
	local ApplyDamageInfo DamageInfo;

	super.GetEffectDamageTypes(GameState, EffectData, EffectDamageTypes);

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	if (AbilityState != none)
	{
		if (AbilityState.SourceAmmo.ObjectID > 0)
		{
			SourceWeapon = AbilityState.GetSourceAmmo();
		}
		else
		{
			SourceWeapon = AbilityState.GetSourceWeapon();
		}
	}

	SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectData.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
	{
		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectData.SourceStateObjectRef.ObjectID));
	}

	TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectData.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
	{
		TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectData.TargetStateObjectRef.ObjectID));
	}

	CalculateDamageValues(SourceWeapon, SourceUnit, TargetUnit, AbilityState, DamageInfo, EffectDamageTypes);
}

function CalculateDamageValues(XComGameState_Item SourceWeapon, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, out ApplyDamageInfo DamageInfo, out array<Name> AppliedDamageTypes)
{
	local XComGameState_Item LoadedAmmo;
	local XComGameStateHistory History;
	local WeaponDamageValue UpgradeTemplateBonusDamage;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local X2AmmoTemplate AmmoTemplate;
	
	if (SourceWeapon != None)
	{
		if (!bIgnoreBaseDamage)
		{
			SourceWeapon.GetBaseWeaponDamageValue(TargetUnit, DamageInfo.BaseDamageValue);
			ModifyDamageValue(DamageInfo.BaseDamageValue, TargetUnit, AppliedDamageTypes);
		}

		if (DamageTag != '')
		{
			SourceWeapon.GetWeaponDamageValue(TargetUnit, DamageTag, DamageInfo.ExtraDamageValue);
			ModifyDamageValue(DamageInfo.ExtraDamageValue, TargetUnit, AppliedDamageTypes);
		}

		if (SourceWeapon.HasLoadedAmmo() && !bIgnoreBaseDamage)
		{
			History = `XCOMHISTORY;

			LoadedAmmo = XComGameState_Item(History.GetGameStateForObjectID(SourceWeapon.LoadedAmmo.ObjectID));
			AmmoTemplate = X2AmmoTemplate(LoadedAmmo.GetMyTemplate()); 
			if (AmmoTemplate != None)
			{
				AmmoTemplate.GetTotalDamageModifier(LoadedAmmo, SourceUnit, TargetUnit, DamageInfo.AmmoDamageValue);
				DamageInfo.bDoesDamageIgnoreShields = AmmoTemplate.bBypassShields || DamageInfo.bDoesDamageIgnoreShields;
			}
			else
			{
				LoadedAmmo.GetBaseWeaponDamageValue(TargetUnit, DamageInfo.AmmoDamageValue);
			}

			ModifyDamageValue(DamageInfo.AmmoDamageValue, TargetUnit, AppliedDamageTypes);
		}

		if (bAllowWeaponUpgrade)
		{
			WeaponUpgradeTemplates = SourceWeapon.GetMyWeaponUpgradeTemplates();
			foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
			{
				if (WeaponUpgradeTemplate.BonusDamage.Tag == DamageTag)
				{
					UpgradeTemplateBonusDamage = WeaponUpgradeTemplate.BonusDamage;

					ModifyDamageValue(UpgradeTemplateBonusDamage, TargetUnit, AppliedDamageTypes);

					DamageInfo.UpgradeDamageValue.Spread += UpgradeTemplateBonusDamage.Spread;
					DamageInfo.UpgradeDamageValue.Damage += UpgradeTemplateBonusDamage.Damage;
					DamageInfo.UpgradeDamageValue.Crit += UpgradeTemplateBonusDamage.Crit;
					DamageInfo.UpgradeDamageValue.Pierce += UpgradeTemplateBonusDamage.Pierce;
					DamageInfo.UpgradeDamageValue.Rupture += UpgradeTemplateBonusDamage.Rupture;
					DamageInfo.UpgradeDamageValue.Shred += UpgradeTemplateBonusDamage.Shred;
					//  ignores PlusOne as there is no good way to add them up
				}
			}
		}
	}

	DamageInfo.BonusEffectDamageValue = GetBonusEffectDamageValue(AbilityState, SourceWeapon, TargetUnit.GetReference());
	ModifyDamageValue(DamageInfo.BonusEffectDamageValue, TargetUnit, AppliedDamageTypes);
}

defaultproperties
{
	bApplyWorldEffectsForEachTargetLocation=false
	bAllowFreeKill=true
	bAppliesDamage=true
}
