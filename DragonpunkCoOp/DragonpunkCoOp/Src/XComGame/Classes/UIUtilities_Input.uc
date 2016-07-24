class UIUtilities_Input extends Object native(UI);

// TODO: Load value from Windows?
const MOUSE_DOUBLE_CLICK_SPEED = 200; // 200 milliseconds

// Constants which the FXS Flash system uses internally for input
// Values are maintained in Input.ac

const FXS_INPUT_NONE		= -1;

const FXS_CONTROLLER_RANGE_BEGIN = 299;

const FXS_BUTTON_A			= 300;
const FXS_BUTTON_B			= 301;
const FXS_BUTTON_X          = 302;
const FXS_BUTTON_Y			= 303;

const FXS_BUTTON_PS3_X		= 300;
const FXS_BUTTON_PS3_CIRCLE	= 301;
const FXS_BUTTON_PS3_SQUARE	= 302;
const FXS_BUTTON_PS3_TRIANGLE = 303;

const FXS_BUTTON_LSTICK		= 310;	// Activating the left stick
const FXS_BUTTON_L3         = 311;	// Pressing left stick in
const FXS_BUTTON_RSTICK		= 312;	// Activating the right stick
const FXS_BUTTON_R3     	= 313;	// Pressing right stick in
const FXS_BUTTON_PAD		= 314;	// Pressing dpad in

const FXS_BUTTON_SELECT		= 320;
const FXS_BUTTON_START		= 321;

const FXS_BUTTON_LBUMPER	= 330;
const FXS_BUTTON_RBUMPER	= 331;
const FXS_BUTTON_LTRIGGER	= 332;
const FXS_BUTTON_RTRIGGER	= 333;

const FXS_DPAD_UP			= 350;
//const FXS_DPAD_UP_RIGHT	= 351;
const FXS_DPAD_RIGHT		= 352;
//const DPAD_DOWN_RIGHT	    = 353;
const FXS_DPAD_DOWN		    = 354;
//const DPAD_DOWN_LEFT	    = 355;
const FXS_DPAD_LEFT		    = 356;
//const DPAD_UP_LEFT	    = 357;

const FXS_ANY_INPUT         = 360; //Used as a marker for any input 
const FXS_BUTTON_A_STEAM    = 361; //Used as a marker for any input 

const FXS_VIRTUAL_LSTICK_UP	    = 370;
const FXS_VIRTUAL_LSTICK_DOWN   = 371;
const FXS_VIRTUAL_LSTICK_LEFT   = 372;
const FXS_VIRTUAL_LSTICK_RIGHT  = 373;

const FXS_VIRTUAL_RSTICK_UP	    = 374;
const FXS_VIRTUAL_RSTICK_DOWN   = 375;
const FXS_VIRTUAL_RSTICK_LEFT   = 376;
const FXS_VIRTUAL_RSTICK_RIGHT  = 378;

const FXS_CONTROLLER_RANGE_END	= 379;

// MOUSE ************************

const FXS_MOUSE_RANGE_BEGIN	= 389;

const FXS_L_MOUSE_DOWN		= 390;
const FXS_L_MOUSE_UP		= 391;
const FXS_L_MOUSE_IN		= 392;
const FXS_L_MOUSE_OUT		= 393;
const FXS_L_MOUSE_DRAG_OVER	= 394;
const FXS_L_MOUSE_DRAG_OUT	= 395;
const FXS_L_MOUSE_RELEASE_OUTSIDE = 396;
const FXS_L_MOUSE_OVER		= 397;
const FXS_L_MOUSE_DOUBLE_UP = 398;
const FXS_L_MOUSE_DOUBLE_DOWN = 399;
// Objects that care about double click events that also perform an action on 
// single click need to listen to this event for their single click action.
const FXS_L_MOUSE_UP_DELAYED = 400;

