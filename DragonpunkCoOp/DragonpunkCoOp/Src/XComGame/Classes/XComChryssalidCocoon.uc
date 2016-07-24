//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComChryssalidCocoon extends XComAlienPawn;

var Array<AnimSet> OriginalUnitPawnAnimSets;

simulated exec function UpdateAnimations()
{
	super.UpdateAnimations();

	if( OriginalUnitPawnAnimSets.Length > 0 )
	{
		XComAddAnimSetsExternal(OriginalUnitPawnAnimSets);
	}
}