//-----------------------------------------------------------
// Show / Hide the UI
//-----------------------------------------------------------
class SeqAct_ToggleUIVisibility extends SequenceAction
	native;

var() bool bShow;

event Activated()
{
	local XComTacticalController kController;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kController)
		break;

	if (kController == none) {
		`warn("Unable to obtain a tactical controller for toggle UI visibility!");
		return;
	}
	
	if ( kController.GetPres() == none )
	{
		`warn("Unable to obtain a presentation layer for toggle UI visibility!");
		return;
	}

	if ( !kController.GetPres().UIIsBusy() )
	{		
		if ( bShow )
			kController.Pres.ScreenStack.Show();
		else
			kController.Pres.ScreenStack.Hide();
	}
	else
	{		
		// UI is busy (likely not loaded yet)... cache value for the battle to check later.

		`log("Caching UI visibility.",,'uixcom');
		if ( bShow )
			kController.Pres.m_ePendingKismetVisibility = eKismetUIVis_Show;
		else
			kController.Pres.m_ePendingKismetVisibility = eKismetUIVis_Hide;
	}
}


// This will actually change the C++ global that ticks the UI!
native function ToggleGfxUI();



defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Show or Hide All"
	bCallHandler = false
	bShow = false

	VariableLinks(0)=(ExpectedType=class'SeqVar_Bool',LinkDesc="Show",PropertyName=bShow)	
}
