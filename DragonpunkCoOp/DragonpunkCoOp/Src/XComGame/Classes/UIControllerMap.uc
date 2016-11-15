//=============================================================================
//  Gamepad/controller layout user interface for xcom
//=============================================================================
class UIControllerMap extends UIScreen;


enum ELayout
{
	eLayout_Battlescape,
	eLayout_MissionControl,
	eLayout_Geoscape
};

struct UIGamepadLabel
{
	//var int	icon;       // icon code
	var string label;   // text label
};


var localized string m_sController;
var localized string m_sControllerPS3;
var localized string m_sKeyboardAndMouse;
var localized string m_sBattlescape;
var localized string m_sMissionControl;
var localized string m_sDone;
var localized string m_sDefaults;
var localized string m_sUnused;

// Battlescape
var localized string m_sTakeAction;     //0
var localized string m_sCancel;         //1
var localized string m_sSwapWeapons;    //2
var localized string m_sOverwatch;      //3
var localized string m_sMoveCursor;     //4
var localized string m_sPanCamera;      //5
var localized string m_sRotateCamera;   //6
var localized string m_sEndTurn;        //7
var localized string m_sPauseMenu;      //8
var localized string m_sNextUnit;       //9
var localized string m_sPrevUnit;       //10
var localized string m_sZoom;           //11
var localized string m_sTargetMode;     //12
var localized string m_sDetails;        //13
var localized string m_sHeightAdjust;   //15

// Mission Control
var localized string m_sAccept;         //0
var localized string m_sCancelHQ;       //1
var localized string m_sAltChoice;      //2
var localized string m_sMainRoom;       //3
var localized string m_sSelectAnalogHQ; //4
var localized string m_sPanCameraHQ;    //5
var localized string m_sSelectHQ;       //6
var localized string m_sDatabaseHQ;     //7 moved to main menu
var localized string m_sNextUnitHQ;     //9
var localized string m_sPrevUnitHQ;     //10
var localized string m_sZoomHQ;         //11
var localized string m_sExpandEventList;//12
var localized string m_sItemSelect;     //15

var localized string m_sNotifications;
var localized string m_sPrevious;
var localized string m_sNext;
var localized string m_sEventQueue;
var localized string m_sBridge;
var localized string m_sBuildFacilities;
var localized string m_sBackcancel;
var localized string m_sDarkEvents;
var localized string m_sScan;
var localized string m_sSelectAccept;
var localized string m_sSkyranger;
var localized string m_sMoveUnit;
var localized string m_sActionMenu;

var localized string m_sControllerMap;
var localized string m_sAvenger;
var localized string m_sGeoscape;
var localized string m_sTactical;
var localized string m_sWaypoint;
var localized string m_sResistanceNetwork;
var localized string m_sLookAtAvenger;
//</workshop>

/* may be utilized
var localized string m_sRSBtnInfo;
var localized string m_sRTBtnInfo;
var localized string m_sYBtnInfo;
var localized string m_sBBtnInfo;
var localized string m_sXBtnInfo;
var localized string m_sABtnInfo;
var localized string m_sStartBtnInfo;
var localized string m_sSelectBtnInfo;
var localized string m_sDPadVBtnInfo;
var localized string m_sDPadHBtnInfo;
var localized string m_sLSBtnInfo;
var localized string m_sLTBtnInfo;
var localized string m_sLBBtnInfo;
*/

var ELayout       layout;

var UIGamepadLabel UIGamePad[16]; 	//static array that holds label-structs

// Psuedo CTOR
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UINavigationHelp NavHelp;
	super.InitScreen(InitController, InitMovie, InitName);
	AnchorCenter();
	SetX(-640);
	SetY(-377);
	
	NavHelp = GetNavHelp();
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton();
}


