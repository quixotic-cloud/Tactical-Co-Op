//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyScreenListener
//  AUTHOR:  Sam Batista
//
//  PURPOSE: This class listens for ScreenStack changes and updates top-level UI components.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyScreenListener extends UIScreenListener;

function bool IsInStrategy()
{
	return `HQGAME  != none && `HQPC != None && `HQPRES != none;
}

event OnInit(UIScreen Screen)
{
	if(IsInStrategy())
	{
		RealizeToDoWidget();
		RealizeShortcuts();
		RealizeLinks();
		RealizeEventQueue();
		RealizeObjectives();
		RealizeResourceHeader();
		RealizeFacilityGrid();
		RealizeCommLink();
	}
}

event OnReceiveFocus(UIScreen Screen)
{
	if(IsInStrategy())
	{
		RealizeToDoWidget();
		RealizeShortcuts();
		RealizeLinks();
		RealizeEventQueue();
		RealizeObjectives();
		RealizeResourceHeader();
		RealizeFacilityGrid();
		RealizeCommLink();
	}
}

function RealizeToDoWidget()
{
	local UIToDoWidget ToDoWidget;

	if(`SCREENSTACK.IsInStack(class'UIAvengerHUD'))
		ToDoWidget = UIAvengerHUD(`SCREENSTACK.GetScreen(class'UIAvengerHUD')).ToDoWidget;

	if(ToDoWidget != none)
	{
		switch( `SCREENSTACK.GetCurrentClass() )
		{
		case class'UIFacilityGrid':
			ToDoWidget.RefreshLocation();
			ToDoWidget.RequestCategoryUpdate();
			break;
		case class'UIStrategyMap':
			ToDoWidget.RefreshLocation();
			ToDoWidget.Show();
			break;
		default:
			ToDoWidget.Hide();
			break;
		}
	}
}

function RealizeShortcuts()
{
	local UIAvengerShortcuts Shortcuts;
	local UIScreen CurrentScreen;

	if(`SCREENSTACK.IsInStack(class'UIAvengerHUD'))
	Shortcuts = UIAvengerHUD(`SCREENSTACK.GetScreen(class'UIAvengerHUD')).Shortcuts;

	CurrentScreen = `SCREENSTACK.GetCurrentScreen();

	if(Shortcuts != none)
	{
		if( CurrentScreen.IsA('UIFacility') )
		{
			Shortcuts.Show();
			Shortcuts.SelectCategoryForFacilityScreen(UIFacility(CurrentScreen));
			Shortcuts.ShowList();
		}
		else
		{
			switch( CurrentScreen.Class )
			{
			case class'UIFacility':
				Shortcuts.Show();
				Shortcuts.ShowList();
				break;
			case class'UIFacilityGrid':
				Shortcuts.Show();
				Shortcuts.HideList();
				break;
			default:
				Shortcuts.Hide();
			}
		}
	}
}

function RealizeLinks()
{
	local UIAvengerLinks Links;
	local UIScreen CurrentScreen;

	if( `SCREENSTACK.IsInStack(class'UIAvengerHUD') )
		Links = UIAvengerHUD(`SCREENSTACK.GetScreen(class'UIAvengerHUD')).Links;

	CurrentScreen = `SCREENSTACK.GetCurrentScreen();

	if( Links != none )
	{
		if( CurrentScreen.IsA('UIFacility') )
		{
			Links.Show();
		}
		else
		{
			switch( CurrentScreen.Class )
			{
			case class'UIFacility':
			case class'UIFacilityGrid':
				Links.Show();
				break;
			default:
				Links.Hide();
			}
		}
	}
}

function RealizeResourceHeader()
{
	local UIAvengerHUD AvengerHUD;

	AvengerHUD = UIAvengerHUD(`SCREENSTACK.GetScreen(class'UIAvengerHUD'));
	if (AvengerHUD != none)
		AvengerHUD.UpdateResources();
}

function RealizeCommLink()
{
	//NOTE: this shoudl happen *AFTER* the resource header is updated. 
	`HQPRES.GetUIComm().RefreshAnchorListener();
}

function RealizeEventQueue()
{
	local UIAvengerHUD AvengerHUD;
	local UIScreen CurrentScreen;

	AvengerHUD = UIAvengerHUD(`SCREENSTACK.GetScreen(class'UIAvengerHUD'));

	if( AvengerHUD != none )
	{
		CurrentScreen = `SCREENSTACK.GetCurrentScreen();

		switch( CurrentScreen.Class )
		{
		case class'UIFacilityGrid':
		case class'UIInventory_BuildItems': 
			AvengerHUD.ShowEventQueue(false);
			break; 
		case class'UIStrategyMap':
			AvengerHUD.ShowEventQueue(true);
			break;
		default:
			AvengerHUD.HideEventQueue();
			break;
		}
	}
}

function RealizeObjectives()
{
	local UIAvengerHUD AvengerHUD;
	local UIScreen CurrentScreen;

	AvengerHUD = UIAvengerHUD(`SCREENSTACK.GetScreen(class'UIAvengerHUD'));

	if( AvengerHUD != none )
	{
		CurrentScreen = `SCREENSTACK.GetCurrentScreen();

		switch( CurrentScreen.Class )
		{
		case class'UIFacilityGrid':
		case class'UIStrategyMap':
			AvengerHUD.Objectives.Show();
			break;
		default:
			AvengerHUD.Objectives.Hide();
			break;
		}
	}
}


function RealizeFacilityGrid()
{
	local XComHQPresentationLayer Pres;
	local UIScreen CurrentScreen;

	Pres = `HQPRES;

	if( Pres != none && Pres.m_kFacilityGrid != none )
	{
		CurrentScreen = `SCREENSTACK.GetCurrentScreen();

		if (CurrentScreen != None)
		{
			switch( CurrentScreen.Class )
			{
			case class'UIFacilityGrid':
			case class'UIBuildFacilities':
				Pres.m_kFacilityGrid.Show();
				break;
			default:
				Pres.m_kFacilityGrid.Hide();
				break;
			}
		}
	}
}
