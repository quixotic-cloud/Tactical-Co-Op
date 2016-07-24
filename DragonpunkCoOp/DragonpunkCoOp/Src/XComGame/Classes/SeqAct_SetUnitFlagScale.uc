/**
 * Sets the currently selected unit.
 */
class SeqAct_SetUnitFlagScale extends SequenceAction;

/** The unit to select */
var() Actor TargetActor;
var() int   UIScale<ToolTip="A value of 0 will allow the game to scale the UI normally.">;
var() int   PreviewMoves<ToolTip="If not -1, it will show the preview for the specified number.">;

event Activated()
{
	local XComUnitPawn pawn;
	local XGUnit unit;

	pawn = XComUnitPawn(TargetActor);
	if (pawn != none)
	{
		unit = XGUnit(pawn.GetGameUnit());
	}
	else
	{
		unit = XGUnit(TargetActor);
	}

	if( unit != none ) {
		XComPresentationLayer(XComPlayerController(unit.GetALocalPlayerController()).Pres).m_kUnitFlagManager.SetUnitFlagScale( unit, UIScale );

		if( PreviewMoves != -1 ) {
			XComPresentationLayer(XComPlayerController(unit.GetALocalPlayerController()).Pres).m_kUnitFlagManager.PreviewMoves( unit, PreviewMoves );
		}
	}
}

defaultproperties
{
	ObjName="Set Unit UI Flag Scale"
	ObjCategory="UI/Input"

	PreviewMoves = -1

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Unit", PropertyName=TargetActor)
}
