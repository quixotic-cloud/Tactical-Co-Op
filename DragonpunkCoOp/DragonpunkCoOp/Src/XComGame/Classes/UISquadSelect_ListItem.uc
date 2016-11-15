//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_ListItem
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays information pertaining to a single soldier in the Squad Select screen
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISquadSelect_ListItem extends UIPanel;

var int SlotIndex;
var bool bDisabled;

// Disable functionality for certain buttons
var bool bDisabledLoadout;
var bool bDisabledEdit;
var bool bDisabledDismiss;
var array<EInventorySlot> CannotEditSlots;

var UIPanel DynamicContainer;
var UIImage PsiMarkup;
var UIPanel AbilityIcons;
var UIList UtilitySlots;

var localized string m_strSelectUnit;
var localized string m_strBackpack;
var localized string m_strBackpackDescription;
var localized string m_strEmptyHeavyWeapon;
var localized string m_strEmptyHeavyWeaponDescription;
var localized string m_strPromote;
var localized string m_strEdit;
var localized string m_strDismiss;
var localized string m_strNeedsMediumArmor;
var localized string m_strNoUtilitySlots;
var localized string m_strIncreaseSquadSize;

enum ESquadSelectButton
{
	eSSB_Promote,
	eSSB_Edit,
	eSSB_Dismiss,
	eSSB_WeaponPrime,
	eSSB_WeaponHeavy,
	eSSB_Utility
};
var ESquadSelectButton m_eActiveButton;

var Bool bEditDisabled;
var Bool bDismissDisabled;
var Bool bDirty;
var Bool bReverseInitialUtilityFocus; //set externally to indicate that focus is coming from a higher index (moving left horizontally)
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	DynamicContainer = Spawn(class'UIPanel', self).InitPanel('dynamicContainerMC');
	
	PsiMarkup = Spawn(class'UIImage', DynamicContainer).InitImage(, class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.SetScale(0.7).SetPosition(220, 258).Hide(); // starts off hidden until needed
	SetDirty(true, false);
	
	return self;
}
 
simulated function UpdateData(optional int Index = -1, optional bool bDisableEdit, optional bool bDisableDismiss, optional bool bDisableLoadout, optional array<EInventorySlot> CannotEditSlotsList)
{
	local bool bCanPromote;
	local string ClassStr, NameStr;
	local int i, NumUtilitySlots, UtilityItemIndex, NumUnitUtilityItems;
	local float UtilityItemWidth, UtilityItemHeight;
	local UISquadSelect_UtilityItem UtilityItem;
	local array<XComGameState_Item> EquippedItems;
	local XComGameState_Unit Unit;
	local XComGameState_Item PrimaryWeapon, HeavyWeapon;
	local X2WeaponTemplate PrimaryWeaponTemplate, HeavyWeaponTemplate;
	local X2AbilityTemplate HeavyWeaponAbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;

	if(bDisabled)
		return;

	SlotIndex = Index != -1 ? Index : SlotIndex;

	bDisabledEdit = bDisableEdit;
	bDisabledDismiss = bDisableDismiss;
	bDisabledLoadout = bDisableLoadout;
	CannotEditSlots = CannotEditSlotsList;

	if( UtilitySlots == none )
	{
		UtilitySlots = Spawn(class'UIList', DynamicContainer).InitList(, 0, 138, 282, 70, true);
		UtilitySlots.bStickyHighlight = false;
		UtilitySlots.ItemPadding = 5;
	}

	if( AbilityIcons == none )
	{
		AbilityIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, 92);
		AbilityIcons.Hide(); // starts off hidden until needed
	}

	// -------------------------------------------------------------------------------------------------------------

	// empty slot
	if(GetUnitRef().ObjectID <= 0)
	{
		AS_SetEmpty(m_strSelectUnit);
		AS_SetUnitHealth(-1, -1);

		AbilityIcons.Remove();
		AbilityIcons = none;

		DynamicContainer.Hide();
		if( !Movie.IsMouseActive() )
			HandleEmptyListItemFocus();
	}
	else
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));
		bCanPromote = (Unit.ShowPromoteIcon());

		UtilitySlots.Show();
		DynamicContainer.Show();
		//Backpack controlled separately by the heavy weapon info. 

	//	if( Navigator.SelectedIndex == -1 )
