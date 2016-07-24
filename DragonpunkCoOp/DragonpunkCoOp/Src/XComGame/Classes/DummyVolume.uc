//---------------------------------------------------------------------------------------
//  FILE:    DummyVolume.uc
//  AUTHOR:  Scott Boeckmann  --  2/17/2015
//  PURPOSE: Placeable Volume that does nothing on its own and is placed in a special layer within a map
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class DummyVolume extends Volume
	placeable;

defaultproperties
{
	Layer=Lighting
}



