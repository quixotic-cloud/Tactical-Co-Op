//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_LookAtActor_AIReveal.uc
//  AUTHOR:  Ryan McFall  --  3/5/2014
//  PURPOSE: A higher priority look at location camera.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_LookAtActor_AIReveal extends X2Camera_LookAtActorTimed;

defaultproperties
{
	Priority=eCameraPriority_GameActions
}