const FXS_R_MOUSE_DOWN		= 405;
//const FXS_R_MOUSE_UP		= 406;
//const FXS_R_MOUSE_IN		= 402;
//const FXS_R_MOUSE_OUT		= 403;
//const FXS_R_MOUSE_DRAG_OVER = 404;
//const FXS_R_MOUSE_DRAG_OUT  = 405;
//const FXS_R_MOUSE_RELEASE_OUTSIDE = 406;

const FXS_M_MOUSE		= 410;

const FXS_MOUSE_SCROLL_UP	= 420;
const FXS_MOUSE_SCROLL_DOWN	= 421;

const FXS_MOUSE_4	        = 422;
const FXS_MOUSE_5	        = 423;

const FXS_MOUSE_RANGE_END	= 424;

// KEYBOARD ************************

const FXS_KEYBOARD_RANGE_BEGIN	= 499;

const FXS_ARROW_UP			= 500;
const FXS_ARROW_RIGHT		= 501;
const FXS_ARROW_DOWN	    = 502;
const FXS_ARROW_LEFT	    = 503;

const FXS_KEY_PAUSE		    = 509;
const FXS_KEY_ESCAPE        = 510;
const FXS_KEY_ENTER         = 511;
const FXS_KEY_BACKSPACE     = 512;
const FXS_KEY_SPACEBAR      = 513;
const FXS_KEY_LEFT_SHIFT    = 514;
const FXS_KEY_A             = 515;
const FXS_KEY_B             = 516;
const FXS_KEY_C             = 517;
const FXS_KEY_D             = 518;
const FXS_KEY_E             = 519;
const FXS_KEY_F             = 520;
const FXS_KEY_G             = 521;
const FXS_KEY_H             = 522;
const FXS_KEY_I             = 523;
const FXS_KEY_J             = 524;
const FXS_KEY_K             = 525;
const FXS_KEY_L             = 526;
const FXS_KEY_M             = 527;
const FXS_KEY_N             = 528;
const FXS_KEY_O             = 529;
const FXS_KEY_P             = 530;
const FXS_KEY_Q             = 531;
const FXS_KEY_R             = 532;
const FXS_KEY_S             = 533;
const FXS_KEY_T             = 534;
const FXS_KEY_U             = 535;
const FXS_KEY_V             = 536;
const FXS_KEY_W             = 537;
const FXS_KEY_X             = 538;
const FXS_KEY_Y             = 539;
const FXS_KEY_Z             = 540;
const FXS_KEY_LEFT_CONTROL  = 541;
const FXS_KEY_DELETE        = 542;
const FXS_KEY_LEFT_ALT      = 543;
const FXS_KEY_RIGHT_CONTROL = 544;
const FXS_KEY_RIGHT_SHIFT   = 545;
const FXS_KEY_RIGHT_ALT     = 546;

const FXS_KEY_HOME          = 570;
const FXS_KEY_TAB           = 571;
const FXS_KEY_END           = 572;
const FXS_KEY_PAGEUP        = 573;
const FXS_KEY_PAGEDN        = 574;

const FXS_KEY_F1            = 600;
const FXS_KEY_F2            = 601;
const FXS_KEY_F3            = 602;
const FXS_KEY_F4            = 603;
const FXS_KEY_F5            = 604;
const FXS_KEY_F6            = 605;
const FXS_KEY_F7            = 606;
const FXS_KEY_F8            = 607;
const FXS_KEY_F9            = 608;
const FXS_KEY_F10           = 609;
const FXS_KEY_F11           = 610;
const FXS_KEY_F12           = 611;

const FXS_KEY_1             = 612;
const FXS_KEY_2             = 613;
const FXS_KEY_3             = 614;
const FXS_KEY_4             = 615;
const FXS_KEY_5             = 616;
const FXS_KEY_6             = 617;
const FXS_KEY_7             = 618;
const FXS_KEY_8             = 619;
const FXS_KEY_9             = 620;
const FXS_KEY_0             = 621;

