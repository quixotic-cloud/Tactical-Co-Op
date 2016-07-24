//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_LookAtEnemyHead.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Special lookat camera for looking at enemy heads on the ability hud. Shows
//           shader on targeted unit and centers perfectly
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_LookAtEnemyHead extends X2Camera_LookAtActor;

function bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	return Unit == ActorToFollow;
}

defaultproperties
{
	Priority=eCameraPriority_EnemyHeadLookat
	UseTether=false // center on the thing we are looking at
}