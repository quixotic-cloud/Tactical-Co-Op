//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeElement.uc
//  AUTHOR:  Russell Aasland
//    
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeElement extends X2DataSet;


static function WeightedTemplate CreateEntry( name templatename, int weight )
{
	local WeightedTemplate Entry;

	Entry.templatename = templatename;
	Entry.weight = weight;

	return Entry;
}