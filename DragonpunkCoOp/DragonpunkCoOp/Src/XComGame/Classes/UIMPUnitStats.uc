//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPUnitStats.uc
//  AUTHOR:  sbatista - 10/21/15
//  PURPOSE: A popup with unit's statistics and abilities that is shown during MP Squad Selection
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPUnitStats extends UIScreen;

var UISoldierHeader SoldierHeader;
var UINavigationHelp NavHelp;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	SoldierHeader = Spawn(class'UISoldierHeader', self).InitSoldierHeader();
	NavHelp = Movie.Pres.GetNavHelp();
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(CloseScreen);
}

simulated function UpdateData(XComGameState_Unit Unit, XComGameState CheckGameState)
{
	local X2MPCharacterTemplate CharacterTemplate;

	SoldierHeader.PopulateData(Unit, , , CheckGameState);
	class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, Unit, true, CheckGameState);

	CharacterTemplate = Unit.GetMPCharacterTemplate();
	MC.FunctionString("setUnitDescription", CharacterTemplate.DisplayDescription);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{	
	// Only pay attention to presses or repeats; ignoring other input types
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch( cmd )
	{
		// Back out
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:	
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
		default:
			break;
	}

	return true; // consume all input
}

simulated function CloseScreen()
{
	super.CloseScreen();
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}


//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxArmory/Armory";
	LibID = "MultiplayerUnitStats";
	InputState = eInputState_Consume; 
	bConsumeMouseEvents = true;
}
