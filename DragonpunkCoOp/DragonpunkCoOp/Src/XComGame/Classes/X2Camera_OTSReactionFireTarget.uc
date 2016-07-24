//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_OTSReactionFireShooter.uc
//  AUTHOR:  Ryan McFall  --  7/8/2015
//  PURPOSE: Specialized over the shoulder camera for reaction fire
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_OTSReactionFireTarget extends X2Camera_OverTheShoulder;

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
	IgnoreSlomo=true
	ShouldAlwaysShow=true
}