//---------------------------------------------------------------------------------------
//  FILE:    XComParticleModuleEvent_SpawnDebrid.uc
//  AUTHOR:  Scott Boeckmann  --  01/28/2014
//  PURPOSE: This object is used with Unreal's particle event system - which allows users
//           to associated particle events ( such as particle deaths ) to trigger actions
//           in the game via event objects that extend ParticleModuleEventSendToGame.
//
//           This event will create a debris mesh to spawn in the game world.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParticleModuleEvent_SpawnDebris extends ParticleModuleEventSendToGame	
	hidecategories(Object);

var() DebrisMeshCollection    DebrisMeshes;

struct DebrisStrength
{
	var() float             Minimum;
	var() float             Maximum;

	structdefaultproperties
	{
		Minimum=0.10
		Maximum=0.25
	}
};

var() DebrisStrength        DebrisValue;
var() float                 DebrisSpawnDelay;

function DoEvent( ParticleEventManager EventMgr, ParticleSystemComponent InComp, const out vector InCollideDirection, const out vector InHitLocation, const out vector InHitNormal, const out name InBoneName )
{
	if( DebrisMeshes.m_DebrisMeshes.Length > 0 )
	{
		`BATTLE.WorldInfo.MyDebrisManager.SpawnDebris(InComp, DebrisMeshes, InHitLocation, Lerp(DebrisValue.Minimum, DebrisValue.Maximum, FRand()), DebrisSpawnDelay);
	}
}

defaultproperties
{
	DebrisSpawnDelay=0.1
}