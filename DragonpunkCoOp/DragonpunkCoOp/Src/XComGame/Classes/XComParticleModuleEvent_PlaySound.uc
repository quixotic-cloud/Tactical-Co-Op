//---------------------------------------------------------------------------------------
//  FILE:    XComParticleModuleEvent_PlaySound.uc
//  AUTHOR:  Ryan McFall  --  02/25/2011
//  PURPOSE: This object is used with Unreal's particle event system - which allows users
//           to associated particle events ( such as particle deaths ) to trigger actions
//           in the game via event objects that extend ParticleModuleEventSendToGame.
//
//           This event will start playing a sound in the game world
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParticleModuleEvent_PlaySound extends ParticleModuleEventSendToGame;

var() SoundCue Sound;

function DoEvent( ParticleEventManager EventMgr, ParticleSystemComponent InComp, const out vector InCollideDirection, const out vector InHitLocation, const out vector InHitNormal, const out name InBoneName )
{
	local XComSoundEmitter SoundEmitter;

	SoundEmitter = class'XComEngine'.static.FindSoundEmitterForParticleSystem(InComp);
	if( SoundEmitter == none )
	{
		SoundEmitter = class'WorldInfo'.static.GetWorldInfo().Spawn(class'XComSoundEmitter', , , InHitLocation);
	}
	
	SoundEmitter.AssociatedParticleEffect = InComp;
	SoundEmitter.bIsPersistentSound = true; //Base our life off of the particle system
	SoundEmitter.PlaySound(Sound, true, true, true, InHitLocation, true);
}

defaultproperties
{}