//---------------------------------------------------------------------------------------
//  FILE:    X2Action_PlayMatinee.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Plays a matinee (or matinee) in a gamestate safe manner. Allows playing multiple 
//           matinees simultaneously, so that you can mix and max (or mod in) new character types 
//           (or even new slots for existing character types). All slots from all playing matinees
//           are available to AddUnitToMatinee().
//           Note that all matinees with the BaseMatineeComment set will be loaded with the base automatically,
//           so you can load them all with a single call to SelectMatineeByTag, even if
//           some were added by mods.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Action_PlayMatinee extends X2Action
	native(Core);

struct native UnitToMatineeGroupMapping
{
	var name GroupName; // matinee group that will control unit
	var XComGameState_Unit Unit; // a unit you want to show up in the matinee
	var bool WasUnitVisibile; // remember if the pawns we hid were visible or not before that
	var XComUnitPawnNativeBase CreatedPawn; // temporary pawn that will be used in the matinee 
	var Object ExistingMatineeObject; // object that was previously in the matinee map. Saved so we can put it back
};

struct native NonUnitToBaseMapping
{
	var Actor NonUnitActor;
	var Actor Base;
	var SkeletalMeshComponent SkelComp;
	var name AttachName;
};

cpptext
{
private:
	// builds a list of all variable links for each of the matinees in the Matinees array
	void GetAllMatineeVariableLinks(TArray<FSeqVarLink*>& AllLinks);
}

// handle to the matinee (and any auxillary matinees) we want to play. All of them will play simultaneously,
// the first one is considered the primary matinee
var array<SeqAct_Interp> Matinees;

// units that will participate in this matinee, and the matinee groups that will control them
var private array<UnitToMatineeGroupMapping> UnitMappings;

// used when rebasing the matinee seqvars actors, so that they can be unrebased.
var private array<NonUnitToBaseMapping> NonUnitMappings;

// matinees will be "based" on a specific actor in the world, allowing us to move the entire matinee
// just by moving the base. Each overlayed matinee will also have it's own base, so we need to be sure
// we move them all
var protected array<Actor> MatineeBases;

// socket in the base actor to use, if any
var protected name MatineeBaseSocket;

// location and rotation to move the matinee base to
var private Vector MatineeBaseLocation;
var private Rotator MatineeBaseRotation;

// In tactical missions, we use the camera stack matinee camera to actually control the camera during playback,
// instead of the build in unreal camera takeover. This allows us to manipulate all of the other gameplay things
// that need to happen, such as cinematic mode and fow disabling, for free.
var private X2Camera_Matinee MatineeCamera;

// Whether or not we should set the base on non units
var private bool bRebaseNonUnitVariables;

var protected bool MatineeSkipped; // set to true if the matinee is skipped by the user

// if true, units will remain hidden after the matinee finishes playing
var PostMatineeVisibility PostMatineeUnitVisibility;

// wrappers to native since the matinee interfaces require native access
native private function StartMatinee();
native private function bool UpdateMatinee(float DeltaTime);
native private function ShutdownMatinee();

// creates (if needed) and sets variable links for each of the unit mappings. 
native private function LinkUnitVariablesToMatinee();

// if a matinee base is set, rebases all non-unit links to use it
native private function RebaseNonUnitVariables();

// this reverses the operations done by RebaseNonUnitVariables()
native private function UnrebaseNonUnitVariables();

// restore the previous object links
native private function UnLinkUnitVariablesFromMatinee();

function AddUnitToMatinee(name GroupName, XComGameState_Unit GameStateUnit)
{
	local UnitToMatineeGroupMapping NewMapping;

	NewMapping.GroupName = GroupName;
	NewMapping.Unit = GameStateUnit;
	UnitMappings.AddItem(NewMapping);
}

function SetMatineeLocation(Vector NewLocation, optional Rotator NewRotation)
{
	MatineeBaseLocation = NewLocation;
	MatineeBaseRotation = NewRotation;
}

