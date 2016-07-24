//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadEditor_RankedGame.uc
//  AUTHOR:  Todd Smith  --  6/30/2015
//  PURPOSE: This file is used for the following stuff..blah
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadEditor_RankedGame extends UIMPShell_SquadEditor;

function DoReady()
{
	m_kMPShellManager.OnlineGame_DoRankedGame();
}

defaultproperties
{
	TEMP_strSreenNameText="Ranked Game Squad Editor"
}