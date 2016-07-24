////// XComShellController.uc ///////////////////////
// ~khirsch
//=============================================================================

class XComShellController extends XComPlayerController;

var XComShell  m_kShell;

var int        m_iMPRankedDeathmatchRank;

// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
simulated function XComShellPresentationLayer GetPres()
{
	return XComShellPresentationLayer(Pres);
}

/**
 * Looks at the current game state and uses that to set the
 * rich presence strings
 *
 * Licensees (that's us!) should override this in their player controller derived class
 */
reliable client function ClientSetOnlineStatus()
{
	`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_MainMenu);
}

defaultproperties
{
	CameraClass=class'XComHeadquartersCamera'
	CheatClass=class'XComGame.XComShellCheatManager'
	InputClass=class'XComGame.XComShellInput'
	PresentationLayerClass=class'XComGame.XComShellPresentationLayer'
}