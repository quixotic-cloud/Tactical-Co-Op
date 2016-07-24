//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_HackingTooltip.uc
 //  AUTHOR:  Brit Steiner --  6/2014
 //  PURPOSE: Tooltip to previz the hacking stats. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_HackingTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;

var int LeftWidth;
var int RightWidth;
var int CenterPadding; 

var public UIStatList LeftStatList; 
var public UIStatList RightStatList; 
var public UIPanel LeftBodyArea;
var public UIPanel RightBodyArea;
var public UIMask LeftBodyMask;
var public UIMask RightBodyMask;

// Header items: 
var public UIText LeftTitle; 
var public UIText RightTitle; 
var public UIText CenterPercent; 

var float DefaultX;
var float DefaultY;

var localized string m_strHackerLabel; 

simulated function UIPanel InitHackingStats(optional name InitName, optional name InitLibID)
{
	local UIPanel HeaderControl;
	
	InitPanel(InitName, InitLibID);

	width = LeftWidth + RightWidth + CenterPadding; 

	Hide();

	// ----------

	Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(width, height);

	HeaderControl = Spawn(class'UIPanel', self).InitPanel('Header').SetPosition(PADDING_LEFT, PADDING_TOP);
	HeaderControl.width = width - PADDING_RIGHT- PADDING_LEFT; 

	LeftTitle = Spawn(class'UIText', HeaderControl).InitText('', "", true);
	LeftTitle.SetWidth(HeaderControl.width); 

	RightTitle = Spawn(class'UIText', HeaderControl).InitText('', "", true);
	RightTitle.SetWidth(HeaderControl.width); 
	RightTitle.SetSubTitle( class'UIUtilities_Text'.static.AlignRight(class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.HackingEnemyLabel, eUITextStyle_Tooltip_Title, eUIState_Normal)));

	CenterPercent = Spawn(class'UIText', HeaderControl).InitText('', "", true);
	CenterPercent.SetWidth(HeaderControl.width); 
	//CenterPercent.SetX(LeftWidth);

	HeaderControl.height = 30;

	class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( HeaderControl, self );

	// ----------
	
	LeftBodyArea = Spawn(class'UIPanel', self); 
	LeftBodyArea.InitPanel('LeftBodyArea').SetPosition(0, HeaderControl.height + HeaderControl.Y);
	LeftBodyArea.width = LeftWidth; 
	LeftBodyArea.height = height;
	
	LeftStatList = Spawn(class'UIStatList', LeftBodyArea);
	LeftStatList.InitStatList('StatListLeft',
								, 
								, 
								, 
								LeftWidth, 
								LeftBodyArea.height);

	LeftBodyMask = Spawn(class'UIMask', self).InitMask('', LeftBodyArea).FitMask(LeftBodyArea); 

	// -----------
	
	RightBodyArea = Spawn(class'UIPanel', self); 
	RightBodyArea.InitPanel('RightBodyArea').SetPosition(RightWidth + CenterPadding, HeaderControl.height + HeaderControl.Y);
	RightBodyArea.width = RightWidth; //For data storage, not for setting.
	RightBodyArea.height = height; 
	
	RightStatList = Spawn(class'UIStatList', RightBodyArea);
	RightStatList.InitStatList('StatListLeft',
								, 
								, 
								, 
								RightWidth, 
								RightBodyArea.height);

	RightBodyMask = Spawn(class'UIMask', self).InitMask('', RightBodyArea).FitMask(RightBodyArea); 

	// -----------

	return self; 
}

simulated function ShowTooltip()
{
	local int ScrollHeight;

	super.ShowTooltip(); //Show called before data refresh, because later items may hide this tooltip when doing data checks. 
	RefreshData();
	
	ScrollHeight = (LeftStatList.height > LeftBodyArea.height ) ? LeftStatList.height : LeftBodyArea.height; 
	LeftBodyArea.AnimateScroll( ScrollHeight, LeftBodyMask.height);

	ScrollHeight = (RightStatList.height > RightBodyArea.height ) ? RightStatList.height : RightBodyArea.height; 
	RightBodyArea.AnimateScroll( ScrollHeight, RightBodyMask.height);
}

