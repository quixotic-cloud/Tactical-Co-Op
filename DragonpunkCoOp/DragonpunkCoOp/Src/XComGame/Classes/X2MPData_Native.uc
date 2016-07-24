//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPData_Native.uc
//  AUTHOR:  Todd Smith  --  10/6/2015
//  PURPOSE: MP Data that needs to be nativized
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPData_Native extends Object
	native(MP);

struct native TX2UnitLoadoutTemplateData
{
	var name                    nMPCharacterTemplate;
	var name					nCharacterTemplate;
	var name					nSoldierClassTemplate;
	var name					nPrimaryWeaponTemplate;
	var name					nSecondaryWeaponTemplate;
	var name                    nHeavyWeaponTemplate;
	var name					nArmorTemplate;
	var name					nUtilityItem1Template;
	var name					nUtilityItem2Template;
	var name					nUtilityItem3Template;
	var int						iSoldierRank;
	var array<SCATProgression>  arrSoldierProgression;
	var string					strFirstName;
	var string					strLastName;
	var string					strNickName;
	var TAppearance             kAppearance;
};

struct native TX2MPSoldierItemDefinition
{
	var name    ItemTemplateName;
	var int     ItemCost;

	structdefaultproperties
	{
	}
};

struct native TX2UnitPresetData
{
	var int                     iID;
	var string                  strName;
	var string                  strLanguageCreatedWith;
	var TX2UnitLoadoutTemplateData kLoadoutTemplateData;

	structdefaultproperties
	{
		iID = -1;
	}
};