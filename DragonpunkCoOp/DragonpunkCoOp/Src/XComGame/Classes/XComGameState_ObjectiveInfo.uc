//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ObjectiveInfo.uc
//  AUTHOR:  David Burchanowski  --  04/30/2014
//  PURPOSE: Component gamestate to be attached to tactical objective game states objects.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_ObjectiveInfo extends XComGameState_BaseObject
	native(Core);

// The mission this objective belongs to, by type.
var string MissionType;

// The OSP SpawnTag that this objective was spawned from, if a tag was specified on the OSP.
var string OSPSpawnTag;

DefaultProperties
{    
}
