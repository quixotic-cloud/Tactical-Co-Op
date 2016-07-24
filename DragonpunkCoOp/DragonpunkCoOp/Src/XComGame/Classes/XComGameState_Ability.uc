class XComGameState_Ability extends XComGameState_BaseObject
	dependson(X2TacticalGameRuleset, X2Effect, X2AbilityTemplate)
	implements(UIQueryInterfaceAbility)
	native(Core);

var() protected name                      m_TemplateName;
var() protected X2AbilityTemplate         m_Template;

var() privatewrite StateObjectReference	  OwnerStateObject;         // the unit that will perform this ability
var() StateObjectReference                SourceWeapon;             //  if this ability was created by a weapon, this is the weapon
var() StateObjectReference                SourceAmmo;               //  if this ability requires specific ammo, this is that ammo
var() int                                 iCooldown;
var() int                                 iCharges;
var() int                                 iAmmoConsumed;            // Valid after ability has completed activation
var() array<TTile>                        ValidActivationTiles;     // Certain abilities may require the target exist only in one of these valid tiles
var() int                                 PanicEventValue;			// Defines strength of panic event for this ability or its effect.
var() bool                                PanicFlamethrower;        // True only when flamethrower has triggered panic
var() int								  TurnsUntilAbilityExpires; // If >0, after this many turns, this ability will be removed from the Unit that owns it (and become unavailable for use)
var() private transient bool              HasBeenPostPlayInited;    // Safety to prevent multiple post play inits 
	
function InitAbilityForUnit(XComGameState_Unit OwnerUnit, XComGameState NewGameState)
{
	OwnerStateObject = OwnerUnit.GetReference();
	CheckForPostBeginPlayActivation();
	GetMyTemplate().InitAbilityForUnit(self, OwnerUnit, NewGameState);
}

/**
 *  These functions should exist on all data instance classes, but they are not implemented as an interface so
 *  the correct classes can be used for type checking, etc.
 *  
 *  function <TemplateManagerClass> GetMyTemplateManager()
 *      @return the manager which should be available through a static function on XComEngine.
 *      
 *  function name GetMyTemplateName()
 *      @return the name of the template this instance was created from. This should be saved in a private field separate from a reference to the template.
 *      
 *  function <TemplateClass> GetMyTemplate()
 *      @return the template used to create this instance. Use a private variable to ache it, as it shouldn't be saved in a checkpoint.
 *      
 *  function OnCreation(<TemplateClass> Template)
 *      @param Template this instance should base itself on, which is as meaningful as you need it to be.
 *      Cache a reference to the template now, store its name, and perform any other required setup.
 */

