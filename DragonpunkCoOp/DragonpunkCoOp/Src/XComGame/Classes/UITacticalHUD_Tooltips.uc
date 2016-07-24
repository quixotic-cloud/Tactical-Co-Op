//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_Tooltips.uc
 //  AUTHOR:  Brit Steiner --  6/24/2014
 //  PURPOSE: Fires up all tooltips in the TacticalHUD and manages updates.
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_Tooltips extends UIPanel dependson(X2GameRuleset);

var UITooltipGroup_Stacking EnemyStats;

// Constructor
simulated function UITacticalHUD_Tooltips InitTooltips()
{
	InitPanel();
	InitializeTooltipData();
	return self;
}

simulated function InitializeTooltipData()
{
	local UITacticalHUD_WeaponTooltip WeaponTooltip;
	//local UITacticalHUD_BackPackTooltip BackpackTooltip;
	local UITacticalHUD_SoldierInfoTooltip SoldierInfoTooltip;
	//local UITacticalHUD_HackingTooltip HackingTooltip;
	local UITacticalHUD_EnemyTooltip EnemyTooltip;
	local UITacticalHUD_PerkTooltip PerkTooltip;
	local UITacticalHUD_AbilityTooltip AbilityTooltip;
	local UITacticalHUD_BuffsTooltip EnemyBonusesTooltip;
	local UITacticalHUD_BuffsTooltip EnemyPenaltiesTooltip;
	local UITacticalHUD_BuffsTooltip SoldierBonusesTooltip;
	local UITacticalHUD_BuffsTooltip SoldierPenaltiesTooltip;

	EnemyStats = new class'UITooltipGroup_Stacking';

	// Weapon tooltip ---------------------------------------------------------------------
	WeaponTooltip = Spawn(class'UITacticalHUD_WeaponTooltip', Movie.Pres.m_kTooltipMgr); 
	WeaponTooltip.InitWeaponStats('TooltipWeaponStats');
	
	WeaponTooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT);
	WeaponTooltip.SetPosition(-20, -150);
	WeaponTooltip.bFollowMouse = false;

	WeaponTooltip.targetPath = string( UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kInventory.m_kWeapon.MCPath); 

	WeaponTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( WeaponTooltip );

	// Unit Stats tooltip ------------------------------------------------------------------
	SoldierInfoTooltip = Spawn(class'UITacticalHUD_SoldierInfoTooltip', Movie.Pres.m_kTooltipMgr); 
	SoldierInfoTooltip.InitSoldierStats('TooltipSoldierStats');

	SoldierInfoTooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT);
	SoldierInfoTooltip.SetPosition(20 , -210 - SoldierInfoTooltip.height);
	SoldierInfoTooltip.bFollowMouse = false;

	SoldierInfoTooltip.targetPath = string( UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kStatsContainer.MCPath);

	SoldierInfoTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( SoldierInfoTooltip );

	// Hacking  Stats tooltip **DEPRECATED** -----------------------------------------------
	/*
	HackingTooltip = Spawn(class'UITacticalHUD_HackingTooltip', Movie.Pres.m_kTooltipMgr); 
	HackingTooltip.InitHackingStats('TooltipHackingStats');

	HackingTooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT);
	HackingTooltip.SetPosition(-20 - HackingTooltip.width , -210 - HackingTooltip.height);

	HackingTooltip.targetPath =  string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kEnemyTargets.MCPath);

	HackingTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( HackingTooltip );
	*/

	// Enemy Stats tooltip ------------------------------------------------------------------
	// dburchanowski - Oct 16, 2015: Disabling, but leaving here in case Jake wants it back before we ship
	if(false)
	{
		EnemyTooltip = Spawn(class'UITacticalHUD_EnemyTooltip', Movie.Pres.m_kTooltipMgr); 
		EnemyTooltip.InitEnemyStats('TooltipEnemyStats');

		EnemyTooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_NONE);
		EnemyTooltip.SetPosition(Movie.m_v2ScaledDimension.X - 20 - EnemyTooltip.width, Movie.m_v2ScaledDimension.Y - 450 - EnemyTooltip.height);
		EnemyTooltip.bFollowMouse = false;

		EnemyTooltip.targetPath = string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kEnemyTargets.MCPath);
		EnemyTooltip.bUsePartialPath = true; 

		EnemyTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( EnemyTooltip );
	}

	// Soldier Passives tooltip ------------------------------------------------------------------
	PerkTooltip = Spawn(class'UITacticalHUD_PerkTooltip', Movie.Pres.m_kTooltipMgr); 
	PerkTooltip.InitPerkTooltip('TooltipSoldierPerks');

	PerkTooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT);
	PerkTooltip.SetPosition(20, -210- PerkTooltip.height);
	PerkTooltip.bFollowMouse = false;

	PerkTooltip.targetPath =  string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kPerks.MCPath); 
	PerkTooltip.bUsePartialPath = true;

	PerkTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( PerkTooltip );

	// Enemy Bonuses tooltip ------------------------------------------------------------------
	EnemyBonusesTooltip = Spawn(class'UITacticalHUD_BuffsTooltip', Movie.Pres.m_kTooltipMgr); 
	EnemyBonusesTooltip.InitBonusesAndPenalties('TooltipEnemyBonuses',,true, false, Movie.m_v2ScaledDimension.X - 160, Movie.m_v2ScaledDimension.Y - 400, true);

	EnemyBonusesTooltip.targetPath =  string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kEnemyTargets.MCPath); 
	EnemyBonusesTooltip.bUsePartialPath = true; 

	EnemyBonusesTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( EnemyBonusesTooltip );
	
	// Enemy Penalties tooltip ------------------------------------------------------------------
	EnemyPenaltiesTooltip = Spawn(class'UITacticalHUD_BuffsTooltip', Movie.Pres.m_kTooltipMgr); 
	EnemyPenaltiesTooltip.InitBonusesAndPenalties('TooltipEnemyPenalties',,false, false, Movie.m_v2ScaledDimension.X - 160, Movie.m_v2ScaledDimension.Y - 400, true);

	EnemyPenaltiesTooltip.targetPath =  string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kEnemyTargets.MCPath); 
	EnemyPenaltiesTooltip.bUsePartialPath = true; 

	EnemyPenaltiesTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( EnemyPenaltiesTooltip );

	// Unit Bonuses tooltip ------------------------------------------------------------------
	SoldierBonusesTooltip = Spawn(class'UITacticalHUD_BuffsTooltip', Movie.Pres.m_kTooltipMgr); 
	SoldierBonusesTooltip.InitBonusesAndPenalties('TooltipSoldierBonuses',,true, true, 20, -210);

	SoldierBonusesTooltip.SetPosition(20, Movie.m_v2ScaledDimension.Y - 210 - SoldierBonusesTooltip.Height);
	SoldierBonusesTooltip.targetPath =  string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kStatsContainer.MCPath) $ "." $ class'UITacticalHUD_BuffsTooltip'.default.m_strBonusMC; 
	SoldierBonusesTooltip.bUsePartialPath = true; 

	SoldierBonusesTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( SoldierBonusesTooltip );

	// Unit Penalties tooltip ------------------------------------------------------------------
	SoldierPenaltiesTooltip = Spawn(class'UITacticalHUD_BuffsTooltip', Movie.Pres.m_kTooltipMgr); 
	SoldierPenaltiesTooltip.InitBonusesAndPenalties('TooltipSoldierPenalties', , false, true, 20, -210);

	SoldierPenaltiesTooltip.SetPosition(20, Movie.m_v2ScaledDimension.Y - 210 - SoldierPenaltiesTooltip.Height);
	SoldierPenaltiesTooltip.targetPath = UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kStatsContainer.MCPath $ "." $ class'UITacticalHUD_BuffsTooltip'.default.m_strPenaltyMC;
	SoldierPenaltiesTooltip.bUsePartialPath = true; 

	SoldierPenaltiesTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( SoldierPenaltiesTooltip );

	// Soldier ability hover tooltip -----------------------------------------------------------
	AbilityTooltip = Spawn(class'UITacticalHUD_AbilityTooltip', Movie.Pres.m_kTooltipMgr); 
	AbilityTooltip.InitAbility('TooltipAbility',,20, -210);

	AbilityTooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT);
	AbilityTooltip.bFollowMouse = false;

	AbilityTooltip.targetPath =  string(UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kAbilityHUD.MCPath); 
	AbilityTooltip.bUsePartialPath = true; 

	AbilityTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( AbilityTooltip );

	EnemyStats.Add(EnemyPenaltiesTooltip);
	EnemyStats.AddWithRestingYPosition(EnemyBonusesTooltip, EnemyBonusesTooltip.Y);
	if (EnemyTooltip != none)
		EnemyStats.AddWithRestingYPosition(EnemyTooltip, EnemyTooltip.Y);
}

event Tick(float DeltaTime)
{
	EnemyStats.CheckNotify();
}

defaultproperties
{
	bAnimateOnInit = false;
}