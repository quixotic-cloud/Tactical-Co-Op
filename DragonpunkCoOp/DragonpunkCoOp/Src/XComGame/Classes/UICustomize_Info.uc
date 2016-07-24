//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Info.uc
//  AUTHOR:  Brit Steiner --  8/28/2014
//  PURPOSE: Edit the soldier's name and nationality. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_Info extends UICustomize;

const MAX_CHARACTERS_BIO = 3000;

//----------------------------------------------------------------------------
// MEMBERS

var localized string m_strTitle;
var localized string m_strFirstNameLabel;
var localized string m_strLastNameLabel;
var localized string m_strNicknameLabel;
var localized string m_strEditBiography;
var localized string m_strBiographyLabel;
var localized string m_strNationality;
var localized string m_strGender;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function UpdateData()
{
	local int i;
	local EUIState ColorState;
	local CharacterPoolManager cpm;
	local int currentSel;
	currentSel = List.SelectedIndex;

	super.UpdateData();

	// Do we have any separated data to request? 
	if(!bInArmory)
	{
		cpm = CharacterPoolManager( `XENGINE.GetCharacterPoolManager() );
		cpm.OnCharacterModified(Unit);
	}

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// FIRST NAME
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataDescription(m_strFirstNameLabel, OpenFirstNameInputBox)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// LAST NAME
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataDescription(m_strLastNameLabel, OpenLastNameInputBox)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// NICKNAME
	//-----------------------------------------------------------------------------------------
	ColorState = (bIsSuperSoldier || (!Unit.IsVeteran() && !InShell())) ? eUIState_Disabled : eUIState_Normal;
	GetListItem(i++)
		.UpdateDataDescription(m_strNickNameLabel, OpenNickNameInputBox)
		.SetDisabled(bIsSuperSoldier || (!Unit.IsVeteran() && !InShell()), bIsSuperSoldier ? m_strIsSuperSoldier : m_strNeedsVeteranStatus); // Don't disable in the shell. 

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// BIO
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataDescription(m_strEditBiography, OpenBiographyInputBox)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// NATIONALITY
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Country)$ m_strNationality, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Country, ColorState, FontSize), CustomizeCountry)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// GENDER
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Gender)$ m_strGender, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Gender, ColorState, FontSize), CustomizeGender)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	AS_SetCharacterBio(m_strBiographyLabel, class'UIUtilities_Text'.static.GetSizedText(Unit.GetBackground(), FontSize));

	if (currentSel > -1 && currentSel < List.ItemCount)
	{
		List.Navigator.SetSelected(List.GetItem(currentSel));
	}
	else
	{
		List.Navigator.SetSelected(List.GetItem(0));
	}
}

// -----------------------------------------------------------------------

simulated function OpenFirstNameInputBox() { CustomizeManager.EditText( eUICustomizeCat_FirstName ); }
simulated function OpenLastNameInputBox()  { CustomizeManager.EditText( eUICustomizeCat_LastName ); }
simulated function OpenNickNameInputBox()  { CustomizeManager.EditText( eUICustomizeCat_NickName ); }

simulated function OpenBiographyInputBox() 
{
	local TInputDialogData kData;

	kData.strTitle = m_strEditBiography;
	kData.iMaxChars = MAX_CHARACTERS_BIO;
	kData.strInputBoxText = Unit.GetBackground();
	kData.fnCallback = OnBackgroundInputBoxClosed;
	kData.DialogType = eDialogType_MultiLine;

	Movie.Pres.UIInputDialog(kData);
}

function OnBackgroundInputBoxClosed(string text)
{
	CustomizeManager.UpdatedUnitState.SetBackground(text);
	AS_SetCharacterBio(m_strBiographyLabel, text);
}

// --------------------------------------------------------------------------

simulated function CustomizeGender()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strGender, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Gender),
		ChangeGender, ChangeGender, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Gender));
}
simulated function ChangeGender(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Gender, 0, itemIndex );
	UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn')).SetActorPawn(CustomizeManager.ActorPawn);
}

// --------------------------------------------------------------------------

reliable client function CustomizeCountry()
{
	Movie.Pres.UICustomize_Trait( 
	class'UICustomize_Props'.default.m_strArmorPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Country),
		ChangeCountry, ChangeCountry, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Country)); 
}

reliable client function ChangeCountry(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Country, 0, itemIndex ); 
	UICustomize(Movie.Pres.ScreenStack.GetCurrentScreen()).Header.PopulateData(CustomizeManager.UpdatedUnitState);
}

//==============================================================================

simulated function AS_SetCharacterBio(string title, string bio)
{
	MC.BeginFunctionOp("setCharacterBio");
	MC.QueueString(title);
	MC.QueueString(bio);
	MC.EndOp();
}