static function X2AbilityTemplateManager GetMyTemplateManager()
{
	return class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

simulated native function X2AbilityTemplate GetMyTemplate();

function OnCreation(X2AbilityTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

simulated function UpdateAbilityAvailability(out AvailableAction Action)
{
	local XComGameStateHistory History;
	local XComGameState_Unit kUnit;
	local XComGameState_BattleData BattleDataState;

	Action.AbilityObjectRef = GetReference();
	Action.AvailableCode = 'AA_UnknownError';

	History = `XCOMHISTORY;

	kUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (kUnit != none)
	{
		Action.AvailableCode = CanActivateAbility(kUnit);
		
		if (Action.AvailableCode == 'AA_Success')
		{
			Action.bFreeAim = IsAbilityFreeAiming();
			Action.AvailableCode = GatherAbilityTargets(Action.AvailableTargets);
			Action.bInputTriggered = IsAbilityInputTriggered();
		}
	}

	if (m_Template != None)
	{
		Action.eAbilityIconBehaviorHUD = m_Template.eAbilityIconBehaviorHUD;

		BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if(BattleDataState.IsAbilityObjectiveHighlighted(GetMyTemplateName()))
		{
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.OBJECTIVE_INTERACT_PRIORITY;
		}
		else
		{
			// since we can't put class constants in default properties, catch < 0 (invalid) shot hud priorities here and stick them in
			// the default sort location
			Action.ShotHUDPriority = m_Template.ShotHUDPriority >= 0 ? m_Template.ShotHUDPriority : class'UIUtilities_Tactical'.const.UNSPECIFIED_PRIORITY;
		}
	}

	if(Action.AvailableCode == 'AA_Success' && GetMyTemplateName() == 'Reload')
	{
		//	Sort of hacky. If we end up needing to do this for many more abilities, we can refactor
		//	into a delegate function call on the template to determine the new priority.
		if (GetSourceWeapon().Ammo == 0)
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.MUST_RELOAD_PRIORITY; // push it to the front of the list
		else
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.RELOAD_PRIORITY; // give it the normal priority
	}
}

simulated function name CanActivateAbility(XComGameState_Unit Unit, optional EInterruptionStatus InInterruptionStatus, optional bool bIgnoreCosts)
{
	local XComGameState_Unit kUnit;
	local name AvailableCode;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local UnitValue AllowedValue;
	local name AllowedName;
	local bool Revalidation;

	kUnit = Unit;
	GetMyTemplate();
	if (kUnit != none && m_Template != none)
	{
		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		if (BattleData.IsAbilityGloballyDisabled(GetMyTemplateName()))
		{
			//  Check for individual override
			AllowedName = name("AllowedAbility_" $ string(GetMyTemplateName()));
			if (!kUnit.GetUnitValue(AllowedName, AllowedValue) || AllowedValue.fValue == 0)
				return 'AA_AbilityUnavailable';
		}

		if (IsCoolingDown())
			return 'AA_CoolingDown';

		if (!bIgnoreCosts)
		{
			AvailableCode = m_Template.CanAfford(self, kUnit);
			if (AvailableCode != 'AA_Success')
				return AvailableCode;
		}

		Revalidation = InInterruptionStatus != eInterruptionStatus_None;
		AvailableCode = m_Template.CheckShooterConditions(self, kUnit, Revalidation);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	}

	return 'AA_Success';
}

// Used for AI checks if an ability would be available after moving, or after Gatekeeper Opens, etc.
simulated function array<name> GetAvailabilityErrors(XComGameState_Unit Unit)
{
	local name AvailableCode;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local UnitValue AllowedValue;
	local name AllowedName;
	local array<name> ErrorList;
	local X2AbilityCost Cost;
	local X2Condition Condition;

	GetMyTemplate();
	if( Unit != none && m_Template != none )
	{
		History = `XCOMHISTORY;
			BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		if( BattleData.IsAbilityGloballyDisabled(GetMyTemplateName()) )
		{
			//  Check for individual override
			AllowedName = name("AllowedAbility_" $ string(GetMyTemplateName()));
			if( !Unit.GetUnitValue(AllowedName, AllowedValue) || AllowedValue.fValue == 0 )
			{
				ErrorList.AddItem('AA_AbilityUnavailable');
			}
		}

		if( IsCoolingDown() )
		{
			ErrorList.AddItem('AA_CoolingDown');
		}

		foreach m_Template.AbilityCosts(Cost)
		{
			AvailableCode = Cost.CanAfford(self, Unit);
			if( AvailableCode != 'AA_Success' )
			{
				ErrorList.AddItem(AvailableCode);
			}
		}

		foreach m_Template.AbilityShooterConditions(Condition)
		{
			AvailableCode = Condition.MeetsCondition(Unit);
			if( AvailableCode != 'AA_Success' )
			{
				ErrorList.AddItem(AvailableCode);
			}
			AvailableCode = Condition.AbilityMeetsCondition(self, None);
			if( AvailableCode != 'AA_Success' )
			{
				ErrorList.AddItem(AvailableCode);
			}
		}
	}

	return ErrorList;
}

simulated function name CanActivateAbilityForObserverEvent(XComGameState_BaseObject TargetObject, optional XComGameState_Unit ShootingUnit)
{	
	local name AvailableCode;	
	local XComGameState_Unit TargetUnit;

	GetMyTemplate();

	//CanActivateAbility needs units, so ignore this if the unit or target are not units
	if (ShootingUnit == none)
		ShootingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	TargetUnit = XComGameState_Unit(TargetObject);
	if( ShootingUnit != none && TargetUnit != none )
	{		
		AvailableCode = CanActivateAbility(ShootingUnit);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
		if (m_Template != none && m_Template.AbilityTargetStyle != none)
		{
			if (!m_Template.AbilityTargetStyle.ValidatePrimaryTargetOption(self, ShootingUnit, TargetObject))
				return 'AA_NoTargets';

			AvailableCode = m_Template.CheckTargetConditions(self, ShootingUnit, TargetUnit);
		}
		if (AvailableCode != 'AA_Success')
			return AvailableCode;

		return 'AA_Success';		
	}
	
	return 'AA_NoTargets';
}

event int GetShotBreakdownNative(AvailableTarget kTarget, out ShotBreakdown kBreakdown)
{
	return GetShotBreakdown(kTarget, kBreakdown);
}

//This function is native for performance reasons, the script code below describes its function
simulated function native name GatherAbilityTargets(out array<AvailableTarget> Targets, optional XComGameState_Unit OverrideOwnerState);
/*
{
	local int i, j;
	local XComGameState_Unit kOwner;
	local name AvailableCode;
	local XComGameStateHistory History;

	GetMyTemplate();
	History = `XCOMHISTORY;
	kOwner = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (OverrideOwnerState != none)
		kOwner = OverrideOwnerState;

	if (m_Template != None)
	{
		AvailableCode = m_Template.AbilityTargetStyle.GetPrimaryTargetOptions(self, Targets);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	
		for (i = Targets.Length - 1; i >= 0; --i)
		{
			AvailableCode = m_Template.CheckTargetConditions(self, kOwner, History.GetGameStateForObjectID(Targets[i].PrimaryTarget.ObjectID));
			if (AvailableCode != 'AA_Success')
			{
				Targets.Remove(i, 1);
			}
		}

		if (m_Template.AbilityMultiTargetStyle != none)
		{
			m_Template.AbilityMultiTargetStyle.GetMultiTargetOptions(self, Targets);
			for (i = Targets.Length - 1; i >= 0; --i)
			{
				for (j = Targets[i].AdditionalTargets.Length - 1; j >= 0; --j)
				{
					AvailableCode = m_Template.CheckMultiTargetConditions(self, kOwner, History.GetGameStateForObjectID(Targets[i].AdditionalTargets[j].ObjectID));
					if (AvailableCode != 'AA_Success' || (Targets[i].AdditionalTargets[j].ObjectID == Targets[i].PrimaryTarget.ObjectID) && !m_Template.AbilityMultiTargetStyle.bAllowSameTarget)
					{
						Targets[i].AdditionalTargets.Remove(j, 1);
					}
				}

				AvailableCode = m_Template.AbilityMultiTargetStyle.CheckFilteredMultiTargets(self, Targets[i]);
				if (AvailableCode != 'AA_Success')
					Targets.Remove(i, 1);
			}
		}

		//The Multi-target style may have deemed some primary targets invalid in calls to CheckFilteredMultiTargets - so CheckFilteredPrimaryTargets must come afterwards.
		AvailableCode = m_Template.AbilityTargetStyle.CheckFilteredPrimaryTargets(self, Targets);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;

		Targets.Sort(SortAvailableTargets);
	}
	return 'AA_Success';
}

simulated function int SortAvailableTargets(AvailableTarget TargetA, AvailableTarget TargetB)
{
	local XComGameStateHistory History;
	local XComGameState_Destructible DestructibleA, DestructibleB;
	local int HitChanceA, HitChanceB;
	local ShotBreakdown BreakdownA, BreakdownB;

	if (TargetA.PrimaryTarget.ObjectID != 0 && TargetB.PrimaryTarget.ObjectID == 0)
	{
		return -1;
	}
	if (TargetB.PrimaryTarget.ObjectID != 0 && TargetA.PrimaryTarget.ObjectID == 0)
	{
		return 1;
	}
	if (TargetA.PrimaryTarget.ObjectID == 0 && TargetB.PrimaryTarget.ObjectID == 0)
	{
		return 1;
	}
	History = `XCOMHISTORY;
	DestructibleA = XComGameState_Destructible(History.GetGameStateForObjectID(TargetA.PrimaryTarget.ObjectID));
	DestructibleB = XComGameState_Destructible(History.GetGameStateForObjectID(TargetB.PrimaryTarget.ObjectID));
	if (DestructibleA != none && DestructibleB == none)
	{
		return -1;
	}
	if (DestructibleB != none && DestructibleA == none)
	{
		return 1;
	}

	HitChanceA = GetShotBreakdown(TargetA, BreakdownA);
	HitChanceB = GetShotBreakdown(TargetB, BreakdownB);
	if (HitChanceA < HitChanceB)
	{
		return -1;
	}

	return 1;
}
*/

simulated function GatherAbilityTargetLocationsForLocation(const vector Location, const AvailableTarget Targets, out array<Vector> TargetLocations)
{
	local X2AbilityMultiTarget_BlazingPinions BlazingPinionsMultiTarget;
	local bool MultiTargetFoundLocations;

	MultiTargetFoundLocations = false;
	GetMyTemplate();

	if( (m_Template != none) )
	{
		BlazingPinionsMultiTarget = X2AbilityMultiTarget_BlazingPinions(m_Template.AbilityMultiTargetStyle);
		TargetLocations.Length = 0;
		if( BlazingPinionsMultiTarget != None )
		{
			MultiTargetFoundLocations = BlazingPinionsMultiTarget.CalculateValidLocationsForLocation(self, Location, Targets, TargetLocations);
		}
	}

	if( !MultiTargetFoundLocations )
	{
		TargetLocations.AddItem(Location);
	}
}

simulated function GatherAdditionalAbilityTargetsForLocation(const vector vLocation, out AvailableTarget Target)
{
	local int i;
	local name AvailableCode;
	local XComGameState_Unit kOwner;
	local XComGameStateHistory History;

	GetMyTemplate();
	if (m_Template != None
		&& m_Template.AbilityMultiTargetStyle != none)
	{
		History = `XCOMHISTORY;
		kOwner = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		m_Template.AbilityMultiTargetStyle.GetMultiTargetsForLocation(self, vLocation, Target);
		for (i = Target.AdditionalTargets.Length - 1; i >= 0; --i)
		{
			AvailableCode = m_Template.CheckMultiTargetConditions(self, kOwner, History.GetGameStateForObjectID(Target.AdditionalTargets[i].ObjectID));
			if (AvailableCode != 'AA_Success')
			{
				Target.AdditionalTargets.Remove(i, 1);
			}
		}
	}
}

simulated function float GetAbilityRadius()
{
	GetMyTemplate();
	if( m_Template != None
	   && m_Template.AbilityMultiTargetStyle != none
	   && m_Template.AbilityMultiTargetStyle.IsA('X2AbilityMultiTarget_Cone') )
	{
		return X2AbilityMultiTarget_Cone(m_Template.AbilityMultiTargetStyle).ConeLength;
	}

	if (m_Template != None 
		&& m_Template.AbilityMultiTargetStyle != none 
		&& m_Template.AbilityMultiTargetStyle.IsA('X2AbilityMultiTarget_Radius'))
		return X2AbilityMultiTarget_Radius(m_Template.AbilityMultiTargetStyle).GetTargetRadius(self);
	return 0;
}

simulated function float GetActiveAbilityRadiusScalar()
{
	GetMyTemplate( );
	if (m_Template != None
		&& m_Template.AbilityMultiTargetStyle != none
		&& m_Template.AbilityMultiTargetStyle.IsA( 'X2AbilityMultiTarget_Radius' ))
		return X2AbilityMultiTarget_Radius( m_Template.AbilityMultiTargetStyle ).GetActiveTargetRadiusScalar( self );
	return 1.0f;
}

simulated function float GetAbilityCoverage()
{
	GetMyTemplate();
	if (m_Template != None 
		&& m_Template.AbilityMultiTargetStyle != none 
		&& m_Template.AbilityMultiTargetStyle.IsA('X2AbilityMultiTarget_Radius'))
		return X2AbilityMultiTarget_Radius(m_Template.AbilityMultiTargetStyle).GetTargetCoverage(self);
	return 0;
}

simulated function bool CanTeleport()
{
	if (m_Template != None)
	{
		return !m_Template.bCannotTeleport;
	}
	return false;
}

simulated function bool IsAbilityPathing()
{
	GetMyTemplate();
	if( m_Template != None && m_Template.AbilityTargetStyle.IsA('X2AbilityTarget_Path') )
	{
		return true;
	}
	return false;
}


simulated function float GetAbilityCursorRangeMeters()
{
	GetMyTemplate();
	if (m_Template != None && m_Template.AbilityTargetStyle.IsA('X2AbilityTarget_Cursor'))
	{
		return X2AbilityTarget_Cursor(m_Template.AbilityTargetStyle).GetCursorRangeMeters(self);
	}
	return -1;      //  indicates unrestricted range
}

simulated function bool IsAbilityFreeAiming()
{
	GetMyTemplate();
	if (m_Template != None)
	{
		return m_Template.AbilityTargetStyle.IsFreeAiming(self);
	}
	return false;
}

simulated function bool IsAbilityInputTriggered()
{
	local int Index;
	local bool bInputTriggered;

	GetMyTemplate();

	bInputTriggered = false;
	if (m_Template != None)
	{
		for( Index = 0; Index < m_Template.AbilityTriggers.Length && !bInputTriggered; ++Index )
		{
			bInputTriggered = m_Template.AbilityTriggers[Index].IsA('X2AbilityTrigger_PlayerInput');
		}
	}

	return bInputTriggered;
}

simulated function bool IsAbilityTriggeredOnUnitPostBeginTacticalPlay(out int Priority)
{
	local int Index;
	local bool bUPBTPTriggered;

	GetMyTemplate();

	bUPBTPTriggered = false;
	if (m_Template != None)
	{
		for( Index = 0; Index < m_Template.AbilityTriggers.Length && !bUPBTPTriggered; ++Index )
		{
			bUPBTPTriggered = m_Template.AbilityTriggers[Index].IsA('X2AbilityTrigger_UnitPostBeginPlay');
			if (bUPBTPTriggered)
				Priority = X2AbilityTrigger_UnitPostBeginPlay(m_Template.AbilityTriggers[Index]).Priority;
		}
	}
	return bUPBTPTriggered;
}

simulated function bool IsCoolingDown()
{
	// Check for player-based cooldowns first.
	// note this is mainly for player-side, because the AI generally selects actions among multiple 
	// units simultaneously,  the cooldown value may be outdated until the gamestate history or 
	// visualizer is updated.  AI will have its own internal checks to determine if any cooldown 
	// ability is available.  (i.e. CallReinforcements)
	local XComGameState_Unit kUnit;
	local XComGameState_Player kPlayer;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	kUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (kUnit != none)
	{
		kPlayer = XComGameState_Player(History.GetGameStateForObjectID(kUnit.ControllingPlayer.ObjectID));
		if (kPlayer != none && kPlayer.GetCooldown(GetMyTemplateName()) > 0)
			return true;
	}

	return iCooldown != 0;
}

simulated function int GetCooldownRemaining()
{
	local XComGameState_Unit kUnit;
	local XComGameState_Player kPlayer;
	local XComGameStateHistory History;
	local int RetCooldown;

	History = `XCOMHISTORY;
	kUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (kUnit != none)
	{
		kPlayer = XComGameState_Player(History.GetGameStateForObjectID(kUnit.ControllingPlayer.ObjectID));
		if (kPlayer != none)
			RetCooldown = kPlayer.GetCooldown(GetMyTemplateName());
	}
	if (iCooldown > RetCooldown)
		RetCooldown = iCooldown;

	return RetCooldown;
}

function bool WillEndTurn()
{
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	AbilityTemplate = GetMyTemplate();
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	return AbilityTemplate.WillEndTurn(self, UnitState);
}

function bool MayBreakConcealmentOnActivation()
{
	local EConcealmentRule ConcealmentRule;
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local bool bRetainConcealment;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	if( UnitState == None || !UnitState.IsConcealed() )
	{
		return false;
	}

	AbilityTemplate = GetMyTemplate();
	ConcealmentRule = AbilityTemplate.ConcealmentRule;
	ItemState = GetSourceWeapon();
	if( ItemState != none )
	{
		WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
		if( WeaponTemplate != none && WeaponTemplate.bOverrideConcealmentRule )
		{
			ConcealmentRule = WeaponTemplate.OverrideConcealmentRule;
		}
		else
		{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetLoadedAmmoTemplate(self));
			if( WeaponTemplate != none && WeaponTemplate.bOverrideConcealmentRule )
			{
				ConcealmentRule = WeaponTemplate.OverrideConcealmentRule;
			}
		}
	}

	switch( ConcealmentRule )
	{
	case eConceal_NonOffensive:         //  Always retain Concealment if the Hostility != Offensive (default behavior)
		bRetainConcealment = AbilityTemplate.Hostility != eHostility_Offensive;
		break;
	case eConceal_Always:               //  Always retain Concealment, period
		bRetainConcealment = true;
		break;
	case eConceal_Never:                //  Never retain Concealment, period
		bRetainConcealment = false;
		break;
	case eConceal_KillShot:             //  Retain concealment when killing a single (primary) target
		bRetainConcealment = false;
		break;
	case eConceal_Miss:                 //  Retain concealment when the ability misses
		bRetainConcealment = false;
		break;
	case eConceal_MissOrKillShot:       //  Retain concealment when the ability misses or when killing a single (primary) target
		bRetainConcealment = false;
		break;
	default:
		`RedScreenOnce("Unhandled ConcealmentRule" @ AbilityTemplate.ConcealmentRule @ "- assuming concealment is broken, but this should be handled. -dkaplan @gameplay");
		bRetainConcealment = false;
		break;
	}

	return !bRetainConcealment;
}

function bool RetainConcealmentOnActivation(XComGameStateContext_Ability ActivationContext)
{
	local EConcealmentRule ConcealmentRule;
	local XComGameState_Unit PrimaryTargetUnitState;
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local bool bRetainConcealment;

	AbilityTemplate = GetMyTemplate();
	ConcealmentRule = AbilityTemplate.ConcealmentRule;
	PrimaryTargetUnitState = XComGameState_Unit(ActivationContext.AssociatedState.GetGameStateForObjectID(ActivationContext.InputContext.PrimaryTarget.ObjectID));
	ItemState = XComGameState_Item(ActivationContext.AssociatedState.GetGameStateForObjectID(ActivationContext.InputContext.ItemObject.ObjectID));
	if (ItemState != none)
	{
		WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
		if (WeaponTemplate != none && WeaponTemplate.bOverrideConcealmentRule)
		{
			ConcealmentRule = WeaponTemplate.OverrideConcealmentRule;
		}
		else
		{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetLoadedAmmoTemplate(self));
			if (WeaponTemplate != none && WeaponTemplate.bOverrideConcealmentRule)
			{
				ConcealmentRule = WeaponTemplate.OverrideConcealmentRule;
			}
		}
	}

	switch(ConcealmentRule)
	{
	case eConceal_NonOffensive:         //  Always retain Concealment if the Hostility != Offensive (default behavior)
		bRetainConcealment = AbilityTemplate.Hostility != eHostility_Offensive;
		break;
	case eConceal_Always:               //  Always retain Concealment, period
		bRetainConcealment = true;
		break;
	case eConceal_Never:                //  Never retain Concealment, period
		bRetainConcealment = false;
		break;
	case eConceal_KillShot:             //  Retain concealment when killing a single (primary) target
		bRetainConcealment = PrimaryTargetUnitState != none && PrimaryTargetUnitState.IsDead();
		break;
	case eConceal_Miss:                 //  Retain concealment when the ability misses
		bRetainConcealment = ActivationContext.IsResultContextMiss();
		break;
	case eConceal_MissOrKillShot:       //  Retain concealment when the ability misses or when killing a single (primary) target
		bRetainConcealment = (PrimaryTargetUnitState != none && PrimaryTargetUnitState.IsDead()) || ActivationContext.IsResultContextMiss();
		break;
	default:
		`RedScreenOnce("Unhandled ConcealmentRule" @ AbilityTemplate.ConcealmentRule @ "- assuming concealment is broken, but this should be handled. -jbouscher @gameplay");
		bRetainConcealment = false;
		break;
	}		

	return bRetainConcealment;
}

simulated native function XComGameState_Item GetSourceWeapon() const;
simulated native function XComGameState_item GetSourceAmmo() const;

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

simulated function bool AllowFreeFireWeaponUpgrade()
{
	GetMyTemplate();
	if (m_Template != None)
	{
		return m_Template.bAllowFreeFireWeaponUpgrade;
	}
	return false;
}

simulated function int GetShotBreakdown(AvailableTarget kTarget, out ShotBreakdown kBreakdown)
{
	GetMyTemplate();
	if (m_Template != None && m_Template.AbilityToHitCalc != none)
		return m_Template.AbilityToHitCalc.GetShotBreakdown(self, kTarget, kBreakdown);

	//If there's no AbilityToHitCalc, don't show a breakdown. (Example: doors.)
	kBreakdown.HideShotBreakdown = true;
	return 0;
}

//  this is pretty hacky, but we do need special handling for it...
simulated function bool IsLootAbility()
{
	return m_TemplateName == 'Loot';
}

simulated function bool IsMoveAbility()     //  @TODO this should perhaps be a property of the ability
{
	return m_TemplateName == 'StandardMove';
}

simulated function bool IsMeleeAbility()
{
	return GetMyTemplate().IsMelee();
}

simulated function name GetFireAnimationName(XComUnitPawn UnitPawn, bool UseMoveEndAnim, bool UseKillAnim, vector MoveEndDirection, vector CurrentDirection, bool bSelfTarget, float DistanceForAnimation)
{
	local XComGameState_Item ItemState;
	local XGWeapon WeaponVisualizer;
	local XComWeapon Weapon;
	local bool UseTurnLeft;
	local bool UseTurnRight;
	local float Dot;
	local float AngleBetween;
	local vector Left;
	local XComPerkContent kContent;
	local name AnimName, SavedPerkAnimName;
	local XGUnit Unit;

	local X2AbilityTemplate AbilityTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local name AbilityAnimName;

	local array<XComPerkContent> Perks;
	local int x;

	UseTurnLeft = false;
	UseTurnRight = false;

	if (UseMoveEndAnim)
	{
		if( UnitPawn.GetAnimTreeController().DistanceNeededForMovingMelee <= DistanceForAnimation )
		{
			if( MoveEndDirection != CurrentDirection )
			{
				Dot = NoZDot(CurrentDirection, MoveEndDirection);
				AngleBetween = Acos(Dot) * RadToDeg;

				if( AngleBetween >= 60.0f )
				{
					Left = CurrentDirection cross vect(0, 0, 1);
					Dot = NoZDot(Left, MoveEndDirection);
					if( Dot > 0 )
					{
						UseTurnLeft = true;
					}
					else
					{
						UseTurnRight = true;
					}
				}
			}
		}
		else
		{
			UseMoveEndAnim = false;
		}
	}

	Unit = XGUnit(UnitPawn.m_kGameUnit);
	class'XComPerkContent'.static.GetAssociatedPerks(Perks, UnitPawn, m_TemplateName);
	for (x = 0; x < Perks.Length; ++x)
	{
		kContent = Perks[x];

		if ((kContent.IsInState('ActionActive') || kContent.IsInState('DurationAction')) &&
			kContent.CasterActivationAnim.PlayAnimation &&
			!kContent.CasterActivationAnim.AdditiveAnim)
	{
		AnimName = class'XComPerkContent'.static.ChooseAnimationForCover( Unit, kContent.CasterActivationAnim );

			if (AnimName != '')
		{
				if (SavedPerkAnimName == '')
				{
					SavedPerkAnimName = AnimName;
		}
				else
				{
					`Redscreen("XComGameState_Ability::GetFireAnimationName - Multiple Perks are trying to play non-additive animations.");
				}
			}
		}
	}

	if (SavedPerkAnimName != '')
	{
		return SavedPerkAnimName;
	}

	AbilityTemplate = GetMyTemplate();
	ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectId(SourceWeapon.ObjectID));
	if (ItemState != none)
	{
		WeaponVisualizer = XGWeapon(ItemState.GetVisualizer());
		if (WeaponVisualizer != None)
		{
			Weapon = XComWeapon(WeaponVisualizer.m_kEntity);
		}
	}

	// Priority List:
	// Run Turn Left Kill
	// Run Turn Right Kill
	// Run Turn Left Fire
	// Run Turn Right Fire
	// Run Kill
	// Run Fire
	// Kill
	// Fire

	if (UseMoveEndAnim && UseTurnLeft && UseKillAnim)
	{
		if (m_Template != None &&  m_Template.CustomMovingTurnLeftFireKillAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomMovingTurnLeftFireKillAnim))
		{
			return m_Template.CustomMovingTurnLeftFireKillAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponMoveEndTurnLeftFireKillAnimSequenceName))
		{
			return Weapon.WeaponMoveEndTurnLeftFireKillAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponMoveEndTurnLeftFireKillAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponMoveEndTurnLeftFireKillAnimSequenceName;
		}
	}
	
	if (UseMoveEndAnim && UseTurnRight && UseKillAnim)
	{
		if (m_Template != None && m_Template.CustomMovingTurnRightFireKillAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomMovingTurnRightFireKillAnim))
		{
			return m_Template.CustomMovingTurnRightFireKillAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponMoveEndTurnRightFireKillAnimSequenceName))
		{
			return Weapon.WeaponMoveEndTurnRightFireKillAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponMoveEndTurnRightFireKillAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponMoveEndTurnRightFireKillAnimSequenceName;
		}
	}
	
	if (UseMoveEndAnim && UseTurnLeft)
	{
		if (m_Template != None && m_Template.CustomMovingTurnLeftFireAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomMovingTurnLeftFireAnim))
		{
			return m_Template.CustomMovingTurnLeftFireAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponMoveEndTurnLeftFireAnimSequenceName))
		{
			return Weapon.WeaponMoveEndTurnLeftFireAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponMoveEndTurnLeftFireAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponMoveEndTurnLeftFireAnimSequenceName;
		}
	}
	
	if (UseMoveEndAnim && UseTurnRight)
	{
		if (m_Template != None && m_Template.CustomMovingTurnRightFireAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomMovingTurnRightFireAnim))
		{
			return m_Template.CustomMovingTurnRightFireAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponMoveEndTurnRightFireAnimSequenceName))
		{
			return Weapon.WeaponMoveEndTurnRightFireAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponMoveEndTurnRightFireAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponMoveEndTurnRightFireAnimSequenceName;
		}
	}
	
	if (UseMoveEndAnim && UseKillAnim)
	{
		if (m_Template != None && m_Template.CustomMovingFireKillAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomMovingFireKillAnim))
		{
			return m_Template.CustomMovingFireKillAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponMoveEndFireKillAnimSequenceName))
		{
			return Weapon.WeaponMoveEndFireKillAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponMoveEndFireKillAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponMoveEndFireKillAnimSequenceName;
		}
	}
	
	if (UseMoveEndAnim)
	{
		if (m_Template != None && m_Template.CustomMovingFireAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomMovingFireAnim))
		{
			return m_Template.CustomMovingFireAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponMoveEndFireAnimSequenceName))
		{
			return Weapon.WeaponMoveEndFireAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponMoveEndFireAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponMoveEndFireAnimSequenceName;
		}
	}
	
	if (UseKillAnim)
	{
		if (m_Template != None && m_Template.CustomFireKillAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomFireKillAnim))
		{
			return m_Template.CustomFireKillAnim;
		}
		else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponFireKillAnimSequenceName))
		{
			return Weapon.WeaponFireKillAnimSequenceName;
		}
		else if (UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponFireKillAnimSequenceName))
		{
			return class'XComWeapon'.default.WeaponFireKillAnimSequenceName;
		}
	}

	if (ItemState != None)
	{
		WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
		if (WeaponTemplate != None && AbilityTemplate != None)
		{
			AbilityAnimName = WeaponTemplate.GetAnimationNameFromAbilityName(AbilityTemplate.DataName);

			if (AbilityAnimName != '')
				return AbilityAnimName;
		}
	}
	
	if (m_Template != none && bSelfTarget && m_Template.CustomSelfFireAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomSelfFireAnim))
	{
		return m_Template.CustomSelfFireAnim;
	}
	if (m_Template != None && m_Template.CustomFireAnim != '' && UnitPawn.GetAnimTreeController().CanPlayAnimation(m_Template.CustomFireAnim))
	{
		return m_Template.CustomFireAnim;
	}
	else if (Weapon != None && UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponFireAnimSequenceName))
	{
		return Weapon.WeaponFireAnimSequenceName;
	}
	else if(UnitPawn.GetGameUnit().IsTurret())
	{
		if( UnitPawn.GetGameUnit().m_eTeam == eTeam_Alien )
		{
			return 'FF_Fire_Advent';
		}
		else
		{
			return 'FF_Fire_Xcom';
		}
	}
	else
	{
		return class'XComWeapon'.default.WeaponFireAnimSequenceName;
	}	
}

simulated function int GetCharges()
{
	local XComGameState_Item Weapon;

	GetMyTemplate();
	if (m_Template != None && m_Template.bUseAmmoAsChargesForHUD)
	{
		if (SourceAmmo.ObjectID > 0)
		{
			Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(SourceAmmo.ObjectID));
			if (Weapon != none)
				return Weapon.Ammo / m_Template.iAmmoAsChargesDivisor;
		}
		else
		{
			Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(SourceWeapon.ObjectID));
			if (Weapon != none)
				return Weapon.Ammo / m_Template.iAmmoAsChargesDivisor;
		}
	}

	return iCharges;
}

//  THIS IS NOT FOR GAMEPLAY - it is a UI query
function bool DamageIgnoresArmor()
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim StandardAim;

	AbilityTemplate = GetMyTemplate();
	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	return StandardAim == none;
}

function GetDamagePreview(StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local X2AbilityTemplate AbilityTemplate;
	local WeaponDamageValue EmptyDamageValue;

	AbilityTemplate = GetMyTemplate();
	MinDamagePreview = EmptyDamageValue;
	MaxDamagePreview = EmptyDamageValue;
	AllowsShield = 0;

	if (AbilityTemplate.DamagePreviewFn != none)
	{
		if (AbilityTemplate.DamagePreviewFn(self, TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield))
			return;
	}

	NormalDamagePreview(TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield);
}

//  Note: You want to call GetDamagePreview to allow the template to override the values! This is only here so other damage preview functions can reuse this functionality.
function NormalDamagePreview(StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityMultiTarget_BurstFire BurstFire;
	local WeaponDamageValue TempMinDamage, TempMaxDamage, EmptyDamageValue;
	local array<X2Effect> TargetEffects;
	local XComGameState_BaseObject TargetObj;
	local Damageable DamageableTarget;
	local int i, Rupture;

	AbilityTemplate = GetMyTemplate();

	if (TargetRef.ObjectID > 0)
	{
		TargetEffects = AbilityTemplate.AbilityTargetEffects;
		TargetObj = `XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID);
		if (TargetObj != none)
		{
			DamageableTarget = Damageable(TargetObj);
			if (DamageableTarget != none)
				Rupture = DamageableTarget.GetRupturedValue();
		}
	}
	else if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		TargetEffects = X2GrenadeTemplate(GetSourceWeapon().GetLoadedAmmoTemplate(self)).LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		TargetEffects = X2GrenadeTemplate(GetSourceWeapon().GetMyTemplate()).ThrownGrenadeEffects;
	}
	else
	{
		TargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
	}

	for (i = 0; i < TargetEffects.Length; ++i)
	{
		if (TargetEffects[i] != none)
		{
			TempMaxDamage = EmptyDamageValue;
			TempMinDamage = EmptyDamageValue;
			TargetEffects[i].GetDamagePreview(TargetRef, self, TempMinDamage, TempMaxDamage, AllowsShield);
			
			MaxDamagePreview.Damage += TempMaxDamage.Damage;
			MaxDamagePreview.Pierce += TempMaxDamage.Pierce;
			MaxDamagePreview.Shred  += TempMaxDamage.Shred;
			
			MinDamagePreview.Damage += TempMinDamage.Damage;
			MinDamagePreview.Pierce += TempMinDamage.Pierce;
			MinDamagePreview.Shred  += TempMinDamage.Shred;
		}
	}
	if (AbilityTemplate.AbilityMultiTargetStyle != none)
	{
		BurstFire = X2AbilityMultiTarget_BurstFire(AbilityTemplate.AbilityMultiTargetStyle);
		if (BurstFire != none)
		{
			MinDamagePreview.Damage += MinDamagePreview.Damage * BurstFire.NumExtraShots;
			MinDamagePreview.Pierce += MinDamagePreview.Pierce * BurstFire.NumExtraShots;
			MinDamagePreview.Shred  += MinDamagePreview.Shred * BurstFire.NumExtraShots;

			MaxDamagePreview.Damage += MaxDamagePreview.Damage * BurstFire.NumExtraShots;
			MaxDamagePreview.Pierce += MaxDamagePreview.Pierce * BurstFire.NumExtraShots;
			MaxDamagePreview.Shred  += MaxDamagePreview.Shred * BurstFire.NumExtraShots;
		}
	}
	MinDamagePreview.Damage += Rupture;
	MaxDamagePreview.Damage += Rupture;
}

event int GetEnvironmentDamagePreview( )
{
	local XComGameStateHistory History;
	local int Damage;
	local XComGameState_Item SourceItemState, SourceAmmoState, LoadedAmmoState;

	History = `XCOMHISTORY;
	Damage = 0;

	SourceItemState = XComGameState_Item( History.GetGameStateForObjectID( SourceWeapon.ObjectID ) );
	if (SourceItemState != none)
	{
		SourceAmmoState = GetSourceAmmo( );
		if (SourceAmmoState != none)
		{
			Damage += SourceAmmoState.GetItemEnvironmentDamage( );
		}
		else if (SourceItemState.HasLoadedAmmo( ))
		{
			LoadedAmmoState = XComGameState_Item( History.GetGameStateForObjectID( SourceItemState.LoadedAmmo.ObjectID ) );
			if (LoadedAmmoState != None)
			{
				Damage += LoadedAmmoState.GetItemEnvironmentDamage( );
			}
		}

		Damage += SourceItemState.GetItemEnvironmentDamage( );
	}

	return Damage;
}

function bool MaybeApplyAbilityToUnitState( XComGameState_Unit UnitState, Name EventToUnregisterFrom )
{
	local AvailableTarget MultiTarget;
	local array<AvailableTarget> MultiTargetOptions;
	local array<int> MultiTargetIDs;
	local int i;
	local XComGameStateContext	AbilityContext;
	local XComGameState_Ability ThisObj;

	if( OwnerStateObject.ObjectID == UnitState.ObjectID && 
		CanActivateAbilityForObserverEvent(UnitState) == 'AA_Success' )
	{
		if (GetMyTemplate().AbilityMultiTargetStyle != none)
		{
			MultiTarget.PrimaryTarget.ObjectID = OwnerStateObject.ObjectID;
			MultiTargetOptions.AddItem(MultiTarget);
			m_Template.AbilityMultiTargetStyle.GetMultiTargetOptions(self, MultiTargetOptions);
			for (i = 0; i < MultiTargetOptions[0].AdditionalTargets.Length; ++i)
			{
				MultiTargetIDs.AddItem(MultiTargetOptions[0].AdditionalTargets[i].ObjectID);
			}
		}
		AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(self, OwnerStateObject.ObjectID, MultiTargetIDs);
		if( AbilityContext.Validate() )
		{
			ThisObj = self;
			`XEVENTMGR.UnRegisterFromEvent( ThisObj, EventToUnregisterFrom );

			`XCOMGAME.GameRuleset.SubmitGameStateContext(AbilityContext);

			return true;
		}
	}

	return false;
}

function EventListenerReturn OnUnitBeginPlay(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit EventUnitState;

	EventUnitState = XComGameState_Unit(EventData);

	MaybeApplyAbilityToUnitState(EventUnitState, 'OnUnitBeginPlay');

	return ELR_NoInterrupt;
}

function EventListenerReturn OnTacticalBeginPlay(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	MaybeApplyAbilityToUnitState(UnitState, 'OnTacticalBeginPlay');

	return ELR_NoInterrupt;
}

function EventListenerReturn OnGameStateSubmitted(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	MaybeApplyAbilityToUnitState(UnitState, 'HACK_OnGameStateSubmitted');

	return ELR_NoInterrupt;
}

function SetOwnerStateObject(out XComGameState_Unit InGameStateUnit)
{
	// deprecated
	`Redscreen("SetOwnerStateObject(): Deprecated!");
}

function CheckForPostBeginPlayActivation()
{
	local XComGameStateHistory History;
	local Object ThisObj;
	local X2EventManager EventManager;
	local XComGameState_Unit UnitState;
	local int Priority;

	if(OwnerStateObject.ObjectID <= 0)
	{
		`Redscreen("CheckForPostBeginPlayActivation(): No unit has been set for this ability yet!");
		return;
	}

	// only do these checks once
	if(HasBeenPostPlayInited)
	{
		return;
	}
	HasBeenPostPlayInited = true;

	if (IsAbilityTriggeredOnUnitPostBeginTacticalPlay(Priority))
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		if(UnitState == none)
		{
			`Redscreen("CheckForPostBeginPlayActivation(): Owning object is not a unit. This case needs to be handled.");
			return;
		}

		// if the Owner unit is already in play, apply at earliest opportunity
		if (UnitState.IsInPlay())
		{
			if (`TACTICALRULES.TacticalGameIsInPlay())
			{
				// The tactial game has already started so register to listen for the game state to be submitted
				// This will be changed with updates to the events system
				EventManager.RegisterForEvent(ThisObj, 'HACK_OnGameStateSubmitted', OnGameStateSubmitted, ELD_OnStateSubmitted, Priority);
				EventManager.TriggerEvent('HACK_OnGameStateSubmitted');
			}
			else
			{
				EventManager.RegisterForEvent(ThisObj, 'OnTacticalBeginPlay', OnTacticalBeginPlay, ELD_OnStateSubmitted, Priority);
			}
		}
		// the Owner is not yet in play, register for notification when it enters play so this ability can be applied then
		else
		{
			EventManager.RegisterForEvent(ThisObj, 'OnUnitBeginPlay', OnUnitBeginPlay, ELD_OnStateSubmitted, Priority, UnitState);
		}
	}
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2AbilityTrigger Trigger;
	local X2AbilityTemplate Template;
	local XComGameState_Ability AbilityState;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState != none)
	{
		Template = GetMyTemplate();
		if (Template != None)
		{
			foreach Template.AbilityTriggers(Trigger)
			{
				if (Trigger.IsA('X2AbilityTrigger_OnAbilityActivated'))
				{
					if( X2AbilityTrigger_OnAbilityActivated(Trigger).OnAbilityActivated(AbilityState, GameState, self, EventID) )
						break;
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn CarryUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState, TargetUnitState, NewTargetUnitState;
	local XComGameState_Effect EffectState;

	UnitState = XComGameState_Unit(EventData);
	EffectState = UnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	if (EffectState != none)
	{
		TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if (TargetUnitState != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			NewTargetUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', TargetUnitState.ObjectID));
			NewTargetUnitState.SetVisibilityLocation(UnitState.TileLocation);
			NewGameState.AddStateObject(NewTargetUnitState);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn EvacActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_Ability EvacState;
	local XComGameState_Unit UnitState, IterateUnit, NewUnit;
	local XComGameStateHistory History;
	local UnitValue EvacValue;

	//  Update the EvacThisTurn value for ALL units on the same team.

	History = `XCOMHISTORY;
	EvacState = XComGameState_Ability(EventData);
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EvacState.OwnerStateObject.ObjectID));
	UnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'.default.EvacThisTurnName, EvacValue);
	EvacValue.fValue += 1;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	foreach History.IterateByClassType(class'XComGameState_Unit', IterateUnit)
	{
		if (IterateUnit.ControllingPlayer == UnitState.ControllingPlayer)
		{
			NewUnit = XComGameState_Unit(NewGameState.CreateStateObject(IterateUnit.Class, IterateUnit.ObjectID));
			NewUnit.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.EvacThisTurnName, EvacValue.fValue);
			NewGameState.AddStateObject(NewUnit);
		}
	}
	`TACTICALRULES.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_EndOfMoveLoot(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2TacticalGameRuleset TacticalRules;
	local StateObjectReference LootAbilityRef;
	local XComGameState_Unit MovingUnitState;
	local GameRulesCache_Unit UnitCache;
	local int ActionIndex;
	local int LootTargetIndex;

	TacticalRules = `TACTICALRULES;

	MovingUnitState = XComGameState_Unit(EventSource);
	if (!TacticalRules.GetGameRulesCache_Unit(MovingUnitState.GetReference(), UnitCache))
	{
		return ELR_NoInterrupt;
	}

	LootAbilityRef = MovingUnitState.FindAbility('Loot');
	if(LootAbilityRef.ObjectID == 0) return ELR_NoInterrupt;
	for (ActionIndex = 0; ActionIndex < UnitCache.AvailableActions.Length; ++ActionIndex)
	{
		if (UnitCache.AvailableActions[ActionIndex].AbilityObjectRef.ObjectID == LootAbilityRef.ObjectID)
		{
			for (LootTargetIndex = 0; LootTargetIndex < UnitCache.AvailableActions[ActionIndex].AvailableTargets.Length; ++LootTargetIndex)
			{
				class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[ActionIndex], LootTargetIndex);
			}

			return ELR_NoInterrupt;
		}
	}

	return ELR_NoInterrupt;
}