//			Navigator.SelectFirstAvailable();

		NumUtilitySlots = 2;
		if(Unit.HasGrenadePocket()) NumUtilitySlots++;
		if(Unit.HasAmmoPocket()) NumUtilitySlots++;
		
		UtilityItemWidth = (UtilitySlots.GetTotalWidth() - (UtilitySlots.ItemPadding * (NumUtilitySlots - 1))) / NumUtilitySlots;
		UtilityItemHeight = UtilitySlots.Height;

		if(UtilitySlots.ItemCount != NumUtilitySlots)
			UtilitySlots.ClearItems();

		for(i = 0; i < NumUtilitySlots; ++i)
		{
			if(i >= UtilitySlots.ItemCount)
			{
				UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.CreateItem(class'UISquadSelect_UtilityItem').InitPanel());
				UtilityItem.SetSize(UtilityItemWidth, UtilityItemHeight);
				UtilityItem.CannotEditSlots = CannotEditSlotsList;
				UtilitySlots.OnItemSizeChanged(UtilityItem);
			}
		}

		NumUnitUtilityItems = Unit.GetCurrentStat(eStat_UtilityItems); // Check how many utility items this unit can use
		
		UtilityItemIndex = 0;
		UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
		if (NumUnitUtilityItems > 0)
		{
			EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedItemsInSlot(Unit, eInvSlot_Utility);
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_Utility, 0, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_Utility, 0, NumUtilitySlots);
		}
		else
			UtilityItem.SetLocked(m_strNoUtilitySlots); // If the unit has no utility slots allowed, lock the slot

		if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress)
		{
			// spawn the attention icon externally so it draws on top of the button and image 
			Spawn(class'UIPanel', UtilityItem).InitPanel('attentionIconMC', class'UIUtilities_Controls'.const.MC_AttentionIcon)
			.SetPosition(2, 4)
			.SetSize(70, 70); //the animated rings count as part of the size. 
		} else if(GetChildByName('attentionIconMC', false) != none) {
			GetChildByName('attentionIconMC').Remove();
		}

		UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
		if (Unit.HasExtraUtilitySlot())
		{
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 1 ? EquippedItems[1] : none, eInvSlot_Utility, 1, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 1 ? EquippedItems[1] : none, eInvSlot_Utility, 1, NumUtilitySlots);
		}
		else
			UtilityItem.SetLocked(NumUnitUtilityItems > 0 ? m_strNeedsMediumArmor : m_strNoUtilitySlots);

		if(Unit.HasGrenadePocket())
		{
			UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
			EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedItemsInSlot(Unit, eInvSlot_GrenadePocket); 
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_GrenadePocket, 0, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_GrenadePocket, 0, NumUtilitySlots);
		}

		if(Unit.HasAmmoPocket())
		{
			UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
			EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedItemsInSlot(Unit, eInvSlot_AmmoPocket);
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_AmmoPocket, 0, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_AmmoPocket, 0, NumUtilitySlots);
		}
		
		// Don't show class label for rookies since their rank is shown which would result in a duplicate string
		if(Unit.GetRank() > 0)
			ClassStr = class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierClassTemplate().DisplayName), eUIState_Faded, 17);
		else
			ClassStr = "";

		PrimaryWeapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
		if(PrimaryWeapon != none)
		{
			PrimaryWeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		}

		NameStr = Unit.GetName(eNameType_Last);
		if (NameStr == "") // If the unit has no last name, display their first name instead
		{
			NameStr = Unit.GetName(eNameType_First);
		}

		// TUTORIAL: Disable buttons if tutorial is enabled
		if(bDisableEdit)
			MC.FunctionVoid("disableEdit");
		if(bDisableDismiss)
			MC.FunctionVoid("disableDismiss");
		bEditDisabled = bDisableEdit; //Used in controller nav
		bDismissDisabled = bDisableDismiss; //used in controller nav

		AS_SetFilled( class'UIUtilities_Text'.static.GetColoredText(Caps(class'X2ExperienceConfig'.static.GetRankName(Unit.GetRank(), Unit.GetSoldierClassTemplateName())), eUIState_Normal, 18),
					  class'UIUtilities_Text'.static.GetColoredText(Caps(NameStr), eUIState_Normal, 22),
					  class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Nick)), eUIState_Header, 28),
					  Unit.GetSoldierClassTemplate().IconImage, class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName()),
					  class'UIUtilities_Text'.static.GetColoredText(m_strEdit, bDisableEdit ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(m_strDismiss, bDisableDismiss ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(PrimaryWeaponTemplate.GetItemFriendlyName(PrimaryWeapon.ObjectID), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_PrimaryWeapon], bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponName(), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponDesc(), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  (bCanPromote ? m_strPromote : ""), Unit.IsPsiOperative() || (Unit.HasPsiGift() && Unit.GetRank() < 2), ClassStr);
		
		AS_SetUnitHealth(class'UIUtilities_Strategy'.static.GetUnitCurrentHealth(Unit), class'UIUtilities_Strategy'.static.GetUnitMaxHealth(Unit));
		
		PsiMarkup.SetVisible(Unit.HasPsiGift());

		HeavyWeapon = Unit.GetItemInSlot(eInvSlot_HeavyWeapon);
		if(HeavyWeapon != none)
		{
			HeavyWeaponTemplate = X2WeaponTemplate(HeavyWeapon.GetMyTemplate());

			// Only show one icon for heavy weapon abilities
			if(HeavyWeaponTemplate.Abilities.Length > 0)
			{
				AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
				HeavyWeaponAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(HeavyWeaponTemplate.Abilities[0]);
				if(HeavyWeaponAbilityTemplate != none)
					Spawn(class'UIIcon', AbilityIcons).InitIcon(, HeavyWeaponAbilityTemplate.IconImage, false);
			}

			AbilityIcons.Show();
			AS_HasHeavyWeapon(true);
		}
		else
		{
			AbilityIcons.Hide();
			AS_HasHeavyWeapon(false);
		}
	}
	RefreshFocus();
	//bsg-cballinger (7.8.16): disable update optimization on SquadSelect for now (dirty is now always set). Causes items to not update properly on the SquadSelect screen when changes are made to the squad loadout
}

