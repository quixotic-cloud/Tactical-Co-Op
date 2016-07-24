//----------------------------------------------------------------------------
//  Copyright 2008-2011, Firaxis Games
//
//  Manager for all Flash SWF/GFx streams in game.
//  On the Flash side is the cooresponding InterfaceMgr class.
//
//  What funnels through this:
//      SWF and/or GFx loading and unloading
//      Input
//      Signaling to Flash via Invoke()
//

class UIMovie extends GFxMoviePlayer
	native(UI);

//----------------------------------------------------------------------------
// MEMBERS
//
var XComPresentationlayerBase Pres;

var name MCPath;

var bool bIsInited;
var bool bIsVisible;

var bool MouseActive;

var int UI_RES_X;
var int UI_RES_Y;
var Vector2D m_v2ScaledOrigin;
var Vector2D m_v2ScaledDimension;
var Vector2D m_v2ScaledFullscreenDimension;
var Vector2D m_v2FullscreenDimension;
var Vector2D m_v2ViewportDimension;
var bool IsFullScreenView;

var UIScreenStack Stack;
var array<UIScreen> Screens;	            // loaded Screens
var array<UIScreen> HighestDepthScreens;	// used for depth sorting on the flash side
var array<ASValue> CommandQueue;	        // UIPanel: global array of commands to batch to ActionScript every frame
var array<ASValue> BatchedFunctions;	    // cached functions to call on the InterfaceMgr class
var array<bool> CachedPanels;	            // Cache of UI Actors synchronized with 'arrCachedMovieClips' in Environment.as (TRUE entries are in use, FALSE entries are free)
var array<int> RemovalCache;	            // Array of indices into the CachedPanels that need to be nulled out when commands are processed
var int NumModalScreens;			        // Used to determine if a model Screens are up

var EConsoleType ConsoleType;

// DEBUG: 
var bool DebugHardHide;						 // Debug: Hide UI despite other show/hide commands;
var bool ShowingDebugAnchorFrame;			 // Debug: Show anchoring frame's current position

var array<name> PanelsPendingRemoval;	    // Panels that haven't yet been initialized, but have already been removed

 /* 
 * Add commands to CommandQueue
 */
simulated native function QueueCommands( array<ASValue> arrData );

 /* 
 * Add a control to the cached MC array, should mirror the cached array in Environment.as -sbatista 
 */
 simulated native function int CachePanel(UIPanel Panel);

//----------------------------------------------------------------------------
// Pseudo CONSTRUCTOR
// ** Can NOT use regular Init(), because GFx forces it to have different parameters that we can't override. 
simulated function InitMovie(XComPresentationlayerBase InitPres)
{
	Pres = InitPres;
	Stack = InitPres.ScreenStack;

	//---------------------------------------------

	if ( Pres.WorldInfo.IsConsoleBuild( CONSOLE_PS3 ) )
		ConsoleType = CONSOLE_PS3;
	else if ( Pres.WorldInfo.IsConsoleBuild( CONSOLE_Xbox360 ) )
		ConsoleType = CONSOLE_Xbox360;
	else
		ConsoleType = CONSOLE_Any;

	//---------------------------------------------

	RenderTextureMode = RTM_AlphaComposite;

	// Kick of Flash loading
	Start();
}

//----------------------------------------------------------------------------
//  CALLBACK from Flash
//  Occurs when Flash sends an "OnInit" fscommand. 
//
simulated function OnInit()
{
	bIsInited = true;
	
	if( bIsVisible )
	{
		`log("FxsMovie OnInit() SHOW",,'uixcom');
		Show();
	}
	else
	{
		`log("FxsMovie OnInit() HIDE",,'uixcom');
		Hide();
	}

	// Necessary so animations continue to play at full speed when "slomo" is activated
	// for bullet-time in the game.
	SetTimingMode( TM_REAL );

	SetResolutionAndSafeArea();
	
	IsFullScreenView = class'Engine'.static.GetEngine().GameViewport.IsFullScreenViewport(); 

	SetDoubleClickMouseSpeed();
	UpdateLanguage();

	// Init mouse
	SetMouseActive( `XPROFILESETTINGS == none ? true : `XPROFILESETTINGS.Data.IsMouseActive() );

	Pres.SubscribeToUIUpdate( ProcessQueuedCommands );
	Pres.SubscribeToUIUpdate( WatchForFullscreenChanges );
}

