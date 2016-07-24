//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UIDropshipHUD extends UIScreen;

var bool bWaitingForInput;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	BuildButton_StartBattle();
}


function BuildButton_StartBattle()
{	
}

function NotifyDestinationLoaded()
{	
	bWaitingForInput = true;
}

// Flash screen is ready
simulated function OnInit()
{
	super.OnInit();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if(bWaitingForInput)
			{
				WorldInfo.bContinueToSeamlessTravelDestination = true;				
			}
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{	
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();	
	Show();
}
simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Hide();
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	bWaitingForInput = false;
	bShowDuringCinematic = true;
}