const FXS_KEY_NUMPAD_1      = 631;
const FXS_KEY_NUMPAD_2      = 632;
const FXS_KEY_NUMPAD_3      = 633;
const FXS_KEY_NUMPAD_4      = 634;
const FXS_KEY_NUMPAD_5      = 635;
const FXS_KEY_NUMPAD_6      = 636;
const FXS_KEY_NUMPAD_7      = 637;
const FXS_KEY_NUMPAD_8      = 638;
const FXS_KEY_NUMPAD_9      = 639;
const FXS_KEY_NUMPAD_0      = 640;

const FXS_KEYBOARD_RANGE_END = 700;

// Actions - bitmasks *************
const FXS_ACTION_PRESS           = 1;
const FXS_ACTION_PREHOLD_REPEAT  = 2;
const FXS_ACTION_HOLD	         = 4;
const FXS_ACTION_POSTHOLD_REPEAT = 8;
const FXS_ACTION_TAP             = 16;
const FXS_ACTION_RELEASE         = 32;

// GAMEPAD ICONS

const ICON_A_X	    		= "Icon_A_X";
const ICON_B_CIRCLE			= "Icon_B_CIRCLE";
const ICON_X_SQUARE         = "Icon_X_SQUARE";
const ICON_Y_TRIANGLE		= "Icon_Y_TRIANGLE";

const ICON_START            = "Icon_START";
const ICON_BACK_SELECT      = "Icon_BACK_SELECT";
	
const ICON_DPAD             = "Icon_DPAD";
const ICON_DPAD_UP          = "Icon_DPAD_UP";
const ICON_DPAD_DOWN        = "Icon_DPAD_DOWN";
const ICON_DPAD_LEFT        = "Icon_DPAD_LEFT";
const ICON_DPAD_RIGHT       = "Icon_DPAD_RIGHT";
const ICON_DPAD_HORIZONTAL  = "Icon_DPAD_HORIZONTAL";
const ICON_DPAD_VERTICAL    = "Icon_DPAD_VERTICAL";

const ICON_LSTICK           = "Icon_LSTICK";
const ICON_RSTICK           = "Icon_RSTICK";

const ICON_LB_L1            = "Icon_LB_L1";
const ICON_LT_L2            = "Icon_LT_L2";
const ICON_LSCLICK_L3       = "Icon_LSCLICK_L3";

const ICON_RB_R1            = "Icon_RB_R1";
const ICON_RT_R2            = "Icon_RT_R2";
const ICON_RSCLICK_R3       = "Icon_RSCLICK_R3";

const ICON_ABILITY_OVERWATCH = "Icon_OVERWATCH_HTML";

const ICON_KEY_TAB          = "Icon_KEY_TAB";

const ICON_PC_LEFTMOUSE     = "lmb_icon";
const ICON_PC_RIGHTMOUSE    = "rmb_icon";
const ICON_PC_WHEELCLICK    = "PC_mouseWheelClick";
const ICON_PC_WHEELSCROLL   = "PC_mouseWheelScroll";
const ICON_PC_MOUSE_4       = "PC_mouseLeft4";
const ICON_PC_MOUSE_5       = "PC_mouseLeft5";

const ICON_PC_ARROWLEFT     = "PC_arrowLEFT";
const ICON_PC_ARROWRIGHT    = "PC_arrowRIGHT";
const ICON_PC_ARROWUP       = "PC_arrowUP";
const ICON_PC_ARROWDOWN     = "PC_arrowDOWN";

const ICON_PC_LEFTMOUSE4    = "PC_mouseLeft4";
const ICON_PC_LEFTMOUSE5    = "PC_mouseLeft5";