event Destroyed()
{
	Pres.UnsubscribeToUIUpdate( ProcessQueuedCommands );
	Pres.UnsubscribeToUIUpdate( WatchForFullscreenChanges );
	`log("UIMovie.Destroyed(), self:" $ String(self),,'uicore');
}

// Convert from Flash UI space to game UV coordinates
simulated function ConvertUIToUVCoords( out Vector2D kVector )
{
	local Vector2D AspectCorrectDimension;

	if( m_v2FullscreenDimension.X / m_v2FullscreenDimension.Y > 1.777 )
	{
		AspectCorrectDimension.X = m_v2FullscreenDimension.Y * 1.7777;
		AspectCorrectDimension.Y = m_v2FullscreenDimension.Y;
	}
	else
	{
		AspectCorrectDimension.X = m_v2FullscreenDimension.X;
		AspectCorrectDimension.Y = m_v2FullscreenDimension.X * 0.5625;
	}

	kVector.X = ((kVector.X * AspectCorrectDimension.X) - ((AspectCorrectDimension.X - m_v2ViewportDimension.X) * 0.5f)) / m_v2ViewportDimension.X;
	kVector.Y = ((kVector.Y * AspectCorrectDimension.Y) - ((AspectCorrectDimension.Y - m_v2ViewportDimension.Y) * 0.5f)) / m_v2ViewportDimension.Y;
}

simulated function GetGammaLogoDimensions( out Vector2D TopLeft, out Vector2D Extent )
{
	local Vector2D ConstTopLeft;
	local Vector2D BottomRight;
	
	//Top left anchor point ---------------
	//Location is based on the default resolution 1280x720 and origin at (0,0).
	ConstTopLeft.X = 0.63203f;//809;
	ConstTopLeft.Y = 0.38194f;//275;
	
	TopLeft = ConstTopLeft; 
	ConvertUIToUVCoords(TopLeft); 

	//Extent of the images ---------------

	BottomRight.X = ConstTopLeft.X + 0.14921f;
	BottomRight.Y = ConstTopLeft.Y + 0.29861f;
	ConvertUIToUVCoords(BottomRight);

	Extent.X = BottomRight.X - TopLeft.X;
	Extent.Y = BottomRight.Y - TopLeft.Y;
}

simulated native function GetScreenDimensions( out int RenderedWidth, out int RenderedHeight, out float RenderedAspectRatio, 
											   out int FullWidth,     out int FullHeight,     out float FullAspectRatio, 
											   out int AlreadyAdjustedVerticalSafeZone ) const; 

simulated event RefreshResolutionAndSafeArea()
{
	SetResolutionAndSafeArea();
}

// The order of creating the parameters to send to flash is awkward, because the latter params were added late, 
// and many flash elements depend on the order of the parameters for testing, so I opted to add the new params 
// and keep the awkwardness here, so that all flash testing could stay neat. -bsteiner 6/9/2012
simulated function SetResolutionAndSafeArea()
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int RenderedWidth, RenderedHeight, FullWidth, FullHeight; 
	local float RenderedAspectRatio, GfxAspectRatio, FullAspectRatio; 
	local int AlreadyAdjustedVerticalSafeZone; 
	local bool bIsFullscreen;

	myValue.Type = AS_Number;

	GetScreenDimensions(RenderedWidth, RenderedHeight, RenderedAspectRatio, FullWidth, FullHeight, FullAspectRatio, AlreadyAdjustedVerticalSafeZone);

	bIsFullscreen = class'Engine'.static.GetEngine().GameViewport.IsFullScreenViewport(); 

	if( m_v2FullscreenDimension.X == FullWidth &&
		m_v2FullscreenDimension.Y == FullHeight &&
		m_v2ViewportDimension.X == RenderedWidth &&
		m_v2ViewportDimension.Y == RenderedHeight && 
		IsFullScreenView == bIsFullscreen )
	{
		return;
	}

	m_v2FullscreenDimension.X = FullWidth;
	m_v2FullscreenDimension.Y = FullHeight;

	m_v2ViewportDimension.X = RenderedWidth;
	m_v2ViewportDimension.Y = RenderedHeight;

	IsFullScreenView = bIsFullscreen;

	GfxAspectRatio = float(UI_RES_Y) / float(UI_RES_X); 
	
	if( RenderedAspectRatio == GfxAspectRatio ) 
	{
		myValue.n = UI_RES_X;
		myArray.AddItem( myValue );
		myValue.n = UI_RES_Y;
		myArray.AddItem( myValue );

		m_v2ScaledDimension.X = UI_RES_X; 
		m_v2ScaledDimension.Y = UI_RES_Y;
	}
	else if( RenderedAspectRatio > GfxAspectRatio ) //taller than default 
	{
		myValue.n = UI_RES_X;
		myArray.AddItem( myValue );
		m_v2ScaledDimension.X = myValue.n; 

		myValue.n = UI_RES_X * RenderedAspectRatio; //MULTIPLY 
		myArray.AddItem( myValue );
		m_v2ScaledDimension.Y = myValue.n;
	}
	else if( RenderedAspectRatio < GfxAspectRatio ) //wider than default 
	{
		myValue.n = UI_RES_Y / RenderedAspectRatio; //DIVIDE 
		myArray.AddItem( myValue );
		m_v2ScaledDimension.X = myValue.n; 


		myValue.n = UI_RES_Y; 
		myArray.AddItem( myValue );
		m_v2ScaledDimension.Y = myValue.n; 

	}
	m_v2ScaledFullscreenDimension.X = (UI_RES_X * FullWidth) / RenderedWidth;
	m_v2ScaledFullscreenDimension.Y = (UI_RES_Y * FullHeight) / RenderedHeight;

	// Safe area - 
	// * This is the important part, for flash to calculate the actual anchoring placements. 
	// 4/12/2016 bsteiner - removing old console safe frame values that no longer apply to ps4 / xboxone 
	myValue.n = 0.0;  // no safe area
	myArray.AddItem( myValue );

	if( RenderedAspectRatio == GfxAspectRatio || bool(AlreadyAdjustedVerticalSafeZone) ) 
	{
		myValue.n = 0;
		myArray.AddItem( myValue );
		m_v2ScaledOrigin.X = myValue.n; 
		myValue.n = 0;
		myArray.AddItem( myValue );
		m_v2ScaledOrigin.Y = myValue.n; 
	}
	else if( RenderedAspectRatio > GfxAspectRatio ) //taller than normal 
	{
		myValue.n = 0;
		myArray.AddItem( myValue );
		m_v2ScaledOrigin.X = myValue.n; 

		myValue.n = 0 - (0.5 * (m_v2ScaledDimension.Y - UI_RES_Y));
		myArray.AddItem( myValue );
		m_v2ScaledOrigin.Y = myValue.n; 
	}
	else if( RenderedAspectRatio < GfxAspectRatio ) //wider than normal 
	{
		myValue.n = 0 - (0.5 * (m_v2ScaledDimension.X - UI_RES_X));
		myArray.AddItem( myValue );
		m_v2ScaledOrigin.X = myValue.n; 

		myValue.n = 0; 
		myArray.AddItem( myValue );
		m_v2ScaledOrigin.Y = myValue.n; 
	}
	
	//Set console type directly 
	if( ConsoleType == CONSOLE_PS3 )
		myValue.n = 2;	
	else if( ConsoleType == CONSOLE_Xbox360 )
		myValue.n = 1;
	else
		myValue.n = 0;	

	myArray.AddItem( myValue );

	// Does the vertical location alreday have the safe zone accoutned for? 
	myValue.Type = AS_Boolean;
	myValue.b = bool(AlreadyAdjustedVerticalSafeZone);	
	myArray.AddItem( myValue );

	`log( "SetResolutionAndSafeArea: " ,,'uixcom');
	`log( "REZ_X:   "$ myArray[0].n,,'uixcom');
	`log( "REZ_Y:   "$ myArray[1].n ,,'uixcom');
	`log( "Percent: "$ myArray[2].n ,,'uixcom');
	`log( "X_LOC:   "$ myArray[3].n ,,'uixcom');
	`log( "Y_LOC:   "$ myArray[4].n ,,'uixcom');
	`log( "PLATFORM:"$ myArray[5].n ,,'uixcom');
	`log( "bAlreadyAdjustedVerticalSafeZone: " $AlreadyAdjustedVerticalSafeZone,,'uixcom');

	Invoke(MCPath $ ".SetUIView", myArray);
}

simulated function WatchForFullscreenChanges()
{
	if( IsFullScreenView == class'Engine'.static.GetEngine().GameViewport.IsFullScreenViewport())
		return;

	SetResolutionAndSafeArea();
}

simulated function GetScaledMouseRect( out Vector2D topLeft, out Vector2D bottomRight )
{
	topLeft = m_v2ScaledOrigin;
	bottomRight.X = m_v2ScaledDimension.X - Abs(m_v2ScaledOrigin.X);  //is there a better way to do this? Ugh. 
	bottomRight.Y = m_v2ScaledDimension.Y - Abs(m_v2ScaledOrigin.Y); 
}


simulated function SetDoubleClickMouseSpeed()
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	myValue.Type = AS_Number;
	myValue.n = class'UIUtilities_Input'.const.MOUSE_DOUBLE_CLICK_SPEED;
	myArray.AddItem( myValue );

	Invoke(MCPath $ ".SetDoubleClickSpeed", myArray);
}

simulated function string GetPathUnderMouse()
{
	return ActionscriptString(MCPath $ ".GetPathUnderMouse");
}

simulated function ClickPathUnderMouse( optional bool bDebugLogs = false)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Boolean;
	myValue.b = bDebugLogs;	
	myArray.AddItem( myValue );

	Invoke(MCPath $ ".ClickPathUnderMouse", myArray);
}

//Toggles the gfx extension in flash for disabling hittesting. 
simulated function SetbHitTestDisabled( bool bShouldDisable )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Boolean;
	myValue.b = bShouldDisable;
	myArray.AddItem( myValue );
	Invoke(MCPath $ ".SetHitTestDisable", myArray);	
}

simulated function bool OnUnrealCommand( int iInput,  optional int ActionMask = class'UIUtilities_Input'.const.FXS_ACTION_PRESS )
{
	`log("INPUT PROBLEM!!! Somethign is calling UIMovie.OnUnrealCommand() which is now deprecated.",,'uixcom');
	return false; 
}

