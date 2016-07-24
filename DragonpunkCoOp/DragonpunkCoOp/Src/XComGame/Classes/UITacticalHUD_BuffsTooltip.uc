//---------------------------------------------------------------------------------------
 //  FILE:    UITooltip_BonusesAndPenalties.uc
 //  AUTHOR:  Brit Steiner --  7/1/2014
 //  PURPOSE: Tooltip for the bonus list or the penalty list used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_BuffsTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;

var int headerHeight; 
var int MaxHeight; 
var float AnchorX; 
var float AnchorY; 

var UIEffectList	ItemList; 
var UIMask			ItemListMask; 
var UIPanel				Header; 
var UIText			Title; 
var UIPanel				HeaderIcon; 
var UIPanel				BGBox; 

var bool ShowBonusHeader; 
var bool IsSoldierVersion;
var bool ShowOnRightSide;

var string m_strBonusMC;
var string m_strPenaltyMC; 

simulated function UIPanel InitBonusesAndPenalties(optional name InitName, optional name InitLibID, optional bool bIsBonusPanel, optional bool bIsSoldier, optional float InitX = 0, optional float InitY = 0, optional bool bShowOnRight)
{
	InitPanel(InitName, InitLibID);

	Hide();
	SetPosition(InitX, InitY);
	AnchorX = InitX; 
	AnchorY = InitY; 
	ShowOnRightSide = bShowOnRight;

	ShowBonusHeader = bIsBonusPanel;
	IsSoldierVersion = bIsSoldier;
	
	BGBox = Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	BGBox.SetWidth(width); // Height set in size callback

	// --------------------------------------------- 
	Header = Spawn(class'UIPanel', self).InitPanel('HeaderArea').SetPosition(PADDING_LEFT,0);
	Header.SetHeight(headerHeight);

	if( bIsBonusPanel )
		HeaderIcon = Spawn(class'UIPanel', Header).InitPanel('BonusIcon', class'UIUtilities_Controls'.const.MC_BonusIcon).SetSize(20,20);
	else
		HeaderIcon = Spawn(class'UIPanel', Header).InitPanel('PenaltyIcon', class'UIUtilities_Controls'.const.MC_PenaltyIcon).SetSize(20,20);
	
	HeaderIcon.SetY(8);

	Title = Spawn(class'UIText', Header).InitText('Title');
	Title.SetPosition(30, 2); 
	Title.SetWidth(width - PADDING_LEFT - HeaderIcon.width); 
	//Title.SetAlpha( class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_StatLabel).Alpha );
		
	// --------------------------------------------- 
	
	ItemList = Spawn(class'UIEffectList', self);
	ItemList.InitEffectList('ItemList',
		, 
		PADDING_LEFT, 
		PADDING_TOP + headerHeight, 
		width-PADDING_LEFT-PADDING_RIGHT, 
		Height-PADDING_TOP-PADDING_BOTTOM - headerHeight,
		Height-PADDING_TOP-PADDING_BOTTOM - headerHeight,
		MaxHeight,
		OnEffectListSizeRealized);

	ItemListMask = Spawn(class'UIMask', self).InitMask('Mask', ItemList).FitMask(ItemList); 

	// --------------------------------------------- 

	return self; 
}

simulated function ShowTooltip()
{
	super.ShowTooltip();
	RefreshData();	
}

simulated function RefreshData()
{
	local XGUnit				kActiveUnit;
	local XComGameState_Unit	kGameStateUnit;
	local int					iTargetIndex; 
	local array<string>			Path; 
	local array<UISummary_UnitEffect> Effects; 

	//Trigger on the correct hover item 
	if( XComTacticalController(PC) != None )
	{	
		if( IsSoldierVersion )
		{
			kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		}
		else
		{
			Path = SplitString( currentPath, "." );	
			iTargetIndex = int(Split( Path[5], "icon", true));
			kActiveUnit = XGUnit(XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetEnemyAtIcon(iTargetIndex));
		}
	}

	// Only update if new unit
	if( kActiveUnit == none )
	{
		if( XComTacticalController(PC) != None )
		{
			HideTooltip();
			return; 
		}
	} 
	else if( kActiveUnit != none )
	{
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}

	if(ShowBonusHeader)
	{
		Effects = kGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus);
		Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.BonusesHeader, eUITextStyle_Tooltip_StatLabel) );
	}
	else
	{
		Effects = kGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);
		Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.PenaltiesHeader, eUITextStyle_Tooltip_StatLabel) );
	}

	if( Effects.length == 0 )
	{
		if( XComTacticalController(PC) != None )
			HideTooltip();
		else
			ItemList.RefreshData( DEBUG_GetData() );
		return; 
	}

	ItemList.RefreshData( Effects );
	OnEffectListSizeRealized();
}

simulated function array<UISummary_UnitEffect> DEBUG_GetData()
{
	local array<UISummary_UnitEffect> Items; 
	local UISummary_UnitEffect Item; 
	local int i, iSize;

	if( ShowBonusHeader )
		iSize = 10;
	else 
		iSize = 3; 

	for( i = 0; i < iSize; i++ )
	{
		if( ShowBonusHeader )
			Item.Name = "Bonus" @ string(i);
		else
			Item.Name = "Penalty" @ string(i);

		Item.Description = "Sample "$string(i) $" description! This is where the description for the perk would go.";
		Item.Icon = "img:///UILibrary_PerkIcons.UIPerk_gremlincommand";
		Items.AddItem(Item);
	}

	return Items;
}

static function bool IsPathBonusOrPenaltyMC( string tPath )
{
	local array<string>	Path; 
	local string		MCLabel; 

	//Trigger only on the correct hover item 
	Path = SplitString( tPath, "." );	
	MCLabel = Path[Path.length-1]; 

	return ( MCLabel == default.m_strBonusMC 
		 ||  MCLabel == default.m_strPenaltyMC );
}

simulated function OnEffectListSizeRealized()
{
	local Vector2D BottomAnchor;

	Height = PADDING_TOP + PADDING_BOTTOM + headerHeight + ItemList.MaskHeight;
	BGBox.SetHeight( Height );
	ItemListMask.SetHeight(ItemList.MaskHeight);

	if (ShowOnRightSide)
	{
		BottomAnchor = Movie.ConvertNormalizedScreenCoordsToUICoords(1, 1); //Bottom Right
		SetPosition(BottomAnchor.X - Width - 20, BottomAnchor.Y - 180 - Height);
	}
	else
	{
		BottomAnchor = Movie.ConvertNormalizedScreenCoordsToUICoords(0, 1); //Bottom Left
		SetPosition(BottomAnchor.X + 20, BottomAnchor.Y - 180 - Height);
	}

	if (TooltipGroup != none)
	{
		if (UITooltipGroup_Stacking(TooltipGroup) != none)
			UITooltipGroup_Stacking(TooltipGroup).UpdateRestingYPosition(self, Y);
		TooltipGroup.SignalNotify();
	}
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	width = 450;
	Height = 220;
	MaxHeight = 700;

	headerHeight = 30; 

	PADDING_LEFT	= 10;
	PADDING_RIGHT	= 10;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;

	bUsePartialPath = true; 
	bFollowMouse = false;
	Anchor = 0;

	m_strBonusMC = "bonusMC"
	m_strPenaltyMC = "penaltyMC";
}