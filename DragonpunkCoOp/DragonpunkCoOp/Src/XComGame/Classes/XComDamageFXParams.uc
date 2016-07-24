//---------------------------------------------------------------------------------------
//  FILE:    XComWeaponFXParams.uc
//  AUTHOR:  Jeremy Shopf 4/2/14
//  PURPOSE: This object contains a set of definitions that maps damage types to 
//				a set of information used when spawning destruction effects.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComDamageFXParams extends Object
	native(Level);

struct native PerDamageFXParams
{
	/**Select the damage type that the specified particle systems will be associated with */
	var() name EffectDamageTypeName<DynamicList = "DamageTypeList">;

	var() editinline LinearColor  Core_Color;
	var() editinline LinearColor  Mid_Color;
	var() editinline LinearColor  Outer_Color;

	structdefaultproperties
	{		
		EffectDamageTypeName = "Explosion"
	}
};

cpptext
{
public:
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);
}

var() array<PerDamageFXParams> DmgFXData;