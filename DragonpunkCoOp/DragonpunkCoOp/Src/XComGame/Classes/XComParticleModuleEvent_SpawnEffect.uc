//---------------------------------------------------------------------------------------
//  FILE:    XComParticleModuleEvent_SpawnEffect.uc
//  AUTHOR:  Ryan McFall  --  04/14/2010
//  PURPOSE: This object is used with Unreal's particle event system - which allows users
//           to associated particle events ( such as particle deaths ) to trigger actions
//           in the game via event objects that extend ParticleModuleEventSendToGame.
//
//           This event will create a particle emitter in the game world.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParticleModuleEvent_SpawnEffect extends ParticleModuleEventSendToGame;

var() editinline EffectCue Effect;
var() vector DefaultNormal<ToolTip="If the event does not create a normal ( ie. via collision ), then this normal will be used as the effect rotation.">;

function DoEvent( ParticleEventManager EventMgr, ParticleSystemComponent InComp, const out vector InCollideDirection, const out vector InHitLocation, const out vector InHitNormal, const out name InBoneName )
{
	class'EffectCue'.static.SpawnEffect( EventMgr.WorldInfo.MyEmitterPool, Effect, InHitLocation, Rotator(VSize(InHitNormal) > 0.0f ? -InHitNormal : DefaultNormal) );
}

defaultproperties
{
	DefaultNormal = (X=0.0,Y=0.0,Z=1.0)
}