static function string HTML( string sIcon, optional int imgDimensions = 18, optional int vspaceOffset=-3 )
{
	return( "<img src='" $ sIcon $ "' align='baseline' vspace='"$vspaceOffset$"' width='"$imgDimensions$"' height='"$imgDimensions$"'>" );
}
static function string HTML_MESSENGER( string sIcon )
{
	return( "<img src='" $ sIcon $ "' align='baseline' vspace='-5' width='25' height='25'>" );
}
static function string HTML_TITLEFONT( string sIcon )
{
	return( "<img src='" $ sIcon $ "' align='baseline' vspace='-10' width='30' height='30'>" );
}
static function string HTML_BODYFONT( string sIcon )
{
	return( "<img src='" $ sIcon $ "' align='baseline' vspace='-7' width='25' height='25'>" );
}
static function string HTML_KEYMAP( string sKeymap )
{
	//return(ColorString WARNING_HTML_COLOR   "[<font color='#67E8ED'>" $ sKeymap $ "</font>]"); // Yellow
	return("[" $ class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(sKeymap) $ "]"); 
}

static function string InsertGamepadIcons(string sSource)
{
	local string sResult;

	//TODO: Import Steam icons, and look those up if steam controller is active. 

	sResult = Repl(sSource, "%LS", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_LSTICK));
	sResult = Repl(sResult, "%RS", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_RSTICK));
	sResult = Repl(sResult, "%A", class'UIUtilities_Input'.static.HTML(GetAdvanceButtonIcon()));
	sResult = Repl(sResult, "%B", class'UIUtilities_Input'.static.HTML(GetBackButtonIcon()));
	sResult = Repl(sResult, "%X", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.Icon_X_SQUARE));
	sResult = Repl(sResult, "%Y", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.Icon_Y_TRIANGLE));
	sResult = Repl(sResult, "%RB", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_RB_R1));
	sResult = Repl(sResult, "%RT", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_RT_R2));
	sResult = Repl(sResult, "%LB", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_LB_L1));
	sResult = Repl(sResult, "%LT", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_LT_L2));
	sResult = Repl(sResult, "%RT", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_RT_R2));
	sResult = Repl(sResult, "%DU", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_DPAD_UP));
	sResult = Repl(sResult, "%DD", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_DPAD_DOWN));
	sResult = Repl(sResult, "%DL", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_DPAD_LEFT));
	sResult = Repl(sResult, "%DR", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_DPAD_RIGHT));

	return sResult;
}

static function string InsertGamepadIconsMessenger(string sSource)
{
	local string sResult;

	// TODO: Add all gamepad icons
	sResult = Repl(sSource, "%LS", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_LSTICK));
	sResult = Repl(sResult, "%RS", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_RSTICK));
	sResult = Repl(sResult, "%A", class'UIUtilities_Input'.static.HTML_MESSENGER(GetAdvanceButtonIcon()));
	sResult = Repl(sResult, "%B", class'UIUtilities_Input'.static.HTML_MESSENGER(GetBackButtonIcon()));
	sResult = Repl(sResult, "%X", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.Icon_X_SQUARE));
	sResult = Repl(sResult, "%Y", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.Icon_Y_TRIANGLE));
	sResult = Repl(sResult, "%RB", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_RB_R1));
	sResult = Repl(sResult, "%RT", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_RT_R2));
	sResult = Repl(sResult, "%LB", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_LB_L1));
	sResult = Repl(sResult, "%LT", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_LT_L2));
	sResult = Repl(sResult, "%DU", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_DPAD_UP));
	sResult = Repl(sResult, "%DD", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_DPAD_DOWN));
	sResult = Repl(sResult, "%DL", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_DPAD_LEFT));
	sResult = Repl(sResult, "%DR", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_DPAD_RIGHT));

	return sResult;
}