simulated function DisableSlot()
{
	bDisabled = true;
	AS_SetDisabled(m_strIncreaseSquadSize);
	DynamicContainer.Hide();
}

simulated function AnimateIn(optional float AnimationIndex = -1.0)
{
	MC.FunctionNum("animateIn", AnimationIndex);
}

function StateObjectReference GetUnitRef()
{
	local StateObjectReference NullRef; 
	if( SlotIndex >= UISquadSelect(Screen).XComHQ.Squad.length )
		return NullRef;
	else
		return UISquadSelect(Screen).XComHQ.Squad[SlotIndex];
}

simulated function string GetHeavyWeaponName()
{
	if(GetEquippedHeavyWeapon() != none)
		return GetEquippedHeavyWeapon().GetMyTemplate().GetItemFriendlyName();
	else
		return HasHeavyWeapon() ? m_strEmptyHeavyWeapon : "";
}

simulated function string GetHeavyWeaponDesc()
{
	if(GetEquippedHeavyWeapon() != none)
		return class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_HeavyWeapon];
	else
		return "";
}

simulated function XComGameState_Item GetEquippedHeavyWeapon()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID)).GetItemInSlot(eInvSlot_HeavyWeapon);
}

function bool HasHeavyWeapon()
{
	if(GetUnitRef().ObjectID > 0)
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID)).HasHeavyWeapon();
	return false;
}

//------------------------------------------------------

simulated function OnClickedPromote()
{
	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if( GetUnitRef().ObjectID > 0 )
	{
		//UISquadSelect(Screen).bDirty = true;
		SetDirty(true);
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoPromote));
	}
}

simulated function GoPromote()
{
	`HQPRES.UIArmory_Promotion(GetUnitRef());
}

simulated function OnClickedPrimaryWeapon()
{
	if (bDisabledLoadout)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if(GetUnitRef().ObjectID > 0)
	{
		//UISquadSelect(Screen).bDirty = true;
		SetDirty(true);
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoToPrimaryWeapon));
	}
}

simulated function GoToPrimaryWeapon()
{
	`HQPRES.UIArmory_Loadout(GetUnitRef(), CannotEditSlots);
	
	if (CannotEditSlots.Find(eInvSlot_PrimaryWeapon) == INDEX_NONE)
	{
		UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectWeapon(eInvSlot_PrimaryWeapon);
	}
}

