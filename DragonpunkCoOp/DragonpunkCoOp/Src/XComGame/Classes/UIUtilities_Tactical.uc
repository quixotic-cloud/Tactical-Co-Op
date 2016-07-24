//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Tactical.uc
//  AUTHOR:  sbatista
//  PURPOSE: Container of utility data functionality for tactical UI.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Tactical extends Object;

// ABILITY PRIORITIES top -> bottom == left -> right

// 0 is reserved for reload, when it's available

// NOTE: the values are base 10 to allow for addition of new abilities without having to re-prioritize everything

const MUST_RELOAD_PRIORITY 				= 70;
const STANDARD_SHOT_PRIORITY 			= 100;
const OVERWATCH_PRIORITY				= 200;
const STANDARD_PISTOL_SHOT_PRIORITY 	= 210;
const PISTOL_OVERWATCH_PRIORITY			= 220;
const OBJECTIVE_INTERACT_PRIORITY 		= 230;
const EVAC_PRIORITY						= 240;
const CLASS_SQUADDIE_PRIORITY			= 310;
const CLASS_CORPORAL_PRIORITY			= 320;
const CLASS_SERGEANT_PRIORITY			= 330;
const CLASS_LIEUTENANT_PRIORITY			= 340;
const CLASS_CAPTAIN_PRIORITY			= 350;
const CLASS_MAJOR_PRIORITY				= 360;
const CLASS_COLONEL_PRIORITY			= 370;
const HUNKER_DOWN_PRIORITY 				= 400;
const INTERACT_PRIORITY 				= 500;
const HACK_PRIORITY 					= 600;
const LOOT_PRIORITY 					= 700;
const RELOAD_PRIORITY 					= 800; // Reload should come after class abilities, but before item abilities
const STABILIZE_PRIORITY				= 900;
const MEDIKIT_HEAL_PRIORITY				= 1000;
const COMBAT_STIMS_PRIORITY				= 1100;
const UNSPECIFIED_PRIORITY 				= 1200;
const STANDARD_GRENADE_PRIORITY 		= 1300;
const ALIEN_GRENADE_PRIORITY 			= 1400;
const FLASH_BANG_PRIORITY 				= 1500;
const FIREBOMB_PRIORITY					= 1600;
const STASIS_LANCE_PRIORITY				= 1700;
const ARMOR_ACTIVE_PRIORITY				= 1800;

// commander abilities must be placed after normal ability priorities
const PLACE_EVAC_PRIORITY				= 2000;