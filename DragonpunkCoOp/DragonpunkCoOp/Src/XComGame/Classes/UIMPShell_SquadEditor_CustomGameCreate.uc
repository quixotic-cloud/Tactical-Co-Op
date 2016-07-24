//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadEditor_CustomGameCreate.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Squad Editor Screen for creating a custom game.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadEditor_CustomGameCreate extends UIMPShell_SquadEditor;

defaultproperties
{
	UINextScreenClass=class'UIMPShell_CustomGameCreateMenu'

	TEMP_strSreenNameText="Custom Game Create Squad Editor"
}