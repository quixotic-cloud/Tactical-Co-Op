//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGMissionControlUI extends XGScreenMgr; 


enum EMCView
{
	eMCView_MainMenu,
	eMCView_Alert,
	eMCView_Abduction,
	eMCView_FCRequest,
	eMCView_ChooseShip
};

struct TMCHeader
{
	var TText txtTitle;
};

struct TMCCounter
{
	var TText txtTitle;
	var TLabeledText txtTotal;
	var TLabeledText txtAbductions;
	var TLabeledText txtTerror;
	var TLabeledText txtUFOCrash;
	var TLabeledText txtUFOLanded;
	var TLabeledText txtAlienBase;
};

struct TMCClock
{
	// Variable only present so I can put a watch on it and avoid a string compare. Efficient solution - sbatista
	var int iMinutes;
	var TText txtDateTime;
	var TText txtTimeScale;
};

struct TMCAlert
{
	var int iAlertType;
	var TText txtTitle;
	var array<TText> arrText;
	var array<TLabeledText> arrLabeledText;
	var TMenu   mnuReplies;
	var TImage  imgAlert;
	var TImage  imgAlert2;
	var TImage  imgAlert3;
	// Arbitrary number that can store alert specific data
	var int iNumber;
};

struct TMCMission
{
	var TImage imgOption;
	var TButtonText txtOption;
	var Color clrOption;
};

struct TMCMenu
{
	var TButtonText txtChooseButton;
	var TText txtMissionsLabel;
	var array<TMCMission> arrMissions;
	var int iHighlight;
};

struct TMCNotice
{
	var TImage imgNotice;
	var TText txtNotice;
	var float fTimer;
};

struct TMCSighting
{
	var TText   txtLocation;
	var TText   txtTimestamp;
	var TImage  imgSighting;
};

struct TMCAbduct
{
	var TMenu mnuSites;

	var array<XGMission> arrAbductions;

	var TText txtCountryName;
	var TText txtPanicLabel;
	var int iPanicLevel;
	
	var int iMissionDiffLevel;
	var TLabeledText txtMissionDifficulty;
	
	var TLabeledText txtReward;

	var TLabeledText txtFundingIncrease;
	var TLabeledText txtCurrFunding;

	var TImage imgBG;

	var int iSelected;
	var int iPrevSelection;	
};

// Elements
var TMCHeader       m_kHeader;
var TMCClock        m_kClock;

var TButtonBar      m_kButtonBar;
var TMCCounter      m_kCounter;
var TMCAlert        m_kCurrentAlert;
var TMCMenu         m_kMenu;
var array<HQEvent>    m_kEvents;
var TMCAbduct       m_kAbductInfo;

var array<int>          m_arrMenuUFOs;
var array<int>          m_arrMenuMissions;
var TButtonText         m_btxtScan;
var TButtonText         m_btxtSatellites;
var array<TMCNotice>    m_arrNotices;
var array<TMCSighting>  m_arrSightings;
var int                 m_iEvent;

var float               m_fFirstTimeTimer;
var int                 m_iLastUpdateDay;
var bool                m_bNarrFilteringAbduction;


var int                 m_intMissionType;
var int                 m_eCountryFromExaltSelection; 

var localized string	m_strLabelDays;
var localized string	m_strLabelHours;

