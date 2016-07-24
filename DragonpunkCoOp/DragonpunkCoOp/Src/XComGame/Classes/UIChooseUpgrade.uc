//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChooseUpgrade
//  AUTHOR:  Brian Whitman - 11/1/2015
//  PURPOSE: This file controls the game side of the choose an upgrade for a facility screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChooseUpgrade extends UIScreen
	dependson(XGBuildUI);

// UI
var UIX2PanelHeader  m_Title;
var UIList m_List;
var UINavigationHelp m_HelpBar;

// Game
var int SelectedIndex;
var StateObjectReference m_FacilityRef;
var array<X2FacilityUpgradeTemplate> m_arrUpgrades;

// Text
var localized string m_strTitle;
var localized string m_strListLabel;
var localized string m_strRequirementsLabel;
var localized string m_strPowerLabel;
var localized string m_strInsufficientSupplies;
var localized string m_strInsufficientItems;
var localized string m_strInsufficientPowerWarning;
var localized string m_strInsufficientStaffing;
var localized string m_strUpkeepCostLabel;
var localized string m_strUpgradeButton;

var X2FacilityUpgradeTemplate m_selectedUpgrade;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen( InitController, InitMovie, InitName );

	// UI
	m_Title = Spawn(class'UIX2PanelHeader', self).InitPanelHeader(, m_strTitle);

	m_List = Spawn(class'UIList', self).InitList(, 260, 820, 456, 238);
	m_List.OnItemDoubleClicked = ConfirmSelection;
	m_List.OnSelectionChanged = UpdateSelection;
	//m_List.bCenterNoScroll = true;

	AS_SetHeaders(m_strListLabel, m_strRequirementsLabel);

	m_HelpBar = Spawn(class'UINavigationHelp', self).InitNavHelp();
	m_HelpBar.AddBackButton(OnCancel);

	PopulateList();
}

simulated function SetFacility(StateObjectReference FacilityRef)
{
	m_FacilityRef = FacilityRef;
	RefreshAvailableUpgrades();	

	//TODO(bwhitman): enable when we add the update effect (if its a hologram)
	//`XSTRATEGYSOUNDMGR.PlaySoundEvent("Facility_Select_Hologram_Loop"); // Play the hologram looping sound
}


simulated function RefreshAvailableUpgrades()
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_FacilityUpgrade FacilityUpgrade;
	local array<X2FacilityUpgradeTemplate> FacilityUpgrades;
	local int i;
	
	m_arrUpgrades.Length = 0;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(m_FacilityRef.ObjectID));
	FacilityUpgrades = Facility.GetBuildableUpgrades();

	for(i = 0; i < FacilityUpgrades.Length; i++)
	{
		m_arrUpgrades.AddItem(FacilityUpgrades[i]);
	}

	m_arrUpgrades.Sort(SortByCanBuild);
	m_arrUpgrades.Sort(SortByPriority);

	// Completed upgrades
	for(i = 0; i < Facility.Upgrades.Length; i++)
	{
		FacilityUpgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(Facility.Upgrades[i].ObjectID));
		m_arrUpgrades.AddItem(FacilityUpgrade.GetMyTemplate());
	}
}

simulated function int SortByCanBuild(X2FacilityUpgradeTemplate A, X2FacilityUpgradeTemplate B)
{
	if(CanBuildUpgrade(A) && !CanBuildUpgrade(B)) return 1;
	else if(CanBuildUpgrade(B) && !CanBuildUpgrade(A)) return -1;
	return 0;
}

function int SortByPriority(X2FacilityUpgradeTemplate UpgradeTemplateA, X2FacilityUpgradeTemplate UpgradeTemplateB)
{
	if (UpgradeTemplateA.bPriority && !UpgradeTemplateB.bPriority)
	{
		return 1;
	}
	else if (!UpgradeTemplateA.bPriority && UpgradeTemplateB.bPriority)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

simulated function bool CanBuildUpgrade(X2FacilityUpgradeTemplate UpgradeTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ.MeetsRequirmentsAndCanAffordCost(UpgradeTemplate.Requirements, UpgradeTemplate.Cost, XComHQ.FacilityUpgradeCostScalars);
}

simulated function bool UpgradeAlreadyPerformed(X2FacilityUpgradeTemplate UpgradeTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_FacilityUpgrade FacilityUpgrade;
	local int i;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(m_FacilityRef.ObjectID));
	for(i = 0; i < Facility.Upgrades.Length; i++)
	{
		FacilityUpgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(Facility.Upgrades[i].ObjectID));
		if (FacilityUpgrade.GetMyTemplate() == UpgradeTemplate)
		return true;
	}

	return false;
}

