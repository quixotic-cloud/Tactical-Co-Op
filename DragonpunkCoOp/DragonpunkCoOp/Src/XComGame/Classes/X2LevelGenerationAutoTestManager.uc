//---------------------------------------------------------------------------------------
//  FILE:    X2PlotGenerationTest.uc
//  AUTHOR:  David Burchanowski  --  04/28/2015
//  PURPOSE: Test object to exhaustively check that every mission/plot pairing that is
//           specified in the ini files actually works.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2LevelGenerationAutoTestManager extends AutoTestManager
	config(GameCore);

// bundles up the information needed to recreate the exact same map in the event of a crash 
struct native LevelGenerationAutoTestRecreationData
{
	var int MissionIndex;
	var int PlotIndex;
	var array<SavedCardDeck> Decks;
	var int Seed;
};

// if this is specified in the config file, this data will be used to create the map instead of the
// normal auto test sequence. Every map generation will dump a drag and drop config entry for this,
// so if the game crashes while doing an auto generate, grab this from the log and stick it in the ini.
var private const config LevelGenerationAutoTestRecreationData RecreationData;

// index of the last plot in ValidPlotsForMission that we have tested
var private int PlotIndex;

// index of the last mission type we've tested
var private int MissionIndex;

// cached common values
var private XComTacticalMissionManager MissionManager;
var private XComParcelManager ParcelManager;
var private XComGameStateHistory History;
var private X2TacticalGameRuleset Rules;

// delegate of the current update function to run in the tick. Since we can't do full latent
// execution we can emulate it here 
delegate CurrentUpdateFunction();

/**
  * Base AutoTestManager timer ticks once per second
  * Checks if we need to move on to the next step of generation
  */
event Timer()
{
	if(CurrentUpdateFunction != none)
	{
		CurrentUpdateFunction();
	}
}

function InitializeOptions(string Options)
{
	local int LoadingPlot;

	MissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;
	History = `XCOMHISTORY;

	if(RecreationData.Seed != 0)
	{
		MissionIndex = RecreationData.MissionIndex;
		PlotIndex = RecreationData.PlotIndex;
	}
	else
	{
		MissionIndex = int(class'GameInfo'.static.ParseOption(Options, "MissionIndex"));
		PlotIndex = int(class'GameInfo'.static.ParseOption(Options, "PlotIndex"));
	}

	LoadingPlot = int(class'GameInfo'.static.ParseOption(Options, "LoadingPlot"));

	if(LoadingPlot != 1)
	{
		// this is our first time into the test manager, so we need to load a plot
		CurrentUpdateFunction = LoadNextPlot;
	}
	else
	{
		// plot is loaded, commence layout generation
		CurrentUpdateFunction = GenerateParcelLayout;
		ParcelManager.ParcelGenerationAssertDelegate = OnParcelGenerationAssert;
	}
}

private function OnParcelGenerationAssert(string FullErrorMessage)
{
	`log("[Automated Test Error]\n" $ FullErrorMessage);
}

private function GetTestData(out MissionDefinition Mission, out string PlotMap)
{
	local array<PlotDefinition> ValidPlotsForMission;
	local int ValidPlotIndex;

	Mission = MissionManager.arrMissions[MissionIndex];
	ParcelManager.GetValidPlotsForMission(ValidPlotsForMission, Mission);

	// remove any that aren't allowed in strategy
	for (ValidPlotIndex = ValidPlotsForMission.Length - 1; ValidPlotIndex >= 0; ValidPlotIndex--)
	{
		if(ValidPlotsForMission[ValidPlotIndex].ExcludeFromStrategy)
		{
			ValidPlotsForMission.Remove(ValidPlotIndex, 1);
		}
	}

	// first check if we're out of plots to test. If so, move on to the next mission
	if(PlotIndex >= ValidPlotsForMission.Length)
	{
		MissionIndex++;
		// out of missions to test?
		if(MissionIndex >= MissionManager.arrMissions.Length)
		{
			// all done
			ConsoleCommand("EXIT");
		}

		PlotIndex = 0;
		GetTestData(Mission, PlotMap);
	}
	else
	{
		PlotMap = ValidPlotsForMission[PlotIndex].MapName;
	}
}

