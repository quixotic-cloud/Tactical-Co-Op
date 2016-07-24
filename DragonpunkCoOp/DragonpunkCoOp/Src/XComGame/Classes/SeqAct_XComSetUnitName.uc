//-----------------------------------------------------------
//Take a pawn or unit and then set the specified name information on that unit. 
//-----------------------------------------------------------
class SeqAct_XComSetUnitName extends SequenceAction;

var XComGameState_Unit Unit;
var string FirstName;
var string LastName;
var string NickName;

event Activated()
{
	if(Unit == none) return;

	//Unit.SetName(FirstName, LastName, NickName);
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Set Unit Name"
	bCallHandler = false
	
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="First Name",PropertyName=FirstName)
	VariableLinks(2)=(ExpectedType=class'SeqVar_String',LinkDesc="Last Name",PropertyName=LastName)
	VariableLinks(3)=(ExpectedType=class'SeqVar_String',LinkDesc="Nick Name",PropertyName=NickName)

}

