//-----------------------------------------------------------
//Show a tactical message in the UI messaging system.
//-----------------------------------------------------------
class SeqAct_DisplayUIMessageBox extends SequenceAction
	dependson(UIDialogueBox)
	native(Level);

enum UIMessageBoxInputType
{
	eUIInputMessageType_OK,
	eUIInputMessageType_OKCancel
};

cpptext
{
	virtual UBOOL UpdateOp(FLOAT DeltaTime);
};

var() EUIDialogBoxDisplay DisplayType;
var() UIMessageBoxInputType InputType;
var() string Title;
var() string Message;
var() string ImagePath;

event Activated()
{
	local XComTacticalController kTacticalController;
	local TDialogueBoxData kDialogData;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		kDialogData.eType     = DisplayType;
		kDialogData.strTitle  = ParseLocalizedPropertyPath(Title);
		kDialogData.strText   = class'UIUtilities_Input'.static.InsertGamepadIconsMessenger(ParseLocalizedPropertyPath(Message));
		
		kDialogData.strAccept = Localize("UIDialogueBox", "m_strDefaultAcceptLabel", "XComGame");

		if (InputType == eUIInputMessageType_OKCancel)
		{
			kDialogData.strCancel = Localize("UIDialogueBox", "m_strDefaultCancelLabel", "XComGame");
		}

		kDialogData.strImagePath = ImagePath;
		kDialogData.fnCallback = OnComplete;
		kDialogData.sndIn = SoundCue'SoundUI.HUDOnCue';
		kDialogData.sndOut = SoundCue'SoundUI.HUDOffCue';
		kDialogData.isModal = true;

		XComPresentationLayer(kTacticalController.Pres).UIRaiseDialog(kDialogData);
		break;
	}

	OutputLinks[0].bHasImpulse = true;
}

simulated public function OnComplete(eUIAction eAction)
{
	OutputLinks[1].bHasImpulse = true;
}

defaultproperties
{
	DisplayType=eDialog_Normal
	InputType=eUIInputMessageType_OK
	ObjCategory="UI/Input"
	ObjName="Spawn Message Box"
	bCallHandler=false
	bLatentExecution=true
	bAutoActivateOutputLinks=false
	VariableLinks.Empty
	OutputLinks(1)=(LinkDesc="Completed")
}
