//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UINarrativePopup.uc
//  AUTHOR:  Brit Steiner - 6/24/11
//           Tronster - 4/19/12
//  PURPOSE: The narrative popup window with portrait.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UINarrativePopup extends UIScreen
	dependson(XGNarrative, XGTacticalScreenMgr);

//----------------------------------------------------------------------------
// MEMBERS

var UINarrativemgr m_kNarrativeMgr;

var bool bIsModal; 
var name DisplayTag;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	m_kNarrativeMgr.m_kTargetScreen = self;
}

simulated function OnInit()
{
	super.OnInit();
	
	RefreshMouseState();
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(Movie, 'IsMouseActive', self, RefreshMouseState);
	
	m_kNarrativeMgr.BeginNarrative();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to release; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false; 

	switch( cmd )
	{			
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			OnAccept();
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			break;

		default:
			//bHandled = false;
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}


simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string targetCallback;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			targetCallback = args[4];
			switch(targetCallback)
			{
				case("theStartButton"):
					OnAccept();
					Movie.Pres.PlayUISound(eSUISound_MenuSelect);
					break;
				
				default:
					//nothing 
					break;
			}
			break;
	}
}

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================

simulated function UpdateDisplay()
{
	AS_SetTitle( m_kNarrativeMgr.CurrentOutput.strTitle ); 
	AS_SetPortrait( m_kNarrativeMgr.CurrentOutput.strImage );
	AS_SetText( m_kNarrativeMgr.CurrentOutput.strText );		
	AS_SetHelp( 3, m_kNarrativeMgr.m_stNarrativeOk, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}


simulated function bool OnAccept( optional string strOption = "" )
{
	if (m_kNarrativeMgr.m_arrConversations.Length > 0)
	{
		if (m_kNarrativeMgr.m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_Tentpole)
		{
			m_kNarrativeMgr.EndCurrentConversation();
		}
		else
		{
			m_kNarrativeMgr.NextDialogueLine();
		}
	}

	return true; 
}


simulated public function RefreshMouseState()
{
	if( Movie != none && Movie.IsMouseActive() )
		AS_UseMouseNavigation();
	else
		AS_UseControllerNavigation();
}



simulated public function Show()
{
	super.Show();
	UpdateDisplay();
}


//==============================================================================
//  FLASH
//==============================================================================

simulated function AS_SetTitle(string DisplayText)
{ Movie.ActionScriptVoid(MCPath$".SetTitle"); }

simulated function AS_SetText(string DisplayText)
{ Movie.ActionScriptVoid(MCPath$".SetText"); }

simulated function AS_SetType(int iType)
{ Movie.ActionScriptVoid(MCPath$".SetType"); }

simulated function AS_SetPortrait(string strPortrait)
{ Movie.ActionScriptVoid(MCPath$".SetPortrait"); }

simulated function AS_SetMouseNavigationText(string str0, string str1)
{ Movie.ActionScriptVoid(MCPath$".SetMouseNavigationText"); }

simulated function AS_SetHelp(int index, string displayString, string icon)
{ Movie.ActionScriptVoid(MCPath$".SetHelp"); }

simulated public function AS_UseMouseNavigation()
{ Movie.ActionScriptVoid(MCPath$".UseMouseNavigation"); }

simulated public function AS_UseControllerNavigation()
{ Movie.ActionScriptVoid(MCPath$".UseControllerNavigation"); }



//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxNarrativePopup/NarrativePopup";
	MCName  = "theNarrativePopup";
	
	InputState = eInputState_Consume; 
	bIsModal = true;

	DisplayTag = "DropshipScreen";

	// Flash-side starts in a hidden state.
	bIsVisible = false;
}
