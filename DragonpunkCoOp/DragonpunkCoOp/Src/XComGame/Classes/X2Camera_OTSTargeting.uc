//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_OverTheShoulder.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized over the shoulder camera for targeting so we can blend from it automatically without needing
//           really complex cinescript setups.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_OTSTargeting extends X2Camera_OverTheShoulder;

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	// hide loot. We want the rest of the 2D UI up
	XComTacticalController(`BATTLE.GetALocalPlayerController()).ShowLootVisuals(false);
}

function Deactivated()
{
	super.Deactivated();

	XComTacticalController(`BATTLE.GetALocalPlayerController()).ShowLootVisuals(true);
}

function bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	return Unit == TargetActor;
}

function bool ShowTargetingOutlines()
{
	return true;
}

function Removed()
{
	super.Removed();

	if (TargetActor != none)
	{
		if (XGUnit(TargetActor) != none)
		{
			if (XGUnit(TargetActor).GetPawn() != none)
			{
				XGUnit(TargetActor).GetPawn().UpdateAuxParameters(true);
			}
		}
	}
}

defaultproperties
{
	ShouldAlwaysShow=true
}