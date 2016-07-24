//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMouseCursor.uc
//  AUTHOR:  Brit Steiner  8/26/10
//  PURPOSE: Handles the movieclip display of the mouse cursor 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMouseCursor extends UIScreen
	implements(X2VisualizationMgrObserverInterface);

var Vector2D m_v2MouseLoc;
var Vector2D m_v2MouseFrameDelta;
var bool bIsInDefaultLocation; // captuire once the mouse relcoated 

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	if( Movie.bIsVisible )
		ShowMouseCursor();
	else
		 HideMouseCursor();
	
	if( Movie.IsMouseActive() )
		Movie.Pres.Get2DMovie().SetbHitTestDisabled(false);
	else
		Movie.Pres.Get2DMovie().SetbHitTestDisabled(true);

	Movie.InsertHighestDepthScreen(self);

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(Movie, 'IsMouseActive', self, MouseStateChanged);
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	super.OnInit();	
	MouseStateChanged();
	SetTimer(0.1f, true, 'UpdateMouseLocation', self);
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState);
event OnVisualizationIdle();
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	ShowMouseCursor();
}

//----------------------------------------------------------------------------
//	Poll for the direct variable access of the mouse location in the GFx movie. 
//
simulated function UpdateMouseLocation()
{
	local ASValue myValue;
	local Vector2D v2PreviousMouseLoc;

	v2PreviousMouseLoc = m_v2MouseLoc;

	myValue = Movie.GetVariable("_root._xmouse");
	m_v2MouseLoc.X = myValue.n;

	myValue = Movie.GetVariable("_root._ymouse");
	m_v2MouseLoc.Y = myValue.n;

	m_v2MouseFrameDelta = m_v2MouseLoc - v2PreviousMouseLoc;

	if( bIsInDefaultLocation && (m_v2MouseLoc.X > 0.0f || m_v2MouseLoc.Y > 0.0f) )
	{
		bIsInDefaultLocation = false;
	}

	if(V2DSize(m_v2MouseFrameDelta) > 0.0f)
	{
		ShowMouseCursor();
	}

	//`log("Mouse reporting from flash: (" $m_v2MouseLoc.X $", " $m_v2MouseLoc.Y $") at poll rate",,'uixcom');
}

simulated function MouseStateChanged()
{

	// No need to process any mouse activity on the consoles. 
	if( WorldInfo.IsConsoleBuild( CONSOLE_PS3 )  || WorldInfo.IsConsoleBuild( CONSOLE_Xbox360 ) )
	{
		`log("Warning: MouseStateChange has been triggered, but we're running on a console, where mouse isn't processed.");
		return;
	}

	if( Movie.IsMouseActive() )
	{
		if( !bIsInited )
		{
			Movie.LoadScreen( self );
		}
	}
}

simulated function ZoomMouseCursor( bool zooming = false )
{
    local LocalPlayer LP;

	LP = LocalPlayer(GetALocalPlayerController().Player);

	if( LP != None )
	{
		if(zooming)
		{
			//Invoke("ActivateZoomCursor");
			LP.ViewportClient.GameCursorType = GCT_XComZooming;
		}
		else
		{
			//Invoke("RestoreNormalCursor");
			LP.ViewportClient.GameCursorType = GCT_XComDefault;
		}
	}
}

// This function is now pointless since we are using the OS cursor
simulated function Show()
{
	if( Movie.IsMouseActive() && (`XPROFILESETTINGS == none ? true : `XPROFILESETTINGS.Data.IsMouseActive()) )
	{
		// Don't actually show the movie
		//super.Show();
		ShowMouseCursor();
	}
}

simulated function ShowMouseCursor()
{
	local LocalPlayer LP;

	LP = LocalPlayer(GetALocalPlayerController().Player);

	// Don't show the mouse cursor if the interface Movie is still hidden
	if( LP != None && Movie.bIsVisible )
	{
		LP.ViewportClient.bHideMouseCursorForCinematics = false;
	}
	Movie.Pres.Get2DMovie().SetbHitTestDisabled(false);
}

simulated function Hide()
{
	HideMouseCursor();
}

simulated function HideMouseCursor()
{
	local LocalPlayer LP;

	LP = LocalPlayer(GetALocalPlayerController().Player);

	// Don't show the mouse cursor if the interface Movie is still hidden
	if( LP != None )
	{
		LP.ViewportClient.bHideMouseCursorForCinematics = true;
	}
	Movie.Pres.Get2DMovie().SetbHitTestDisabled(true);
}

// Mouse cursor will always want to trigger on cinematic changes. 
simulated function HideForCinematics()
{
	Hide();
}

simulated function ShowForCinematics()
{
	// Latest request is that mouse cursor be hidden during cinematics so we no longer want to call this show - Joe C
	//Show();
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

DefaultProperties
{
	MCName = "theMouseCursorContainer";
	Package = "/ package/gfxMouseCursor/MouseCursor";

	InputState= eInputState_None;
	bIsInDefaultLocation = true;

	bIsVisible = false;
	bHideOnLoseFocus = false;
}
