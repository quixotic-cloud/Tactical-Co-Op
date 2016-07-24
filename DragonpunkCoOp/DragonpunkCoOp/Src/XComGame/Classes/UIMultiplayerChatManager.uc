//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMultiplayerHUD_ChatManager
//  AUTHOR:  Sam Batista
//  PURPOSE: Controls the chat panel for Multiplayer communications
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMultiplayerChatManager extends UIScreen;

const MY_MESSAGE_COLOR_HTML 	  = "B9FFFF"; // Hot Cyan
const OPPONENT_MESSAGE_COLOR_HTML = "EE1C25"; // Red

var bool m_bIsActive;
var bool m_bMuteChime;
var bool m_bMuteChat;

var XComGameStateNetworkManager NetworkMgr;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	XComInputBase(PC.PlayerInput).SetRawInputHandler(RawInputHandler);
	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddReceiveRemoteCommandDelegate(OnRemoteCommand);

	SubscribeToOnCleanupWorld();
}

simulated function OnInit()
{
	super.OnInit();
	CloseChat();
}

simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated function Cleanup()
{
	NetworkMgr.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	local string Sender, Message;
	if( Command ~= "ChatMsg" )
	{
		Sender = NetworkMgr.GetCommandParam_String(RawParams);
		Message = NetworkMgr.GetCommandParam_String(RawParams);
		AddMessage(Sender, Message, false);
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string callbackObj;

	if(cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		return;

	callbackObj = args[args.Length - 1];

	if(callbackObj == "tfInput")
		OnReceiveFocus();
	else if(callbackObj == "toggleLines")
		m_bMuteChat = !m_bMuteChat;
	else if(callbackObj == "toggleSound")
		m_bMuteChime = !m_bMuteChime;
}

simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(ucmd, arg))
		return false;

	// Consume all input if the user is actively inputting text
	if(m_bIsActive)
		return true;

	if(ucmd == class'UIUtilities_Input'.const.FXS_KEY_J)
	{
		OpenChat();
		return true;
	}

	return super.OnUnrealCommand(ucmd, arg);
}

simulated function bool RawInputHandler(Name Key, int ActionMask, bool bCtrl, bool bAlt, bool bShift)
{
	if( !m_bIsActive )
		return false;

	if(Key == 'Enter')
		OnAccept();
	else if(key == 'Escape' || Key == 'RightMouseButton')
		OnCancel();

	return true;
}

simulated function bool OnAccept(optional string arg = "") 
{
	local array<byte> Params;
	local string inputText;
	inputText = AS_GetInputText();

	if(Len(inputText) > 0)
	{
		NetworkMgr.AddCommandParam_String(PC.PlayerReplicationInfo.PlayerName, Params);
		NetworkMgr.AddCommandParam_String(inputText, Params);
		NetworkMgr.SendRemoteCommand("ChatMsg", Params);
		AddMessage(PC.PlayerReplicationInfo.PlayerName, inputText, true);
		if(!m_bMuteChime)
		{
			PlayAKEvent(AkEvent'SoundX2Multiplayer.MP_Chat_Send' );
		}
	}

	CloseChat();
	return true;
}
simulated function bool OnCancel(optional string arg = "")
{
	CloseChat();
	return true;
}

simulated function OpenChat()
{
	m_bIsActive = true;
	Invoke("ActivateChat");
	Show();
}
simulated function CloseChat()
{
	m_bIsActive = false;
	Invoke("DeactivateChat");
	if(m_bMuteChat)
		Hide();
}

simulated function AddMessage(string sender, string text, bool isFromLocalPlayer)
{
	local string finalText;
	
	finalText = "<font color='#"$ (isFromLocalPlayer ? MY_MESSAGE_COLOR_HTML : OPPONENT_MESSAGE_COLOR_HTML) $"'>"$sender$"</font>:";
	finalText @= SanitizeInputText(text);

	if(!m_bMuteChime && !isFromLocalPlayer)
	{
		PlayAKEvent(AkEvent'SoundX2Multiplayer.MP_Chat_Receive' );
	}

	AS_AppendText(finalText);
}

// This function prevents the message text from being interpreted as HTML code.
simulated function string SanitizeInputText(string txt)
{
	local string processedTxt;
	processedTxt = Repl(txt, "<", "&lt;");
	processedTxt = Repl(processedTxt, ">", "&gt;");
	return processedTxt;
}

simulated function GameEnded()
{
	Hide();
}

event Destroyed()
{
	Cleanup();
	super.Destroyed();
	XComInputBase(PC.PlayerInput).RemoveRawInputHandler(RawInputHandler);
}

//==============================================================================
// 		FLASH INTERFACE:
//==============================================================================

simulated function AS_AppendText(string txt) {
	Movie.ActionScriptVoid(MCPath$".AddText");
}
simulated function string AS_GetInputText() {
	return Movie.ActionScriptString(MCPath$".GetInputText");
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_bIsActive   = false;
	m_bMuteChime  = false;
	m_bMuteChat   = false;
	Package       = "/ package/gfxChat/Chat";
	bHideOnLoseFocus = false;
	bShowDuringCinematic = true;
	bProcessMouseEventsIfNotFocused=true;
}
