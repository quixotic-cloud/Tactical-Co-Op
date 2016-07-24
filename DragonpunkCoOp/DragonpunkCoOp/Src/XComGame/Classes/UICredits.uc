//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UICredits
//  AUTHOR:  Brit Steiner --  03/2/12, major revision 10/07/2015
//  PURPOSE: This file controls the game side of the credits screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UICredits extends UIScreen;

var bool m_bGameOver;

var string h0_tagOpen, h1_tagOpen, h2_tagOpen, h3_tagOpen, h0_tagClose, h1_tagClose, h2_tagClose, h3_tagClose;
var string h0_pre, h0_post, h1_pre, h1_post, h2_pre, h2_post, h3_pre, h3_post; 

var localized string m_strLegal_PS3;
var localized string m_strLegal_XBOX;
var localized string m_strLegal_PC;

var localized array<string> m_arrCredits;

var int PixelsPerSec;
var int PixelsPerSecRateChange;

var UINavigationHelp NavHelp;

var XComStrategySoundManager SoundManager;
var XComShell ShellMenu;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);
	
	AS_SetPixelsPerSec(PixelsPerSec);

	h0_tagOpen = "<h0>"; 
	h1_tagOpen = "<h1>"; 
	h2_tagOpen = "<h2>"; 
	h3_tagOpen = "<h3>"; 
	h0_tagClose = "</h0>"; 
	h1_tagClose = "</h1>"; 
	h2_tagClose = "</h2>"; 
	h3_tagClose = "</h3>"; 
	
	h0_pre = "<font size='38'><b>";
	h0_post = "</b></font>";

	h1_pre = "<font size='34'><b>";
	h1_post = "</b></font>";

	h2_pre = "<font size='26'><b>";
	h2_post = "</b></font>";

	h3_pre = "<font size='20'>";
	h3_post = "</font>";

	if(XComHQPresentationLayer(Movie.Pres) != none)
		NavHelp = XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp;
	else
		NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();

	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	if(Movie.Pres.m_kPCOptions != none)
		Movie.Pres.m_kPCOptions.Hide();

	SoundManager = `XSTRATEGYSOUNDMGR;
	if(SoundManager != none)
	{
		SoundManager.PlayCreditsMusic();
	}
	else
	{
		SoundManager = Spawn(class'XComStrategySoundManager', self);
		DeferredPlayCreditsMusic();
	}

	ShellMenu = XComShell(WorldInfo.Game);
	ShellMenu.StopMenuMusic();

	UpdateData();
}

function DeferredPlayCreditsMusic()
{
	if(SoundManager.PlayHQMusic != none)
	{
		SoundManager.PlayHQMusicEvent();
		SoundManager.PlayCreditsMusic();
	}
	else
	{
		SetTimer(0.1f, false, nameof(DeferredPlayCreditsMusic));
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			MC.FunctionVoid("ToggleAnimation");
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
			AS_SetPixelsPerSec(PixelsPerSec + PixelsPerSecRateChange);
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
			AS_SetPixelsPerSec(PixelsPerSec - PixelsPerSecRateChange);
			break;
		default:
			break;
	}

	return true;
}

simulated function OnCommand( string cmd, string arg )
{
	if( cmd == "ScrollComplete" )
	{
		OnCancel();
	}
}
simulated protected function UpdateData()
{	
	local int i; 
	MC.BeginFunctionOp("RealizeCredits");
	for( i = 0; i < m_arrCredits.Length; i++ )
	{
		if( m_arrCredits[i] != "" )
			MC.QueueString(CapitalizeHeaders(m_arrCredits[i]));
	}	
	MC.EndOp();
}

function string CapitalizeHeaders( string styledString )
{
	local array<string> strPieces, strSubPieces; 
	local string specialUseSplitCharOpen, specialUseSplitCharClose; 
	local int i; 

	//No need to process empty strings used to format line breaks
	if( styledString == "" ) return styledString;

	//Get us something unique to break the string up with. Use these injected strings, because we don't actually want to 
	//rip out the header tags. 

	specialUseSplitCharOpen = "$";
	styledString = Repl( styledString, "<h", specialUseSplitCharOpen$"<h");
	specialUseSplitCharClose = "#";
	styledString = Repl( styledString, "</h", specialUseSplitCharClose$"</h");
	
	ParseStringIntoArray( styledString, strPieces, specialUseSplitCharOpen, true );

	for(i=0; i<strPieces.Length; i++)
	{
		if( InStr( strPieces[i], "<h", false, true ) == -1 )
			continue; 
		
		//Since we only want to caps anything in the front of this string that is wrapped in the header, 
		//chop up the sub string and caps the first entry. 
		ParseStringIntoArray( strPieces[i], strSubPieces, specialUseSplitCharClose, true );
		strSubPieces[0] = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(strSubPieces[0]);	

		//Slap strings back in to the main array: 
		JoinArray( strSubPieces, strPieces[i], "" ); 
	}

	//Slap all strings back together. 
	JoinArray( strPieces, styledString, "" );

	return styledString;
}

simulated function OnCancel()
{	
	SoundManager.StopHQMusicEvent();
	if(ShellMenu != none)
	{
		
		ShellMenu.StartMenuMusic();
	}

	CloseScreen();
	if(m_bGameOver)
	{
		Movie.Pres.UIEndGame();
		`XCOMHISTORY.ResetHistory();
		ConsoleCommand("disconnect");
	}
}

// ---------------------------------------------------------------------------
//  FLASH COMMANDS
// ---------------------------------------------------------------------------

simulated function AS_SetPixelsPerSec( int NewPPS )
{
	if( NewPPS > 0 )
	{
		PixelsPerSec = NewPPS;
		MC.FunctionNum("SetPixelsPerSec", PixelsPerSec);
	}
}

DefaultProperties
{
	LibID = "CreditsScreen"
	Package = "/ package/gfxCredits/Credits";
	InputState = eInputState_Consume;
	PixelsPerSec = 100;
	PixelsPerSecRateChange = 50;
	bAnimateOnInit = false;
}
