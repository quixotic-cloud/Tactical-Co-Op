//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_WeaponUpgrade
//  AUTHOR:  Sam Batista
//  PURPOSE: UI for viewing and modifying weapon upgrades
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIArmory_WeaponUpgrade extends UIArmory
	dependson(UIInputDialogue)
	config(UI);

struct TUIAvailableUpgrade
{
	var XComGameState_Item Item;
	var bool bCanBeEquipped;
	var string DisabledReason; // Reason why upgrade cannot be equipped
};

var int FontSize;

var UIList ActiveList;

var UIPanel SlotsListContainer;
var UIList SlotsList;

var UIPanel UpgradesListContainer;
var UIList UpgradesList;

var StateObjectReference WeaponRef;
var XComGameState_Item UpdatedWeapon;
var XComGameState CustomizationState;
var UIArmory_WeaponUpgradeStats WeaponStats;
var UIMouseGuard_RotatePawn MouseGuard;

var Rotator DefaultWeaponRotation;

var config int CustomizationListX;
var config int CustomizationListY;
var config int CustomizationListYPadding;
var UIList CustomizeList;

var config int ColorSelectorX;
var config int ColorSelectorY;
var config int ColorSelectorWidth;
var config int ColorSelectorHeight;
var UIColorSelector ColorSelector;

var localized string m_strTitle;
var localized string m_strEmptySlot;
var localized string m_strUpgradeWeapon;
var localized string m_strSelectUpgrade;
var localized string m_strSlotsAvailable;
var localized string m_strSlotsLocked;
var localized string m_strCost;
var localized string m_strWeaponFullyUpgraded;
var localized string m_strInvalidUpgrade;
var localized string m_strRequiresContinentBonus;
var localized string m_strConfirmDialogTitle;
var localized string m_strConfirmDialogDescription;
var localized string m_strReplaceUpgradeTitle;
var localized string m_strReplaceUpgradeText;
var localized string m_strUpgradeAvailable;
var localized string m_strNoUpgradeAvailable;
var localized string m_strWeaponNotEquipped;
var localized string m_strWeaponEquippedOn;
var localized string m_strCustomizeWeaponTitle;
var localized string m_strCustomizeWeaponName;