//----------------------------------------------------------------------------

/**
	IMPORTANT:
	Each dynamic Screen's UC class needs to have a specific class type specifier.
	Attempting to generate a class type dynamically may work on the PC but will
	fail on the consoles due to how Unreal cooks its assets.

Jerad Heck from Psyonix explains the issue:

"The main reason this way of doing things is "bad" is because if the
classes reside in a non-native package, without a direct reference, the classes
will not be cooked in to the packages which need them in order to work on
consoles, so the reference wont exist at all, and wont be able to be found in
order to spawn, and the whole thing will just come apart at that point.

"In general, I would say not to use this method to instantiate objects, as it
will almost inevitably lead to either console runtime problems (the class cant
be found), or memory problems on consoles (because you dont have a non-native
package, and everything is always loaded)."

[...]

"On PC, this will load whatever package is specified, and find the instance of
whatever was given, and return it.  On console, however, this simply tries to
find the object in memory, and if its not already there, returns None.  if this
happens, it is a problem with the class or object not being referenced at
	cook time."
*/
simulated function LoadScreen( UIScreen Screen )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	if( !bIsInited )
	{
		`warn("Attempt to load Screen '" $ Screen.MCPath $ "' before InterfaceMgr was done loading.");
		return;
	}

	`log("LoadScreen(): " $ Screen @ Screen.Package,,'uicore');
	
	myValue.Type = AS_String;

	// Unique ID
	myValue.s = string(Screen.Name);
	myArray.AddItem(myValue);

	// Instance Name
	myValue.s = string(Screen.MCName);
	myArray.AddItem(myValue);

	// Path to SWF (optional)
	// Empty Package indicates the loading of an "EmptyScreen" - sbatista 12/9/2013
	myValue.s = (Screen.Package != class'UIScreen'.default.Package) ? string(Screen.Package) : "";
	myArray.AddItem(myValue);

	// Library identifier for the screen (in case multiple screens exist in the same SWF, optional)
	// Specifying a LibID instructs flash to ignore what's on the stage and spawn a new Screen MC of the specified type
	myValue.s = Screen.LibID != class'UIScreen'.default.LibID ? string(Screen.LibID) : "";
	myArray.AddItem(myValue);

	// CacheIndex
	myValue.Type = AS_Number;
	myValue.n = float(Screen.MC.CacheIndex);
	myArray.AddItem(myValue);

	Invoke(MCPath $ ".LoadScreen", myArray);

	// Store reference to Screen, pushed to the beginning of the array
	Screens.InsertItem(0, Screen);

	if( Screen.ConsumesInput() )
	{  
		if(NumModalScreens <= 0)
		{
			XComPlayerController(Pres.Owner).SetModalMode(true);
		}
		NumModalScreens++;
	}
}

