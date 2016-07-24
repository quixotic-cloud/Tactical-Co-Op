//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeTemplate.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeTemplate extends X2DataTemplate;

var int Weight; // Randomization weight vs other challenge templates of the same type

struct WeightedTemplate
{
	var int weight;
	var name templatename;
};

static function name GetRandomTemplate( array<WeightedTemplate> Templates )
{
	local WeightedTemplate Entry;
	local int TotalWeight;
	local int RandomWeight;

	TotalWeight = 0;
	foreach Templates( Entry )
	{
		TotalWeight += Entry.weight;
	}

	RandomWeight = `SYNC_RAND_STATIC(TotalWeight);

	foreach Templates( Entry )
	{
		if (RandomWeight < Entry.weight)
		{
			return Entry.templatename;
		}

		RandomWeight -= Entry.weight;
	}
}

defaultproperties
{
	Weight = 1
}