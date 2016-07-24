//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalInfoListItem.uc
//  AUTHOR:  Brit Steiner 7/28/2014
//  PURPOSE: Ability list item used in armory for tactical info. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalInfoListItem extends UIPanel
	dependson(UIQueryInterfaceItem);

var public UISummary_TacaticalText Data;

var UIIcon Icon; 
var UIScrollingText Title; 
var UIText Desc; 

var int TitlePadding; 
var int DescPadding; 
var int EndPadding; 

simulated function UITacticalInfoListItem InitTacticalInfoListItem()
{
	local UITacticalInfoList ParentList;

	InitPanel();

	// Inherit size
	ParentList = UITacticalInfoList(GetParent(class'UITacticalInfoList'));
	if(ParentList != none)
		Width = ParentList.width;

	Icon = Spawn(class'UIIcon', self);
	Icon.bAnimateOnInit = false;
	Icon.InitIcon(,,false,true,36);
	Icon.SetY(5);

	Title = Spawn(class'UIScrollingText', self);
	Title.bAnimateOnInit = false;
	Title.InitScrollingText('Title', "", width,,,true);
	Title.SetPosition(Icon.X + Icon.width + TitlePadding, 10);
	Title.SetWidth(width - Title.X); 

	Desc = Spawn(class'UIText', self);
	Desc.bAnimateOnInit = false;
	Desc.InitText('Desc', "", true);
	Desc.SetWidth(width - Desc.X); 
	Desc.SetAlpha(67);

	return self;
}

simulated function Show()
{
	RefreshDisplay();
	super.Show();
}

simulated function RefreshDisplay()
{
	Icon.LoadIcon(Data.Icon);
	if( Data.Icon == "" )
	{
		Icon.HideBG();
		Desc.SetY(0);
	}
	else
	{
		Icon.ShowBG();
		Desc.SetY(Icon.Y + Icon.Height + DescPadding);
	}

	if(Data.Name != "")
		Title.SetTitle(Data.Name);
	
	Desc.SetHTMLText(class'UIUtilities_Text'.static.GetColoredText(Data.Description, eUIState_Normal, 26), DescriptionTextRealized);
}

simulated function DescriptionTextRealized()
{
	local UITacticalInfoList ParentList;

	Height = Desc.Y + Desc.Height + EndPadding;

	ParentList = UITacticalInfoList(GetParent(class'UITacticalInfoList'));
	if(ParentList != none)
		ParentList.RealizeSize();
}

defaultproperties
{
	EndPadding = 6;
	DescPadding = 4;
	TitlePadding = 6;
	bAnimateOnInit = false;
}