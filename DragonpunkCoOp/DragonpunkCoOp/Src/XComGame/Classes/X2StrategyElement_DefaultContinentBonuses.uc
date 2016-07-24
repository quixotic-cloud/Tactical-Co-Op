//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultContinentBonuses.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultContinentBonuses extends X2StrategyElement
	config(GameData);

var config array<int>			AllInBonus;
var config array<int>			SpyRingBonus;
var config array<int>			FutureCombatBonus;
var config array<int>			PursuitOfKnowledgeBonus;
var config array<int>			ToServeMankindCost;
var config array<int>			HiddenReservesBonus;
var config array<int>			QuidProQuoBonus;
var config array<int>			UnderTheTableBonus;
var config array<int>			SparePartsBonus;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Bonuses;

	Bonuses.AddItem(CreateAllInTemplate());
	Bonuses.AddItem(CreateSpyRingTemplate());
	//Bonuses.AddItem(CreateSignalFlareTemplate());
	Bonuses.AddItem(CreateFutureCombatTemplate());
	//Bonuses.AddItem(CreateXenobiologyTemplate());
	Bonuses.AddItem(CreatePursuitOfKnowledgeTemplate());
	Bonuses.AddItem(CreateToServeMankindTemplate());
	Bonuses.AddItem(CreateHiddenReservesTemplate());
	Bonuses.AddItem(CreateQuidProQuoTemplate());
	Bonuses.AddItem(CreateUnderTheTableTemplate());
	//Bonuses.AddItem(CreateHelpingHandTemplate());
	Bonuses.AddItem(CreateSparePartsTemplate());
	Bonuses.AddItem(CreateSuitUpTemplate());
	Bonuses.AddItem(CreateFireWhenReadyTemplate());
	Bonuses.AddItem(CreateLockAndLoadTemplate());
	Bonuses.AddItem(CreateArmedToTheTeethTemplate());

	return Bonuses;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAllInTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_AllIn');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateAllIn;
	Template.OnDeactivatedFn = DeactivateAllIn;
	Template.GetMutatorValueFn = GetValueAllIn;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateAllIn(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = GetNewResHQState(NewGameState);
	ResistanceHQ.SupplyDropPercentIncrease += default.AllInBonus[`DIFFICULTYSETTING];
}
//---------------------------------------------------------------------------------------
static function DeactivateAllIn(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = GetNewResHQState(NewGameState);
	ResistanceHQ.SupplyDropPercentIncrease = 0;
}
//---------------------------------------------------------------------------------------
static function int GetValueAllIn()
{
	return default.AllInBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateSpyRingTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_SpyRing');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateSpyRing;
	Template.OnDeactivatedFn = DeactivateSpyRing;
	Template.GetMutatorValueFn = GetValueSpyRing;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateSpyRing(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = GetNewResHQState(NewGameState);
	ResistanceHQ.IntelRewardPercentIncrease += default.SpyRingBonus[`DIFFICULTYSETTING];
}
//---------------------------------------------------------------------------------------
static function DeactivateSpyRing(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = GetNewResHQState(NewGameState);
	ResistanceHQ.IntelRewardPercentIncrease = 0;
}
//---------------------------------------------------------------------------------------
static function int GetValueSpyRing()
{
	return default.SpyRingBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateSignalFlareTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_SignalFlare');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateSignalFlare;
	Template.OnDeactivatedFn = DeactivateSignalFlare;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateSignalFlare(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	if(!bReactivate || !XComHQ.bUsedFreeContact)
	{
		XComHQ.bFreeContact = true;
	}
}
//---------------------------------------------------------------------------------------
static function DeactivateSignalFlare(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bFreeContact = false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateFutureCombatTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_FutureCombat');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateFutureCombat;
	Template.OnDeactivatedFn = DeactivateFutureCombat;
	Template.GetMutatorValueFn = GetValueFutureCombat;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateFutureCombat(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.GTSPercentDiscount = default.FutureCombatBonus[`DIFFICULTYSETTING];
}
//---------------------------------------------------------------------------------------
static function DeactivateFutureCombat(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.GTSPercentDiscount = 0;
}
//---------------------------------------------------------------------------------------
static function int GetValueFutureCombat()
{
	return default.FutureCombatBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateXenobiologyTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_Xenobiology');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateXenobiology;
	Template.OnDeactivatedFn = DeactivateXenobiology;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateXenobiology(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);

	XComHQ.bInstantAutopsies = true;
}
//---------------------------------------------------------------------------------------
static function DeactivateXenobiology(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bInstantAutopsies = false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePursuitOfKnowledgeTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_PursuitOfKnowledge');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivatePursuitOfKnowledge;
	Template.OnDeactivatedFn = DeactivatePursuitOfKnowledge;
	Template.GetMutatorValueFn = GetValuePursuitOfKnowledge;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivatePursuitOfKnowledge(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);

	// Add a research bonus for each lab already created, then set the flag so it will work for all future labs built
	XComHQ.ResearchEffectivenessPercentIncrease = default.PursuitOfKnowledgeBonus[`DIFFICULTYSETTING] * XComHQ.GetNumberOfFacilitiesOfType(XComHQ.GetFacilityTemplate('Laboratory'));
	XComHQ.bLabBonus = true;

	XComHQ.HandlePowerOrStaffingChange(NewGameState);
}
//---------------------------------------------------------------------------------------
static function DeactivatePursuitOfKnowledge(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.ResearchEffectivenessPercentIncrease = 0;
	XComHQ.bLabBonus = false;
	
	XComHQ.HandlePowerOrStaffingChange(NewGameState);
}
//---------------------------------------------------------------------------------------
static function int GetValuePursuitOfKnowledge()
{
	return default.PursuitOfKnowledgeBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateToServeMankindTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_ToServeMankind');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateToServeMankind;
	Template.OnDeactivatedFn = DeactivateToServeMankind;
	Template.GetMutatorValueFn = GetValueToServeMankind;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateToServeMankind(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = GetNewResHQState(NewGameState);
	ResistanceHQ.RecruitCostModifier = (default.ToServeMankindCost[`DIFFICULTYSETTING] - ResistanceHQ.RecruitSupplyCosts[`DIFFICULTYSETTING]);
}
//---------------------------------------------------------------------------------------
static function DeactivateToServeMankind(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = GetNewResHQState(NewGameState);
	ResistanceHQ.RecruitCostModifier = 0;
}
//---------------------------------------------------------------------------------------
static function int GetValueToServeMankind()
{
	return default.ToServeMankindCost[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateHiddenReservesTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_HiddenReserves');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateHiddenReserves;
	Template.OnDeactivatedFn = DeactivateHiddenReserves;
	Template.GetMutatorValueFn = GetValueHiddenReserves;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateHiddenReserves(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.PowerOutputBonus += default.HiddenReservesBonus[`DIFFICULTYSETTING];
	XComHQ.DeterminePowerState();
	XComHQ.HandlePowerOrStaffingChange(NewGameState);
}
//---------------------------------------------------------------------------------------
static function DeactivateHiddenReserves(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.PowerOutputBonus = 0;
	XComHQ.DeterminePowerState();
	XComHQ.HandlePowerOrStaffingChange(NewGameState);
}
//---------------------------------------------------------------------------------------
static function int GetValueHiddenReserves()
{
	return default.HiddenReservesBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateQuidProQuoTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_QuidProQuo');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateQuidProQuo;
	Template.OnDeactivatedFn = DeactivateQuidProQuo;
	Template.GetMutatorValueFn = GetValueQuidProQuo;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateQuidProQuo(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_BlackMarket BlackMarket;

	BlackMarket = GetNewBlackMarketState(NewGameState);
	BlackMarket.GoodsCostPercentDiscount += default.QuidProQuoBonus[`DIFFICULTYSETTING];
	BlackMarket.UpdateForSaleItemDiscount();
}
//---------------------------------------------------------------------------------------
static function DeactivateQuidProQuo(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_BlackMarket BlackMarket;

	BlackMarket = GetNewBlackMarketState(NewGameState);
	BlackMarket.GoodsCostPercentDiscount = 0;
	BlackMarket.UpdateForSaleItemDiscount();
}
//---------------------------------------------------------------------------------------
static function int GetValueQuidProQuo()
{
	return default.QuidProQuoBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateUnderTheTableTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_UnderTheTable');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateUnderTheTable;
	Template.OnDeactivatedFn = DeactivateUnderTheTable;
	Template.GetMutatorValueFn = GetValueUnderTheTable;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateUnderTheTable(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_BlackMarket BlackMarket;

	BlackMarket = GetNewBlackMarketState(NewGameState);
	BlackMarket.BuyPricePercentIncrease += default.UnderTheTableBonus[`DIFFICULTYSETTING];
}
//---------------------------------------------------------------------------------------
static function DeactivateUnderTheTable(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_BlackMarket BlackMarket;

	BlackMarket = GetNewBlackMarketState(NewGameState);
	BlackMarket.BuyPricePercentIncrease = 0;
}
//---------------------------------------------------------------------------------------
static function int GetValueUnderTheTable()
{
	return default.UnderTheTableBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateHelpingHandTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_HelpingHand');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateHelpingHand;
	Template.OnDeactivatedFn = DeactivateHelpingHand;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateHelpingHand(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bExtraEngineer = true;
}
//---------------------------------------------------------------------------------------
static function DeactivateHelpingHand(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bExtraEngineer = false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateSparePartsTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_SpareParts');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateSpareParts;
	Template.OnDeactivatedFn = DeactivateSpareParts;
	Template.GetMutatorValueFn = GetValueSpareParts;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateSpareParts(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.ProvingGroundPercentDiscount = default.SparePartsBonus[`DIFFICULTYSETTING];
}
//---------------------------------------------------------------------------------------
static function DeactivateSpareParts(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.ProvingGroundPercentDiscount = 0;
}
//---------------------------------------------------------------------------------------
static function int GetValueSpareParts()
{
	return default.SparePartsBonus[`DIFFICULTYSETTING];
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateSuitUpTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_SuitUp');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateSuitUp;
	Template.OnDeactivatedFn = DeactivateSuitUp;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateSuitUp(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom ProvingGround;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ProvingGroundProject;
	local StateObjectReference ProjectRef;

	History = `XCOMHISTORY;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bInstantArmors = true;

	// Check if there are any current weapon projects, and set it to complete immediately
	if (XComHQ.HasFacilityByName('ProvingGround'))
	{
		ProvingGround = XComHQ.GetFacilityByName('ProvingGround');
		foreach ProvingGround.BuildQueue(ProjectRef)
		{
			ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(ProjectRef.ObjectID));
			TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
			if (TechState.GetMyTemplate().bArmor)
			{
				ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectProvingGround', ProvingGroundProject.ObjectID));
				NewGameState.AddStateObject(ProvingGroundProject);
				ProvingGroundProject.CompletionDateTime = `STRATEGYRULES.GameTime;
			}
		}
	}
}
//---------------------------------------------------------------------------------------
static function DeactivateSuitUp(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bInstantArmors = false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateFireWhenReadyTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_FireWhenReady');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateFireWhenReady;
	Template.OnDeactivatedFn = DeactivateFireWhenReady;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateFireWhenReady(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom ProvingGround;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ProvingGroundProject;
	local StateObjectReference ProjectRef;

	History = `XCOMHISTORY;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bInstantRandomWeapons = true;

	// Check if there are any current weapon projects, and set it to complete immediately
	if (XComHQ.HasFacilityByName('ProvingGround'))
	{
		ProvingGround = XComHQ.GetFacilityByName('ProvingGround');
		foreach ProvingGround.BuildQueue(ProjectRef)
		{
			ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(ProjectRef.ObjectID));
			TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
			if (TechState.GetMyTemplate().bRandomWeapon)
			{
				ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectProvingGround', ProvingGroundProject.ObjectID));
				NewGameState.AddStateObject(ProvingGroundProject);
				ProvingGroundProject.CompletionDateTime = `STRATEGYRULES.GameTime;
			}
		}
	}
}
//---------------------------------------------------------------------------------------
static function DeactivateFireWhenReady(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bInstantRandomWeapons = false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateLockAndLoadTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_LockAndLoad');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateLockAndLoad;
	Template.OnDeactivatedFn = DeactivateLockAndLoad;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateLockAndLoad(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bReuseUpgrades = true;
}
//---------------------------------------------------------------------------------------
static function DeactivateLockAndLoad(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bReuseUpgrades = false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateArmedToTheTeethTemplate()
{
	local X2GameplayMutatorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', Template, 'ContinentBonus_ArmedToTheTeeth');
	Template.Category = "ContinentBonus";
	Template.OnActivatedFn = ActivateArmedToTheTeeth;
	Template.OnDeactivatedFn = DeactivateArmedToTheTeeth;

	return Template;
}
//---------------------------------------------------------------------------------------
static function ActivateArmedToTheTeeth(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bExtraWeaponUpgrade = true;
}
//---------------------------------------------------------------------------------------
static function DeactivateArmedToTheTeeth(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(NewGameState);
	XComHQ.bExtraWeaponUpgrade = false;
}

//#############################################################################################
//----------------   HELPER FUNCTIONS  --------------------------------------------------------
//#############################################################################################

static function XComGameState_HeadquartersXCom GetNewXComHQState(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom NewXComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', NewXComHQ)
	{
		break;
	}

	if (NewXComHQ == none)
	{
		NewXComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', NewXComHQ.ObjectID));
		NewGameState.AddStateObject(NewXComHQ);
	}

	return NewXComHQ;
}

static function XComGameState_HeadquartersResistance GetNewResHQState(XComGameState NewGameState)
{
	local XComGameState_HeadquartersResistance NewResHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', NewResHQ)
	{
		break;
	}

	if (NewResHQ == none)
	{
		NewResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		NewResHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', NewResHQ.ObjectID));
		NewGameState.AddStateObject(NewResHQ);
	}

	return NewResHQ;
}

static function XComGameState_BlackMarket GetNewBlackMarketState(XComGameState NewGameState)
{
	local XComGameState_BlackMarket NewBlackMarket;

	foreach NewGameState.IterateByClassType(class'XComGameState_BlackMarket', NewBlackMarket)
	{
		break;
	}

	if (NewBlackMarket == none)
	{
		NewBlackMarket = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
		NewBlackMarket = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', NewBlackMarket.ObjectID));
		NewGameState.AddStateObject(NewBlackMarket);
	}

	return NewBlackMarket;
}