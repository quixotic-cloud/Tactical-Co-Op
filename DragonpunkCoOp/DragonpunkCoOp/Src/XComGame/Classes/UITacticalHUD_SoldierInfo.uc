//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_StatsContainer.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Statistics on the currently selected soldier.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_SoldierInfo extends UIPanel;

var string FeedbackMeterPipPath; 
var string FeedbackIconPath; 
var string HackingToolTipTargetPath;

var localized string PsiFeedbackGeneral; 
var localized string PsiFeedbackSafe;
var localized array<string> m_arrPsiFeedback;
var localized array<string> m_arrPsiFeedbackFinal;

// Pseudo-Ctor
simulated function UITacticalHUD_SoldierInfo InitStatsContainer()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	super.OnInit();
	
	UpdateStats();

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalController(PC), 'm_kActiveUnit', self, UpdateStats);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen), 'm_isMenuRaised', self, UpdateStats);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComPresentationLayer(Movie.Pres), 'm_kInventoryTactical', self, UpdateStats);

	HackingToolTipTargetPath = MCPath$".HackingInfoGroup.HackingInfo";
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local XGUnit kTargetUnit; 
	
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			kTargetUnit = XComTacticalController(PC).GetActiveUnit();
			kTargetUnit.ShowMouseOverDisc(false);	
			//`BATTLE.PRES().GetCamera().m_kScrollView.SetLocationTarget(`BATTLE.PRES().GetCamera().m_kCurrentView.GetLookAt());
			//`CAMERAMGR.RemoveLookAt( kTargetUnit.Location );
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			//if( `CAMERAMGR.IsCameraBusyWithKismetLookAts() )
			//	return true;

			kTargetUnit = XComTacticalController(PC).GetActiveUnit();
			kTargetUnit.ShowMouseOverDisc();	
			//if( XComPresentationLayer(Owner)==None || !XComPresentationLayer(Owner).Get2DMovie().HasModalScreens() )
			//	`CAMERAMGR.AddLookAt( kTargetUnit.Location );
			
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			kTargetUnit = XComTacticalController(PC).GetActiveUnit();

			if(kTargetUnit != none)
			{
				XComPresentationLayer(Movie.Pres).ZoomCameraIn(); //reset camera in case we're zoomed out
			}
			else
				Movie.Pres.PlayUISound(eSUISound_MenuClose);
			break; 
	}
}


// Pinged when the active unit changed. 
simulated function UpdateStats()
{
	local XGUnit        kActiveUnit;

	// If not shown or ready, leave.
	if( !bIsInited )
		return;
	
	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if( kActiveUnit == none )
	{
		Hide();
	}
	else
	{
		//UITacticalHUD(Screen).m_kInventory.m_kBackpack.Update( kActiveUnit );
		SetStats( kActiveUnit );
		SetHackingInfo(kActiveUnit);
		Show();
	}

	AS_ToggleSoldierInfoTip(true);
}

simulated function SetStats( XGUnit kActiveUnit )
{
	local XComGameState_Unit StateUnit;
	local string charName, charNickname, charRank, charClass;
	local bool isLeader, isLeveledUp, showBonus, showPenalty;
	local float aimPercent;
	local array<UISummary_UnitEffect> BonusEffects, PenaltyEffects; 
	local X2SoldierClassTemplateManager SoldierTemplateManager;

	StateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));

	if( StateUnit.GetMyTemplateName() == 'AdvPsiWitchM2' )
	{
		charName = StateUnit.GetName(eNameType_Full);

		charRank = "img:///UILibrary_Common.rank_fieldmarshall";
		SoldierTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		charClass = SoldierTemplateManager.FindSoldierClassTemplate('PsiOperative').IconImage;
		aimPercent = StateUnit.GetCurrentStat(eStat_Offense);
	}
	else 
	{
		charName = StateUnit.GetName(eNameType_Full);
		charNickname = StateUnit.GetNickName();

		if( StateUnit.IsSoldier() )
		{
			charRank = class'UIUtilities_Image'.static.GetRankIcon(StateUnit.GetRank(), StateUnit.GetSoldierClassTemplateName());
			charClass = StateUnit.GetSoldierClassTemplate().IconImage;
			isLeveledUp = StateUnit.CanRankUpSoldier();
			aimPercent = StateUnit.GetCurrentStat(eStat_Offense);
		}
		else if( StateUnit.IsCivilian() )
		{
			//charRank = string(-2); // TODO: show civilian icon 
			//charClass = "";
			aimPercent = -1;
		}
		else // is enemy
		{
			//charRank = string(99); //TODO: show alien icon 
			//charClass = "none";
			aimPercent = -1;
		}
	}

	// TODO:
	isLeader = false;

	BonusEffects = StateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus);
	PenaltyEffects = StateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);

	showBonus = (BonusEffects.length > 0 ); 
	showPenalty = (PenaltyEffects.length > 0);

	AS_SetStats(charName, charNickname, charRank, charClass, isLeader, isLeveledUp, aimPercent, showBonus, showPenalty);
}

