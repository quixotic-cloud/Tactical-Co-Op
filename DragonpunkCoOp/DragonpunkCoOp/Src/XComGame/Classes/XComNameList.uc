//---------------------------------------------------------------------------------------
//  FILE:    XComNameList.uc
//  AUTHOR:  Ryan McFall  --  3/3/2015
//  PURPOSE: Replaces enums in situations where a list of IDs or names needs to be 
//			 extended without modifying base game code or data. Extends the basic
//			 name list by being able to add in names from config files
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComNameList extends NameList native(Core) config(GameCore);

var private config array<name> NameListConfig;

event OnEngineInit() 
{
	local int Index;
	
	//Add the config names into the general name list
	for (Index = 0; Index < NameListConfig.Length; ++Index)
	{
		NameList.AddItem(NameListConfig[Index]);
	}
}

defaultproperties
{
}
