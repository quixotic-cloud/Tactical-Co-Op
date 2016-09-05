//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComCoOpTacticalGame
//  AUTHOR:  Elad Dvash
//  PURPOSE: Game class for the Co-Op game
//---------------------------------------------------------------------------------------

Class XComCoOpTacticalGame extends XComTacticalGame;

var float	fPendingMatchTimeoutCounter;
var bool	bMatchStarting,bPendingMatchTimedOut;
simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2TacticalCoOpGameRuleset';
}


simulated function CreateGameRuleset()
{
	GameRuleset = Spawn(class'X2TacticalCoOpGameRuleset', self);
}

static event class<GameInfo> SetGameType(string MapName, string Options, string Portal) //Basically the old version from GameInfo.uc but with the Co-op ruleset option added.
{
	local class<GameInfo>   GameInfoClass;
	local string            GameInfoClassName;

	local string            GameInfoClassToUse;

	GameInfoClassName = class'GameInfo'.static.ParseOption(Options, "Game");

	// 1) test MP/Co-Op game type before the map name tests just in case an MP map name contains one of the search strings -tsmith 
	if (InStr(GameInfoClassName, "XComCoOpTacticalGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "Dragonpunk_CoOp.XComCoOpTacticalGame";
	}
	else if (InStr(GameInfoClassName, "XComMPTacticalGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComMPTacticalGame";
	}
	else if (InStr(GameInfoClassName, "X2MPLobbyGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.X2MPLobbyGame";
	}
	else if(InStr(GameInfoClassName, "MPShell", , true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComMPShell";
	}

	// 2) pick a gametype based on the filename of the map
	else if (InStr(MapName, "Shell", , true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComShell";
	}
	else if (InStr(MapName, "Avenger_Root", , true) != INDEX_NONE || InStr(GameInfoClassName, "XComHeadquartersGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComHeadquartersGame";
	}
	else if (InStr(GameInfoClassName, "XComTacticalGameValidation", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComTacticalGameValidation";
	}
	else
	{
		GameInfoClassToUse = "XComGame.XComTacticalGame"; // likely it's a tactical map.
	}
	`log("loading requested gameinfo '" $ GameInfoClassToUse $ "'.",GameInfoClassToUse!="",'Team Dragonpunk Co Op');

	if (GameInfoClass == none)
	{
		GameInfoClass = class<GameInfo>(DynamicLoadObject(GameInfoClassToUse, class'Class'));
	}

	if (GameInfoClass != none)
	{
		return GameInfoClass;
	}
	else
	{
		`log("SetGameType: ERROR! failed loading requested gameinfo '" $ GameInfoClassToUse $ "', using default gameinfo.");
		return default.Class;
	}
}

auto state PendingMatch
{
	function bool IsLoading()
	{
		local bool bLoading;
		local string MyURL;
		MyURL = WorldInfo.GetLocalURL();
		bLoading = InStr(MyURL, "LoadingSave") != -1;
		return bLoading;
	}

	event BeginState(name PreviousStateName)
	{
		`log("MY TACTICAL GAME HAS BEEN STARTED!",,'Team Dragonpunk Co Op');
		super.BeginState(PreviousStateName);
		m_bMatchStarting = false;
	}

	function Tick( float fDTime )
	{
		if( WorldInfo.NetMode != NM_Standalone )
		{
			if(bPendingMatchTimedOut)
			{
				return;
			}

			if(!bMatchStarting)
			{
				fPendingMatchTimeoutCounter += fDTime;
				if(fPendingMatchTimeoutCounter >= m_fPendingMatchTimeoutSeconds)
				{
					bPendingMatchTimedOut = true;
					ConsoleCommand("disconnect");
					return;
				}
				// TODO: SP has 0 required players
				if( CountHumanPlayers() >= m_iRequiredPlayers )
				{
					`Log( "Player quota met, calling StartMatch()" @ "State=" $ GetStateName(), true, 'XCom_Net' );
					bMatchStarting = true;
					StartMatch();
				}
			}
		}
	}


	Begin:
		`log("MY TACTICAL GAME HAS BEEN STARTED!",,'Team Dragonpunk Co Op');
		if( IsLoading() )
		{
			`MAPS.AddStreamingMapsFromURL(WorldInfo.GetLocalURL(), false);
			GetALocalPlayerController().ClientFlushLevelStreaming();
		}

		while( WorldInfo.bRequestedBlockOnAsyncLoading )
		{
			Sleep( 0.1f );
		}

		if (class'WorldInfo'.static.IsPlayInEditor())
		{
			while (!`MAPS.IsStreamingComplete( ))
			{
				sleep( 0.0f );
			}
		}

		StartMatch();
		while( WorldInfo.GRI.IsInState( 'LoadingFromStrategy' ) )
		{
			Sleep( 0.1f );
		}
}


defaultproperties
{
	GameReplicationInfoClass = class'XComMPCOOPGRI'
	m_bMatchStarting=false
	m_iRequiredPlayers=0
}