simulated function InitArmory(StateObjectReference UnitOrWeaponRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	super.InitArmory(UnitOrWeaponRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	`HQPRES.CAMLookAtNamedLocation( CameraTag, 0 );

	FontSize = bIsIn3D ? class'UIUtilities_Text'.const.BODY_FONT_SIZE_3D : class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D;
	
	SlotsListContainer = Spawn(class'UIPanel', self);
	SlotsListContainer.bAnimateOnInit = false;
	SlotsListContainer.InitPanel('leftPanel');
	SlotsList = class'UIArmory_Loadout'.static.CreateList(SlotsListContainer);
	SlotsList.OnChildMouseEventDelegate = OnListChildMouseEvent;
	SlotsList.OnSelectionChanged = PreviewUpgrade;
	SlotsList.OnItemClicked = OnItemClicked;

	CustomizeList = Spawn(class'UIList', SlotsListContainer);
	CustomizeList.ItemPadding = 5;
	CustomizeList.bStickyHighlight = false;
	CustomizeList.InitList('customizeListMC');
	CustomizeList.AddOnInitDelegate(UpdateCustomization);

	UpgradesListContainer = Spawn(class'UIPanel', self);
	UpgradesListContainer.bAnimateOnInit = false;
	UpgradesListContainer.InitPanel('rightPanel');
	UpgradesList = class'UIArmory_Loadout'.static.CreateList(UpgradesListContainer);
	UpgradesList.OnChildMouseEventDelegate = OnListChildMouseEvent;
	UpgradesList.OnSelectionChanged = PreviewUpgrade;
	UpgradesList.OnItemClicked = OnItemClicked;

	Navigator.RemoveControl(UpgradesList);

	WeaponStats = Spawn(class'UIArmory_WeaponUpgradeStats', self).InitStats('weaponStatsMC', WeaponRef);

	if(GetUnit() != none)
		WeaponRef = GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference();
	else
		WeaponRef = UnitOrWeaponRef;

	SetWeaponReference(WeaponRef);

	`XCOMGRI.DoRemoteEvent(EnableWeaponLightingEvent);

	MouseGuard = UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn'));
	MouseGuard.OnMouseEventDelegate = OnMouseGuardMouseEvent;
	MouseGuard.SetActorPawn(none, DefaultWeaponRotation);
}

simulated function OnInit()
{
	super.OnInit();
	SetTimer(0.01f, true, nameof(InterpolateWeapon));
}

// Override the soldier cycling behavior since we don't want to spawn soldier pawns on previous armory screens
simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local int i;
	local UIArmory ArmoryScreen;
	local UIArmory_WeaponUpgrade UpgradeScreen;
	local UIScreenStack ScreenStack;
	local Rotator CachedRotation;

	ScreenStack = `SCREENSTACK;

	// Update the weapon in the WeaponUpgrade screen
	UpgradeScreen = UIArmory_WeaponUpgrade(ScreenStack.GetScreen(class'UIArmory_WeaponUpgrade'));
	
	// Close the color selector before switching weapons (canceling any changes not yet confirmed)
	if(UpgradeScreen.ColorSelector != none)
		UpgradeScreen.CloseColorSelector(true);

	if( UpgradeScreen.ActorPawn != none )
		CachedRotation = UpgradeScreen.ActorPawn.Rotation;

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			ArmoryScreen.ReleasePawn();
			ArmoryScreen.SetUnitReference(NewRef);
			ArmoryScreen.Header.UnitRef = NewRef;
		}
	}

	UpgradeScreen.SetWeaponReference(UpgradeScreen.GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference());

	if(UpgradeScreen.ActorPawn != none)
		UpgradeScreen.ActorPawn.SetRotation(CachedRotation);
}

simulated function SetWeaponReference(StateObjectReference NewWeaponRef)
{
	local XComGameState_Item Weapon;

	if(CustomizationState != none)
		SubmitCustomizationChanges();

	WeaponRef = NewWeaponRef;
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	SetWeaponName(Weapon.GetMyTemplate().GetItemFriendlyName());
	CreateWeaponPawn(Weapon);
	DefaultWeaponRotation = ActorPawn.Rotation;

	ChangeActiveList(SlotsList, true);
	UpdateOwnerSoldier();
	UpdateSlots();

	if(CustomizeList.bIsInited)
		UpdateCustomization(none);

	MC.FunctionVoid("animateIn");
}

simulated function UpdateOwnerSoldier()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;

	History = `XCOMHISTORY;
	Weapon = XComGameState_Item(History.GetGameStateForObjectID(WeaponRef.ObjectID));
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(Weapon.OwnerStateObject.ObjectID));

	if(Unit != none)
		SetEquippedText(m_strWeaponEquippedOn, Unit.GetName(eNameType_Full));
	else
		SetEquippedText(m_strWeaponNotEquipped, "");
}

simulated function UpdateSlots()
{
	local XGParamTag LocTag;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Weapon;
	local int i, SlotsAvailable, NumUpgradeSlots;
	local array<X2WeaponUpgradeTemplate> EquippedUpgrades;
	local string EquipSlotLockedStr;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	LocTag.StrValue0 = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Weapon.GetMyTemplate().GetItemFriendlyName(Weapon.ObjectID));

	// Get equipped upgrades
	EquippedUpgrades = Weapon.GetMyWeaponUpgradeTemplates();
	NumUpgradeSlots = X2WeaponTemplate(Weapon.GetMyTemplate()).NumUpgradeSlots;

	if (XComHQ.bExtraWeaponUpgrade)
		NumUpgradeSlots++;

	SlotsAvailable = NumUpgradeSlots - EquippedUpgrades.Length;

	SetAvailableSlots(class'UIUtilities_Text'.static.GetColoredText(m_strSlotsAvailable, eUIState_Disabled, 26),
					  class'UIUtilities_Text'.static.GetColoredText(SlotsAvailable $ "/" $ NumUpgradeSlots, eUIState_Highlight, 40));

	SlotsList.ClearItems();
	
	// Add equipped slots
	for (i = 0; i < EquippedUpgrades.Length; ++i)
	{
		// If an upgrade was equipped while the extra slot continent bonus was active, but it is now disabled, don't allow the upgrade to be edited
		EquipSlotLockedStr = (i > (NumUpgradeSlots - 1)) ? class'UIUtilities_Text'.static.GetColoredText(m_strRequiresContinentBonus, eUIState_Bad) : "";
		UIArmory_WeaponUpgradeItem(SlotsList.CreateItem(class'UIArmory_WeaponUpgradeItem')).InitUpgradeItem(Weapon, EquippedUpgrades[i], i, EquipSlotLockedStr);
	}

	// Add available upgrades
	for (i = 0; i < SlotsAvailable; ++i)
	{
		UIArmory_WeaponUpgradeItem(SlotsList.CreateItem(class'UIArmory_WeaponUpgradeItem')).InitUpgradeItem(Weapon, none, i + EquippedUpgrades.Length);
	}

	if(SlotsAvailable == 0)
		SetSlotsListTitle(`XEXPAND.ExpandString(m_strWeaponFullyUpgraded));
	else
		SetSlotsListTitle(`XEXPAND.ExpandString(m_strUpgradeWeapon));
}

