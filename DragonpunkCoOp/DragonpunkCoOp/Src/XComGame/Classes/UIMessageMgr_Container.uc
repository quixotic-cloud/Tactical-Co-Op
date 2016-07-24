//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMessageMgr_VerticalContainer
//  AUTHOR:  Brit Steiner  --  02/27/09
//  PURPOSE: This file controls the popup message box UI element. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMessageMgr_Container extends UIPanel
	dependson(UIMessageMgr);


var int idCounter; //Used to generate new id names for generic Messages
var array<UI_FxsMessageBox> Messages;

//==============================================================================
// 		GENERAL FUNCTIONS:
//==============================================================================

simulated function UIMessageMgr_Container InitMessageContainer()
{
	InitPanel();
	return self;
}

simulated function Message( string    _sMsg, 
							EUIIcon   _iIcon   = eIcon_GenericCircle, 
							EUIPulse  _iPulse  = ePulse_None, 
							float     _fTime   = 2.0,
							string    _id      = "default" )
{

	local UI_FxsMessageBox newMessage;
	//`log("+++++++++++++++++++++++++  Container creating new message using screen:" @ screen,true,'uixcom');

	//TODO: Cache the message if the manager is not initted

	newMessage = Spawn( class'UI_FxsMessageBox', self);
	if( _id != "default")
	{
		++idCounter;
		newMessage.Init( _id );
	}
	else
	{
		newMessage.Init( "messageBox" $ (++idCounter));
	}

	newMessage.SetTitle( _sMsg );
	newMessage.LoadIcon( _iIcon );
	newMessage.SetPulse( _iPulse );

	if(_fTime <= 0.0 && _fTime != -1 )  //-1 allows infinite placeent.
	{
		`warn("UI message time is " @ _fTime $"; when less than 0 it will persist and leak."
			@"Resetting to 10 seconds. msg: '" $ _sMsg $ "'");
		_fTime = 10.0;
	}
	newMessage.SetTime( _fTime );
	
	CreateMessageBox( newMessage );
	Messages.AddItem( newMessage );
}


simulated function CreateMessageBox(UI_FxsMessageBox kMessageBox)
{	
	MC.BeginFunctionOp("CreateMessageBoxDefined");

	MC.QueueString(string(kMessageBox.MCName));
	MC.QueueString(kMessageBox.GetTitle());
	MC.QueueNumber(kMessageBox.GetIcon());
	MC.QueueNumber(kMessageBox.GetPulse());

	MC.EndOp();
}

public function UI_FxsMessageBox GetMessage(name id)
{
	local UI_FxsMessageBox msg;
	foreach Messages(msg)
	{
		if(msg.MCName == id)
			return msg;
	}
	return none;
}

public function RemoveMessageFromList(UI_FxsMessageBox targetMessage)
{
	Messages.RemoveItem(targetMessage);
}

public function RemoveMessage(UI_FxsMessageBox targetMessage)
{
	targetMessage.AnimateOut();
}
//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	idCounter   = -1;
	LibID       = "MessageVerticalContainer";
}
