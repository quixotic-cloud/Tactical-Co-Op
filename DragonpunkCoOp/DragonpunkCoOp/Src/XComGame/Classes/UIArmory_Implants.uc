//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_Implant.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Contains a list of slots that can contain soldier implants.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIArmory_Implants extends UIArmory
	dependson(UIUtilities_Strategy);

var XComGameState UpdateState;

var UIPanel	 ListContainer; // contains all controls bellow
var UIBGBox	 ListBG;
var UIText		 ListTitle;
var UIList		 List;
var UIPanel     DividerLine;

var int MaxImplantSlots;

simulated function InitImplants(StateObjectReference UnitRef)
{
	super.InitArmory(UnitRef);

	ListContainer = Spawn(class'UIPanel', self).InitPanel('ListContainer').SetPosition(100, 300);

	ListBG = Spawn(class'UIBGBox', ListContainer);
	ListBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	ListBG.InitBG('ListBG', 0, 0, 585, 320);

	ListTitle = Spawn(class'UIText', ListContainer).InitText('ListTitle');
	ListTitle.SetSize(500, 50).SetPosition(15, 15);

	DividerLine = Spawn(class'UIPanel', ListContainer);
	DividerLine.bIsNavigable = false;
	DividerLine.LibID = class'UIUtilities_Controls'.const.MC_GenericPixel;
	DividerLine.InitPanel('DividerLine').SetPosition(15, 55).SetWidth(560);

	List = Spawn(class'UIList', ListContainer);
	List.InitList('List', 15, 75, 555, 540);

	ListContainer.SetY(300);
	ListTitle.SetTitle(class'UIUtilities_Text'.static.GetColoredText(class'UIArmory_MainMenu'.default.m_strImplants, eUIState_Disabled));

	List.SetHeight(class'UIArmory_ImplantSlot'.default.Height * MaxImplantSlots);
	ListBG.SetHeight((List.y - ListBG.y) + List.height + 20);

	List.ClearItems();
	PopulateData();
}

simulated function PopulateData()
{
	local int i, AvailableSlots;
	local XComGameState_Unit Unit;
	local UIArmory_ImplantSlot Item;
	local array<XComGameState_Item> EquippedImplants;

	// We don't need to clear the list, or recreate the pawn here -sbatista
	//super.PopulateData();
	Unit = GetUnit();

	if(ActorPawn == none)
	{
		super.CreateSoldierPawn();
	}

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	AvailableSlots = Unit.GetCurrentStat(eStat_CombatSims);

	for(i = 0; i < MaxImplantSlots; ++i)
	{
		Item = UIArmory_ImplantSlot(List.GetItem(i));
		
		if(Item == none)
			Item = UIArmory_ImplantSlot(List.CreateItem(class'UIArmory_ImplantSlot')).InitImplantSlot(i);

		if(i < AvailableSlots && i < EquippedImplants.Length)
			Item.SetAvailable(EquippedImplants[i]);
		else if(i < AvailableSlots)
			Item.SetAvailable();
		else
			Item.SetLocked(Unit);
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Header.PopulateData();
	PopulateData();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	// DEBUG: Press Tab to rank up the soldier
	`if (`notdefined(FINAL_RELEASE))
	if(cmd == class'UIUtilities_Input'.const.FXS_KEY_TAB)
	{
		bHandled = true;
	}
	`endif
	
	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	local TPCSAvailabilityData Data;

	class'UIUtilities_Strategy'.static.GetPCSAvailability(Unit, Data);
	
	return super.CanCycleTo(Unit) && Data.bHasCombatSimsSlotsAvailable && Data.bHasAchievedCombatSimsRank && Data.bHasGTS && Data.bCanEquipCombatSims;
}

//==============================================================================

defaultproperties
{
	MaxImplantSlots = 1;
	DisplayTag = "UIBlueprint_CustomizeMenu";
	CameraTag = "UIBlueprint_CustomizeMenu";
}