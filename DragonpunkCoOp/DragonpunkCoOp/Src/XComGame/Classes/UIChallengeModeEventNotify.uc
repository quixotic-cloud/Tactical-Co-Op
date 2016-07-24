//---------------------------------------------------------------------------------------
//  FILE:    UIChallengeModeEventNotify.uc
//  AUTHOR:  Timothy Talley  --  11/24/2014
//  PURPOSE: Small dialog window that shows the stats of a Challenge Mode Event, such as
//           number of players who have completed the event prior to the current turn,
//           number completed on the same turn, and those who have finished on a
//           following turn.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UIChallengeModeEventNotify extends UIScreen
	dependson(UIDebugChallengeMode)
	dependson(X2TacticalChallengeModeManager)
	dependson(X2ChallengeModeDataStructures);


//--------------------------------------------------------------------------------------- 
// UI Layout Data
//
var UIPanel							m_kAllContainer;
var UIX2PanelHeader				m_TitleHeader;
var UIButton					m_CloseButton;			// Closes this dialog
var UIButton					m_NextButton;			// Views the next event
var UIButton					m_PreviousButton;		// Views the previous event
var UITextContainer             m_kDetailText;          // Text-box to hold all of the event details

//--------------------------------------------------------------------------------------- 
// Data
//
var bool                                bStoredMouseIsActive;
var bool                                bOpenedInDataView;      // Instead of grabbing the live data from the Challenge Mode Manager, this allows someone to iterate through all events.
var int                                 m_CurrentEventIndex;

//--------------------------------------------------------------------------------------- 
// Cached References
//
var X2TacticalChallengeModeManager      ChallengeModeManager;
var XComOnlineEventMgr                  OnlineMgr;

//--------------------------------------------------------------------------------------- 
// Delegates
//
delegate OnClosedDelegate();


//==============================================================================
//		INITIALIZATION:
//==============================================================================
simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	foreach AllActors(class'X2TacticalChallengeModeManager', ChallengeModeManager) { break; }
	OnlineMgr = `ONLINEEVENTMGR;

	super.InitScreen(InitController, InitMovie, InitName);

	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	m_kAllContainer = Spawn(class'UIPanel', self);

	m_kAllContainer.InitPanel('allContainer');
	m_kAllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kAllContainer.SetPosition(30, 110).SetSize(600, 800);

	// Create Title text
	Spawn(class'UIBGBox', m_kAllContainer).InitBG('', 0, 0, m_kAllContainer.width, m_kAllContainer.height);
	m_TitleHeader = Spawn(class'UIX2PanelHeader', m_kAllContainer);
	m_TitleHeader.InitPanelHeader('', class'UIDebugChallengeMode'.default.m_strChallengeModeTitle @ "EVENT", "");
	m_TitleHeader.SetHeaderWidth(m_kAllContainer.width - 20);
	m_TitleHeader.SetPosition(10, 10);

	// Detail Text
	m_kDetailText = Spawn(class'UITextContainer', m_kAllContainer);	
	m_kDetailText.InitTextContainer('', "<Empty>", 10, 50, m_kAllContainer.width - 30, m_kAllContainer.height - 150 );

	// Close Button
	m_CloseButton = Spawn(class'UIButton', m_kAllContainer);
	m_CloseButton.InitButton('closeButton', "Close", OnCloseButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_CloseButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_CloseButton.SetPosition(450, 850);

	// Previous Event Button
	m_PreviousButton = Spawn(class'UIButton', m_kAllContainer);
	m_PreviousButton.InitButton('previousEventButton', "Previous Event", OnPreviousButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_PreviousButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_PreviousButton.SetPosition(50, 850);
	
	// Next Event Button
	m_NextButton = Spawn(class'UIButton', m_kAllContainer);
	m_NextButton.InitButton('nextEventButton', "Next Event", OnNextButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_NextButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_NextButton.SetPosition(250, 850);

	UpdateData();
}

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();
	Movie.InsertHighestDepthScreen(self);
}

simulated function SetDataView(bool bDataView)
{
	if (bDataView)
	{
		GotoState('FullDataView');
	}
	else
	{
		GotoState('SeenEventView');
	}
}

//==============================================================================
//		HELPERS:
//==============================================================================
simulated function string GetLeadingString(string text, string leading, int leadingCount)
{
	local string OutText;
	local int i, SpacingWidth;
	SpacingWidth = leadingCount - Len(text);
	for (i = 0; i < SpacingWidth; ++i)
	{
		OutText $= leading;
	}

	return OutText $ text;
}

simulated function SetEventDetails(const out PendingEventType PendingEvent)
{
	local string EventText;
	local float TotalPlayers;

	TotalPlayers = PendingEvent.NumPlayersPrior + PendingEvent.NumPlayersCurrent + PendingEvent.NumPlayersSubsequent;

	// Update the text
	EventText = "\n\n\nEvent Description: " @ `ShowEnum(EChallengeModeEventType, PendingEvent.EventType) @ "\n";
	EventText $= "Turn Completed: " @ PendingEvent.Turn @ "\n";
	EventText $= "Other Players Completed Prior: " @ ((TotalPlayers == 0) ? 0 : (Round((PendingEvent.NumPlayersPrior / TotalPlayers) * 1000) / 10)) $ "% (" $ PendingEvent.NumPlayersPrior $ ")\n";
	EventText $= "Other Players Completed on Same Turn: " @ ((TotalPlayers == 0) ? 0 : (Round((PendingEvent.NumPlayersCurrent / TotalPlayers) * 1000) / 10)) $ "% (" $ PendingEvent.NumPlayersCurrent $ ")\n";
	EventText $= "Other Players Completed Subsequent: " @ ((TotalPlayers == 0) ? 0 : (Round((PendingEvent.NumPlayersSubsequent / TotalPlayers) * 1000) / 10)) $ "% (" $ PendingEvent.NumPlayersSubsequent $ ")\n";
	m_kDetailText.SetText(EventText);
}

