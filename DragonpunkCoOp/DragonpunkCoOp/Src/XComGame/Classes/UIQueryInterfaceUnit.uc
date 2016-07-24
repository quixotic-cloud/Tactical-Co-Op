//---------------------------------------------------------------------------------------
//  FILE:     UIQueryInterfaceUnit.uc
 //  AUTHOR:  Brit Steiner --  6/26/2014
 //  PURPOSE: Define data needed in the UI soldier and enemy target tooltips. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

interface UIQueryInterfaceUnit; 

struct EUISummary_UnitStats
{
	var int CurrentHP;
	var int MaxHP;
	var int Aim;
	var int Tech;
	var int Will;
	var int Defense;
	var int Dodge;
	var int Armor;
	var int PsiOffense;
	var string UnitName; 

	/* Debug Values */
	var int Xp;
	var float XpShares;
	var float SquadXpShares;
	var float EarnedPool;
	/* End Debug Values */

	structdefaultproperties
	{
		UnitName="";
	}
};

struct UISummary_UnitEffect
{
	// TODO: Need something to look up the label and keybinding with 
	var string Name; 
	var string Description; 
	var string Icon;
	var int Cooldown;
	var int Charges;
	var Name AbilitySourceName;

	structdefaultproperties
	{
		Name="";
		Description="";
		Icon="";
		Cooldown=0;
		Charges=0;
	}
};

simulated function EUISummary_UnitStats GetUISummary_UnitStats();
simulated function array<UISummary_UnitEffect> GetUISummary_UnitEffectsByCategory(EPerkBuffCategory Category);
simulated function array<UISummary_Ability> GetUISummary_Abilities();
simulated function int GetUISummary_StandardShotHitChance(XGUnit Target); 