var localized string    m_strLabelMissionCounter;
var localized string    m_strLabelScanUFO;
var localized string    m_strLabelStopScanUFO;
var localized string    m_strLabelUFOPrefix;
var localized string    m_strLabelAlienAbductions;
var localized string    m_strAvailableMissions;
var localized string    m_strLabelUpcomingEvents;
var localized string    m_strLabelNewInterceptors;
var localized string    m_strNewSoldierEvent;
var localized string    m_strLabelSatOperational;
var localized string    m_strLabelShipTransfer;
var localized string    m_strLabelPsiTesting;
var localized string    m_strLabelGeneModification;
var localized string    m_strLabelCyberneticModification;
var localized string    m_strLabelMecRepair;
var localized string    m_strLabelFCRequest;
var localized string    m_strLabelCouncilReport;
var localized string    m_strLabelCovertOperative;
var localized string    m_strLabelItemBuilt;
var localized string    m_strLabelExcavationComplete;
var localized string    m_strLabelFacilityRemoved;
var localized string    m_strLabelNewScientists;
var localized string    m_strLabelNewEngineers;
var localized string    m_strLabelNewSoldiers;
var localized string    m_strLabelNewInterceptorArrival;
var localized string    m_strLabelShipOnline;
var localized string    m_strLabelSatOnline;
var localized string    m_strLabelShipTransferArrival;
var localized string    m_strLabelExitToHQ;
var localized string    m_strLabelAbductionSites;
var localized string    m_strLabelPanicLevel;
var localized string    m_strLabelDifficulty;
var localized string    m_strLabelCurrentFunding;
var localized string    m_strLabelCashPerMonth;
var localized string    m_strLabelNone;
var localized string    m_strLabelNewHire;
var localized string    m_strLabelDoomTrackerTitle;

var localized string    m_strTagAbduction;
var localized string    m_strTagTerrorSite;
var localized string    m_strTagCrash;
var localized string    m_strTagAlienBase;
var localized string    m_strTagLandedUFO;
var localized string    m_strTagTotal;

var localized string    m_strSpeakSatDestroyed;
var localized string    m_strSpeakIncTransmission;

var localized string    m_strNumScientists;
var localized string    m_strNumEngineers;

