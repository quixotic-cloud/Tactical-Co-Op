//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Menu.uc
//  AUTHOR:  Brit Steiner --  8/28/2014
//  PURPOSE:Soldier category options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_Menu extends UICustomize;

//----------------------------------------------------------------------------
// MEMBERS

var localized string m_strTitle;
var localized string m_strEditInfo;
var localized string m_strEditProps;
var localized string m_strFace;
var localized string m_strHair;
var localized string m_strFacialHair;
var localized string m_strHairColor;
var localized string m_strEyeColor;
var localized string m_strRace;
var localized string m_strSkinColor;
var localized string m_strMainColor;
var localized string m_strSecondaryColor;
var localized string m_strWeaponColor;

var localized string m_strVoice;
var localized string m_strPreviewVoice;
var localized string m_strAttitude;
//var localized string m_strType;

// Character Pool
var localized string m_strCustomizeClass;
var localized string m_strExportCharacter;

var localized string m_strAllowTypeSoldier;
var localized string m_strAllowTypeVIP;
var localized string m_strAllowTypeDarkVIP;
var localized string m_strAllowed;

var localized string m_strTimeAdded;

var localized string m_strExportSuccessTitle;
var localized string m_strExportSuccessBody;

var localized string m_strRemoveHelmetOrLowerProp;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function UpdateData()
{
	local int i;
	local bool bIsObstructed;
	local EUIState ColorState;
	local int currentSel;
	currentSel = List.SelectedIndex;

	super.UpdateData();

	// Hide all existing options since the number of options can change if player switches genders
	HideListItems();

	CustomizeManager.UpdateBodyPartFilterForNewUnit(CustomizeManager.Unit);

	// INFO
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataDescription(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FirstName)$ m_strEditInfo, OnCustomizeInfo);

	// PROPS
	//-----------------------------------------------------------------------------------------
	//Using first name to sit in for the props category 
	GetListItem(i++).UpdateDataDescription(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_NickName)$ m_strEditProps, OnCustomizeProps);

	// FACE
	//-----------------------------------------------------------------------------------------
	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Face)$ m_strFace, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Face, ColorState, FontSize), CustomizeFace)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// HAIRSTYLE
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).HelmetContent.FallbackHairIndex <= -1;
	ColorState = (bIsSuperSoldier || bIsObstructed) ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Hairstyle)$ m_strHair, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Hairstyle, ColorState, FontSize), CustomizeHair)
		.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : m_strRemoveHelmet);

	// FACIAL HAIR
	//-----------------------------------------------------------------------------------------
	if(CustomizeManager.ShowMaleOnlyOptions())
	{
		bIsObstructed = CustomizeManager.IsFacialHairDisabled();
		ColorState = (bIsSuperSoldier || bIsObstructed) ? eUIState_Disabled : eUIState_Normal;

		GetListItem(i++)
			.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FacialHair)$m_strFacialHair, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FacialHair, ColorState, FontSize), CustomizeFacialHair)
			.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : m_strRemoveHelmetOrLowerProp);
	}

	// HAIR COLOR
	//----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).HelmetContent.FallbackHairIndex <= -1 && 
					(CustomizeManager.UpdatedUnitState.kAppearance.iGender == eGender_Female ||
					(CustomizeManager.HasBeard() && !XComHumanPawn(CustomizeManager.ActorPawn).HelmetContent.bHideFacialHair));
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++)
		.UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_HairColor)$ m_strHairColor, CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_HairColor), HairColorSelector)
		.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : m_strRemoveHelmet);

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// EYE COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_EyeColor)$m_strEyeColor, CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_EyeColor), EyeColorSelector)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// RACE
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Race)$ m_strRace, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Race, ColorState, FontSize), CustomizeRace)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// SKIN COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Skin)$ m_strSkinColor, CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_Skin), SkinColorSelector)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// ARMOR PRIMARY COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_PrimaryArmorColor)$ m_strMainColor,
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_PrimaryArmorColor), PrimaryArmorColorSelector);

	// ARMOR SECONDARY COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_SecondaryArmorColor)$ m_strSecondaryColor,
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_SecondaryArmorColor), SecondaryArmorColorSelector);

	// WEAPON PRIMARY COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_WeaponColor)$ m_strWeaponColor,
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_WeaponColor), WeaponColorSelector);

	// VOICE
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Voice)$ m_strVoice, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Voice, eUIState_Normal, FontSize), CustomizeVoice);

	// DISABLE VETERAN OPTIONS
	ColorState = bDisableVeteranOptions ? eUIState_Disabled : eUIState_Normal;

	// ATTITUDE (VETERAN)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Personality)$ m_strAttitude,
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Personality, ColorState, FontSize), CustomizePersonality);

	//  CHARACTER POOL OPTIONS
	//-----------------------------------------------------------------------------------------
	//If in the armory, allow exporting character to the pool
	if (bInArmory) 
	{
		GetListItem(i++).UpdateDataDescription(m_strExportCharacter, OnExportSoldier);
	}
	else //Otherwise, allow customizing their potential appearances
	{
		if(!bInMP)
		{
			if(Unit.IsSoldier())
				GetListItem(i++).UpdateDataValue(m_strCustomizeClass,
					CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Class, eUIState_Normal, FontSize), CustomizeClass);

			GetListItem(i++).UpdateDataCheckbox(m_strAllowTypeSoldier, m_strAllowed, CustomizeManager.UpdatedUnitState.bAllowedTypeSoldier, OnCheckbox_Type_Soldier);
			GetListItem(i++).UpdateDataCheckbox(m_strAllowTypeVIP, m_strAllowed, CustomizeManager.UpdatedUnitState.bAllowedTypeVIP, OnCheckbox_Type_VIP);
			GetListItem(i++).UpdateDataCheckbox(m_strAllowTypeDarkVIP, m_strAllowed, CustomizeManager.UpdatedUnitState.bAllowedTypeDarkVIP, OnCheckbox_Type_DarkVIP);

			GetListItem(i).UpdateDataDescription(m_strTimeAdded @ CustomizeManager.UpdatedUnitState.PoolTimestamp, None);
			GetListItem(i++).SetDisabled(true);
		}
	}

	if (currentSel > -1 && currentSel < List.ItemCount)
	{
		//Don't use GetItem(..), because it overwrites enable.disable option indiscriminately. 
		List.Navigator.SetSelected(List.GetItem(currentSel));
	}
	else
	{
		//Don't use GetItem(..), because it overwrites enable.disable option indiscriminately. 
		List.Navigator.SetSelected(List.GetItem(0));
	}
	//-----------------------------------------------------------------------------------------
}

