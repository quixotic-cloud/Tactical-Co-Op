//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_OTSReactionFireShooter.uc
//  AUTHOR:  David Burchanowski  --  7/8/2015
//  PURPOSE: Specialized over the shoulder camera for reaction fire
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_OTSReactionFireShooter extends X2Camera_OverTheShoulder;

function bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	return false;
}

function bool ShowTargetingOutlines()
{
	return false;
}

defaultproperties
{
	Priority = eCameraPriority_Cinematic
	IgnoreSlomo=true
	ShouldAlwaysShow=true
}