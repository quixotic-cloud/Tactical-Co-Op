class UIAdventOperations extends UIX2SimpleScreen;

var public localized String m_strTitle;
var public localized String m_strTitleHelp;
var public localized String m_strTitleHelpPending;
var public localized String m_strTitleHelpActive;
var public localized String m_strStatusLabel;
var public localized String m_strPreparing;
var public localized String m_strActive;
var public localized String m_strAlienFacility;
var public localized String m_strRetaliation;
var public localized String m_strWeek;
var public localized String m_strWeeks;
var public localized String m_strImminent;
var public localized String m_strUnknown;
var public localized String m_strShowActiveButton;
var public localized String m_strShowPendingButton;
var public localized String m_strReveal;
var public localized String m_strEstimated;
var public localized String m_strUnlockButton;

var bool bResistanceReport;
var bool bShowActiveEvents;
var array<StateObjectReference> ChosenDarkEvents;
var array<StateObjectReference> ActiveDarkEvents;
var UIButton FlipButton;
var string TitleHelp;

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	if(bResistanceReport)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("GeoscapeAlerts_ADVENTControl");
	}
		
	BuildScreen(true);
}

simulated function BuildScreen( optional bool bAnimateIn = false )
{
	local int idx, NumEvents;

	MC.FunctionVoid("HideAllCards");

	BuildTitlePanel();

	if( !bShowActiveEvents )
	{
		NumEvents = class'UIUtilities_Strategy'.static.GetAlienHQ().ChosenDarkEvents.Length;

		for( idx = 0; idx < NumEvents; idx++ )
		{
			BuildDarkEventPanel(idx, false);
		}
	}
	else if( !bResistanceReport )
	{
		NumEvents = ALIENHQ().ActiveDarkEvents.Length;
		for( idx = 0; idx < NumEvents; idx++ )
		{
			BuildDarkEventPanel(idx, true);
		}
	}
	MC.FunctionNum("SetNumCards", NumEvents);
	RefreshNav();
	if(bAnimateIn) 
		MC.FunctionVoid("AnimateIn");
}

simulated function RefreshNav()
{
	local UINavigationHelp NavHelp; 
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();

	if( !bResistanceReport )
	{
		if( ActiveDarkEvents.Length > 0 )
		{
			if( bShowActiveEvents )
				NavHelp.AddCenterHelp(m_strShowPendingButton, , FlipScreenMode);
			else
				NavHelp.AddCenterHelp(m_strShowActiveButton, , FlipScreenMode);
		}
	}

	// Carry On
	NavHelp.AddBackButton(OnContinueClicked);
}

simulated function BuildTitlePanel()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionCalendar CalendarState;
	local int WeekDiff;
	local TDateTime RetalDate;
	local string WeeksDisplay, RetaliationDisplay;
	local bool bHaveRetaliation;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));

	if(bResistanceReport)
	{
		TitleHelp = m_strTitleHelp;
	}
	else
	{
		if( bShowActiveEvents )
			TitleHelp = m_strTitleHelpActive;
		else
			TitleHelp = m_strTitleHelpPending;
	}
	
	WeekDiff = (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(AlienHQ.FacilityBuildEndTime, `STRATEGYRULES.GameTime)/7);

	if(WeekDiff > 1)
	{
		WeeksDisplay = string(WeekDiff) @ m_strWeeks;
		WeeksDisplay= class'UIUtilities_Text'.static.GetColoredText(WeeksDisplay, eUIState_Warning2);
	}
	else if(WeekDiff == 1)
	{
		WeeksDisplay = string(WeekDiff) @ m_strWeek;
		WeeksDisplay= class'UIUtilities_Text'.static.GetColoredText(WeeksDisplay, eUIState_Warning2);
	}
	else
	{
		WeeksDisplay = m_strImminent; 
		WeeksDisplay= class'UIUtilities_Text'.static.GetColoredText(WeeksDisplay, eUIState_Bad);
	}

	if(CalendarState.GetNextDateForMissionSource('MissionSource_Retaliation', RetalDate))
	{
		WeekDiff = (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(RetalDate, `STRATEGYRULES.GameTime) / 7);
		bHaveRetaliation = true;

		if(WeekDiff > 1)
		{
			RetaliationDisplay = string(WeekDiff) @ m_strWeeks;
			RetaliationDisplay = class'UIUtilities_Text'.static.GetColoredText(RetaliationDisplay, eUIState_Warning2);
		}
		else if(WeekDiff == 1)
		{
			RetaliationDisplay = string(WeekDiff) @ m_strWeek;
			RetaliationDisplay = class'UIUtilities_Text'.static.GetColoredText(RetaliationDisplay, eUIState_Warning2);
		}
		else
		{
			RetaliationDisplay = m_strImminent;
			RetaliationDisplay = class'UIUtilities_Text'.static.GetColoredText(RetaliationDisplay, eUIState_Bad);
		}
	}
	else
	{
		bHaveRetaliation = false;
		RetaliationDisplay = m_strUnknown; 
	}

	MC.BeginFunctionOp("UpdateDarkEventData");
	MC.QueueString(m_strTitle);
	MC.QueueString(TitleHelp);

	// Alien Facility countdown
	if (AlienHQ.bHasSeenFacility && AlienHQ.bBuildingFacility && AlienHQ.AIMode != "Lose")
	{
		MC.QueueString(m_strAlienFacility);
		MC.QueueString(WeeksDisplay);
		MC.QueueString(m_strEstimated);
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
	}

	// Retaliation Mission countdown
	if (AlienHQ.bHasSeenRetaliation && bHaveRetaliation)
	{
		MC.QueueString(m_strRetaliation);
		MC.QueueString(RetaliationDisplay);
		MC.QueueString(m_strEstimated);
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
	}
	
	MC.EndOp();
}

