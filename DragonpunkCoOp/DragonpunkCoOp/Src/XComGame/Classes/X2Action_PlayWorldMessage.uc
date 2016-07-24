//---------------------------------------------------------------------------------------
//  FILE:    X2Action_PlayWorldMessage.uc
//  AUTHOR:  Dan Kaplan
//  DATE:    6/8/2015
//  PURPOSE: Visualization for scrolling world messages.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_PlayWorldMessage extends X2Action;

struct MessageData
{
	var() string Message;
	var() string IconPath;
};

var array<MessageData> WorldMessages;

function AddWorldMessage(string Message, string IconPath = "")
{
	local MessageData NewMessage;

	NewMessage.Message = Message;
	NewMessage.IconPath = IconPath;

	WorldMessages.AddItem(NewMessage);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function PlayAllMessages()
	{
		local int Index;
		local XComPresentationLayer Presentation;

		Presentation = `PRES;

		for( Index = 0; Index < WorldMessages.Length; ++Index )
		{
			Presentation.Notify(WorldMessages[Index].Message, WorldMessages[Index].IconPath);
		}
	}
Begin:
	PlayAllMessages();

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

defaultproperties
{
}

