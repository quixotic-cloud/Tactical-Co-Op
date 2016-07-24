//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ObjectivesList.uc
//  AUTHOR:  David Burchanowski  --  1/24/2014
//  PURPOSE: This object represents the state of the objectives list
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_ObjectivesList extends XComGameState_BaseObject
	dependson(X2StrategyGameRulesetDataStructures);

// since the counter does not have text, we have dedicated text indices for it
const CounterDisplayLabel = "CounterLabel"; 

/// <summary>
/// Contains a list of all objectives in the list
/// </summary>
var array<ObjectiveDisplayInfo> ObjectiveDisplayInfos; 

/// <summary>
/// Finds the index, if any, of the objective line that matches the parameters. If no such pip exists,
/// returns -1
/// </summary>
private function int GetObjectiveDisplayInfoIndex(string MissionType, string DisplayLabel)
{
	local int Index;

	for(Index = 0; Index < ObjectiveDisplayInfos.Length; Index++)
	{
		if(ObjectiveDisplayInfos[Index].MissionType == MissionType
			&& ObjectiveDisplayInfos[Index].DisplayLabel == DisplayLabel)
		{
			return Index;
		}
	}

	return -1;
}

/// <summary>
/// Finds the objective info that matches the given parameters, if any. If none found, returns false
/// </summary>
function bool GetObjectiveDisplay(string MissionType, string DisplayLabel, out ObjectiveDisplayInfo Result)
{
	local int Index;

	// if this objective is already being displayed, find it and modify
	Index = GetObjectiveDisplayInfoIndex(MissionType, DisplayLabel);

	if(Index >= 0)
	{
		Result = ObjectiveDisplayInfos[Index];
		return true;
	}
	else
	{
		return false;
	}
}

/// <summary>
/// Adds or updates the given objective display info.
/// </summary>
function SetObjectiveDisplay(const out ObjectiveDisplayInfo DisplayInfo)
{
	local int Index;

	// if this objective is already being displayed, find it and modify
	Index = GetObjectiveDisplayInfoIndex(DisplayInfo.MissionType, DisplayInfo.DisplayLabel);
	if(Index >= 0)
	{
		ObjectiveDisplayInfos[Index] = DisplayInfo;
	}
	else
	{
		// if we didn't find this objective (it's not being displayed), add it
		ObjectiveDisplayInfos.AddItem(DisplayInfo);
	}
}

/// <summary>
/// Removes the objective info that matches the parameters.
/// </summary>
function HideObjectiveDisplay(string MissionType, string DisplayLabel)
{
	local int Index;

	Index = GetObjectiveDisplayInfoIndex(MissionType, DisplayLabel);
	if(Index >= 0)
	{
		ObjectiveDisplayInfos.Remove(Index, 1);
	}
}

function ClearTacticalObjectives()
{
	local int Index;

	for( Index = ObjectiveDisplayInfos.Length - 1; Index >= 0; --Index )
	{
		if( !ObjectiveDisplayInfos[Index].GPObjective )
		{
			ObjectiveDisplayInfos.Remove(Index, 1);
		}
	}
}

function string ToString(optional bool bAllFields)
{
	return "Objectives List Game State";
}

DefaultProperties
{	
}
