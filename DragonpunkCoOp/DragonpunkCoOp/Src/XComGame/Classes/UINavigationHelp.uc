
class UINavigationHelp extends UIPanel
	config(GameData);

const HELP_OPTION_IDENTIFIER = "buttonNavHelp";

// Must match enum values in XComButtonIconPC.as
enum EButtonIconPC
{
	eButtonIconPC_Prev_Soldier,     // 0
	eButtonIconPC_Next_Soldier,     // 1
	eButtonIconPC_Hologlobe,        // 2
	eButtonIconPC_Details,          // 3
	eButtonIconPC_Back,             // 4
	eButtonIconPC_Scan,             // 5
	eButtonIconPC_Land,             // 6
	eButtonIconPC_LiftOff,          // 7
	eButtonIconPC_Skyranger,        // 8
	eButtonIconPC_Scanimate			// 9
};

// MODIFY THESE BEFORE CALLING INIT
// Default constants that let us modify visual layout of help options.
var public int LEFT_HELP_CONTAINER_PADDING;
var public int RIGHT_HELP_CONTAINER_PADDING;
var public int CENTER_HELP_CONTAINER_PADDING;

// SOME HELPER LOCALIZED STRINGS
var localized string m_strBackButtonLabel;

//To find the geoscape for hotlinking. 
var config name GeoscapeFacility;
var UIPanel AttentionPulse;
var UILargeButton ContinueButton;

var UIPanel LeftContainer;
var UIPanel CenterContainer;
var UIPanel RightContainer;

var bool bBackButton;
var bool bContinueButton;
var bool bGeoscapeButton;

// DELEGATES
var array< delegate<OnButtonClickedDelegate> >  m_arrButtonClickDelegates;

public delegate OnHelpBarInitializedDelegate();
public delegate OnButtonClickedDelegate();
delegate OnGeoscapeClickedDelegate();

delegate OnContinueClickedDelegate(UIButton Button);
delegate OnClickedContinueDelegate();


//==============================================================================
//		INITIALIZATION & INPUT:
//==============================================================================
simulated function UINavigationHelp InitNavHelp(optional name InitName)
{
	InitPanel(InitName);

	// If we're linking with an existing Flash help bar, don't override position / padding
	if(InitName == '')
	{
		MC.FunctionVoid("AnchorToBottom");
		SetY( -5 );

		MC.FunctionNum("SetLeftHelpPadding", LEFT_HELP_CONTAINER_PADDING);
		MC.FunctionNum("SetRightHelpPadding", RIGHT_HELP_CONTAINER_PADDING);
		MC.FunctionNum("SetCenterHelpPadding", CENTER_HELP_CONTAINER_PADDING);
	}

	LeftContainer = Spawn(class'UIPanel', self).InitPanel('leftBtnHelpContainer');
	CenterContainer = Spawn(class'UIPanel', self).InitPanel('centerBtnHelpContainer');
	RightContainer = Spawn(class'UIPanel', self).InitPanel('rightBtnHelpContainer');

	return self;
}

//==============================================================================
//		XCOM HELP BAR FUNCTIONALITY
//==============================================================================
public function UINavigationHelp AddBackButton( optional delegate<onButtonClickedDelegate> mouseCallback = none )
{
	local int i;            // needed for enum hackery
	local string strIcon;   // needed for enum hackery

	if(!bBackButton)
	{
		bBackButton = true;
		if ( Movie.IsMouseActive() )
		{
			SetButtonType("XComButtonIconPC");
			i = eButtonIconPC_Back; 
			strIcon = string(i);
			AddLeftHelp( strIcon, "", mouseCallback);
			SetButtonType("");
		}
		else
		{
			AddLeftHelp(m_strBackButtonLabel, class'UIUtilities_Input'.static.GetBackButtonIcon(), mouseCallback);
		}
	}
	return self;
}

public function UINavigationHelp AddContinueButton(optional delegate<OnButtonClickedDelegate> ContinueButtonMouseCallback = none, optional name continueLibID = 'X2ContinueButton')
{
	bContinueButton = true;
	if( ContinueButton == none )
	{
		// Spawn the continue button on the AvengerHUD screen, to avoid nested positioning
		ContinueButton = Spawn(class'UILargeButton', Screen);
		ContinueButton.LibID = continueLibID;
		ContinueButton.bHideUntilRealized = true;
		ContinueButton.InitLargeButton('ContinueButton', class'UIUtilities_Text'.default.m_strGenericContinue);
		ContinueButton.AnchorBottomCenter();
		ContinueButton.OffsetY = -10;
	}
	ContinueButton.OnClickedDelegate = ContinueButtonClicked;
	OnClickedContinueDelegate = ContinueButtonMouseCallback;
	ContinueButton.Show();
	return self;
}

