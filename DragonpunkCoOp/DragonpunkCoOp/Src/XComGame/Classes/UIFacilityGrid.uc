
class UIFacilityGrid extends UIScreen;

var UIFacilityGrid_FacilityOverlay m_kSelectedOverlay;
var array<UIFacilityGrid_FacilityOverlay> FacilityOverlays;
var bool bInstantInterp;

var bool bForceShowGrid; 

var localized string MenuPause;
var localized string MenuGridOn;
var localized string MenuGridOff;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	local XComGameState_HeadquartersRoom RoomState; 
	local Vector Loc, DefaultOffset; 
	local array<Vector> Corners; 

	super.InitScreen(InitController, InitMovie, InitName);

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersRoom', RoomState)
	{
		Loc = RoomState.GetLocation();
		Corners = RoomState.GetUILocations();

		//If we didn't find the points in the level, then generate the defaults. 
		if( Corners.Length == 0 )
		{
			//Use default if no facility is in this location. 
			DefaultOffset = class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_RoomUIOffset; 
			Corners.AddItem(Loc);
			Corners.AddItem(Loc + DefaultOffset); 
		}

		Corners.Sort(SortCorners); 

		FacilityOverlay = Spawn(class'UIFacilityGrid_FacilityOverlay', self);
		FacilityOverlay.InitFacilityOverlay(RoomState.GetReference(), Loc, Corners);

		FacilityOverlays.AddItem(FacilityOverlay);
	}

	FacilityOverlays.Sort(SortFacilityOverlaysByMapIndex);

	InitializeNavigationGrid(); 

	SetBorderSize(Movie.UI_RES_X * 0.9, Movie.UI_RES_Y * 0.9);

	Movie.Pres.SubscribeToUIUpdate(UpdateOverlayPositions);
	
	RefreshButtonHelp();
}

simulated function OnInit()
{
	local UIPanel SelectedPanel; 

	super.OnInit();

	// This will allow a room to be default selected in the super.OnInit, but will 
	// then hide the highlight. The highlight reappears if any keyboard button or mouse over action occurs. 
	SelectedPanel = Navigator.GetSelected(); 
	if( SelectedPanel!= none )
		SelectedPanel.OnLoseFocus();
}

simulated function UpdateData()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	foreach FacilityOverlays(FacilityOverlay)
		FacilityOverlay.UpdateData();
}

simulated function Show()
{
	if( !IsTimerActive('CameraTravelFinished') )
		super.Show();
	//AnimateIn();
}

simulated function Hide()
{
	super.Hide();
	MC.FunctionVoid("hideBorder");
}

simulated function UpdateOverlayPositions()
{
	local Vector2D v2DPos, v2Offset;
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	foreach FacilityOverlays(FacilityOverlay)
	{
		// get screen position for the upper corner
		class'UIUtilities'.static.IsOnScreen(FacilityOverlay.Corners[0], v2DPos, 0, 0);
		v2DPos = Movie.ConvertNormalizedScreenCoordsToUICoords(v2DPos.x, v2DPos.y, false);
		
		// get screen position for the lower corner
		class'UIUtilities'.static.IsOnScreen(FacilityOverlay.Corners[1], v2Offset, 0, 0);
		v2Offset = Movie.ConvertNormalizedScreenCoordsToUICoords(v2Offset.x, v2Offset.y, false);
		
		//FacilityOverlay.UpdateBGSizeUsingOffset(v2Offset.X - v2DPos.x, v2Offset.Y - v2DPos.y);
		FacilityOverlay.SetSize(Abs(v2Offset.X - v2DPos.x), Abs(v2Offset.Y - v2DPos.y));

		// ------------------------------- 

		/// NOTE: you want to set the location *after* setting the Offset -> BG Size up above, that way the BG has updated the facility's height. 
		FacilityOverlay.SetPosition(v2DPos.x, v2DPos.y - FacilityOverlay.height);

		// ------------------------------- 

		FacilityOverlay.Show();
	}

	// This flushes queued SetPosition events so UI elements don't lag behind the Facility Rooms
	Movie.ProcessQueuedCommands();
}

//Sorts so that map index matches array index. 
simulated function int SortFacilityOverlaysByMapIndex(UIFacilityGrid_FacilityOverlay FacilityA, UIFacilityGrid_FacilityOverlay FacilityB)
{
	if( FacilityA.RoomMapIndex < FacilityB.RoomMapIndex )
		return 1;
	else
		return -1;
}

