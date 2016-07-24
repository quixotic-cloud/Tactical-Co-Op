/**
 * Prints text and values in debug builds
 */
class SeqAct_DebugOutput extends SequenceAction;

var string DebugText;

event Activated()
{
`if(`notdefined(FINAL_RELEASE))

	local SeqVarLink kVarLink;
	local SequenceVariable kSeqVar; 
	local string strDebugVarString;

	PrivateLog("SeqAct_DebugOutput:");
	strDebugVarString = DebugText == "" ? "No debug text" : DebugText;

	foreach VariableLinks(kVarLink)
	{
		if(kVarLink.LinkDesc == "Debug Values")
		{
			foreach kVarLink.LinkedVariables(kSeqVar)
			{
				strDebugVarString $= ", " $ GetSeqVarText(kSeqVar);
			}
		}
	}

	PrivateLog(strDebugVarString);

`endif
}

private function string GetSeqVarText(SequenceVariable kSeqVar)
{
	local string strText;
	local XGUnit kUnit;

	strText = kSeqVar.VarName $ ": ";

	if(kSeqVar.IsA('SeqVar_Bool'))
	{
		strText $= SeqVar_Bool(kSeqVar).bValue != 0 ? "true" : "false";
	}
	else if(kSeqVar.IsA('SeqVar_Int'))
	{
		strText $= SeqVar_Int(kSeqVar).IntValue;
	}
	else if(kSeqVar.IsA('SeqVar_Float'))
	{
		strText $= SeqVar_Float(kSeqVar).FloatValue;
	}
	else if(kSeqVar.IsA('SeqVar_String'))
	{
		strText $= SeqVar_String(kSeqVar).StrValue;
	}
	else if(kSeqVar.IsA('SeqVar_Object'))
	{
		// special case some objects to get more helpful information out of them
		if(SeqVar_Object(kSeqVar).GetObjectValue().IsA('XGUnit'))
		{
			kUnit = XGUnit(SeqVar_Object(kSeqVar).GetObjectValue());
			strText $= "Unit: " $ kUnit.SafeGetCharacterFullName();
		}
		else if(SeqVar_Object(kSeqVar).GetObjectValue().IsA('XComUnitPawn'))
		{
			kUnit = XGUnit(XComUnitPawn(SeqVar_Object(kSeqVar).GetObjectValue()).GetGameUnit());
			strText $= "Unit: " $ kUnit.SafeGetCharacterFullName();
		}
		else
		{
			// any other object types
			strText $= SeqVar_Object(kSeqVar).GetObjectValue().Name;
		}
	}

	return strText;
}

private function PrivateLog(string strText)
{
	local XComTacticalGRI kTacticalGRI;

	`log(strText);

	kTacticalGRI = `TACTICALGRI;
	if(kTacticalGRI != none)
	{
		kTacticalGRI.GetALocalPlayerController().ClientMessage(strText,,6.0);
	}
}

defaultproperties
{
	ObjName="Debug Output"
	ObjCategory="Debug"
	bCallHandler=false

	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Debug Text",PropertyName=DebugText)
	VariableLinks(1)=(ExpectedType=class'SequenceVariable',LinkDesc="Debug Values")
}