static function string FindAbilityKey(string sSource, string sAction, int iActionEnum, out byte bKeyNotFound, XComKeybindingData kKeybinds, PlayerInput kPlayerInput, optional KeybindCategories category = eKC_Tactical )
{
	local string sActionKey;

	// If the action string does not exist in the source string, itnore it.
	if( InStr( sSource, sAction ) == -1 )
	{
		return sSource;
	}

	// See if the player has the primary binding set.
	sActionKey = kKeybinds.GetKeyStringForAction( kPlayerInput, iActionEnum, , category ); 
	if( Len(sActionKey) > 0 )
	{
		return Repl( sSource, sAction, HTML_KEYMAP( sActionKey ) );
	}

	// See if the player has the secondary binding set.
	sActionkey = kKeybinds.GetKeyStringForAction( kPlayerInput, iActionEnum, true, category );
	if( Len(sActionkey) > 0 )
	{
		return Repl( sSource, sAction, HTML_KEYMAP( sActionKey ) );
	}

	// No bindings set, the help system will display a secondary line of text with no keymappings.
	bKeyNotFound++;
	return sSource;
}

static function string InsertAbilityKeys(string sSource, out byte bKeyNotFound, XComKeybindingData kKeybinds, PlayerInput kPlayerInput)
{
	local string sResult;
	bKeyNotFound = 0;

	//sResult = FindAbilityKey(sSource, "%PREV_ABILITY", "PREV_ABILITY", bKeyNotFound );
	//sResult = FindAbilityKey(sResult, "%NEXT_ABILITY", "NEXT_ABILITY", bKeyNotFound );
	sResult = FindAbilityKey(sSource, "%USE_ABILITY", eTBC_EnterShotHUD_Confirm, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%PREV_TARGET", eTBC_PrevUnit, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%NEXT_TARGET", eTBC_NextUnit, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%ACTIVATE_HUD", eTBC_EnterShotHUD_Confirm, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_LEFT", eTBC_CamMoveLeft, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_RIGHT", eTBC_CamMoveRight, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_UP", eTBC_CamMoveUp, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_DOWN", eTBC_CamMoveDown, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_SPIN_LEFT", eTBC_CamRotateLeft, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_SPIN_RIGHT", eTBC_CamRotateRight, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%PREV_SOLDIER", eTBC_PrevUnit, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%NEXT_SOLDIER", eTBC_NextUnit, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%OPEN_DOOR", eTBC_Interact, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CURSOR_LEVEL_UP", eTBC_CursorUp, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CURSOR_LEVEL_DOWN", eTBC_CursorDown, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%RELOAD", eTBC_AbilityReload, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_ZOOM_OUT", eTBC_CamZoomOut, bKeyNotFound, kKeybinds, kPlayerInput );
	sResult = FindAbilityKey(sResult, "%CAMERA_ZOOM_IN", eTBC_CamZoomIn, bKeyNotFound, kKeybinds, kPlayerInput );

	return sResult;
}

