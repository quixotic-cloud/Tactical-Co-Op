
class UIStrategyMap_Outpost extends UIScreen;

var UIPanel			m_kContainer;
var UIBGBox		m_kBG;
var UIText		m_kTitle;
var UIText		m_kText;

var UIText		m_kText_Button0Alt;
var UIText      m_kText_Button1Alt;
var UIText      m_kText_Button2Alt;


var UIButton	m_kButton0;
var UIButton	m_kButton1;
var UIButton	m_kButton2;
var UIButton	m_kButton3;
var UIButton	m_kExitButton;

var public localized string m_strButton0;
var public localized string m_strButton0Alt;
var public localized string m_strButton1;
var public localized string m_strButton1Alt;
var public localized string m_strButton2;
var public localized string m_strButton2Alt;
var public localized string m_strButton3;
var public localized string m_strTitle;
var public localized string m_strText;

delegate Callback_Button0( UIStrategyMap_Outpost kScreen );
delegate Callback_Button1( UIStrategyMap_Outpost kScreen );
delegate Callback_Button2( UIStrategyMap_Outpost kScreen );
delegate Callback_ExitButton();

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	CreateWidgets();
	RefreshData();
}
simulated function CreateWidgets()
{
	//=======================================================================================
	//=======================================================================================
	//X-Com 2 UI - new dynamic UI system
	//
	// Spawn UI Controls
	m_kContainer		= Spawn(class'UIPanel', self);

	m_kBG				= Spawn(class'UIBGBox', m_kContainer);
	m_kTitle			= Spawn(class'UIText', m_kContainer);
	m_kText				= Spawn(class'UIText', m_kContainer);
	
	m_kButton0			= Spawn(class'UIButton', m_kContainer);
	m_kText_Button0Alt	= Spawn(class'UIText', m_kContainer);
	
	m_kButton1			= Spawn(class'UIButton', m_kContainer);
	m_kText_Button1Alt  = Spawn(class'UIText', m_kContainer);

	m_kButton2			= Spawn(class'UIButton', m_kContainer);
	m_kText_Button2Alt  = Spawn(class'UIText', m_kContainer);

	m_kButton3          = Spawn(class'UIButton', m_kContainer);

	m_kExitButton       = Spawn(class'UIButton', m_kContainer);
	
	// -------------------------------------
	// Set any one-time data 
	m_kContainer.InitPanel('outpostInfoContainer');
	m_kContainer.SetPosition(450, 300); 
	m_kBG.InitBG('outpostBG', 0, 0, 450, 190);

	m_kTitle.InitText('outpostTitle', m_strTitle, true);
	m_kTitle.SetPosition( 10, 10 ); 
	m_kTitle.SetWidth( 200 );

	m_kText.InitText('outpostText', m_strText, true);
	m_kText.SetPosition( 10, 45 ); 
	m_kText.SetWidth( 200 );

	m_kButton0.InitButton('button0', m_strButton0, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kButton0.SetPosition( 260, 40 );

	m_kText_Button0Alt.InitText('missionText', class'UIUtilities_Text'.static.GetColoredText(m_strButton0Alt, eUIState_Good), true);
	m_kText_Button0Alt.SetPosition( 260, 40 ); 
	m_kText_Button0Alt.SetWidth( 200 );

	m_kButton1.InitButton('button1', m_strButton1, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kButton1.SetPosition( 260, 70 );

	m_kText_Button1Alt.InitText('soldierText', class'UIUtilities_Text'.static.GetColoredText(m_strButton1Alt, eUIState_Bad), true);
	m_kText_Button1Alt.SetPosition( 260, 70 ); 
	m_kText_Button1Alt.SetWidth( 200 );

	m_kButton2.InitButton('button2', m_strButton2, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kButton2.SetPosition( 260, 100 );

	m_kText_Button2Alt.InitText('blackMarketText', class'UIUtilities_Text'.static.GetColoredText(m_strButton2Alt, eUIState_Bad), true);
	m_kText_Button2Alt.SetPosition( 260, 100 ); 
	m_kText_Button2Alt.SetWidth( 200 );

	m_kButton3.InitButton('', m_strButton3, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kButton3.SetPosition( 260, 130 );

	m_kExitButton.InitButton('cancelButton', "LEAVE OUTPOST", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kExitButton.SetPosition( 10, 160 );
}

simulated function RefreshData()
{
	m_kTitle.SetText( m_strTitle );

	m_kButton0.Show();
	m_kText_Button0Alt.Hide();
	
	m_kButton1.Show();
	m_kText_Button1Alt.Hide();

	m_kButton2.Show();
	m_kText_Button2Alt.Hide();
}
simulated function OnButtonClicked(UIButton button)
{
	switch( button )
	{
		case m_kButton0: 
			//Movie.Stack.Pop(self);
			Callback_Button0(self); 
			break;

		case m_kButton1: 
			`log( "Clicked button 1");
			//Movie.Stack.Pop(self);
			Callback_Button1(self);
			break;

		case m_kButton2: 
			`log( "Clicked button 2");
			//Movie.Stack.Pop(self);
			Callback_Button2(self);
			return; 
			break;

		case m_kButton3:
			Movie.Stack.Pop(self);
			Movie.Stack.Push( Spawn(class'UIBlackMarket_Sell', self) );
			break;

		case m_kExitButton: 
			Movie.Stack.Pop(self);
			Callback_ExitButton();
			return; 
			break;
	}
	//Refresh data after we make the callbacks, since some buttons and such may have deactivated.
	RefreshData();
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
			OnButtonClicked(m_kExitButton);
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
	MCName          = "theScreen";
	InputState    = eInputState_Evaluate;
}
