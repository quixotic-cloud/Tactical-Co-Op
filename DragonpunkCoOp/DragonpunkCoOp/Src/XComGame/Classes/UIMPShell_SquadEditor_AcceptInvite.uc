//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadEditor_AcceptInvite.uc
//  AUTHOR:  Timothy Talley  --  12/02/2015
//  PURPOSE: Configures the Squad Editor to inform the user that they are at an invite acceptance stage.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadEditor_AcceptInvite extends UIMPShell_SquadEditor;

function ReadyButtonCallback()
{
	local XComOnlineEventMgr EventMgr;
	if(m_kSquadLoadout == none)
		return;

	`XPROFILESETTINGS.X2MPWriteTempLobbyLoadout(m_kSquadLoadout);
	m_kMPShellManager.SaveProfileSettings();

	EventMgr = `ONLINEEVENTMGR;
	EventMgr.TriggerAcceptedInvite();
}

defaultproperties
{
	UINextScreenClass=None

	TEMP_strSreenNameText="Accepting Invite Squad Editor"
}
