//---------------------------------------------------------------------------------------
//  FILE:    XComSoundEmitter
//  AUTHOR:  Mark F. Domowicz -- 9/17/2015
//  PURPOSE: This is an actor used for playing positional sounds on.  This is needed
//           because positional audio with Wwise only works with Actors.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------


class XComSoundEmitter extends Actor native;

var float fTimeAlive;
var int iAssociatedGameStateObjectId;
var bool bIsPersistentSound;
var ParticleSystemComponent AssociatedParticleEffect;

event Tick( float DeltaTime )
{
	super.Tick( DeltaTime );

	fTimeAlive += DeltaTime;

	// Persistent sounds are externally managed, but One-offs are manually self-destroyed.
	if (fTimeAlive > 5.0f && !bIsPersistentSound)
		Destroy();

	if(AssociatedParticleEffect != none && 
	   (AssociatedParticleEffect.bWasDeactivated || AssociatedParticleEffect.bWasCompleted))
	{
		Destroy();
	}
}


DefaultProperties
{
	iAssociatedGameStateObjectId=0;
}