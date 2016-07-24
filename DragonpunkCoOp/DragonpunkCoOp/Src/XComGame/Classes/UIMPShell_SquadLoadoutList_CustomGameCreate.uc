//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadLoadoutList_CustomGameCreate.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Squad loadout list for a custom game
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadLoadoutList_CustomGameCreate extends UIMPShell_SquadLoadoutList;

var UIButton EditSquadButton;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_kMPShellManager.OnlineGame_SetIsRanked(false);
	m_kMPShellManager.OnlineGame_SetAutomatch(false);
}

function EditSquadButtonCallback()
{
	if(!EditSquadButton.IsDisabled)
		CreateSquadEditor(m_kSquadLoadout);
}

function NextButton()
{
	if(m_kSquadLoadout == none)
		return;

	if(CanJoinGame())
	{
		`XPROFILESETTINGS.X2MPWriteTempLobbyLoadout(m_kSquadLoadout);
		m_kMPShellManager.SaveProfileSettings();
		m_kMPShellManager.OnlineGame_DoCustomGame();
	}
}

function EditSquadClickedButtonCallback(UIButton Button)
{
	EditSquadButtonCallback();
}

simulated function UpdateNavHelp()
{
	super.UpdateNavHelp();

	if(EditSquadButton == none)
	{
		EditSquadButton = IntegratedNavHelp.AddCenterButton(m_strEditSquad,, EditSquadButtonCallback, m_kSquadLoadout == none);
		EditSquadButton.OnClickedDelegate = EditSquadClickedButtonCallback;
		Navigator.AddControl(EditSquadButton);
	}

	 UpdateNavHelpState();
}

simulated function UpdateNavHelpState()
{
	super.UpdateNavHelpState();
	EditSquadButton.SetDisabled(m_kSquadLoadout == none);
}

defaultproperties
{
	UISquadEditorClass=class'UIMPShell_SquadEditor_Preset'

	TEMP_strSreenNameText="Custom Game Create Squad Loadout List"
}