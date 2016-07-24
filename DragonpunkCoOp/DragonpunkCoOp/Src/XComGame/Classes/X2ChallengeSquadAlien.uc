//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSquadAlien.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSquadAlien extends X2ChallengeTemplate;

var array<WeightedTemplate> WeightedAlienTypes;
var delegate<SquadAlienSelector> SelectSquadAliensFn;

delegate array<name> SquadAlienSelector( X2ChallengeSquadAlien Selector, int count );

static function array<name> WeightedTypeSelected( X2ChallengeSquadAlien Selector, int count )
{
	local array<name> AlienTypes;
	local int x;

	for( x = 0; x < count; ++x )
	{
		AlienTypes.AddItem( GetRandomTemplate( Selector.WeightedAlienTypes ) );
	}

	return AlienTypes;
}

static function array<name> SelectAlienTypes( X2ChallengeSquadAlien Selector, int count )
{
	return Selector.SelectSquadAliensFn( Selector, count );
}

defaultproperties
{
	SelectSquadAliensFn = WeightedTypeSelected;
}