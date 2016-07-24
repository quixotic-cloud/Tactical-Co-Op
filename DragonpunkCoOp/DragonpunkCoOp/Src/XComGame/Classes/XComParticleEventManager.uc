//---------------------------------------------------------------------------------------
//  FILE:    XComParticleEventManager.uc
//  AUTHOR:  Ryan McFall  --  04/14/2010
//  PURPOSE: Traps and acts on events sent out by the particle system, such as particle 
//           collision events.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParticleEventManager extends ParticleEventManager;

event HandleParticleModuleEventSendToGame( ParticleModuleEventSendToGame InEvent, ParticleSystemComponent InComp, const out vector InCollideDirection, const out vector InHitLocation, const out vector InHitNormal, const out name InBoneName )
{
	if( InEvent != none )
		InEvent.DoEvent( self, InComp, InCollideDirection, InHitLocation, InHitNormal, InBoneName );
}

defaultproperties
{
}