simulated function SetFullEventMapDetails(EChallengeModeEventType EventType)
{
	local int UpdateTurn, MaxTurns, NumPlayers;
	local string EventText, MapText;
	local float TotalPlayers;

	MaxTurns = OnlineMgr.m_ChallengeModeEventMap.Length / ECME_MAX;
	for (UpdateTurn = 0; UpdateTurn < MaxTurns; ++UpdateTurn)
	{
		if (UpdateTurn % 8 == 0)
		{
			MapText $= "\n" $ GetLeadingString(string(UpdateTurn), "0", 3) $ " | ";
		}
		NumPlayers = OnlineMgr.m_ChallengeModeEventMap[(EventType * MaxTurns) + UpdateTurn];
		TotalPlayers += NumPlayers;
		if (UpdateTurn % 4 == 0)
		{
			MapText $= "  "; // Add additional space after every 4th 0 to break up the groups of 8.
		}
		MapText $= "  " $ GetLeadingString(string(NumPlayers), "0", 3);
	}

	EventText = "Event Description: " @ `ShowEnum(EChallengeModeEventType, EventType) @ "\n";
	EventText @= "Total Players:" @ TotalPlayers @ "\n";
	EventText @= MapText;

	m_kDetailText.SetText(EventText);
}

//==============================================================================
//		STATES:
//==============================================================================
simulated function UpdateDisplay()
{
}

simulated function UpdateData()
{
}

auto state SeenEventView
{
	simulated function UpdateDisplay()
	{
		m_PreviousButton.DisableButton("No other pending events to view.");
		m_NextButton.DisableButton("No other pending events to view.");

		if (ChallengeModeManager.HasPreviousEvent())
		{
			m_PreviousButton.EnableButton();
		}

		if (ChallengeModeManager.HasNextEvent())
		{
			m_NextButton.EnableButton();
		}
	}

	simulated function UpdateData()
	{
		local PendingEventType PendingEvent;
		if (ChallengeModeManager.GetCurrentEvent(PendingEvent))
		{
			SetEventDetails(PendingEvent);
		}
		UpdateDisplay();
	}

	simulated function OnCloseButtonPress(UIButton button)
	{
		ChallengeModeManager.ViewAllPendingEvents();
		CloseScreen();
	}

	simulated function OnPreviousButtonPress(UIButton button)
	{
		if (ChallengeModeManager.PreviousEvent())
		{
			UpdateData();
		}
	}

	simulated function OnNextButtonPress(UIButton button)
	{
		if (ChallengeModeManager.NextEvent())
		{
			UpdateData();
		}
	}

Begin:
	UpdateData();
}

state FullDataView
{
	simulated function UpdateDisplay()
	{
		m_PreviousButton.DisableButton("No other events to view.");
		m_NextButton.DisableButton("No other events to view.");

		if (m_CurrentEventIndex > 0)
		{
			m_PreviousButton.EnableButton();
		}

		if (m_CurrentEventIndex < ECME_MAX)
		{
			m_NextButton.EnableButton();
		}
	}

	simulated function UpdateData()
	{
		SetFullEventMapDetails(EChallengeModeEventType(m_CurrentEventIndex));
		UpdateDisplay();
	}

	simulated function OnPreviousButtonPress(UIButton button)
	{
		m_CurrentEventIndex = Max(--m_CurrentEventIndex, 0);
		UpdateData();
	}

	simulated function OnNextButtonPress(UIButton button)
	{
		m_CurrentEventIndex = Min(ECME_MAX, ++m_CurrentEventIndex);
		UpdateData();
	}

Begin:
	m_CurrentEventIndex = 0;
	UpdateData();
}

//==============================================================================
//		UI EVENT HANDLERS:
//==============================================================================
simulated function OnCloseButtonPress(UIButton button)
{
	CloseScreen();
}

simulated function OnPreviousButtonPress(UIButton button)
{
	UpdateData();
}

simulated function OnNextButtonPress(UIButton button)
{
	UpdateData();
}

// Used in navigation stack
simulated function OnRemoved()
{
	super.OnRemoved();

	if( !bStoredMouseIsActive )
		Movie.DeactivateMouse();

	if( OnClosedDelegate != none )
		OnClosedDelegate();

}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:		
			CloseScreen();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
event ActivateEvent()
{
	PC.Pres.UIRedScreen();	
}

defaultproperties
{
	bAlwaysTick = true;
	InputState = eInputState_Consume;
}