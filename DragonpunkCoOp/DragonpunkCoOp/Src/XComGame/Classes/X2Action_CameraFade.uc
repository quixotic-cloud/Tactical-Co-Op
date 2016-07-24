//---------------------------------------------------------------------------------------
//  FILE:    X2Action_CameraFade.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Causes a camera fade
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Action_CameraFade extends X2Action;

// should we enable camera fades or turn them off
var bool EnableFade;

// Color to use as the fade 
var Color FadeColor;

// The opacity that the camera will fade to
var float FadeOpacity<ClampMin=0.0 | ClampMax=1.0>;

// How long to fade to FadeOpacity from the camera's current fade opacity
var float FadeTime<ClampMin=0.0>;

simulated state Executing
{
	function DoCameraFade()
	{
		local Vector2D FadeAlpha;
		local XComTacticalController LocalController;

		FadeAlpha.X = 0;
		FadeAlpha.Y = FadeOpacity;
		LocalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
		LocalController.ClientSetCameraFade(EnableFade, FadeColor, FadeAlpha, FadeTime);

		// need to show or hide the UI based on whether we are fading or not, since the fade doesn't cover
		// any UI
		if(FadeOpacity > 0.5) // fading
		{
			LocalController.SetCinematicMode(true, true, true, true, true, true);
		}
		else // not fading
		{
			LocalController.SetCinematicMode(false, true, true, true, true, true);
		}
	}

Begin:
	DoCameraFade();

	Sleep(FadeTime * GetDelayModifier());

	CompleteAction();
}

defaultproperties
{

}