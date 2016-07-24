//-----------------------------------------------------------
//Take a pawn and return its associated XGUnit.
//-----------------------------------------------------------
class SeqAct_XComPawnToUnit extends SequenceAction;

var XGUnit TargetUnit; 
var Actor         TargetActor;

event Activated()
{
	local SeqVar_Object TargetSeqObj;
	local Object TargetObject;
	local XComPawn TargetPawn; 
	local XGUnit kUnit; 

	//`log("SeqAct_XComPawnToUnit:");
	//`log("TargetSeqObj =" @ TargetSeqObj);

	//Only grabbing ther first one, in case multiple are shoved in here. 
	foreach LinkedVariables(class'SeqVar_Object',TargetSeqObj,"XComPawn")
	{
		TargetObject = TargetSeqObj.GetObjectValue();
		break;
	}

	TargetPawn = XComPawn(TargetObject);
	//`log("TargetPawn =" @ TargetPawn);

	if( TargetPawn == none ) 
	{
		`log("XComPawnToUnit: your input object doesn't have an XComPawn associated with it. (object = " $TargetObject$")");
		OutputLinks[0].bHasImpulse = false;
		return; 
	}

	foreach GetWorldInfo().AllActors(class'XGUnit', kUnit)
	{
		if( kUnit.GetPawn() == TargetPawn )
		{	
			//`log("MATCHED: kUnit =" @ kUnit @ "'" $kUnit.GetCharacter().GetHumanReadableName() );
			TargetUnit = kUnit;
			OutputLinks[0].bHasImpulse = true;
			return; 
		}
	}
	
	//Matching unit was not found:
	`log("XComPawnToUnit: could not find any unit related to your input object. (instance = " $self $"; object = " $TargetObject$")");
	OutputLinks[0].bHasImpulse = false;
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="XComPawn To Unit"
	bCallHandler = false
	
	bAutoActivateOutputLinks=false
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="XComPawn")
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="XGUnit",bWriteable=true,PropertyName=TargetUnit)

}

