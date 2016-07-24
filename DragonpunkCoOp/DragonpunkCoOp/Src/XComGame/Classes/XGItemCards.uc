//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGItemCards.h
//  AUTHOR:  dburchanowski  --  05/04/2012
//  PURPOSE: Various helper functions for building TItemCards
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XGItemCards extends Object;

static private function string GetLocalizedItemName(EItemType eItem)
{
	return "LEGACY STRING - STOP USING THIS";
}

static private function string GetLocalizedItemTacticalText(EItemType eItem)
{
	return "LEGACY STRING - STOP USING THIS";
}

static function TItemCard BuildItemCard(EItemType eItem)
{
	/*
	if(`GAMECORE.ItemIsWeapon(eItem))
	{
		return BuildWeaponCard(eItem);
	}
	else if(`GAMECORE.ItemIsArmor(eItem))
	{
		return BuildArmorCard(eItem);
	}
	else
	{*/
		return BuildEquippableItemCard(eItem);
	//}
}

static function TItemCard BuildWeaponCard(EItemType eWeapon)
{
	local TItemCard kItemCard;
	/*
	local TConfigWeapon kWeapon;
	local int minDamage, maxDamage, minCrit, maxCrit;

	if(eWeapon == eItem_None)
	{
		kItemCard.m_type = eItemCard_NONE;
		return kItemCard;
	}

	kWeapon = GetConfigWeapon(eWeapon);

	kItemCard.m_type = eItemCard_SoldierWeapon;
	kItemCard.m_item = eWeapon;
	kItemCard.m_strName = GetLocalizedItemName(eWeapon);
	kItemCard.m_strFlavorText = GetLocalizedItemTacticalText(eWeapon);

	kItemCard.m_eRange = `GAMECORE.GetWeaponCatRange(eWeapon);

	// AOE weapons cannot crit, nor do they do a damage range.
	if(`GAMECORE.m_arrWeapons[int(eWeapon)].aProperties[eWP_Explosive] > 0)
	{
		kItemCard.m_iBaseDamage = kWeapon.iDamage;
		kItemCard.m_iBaseDamageMax = -1;
		kItemCard.m_iBaseCritChance = -1;
		kItemCard.m_iCritDamage = -1;
		kItemCard.m_iCritDamageMax = -1;
	}
	else
	{
		minDamage = FMax(1, kWeapon.iDamage - 1);
		maxDamage = FMax(1, kWeapon.iDamage + 1);
		kItemCard.m_iBaseDamage = minDamage;
		kItemCard.m_iBaseDamageMax = maxDamage;

		kItemCard.m_iBaseCritChance = kWeapon.iCritical;

		minCrit = FMax(1, int(maxDamage * class'XGTacticalGameCoreData'.const.CRIT_DMG_MULT) - 1);
		maxCrit = FMax(1, int(maxDamage * class'XGTacticalGameCoreData'.const.CRIT_DMG_MULT) + 1);
		kItemCard.m_iCritDamage = minCrit;
		kItemCard.m_iCritDamageMax = maxCrit;
	}*/

	return kItemCard;
}

static function TItemCard BuildArmorCard(EItemType eArmor)
{
	local TItemCard kItemCard;/*
	local TConfigArmor kArmor;
	local int iIndex;

	if(eArmor == eItem_None)
	{
		kItemCard.m_type = eItemCard_NONE;
		return kItemCard;
	}

	kItemCard.m_type = eItemCard_Armor;
	kItemCard.m_item = eArmor;

	kArmor = GetConfigArmor(eArmor);
	kItemCard.m_strName = GetLocalizedItemName(eArmor);
	kItemCard.m_strFlavorText = GetLocalizedItemTacticalText(eArmor);

	kItemCard.m_iArmorHPBonus = kArmor.iHPBonus;
	for (iIndex = 0; iIndex < 4; iIndex++)
	{
		if (kArmor.Abilities[iIndex] != eAbility_None)
		{
			kItemCard.m_abilities.AddItem(kArmor.Abilities[iIndex]);
		}
	}

	// grapple is not actually an ability in the game data, but a property, so we need to manually append it.
	if (`GAMECORE.ArmorHasProperty(eArmor, eAP_Grapple))
	{
		kItemCard.m_abilities.AddItem(eAbility_Grapple);
	}
*/
	return kItemCard;
}

static function TItemCard BuildEquippableItemCard(EItemType eItem)
{
	local TItemCard kItemCard;

	if(eItem == eItem_None)
	{
		kItemCard.m_type = eItemCard_NONE;
		return kItemCard;
	}

	kItemCard.m_type = eItemCard_EquippableItem;
	kItemCard.m_item = eItem;

	kItemCard.m_strName = GetLocalizedItemName(eItem);
	kItemCard.m_strFlavorText = GetLocalizedItemTacticalText(eItem);

	return kItemCard;
}

