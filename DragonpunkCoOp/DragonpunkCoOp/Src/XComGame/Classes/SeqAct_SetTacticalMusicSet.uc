//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SetTacticalMusicSet.uc
//  AUTHOR:  David Burchanowski  --  3/31/2016
//  PURPOSE: Allows Kismet to override the mission music
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_SetTacticalMusicSet extends SequenceAction;

var name TacticalMusicOverride;
var string TacticalMusicOverrideString; // This is duplicated to prevent recooking maps that already use this sequence action.

event Activated()
{
	local XComTacticalCheatManager CheatsManager;

	if(TacticalMusicOverrideString != "")
	{
		TacticalMusicOverride = name(TacticalMusicOverrideString);
	}

	if(TacticalMusicOverride == '')
	{
		`Redscreen(self $ " specified no music set!");
	}
	else
	{
		CheatsManager = `CHEATMGR;
		CheatsManager.OverrideTacticalMusicSet(TacticalMusicOverride);
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory = "Audio"
	ObjName = "Set Tactical Music Set"

	bConvertedForReplaySystem = true
	bCanBeUsedForGameplaySequence = true

	bAutoActivateOutputLinks = true

	VariableLinks(0)=(ExpectedType = class'SeqVar_String', LinkDesc = "Music Set", PropertyName = TacticalMusicOverrideString)
}
