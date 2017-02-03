//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComCoOpReplayMgr
//  AUTHOR:  Elad Dvash
//  PURPOSE: Manages replays of gamestates recieved while in co-op
//           Mostly copied from the parent class.                                                       
//---------------------------------------------------------------------------------------  
                                                                                                                      
class XComCoOpReplayMgr extends XComMPReplayMgr;

var bool finishedReplay;
var int LastKnownHistoryIndex;


simulated event PostBeginPlay()
{
	super(XComReplayMgr).PostBeginPlay();

	`XCOMNETMANAGER.AddReceiveHistoryDelegate(ReceivePartialHistory);
	`XCOMNETMANAGER.AddReceivePartialHistoryDelegate(ReceivePartialHistory);
}

simulated function Cleanup()
{
	`XCOMNETMANAGER.ClearReceiveHistoryDelegate(ReceivePartialHistory);
	`XCOMNETMANAGER.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
}


simulated function ReceivePartialHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	// Update the world data to be in alignment with the new history data.
	`XWORLD.SyncVisualizers();
	`XWORLD.UpdateTileDataCache();
}


simulated event StepReplayForward(bool bStepAll = false)
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameState NextGameState;	
	local XComGameStateHistory History;	
	local int StartTickIndex;
	local int SkipTicksIndex;
	local bool bHasVisualizationBlock;
	local XComGameStateContext_TacticalGameRule GameRuleContext;
	local X2TacticalCoOpGameRuleset GameRuleset;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();	
	GameRuleset = X2TacticalCoOpGameRuleset(XComGameInfo(class'Engine'.static.GetCurrentWorldInfo().Game).GameRuleset);
	finishedReplay=false;

	if( CurrentHistoryFrame < StepForwardStopFrame )
	{
		VisualizationMgr = XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).VisualizationMgr;
		NextGameState = History.GetGameStateFromHistory(CurrentHistoryFrame+1);
		StartTickIndex = NextGameState.TickAddedToHistory;

		do
		{	
			GameRuleContext = XComGameStateContext_TacticalGameRule(NextGameState.GetContext());
			if( GameRuleContext != None && GameRuleContext.GameRuleType == eGameRule_PlayerTurnBegin )
			{
				GameRuleset.CachedUnitActionPlayerRef = GameRuleContext.PlayerRef; // Update the 'active player'
			}

			NextGameState = History.GetGameStateFromHistory(CurrentHistoryFrame+1);

			if(!bStepAll && (StartTickIndex != NextGameState.TickAddedToHistory) && bHasVisualizationBlock)
			{
				break;
			}

			++CurrentHistoryFrame;
			History.SetCurrentHistoryIndex(CurrentHistoryFrame);	
			`log("Playing GameState On Replay",,'Dragonpunk Coop ReplayMgr');
			HandleGameState(History, NextGameState);

			// Update the VisiblityMgr with the gamestate
			GameRuleset.VisibilityMgr.OnNewGameState(NextGameState);
			class'XComWorldData'.static.GetWorldData().SyncReplay(NextGameState);
			class'XComWorldData'.static.GetWorldData().UpdateTileDataCache( );

			// Before handling control over the visualizer, reset all the collision that may have been changed by the state submission
			class'XComWorldData'.static.GetWorldData().RestoreFrameDestructionCollision( );

			VisualizationMgr.BuildVisualization(CurrentHistoryFrame, bVisualizationSkip);			

			//'Instant' visualization tracks take 2 ticks to execute and remove
			for( SkipTicksIndex = 0; SkipTicksIndex < 2; ++SkipTicksIndex )
			{
				VisualizationMgr.Tick(0.0f);
			}

			bHasVisualizationBlock = class'XComGameStateVisualizationMgr'.static.VisualizerBusy();
		}
		until( CurrentHistoryFrame == StepForwardStopFrame || bSingleStepMode );
		if(CurrentHistoryFrame == StepForwardStopFrame)
		{
			finishedReplay=true;
			SendRemoteCommand("EndOfReplay");
		}
	}
//	`log("CurrentHistoryFrame" @CurrentHistoryFrame @",StepForwardStopFrame" @StepForwardStopFrame @",NumGameStates"@`XCOMHISTORY.GetNumGameStates());
}

/*
simulated event StepReplayForward(bool bStepAll = false)
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameState NextGameState;	
	local XComGameStateHistory History;	
	local int StartTickIndex;
	local int SkipTicksIndex;
	local bool bHasVisualizationBlock;
	local XComGameStateContext_TacticalGameRule GameRuleContext;
	local X2TacticalGameRuleset GameRuleset;


	History = `XCOMHISTORY;	
	GameRuleset = `TACTICALRULES;
	finishedReplay=false;
	if( CurrentHistoryFrame < StepForwardStopFrame )
	{
		VisualizationMgr = `XCOMVISUALIZATIONMGR;
		NextGameState = History.GetGameStateFromHistory(CurrentHistoryFrame+1);
		StartTickIndex = NextGameState.TickAddedToHistory;

		do
		{	
			GameRuleContext = XComGameStateContext_TacticalGameRule(NextGameState.GetContext());
			if( GameRuleContext != None && GameRuleContext.GameRuleType == eGameRule_PlayerTurnBegin )
			{
				GameRuleset.CachedUnitActionPlayerRef = GameRuleContext.PlayerRef; // Update the 'active player'
			}
				
			if(!bStepAll && (StartTickIndex != NextGameState.TickAddedToHistory) && bHasVisualizationBlock)
			{
				break;
			}
			
			++CurrentHistoryFrame;
			History.SetCurrentHistoryIndex(CurrentHistoryFrame);	
			//`XCOMHISTORY.SetCurrentHistoryIndex(CurrentHistoryFrame);	
			`log("Playing GameState On Replay",,'Dragonpunk Coop ReplayMgr');
			HandleGameState(History, NextGameState);

			// Update the VisiblityMgr with the gamestate
			GameRuleset.VisibilityMgr.OnNewGameState(NextGameState);
			`XWORLD.SyncReplay(NextGameState);
			`XWORLD.UpdateTileDataCache( );

			// Before handling control over the visualizer, reset all the collision that may have been changed by the state submission
			`XWORLD.RestoreFrameDestructionCollision( );

			VisualizationMgr.BuildVisualization(CurrentHistoryFrame, bVisualizationSkip);			

			//'Instant' visualization tracks take 2 ticks to execute and remove
			for( SkipTicksIndex = 0; SkipTicksIndex < 2; ++SkipTicksIndex )
			{
				VisualizationMgr.Tick(0.0f);
			}

			bHasVisualizationBlock = class'XComGameStateVisualizationMgr'.static.VisualizerBusy();
		}
		until( CurrentHistoryFrame == StepForwardStopFrame || bSingleStepMode );
		if(CurrentHistoryFrame == StepForwardStopFrame)
		{
			finishedReplay=true;
			SendRemoteCommand("EndOfReplay");
		}
	}
//	`log("CurrentHistoryFrame" @CurrentHistoryFrame @",StepForwardStopFrame" @StepForwardStopFrame @",NumGameStates"@`XCOMHISTORY.GetNumGameStates());
}
*/
simulated event StopReplay()
{
	local XComCoOpTacticalController TacticalController;

	// Make sure to set the current history frame here, before the EndReplay of the Tactical Rules, since that will advance the History by changing Phases.
	`XCOMVISUALIZATIONMGR.SetCurrentHistoryFrame(`XCOMHISTORY.GetNumGameStates() - 1);
	`XCOMHISTORY.SetCurrentHistoryIndex(-1);

	TacticalController = XComCoOpTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());

	if (TacticalController != none)
	{
		//TacticalController.SetInputState('ActiveUnit_Moving');
		bInReplay = false;
		`TACTICALRULES.EndReplay();
	}
}