// Dynamically spawn a Control based on a library identifier - returns a unique index that is used during batching process
simulated function LoadPanel( string parentPath, string InitName, string libraryID, int cacheIndex )
{
	ActionScriptVoid(MCPath $ ".LoadPanel");
}

simulated function RemoveCachedPanel(int CacheIndex)
{
	// In order to keep the Flash and Unreal cache synced up, we can't zero out the entry of the Panel from the cache in Unreal
	// until Flash processes queued up commands (done in ProcessQueuedCommands) - sbatista
	RemovalCache.AddItem(CacheIndex);
}

simulated function RemoveScreen( UIScreen Screen )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( Screen != none )
	{
		if ( Screen.ConsumesInput() && NumModalScreens > 0 )
		{
			NumModalScreens--;
			if(NumModalScreens <= 0)
			{
				XComPlayerController(Pres.Owner).SetModalMode(false);
			}
		}

		// If Screen is not initialized, and remove is being called,
		// then it's likely to be in the process of being created; removing
		// would orphan it from the Unreal and leave the Flash running uncontrolled.
		if ( !Screen.bIsInited && !Screen.bIsPendingRemoval)
		{
			// Assume the remove will be tracked by the Screen and when OnInit
			// is sent to it, instead it will properly remove itself.
			`warn("Attempt to remove an uninitialized Screen '" $ Screen.MCPath $ "' from UIMovie.", , 'uicore');
			Screen.MarkForDelayedRemove();
		}
		else if( !Screen.bIsRemoved )
		{
			`log("Removing Screen '" $ Screen.MCPath $ "'.",,'uicore');
			Screen.Remove();
			Screen.SignalOnRemoved();
			Screens.RemoveItem(Screen);
			RemoveHighestDepthScreen(Screen);

			myValue.Type = AS_String;
			myValue.s = string(Screen.Name); // Unique ID
			myArray.AddItem(myValue);
			myValue.Type = AS_Boolean;
			myValue.b = Screen.bAnimateOut; // Screen animation is disabled since screens are now UIControls, and those are already animated by default
			myArray.AddItem(myValue);
			Invoke(MCPath $ ".RemoveScreen", myArray);	
		}
	}
}

simulated function bool HasScreen(UIScreen Screen)
{
	local UIScreen TmpScreen;
	foreach Screens(TmpScreen)
	{
		if(TmpScreen == Screen)
			return true;
	}
	return false; 
}

simulated function InsertHighestDepthScreen(UIScreen Screen)
{
	HighestDepthScreens.AddItem(Screen);
	UpdateHighestDepthScreens();
}

simulated function RemoveHighestDepthScreen(UIScreen Screen)
{
	if(HighestDepthScreens.Find(Screen) != INDEX_NONE)
	{
		HighestDepthScreens.RemoveItem(Screen);
		UpdateHighestDepthScreens();
	}
}

