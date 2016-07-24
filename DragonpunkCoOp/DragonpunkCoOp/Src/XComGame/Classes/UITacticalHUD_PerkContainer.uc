//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_PerkContainer.uc
//  AUTHOR:  Sam Batista
//  PURPOSE: Displays passive abilities on currently selected soldier. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_PerkContainer extends UIPanel;

const MAX_NUM_PERKS = 24;

var int NumActivePerks;
var array<UITacticalHUD_Perk> m_arrPerks;

simulated function UITacticalHUD_PerkContainer InitPerkContainer()
{
	local int i;
	local UITacticalHUD_Perk kItem;

	InitPanel();

	// Pre-cache UI data array
	for(i = 0; i < MAX_NUM_PERKS; ++i)
	{	
		kItem = Spawn(class'UITacticalHUD_Perk', self);
		kItem.InitPerkItem(name("PerkItem_" $ i));
		m_arrPerks.AddItem(kItem);
	}

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalController(PC), 'm_kActiveUnit', self, UpdatePerks);

	UpdatePerks();
}

// Pinged when the active unit changed.
simulated function UpdatePerks()
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit kGameStateUnit;
	local UISummary_UnitEffect Effect;
	local array<UISummary_UnitEffect> Effects;
	local int i; 

	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();

	if( kActiveUnit == none )
	{
		Hide();
		return;
	}
	
	kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	Effects = kGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Passive);

	SetNumActivePerks(Effects.Length);

	if(Effects.Length > 0)
	{
		for(i = 0; i < Effects.Length; i++)
		{
			Effect = Effects[i]; 
			m_arrPerks[i].UpdateData(Effect);
		}

		Show();
	}
	else
		Hide();
}

simulated function SetNumActivePerks(int NumPerks)
{
	if(NumActivePerks != NumPerks)
	{
		NumActivePerks = NumPerks;
		mc.FunctionNum("setNumActivePerks", NumActivePerks);
	}
}

defaultproperties
{
	MCName = "perkContainer";
	NumActivePerks = -1;
	bAnimateOnInit = false;
}