simulated function InitializeNavigationGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay, CommandersQuarters, CIC, Armory, Engineering, PowerCore, LivingQuarters, Memorial;
	
	//CORE FACILITIES: ==============================================

	PowerCore = FacilityOverlays[1];
	CommandersQuarters = FacilityOverlays[0];
	CIC = FacilityOverlays[15];
	Armory = FacilityOverlays[2];
	Engineering = FacilityOverlays[17]; 
	LivingQuarters = FacilityOverlays[16];
	Memorial = FacilityOverlays[18];

	//PowerCore.Navigator.AddNavTargetLeft(None);
	PowerCore.Navigator.AddNavTargetRight(FacilityOverlays[3]); //Top left of grid
	PowerCore.Navigator.AddNavTargetUp(CommandersQuarters);
	//PowerCore.Navigator.AddNavTargetDown(None);

	//CommandersQuarters.Navigator.AddNavTargetLeft(none);
	CommandersQuarters.Navigator.AddNavTargetRight(CIC);
	CommandersQuarters.Navigator.AddNavTargetDown(LivingQuarters);
	//CommandersQuarters.Navigator.AddNavTargetUp(none);

	CIC.Navigator.AddNavTargetLeft(CommandersQuarters);
	CIC.Navigator.AddNavTargetRight(Armory);
	//CIC.Navigator.AddNavTargetUp(None);
	CIC.Navigator.AddNavTargetDown(FacilityOverlays[5]);

	Armory.Navigator.AddNavTargetLeft(FacilityOverlays[5]);
	//Armory.Navigator.AddNavTargetRight(None);
	//Armory.Navigator.AddNavTargetUp(None);
	Armory.Navigator.AddNavTargetDown(Engineering);
	
	Engineering.Navigator.AddNavTargetLeft(FacilityOverlays[8]);
	//Engineering.Navigator.AddNavTargetRight(None);
	Engineering.Navigator.AddNavTargetUp(Memorial);
	//Engineering.Navigator.AddNavTargetDown(None);
	
	//LivingQuarters.Navigator.AddNavTargetLeft(none);
	LivingQuarters.Navigator.AddNavTargetRight(CIC);
	LivingQuarters.Navigator.AddNavTargetDown(FacilityOverlays[4]); //Top center column 
	LivingQuarters.Navigator.AddNavTargetUp(CommandersQuarters);

	Memorial.Navigator.AddNavTargetLeft(FacilityOverlays[5]);
	//Memorial.Navigator.AddNavTargetRight(None);
	Memorial.Navigator.AddNavTargetUp(Armory);
	Memorial.Navigator.AddNavTargetDown(Engineering);

	// CENTER GRID: ==================================================

	// TOP ROW 0 ---------------------------------------------------------
	// Top left  3
	FacilityOverlay = FacilityOverlays[3];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetUp(CIC);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[6]);


	// Top middle 4
	FacilityOverlay = FacilityOverlays[4];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetUp(LivingQuarters);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[7]);

	// Top Right 5
	FacilityOverlay = FacilityOverlays[5];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetRight(Armory);
	FacilityOverlay.Navigator.AddNavTargetUp(CIC);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[8]);

	// CENTER ROW 1 -------------------------------------------------------

	// Center left 6
	FacilityOverlay = FacilityOverlays[6];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[3]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[9]);

	// Center middle 7
	FacilityOverlay = FacilityOverlays[7];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[4]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[10]);

	// Center right 8
	FacilityOverlay = FacilityOverlays[8];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetRight(Memorial);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[5]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[11]);

	// CENTER ROW 2 -------------------------------------------------------

	// Center left 9
	FacilityOverlay = FacilityOverlays[9];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[6]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[12]);

	// Center middle 10
	FacilityOverlay = FacilityOverlays[10];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[9]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[11]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[7]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[13]);

	// Center right 11
	FacilityOverlay = FacilityOverlays[11];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[10]);
	FacilityOverlay.Navigator.AddNavTargetRight(Engineering);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[8]);
	FacilityOverlay.Navigator.AddNavTargetDown(FacilityOverlays[14]);

	// BOTTOM ROW 3 -------------------------------------------------------

	// Bottom left 12
	FacilityOverlay = FacilityOverlays[12];
	FacilityOverlay.Navigator.AddNavTargetLeft(PowerCore);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[9]);
	//FacilityOverlay.Navigator.AddNavTargetDown(None);

	// Bottom middle 12
	FacilityOverlay = FacilityOverlays[13];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[12]);
	FacilityOverlay.Navigator.AddNavTargetRight(FacilityOverlays[14]);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[10]);
	//FacilityOverlay.Navigator.AddNavTargetDown(None);

	// Bottom right 14
	FacilityOverlay = FacilityOverlays[14];
	FacilityOverlay.Navigator.AddNavTargetLeft(FacilityOverlays[13]);
	FacilityOverlay.Navigator.AddNavTargetRight(Engineering);
	FacilityOverlay.Navigator.AddNavTargetUp(FacilityOverlays[11]);
	//FacilityOverlay.Navigator.AddNavTargetDown(None);

	// Initialize for keyboard navigation 
	Navigator.SetSelected(CIC);
}

