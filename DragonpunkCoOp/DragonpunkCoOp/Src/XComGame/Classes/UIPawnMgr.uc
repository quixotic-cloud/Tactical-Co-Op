class UIPawnMgr extends Actor;

struct CosmeticInfo
{
	var XComUnitPawn ArchetypePawn;
	var XComUnitPawn Pawn;
};

struct PawnInfo
{
	var int PawnRef;
	var array<Actor> Referrers;
	var XComUnitPawn Pawn;
	var array<CosmeticInfo> Cosmetics;
	var array<Actor> Weapons;
	var bool bPawnRemoved;
};

var array<PawnInfo> Pawns;
var array<PawnInfo> CinematicPawns;

var XComGameState CheckGameState;

delegate bool VariableNameTest(Name VarName);

simulated function XComUnitPawn CreatePawn(Actor referrer, XComGameState_Unit UnitState, Vector UseLocation, Rotator UseRotation, optional bool bForceMenuState)
{
	return UnitState.CreatePawn(referrer, UseLocation, UseRotation, bForceMenuState);
}

//this is the MP squad loadout we're checking for the units to spawn
simulated function SetCheckGameState(XComGameState MPGameState)
{
	CheckGameState = MPGameState;
}

function bool DefaultVariablePredicate(Name VarName)
{	
	return true;
}

function int GetPawnVariablesStartingWith(name VariableName, out array<name> VariableNames)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.GetVariableStartingWith(VariableName, OutVariables);

	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			VariableNames.AddItem(SeqVarPawn.VarName);
		}
	}

	return VariableNames.Length;
}

function bool HasPawnVariable(name VariableName)
{
	local array<SequenceVariable> OutVariables;
	WorldInfo.MyKismetVariableMgr.GetVariable(VariableName, OutVariables);
	return (OutVariables.Length > 0);
}

function SetPawnVariable(XComUnitPawn UnitPawn, name VariableName)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	if (VariableName == '')
		return;

	WorldInfo.MyKismetVariableMgr.GetVariable(VariableName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
			SeqVarPawn.SetObjectValue(UnitPawn);
		}
	}
}

function ClearPawnVariable(name VariableName)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	if (VariableName == '')
		return;

	WorldInfo.MyKismetVariableMgr.GetVariable(VariableName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
		}
	}
}

