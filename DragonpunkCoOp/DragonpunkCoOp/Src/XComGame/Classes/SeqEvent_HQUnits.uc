class SeqEvent_HQUnits extends SequenceEvent;

var Object Unit0,Unit1,Unit2,Unit3,Unit4,Unit5,Unit6,Unit7,Unit8,Unit9,Unit10,Unit11;
var() const int MaxUnits;
var() Actor CineDummy;
var() bool bDisableGenderBlender;

/**
 * Return the version number for this class.  Child classes should increment this method by calling Super then adding
 * a individual class version to the result.  When a class is first created, the number should be 0; each time one of the
 * link arrays is modified (VariableLinks, OutputLinks, InputLinks, etc.), the number that is added to the result of
 * Super.GetObjClassVersion() should be incremented by 1.
 *
 * @return	the version number for this specific class.
 */
static event int GetObjClassVersion()
{
	return Super.GetObjClassVersion() + 3;
}

event Activated()
{
	//`log("SeqEvent_HQUnits:"@ ObjComment @"Activated");
	OutputLinks[0].bDisabled = false;
	OutputLinks[1].bDisabled = false;
}

// jboswell: this makes me feel dirty, but there isn't really a better way in script :(
function private bool AddUnit(Object InUnit, int SlotIdx)
{
	local bool bAdded;
	local XComUnitPawn UnitPawn;
	local XComHumanPawn HumanPawn;

	bAdded = true;

	switch(SlotIdx)
	{
	case 0: Unit0 = InUnit; break;
	case 1: Unit1 = InUnit; break;
	case 2: Unit2 = InUnit; break;
	case 3: Unit3 = InUnit; break;
	case 4: Unit4 = InUnit; break;
	case 5: Unit5 = InUnit; break;
	case 6: Unit6 = InUnit; break;
	case 7: Unit7 = InUnit; break;
	case 8: Unit8 = InUnit; break;
	case 9: Unit9 = InUnit; break;
	case 10: Unit10 = InUnit; break;
	case 11: Unit11 = InUnit; break;
	default: bAdded = false; break;
	}

	if (bAdded)
	{
		if (CineDummy != none)
		{
			HumanPawn = XComHumanPawn(InUnit);
			if (HumanPawn != none)
			{
				HumanPawn.PrepForMatinee();
				HumanPawn.bSkipGenderBlender = bDisableGenderBlender;
				if (bDisableGenderBlender && HumanPawn.IsFemale())
					HumanPawn.GetAnimTreeController().SetGenderBlenderBlendTarget(0.0f, 0.0f);
			}

			UnitPawn = XComUnitPawn(InUnit);
			UnitPawn.SetBase(CineDummy);
			UnitPawn.SetPhysics(PHYS_Interpolating);
			UnitPawn.ResetIKTranslations();

			UpdateMatinee();
		}
	}

	return bAdded;
}

function bool RemoveUnit(Object InUnit)
{
	local bool bRemoved;
	local XComHumanPawn HumanPawn;

	bRemoved = true;

	if (Unit0 == InUnit)
		Unit0 = none;
	else if (Unit1 == InUnit)
		Unit1 = none;
	else if (Unit2 == InUnit)
		Unit2 = none;
	else if (Unit3 == InUnit)
		Unit3 = none;
	else if (Unit4 == InUnit)
		Unit4 = none;
	else if (Unit5 == InUnit)
		Unit5 = none;
	else if (Unit6 == InUnit)
		Unit6 = none;
	else if (Unit7 == InUnit)
		Unit7 = none;
	else if (Unit8 == InUnit)
		Unit8 = none;
	else if (Unit9 == InUnit)
		Unit9 = none;
	else if (Unit10 == InUnit)
		Unit10 = none;
	else if (Unit11 == InUnit)
		Unit11 = none;
	else
		bRemoved = false;

	if (bRemoved)
	{
		UpdateMatinee();

		HumanPawn = XComHumanPawn(InUnit);
		if (HumanPawn != none)
		{
			HumanPawn.RemoveFromMatinee();
			HumanPawn.bSkipGenderBlender = false;
		}
	}

	return bRemoved;
}

// Push the new set of inputs into the matinee, but continue playing from the current
// position if the matinee is already playing
function UpdateMatinee()
{
	local int LinkIdx, OutIdx;
	local SeqAct_Interp Matinee;

	PopulateLinkedVariableValues();
	for (OutIdx = 0; OutIdx < OutputLinks.Length; ++OutIdx)
	{
		for (LinkIdx = 0; LinkIdx < OutputLinks[OutIdx].Links.Length; ++LinkIdx)
		{
			Matinee = SeqAct_Interp(OutputLinks[OutIdx].Links[LinkIdx].LinkedOp);
			if (Matinee != none)
			{
				Matinee.NativeActivated(0);
				return;
			}
		}
	}
}

