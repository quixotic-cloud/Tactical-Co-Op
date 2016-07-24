//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadEditor_Quickmatch.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Squad editor for quickmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadEditor_Quickmatch extends UIMPShell_SquadEditor;

function DoReady()
{
	m_kMPShellManager.OnlineGame_DoAutomatchGame();
}

defaultproperties
{
	TEMP_strSreenNameText="Quickmatch Squad Editor"
}