// DEBUG: Display an ordered stack of how input is sent to Screens.
simulated function PrintScreenStack()
{
	Stack.PrintScreenStack();
}

// Stop UI Screens system from handling all input!
simulated function RaiseInputGate()
{
	Stack.IsInputBlocked = true;
}

simulated function LowerInputGate()
{ 
	Stack.IsInputBlocked = false;
}

//----------------------------------------------------------------------------

// Turn on entire User Interface
// Must be called to show the movie initiall, since this is hidden on the flash side by default. 
simulated function Show()
{
	local array<ASValue> myArray;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if ( DebugHardHide)
		return;

	bIsVisible = true;

	if(bIsInited)
	{
		myArray.Length = 0;
		Invoke(MCPath $ ".Show", myArray);	
	}
}

// Turn off entire User Interface
simulated function Hide()
{
	local array<ASValue> myArray;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if ( DebugHardHide )
		return;

	bIsVisible = false;

	if(bIsInited)
	{
		myArray.Length = 0;
		Invoke(MCPath $ ".Hide", myArray);	
	}
}

simulated function Vector2D GetScreenResolution()
{
	local Vector2D res;
	local ScriptSceneView SceneView;

	// grab our sceneview interface
	SceneView = XComLocalPlayer(XComPlayerController(Pres.Owner).Player).SceneView;

	res = SceneView.GetSceneResolution();

	return res;
}

/// <summary>
/// Gets the raw size of the UI Resolution (into which GFX can draw). Usually 1980x1080. Note that for output devices with a non-16x9
/// resolution, the UI will not cover the entire screen and therefore there may be points on the screen that lie outside the UI area.
/// </summary>
simulated native function Vector2D GetUIResolution() const;

simulated function Vector2D ConvertNormalizedScreenVectorToUICoords(Vector2D NormalizedVector, optional bool bClampToScreenEdges=true, optional float Padding=0.0f)
{
	return ConvertNormalizedScreenCoordsToUICoords(NormalizedVector.x, NormalizedVector.y, bClampToScreenEdges);
}

/// <summary>
/// Gets the 2D GFX UI coordinate that corresponds to the given normalized screen coordinate. A normalized screen coordinate
/// in the range 0.0f-1.0f, where 0.0 is the top/left of the screen, and 1.0 is the bottom/right
/// </summary>
simulated native function Vector2D ConvertNormalizedScreenCoordsToUICoords(float x, float y, optional bool bClampToScreenEdges=true, optional float Padding=0.0f) const;

simulated function Vector2D ConvertUVToUICoords( Vector2D kInVector )
{
	local Vector2D kResultVector;

	// Obtain actual width / height values for the Screen since GFx can scale up / down movie clips to improve visual quality. - sbatista 4/27/12
	kResultVector.X = kInVector.X * RenderTexture.SizeX;
	kResultVector.Y = kInVector.Y * RenderTexture.SizeY;
	
	return kResultVector;
}

// ------------------------------------------------------------------------------
// END NOTICE
// ------------------------------------------------------------------------------

simulated function bool HasModalScreens()
{
	return NumModalScreens > 0;
}


// DEBUG
// Show anchor points around the Screen.
simulated function ToggleAnchors()
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	ShowingDebugAnchorFrame = !ShowingDebugAnchorFrame;

	myValue.Type = AS_Boolean;
	myValue.b = ShowingDebugAnchorFrame;
	myArray.AddItem( myValue );

	Invoke(MCPath $ ".DebugDisplayAnchorFrame", myArray);
}


// DEBUG
// Hide the userinterface and keep it off despite any show/hide commands
// (Request from Greg so game screenshots can be taken without UI coming on after cinematics.)
simulated function ToggleHardHide(bool bHide)
{
	local ASValue myValue;	

	myValue.Type = AS_Boolean;
	myValue.b = DebugHardHide;
	
	SetVariable( MCPath $ "._visible", myValue );

	DebugHardHide = bHide;
}