var localized string    m_strLabelPriorityAlert;
var localized string    m_strLabelGoSituationRoom;
var localized string    m_strLabelNewRecruit;
var localized string    m_strLabelReward;
var localized string    m_strLabelRadarContact;
var localized string    m_strLabelContact;
var localized string    m_strLabelLocation;
var localized string    m_strLabelSize;
var localized string    m_strLabelSpeed;
var localized string    m_strLabelHeading;
var localized string    m_strLabelAltitude;
var localized string    m_strLabelUFOClass;
var localized string    m_strLabelSignatureIdentified;
var localized string    m_strLabelSignatureNotIdentified;
var localized string    m_strLabelUnidentified;
var localized string    m_strLabelNoInterceptors;
var localized string    m_strLabelNoInterceptorsInRange;
var localized string    m_strLabelInterceptorsUnavailable;
var localized string    m_strLabelScrambleInterceptors;
var localized string    m_strLabelIgnoreContact;
var localized string    m_strLabelWarningUFOOnGround;
var localized string    m_strLabelAlienSpecies;
var localized string    m_strLabelAlienCrewSize;
var localized string    m_strLabelAlienObjective;
var localized string    m_strLabelSendSkyranger;
var localized string    m_strLabelIgnore;
var localized string    m_strLabelUFOCrashSite;
var localized string    m_strLabelContactLost;
var localized string    m_strLabelUFOHasLanded;
var localized string    m_strLabelLostContactRequestOrder;
var localized string    m_strLabelWarningContactLost;
var localized string    m_strLabelRecallInterceptors;
var localized string    m_strLabelLostSatFundingSuspending;
var localized string    m_strLabelBonusLost;
var localized string    m_strPanicIncrease;
var localized string    m_strPanicRemedy;
var localized string    m_strLabelOK;
var localized string    m_strLabelStatCountryDestroyed;
var localized string    m_strLabelIncFCCom;
var localized string    m_strLabelFCPresenceRequest;
var localized string    m_strLabelFCFinishedJetTransfer;
var localized string    m_strLabelFCFinishedSatCountry;
var localized string    m_strLabelFCRequestExpired;
var localized string    m_strLabelFCRequestDelayed;
var localized string    m_strLabelCommanderUrgentNews;
var localized string    m_strLabelVisualContact;
var localized string    m_strSkyRangerArrivedSite;
var localized string    m_strLabelBeginAssault;
var localized string    m_strLabelReturnToBase;
var localized string    m_strLabelAbductionsReported;
var localized string    m_strLabelViewAbductionSites;
var localized string    m_strLabelViewAbductionSitesFlying;
var localized string    m_strLabelTerrorCity;
var localized string    m_strLabelFCMission;
var localized string    m_strLabelCountrySignedPactLabel;
var localized string    m_strLabelCountryCountLeave;
var localized string    m_strLabelPanicCountry;
var localized string    m_strLabelPanicCountryLeave;
var localized string    m_strLabelAssaultAlienBase;
var localized string    m_strLabelAssaultTempleShip;
var localized string    m_strLabelTempleShip;
var localized string    m_strLabelSkeletonKey;
var localized string    m_strLabelAssault;
var localized string    m_strlabelWait;
var localized string    m_strLabelMessageFromLabs;
var localized string    m_strLabelTechResearchComplete;
var localized string    m_strLabelAssignNewResearch;
var localized string    m_strLabelCarryOn;
var localized string    m_strLabelMessageFromEngineering;
var localized string    m_strLabelManufactureItemComplete;
var localized string    m_strLabelWorkshopRebate;
var localized string    m_strLabelAssignNewProjects;
var localized string    m_strLabelConstructItemFacilityComplete;
var localized string    m_strLabelAssignNewConstruction;
var localized string    m_strLabelMessageFromFoundry;
var localized string    m_strLabelFoundryItemComplete;
var localized string    m_strLabelMessageFromPsiLabs;
var localized string    m_strLabelPsionicTestingRoundComplete;
var localized string    m_strLabelViewResults;
var localized string    m_strLabelMessageFormBarracks;
var localized string    m_strLabelNumRookiesArrived;
var localized string    m_strLabelVisitBarracks;
var localized string    m_strLabelNumEngineersArrived;
var localized string    m_strLabelVisitEngineering;
var localized string    m_strLabelNumScientistsArrived;
var localized string    m_strLabelVisitLabs;
var localized string    m_strLabelShipRearmed; 
var localized string    m_strLabelSoldierHealed;
var localized string    m_strLabelExaltActivityBody;
var localized string    m_strLabelExaltSelSendOperative;
var localized string    m_strLabelExaltSelSitRoom;
var localized string    m_strLabelExaltSelNotNow;
var localized string    m_strLabelExaltAlertSendSquad;
var localized string    m_strLabelExaltAlertNotNow;
var localized string    m_strLabelExaltAlertTitle;
var localized string    m_strLabelExaltAlertBody;
var localized string    m_strLabelExaltActivityTitle;
var localized string    m_strLabelResearchHackTimeLost;
var localized string    m_strLabelResearchHackNumLabs;
var localized string    m_strLabelResearchHackDataBackup;
var localized string    m_strLabelResearchHackTotalTimeLost;
var localized string    m_strCellHides;

var localized string    m_strLabelGeneModTitle;
var localized string    m_strLabelGeneModBody;
var localized string    m_strLabelAugmentTitle;
var localized string    m_strLabelAugmentBody;
var localized string    m_strLabelGotoBuildMec;
var localized string    m_strGeneModCompleteNotify;

var localized string    m_strLabelItemsRequested;

var localized string    m_strLabelExaltRaidCountryFailSubtitle;
var localized string    m_strLabelExaltRaidCountryFailLeft;
var localized string    m_strLabelExaltRaidContinentFailTitle;
var localized string    m_strLabelExaltRaidContinentFailSubtitle;
var localized string    m_strLabelExaltRaidContinentFailDesc;
var localized string    m_strLabelExaltRaidContinentFailPanic;

var array<string>       m_arrEventStrings;


