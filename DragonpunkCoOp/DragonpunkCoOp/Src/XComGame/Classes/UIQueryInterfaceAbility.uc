//---------------------------------------------------------------------------------------
//  FILE:    UIQueryInterfaceAbility.uc
 //  AUTHOR:  Brit Steiner --  7/11/2014
 //  PURPOSE: Define data needed in the UI ability tooltips. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

interface UIQueryInterfaceAbility; 


struct UISummary_Ability
{
	// TODO: Need something to look up the label and keybinding with 
	var string KeybindingLabel; 
	var string Name; 
	var string Description; 
	var int ActionCost; 
	var int CooldownTime; 
	var bool bEndsTurn;		//will show the bale for "ENDS TURN"
	var string EffectLabel; //Such as "REFLEX" 
	var string Icon;

	structdefaultproperties
	{
		bEndsTurn=false;
		EffectLabel="";
		KeybindingLabel="";
	}
};

struct UIHackingBreakdown
{
	var int FinalHitChance;
	var float ExpectedHits;
	var float ExpectedBlocks;
	var int ShotPercent;
	var int BlocksPercent;
	var array<UISummary_ItemStat> ShotModifiers;
	var array<UISummary_ItemStat> BlockModifiers;
	var array<UISummary_ItemStat> BonusHitsModifiers;
	var array<UISummary_ItemStat> BonusBlocksModifiers;
	var bool bShow; 

	structdefaultproperties
	{
		bShow = false;
	}
};


simulated function UISummary_Ability GetUISummary_Ability(optional XComGameState_Unit UnitState);
simulated function int GetUISummary_HackingBreakdown(out UIHackingBreakdown kBreakdown, int TargetID);