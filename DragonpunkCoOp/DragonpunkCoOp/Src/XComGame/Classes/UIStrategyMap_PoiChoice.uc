
class UIStrategyMap_PoiChoice extends UIScreen;

var UIBGBox		BG;
var UIText		Title;
var UIText		Desc;
var UIText		Choice0;
var UIText		Choice1;

var UIButton	Button0;
var UIButton	Button1;
var UIButton	CancelButton;

var public localized string m_strButton0;

var StateObjectReference PointReference;

delegate Callback_ChoiceSelected(int ChoiceIndex);
delegate Callback_CancelButton();

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	CreateWidgets();
}
simulated function CreateWidgets()
{
	local XComGameState_PointOfInterest PointState;

	PointState = XComGameState_PointOfInterest(`XCOMHISTORY.GetGameStateForObjectID(PointReference.ObjectID));
	`assert(PointState != none);

	// Spawn UI Controls
	BG				= Spawn(class'UIBGBox', self);
	Title			= Spawn(class'UIText', self);
	Desc			= Spawn(class'UIText', self);

	Choice0		    = Spawn(class'UIText', self);
	Button0			= Spawn(class'UIButton', self);	

	Choice1		    = Spawn(class'UIText', self);
	Button1			= Spawn(class'UIButton', self);

	CancelButton    = Spawn(class'UIButton', self);
	
	// -------------------------------------
	// Set any one-time data 
	SetPosition(450, 300); 
	
	BG.InitBG('BG', -50, -30, 500, 500);

	Title.InitText('Title', PointState.GetDisplayName(), true);
	Title.SetWidth( 400 );

	/*Desc.InitText('Desc', PointState.GetDisplayText());
	Desc.SetPosition( 0, 45 ); 
	Desc.SetWidth( 400 );

	if(PointState.Resolution == PoiRes_Unresolved)
	{
		Choice0.InitText('Choice0');
		Choice0.SetPosition( 10, 160 ); 
		Choice0.SetWidth( 190 );

		Button0.InitButton('Button0', PointState.GetChoiceDisplayText(0), OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
		Button0.SetPosition( 0, 370 );
		CreateButtonTooltip( Button0, "", PointState.GetTooltipText(0));

		if(PointState.GetMyTemplate().Choices.Length > 1)
		{
			Choice1.InitText('Choice1');
			Choice1.SetPosition( 200, 160 ); 
			Choice1.SetWidth( 190 );

			Button1.InitButton('Button1', PointState.GetChoiceDisplayText(1), OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
			Button1.SetPosition( 215, 370 );
			CreateButtonTooltip( Button1, "", PointState.GetTooltipText(1));
		}
	}*/

	CancelButton.InitButton('CancelButton', class'UIUtilities_Text'.default.m_strGenericBack, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	CancelButton.SetPosition( 0, 420 );
}

simulated function CreateButtonTooltip( UIButton kBtn, string sTitle, string sText)
{
	local UITooltip tooltip; 

	if( !Movie.IsMouseActive() ) return; 

	tooltip = Spawn(class'UITextTooltip', Movie.Pres.m_kTooltipMgr); 
	tooltip.Init();

	UITextTooltip(tooltip).sTitle        = sTitle;
	UITextTooltip(tooltip).sBody         = sText;
	tooltip.SetPosition(0, 30); 
	tooltip.targetPath    = string(kBtn.MCPath);

	tooltip.bRelativeLocation = true;
	tooltip.SetAnchor( class'UIUtilities'.const.ANCHOR_TOP_LEFT );
	tooltip.bFollowMouse  = false;

	tooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( tooltip );
}


simulated function OnButtonClicked(UIButton button)
{
	Movie.Stack.Pop(self);

	switch( button )
	{
		case Button0: 
			Callback_ChoiceSelected(0); 
			break;

		case Button1: 
			Callback_ChoiceSelected(1); 
			break;

		case CancelButton: 
			Callback_CancelButton();
			break;
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
			OnButtonClicked(CancelButton);
			break;
		
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			//TODO: Selection + Confirmation 
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
}
