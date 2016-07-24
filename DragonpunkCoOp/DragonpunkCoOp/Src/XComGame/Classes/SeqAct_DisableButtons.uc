/**
 * Disable input Buttons
 */
class SeqAct_DisableButtons extends SequenceAction;

/*  */
var() bool bAllButtons;

/* Buttons to disable */
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

	if( bAllButtons == true )
	{
		AButton = true; BButton = true; XButton = true; YButton = true;
		LTrigger = true; RTrigger = true;
		LBumper = true; RBumper = true;
		L3 = true; R3 = true;
		DPadButton = true; DPadUp = true; DPadDown = true; DPadLeft = true; DPadRight = true;
		Select = true; Start = true;
		MouseDoubleclick = true;
	}

	kDTE = `TACTICALGRI.DirectedExperience;

	if( kDTE != none )
	{
		if( AButton ) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_A );
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_X );
		}

		if( BButton ) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_B );
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_CIRCLE );
		}

		if( XButton ) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_X );
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_SQUARE );
		}

		if( YButton ) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_Y );
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PS3_TRIANGLE );
		}

		if( L3 )        kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_L3 );
		if( R3 )        kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_R3 );
		if( DPadButton) kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_PAD );

		if( LBumper )   kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER );
		if( RBumper )   kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER );
		if( LTrigger )  kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER );
		if( RTrigger )  kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER );

		if( DPadUp ) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_DPAD_UP );
		}
		if( DPadRight ) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_DPAD_RIGHT );
		}
		if( DPadDown )  {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_DPAD_DOWN );
		}
		if( DPadLeft) {
			kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_DPAD_LEFT );
		}

		if( Select )    kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_SELECT );
		if( Start )     kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_BUTTON_START );

		if( MouseDoubleclick) kDTE.BlockButton( class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP );

	}
}

defaultproperties
{
	ObjName="Disable Buttons"
	ObjCategory="Tutorial"

	VariableLinks.Empty
}