simulated function BuildDarkEventPanel(int Index, bool bActiveDarkEvent)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_DarkEvent DarkEventState;
	local array<StrategyCostScalar> CostScalars;
	local bool bCanAfford;

	local string StatusLabel, Quote, QuoteAuthor, UnlockButtonLabel; 
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CostScalars.Length = 0;

	if(bActiveDarkEvent)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ALIENHQ().ActiveDarkEvents[Index].ObjectID));
	}
	else
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ALIENHQ().ChosenDarkEvents[Index].ObjectID));
	}
	
	if(DarkEventState != none)
	{

		if(DarkEventState.bSecretEvent) 
		{
			UnlockButtonLabel = m_strReveal;
			ChosenDarkEvents[Index] = DarkEventState.GetReference();
			bCanAfford = XComHQ.CanAffordAllStrategyCosts(DarkEventState.RevealCost, CostScalars);

			MC.BeginFunctionOp("UpdateDarkEventCardLocked");
			MC.QueueNumber(index);
			MC.QueueString(DarkEventState.GetDisplayName());
			MC.QueueString(bCanAfford ? m_strUnlockButton : "");
			MC.QueueString(DarkEventState.GetCost());
			MC.QueueString(bCanAfford ? UnlockButtonLabel : "");
			MC.EndOp();
		}
		else
		{
			if( bActiveDarkEvent )
				StatusLabel = m_strActive;
			else
				StatusLabel = m_strPreparing;

			Quote = DarkEventState.GetQuote();
			QuoteAuthor = DarkEventState.GetQuoteAuthor();
			ActiveDarkEvents[Index] = DarkEventState.GetReference();

			MC.BeginFunctionOp("UpdateDarkEventCard");
			MC.QueueNumber(index);
			MC.QueueString(DarkEventState.GetDisplayName());
			MC.QueueString(m_strStatusLabel);
			MC.QueueString(StatusLabel);
			MC.QueueString(DarkEventState.GetImage());
			MC.QueueString(DarkEventState.GetSummary());
			MC.QueueString(Quote);
			MC.QueueString(QuoteAuthor);
			MC.EndOp();
		}
	}	
}

simulated function OnRevealClicked(int idx)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_DarkEvent DarkEventState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StrategyCostScalar> CostScalars;
	local bool bCanAfford;
	
	History = `XCOMHISTORY;

	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ChosenDarkEvents[idx].ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CostScalars.Length = 0;
	bCanAfford = XComHQ.CanAffordAllStrategyCosts(DarkEventState.RevealCost, CostScalars);

	if(DarkEventState != none && DarkEventState.bSecretEvent && bCanAfford)
	{
		PlaySFX("Geoscape_Reveal_Dark_Event");
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reveal Dark Event");
		DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
		NewGameState.AddStateObject(DarkEventState);
		DarkEventState.RevealEvent(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		ChosenDarkEvents.Remove(idx, 1);
		BuildDarkEventPanel(idx, false);
	}
}

simulated function FlipScreenMode()
{
	bShowActiveEvents = !bShowActiveEvents;
	BuildScreen();
}

simulated function CloseScreen()
{
	local XComHeadquartersCheatManager CheatMgr;

	super.CloseScreen();
	
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	if (bResistanceReport)
	{
		CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

		if (CheatMgr != none && CheatMgr.bGamesComDemo)
		{
			return;
		}
	}
	else
	{
		`GAME.GetGeoscape().Resume();
	}
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnContinueClicked()
{
	CloseScreen();	
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int iTargetCallback;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:

		iTargetCallback = int(Split(args[args.length - 3], "Card0", true)); // this is dissecting the Flash path. 
		OnRevealClicked(iTargetCallback);
		break;
	}
}


//-------------- GAME DATA HOOKUP --------------------------------------------------------

defaultproperties
{
	Package = "/ package/gfxDarkEvents/DarkEvents";
	bConsumeMouseEvents = true;
}