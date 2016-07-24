class SeqAct_XComKVP_Set extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var() string Key;
var() int Value;


event Activated()
{
	OutputLinks[0].bHasImpulse = TRUE;
}

function ModifyKismetGameState(out XComGameState GameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(GameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	GameState.AddStateObject(XComHQ);

	if (XComHQ != none)
	{
		XComHQ.SetGenericKeyValue(Key, Value);
	}
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks);

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjName = "Key Value Pair Set"
	ObjCategory = "Procedural Missions"
	bCallHandler = false

	bConvertedForReplaySystem = true

	OutputLinks(0) = (LinkDesc = "Out")

	VariableLinks.Empty;
	VariableLinks(0) = (ExpectedType = class'SeqVar_String', LinkDesc = "Key String", PropertyName = Key)
	VariableLinks(1) = (ExpectedType = class'SeqVar_Int', LinkDesc = "Value", PropertyName = Value)
}