//---------------------------------------------------------------------------------------
 //  FILE:    UIDebugInfo.uc
 //  AUTHOR:  Brit Steiner --  3/2015
 //  PURPOSE: Debug container for tactical game 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UIDebugInfo extends UIScreen;

var public UITextContainer DebugTextField;
var public UIButton ClearButton; 
var privatewrite string DebugText; 
var private array<string> DebugTextArray;

const MAX_DEBUG_LINES = 20;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	DebugTextField = Spawn(class'UITextContainer', self);
	DebugTextField.InitTextContainer('', DebugText, 5, 25, 400, 200, true);
	DebugTextField.AnchorTopRight().SetX(-DebugTextField.Width); // Move in to the visual frame area. 

	ClearButton = Spawn(class'UIButton', self).InitButton('', "CLEAR DEBUG", OnClickedClearText);
	ClearButton.AnchorTopRight().SetX(-DebugTextField.Width); // Move in to the visual frame area. 

	Refresh(); 
}

private function Refresh()
{
	local int i;

	while (DebugTextArray.Length > MAX_DEBUG_LINES)
	{
		DebugTextArray.Remove(0, 1);
	}
	DebugText = "";
	for (i = DebugTextArray.Length - 1; i >= 0; --i)
	{
		DebugText $= "\n" $ DebugTextArray[i];
	}

	DebugTextField.SetHTMLText(DebugText);

	if( DebugText == "" )
	{
		DebugTextField.Hide();
		ClearButton.Hide();
	}
	else
	{
		DebugTextField.Show();
		ClearButton.Show();
	}
}

public function AddText(string NewInfo, optional bool bClearPrevious = false)
{
	if( bClearPrevious )
		ClearText();

	DebugTextArray.AddItem(NewInfo);

	Refresh();
}

public function ClearText()
{
	DebugTextArray.Length = 0;	
	Refresh();
}


function OnClickedClearText(UIButton Button)
{
	ClearText();
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	bAlwaysTick = true;
	InputState = eInputState_None;
	bShowDuringCinematic = true;
	DebugText = ""; 
}