//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_CharacterTemplateSelector.uc
//  AUTHOR:  Todd Smith  --  9/4/2015
//  PURPOSE: List character templates and allow one to be chosen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_CharacterTemplateSelector extends UIInventory;

var localized string            m_strCharacterHeaderText;
var localized string			m_strAdventPrefix;
var localized string			m_strSoldierClassDivider;

var X2MPCharacterTemplate m_kCurrentCharacterTemplate;
var UISoldierHeader SoldierHeader;
var UINavigationHelp NavHelp;

delegate OnAccept(X2MPCharacterTemplate kSelectedTemplate);
delegate OnBack();

function InitCharacterTemplateSelector(delegate<OnAccept> InitOnAccept, delegate<OnBack> InitOnCancel)
{
	OnAccept = InitOnAccept;
	OnBack = InitOnCancel;

	SoldierHeader = Spawn(class'UISoldierHeader', self).InitSoldierHeader();
	SoldierHeader.bHideFlag = true;

	SetCategory(m_strCharacterHeaderText);
	SetBuiltLabel(class'X2MPData_Shell'.default.m_strPoints);
	Movie.UpdateHighestDepthScreens();

	NavHelp = Pc.Pres.m_kNavHelpScreen.NavHelp;
	UpdateNavHelp();

	PopulateData();
	
	//SetX(260); // center the screen
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(Cancel);
}

simulated function PopulateData()
{
	local int i;
	local array<name> arrNames;
	local X2MPCharacterTemplate MPCharTemplate;
	local X2MPCharacterTemplateManager MPCharTemplateManager;
	local X2CharacterTemplate CharTemplate;
	local X2CharacterTemplateManager CharTemplateManager;
	local X2SoldierClassTemplateManager SoldierClassManager;
	local UIInventory_ListItem kListItem;
	local string strDisplayText;
	List.ItemPadding = 0;

	MPCharTemplateManager = class'X2MPCharacterTemplateManager'.static.GetMPCharacterTemplateManager();
	MPCharTemplateManager.GetTemplateNames(arrNames);
	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	SoldierClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	for (i = 0; i < arrNames.Length; ++i)
	{
		MPCharTemplate = MPCharTemplateManager.FindMPCharacterTemplate(arrNames[i]);
		if(MPCharTemplate == none)
			continue;

		if(i == 0)
			SelectCharacterTemplate(MPCharTemplate);

		strDisplayText = "";
		
		CharTemplate = CharTemplateManager.FindCharacterTemplate(MPCharTemplate.CharacterTemplateName);

		if(CharTemplate != none)
		{
			if(CharTemplate.DataName == 'Soldier' && MPCharTemplate.DataName != 'PsiOperative')
			{
				strDisplayText $= SoldierClassManager.FindSoldierClassTemplate(MPCharTemplate.SoldierClassTemplateName).DisplayName $ m_strSoldierClassDivider;
			}
			else if(CharTemplate.bIsAdvent)
			{
				strDisplayText $= m_strAdventPrefix;
			}
		}

		strDisplayText $= MPCharTemplate.DisplayName;
	
		kListItem = UIInventory_ListItem(List.CreateItem(class'UIInventory_ListItem'));
		kListItem.InitListItem(strDisplayText);
		kListItem.UpdateQuantity(MPCharTemplate.Cost);
		kListItem.SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, class'UIMPShell_SquadUnitInfoItem'.default.m_strAddUnitText, 80, , AcceptUnit);
		kListItem.metadataObject = MPCharTemplate;
	}
}

simulated function SelectedItemChanged(UIList listControl, int itemIndex)
{
	SelectCharacterTemplate(X2MPCharacterTemplate(UIListItemString(listControl.GetItem(itemIndex)).metadataObject));
	`log(self $ "::" $ GetFuncName() @ "itemIndex=" $ itemIndex @ "character=" $ m_kCurrentCharacterTemplate.DisplayName,, 'uixcom_mp');
}

simulated function AcceptUnit(UIButton button)
{
	AcceptCurrentTemplate();
}

function SelectCharacterTemplate(X2MPCharacterTemplate kCharacterTemplate)
{
	local XComGameState SquadState;
	local XComGameState_Unit TempUnit;
	local X2CharacterTemplate CharTemplate;
	local X2CharacterTemplateManager CharTemplateManager;
	local X2SoldierClassTemplateManager SoldierClassManager;
	local string strDisplayText;

	m_kCurrentCharacterTemplate = kCharacterTemplate;
	ItemCard.PopulateUnitCard(kCharacterTemplate);

	SquadState = UIMPShell_SquadEditor(Movie.Pres.ScreenStack.GetFirstInstanceOf(class'UIMPShell_SquadEditor')).m_kSquadLoadout;
	TempUnit = XComShellPresentationLayer(Movie.Pres).m_kMPShellManager.CreateMPUnitState(kCharacterTemplate, SquadState);
	class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, TempUnit, true, SquadState);

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	SoldierClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	strDisplayText = "";
	CharTemplate = CharTemplateManager.FindCharacterTemplate(m_kCurrentCharacterTemplate.CharacterTemplateName);

	if(CharTemplate != none)
	{
		if(CharTemplate.DataName == 'Soldier' && m_kCurrentCharacterTemplate.DataName != 'PsiOperative')
		{
			strDisplayText $= SoldierClassManager.FindSoldierClassTemplate(m_kCurrentCharacterTemplate.SoldierClassTemplateName).DisplayName $ m_strSoldierClassDivider;
		}
		else if(CharTemplate.bIsAdvent)
		{
			strDisplayText $= m_strAdventPrefix;
		}
	}

	strDisplayText $= m_kCurrentCharacterTemplate.DisplayName;

	SoldierHeader.strMPForceName = strDisplayText;
	
	SoldierHeader.PopulateData(TempUnit, , , SquadState);
}

function AcceptCurrentTemplate()
{
	`log(self $ "::" $ GetFuncName() @ "character=" $ m_kCurrentCharacterTemplate.CharacterTemplateName,, 'uixcom_mp');
	if(OnAccept != none)
		OnAccept(m_kCurrentCharacterTemplate);
	else
		CloseScreen();
}

function Cancel()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(OnBack != none)
		OnBack();
	else
		CloseScreen();
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
			AcceptCurrentTemplate();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			Cancel();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	CameraTag="UIDisplay_MPShell";
	DisplayTag="UIDisplay_MPShell";
	Package = "/ package/gfxMultiplayerCharacterSelector/MultiplayerCharacterSelector";
}