simulated function OnExportSoldier()
{
	local TDialogueBoxData kDialogData;

	//Add to pool and save
	local CharacterPoolManager cpm;
	cpm = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	CustomizeManager.Unit.PoolTimestamp = class'X2StrategyGameRulesetDataStructures'.static.GetSystemDateTimeString();
	cpm.CharacterPool.AddItem(CustomizeManager.Unit);
	cpm.SaveCharacterPool();

	//Inform the user
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strExportSuccessTitle;
	kDialogData.strText = m_strExportSuccessBody;
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;
	Movie.Pres.UIRaiseDialog(kDialogData);
}

// --------------------------------------------------------------------------
simulated function OnCustomizeInfo()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Info(Unit);
}
// --------------------------------------------------------------------------
simulated function OnCustomizeProps()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Props(Unit);
}
// --------------------------------------------------------------------------
simulated function CustomizeFace()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strFace, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Face),
		ChangeFace, ChangeFace, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Face));
}
reliable client function ChangeFace(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Face, 0, itemIndex ); 
}
// --------------------------------------------------------------------------
simulated function CustomizeHair()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strHair, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Hairstyle),
		ChangeHair, ChangeHair, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Hairstyle));
}
reliable client function ChangeHair(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Hairstyle, 0, itemIndex ); 
}
// --------------------------------------------------------------------------
simulated function CustomizeFacialHair()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strFacialHair, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacialHair),
		ChangeFacialHair, ChangeFacialHair, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacialHair));
}
reliable client function ChangeFacialHair(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_FacialHair, 0, itemIndex ); 
}
// --------------------------------------------------------------------------
simulated function CustomizeRace()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strRace, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Race),
		ChangeRace, ChangeRace, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Race));
}
reliable client function ChangeRace(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Race, 0, itemIndex ); 
}
// --------------------------------------------------------------------------
simulated function EyeColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_EyeColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_EyeColor),
		PreviewEyeColor, SetEyeColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_EyeColor)));

	CustomizeManager.AccessedCategoryCheckDLC(eUICustomizeCat_EyeColor);
}
simulated function PreviewEyeColor(int iIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_EyeColor, -1, iIndex);
}
simulated function SetEyeColor(int iIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_EyeColor, -1, iIndex);
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function HairColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_HairColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_HairColor),
		PreviewHairColor, SetHairColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_HairColor)));
}
function PreviewHairColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_HairColor, -1, iColorIndex); 
}
function SetHairColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_HairColor, -1, iColorIndex); 
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function PrimaryArmorColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_PrimaryArmorColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_PrimaryArmorColor),
		PreviewPrimaryArmorColor, SetPrimaryArmorColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_PrimaryArmorColor)));

	CustomizeManager.AccessedCategoryCheckDLC(eUICustomizeCat_PrimaryArmorColor);
}
function PreviewPrimaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_PrimaryArmorColor, -1, iColorIndex); 
}
function SetPrimaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_PrimaryArmorColor, -1, iColorIndex); 
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function SecondaryArmorColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_SecondaryArmorColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_SecondaryArmorColor),
		PreviewSecondaryArmorColor, SetSecondaryArmorColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_SecondaryArmorColor)));
}
function PreviewSecondaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_SecondaryArmorColor, -1, iColorIndex ); 
}
function SetSecondaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_SecondaryArmorColor, -1, iColorIndex ); 
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function WeaponColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_WeaponColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_WeaponColor), PreviewWeaponColor, SetWeaponColor,
									int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_WeaponColor)));
}
function PreviewWeaponColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_WeaponColor, -1, iColorIndex);
}
function SetWeaponColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_WeaponColor, -1, iColorIndex);
	UpdateData();
}
// ------------------------------------------------------------------------
reliable client function SkinColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Skin);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_Skin), 
		PreviewSkinColor, SetSkinColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_Skin)));
}
function PreviewSkinColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Skin, -1, iColorIndex ); 
}
function SetSkinColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Skin, -1, iColorIndex ); 
	UpdateData();
}