simulated function UpdateUpgrades()
{
	local int i, SlotIndex;
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local XComGameState_Item Weapon;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIArmory_WeaponUpgradeItem UpgradeItem;
	local array<TUIAvailableUpgrade> AvailableUpgrades;
	local TUIAvailableUpgrade Upgrade;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;

	AvailableUpgrades.Length = 0;
	foreach XComHQ.Inventory(ItemRef)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
		if (Item == none || X2WeaponUpgradeTemplate(Item.GetMyTemplate()) == none)
			continue;
		
		Upgrade.Item = Item;
		Upgrade.bCanBeEquipped = X2WeaponUpgradeTemplate(Item.GetMyTemplate()).CanApplyUpgradeToWeapon(Weapon, SlotIndex);
		Upgrade.DisabledReason = Upgrade.bCanBeEquipped ? "" : class'UIUtilities_Text'.static.GetColoredText(m_strInvalidUpgrade, eUIState_Bad);

		AvailableUpgrades.AddItem(Upgrade);
	}

	AvailableUpgrades.Sort(SortUpgradesByTier);
	AvailableUpgrades.Sort(SortUpgradesByEquip);

	UpgradesList.ClearItems();

	for(i = 0; i < AvailableUpgrades.Length; ++i)
	{
		UpgradeItem = UIArmory_WeaponUpgradeItem(UpgradesList.CreateItem(class'UIArmory_WeaponUpgradeItem'));
		UpgradeItem.InitUpgradeItem(Weapon, X2WeaponUpgradeTemplate(AvailableUpgrades[i].Item.GetMyTemplate()), , AvailableUpgrades[i].DisabledReason);
		UpgradeItem.SetCount(AvailableUpgrades[i].Item.Quantity);
	}

	if(AvailableUpgrades.Length == 0)
		SetUpgradeListTitle(m_strNoUpgradeAvailable);
	else
		SetUpgradeListTitle(m_strSelectUpgrade);
}

simulated function int SortUpgradesByEquip(TUIAvailableUpgrade A, TUIAvailableUpgrade B)
{
	if(A.bCanBeEquipped && !B.bCanBeEquipped) return 1;
	else if(!A.bCanBeEquipped && B.bCanBeEquipped) return -1;
	else return 0;
}

simulated function int SortUpgradesByTier(TUIAvailableUpgrade A, TUIAvailableUpgrade B)
{
	local int TierA, TierB;

	TierA = A.Item.GetMyTemplate().Tier;
	TierB = B.Item.GetMyTemplate().Tier;

	if (TierA > TierB) return 1;
	else if (TierA < TierB) return -1;
	else return 0;
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	local Vector PreviousLocation, NoneLocation;
	local XComGameState_Item WeaponItemState;

	ActiveList = kActiveList;
	UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SetLocked(ActiveList != SlotsList);
	ActiveList.SetSelectedIndex(INDEX_NONE);
	
	if(ActiveList == SlotsList)
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("closeList");

		// disable list item selection on LockerList, enable it on EquippedList
		UpgradesListContainer.DisableMouseHit();
		SlotsListContainer.EnableMouseHit();

		//Reset the weapon location tag as it may have changed if we were looking at attachments
		WeaponItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

		PreviousLocation = ActorPawn.Location;
		CreateWeaponPawn(WeaponItemState, ActorPawn.Rotation);
		WeaponStats.PopulateData(WeaponItemState);
		if(PreviousLocation != NoneLocation)
			ActorPawn.SetLocation(PreviousLocation);

		SetUpgradeText();
	}
	else
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("openList");
		
		// disable list item selection on LockerList, enable it on EquippedList
		UpgradesListContainer.EnableMouseHit();
		SlotsListContainer.DisableMouseHit();
	}

	if (ActiveList != none)
	{
		Navigator.SetSelected(ActiveList);
		ActiveList.Navigator.SetSelected(ActiveList.GetItem(ActiveList.SelectedIndex != -1 ? ActiveList.SelectedIndex : 0));
	}
} 

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local X2WeaponUpgradeTemplate NewUpgradeTemplate;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Weapon;
	local int SlotIndex;

	if(ContainerList != ActiveList) return;

	if(UIArmory_WeaponUpgradeItem(ContainerList.GetItem(ItemIndex)).bIsDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	if(ContainerList == SlotsList)
	{
		UpdateNavHelp();
		UpdateUpgrades();
		ChangeActiveList(UpgradesList);
	}
	else
	{
		Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
		UpgradeTemplates = Weapon.GetMyWeaponUpgradeTemplates();
		NewUpgradeTemplate = UIArmory_WeaponUpgradeItem(ContainerList.GetItem(ItemIndex)).UpgradeTemplate;
		SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;
		
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		if (XComHQ.bReuseUpgrades)
		{
			// Skip the popup if the continent bonus for reusing upgrades is active
			EquipUpgradeCallback(eUIAction_Accept);
		}
		else
		{			
			if (SlotIndex < UpgradeTemplates.Length)
				ReplaceUpgrade(UpgradeTemplates[SlotIndex], NewUpgradeTemplate);
			else
				EquipUpgrade(NewUpgradeTemplate);
		}
	}
}

