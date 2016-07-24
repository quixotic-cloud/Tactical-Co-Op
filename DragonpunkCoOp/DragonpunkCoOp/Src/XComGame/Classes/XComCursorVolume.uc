//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComCursorVolume
//  AUTHOR:  David Burchanowski
//  PURPOSE: Volume for defining pathable cursor areas in the game.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComCursorVolume extends Volume
	placeable
	native;

var() const int m_iFloorNumber <ToolTip="The floor this volume belongs to, for purposes of the cursor. Need not line up with the floors of any other volume type.">;
var() const bool m_bTreatAsStair <ToolTip="Indicates that this is a "stair" volume. If the cursor gets within 5% of the top of a stair volume, it will automatically go up one floor.">;
var() const bool m_bIgnoreHoles <ToolTip="Prevents the cursor from autosnapping to a lower level. Useful for volumes with holes inthe roof.">;

DefaultProperties
{
	bWorldGeometry=false
	bCollideActors=true
	bBlockActors=false
	bMovable=false
}