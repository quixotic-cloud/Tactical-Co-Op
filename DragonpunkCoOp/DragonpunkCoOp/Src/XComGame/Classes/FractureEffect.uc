//---------------------------------------------------------------------------------------
//  FILE:    FractureEffect.uc
//  AUTHOR:  Jeremy Shopf 5/6/14 - Happy Birthday Nolan!
//  PURPOSE: This object defines information necessary to spawn an effect related to
//              fracture chunk removal.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class FractureEffect extends Object
	native(Level)
    editinlinenew;


enum EMatInheritanceType
{
	eMaterialID0,
	eMaterialID1,
	eNoParent
};

/** Particle systems to spawn */
var() instanced EffectCue EffectCue;

/** Instance parameters to pass to the particle system */
var() EmitterInstanceParameterSet InstanceParameters;

/** Which material on the frac mesh should this effect's MIC inherit parameters from ? */
var() EMatInheritanceType MaterialParent;

defaultproperties
{
	MaterialParent=eMaterialID0;
}