function bool AbilityTriggerAgainstSingleTarget(StateObjectReference TargetRef, bool bMustHaveAdditionalTargets, optional int VisualizeIndex = -1, optional array<vector> TargetLocations)
{
	return AbilityTriggerAgainstSingleTarget_Static(ObjectID, OwnerStateObject, TargetRef, bMustHaveAdditionalTargets, VisualizeIndex, TargetLocations);
}

static function bool AbilityTriggerAgainstSingleTarget_Static(int AbilityID, StateObjectReference SourceRef, StateObjectReference TargetRef, bool bMustHaveAdditionalTargets, optional int VisualizeIndex = -1, optional array<vector> TargetLocations)
{
	local GameRulesCache_Unit UnitCache;
	local int i, j;
	local X2TacticalGameRuleset TacticalRules;
	local AvailableTarget AvailTarget;

	TacticalRules = `TACTICALRULES;

	if (TacticalRules.GetGameRulesCache_Unit(SourceRef, UnitCache))
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
		{
			if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityID)
			{
				for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j)
				{
					AvailTarget = UnitCache.AvailableActions[i].AvailableTargets[j];
					if (AvailTarget.PrimaryTarget.ObjectID == TargetRef.ObjectID)
					{
						if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')
						{
							if (bMustHaveAdditionalTargets ? AvailTarget.AdditionalTargets.Length > 0 : true)
							{
								class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j, TargetLocations,,,, VisualizeIndex);

								return true;
							}
						}
						break;
					}
				}
				break;
			}
		}
	}
	return false;
}

function bool AbilityTriggerAgainstTargetIndex(int TargetIdx, optional int VisualizeIndex = -1, optional array<vector> TargetLocations)
{
	local GameRulesCache_Unit UnitCache;
	local int i;
	local X2TacticalGameRuleset TacticalRules;

	TacticalRules = `TACTICALRULES;

	if (TacticalRules.GetGameRulesCache_Unit(OwnerStateObject, UnitCache))
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
		{
			if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == ObjectID)
			{
				if (UnitCache.AvailableActions[i].AvailableTargets.Length > TargetIdx && TargetIdx >= 0)
				{
					if (class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], TargetIdx, TargetLocations,,,, VisualizeIndex))
						return true;
					
				}
				break;
			}
		}
	}
	return false;
}