static function SeqEvent_HQUnits FindHQRoomSequence(string RoomName)
{
	local array<SequenceObject> HQUnitEvents;
	local SeqEvent_HQUnits UnitMap;
	local int Idx;

	class'Engine'.static.GetCurrentWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_HQUnits', true, HQUnitEvents);
	for (Idx = 0; Idx < HQUnitEvents.Length; ++Idx)
	{
		UnitMap = SeqEvent_HQUnits(HQUnitEvents[Idx]);
		if (UnitMap != none && UnitMap.ObjComment == RoomName)
			return UnitMap;
	}

	`log("FindHQRoomSequence: Did not find a room named" @ RoomName);

	return none;
}

static function SeqEvent_HQUnits FindHQUnitsInLevel(string LevelName)
{
	local array<SequenceObject> HQUnitEvents;
	local SeqEvent_HQUnits UnitMap;
	local int Idx;
	local string sEventLevelName;

	class'Engine'.static.GetCurrentWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_HQUnits', true, HQUnitEvents);
	for (Idx = 0; Idx < HQUnitEvents.Length; ++Idx)
	{
		UnitMap = SeqEvent_HQUnits(HQUnitEvents[Idx]);
		if (UnitMap != none)
		{
			sEventLevelName = UnitMap.GetLevelName();
			if (sEventLevelName ~= LevelName)
				return UnitMap;
		}
	}

	`log("FindHQRoomSequence: Did not SeqEvent_HQUnits with level named" @ LevelName);

	return none;
}

function bool AreHQUnitsReady()
{
	local int i;
	local XComUnitPawn kPawn;

	for (i = 0; i < MaxUnits; ++i)
	{
		switch(i)
		{
		case 0: kPawn = Unit0 == none ? none : XComUnitPawn(Unit0); break;
		case 1: kPawn = Unit1 == none ? none : XComUnitPawn(Unit1); break;
		case 2: kPawn = Unit2 == none ? none : XComUnitPawn(Unit2); break;
		case 3: kPawn = Unit3 == none ? none : XComUnitPawn(Unit3); break;
		case 4: kPawn = Unit4 == none ? none : XComUnitPawn(Unit4); break;
		case 5: kPawn = Unit5 == none ? none : XComUnitPawn(Unit5); break;
		case 6: kPawn = Unit6 == none ? none : XComUnitPawn(Unit6); break;
		case 7: kPawn = Unit7 == none ? none : XComUnitPawn(Unit7); break;
		case 8: kPawn = Unit8 == none ? none : XComUnitPawn(Unit8); break;
		case 9: kPawn = Unit9 == none ? none : XComUnitPawn(Unit9); break;
		case 10: kPawn = Unit10 == none ? none : XComUnitPawn(Unit10); break;
		case 11: kPawn = Unit11 == none ? none : XComUnitPawn(Unit11); break;
		}

		if (kPawn != none && !kPawn.IsPawnReadyForViewing())
		{
			return false;
		}
	}
	return true;
}

static private function SeqEvent_HQUnits GetSpecializedRoom(string RoomName, const out TCharacter Char)
{
	local SeqEvent_HQUnits UnitMap;

	// if a mec trooper, see if we have a special variation of the room for them. 
	// this allows the artists to give mec troopers their own animations
	if(Char.TemplateName == 'Tank')
	{
		UnitMap = FindHQRoomSequence(RoomName $ "_Shiv");
	}

	if(UnitMap == none)
	{
		UnitMap = FindHQRoomSequence(RoomName);
	}

	return UnitMap;
}

