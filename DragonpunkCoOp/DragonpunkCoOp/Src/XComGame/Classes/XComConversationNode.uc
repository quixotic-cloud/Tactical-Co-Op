class XComConversationNode extends SoundNodeConcatenator
	native;

var(XCom) bool bMatineeContainsVoice;  // If this is true, we don't play any of the sounds because the matinee will do that.
var(XCom) name MatineeToPlay;

var bool bModal;
var bool bFinished;

var bool bDialogLineFinished;

simulated function Reset(bool bIsModal)
{
	bModal = bIsModal;
	bFinished = false;
	bDialogLineFinished = false;

	//`log("ConversationNode RESET - "@Name);
}

// Called from native when one piece of dialog has finished
event DialogLineFinished()
{
	bDialogLineFinished = true;
//	XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).Pres.m_kNarrativeUIMgr.NotifyDialogLineFinished();
}

native simulated function string GetCurrentDialogue(AudioComponent AudioComponent);
native simulated function float GetCurrentDialogueDuration(AudioComponent AudioComponent);

native simulated function name GetCurrentSpeaker(AudioComponent AudioComponent);

native simulated function SkipToNextDialogueLine(AudioComponent AudioComponent);

native simulated function GetFaceFxInfo(AudioComponent AudioComponent, out FaceFXAnimSet FaceFxAnimSetRef, out string FaceFXGroupName, out string FaceFXAnimName);