public function ContinueButtonClicked(UIButton Button)
{
	if( OnClickedContinueDelegate != none )
		OnClickedContinueDelegate();
}

public function UINavigationHelp AddLeftHelp( string label, optional string gamepadIcon, 
											  optional delegate<onButtonClickedDelegate> mouseCallback = none,
											  optional bool isDisabled = false, 
											  optional string tooltipHTML = "",
											  optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	GenerateTooltip( tooltipHTML, "left", m_arrButtonClickDelegates.Length, tooltipAnchor );
	ButtonOp( "AddLeftButtonHelp", m_arrButtonClickDelegates.Length, label, gamepadIcon, isDisabled );
	m_arrButtonClickDelegates.AddItem(mouseCallback);
	return self;
}

public function UINavigationHelp AddRightHelp( string label, optional string gamepadIcon,
											   optional delegate<onButtonClickedDelegate> mouseCallback = none,
											   optional bool isDisabled = false, 
											   optional string tooltipHTML = "",
											   optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	GenerateTooltip( tooltipHTML, "right", m_arrButtonClickDelegates.Length, tooltipAnchor );
	ButtonOp( "AddRightButtonHelp", m_arrButtonClickDelegates.Length, label, gamepadIcon, isDisabled );
	m_arrButtonClickDelegates.AddItem(mouseCallback);
	return self;
}

public function UINavigationHelp AddRoomHelp( string label, optional string gamepadIcon,
											  optional delegate<onButtonClickedDelegate> mouseCallback = none,
											  optional bool isDisabled = false, 
											  optional string tooltipHTML = "",
											  optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	GenerateTooltip( tooltipHTML, "right", m_arrButtonClickDelegates.Length, tooltipAnchor );
	ButtonOp( "AddRightStackButtonHelp", m_arrButtonClickDelegates.Length, label, gamepadIcon, isDisabled );
	m_arrButtonClickDelegates.AddItem(mouseCallback);
	return self;
}

public function UINavigationHelp AddCenterHelp( string label, optional string gamepadIcon,
												optional delegate<onButtonClickedDelegate> mouseCallback = none,
												optional bool isDisabled = false, 
												optional string tooltipHTML = "",
												optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	GenerateTooltip( tooltipHTML, "center", m_arrButtonClickDelegates.Length, tooltipAnchor );
	ButtonOp( "AddCenterButtonHelp", m_arrButtonClickDelegates.Length, label, gamepadIcon, isDisabled );
	m_arrButtonClickDelegates.AddItem(mouseCallback);
	return self;
}

// WARNING: Buttons returned from this function might be lacking certain functionality
public function UIButton AddLeftButton( string label, optional string gamepadIcon, 
										optional delegate<onButtonClickedDelegate> mouseCallback = none,
										optional bool isDisabled = false, 
										optional string tooltipHTML = "",
										optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	AddLeftHelp(label, gamepadIcon, mouseCallback, isDisabled, tooltipHTML, tooltipAnchor);
	return CreateUIButton(LeftContainer, m_arrButtonClickDelegates.Length-1);
}

// WARNING: Buttons returned from this function might be lacking certain functionality
public function UIButton AddRightButton(string label, optional string gamepadIcon,
										optional delegate<onButtonClickedDelegate> mouseCallback = none,
										optional bool isDisabled = false, 
										optional string tooltipHTML = "",
										optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	AddRightHelp(label, gamepadIcon, mouseCallback, isDisabled, tooltipHTML, tooltipAnchor);
	return CreateUIButton(RightContainer, m_arrButtonClickDelegates.Length-1);
}

