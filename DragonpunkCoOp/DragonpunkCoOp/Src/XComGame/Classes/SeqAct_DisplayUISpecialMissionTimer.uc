//-----------------------------------------------------------
//Update the text forthe Special Mission countdown timer. 
//-----------------------------------------------------------
class SeqAct_DisplayUISpecialMissionTimer extends SequenceAction;

enum TimerColors
{
	Normal_Blue,
	Bad_Red,
	Good_Green,
	Disabled_Grey
};

var int     NumTurns;
var string  DisplayMsgTitle;
var string  DisplayMsgSubtitle;

var() TimerColors TimerColor;

event Activated()
{
	local int UIState;
	local bool ShouldShow;
	local XComGameState NewGameState;
	local XComGameState_UITimer UiTimer;

	switch(TimerColor)
	{
		case Normal_Blue:   UIState = eUIState_Normal;     break;
		case Bad_Red:       UIState = eUIState_Bad;        break;
		case Good_Green:    UIState = eUIState_Good;       break;
		case Disabled_Grey: UIState = eUIState_Disabled;   break;
	}
	ShouldShow = InputLinks[0].bHasImpulse;
	
	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
	NewGameState = class 'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Objective Timer changes");
	if (UiTimer == none)
		UiTimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer'));
	else
		UiTimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer', UiTimer.ObjectID));

	UiTimer.UiState = UIState;
	UiTimer.ShouldShow = ShouldShow;
	UiTimer.DisplayMsgTitle = DisplayMsgTitle;
	UiTimer.DisplayMsgSubtitle = DisplayMsgSubtitle;
	UiTimer.TimerValue = NumTurns;
	
	NewGameState.AddStateObject(UiTimer);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Modify Mission Timer"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	InputLinks(0)=(LinkDesc="Show")
	InputLinks(1)=(LinkDesc="Hide")

	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0) = (ExpectedType=class'SeqVar_Int',LinkDesc="# Turns Remaining",PropertyName=NumTurns)
	VariableLinks(1) = (ExpectedType = class'SeqVar_String', LinkDesc = "Display Message Title", bWriteable = true, PropertyName = DisplayMsgTitle)
	VariableLinks(2) = (ExpectedType = class'SeqVar_String', LinkDesc = "Display Message Subtitle", bWriteable = true, PropertyName = DisplayMsgSubtitle)

	TimerColor = Bad_Red;
}
