//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIScreen.uc
//  AUTHOR:  Samuel Batista, Brit Steiner
//  PURPOSE: Base class for managing a SWF/GFx file that is loaded into the game.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIDistortionManager extends Object;

var XComPresentationLayerBase Pres;
var UIScreenStack ScreenStack;
var protected UIScreen CurrentScreen; 

var protectedwrite float CurrentDistortionTime;
var protectedwrite float IdleDistortionTarget;

//==============================================================================
//  INITIALIZATION
//==============================================================================

simulated function Update(float deltaTime)
{
	local UIScreen NewScreen; 
	local float IdleStrength;

	if( ScreenStack.bCinematicMode )
	{
		Pres.SetUIDistortionStrength(0);
		return;
	}

	NewScreen = ScreenStack.GetCurrentScreen();
	if( CurrentScreen != NewScreen )
	{
		CurrentDistortionTime = 0.0;
		CurrentScreen = NewScreen;
	}

	if(	  CurrentScreen == None 
	   || !CurrentScreen.bIsVisible
	   || !CurrentScreen.bIsFocused )
	{
		Pres.SetUIDistortionStrength(0);
		return;
	}
	
	// INTRO ===================================================
	if( CurrentScreen.bPlayAnimateInDistortion && CurrentDistortionTime < CurrentScreen.AnimateInDistortionTime )
	{
		CurrentDistortionTime += deltaTime;

		if( CurrentDistortionTime > CurrentScreen.AnimateInDistortionTime )
		{
			Pres.SetUIDistortionStrength(0);
		}
		else
		{
			// This will set the distortion down in a simple linear change as percent of the animation time that has passed. 
			Pres.SetUIDistortionStrength(1.0 - (CurrentDistortionTime / CurrentScreen.AnimateInDistortionTime));
		}
	}
	// IDLE ===================================================
	else if( CurrentScreen.bPlayIdleDistortion ) // only triggers after the animate in wraps up
	{
		CurrentDistortionTime += deltaTime;

		// IDLE RAMP UP ---------------------------------------
		if( CurrentDistortionTime >= IdleDistortionTarget + CurrentScreen.IdleDistortionAnimationLength )
		{
			//Generate next distortion idle target time 
			IdleDistortionTarget = CurrentDistortionTime + RandRange(CurrentScreen.IdleDistortionGapMin, CurrentScreen.IdleDistortionGapMax);
			Pres.SetUIDistortionStrength(0);
			//`log(" ---------- RESETING DISTORTION"@self @"curr: " @CurrentDistortionTime @" target: " @IdleDistortionTarget);
		}
		// IDLE RAMP DOWN ---------------------------------------
		else
		{
			if( CurrentDistortionTime > IdleDistortionTarget )
			{
				//Ramping up
				if( CurrentDistortionTime < IdleDistortionTarget + (CurrentScreen.IdleDistortionAnimationLength / 2) )
				{
					IdleStrength = 1.0 - (IdleDistortionTarget - CurrentDistortionTime) / (CurrentScreen.IdleDistortionAnimationLength / 2);
				}
				else //Ramping down
				{
					IdleStrength = ((IdleDistortionTarget - CurrentDistortionTime - (CurrentScreen.IdleDistortionAnimationLength / 2)) / (CurrentScreen.IdleDistortionAnimationLength / 2));
				}

				Pres.SetUIDistortionStrength(IdleStrength * CurrentScreen.MaxIdleStrength);

				//`log("DISTORTION "@self @"curr: " @CurrentDistortionTime @" target: " @IdleDistortionTarget @"IdleStrength: " @(IdleStrength * MaxIdleStrength) );
			}
		}
	}
	// NO ANIMATION ===================================================
	else
	{
		Pres.SetUIDistortionStrength(0);
	}
}


//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

defaultproperties
{
	CurrentDistortionTime = 0.0;
}
