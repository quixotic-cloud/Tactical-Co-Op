/**
 * Enable input buttons
 */
class SeqAct_EnableButtons extends SequenceAction;

/*  */
var() bool bAllButtons;

/* Buttons to enable */
var() bool AButton;
var() bool BButton;
var() bool XButton;
var() bool YButton;

var() bool LTrigger;
var() bool RTrigger;

var() bool LBumper;
var() bool RBumper;

var() bool L3;
var() bool R3;

var() bool DPadButton;
var() bool DPadUp;
var() bool DPadDown;
var() bool DPadLeft;
var() bool DPadRight;

var() bool Select;
var() bool Start;

var() bool MouseDoubleclick;

event Activated()
{
	local XComDirectedTacticalExperience kDTE;

	kDTE = `TACTICALGRI.DirectedExperience;

	if( kDTE != none )
	{
		if( bAllButtons )
		{
			kDTE.UnblockAllButtons();
		}
		else
		{
			if( AButton ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_A );
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_X );
			}

			if( BButton ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_B );
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_CIRCLE );
			}

			if( XButton ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_X );
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_SQUARE );
			}

			if( YButton ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_Y );
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_TRIANGLE );
			}

			if( L3 )        kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_L3 );
			if( R3 )        kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_R3 );
			if( DPadButton) kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PAD );

			if( LBumper )   kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER );
			if( RBumper )   kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER );
			if( LTrigger )  kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER );
			if( RTrigger )  kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER );

			if( DPadUp ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_DPAD_UP );
			}
			if( DPadRight ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_DPAD_RIGHT );
			}
			if( DPadDown ) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_DPAD_DOWN );
			}
			if( DPadLeft) {
				kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_DPAD_LEFT );
			}

			if( Select )    kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_SELECT );
			if( Start )     kDTE.UnblockButton( class'UIUtilities_Input'.const.FXS_BUTTON_START );

			if( MouseDoubleclick ) kDTE.Unblockbutton( class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP );
		}
	}
}


defaultproperties
{
	ObjName="Enable Buttons"
	ObjCategory="Tutorial"

	VariableLinks.Empty
}
