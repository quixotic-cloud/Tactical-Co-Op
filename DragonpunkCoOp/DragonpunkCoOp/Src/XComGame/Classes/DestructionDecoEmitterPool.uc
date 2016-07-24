//---------------------------------------------------------------------------------------
//  FILE:    DestructionDecoEmitterPool.uc
//  AUTHOR:  Jeremy Shopf 3/26/14
//  PURPOSE: An emitter pool specific to effects spawned from destruction Deco FX
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class DestructionDecoEmitterPool extends EmitterPool
	native(Level)
	transient;


native function FlushAllActive();

cpptext
{

}