
class UIFacility_CIC extends UIFacility;

var public localized string m_strFacilitySummary;

//----------------------------------------------------------------------------
// MEMBERS

// ------------------------------------------------------------

simulated function RealizeNavHelp()
{
	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M1_WelcomeToLabs'))
	{
		NavHelp.AddBackButton(OnCancel);
	}
	
	NavHelp.AddGeoscapeButton();
}

simulated function FacilitySummary()
{
	Movie.Stack.Push(Spawn(class'UIFacilitySummary', PC.Pres));
}

simulated function ViewObjectives()
{
	Movie.Stack.Push(Spawn(class'UIViewObjectives', PC.Pres), PC.Pres.Get3DMovie());
}

simulated function OnCancel()
{
	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M1_WelcomeToLabs'))
	{
		super.OnCancel();
	}
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
}
