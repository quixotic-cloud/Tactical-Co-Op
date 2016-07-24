class UIShell_NavHelpScreen extends UIScreen;

var UINavigationHelp NavHelp;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();

	XComShellPresentationLayer(InitController.Pres).m_kMPShellManager.NavHelp = NavHelp;
}

DefaultProperties
{
	bHideOnLoseFocus = false;
	bProcessMouseEventsIfNotFocused = true
}