simulated function OnClickedHeavyWeapon()
{
	if (bDisabledLoadout)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if(GetUnitRef().ObjectID > 0)
	{
		//UISquadSelect(Screen).bDirty = true;
		SetDirty(true);
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoToHeavyWeapon));
	}
}

simulated function GoToHeavyWeapon()
{
	`HQPRES.UIArmory_Loadout(GetUnitRef(), CannotEditSlots);

	if (CannotEditSlots.Find(eInvSlot_HeavyWeapon) == INDEX_NONE)
	{
		UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectWeapon(eInvSlot_HeavyWeapon);
	}
}

simulated function OnClickedDismissButton()
{
	local UISquadSelect SquadScreen;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(!XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') || bDisabledDismiss)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	HandleButtonFocus(m_eActiveButton, false);
	SquadScreen = UISquadSelect(screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	SquadScreen.ChangeSlot();
	UpdateData(); // passing no params clears the slot
}

simulated function OnClickedEditUnitButton()
{
	local UISquadSelect SquadScreen;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(!XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') || bDisabledEdit)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	SquadScreen = UISquadSelect(screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	
	if( XComHQ.Squad[SquadScreen.m_iSelectedSlot].ObjectID > 0 )
	{
		//UISquadSelect(Screen).bDirty = true;
		SetDirty(true);
		SquadScreen.SnapCamera();
		`HQPRES.UIArmory_MainMenu(XComHQ.Squad[SquadScreen.m_iSelectedSlot], 'PreM_CustomizeUI', 'PreM_SwitchToSoldier', 'PreM_GoToLineup', 'PreM_CustomizeUI_Off', 'PreM_SwitchToLineup');
		`XCOMGRI.DoRemoteEvent('PreM_GoToSoldier');
	}
}

simulated function OnClickedSelectUnitButton()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	//UISquadSelect(Screen).bDirty = true;
	SetDirty(true);
	SquadScreen.SnapCamera();
	`HQPRES.UIPersonnel_SquadSelect(SquadScreen.ChangeSlot, SquadScreen.UpdateState, SquadScreen.XComHQ);
}

simulated function OnMouseEvent(int Cmd, array<string> Args)
{
	local string CallbackTarget;

	Super.OnMouseEvent(Cmd, Args);

	if(bDisabled) return;

	if(Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		CallbackTarget = Args[Args.Length - 2]; // -2 to account for bg within ButtonControls

		switch(CallbackTarget)
		{
		case "promoteButtonMC":         OnClickedPromote(); break;
		case "primaryWeaponButtonMC":   OnClickedPrimaryWeapon(); break;
		case "heavyWeaponButtonMC":     OnClickedHeavyWeapon(); break;
		case "dismissButtonMC":         OnClickedDismissButton(); break;
		case "selectUnitButtonMC":      OnClickedSelectUnitButton(); break;
		case "editButtonMC":            OnClickedEditUnitButton(); break;
		}
	}
}

simulated function SetDirty(bool bIsDirty, optional bool bMarkSquadSelectScreen = true)
{
	bDirty = bIsDirty;
	if(bMarkSquadSelectScreen)
		UISquadSelect(Screen).bDirty = bIsDirty;
}
simulated function Bool ListItemIsEmpty()
{
	return MC.GetBool("isEmpty");
}

simulated function bool HasUnit()
{
	return `XCOMHQ.Squad.Length > SlotIndex && `XCOMHQ.Squad[SlotIndex].ObjectID > 0;
}

//Returns the variable name that is set in actionscript (useful for 'invoke' functions)
simulated function String GetActionscriptButtonString(ESquadSelectButton Button)
{
	switch(Button)
	{
		case eSSB_Dismiss:		return "dismissButton";
		case eSSB_Promote:		return "promoteButton";
		case eSSB_WeaponPrime:	return "primaryWeaponButton";
		case eSSB_WeaponHeavy:	return "heavyWeaponButton";
		case eSSB_Edit:			return "editButton";
		default:				return "Error-ReturnCaseNotHandled";
	}
}