static function string InsertPCIcons(string sSource)
{
	local string sResult;

	sResult = sSource; 

	if( `XENGINE.m_SteamControllerManager.IsSteamControllerActive() )
	{
		sResult = InsertSteamIcons(sResult);
	}

	// TODO: Add all gamepad icons
	sResult = Repl(sResult, "%LM4", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_LEFTMOUSE4));
	sResult = Repl(sResult, "%LM5", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_LEFTMOUSE5));
	sResult = Repl(sResult, HTML_KEYMAP(class'XComKeybindingData'.default.m_arrLocalizedKeyNames[eLKN_LeftMouseButton]), class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_PC_LEFTMOUSE, 40, 20, 0));
	sResult = Repl(sResult, "%KEY:LMB%", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_PC_LEFTMOUSE, 40, 20, 0));
	sResult = Repl(sResult, HTML_KEYMAP(class'XComKeybindingData'.default.m_arrLocalizedKeyNames[eLKN_RightMouseButton]), class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_PC_RIGHTMOUSE, 40, 20, 0));

	sResult = Repl(sResult, "%WC", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_WHEELCLICK));
	sResult = Repl(sResult, "%WS", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_WHEELSCROLL));
	sResult = Repl(sResult, "%LA", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_ARROWLEFT));
	sResult = Repl(sResult, "%RA", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_ARROWRIGHT));
	sResult = Repl(sResult, "%UA", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_ARROWUP));
	sResult = Repl(sResult, "%DA", class'UIUtilities_Input'.static.HTML_MESSENGER(class'UIUtilities_Input'.const.ICON_PC_ARROWDOWN));

	return sResult;
}


static function string InsertSteamIcons(string sSource) 
{
	local string sResult, SteamIcon;
	local XComSteamControllerManager SteamMgr; 
	local int IconSize; 

	IconSize = 24; 

	sResult = sSource; 
	SteamMgr = `XENGINE.m_SteamControllerManager; 
	
	//RMB eKC_Tactical, eTBC_Path
	SteamIcon = "steam_"$SteamMgr.GetSteamControllerActionOrigin(eKC_Tactical, eTBC_Path);
	sResult = Repl(sResult, MarkForKeybinding(class'XComKeybindingData'.default.m_arrLocalizedKeyNames[eLKN_RightMouseButton]), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));

	//LMB eKC_Tactical, eTBC_EnterShotHUD_Confirm
	SteamIcon = "steam_"$SteamMgr.GetSteamControllerActionOrigin(eKC_Tactical, eTBC_EnterShotHUD_Confirm);
	sResult = Repl(sResult, MarkForKeybinding(class'XComKeybindingData'.default.m_arrLocalizedKeyNames[eLKN_LeftMouseButton]), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));

	//Q eKC_Tactical, eTBC_CamRotateLeft
	SteamIcon = "steam_"$SteamMgr.GetSteamControllerActionOrigin(eKC_Tactical, eTBC_CamRotateLeft);
	sResult = Repl(sResult, MarkForKeybinding("Q"), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));

	//E eKC_Tactical, eTBC_CamRotateRight 
	SteamIcon = "steam_"$SteamMgr.GetSteamControllerActionOrigin(eKC_Tactical, eTBC_CamRotateRight);
	sResult = Repl(sResult, MarkForKeybinding("E"), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));

	//TAB eKC_Tactical, eTBC_NextUnit 
	SteamIcon = "steam_"$SteamMgr.GetSteamControllerActionOrigin(eKC_Tactical, eTBC_NextUnit);
	sResult = Repl(sResult, MarkForKeybinding(class'XComKeybindingData'.default.m_arrLocalizedKeyNames[eLKN_Tab]), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));

	//ENTER eKC_General, eGBC_Confirm
	SteamIcon = "steam_"$SteamMgr.GetSteamControllerActionOrigin(eKC_General, eGBC_Confirm);
	sResult = Repl(sResult, MarkForKeybinding(class'XComKeybindingData'.default.m_arrLocalizedKeyNames[eLKN_Enter]), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));
	
	//P eKC_Tactical,  eTBC_Interact 
	SteamIcon = "steam_"$ SteamMgr.GetSteamControllerActionOrigin(eKC_Tactical, eTBC_Interact);
	sResult = Repl(sResult, MarkForKeybinding("P"), class'UIUtilities_Text'.static.InjectImage(SteamIcon, IconSize, IconSize, 0));

	return sResult;
}

static function string MarkForKeybinding(string Source)
{
	return "%KEY:" $ Source $"%";
}

static function string GetAdvanceButtonIcon()
{
	if( IsAdvanceButtonSwapActive() ) //TODO: get Korean setting 
		return class'UIUtilities_Input'.const.ICON_B_CIRCLE; 
	else
		return class'UIUtilities_Input'.const.ICON_A_X; 
}
static function string GetBackButtonIcon()
{
	if( IsAdvanceButtonSwapActive() ) //TODO: get Korean setting 
		return class'UIUtilities_Input'.const.ICON_A_X; 
	else
		return class'UIUtilities_Input'.const.ICON_B_CIRCLE; 
}

native static function bool IsAdvanceButtonSwapActive(); 

DefaultProperties
{
}
