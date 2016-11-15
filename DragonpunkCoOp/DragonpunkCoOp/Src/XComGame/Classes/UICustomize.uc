//---------------------------------------------------------------------------------------
//  FILE:   UICustomize.uc
//  AUTHOR: Sam Batista --  3/18/2015
//  PURPOSE:Soldier category options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize extends UIScreen
	dependson(UIColorSelector)
	config(UI);

// MEMBERS
var XComCharacterCustomization CustomizeManager;

// GAME
var public StateObjectReference     UnitRef; 
var public XComGameState_Unit       Unit;
var bool				bInArmory;
var bool				bInMP;
var name               IdleAnimName;

// UI
var UINavigationHelp   NavHelp;
var UIBGBox		    ListBG;
var UIList				List;
var UISoldierHeader    Header;
var string             CameraTag;
var name               DisplayTag;
var int                FontSize;
var bool               bDisableVeteranOptions;
var bool               bIsSuperSoldier;

var config int ColorSelectorX;
var config int ColorSelectorY;
var config int ColorSelectorWidth;
var config int ColorSelectorHeight;
var protected UIColorSelector ColorSelector; 

// TOOLTIPS
var localized string m_strIsSuperSoldier;
var localized string m_strNeedsVeteranStatus;
var localized string m_strRemoveHelmet;
var localized string m_strNoVariations;
var localized string m_strIncompatibleStatus;

delegate static bool IsSoldierEligible(XComGameState_Unit Soldier);

// FUNCTIONS
//----------------------------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	// Overwritten in UICustomize_Trait
	IsSoldierEligible = CanCycleTo;
	bInArmory = (Movie.Stack.GetLastInstanceOf(class'UIArmory') != none);
	bInMP = (Movie.Stack.GetLastInstanceOf(class'UIMPShell_MainMenu') != none) || (Movie.Stack.GetLastInstanceOf(class'UIMPShell_Lobby') != none) ;

	FontSize = bIsIn3D ? class'UIUtilities_Text'.const.BODY_FONT_SIZE_3D : class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D;

	// HAX: Get the Unit from the customization menu screen since the customization manager might have been killed by the previous screen
	UpdateCustomizationManager();
	CustomizeManager = Movie.Pres.GetCustomizeManager();

	Unit = GetUnit();

	// ---------------------------------------------------------

	ListBG = Spawn(class'UIBGBox', self).InitBG('armoryMenuBG');
	List = Spawn(class'UIList', self).InitList('armoryMenuList');
	List.ItemPadding = 5;
	List.bStickyHighlight = false;
	List.width = 538;
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	Header = Spawn(class'UISoldierHeader', self);
	Header.bSoldierStatsHidden = true;
	Header.InitSoldierHeader(UnitRef);
	Header.HideSoldierStats();

	// ---------------------------------------------------------
	
	if(bInArmory)
		NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	else
		NavHelp = InitController.Pres.GetNavHelp();

	// We get the list size from flash, so wait until we have gotten that callback before updating data
	List.AddOnInitDelegate(OnListInited);

	Movie.UpdateHighestDepthScreens(); 
}

// Separate function so it can be overwritten by class specific customization menus
simulated function UpdateCustomizationManager()
{
	if (Movie.Pres.m_kCustomizeManager == none)
	{
		Unit = UICustomize_Menu(Movie.Stack.GetScreen(class'UICustomize_Menu')).Unit;
		UnitRef = UICustomize_Menu(Movie.Stack.GetScreen(class'UICustomize_Menu')).UnitRef;
		Movie.Pres.InitializeCustomizeManager(Unit);
	}
}

simulated function XComGameState_Unit GetUnit()
{
	if(Movie.Pres.m_kCustomizeManager != none)
	{
		Unit =  Movie.Pres.GetCustomizationUnit();
		UnitRef =  Movie.Pres.GetCustomizationUnitRef();

		bIsSuperSoldier = Unit.bIsSuperSoldier;
		bDisableVeteranOptions = !Unit.IsVeteran() && !InShell();
	}

	return Unit;
}

