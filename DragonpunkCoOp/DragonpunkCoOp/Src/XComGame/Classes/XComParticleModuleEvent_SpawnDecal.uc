//---------------------------------------------------------------------------------------
//  FILE:    XComParticleModuleEvent_SpawnDecal.uc
//  AUTHOR:  Ryan McFall  --  04/14/2010
//  PURPOSE: This object is used with Unreal's particle event system - which allows users
//           to associated particle events ( such as particle deaths ) to trigger actions
//           in the game via event objects that extend ParticleModuleEventSendToGame.
//
//           This event will create a decal in the game world.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParticleModuleEvent_SpawnDecal extends ParticleModuleEventSendToGame	
	hidecategories(Object);

var() editinline DecalCue Materials;
var() DecalProperties SpawnDecalProperties<ToolTip="Values to control the formation / appearence of the decal">;
var() vector DefaultNormal<ToolTip="If the event does not create a normal ( ie. via collision ), then this normal will be used to project the decal.">;

function DoEvent( ParticleEventManager EventMgr, ParticleSystemComponent InComp, const out vector InCollideDirection, const out vector InHitLocation, const out vector InHitNormal, const out name InBoneName )
{
	class'DecalCue'.static.SpawnDecalFromCue( EventMgr.WorldInfo.MyDecalManager, Materials, SpawnDecalProperties, 
											  (FRand() + 1) * class'DecalComponent'.Default.DepthBias, InHitLocation, 
											  Rotator(VSize(InHitNormal) > 0.0f ? -InHitNormal : DefaultNormal) );
}

defaultproperties
{
	DefaultNormal = (X=0.0,Y=0.0,Z=-1.0)
}