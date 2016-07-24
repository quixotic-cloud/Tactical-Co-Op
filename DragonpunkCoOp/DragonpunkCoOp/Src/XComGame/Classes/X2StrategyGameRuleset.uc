class X2StrategyGameRuleset extends X2GameRuleset dependson(X2StrategyGameRulesetDataStructures);

//******** General Purpose Variables **********
var TDateTime GameTime;                                         // Date time of the strategy game
//****************************************

/// <summary>
/// Called by the tactical game start up process when a new battle is starting
/// </summary>
simulated function StartNewGame()
{
	local XComGameState FullGameState;
	
	`XCOMVISUALIZATIONMGR.EnableBuildVisualization();

	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	FullGameState = CachedHistory.GetGameStateFromHistory(-1, eReturnType_Copy, false);

	`XCOMVISUALIZATIONMGR.OnJumpForwardInHistory();
	`XCOMVISUALIZATIONMGR.BuildVisualization(FullGameState.HistoryIndex, false);
}

/// <summary>
/// Called by the strategy game start up process the player is resuming a previously created game
/// </summary>
simulated function LoadGame()
{
	local XComGameState FullGameState;

	`XCOMVISUALIZATIONMGR.EnableBuildVisualization();

	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	FullGameState = CachedHistory.GetGameStateFromHistory(-1, eReturnType_Copy, false);

	`XCOMVISUALIZATIONMGR.OnJumpForwardInHistory();
	`XCOMVISUALIZATIONMGR.BuildVisualization(FullGameState.HistoryIndex, false);
}

/// <summary>
/// Reponsible for verifying that a set of newly incoming game states obey the rules.
/// </summary>
simulated function bool ValidateIncomingGameStates()
{
	return true;
}

/// <summary>
/// Returns true if the visualizer is currently in the process of showing the last game state change
/// </summary>
simulated function bool WaitingForVisualizer()
{
	return class'XComGameStateVisualizationMgr'.static.VisualizerBusy();
}

/// <summary>
/// This method builds a local list of state object references for objects that are relatively static, and that we 
/// may need to access frequently. Using the cached ObjectID from a game state object reference is much faster than
/// searching for it each time we need to use it.
/// </summary>
simulated function BuildLocalStateObjectCache()
{	
	CachedHistory = `XCOMHISTORY;
}

simulated function string GetStateDebugString();

simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local int iX, iY;
	local XComCheatManager LocalCheatManager;
	
	LocalCheatManager = XComCheatManager(GetALocalPlayerController().CheatManager);

	if( LocalCheatManager != None && LocalCheatManager.bDebugRuleset )
	{
		iX=250;
		iY=50;

		kStr =      "=========================================================================================\n";
		kStr = kStr$"Rules Engine (State"@GetStateName()@")\n";
		kStr = kStr$"=========================================================================================\n";	
		kStr = kStr$GetStateDebugString();
		kStr = kStr$"\n";

		kCanvas.SetPos(iX, iY);
		kCanvas.SetDrawColor(0,255,0);
		kCanvas.DrawText(kStr);
	}
}