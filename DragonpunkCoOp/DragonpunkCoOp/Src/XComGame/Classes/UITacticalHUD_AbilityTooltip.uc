//---------------------------------------------------------------------------------------
 //  FILE:    UITooltip_Ability.uc
 //  AUTHOR:  Brit Steiner --  7/11/2014
 //  PURPOSE: Tooltip for the single ability description used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_AbilityTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int MAX_HEIGHT;

var public UIPanel AbilityArea;
var public UIPanel BG;
var public UIMask AbilityMask;

var public UISummary_Ability Data; 

var UIScrollingText Title; 
var UIText Keybinding; 
var UIPanel Line; 
var UIText Desc; 
var UIText Actions;
var UIText EndTurn;
var UIText Cooldown;
var UIText Effect;

var int TitlePadding; 
var int ActionsPadding; 

//These are used to re-anchor after the size of this panel updates. 
var int InitAnchorX;
var int InitAnchorY;

simulated function UIPanel InitAbility(optional name InitName, 
										 optional name InitLibID,
										 optional int InitX = 0, //Necessary for anchoring
										 optional int InitY = 0, //Necessary for anchoring
										 optional int InitWidth = 0)
{
	InitPanel(InitName, InitLibID);

	Hide();

	SetPosition(InitX, InitY);
	InitAnchorX = X; 
	InitAnchorY = Y; 

	if( InitWidth != 0 )
		width = InitWidth;

	//---------------------

	BG = Spawn(class'UIPanel', self).InitPanel('BGBoxSimplAbilities', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetPosition(0, 0).SetSize(width, height);

	// --------------------

	Title = Spawn(class'UIScrollingText', self).InitScrollingText('Title', "", width - PADDING_LEFT - PADDING_RIGHT, PADDING_LEFT, ,true); 

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( Title );

	Keybinding = Spawn(class'UIText', self).InitText('Keybinding');
	Keybinding.SetWidth(width - PADDING_RIGHT); 

	// --------------------

	AbilityArea = Spawn(class'UIPanel', self); 
	AbilityArea.InitPanel('AbilityArea');
	AbilityArea.SetPosition(PADDING_LEFT, Line.Y + ActionsPadding);
	AbilityArea.width = width - PADDING_LEFT - PADDING_RIGHT;
	AbilityArea.height = height - AbilityArea.Y - PADDING_BOTTOM; //This defines the initialwindow, not the actual contents' height. 

	Actions = Spawn(class'UIText', AbilityArea).InitText('Actions');
	Actions.SetWidth(AbilityArea.width); 
	Actions.SetY(ActionsPadding); 

	EndTurn = Spawn(class'UIText', AbilityArea).InitText('EndTurn');
	EndTurn.SetWidth(AbilityArea.width); 
	EndTurn.SetY(ActionsPadding);

	Desc = Spawn(class'UIText', AbilityArea).InitText('Desc');
	Desc.SetWidth(AbilityArea.width); 
	Desc.SetY(Actions.Y + 26);
	Desc.onTextSizeRealized = onTextSizeRealized; 

	Cooldown = Spawn(class'UIText', AbilityArea).InitText('Cooldown');
	Cooldown.SetWidth(AbilityArea.width); 
	//Y loc set in the update data.

	Effect = Spawn(class'UIText', AbilityArea).InitText('Effect');
	Effect.SetWidth(AbilityArea.width); 
	//Y loc set in the update data.

	AbilityMask = Spawn(class'UIMask', self).InitMask('AbilityMask', AbilityArea).FitMask(AbilityArea);

	//--------------------------
	
	return self; 
}

simulated function ShowTooltip()
{
	RefreshData();
	super.ShowTooltip();
}
simulated function HideTooltip( optional bool bAnimateIfPossible = false )
{
	AbilityArea.ClearScroll();
	super.HideTooltip(bAnimateIfPossible);
}

simulated function RefreshData()
{
	local XComGameState_Ability	kGameStateAbility;
	local int					iTargetIndex; 
	local array<string>			Path; 

	if( XComTacticalController(PC) == None )
	{	
		Data = DEBUG_GetUISummary_Ability();
		RefreshDisplay();	
		return; 
	}

	Path = SplitString( currentPath, "." );	
	iTargetIndex = int(GetRightMost(Path[5]));
	kGameStateAbility = UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kAbilityHUD.GetAbilityAtIndex(iTargetIndex);
	
	if( kGameStateAbility == none )
	{
		HideTooltip();
		return; 
	}

	Data = kGameStateAbility.GetUISummary_Ability();
	RefreshDisplay();	
}

simulated function RefreshDisplay()
{
	Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText(Data.Name, eUITextStyle_Tooltip_Title) );
	Keybinding.SetHTMLText( class'UIUtilities_Text'.static.StyleText(Data.KeybindingLabel, eUITextStyle_Tooltip_AbilityRight) );
	Actions.SetText( GetActionString(Data.ActionCost) );
	EndTurn.SetText( class'UIUtilities_Text'.static.StyleText(GetEndTurnString(Data.bEndsTurn), eUITextStyle_Tooltip_AbilityRight) );
	Desc.SetHTMLText( class'UIUtilities_Text'.static.StyleText(`XEXPAND.ExpandString(Data.Description), eUITextStyle_Tooltip_Body) );
	Cooldown.SetText( GetCooldownString(Data.CooldownTime) );
	Effect.SetText( class'UIUtilities_Text'.static.StyleText(Data.EffectLabel, eUITextStyle_Tooltip_AbilityRight) );
	RefreshSizeAndScroll();
}

simulated function string GetActionString( int iActions )
{
	local string Label; 

	Label = (iActions > 1) ? class'XLocalizedData'.default.ActionsLabel : class'XLocalizedData'.default.ActionLabel;

	if( iActions > 0 )
		return class'UIUtilities_Text'.static.StyleText(string(iActions), eUITextStyle_Tooltip_Title) @ class'UIUtilities_Text'.static.StyleText(Label, eUITextStyle_Tooltip_StatLabel);
	else return "";
}

simulated function string GetEndTurnString( bool bEndsTurn )
{
	if( bEndsTurn )
		return class'XLocalizedData'.default.EndTurnLabel;
	else
		return ""; 
}

simulated function string GetCooldownString( int iCooldown )
{
	local string Label; 

	Label = class'XLocalizedData'.default.CooldownLabel;
	if( iCooldown > 0 )
		return class'UIUtilities_Text'.static.StyleText(string(iCooldown), eUITextStyle_Tooltip_Title) @ class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.TurnLabel, eUITextStyle_Tooltip_StatLabel) @ class'UIUtilities_Text'.static.StyleText(Label, eUITextStyle_Tooltip_StatLabel); 
	else 
		return "";
}

simulated function onTextSizeRealized()
{
	RefreshSizeAndScroll();
}
simulated function RefreshSizeAndScroll()
{
	local int iCalcNewHeight;
	local int MaxAbilityHeight;
	
	AbilityArea.ClearScroll();

	AbilityArea.height = Desc.Y + Desc.height + Cooldown.Height; 
	iCalcNewHeight = AbilityArea.Y + AbilityArea.height; 
	MaxAbilityHeight = MAX_HEIGHT - AbilityArea.Y; 

	if( iCalcNewHeight != height )
	{
		height = iCalcNewHeight;  
		if( height > MAX_HEIGHT )
			height = MAX_HEIGHT; 

		Cooldown.SetY(Desc.Y + Desc.height);
		Effect.SetY(Cooldown.Y);
	}

	if( AbilityArea.height < MaxAbilityHeight )
		AbilityMask.SetSize(AbilityArea.width, AbilityArea.height); 
	else
		AbilityMask.SetSize(AbilityArea.width, MaxAbilityHeight - PADDING_BOTTOM); 

	AbilityArea.AnimateScroll(AbilityArea.height, AbilityMask.height);

	BG.SetSize(width, height);
	SetY( InitAnchorY - height );
}

simulated function UISummary_Ability DEBUG_GetUISummary_Ability()
{
	local UISummary_Ability AbilityInfo; 

	AbilityInfo.KeybindingLabel = "KEY";
	AbilityInfo.Name = "SINGLE DESC"; 
	AbilityInfo.Description = "Description text area. Lorizzle for sure dolizzle shizznit amizzle, crunk adipiscing fo."  $" Nullizzle sapien velizzle, yo volutpizzle, quizzle, daahng dawg vel, arcu. Pellentesque i saw beyonces tizzles and my pizzle went crizzle tortor. Fizzle eros. Doggy uhuh ... yih! shut the shizzle up dapibus turpis tempus da bomb. Maurizzle pellentesque nibh turpizzle. Get down get down izzle tortor. Fo shizzle my nizzle shiznit rhoncus nisi. In check out this platea dawg. Daahng dawg rizzle. Shizznit tellus things, pretizzle bizzle, mattizzle ac, we gonna chung vitae, yo. Check it out suscipizzle. Integer sempizzle check it out sizzle ass."; 
	AbilityInfo.ActionCost = 1;
	AbilityInfo.CooldownTime = 1; 
	AbilityInfo.bEndsTurn = true;
	AbilityInfo.EffectLabel = "REFLEX";
	AbilityInfo.Icon = "img:///UILibrary_PerkIcons.UIPerk_gremlincommand";

	return AbilityInfo; 
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	width = 350;
	height = 150; 
	MAX_HEIGHT = 400; 

	PADDING_LEFT	= 10;
	PADDING_RIGHT	= 10;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;

	TitlePadding = 6;
	ActionsPadding = 2;
}