// Tests the next plot/parcel combination in line to be tested
private function LoadNextPlot()
{
	local MissionDefinition MissionToTest;
	local string PlotToTest;

	// this delegate must be cleared before we open the new map or the we won't be garbage collected,
	// causing the load to crash
	ParcelManager.ParcelGenerationAssertDelegate = none;

	// choose the next map to load
	GetTestData(MissionToTest, PlotToTest);
	`log("[Autotest]\n Beginning test for map: " $ MissionToTest.sType$ ", " $ PlotToTest 
					$ ", MissionIndex=" $ MissionIndex $ ", PlotIndex=" $ PlotIndex);

	// and start it up
	ConsoleCommand("open " $ PlotToTest $ "?AutoTests=1"
					$ "?MissionIndex=" $ MissionIndex $ "?PlotIndex=" $ PlotIndex $ "?LoadingPlot=1");
}

private function GenerateParcelLayout()
{
	local XComGameState StartState;
	local XComGameState_BattleData BattleData;
	local MissionDefinition MissionToTest;
	local XComTacticalController TacticalController;
	local int Seed;
	local string PlotToTest;

	// reset the history and create the default start states
	History.ResetHistory();
	StartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart();

	StartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer();

	// then copy in profile settings so we get xcom soldiers and such
	`XPROFILESETTINGS.ReadTacticalGameStartState(StartState);
	class'XComGameState_GameTime'.static.CreateGameStartTime(StartState);	
	History.AddGameStateToHistory(StartState);

	// grab the battle data out of the start state
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// fill everything out to load and test our next mission/plot pair
	GetTestData(MissionToTest, PlotToTest);
	MissionManager.ForceMission = MissionToTest;
	BattleData.MapData.PlotMapName = PlotToTest;

	// if we are recreating a previously tested configuration, restore the deck and seed so we will build the same layout
	if(RecreationData.Seed != 0)
	{
		Seed = RecreationData.Seed;
		class'X2CardManager'.static.GetCardManager().LoadDeckData(RecreationData.Decks);
	}
	else
	{
		// not recreating, so just choose any old seed and the dump the 
		// recreation data so we can retest this map if needed
		Seed = class'Engine'.static.GetEngine().GetARandomSeed();

		if(Seed == 0)
		{
			// since we use Seed == 0 as a sentinel for the recreation data being valid, 
			// should we ever actually roll a zero, just use 1 instead.
			Seed = 1; 
		}

		DumpRecreationData(Seed);
	}

	// use any old seed, really doesn't matter for testing purposes. Since the solver is exhaustive and will find a solution
	// for parcel layout if one exists, we really don't need to worry about the specific random order the parcels may be considered.
	ParcelManager.bBlockingLoadParcels = false; // set the parcel manager to work in async mode
	ParcelManager.GenerateMap(Seed); 

	// drop the camera fade so we can see what is happening
	TacticalController = XComTacticalController(WorldInfo.GetALocalPlayerController());
	if (TacticalController != none)
	{
		TacticalController.ClientSetCameraFade(false);
		TacticalController.SetInputState('Multiplayer_Inactive');
	}

	CurrentUpdateFunction = BeginMatch;
}

private function BeginMatch()
{
	// wait for the map to finish generating
	if(ParcelManager.IsGeneratingMap())
	{
		return;
	}

	// make sure pathing is up to date before we transition to the game
	ParcelManager.RebuildWorldData();

	// start the battle
	`TACTICALGRI.InitBattle();

	CurrentUpdateFunction = WaitingForMatchToFinishInitializing;
}

private function WaitingForMatchToFinishInitializing()
{
	// wait for the match to finish initializing. We need to do this so we also test objective spawning and such
	if(`TACTICALRULES.GetStateName() == 'CreateTacticalGame')
	{
		return;
	}

	// and test the next plot!
	PlotIndex++;
	CurrentUpdateFunction = LoadNextPlot;
}

private function DumpRecreationData(int Seed)
{
	local array<SavedCardDeck> Decks;
	local string Result;
	local string WorkingString; // smaller string to work on to make replacements faster
	local int DeckIndex;
	local int CardIndex;
	local int LastCard;

	// dump indices and seeds
	Result = "[Autotest]\n RecreationData=(Seed=%Seed, MissionIndex=%MissionIndex, PlotIndex=%PlotIndex";
	Result = Repl(Result, "%Seed", Seed);
	Result = Repl(Result, "%MissionIndex", MissionIndex);
	Result = Repl(Result, "%PlotIndex", PlotIndex);

	// and dump the decks
	class'X2CardManager'.static.GetCardManager().SaveDeckData(Decks);
	for (DeckIndex = 0; DeckIndex < Decks.Length; DeckIndex++)
	{
		// export the deck name and shuffle count
		WorkingString = ",\\\\\n  Decks[%DeckIndex]=(DeckName=\"%DeckName\", Deck=(ShuffleCount=%ShuffleCount, ";
		WorkingString = Repl(WorkingString, "%DeckIndex", DeckIndex);
		WorkingString = Repl(WorkingString, "%DeckName", Decks[DeckIndex].DeckName);
		WorkingString = Repl(WorkingString, "%ShuffleCount", Decks[DeckIndex].Deck.ShuffleCount);
		Result $= WorkingString; 

		// and then each of the cards
		LastCard = Decks[DeckIndex].Deck.Cards.Length - 1;
		for (CardIndex = 0; CardIndex <= LastCard; ++CardIndex)
		{
			WorkingString = "Cards[%CardIndex]=(CardLabel=\"%CardLabel\", UseCount=%UseCount, InitialWeight=%InitialWeight)";
			WorkingString = Repl(WorkingString, "%CardIndex", CardIndex); 
			WorkingString = Repl(WorkingString, "%CardLabel", Decks[DeckIndex].Deck.Cards[CardIndex].CardLabel);
			WorkingString = Repl(WorkingString, "%UseCount", Decks[DeckIndex].Deck.Cards[CardIndex].UseCount);
			WorkingString = Repl(WorkingString, "%InitialWeight", Decks[DeckIndex].Deck.Cards[CardIndex].InitialWeight);
			WorkingString $= (CardIndex == LastCard) ? "))" : ", ";

			Result $= WorkingString;
		}
	}

	Result $= ")";

	`log(Result);
}

defaultproperties
{
	MissionIndex=0
}