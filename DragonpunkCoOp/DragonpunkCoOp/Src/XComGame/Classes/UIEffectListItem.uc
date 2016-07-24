//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIEffectListItem.uc
//  AUTHOR:  Brit Steiner 7/1/2014
//  PURPOSE: Ability list item used in tacticaHUD tooltips for perks, 
//			 buffs, debuffs, etc. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIEffectListItem extends UIPanel;

var public UISummary_UnitEffect Data; 
var public int ID; 

var UIIcon Icon; 
var UIScrollingText Title; 
var UIPanel Line; 
var UIText Desc; 

var int TitleXPadding; 
var int TitleYPadding; 
var int DescPadding; 
var int BottomPadding; 

//List that owns this object. 
var UIEffectList List;

simulated function UIEffectListItem InitEffectListItem(UIEffectList initList,
															   optional int InitX = 0, 
															   optional int InitY = 0, 
															   optional int InitWidth = 0)
{
	InitPanel(); 

	List = initList;

	if( List == none )
	{
		`log("UIEffectListItem incoming 'List' is none.",,'uixcom');
		return self;
	}

	//Inherit size. 
	if( InitWidth == 0 )
		width = List.width;
	else
		width = InitWidth;

	Icon = Spawn(class'UIIcon', self).InitIcon(,,false,true,36);

	Title = Spawn(class'UIScrollingText', self).InitScrollingText('Title', "", width,,,true);
	Title.SetPosition( Icon.Y + Icon.width + TitleXPadding, TitleYPadding );
	Title.SetWidth(width - Title.X); 

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( Title );

	Desc = Spawn(class'UIText', self).InitText('Desc', "", true);
	Desc.SetWidth(width); 
	Desc.SetPosition(0, Line.Y + DescPadding);
	Desc.onTextSizeRealized = onTextSizeRealized; 

	return self;
}

simulated function UIEffectListItem SetText(string txt)
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
	if (Data.Icon == "")
	{
		Icon.Hide();
	}
	else
	{
		Icon.LoadIcon(Data.Icon);
		Icon.Show();
	}

	Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText(Data.Name, eUITextStyle_Tooltip_Title));
	Desc.SetHTMLText( class'UIUtilities_Text'.static.StyleText(Data.Description, eUITextStyle_Tooltip_Body));
}

simulated function string GetActionString( int iActions )
{
	local string Label; 

	Label = (iActions > 1) ? class'XLocalizedData'.default.ActionsLabel : class'XLocalizedData'.default.ActionLabel;

	if( iActions > 0 )
		return string(iActions) @ Class'UIUtilities_Text'.static.GetColoredText(Label, eUIState_Disabled); 
	else return "";
}

simulated function string GetEndTurnString( bool bEndsTurn )
{
	if( bEndsTurn )
		 return class'UIUtilities_Text'.static.AlignRight( class'XLocalizedData'.default.EndTurnLabel ) ;
	else
		return ""; 
}

simulated function string GetCooldownString( int iCooldown )
{
	local string Label; 

	Label = class'XLocalizedData'.default.CooldownLabel;
	if( iCooldown > 0 )
		return string(iCooldown) @ class'XLocalizedData'.default.TurnLabel @ Class'UIUtilities_Text'.static.GetColoredText(Label, eUIState_Disabled); 
	else 
		return "";
}

simulated function onTextSizeRealized()
{
	local int iCalcNewHeight;

	iCalcNewHeight = Desc.Y + Desc.Height + BottomPadding; 

	if( iCalcNewHeight != Height )
	{
		Height = iCalcNewHeight;  

		List.OnItemChanged(self);
	}
}

defaultproperties
{
	TitleXPadding = 6;
	TitleYPadding = 4;
	DescPadding = 8;
	BottomPadding = 6;
}