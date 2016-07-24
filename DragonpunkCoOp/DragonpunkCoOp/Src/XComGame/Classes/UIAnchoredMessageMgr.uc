//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInfoBox
//  AUTHOR:  Brit Steiner  --  02/27/09
//  PURPOSE: This file controls the popup message box UI element. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIAnchoredMessageMgr extends UIMessageMgrBase;

enum EUIAnchor
{
	//corresponds to defined points in flash 
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	CENTER_LEFT,
	CENTER,
	CENTER_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
};
struct THUDAnchoredMsg
{
	var string              m_sId;
	var string              m_txtMsg;
	var float               m_fX;
	var float               m_fY;
	var bool                m_bVisible;
	var EUIAnchor           m_eAnchor;
	var EUIIcon             m_eIcon;
	var float               m_fTime;

	structdefaultproperties
	{
		m_txtMsg = "";
		m_fX = 0.1f;
		m_fY = 0.1f;
		m_eAnchor = TOP_LEFT;
		m_eIcon = eIcon_None;
		m_fTime = 5.0f;
	}
};

var int Counter;
var UIMessageMgr_Container m_MessageContainer;
var array<THUDAnchoredMsg> m_arrMsgs;


//==============================================================================
// 		GENERAL FUNCTIONS:
//==============================================================================

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	m_MessageContainer = Spawn(class'UIMessageMgr_Container', self).InitMessageContainer();
}

simulated function OnCommand(string cmd, string arg)
{
	if (cmd == "RemoveMessage") 
		RemoveMessageData( arg );
	else 
		`warn("Unhandled fscommand '" $ cmd $ "," $ arg $ "' sent to '" $ MCPath $ "'.",,'uicore' );
}

//Example calling in the presentaiton layer:
//GetAnchoredMessenger().Message("This is a test message to show a long string of text that will wrap around after a certain width.", 0.5f, 0.8f, BOTTOM_CENTER, 5.0f);

// Only call Message() for popups that will animate out on their own/ not persistant. 
// If you want the message to be persistent, you will need to as the UI team for access functions. 
simulated function Message( string    _sMsg, 
							float    _xLoc, 
							float    _yLoc,
							EUIAnchor _anchor,
							float     _displayTime = 5.0f,
							optional string    _sId = "",
							optional EUIIcon   _iIcon   = eIcon_None,
							optional ETeam _eBroadcastToTeams = eTeam_None)
{
	local THUDAnchoredMsg kMsg;
	local bool bDisplayMessage, bBroadcastMessage;
	local int ibDisplayMessage, ibBroadcastMessage;
	local XComUIBroadcastAnchoredMessage kBroadcastMessage;

	ShouldDisplayAndBroadcastMessage(
		ibDisplayMessage, 
		ibBroadcastMessage, 
		_eBroadcastToTeams, 
		`ShowVar(_sMsg) @
		`ShowVar(_xLoc) @
		`ShowVar(_yLoc) @
		`ShowVar(_anchor) @
		`ShowVar(_displayTime) @
		`ShowVar(_sId) @ 
		`ShowVar(_iIcon) @
		`ShowVar(_eBroadcastToTeams));

	// unrealscript is teh suck and doesnt allow 'out bool' parameters to function hence the int hacks -tsmith 
	bDisplayMessage = ibDisplayMessage > 0;
	bBroadcastMessage = ibBroadcastMessage > 0;

	if(bDisplayMessage)
	{
		if( _sId == "")
			kMsg.m_sId = "anchoredMessageBox" $Counter++;
		else
			kMsg.m_sId = _sId;
		
		kMsg.m_txtMsg   = _sMsg;
		kMsg.m_fX       = _xLoc;
		kMsg.m_fY       = _yLoc;
		kMsg.m_eAnchor  = _anchor;
		kMsg.m_fTime    = _displayTime;
		kMsg.m_eIcon    = _iIcon;

		if( m_arrMsgs.Find('m_sId', kMsg.m_sId)  > -1 )
		{
			`log( "Problem in" @screen $": trying to CREATE new message (id=" $kMsg.m_sId 
					$"), but that id already exists in the tracking array.",,'uixcom');
		}
		else
		{
			m_arrMsgs.AddItem( kMsg );
			CreateMessage( kMsg );
		}
	}
	if(bBroadcastMessage)
	{
		kBroadcastMessage = Spawn(class'XComUIBroadcastAnchoredMessage',,,,,,, _eBroadcastToTeams);
		kBroadcastMessage.Init(_sMsg, _xLoc, _yLoc, _anchor, _displayTime, _sId, _iIcon, _eBroadcastToTeams);
	}
}

simulated function CreateMessage(THUDAnchoredMsg kMsg)
{
	local Vector2D vScreenLocation;
	local ASValue myValue;
	local Array<ASValue> myArray;

	//`log("+++++++++++++++++++++++++  Creating new message using screen:" @ screen,true,'uixcom');

	//MC Name
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sId;
	myArray.AddItem( myValue );
	
	//Display string 
	myValue.s = kMsg.m_txtMsg;
	myArray.AddItem( myValue );
	
	vScreenLocation = Movie.ConvertNormalizedScreenCoordsToUICoords( kMsg.m_fX,  kMsg.m_fY);
	//X loc
	myValue.Type = AS_Number;
	myValue.n = vScreenLocation.X;
	myArray.AddItem( myValue );
	
	//Y loc
	myValue.Type = AS_Number;
	myValue.n = vScreenLocation.Y;
	myArray.AddItem( myValue );

	//Anchor
	myValue.Type = AS_Number;
	myValue.n = int(kMsg.m_eAnchor);
	myArray.AddItem( myValue );

	//Icon
	myValue.Type = AS_Number;
	myValue.n = int(kMsg.m_eIcon);
	myArray.AddItem( myValue );

	//Time
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_fTime;
	myArray.AddItem( myValue );

	Invoke("CreateAnchoredMessageBox", myArray); 

	if ( kMsg.m_eIcon == eIcon_Globe )
	{
		Movie.InsertHighestDepthScreen(self);
	}
}

simulated public function RemoveMessage( string strId )
{
	AS_RemoveMessageBox( strId );
	RemoveMessageData( strId );
}

simulated function AS_RemoveMessageBox( string strId )
{
	Movie.ActionScriptVoid(MCPath$".RemoveMessageBox");
}


//Show and Hide are special on the flash side: they will handle pausing/resuming all of the tweens automatically. 

simulated function Pause()
{
	Invoke("Pause");
}
simulated function Resume()
{
	Invoke("Resume");
}

simulated function Hide()
{
	super.Hide();
}

simulated function RemoveMessageData( string _id )
{
	local int Index;

	if ( Movie.HighestDepthScreens.Find(self) != INDEX_NONE )
		Movie.RemoveHighestDepthScreen(self);

	Index = m_arrMsgs.Find('m_sId', _Id);

	if( Index > -1 )
	{
		m_arrMsgs.Remove(Index, 1); 
	}
	else
	{
		`log( "Problem in" @screen $": trying to REMOVE a message (id=" $_id 
				$"), but that id weas not found in the tracking array.",,'uixcom');
	}
}


//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	MCName = "theAnchoredMessageContainer";
	Package = "/ package/gfxAnchoredMessageMgr/AnchoredMessageMgr";
	bShowDuringCinematic = true;
}