simulated function RefreshData()
{
	local AvailableAction       kAction;
	local XComGameState_Ability AbilityState;
	local UITacticalHUD         HUD; 
	local int					EnemyID; 
	local UIHackingBreakdown	kHackingBreakdown;
	local array<string>			Path;
	local int					iTargetIndex; 

	//Shell debugging layout 
	if( XComTacticalController(PC) == None )
	{
		DEBUG_GetUISummary_HackingBreakdown(kHackingBreakdown);

		CenterPercent.SetSubTitle( StyleFinalHitChance(kHackingBreakdown) );
		LeftTitle.SetSubTitle( class'UIUtilities_Text'.static.StyleText( m_strHackerLabel, eUITextStyle_Tooltip_Title, eUIState_Normal));

		LeftStatList.RefreshData( ProcessSoldierBreakdown(kHackingBreakdown) );
		RightStatList.RefreshData( ProcessTargetBreakdown(kHackingBreakdown) );
		return; 
	}

	//------------------------------------------------------------------

	HUD = XComPresentationLayer(Movie.Pres).GetTacticalHUD(); 
	kAction = HUD.m_kAbilityHUD.GetShotActionForTooltip();

	// Get the enemy unit we're hovering on 
	Path = SplitString( currentPath, "." );	
	iTargetIndex = int(Split( Path[5], "icon", true));
	EnemyID = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetEnemyIDAtIcon(iTargetIndex);

	HUD.m_kAbilityHUD.GetDefaultTargetingAbility(EnemyID, kAction);
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));

	if( AbilityState == none )
	{
		Hide();
		return; 
	}

	//Don't show any other normal shot breakdown; we only want hacking actions. 
	AbilityState.GetUISummary_HackingBreakdown( kHackingBreakdown, EnemyID );
	if( !kHackingBreakdown.bShow )
	{
		Hide();
		return; 
	}
	
	CenterPercent.SetSubTitle( StyleFinalHitChance(kHackingBreakdown) );
	LeftTitle.SetSubTitle( class'UIUtilities_Text'.static.StyleText( m_strHackerLabel, eUITextStyle_Tooltip_HackHeaderLeft));

	LeftStatList.RefreshData( ProcessSoldierBreakdown(kHackingBreakdown) );
	RightStatList.RefreshData( ProcessTargetBreakdown(kHackingBreakdown) );
}

simulated function string StyleFinalHitChance( UIHackingBreakdown kHackingBreakdown )
{
	local string FinalHitDisplay; 
	local EUIState eState; 

	FinalHitDisplay = string(kHackingBreakdown.FinalHitChance); 

	if( kHackingBreakdown.ExpectedHits > kHackingBreakdown.ExpectedBlocks )
		eState = eUIState_Good; 
	else
		eState = eUIState_Normal;
	
	FinalHitDisplay = class'UIUtilities_Text'.static.GetColoredText(FinalHitDisplay, eState);
	//FinalHitDisplay = class'UIUtilities_Text'.static.StyleText( string(kHackingBreakdown.FinalHitChance), eUITextStyle_Tooltip_HackHeaderLeft);
	FinalHitDisplay = class'UIUtilities_Text'.static.AlignCenter(FinalHitDisplay);
	
	return FinalHitDisplay;
}

simulated function array<UISummary_ItemStat> ProcessSoldierBreakdown( UIHackingBreakdown kBreakdown )
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local int i; 

	Item.Label = class'XLocalizedData'.default.HackingExpectedHitsLabel;
	Item.Value = string(kBreakdown.ExpectedHits);
	Item.LabelState = eUIState_Normal; 
	Item.ValueState = (kBreakdown.ExpectedHits > kBreakdown.ExpectedBlocks) ? eUIState_Good : eUIState_Normal; 
	Item.LabelStyle = eUITextStyle_Tooltip_HackBodyLeft; 
	Item.ValueStyle = eUITextStyle_Tooltip_StatValue;
	Stats.AddItem(Item);

	Item.Label = class'XLocalizedData'.default.HackingShotsLabel;
	Item.Value = kBreakdown.ShotPercent $"%"; 
	Item.LabelState = eUIState_Normal; 
	Item.ValueState = eUIState_Normal;
	Item.LabelStyle = eUITextStyle_Tooltip_HackH3Left;
	Item.ValueStyle = eUITextStyle_Tooltip_StatValue;
	Stats.AddItem(Item);
	
	for( i = 0; i < kBreakdown.ShotModifiers.length; i++ )
	{
		Item = kBreakdown.ShotModifiers[i];
		Stats.AddItem( Item );
	}

	if( kBreakdown.BonusHitsModifiers.length > 0 )
	{
		Item.Label = class'XLocalizedData'.default.HackingBonusHitsLabel;
		Item.Value = ""; 
		Item.LabelState = eUIState_Normal; 
		Item.ValueState = eUIState_Normal;
		Item.LabelStyle = eUITextStyle_Tooltip_HackH3Left;
		Item.ValueStyle = eUITextStyle_Tooltip_StatValue;
		Stats.AddItem(Item);

		for( i = 0; i < kBreakdown.BonusHitsModifiers.length; i++ )
		{
			Item = kBreakdown.BonusHitsModifiers[i];
			Stats.AddItem( Item );
		}
	}
	
	return Stats; 
}

