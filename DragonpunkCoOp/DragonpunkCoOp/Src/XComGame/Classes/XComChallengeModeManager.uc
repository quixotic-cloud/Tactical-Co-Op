//---------------------------------------------------------------------------------------
//  FILE:    XComChallengeModeManager.uc
//  AUTHOR:  Timothy Talley  --  02/16/2015
//  PURPOSE: Manages the System Interface and any necessary persistent data.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComChallengeModeManager extends Object
	config(Game)
	native(Core);

struct native ChallengeData
{
	var int TimeLimit;
	var int PlayerSeed;
	var array<byte> StartData;
};

var private array<ChallengeData> Challenges;
var private int SelectedChallengeIndex;

var private X2ChallengeModeInterface SystemInterface;
var config bool bUseMCP;

native final function ClearChallengeData();

cpptext
{
	void Init();
	void AddChallengeData(void* Data, int DataLenth, int TimeLimit, int PlayerSeed);
	TArrayNoInit<BYTE>& GetChallengeStartData(int ChallengeIndex);
}

event Init()
{
	`log(`location @ `ShowVar(bUseMCP));
	if (SystemInterface == none)
	{
		if (bUseMCP)
		{
			SystemInterface = `XENGINE.MCPManager;
		}
		else
		{
			SystemInterface = `FXSLIVE;
		}
	}
	`log(`location @ "Using Interface:" @ `ShowVar(SystemInterface));
}

function X2ChallengeModeInterface GetSystemInterface()
{
	if (SystemInterface == none)
	{
		Init();
	}
	return SystemInterface;
}

function SetSystemInterface(X2ChallengeModeInterface Interface)
{
	SystemInterface = Interface;
}

function XComPresentationLayerBase GetPresBase()
{
	local XComPresentationLayerBase PresBase;
	PresBase = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres;
	if (PresBase == none)
	{
		PresBase = `HQPRES;
	}
	return PresBase;
}

function OpenChallengeModeUI()
{
	if (SystemInterface.RequiresSystemLogin())
	{
		OpenLoginUI();
	}
	else
	{
		OpenIntervalUI();
	}
}

function OpenLoginUI()
{
	local string LoginUIClassName;
	local UILoginScreen Screen;
	LoginUIClassName = SystemInterface.GetSystemLoginUIClassName();
	Screen = UILoginScreen(GetPresBase().LoadGenericScreenFromName(LoginUIClassName));
	Screen.OnClosedDelegate = LoginUIClosed;
}

function LoginUIClosed(bool bLoginSuccessful)
{
	if (bLoginSuccessful)
	{
		OpenIntervalUI();
	}
}

function UIScreen OpenDebugUI()
{
	return GetPresBase().UIDebugChallengeMode();
}

function UIScreen OpenIntervalUI()
{
	if( SystemInterface.IsDebugMenuEnabled() )
	{
		return OpenDebugUI();
	}
	return OpenSqadSelectUI();
}

function UIScreen OpenSqadSelectUI()
{
	return GetPresBase().UIChallengeMode_SquadSelect();
}

function SetSelectedChallengeIndex(int Index)
{
	SelectedChallengeIndex = Index;
}

function int GetSelectedChallengeTimeLimit()
{
	if(SelectedChallengeIndex >= 0 && SelectedChallengeIndex < Challenges.Length)
	{
		return Challenges[SelectedChallengeIndex].TimeLimit;
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() @ "SelectedChallengeIndex is out of bounds (" $ SelectedChallengeIndex $ "). Returning -1");
`if(`notdefined(FINAL_RELEASE))
		return MaxInt;
`else
		return -1;
`endif
	}
}

function int FindChallengeIndex(int PlayerSeedId)
{
	local int Idx;
	`log(`location @ `ShowVar(PlayerSeedId),,'FiraxisLive');
	for( Idx = 0; Idx < Challenges.Length; ++Idx )
	{
		`log(`location @ `ShowVar(Challenges[Idx].PlayerSeed) @ "==" @ `ShowVar(PlayerSeedId),,'FiraxisLive');
		if( Challenges[Idx].PlayerSeed == PlayerSeedId )
		{
			return Idx;
		}
	}
	return -1;
}

defaultproperties
{
}