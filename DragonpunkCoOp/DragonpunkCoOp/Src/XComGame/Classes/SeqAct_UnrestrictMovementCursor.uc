/**
 * Remove location restriction placed on the movement cursor.
 */
class SeqAct_UnrestrictMovementCursor extends SequenceAction;

/** The Pathing Pawn that is to have restricted movement.  This may remain "none" */
var() Actor PathingUnit;

event Activated()
{
}

defaultproperties
{
	ObjName="Unrestrict Movement Cursor"
	ObjCategory="Tutorial"
	bCallHandler=false;

	PathingUnit = none

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="PathingUnit", PropertyName=PathingUnit)
}
