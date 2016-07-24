//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShellNarrativeContent.uc
//  AUTHOR:  Mark Nauta --2/4/2016

//  PURPOSE: Controls enabling optional narrative content for the campaign. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIShellNarrativeContent extends UIScreen
	dependson(XComOnlineProfileSettingsDataBlob);

var localized string NarrativeContentTitle;

var UIList           m_List;
var UIButton         m_CancelButton;
var UILargeButton    m_StartButton;

var array<name> EnabledOptionalNarrativeDLC; // DLC Identifiers with enabled optional narrative content
var private array<X2DownloadableContentInfo> DLCInfos; // All DLC infos that have optional narrative content (forms the list of checkboxes)
var private bool bCheckboxUpdate;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_List = Spawn(class'UIList', self);
	m_List.InitList('difficultyListMC');
	m_List.Navigator.LoopSelection = false;
	m_List.Navigator.LoopOnReceiveFocus = true;
	m_List.SetHeight(330);
	m_List.OnItemClicked = OnClicked;
	m_List.OnSelectionChanged = OnSelectedItemChanged;

	m_CancelButton = Spawn(class'UIButton', self);
	m_CancelButton.InitButton('difficultyCancelButton', class'UIUtilities_Text'.default.m_strGenericCancel, OnButtonCancel);
	m_Cancelbutton.DisableNavigation();

	m_StartButton = Spawn(class'UILargeButton', self);
	m_StartButton.InitLargeButton('difficultyLaunchButton', class'UIUtilities_Text'.default.m_strGenericAccept, "", ConfirmNarrativeContent);

	Navigator.SetSelected(m_StartButton);
	m_List.Navigator.SetSelected(m_List.GetItem(m_List.SelectedIndex));
}

simulated function OnInit()
{
	super.OnInit();

	SetX(500);
	BuildMenu();

	//If we don't have DLC to show, then skip right over this screen. 
	if(DLCInfos.length == 0)
		ConfirmNarrativeContent(none);
}

simulated function BuildMenu()
{
	local XComOnlineProfileSettings m_kProfileSettings;
	local array<X2DownloadableContentInfo> AllDLCInfos;
	local array<NarrativeContentFlag> AllDLCFlags;
	local NarrativeContentFlag DLCFlag;
	local int idx, DLCIndex;
	local bool bChecked, bProfileModified;

	m_List.ClearItems();
	DLCInfos.length = 0;

	AS_SetNarrativeContentMenu(NarrativeContentTitle, class'UIUtilities_Text'.default.m_strGenericCancel, class'UIUtilities_Text'.default.m_strGenericContinue);

	// Grab DLC infos for quick access to identifier and localized strings
	m_kProfileSettings = `XPROFILESETTINGS;
	AllDLCFlags = m_kProfileSettings.Data.m_arrNarrativeContentEnabled;
	AllDLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);

	for(idx = 0; idx < AllDLCInfos.Length; idx++)
	{
		if(AllDLCInfos[idx].bHasOptionalNarrativeContent)
		{
			bChecked = true; // All DLCs start with narrative content enabled
			
			DLCIndex = AllDLCFlags.Find('DLCName', name(AllDLCInfos[idx].DLCIdentifier));
			if (DLCIndex != INDEX_NONE)
			{
				bChecked = AllDLCFlags[DLCIndex].NarrativeContentEnabled;
			}
			else
			{
				DLCFlag.DLCName = name(AllDLCInfos[idx].DLCIdentifier);
				DLCFlag.NarrativeContentEnabled = bChecked;
				m_kProfileSettings.Data.m_arrNarrativeContentEnabled.AddItem(DLCFlag);
				
				bProfileModified = true;
			}

			DLCInfos.AddItem(AllDLCInfos[idx]);
			CreateListItem(AllDLCInfos[idx].NarrativeContentLabel, bChecked);

			if(bChecked)
			{
				EnabledOptionalNarrativeDLC.AddItem(Name(AllDLCInfos[idx].DLCIdentifier));
			}
		}
	}
	if(DLCInfos.length > 0)
		OnSelectedItemChanged(m_List, 0);

	if (bProfileModified)
	{
		`ONLINEEVENTMGR.SaveProfileSettings(true);
	}
}