function SetMatineeBase(name MatineeBaseActorTag, optional name MatineeBaseSocketName = '')
{
	local SkeletalMeshActor PotentialBase;
	local Actor PotentialBaseNonSkel;

	if(MatineeBaseActorTag == '')
	{
		// no base specified, so just clear any previous one if there was one
		MatineeBases.Length = 0;
		return;
	}

	if(Matinees.Length == 0)
	{
		`Redscreen("Attempting to set Matinee Base but no Matinee has been set yet!");
		return;
	}

	if (MatineeBaseSocketName == '')
	{
		foreach AllActors(class'Actor', PotentialBaseNonSkel)
		{
			if (PotentialBaseNonSkel.Tag == MatineeBaseActorTag)
			{
				MatineeBases.AddItem(PotentialBaseNonSkel);
			}
		}
	}
	else
	{
		foreach AllActors(class'SkeletalMeshActor', PotentialBase)
		{
			if (PotentialBase.Tag == MatineeBaseActorTag)
			{
				MatineeBases.AddItem(PotentialBase);
			}
		}
	}

	if(MatineeBases.Length == 0)
	{
		`Redscreen("Could not find dropship intro base actor with tag: " $ string(MatineeBaseActorTag));
		return;
	}

	MatineeBaseSocket = MatineeBaseSocketName;
}

private function PrepareUnitsForMatinee()
{
	local XGUnit UnitVisualizer;
	local XComUnitPawn TacticalPawn;
	local XComUnitPawn MatineePawn;
	local int Index;
		
	for(Index = 0; Index < UnitMappings.Length; Index++)
	{
		if(UnitMappings[Index].Unit != none)
		{
			UnitVisualizer = XGUnit(UnitMappings[Index].Unit.GetVisualizer());
			`assert(UnitVisualizer != none);

			TacticalPawn = UnitVisualizer.GetPawn();
			`assert(TacticalPawn != none);

			TacticalPawn.m_bHiddenForMatinee = true;
			UnitMappings[Index].WasUnitVisibile = TacticalPawn.IsVisible();
			TacticalPawn.SetVisible(false);

			// create a temporary pawn for the matinee
			MatineePawn = UnitMappings[Index].Unit.CreatePawn(self, TacticalPawn.Location, TacticalPawn.Rotation);
			MatineePawn.CreateVisualInventoryAttachments(none, UnitMappings[Index].Unit, none, false);
			MatineePawn.ObjectID = -1;
			MatineePawn.SetupForMatinee(none, true, false);
			MatineePawn.StopTurning();
			MatineePawn.SetVisible(FALSE);

			UnitMappings[Index].CreatedPawn = MatineePawn;
		}
		else
		{
			UnitMappings[Index].CreatedPawn = none;
		}
	}
}

private function RemoveUnitsFromMatinee()
{
	local XGUnit UnitVisualizer;
	local int Index;

	for(Index = 0; Index < UnitMappings.Length; Index++)
	{
		// re-sync the unit visualizer to the location and state it should be in
		if(UnitMappings[Index].Unit != none)
		{
			UnitMappings[Index].Unit.SyncVisualizer();
			UnitVisualizer = XGUnit(UnitMappings[Index].Unit.GetVisualizer());
			UnitVisualizer.GetPawn().m_bHiddenForMatinee = false;

			// update the unit's visibility. Some matinees, for example spawns and level exits, may want to force
			// the gamestate units to be hidden or visible
			switch(PostMatineeUnitVisibility)
			{
			case PostMatineeVisibility_Visible:
				UnitVisualizer.SetVisible(true);
				break;

			case PostMatineeVisibility_Hidden:
				UnitVisualizer.SetVisible(false);
				break;

			default:
				UnitVisualizer.SetVisible(UnitMappings[Index].WasUnitVisibile);
			}

			// destroy the temporary pawn we created
			UnitMappings[Index].CreatedPawn.Destroy();
			UnitMappings[Index].CreatedPawn = none;
		}
	}
}

