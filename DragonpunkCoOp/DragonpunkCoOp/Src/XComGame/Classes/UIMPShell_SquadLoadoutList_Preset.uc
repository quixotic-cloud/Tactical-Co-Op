//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadLoadoutList_Preset.uc
//  AUTHOR:  Todd Smith  --  7/2/2015
//  PURPOSE: Squad loadout list for editing presets
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadLoadoutList_Preset extends UIMPShell_SquadLoadoutList;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_kMPShellManager.OnlineGame_SetIsRanked(false);
	m_kMPShellManager.OnlineGame_SetAutomatch(false);

	m_kMPShellManager.OnlineGame_SetMaxSquadCost(-1);
}

defaultproperties
{
	UISquadEditorClass=class'UIMPShell_SquadEditor_Preset'

	TEMP_strSreenNameText="Preset Squad Loadout List"
}