//simulates a mouse click
simulated function HandleButtonSelect()
{
	if(ListItemIsEmpty())
	{
		OnClickedSelectUnitButton();
		return;
	}

	switch(m_eActiveButton)
	{
		case eSSB_Dismiss:		OnClickedDismissButton(); break;
		case eSSB_Promote:		OnClickedPromote(); break;
		case eSSB_WeaponPrime:	OnClickedPrimaryWeapon(); break;
		case eSSB_WeaponHeavy:	OnClickedHeavyWeapon(); break;
		case eSSB_Edit:			OnClickedEditUnitButton(); break;
		case eSSB_Utility:
			UISquadSelect_UtilityItem(UtilitySlots.GetSelectedItem()).Button.Click();
			break;
		default:				break;
	}			
}

//Finds the next available index (looping if it moves out of bounds)
simulated function INT LoopButtonIndex(INT Index, Bool bDownward, INT MaxCount)
{
	Index = bDownward ? Index + 1 : Index - 1;
	if(Index < 0)
		Index = MaxCount - 1;
	Index = Index % MaxCount;

	return Index;
}

//Moves the focus of the button down the list of buttons with an enum in ESquadSelectButton
//checks for disabled states and skips them
simulated function ShiftButtonFocus(Bool bDownward)
{
	//removes focus from previous button/list
	HandleButtonFocus(m_eActiveButton, false);

	do
	{
		//Find index of next ListItem in sequence
		m_eActiveButton = ESquadSelectButton(LoopButtonIndex(INT(m_eActiveButton), bDownward, ESquadSelectButton.EnumCount));
	}
	//check for disabled buttons
	until( !IsActiveButtonDisabled() );

	//gives focus to the newly active button/list
	HandleButtonFocus(m_eActiveButton, true);	
}

