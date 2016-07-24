class SeqAct_DisplayUIHelp extends SequenceAction;

var() string Message;
var() string MessagePC;
var() float DisplayTime;

event Activated()
{
	local XComTacticalController kTacticalController;
	local XComPresentationLayer Pres;
	local string sDisplayHelp;
	local byte bKeysNotFound;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		Pres = XComPresentationLayer(kTacticalController.Pres);
		if (InputLinks[0].bHasImpulse)
		{
			if (Pres.Get2DMovie().IsMouseActive() && Len(MessagePC) > 0)
			{
				sDisplayHelp = class'UIUtilities_Input'.static.InsertAbilityKeys(ParseLocalizedPropertyPath(MessagePC),bKeysNotFound,Pres.m_kKeybindingData,kTacticalController.PlayerInput);
				if( bKeysNotFound > 0 )
				{
					Pres.GetTacticalHUD().ShowTutorialHelp(class'UIUtilities_Input'.static.InsertPCIcons(ParseLocalizedPropertyPath(MessagePC$"NoKeymapping")), DisplayTime);
				}
				else
				{
					Pres.GetTacticalHUD().ShowTutorialHelp(class'UIUtilities_Input'.static.InsertPCIcons(sDisplayHelp), DisplayTime);
				}
			}
			else if(Len(Message) > 0 )
			{
				Pres.GetTacticalHUD().ShowTutorialHelp(class'UIUtilities_Input'.static.InsertGamepadIconsMessenger(ParseLocalizedPropertyPath(Message)), DisplayTime);
			}
		}
		else
		{
			Pres.GetTacticalHUD().HideTutorialHelp();
		}
		break;
	}

	OutputLinks[0].bHasImpulse = true;
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Spawn Help Box"
	bCallHandler=false

	InputLinks(0)=(LinkDesc="Show")
	InputLinks(1)=(LinkDesc="Hide")
	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Display Message",PropertyName=Message)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Float',LinkDesc="Display Time",bWriteable=true,PropertyName=DisplayTime)
}