function SendRemoteCommand(string Command)
{
	local array<byte> EmptyParams;
	EmptyParams.Length = 0; // Removes script warning
	`XCOMNETMANAGER.SendRemoteCommand(Command, EmptyParams);
	`log("Command Sent:"@Command,,'Dragonpunk Tactical');
}

state PlayingReplay
{
	event BeginState(Name PreviousStateName)
	{
		// Must set this otherwise SteppingForward might step just a tad too far because it steps past things that don't
		// have visualization, etc.
		`log("Starting Replay",,'Dragonpunk Coop ReplayMgr');
		XComCoOpTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).IsCurrentlyWaiting=true;
//		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');	
	}

	event Tick(float DeltaTime)
	{
		StepForwardStopFrame = `XCOMHISTORY.GetNumGameStates() - 1;
//		if(!XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsInState('BlockingInput'))
//			XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');	

		if (CurrentHistoryFrame < StepForwardStopFrame)
		{
			StepReplayForward();
			UpdateUIWithFrame(CurrentHistoryFrame);
		}
		else if (PauseReplayRequested && (!class'XComGameStateVisualizationMgr'.static.VisualizerBusy()) )
		{
			PauseReplay();
		}
		/*else if(CurrentHistoryFrame == StepForwardStopFrame && finishedReplay!=true)
		{
			`log("CurrentHistoryFrame" @CurrentHistoryFrame @",StepForwardStopFrame" @StepForwardStopFrame @",NumGameStates"@`XCOMHISTORY.GetNumGameStates());
		}*/
	}

	simulated function PauseReplay()
	{
		`log("Pausing Replay",,'Dragonpunk Coop ReplayMgr');
		PauseReplayRequested = false;
		GotoState('PausedReplay');
		//LastSeenHistoryIndex = CachedHistory.GetCurrentHistoryIndex();
		StopReplay();
	}

Begin:
}

state PausedReplay
{
	event BeginState(Name PreviousStateName)
	{
//		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');	
	}

	event Tick(float DeltaTime)
	{
	}

Begin:
}
