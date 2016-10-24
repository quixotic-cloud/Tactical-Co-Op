// This is an Unreal Script
                           
class XComCoOpReplayMgr extends XComMPReplayMgr;

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
			SendRemoteCommand("EndOfReplay");
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
		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');	
	}

	event Tick(float DeltaTime)
	{
		StepForwardStopFrame = `XCOMHISTORY.GetNumGameStates() - 1;

		if (CurrentHistoryFrame < StepForwardStopFrame)
		{
			StepReplayForward();
			UpdateUIWithFrame(CurrentHistoryFrame);
		}
		else if (PauseReplayRequested && !class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
		{
			PauseReplay();
		}
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
	}

	event Tick(float DeltaTime)
	{
	}

Begin:
}