protected function PlayMatinee()
{
	local X2MatineeInfo MatineeInfo;
	local Actor MatineeBase;
	local SeqAct_Interp Matinee;

	// make sure we have a matinee to play
	if(Matinees.Length == 0)
	{
		`Redscreen("No matinee specified in X2Action_PlayMatinee!");
		return;
	}

	// move the matinee bases to the correct location
	if( MatineeBaseLocation != vect(0,0,0))
	{
		foreach MatineeBases(MatineeBase)
		{
		MatineeBase.SetLocation(MatineeBaseLocation);
		MatineeBase.SetRotation(MatineeBaseRotation);
	}
	}

	// update the timeout so that we can see the entire matinee
	MatineeInfo = new class'X2MatineeInfo';
	MatineeInfo.InitFromMatinee(Matinees[0]);
	TimeoutSeconds = ExecutingTime + MatineeInfo.GetMatineeDuration() + 5.0f; // timeout 5 seconds after the point where we think we should be finished

	// don't do any visibilty updates during the matinee, or it can mess with pawn visibility
	`XWORLD.bDisableVisibilityUpdates = true;

	// assign all units to the matinee
	PrepareUnitsForMatinee();
	
	LinkUnitVariablesToMatinee();

	// some matinee groups will have non-unit actors attached, rebase those too if needed
	if (bRebaseNonUnitVariables)
	{
		RebaseNonUnitVariables();
	}

	// put ourselves in cinematic mode, so the matinee can hook the camera and such at the unreal level
	XComTacticalController(GetALocalPlayerController()).SetCinematicMode(true, true, true, true, true, true);

	// create a camera on the camera stack to do the actual camera logic
	if( !bNewUnitSelected && MatineeBases.Length > 0 )
	{
		MatineeCamera = new class'X2Camera_Matinee';
		MatineeCamera.SetMatinee(Matinees[0], MatineeBases[0]);
		MatineeCamera.PopWhenFinished = false;
		`CAMERASTACK.AddCamera(MatineeCamera);
	}

	// fixes bug where skipped matinee won't replay (because it thinks it's still playing).  mdomowicz 2015_11_13
	foreach Matinees(Matinee)
	{
	Matinee.Stop();
	}

	// and play the matinees
	StartMatinee();
}

simulated protected function EndMatinee()
{
	if(MatineeCamera != none)
	{
		RemoveUnitsFromMatinee();
		`CAMERASTACK.RemoveCamera(MatineeCamera);
		`XWORLD.bDisableVisibilityUpdates = false;

		MatineeCamera = none;
	}
}

simulated function SelectMatineeByTag(string TagPrefix)
{
	local array<SequenceObject> FoundMatinees;
	local Sequence GameSeq;
	local SeqAct_Interp FoundMatinee;
	local int Index;

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, FoundMatinees);

	// randomize the list and take the first one that matches. Since the input is random, the 
	// selection will also be random
	FoundMatinees.RandomizeOrder();
	Matinees.Length = 0;
	for (Index = 0; Index < FoundMatinees.length; Index++)
	{
		FoundMatinee = SeqAct_Interp(FoundMatinees[Index]);
		if(FoundMatinee.BaseMatineeComment == "" && Instr(FoundMatinee.ObjComment, TagPrefix,, true) == 0)
		{
			Matinees.AddItem(FoundMatinee);
			break;
			}
		}

	if(Matinees.Length == 0)
	{
		`Redscreen("X2Action_PlayMatinee::SelectMatineeByTag(): Could not find Matinee for tag " $ TagPrefix);
		return;
	}

	// add any layered auxiallary matinees from mods
	for (Index = 0; Index < FoundMatinees.length; Index++)
	{
		FoundMatinee = SeqAct_Interp(FoundMatinees[Index]);
		if(FoundMatinee.BaseMatineeComment == Matinees[0].ObjComment)
	{
			Matinees.AddItem(FoundMatinee);
		}
	}
}

simulated state Executing
{
	event Tick(float DeltaTime)
	{
		super.Tick(DeltaTime);

		// keep updating the matinee until it is finished. Use the camera as a sentinel to
		// indicate that the matinee has actually started playback, as sub classes might not start
		// the matinee immediately
		if(MatineeCamera != none)
		{
			UpdateMatinee(DeltaTime);
		}
	}

Begin:
	PlayMatinee();

	// just wait for the matinee to complete playback
	while(Matinees.Length > 0) // the matinees will be cleared when they are finished
	{
		Sleep(0.0f);
	}
	
	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();

	EndMatinee();

	XComTacticalController(GetALocalPlayerController()).SetCinematicMode(false, true, true, true, true, true);
}

event bool BlocksAbilityActivation()
{
	return true; // matinees should never permit interruption
}

event HandleNewUnitSelection()
{
	if( MatineeCamera != None )
	{
		`CAMERASTACK.RemoveCamera(MatineeCamera);
		MatineeCamera = None;
	}
}

DefaultProperties
{
	bRebaseNonUnitVariables=true
}
