//-----------------------------------------------------------
//Gets the location of an xcom unit
//-----------------------------------------------------------
class SeqAct_GetUnitGender extends SequenceAction;

var XComGameState_Unit Unit;

event Activated()
{
	OutputLinks[0].bHasImpulse = false;
	OutputLinks[1].bHasImpulse = false;

	if (Unit != none)
	{
		if (Unit.kAppearance.iGender == eGender_Female)
		{
			OutputLinks[1].bHasImpulse = true;
		}
		else
		{
			OutputLinks[0].bHasImpulse = true;
		}
	}
}

defaultproperties
{
	ObjCategory = "Unit"
	ObjName = "Get Unit Gender"

	bConvertedForReplaySystem = true
	bCanBeUsedForGameplaySequence = true

	bAutoActivateOutputLinks = false
	OutputLinks(0) = (LinkDesc = "Male")
	OutputLinks(1) = (LinkDesc = "Female")

	VariableLinks(0) = (ExpectedType = class'SeqVar_GameUnit', LinkDesc = "Unit", PropertyName = Unit)
}