//for cycling through the utility items while those are in focus
//iForceUtilityIndex attempts to set the focus directly (instead of shifting it). If that index is unavailable, it will continue through the loop
simulated function bool ShiftHorizontalFocus(Bool bIncreasing, optional int iForceUtilityIndex = -1)
{
	local int Index;
	local UISquadSelect_UtilityItem Item;

	if(m_eActiveButton == eSSB_Utility && UtilitySlots.ItemCount > 1)
	{
		//grabs Index locally to check for a change later
		Index = UtilitySlots.SelectedIndex;
		
		if(iForceUtilityIndex != -1)
		{
			if(bIncreasing)	Index = iForceUtilityIndex - 1;
			else			Index = iForceUtilityIndex + 1;
		}

		do
		{
			//grabs the next index
			if(bIncreasing)	Index++;
			else			Index--;

			if(Index < 0 || Index >= UtilitySlots.ItemCount)
				return false;

			Item = UISquadSelect_UtilityItem(UtilitySlots.GetItem(Index));
			if(Item == None) `log("ERROR: List Item found is not a UISquadSelect_ListItem. Breaking loop...");
		}
		//checks to make sure the next slot isn't disabled
		until(Item == None || !Item.Button.IsDisabled);

	//	//checks to make sure it didn't loop back to the original index
	//	//if(Index != UtilitySlots.SelectedIndex)
	//	{
			//remove current focus
			UtilitySlots.GetSelectedItem().OnLoseFocus();

			//Assign new current focus
			UtilitySlots.SetSelectedIndex(Index);

			//Give focus to new utility item
			Item.OnReceiveFocus();

			return true;
	//	}				
	}

	return false;
}

//checks for disabled states (used before giving buttons focus in vertical nav)
simulated function bool IsActiveButtonDisabled()
{
	local XComGameState_Unit Unit;

	//check for disabled buttons
	if(m_eActiveButton == eSSB_Promote)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));
		if(!Unit.ShowPromoteIcon())
			return true;
	}		
	if(bEditDisabled && m_eActiveButton == eSSB_Edit)
		return true;
	if(bDismissDisabled && m_eActiveButton == eSSB_Dismiss)
		return true;
	if(!HasHeavyWeapon() && m_eActiveButton == eSSB_WeaponHeavy)
		return true;
	
	return false;
}

//Handles the visuals to simulate mouse-hover focus
simulated function HandleButtonFocus(ESquadSelectButton ButtonControl, bool bFocusGiven)
{
	//all of the button assets are not visible if List Item is empty
	if(HandleEmptyListItemFocus())
		return;

	//GIVING focus to the button
	if(bFocusGiven)
	{
		if(m_eActiveButton == eSSB_Utility)
		{
			HandleUtilityItemFocus();
		}
		else
		{
			Invoke(GetActionscriptButtonString(m_eActiveButton) $ ".onReceiveFocus");
			if(m_eActiveButton == eSSB_Promote)
				MC.FunctionVoid("onReceiveFocus"); //needs to call manually because the actionscript turns the visual focus off when the other buttons lose focus
		}
	}
	//REMOVING focus to from button
	else
	{
		if(m_eActiveButton == eSSB_Utility)
			UtilitySlots.GetSelectedItem().OnLoseFocus();
		else
			Invoke(GetActionscriptButtonString(m_eActiveButton) $ ".onLoseFocus");
	}
}

simulated function HandleUtilityItemFocus()
{
	local int NewIndex;

	if(bReverseInitialUtilityFocus)
	{
		//should should only trigger on the 'initial' focus given when the list item is given focus
		//so that the utility item on the RIGHT if given focus when it's parent list's focus comes from the RIGHT		
		bReverseInitialUtilityFocus = false;
		//sets focus to the first available index from the top/right
		ShiftHorizontalFocus(false, UtilitySlots.ItemCount - 1);
		MC.FunctionVoid("onReceiveFocus"); //needs to call manually because the actionscript turns the visual focus off when the other buttons lose focus
		return;
	}
	//if the user has been navigating vertically within this list item, it will grab the most recent utility slot that was selected
	else if(UtilitySlots.SelectedIndex > 0)
		NewIndex = UtilitySlots.SelectedIndex;
	else
		NewIndex = 0;

	UtilitySlots.GetItem(NewIndex).OnReceiveFocus();
	UtilitySlots.SetSelectedIndex(NewIndex);
	MC.FunctionVoid("onReceiveFocus"); //needs to call manually because the actionscript turns the visual focus off when the other buttons lose focus
}

//Resets the focus in actionscript, ensuring proper visual highlights
simulated function RefreshFocus()
{
	local UISquadSelect SquadScreen;

	SquadScreen = UISquadSelect(Screen);
	if(SquadScreen != None && SquadScreen.m_iSelectedSlot == SlotIndex)
	{	
		//Tells actionscript that it lost focus so it can properly gain it again cleanly
		OnLoseFocus();

		//Delay needed to wait for Flash to clear the previous focus
		SetTimer(0.05f, false, 'DelayedRefreshFocus');
	}
}

//Called from a Timer in RefreshFocus()
simulated function DelayedRefreshFocus()
{	
	local UISquadSelect SquadScreen;

	SquadScreen = UISquadSelect(Screen);
	if(SquadScreen != None && SquadScreen.m_iSelectedSlot == SlotIndex)
	{	
		OnReceiveFocus();
		SetSquadSelectButtonFocus();
	}
}
//------------------------------------------------------

simulated function AS_SetFilled( string firstName, string lastName, string nickName,
								 string classIcon, string rankIcon, string editLabel, string dismissLabel, 
								 string primaryWeaponLabel, string primaryWeaponDescription,
								 string heavyWeaponLabel, string heavyWeaponDescription,
								 string promoteLabel, bool isPsiPromote, string className )
{
	mc.BeginFunctionOp("setFilledSlot");
	mc.QueueString(firstName);
	mc.QueueString(lastName);
	mc.QueueString(nickName);
	mc.QueueString(classIcon);
	mc.QueueString(rankIcon);
	mc.QueueString(editLabel);
	mc.QueueString(dismissLabel);
	mc.QueueString(primaryWeaponLabel);
	mc.QueueString(primaryWeaponDescription);
	mc.QueueString(heavyWeaponLabel);
	mc.QueueString(heavyWeaponDescription);
	mc.QueueString(promoteLabel);
	mc.QueueBoolean(isPsiPromote);
	mc.QueueString(className);
	mc.EndOp();
}

simulated function AS_HasHeavyWeapon( bool bHasHeavyWeapon )
{
	mc.FunctionBool("setHeavyWeapon", bHasHeavyWeapon);
}

simulated function AS_SetEmpty( string label )
{
	mc.FunctionString("setEmptySlot", label);
}

simulated function AS_SetBlank( string label )
{
	mc.FunctionString("setBlankSlot", label);
}

simulated function AS_SetDisabled( string label )
{
	mc.FunctionString("setDisabledSlot", label);
}

simulated function AS_SetUnitHealth(int CurrentHP, int MaxHP)
{
	mc.BeginFunctionOp("setUnitHealth");
	mc.QueueNumber(CurrentHP);
	mc.QueueNumber(MaxHP);
	mc.EndOp();
}

//Attempts to set focus to the button, will grab the next button in line if that's not possible
simulated function SetSquadSelectButtonFocus(optional int ButtonEnumAsInt = 0, optional bool bReverseFocusIfUtility = false) //ESquadSelectButton
{
	local ESquadSelectButton ButtonEnum;

	ButtonEnum = ESquadSelectButton(ButtonEnumAsInt);
	
	//allows the player to move fluidly Right->Left while selecting a Utility item and there are more than 1
	if(bReverseFocusIfUtility && ButtonEnum == eSSB_Utility)
		bReverseInitialUtilityFocus = true;

	//If the previous listItem had a heavy weapon selected and this does not have that enabled, move to a lower index
	if(ButtonEnum == eSSB_WeaponHeavy && !HasHeavyWeapon())
		ButtonEnum = ESquadSelectButton(ButtonEnum - 1);

	//sets the active button to a lower increment b/c ShiftButtonFocus() always increases by at least 1
	if(ButtonEnum <= 0 || ButtonEnum >= ESquadSelectButton.EnumCount) //Desired index is 0
		m_eActiveButton = ESquadSelectButton(ESquadSelectButton.EnumCount - 1);
	else //Desired index is not 0
		m_eActiveButton = ESquadSelectButton(ButtonEnum - 1);

	//loops through buttons until it finds one that can be given focus (always increases m_eActiveButton by 1)
	ShiftButtonFocus(true);
}
// Don't propagate focus changes to children
simulated function OnReceiveFocus()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	//if(SquadScreen != none)
	if(SquadScreen != none && SquadScreen.m_iSelectedSlot != SlotIndex)
	{
		SquadScreen.m_iSelectedSlot = SlotIndex;
		SquadScreen.m_kSlotList.SetSelectedItem(self);
	}
	Invoke("onReceiveFocus");
	if(!bIsFocused)
		bIsFocused = true;
}

simulated function OnLoseFocus()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	if(SquadScreen != none)
	{
		SquadScreen.m_iSelectedSlot = SlotIndex;
		SquadScreen.m_kSlotList.SetSelectedItem(none);
	}
	Invoke("onLoseFocus");
	if(bIsFocused)
	{
		bIsFocused = false;
		HandleButtonFocus(m_eActiveButton,false);
		if(UtilitySlots != None)
		{
			UtilitySlots.SelectedIndex = 0;
			bReverseInitialUtilityFocus = false;
		}		
	}	
}

//Called when there is a focus change in 'HandleButtonFocus', returns TRUE if handled and no other focus changes are needed
simulated function bool HandleEmptyListItemFocus()
{
	if(GetUnitRef().ObjectID <= 0) //Will return true if the ListItem is empty
	{
		if(bIsFocused)
		{
			Invoke("selectUnitButton.onReceiveFocus");
		}
		else
		{
			Invoke("selectUnitButton.onLoseFocus");
		}

		//In actionscript, this function detects whether or not the button is in focus and changes the visuals accordingly
		MC.FunctionVoid("realizeUnitFocus");

		return true;
	}

	return false;
}

defaultproperties
{
	LibID = "SquadSelectListItem";
	width = 282;
	bIsNavigable = true;
	bCascadeFocus = false;
}

//------------------------------------------------------