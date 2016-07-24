/**
 * This is used for the tutorial. - Ryan Baker
 */
class SeqAct_RestrictMovementCursorToCover extends SequenceAction;

/** The Pathing Unit that is to have restricted movement.  This may remain "none" */
var() Actor PathingUnit;

var() bool bFirstMoveOutOfCover;

event Activated()
{
}

defaultproperties
{
	ObjName="Restrict Movement Cursor To Cover"
	ObjCategory="Tutorial"
	bCallHandler=false;

	PathingUnit = none;

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="PathingUnit", PropertyName=PathingUnit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Bool', LinkDesc="bFirstMoveOutOfCover", PropertyName=bFirstMoveOutOfCover)
}