//----------------------------------------------------------------------------
// Prints out all proto Screens, and then all regular Screens 
simulated function PrintCurrentScreens()
{
`if (`notdefined(FINAL_RELEASE))
	local int i;
	local int len;
	local int total3d;
	local int total2d;
	local UIScreen Screen;

	len = Screens.Length;

	`log("---- UIMovie.PrintCurrentScreens() -----------------------",, 'uicore');

	for( i = 0; i < len; i++)
	{
		Screen = Screens[i];

		if ( Screen.bIsIn3D )
		{
			`log("     " $ i $ "    3D: " @Screen.class @ Screen.name,, 'uicore');
			total3d++;
		}
		else
		{
			`log("     " $ i $ "   std: " @Screen.class @ Screen.name,, 'uicore');
			total2d++;
		}
	}
	
	`log("-----",, 'uicore');
	`log("TOTAL: " $ len $ "   3D: " $ total3d $ "   2D: " $ total2d,, 'uicore');
	`log("---------------------------------------------------------------",,'uicore');
`endif
}

simulated function FlashRaiseBatchedInit( string paths )
{
	local int i;
	local array<string> arrPaths;

	arrPaths = SplitString(paths);

	// we must traverse the array in reverse, because in Flash, items are loaded from bottom to top (child to parent),
	// but UIControls must initialize from top to bottom, since parents must process their commands before their children -sbatista
	for(i = arrPaths.Length - 1; i > INDEX_NONE; --i)
	{
		FlashRaiseInit(arrPaths[i]);
	}
}

//----------------------------------------------------------------------------
//  CALLBACK directly from Flash
// 
//  When a Control is done loading and it's onLoad() is raised in Flash, it will
//  call back to this function via ExternalInterface.call().
//
//  path, Path to the Control to be initialized.  (Screens are panels).
//
//  EXAMPLE: arg = "_level0.theInterfaceMgr.gfxProtoMissionFoo.bar"
//
simulated function FlashRaiseInit(string InitPath)
{
	local name Path;
	local UIScreen Screen;
	local UIPanel Control;

	Path = name(InitPath);

	// Initialize the Movie
	if( MCPath == Path && !bIsInited )
	{
		OnInit();
		return;
	}

	foreach Screens(Screen)
	{
		if( InStr(Path, Screen.MCPath) == -1 )
			continue; 

		foreach Screen.ChildPanels( Control )
		{
			if (Path == Control.MCPath)
			{
				if ( Control.bIsInited )
					`log("Control '" $ Control.MCPath $ "' already initialized; was old instance not removed?",,'uicore');
				else
				{
					Control.OnInit();
					if(Control == Screen)
						Screen.SignalOnInit();
				}

				`log("FlashRaiseInit: " $ InitPath $ "",,'uicore');
				return;
			}
		}
	}

	if(PanelsPendingRemoval.Find(Path) == INDEX_NONE)
	{
		// Panels are hidden by default in Flash until UIPanel.OnInit() is called.
		// If we don't have a batching controller, force it to show.
		`log("FlashRaiseInit: '" $ InitPath $ "' wasn't handled, calling Show()",,'uicore');
		ShowUninitializedMC(InitPath);
	}
	else
	{
		// Panels that were removed before their OnInit call was triggered need to be removed post init
		`log("FlashRaiseInit: '" $ InitPath $ "' was already removed, cleaning up flash MC",,'uicore');
		RemoveUninitializedMC(InitPath);
	}
}

// OPT: Queue the Show function to be called when this movie ticks.
simulated function ShowUninitializedMC(string Path)
{
	local ASValue ASVal;
	ASVal.Type = AS_String;
	ASVal.s = Path;
	BatchedFunctions.AddItem(ASVal);
	ASVal.s = "ShowPostInit";
	BatchedFunctions.AddItem(ASVal);
	ASVal.Type = AS_Null;
	BatchedFunctions.AddItem(ASVal);
}

// OPT: Queue the remove function to be called when this movie ticks.
simulated function RemoveUninitializedMC(string Path)
{
	local ASValue ASVal;
	ASVal.Type = AS_String;
	ASVal.s = Path;
	BatchedFunctions.AddItem(ASVal);
	ASVal.s = "remove";
	BatchedFunctions.AddItem(ASVal);
	ASVal.Type = AS_Null;
	BatchedFunctions.AddItem(ASVal);
}

// CALLBACK directly from Flash
// Occurs for a non-initialization event
//  path,       Path to Control which handles event
//  cmd,    Command to send to pannel
//  arg,  (optional) parameter to pass along.
simulated function FlashRaiseCommand( string strPath, string cmd, string arg )
{
	local name Path;
	local UIScreen Screen;
	local UIPanel Control;

	Path = name(strPath);

	`log("Flash raise command: " $ path $ ", " $ cmd $ ", " $ arg,, 'uicore');
	foreach Screens( Screen )
	{
		if( InStr(Path, Screen.MCPath) == -1)
			continue; 

		foreach Screen.ChildPanels( Control )
		{
			if (Control.MCPath == Path )
			{
				Control.OnCommand(cmd, arg);
				return;
			}	
		}
	}
}

