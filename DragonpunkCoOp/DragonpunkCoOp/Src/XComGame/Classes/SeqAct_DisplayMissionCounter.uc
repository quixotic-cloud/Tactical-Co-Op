//-----------------------------------------------------------
//Show a tactical message in the UI messaging system, allowed to persist until removed.
//-----------------------------------------------------------
class SeqAct_DisplayMissionCounter extends SequenceAction
	dependson(UIObjectiveList, XComTacticalMissionManager);

var() string CounterHaveImage;
var() string CounterAvailableImage;
var() string CounterLostImage;

var int CounterHaveAmount;
var int CounterHaveMin;
var int CounterAvailableAmount;
var int CounterLostAmount;
var int GroupID; 

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_ObjectivesList ObjectiveList;
	local ObjectiveDisplayInfo DisplayInfo;
	local string MissionType;

	History = `XCOMHISTORY;

	NewGameState = History.GetStartState();
	if (NewGameState == None)
	{		
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Display Mission Counter");
	}

	foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
	{
		break;
	}

	ObjectiveList = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList', 
												 ObjectiveList != none ? ObjectiveList.ObjectID : -1));

	MissionType = `TACTICALMISSIONMGR.ActiveMission.sType;
	if(InputLinks[2].bHasImpulse)
	{
		ObjectiveList.HideObjectiveDisplay(MissionType, 
											class'XComGameState_ObjectivesList'.const.CounterDisplayLabel);
	}
	else
	{
		if(!ObjectiveList.GetObjectiveDisplay(MissionType, 
												class'XComGameState_ObjectivesList'.const.CounterDisplayLabel,
												DisplayInfo))
		{
			// there is no current line for this mission text yet, so add a new one
			DisplayInfo.MissionType = MissionType;
			DisplayInfo.DisplayLabel = class'XComGameState_ObjectivesList'.const.CounterDisplayLabel;
		}

		// update the status
		DisplayInfo.CounterHaveImage = CounterHaveImage;
		DisplayInfo.CounterAvailableImage = CounterAvailableImage;
		DisplayInfo.CounterLostImage = CounterLostImage;
		DisplayInfo.CounterHaveAmount = CounterHaveAmount;
		DisplayInfo.CounterHaveMin = CounterHaveMin;
		DisplayInfo.CounterAvailableAmount = CounterAvailableAmount;
		DisplayInfo.CounterLostAmount = CounterLostAmount;
		DisplayInfo.GroupID = GroupID;

		// and add/update it in the state object
		ObjectiveList.SetObjectiveDisplay(DisplayInfo);
	}

	NewGameState.AddStateObject(ObjectiveList);

	if (NewGameState != History.GetStartState())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Display Mission Counter"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Show")
	InputLinks(1)=(LinkDesc="Remove")
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int',LinkDesc="Current",PropertyName=CounterHaveAmount)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Int',LinkDesc="Target",PropertyName=CounterHaveMin)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="Available",PropertyName=CounterAvailableAmount)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Int',LinkDesc="Lost",PropertyName=CounterLostAmount)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Int',LinkDesc="GroupID",PropertyName=GroupID)
}
