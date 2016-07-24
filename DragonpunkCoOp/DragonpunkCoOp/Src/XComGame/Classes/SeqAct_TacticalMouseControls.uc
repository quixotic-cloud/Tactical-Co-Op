class SeqAct_TacticalMouseControls extends SequenceAction;

var() bool bDisablePreviousSoldier;
var() bool bDisableNextSoldier;
var() bool bDisableSoldierInfo;
var() bool bDisableEndTurn;
var() bool bDisableCameraRotate;

event Activated()
{
	local XComTacticalController kTacticalController;
	local UITacticalHUD kHUD;
	
	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		kHUD = XComPresentationLayer(kTacticalController.Pres).GetTacticalHUD();
		if( kHUD.m_kMouseControls != none )
		{
			kHUD.m_kMouseControls.SetButtonState(0, bDisableEndTurn ? eUIState_Disabled : eUIState_Normal);
			kHUD.m_kMouseControls.SetButtonState(1, bDisableSoldierInfo ? eUIState_Disabled : eUIState_Normal);
			kHUD.m_kMouseControls.SetButtonState(2, bDisablePreviousSoldier ? eUIState_Disabled : eUIState_Normal);
			kHUD.m_kMouseControls.SetButtonState(3, bDisableNextSoldier ? eUIState_Disabled : eUIState_Normal);
			kHUD.m_kMouseControls.SetButtonState(4, bDisableCameraRotate ? eUIState_Disabled : eUIState_Normal);
			kHUD.m_kMouseControls.SetButtonState(5, bDisableCameraRotate ? eUIState_Disabled : eUIState_Normal);
		}
		break;
	}
}


defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="Tactical Mouse HUD"
}
