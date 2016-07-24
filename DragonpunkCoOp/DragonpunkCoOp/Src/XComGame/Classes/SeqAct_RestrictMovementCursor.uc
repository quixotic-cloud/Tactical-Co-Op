/**
 * Restricts the movement cursor so that only a specific spot
 * may be selected.
 */
class SeqAct_RestrictMovementCursor extends SequenceAction;

/** The Pathing Unit that is to have restricted movement.  This may remain "none" */
var() Actor PathingUnit;

/** Marks the location the movement cursor is restricted to. */
var() Actor Locator;

/** The distance the movement cursor may be from the locator. */
var() bool SnapToLocator;

event Activated()
{
}

defaultproperties
{
	ObjName="Restrict Movement Cursor"
	ObjCategory="Tutorial"
	bCallHandler=false;

	SnapToLocator = false;
	PathingUnit = none;
	Locator = none;

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="PathingUnit", PropertyName=PathingUnit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object', LinkDesc="Locator", PropertyName=Locator)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Bool', LinkDesc="SnapToLocator", PropertyName=SnapToLocator)
}