//bHardAttach should be used if the cinematic pawn will be moving around with the cinedummy, ie. riding a lift or moving platform
simulated function XComUnitPawn RequestCinematicPawn(Actor referrer, int UnitRef, Vector UseLocation, Rotator UseRotation, optional name VariableName, optional name CineBaseTag, optional bool bCinedummyHardAttach)
{
	local XComUnitPawn Pawn;
	local SkeletalMeshActor CineDummy;
	local SkeletalMeshActor IterateActor;	
	local float ClosestCineDummyDistance; //Since the player can build certain rooms multiple times, we need to look for the closest cinedummy to use
	local float DistanceSq;
	
	if (CineBaseTag != '')
	{
		ClosestCineDummyDistance = 10000000.0f;
		foreach AllActors(class'SkeletalMeshActor', IterateActor)
		{
			if(IterateActor.Tag == CineBaseTag)
			{
				DistanceSq = VSizeSq(IterateActor.Location - UseLocation);
				if(DistanceSq < ClosestCineDummyDistance)
				{
					ClosestCineDummyDistance = DistanceSq;
					CineDummy = IterateActor;
				}
			}
		}

		UseLocation = vect(0, 0, 0); //If we are attaching to a cinedummy, don't have a local offset
		if(CineDummy == None)
		{
			if(referrer.Tag == CineBaseTag)
			{
				//Last ditch effort, in some situations the referrer can be the cinedummy, such as tentpole cinematics
				CineDummy = SkeletalMeshActor(referrer);
			}
			else
			{
				`redscreen("Could not locate cinedummy with tag:"@CineBaseTag@" This will result in incorrectly located base personnel! @acurrie");
			}
		}
	}
		
	Pawn = RequestPawnByIDInternal(referrer, UnitRef, UseLocation, UseRotation, CinematicPawns);
	Pawn.GotoState('InHQ');	
	Pawn.SetupForMatinee(CineDummy, true, true, bCinedummyHardAttach);
	if(VariableName != '')
	{
		SetPawnVariable(Pawn, VariableName);
	}
	return Pawn;
}

simulated function XComUnitPawn GetCosmeticArchetypePawn(int CosmeticSlot, int UnitRef)
{
	local int PawnInfoIndex;

	PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		return GetCosmeticArchetypePawnInternal(Pawns, CosmeticSlot, PawnInfoIndex);
	}

	PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		return GetCosmeticArchetypePawnInternal(CinematicPawns, CosmeticSlot, PawnInfoIndex);
	}

	return none;
}

simulated function XComUnitPawn GetCosmeticArchetypePawnInternal(out array<PawnInfo> PawnStore, int CosmeticSlot, int StoreIdx)
{
	if (CosmeticSlot >= PawnStore[StoreIdx].Cosmetics.Length)
		return none;

	return PawnStore[StoreIdx].Cosmetics[CosmeticSlot].ArchetypePawn;
}

simulated function XComUnitPawn GetCosmeticPawn(int CosmeticSlot, int UnitRef)
{
	local int PawnInfoIndex;

	PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		return GetCosmeticPawnInternal(Pawns, CosmeticSlot, PawnInfoIndex);
	}

	PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		return GetCosmeticPawnInternal(CinematicPawns, CosmeticSlot, PawnInfoIndex);
	}

	return none;
}

simulated function XComUnitPawn GetCosmeticPawnInternal(out array<PawnInfo> PawnStore, int CosmeticSlot, int StoreIdx)
{
	if (CosmeticSlot >= PawnStore[StoreIdx].Cosmetics.Length)
		return none;

	return PawnStore[StoreIdx].Cosmetics[CosmeticSlot].Pawn;
}

simulated function AssociateWeaponPawn(int CosmeticSlot, Actor WeaponPawn, int UnitRef,  XComUnitPawn OwningPawn)
{
	local int PawnInfoIndex;

	PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		AssociateWeaponPawnInternal(CosmeticSlot, WeaponPawn, Pawns, PawnInfoIndex, OwningPawn);
		return;
	}

	PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		AssociateWeaponPawnInternal(CosmeticSlot, WeaponPawn, CinematicPawns, PawnInfoIndex, OwningPawn);
		return;
	}

	`assert(false);
}

simulated function AssociateWeaponPawnInternal(int CosmeticSlot, Actor WeaponPawn, out array<PawnInfo> PawnStore, int StoreIdx, XComUnitPawn OwningPawn)
{
	local XGInventoryItem PreviousItem;
	`assert(StoreIdx != -1);

	if (PawnStore[StoreIdx].Weapons[CosmeticSlot] != WeaponPawn)
	{
		if (PawnStore[StoreIdx].Weapons[CosmeticSlot] != none)
		{
			PreviousItem = XGInventoryItem(PawnStore[StoreIdx].Weapons[CosmeticSlot]);
			OwningPawn.DetachItem(XComWeapon(PreviousItem.m_kEntity).Mesh);
			PawnStore[StoreIdx].Weapons[CosmeticSlot].Destroy();
		}
		PawnStore[StoreIdx].Weapons[CosmeticSlot] = WeaponPawn;
	}
}

simulated function XComUnitPawn AssociateCosmeticPawn(int CosmeticSlot, XComUnitPawn ArchetypePawn, int UnitRef,  XComUnitPawn OwningPawn, optional Vector UseLocation, optional Rotator UseRotation)
{
	local int PawnInfoIndex;

	PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		return AssociateCosmeticPawnInternal(CosmeticSlot, ArchetypePawn, Pawns, PawnInfoIndex, OwningPawn, UseLocation, UseRotation);
	}

	PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
	if (PawnInfoIndex != -1)
	{
		return AssociateCosmeticPawnInternal(CosmeticSlot, ArchetypePawn, CinematicPawns, PawnInfoIndex, OwningPawn, UseLocation, UseRotation);
	}

	`assert(false);
	return none;
}

simulated function XComUnitPawn AssociateCosmeticPawnInternal(int CosmeticSlot, XComUnitPawn ArchetypePawn, out array<PawnInfo> PawnStore, int StoreIdx, XComUnitPawn OwningPawn, optional Vector UseLocation, optional Rotator UseRotation)
{
	local CosmeticInfo Cosmetic;

	`assert(StoreIdx != -1);

	if (PawnStore[StoreIdx].Cosmetics[CosmeticSlot].ArchetypePawn != ArchetypePawn)
	{
		if (PawnStore[StoreIdx].Cosmetics[CosmeticSlot].Pawn != none)
		{
			PawnStore[StoreIdx].Cosmetics[CosmeticSlot].Pawn.Destroy();
		}

		Cosmetic.ArchetypePawn = ArchetypePawn;
		Cosmetic.Pawn = class'Engine'.static.GetCurrentWorldInfo().Spawn( ArchetypePawn.Class, OwningPawn, , UseLocation, UseRotation, ArchetypePawn, true, eTeam_All );
		Cosmetic.Pawn.SetPhysics(PHYS_None);
		Cosmetic.Pawn.SetVisible(true);

		PawnStore[StoreIdx].Cosmetics[CosmeticSlot] = Cosmetic;
	}
	else
	{
		Cosmetic = PawnStore[StoreIdx].Cosmetics[CosmeticSlot];
	}
	return Cosmetic.Pawn;
}

simulated function XComUnitPawn RequestPawnByState(Actor referrer, XComGameState_Unit UnitState, optional Vector UseLocation, optional Rotator UseRotation)
{
	return RequestPawnByStateInternal(referrer, UnitState, UseLocation, UseRotation, Pawns);
}

simulated function XComUnitPawn RequestPawnByStateInternal(Actor referrer, XComGameState_Unit UnitState, Vector UseLocation, Rotator UseRotation, out array<PawnInfo> PawnStore)
{
	local int PawnInfoIndex;
	local PawnInfo Info;

	PawnInfoIndex = PawnStore.Find('PawnRef', UnitState.ObjectID);
	if (PawnInfoIndex == -1)
	{
		Info.PawnRef = UnitState.ObjectID;
		Info.Referrers.AddItem(referrer);
		Info.Pawn = CreatePawn(referrer, UnitState, UseLocation, UseRotation, CheckGameState != none);
		PawnStore.AddItem(Info);
	}
	else if(PawnStore[PawnInfoIndex].bPawnRemoved)
	{
		PawnStore[PawnInfoIndex].Referrers.AddItem(referrer);
		PawnStore[PawnInfoIndex].Pawn = CreatePawn(referrer, UnitState, UseLocation, UseRotation, CheckGameState != none);
		PawnStore[PawnInfoIndex].bPawnRemoved = false;
		Info = PawnStore[PawnInfoIndex];
	}
	else
	{
		Info = PawnStore[PawnInfoIndex];
		if (Info.Referrers.Find(referrer) == -1)
		{
			PawnStore[PawnInfoIndex].Referrers.AddItem(referrer);
		}
	}
	return Info.Pawn;
}

simulated function XComUnitPawn RequestPawnByID(Actor referrer, int UnitRef, optional Vector UseLocation, optional Rotator UseRotation)
{
	return RequestPawnByIDInternal(referrer, UnitRef, UseLocation, UseRotation, Pawns);
}

simulated function XComUnitPawn RequestPawnByIDInternal(Actor referrer, int UnitRef, Vector UseLocation, Rotator UseRotation, out array<PawnInfo> PawnStore)
{
	local XComGameState_Unit Unit;
	if(CheckGameState == none)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef));
	}
	else
	{
		Unit = XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitRef));
	}

	return RequestPawnByStateInternal(referrer, Unit, UseLocation, UseRotation, PawnStore);
}

simulated function ReleaseCinematicPawn(Actor referrer, int UnitRef, optional bool bForce)
{
	ReleasePawnInternal(referrer, UnitRef, CinematicPawns, bForce);
}

simulated function ReleasePawn(Actor referrer, int UnitRef, optional bool bForce)
{
	ReleasePawnInternal(referrer, UnitRef, Pawns, bForce);
}

simulated function DestroyPawns(int StoreIdx, out array<PawnInfo> PawnStore)
{
	local int idx;

	PawnStore[StoreIdx].Pawn.Destroy();
	for ( idx = 0; idx < PawnStore[StoreIdx].Cosmetics.Length; ++idx )
	{
		if (PawnStore[StoreIdx].Cosmetics[idx].Pawn != none)
		{
			PawnStore[StoreIdx].Cosmetics[idx].Pawn.Destroy();

			//This is checked in various places to determine if the pawn should be re-made.
			//So, since we just Destroyed the Pawn, un-set this too.
			PawnStore[StoreIdx].Cosmetics[idx].ArchetypePawn = None;
		}
	}

	for ( idx = 0; idx < PawnStore[StoreIdx].Weapons.Length; ++idx )
	{
		if (PawnStore[StoreIdx].Weapons[idx] != none)
		{
			PawnStore[StoreIdx].Weapons[idx].Destroy();
		}
	}
	
}

simulated function ReleasePawnInternal(Actor referrer, int UnitRef, out array<PawnInfo> PawnStore, optional bool bForce)
{
	local int PawnInfoIndex;

	PawnInfoIndex = PawnStore.Find('PawnRef', UnitRef);
	if (PawnInfoIndex == -1)
	{
		// red screen??
	}
	else if(bForce) // don't remove the entry from the array to preserve the Referrers
	{
		PawnStore[PawnInfoIndex].Referrers.RemoveItem(referrer);
		DestroyPawns(PawnInfoIndex, PawnStore);
		PawnStore[PawnInfoIndex].bPawnRemoved = true;
	}
	else
	{		
		PawnStore[PawnInfoIndex].Referrers.RemoveItem(referrer);
		if(PawnStore[PawnInfoIndex].Referrers.Length == 0)
		{
			DestroyPawns(PawnInfoIndex, PawnStore);
			PawnStore.Remove(PawnInfoIndex, 1);
		}
	}
}

defaultproperties
{
}