simulated function UIFacilityGrid_FacilityOverlay GetOverlayForRoom( StateObjectReference RoomRef )
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	foreach FacilityOverlays(FacilityOverlay)
	{
		if( FacilityOverlay.RoomRef == RoomRef )
			return FacilityOverlay;
	}
	return none; 
}
simulated function ClickPauseButton()
{
	`HQPRES.UIPauseMenu(); 
}
simulated function RefreshButtonHelp()
{
	local UINavigationhelp NavHelp;
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.AddGeoscapeButton();

	//NavHelp.AddLeftHelp(MenuPause,,ClickPauseButton);
	/*if( bForceShowGrid ) 
		NavHelp.AddLeftHelp(MenuGridOn,,ToggleGrid);
	else
		NavHelp.AddLeftHelp(MenuGridOff,,ToggleGrid);*/
}
//xcom2/main/XCOM2/XComGame/Mods/AnnounceDemo/Classes/UIAnnounceDemoShell.uc
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	
	XComHeadquartersController(`HQPRES.Owner).SetInputState('HQ_FreeMovement');
	Movie.Pres.SubscribeToUIUpdate(UpdateOverlayPositions);
	UpdateOverlayPositions();
	UpdateData();

	if( bForceShowGrid ) 
		ActivateGrid(); 

	RefreshButtonHelp();

	if(`HQPRES.GetCamera().PreviousRoom != 'Base')
	{
		Hide();
		if(bInstantInterp)
		{
			`HQPRES.GetCamera().StartRoomViewNamed('Base', 0);
			CameraTravelFinished();
			bInstantInterp = false;
		}
		else
		{
			`HQPRES.GetCamera().StartRoomViewNamed('Base', `HQINTERPTIME);
			// Show the UI right before the camera transition is over
			SetTimer(`HQINTERPTIME, false, 'CameraTravelFinished');
		}
	}
}

// allows us to only show the UI once the camera finishes moving back to base view. Otherwise all of the 2D UI
// floats around strangely
simulated function CameraTravelFinished()
{
	//CALLING UP, to skip the timer check.
	super.Show();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.HideEventQueue();
	XComHeadquartersController(`HQPRES.Owner).SetInputState('None');
	Movie.Pres.UnsubscribeToUIUpdate(UpdateOverlayPositions);
	Movie.Pres.m_kTooltipMgr.HideTooltipsByPartialPath(string(MCPath));
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	//This clear is helpful for hotlinking around the base. We clear all tooltips, in case something is 
	//dangling once a hotlink activates. 
	Movie.Pres.m_kTooltipMgr.HideAllTooltips();

	// if we lose focus again before the camera finishes transitioning to the screen, we could trip this timer
	// and show ourself even though we shouldn't. So clear any extant timers just in case. 
	ClearTimer('CameraTravelFinished');
}

simulated function OnRemoved()
{
	Movie.Pres.UnsubscribeToUIUpdate(UpdateOverlayPositions);
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(MCPath));
	super.OnRemoved();
}


simulated function SetBorderSize(float NewWidth, float NewHeight)
{
	MC.BeginFunctionOp("setBorderSize");
	MC.QueueNumber(NewWidth);
	MC.QueueNumber(NewHeight);
	MC.EndOp();
}

simulated function SetBorderLabel(string Label)
{
	MC.FunctionString("setLabel", Label);
}

simulated function ActivateGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	bForceShowGrid = true;

	foreach FacilityOverlays(FacilityOverlay)
	{
		if( FacilityOverlay.GetRoom() != none )
		{
			FacilityOverlay.OnShowGrid();
		}
	}

	MC.FunctionVoid("showBorder");
	bProcessMouseEventsIfNotFocused = true;

	//The grid may be requested to activate beneath another screen. 
	if( !bIsFocused )
		Movie.Pres.SubscribeToUIUpdate(UpdateOverlayPositions);
}

simulated function DeactivateGrid()
{
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;

	bForceShowGrid = false;

	foreach FacilityOverlays(FacilityOverlay)
	{
		if(!FacilityOverlay.bIsFocused)
			FacilityOverlay.OnHideGrid();
	}

	MC.FunctionVoid("hideBorder");
	bProcessMouseEventsIfNotFocused = false;

	//The grid may be requested to deactivate beneath another screen. 
	if( !bIsFocused )
		Movie.Pres.UnsubscribeToUIUpdate(UpdateOverlayPositions);
}

public function ToggleGrid()
{
	if( bForceShowGrid )
		DeactivateGrid();
	else
		ActivateGrid();
	RefreshButtonHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Ensure we're at the top of the input stack - navigation commands should only be processed on top screen
	if ( Movie.Stack.GetCurrentScreen() != self )
		return false;

	bHandled = true;

	switch( cmd )
	{
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function int SortCorners( vector vA, vector vB )
{
	if( vB.X > vA.X ) return -1; 
	return 0; 
}

defaultproperties
{
	Package = "/ package/gfxFacilityGrid/FacilityGrid";
	bProcessMouseEventsIfNotFocused = false;
	bAutoSelectFirstNavigable = false;
	bIsNavigable = false;
}