simulated function array<UISummary_ItemStat> ProcessTargetBreakdown( UIHackingBreakdown kBreakdown )
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local int i; 

	Item.Label = class'XLocalizedData'.default.HackingExpectedBlocksLabel;
	Item.Value = string(kBreakdown.ExpectedBlocks);
	Item.LabelState = eUIState_Normal; 
	Item.ValueState = eUIState_Normal; 
	Item.LabelStyle = eUITextStyle_Tooltip_HackBodyRight; 
	Item.ValueStyle = eUITextStyle_Tooltip_HackStatValueLeft;
	Stats.AddItem(Item);

	Item.Label = class'XLocalizedData'.default.HackingBlocksLabel;
	Item.Value = kBreakdown.BlocksPercent $"%"; 
	Item.LabelState = eUIState_Normal; 
	Item.ValueState = eUIState_Normal;
	Item.LabelStyle = eUITextStyle_Tooltip_HackH3Right;
	Item.ValueStyle = eUITextStyle_Tooltip_HackStatValueLeft;
	Stats.AddItem(Item);

	for( i = 0; i < kBreakdown.BlockModifiers.length; i++ )
	{
		Item = kBreakdown.BlockModifiers[i];
		Stats.AddItem( Item );
	}

	if( kBreakdown.BonusBlocksModifiers.length > 0 )
	{
		Item.Label = class'XLocalizedData'.default.HackingBonusBlocksLabel;
		Item.Value = ""; 
		Item.LabelState = eUIState_Normal; 
		Item.ValueState = eUIState_Normal;
		Item.LabelStyle = eUITextStyle_Tooltip_HackH3Right;
		Item.ValueStyle = eUITextStyle_Tooltip_HackStatValueLeft;
		Stats.AddItem(Item);

		for( i = 0; i < kBreakdown.BonusBlocksModifiers.length; i++ )
		{
			Item = kBreakdown.BonusBlocksModifiers[i];
			Stats.AddItem( Item );
		}
	}

	return Stats; 
}

simulated function int DEBUG_GetUISummary_HackingBreakdown(out UIHackingBreakdown kBreakdown)
{
	local UISummary_ItemStat kModifier; 
	local int i; 
	
	kBreakdown.FinalHitChance = 999;
	kBreakdown.ExpectedHits = 6.6;
	kBreakdown.ExpectedBlocks = 5.5;
	kBreakdown.ShotPercent = 777;
	kBreakdown.BlocksPercent =555;

	// SHOT MODIFIERS -------------------------------
	for( i = 0; i < 2; i++ )
	{
		kModifier.Label = "Shot Modifier";
		kModifier.Value = "666";
		kModifier.LabelState = eUIState_Normal; 
		kModifier.ValueState = eUIState_Normal; 
		kModifier.LabelStyle = eUITextStyle_Tooltip_HackBodyLeft; 
		kModifier.ValueStyle = eUITextStyle_Tooltip_StatValue;

		kBreakdown.ShotModifiers.AddItem( kModifier ); 
	}

	// BLOCK MODIFIERS -------------------------------
	for( i = 0; i < 1; i++ )
	{
		kModifier.Label = "Block Modifier";
		kModifier.Value = "777";
		kModifier.LabelState = eUIState_Normal; 
		kModifier.ValueState = eUIState_Normal; 
		kModifier.LabelStyle = 	eUITextStyle_Tooltip_HackBodyRight; 
		kModifier.ValueStyle = eUITextStyle_Tooltip_HackStatValueLeft;

		kBreakdown.BlockModifiers.AddItem( kModifier ); 
	}

	// BONUS HITS MODIFIERS -------------------------------
	for( i = 0; i < 2; i++ )
	{
		kModifier.Label = "Bonus Hit Modifier";
		kModifier.Value = "888";
		kModifier.LabelState = eUIState_Normal; 
		kModifier.ValueState = eUIState_Normal; 
		kModifier.LabelStyle = eUITextStyle_Tooltip_HackBodyLeft; 
		kModifier.ValueStyle = eUITextStyle_Tooltip_StatValue;

		kBreakdown.BonusHitsModifiers.AddItem( kModifier ); 
	}

	// BONUS BLOCKS MODIFIERS -------------------------------
	for( i = 0; i < 1; i++ )
	{
		kModifier.Label = "Bonus Block Modifier";
		kModifier.Value = "999";
		kModifier.LabelState = eUIState_Normal; 
		kModifier.ValueState = eUIState_Normal; 
		kModifier.LabelStyle = 	eUITextStyle_Tooltip_HackBodyRight; 
		kModifier.ValueStyle = eUITextStyle_Tooltip_HackStatValueLeft;

		kBreakdown.BonusBlocksModifiers.AddItem( kModifier ); 
	}

	kBreakdown.bShow = true; 

	return kBreakdown.FinalHitChance;
}



//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	height = 210;

	LeftWidth = 250; 
	RightWidth = 250; 
	CenterPadding = 0;

	bUsePartialPath = true; 
	bFollowMouse = false;

	PADDING_LEFT = 10;
	PADDING_RIGHT = 10;
	PADDING_TOP = 10;
	PADDING_BOTTOM = 10;
}