//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIRedScreen.uc
//  AUTHOR:  Ned Way
//
//  PURPOSE: Pain upon error, oh ye fallible ones
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIRedScreen extends UIScreen native(UI) config(UI);

var config bool bPauseOnRedscreen;
var config bool bHide2dUIOnRedscreen;

var private XComPresentationLayerBase Pres;
var private bool b2DUIVisible;
var private string m_strErrorMsg;
var private array<string> RedscreenLines;
var private int MaxRedscreenLinesPerScreen;
var private int RedcreenShowOffset;

delegate OnClosedDelegate();

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);

	if(bPauseOnRedscreen)
	{
		PC.SetPause(true);
	}

	Pres = PC.Pres;
	if(bHide2dUIOnRedscreen && Pres.Get2DMovie().bIsVisible)
	{
		b2DUIVisible = true;
		Pres.Get2DMovie().Hide();
	}

	AddHUDOverlayActor();
}
// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();
	Movie.InsertHighestDepthScreen(self);
}

// Used in navigation stack
simulated function OnRemoved()
{
	super.OnRemoved();

	RemoveHUDOverlayActor();

	if(bHide2dUIOnRedscreen && b2DUIVisible)
	{		 
		Pres.Get2DMovie().Show();
	}

	if(bPauseOnRedscreen)
	{
		PC.SetPause(false);
	}

	if( OnClosedDelegate != none )
		OnClosedDelegate();

}

simulated function SetErrorText( string ErrorMsg )
{
	m_strErrorMsg = ErrorMsg;
	RedscreenLines = SplitString(m_strErrorMsg, "\n");
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local Vector2D ViewportSize;
	local int Index;	
	local int RedscreenLinesY;	
	local float LineSizeX;
	local float LineSizeY;

	kCanvas.SetPos(0, 0);
	kCanvas.SetDrawColor(255, 0, 0, 140);	
	class'Engine'.static.GetEngine().GameViewport.GetViewportSize(ViewportSize);
	kCanvas.DrawRect(ViewportSize.X, ViewportSize.Y);

	kCanvas.SetPos((ViewportSize.X / 2.0) - 200, 10);
	kCanvas.SetDrawColor(255, 255, 255);
	kCanvas.DrawText("Redscreen Errors", false, 4.0f, 4.0f);

	RedscreenLinesY = 100;
	for(Index = RedcreenShowOffset; Index < (RedcreenShowOffset + MaxRedscreenLinesPerScreen) && Index < RedscreenLines.Length; ++Index)
	{
		kCanvas.SetPos(25, RedscreenLinesY);
		kCanvas.SetDrawColor(255, 255, 255);
		kCanvas.DrawText(RedscreenLines[Index], true, 1.0f, 1.0f);
		kCanvas.TextSize(RedscreenLines[Index], LineSizeX, LineSizeY);

		if(LineSizeX >= (ViewportSize.X - 25))
		{
			RedscreenLinesY += LineSizeY * 2.0f;
		}
		else
		{
			RedscreenLinesY += LineSizeY;
		}
	}

	kCanvas.SetPos(ViewportSize.X - 200, 10);
	kCanvas.SetDrawColor(255, 255, 255);
	kCanvas.DrawText("Press Esc/Enter/A/Start to continue...", true, 1.0f, 1.0f);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:	
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			RedcreenShowOffset += MaxRedscreenLinesPerScreen;
			if(RedcreenShowOffset >= RedscreenLines.Length)
			{
				CloseScreen();
			}
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

event ActivateEvent()
{
	PC.Pres.UIRedScreen();	
}

cpptext
{
	virtual UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType );
};

defaultproperties
{
	bAlwaysTick = true;
	InputState = eInputState_Consume;
	bShowDuringCinematic = true;	
	MaxRedscreenLinesPerScreen = 42;
}