simulated function PreviewUpgrade(UIList ContainerList, int ItemIndex)
{
	local XComGameState_Item Weapon;
	local XComGameState ChangeState;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local Vector PreviousLocation;
	local int WeaponAttachIndex, SlotIndex;
	local Name WeaponTemplateName;

	if(ItemIndex == INDEX_NONE)
	{
		SetUpgradeText();
		return;
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade");
	ChangeState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Visualize Weapon Upgrade");

	Weapon = XComGameState_Item(ChangeState.CreateStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
	ChangeState.AddStateObject(Weapon);

	UpgradeTemplate = UIArmory_WeaponUpgradeItem(ContainerList.GetItem(ItemIndex)).UpgradeTemplate;
	SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;

	Weapon.DeleteWeaponUpgradeTemplate(SlotIndex);
	Weapon.ApplyWeaponUpgradeTemplate(UpgradeTemplate, SlotIndex);

	PreviousLocation = ActorPawn.Location;
	CreateWeaponPawn(Weapon, ActorPawn.Rotation);
	ActorPawn.SetLocation(PreviousLocation);

	//Formulate the attachment specific location tag from the attach socket
	WeaponTemplateName = Weapon.GetMyTemplateName();
	for( WeaponAttachIndex = 0; WeaponAttachIndex < UpgradeTemplate.UpgradeAttachments.Length; ++WeaponAttachIndex )
	{
		if( UpgradeTemplate.UpgradeAttachments[WeaponAttachIndex].ApplyToWeaponTemplate == WeaponTemplateName &&
		    UpgradeTemplate.UpgradeAttachments[WeaponAttachIndex].UIArmoryCameraPointTag != '' )
		{
			PawnLocationTag = UpgradeTemplate.UpgradeAttachments[WeaponAttachIndex].UIArmoryCameraPointTag;
			break;
		}
	}

	SetUpgradeText(UpgradeTemplate.GetItemFriendlyName(), UpgradeTemplate.GetItemBriefSummary());

	WeaponStats.PopulateData(Weapon, UpgradeTemplate);

	`XCOMHISTORY.CleanupPendingGameState(ChangeState);
}

function EquipUpgrade(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
		
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UpgradeTemplate.GetItemFriendlyName();
		
	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strConfirmDialogTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strConfirmDialogDescription); 

	kDialogData.fnCallback = EquipUpgradeCallback;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function ReplaceUpgrade(X2WeaponUpgradeTemplate UpgradeToRemove, X2WeaponUpgradeTemplate UpgradeToInstall)
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UpgradeToRemove.GetItemFriendlyName();
	kTag.StrValue1 = UpgradeToInstall.GetItemFriendlyName();

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strReplaceUpgradeTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strReplaceUpgradeText);

	kDialogData.fnCallback = EquipUpgradeCallback;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

simulated public function EquipUpgradeCallback(eUIAction eAction)
{
	local int i, SlotIndex;
	local XComGameState_Item Weapon;
	local XComGameState_Item UpgradeItem;
	local X2WeaponUpgradeTemplate UpgradeTemplate, OldUpgradeTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState ChangeState;
	
	if( eAction == eUIAction_Accept )
	{
		Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
		UpgradeTemplate = UIArmory_WeaponUpgradeItem(UpgradesList.GetSelectedItem()).UpgradeTemplate;
		SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;

		if (UpgradeTemplate != none && UpgradeTemplate.CanApplyUpgradeToWeapon(Weapon, SlotIndex))
		{
			// Create change context
			ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Weapon Upgrade");
			ChangeState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);

			// Apply upgrade to weapon
			Weapon = XComGameState_Item(ChangeState.CreateStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
			OldUpgradeTemplate = Weapon.DeleteWeaponUpgradeTemplate(SlotIndex);
			Weapon.ApplyWeaponUpgradeTemplate(UpgradeTemplate, SlotIndex);
			ChangeState.AddStateObject(Weapon);
			
			// Remove the new upgrade from HQ inventory
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			XComHQ = XComGameState_HeadquartersXCom(ChangeState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			ChangeState.AddStateObject(XComHQ);

			for(i = 0; i < XComHQ.Inventory.Length; ++i)
			{
				UpgradeItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Inventory[i].ObjectID));
				if (UpgradeItem != none && UpgradeItem.GetMyTemplateName() == UpgradeTemplate.DataName)
					break;
			}

			if(UpgradeItem == none)
			{
				`RedScreen("Failed to find upgrade"@UpgradeTemplate.DataName@"in HQ inventory.");
				return;
			}

			XComHQ.RemoveItemFromInventory(ChangeState, UpgradeItem.GetReference(), 1);

			// If reusing upgrades Continent Bonus is active, create an item for the old upgrade template and add it to the inventory
			if (XComHQ.bReuseUpgrades && OldUpgradeTemplate != none)
			{
				UpgradeItem = OldUpgradeTemplate.CreateInstanceFromTemplate(ChangeState);
				ChangeState.AddStateObject(UpgradeItem);
				XComHQ.PutItemInInventory(ChangeState, UpgradeItem);
			}
			
			`XEVENTMGR.TriggerEvent('WeaponUpgraded', Weapon, UpgradeItem, ChangeState);
			`GAMERULES.SubmitGameState(ChangeState);

			UpdateSlots();
			WeaponStats.PopulateData(Weapon);

			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade_Select");
		}
		else
			Movie.Pres.PlayUISound(eSUISound_MenuClose);

		ChangeActiveList(SlotsList);
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function UpdateCustomization(UIPanel DummyParam)
{
	local int i;
	local XGParamTag LocTag;
	local XComLinearColorPalette Palette;

	CreateCustomizationState();

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Caps(UpdatedWeapon.GetMyTemplate().GetItemFriendlyName(UpdatedWeapon.ObjectID));

	SetCustomizeTitle(`XEXPAND.ExpandString(m_strCustomizeWeaponTitle));

	// WEAPON NAME
	//-----------------------------------------------------------------------------------------
	GetCustomizeItem(i++).UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(m_strCustomizeWeaponName, eUIState_Normal), OpenWeaponNameInputBox);

	// WEAPON PRIMARY COLOR
	//-----------------------------------------------------------------------------------------
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	GetCustomizeItem(i++).UpdateDataColorChip(class'UIUtilities_Text'.static.GetColoredText(class'UICustomize_Menu'.default.m_strWeaponColor, eUIState_Normal),
		class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[UpdatedWeapon.WeaponAppearance.iWeaponTint].Primary), WeaponColorSelector);

	// WEAPON PATTERN (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetCustomizeItem(i++).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(class'UICustomize_Props'.default.m_strWeaponPattern, eUIState_Normal),
							  class'UIUtilities_Text'.static.GetColoredText(GetWeaponPatternDisplay(UpdatedWeapon.WeaponAppearance.nmWeaponPattern), eUIState_Normal, FontSize), CustomizeWeaponPattern);

	CustomizeList.SetPosition(CustomizationListX, CustomizationListY - CustomizeList.ShrinkToFit() - CustomizationListYPadding);

	CleanupCustomizationState();
}

simulated function bool InShell()
{
	return XComShellPresentationLayer(Movie.Pres) != none;
}

simulated function UIMechaListItem GetCustomizeItem(int ItemIndex)
{
	local UIMechaListItem CustomizeItem;

	if(CustomizeList.ItemCount <= ItemIndex)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', CustomizeList.ItemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem();
	}
	else
		CustomizeItem = UIMechaListItem(CustomizeList.GetItem(ItemIndex));

	return CustomizeItem;
}

simulated function CustomizeWeaponPattern()
{
	XComHQPresentationLayer(Movie.Pres).UIArmory_WeaponTrait(WeaponRef, class'UICustomize_Props'.default.m_strWeaponPattern, GetWeaponPatternList(),
		PreviewWeaponPattern, UpdateWeaponPattern, CanCycleTo, GetWeaponPatternIndex(),,, false);
}

function PreviewWeaponPattern(UIList _list, int itemIndex)
{
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;

	CreateCustomizationState();

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);

	newIndex = WrapIndex( itemIndex, 0, BodyParts.Length);
	
	UpdatedWeapon.WeaponAppearance.nmWeaponPattern = BodyParts[newIndex].DataName;
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);

	CleanupCustomizationState();
}

function UpdateWeaponPattern(UIList _list, int itemIndex)
{
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;
	local XComGameState_Unit Unit;

	CreateCustomizationState();

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);

	newIndex = WrapIndex( itemIndex, 0, BodyParts.Length);
	
	UpdatedWeapon.WeaponAppearance.nmWeaponPattern = BodyParts[newIndex].DataName;
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);
	
	// Transfer the new weapon pattern back to the owner Unit's appearance data ONLY IF the weapon is otherwise unmodified
	Unit = GetUnit();
	if (Unit != none && !UpdatedWeapon.HasBeenModified())
	{
		Unit = XComGameState_Unit(CustomizationState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		CustomizationState.AddStateObject(Unit);
		Unit.kAppearance.nmWeaponPattern = UpdatedWeapon.WeaponAppearance.nmWeaponPattern;
	}

	SubmitCustomizationChanges();
}

function string GetWeaponPatternDisplay( name PartToMatch )
{
	local int PartIndex;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);

	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			return BodyParts[PartIndex].DisplayName;
		}
	}

	return PartManager.FindUberTemplate("Patterns", 'Pat_Nothing').DisplayName;
}

function array<string> GetWeaponPatternList()
{
	local int i;
	local array<string> Items;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);
	for( i = 0; i < BodyParts.Length; ++i )
	{
		if(BodyParts[i].DisplayName != "")
			Items.AddItem(BodyParts[i].DisplayName);
		else if(class'UICustomize_Props'.default.m_strWeaponPattern != "")
			Items.AddItem(class'UICustomize_Props'.default.m_strWeaponPattern @ i);
		else
			Items.AddItem(string(i));
	}

	return Items;
}

function int GetWeaponPatternIndex()
{
	local array<X2BodyPartTemplate> BodyParts;
	local int PartIndex;
	local int categoryValue;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( XComWeapon(ActorPawn).m_kGameWeapon.m_kAppearance.nmWeaponPattern == BodyParts[PartIndex].DataName )
		{
			categoryValue = PartIndex;
			break;
		}
	}

	return categoryValue;
}

simulated function array<string> GetWeaponColorList()
{
	local XComLinearColorPalette Palette;
	local array<string> Colors; 
	local int i; 

	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	for(i = 0; i < Palette.Entries.length; i++)
	{
		Colors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, class'XComCharacterCustomization'.default.UIColorBrightnessAdjust));
	}

	return Colors;
}
reliable client function WeaponColorSelector()
{
	//If an extra click sneaks in, multiple color selectors will be created on top of each other and leak. 
	if( ColorSelector != none ) return; 

	CreateCustomizationState();
	HideListItems();
	CustomizeList.Hide();
	ColorSelector = Spawn(class'UIColorSelector', self);
	ColorSelector.InitColorSelector(, ColorSelectorX, ColorSelectorY, ColorSelectorWidth, ColorSelectorHeight,
		GetWeaponColorList(), PreviewWeaponColor, SetWeaponColor,
		UpdatedWeapon.WeaponAppearance.iWeaponTint);

	SlotsListContainer.GetChildByName('BG').ProcessMouseEvents(ColorSelector.OnChildMouseEvent);
	CleanupCustomizationState();
}
function PreviewWeaponColor(int iColorIndex)
{
	local array<string> Colors;
	Colors = GetWeaponColorList();
	CreateCustomizationState();
	UpdatedWeapon.WeaponAppearance.iWeaponTint = WrapIndex(iColorIndex, 0, Colors.Length);
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);
	CleanupCustomizationState();
}
function SetWeaponColor(int iColorIndex)
{
	local XComGameState_Unit Unit;
	local array<string> Colors;

	Colors = GetWeaponColorList();
	CreateCustomizationState();
	UpdatedWeapon.WeaponAppearance.iWeaponTint = WrapIndex(iColorIndex, 0, Colors.Length);
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);

	// Transfer the new weapon color back to the owner Unit's appearance data ONLY IF the weapon is otherwise unmodified
	Unit = GetUnit();
	if (Unit != none && !UpdatedWeapon.HasBeenModified())
	{
		Unit = XComGameState_Unit(CustomizationState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		CustomizationState.AddStateObject(Unit);
		Unit.kAppearance.iWeaponTint = UpdatedWeapon.WeaponAppearance.iWeaponTint;
	}

	SubmitCustomizationChanges();

	CloseColorSelector();
	CustomizeList.Show();
	UpdateCustomization(none);
	ShowListItems();
}

simulated function HideListItems()
{
	local int i;
	for(i = 0; i < ActiveList.ItemCount; ++i)
	{
		ActiveList.GetItem(i).Hide();
	}
}
simulated function ShowListItems()
{
	local int i;
	for(i = 0; i < ActiveList.ItemCount; ++i)
	{
		ActiveList.GetItem(i).Show();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	
	if (ActiveList != none)
	{
		switch( cmd )
		{
			case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
				OnItemClicked(ActiveList, ActiveList.SelectedIndex);
				return true;
		}

		if (ActiveList.Navigator.OnUnrealCommand(cmd, arg))
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnCancel()
{
	if(ColorSelector != none)
	{
		CloseColorSelector(true);
	}
	else if(ActiveList == SlotsList)
	{
		`XCOMGRI.DoRemoteEvent(DisableWeaponLightingEvent);

		super.OnCancel(); // exists screen
	}
	else
	{
		ChangeActiveList(SlotsList);
	}
}

simulated function CloseColorSelector(optional bool bCancelColorSelection)
{
	if( bCancelColorSelection )
	{
		ColorSelector.OnCancelColor();
	}
	else
	{
		ColorSelector.Remove();
		ColorSelector = none;
	}

	// restore mouse events to slot list
	SlotsListContainer.GetChildByName('BG').ProcessMouseEvents(SlotsList.OnChildMouseEvent);
}

simulated function bool HasWeaponChanged()
{
	local XComGameState_Item PrevState;
	PrevState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(UpdatedWeapon.GetReference().ObjectID));
	return PrevState.WeaponAppearance != UpdatedWeapon.WeaponAppearance || PrevState.Nickname != UpdatedWeapon.Nickname;
}