// Callback from Flash
simulated function OnInit()
{
	//local  XComOnlineProfileSettings ProfileSettings;
	super.OnInit();

	//ProfileSettings = `XPROFILESETTINGS;

	//if( ProfileSettings.Data.m_eControllerIconType == eControllerIconType_Playstation )
	//	AS_SetPS3GamePadLayout();   // PS3
	//else
		AS_Set360GamePadLayout();   // PC & 360

	if ( layout == eLayout_Battlescape )
		LoadDefaultBattlescape();
	else if (layout == eLayout_GeoScape)
	{
		LoadDefaultGeoscape();
	}
	else
		LoadDefaultMissionControl();
	InjectImages();

	Realize();
}

simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;
	Result = PC.Pres.GetNavHelp();
	if( Result == None )
	{
		if( `PRES != none ) // Tactical
		{
			Result = Spawn(class'UINavigationHelp', Movie.Stack.GetScreen(class'UIMouseGuard')).InitNavHelp();
		}
		else if( `HQPRES != none ) // Strategy
			Result = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	return Result;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B: 
			if( bIsInited )
			{
				Movie.Stack.Pop(self);
			}
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function LoadDefaultBattlescape()
{
	if( class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive() )
	{
		UIGamePad[0].label = m_sBackcancel;
		UIGamePad[2].label = m_sSelectAccept;
	}
	else
	{	
		UIGamePad[0].label = m_sSelectAccept;
		UIGamePad[2].label = m_sBackcancel;
	}
	UIGamePad[1].label = m_sWaypoint;

	UIGamePad[3].label = m_sOverwatch;
	UIGamePad[4].label = m_sMoveUnit;
	UIGamePad[5].label = m_sPanCamera;
	UIGamePad[6].label = m_sRotateCamera;           // dpad left/right
	UIGamePad[7].label = m_sEndTurn;
	UIGamePad[8].label = m_sPauseMenu;
	UIGamePad[9].label = m_sPrevious;
	UIGamePad[10].label = m_sNext;
	UIGamePad[11].label = m_sZoom;
	UIGamePad[12].label = m_sActionMenu;
	UIGamePad[13].label = m_sDetails;
	UIGamePad[14].label = m_sSkyranger;
	UIGamePad[15].label = m_sHeightAdjust;
	//</workshop>
}


simulated function LoadDefaultMissionControl()
{
	if (class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive())
	{
		UIGamePad[0].label = m_sBackcancel;
		UIGamePad[2].label = m_sAccept;
	}
	else
	{
		UIGamePad[0].label = m_sAccept;
		UIGamePad[2].label = m_sBackcancel;
	}

	UIGamePad[1].label = m_sBuildFacilities;

	UIGamePad[3].label = m_sBridge;
	UIGamePad[4].label = m_sSelectHQ;
	UIGamePad[5].label = m_sPanCamera;
	UIGamePad[6].label = m_sSelectHQ;
	UIGamePad[7].label = m_sUnused;
	UIGamePad[8].label = m_sPauseMenu;
	UIGamePad[9].label = m_sPrevious;
	UIGamePad[10].label = m_sNext;
	UIGamePad[11].label = m_sZoom;
	UIGamePad[12].label = m_sZoom;
	UIGamePad[13].label = m_sNotifications;
	UIGamePad[14].label = m_sEventQueue;
	UIGamePad[15].label = m_sSelectHQ;
}

simulated function LoadDefaultGeoscape()
{
	if (class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive())
	{
		UIGamePad[0].label = m_sBackcancel;
		UIGamePad[1].label = m_sSelectAccept;
	}
	else
	{
		UIGamePad[0].label = m_sSelectAccept;
		UIGamePad[1].label = m_sBackcancel;
	}

	UIGamePad[2].label = m_sUnused;
	UIGamePad[3].label = m_sDarkEvents;
	UIGamePad[4].label = m_sSelectHQ;
	UIGamePad[5].label = m_sUnused;
	UIGamePad[6].label = m_sUnused;
	UIGamePad[7].label = m_sResistanceNetwork;
	UIGamePad[8].label = m_sPauseMenu;
	UIGamePad[9].label = m_sPrevious;
	UIGamePad[10].label = m_sNext;
	UIGamePad[11].label = m_sZoom;
	UIGamePad[12].label = m_sZoom;
	UIGamePad[13].label = m_sUnused;
	UIGamePad[14].label = m_sLookAtAvenger;
	UIGamePad[15].label = m_sUnused;
}

simulated function InjectImages()
{
	local string IconPrefix;

	IconPrefix = class'UIUtilities_Input'.static.GetGamepadIconPrefix();


	UIGamePad[0].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_A_X, 20, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[0].label);
		UIGamePad[1].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 20, 20, -10) @
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[1].label);
		UIGamePad[2].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_B_CIRCLE, 20, 20, -10) @
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[2].label);
	UIGamePad[3].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, 20, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[3].label);
	UIGamePad[4].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[4].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_LSTICK, 20, 20, -10);
	UIGamePad[5].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_RSTICK, 20, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[5].label);
	UIGamePad[6].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[6].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL, 20, 20, -10);

	if (WorldInfo.IsConsoleBuild(CONSOLE_PS3))
	{
		UIGamePad[7].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[7].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_BACK_SELECT, 32, 20, -10);
		UIGamePad[8].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_START, 40, 40, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[8].label);
	}
	else
	{
		UIGamePad[7].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[7].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_BACK_SELECT, 20, 20, -10);
		UIGamePad[8].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_START, 20, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[8].label);
	}
	UIGamePad[9].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[9].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_LB_L1, 32.5, 20, -10);
	UIGamePad[10].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_RB_R1, 32.5, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[10].label);
	UIGamePad[11].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[11].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_LT_L2, 32.5, 20, -10);
	UIGamePad[12].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_RT_R2, 32.5, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[12].label);
	UIGamePad[13].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[13].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_LSCLICK_L3, 20, 20, -10);
	UIGamePad[14].label = class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_RSCLICK_R3, 20, 20, -10) @ 
		class'UIUtilities_Text'.static.AlignLeft(UIGamePad[14].label);
	UIGamePad[15].label = class'UIUtilities_Text'.static.AlignRight(UIGamePad[15].label) @ 
		class'UIUtilities_Text'.static.InjectImage(IconPrefix $ class'UIUtilities_Input'.const.ICON_DPAD_VERTICAL, 20, 20, -10);
}

