//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGBuildUI extends XGScreenMgr;

enum EBuildView
{
	eBuildView_Main,
	eBuildView_Menu,
};

enum EBuildCursorState
{
	eBCS_Excavate,
	eBCS_BuildFacility,
	eBCS_BuildAccessLift,
	eBCS_RemoveFacility,
	eBCS_BeginConstruction,
	eBCS_Cancel,
	eBCS_CantDo,
};

struct TFacilityTable
{
	var TTableMenu              mnuOptions;
	var array<int>              arrFacilities;
};

struct TUIBaseTile
{
	var XComGameState_HeadquartersRoom kRoom;
	var TText   txtLabel;
	var TText   txtCounter;
	var TImage  imgTile;
	var bool bDisabled; 
};


struct TBuildCursor
{
	var int x;
	var int y;
	var int iSize;
	var int iCursorState;
	var int iUIState;
	var TButtonText txtLabel;
	var TText txtCost;
	var TText txtHelp;
};

struct TBuildHeader
{
	var TLabeledText txtCash;
	var TLabeledText txtSupplies;
	var TLabeledText txtPower;
	var TLabeledText txtElerium;
	var TLabeledText txtAlloys;
};

// UI Elements

// Elements
var array<TUIBaseTile>      m_arrTiles;
var TBuildCursor            m_kCursor;
var TBuildHeader            m_kHeader;
var TFacilityTable          m_kTable;

var bool                    m_bFacilityBuilt;
var bool                    m_bCantRemove;

var localized string        m_strLabelCancel;
var localized string        m_strLabelRemove;
var localized string        m_strLabelBuildLift;
var localized string        m_strLabelBuildFacility;
var localized string        m_strLabelExcavate;
var localized string        m_strLabelRequiredBuild;
var localized string        m_strLabelExcavating;
var localized string        m_strLabelSteam;
var localized string        m_strLabelDays;
var localized string        m_strLabelRemoving;
var localized string        m_strLabelCost;
var localized string        m_strOk;

var localized string        m_strErrNeedLift;
var localized string        m_strErrNeedExcavating;
var localized string        m_strErrNeedFunds;
var localized string        m_strErrNeedPower;
var localized string        m_strErrNeedSteam;
var localized string        m_strPriority;

var localized string        m_strRemoveTitle;
var localized string        m_strRemoveBody;
var localized string        m_strRemoveOK;
var localized string        m_strRemoveCancel;

var localized string        m_strCantRemoveTitle;
var localized string 		m_strPowerCantRemoveBody;
var localized string 		m_strCaptiveCantRemoveBody;
var localized string 		m_strCaptiveRemoveBody;
var localized string 		m_strWorkshopCantRemoveBody;
var localized string 		m_strUplinkCantRemoveBody;
var localized string 		m_strFoundryCantRemoveBody;
var localized string 		m_strPsiLabsCantRemoveBody;

var localized string        m_strCancelConstructionTitle;
var localized string        m_strCancelConstructionBody;
var localized string        m_strCancelConstructionOK;
var localized string        m_strCancelConstructionCancel;

var localized string        m_strDisabledForTutorial;

var int                     m_iLastTileIndex;
//------------------------------------------------------
//------------------------------------------------------
function Init( int iView )
{
	m_kCursor.x = 0;
	m_kCursor.y = 1;

	super.Init( iView );
}
//------------------------------------------------------
// Update the appropriate elements based on the View type
function UpdateView()
{
	UpdateHeader();

	switch( m_iCurrentView )
	{
	case eBuildView_Menu:
		UpdateFacilityTable();
		break;
	}

	super.UpdateView();
}
//------------------------------------------------------
// Input Events
//------------------------------------------------------
//------------------------------------------------------
function OnCursorLeft()
{
	if( m_kCursor.x == 0 )
	{
		PlayBadSound();
		return;
	}

	PlayScrollSound();
	UpdateView();
}

//------------------------------------------------------
function SetCursorAt( int tileX, int tileY )
{
	m_kCursor.x = tileX;
	m_kCursor.y = tileY;
}

function bool CanChoseFacility(int iOption)
{
	if( m_kTable.mnuOptions.arrOptions[iOption].iState == eUIState_Disabled )
	{
		PlayBadSound();
		return false;
	}
	return true;
}
//------------------------------------------------------
function OnLeaveTable()
{
	GoToView( eBuildView_Main );
	PlaySmallCloseSound();
}
//------------------------------------------------------
function OnLeaveScreen()
{
	class'UIUtilities_Sound'.static.PlayCloseSound();
}
//------------------------------------------------------
function OnFacilityOption()
{
	UpdateView();
}
//------------------------------------------------------
function UpdateHeader()
{
	//m_kHeader.txtPower = GetResourceText(eResource_Power);
	//m_kHeader.txtSupplies = GetResourceText(eResource_Supplies);
}
//------------------------------------------------------
function UpdateFacilityTable()
{

}

//------------------------------------------------------
function int GetCursorLevel()
{
	return m_kCursor.y;
}

//------------------------------------------------------
simulated function OnReceiveFocus()
{
	if( !GetUIScreen().IsVisible() )
		GetUIScreen().Show();
	UpdateView();
}

DefaultProperties
{
}
