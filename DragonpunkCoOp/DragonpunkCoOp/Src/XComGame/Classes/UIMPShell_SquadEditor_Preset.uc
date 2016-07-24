//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadEditor_Preset.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Squad Editor Screen for offline editing
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadEditor_Preset extends UIMPShell_SquadEditor;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	m_MissionInfo.Hide();
}

defaultproperties
{
//	TEMP_strSreenNameText="Preset Squad Editor"
}