//------------------------------------------------------
//------------------------------------------------------
function Init( int iView )
{
	super.Init( iView );

	m_kAbductInfo.iSelected = -1;
}
//------------------------------------------------------
function UpdateView()
{
	if( m_iCurrentView == eMCView_MainMenu )
	{
		UpdateButtonHelp();
		UpdateEvents();
	}

	else if( m_iCurrentView == eMCView_ChooseShip )
	{
		`GAME.GetGeoscape().Pause();
	}

	super.UpdateView();
}
//------------------------------------------------------
function UpdateClock()
{
	local TDateTime kDateTime;
	local XComGameState_HeadquartersXCom XComHQ;

	//When showing time, either through time of day or the clock - always show local time
	kDateTime = `GAME.GetGeoscape().m_kDateTime;
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(XComHQ.Get2DLocation(), kDateTime);
	m_kClock.iMinutes = class'X2StrategyGameRulesetDataStructures'.static.GetMinute(kDateTime);

	if(`GAME.GetGeoscape().IsPaused())
		m_kClock.txtDateTime.iState = eUIState_Bad;
	else
		m_kClock.txtDateTime.iState = eUIState_Normal;
}
const OPTION_ALPHA = 175;
//------------------------------------------------------
function UpdateEvents()
{
	m_kEvents.Length = 0;

	class'UIUtilities_Strategy'.static.GetXComHQ().GetEvents( m_kEvents);

	m_iLastUpdateDay = class'X2StrategyGameRulesetDataStructures'.static.GetDay(`GAME.GetGeoscape().m_kDateTime);
}
//------------------------------------------------------
// Making function static because XGMissionControlUI gets created and destroyed several times while the user is navigating the base.
static function int SortEvents( HQEvent e1, HQEvent e2 )
{
	return ( e1.Hours < e2.Hours ) ? 0 : -1;
}

//------------------------------------------------------
function UpdateNotices( float fDeltaT )
{
	local int iNotice;
	local array<int> arrRemove;
	
	for( iNotice = 0; iNotice < m_arrNotices.Length; iNotice++ )
	{
		m_arrNotices[iNotice].fTimer -= fDeltaT;

		if( m_arrNotices[iNotice].fTimer <= 0 )
			arrRemove.AddItem( iNotice );
	}

	for( iNotice = 0; iNotice < arrRemove.Length; iNotice++ )
	{
		m_arrNotices.Remove( arrRemove[iNotice], 1 );
	}
}
//------------------------------------------------------
function UpdateButtonHelp()
{
	local TButtonText txtButton;

	m_kButtonBar.arrButtons.Remove( 0, m_kButtonBar.arrButtons.Length );

	if( m_iCurrentView == eMCView_MainMenu )
	{
		txtButton.strValue = m_strLabelExitToHQ;
		txtButton.iButton = eButton_B;
		m_kButtonBar.arrButtons.AddItem( txtButton );
	}
}
//------------------------------------------------------
simulated function OnReceiveFocus()
{
	if( !GetUIScreen().IsVisible() )
		GetUIScreen().Show();

	`GAME.GetGeoscape().ShowRealEarth();
	`GAME.GetGeoscape().Resume();
}

//------------------------------------------------------
simulated function OnLoseFocus()
{
	GetUIScreen().Hide();
	`GAME.GetGeoscape().Pause();
}

//------------------------------------------------------
event Tick( float fDeltaT )
{
	UpdateClock();

	if( m_iCurrentView != eMCView_MainMenu )
	{
		GoToView( eMCView_MainMenu );
	}
	else
	{
		UpdateNotices( fDeltaT );

		// Update the menu every day, even when time is passing
		if(class'X2StrategyGameRulesetDataStructures'.static.GetDay(`GAME.GetGeoscape().m_kDateTime) != m_iLastUpdateDay)
		{
			UpdateView();
		}
	}
}

DefaultProperties
{
	m_fFirstTimeTimer=3
	m_iEvent = -1;
	m_eCountryFromExaltSelection = -1;
}