// ------------------------------------------------------------------------

reliable client function OnCheckbox_Type_Soldier(UICheckbox Checkbox)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_AllowTypeSoldier, 0, Checkbox.bChecked ? 1 : 0);
}

reliable client function OnCheckbox_Type_VIP(UICheckbox Checkbox)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_AllowTypeVIP, 0, Checkbox.bChecked ? 1 : 0);
}

reliable client function OnCheckbox_Type_DarkVIP(UICheckbox Checkbox)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_AllowTypeDarkVIP, 0, Checkbox.bChecked ? 1 : 0);
}

reliable client function CustomizeClass()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strCustomizeClass, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Class), 
		none, ChangeClass, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Voice));
}

reliable client function ChangeClass(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Class, 0, itemIndex ); 
}

// --------------------------------------------------------------------------
simulated function CustomizeVoice()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strVoice, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Voice),
		none, ChangeVoice, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Voice), m_strPreviewVoice, ChangeVoice);
}
reliable client function ChangeVoice(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Voice, 0, itemIndex ); 
}

// --------------------------------------------------------------------------

reliable client function CustomizePersonality()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strAttitude, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Personality),
		ChangePersonality, ChangePersonality, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Personality));
}

function ChangePersonality(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Personality, 1, itemIndex);
}

simulated static function bool CanCycleToAttitude(XComGameState_Unit NewUnit)
{
	return CanCycleTo(NewUnit) && NewUnit.IsVeteran();
}

// ------------------------------------------------------------------------

simulated function Remove()
{
	if(CustomizeManager.ActorPawn != none)
	{
		// Restore the character's default idle animation
		XComHumanPawn(CustomizeManager.ActorPawn).CustomizationIdleAnim = '';
		XComHumanPawn(CustomizeManager.ActorPawn).PlayHQIdleAnim();
	}

	Movie.Pres.DeactivateCustomizationManager(true);
	super.Remove();
}

//==============================================================================