// since there can be multiple HQUnit events for differnt pawn types, we
// need to search across all of them to find the correct slot to put a guy in
static private function int GetFirstFreeSlot(string RoomName)
{
	local SeqEvent_HQUnits UnitMap;
	local array<SeqEvent_HQUnits> UnitMaps;
	local bool Found;
	local int Slot;

	UnitMap = FindHQRoomSequence(RoomName);
	if(UnitMap != none) UnitMaps.AddItem(UnitMap); 

	UnitMap = FindHQRoomSequence(RoomName $ "_MecTrooper");
	if(UnitMap != none) UnitMaps.AddItem(UnitMap); 

	UnitMap = FindHQRoomSequence(RoomName $ "_Mec");
	if(UnitMap != none) UnitMaps.AddItem(UnitMap); 

	UnitMap = FindHQRoomSequence(RoomName $ "_Shiv");
	if(UnitMap != none) UnitMaps.AddItem(UnitMap); 

	for(Slot = 0; Slot < 12; Slot++)
	{
		Found = True;
		foreach UnitMaps(UnitMap)
		{
			switch(Slot)
			{
			case 0: if(UnitMap.Unit0 != none) Found = false; break;
			case 1: if(UnitMap.Unit1 != none) Found = false; break;
			case 2: if(UnitMap.Unit2 != none) Found = false; break;
			case 3: if(UnitMap.Unit3 != none) Found = false; break;
			case 4: if(UnitMap.Unit4 != none) Found = false; break;
			case 5: if(UnitMap.Unit5 != none) Found = false; break;
			case 6: if(UnitMap.Unit6 != none) Found = false; break;
			case 7: if(UnitMap.Unit7 != none) Found = false; break;
			case 8: if(UnitMap.Unit8 != none) Found = false; break;
			case 9: if(UnitMap.Unit9 != none) Found = false; break;
			case 10: if(UnitMap.Unit10 != none) Found = false; break;
			case 11: if(UnitMap.Unit11 != none) Found = false; break;
			}
		}

		if(Found)
		{
			break;
		}
	}

	return Slot;
}

static function bool AddUnitToRoomSequence(string RoomName, XComUnitPawn UnitPawn, const out TCharacter Char, optional int SlotIdx=-1)
{
	local SeqEvent_HQUnits UnitMap;

	if(SlotIdx == -1)
	{
		SlotIdx = GetFirstFreeSlot(RoomName);
	}

	UnitMap = GetSpecializedRoom(RoomName, Char);
	if (UnitMap != none)
	{
		`log("AddUnitToRoomSequence:" @ RoomName @ UnitPawn.Name);
		 return UnitMap.AddUnit(UnitPawn, SlotIdx);
	}

	return false;
}

static function RemoveUnitFromRoomSequence(string RoomName, XComUnitPawn UnitPawn, const out TCharacter Char)
{
	local SeqEvent_HQUnits UnitMap;

	UnitMap = GetSpecializedRoom(RoomName, Char);
	if (UnitMap != none && UnitPawn != none)
	{
		`log("RemoveUnitFromRoomSequence:" @ RoomName @ UnitPawn.Name);
		UnitMap.RemoveUnit(UnitPawn);
	}
}

static function PlayRoomSequence(string RoomName)
{
	local SeqEvent_HQUnits RoomSeq;
	local array<int> Indices;
	local PlayerController PC;
	PC = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController();

	RoomSeq = class'SeqEvent_HQUnits'.static.FindHQRoomSequence(RoomName);
	if (RoomSeq != none)
	{
		Indices[Indices.Length] = 0;
		RoomSeq.CheckActivate(PC, PC,, Indices);
	}
	else
	{
		`log("PlayRoomSequence: Could not find sequence for room" @ RoomName);
	}
}

static function StopRoomSequence(string RoomName)
{
	local SeqEvent_HQUnits RoomSeq;
	local array<int> Indices;
	local PlayerController PC;
	PC = class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController();

	RoomSeq = class'SeqEvent_HQUnits'.static.FindHQRoomSequence(RoomName);
	if (RoomSeq != none)
	{
		Indices[Indices.Length] = 1;
		RoomSeq.CheckActivate(PC, PC,, Indices);
	}
	else
	{
		`log("StopRoomSequence: Could not find sequence for room" @ RoomName);
	}
}

defaultproperties
{
	ObjName="HQ Units"
	ObjCategory="Cinematic"
	bPlayerOnly=false
	MaxTriggerCount=0
	bDisableGenderBlender=false

	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Play")
	OutputLinks(1)=(LinkDesc="Stop")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 0",PropertyName=Unit0,bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 1",PropertyName=Unit1,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 2",PropertyName=Unit2,bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 3",PropertyName=Unit3,bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 4",PropertyName=Unit4,bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 5",PropertyName=Unit5,bWriteable=TRUE)
	VariableLinks(6)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 6",PropertyName=Unit6,bWriteable=TRUE)
	VariableLinks(7)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 7",PropertyName=Unit7,bWriteable=true)
	VariableLinks(8)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 8",PropertyName=Unit8,bWriteable=TRUE)
	VariableLinks(9)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 9",PropertyName=Unit9,bWriteable=TRUE)
	VariableLinks(10)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 10",PropertyName=Unit10,bWriteable=TRUE)
	VariableLinks(11)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 11",PropertyName=Unit11,bWriteable=TRUE)

	MaxUnits=12;
}
