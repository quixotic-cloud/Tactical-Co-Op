/**
 * Gets the units available for a matinee in game
 */
class SeqAct_GetMatineePawns extends SequenceAction;

var XComPawn Soldier1;
var XComPawn Soldier2;
var XComPawn Soldier3;
var XComPawn Soldier4;
var XComPawn Soldier5;
var XComPawn Soldier6;

var int NumAvailable;

event Activated()
{
	local XComTacticalGRI kTacticalGRI;
	local XGBattle_SP kBattle;
	local XGSquad kSquad;
	local XGUnit kUnit;
	local int iNumPermanentMembers;
	local int iSoldierIndex;
	local int iNumSlotsUsed;

	kTacticalGRI = `TACTICALGRI;
	kBattle = (kTacticalGRI != none) ? XGBattle_SP(kTacticalGRI.m_kBattle) : none;
	if(kBattle == none) return;	

	ClearSlots();
	iNumSlotsUsed = 0;

	kSquad = kBattle.GetHumanPlayer().GetSquad();
	iNumPermanentMembers = kSquad.GetNumPermanentMembers();
	for(iSoldierIndex = 0; iSoldierIndex < iNumPermanentMembers; iSoldierIndex++)
	{
		kUnit = kSquad.GetPermanentMemberAt(iSoldierIndex);
		if(kUnit.IsAliveAndWell())
		{
			SetSlot(iNumSlotsUsed, kUnit);
			iNumSlotsUsed++;
		}
	}

	NumAvailable = iNumSlotsUsed;
}

function SetSlot(int iSlot, XGUnit kUnit)
{
	local XComUnitPawn kPawn;

	kPawn = kUnit.GetPawn();
	kPawn.SetupForMatinee();
	switch(iSlot)
	{
	case 0: Soldier1 = kPawn; return;
	case 1: Soldier2 = kPawn; return;
	case 2: Soldier3 = kPawn; return;
	case 3: Soldier4 = kPawn; return;
	case 4: Soldier5 = kPawn; return;
	case 5: Soldier6 = kPawn; return;
	}

	`assert(false); // invalid slot
}

function ClearSlots()
{
	Soldier1 = none;
	Soldier2 = none;
	Soldier3 = none;
	Soldier4 = none;
	Soldier5 = none;
	Soldier6 = none;
}

defaultproperties
{
	ObjName="Get Matinee Units"
	ObjCategory="Cinematic"
	bCallHandler=false

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier1",PropertyName=Soldier1,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier2",PropertyName=Soldier2,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier3",PropertyName=Soldier3,bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier4",PropertyName=Soldier4,bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier5",PropertyName=Soldier5,bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier6",PropertyName=Soldier6,bWriteable=TRUE)

	VariableLinks(6)=(ExpectedType=class'SeqVar_Int',LinkDesc="NumAvailable",PropertyName=NumAvailable,bWriteable=TRUE)
}
