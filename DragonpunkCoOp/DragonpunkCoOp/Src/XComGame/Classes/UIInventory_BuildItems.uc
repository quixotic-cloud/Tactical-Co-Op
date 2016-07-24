//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventory_Manufacture.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Screen where players select items to add to the build queue.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIInventory_BuildItems extends UIInventory
	dependson(UIButton) config(GameData);

enum EUIItemType
{
	eUIItemType_Misc,
	eUIItemType_Weapon,
	eUIItemType_Armor,
	eUIItemType_MAX
};

var int SelectedTab;

var public localized string m_strWeaponTab;
var public localized string m_strArmorTab;
var public localized string m_strMiscTab;
var public localized string m_strBuiltLabel;
var public localized string ConfirmInstantBuild;
var public localized string ConfirmBuildTime;

var array<UIButton> TabButtons;

var UIText ItemCategory;

var array<X2ItemTemplate> ListData;
var array<X2ItemTemplate> WeaponItems;
var array<X2ItemTemplate> ArmorItems;
var array<X2ItemTemplate> MiscItems;

var config name WelcomeEngineeringObjective;
var config name TutorialBuildItem;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	PopulateGameData();
	OpenScreenEvent();

	// Move and resize list to accommodate label
	List.OnItemDoubleClicked = ManufactureItem;

	// Built Label
	SetBuiltLabel(class'UIUtilities_Text'.static.GetColoredText(m_strBuiltLabel, eUIState_Header));
		
	// Create Tab Buttons
	TabButtons[eUIItemType_Weapon] = CreateTabButton(eUIItemType_Weapon, m_strWeaponTab, WeaponTab, WeaponItems.Length == 0);
	TabButtons[eUIItemType_Armor] = CreateTabButton(eUIItemType_Armor, m_strArmorTab, ArmorTab, ArmorItems.Length == 0);
	TabButtons[eUIItemType_Misc] = CreateTabButton(eUIItemType_Misc, m_strMiscTab, MiscTab, MiscItems.Length == 0);
	
	SwitchTab(eUIItemType_Misc);
	PopulateItemCard(MiscItems[0]);

	SetBuildItemLayout();

	HideQueue();
}

simulated function OpenScreenEvent()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Open Build Items Event");
	`XEVENTMGR.TriggerEvent('OpenBuildItems', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

simulated function CloseScreen()
{
	Super.CloseScreen();

	ShowQueue(true);
}

simulated function UpdateNavHelp()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	if(CanBackOut())
	{
		`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
	}
}

simulated function UIButton CreateTabButton(int Index, string Text, delegate<UIButton.OnClickedDelegate> ButtonClickedDelegate, bool IsDisabled)
{
	local UIButton TabButton;

	TabButton = Spawn(class'UIButton', self);
	TabButton.InitButton(Name("inventoryTab" $ Index), "", ButtonClickedDelegate);
	TabButton.MC.FunctionString( "populateData", Text );//special formating in flash
	TabButton.SetWidth( 198 );
	TabButton.SetDisabled(IsDisabled);
	TabButton.Show();

	return TabButton;
}

// Called every time a tab is switched
simulated function PopulateData()
{
	local int Quantity;
	local X2ItemTemplate ItemTemplate;
	local StateObjectReference ItemRef, UnitRef, EmptyRef;
	local XComGameState_Item Item;
	local XComGameState_Unit UnitState;

	super.PopulateData();

	foreach ListData(ItemTemplate)
	{
		Quantity = 0;

		foreach XComHQ.Inventory(ItemRef)
		{
			Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
			if(Item.GetMyTemplateName() == ItemTemplate.DataName)
			{
				Quantity += Item.Quantity;
			}
		}

		foreach XComHQ.Crew(UnitRef)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

			if(UnitState != none)
			{
				ItemRef = EmptyRef;
				foreach UnitState.InventoryItems(ItemRef)
				{
					Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
					if(Item.GetMyTemplateName() == ItemTemplate.DataName)
					{
						Quantity += Item.Quantity;
					}
				}
			}
		}

		Spawn(class'UIInventory_ListItem', List.itemContainer)
		.InitInventoryListItem(ItemTemplate, Quantity, , GetConfirmItemString(ItemTemplate), , 50)
		.NeedsAttention(InWelcomeToEngineering() && ItemTemplate.DataName == TutorialBuildItem);
	}

	if(List.ItemCount > 0)
	{
		List.SetSelectedIndex(0);
		PopulateItemCard(UIInventory_ListItem(List.GetItem(0)).ItemTemplate);
		TitleHeader.SetText(m_strTitle, "");
	}
}


