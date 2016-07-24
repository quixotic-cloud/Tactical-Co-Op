//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChooseFacility
//  AUTHOR:  Brit Steiner --  10/26/11
//  PURPOSE: This file controls the game side of the choosea facility screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChooseFacility extends UIScreen
	dependson(XGBuildUI);

// UI
var UIX2PanelHeader  m_Title;
var UIList m_List;
var UINavigationHelp m_HelpBar;

// Game
var int SelectedIndex;
var StateObjectReference m_RoomRef; // set in XComHQPresentationLayer
var StateObjectReference m_UnitRef; // used when reassigning staff
var array<X2FacilityTemplate> m_arrFacilities;

// Text
var localized string m_strTitle;
var localized string m_strListLabel;
var localized string m_strRequirementsLabel;
var localized string m_strPowerLabel;
var localized string m_strInsufficientSupplies;
var localized string m_strInsufficientItems;
var localized string m_strBuildButtonLabel;
var localized string m_strInsufficientPowerWarning;
var localized string m_strInsufficientStaffing;
var localized string m_strPowerCoilBenefitDouble;
var localized string m_strPowerCoilBenefitNoPower;
var localized string m_strUpkeepCostLabel;
var localized string m_strBuildButton;
var localized string m_strTimeLabel;

var X2FacilityTemplate m_selectedFacility;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom RoomState;
	
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

	// Game
	m_arrFacilities = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetBuildableFacilityTemplates();
	m_arrFacilities.Sort(SortFacilities);
	m_arrFacilities.Sort(SortByPriority);
	
	PopulateList();

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Facility_Select_Hologram_Loop"); // Play the hologram looping sound

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.PowerState == ePowerState_Red)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Warning No Power");
		`XEVENTMGR.TriggerEvent('WarningNoPowerAI', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(m_RoomRef.ObjectID));
	if (RoomState.HasShieldedPowerCoil() && !XComHQ.bHasSeenPowerCoilShieldedPopup)
	{
		`HQPRES.UIPowerCoilShielded();
	}
}

simulated function int SortFacilities(X2FacilityTemplate A, X2FacilityTemplate B)
{
	if(CanBuildFacility(A) && !CanBuildFacility(B)) return 1;
	else if(CanBuildFacility(B) && !CanBuildFacility(A)) return -1;
	return 0;
}

function int SortByPriority(X2FacilityTemplate FacilityTemplateA, X2FacilityTemplate FacilityTemplateB)
{
	if(FacilityTemplateA.bPriority && !FacilityTemplateB.bPriority)
	{
		return 1;
	}
	else if(!FacilityTemplateA.bPriority && FacilityTemplateB.bPriority)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

simulated function bool CanBuildFacility(X2FacilityTemplate Facility)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ.MeetsRequirmentsAndCanAffordCost(Facility.Requirements, Facility.Cost, XComHQ.FacilityBuildCostScalars) && HasEnoughPower(Facility) && HasEnoughStaffing(Facility);
}

simulated function bool CanBuildInRoom(StateObjectReference RoomRef)
{
	local XComGameState_HeadquartersRoom RoomState;

	RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));
	return !RoomState.UnderConstruction;
}

simulated function bool HasEnoughPower(X2FacilityTemplate Facility)
{
	local XComGameStateHistory History;
	local int TotalPower;
	local int CurrentPower;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	CurrentPower = XComHQ.GetPowerConsumed();
	TotalPower = XComHQ.GetPowerProduced();

	if (Facility.iPower > 0)
	{
		return true; //Building a power generator, so no power cost
	}
	else
	{
		return ((CurrentPower + Abs(Facility.iPower)) <= TotalPower ||
			XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(m_RoomRef.ObjectID)).HasShieldedPowerCoil());
	}
}
simulated function string GetBuildTime(X2FacilityTemplate Facility)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return XComHQ.GetFacilityBuildEstimateString(m_RoomRef, Facility); 
}

simulated function bool HasEnoughStaffing(X2FacilityTemplate Facility)
{
	local int ScienceReq, EngineeringReq;

	if (Facility.CalculateStaffingRequirementFn != None)
	{
		Facility.CalculateStaffingRequirementFn(Facility, ScienceReq, EngineeringReq);

		if(`XCOMHQ.GetEngineeringScore(true) >= EngineeringReq &&
		   `XCOMHQ.GetScienceScore(true) >= ScienceReq)
		{
			return true;
		}

		return false;
	}
	
	return true;
}

function int GetPowerRequirement(X2FacilityTemplate selectedFacility)
{
	local XComGameStateHistory History;
	local int power;

	History = `XCOMHISTORY;
		
	if (XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(m_RoomRef.ObjectID)).HasShieldedPowerCoil())
	{
		if (selectedFacility.iPower > 0) //Building a generator, so power is doubled when on top of power coil
		{
			power = selectedFacility.iPower + class'UIUtilities_Strategy'.static.GetXComHQ().PowerRelayOnCoilBonus[`DIFFICULTYSETTING];
		}
		else
		{
			power = 0;
		}
	}
	else
	{
		power = selectedFacility.iPower;
	}

	return power;
}

//------------------------------------------------------