// Generally for humans, you want to use a soldier template, since their perks will
// vary so wildly. Thus, this function only fills out perks for aliens.
static function TItemCard BuildCharacterCard(name TemplateName)
{
	local TItemCard kItemCard;
	local TCharacter kCharacter;

	if(TemplateName == '')
	{
		kItemCard.m_type = eItemCard_NONE;
		return kItemCard;
	}

	//kCharacter = `GAMECORE.GetTCharacter(TemplateName);

	kItemCard.m_type = eItemCard_MPCharacter;
	kItemCard.m_CharacterTemplateName = TemplateName;
		
	kItemCard.m_strName = `XEXPAND.ExpandString(kCharacter.strName);
	//kItemCard.m_strFlavorText = `XEXPAND.ExpandString(class'XLocalizedData'.default.m_aCharacterTacticalText[TemplateName]); // TODO: Hook this up to actually get a localized tactical text for the template. -ttalley

	/*
	kItemCard.m_iHealth = kCharacter.aStats[eStat_HP];
	kItemCard.m_iWill = kCharacter.aStats[eStat_Will];
	kItemCard.m_iAim = kCharacter.aStats[eStat_Offense];
	kItemCard.m_iDefense = kCharacter.aStats[eStat_Defense];
	*/

	return kItemCard;
}

static function TItemCard BuildSoldierTemplateCard(EMPTemplate eSoldierTemplate)
{
	local TItemCard kItemCard;
	local TCharacter kCharacter;
	local TMPClassPerkTemplate kTemplate;
	//local ESoldierClass eClass;
	//local ESoldierRanks eRank;
	local int iIndex;
	//local int iAim;
	//local int iDefense;
	//local int iWill;
	//local int iHealth;
	//local int iMobility;
	
	/*if(eSoldierTemplate == eMPT_None)
	{
		kItemCard.m_type = eItemCard_NONE;
		return kItemCard;
	}*/

	//kCharacter = `GAMECORE.GetTCharacter('Soldier');

	kItemCard.m_type = eItemCard_MPCharacter;
	kItemCard.m_CharacterTemplateName = 'Soldier';

	if(eSoldierTemplate == eMPT_None)
		kItemCard.m_strName = kCharacter.strName $ " - ";// jbouscher - this was never valid, and it's old: $ `XEXPAND.ExpandString(class'XGTacticalGameCore'.default.m_aSoldierClassNames[eSoldierTemplate]); //No template name for rookies 
	else
		kItemCard.m_strName = kCharacter.strName $ " - " $ `XEXPAND.ExpandString(class'XGTacticalGameCore'.default.m_aSoldierMPTemplate[eSoldierTemplate]);
	
	kItemCard.m_strFlavorText = `XEXPAND.ExpandString(class'XGTacticalGameCore'.default.m_aSoldierMPTemplateTacticalText[eSoldierTemplate]);

	// need to level up the char stats here so rank, class, etc., are factored in to the stats -tsmith/	iHealth = kCharacter.aStats[eStat_HP];
	/*
	iWill = kCharacter.aStats[eStat_Will];
	iAim = kCharacter.aStats[eStat_Offense];
	iDefense = kCharacter.aStats[eStat_Defense];
	iMobility = kCharacter.aStats[eStat_Mobility];
	*/
	// find the correct template config for this template
	for(iIndex = 0; iIndex < class'XComMPData'.default.m_arrPerkTemplate.Length; iIndex++)
	{
		kTemplate = class'XComMPData'.default.m_arrPerkTemplate[iIndex];
		if(kTemplate.m_eTemplate == eSoldierTemplate)
		{
			//eRank = kTemplate.m_eRank;
			//eClass = kTemplate.m_eClassType;
			break;
		}
	}

	/*
	`log(GetFuncName() @ "BEFORE stat mods from rank and class: " @ `ShowVar(eClass) @ `ShowVar(eRank) @ `ShowVar(iAim) @ `ShowVar(iDefense) @ `ShowVar(iWill) @ `ShowVar(iHealth) @ `ShowVar(iMobility), true, 'XCom_Net');
	class'XGTacticalGameCore'.static.LevelUpStats(      @TODO gameplay: fix this up
		eClass,
		eRank,
		iHealth,
		iAim,
		iWill,
		iMobility,
		iDefense,
		false /* bRandStatIncrease */,
		true /* bIsMultiplayer */);
	`log(GetFuncName() @ "AFTER stat mods from rank and class: " @ `ShowVar(eClass) @ `ShowVar(eRank) @ `ShowVar(iAim) @ `ShowVar(iDefense) @ `ShowVar(iWill) @ `ShowVar(iHealth) @ `ShowVar(iMobility), true, 'XCom_Net');
	*/

//	kItemCard.m_iHealth = iHealth;
//	kItemCard.m_iWill = iWill;
//	kItemCard.m_iAim = iAim;
//	kItemCard.m_iDefense = kCharacter.aStats[eStat_Defense];

	return kItemCard;
}