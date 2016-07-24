//-----------------------------------------------------------
//Show a special mission arrow pointing at an actor. 
//-----------------------------------------------------------
class SeqAct_DisplayUIArrowPointingTo2DLoc extends SequenceAction
	dependson(XGTacticalScreenMgr);

var Vector Location;
var() float Offset;
var() int CounterValue; 
var() Texture2D Icon;

private function EUIState GetUIStateForColorInput()
{
	if(InputLinks[1].bHasImpulse) // red
		return eUIState_Bad;
	else if(InputLinks[2].bHasImpulse) // blue
		return eUIState_Normal;
	else if(InputLinks[3].bHasImpulse) // gray
		return eUIState_Disabled;
	else
		return eUIState_Warning; // yellow, also default case just in case
}

event Activated()
{
	local string IconPath;

	if(InputLinks[4].bHasImpulse)
	{
		class'XComGameState_IndicatorArrow'.static.RemoveArrowPointingAtLocation(Location);
	}
	else
	{
		IconPath = class'UIUtilities_Image'.static.GetImgPathFromResource(Icon);
		class'XComGameState_IndicatorArrow'.static.CreateArrowPointingAtLocation(Location, Offset, GetUIStateForColorInput(), CounterValue, IconPath);
	}
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Arrow Pointing at Location"
	Offset=128
	CounterValue = -1;
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	InputLinks.Empty;
	InputLinks(0)=(LinkDesc="Yellow")
	InputLinks(1)=(LinkDesc="Red")
	InputLinks(2)=(LinkDesc="Blue")
	InputLinks(3)=(LinkDesc="Gray")
	InputLinks(4)=(LinkDesc="Hide")

	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=Location)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Float',LinkDesc="Offset",PropertyName=Offset)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Int',LinkDesc="Counter",PropertyName=CounterValue)
}
