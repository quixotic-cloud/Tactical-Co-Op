//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComGameViewportClient extends GameViewportClient
	native;

cpptext
{
	virtual UBOOL InputKey(FViewport* Viewport,INT ControllerId,FName Key,EInputEvent EventType,FLOAT AmountDepressed=1.f,UBOOL bGamepad=FALSE);
	virtual UBOOL InputAxis(FViewport* Viewport,INT ControllerId,FName Key,FLOAT Delta,FLOAT DeltaTime, UBOOL bGamepad=FALSE);
}

event bool Init(out string OutError)
{
	if(!Super.Init(OutError))
	{
		return false;
	}
	
	return true;
}

/** handler for global state messages, generally network connection related (failures, download progress, etc) */
event SetProgressMessage(EProgressMessageType MessageType, string Message, optional string Title, optional bool bIgnoreFutureNetworkMessages)
{
	if (MessageType == PMT_Clear)
	{
		ClearProgressMessages();
	}
	else
	{
		if ( ! Outer.GamePlayers[0].Actor.bIgnoreNetworkMessages )
		{
			if (MessageType == PMT_ConnectionFailure || 
				MessageType == PMT_SocketFailure || 
				MessageType == PMT_PeerConnectionFailure || 
				MessageType == PMT_PeerHostMigrationFailure)
			{
				NotifyConnectionError(MessageType, Message, Title);
			}
			else if (MessageType == PMT_ConnectionProblem ||
					 MessageType == PMT_PeerConnectionProblem)
			{
				NotifyConnectionProblem();
			}
			else
			{
				if (Title != "")
				{
					ProgressMessage[0] = Title;
					ProgressMessage[1] = Message;
				}
				else
				{
					ProgressMessage[1] = "";
					ProgressMessage[0] = Message;
				}
			}
		}
	}
}

/**
 * Notifies the player that an attempt to connect to a remote server failed, or an existing connection was dropped.
 *
 * @param	Message		a description of why the connection was lost
 * @param	Title		the title to use in the connection failure message.
 */
function NotifyConnectionError(EProgressMessageType MessageType, optional string Message=Localize("Errors", "ConnectionFailed", "Engine"), optional string Title=Localize("Errors", "ConnectionFailed_Title", "Engine") )
{
	local XComPlayerController kPC;
	local WorldInfo WI;

	WI = GetCurrentWorldInfo();

	if (!WI.GetALocalPlayerController().bIgnoreNetworkMessages)
	{
		XComPlayerController(WI.GetALocalPlayerController()).Pres.GetMessenger().Message(Message);

		foreach WI.LocalPlayerControllers(class'XComPlayerController', kPC)
		{
			kPC.NotifyConnectionError(MessageType, Message, Title);
		}
	}
}

/**
 * Notifies the player that there is a problem with the current connection.
 */
function NotifyConnectionProblem()
{
	local XComOnlineEventMgr EventMgr;
	EventMgr = `ONLINEEVENTMGR;

	EventMgr.NotifyConnectionProblem();
}

DefaultProperties
{

}