simulated function bool HasEnoughPower(X2FacilityUpgradeTemplate UpgradeTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local bool HasPower;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(m_FacilityRef.ObjectID));

	if (UpgradeTemplate.iPower >= 0 || FacilityState.GetRoom().HasShieldedPowerCoil())
	{
		HasPower = true;
	}
	else
	{
		HasPower = ((XComHQ.GetPowerConsumed() - UpgradeTemplate.iPower) <= XComHQ.GetPowerProduced());
	}

	return HasPower;
}

function int GetPowerRequirement(X2FacilityUpgradeTemplate UpgradeTemplate)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	local int power;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(m_FacilityRef.ObjectID));
	
	if (FacilityState.BuiltOnPowerCell())
	{
		//Building a generator, so power is doubled when on top of power coil
		if (UpgradeTemplate.iPower > 0) 
		{
			power = UpgradeTemplate.iPower + class'UIUtilities_Strategy'.static.GetXComHQ().PowerRelayOnCoilBonus[`DIFFICULTYSETTING];
		}
		else
		{
			power = 0;
		}
	}
	else
	{
		power = UpgradeTemplate.iPower;
	}

	return power;
}

//------------------------------------------------------

simulated function PopulateList()
{	
	local int i;
	local UIListItemString Item;

	for (i = 0; i < m_arrUpgrades.length; ++i) 
	{
		Item = UIListItemString(m_List.GetItem(i));
		if( Item == none )
		{
			Item = UIListItemString(m_List.CreateItem()).InitListItem();
			Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, m_strUpgradeButton);
		}

		Item.SetText(m_arrUpgrades[i].DisplayName);
		Item.NeedsAttention(m_arrUpgrades[i].bPriority);
		Item.SetDisabled(UpgradeAlreadyPerformed(m_arrUpgrades[i]) || !HasEnoughPower(m_arrUpgrades[i]) || !CanBuildUpgrade(m_arrUpgrades[i]));
	}

	if(m_List.ItemCount > 0)
		m_List.SetSelectedIndex(0);
}

simulated function UpdateSelection(UIList list, int itemIndex)
{
	local int power;
	local string Summary, Requirements, StratReqs, InsufficientResourcesWarning, DividerHTML, UpkeepCostStr;
	local bool HasPower, AlreadyUpgraded;

	DividerHTML = "<font color='#546f6f'> | </font>";
	
	SelectedIndex = itemIndex;
	m_selectedUpgrade = m_arrUpgrades[SelectedIndex];
	HasPower = HasEnoughPower(m_selectedUpgrade); 
	AlreadyUpgraded = UpgradeAlreadyPerformed(m_selectedUpgrade);

	// Supplies Requirement
	Requirements $= class'UIUtilities_Strategy'.static.GetStrategyCostString(m_selectedUpgrade.Cost, `XCOMHQ.FacilityBuildCostScalars);

	// Power Requirement
	Requirements $= DividerHTML;
	power = GetPowerRequirement(m_selectedUpgrade);
	if (HasPower || AlreadyUpgraded)
	{
		if (power >= 0) //Building a power generator, or facility on top of a power coil
			Requirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText(string(power), eUIState_Good);
		else
			Requirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText(string(int(Abs(power))), eUIState_Warning);
	}
	else
	{
		Requirements $= class'UIUtilities_Text'.static.InjectImage("power_icon_warning") $ class'UIUtilities_Text'.static.GetColoredText(string(int(Abs(power))), eUIState_Warning);
	}
	
	// All other strategy requirements
	StratReqs = class'UIUtilities_Strategy'.static.GetStrategyReqString(m_selectedUpgrade.Requirements);
	if (StratReqs != "")
	{
		Requirements $= DividerHTML;
		Requirements $= StratReqs;
	}

	if (!HasPower && !AlreadyUpgraded)
	{
		if (InsufficientResourcesWarning != "")
			InsufficientResourcesWarning $= ", ";

		InsufficientResourcesWarning @= class'UIUtilities_Text'.static.GetColoredText(m_strInsufficientPowerWarning, eUIState_Bad);
	}
	

	//TODO(bwhitman): enable when we add the update effect (if its a hologram)
	//`HQPRES.SetFacilityBuildPreviewVisibility(RoomState.MapIndex, m_selectedUpgrade.DataName, true);

	Summary = m_selectedUpgrade.Summary;

	if (m_selectedUpgrade.UpkeepCost > 0)
	{
		UpkeepCostStr = m_strUpkeepCostLabel @ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ m_selectedUpgrade.UpkeepCost;
		UpkeepCostStr = class'UIUtilities_Text'.static.GetColoredText(UpkeepCostStr, eUIState_Warning);
		Summary $= "\n\n" $ UpkeepCostStr;
	}

	if(Summary == "")
		Summary = "Missing 'strSummary' for facility template '" $ m_selectedUpgrade.DataName $ "'.";

	AS_SetDescription(Summary, InsufficientResourcesWarning);
	AS_SetResources(Requirements, "");
}

simulated function ConfirmSelection(UIList list, int itemIndex)
{
	OnAccept();
}

//------------------------------------------------------

simulated function OnBuildButtonClicked(UIButton Button)
{
	OnAccept();
}

simulated function StartUpgradeFacility()
{
	local XComGameState NewGameState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local XComNarrativeMoment UpgradeNarrative;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	UpgradeTemplate = m_arrUpgrades[SelectedIndex];

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Start Facility Upgrade");
	
	UpgradeState = UpgradeTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(UpgradeState);

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.PayStrategyCost(NewGameState, UpgradeState.GetMyTemplate().Cost, XComHQ.FacilityUpgradeCostScalars);
			
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', m_FacilityRef.ObjectID));
	NewGameState.AddStateObject(FacilityState);
	FacilityState.Upgrades.AddItem(UpgradeState.GetReference());

	UpgradeState.Facility = m_FacilityRef;
	UpgradeState.OnUpgradeAdded(NewGameState, FacilityState);

	`XEVENTMGR.TriggerEvent('UpgradeCompleted', UpgradeState, FacilityState, NewGameState);

	if (FacilityState.GetMyTemplate().FacilityUpgradedNarrative != "")
	{
		UpgradeNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityState.GetMyTemplate().FacilityUpgradedNarrative));
		if (UpgradeNarrative != None)
		{
			`HQPRES.UINarrative(UpgradeNarrative);
		}
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Facility_Upgrade");

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();

	RefreshAvailableUpgrades();
	PopulateList();
	
	// Refresh XComHQ and see if we need to display a power warning
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.PowerState == ePowerState_Red && FacilityState.GetPowerOutput() < 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Warning No Power");
		`XEVENTMGR.TriggerEvent('WarningNoPower', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

simulated function OnAccept()
{
	if (!UpgradeAlreadyPerformed(m_arrUpgrades[SelectedIndex]) && HasEnoughPower(m_arrUpgrades[SelectedIndex]) && CanBuildUpgrade(m_arrUpgrades[SelectedIndex]))
	{
		StartUpgradeFacility();
		CloseScreen();		
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated function OnCancel()
{	
	CloseScreen();
}

simulated function CloseScreen()
{
	super.CloseScreen();
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function AS_SetHeaders(string listHeader, string descriptionHeader)
{
	MC.BeginFunctionOp("setHeaders");
	MC.QueueString(listHeader);
	MC.QueueString(descriptionHeader);
	MC.EndOp();
}

simulated function AS_SetDescription(string description, string warning)
{
	MC.BeginFunctionOp("setDescription");
	MC.QueueString(description);
	MC.QueueString(warning);
	MC.EndOp();
}

simulated function AS_SetResources(string resources, string timeValue)
{
	MC.BeginFunctionOp("setResources");
	MC.QueueString(resources);
	MC.QueueString("");
	MC.QueueString(timeValue);
	MC.EndOp();
}

//------------------------------------------------------

DefaultProperties
{
	Package = "/ package/gfxChooseFacility/ChooseFacility";
}