function EventListenerReturn ChainShotListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.IsResultContextHit())
	{
		AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn RapidFireListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
		AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);
	}
	return ELR_NoInterrupt;
}

//  General function for use with X2AbilityTrigger_EventListener to activate this ability with the owner as the target
function EventListenerReturn AbilityTriggerEventListener_Self(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	AbilityTriggerAgainstSingleTarget(OwnerStateObject, false);
	return ELR_NoInterrupt;
}

//  General function for use with X2AbilityTrigger_EventListener to activate this ability with the owner as the target
function EventListenerReturn AbilityTriggerEventListener_SelfWithAdditionalTargets(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	AbilityTriggerAgainstSingleTarget(OwnerStateObject, true);
	return ELR_NoInterrupt;
}

//  General function for use with X2AbilityTrigger_EventListener to activate this ability with the owner as the target
function EventListenerReturn AbilityTriggerEventListener_Self_VisualizeInGameState(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	AbilityTriggerAgainstSingleTarget(OwnerStateObject, false, GameState.HistoryIndex);
	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_InterruptSelf(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		AbilityTriggerAgainstSingleTarget(OwnerStateObject, false);
	}

	return ELR_NoInterrupt;
}

//  TODO: This needs to be removed when the refactor/overhaul of the UnitCache system is completed
function EventListenerReturn AbilityTriggerEventListener_SelfIgnoreCache(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComWorldData World;
	local XComGameStateHistory History;
	local AvailableAction CurrentAvailableAction;
	local AvailableTarget Targets;
	local XComGameState_Unit SourceUnit;
	local vector SourceUnitLocation;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	CurrentAvailableAction.AvailableCode = CanActivateAbility(SourceUnit);

	if (CurrentAvailableAction.AvailableCode == 'AA_Success')
	{
		World = `XWORLD;

		SourceUnitLocation = World.GetPositionFromTileCoordinates(SourceUnit.TileLocation);
		Targets.PrimaryTarget = OwnerStateObject;
		GatherAdditionalAbilityTargetsForLocation(SourceUnitLocation, Targets);

		CurrentAvailableAction.AvailableTargets.AddItem(Targets);
		CurrentAvailableAction.AbilityObjectRef = GetReference();
		class'XComGameStateContext_Ability'.static.ActivateAbility(CurrentAvailableAction, 0);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_AdditionalTargetRequiredIgnoreCache(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComWorldData World;
	local XComGameStateHistory History;
	local AvailableAction CurrentAvailableAction;
	local AvailableTarget Targets;
	local XComGameState_Unit SourceUnit;
	local vector SourceUnitLocation;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	CurrentAvailableAction.AvailableCode = CanActivateAbility(SourceUnit);

	if (CurrentAvailableAction.AvailableCode == 'AA_Success')
	{
		World = `XWORLD;

		SourceUnitLocation = World.GetPositionFromTileCoordinates(SourceUnit.TileLocation);
		Targets.PrimaryTarget = OwnerStateObject;
		GatherAdditionalAbilityTargetsForLocation(SourceUnitLocation, Targets);

		if (Targets.AdditionalTargets.Length > 0)
		{
			Targets.PrimaryTarget = Targets.AdditionalTargets[0];

			CurrentAvailableAction.AvailableTargets.AddItem(Targets);
			CurrentAvailableAction.AbilityObjectRef = GetReference();
			class'XComGameStateContext_Ability'.static.ActivateAbility(CurrentAvailableAction, 0);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_ValidAbilityLocation(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComWorldData World;
	local XComGameStateHistory History;
	local AvailableAction CurrentAvailableAction;
	local AvailableTarget Targets;
	local XComGameState_Unit SourceUnit;
	local TTile ValidTile;
	local vector ValidActiviationLocation;
	local array<vector> TargetLocations;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	CurrentAvailableAction.AvailableCode = CanActivateAbility(SourceUnit);

	if (CurrentAvailableAction.AvailableCode == 'AA_Success' && ValidActivationTiles.Length > 0)
	{
		World = `XWORLD;

		ValidTile = ValidActivationTiles[0];
		ValidActiviationLocation = World.GetPositionFromTileCoordinates(ValidTile);
		GatherAdditionalAbilityTargetsForLocation(ValidActiviationLocation, Targets);

		// Set up the available action
		CurrentAvailableAction.AvailableTargets.AddItem(Targets);
		CurrentAvailableAction.AbilityObjectRef = GetReference();

		// The ValidTile is also the Target location which needs to be passed when activating the ability
		TargetLocations.AddItem(ValidActiviationLocation);

		class'XComGameStateContext_Ability'.static.ActivateAbility(CurrentAvailableAction, 0, TargetLocations);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_BlazingPinions(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;
	local AvailableAction CurrentAvailableAction;
	local AvailableTarget Targets;
	local XComGameState_Unit SourceUnit;
	local array<vector> TargetLocations;
	local XComGameState_Effect EffectState;
	local AbilityInputContext InputContext;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	EffectState = SourceUnit.GetUnitAffectedByEffectState(class'X2Ability_Archon'.default.BlazingPinionsStage1EffectName);
	if( EffectState != none )
	{
		CurrentAvailableAction.AvailableCode = CanActivateAbility(SourceUnit);

		InputContext = EffectState.ApplyEffectParameters.AbilityInputContext;
		if( (CurrentAvailableAction.AvailableCode == 'AA_Success') &&  (InputContext.TargetLocations.Length > 1) )
		{
			// Set up the available action
			CurrentAvailableAction.AvailableTargets.AddItem(Targets);
			CurrentAvailableAction.AbilityObjectRef = GetReference();

			// The Target Locations for this ability are the same as the stage 1 ability
			// except the first target location. That is the landing point, which the Archon
			// is now flying above.
			InputContext.TargetLocations.Remove(0, 1);
			TargetLocations = InputContext.TargetLocations;
			class'XComGameStateContext_Ability'.static.ActivateAbility(CurrentAvailableAction, 0, TargetLocations);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn MeleeCounterattackListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local GameRulesCache_Unit UnitCache;
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;
	local int i, j;
	local StateObjectReference UseMeleeAbilityRef;
	local bool bFoundUsableMeleeAbility;
	local bool CounterAttackBool;
	local UnitValue CounterAttackUnitValue;
	
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if ((AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt) &&
		(AbilityContext.InputContext.PrimaryTarget == OwnerStateObject) &&
		(AbilityContext.ResultContext.HitResult == eHit_CounterAttack))
	{
		History = `XCOMHISTORY;

		// The target of the ability must be the source of the counterattack		
		UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		if (UnitState == none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		}

		// A dodge happened and this was a melee attack
		// Activate the counterattack ability (iff the unit is not impaired)
		CounterAttackBool = UnitState.GetUnitValue(class'X2Ability'.default.CounterattackDodgeEffectName, CounterAttackUnitValue);
		if (CounterAttackBool && (CounterAttackUnitValue.fValue == class'X2Ability'.default.CounterattackDodgeUnitValue) &&
			!UnitState.IsImpaired())
		{
			TacticalRules = `TACTICALRULES;

			//Find an ability that can use counter attack action points
			foreach UnitState.Abilities(UseMeleeAbilityRef)
			{
				AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UseMeleeAbilityRef.ObjectID));
				AbilityTemplate = AbilityState.GetMyTemplate();
				if (AbilityTemplate.AbilityCosts.Length > 0)
				{
					ActionPointCost = X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[0]);
					if (ActionPointCost != None && ActionPointCost.AllowedTypes.Find(class'X2CharacterTemplateManager'.default.CounterattackActionPoint) > -1)
					{
						bFoundUsableMeleeAbility = true;
						break;
					}
				}
			}

			if (bFoundUsableMeleeAbility)
			{
				//  Give the unit an action point so they can activate counterattack
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
				UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OwnerStateObject.ObjectID));
				UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.CounterattackActionPoint);

				NewGameState.AddStateObject(UnitState);
				TacticalRules.SubmitGameState(NewGameState);

				if (TacticalRules.GetGameRulesCache_Unit(OwnerStateObject, UnitCache))
				{
					for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
					{
						if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == UseMeleeAbilityRef.ObjectID)
						{
							for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j)
							{
								if (UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget == AbilityContext.InputContext.SourceObject)
								{
									if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')
									{
										class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j);
									}
									break;
								}
							}
							break;
						}
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn EverVigilantTurnEndListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit UnitState;
	local UnitValue NonMoveActionsThisTurn;
	local bool GotValue;
	local StateObjectReference OverwatchRef;
	local XComGameState_Ability OverwatchState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local EffectAppliedData ApplyData;
	local X2Effect VigilantEffect;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (UnitState == none)
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	if (UnitState.NumAllReserveActionPoints() == 0)     //  don't activate overwatch if the unit is potentially doing another reserve action
	{
		GotValue = UnitState.GetUnitValue('NonMoveActionsThisTurn', NonMoveActionsThisTurn);
		if (!GotValue || NonMoveActionsThisTurn.fValue == 0)
		{
			OverwatchRef = UnitState.FindAbility('PistolOverwatch');
			if (OverwatchRef.ObjectID == 0)
				OverwatchRef = UnitState.FindAbility('Overwatch');
			OverwatchState = XComGameState_Ability(History.GetGameStateForObjectID(OverwatchRef.ObjectID));
			if (OverwatchState != none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
				UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
				//  apply the EverVigilantActivated effect directly to the unit
				ApplyData.EffectRef.LookupType = TELT_AbilityShooterEffects;
				ApplyData.EffectRef.TemplateEffectLookupArrayIndex = 0;
				ApplyData.EffectRef.SourceTemplateName = 'EverVigilantTrigger';
				ApplyData.PlayerStateObjectRef = UnitState.ControllingPlayer;
				ApplyData.SourceStateObjectRef = UnitState.GetReference();
				ApplyData.TargetStateObjectRef = UnitState.GetReference();
				VigilantEffect = class'X2Effect'.static.GetX2Effect(ApplyData.EffectRef);
				`assert(VigilantEffect != none);
				VigilantEffect.ApplyEffect(ApplyData, UnitState, NewGameState);

				if (UnitState.NumActionPoints() == 0)
				{
					//  give the unit an action point so they can activate overwatch										
					UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);					
				}
				UnitState.SetUnitFloatValue(class'X2Ability_SpecialistAbilitySet'.default.EverVigilantEffectName, 1, eCleanup_BeginTurn);
				
				NewGameState.AddStateObject(UnitState);
				`TACTICALRULES.SubmitGameState(NewGameState);
				return OverwatchState.AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID);
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn DeepCoverTurnEndListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit UnitState;
	local UnitValue AttacksThisTurn;
	local bool GotValue;
	local StateObjectReference HunkerDownRef;
	local XComGameState_Ability HunkerDownState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (UnitState == none)
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	if (UnitState != none && !UnitState.IsHunkeredDown())
	{
		GotValue = UnitState.GetUnitValue('AttacksThisTurn', AttacksThisTurn);
		if (!GotValue || AttacksThisTurn.fValue == 0)
		{
			HunkerDownRef = UnitState.FindAbility('HunkerDown');
			HunkerDownState = XComGameState_Ability(History.GetGameStateForObjectID(HunkerDownRef.ObjectID));
			if (HunkerDownState != none && HunkerDownState.CanActivateAbility(UnitState,,true) == 'AA_Success')
			{
				if (UnitState.NumActionPoints() == 0)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
					UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
					//  give the unit an action point so they can activate hunker down										
					UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.DeepCoverActionPoint);					
					NewGameState.AddStateObject(UnitState);
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
							
				return HunkerDownState.AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID);
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ChryssalidCocoonSpawnedListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local GameRulesCache_Unit UnitCache;
	local X2TacticalGameRuleset TacticalRules;
	local int i, j;
	local XComGameState_Unit CocoonUnit, SourceUnit;
	local XComGameStateHistory History;

	CocoonUnit = XComGameState_Unit(EventSource);
	if( (CocoonUnit != none) && (CocoonUnit.ObjectID == OwnerStateObject.ObjectID) )
	{
		History = `XCOMHISTORY;
		SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(CocoonUnit.m_SpawnedCocoonRef.ObjectID));
		if( SourceUnit == none )
		{
			SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(CocoonUnit.m_SpawnedCocoonRef.ObjectID));
		}

		// The SourceUnit is the unit that spawned this Cocoon
		TacticalRules = `TACTICALRULES;

		if (TacticalRules.GetGameRulesCache_Unit(OwnerStateObject, UnitCache))
		{
			for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
			{
				if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == ObjectID)
				{
					for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j)
					{
						if (UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget == OwnerStateObject)
						{
							if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')
							{
								// This ability needs the source unit that spawned the ability as an AdditionalTarget
								UnitCache.AvailableActions[i].AvailableTargets[j].AdditionalTargets.AddItem(SourceUnit.GetReference());
								class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j);
							}
							break;
						}
					}
					break;
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn BurrowedChryssalidTakeDamageListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_Unit OldState, UnitState;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	// The target of the ability must be the source of the counterattack
	// The result must be a dodge for the counterattack to happen
	OldState = XComGameState_Unit(GameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (OldState == none)
	{
		History = `XCOMHISTORY;
		OldState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	}

	if( (OldState != none) && OldState.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.BurrowedName) )
	{
		TacticalRules = `TACTICALRULES;

		//  Give the unit an action point so they can activate counterattack
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OwnerStateObject.ObjectID));
		UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);

		UnitState.bTriggerRevealAI = false;

		// If this unit is queued to scamper, disable the scamper.
		`BEHAVIORTREEMGR.RemoveFromBTQueue(UnitState.ObjectID, true);

		NewGameState.AddStateObject(UnitState);
		TacticalRules.SubmitGameState(NewGameState);
		//  Give the unit an action point so they can activate counterattack

		AbilityTriggerAgainstSingleTarget(OwnerStateObject, false);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ScorchCircuits_AbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit UnitState, ScorchCircuitsUnit;
	local X2AbilityTemplate AbilityTemplate;
	local bool bReact;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)       //  only apply post-attack
	{
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID == OwnerStateObject.ObjectID)
		{
			AbilityState = XComGameState_Ability(EventData);
			UnitState = XComGameState_Unit(EventSource);
			ScorchCircuitsUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
			if (ScorchCircuitsUnit == None)
				ScorchCircuitsUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));

			if (AbilityState != none && UnitState != none && ScorchCircuitsUnit != none)
			{
				AbilityTemplate = AbilityState.GetMyTemplate();
				if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc) != None && X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bMeleeAttack
					&& AbilityContext.IsResultContextHit())
					bReact = true;
				else if (AbilityTemplate.DataName == class'X2Ability_Viper'.default.GetOverHereAbilityName)
					bReact = true;

				if (bReact)
				{
					AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false, GameState.HistoryIndex);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn WallPhasingActivation( Object EventData, Object EventSource, XComGameState GameState, Name EventID )
{
	local XComGameState_Unit ShooterUnit, TargetUnit;

	ShooterUnit = XComGameState_Unit( EventSource );
	TargetUnit = XComGameState_Unit( EventData );

	if (ShooterUnit != none && TargetUnit != none)
	{
		AbilityTriggerAgainstSingleTarget( ShooterUnit.GetReference( ), false );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn VoidRiftInsanityListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit ShooterUnit, TargetUnit;

	ShooterUnit = XComGameState_Unit(EventSource);
	TargetUnit = XComGameState_Unit(EventData);

	if (ShooterUnit != none && TargetUnit != none)
	{
		AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_VoidRiftEndDurrationFX(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit ShooterUnit, TargetUnit;
	local UnitValue NumInsanityTriggersUnitValue, NumSuccessfulInsanitiesUnitValue;
	local XComGameStateContext_Ability AbilityContext;
	local name EffectResult;
	local int TargetIndex, EffectIndex, NumSuccessfulInsanities;
	local X2Effect_TriggerEvent TargetEffect;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	ShooterUnit = XComGameState_Unit(EventSource);
	ShooterUnit.GetUnitValue('NumInsanityTriggers', NumInsanityTriggersUnitValue);
	ShooterUnit.GetUnitValue('NumSuccessfulInsanities', NumSuccessfulInsanitiesUnitValue);
	NumSuccessfulInsanities = NumSuccessfulInsanitiesUnitValue.fValue;

	if ((NumInsanityTriggersUnitValue.fValue == 0) &&
		(AbilityContext != none) &&
		(AbilityContext.ResultContext.MultiTargetEffectResults.Length > 0))
	{
		// If the value for NumInsanityTriggers is 0, then this must be the first time through
		// so count the number of successful insanities. If there are no successes then the end 
		// abiltiy will trigger and reset all values.
		NumSuccessfulInsanities = 0;

		for (TargetIndex = 0; TargetIndex < AbilityContext.ResultContext.MultiTargetEffectResults.Length; ++TargetIndex)
		{
			TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.MultiTargets[TargetIndex].ObjectID));
			if (TargetUnit != none)
			{
				for (EffectIndex = 0; EffectIndex < AbilityContext.ResultContext.MultiTargetEffectResults[TargetIndex].Effects.Length; ++EffectIndex)
				{
					TargetEffect = X2Effect_TriggerEvent(AbilityContext.ResultContext.MultiTargetEffectResults[TargetIndex].Effects[EffectIndex]);
					EffectResult = AbilityContext.ResultContext.MultiTargetEffectResults[TargetIndex].ApplyResults[EffectIndex];

					if ((TargetEffect != none) &&
						(TargetEffect.TriggerEventName == class'X2Ability_PsiOperativeAbilitySet'.default.VoidRiftInsanityEventName) &&
						(EffectResult == 'AA_Success'))
					{
						++NumSuccessfulInsanities;
						break;
					}
				}
			}
		}

		ShooterUnit.SetUnitFloatValue('NumSuccessfulInsanities', NumSuccessfulInsanities, eCleanup_BeginTurn);
	}

	if( NumSuccessfulInsanities == NumInsanityTriggersUnitValue.fValue)
	{
		ShooterUnit.ClearUnitValue('NumInsanityTriggers');
		ShooterUnit.ClearUnitValue('NumSuccessfulInsanities');

		AbilityTriggerAgainstSingleTarget(OwnerStateObject, false);
	}
	else
	{
		// Increment the number of times this has gotten a tick
		ShooterUnit.SetUnitFloatValue('NumInsanityTriggers', NumInsanityTriggersUnitValue.fValue + 1.0f);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn FuseListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit SourceUnit;
	local array<vector> TargetLocs;
	local StateObjectReference FuseRef;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID == OwnerStateObject.ObjectID)
		{
			SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));
			if (class'X2Condition_FuseTarget'.static.GetAvailableFuse(SourceUnit, FuseRef))
			{
				if (FuseRef.ObjectID == ObjectID)
				{
					TargetLocs.AddItem(`XWORLD.GetPositionFromTileCoordinates(SourceUnit.TileLocation));
					if (AbilityTriggerAgainstTargetIndex(0, GameState.HistoryIndex, TargetLocs))
						return ELR_InterruptListeners;
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn SoulStealListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Unit NewSourceUnit, TargetUnit;
	local int DamageDealt, DmgIdx;
	local float StolenHP;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if (TargetUnit != none)
		{
			for (DmgIdx = 0; DmgIdx < TargetUnit.DamageResults.Length; ++DmgIdx)
			{
				if (TargetUnit.DamageResults[DmgIdx].Context == AbilityContext)
				{
					DamageDealt += TargetUnit.DamageResults[DmgIdx].DamageAmount;
				}
			}
			if (DamageDealt > 0)
			{
				StolenHP = Round(float(DamageDealt) * class'X2Ability_PsiOperativeAbilitySet'.default.SOULSTEAL_MULTIPLIER);
				if (StolenHP > 0)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
					NewSourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
					if (NewSourceUnit != none)
					{
						//  Submit a game state that saves the Soul Steal value on the source unit
						NewSourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(NewSourceUnit.Class, NewSourceUnit.ObjectID));					
						NewSourceUnit.SetUnitFloatValue(class'X2Ability_PsiOperativeAbilitySet'.default.SoulStealUnitValue, StolenHP, eCleanup_BeginTurn);
						NewGameState.AddStateObject(NewSourceUnit);
						`TACTICALRULES.SubmitGameState(NewGameState);
						//  Activate this ability to steal the HP
						AbilityTriggerAgainstSingleTarget(OwnerStateObject, false, GameState.HistoryIndex);
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn SolaceCleanseListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit TargetUnit;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', TargetUnit, , , GameState.HistoryIndex)
	{
		AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);
	}

	return ELR_NoInterrupt;
}

// Responds when a unit moves and checks to see if the moved unit passed through the burrowed Chryssalid's detection area
// The primary target is the owner of this ability and the moved unit is set in multitarget
function EventListenerReturn CheckForVisibleMovementInRadius_Self(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	AbilityTriggerSawMovedTarget(EventData, GameState, GetAbilityRadius());
	return ELR_NoInterrupt;
}

function EventListenerReturn CheckForVisibleMovementInSightRadius_Self(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit OwnerUnit;
	local float SightRadiusMeters;

	History = `XCOMHISTORY;

	OwnerUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	SightRadiusMeters = `TILESTOUNITS(OwnerUnit.GetVisibilityRadius());
	AbilityTriggerSawMovedTarget(EventData, GameState, SightRadiusMeters);
	return ELR_NoInterrupt;
}

function EventListenerReturn CheckMoveTriggersRadiusAndBand_Self(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	// Check if band has been crossed.
	if( !AbilityTriggerIfGroupBandPassed(EventData, EventSource, GameState, EventID) )
	{
		AbilityTriggerSawMovedTarget(EventData, GameState, GetAbilityRadius());
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn CheckMoveTriggerGroupBandPassed(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	AbilityTriggerIfGroupBandPassed(EventData, EventSource, GameState, EventID);

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_UnitSeesUnit(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit ShooterUnit, TargetUnit, SourceUnit;
	local XComGameStateHistory History;
	local AvailableTarget Targets;
	local AvailableAction CurrentAvailableAction;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	ShooterUnit = XComGameState_Unit(EventSource);
	TargetUnit = XComGameState_Unit(EventData);

	if (ShooterUnit == XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID)))
	{
		CurrentAvailableAction.AvailableCode = CanActivateAbility(SourceUnit);

		if (CurrentAvailableAction.AvailableCode == 'AA_Success')
		{
			Targets.PrimaryTarget = TargetUnit.GetReference();
			CurrentAvailableAction.AvailableTargets.AddItem(Targets);
			CurrentAvailableAction.AbilityObjectRef = GetReference();

			class'XComGameStateContext_Ability'.static.ActivateAbility(CurrentAvailableAction, 0);
		}
	}

	return ELR_NoInterrupt;
}

function bool AbilityTriggerIfGroupBandPassed(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit SourceUnit, MovedUnit;
	local XComGameState_AIGroup Group;
	local XComGameStateHistory History;
	local Name AvailableCode;
	local XComGameState NewGameState;
	
	History = `XCOMHISTORY;
	MovedUnit = XComGameState_Unit(EventData);
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if( SourceUnit.bRemovedFromPlay )
		return false;

	GetMyTemplate();
	AvailableCode = m_Template.CheckShooterConditions(self, SourceUnit);// First check if source is eligible.  (Chryssalid must be burrowed for burrowed attack.)
	if( AvailableCode == 'AA_Success' )
	{
		AvailableCode = m_Template.CheckMultiTargetConditions(self, SourceUnit, MovedUnit);
	}
	if( AvailableCode != 'AA_Success' )
	{
		// The target is not valid for this ability
		return false;
	}
	if( MovedUnit.GetTeam() == eTeam_XCom ) // Only concerned when team XCom has moved.
	{
		// Test if band has been crossed by the enemy team.
		Group = SourceUnit.GetGroupMembership(GameState);
		if( Group != None && Group.XComSquadMidpointPassedGroup() )
		{
			// Give a free unburrow action point for this to work.
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			SourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(SourceUnit.Class, SourceUnit.ObjectID));
			SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);
			NewGameState.AddStateObject(SourceUnit);
			`TACTICALRULES.SubmitGameState(NewGameState);

			AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID);
			return true;
		}
	}
	return false;
}
function AbilityTriggerSawMovedTarget(Object EventData, XComGameState GameState, float DetectionRadius)
{
	local GameRulesCache_Unit UnitCache;
	local XComGameStateContext_Ability MoveContext;
	local int i,  j, TargetsIndex;
	local XComGameState_Unit SourceUnit, MovedUnit;
	local TTile CurrentTile;
	local bool bAbilityAvailable;
	local GameRulesCache_VisibilityInfo DirectionInfo;
	local float DetectionRadiusSq;
	local name AvailableCode;
	local AvailableAction AvailAction;
	local XComWorldData WorldData;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;
	local int PathIndex;

	History = `XCOMHISTORY;

	MoveContext = XComGameStateContext_Ability(GameState.GetContext());
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if( SourceUnit.bRemovedFromPlay )
		return;

	MovedUnit = XComGameState_Unit(EventData);
	PathIndex = MoveContext.GetMovePathIndex(MovedUnit.ObjectID);

	GetMyTemplate();
	AvailableCode = m_Template.CheckShooterConditions(self, SourceUnit); // First check if source is eligible.  (Chryssalid must be burrowed for burrowed attack.)
	if( AvailableCode == 'AA_Success' )
	{
		AvailableCode = m_Template.CheckMultiTargetConditions(self, SourceUnit, MovedUnit);
	}
	if (AvailableCode != 'AA_Success')
	{
		// The target is not valid for this ability
		return;
	}

	TacticalRules = `TACTICALRULES;

	// search the cache for the listening ability, if it is not available, don't
	// do the rest of this check
	bAbilityAvailable = false;
	if (TacticalRules.GetGameRulesCache_Unit(OwnerStateObject, UnitCache))
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
		{
			if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == ObjectID)
			{
				for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j)
				{
					if (UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget == OwnerStateObject)
					{
						if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')
						{
							AvailAction = UnitCache.AvailableActions[i];
							TargetsIndex = j;
							bAbilityAvailable = true;
						}
						break;
					}
				}
				break;
			}
		}
	}

	if( !bAbilityAvailable )
	{
		// This ability can't be used
		return;
	}

	WorldData = `XWORLD;

	DetectionRadiusSq = DetectionRadius * DetectionRadius;

	i = 0;
	while(i < MoveContext.InputContext.MovementPaths[PathIndex].MovementTiles.Length)
	{
		// Check if current tile passed through the radius
		CurrentTile = MoveContext.InputContext.MovementPaths[PathIndex].MovementTiles[i];

		if( WorldData.CanSeeTileToTile(SourceUnit.TileLocation, CurrentTile, DirectionInfo) 
		   && DirectionInfo.DefaultTargetDist <= DetectionRadiusSq)
		{
			AvailAction.AvailableTargets[TargetsIndex].AdditionalTargets.Length = 0;
			AvailAction.AvailableTargets[TargetsIndex].AdditionalTargets.AddItem(MovedUnit.GetReference());
			class'XComGameStateContext_Ability'.static.ActivateAbility(AvailAction, TargetsIndex);
			i = MoveContext.InputContext.MovementPaths[PathIndex].MovementTiles.Length;
		}

		++i;
	}
}

function EventListenerReturn HackTriggerTargetListener(Object EventData, Object EventSource, XComGameState GameState, Name InEventID)
{
	local XComGameState_BaseObject HackTarget;

	if( EventSource == self )
	{
		HackTarget = XComGameState_BaseObject(EventData);
		AbilityTriggerAgainstSingleTarget(HackTarget.GetReference(), false);
	}

	return ELR_NoInterrupt;
}

simulated function UISummary_Ability GetUISummary_Ability(optional XComGameState_Unit UnitState)
{
	local UISummary_Ability Data;
	local X2AbilityTemplate Template;

	// First, get all of the template-relevant data in here. 
	Template = GetMyTemplate();
	if (Template != None)
	{
		Data = Template.GetUISummary_Ability(); 		
	}

	// Now, fill in the instance data. 
	Data.Name = GetMyFriendlyName();
	if (Template.bUseLaunchedGrenadeEffects || Template.bUseThrownGrenadeEffects)
		Data.Description = GetMyHelpText(UnitState);
	else if (Template.HasLongDescription())
		Data.Description = Template.GetMyLongDescription(self, UnitState);
	else
		Data.Description = Template.GetMyHelpText(self, UnitState);
	
	if (Data.Description == "")
		Data.Description = "MISSING ALL HELP TEXT";

	//TODO: @gameplay fill in somma dat data. 
	Data.KeybindingLabel = "<KEY>"; //TODO
	Data.ActionCost = 0; //TODO
	Data.CooldownTime = iCooldown; 
	Data.bEndsTurn = false; //TODO
	Data.EffectLabel = ""; //TODO "Reflex" etc.

	return Data; 
}

simulated function int GetUIReticleIndex()
{
	local X2AbilityTemplate Template;
	local XComGameState_Item Weapon;
	local name WeaponTech;
	local name WeaponCategory;

	Template = GetMyTemplate();
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(SourceWeapon.ObjectID));
		
	if (Weapon != none)
	{
		WeaponTech = Weapon.GetWeaponTech();
		WeaponCategory = Weapon.GetWeaponCategory();
	}

	if (Template.Hostility == eHostility_Defensive)
		return eUIReticle_Defensive;

	// TODO: do we have / can we have constants for these names?
	if (WeaponCategory == 'sword')
		return eUIReticle_Sword;

	if (WeaponTech == 'magnetic')
		return eUIReticle_Advent;

	if (WeaponTech == 'beam')
		return eUIReticle_Alien;

	// conventional
	if (Template.Hostility == eHostility_Offensive)
		return eUIReticle_Offensive;
	else //neutral hostility with no weapon override should use defensive reticle (objectives, interactives)
		return eUIReticle_Defensive;
}

simulated function int GetUISummary_HackingBreakdown(out UIHackingBreakdown kBreakdown, int TargetID)
{
	//  @TODO jbouscher - fill this out - may require updates from UI

	return -1;
}

static function int LookupShotBreakdown(StateObjectReference Shooter, StateObjectReference Target, optional StateObjectReference UseAbility, optional out ShotBreakdown kBreakdown)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState, DisplayAbilityState;
	local AvailableTarget AvailTarget;
	local XComGameState_Item PrimaryWeapon;
	local int i;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Shooter.ObjectID));
	if (UnitState != none)
	{		
		if (UseAbility.ObjectID == 0)
		{
			PrimaryWeapon = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon);
			for (i = 0; i < UnitState.Abilities.Length; ++i)
			{
				AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
				if (AbilityState.SourceWeapon.ObjectID == PrimaryWeapon.ObjectID)
				{
					if (AbilityState.GetMyTemplate().DisplayTargetHitChance)
					{
						DisplayAbilityState = AbilityState;
						break;
					}
				}
			}
		}
		else
		{
			DisplayAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UseAbility.ObjectID));
		}
		if (DisplayAbilityState == none)
		{
			`RedScreen(string(GetFuncName()) @ "could not determine ability to display for shooter" @ Shooter.ObjectID);
			return 0;
		}
		AvailTarget.PrimaryTarget = Target;
		return DisplayAbilityState.GetShotBreakdown(AvailTarget, kBreakdown);
	}
	`RedScreen(string(GetFuncName()) @ "called with invalid shooter" @ Shooter.ObjectID);
	return 0;
}

simulated function string GetMyFriendlyName()
{
	local X2AbilityTemplate Template;
	local X2GrenadeTemplate GrenadeTemplate;
	local XComGameState_Unit UnitState;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local XComGameState_Item LocalSourceWeapon;
	local string RenamedAbility;
	local int i;

	Template = GetMyTemplate();
	LocalSourceWeapon = GetSourceWeapon();

	if (Template.LocFriendlyNameWhenConcealed != "")
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		if (UnitState != none && UnitState.IsConcealed())
			return Template.LocFriendlyNameWhenConcealed;
	}

	if (Template.bUseThrownGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(LocalSourceWeapon.GetMyTemplate());
		if (GrenadeTemplate != none)
			return GrenadeTemplate.ThrownAbilityName;
	}
	if (Template.bUseLaunchedGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(LocalSourceWeapon.GetLoadedAmmoTemplate(self));
		if (GrenadeTemplate != none)
			return GrenadeTemplate.LaunchedAbilityName;
	}

	//Check if the source weapon has any upgrades that would alter this ability's name.
	if (LocalSourceWeapon != none)
	{
		UpgradeTemplates = LocalSourceWeapon.GetMyWeaponUpgradeTemplates();
		for (i = 0; i < UpgradeTemplates.Length; ++i)
		{
			RenamedAbility = UpgradeTemplates[i].GetRenamedAbilityFriendlyName(self);
			if ( RenamedAbility != "")
				return RenamedAbility;
		}
	}

	return Template.LocFriendlyName;
}

simulated function string GetMyHelpText(optional XComGameState_Unit Unit)
{
	local X2AbilityTemplate Template;
	local X2GrenadeTemplate GrenadeTemplate;

	Template = GetMyTemplate();
	if (Template.bUseThrownGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(GetSourceWeapon().GetMyTemplate());
		if (GrenadeTemplate != none)
			return GrenadeTemplate.ThrownAbilityHelpText;
	}
	if (Template.bUseLaunchedGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate(GetSourceWeapon().GetLoadedAmmoTemplate(self));
		if (GrenadeTemplate != none)
			return GrenadeTemplate.LaunchedAbilityHelpText;
	}
	return Template.GetMyHelpText(self, Unit);
}

simulated function string GetMyIconImage()
{
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Item MySourceWeapon;
	local X2WeaponTemplate WeaponTemplate;
	local string IconImage;

	AbilityTemplate = GetMyTemplate();
	if (AbilityTemplate != none)
	{		
		MySourceWeapon = GetSourceWeapon();
		if (MySourceWeapon != none)
		{
			WeaponTemplate = X2WeaponTemplate(MySourceWeapon.GetMyTemplate());
			if (WeaponTemplate != none)
			{
				IconImage = WeaponTemplate.GetAbilityIconOverride(GetMyTemplateName());
			}
			if (IconImage == "")
			{
				WeaponTemplate = X2WeaponTemplate(MySourceWeapon.GetLoadedAmmoTemplate(self));
				if (WeaponTemplate != none)
				{
					IconImage = WeaponTemplate.GetAbilityIconOverride(GetMyTemplateName());
				}
			}
		}
		if (IconImage == "")
			IconImage = AbilityTemplate.IconImage;
	}
	return IconImage;
}

// Used by AI, mainly to get weapon range of melee attacks.  Returns MinRange = 0 and MaxRange = -1 if not restricted.
event GetValidWeaponRange(out float MinRange, out float MaxRange)
{
	local X2AbilityTarget_Single AbilityTargetStyle;
	local XComGameState_Item SourceWeaponState;
	local X2AbilityTemplate Template;
	local X2Condition Condition;
	local X2Condition_UnitProperty TargetCondition;
	local int ItemRange;

	MinRange = 0;
	MaxRange = -1;
	// Check for weapon-restriction on range.
	Template = GetMyTemplate();
	AbilityTargetStyle = X2AbilityTarget_Single(Template.AbilityTargetStyle);
	if( AbilityTargetStyle != None && AbilityTargetStyle.OnlyIncludeTargetsInsideWeaponRange )
	{
		SourceWeaponState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(SourceWeapon.ObjectID));
		if( SourceWeaponState != None )
		{
			ItemRange = SourceWeaponState.GetItemRange(self);
			if( ItemRange == 0 )
			{
				// This is a melee range
				MaxRange = `METERSTOUNITS(class'XComWorldData'.const.WORLD_Melee_Range_Meters);
			}
			else
			{
				MaxRange = `TILESTOUNITS(ItemRange);
			}
		}
	}

	// Also check range in target conditions.
	if( MaxRange == -1 )
	{
		foreach Template.AbilityTargetConditions(Condition)
		{
			TargetCondition = X2Condition_UnitProperty(Condition);
			if( TargetCondition != None )
			{
				if( TargetCondition.RequireWithinRange )
				{
					MaxRange = TargetCondition.WithinRange;
				}
				 // WithinMinRange is the inner range of valid locations.  
				if( TargetCondition.RequireWithinMinRange )
				{
					MinRange = TargetCondition.WithinMinRange;
				}
			}
		}
	}
}

// Panic triggered when a unit takes damage.  Also applies to any teammates that have seen this unit die.
// Since the ability's hit calc depends on the panic event strength, this value needs to be updated and submitted
// before activating the panic ability.
function EventListenerReturn PanicTriggerListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit DamagedUnit, Viewer;
	local GameRulesCache_Unit UnitCache;
	local int i, PanicStrength, DeadRank, ViewRank;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;

	if( !`TACTICALMISSIONMGR.ActiveMission.DisablePanic && (`CHEATMGR == None || !`CHEATMGR.bDisablePanic) )
	{
		History = `XCOMHISTORY;
		TacticalRules = `TACTICALRULES;

		if (EventID == 'UnitPanicked')
			DamagedUnit = XComGameState_Unit(EventSource);
		else
			DamagedUnit = XComGameState_Unit(EventData);

		//  If responding to a panicked unit, make sure it's not us
		if (EventID == 'UnitPanicked')
		{
			Viewer = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
			if (Viewer != none && Viewer.ObjectID != DamagedUnit.ObjectID)
			{
				if( TacticalRules.GetGameRulesCache_Unit(Viewer.GetReference(), UnitCache) )
				{
					for( i = 0; i < UnitCache.AvailableActions.Length; ++i )
					{
						AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID));
						if( AbilityState.m_TemplateName == m_TemplateName ) // Find panic ability on this unit.
						{
							if( UnitCache.AvailableActions[i].AvailableCode == 'AA_Success' )
							{
								// Set panic strength.
								NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
								AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', AbilityState.ObjectID));
								AbilityState.PanicEventValue = class'X2StatusEffects'.default.PANIC_STRENGTH_ALLY_PANICS;
								AbilityState.PanicFlamethrower = false;
								NewGameState.AddStateObject(AbilityState);
								`TACTICALRULES.SubmitGameState(NewGameState);

								class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i]);
							}
							break;
						}
					}
				}
			}
		}
		// If this unit is damaged, only this unit can panic.
		else if( DamagedUnit.IsAlive() && !DamagedUnit.IsBleedingOut() && !DamagedUnit.IsUnconscious() && !DamagedUnit.IsStasisLanced() )
		{
			// Set panic strength.
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', ObjectID));

			AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
			if (AbilityContext != None && AbilityContext.InputContext.AbilityTemplateName == 'Flamethrower')    //  @TODO - better way to handle this?
			{
				AbilityState.PanicFlamethrower = true;
			}
			else
			{
				AbilityState.PanicFlamethrower = false;
			}

			//  AI can only panic from flamethrower damage
			if( DamagedUnit.ControllingPlayerIsAI() && !AbilityState.PanicFlamethrower)
			{
				History.CleanupPendingGameState(NewGameState);
				return ELR_NoInterrupt;
			}

			AbilityState.PanicEventValue = class'X2StatusEffects'.default.PANIC_STRENGTH_TAKE_DAMAGE;
			NewGameState.AddStateObject(AbilityState);
			`TACTICALRULES.SubmitGameState(NewGameState);
			// Apply panic ability to self.
			if( TacticalRules.GetGameRulesCache_Unit(OwnerStateObject, UnitCache) )
			{
				for( i = 0; i < UnitCache.AvailableActions.Length; ++i )
				{
					if( UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == ObjectID )
					{
						if( UnitCache.AvailableActions[i].AvailableCode == 'AA_Success' )
						{
							class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], 0);
						}
						break;
					}
				}
			}
		}
		// On death, all teammates with LoS kick off their panic ability, with the appropriate value.
		else if (!DamagedUnit.ControllingPlayerIsAI())
		{
			DeadRank = DamagedUnit.GetRank();
			// Apply panic check on all teammates.
			foreach History.IterateByClassType(class'XComGameState_Unit', Viewer, , , GameState.HistoryIndex)
			{
				// Reset PanicStrength value, as it can be increased depending on unit rank.
				PanicStrength = class'X2StatusEffects'.default.PANIC_STRENGTH_LOS_FRIENDLY_DEATH;
				if( Viewer.GetTeam() == DamagedUnit.GetTeam() && Viewer.ObjectID != DamagedUnit.ObjectID )
				{
					if( TacticalRules.GetGameRulesCache_Unit(Viewer.GetReference(), UnitCache) )
					{
						for( i = 0; i < UnitCache.AvailableActions.Length; ++i )
						{
							AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID));
							if( AbilityState.m_TemplateName == m_TemplateName ) // Find panic ability on this unit.
							{
								if( UnitCache.AvailableActions[i].AvailableCode == 'AA_Success' )
								{
									// Set panic strength.
									ViewRank = Viewer.GetRank();
									if (DeadRank >= ViewRank + class'X2StatusEffects'.default.PANIC_HIGHER_RANK)
									{
										PanicStrength = class'X2StatusEffects'.default.PANIC_STRENGTH_LOS_HIGHER_FRIENDLY_DEATH;
									}
									else if (DeadRank >= ViewRank - class'X2StatusEffects'.default.PANIC_LOWER_RANK)
									{
										PanicStrength = class'X2StatusEffects'.default.PANIC_STRENGTH_LOS_FRIENDLY_DEATH;
									}
									else
									{
										//  rank is too low to care
										break;
									}
									NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
									AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', AbilityState.ObjectID));
									AbilityState.PanicEventValue = PanicStrength;
									AbilityState.PanicFlamethrower = false;
									NewGameState.AddStateObject(AbilityState);
									`TACTICALRULES.SubmitGameState(NewGameState);

									class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], 0);
								}
								break;
							}
						}
					}
				}
			}
		}

	}
	return ELR_NoInterrupt;
}

function bool DoesAbilityCauseSound()
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect AbilityEffect;

	// TODO: come up with something more appropriate

	AbilityTemplate = GetMyTemplate();
	
	if (AbilityTemplate.bSilentAbility)
		return false;

	// for now, looking for abilities which consume ammo...
	if( iAmmoConsumed > 0 )
	{
		return true;
	}

	// ... or deal damage	
	foreach AbilityTemplate.AbilityTargetEffects(AbilityEffect)
	{
		if( AbilityEffect.IsA('X2Effect_ApplyWeaponDamage') )
		{
			return true;
		}
	}
	return false;

}


function EventListenerReturn AbilityTriggerEventListener_WrathCannon(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;
	local AvailableAction CurrentAvailableAction;
	local XComGameState_Unit SourceUnit;
	local array<vector> TargetLocations;
	local XComGameState_Effect EffectState;
	local AbilityInputContext InputContext;

	History = `XCOMHISTORY;

		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	EffectState = SourceUnit.GetUnitAffectedByEffectState(class'X2Ability_Sectopod'.default.WrathCannonStage1EffectName);
	if( EffectState != none )
	{
		UpdateAbilityAvailability(CurrentAvailableAction);
		InputContext = EffectState.ApplyEffectParameters.AbilityInputContext;
		if( (CurrentAvailableAction.AvailableCode == 'AA_Success') && (InputContext.TargetLocations.Length > 0) )
		{
			// Set up the available action
			CurrentAvailableAction.AbilityObjectRef = GetReference();

			// The Target Locations for this ability are the same as the stage 1 ability
			TargetLocations = InputContext.TargetLocations;
			class'XComGameStateContext_Ability'.static.ActivateAbility(CurrentAvailableAction, 0, TargetLocations);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AbilityTriggerEventListener_DamagedByEnemyTeleport(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit DamagedUnit, DamageSourceUnit;
	local XComGameStateContext GameStateContext;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	GameStateContext = GameState.GetContext();

	AbilityContext = XComGameStateContext_Ability(GameStateContext);
	if (AbilityContext != none)
	{
		DamagedUnit = XComGameState_Unit(EventData);
		DamageSourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		if( DamageSourceUnit == none )
		{
			DamageSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		}

		// Check to see if the source of this ability damage is an enemy
		if( DamagedUnit.IsFriendlyUnit(DamageSourceUnit) )
		{
			// Do not teleport if the damage is caused by a friendly unit
			return ELR_NoInterrupt;
		}
	}

	return AbilityTriggerEventListener_DamagedTeleport(EventData, EventSource, GameState, EventID);
}

function EventListenerReturn AbilityTriggerEventListener_DamagedTeleport(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit DamagedUnit, DamagedUnitPrevious, NewDamagedUnit;
	local XComGameState_BaseObject NewUnit, OldUnit;
	local int DamageAmount, DamageIndex, DamageCheckIndex;
	local XComGameState NewGameState;
	local UnitValue DamageTeleportUnitValue;
	local XComGameStateContext GameStateContext;
	local XComGameState EventChainStart;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameStateHistory History;
	local bool bTriggered;
	local X2EffectTemplateRef LookupEffect;
	local X2Effect SourceEffect;
	local array<name> DamageTypes;

	History = `XCOMHISTORY;

	GameStateContext = GameState.GetContext();

	AbilityContext = XComGameStateContext_Ability(GameStateContext);
	if (AbilityContext != none)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != none && AbilityTemplate.bPreventsTargetTeleport)
		{
			//The ability uses does not allow the damaged unit to teleport
			return ELR_NoInterrupt;
		}
	}

	// The unit must still be alive and not incapacitated
	DamagedUnit = XComGameState_Unit(EventData);
	if( DamagedUnit.IsAlive() && !DamagedUnit.IsBleedingOut() && !DamagedUnit.IsUnconscious() && !DamagedUnit.IsStasisLanced() )
	{			
		if(EventID == 'UnitTakeEffectDamage') //If we were triggered by taking damage, 
		{			
			//First verify that we aren't moving
			EventChainStart = GameStateContext.GetFirstStateInEventChain();
			DamagedUnit = XComGameState_Unit(History.GetGameStateForObjectID(DamagedUnit.ObjectID, eReturnType_Reference, GameState.HistoryIndex));
			DamagedUnitPrevious = XComGameState_Unit(History.GetGameStateForObjectID(DamagedUnit.ObjectID, eReturnType_Reference, EventChainStart.HistoryIndex));
			if(DamagedUnit.TileLocation == DamagedUnitPrevious.TileLocation) 
			{
				//Now update current and previous so that the damage amount can be measured
				History.GetCurrentAndPreviousGameStatesForObjectID(DamagedUnit.ObjectID, OldUnit, NewUnit, eReturnType_Reference, GameState.HistoryIndex);
				DamagedUnit = XComGameState_Unit(NewUnit);
				DamagedUnitPrevious = XComGameState_Unit(OldUnit);
				bTriggered = true;
			}
		}
		else if(EventID == 'UnitMoveFinished')
		{
			EventChainStart = GameStateContext.GetFirstStateInEventChain();
			DamagedUnit = XComGameState_Unit(History.GetGameStateForObjectID(DamagedUnit.ObjectID, eReturnType_Reference, GameState.HistoryIndex));
			DamagedUnitPrevious = XComGameState_Unit(History.GetGameStateForObjectID(DamagedUnit.ObjectID, eReturnType_Reference, EventChainStart.HistoryIndex));
			bTriggered = DamagedUnit.GetCurrentStat(eStat_HP) != DamagedUnitPrevious.GetCurrentStat(eStat_HP); //Moved, and took damage while moving
		}

		if(bTriggered)
		{
			`assert(DamagedUnit != none);
			`assert(DamagedUnitPrevious != none);
			if((DamagedUnitPrevious != none) && (DamagedUnit != none))
			{
				DamageAmount = DamagedUnitPrevious.GetCurrentStat(eStat_HP) - DamagedUnit.GetCurrentStat(eStat_HP);

				// The damage taken must be greater than zero
				if(DamageAmount > 0)
				{
					for(DamageIndex = 0; DamageIndex < DamagedUnit.DamageResults.Length; ++DamageIndex)
					{
						if(DamagedUnit.DamageResults[DamageIndex].Context == GameStateContext)
						{
							if(XComGameStateContext_Falling(DamagedUnit.DamageResults[DamageIndex].Context) != none)
							{
								// Cannot do a damage teleport due to falling damage
								bTriggered = false;
							}
							else
							{
								// Damage types need to be checked
								DamageTypes.Length = 0;

								LookupEffect = DamagedUnit.DamageResults[DamageIndex].SourceEffect.EffectRef;
								SourceEffect = class'X2Effect'.static.GetX2Effect(LookupEffect);

								SourceEffect.GetEffectDamageTypes(GameState, DamagedUnit.DamageResults[DamageIndex].SourceEffect, DamageTypes);
								
								for(DamageCheckIndex = 0; DamageCheckIndex < DamageTypes.Length; ++DamageCheckIndex)
								{
									if(class'X2Item_DefaultDamageTypes'.default.DamagedTeleport_DmgNotAllowed.Find(DamageTypes[DamageCheckIndex]) != INDEX_NONE)
									{
										// This damage type does not allow the damaged teleport to occur
										bTriggered = false;
										break;
									}
								}
							}

							if(!bTriggered)
							{
								break;
							}
						}
					}

					if(bTriggered)
					{
						// Check to see if a damage in this GameState has already triggered the DamageTeleport
						DamagedUnit.GetUnitValue(class'X2Ability_Cyberus'.default.DamageTeleportDamageChainIndexName, DamageTeleportUnitValue);

						if(DamageTeleportUnitValue.fValue != GameStateContext.EventChainStartIndex)
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
							NewDamagedUnit = XComGameState_Unit(NewGameState.CreateStateObject(DamagedUnit.Class, DamagedUnit.ObjectID));
							NewDamagedUnit.SetUnitFloatValue(class'X2Ability_Cyberus'.default.DamageTeleportDamageChainIndexName, GameStateContext.EventChainStartIndex);
							NewGameState.AddStateObject(NewDamagedUnit);
							`TACTICALRULES.SubmitGameState(NewGameState);

							return AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID);
						}
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn FacelessOnDeathListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit DeadUnit, UnitIterator;
	local XComGameStateHistory History;

	local XComGameState_Unit SourceUnit;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if( SourceUnit.bRemovedFromPlay )
		return ELR_NoInterrupt;

	DeadUnit = XComGameState_Unit(EventSource);
	if( (DeadUnit != none) && DeadUnit.GetTeam() == eTeam_Alien ) // Check only if the dead unit could be the last AI unit.
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitIterator,,,GameState.HistoryIndex)
		{
			if( UnitIterator.GetTeam() != eTeam_Alien || UnitIterator.IsTurret())
			{
				continue;
			}

			if( UnitIterator.IsAbleToAct() )
			{
				return ELR_NoInterrupt; // Still have living active AI units.
			}
		}

		// No living AI units!
		return AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID);
	}

	return ELR_NoInterrupt;
}

// From X2AbilityCost_ActionPoints - moved here so the delegate serializes properly
simulated static function DidNotConsumeAll_PostBuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int ShooterID;
	local int TrackIndex, CostIndex;
	local XComGameState_Unit UnitState, OldUnitState;
	local X2AbilityTemplate AbilityTemplate, HasAbilityTemplate;;
	local X2AbilityCost_ActionPoints PointCost;
	local name DoNotConsumeIter;
	local string FlyoverText, FlyoverIcon;
	local X2Effect_Persistent Effect;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	ShooterID = AbilityContext.InputContext.SourceObject.ObjectID;

	for (TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; TrackIndex++)
	{
		if (OutVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == ShooterID)
		{
			UnitState = XComGameState_Unit(OutVisualizationTracks[TrackIndex].StateObject_NewState);
			//  Only show a flyover if the unit still has action points remaining, otherwise the fact we saved points doesn't really matter
			if (UnitState.NumActionPoints() > 0)
			{
				OldUnitState = XComGameState_Unit(OutVisualizationTracks[TrackIndex].StateObject_OldState);
				AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
				for (CostIndex = 0; CostIndex < AbilityTemplate.AbilityCosts.Length; ++CostIndex)
				{
					PointCost = X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[CostIndex]);
					if (PointCost != none)
					{
						foreach PointCost.DoNotConsumeAllEffects(DoNotConsumeIter)
						{
							if (OldUnitState.IsUnitAffectedByEffectName(DoNotConsumeIter))
							{
								Effect = OldUnitState.GetUnitAffectedByEffectState(DoNotConsumeIter).GetX2Effect();
								FlyoverText = Effect.FriendlyName;
								FlyoverIcon = Effect.IconImage;
								break;
							}
						}
						if (FlyoverText != "")
							break;
						foreach PointCost.DoNotConsumeAllSoldierAbilities(DoNotConsumeIter)
						{
							if (OldUnitState.HasSoldierAbility(DoNotConsumeIter))
							{
								HasAbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(DoNotConsumeIter);
								FlyoverText = HasAbilityTemplate.LocFlyOverText;
								FlyoverIcon = HasAbilityTemplate.IconImage;
								break;
							}
						}
					}
				}
			}
			if (FlyoverText == "")
			{
				return;
			}
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.CreateVisualizationAction(AbilityContext));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, FlyoverText, '', eColor_Good, FlyoverIcon, `DEFAULTFLYOVERLOOKATTIME, true);
			OutVisualizationTracks[TrackIndex].TrackActions.AddItem(SoundAndFlyOver);
			break;
		}
	}
}

// From X2AbilityTemplate - moved here so the delegate serializes properly
simulated function FreeFire_PostBuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int ShooterID;
	local int TrackIndex;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	ShooterID = AbilityContext.InputContext.SourceObject.ObjectID;

	for (TrackIndex = 0; TrackIndex < OutVisualizationTracks.Length; TrackIndex++)
	{
		if (OutVisualizationTracks[TrackIndex].StateObject_OldState.ObjectID == ShooterID)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.CreateVisualizationAction(AbilityContext));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'XLocalizedData'.default.HairTriggerFreeAction, '', eColor_Good, , `DEFAULTFLYOVERLOOKATTIME, true);
			OutVisualizationTracks[TrackIndex].TrackActions.AddItem(SoundAndFlyOver);
			break;
		}
	}
}

DefaultProperties
{
	iCharges = -1
	TurnsUntilAbilityExpires = -1
}
