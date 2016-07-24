//---------------------------------------------------------------------------------------
//  FILE:    X2Action_ATT.uc
//  AUTHOR:  Dan Kaplan  --  4/28/2015
//  PURPOSE: Starts and controls the ATT sequence when dropping off reinforcements
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_ATT extends X2Action_PlayMatinee config(GameData);

var const config string MatineeCommentPrefix;
var const config int NumDropSlots;

var private array<StateObjectReference> MatineeUnitRefs;

function Init(const out VisualizationTrack InTrack)
{
	// need to find the matinee before calling super, which will init it
	FindATTMatinee();

	super.Init(InTrack);

	AddUnitsToMatinee(StateChangeContext);

	SetMatineeBase('CIN_Advent_Base');
	SetMatineeLocation(XComGameState_AIReinforcementSpawner(InTrack.StateObject_NewState).SpawnInfo.SpawnLocation);
}

private function AddUnitsToMatinee(XComGameStateContext InContext)
{
	local XComGameState_Unit GameStateUnit;
	local int UnitIndex;
	local bool IsMec;

	UnitIndex = 1;

	foreach InContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
	{
		IsMec = GameStateUnit.GetMyTemplate().CharacterGroupName == 'AdventMEC';
		AddUnitToMatinee(name("Mec" $ UnitIndex), IsMec ? GameStateUnit : none);
		AddUnitToMatinee(name("Advent" $ UnitIndex), (!IsMec) ? GameStateUnit : none);
	
		UnitIndex++;

		MatineeUnitRefs.AddItem(GameStateUnit.GetReference());
	}

	while(UnitIndex < NumDropSlots)
	{
		AddUnitToMatinee(name("Mec" $ UnitIndex), none);
		AddUnitToMatinee(name("Advent" $ UnitIndex), none);
		UnitIndex++;
	}
}

//We never time out
function bool IsTimedOut()
{
	return false;
}

private function FindATTMatinee()
{
	local array<SequenceObject> FoundMatinees;
	local SeqAct_Interp Matinee;
	local Sequence GameSeq;
	local int Index;

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, FoundMatinees);
	FoundMatinees.RandomizeOrder();

	for (Index = 0; Index < FoundMatinees.length; Index++)
	{
		Matinee = SeqAct_Interp(FoundMatinees[Index]);
		`log("Matinee:"@ Matinee.ObjComment);
		if( Instr(Matinee.ObjComment, MatineeCommentPrefix, , true) >= 0 )
		{
			Matinees.AddItem(Matinee);
			return;
		}
	}

	`Redscreen("Could not find the ATT matinee!");
	Matinee = none;
}

simulated state Executing
{
	simulated event BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);
		
		`BATTLE.SetFOW(false);
	}

	simulated event EndState(name NextStateName)
	{
		local int i;
		local StateObjectReference UnitRef;

		super.EndState(NextStateName);

		// Send intertrack messages
		for (i = 0; i < MatineeUnitRefs.Length; ++i )
		{
			UnitRef = MatineeUnitRefs[i];
			VisualizationMgr.SendInterTrackMessage( UnitRef );
		}

		`BATTLE.SetFOW(true);
	}
}


DefaultProperties
{
}