// WARNING: Buttons returned from this function might be lacking certain functionality
public function UIButton AddCenterButton( string label, optional string gamepadIcon,
										  optional delegate<onButtonClickedDelegate> mouseCallback = none,
										  optional bool isDisabled = false, 
										  optional string tooltipHTML = "",
										  optional int tooltipAnchor = class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT )
{
	AddCenterHelp(label, gamepadIcon, mouseCallback, isDisabled, tooltipHTML, tooltipAnchor);
	return CreateUIButton(CenterContainer, m_arrButtonClickDelegates.Length-1);
}

function UIButton CreateUIButton(UIPanel Container, int Index)
{
	local UIButton Button;
	Button = Spawn(class'UIButton', Container);
	Button.bProcessesMouseEvents = false; // NavHelp class handles all child mouse events
	return Button.InitButton(name(HELP_OPTION_IDENTIFIER $ "_" $ Index));
}

simulated public function UINavigationHelp SetButtonType( string strButtonType )
{
	mc.FunctionString("SetButtonType", strButtonType);
	return self;
}

public function UINavigationHelp ClearButtonHelp()
{
	mc.FunctionVoid("ClearButtonHelp");
	m_arrButtonClickDelegates.Length = 0;
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath( string(MCPath) );
	HighlightGeoscape(false);
	if(ContinueButton != none)
	{
		ContinueButton.Hide();
		ContinueButton.OnClickedDelegate = none;
	}
	OnClickedContinueDelegate = none;
	HighlightGeoscape(false);
	bBackButton = false;
	bGeoscapeButton = false;
	bContinueButton = false;
	return self;
}

function GenerateTooltip( string tooltipHTML, string position, int id, int tooltipAnchor)
{
	if( tooltipHTML != "" )
	{
		Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox( tooltipHTML, 
			0,
			-5,
			GenerateTooltipPath(position, id), 
			,
			true,
			tooltipAnchor,
			false );
	}
}
function string GenerateTooltipPath( string position, int id )
{
	return MCPath $ "." $ position $ "BtnHelpContainer." $ HELP_OPTION_IDENTIFIER $ "_" $ string(id);
}

//==============================================================================
//		MOUSE HANDLING:
//==============================================================================
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local delegate<onButtonClickedDelegate> callbackDelegate;
	local string callbackObj, tmp;
	local int buttonIndex;

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		callbackObj = args[args.Length - 1];
		if(InStr(callbackObj, HELP_OPTION_IDENTIFIER) == -1)
			return;

		if( InStr(callbackObj, ContinueButton.MCName) != -1 )
			return;

		tmp = GetRightMost(callbackObj);
		if(tmp != "")
			buttonIndex = int(tmp);
		else
			buttonIndex = -1;

		// This can never ever happen.
		`assert(buttonIndex >= 0); 

		callbackDelegate = m_arrButtonClickDelegates[buttonIndex];
		// Call the delegate that was registered to handle this button
		if(callbackDelegate != none)
			callbackDelegate();
	}
	super.OnMouseEvent(cmd, args);
}

//==============================================================================
//		FLASH INTERFACE:
//==============================================================================
simulated function ButtonOp( string func, int id, string label, string icon, bool disabled) 
{
	mc.BeginFunctionOp(func);  // add function
	mc.QueueNumber(id);        // add id parameter
	mc.QueueString(label);     // add label parameter
	mc.QueueString(icon);      // add icon parameter
	mc.QueueBoolean(disabled); // add disabled parameter
	mc.EndOp();                // add delimiter and process command
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated event Removed()
{
	super.Removed();
	m_arrButtonClickDelegates.Length = 0;
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath( string(MCPath) );
}

//==============================================================================
//		ANCHORING OVERRIDES:
//==============================================================================

simulated function UIPanel SetAnchor(int newAnchor)
{
	`log("CAN'T SET ANCHORING ON A UINavigationHelper. Anchoring is currently automated." @string(MCPath)); 
	// Note: We can only be placed at the bottom auto anchoring right now. If we want to change this, we need to create a 
	// UIPanel version if the XComHelpBar that will let us anchor independently from the interior item anchors. -bsteiner 
	mc.FunctionVoid("AnchorToBottom");

	return self;
}