simulated function Realize()
{
	local int i;
	/*
	local string sOtherLocation;
	
	if ( layout == eLayout_Battlescape )
		sOtherLocation = m_sMissionControl;
	else
		sOtherLocation = m_sBattlescape;
	*/


	AS_SetTitle(m_sControllerMap);
	if (layout == eLayout_Battlescape)
	{
		MC.FunctionString("SetSubtitle", m_sTactical);
	}
	else if (layout == eLayout_GeoScape)
	{
		MC.FunctionString("SetSubtitle", m_sGeoscape);
	}
	else
	{
		MC.FunctionString("SetSubtitle", m_sAvenger);
	}

	AS_SetHelp( 
		class'UIUtilities_Input'.static.GetBackButtonIcon(), m_sDone, 
		"", "", 
		"", "" );

	for( i = 0; i < 16; i++ )
	{
		AS_SetControl(i, UIGamePad[i].label );
	}
}


//----------------------------------------------------------------------------
// Flash calls
//----------------------------------------------------------------------------



simulated function AS_Set360GamePadLayout()
{ Movie.ActionScriptVoid( MCPath $ ".Set360GamePadLayout" ); } 

simulated function AS_SetPS3GamePadLayout()
{ Movie.ActionScriptVoid( MCPath $ ".SetPS3GamePadLayout" ); } 

simulated function AS_SetTitle( string text )
{ Movie.ActionScriptVoid( MCPath $ ".SetTitle" ); } 

simulated function AS_SetHelp( string icon0, string text0, string icon1, string text1, string icon2, string text2 )
{ Movie.ActionScriptVoid( MCPath $ ".SetHelp" ); } 

simulated function AS_SetControl( int icon, string text )
{ Movie.ActionScriptVoid( MCPath $ ".SetControl" ); } 


defaultproperties
{
	Package = "/ package/gfxControllerMap/ControllerMap";
	MCName = "theControllerMap";
	InputState = eInputState_Consume;
}
