//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_SquadSelect.uc
//  AUTHOR:  Timothy Talley  --  08/19/2014
//  PURPOSE: Simple context for containing all the units, items, etc. of a squad.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_SquadSelect extends XComGameStateContext;

var private XComGameState		NewGameState;
var int							iLoadoutId;
var bool						bEmpty;
var string						strLoadoutName;
var string						strLanguageCreatedWith;
var array<StateObjectReference> UnitToSquadLocationMap; // Converts the index of a location to a Unit's Object ID


// Public SquadSelect Interface
//=======================================================================================
function SetUnitAtLocation(int Index, StateObjectReference UnitRef)
{
	local int Diff;
	Diff = Index - UnitToSquadLocationMap.Length;
	if (Diff >= 0)
	{
		UnitToSquadLocationMap.Add(Diff+1);
	}
	UnitToSquadLocationMap[index] = UnitRef;
	bEmpty = false;
}

function XComGameState_Unit GetUnitAtLocation(int Index)
{
	if (Index >= 0 && Index < UnitToSquadLocationMap.Length)
	{
		return XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitToSquadLocationMap[Index].ObjectID));
	}
	`warn(`location @ "Invalid Location Index:" @ `ShowVar(Index));
	return none;
}

function int GetUnitCount()
{
	local int iCount, i;
	iCount = 0;
	for (i = 0; i < UnitToSquadLocationMap.Length; ++i)
	{
		if (UnitToSquadLocationMap[i].ObjectID > 0)
		{
			++iCount;
		}
	}
	return iCount;
}

function ClearSquad()
{
	local XComGameState_Item Item;
	local XComGameState_Unit Unit;

	foreach AssociatedState.IterateByClassType(class'XComGameState_Item', Item)
	{
		AssociatedState.PurgeGameStateForObjectID(Item.ObjectID);
	}

	foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		AssociatedState.PurgeGameStateForObjectID(Unit.ObjectID);
	}
	bEmpty = true;
}
//=======================================================================================


// External Interface for Creation
//=======================================================================================
static function XComGameStateContext_SquadSelect CreateEmptySquadSelect(int _iLoadoutId, optional bool _bEmpty, optional string _strLoadoutName, optional string _strLanguageCreatedWith)
{
	local XComGameStateContext_SquadSelect Container;
	Container = XComGameStateContext_SquadSelect(CreateXComGameStateContext());
	Container.iLoadoutId = _iLoadoutId;
	Container.bEmpty = _bEmpty;
	Container.strLoadoutName = _strLoadoutName;
	Container.strLanguageCreatedWith = _strLanguageCreatedWith;
	return Container;
}

static function XComGameState CreateSquadSelect(int _iLoadoutId, optional bool bCleanupPending=false, optional bool _bEmpty, optional string _strLoadoutName, optional string _strLanguageCreatedWith)
{
	local XComGameStateContext_SquadSelect Container;
	local XComGameState NewSquadState;
	Container = CreateEmptySquadSelect(_iLoadoutId, _bEmpty, _strLoadoutName, _strLanguageCreatedWith);
	NewSquadState = `XCOMHISTORY.CreateNewGameState(true, Container);
	if (bCleanupPending)
	{
		`XCOMHISTORY.CleanupPendingGameState(NewSquadState);
	}
	return NewSquadState;
}

static function XComGameState CopySquadSelect(int _iLoadoutId, XComGameStateContext_SquadSelect CopySquad, optional bool bCleanupPending=false, optional bool _bEmpty, optional string _strLoadoutName, optional string _strLanguageCreatedWith)
{
	local XComGameState NewSquadState, OldSquadState;

	OldSquadState = CopySquad.AssociatedState;
	if (OldSquadState != none)
	{
		NewSquadState = CreateSquadSelect(_iLoadoutId, bCleanupPending, _bEmpty, _strLoadoutName, _strLanguageCreatedWith);

		OldSquadState.CopyGameState(NewSquadState);
	}
	else
	{
		`warn( "XComGameStateContext_SquadSelect.CreateSquadSelect: Unable to copy squad select from a container without an associated state!" @ `ShowVar(CopySquad) @ `ShowVar(CopySquad.AssociatedState));
	}

	return NewSquadState;
}
//=======================================================================================


// GameState Interface
//=======================================================================================
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class isn't meant to be used with SubmitGameStateContext. Use plain vanilla SubmitGameState instead.
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
}

function string SummaryString()
{
	return "SquadSelect("$iLoadoutId$") - " @ strLoadoutName @ "["$strLanguageCreatedWith$"]";
}
//=======================================================================================


defaultproperties
{
	bEmpty=true
	strLoadoutName="Empty Squad"
}