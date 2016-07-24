//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMessageMgrBase.uc
//  AUTHOR:  Todd Smith  --  4/14/2010
//  PURPOSE: Base class for the UIMessage Managers.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UIMessageMgrBase extends UIScreen
	native(UI)
	abstract;

// Valid flash icon states, their ints translate to frame number to display, so the order listed here does matter!
enum EUIIcon
{
							//frame-image number: 
	eIcon_None,             //0
	eIcon_XcomTurn,         //1
	eIcon_AlienTurn,        //2
	eIcon_QuestionMark,     //3
	eIcon_ExclamationMark,  //4
	eIcon_GenericCircle,    //5
	eIcon_Globe,           //6
};

function ShouldDisplayAndBroadcastMessage(out int ibDisplayMessage, out int ibBroadcastMessage, ETeam eBroadcastToTeams, string warnMessage)
{
	ibDisplayMessage = 0;
	ibBroadcastMessage = 0;
	if(WorldInfo.NetMode == NM_Standalone)
	{
		// its a non broadcasting message, clients can display it -tsmith 
		ibDisplayMessage = 1;
		ibBroadcastMessage = 0;
	}
	else if(WorldInfo.NetMode == NM_Client && eBroadcastToTeams == eTeam_None)
	{
		ibDisplayMessage = 1;
		ibBroadcastMessage = 0;
	}
	else if(WorldInfo.NetMode != NM_Client) 
	{
		// server -tsmith 
		ibBroadcastMessage = (eBroadcastToTeams != eTeam_None) ? 1 : 0;

		// broadcast to specific teams. if server and its servers team, display message -tsmith 
		if (eBroadcastToTeams == eTeam_None || PC.IsTeamFriendly(eBroadcastToTeams))
		{
			ibDisplayMessage = 1;
		}
	}
}