simulated function CreateListItem(string Label, bool bChecked)
{
	local UIMechaListItem SpawnedItem;

	// @bsteiner - DLCInfos have a few values you'll need
	// DLCIdentifier - store these in EnabledOptionalNarrativeDLC, will want to pass in CreateStrategyGameStart
	// NarrativeContentLabel - Label for the checkbox
	// NarrativeContentSummary - Description to appear when hovering over the option (not tooltip)

	SpawnedItem = Spawn(class'UIMechaListItem', m_List.ItemContainer);
	SpawnedItem.bAnimateOnInit = false;
	SpawnedItem.InitListItem();
	SpawnedItem.UpdateDataCheckbox(Label, "", bChecked, OnCheckboxChanged);
}

simulated function OnCheckboxChanged(UICheckbox CheckboxControl)
{
	bCheckboxUpdate = true;
}

simulated function OnClicked(UIList ContainerList, int ItemIndex)
{
	local XComOnlineProfileSettings m_kProfileSettings;
	local array<NarrativeContentFlag> AllDLCFlags;
	local UICheckbox checkedBox;
	local int DLCFlagIndex;
	
	checkedBox = UIMechaListItem(m_List.GetItem(ItemIndex)).Checkbox;

	if(bCheckboxUpdate)
	{
		m_kProfileSettings = `XPROFILESETTINGS;
			AllDLCFlags = m_kProfileSettings.Data.m_arrNarrativeContentEnabled;
		DLCFlagIndex = AllDLCFlags.Find('DLCName', Name(DLCInfos[ItemIndex].DLCIdentifier));

		if(DLCFlagIndex != INDEX_NONE && AllDLCFlags[DLCFlagIndex].NarrativeContentEnabled && !checkedBox.bChecked)
		{
			// Only turn the flag off if it is true, so should only happen once
			m_kProfileSettings.Data.m_arrNarrativeContentEnabled[DLCFlagIndex].NarrativeContentEnabled = false;
			`ONLINEEVENTMGR.SaveProfileSettings(true);
		}

		if(checkedBox.bChecked)
			EnabledOptionalNarrativeDLC.AddItem(Name(DLCInfos[ItemIndex].DLCIdentifier));
		else
			EnabledOptionalNarrativeDLC.RemoveItem(Name(DLCInfos[ItemIndex].DLCIdentifier));

		bCheckboxUpdate = false;
	}
}

simulated function OnSelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	AS_SetDifficultyDesc(DLCInfos[ItemIndex].NarrativeContentSummary);
}

simulated function AS_SetNarrativeContentMenu(string title, string launchLabel, string CancelLabel)
{
	Movie.ActionScriptVoid(MCPath$".UpdateNarrativeContentMenu");
}
simulated function AS_SetTitle(string title)
{
	Movie.ActionScriptVoid(MCPath$".SetTitle");
}
simulated function AS_SetDifficultyDesc(string desc)
{
	Movie.ActionScriptVoid(MCPath$".SetDifficultyDesc");
}

simulated public function OnButtonCancel(UIButton ButtonControl)
{
	if(bIsInited)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		Movie.Stack.Pop(self);
	}
}

simulated public function ConfirmNarrativeContent(UIButton ButtonControl)
{
	local UIShellDifficulty difficultyMenu;
	difficultyMenu = UIShellDifficulty(Movie.Stack.GetFirstInstanceOf(class'UIShellDifficulty'));
	Movie.Stack.PopUntilClass(class'UIShellDifficulty');
	difficultyMenu.EnabledOptionalNarrativeDLC = EnabledOptionalNarrativeDLC;
	difficultyMenu.OnDifficultyConfirm(ButtonControl);
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIPanel CurrentSelection;

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:

		CurrentSelection = Navigator.GetSelected();
		if(CurrentSelection != None)
		{
			bHandled = CurrentSelection.OnUnrealCommand(cmd, arg);
		}
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnButtonCancel(none);
		break;

	default:
		bHandled = false;
	}


	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================
//		CLEANUP:
//==============================================================================

event Destroyed()
{
	super.Destroyed();
}

DefaultProperties
{
	Package = "/ package/gfxDifficultyMenu/DifficultyMenu";
	LibID = "DifficultyMenu_NarrativeContent"

		InputState = eInputState_Consume;
	bConsumeMouseEvents = true;
	bHideOnLoseFocus = true;

}