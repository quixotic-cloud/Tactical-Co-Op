//---------------------------------------------------------------------------------------
//  FILE:    XComParticleModuleEvent_RemoteEvent.uc
//  AUTHOR:  Ryan McFall  --  07/08/2015
//  PURPOSE: Lets the particle system generate remove events that can be listened for by
//			 kismet. Which sounds insane. But here we are.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParticleModuleEvent_RemoteEvent extends ParticleModuleEventSendToGame;

var() name RemoteEventName;

function DoEvent( ParticleEventManager EventMgr, ParticleSystemComponent InComp, const out vector InCollideDirection, const out vector InHitLocation, const out vector InHitNormal, const out name InBoneName )
{
	`XCOMGRI.DoRemoteEvent(RemoteEventName);	
}

defaultproperties
{}