// CALLBACK directly from Flash
// Occurs for a mouse-triggered event (-in, -out, -press, -release) 
//  path  Path to Control which handles event
//  cmd   Command to send to panel
//  arg   (optional) parameter to pass along.
simulated function FlashRaiseMouseEvent( string strPath, int cmd, string arg )
{
	local name Path;
	local array<string> Args;
	local UIScreen Screen;
	local UIPanel Control;

	`log("Flash raise mouse event: " $ strPath $ ", " $ cmd $ ", " $ arg ,,'uicore');

	if( !MouseActive )
		return;

	// Don't let the mouse work if we're still in alt-tab mode
	if( XComPlayerController(Pres.Owner).InAltTab() )
		return;

	Pres.m_kTooltipMgr.OnMouse( strPath, cmd, arg );

	Path = name(strPath);

	foreach Screens( Screen )
	{
		// Early out for optimization reasons.
		if( InStr(Path, Screen.MCPath) < 0 ) continue; 

		foreach Screen.ChildPanels( Control )
		{
			if( Control.MCPath == Path )
			{
				if ( !Control.bIsInited )
				{
					`log("Panel '" $ Path $ "' cannot receive '" $ cmd $ "' because it is not initialized.",,'uicore');
					return;
				}

				if ( Control.bIsRemoved )
				{
					`log("Panel '" $ Path $ "' cannot receive '" $ cmd $ "' because it was removed.",,'uicore');
					return;
				}

				if( Screen.bIsFocused || Screen.bProcessMouseEventsIfNotFocused )
				{
					// Parse out a flash path into an array, expected deliniation by periods. 
					Args = SplitString( arg, "." );
					Control.OnMouseEvent(cmd, Args);
				}
				return;
			}	
		}

		if( Screen.ConsumesMouseEvents() )
			break;
	}
}

simulated function SetMouseActive(bool bActive)
{
	//ScriptTrace();
	`log("GFX_INPUT: SetMouseActive: " $ bActive,,'uixcom');
	if( MouseActive != bActive )
	{
		MouseActive = bActive;
		NotifyFlashMouseStateChange();

		if(Pres.m_kUIMouseCursor != none)
		{
			if(MouseActive)
				Pres.m_kUIMouseCursor.Show();
			else
				Pres.m_kUIMouseCursor.Hide();
		}
	}
}

simulated function ActivateMouse()
{
	if( !MouseActive )
	{
		ScriptTrace();
		`log("GFX_INPUT: ActivateMouse",,'uixcom');		
		MouseActive = true;
		NotifyFlashMouseStateChange();
		if( Pres.m_kUIMouseCursor != None )
			Pres.m_kUIMouseCursor.Show();
	}
}

simulated function DeactivateMouse()
{
	if( MouseActive )
	{
		ScriptTrace();
		`log("GFX_INPUT: DeactivateMouse",,'uixcom');		
		MouseActive = false;
		NotifyFlashMouseStateChange();
		if( Pres.m_kUIMouseCursor != None )
			Pres.m_kUIMouseCursor.Hide();
	}
}

simulated function ToggleMouseActive()
{
	//ScriptTrace();
	`log("GFX_INPUT: ToggleMouseActive: " $ !MouseActive,,'uixcom');
	MouseActive = !MouseActive;
	NotifyFlashMouseStateChange();
	`log("Toggling mouse in the UIMovie. New state: MouseActive =" @string(MouseActive),,'uixcom');

	if( MouseActive )
		Pres.m_kUIMouseCursor.Show();
	else
		Pres.m_kUIMouseCursor.Hide();
}

function NotifyFlashMouseStateChange()
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Boolean;
	myValue.b = MouseActive;
	myArray.AddItem( myValue );

	Invoke(MCPath $ ".SetMouseActive", myArray);
}

public function bool IsMouseActive()
{
	return MouseActive || class'WorldInfo'.static.GetWorldInfo().IsPlayInEditor();	
}

// Use to set a Screen, by name, to be the highest visual depth displayed in flash. 
// This will persist, pushing targeted Screen above any later loaded Screens, 
// until this is set to an empty string. (At which time the sorting will stop
// as it currently exists, and it will *not* replace it back to the loaded order. 
// This should be called *after* the Screen has loaded, usually in its OnInit or elsewhere. 
// If it's called in the Init, the Screen won't exist to actually be swapped. 
//     ORDER: [ 0 = highest ... N = lowest ]
simulated public function UpdateHighestDepthScreens()
{
	local int i;
	local UIScreen Screen;
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	//`log("UpdateHighestDepthScreens: " ,,'uixcom');

	//Note: Once we move the grid in to 3D, this call will not be necessary for sorting issues, as the HUD and grid will be in 2 separate movies. 
	// TODO: @bsteiner: remove this call after grid goes 3D. 
	if( XComHQPresentationLayer(Pres) != none )
		MoveScreenToTop( XComHQPresentationLayer(Pres).m_kAvengerHUD ); //NOT IN STACK! Do not use Stack.GetScreen()

	// HACK: Force these types of screen to the top in the following order (bottom -> top)
	MoveScreenToTop(Pres.m_kNavHelpScreen);
	MoveScreenToTop(Pres.m_kTooltipMgr);			//NOT IN STACK!  Do not use Stack.GetScreen()
	MoveScreenToTop(Pres.Get2DMovie().DialogBox);	//NOT IN STACK!  Do not use Stack.GetScreen()
	MoveScreenToTop(Stack.GetScreen(class'UIRedScreen'));
	MoveScreenToTop(Stack.GetScreen(class'UIProgressDialogue'));

	for( i = 0; i < HighestDepthScreens.length; i++)
	{
		Screen = HighestDepthScreens[i];
		if (Screen != none)
		{
			myValue.Type = AS_String;
			myValue.s = string(Screen.Name); // Unique Name
			myArray.AddItem(myValue);
		}
	}

	Invoke(MCPath $ ".UpdateHighestDepthScreens", myArray);
}

// If the Screen currently exists, move to top.
simulated function MoveScreenToTop(UIScreen Screen)
{
	if(Screen != none)
	{
		HighestDepthScreens.RemoveItem(Screen);
		HighestDepthScreens.InsertItem(0, Screen);
	}
}