simulated function OnListInited(UIPanel Panel)
{
	class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), bInArmory ? `HQINTERPTIME : 0.0);

	UpdateNavHelp();
	UpdateData();
}

simulated function UIMechaListItem GetListItem(int ItemIndex, optional bool bDisableItem, optional string DisabledReason)
{
	local UIMechaListItem CustomizeItem;
	local UIPanel Item;

	if(List.ItemCount <= ItemIndex)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', List.ItemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem();
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		CustomizeItem = UIMechaListItem(Item);
	}

	CustomizeItem.SetDisabled(bDisableItem, DisabledReason != "" ? DisabledReason : m_strNeedsVeteranStatus);

	return CustomizeItem;
}

simulated function UIColorSelector GetColorSelector(optional array<string> Colors,
													optional delegate<UIColorSelector.OnPreviewDelegate> PreviewDelegate,
													optional delegate<UIColorSelector.OnSetDelegate> SetDelegate,
													optional int Selection = 0)
{
	if(ColorSelector == none)
	{
		List.Hide();
		ColorSelector = Spawn(class'UIColorSelector', self);
		ColorSelector.InitColorSelector(, ColorSelectorX, ColorSelectorY, ColorSelectorWidth, ColorSelectorHeight, Colors, PreviewDelegate, SetDelegate, Selection);
		ColorSelector.SetSelectedNavigation();
		ListBG.ProcessMouseEvents(ColorSelector.OnChildMouseEvent);
	}
	return ColorSelector;
}

simulated function HideListItems()
{
	local int i;
	for(i = 0; i < List.ItemCount; ++i)
	{
		List.GetItem(i).Hide();
	}
}

simulated function ShowListItems()
{
	local int i;
	for(i = 0; i < List.ItemCount; ++i)
	{
		List.GetItem(i).Show();
	}
}

simulated function UpdateData()
{
	if( ColorSelector != none )
	{
		CloseColorSelector();
	}

	// Override in child classes for custom behavior
	Header.PopulateData(Unit);

	if(CustomizeManager.ActorPawn != none)
	{
		IdleAnimName = Unit.GetPersonalityTemplate().IdleAnimName;

		// Play the "By The Book" idle to minimize character overlap with UI elements
		XComHumanPawn(CustomizeManager.ActorPawn).PlayHQIdleAnim(IdleAnimName);

		// Cache desired animation in case the pawn hasn't loaded the customization animation set
		XComHumanPawn(CustomizeManager.ActorPawn).CustomizationIdleAnim = IdleAnimName;

		// Assign the actor pawn to the mouse guard so the pawn can be rotated by clicking and dragging
		UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn')).SetActorPawn(CustomizeManager.ActorPawn);
	}
}

simulated function UpdateNavHelp()
{
	local int i;
	local string PrevKey, NextKey;
	local XGParamTag LocTag;

	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	if(`ISCONTROLLERACTIVE)
		NavHelp.AddSelectNavHelp();

	if( IsSoldierEligible == none )
		IsSoldierEligible = CanCycleTo;

	if( Movie.IsMouseActive() && !InShell() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitRef, IsSoldierEligible) )
	{
		LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
		PrevKey = `XEXPAND.ExpandString(class'UIArmory'.default.PrevSoldierKey);
		LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
		NextKey = `XEXPAND.ExpandString(class'UIArmory'.default.NextSoldierKey);

		NavHelp.SetButtonType("XComButtonIconPC");
		i = eButtonIconPC_Prev_Soldier;
		NavHelp.AddCenterHelp( string(i), "", PrevSoldier, false, PrevKey);
		i = eButtonIconPC_Next_Soldier; 
		NavHelp.AddCenterHelp( string(i), "", NextSoldier, false, NextKey);
		NavHelp.SetButtonType("");
	}

	NavHelp.Show();
}

simulated function PrevSoldier()
{
	local StateObjectReference NewUnitRef;
	if( class'UIUtilities_Strategy'.static.CycleSoldiers(-1, UnitRef, IsSoldierEligible, NewUnitRef) )
		CycleToSoldier(NewUnitRef);
}

simulated function NextSoldier()
{
	local StateObjectReference NewUnitRef;
	if( class'UIUtilities_Strategy'.static.CycleSoldiers(1, UnitRef, IsSoldierEligible, NewUnitRef) )
		CycleToSoldier(NewUnitRef);
}

simulated static function bool CanCycleTo(XComGameState_Unit NewUnit)
{
	return NewUnit.IsSoldier() && !NewUnit.IsDead();
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local int i;
	local bool bRefreshedMgr;
	local UICustomize CustomizeScreen;
	local UIScreenStack ScreenStack;
	local UICustomize TopCustomizeScreen;
	local XComGameState_Unit NewUnit;

	// Update armory screens that might be bellow this screen
	class'UIArmory'.static.CycleToSoldier(NewRef);

	ScreenStack = `SCREENSTACK;
	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		CustomizeScreen = UICustomize(ScreenStack.Screens[i]);
		// Skip this logic for UICustomize_Trait screen because we want to pop it off the stack if the player switch soldiers
		if (CustomizeScreen != none && UICustomize_Trait(CustomizeScreen) == none)
		{
			// Close the color selector before switching units (canceling any changes not yet confirmed)
			if (CustomizeScreen.ColorSelector != none)
				CustomizeScreen.CloseColorSelector(true);

			if (!bRefreshedMgr)
			{
				// This code is always run on the first instance of UICustomize in the stack
				NewUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(NewRef.ObjectID));

				// If the new unit uses a different customization class, the UICustomize menus must be reset
				if (NewUnit.GetMyTemplate().CustomizationManagerClass != CustomizeScreen.CustomizeManager.Class)
				{
					// Pop all of the UICustomize menus, then re-add the appropriate Customization menus for the new unit
					ScreenStack.PopUntil(CustomizeScreen);
					ScreenStack.PopFirstInstanceOfClass(class'UICustomize');
					`HQPRES.UICustomize_Menu(NewUnit, none);
					break;
				}
				else
				{
					CustomizeScreen.CustomizeManager.Refresh(CustomizeScreen.Unit, NewUnit);
					bRefreshedMgr = true;
				}
			}

			CustomizeScreen.UnitRef = NewRef;
			CustomizeScreen.Header.UnitRef = NewRef;
			CustomizeScreen.Unit = CustomizeScreen.GetUnit();

			CustomizeScreen.UpdateData();

			// Signal focus change (even if focus didn't actually change) to ensure modders get notified of soldier switching
			CustomizeScreen.SignalOnReceiveFocus();

			TopCustomizeScreen = CustomizeScreen;
		}
	}

	//Pop to the topmost customize screen when we switch soldiers - override export dialogs, etc.
	if (TopCustomizeScreen != None)
		ScreenStack.PopUntil(TopCustomizeScreen);
}

