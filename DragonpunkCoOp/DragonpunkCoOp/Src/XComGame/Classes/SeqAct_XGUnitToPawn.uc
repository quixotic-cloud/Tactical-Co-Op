//-----------------------------------------------------------
//Trigger when code is passing units to kismet variables for matinee
//-----------------------------------------------------------
class SeqAct_XGUnitToPawn extends SequenceAction;

var Object  Unit;
var Pawn    UnitPawn;

event Activated()
{
	if (XGUnit(Unit) != none)
	{
		UnitPawn = XGUnit(Unit).GetPawn();
	}
}


defaultproperties
{
	ObjName="XComUnit To Pawn"
	ObjCategory="Unit"

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="XGUnit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Pawn",PropertyName=UnitPawn,bWriteable=TRUE)
	
}