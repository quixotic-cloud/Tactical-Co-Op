class SeqAct_XComKVP_Get extends SequenceAction;

var() string Key;
var int Value;


event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Value = -1;

	if (XComHQ != none)
	{
		Value = XComHQ.GetGenericKeyValue(Key);
	}
	
	if (Value == -1)
	{
		OutputLinks[2].bHasImpulse = TRUE;
	}
	else
	{
		OutputLinks[1].bHasImpulse = TRUE;
	}

	OutputLinks[0].bHasImpulse = TRUE;
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjName = "Key Value Pair Get"
	ObjCategory = "Procedural Missions"
	bCallHandler = false

	bConvertedForReplaySystem = true

	OutputLinks(0) = (LinkDesc = "Out")
	OutputLinks(1) = (LinkDesc = "Has Value")
	OutputLinks(2) = (LinkDesc = "No Value")

	VariableLinks.Empty;
	VariableLinks(0) = (ExpectedType = class'SeqVar_String', LinkDesc = "Key String", PropertyName = Key)
	VariableLinks(1) = (ExpectedType = class'SeqVar_Int', LinkDesc = "Value", PropertyName = Value, bWriteable = true)
}