simulated function CreateCustomizationState()
{
	if (CustomizationState == none) // Only create a new customization state if one doesn't already exist
	{
		CustomizationState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Weapon Customize");
	}
	UpdatedWeapon = XComGameState_Item(CustomizationState.CreateStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
	CustomizationState.AddStateObject(UpdatedWeapon);
}

simulated function OpenWeaponNameInputBox()
{
	local TInputDialogData kData;

	kData.strTitle = m_strCustomizeWeaponName;
	kData.iMaxChars = class'XComCharacterCustomization'.const.NICKNAME_NAME_MAX_CHARS;
	kData.strInputBoxText = UpdatedWeapon.Nickname;
	kData.fnCallback = OnNameInputBoxClosed;

	Movie.Pres.UIInputDialog(kData);
}

function OnNameInputBoxClosed(string text)
{
	CreateCustomizationState();
	UpdatedWeapon.Nickname = text;
	SubmitCustomizationChanges();
	SetWeaponReference(WeaponRef);
}

simulated function OnReceiveFocus()
{
	// Clean up pending game states to prevent a RedScreen that occurs due to Avenger visibility changes
	// (in XGBase.SetAvengerVisibility, called by XComCamState_HQ_BaseRoomView.InitRoomView)
	if(CustomizationState != none) SubmitCustomizationChanges();

	super.OnReceiveFocus();

	UpdateCustomization(none);
}

simulated function SubmitCustomizationChanges()
{
	if(HasWeaponChanged()) 
	{
		`GAMERULES.SubmitGameState(CustomizationState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(CustomizationState);
	}
	CustomizationState = none;
	UpdatedWeapon = none;
}

simulated function CleanupCustomizationState()
{
	if (CustomizationState != none) // Only cleanup the CustomizationState if it isn't already none
	{
		`XCOMHISTORY.CleanupPendingGameState(CustomizationState);
	}
	CustomizationState = none;
	UpdatedWeapon = none;
}

simulated function ReleasePawn(optional bool bForce)
{
	ActorPawn.Destroy();
	ActorPawn = none;
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	local TWeaponUpgradeAvailabilityData Data;

	class'UIUtilities_Strategy'.static.GetWeaponUpgradeAvailability(Unit, Data);

	// Logic taken from UIArmory_MainMenu
	return super.CanCycleTo(Unit) && Data.bHasWeaponUpgrades && Data.bHasModularWeapons && Data.bCanWeaponBeUpgraded;
}

function InterpolateWeapon()
{
	local Vector LocationLerp;
	local Rotator RotatorLerp;
	local Quat StartRotation;
	local Quat GoalRotation;
	local Quat ResultRotation;
	local Vector GoalLocation;
	local PointInSpace PlacementActor;

	PlacementActor = GetPlacementActor();
	GoalLocation = PlacementActor.Location;
	if(PawnLocationTag != '')
	{
		if(VSize(GoalLocation - ActorPawn.Location) > 0.1f)
		{
			LocationLerp = VLerp(ActorPawn.Location, GoalLocation, 0.1f);
			ActorPawn.SetLocation(LocationLerp);
		}

		// if MouseGuard is handling rotation of the weapon, stop rotating it here to prevent conflict
		if(MouseGuard.ActorPawn == none && ActiveList.SelectedIndex != -1 && UIArmory_WeaponUpgradeItem(ActiveList.GetSelectedItem()).UpgradeTemplate != none)
		{
			StartRotation = QuatFromRotator(ActorPawn.Rotation);
			GoalRotation = QuatFromRotator(PlacementActor.Rotation);
			ResultRotation = QuatSlerp(StartRotation, GoalRotation, 0.1f, true);
			RotatorLerp = QuatToRotator(ResultRotation);
			ActorPawn.SetRotation(RotatorLerp);
		}
	}
}

simulated function OnListChildMouseEvent(UIPanel Panel, int Cmd)
{
	// if we get any mouse event on the list, stop mouse guard rotation
	MouseGuard.SetActorPawn(none);
}

simulated function OnMouseGuardMouseEvent(UIPanel Panel, int Cmd)
{
	// resume mouse guard rotation if mouse moves over mouse guard
	switch(Cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		MouseGuard.SetActorPawn(ActorPawn, MouseGuard.ActorRotation);
		WeaponStats.PopulateData(XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID)));
		RestoreWeaponLocation();
		break;
	}
}