simulated function string GetConfirmItemString(X2ItemTemplate ItemTemplate)
{
	local int Hours;
	local string ConfirmText;

	if( ItemTemplate == none )
	{
		`RedScreen("UIInventory_BuildItems.GetConfirmString doesn't have a valid ItemTemplate. Please contact the UI team.",,'uixcom'); 
	}
	else
	{
		Hours = `XCOMHQ.GetItemBuildTime(ItemTemplate, UIFacility_Storage(Movie.Stack.GetFirstInstanceOf(class'UIFacility_Storage')).FacilityRef);
		if( Hours <= 0 )
		{
			ConfirmText = ConfirmInstantBuild; 
		}
		else
		{
			ConfirmText = Repl(ConfirmBuildTime, "%TIME", class'UIUtilities_text'.static.GetTimeRemainingString(Hours));
		}
	}

	return ConfirmText; 
}

// Called once when screen opens
simulated function PopulateGameData()
{
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2ItemTemplate> BuildableItems;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	BuildableItems = ItemTemplateManager.GetBuildableItemTemplates();

	// Destroy old data
	WeaponItems.Length = 0;
	ArmorItems.Length = 0;
	MiscItems.Length = 0;
	
	foreach BuildableItems(ItemTemplate)
	{
		if(ItemTemplateManager.BuildItemWeaponCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
			WeaponItems.AddItem(ItemTemplate);
		else if(ItemTemplateManager.BuildItemArmorCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
			ArmorItems.AddItem(ItemTemplate);
		else if(ItemTemplateManager.BuildItemMiscCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
			MiscItems.AddItem(ItemTemplate);
	}

	WeaponItems.Sort(SortItemsAlpha);
	ArmorItems.Sort(SortItemsAlpha);
	MiscItems.Sort(SortItemsAlpha);

	WeaponItems.Sort(SortItemsTier);
	ArmorItems.Sort(SortItemsTier);
	
	WeaponItems.Sort(SortItemsPriority);
	ArmorItems.Sort(SortItemsPriority);
	MiscItems.Sort(SortItemsPriority);

	WeaponItems.Sort(SortItemsAvailability);
	ArmorItems.Sort(SortItemsAvailability);
	MiscItems.Sort(SortItemsAvailability);
}

function int SortItemsPriority(X2ItemTemplate ItemTemplateA, X2ItemTemplate ItemTemplateB)
{
	if(ItemTemplateA.bPriority && !ItemTemplateB.bPriority)
	{
		return 1;
	}
	else if(!ItemTemplateA.bPriority && ItemTemplateB.bPriority)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortItemsAvailability(X2ItemTemplate ItemTemplateA, X2ItemTemplate ItemTemplateB)
{
	if (CanBuildItem(ItemTemplateA) && !CanBuildItem(ItemTemplateB))
	{
		return 1;
	}
	else if (!CanBuildItem(ItemTemplateA) && CanBuildItem(ItemTemplateB))
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortItemsTier(X2ItemTemplate ItemTemplateA, X2ItemTemplate ItemTemplateB)
{
	if (ItemTemplateA.Tier > ItemTemplateB.Tier)
	{
		return 1;
	}
	else if (ItemTemplateA.Tier < ItemTemplateB.Tier)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortItemsAlpha(X2ItemTemplate ItemTemplateA, X2ItemTemplate ItemTemplateB)
{
	if (ItemTemplateA.GetItemFriendlyName() < ItemTemplateB.GetItemFriendlyName())
	{
		return 1;
	}
	else if (ItemTemplateA.GetItemFriendlyName() > ItemTemplateB.GetItemFriendlyName())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

// Called when an item is selected
simulated function PopulateItemCard(optional X2ItemTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	super.PopulateItemCard(ItemTemplate, ItemRef);

	if( ItemTemplate != none )
		ItemCard.PopulateCostData(ItemTemplate);
}

simulated function SwitchTab( int eTab , optional bool bForce = false)
{
	if(!bForce && SelectedTab == eTab)
		return;
	
	SelectedTab = eTab;

	switch(SelectedTab)
	{
	case eUIItemType_Weapon:
		ListData = WeaponItems;
		SetCategory(class'UIUtilities_Text'.static.GetColoredText(m_strWeaponTab, eUIState_Header));
		break;
	case eUIItemType_Armor:
		ListData = ArmorItems;
		SetCategory(class'UIUtilities_Text'.static.GetColoredText(m_strArmorTab, eUIState_Header));
		break;
	case eUIItemType_Misc:
		ListData = MiscItems;
		SetCategory(class'UIUtilities_Text'.static.GetColoredText(m_strMiscTab, eUIState_Header));
		break;
	}

	PopulateData();

	SetTabHighlight(SelectedTab);
}

simulated function OnConfirmButtonClicked(UIButton Button)
{
	ManufactureItem(List, List.selectedIndex);
}

//------------------------------------------------------

simulated function ManufactureItem(UIList ContainerList, int ItemIndex)
{
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local XComGameState_FacilityXCom FacilityState;
	local X2ItemTemplate ItemTemplate;
	local UIInventory_ListItem ListItem;
	local float EngBonus;

	ItemTemplate = UIInventory_ListItem(ContainerList.GetItem(ItemIndex)).ItemTemplate;
	
	if (CanBuildItem(ItemTemplate))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Item Project");
		ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(ItemState);

		// Pay the strategy cost for the item
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		EngBonus = class'UIUtilities_Strategy'.static.GetEngineeringDiscount(ItemTemplate.Requirements.RequiredEngineeringScore);
		XComHQ.PayStrategyCost(NewGameState, ItemTemplate.Cost, XComHQ.ItemBuildCostScalars, EngBonus);
		
		if (ItemTemplate.PointsToComplete > 0)
		{
			// If the item has a build time, create a project for it
			FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom',
				UIFacility_Storage(Movie.Stack.GetFirstInstanceOf(class'UIFacility_Storage')).FacilityRef.ObjectID));
			NewGameState.AddStateObject(FacilityState);

			//Create the build item project
			ItemProject = XComGameState_HeadquartersProjectBuildItem(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectBuildItem'));
			NewGameState.AddStateObject(ItemProject);
			ItemProject.SetProjectFocus(ItemState.GetReference(), NewGameState, FacilityState.GetReference());
			ItemProject.SavedDiscountPercent = EngBonus;
			XComHQ.Projects.AddItem(ItemProject.GetReference());

			//Add build item to the queue
			FacilityState.BuildQueue.AddItem(ItemProject.GetReference());
		}
		else
		{	
			// Otherwise if it builds instantly, immediately add it to the inventory
			ItemState.OnItemBuilt(NewGameState);
			
			XComHQ.PutItemInInventory(NewGameState, ItemState);
			
			`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', ItemState, ItemState, NewGameState);

			//Refresh the list item display to reflect the new quantity
			ListItem = UIInventory_ListItem(ContainerList.GetItem(ItemIndex));
			ListItem.UpdateQuantity(ListItem.Quantity + ItemState.Quantity);
			ListItem.PopulateData();
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.HandlePowerOrStaffingChange();

		RefreshQueue();

		// Refresh here because list needs to get smaller on build of one time build item
		if(ItemTemplate.bOneTimeBuild)
		{
			PopulateGameData();
			SwitchTab(SelectedTab, true);
		}
		
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("BuildItem");
		class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();

		if(InWelcomeToEngineering())
		{
			CloseScreen();
		}
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function RefreshQueue()
{
	`HQPRES.m_kAvengerHUD.UpdateResources();

	UpdateItemAvailability();
}

simulated function UpdateItemAvailability()
{
	local int i;

	// update item availability
	for(i = 0; i < List.ItemCount; ++i)
	{
		UIInventory_ListItem(List.GetItem(i)).PopulateData(true);
	}

	PopulateItemCard(UIInventory_ListItem(List.GetFocusedItem()).ItemTemplate);
}

simulated function bool CanBuildItem(X2ItemTemplate Item)
{
	local float EngBonus;

	if(InWelcomeToEngineering() && Item.DataName != TutorialBuildItem)
	{
		return false;
	}

	EngBonus = class'UIUtilities_Strategy'.static.GetEngineeringDiscount(Item.Requirements.RequiredEngineeringScore);
	return XComHQ.MeetsRequirmentsAndCanAffordCost(Item.Requirements, Item.Cost, XComHQ.ItemBuildCostScalars, EngBonus, Item.AlternateRequirements);
}

//------------------------------------------------------

simulated function WeaponTab( UIButton Button )
{
	SwitchTab( eUIItemType_Weapon );
}
simulated function ArmorTab( UIButton Button )
{
	SwitchTab( eUIItemType_Armor );
}
simulated function MiscTab( UIButton Button )
{
	SwitchTab( eUIItemType_Misc );
}
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
}

simulated function bool InWelcomeToEngineering()
{
	return !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted(WelcomeEngineeringObjective);
}

simulated function bool CanBackOut()
{
	return !InWelcomeToEngineering();
}

simulated function OnCancel()
{
	if(!CanBackOut())
	{
		return;
	}

	super.OnCancel();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			SwitchTab(SelectedTab > 0 ? SelectedTab - 1 : eUIItemType_MAX - 1);
			break;
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			SwitchTab((SelectedTab + 1) % eUIItemType_MAX);
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


defaultproperties
{
	SelectedTab = -1;
	DisplayTag      = "UIBlueprint_BuildItems";
	CameraTag       = "UIBlueprint_BuildItems";

	InventoryListName="tabbedListMC";
}