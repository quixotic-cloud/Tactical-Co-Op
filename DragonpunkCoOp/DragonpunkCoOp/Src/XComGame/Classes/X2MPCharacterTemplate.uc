//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPCharacterTemplate.uc
//  AUTHOR:  Todd Smith  --  10/13/2015
//  PURPOSE: Character templates for multiplayer
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPCharacterTemplate extends X2DataTemplate
	native(MP)
	config(MPCharacterData);

// name of the X2CharacterTemplate to use. i.e. Soldier, Sectoid.  -tsmith
var privatewrite config name        CharacterTemplateName;
// name of the X2SoldierClassTemplate. i.e. Ranger, Sharpshooter. only valid if the character template is a soldier -tsmith
var privatewrite config name        SoldierClassTemplateName;
// rank of the soldier. only valid if the character template is a soldier. range is [0, X2SoldierClassTemplate::GetMaxConfiguredRank). -tsmith
var privatewrite config int         SoldierRank;
// name of abilities this soldier will have. NOTE: the ability must be in the X2SoldierClassTemplate's SoldierRank AbilityTree. -tsmith
var privatewrite config array<name> Abilities;
// name of the loadout the unit will have. this name must correspond to a loadout thats defined in the [XComGame.X2ItemTemplateManager] section DefaultGameData.ini  -tsmith
var privatewrite config name        Loadout;
// point cost for this character. -tsmith
var privatewrite config int         Cost;
// How many utility slots does this unit have? Only applies to XCom Soldiers.
var privatewrite config int			NumUtilitySlots;

var privatewrite config string      SelectorImagePath; // path to image to display in the unit selector screen
var privatewrite config string      IconImage;         // path to image to display on squad select items

var privatewrite localized string   DisplayDescription;

var privatewrite localized string   DisplayName;