simulated function OnReceiveFocus()
{
	local UIScreenStack ScreenStack;
	local UICustomize CustomizeScreen;
	local int idx;

	super.OnReceiveFocus();

	Unit = GetUnit();
	
	// If the unit was modified and requires an update to the customization manager 
	if (Unit.GetMyTemplate().CustomizationManagerClass != CustomizeManager.Class)
	{
		// Clear all of the old customization menus
		ScreenStack = `SCREENSTACK;
		for (idx = ScreenStack.Screens.Length - 1; idx >= 0; --idx)
		{
			CustomizeScreen = UICustomize(ScreenStack.Screens[idx]);
			// Skip this logic for UICustomize_Trait screen because we always want to pop it off the stack
			if (CustomizeScreen != none && UICustomize_Trait(CustomizeScreen) == none)
			{
				ScreenStack.PopUntil(CustomizeScreen);
				ScreenStack.PopFirstInstanceOfClass(class'UICustomize'); // Should always be a Customization Menu class. Will deactivate the old customization manager.

				// Add the customization menu for the new class back to the stack. Will also refresh and update the customization manager.
				Movie.Pres.UICustomize_Menu(Unit, none); // The update code below will be called on the new menu
				break;
			}
		}
	}
	else // Update normally
	{
		UpdateNavHelp();
		UpdateData();

		if (bIsIn3D) UIMovie_3D(Movie).ShowDisplay(DisplayTag);

		if (XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none && `HQPRES != none)
		{
			`HQPRES.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
		}
		else
		{
			XComShellPresentationLayer(`PRESBASE).CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
		}
		CustomizeManager.MoveCosmeticPawnOnscreen();
		CustomizeManager.LastSetCameraTag = name(CameraTag);

		// Make sure the list processes events from the BG (this gets overridden by the color selector).
		ListBG.ProcessMouseEvents(List.OnChildMouseEvent);
	}
}

simulated function Show()
{
	super.Show();
	NavHelp.Show();
}

simulated function Hide()
{
	super.Hide();
	NavHelp.Hide();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (ColorSelector != none && ColorSelector.OnUnrealCommand(cmd, arg))
		return true;

	if (List != none && List.OnUnrealCommand(cmd, arg))
	{
		return true;
	}

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_MOUSE_5:
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			if( bInArmory && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitRef, CanCycleTo) )
				NextSoldier();
			else if(bInArmory)
				Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			return true;
		case class'UIUtilities_Input'.const.FXS_MOUSE_4:
		case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			if( bInArmory && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitRef, CanCycleTo) )
				PrevSoldier();
			else if(bInArmory)
				Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

// override in child classes to provide custom behavior
simulated function OnCancel()
{
	CloseScreen();
}

simulated function CloseScreen()
{	
	if(ColorSelector != none)
	{
		CloseColorSelector(true);
	}
	else
	{
		if(bIsIn3D) UIMovie_3D(Movie).HideDisplay(DisplayTag);
		NavHelp.ClearButtonHelp();
		super.CloseScreen();
	}
}

simulated function CloseColorSelector(optional bool bCancelColorSelection)
{
	if(bCancelColorSelection)
		ColorSelector.OnCancelColor();

	ColorSelector.Remove();
	ColorSelector = none;

	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);
	List.Show();
	List.SetSelectedNavigation();
}

simulated function bool InShell()
{
	return XComShellPresentationLayer(Movie.Pres) != none;
}

//==============================================================================

defaultproperties
{
	LibID           = "CustomizeScreenMC";
	Package         = "/ package/gfxArmory/Armory";
	CameraTag       = "UIBlueprint_CustomizeMenu";
	DisplayTag      = "UIBlueprint_CustomizeMenu";
	bConsumeMouseEvents = true;
	MouseGuardClass = class'UIMouseGuard_RotatePawn';
}