simulated function PopulateList()
{	
	local int i;
	local UIListItemString Item;

	for (i = 0; i < m_arrFacilities.length; ++i) 
	{
		Item = UIListItemString(m_List.GetItem(i));
		if( Item == none )
		{
			Item = UIListItemString(m_List.CreateItem()).InitListItem();
			Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, m_strBuildButton);
		}

		Item.SetText(m_arrFacilities[i].DisplayName);
		Item.NeedsAttention(m_arrFacilities[i].bPriority);
		
		Item.SetDisabled(!CanBuildFacility(m_arrFacilities[i]));
	}

	if(m_List.ItemCount > 0)
		m_List.SetSelectedIndex(0);
}

simulated function UpdateSelection(UIList list, int itemIndex)
{
	local int power;
	local string Summary, Requirements, StratReqs, InsufficientResourcesWarning, DividerHTML, UpkeepCostStr, BuildTime;
	local bool canBuild, HasPower;
	local XComGameState_HeadquartersRoom RoomState;

	RoomState =	XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(m_RoomRef.ObjectID));

	DividerHTML = "<font color='#546f6f'> | </font>";
	
	SelectedIndex = itemIndex;
	m_selectedFacility = m_arrFacilities[SelectedIndex];
	canBuild = CanBuildFacility(m_selectedFacility);
	HasPower = HasEnoughPower(m_selectedFacility); 
	BuildTime = GetBuildTime(m_selectedFacility);

	// Supplies Requirement
	Requirements $= class'UIUtilities_Strategy'.static.GetStrategyCostString(m_selectedFacility.Cost, `XCOMHQ.FacilityBuildCostScalars);

	// Power Requirement
	Requirements $= DividerHTML;
	power = GetPowerRequirement(m_selectedFacility);
	if (HasPower)
	{
		if (power >= 0) //Building a power generator, or facility on top of a power coil
			Requirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText(string(power), eUIState_Good);
		else
			Requirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText(string(int(Abs(power))), eUIState_Warning);
	}
	else
		Requirements $= class'UIUtilities_Text'.static.InjectImage("power_icon_warning") $ class'UIUtilities_Text'.static.GetColoredText(string(int(Abs(power))), eUIState_Warning);
	
	// All other strategy requirements
	StratReqs = class'UIUtilities_Strategy'.static.GetStrategyReqString(m_selectedFacility.Requirements);
	if (StratReqs != "")
	{
		Requirements $= DividerHTML;
		Requirements $= StratReqs;
	}

	if (!canBuild)
	{
		//if (!hasSupplies)
		//	InsufficientResourcesWarning @= class'UIUtilities_Text'.static.GetColoredText(m_strInsufficientSupplies, eUIState_Bad);
		//
		//if (!hasItems)
		//{
		//	if (InsufficientResourcesWarning != "")
		//		InsufficientResourcesWarning $= ", ";
		//
		//	InsufficientResourcesWarning @= class'UIUtilities_Text'.static.GetColoredText(m_strInsufficientItems, eUIState_Bad);
		//}

		if (!HasPower)
		{
			if (InsufficientResourcesWarning != "")
				InsufficientResourcesWarning $= ", ";

			InsufficientResourcesWarning @= class'UIUtilities_Text'.static.GetColoredText(m_strInsufficientPowerWarning, eUIState_Bad);
		}
	}
	

	`HQPRES.SetFacilityBuildPreviewVisibility(RoomState.MapIndex, m_selectedFacility.DataName, true);

	Summary = m_selectedFacility.Summary;

	if (RoomState.HasShieldedPowerCoil())
	{
		if (power > 0)
			Summary $= "\n\n" $ class'UIUtilities_Text'.static.GetColoredText(m_strPowerCoilBenefitDouble, eUIState_Good);
		else
			Summary $= "\n\n" $ class'UIUtilities_Text'.static.GetColoredText(m_strPowerCoilBenefitNoPower, eUIState_Good);
	}

	if (m_selectedFacility.UpkeepCost > 0)
	{
		UpkeepCostStr = m_strUpkeepCostLabel @ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ m_selectedFacility.UpkeepCost;
		UpkeepCostStr = class'UIUtilities_Text'.static.GetColoredText(UpkeepCostStr, eUIState_Warning);
		Summary $= "\n\n" $ UpkeepCostStr;
	}

	if(Summary == "")
		Summary = "Missing 'strSummary' for facility template '" $ m_selectedFacility.DataName $ "'.";

	AS_SetDescription(Summary, InsufficientResourcesWarning);
	AS_SetResources(Requirements, BuildTime);
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

simulated function OnAccept()
{
	if (CanBuildFacility(m_arrFacilities[SelectedIndex]) && CanBuildInRoom(m_RoomRef) )
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().AddFacilityProject(m_RoomRef, m_arrFacilities[SelectedIndex]);
		CloseScreen();		
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function OnCancel()
{	
	local XComGameState_HeadquartersRoom RoomState;
	RoomState =	XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(m_RoomRef.ObjectID));

	`HQPRES.SetFacilityBuildPreviewVisibility(RoomState.MapIndex, m_selectedFacility.DataName, false);

	CloseScreen();
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_Facility_Select_Hologram_Loop"); // Stop the hologram looping sound
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	super.CloseScreen();
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
	MC.QueueString(m_strTimeLabel);
	MC.QueueString(timeValue);
	MC.EndOp();
}

//------------------------------------------------------

DefaultProperties
{
	Package = "/ package/gfxChooseFacility/ChooseFacility";
}
