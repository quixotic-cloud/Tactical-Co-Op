//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComFalconVolume
//  AUTHOR:  David Burchanowski
//  PURPOSE: Volume to limit where XCom soldiers are allowed to spawn into the map. James has promised me an
//           acronym that will make this class name make sense.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComFalconVolume extends Volume
	placeable;

defaultproperties
{
	BrushColor=(R=0,G=255,B=170,A=255)
	bColored=TRUE
}