/**
 * Gets the units available for a matinee in game
 */
class SeqAct_GetHeadquartersCrewPawns extends SequenceAction;

var XComUnitPawn UnitPawn1;
var XComUnitPawn UnitPawn2;
var XComUnitPawn UnitPawn3;
var XComUnitPawn UnitPawn4;
var XComUnitPawn UnitPawn5;
var XComUnitPawn UnitPawn6;
var XComUnitPawn UnitPawn7;
var XComUnitPawn UnitPawn8;
var XComUnitPawn UnitPawn9;
var XComUnitPawn UnitPawn10;
var XComUnitPawn UnitPawn11;
var XComUnitPawn UnitPawn12;

var() Actor CineDummy;

var() array<name> AllowedCharacterTemplates; // If Length > 0, will restrict to only the specified types of characters
var int NumAvailable;

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int iNumSlotsUsed;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit UnitState;
	local int Index;
	local Vector ZeroLoc;
	local Rotator ZeroRotator;
	local XComUnitPawn kPawn;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		
	if(`HQPRES != none && XComHQ != none)
	{
		ClearSlots();
		iNumSlotsUsed = 0;

		Soldiers = XComHQ.GetDeployableSoldiers();
		for(Index = 0; Index < Soldiers.Length && Index < 12; Index++)
		{
			UnitState = Soldiers[Index];

			if(AllowedCharacterTemplates.Length == 0 || AllowedCharacterTemplates.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
			{
			kPawn = UnitState.CreatePawn(CineDummy, ZeroLoc, ZeroRotator, false);			
			kPawn.SetBase(CineDummy);
			kPawn.SetupForMatinee(, true);
			SetSlot(iNumSlotsUsed, kPawn);
			iNumSlotsUsed++;
		}		
		}		

		NumAvailable = iNumSlotsUsed;
	}
}

function SetSlot(int iSlot, XComUnitPawn kPawn)
{
	//kPawn.SetupForMatinee();
	switch(iSlot)
	{
	case 0: UnitPawn1 = kPawn; return;
	case 1: UnitPawn2 = kPawn; return;
	case 2: UnitPawn3 = kPawn; return;
	case 3: UnitPawn4 = kPawn; return;
	case 4: UnitPawn5 = kPawn; return;
	case 5: UnitPawn6 = kPawn; return;
	case 6: UnitPawn7 = kPawn; return;
	case 7: UnitPawn8 = kPawn; return;
	case 8: UnitPawn9 = kPawn; return;
	case 9: UnitPawn10 = kPawn; return;
	case 10: UnitPawn11 = kPawn; return;
	case 11: UnitPawn12 = kPawn; return;
	}

	`assert(false); // invalid slot
}

function ClearSlots()
{
	UnitPawn1 = none;
	UnitPawn2 = none;
	UnitPawn3 = none;
	UnitPawn4 = none;
	UnitPawn5 = none;
	UnitPawn6 = none;
	UnitPawn7 = none;
	UnitPawn8 = none;
	UnitPawn9 = none;
	UnitPawn10 = none;
	UnitPawn11 = none;
	UnitPawn12 = none;
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjName="Get Headquarters Crew Pawns"
	ObjCategory="Cinematic"
	bCallHandler=false

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit1",PropertyName=UnitPawn1,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit2",PropertyName=UnitPawn2,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit3",PropertyName=UnitPawn3,bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit4",PropertyName=UnitPawn4,bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit5",PropertyName=UnitPawn5,bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit6",PropertyName=UnitPawn6,bWriteable=TRUE)
	VariableLinks(6)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit7",PropertyName=UnitPawn7,bWriteable=TRUE)
	VariableLinks(7)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit8",PropertyName=UnitPawn8,bWriteable=TRUE)
	VariableLinks(8)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit9",PropertyName=UnitPawn9,bWriteable=TRUE)
	VariableLinks(9)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit10",PropertyName=UnitPawn10,bWriteable=TRUE)
	VariableLinks(10)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit11",PropertyName=UnitPawn11,bWriteable=TRUE)
	VariableLinks(11)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit12",PropertyName=UnitPawn12,bWriteable=TRUE)

	VariableLinks(12)=(ExpectedType=class'SeqVar_Int',LinkDesc="NumAvailable",PropertyName=NumAvailable,bWriteable=TRUE)
}