simulated function AS_SetStats(string soldierName, string soldierNickname, string soldierRank, string soldierClass, bool isLeader, 
							   bool isLeveledUp, float aimPercent, bool showBonus, bool showPenalty )
{
	MC.BeginFunctionOp("SetStats");
	MC.QueueString(soldierName);
	MC.QueueString(soldierNickname);
	MC.QueueString(soldierRank);
	MC.QueueString(soldierClass);
	MC.QueueBoolean(isLeader);
	MC.QueueBoolean(isLeveledUp);
	MC.QueueNumber(aimPercent);
	MC.QueueBoolean(showBonus);
	MC.QueueBoolean(showPenalty);
	MC.EndOp();
}

simulated function AS_ToggleSoldierInfoTip(bool bShow)
{
	MC.BeginFunctionOp("ToggleSoldierInfoTip");
	MC.QueueBoolean(bShow);
	MC.EndOp();
}

simulated function SetHackingInfo(XGUnit kActiveUnit)
{
	local XComGameState_Unit StateUnit;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;
	local int HackRewardIndex;

	MC.FunctionVoid("ClearHacking");

	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(HackingToolTipTargetPath);

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	StateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	for( HackRewardIndex = 0; HackRewardIndex < StateUnit.CurrentHackRewards.Length && HackRewardIndex < 3; ++HackRewardIndex )
	{
		if( HackRewardIndex < StateUnit.CurrentHackRewards.Length )
		{
			HackRewardTemplate = HackRewardTemplateManager.FindHackRewardTemplate(StateUnit.CurrentHackRewards[HackRewardIndex]);
		}
		else
		{
			HackRewardTemplate = None;
		}

		if( HackRewardTemplate != None )
		{
			UpdateHacking(HackRewardIndex, class'UIUtilities_Image'.const.HackRewardIcon, HackRewardTemplate.GetFriendlyName(), HackRewardTemplate.GetDescription(StateUnit));
		}
		else
		{
			UpdateHacking(HackRewardIndex, "", "", "");
		}
	}

	// DEBUG EXAMPLE: uncomment to see this in action. 
	//UpdateHacking(0, class'UIUtilities_Image'.const.MissionObjective_HackWorkstation /*icon path*/, "HACK0" /*ability name*/, "Tooltip info!" /*desc*/);
	//UpdateHacking(1, class'UIUtilities_Image'.const.MissionObjective_HackWorkstation /*icon path*/, "HACK1" /*ability name*/, "More Tooltips!" /*desc*/);
	//UpdateHacking(2, class'UIUtilities_Image'.const.MissionObjective_HackWorkstation /*icon path*/, "HACK2" /*ability name*/, "Happy super tooltip time" /*desc*/);
}

// Blank strings will hide this widget. 
// Three of these are plopped on the stage. 
simulated function UpdateHacking(int Index, string Path, string AbilityName, string AbilityDesc)
{
	local UITextTooltip Tooltip;

	MC.BeginFunctionOp("SetHacking");
	MC.QueueNumber(Index);
	MC.QueueString(Path);
	MC.QueueString(AbilityName);
	MC.EndOp();

	// Add a tooltip 
	if( AbilityDesc != "" )
	{
		Tooltip = Spawn(class'UITextTooltip', Movie.Pres.m_kTooltipMgr);
		Tooltip.sTitle = AbilityName;
		Tooltip.sBody = AbilityDesc;
		Tooltip.bUsePartialPath = true;
		Tooltip.targetPath = HackingToolTipTargetPath$Index;

		Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(Tooltip);
	}
}

defaultproperties
{
	MCName = "soldierInfo";
	bAnimateOnInit = false;
}