simulated function UpdateLanguage()
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;
	myValue.s = GetLanguage();
	myArray.AddItem( myValue );

	Invoke(MCPath $ ".SetLanguage", myArray);

	myArray.Length = 0;
	myValue.Type = AS_Boolean;
	myValue.b = class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive(); //TODO: Korean swap setting 
	myArray.AddItem( myValue );

	Invoke(MCPath $ ".SetKoreanAdvanceButtonSwap", myArray);
}

//----------------------------------------------------------------------------
//                              UI BATCHING
//----------------------------------------------------------------------------

/* 
* Sends a list of variable length parameters be formatted in the following way:
* 
* AS_String  -> path to the movieclip to call this function on
* AS_String  -> Function to call on mc
* AS_AnyType -> Parameter to pass into function call, variable number of these 
* 
* AS_Null    -> DELIMITER - When a null param is encountered, it signifies all operations are complete on this 
* 				function call, and moves to the next. 
* ...[repeats]
*/
simulated function BatchFunctionCalls( array<ASValue> m_arrData )
{
	Invoke(MCPath $ ".BatchFunctionCalls", m_arrData);
}

/* 
* OPS CODES:
* INDEX_MASK = 0xFFFFFF00
* FIELD_MASK = 0x0000000F
* FUNCTION_MASK = 0x000000F0
* 
* Sends a list of variable length parameters be formatted in the following way:
* 
* AS_Number  -> index into mc handle cache, mixed with ops code
* AS_String  -> Field to manipulate
* AS_AnyType -> Parameter to pass into function call, or value to assign field to
* 
* AS_Null    -> DELIMITER - When a null param is encountered, it signifies this operation is complete, and moves to the next. 
* ...[repeats]
*/
simulated function ControlOps(array<ASValue> arrData)
{
	//local int i;
	//`log("CONTROL OPS ================================", , 'uixcom');
	//for( i = 0; i < arrData.Length; ++i )
	//{
	//	`log("arrData:" @i $":" @arrData[i].S @arrData[i].N, , 'uixcom');
	//}
	//
	//`log("arrData.Length :" @ arrData.length, , 'uixcom');

	Invoke(MCPath $ ".ControlOps", arrData);
	//`log("CO ================================", , 'uixcom');
}

 /* 
 * Process all queued commands (happens once every UI tick)
 */
simulated function ProcessQueuedCommands()
{
	local int i;
	local array<ASValue> CommandBuffer;

	//`log("ProcessQueuedCommands ================================", , 'uixcom');
	//`log("CommandQueue.Length :" @ CommandQueue.length, , 'uixcom');
	if(CommandQueue.Length > 0)
	{
		//for( i = 0; i < CommandQueue.Length; ++i )
		//{
		//	`log("CommandQueue:" @i $":" @CommandQueue[i].S @CommandQueue[i].N, , 'uixcom');
		//}

		// NOTE: You must store the CommandQueue out here, because you may get callbacks manipulating 
		// the queue while in the process of invoking in the ControlOps. -bsteiner 5/27/2015
		CommandBuffer = CommandQueue;
		CommandQueue.length = 0; 
		ControlOps(CommandBuffer);
	}
	//`log("PQC ================================");
	if(BatchedFunctions.Length > 0)
	{
		BatchFunctionCalls(BatchedFunctions);
		BatchedFunctions.Length = 0;
	}
	if(RemovalCache.Length > 0)
	{
		for(i = 0; i < RemovalCache.Length; ++i)
		{
			`log("Clearing RemovalCache[" $i $"]: " @ RemovalCache[i],,'uicore' );
			CachedPanels[RemovalCache[i]] = false; // false means free to use
		}
		RemovalCache.Length = 0;
	}
}

//----------------------------------------------------------------------------
// CLEANUP
//----------------------------------------------------------------------------
simulated function Remove()
{
	OnClose();
	Close(); 
}

//----------------------------------------------------------------------------
// DEBUGGING
//----------------------------------------------------------------------------
simulated function AS_ToggleControlOpsDebugging()
{
	ActionScriptVoid(MCPath $ ".ToggleControlOpsDebugging");
}

simulated function AS_ToggleMouseHitDebugging()
{
	ActionScriptVoid(MCPath $ ".ToggleMouseHitDebugging");
}

simulated function CheckStack(class<UIScreen> targetClass)
{
`if (`notdefined(FINAL_RELEASE))
	if( Stack.IsInStack(targetClass) )
	{
		Pres.PopupDebugDialog("UI ERROR", "Multiple instances of '" $ targetClass.Name $ "' Screen detected. Please inform UI team and provide log file.");
		Stack.PopFirstInstanceOfClass(targetClass);
	}
`endif
}

defaultproperties
{
	UI_RES_X	= 1920;
	UI_RES_Y	= 1080;

	MCPath   	= "_level0.theInterfaceMgr";
	MovieInfo   = SwfMovie'gfxInterfaceMgr.InterfaceMgr';

	bIsVisible = true;
}
