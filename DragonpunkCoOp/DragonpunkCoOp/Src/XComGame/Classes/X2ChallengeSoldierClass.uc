//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSoldierClass.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSoldierClass extends X2ChallengeTemplate;

var array<WeightedTemplate> WeightedSoldierClasses;
var delegate<SoldierClassSelector> SelectSoldierClassesFn;

delegate array<name> SoldierClassSelector( X2ChallengeSoldierClass Selector, int count );

static function array<name> WeightedClassSelected( X2ChallengeSoldierClass Selector, int count )
{
	local array<name> SoldierClasses;
	local int x;

	for( x = 0; x < count; ++x )
	{
		SoldierClasses.AddItem( GetRandomTemplate( Selector.WeightedSoldierClasses ) );
	}

	return SoldierClasses;
}

static function array<name> SelectSoldierClasses( X2ChallengeSoldierClass Selector, int count )
{
	return Selector.SelectSoldierClassesFn( Selector, count );
}

defaultproperties
{
	SelectSoldierClassesFn = WeightedClassSelected;
}