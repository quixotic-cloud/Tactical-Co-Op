//----------------------------------------------------------
//
//-----------------------------------------------------------
class XGScreenMgr extends Actor abstract;

struct TMiniWorld
{
	var TImage imgWorld;
	var TLabeledText ltxtFunding;
	var array<TRect> arrCountries;
	var array<Color> arrColors;
	var array<TText> arrTickerText;
};

var int                     m_iCurrentView;
var string                  m_strVirtualKeyboard;
var TMiniWorld              m_kMap;
var IScreenMgrInterface     m_kInterface;

var localized string m_strCreditsPrefix;

//------------------------------------------------------
function bool Narrative( XComNarrativeMoment Moment, optional bool availableInDebug = false )
{
	return `HQPRES.UINarrative(Moment);
}

//------------------------------------------------------
//------------------------------------------------------
function Init( int iView )
{
	GoToView( iView );
}
//------------------------------------------------------
function UpdateView()
{
	if( GetUIScreen() != none )
		GetUIScreen().GoToView( m_iCurrentView );
}
//------------------------------------------------------
function GoToView( int iView )
{
	if( m_iCurrentView == iView )
		return;

	m_iCurrentView = iView;

	UpdateView();
}
//------------------------------------------------------
function array<string> GetHeaderStrings( array<int> arrCategories )
{
	return class'XGTacticalScreenMgr'.static.GetHeaderStrings( arrCategories );
}
//------------------------------------------------------
function array<int> GetHeaderStates( array<int> arrCategories )
{
	return class'XGTacticalScreenMgr'.static.GetHeaderStates( arrCategories );
}
//------------------------------------------------------
function PlayGoodSound()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_Yes);
}
//------------------------------------------------------
function PlayBadSound()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_No);
}
//------------------------------------------------------
function PlayOpenSound()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_BigOpen);
}
//------------------------------------------------------
function PlayCloseSound()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_BigClose);
}
//------------------------------------------------------
function PlaySmallOpenSound()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_SmallOpen);
}
//------------------------------------------------------
function PlaySmallCloseSound()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_SmallClose);
}
//------------------------------------------------------
function PlayScrollSound()
{
	// TODO: Separate Tactical & Common sounds into Sound Library classes similar to 'XComHQSoundCollection'

	//  1. Create new class: 'XComCommonSoundCollection'
	//  2. Make 'XComHQSoundCollection' derive from 'XComCommonSoundCollection'
	//  3. Create new Collections that derive from 'XComCommonSoundCollection' 
	//     and initialize them in the Appropriate 'XComPresentationLayer'
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
}
//------------------------------------------------------
function PlayToggleSelectContinent()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_ToggleSelectContinent);
}
//------------------------------------------------------
function PlayActivateSoldierPromotion()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_ActivateSoldierPromotion);
}
//------------------------------------------------------
function PlayScienceLabScreenOpen()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_ScienceLabScreenOpen);
}
//------------------------------------------------------
function PlayHologlobeActivation()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_HologlobeActivation);
}
//------------------------------------------------------
function PlayHologlobeDeactivation()
{
	//SOUND().PlaySFX(SNDLIB().SFX_UI_HologlobeDeactivation);
}

//------------------------------------------------------
simulated function OnReceiveFocus()
{
	local IScreenMgrInterface kScreen;
	kScreen = GetUIScreen();

	if( !kScreen.IsVisible() )
		kScreen.Show();
	UpdateView();
}
//------------------------------------------------------
simulated function OnLoseFocus()
{
	// Focus behavior can be overridden in subclasses.
	// Default = Do nothing when losing focus
	//GetUIScreen().Hide();
}

// Screen is about to go away, perform cleanup -- jboswell
simulated function OnRemoved()
{
	`HQPRES.RemoveMgr( self.Class );
}

//------------------------------------------------------
// This is the link to the actual UI screen
function IScreenMgrInterface GetUIScreen()
{
	if( m_kInterface != none ) 
	{
		return m_kInterface;
	}
	else
	{
		`log("XGScreenMgr is unable to find an m_kInterface; defaulting to use the Owner. This should ONLY happen in PROTO screens! " $self,,'uixcom');
		if( Owner == none || IScreenMgrInterface(Owner) == None ) 
			return None; 
		else
			return IScreenMgrInterface(Owner);
	}
}
//------------------------------------------------------
// This function is called externally by the virtual keyboard 
// when the game is waiting for a user entered string
function SetStringFromVirtualKeyboard( string strKeyboard )
{
	m_strVirtualKeyboard = strKeyboard;
}
function CanceledFromVirtualKeyboard()
{
	//Do nothing
}
static function string ConvertCashToString( int iAmount )
{
	local string strNumber, strAmount, strThousand;
	local bool bNegative;

	local string Language;
	local string LocalSeperator; //French and German require a space, Italian requires a "." and the rest, a regular comma

	Language = GetLanguage();

	if( iAmount == 0 )
		return class'XGScreenMgr'.default.m_strCreditsPrefix $ "0"; 
	else if( iAmount < 0 )
		bNegative = true;

	strNumber = string(int(Abs(iAmount)));

	//French and German requires a space, no comma
	if(Language == "FRA" || Language == "DEU")
	{
		LocalSeperator = " ";
	}
	else if(Language == "ITA") // Italian requires a dot
	{
		LocalSeperator = ".";
	}
	else if(Language == "ESN")
	{
		LocalSeperator = ""; //No Space for quantities less than/equal 4 digits 
		if(Len( strNumber) > 4)
		{
			LocalSeperator = " "; //Space for quantities greater than 4 digits 
		}
	}
	else
	{
		LocalSeperator = ",";
	}

	while( Len( strNumber) > 3 )
	{
		strThousand = Right( strNumber, 3 );
		strAmount = LocalSeperator$strThousand$strAmount;
		iAmount /= 1000;
		strNumber = string(iAmount);
	}

	if( iAmount != 0 )
		strAmount = strNumber$strAmount;

	strAmount = class'XGScreenMgr'.default.m_strCreditsPrefix$strAmount;

	if(bNegative)
		strAmount = "-"$strAmount;

	return strAmount;
}

DefaultProperties
{
	m_iCurrentView=-1
}
