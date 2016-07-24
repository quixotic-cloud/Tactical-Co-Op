//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIAbilityListItem.uc
//  AUTHOR:  Brit Steiner 7/11/2014
//  PURPOSE: Ability list item used in tacticaHUD tooltips for abilities.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIAbilityListItem extends UIPanel;

var public UISummary_Ability Data; 
var public int ID; 

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

//List that owns this object. 
var UIAbilityList List;

simulated function UIAbilityListItem InitAbilityListItem(UIAbilityList initList,
															   optional int InitX = 0, 
															   optional int InitY = 0, 
															   optional int InitWidth = 0)
{
	InitPanel(); 

	List = initList;

	if( List == none )
	{
		`log("UIAbilityListItem incoming 'List' is none.",,'uixcom');
		return self;
	}

	//Inherit size. 
	if( InitWidth == 0 )
		width = List.width;
	else
		width = InitWidth;

	Title = Spawn(class'UIScrollingText', self).InitScrollingText('Title', "", width,,,true);
	Title.SetWidth(width); 

	Keybinding = Spawn(class'UIText', self).InitText('Keybinding');
	Keybinding.SetWidth(width); 

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( Title );

	Actions = Spawn(class'UIText', self).InitText('Actions');
	Actions.SetWidth(width); 
	Actions.SetPosition(0, Line.Y+ActionsPadding); 

	EndTurn = Spawn(class'UIText', self).InitText('EndTurn');
	EndTurn.SetWidth(width); 
	EndTurn.SetPosition(0, Line.Y+ActionsPadding);

	Desc = Spawn(class'UIText', self).InitText('Desc');
	Desc.SetWidth(width); 
	Desc.SetPosition(0, Actions.Y + Actions.height);
	Desc.onTextSizeRealized = onTextSizeRealized; 

	Cooldown = Spawn(class'UIText', self).InitText('Cooldown');
	Cooldown.SetWidth(width); 
	//Y loc set in the update data.

	Effect = Spawn(class'UIText', self).InitText('Effect');
	Effect.SetWidth(width); 
	//Y loc set in the update data.

	return self;
}

simulated function UIAbilityListItem SetText(string txt)
{
	//Do nothing.
	return self;
}

simulated function Show()
{
	RefreshDisplay();
	super.Show();
}

simulated function RefreshDisplay()
{
	Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( Data.Name, eUITextStyle_Tooltip_Title) );
	Keybinding.SetHTMLText( class'UIUtilities_Text'.static.StyleText( Data.KeybindingLabel, eUITextStyle_Tooltip_StatLabelRight ) );
	Actions.SetHTMLText( GetActionString( Data.ActionCost ) ); 
	EndTurn.SetHTMLText( GetEndTurnString( Data.bEndsTurn ) ); 
	Desc.SetHTMLText( class'UIUtilities_Text'.static.StyleText( Data.Description, eUITextStyle_Tooltip_Body ));
	Cooldown.SetHTMLText( GetCooldownString( Data.CooldownTime ) ); 
	Effect.SetHTMLText( class'UIUtilities_Text'.static.StyleText( Data.EffectLabel, eUITextStyle_Tooltip_StatLabelRight ) ); 
}

simulated function string GetActionString( int iActions )
{
	local string Label; 

	Label = (iActions > 1) ? class'XLocalizedData'.default.ActionsLabel : class'XLocalizedData'.default.ActionLabel;

	if( iActions > 0 )
		return class'UIUtilities_Text'.static.StyleText( string(iActions), eUITextStyle_Tooltip_AbilityValue)
			   @ class'UIUtilities_Text'.static.StyleText( Label, eUITextStyle_Tooltip_StatLabel); 
	else return "";
}

simulated function string GetEndTurnString( bool bEndsTurn )
{
	if( bEndsTurn )
		 return class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.EndTurnLabel, eUITextStyle_Tooltip_StatLabelRight ) ;
	else
		return ""; 
}

simulated function string GetCooldownString( int iCooldown )
{
	local string Label; 

	Label = class'XLocalizedData'.default.CooldownLabel;
	if( iCooldown > 0 )
		return class'UIUtilities_Text'.static.StyleText(string(iCooldown), eUITextStyle_Tooltip_AbilityValue)
			   @ class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.TurnLabel, eUITextStyle_Tooltip_Body)
			   @ class'UIUtilities_Text'.static.StyleText( Label, eUITextStyle_Tooltip_StatLabel); 
	else 
		return "";
}

simulated function onTextSizeRealized()
{
	local int iCalcNewHeight;

	iCalcNewHeight = Desc.Y + Desc.height + Cooldown.Height; 

	if( iCalcNewHeight != height )
	{
		height = iCalcNewHeight;  

		Cooldown.SetY(Desc.Y + Desc.height);
		Effect.SetY(Cooldown.Y);

		List.OnItemChanged(self);
	}
}

defaultproperties
{
	TitlePadding = 6;
	ActionsPadding = 4;
}