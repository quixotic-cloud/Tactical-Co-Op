//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIAbilityPopup
//  AUTHOR:  Sam Batista
//  PURPOSE: Displays detailed descriptions for abilities.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIAbilityPopup extends UIScreen;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	UpdateNavHelp();
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	NavHelp = XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(CloseScreen);
}

simulated function InitAbilityPopup(X2AbilityTemplate AbilityTemplate)
{
	local string PopupText;

	PopupText = AbilityTemplate.LocPromotionPopupText;
	if(PopupText == "")
	{
		PopupText = "Missing 'LocPromotionPopupText' for " $ AbilityTemplate.DataName;
	}
	AS_UpdateData(AbilityTemplate.LocFriendlyName, AbilityTemplate.GetExpandedPromotionPopupText());
}

simulated function AS_UpdateData(string strTitle, string strDescription)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(strTitle);
	MC.QueueString(strDescription);
	MC.EndOp();
}

//==============================================================================

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			CloseScreen();
			break;
	}

	return true; // consume all input
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
}

simulated function OnRemoved()
{
	super.OnRemoved();
}

//==============================================================================

defaultproperties
{
	LibID = "AbilityInfoPopup";
	Package = "/ package/gfxArmory/Armory";
	InputState = eInputState_Evaluate;
	bAnimateOnInit = true;
}
