//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIEventNotices.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Display and manage the short lifespan of visual notices. 
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIEventNotices extends UIScreen;

struct UIEventNoticeItem
{
	var string DisplayString;
	var string ImagePath;
	var float DisplayTime;
	structDefaultProperties
	{
		DisplayTime = 0.0;
	}
};

var UIPanel Container;
var UIList List; 
var float MaxDisplayTime; 
var array<UIEventNoticeItem> Notices;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	Container = Spawn(class'UIPanel', self);
	Container.InitPanel();

	if( XComPresentationLayer(Movie.Pres) != none ) //In tactical 
	{
		Container.AnchorBottomRight();
		Container.SetPosition( -10, -230);
	}
	else //in strategy 
	{
		Container.AnchorBottomLeft();
		Container.SetPosition(10, -200);
	}

	List = Spawn(class'UIList', Container);
	List.InitList('', 0, 0, 400, 400);
}

event Tick(float deltaTime)
{
	local int i, iInitialNotices;

	if (bIsVisible)
	{
		if (Notices.Length == 0) return;
		if (Movie.Stack.IsCurrentClass(class'UIDialogueBox')) return;

		iInitialNotices = Notices.length;

		if (Notices.Length > 0)
		{
			// Go from end to beginning because we may be removing items from the array. 
			for (i = Notices.Length - 1; i >= 0; i--)
			{
				Notices[i].DisplayTime += deltaTime;

				if (Notices[i].DisplayTime > MaxDisplayTime)
				{
					Notices.Remove(i, 1);
				}
			}
		}

		if (Notices.Length != iInitialNotices)
		{
			List.ClearItems();
			UpdateEventNotices();
		}
	}
}

simulated function Notify(string NewInfo, optional string ImagePath = "")
{
	local UIEventNoticeItem Notice;

	Notice.DisplayString = NewInfo;
	Notice.ImagePath = ImagePath;
	Notices.AddItem(Notice);
	UpdateEventNotices();
}

simulated function UpdateEventNotices()
{
	local int i;
	local UIEventNotice_ListItem ListItem;

	if(Notices.Length > 0)
	{
		for(i = 0; i < Notices.Length; ++i)
		{
			if( List.ItemCount <= i )
				ListItem = UIEventNotice_ListItem(Spawn(class'UIEventNotice_ListItem', List.itemContainer).InitPanel());
			else
				ListItem = UIEventNotice_ListItem(List.GetItem(i));

			ListItem.PopulateData(Notices[i].DisplayString, Notices[i].ImagePath);

		}
		Show();
	}
	else
	{
		Hide();
	}

	List.SetY(-List.ShrinkToFit());
}

simulated function bool AnyNotices()
{
	return Notices.Length > 0;
}

defaultproperties
{
	MaxDisplayTime = 5.0; 
}