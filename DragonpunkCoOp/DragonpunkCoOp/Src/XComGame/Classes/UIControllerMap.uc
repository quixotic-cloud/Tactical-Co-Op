//=============================================================================
//  Gamepad/controller layout user interface for xcom
//=============================================================================
class UIControllerMap extends UIScreen;


enum ELayout
{
	eLayout_Battlescape,
	eLayout_MissionControl
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
	super.InitScreen(InitController, InitMovie, InitName);
}


// Callback from Flash
simulated function OnInit()
{
	super.OnInit();

	if ( WorldInfo.IsConsoleBuild( CONSOLE_PS3 ) )
		AS_SetPS3GamePadLayout();   // PS3
	else
		AS_Set360GamePadLayout();   // PC & 360

	if ( layout == eLayout_Battlescape )
		LoadDefaultBattlescape();
	else
		LoadDefaultMissionControl();

	Realize();
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
		UIGamePad[0].label = m_sCancel;
		UIGamePad[1].label = m_sTakeAction;
	}
	else
	{	
		UIGamePad[0].label = m_sTakeAction;
		UIGamePad[1].label = m_sCancel;
	}
	UIGamePad[2].label = m_sSwapWeapons;
	UIGamePad[3].label = m_sOverwatch;
	UIGamePad[4].label = m_sMoveCursor;
	UIGamePad[5].label = m_sPanCamera;
	UIGamePad[6].label = m_sRotateCamera;           // dpad left/right
	UIGamePad[7].label = m_sEndTurn;
	UIGamePad[8].label = m_sPauseMenu;
	UIGamePad[9].label = m_sPrevUnit;
	UIGamePad[10].label = m_sNextUnit;
	UIGamePad[11].label = m_sZoom;
	UIGamePad[12].label = m_sTargetMode;
	UIGamePad[13].label = m_sDetails;
	UIGamePad[14].label = m_sUnused;
	UIGamePad[15].label = m_sHeightAdjust;          // dpad up/down
}


simulated function LoadDefaultMissionControl()
{
	if( class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive() )
	{
		UIGamePad[0].label = m_sCancelHQ;
		UIGamePad[1].label = m_sAccept;
	}
	else
	{
		UIGamePad[0].label = m_sAccept;
		UIGamePad[1].label = m_sCancelHQ;
	}
	UIGamePad[2].label = m_sAltChoice;
	UIGamePad[3].label = m_sMainRoom;
	UIGamePad[4].label = m_sSelectAnalogHQ;
	UIGamePad[5].label = m_sPanCameraHQ;
	UIGamePad[6].label = m_sSelectHQ;              // dpad left/right
	UIGamePad[7].label = m_sUnused; //m_sDatabaseHQ;
	UIGamePad[8].label = m_sPauseMenu;
	UIGamePad[9].label = m_sPrevUnitHQ;
	UIGamePad[10].label = m_sNextUnitHQ;
	UIGamePad[11].label = m_sZoomHQ;
	UIGamePad[12].label = m_sExpandEventList;
	UIGamePad[13].label = m_sDetails;
	UIGamePad[14].label = m_sUnused;
	UIGamePad[15].label = m_sItemSelect;         // dpad up/down
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

	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3) )
	{
		AS_SetTitle( m_sControllerPS3 );
	}
	else
	{
		AS_SetTitle( m_sController );
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