simulated function RestoreWeaponLocation()
{
	local XComGameState_Item Weapon;
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	PawnLocationTag = X2WeaponTemplate(Weapon.GetMyTemplate()).UIArmoryCameraPointTag;
}

simulated function Remove()
{
	super.Remove();
	ClearTimer(nameof(InterpolateWeapon));
}

//==============================================================================

simulated function SetSlotsListTitle(string ListTitle)
{
	MC.FunctionString("setLeftPanelTitle", ListTitle);
}

simulated function SetUpgradeListTitle(string ListTitle)
{
	MC.FunctionString("setRightPanelTitle", ListTitle);
}

simulated function SetCustomizeTitle(string ListTitle)
{
	MC.FunctionString("setCustomizeTitle", ListTitle);
}

simulated function SetWeaponName(string WeaponName)
{
	MC.FunctionString("setWeaponName", WeaponName);
}

simulated function SetEquippedText(string EquippedLabel, string SoldierName)
{
	MC.BeginFunctionOp("setEquipedText");
	MC.QueueString(EquippedLabel);
	MC.QueueString(SoldierName);
	MC.EndOp();
}

// Passing empty strings hides the upgrade description box
simulated function SetUpgradeText(optional string UpgradeName, optional string UpgradeDescription)
{
	MC.BeginFunctionOp("setUpgradeText");
	MC.QueueString(UpgradeName);
	MC.QueueString(UpgradeDescription);
	MC.EndOp();
}

simulated function SetAvailableSlots(string SlotsAvailableLabel, string NumAvailableSlots)
{
	MC.BeginFunctionOp("setUpgradeCount");
	MC.QueueString(SlotsAvailableLabel);
	MC.QueueString(NumAvailableSlots);
	MC.EndOp();
}

//==============================================================================

defaultproperties
{
	LibID = "WeaponUpgradeScreenMC";
	CameraTag = "UIBlueprint_Loadout";
	DisplayTag = "UIBlueprint_Loadout";
	bHideOnLoseFocus = false;
}