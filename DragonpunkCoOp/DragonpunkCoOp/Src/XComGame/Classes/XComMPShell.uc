class XComMPShell extends XComShell;

event PostLogin( PlayerController NewPlayer )
{
	super.PostLogin(NewPlayer);

	//XComShellPresentationLayer(m_kController.Pres).UIMPShell_MainMenu();
}