simulated function UIPanel SetOrigin(int newAnchor)
{
	`log("CAN'T SET ORIGIN ON A UINavigationHelper. Origin is currently automated." @string(MCPath));
	return self;
}

simulated function Show()
{
	super.Show();
	if(ContinueButton != none && bContinueButton)
		ContinueButton.Show();
}
simulated function Hide()
{
	super.Hide();
	if(ContinueButton != none)
		ContinueButton.Hide();
}

//==============================================================================
//		SPECIAL BUTTONS:
//==============================================================================

public function UINavigationHelp AddGeoscapeButton(optional delegate<onButtonClickedDelegate> mouseCallback = none)
{
	local int i;            // needed for enum hackery
	local string strIcon;   // needed for enum hackery

	// This is only useful in the strategy game. 
	if( XComHQPresentationLayer(Movie.Pres) == none ) return self; 
	if( GeoscapeFacility == '' ) return self;
	if(bGeoscapeButton)
	{
		RefreshGeoscapeHighlight();
		return self;
	}
	if(class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress() && 
	class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M3_WelcomeToHQ') != eObjectiveState_InProgress &&
	class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress &&
	class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_IntroToBlacksite') != eObjectiveState_InProgress)
		return self;

	if( Movie.IsMouseActive() )
	{
		SetButtonType("XComButtonIconPC");
		i = eButtonIconPC_Hologlobe;
		strIcon = string(i);
		AddLeftHelp(strIcon, "", HotlinkToGeoscape, false, GetGeoscapeTooltip());
		SetButtonType("");
		
		//Store this delegate to call back after we make the hotlink jump.
		OnGeoscapeClickedDelegate = mouseCallback; 
		bGeoscapeButton = true;
	}
	/*else
	{
		//TODO: update this if we want have a universal shortcut jump to geoscape via controller Unknown if this will be the case. -bsteiner
		AddLeftHelp(m_strBackButtonLabel, class'UIUtilities_Input'.static.GetBackButtonIcon(), mouseCallback);
	}*/
	RefreshGeoscapeHighlight();

	return self;
}

function string GetGeoscapeTooltip()
{
	local string TooltipDesc; 
	local byte KeyNotFound; 
	local XComKeybindingData KeyBindData; 
	local PlayerInput PlayerIn; 

	PlayerIn = XComPlayerController(`HQPRES.Owner).PlayerInput;
	KeyBindData = `HQPRES.m_kKeybindingData;
	KeyNotFound = 0;

	TooltipDesc = class'UIUtilities_Input'.static.FindAbilityKey(class'UIAvengerShortcuts'.default.TooltipGeoscape, "%KEY:ONE%", eABC_Geoscape, KeyNotFound, KeyBindData, PlayerIn, eKC_Avenger );

	return TooltipDesc;
}

simulated function HotlinkToGeoscape()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	if( GeoscapeFacility == '' ) return; 

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if( FacilityState.GetMyTemplateName() == GeoscapeFacility )
		{
			if(!FacilityState.bTutorialLocked)
			{
				FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
				if(OnGeoscapeClickedDelegate != none)
					OnGeoscapeClickedDelegate();
				break;

				HighlightGeoscape(false);
			}
		}
	}
}

simulated function RefreshGeoscapeHighlight()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if( FacilityState.GetMyTemplateName() == GeoscapeFacility )
		{
			HighlightGeoscape( class'UIUtilities_Strategy'.static.IsInTutorial(true) && FacilityState.NeedsAttention());
		}
	}
}

simulated function HighlightGeoscape(bool bShouldHighlight)
{
	if( bShouldHighlight && AttentionPulse == none )
	{
		AttentionPulse = Spawn(class'UIPanel', self);
		AttentionPulse.InitPanel('NavHelpAttentionPulse', class'UIUtilities_Controls'.const.MC_AttentionPulse);
		AttentionPulse.AnchorBottomLeft();
		AttentionPulse.SetPosition(48, -48);
	}
	else if( AttentionPulse != none )
	{
		AttentionPulse.Remove();
		AttentionPulse = none; 
	}	
}

simulated function Remove()
{
	super.Remove();
	if(ContinueButton != none)
	{
		ContinueButton.Remove();
		ContinueButton = none;
	}
	OnClickedContinueDelegate = none;
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{
	LibID = "XComHelpBar";
	MCName = "helpBarMC"; // by default
	
	bIsNavigable = false;
	bCascadeFocus = false;
	bProcessesMouseEvents = true;

	LEFT_HELP_CONTAINER_PADDING = 20;
	RIGHT_HELP_CONTAINER_PADDING = 20;
	CENTER_HELP_CONTAINER_PADDING = 60;
}