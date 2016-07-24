class UITacticalHUD_Countdown extends UIPanel
	implements(X2VisualizationMgrObserverInterface); 

var localized string m_strReinforcementsTitle;
var localized string m_strReinforcementsBody;

simulated function UITacticalHUD_Countdown InitCountdown()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;

	super.OnInit();

	AS_SetCounterText(m_strReinforcementsTitle, m_strReinforcementsBody);

	// Initialize at the correct values 
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		RefreshCounter(AISpawnerState);
		break;
	}

	//And subscribe to any future changes 
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

// --------------------------------------

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;

	foreach AssociatedGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		RefreshCounter(AISpawnerState);
		break;
	}
}

simulated function RefreshCounter(XComGameState_AIReinforcementSpawner AISpawnerState)
{
	if( AISpawnerState.Countdown > 0 )
	{
		AS_SetCounterTimer(AISpawnerState.Countdown);
		Show(); 
	}
	else
	{
		Hide();
	}
}

simulated function AS_SetCounterText( string title, string label )
{ Movie.ActionScriptVoid( MCPath $ ".SetCounterText" ); }

simulated function AS_SetCounterTimer( int iTurns )
{ Movie.ActionScriptVoid( MCPath $ ".SetCounterTimer" ); }


// --------------------------------------
defaultproperties
{
	MCName = "theCountdown";
	bAnimateOnInit = false;
	bIsVisible = false; // only show when gameplay needs it
	Height = 80; // used for objectives placement beneath this element as well. 
}